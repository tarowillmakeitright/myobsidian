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

# SecDevOps Magazine — 2026-07-04

今日はシリーズのスタートなので、**Beginner arc** の1本目として「Secure Coding」の土台を固めます。ここから Beginner → Middle → Advanced の流れで難易度を回しつつ、Application Security / DevOps / Cloud Security / Observability / Kubernetes incident drills を順番に育てていきます。

## 1) Topic + Level
**Secure Coding Basics + Beginner**

## 2) Why it matters in real projects
実務では、脆弱性の多くは「高度な攻撃」より前に、**日常の実装ミス**から始まります。入力値の未検証、エラーメッセージの出しすぎ、認可チェック漏れ、秘密情報の直書き――こうした小さな穴が、事故になると一気に大きくなります。

Secure Coding を早い段階で身につけると、次の効果があります。

- バグ修正より安く安全性を組み込める
- レビューで見るべきポイントが明確になる
- OWASP Top 10 や auth/session security の理解が速くなる
- DevOps 側の CI/CD security や secrets management と自然につながる

要するに、**あとから守るより、最初から壊れにくく作る**ための基礎です。

## 3) Core concepts
### 入力値は「信用しない」が基本
ユーザー入力、HTTP header、query parameter、JSON body、環境変数、外部 API の返り値まで、全部「外から来たデータ」です。

大事なのはこの3つです。

- **Validate**: 形式が正しいか確認する
- **Sanitize**: 必要なら危険な文字や構造を除く
- **Encode/Escape**: 出力先に応じて安全な形に変換する

たとえば HTML に出すなら HTML escape、SQL に入れるなら parameterized query を使います。**同じデータでも、出力先が違えば守り方も違う**のがポイントです。

### Parameterized query を使う
SQL Injection の基本対策です。文字列連結で SQL を作らず、プレースホルダを使います。

悪い例:
```js
const sql = `SELECT * FROM users WHERE email = '${email}'`;
```

良い例:
```js
const sql = 'SELECT * FROM users WHERE email = ?';
db.query(sql, [email]);
```

### 最小権限 (Least Privilege)
アプリも人も、必要最小限の権限だけ持つべきです。

- DB 接続ユーザーに DROP 権限はいらないかもしれない
- CI job に production deploy 権限を持たせすぎていないか
- アプリが読める secret は本当に必要なものだけか

これは後で IAM、Kubernetes RBAC、Terraform 設計にも直結します。

### エラーハンドリングは「親切すぎない」
開発中は stack trace が便利ですが、本番でそのまま出すと内部構造のヒントになります。

- ユーザー向け: 短く安全なメッセージ
- サーバーログ向け: 詳細な原因
- 監視向け: error rate, trace, request ID

### 秘密情報をコードに埋め込まない
API key、DB password、JWT secret をソースコードに置くと、Git 履歴・ログ・スクリーンショット経由で漏れます。

最初から次を癖にすると強いです。

- `.env` はローカル限定
- 本番は secret manager / CI secret / Kubernetes Secret を使う
- Git に入る前に secret scan を回す

## 4) Hands-on mini lab (30-60 min)
### 目標
危険なサンプルを見て、**SQL Injection / secret hardcode / verbose error** を減らす感覚を作る。

### 手順
#### 1. 作業用ディレクトリを作る
```bash
mkdir -p ~/labs/secdevops/secure-coding-basics
cd ~/labs/secdevops/secure-coding-basics
```

#### 2. 脆弱なサンプルを作る
`app.py` を作成:
```python
import sqlite3
from flask import Flask, request, jsonify

app = Flask(__name__)
SECRET_KEY = "super-secret-demo-key"

@app.route('/user')
def get_user():
    email = request.args.get('email', '')
    conn = sqlite3.connect('demo.db')
    cur = conn.cursor()
    query = f"SELECT id, email FROM users WHERE email = '{email}'"
    rows = cur.execute(query).fetchall()
    return jsonify(rows)

@app.route('/boom')
def boom():
    raise Exception('debug stack trace example')

if __name__ == '__main__':
    app.run(debug=True)
```

#### 3. 仮想環境と依存を入れる
```bash
python3 -m venv .venv
source .venv/bin/activate
pip install flask
```

#### 4. DB を用意する
```bash
python3 - <<'PY'
import sqlite3
conn = sqlite3.connect('demo.db')
cur = conn.cursor()
cur.execute('CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY, email TEXT)')
cur.execute('DELETE FROM users')
cur.executemany('INSERT INTO users (email) VALUES (?)', [
    ('alice@example.com',),
    ('bob@example.com',)
])
conn.commit()
conn.close()
PY
```

#### 5. 動かして問題を見る
```bash
python3 app.py
```
別端末で:
```bash
curl 'http://127.0.0.1:5000/user?email=alice@example.com'
curl 'http://127.0.0.1:5000/user?email='
```

#### 6. 改善する
以下を自分で直してみてください。

- SQL を parameterized query に変更
- `SECRET_KEY` を環境変数から読む
- `debug=True` をやめる
- 例外をそのまま返さない

改善後イメージ:
```python
import os
import sqlite3
from flask import Flask, request, jsonify

app = Flask(__name__)
app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', 'dev-only-change-me')

@app.route('/user')
def get_user():
    email = request.args.get('email', '')
    conn = sqlite3.connect('demo.db')
    cur = conn.cursor()
    rows = cur.execute(
        'SELECT id, email FROM users WHERE email = ?',
        (email,)
    ).fetchall()
    return jsonify(rows)

@app.errorhandler(Exception)
def handle_error(e):
    return jsonify({'error': 'internal server error'}), 500

if __name__ == '__main__':
    app.run()
```

#### 7. 追加チャレンジ
時間が余れば、`gitleaks` や `trufflehog` を後で試せるようメモしておくと良いです。今後の CI/CD security 回でつながります。

## 5) Command cheatsheet
### Linux
```bash
pwd
ls -la
mkdir -p ~/labs/secdevops/secure-coding-basics
cd ~/labs/secdevops/secure-coding-basics
cat app.py
export SECRET_KEY='change-me'
```

### Python / app run
```bash
python3 -m venv .venv
source .venv/bin/activate
pip install flask
python3 app.py
```

### Test with curl
```bash
curl 'http://127.0.0.1:5000/user?email=alice@example.com'
curl 'http://127.0.0.1:5000/boom'
```

### Security mindset shortcuts
```bash
grep -R "SECRET\|PASSWORD\|TOKEN" .
history | tail
```

## 6) Common mistakes and how to avoid them
### 1. 「内部ツールだから安全」で済ませる
社内向けでも脆弱性は普通に事故になります。**利用者が少ない = 安全**ではありません。

**回避策:** 外部公開アプリと同じく、入力検証・認可・secret 管理を最初から入れる。

### 2. サニタイズだけで全部防げると思う
サニタイズは万能ではありません。特に SQL は **escape 頼みではなく parameterized query** が基本です。

**回避策:** 出力先ごとに適切な対策を選ぶ。

### 3. debug モードを本番に持ち込む
便利ですが、情報漏えいの近道です。

**回避策:** 開発と本番の設定を分離し、環境変数で制御する。

### 4. secret を `.env` に置いたままコミットする
Beginner で一番ありがちな事故です。

**回避策:** `.gitignore` を確認し、secret scanning を早めに導入する。

### 5. 認可と認証を混同する
ログインしているだけでは、そのデータにアクセスしてよいとは限りません。

**回避策:** 「誰か」ではなく「その操作をしてよいか」を毎回考える。

## 7) One interview-style question
**質問:** SQL Injection を防ぐとき、入力値のバリデーションだけで不十分なのはなぜですか？ parameterized query が有効な理由も説明してください。

## 8) Next-step reading links
- OWASP Top 10: https://owasp.org/www-project-top-ten/
- OWASP Cheat Sheet Series: https://cheatsheetseries.owasp.org/
- SQL Injection Prevention Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/SQL_Injection_Prevention_Cheat_Sheet.html
- Authentication Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html
- Secrets Management overview (OWASP Secrets Management): https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html

---

## Prerequisites for future issues
- **Middle** に進む前提:
  - Linux 基本操作ができる
  - HTTP request / response の概念がわかる
  - 環境変数と簡単なアプリ起動ができる
- **Advanced** に進む前提:
  - Middle レベルの secure coding / auth / container 基礎を理解している
  - ログ・権限・デプロイ構成を読める
  - 小規模なトラブルシュート経験がある

## Upcoming rotation preview
次回以降は、以下のようにローテーションしていきます。

1. Secure Coding — Beginner
2. Docker Hardening — Middle
3. Cloud Security (IAM / permission design) — Advanced
4. Linux Command Mastery — Beginner
5. OWASP Risks — Middle
6. Observability (Prometheus / Grafana / OpenTelemetry) — Advanced
7. Threat Modeling — Beginner
8. CI/CD Security — Middle
9. Kubernetes Incident Drills — Advanced
10. Auth / Session Security — Beginner
11. Terraform / IaC Best Practices — Middle
12. Kubernetes Fundamentals / Security — Advanced
13. Incident Response — Beginner
14. Secrets Management — Middle
