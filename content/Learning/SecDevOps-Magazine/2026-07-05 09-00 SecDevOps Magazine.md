---
tags:
  - security
  - devops
  - docker
  - kubernetes
  - terraform
  - linux
  - cloudsecurity
  - observability
  - daily
---

[[Home]]

# SecDevOps Magazine — 2026-07-05

昨日の **Secure Coding Basics (Beginner)** を受けて、今日は同じ学習アークの **Middle** に進みます。テーマは **OWASP Top 10 の中でも実務被害が大きい Broken Access Control**。実装は動いていても、「見えてはいけないものが見える」「触れてはいけないものが触れる」状態は、本番事故に直結します。

> **Prerequisites for Middle**
> - 入力値検証の基本
> - parameterized query の意味
> - HTTP request / response の基本
> - 「認証(authentication)」と「認可(authorization)」の違い

## 1) Topic + Level
**OWASP: Broken Access Control 実践 + Middle**

## 2) Why it matters in real projects
認証が入っているだけでは、安全とは言えません。実務で多いのは「ログインしていれば他人のデータも見えてしまう」「一般ユーザーが管理者向けAPIを叩ける」「UIではボタンを隠しているがAPIは無防備」というパターンです。

Broken Access Control は次のような事故を起こします。

- 他ユーザーの注文・プロフィール・請求情報の閲覧
- ID を 1 つ変えるだけで他人のリソース取得が可能になる **IDOR (Insecure Direct Object Reference)**
- admin API の誤公開
- Kubernetes Dashboard や internal admin tool の権限境界ミス
- CI/CD や cloud IAM でも起きる「権限が広すぎる」設計の温床

つまりこれは Web アプリの話に見えて、実際は **IAM / RBAC / secret access / internal tooling** に全部つながる、かなり DevOps 寄りの重要テーマです。

## 3) Core concepts
### 認証と認可は別物
- **認証 (Authentication)**: あなたは誰か
- **認可 (Authorization)**: あなたは何をしてよいか

ログイン済みでも、許可されていない操作は拒否しなければいけません。ここを混同すると、ログイン機能があるのに情報漏えいします。

### Broken Access Control の典型パターン
#### 1. IDOR
URL や API パラメータにある `user_id`, `invoice_id`, `project_id` を書き換えるだけで、他人のデータに到達できる状態です。

悪い例:
```python
@app.route('/invoice/<invoice_id>')
def get_invoice(invoice_id):
    return db.fetch_invoice(invoice_id)
```

これでは「その invoice が **そのユーザーのものか**」を確認していません。

良い方向:
```python
@app.route('/invoice/<invoice_id>')
def get_invoice(invoice_id):
    return db.fetch_invoice_for_user(invoice_id, current_user.id)
```

#### 2. UI だけで隠している
「管理者ボタンを表示しない」だけでは無意味です。サーバー側で `role == admin` を確認しない限り、API は直接叩けます。

#### 3. deny-by-default になっていない
許可ルールを後付けで足していくと漏れます。基本姿勢は:

- まず拒否
- 条件を満たすときだけ許可
- 監査ログを残す

### Resource ownership を毎回確認する
多くの API は「誰がこの resource にアクセスしてよいか」を確認すべきです。

- `document.owner_id == current_user.id`
- `project.members includes current_user`
- `org_id` が一致するか
- RBAC role に必要権限があるか

### サーバー側で判定する
フロントエンドの hidden / disabled / route guard は UX には役立ちますが、セキュリティ境界ではありません。**本物の境界は backend / gateway / policy engine** です。

### ログと監査
認可拒否はエラーではなく、重要な観測点です。

残したいもの:
- user ID
- requested resource ID
- action (`read`, `update`, `delete`)
- result (`allow` / `deny`)
- request ID

これは後で Observability や Incident Response に効きます。

## 4) Hands-on mini lab (30-60 min)
### 目標
`curl` で他ユーザーのデータにアクセスできてしまう脆弱な API を作り、**ownership check** を入れて防ぐ。

### 手順
#### 1. 作業ディレクトリを用意
```bash
mkdir -p ~/labs/secdevops/broken-access-control
cd ~/labs/secdevops/broken-access-control
python3 -m venv .venv
source .venv/bin/activate
pip install flask
```

#### 2. 脆弱なサンプルを作る
`app.py`:
```python
from flask import Flask, jsonify, request

app = Flask(__name__)

INVOICES = {
    "1001": {"owner": "alice", "amount": 12000, "status": "paid"},
    "1002": {"owner": "bob", "amount": 8900, "status": "open"},
}


def current_user():
    # 本来は session / token から取得
    return request.headers.get("X-User", "guest")


@app.route("/invoice/<invoice_id>")
def get_invoice(invoice_id):
    invoice = INVOICES.get(invoice_id)
    if not invoice:
        return jsonify({"error": "not found"}), 404
    return jsonify(invoice)


if __name__ == "__main__":
    app.run(port=5000, debug=True)
```

起動:
```bash
python app.py
```

#### 3. 脆弱性を再現
別ターミナルで:
```bash
curl -s -H 'X-User: alice' http://127.0.0.1:5000/invoice/1001 | jq
curl -s -H 'X-User: alice' http://127.0.0.1:5000/invoice/1002 | jq
```

2本目も見えてしまったら脆弱です。これが IDOR / Broken Access Control の感覚です。

#### 4. ownership check を追加
`get_invoice()` を次のように変更:
```python
@app.route("/invoice/<invoice_id>")
def get_invoice(invoice_id):
    invoice = INVOICES.get(invoice_id)
    if not invoice:
        return jsonify({"error": "not found"}), 404

    user = current_user()
    if invoice["owner"] != user:
        app.logger.warning(
            "authorization denied user=%s invoice=%s owner=%s",
            user,
            invoice_id,
            invoice["owner"],
        )
        return jsonify({"error": "forbidden"}), 403

    return jsonify(invoice)
```

#### 5. 再テスト
```bash
curl -i -H 'X-User: alice' http://127.0.0.1:5000/invoice/1001
curl -i -H 'X-User: alice' http://127.0.0.1:5000/invoice/1002
curl -i -H 'X-User: bob'   http://127.0.0.1:5000/invoice/1002
```

期待結果:
- alice → 1001 は `200`
- alice → 1002 は `403`
- bob → 1002 は `200`

#### 6. 余力があれば role check も足す
`/admin/reports` を作り、`X-Role: admin` がないと拒否する実装にしてみましょう。ポイントは **route ごとに server-side で enforce する** ことです。

## 5) Command cheatsheet
### Linux / HTTP 検証
```bash
pwd
ls -la
cat app.py
grep -n "invoice" app.py
curl -i http://127.0.0.1:5000/invoice/1001
curl -i -H 'X-User: alice' http://127.0.0.1:5000/invoice/1002
```

### Python / Flask
```bash
python3 -m venv .venv
source .venv/bin/activate
pip install flask
python app.py
```

### Docker 化したい場合
```bash
docker build -t broken-access-lab .
docker run --rm -p 5000:5000 broken-access-lab
```

### ログ観察
```bash
journalctl -f
python app.py 2>&1 | tee app.log
grep "authorization denied" app.log
```

## 6) Common mistakes and how to avoid them
### ミス1: 「ログイン済みだからOK」と思い込む
**回避:** every request で `who are you?` と `what can you do?` を分けて考える。

### ミス2: UI を隠しただけで満足する
**回避:** ボタン非表示は UX。権限制御は backend / API / policy 層で行う。

### ミス3: resource ownership を見ていない
**回避:** `resource belongs to current user?` を query / service 層で毎回確認する。

### ミス4: role 名だけを雑に比較する
**回避:** `admin` / `editor` / `viewer` のような role だけでなく、**action 単位**で整理する。将来 IAM / RBAC に展開しやすい。

### ミス5: deny ログを残していない
**回避:** `403` は incident の兆候になり得る。メトリクス化や trace 連携を意識する。

### ミス6: テストが happy path だけ
**回避:** 他人ID、権限なし token、期限切れ session、別組織 ID を含む **negative test** を必ず作る。

## 7) One interview-style question
**質問:**
「認証は入っているのに Broken Access Control が起きるのはなぜですか？ また、IDOR を防ぐ実装上の基本方針を説明してください。」

**考えるポイント:**
- 認証と認可の違い
- user と resource の関係確認
- server-side enforcement
- deny-by-default

## 8) Next-step reading links
- OWASP Top 10: Broken Access Control  
  https://owasp.org/Top10/A01_2021-Broken_Access_Control/
- OWASP Authorization Cheat Sheet  
  https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Cheat_Sheet.html
- OWASP IDOR Prevention Cheat Sheet  
  https://cheatsheetseries.owasp.org/cheatsheets/Insecure_Direct_Object_Reference_Prevention_Cheat_Sheet.html
- MDN: HTTP Authentication 概要  
  https://developer.mozilla.org/en-US/docs/Web/HTTP/Authentication
- OpenTelemetry Concepts  
  https://opentelemetry.io/docs/concepts/

---

### 明日の予告
次はこのアークの **Advanced** として、**Auth / Session Security** に進むのがおすすめです。たとえば session fixation, cookie 属性, token lifetime, refresh flow, logout 設計まで踏み込むと、今日の認可の話とかなりきれいにつながります。
