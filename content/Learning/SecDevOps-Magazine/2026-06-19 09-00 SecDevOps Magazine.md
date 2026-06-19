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

# SecDevOps Magazine — 2026-06-19 09:00

今日のテーマは **Cloud Security 入門: IAM と Permission Design の基本** です。  
**Level: Beginner**

> このマガジンは、Application Security と DevOps を往復しながら、Beginner → Middle → Advanced の学習アークで積み上げていくシリーズです。  
> 今回は新しいアークの土台として、Cloud Security の最重要テーマである **IAM (Identity and Access Management)** を扱います。

---

## 1) Topic + Level

**Topic:** Cloud Security — AWS/GCP IAM と Permission Design の基本  
**Level:** Beginner

### この回の位置づけ
- 今回: **Beginner** — IAM の考え方、最小権限、Role/Policy の基本
- 次回以降の Middle で想定すること:
  - JSON/YAML ポリシーを読める
  - CLI で現在の権限や Caller Identity を確認できる
  - 「人」「アプリ」「CI/CD」の権限を分けて考えられる
- Advanced で想定すること:
  - Cross-account / Organization / 条件付きアクセス / Workload Identity
  - Terraform による IAM の再現性管理
  - Incident 時の一時権限設計・監査

---

## 2) Why it matters in real projects

IAM を甘く扱うと、アプリのコードがきれいでも事故は普通に起きます。

実務ではこんな場面が多いです。

- 開発者が `AdministratorAccess` 相当の広すぎる権限を持ったまま運用に入る
- CI/CD 用の Service Account が本番環境に対して不要な更新権限を持つ
- 監視ツールに読み取りだけで十分なのに、削除・変更権限まで付いている
- 退職者や使われなくなった Bot の認証情報が残る
- ひとつの漏えいした Access Key から、S3・Secrets・Compute まで芋づるで突破される

Cloud Security の多くは「脆弱なソフトウェア」より前に、**脆弱な権限設計**で破綻します。  
だから IAM は単なる運用設定ではなく、**アプリケーションセキュリティの一部**です。

---

## 3) Core concepts

### 3-1. IAM とは何か
IAM はざっくり言うと、

- **誰が**
- **何に対して**
- **どの操作を**
- **どの条件で**

実行できるかを制御する仕組みです。

AWS と GCP で用語に違いはありますが、考え方はかなり共通しています。

---

### 3-2. Principal / Resource / Action / Condition
IAM を読むときは、まずこの4つに分解します。

- **Principal**: 操作する主体  
  例: ユーザー、Role、Service Account、CI/CD
- **Resource**: 対象  
  例: S3 bucket、GCS bucket、Secret、VM、KMS key
- **Action**: 何をするか  
  例: read, write, list, delete, assume, deploy
- **Condition**: どんな条件なら許可するか  
  例: IP 制限、MFA 必須、特定タグ必須、特定時間帯のみ

この分解ができないまま Policy を書くと、ほぼ確実に広すぎる権限になります。

---

### 3-3. Least Privilege（最小権限）
**必要な操作だけを、必要な対象に、必要な時間だけ与える** という原則です。

悪い例:
- 開発用のツールに本番 Secret の読み取り権限まで付ける
- 監査用アカウントに削除権限を付ける
- 一時作業なのに恒久的な管理者権限を付けっぱなしにする

良い例:
- `read-only` と `deploy` と `admin` を分離する
- 環境ごとに Role を分ける（dev/stg/prod）
- 人間用権限と機械用権限を分ける
- 短命な認証（OIDC / Workload Identity / AssumeRole）を優先する

---

### 3-4. AWS の基本イメージ
AWS ではよく次を押さえます。

- **IAM User**: 人に長期 Access Key を持たせる設計は今では極力避けたい
- **IAM Role**: 推奨の中心。人、EC2、Lambda、CI/CD が引き受ける
- **Policy**: `Action` と `Resource` を定義する許可ルール
- **STS / AssumeRole**: 一時的な認証情報を使う仕組み

初心者の最重要ポイントはこれです。

> **長期キーより Role / 一時認証を優先する**

---

### 3-5. GCP の基本イメージ
GCP ではよく次を押さえます。

- **Principal**: user / group / service account
- **Role**: predefined role / custom role
- **Binding**: 「誰にどの Role を付けるか」
- **Service Account**: アプリや自動化の主体

初心者がまず覚えるべきことは、

> **Viewer / Editor / Owner のような広い権限を雑に使わない**

です。特に `Editor` は「とりあえず動く」ので乱用されがちですが、後で事故の温床になります。

---

### 3-6. 人間・アプリ・CI/CD を分ける
同じ「アクセス」でも、主体ごとに設計思想が違います。

#### 人間
- SSO / MFA 前提
- 監査ログが追えること
- 日常は read-only 寄り
- 危険操作は昇格 or break-glass

#### アプリ
- 必要最小限の API 呼び出しだけ
- Secret 直接埋め込み禁止
- 実行環境に紐づく Role / Service Account を使う

#### CI/CD
- deploy できても、データ全件閲覧は不要なことが多い
- build と deploy の権限を分ける
- branch / environment ごとに権限を分ける

---

### 3-7. Permission Design の基本パターン
Beginner の段階では、まずこの設計パターンを覚えると強いです。

1. **職務単位で Role を切る**  
   例: `app-runtime-reader`, `deployer`, `security-auditor`

2. **環境で分離する**  
   例: `dev-deployer`, `stg-deployer`, `prod-deployer`

3. **読み取りと変更を分離する**  
   例: `viewer` と `operator` を別にする

4. **秘密情報アクセスを別格で扱う**  
   Secret/Key/KMS は特に厳しくする

5. **管理者権限は常用しない**  
   日常運用は管理者不要で回るのが理想

---

### 3-8. Application Security との接続
IAM はインフラ設定に見えて、実は AppSec と直結しています。

- **Auth/Session Security**: アプリのセッションが奪われた後、どこまで被害が広がるかは権限設計で決まる
- **OWASP Top 10**: Broken Access Control はアプリ内だけの話ではない
- **Threat Modeling**: 「認証情報漏えい」「CI token 流出」「内部不正」を前提に被害半径を設計する
- **Incident Response**: 侵害時にどの Principal を止めるか、どのログを見るかが明確になる

---

## 4) Hands-on mini lab (30-60 min)

### ラボの目的
- AWS/GCP 風の権限設計をローカルの YAML で練習する
- 「広すぎる権限」を見つけて、最小権限に直す感覚をつかむ
- DevOps 実務でよくある主体分離を理解する

### 前提
- Linux shell の基本操作ができる
- `cat`, `grep`, `less` が使える
- クラウドアカウントは不要

### 所要時間
約 35〜50 分

---

### Step 1. 作業ディレクトリを作る
```bash
mkdir -p ~/lab/iam-basics
cd ~/lab/iam-basics
```

---

### Step 2. まず「危ない権限定義」を作る
`policies.yaml` を作成します。

```yaml
principals:
  - name: dev-user
    type: human
    permissions:
      - resource: "*"
        actions: ["*"]

  - name: cicd-bot
    type: machine
    permissions:
      - resource: "prod-cluster"
        actions: ["deploy", "read-secrets", "delete-service"]

  - name: monitoring-sa
    type: machine
    permissions:
      - resource: "prod-observability"
        actions: ["read-metrics", "read-logs", "delete-logs"]
```

保存後、内容を確認します。

```bash
cat policies.yaml
```

---

### Step 3. 危険ポイントを洗い出す
次を見つけてみてください。

- `dev-user` が全権限 (`*`) を持っている
- `cicd-bot` が Secret 読み取りまでできる
- `monitoring-sa` に削除権限がある

簡単に grep で探します。

```bash
grep -n '\*' policies.yaml
grep -n 'read-secrets\|delete' policies.yaml
```

---

### Step 4. 最小権限版に修正する
以下のように書き換えます。

```yaml
principals:
  - name: dev-user
    type: human
    permissions:
      - resource: "dev-app"
        actions: ["read-logs", "read-config", "deploy-dev"]

  - name: cicd-bot
    type: machine
    permissions:
      - resource: "prod-cluster"
        actions: ["deploy"]
      - resource: "prod-image-registry"
        actions: ["push-image"]

  - name: monitoring-sa
    type: machine
    permissions:
      - resource: "prod-observability"
        actions: ["read-metrics", "read-logs"]
```

差分のイメージを確認します。

```bash
diff -u policies.yaml <(cat policies.yaml)
```

> 実際に差分を見たいなら、修正前を `policies-bad.yaml` として退避しておくとよいです。

おすすめのやり方:

```bash
cp policies.yaml policies-bad.yaml
# ここで policies.yaml を最小権限版に編集

diff -u policies-bad.yaml policies.yaml
```

---

### Step 5. 主体ごとの責務を言語化する
各 Principal について、1行で説明を書きます。

例:
- `dev-user`: 開発環境のログ確認と dev デプロイだけ
- `cicd-bot`: 本番クラスタへの deploy だけ
- `monitoring-sa`: メトリクス・ログの読み取りだけ

これを `notes.md` にまとめます。

```bash
cat > notes.md <<'EOF'
# IAM design notes

- dev-user: 開発環境のみ。日常作業用。管理者権限なし。
- cicd-bot: 本番 deploy 専用。Secrets 読み取り不可。
- monitoring-sa: 監視データ閲覧専用。削除不可。
EOF
```

---

### Step 6. 余裕があれば threat modeling を1つ追加
次の問いに答えてみてください。

> もし `cicd-bot` の認証が漏えいしたら、何ができて、何ができないべきか？

理想:
- できる: 本来の deploy 操作
- できない: Secret 一覧取得、監査ログ削除、DB ダンプ取得

この思考がそのまま **Threat Modeling + Incident Response** につながります。

---

## 5) Command cheatsheet

### Linux
```bash
pwd
mkdir -p ~/lab/iam-basics
cd ~/lab/iam-basics
ls -la
cat policies.yaml
less policies.yaml
grep -n '\*' policies.yaml
grep -n 'delete\|read-secrets' policies.yaml
cp policies.yaml policies-bad.yaml
diff -u policies-bad.yaml policies.yaml
```

### Docker（関連づけ理解用）
IAM の直接操作ではないですが、コンテナ実務とつながる視点です。

```bash
docker ps
docker inspect <container>
```

見るポイント:
- アプリがどの Secret を必要としているか
- そのコンテナに「不要な権限」が前提になっていないか

### Kubernetes（将来の接続）
Middle 以降で重要になります。

```bash
kubectl get serviceaccounts -A
kubectl auth can-i get secrets --as system:serviceaccount:default:default
kubectl describe serviceaccount <name>
```

### Terraform（将来の接続）
IaC で IAM を管理するときの入口です。

```bash
terraform fmt
terraform validate
terraform plan
```

---

## 6) Common mistakes and how to avoid them

### ミス1: とりあえず Admin / Editor を付ける
**なぜ起きるか:** 早く動かしたいから。  
**回避策:** まず必要操作を3つだけ書き出す。`read`, `deploy`, `delete` を混ぜない。

### ミス2: 人間と機械で同じ権限を使う
**なぜ危険か:** 監査もしづらいし、漏えい時の被害半径が読めない。  
**回避策:** human / app / CI を必ず別 Principal にする。

### ミス3: 長期 Access Key を配る
**なぜ危険か:** 漏えいしても気づきにくく、失効も運用負荷が高い。  
**回避策:** Role, STS, OIDC, Workload Identity を優先する。

### ミス4: Secret 読み取り権限を広く配る
**なぜ危険か:** 権限設計の破綻点になりやすい。  
**回避策:** Secret へのアクセスを専用 Role に分離し、用途単位で限定する。

### ミス5: 監視アカウントに変更権限を持たせる
**なぜ危険か:** 侵害後にログ改ざん・削除される。  
**回避策:** Observability 系はまず read-only を基本にする。

### ミス6: 本番と開発の境界がない
**なぜ危険か:** dev 侵害から prod に飛び火しやすい。  
**回避策:** 環境ごとに Role / Project / Account を分離する。

---

## 7) One interview-style question

**Q.** AWS または GCP で、CI/CD 用の権限を設計するときに `least privilege` をどう具体化しますか？

**考えるポイント:**
- build と deploy の権限を分ける
- 対象環境を限定する（dev/stg/prod）
- Secret 読み取りを必要最小限にする
- 長期キーではなく一時認証を使う
- ログと監査証跡を残す

自分の言葉で 60 秒で説明できればかなり強いです。

---

## 8) Next-step reading links

### 公式ドキュメント
- AWS IAM User Guide  
  https://docs.aws.amazon.com/IAM/latest/UserGuide/introduction.html
- AWS IAM Best Practices  
  https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- Google Cloud IAM Overview  
  https://cloud.google.com/iam/docs/overview
- Google Cloud IAM Best Practices  
  https://cloud.google.com/iam/docs/best-practices

### 関連学習
- OWASP Top 10  
  https://owasp.org/www-project-top-ten/
- OWASP ASVS  
  https://owasp.org/www-project-application-security-verification-standard/
- Kubernetes RBAC  
  https://kubernetes.io/docs/reference/access-authn-authz/rbac/
- OpenTelemetry Docs  
  https://opentelemetry.io/docs/
- Terraform Recommended Practices  
  https://developer.hashicorp.com/terraform

---

## 次号への橋渡し
次の Middle 候補はこのあたりです。

- **Observability (Middle): Prometheus / Grafana / OpenTelemetry の役割分担**
- **Docker Security (Middle): rootless / capabilities / read-only filesystem**
- **AppSec (Middle): OWASP Broken Access Control をアプリ実装で潰す**
- **Kubernetes Incident Drill (Middle): Deployment 失敗から rollback / recovery する演習**

### Middle に進む前提条件
- Linux 基本コマンドが使える
- YAML を怖がらず読める
- 「誰が・何に・何をできるか」を文章で説明できる
- `least privilege` を一言で説明できる

---

## 今日のひとこと
IAM は地味です。  
でも、実務では **一番コスパのいい防御** のひとつです。  
コードを書く人ほど、権限設計を「インフラ担当の仕事」で終わらせないほうが強いです。

小さく分ける。広く配らない。あとで困らない。  
この3つを今日の基準にしてください。
