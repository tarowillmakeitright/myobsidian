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

# SecDevOps Magazine — 2026-06-21

今日の号は **Beginner** レベルです。  
学習アークの入口として、まずは **Cloud Security の IAM 設計** をテーマにします。  
次の Middle / Advanced 回では、この基礎を前提に「権限の分離」「CI/CD への接続」「インシデント時の権限見直し」へ進めます。

## 1) Topic + Level

**Cloud Security (AWS/GCP IAM & permission design) + Beginner**

---

## 2) Why it matters in real projects

実務では、アプリの脆弱性そのものよりも **「権限が強すぎる」ことが事故を大きくする** 場面が本当に多いです。

たとえば：

- CI/CD 用のトークンに本番環境のフル権限が付いている
- 開発者アカウントがそのまま本番 DB や Secret に触れる
- Kubernetes や Terraform から使うクラウド権限が広すぎる
- 退職・異動後の権限整理が甘く、不要なアクセスが残る

こういう状態だと、1つのミスや侵害が **全面的な被害** に変わります。  
逆に IAM 設計が良いと、事故は局所化され、調査も復旧も速くなります。

**Application Security と DevOps の接点**としても重要です。  
安全なコードを書いても、実行基盤の IAM が雑なら守りは崩れます。だから IAM は「クラウド運用の設定」ではなく、**プロダクト防御の一部**です。

---

## 3) Core concepts (clear explanations)

### 3-1. IAM は「誰が」「何に」「何をできるか」

基本はこの3つです。

- **Principal**: 誰か（ユーザー、ロール、サービスアカウント、ワークロード）
- **Resource**: 何に対して（S3 bucket, GCS bucket, Secret, VM, KMS key など）
- **Action**: 何をするか（read, write, delete, assume role, decrypt など）

IAM 設計は、ざっくり言うと：

> 必要な主体に、必要な対象へ、必要最小限の操作だけを与える

これが核です。

### 3-2. Least Privilege（最小権限）

最重要原則です。

- `*` を避ける
- admin 権限を常用しない
- 読み取り専用と変更権限を分ける
- 人間用権限と機械用権限を分ける

最初から完璧に細かくする必要はありません。  
でも「とりあえず広く付ける」は後で確実に負債になります。

### 3-3. Human と Workload を分ける

権限設計では、**人の操作**と**システムの自動処理**を混ぜないのが大切です。

- **Human**: 開発者、SRE、監査担当
- **Workload**: GitHub Actions, GitLab CI, Terraform, アプリ本体, Kubernetes Pod

人間はレビューや緊急対応が必要。  
ワークロードは限定目的で機械的に動く。  
この2つを同じ強い権限で扱うと、追跡も制御も壊れます。

### 3-4. Role ベースで考える

個人に直接バラバラの権限を貼るより、**Role / Group / Service Account** 単位で設計すると管理しやすいです。

例：

- `developers-readonly`
- `deploy-ci-staging`
- `deploy-ci-production`
- `terraform-network-admin`
- `incident-response-readonly`

この粒度で分けると、誰が何を持つべきか説明しやすくなります。

### 3-5. 環境分離は超重要

最低限でも以下は分けたいです。

- dev
- staging
- production

理想は権限もアカウント/プロジェクトも分離です。

- AWS: account / role / policy を分離
- GCP: project / service account / IAM binding を分離

**本番だけ特別に厳しくする** のは基本中の基本です。

### 3-6. Temporary Credentials を使う

長寿命キーを配りまくる運用は危険です。

できるだけ：

- AWS IAM Role / STS
- GCP Workload Identity / short-lived credentials
- OIDC federated access（CI/CD からクラウドへ）

を使って、**短命な認証情報**へ寄せます。

これは Secrets Management とも強くつながります。

### 3-7. Auditability（追跡可能性）

IAM は「許可する」だけでなく、**あとで追えること**も重要です。

- 誰がロールを使ったか
- いつ権限変更されたか
- どのワークロードが Secret を読んだか

そのために CloudTrail / GCP Audit Logs / Terraform state 管理 / Git レビューが効いてきます。

---

## 4) Hands-on mini lab (30-60 min)

### ラボの目的

「広すぎる権限」と「用途別に分けた権限」の差を、手で確認します。

### 前提

- AWS または GCP の学習用環境がある
- CLI が使える
- 本番環境ではなく、必ず検証用で行う

### パターンA: AWS でやる

#### 目標

- `app-readonly-role`
- `app-secret-reader-role`

の2つを分けて考える。

#### 手順

1. 読み取り専用の責務を定義する
   - 例: 特定 S3 bucket の一覧と取得のみ
2. Secret 読み取り専用の責務を定義する
   - 例: 特定 Secrets Manager secret の `GetSecretValue` のみ
3. 両者を混ぜない
4. 各 role に対して「できること / できないこと」を CLI で確認する
5. 最後に「もし CI/CD がこの role を盗まれたら被害はどこまでか？」を書き出す

#### 観察ポイント

- S3 読み取り role では Secret を読めないか
- Secret 読み取り role では bucket 全体を列挙できないか
- resource を `*` にしたくなる誘惑に気づけるか

### パターンB: GCP でやる

#### 目標

- viewer 系権限
- Secret Manager アクセス権限

を分離して確認する。

#### 手順

1. 学習用 project を用意する
2. Service Account を2つ作る
   - `sa-app-viewer`
   - `sa-secret-reader`
3. それぞれに異なる最小権限 role を付与する
4. `gcloud` でアクセス検証する
5. 「この Service Account を Pod や CI に渡したら何が起きるか」をメモする

### ラボのまとめメモ

最後に以下を書いて終えると理解が深まります。

- どの主体に何を許可したか
- どのリソースまでを対象にしたか
- 何を明示的に禁止または未許可にしたか
- 侵害された場合の被害範囲

---

## 5) Command cheatsheet (Linux/Docker/K8s/Terraform as relevant)

### Linux

```bash
# 現在の認証情報や環境変数の確認
env | grep -E 'AWS|GCP|GOOGLE|KUBE'

# 設定ファイルの確認
ls -la ~/.aws
ls -la ~/.config/gcloud

# jq で JSON を見やすくする
cat policy.json | jq .
```

### AWS CLI

```bash
# 現在の caller identity 確認
aws sts get-caller-identity

# S3 bucket 一覧（許可されていれば）
aws s3 ls

# 特定 Secret の取得（許可が必要）
aws secretsmanager get-secret-value \
  --secret-id my-app-secret

# IAM role 一覧（権限が必要）
aws iam list-roles
```

### GCP CLI

```bash
# 現在の認証主体を確認
gcloud auth list

gcloud config list

# Project 一覧
gcloud projects list

# Secret 一覧（許可が必要）
gcloud secrets list

# IAM policy 確認
gcloud projects get-iam-policy PROJECT_ID
```

### Kubernetes 関連の視点

```bash
# どの service account で Pod が動くか確認
kubectl get pod POD_NAME -o yaml | grep serviceAccountName

# service account 一覧
kubectl get sa

# RBAC 確認
kubectl get role,rolebinding,clusterrole,clusterrolebinding
```

### Terraform

```bash
# フォーマット
terraform fmt

# 構文・基本検証
terraform validate

# 差分確認
terraform plan

# IAM 系リソースを grep
grep -R "iam" .
grep -R "role" .
grep -R "policy" .
```

### Docker / CI の観点

```bash
# GitHub Actions などで環境変数が露出していないか確認
env | sort

# Dockerfile の確認（認証情報ベタ書きがないか）
grep -nE 'AWS_|GCP_|SECRET|TOKEN|PASSWORD' Dockerfile .env .github/workflows/* 2>/dev/null
```

---

## 6) Common mistakes and how to avoid them

### ミス1: `AdministratorAccess` を常用する

**問題:** 速いけど危険。事故の半径が大きすぎる。  
**回避:** 学習用でも role を分ける癖をつける。緊急時だけ昇格、常用しない。

### ミス2: 人間と CI/CD が同じ権限を使う

**問題:** 監査しにくいし、漏えい時の切り分けも難しい。  
**回避:** Human role と machine role を必ず分離する。

### ミス3: Resource を `*` にする

**問題:** 対象範囲が広すぎる。  
**回避:** bucket 名、secret 名、project、namespace などでできるだけ絞る。

### ミス4: 長寿命アクセスキーを放置する

**問題:** 漏れたら長期間悪用される。  
**回避:** OIDC、STS、Workload Identity、短命 credential を優先する。

### ミス5: Terraform で IAM を増やしたのにレビューが弱い

**問題:** IaC なのに権限追加が見逃される。  
**回避:** PR テンプレートに「誰へ何の権限を増やすか」を書かせる。

### ミス6: Kubernetes RBAC と Cloud IAM を別物として考える

**問題:** Pod → ServiceAccount → Cloud 権限の連鎖を見落とす。  
**回避:** K8s 側の権限とクラウド側権限をセットでレビューする。

---

## 7) One interview-style question

**質問:**  
「CI/CD パイプラインが本番環境へデプロイする必要があります。AWS または GCP 上で、なぜ人間の管理者権限をそのまま CI に流用してはいけないのか？ 代わりにどんな権限設計にするべきか説明してください。」

**考えるポイント:**

- 最小権限
- 監査性
- 一時クレデンシャル
- 環境分離
- 侵害時の被害半径

---

## 8) Next-step reading links

- OWASP Cheat Sheet Series  
  <https://cheatsheetseries.owasp.org/>
- AWS IAM Best Practices  
  <https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html>
- Google Cloud IAM Overview  
  <https://cloud.google.com/iam/docs/overview>
- Google Cloud Security Best Practices  
  <https://cloud.google.com/security/best-practices>
- Kubernetes RBAC Documentation  
  <https://kubernetes.io/docs/reference/access-authn-authz/rbac/>
- Terraform Recommended Practices  
  <https://developer.hashicorp.com/terraform/tutorials/configuration-language>
- OWASP Top 10  
  <https://owasp.org/www-project-top-ten/>

---

## 学習アークメモ

- **今日:** Beginner — Cloud Security / IAM 基礎
- **次回候補 (Middle):** CI/CD と OIDC 連携、Terraform での IAM 設計、Secrets 境界設計
- **その次 (Advanced):** クロスアカウント権限、権限棚卸しの自動化、侵害後の権限封じ込め

### Prerequisites

**Middle に進む前提:**

- IAM の基本用語（principal / resource / action）が分かる
- 最小権限の意味を説明できる
- AWS CLI または gcloud で現在の認証主体を確認できる

**Advanced に進む前提:**

- role/service account の分離設計ができる
- CI/CD 用権限と人間用権限を分ける理由を説明できる
- Terraform plan や IAM policy 差分をレビューできる

---

今日の一言：  
**強い権限は便利だけど、便利さはだいたい後で請求が来ます。**  
まずは「必要なものだけ許可する」設計感覚を育てていきましょう。
