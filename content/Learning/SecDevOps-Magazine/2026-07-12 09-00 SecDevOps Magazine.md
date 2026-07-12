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
links:
  - "[[Home]]"
---

# SecDevOps Magazine — 2026-07-12

#security #devops #docker #kubernetes #terraform #linux #cloudsecurity #observability #daily

[[Home]]

今日は **Learning Arc 1 / Beginner**。
このマガジンは **Beginner → Middle → Advanced** の順で同じ学習アークを回しながら、Application Security と DevOps を往復して積み上げていく構成です。

- 今日の位置づけ: **Beginner**
- 今回のテーマ: **Cloud Security (AWS/GCP IAM & Permission Design)**
- 次に必要になる前提: Linux 基本操作、JSON/YAML の読み書き、クラウド上の principal / role / policy の概念

---

## 1) Topic + Level

**Cloud Security: IAM と Permission Design の基礎** — **Beginner**

---

## 2) Why it matters in real projects

現実の事故は、派手な 0day よりも **権限の広すぎる設定** から起きることが多いです。

たとえば:
- 開発用ユーザーに本番の管理者権限が残っている
- CI/CD の service account がストレージも秘密情報も全部読める
- Terraform 用ロールに `*:*` に近い権限が付いている
- 退職者や使われていない bot の credential が生きたまま

IAM 設計が甘いと、1つの credential 漏えいや 1つのアプリ脆弱性が **そのまま大きな侵害** に直結します。
逆に IAM が堅いと、侵害されても被害範囲を小さくできます。これは Application Security でも DevOps でも超重要です。

IAM は「面倒な管理作業」ではなく、**被害を局所化するための設計** です。

---

## 3) Core concepts

### 3-1. IAM の主役は「誰が」「何に」「どこまで」できるか

基本形は次の 3 つです。

- **Principal**: 誰が実行するのか
  - human user
  - role
  - service account
  - workload identity
- **Resource**: 何に対して操作するのか
  - S3 bucket
  - GCS bucket
  - Secret Manager
  - EC2 / GCE / KMS など
- **Action**: 何を許すのか
  - read
  - write
  - delete
  - assume role
  - decrypt

### 3-2. 最小権限 (Least Privilege)

**必要な操作だけ許す** という原則です。

悪い例:
- `AdministratorAccess` をとりあえず付ける
- `roles/editor` を広く配る
- 何の用途か分からない shared credential を長期運用する

良い例:
- 読み取りだけ必要なら read-only
- 特定バケットだけ必要ならその resource に限定
- 本番 deploy だけ必要なら deploy 用 role を分離

### 3-3. 人間の権限とマシンの権限を分ける

よくある失敗は、
- 人間のアカウントで自動化を回す
- bot に人間と同じ強い権限を与える

おすすめは:
- **human**: 短時間・監査しやすい権限、できれば role assume
- **CI/CD**: deploy 専用
- **app runtime**: 実行に必要な最低限
- **break-glass**: 緊急時だけ使う強権限

### 3-4. AWS と GCP の考え方のざっくり違い

#### AWS
- identity-based policy と resource-based policy がある
- role を `sts:AssumeRole` で切り替える設計が重要
- account / role / policy / permission boundary / SCP の組み合わせで守る

#### GCP
- principal に role を bind する考え方が中心
- project / folder / organization へ継承される
- `Owner` `Editor` `Viewer` を雑に使うと事故りやすい
- service account の権限設計と impersonation が重要

### 3-5. Permission Design の実務原則

1. **role を用途で分ける**
   - app-read
   - app-write
   - deploy
   - terraform-plan
   - terraform-apply

2. **環境を分ける**
   - dev
   - staging
   - prod

3. **永続 credential を減らす**
   - access key より role / workload identity
   - static secret より short-lived token

4. **監査しやすくする**
   - 誰が使う権限か名前で分かる
   - policy に用途が表れる
   - ログで追跡できる

5. **権限は追加より削減の方が難しい** と知る
   最初に雑に広げると、後から怖くて削れません。最初から小さく始めるのが正解です。

---

## 4) Hands-on mini lab (30-60 min)

### 目標
「広すぎる権限」と「用途別に絞った権限」の差を体感する。

### 30-60分ラボ: IAM 設計レビュー練習

#### パート A: サンプル権限を危険度で分類する
以下の 3 つを見て、どれが危ないかを判断します。

**Case 1: CI/CD bot**
- AWS: `AdministratorAccess`
- GCP: `roles/editor`

**Case 2: アプリ実行用**
- 特定の Secret 参照
- 特定 bucket への read のみ

**Case 3: Terraform apply 用**
- infra 作成に必要なサービスだけ
- prod では承認付き

考えるポイント:
- 誰が使うか
- 何に触れるか
- 侵害時にどこまで被害が出るか

#### パート B: policy を文章で設計する
コード不要。文章で OK。

次の 3 ロールを設計してください:

1. **app-runtime-role**
   - Secret 1個だけ読める
   - 特定 bucket を read-only
   - DB 管理操作は不可

2. **cicd-deploy-role**
   - staging へ deploy 可能
   - prod は不可
   - secret 全読みにしない

3. **security-audit-role**
   - 設定閲覧のみ
   - 変更不可
   - ログ確認可

書く項目:
- principal
- resource
- action
- 明示的に禁止したいこと

#### パート C: 1つだけ改善案を出す
今いる環境を想像して、次のどれか 1 つを選んで改善案を 3 行で書く。

- 開発者に本番権限が強すぎる
- CI/CD の secret 権限が広すぎる
- service account が使い回されている
- 監査ログから誰が何をしたか追えない

### 完了条件
- 少なくとも 3 ロールを用途別に説明できる
- `admin を配らない理由` を自分の言葉で言える
- 1つの改善案を文章で出せる

---

## 5) Command cheatsheet

今日は概念回だけど、実務でよく使う確認コマンドを置いておきます。

### Linux
```bash
whoami
id
env | sort
cat ~/.aws/config
cat ~/.aws/credentials
```

### AWS CLI
```bash
aws sts get-caller-identity
aws iam list-attached-user-policies --user-name <USER>
aws iam list-attached-role-policies --role-name <ROLE>
aws s3 ls
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::<ACCOUNT_ID>:role/<ROLE> \
  --action-names s3:GetObject \
  --resource-arns arn:aws:s3:::<BUCKET>/*
```

### GCP CLI
```bash
gcloud auth list
gcloud config list
gcloud projects get-iam-policy <PROJECT_ID>
gcloud iam service-accounts list
gcloud projects add-iam-policy-binding <PROJECT_ID> \
  --member="serviceAccount:<SA_EMAIL>" \
  --role="roles/viewer"
```

### Terraform
```bash
terraform init
terraform validate
terraform plan
terraform show
```

### Docker / Kubernetes とつながる観点
```bash
docker inspect <container>
kubectl get serviceaccounts -A
kubectl get roles,rolebindings,clusterroles,clusterrolebindings -A
kubectl auth can-i get secrets --as=system:serviceaccount:<ns>:<sa> -n <ns>
```

**ポイント:**
Kubernetes RBAC と Cloud IAM は別物ですが、現場では必ずつながります。Pod の service account とクラウド権限の橋渡しが事故ポイントです。

---

## 6) Common mistakes and how to avoid them

### ミス1: とりあえず admin を付ける
**回避策:**
最初は read-only か用途別 role から始める。必要が出たら足す。

### ミス2: dev/staging/prod で同じ権限を使う
**回避策:**
環境ごとに role を分ける。prod は別格にする。

### ミス3: CI/CD に secret 全部見せる
**回避策:**
deploy に必要な secret のみ参照可能にする。wildcard を避ける。

### ミス4: service account の使い回し
**回避策:**
アプリ・ジョブ・環境ごとに分ける。命名規則を作る。

### ミス5: 人間用 access key を長期放置
**回避策:**
role assume / SSO / short-lived credential へ移行する。

### ミス6: 監査ログを見ない
**回避策:**
CloudTrail / GCP Audit Logs を定期確認する。変更系 API を追える状態にする。

---

## 7) One interview-style question

**質問:**
「開発速度を落とさずに Least Privilege を実現するには、AWS または GCP でどんな role 設計をしますか？」

**考える観点:**
- human と machine の分離
- environment 分離
- read / deploy / admin の分割
- 一時的な昇格権限の扱い
- 監査可能性

---

## 8) Next-step reading links

- OWASP Cheat Sheet Series — Authorization Cheat Sheet  
  <https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Cheat_Sheet.html>
- AWS IAM Best Practices  
  <https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html>
- Google Cloud IAM Overview  
  <https://cloud.google.com/iam/docs/overview>
- Kubernetes RBAC  
  <https://kubernetes.io/docs/reference/access-authn-authz/rbac/>
- Terraform Security Best Practices (HashiCorp Learn / docs 起点)  
  <https://developer.hashicorp.com/terraform>

---

## 次号予告

次は **Middle** レベルとして、今日の前提を使って進みます。
候補:
- **CI/CD Security**: deploy 権限の分離と secret 注入設計
- **Secrets Management**: static secret を減らす設計
- **Kubernetes Fundamentals/Security**: service account / RBAC / workload identity の接続

### Middle に進む前提
- IAM の principal / action / resource を説明できる
- least privilege の意味を理解している
- human / CI/CD / app runtime の権限を分ける理由が分かる
