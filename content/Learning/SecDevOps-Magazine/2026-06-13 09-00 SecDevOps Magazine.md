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

# SecDevOps Magazine — 2026-06-13

## 今日のテーマ + レベル
**Cloud Security: IAM Permission Design の基本** — **Beginner**

> 学習アーク: Cloud Security 基礎編の第1回。次回以降で **Middle → Advanced** に進みます。

---

## 1) なぜ実務で重要か
クラウド事故のかなりの割合は、ゼロデイよりも**権限の広すぎる設定**や**ロール設計ミス**で起きます。AWS/GCP では、アプリ・CI/CD・運用者・監視ツールがそれぞれ別の権限を持つため、IAM を雑に設計すると次のような問題が起きます。

- 開発者用の権限が本番削除までできてしまう
- CI が secrets や artifact を不必要に読み取れる
- 侵害された 1 つのアカウントから横展開される
- 監査時に「誰が何をできるか」を説明できない

つまり IAM は、クラウド時代の**最前線の防御線**です。アプリケーションセキュリティと DevOps の両方に直結します。

---

## 2) Core concepts

### Least Privilege
必要最小限の権限だけを与える考え方です。

- できることを最小化する
- 使える対象リソースを絞る
- 実行できる時間・経路・条件を必要に応じて制限する

**悪い例:** `AdministratorAccess` をとりあえず付与する  
**良い例:** `s3:GetObject` を特定バケットの特定 prefix に限定する

### Identity と Role を分けて考える
IAM 設計では、まず「**誰/何が動くのか**」を整理します。

- Human user / group
- Application workload
- CI/CD runner
- Monitoring / backup / incident response tool

そのうえで、「その主体は何をする必要があるか」を role/policy に落とします。

### Action / Resource / Condition
IAM Policy はだいたい次の 3 要素で読むと理解しやすいです。

- **Action**: 何ができるか
- **Resource**: どの対象に対してか
- **Condition**: どんな条件なら許可されるか

この 3 つを曖昧にすると、すぐに過剰権限になります。

### AWS と GCP の見方

#### AWS
主に以下の要素で考えます。
- IAM User / Group / Role
- Policy (JSON)
- AssumeRole
- Managed Policy と Inline Policy

現場では **User より Role 中心** に寄せるのが一般的です。

#### GCP
主に以下の要素で考えます。
- Principal（user / service account / group）
- Role
- IAM binding
- Project / Folder / Organization 単位の継承

現場では **Service Account の使い分け** と **権限継承の把握** が重要です。

### セキュリティ設計の基本パターン
- 人間と機械の権限を分離する
- 開発/本番を分離する
- 読み取り専用ロールをまず作る
- CI/CD には deploy に必要な最小権限のみ与える
- break-glass（緊急管理者権限）は常用しない

---

## 3) Hands-on mini lab（30–60分）
**ラボ名:** IAM の過剰権限を見つけて縮小する

### 目的
「全部許可」から始めず、必要な操作だけを列挙して権限を絞る練習をします。

### 前提
- AWS または GCP の学習用アカウント
- 課金や本番影響のない sandbox 環境
- CLI が使えること

### 進め方（AWS 例）
1. 学習用 role を 2 つ考える
   - `app-reader`
   - `ci-deployer`
2. `app-reader` に必要な操作だけを書き出す
   - 例: S3 オブジェクト参照、CloudWatch Logs 読み取り
3. `ci-deployer` に必要な操作だけを書き出す
   - 例: ECR push、ECS 更新、Parameter Store の限定参照
4. まず「必要そうな操作の一覧」を文章で作る
5. その後 JSON policy に落とす
6. `*` が残っていないか確認する
7. 実際に CLI 実行し、足りない permission が出たら**追加しすぎず最小差分で修正**する

### 進め方（GCP 例）
1. Service Account を用途別に 2 つ想定する
   - `sa-app-read`
   - `sa-ci-deploy`
2. 既存の broad role を避け、できるだけ用途に近い role を検討する
3. Project 全体ではなく、必要なスコープを意識する
4. 何を bind したか記録する
5. 「本当にその SA がその操作を必要としているか」を見直す

### ラボのゴール
以下を説明できれば成功です。
- なぜその権限が必要か
- どの resource に限定したか
- 将来どこが権限肥大化ポイントになるか

---

## 4) Command cheatsheet

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
aws iam list-roles
aws iam get-role --role-name app-reader
aws iam list-attached-role-policies --role-name app-reader
aws iam get-policy --policy-arn <POLICY_ARN>
aws iam get-policy-version --policy-arn <POLICY_ARN> --version-id v1
```

### GCP CLI
```bash
gcloud auth list
gcloud config list
gcloud projects list
gcloud iam service-accounts list
gcloud projects get-iam-policy <PROJECT_ID>
```

### Terraform（IAM をコード化する入口）
```bash
terraform init
terraform fmt
terraform validate
terraform plan
```

### Docker / K8s（CI/CD 文脈を意識）
```bash
docker login
docker build -t demo-app:latest .
kubectl config get-contexts
kubectl auth can-i get pods
```

---

## 5) Common mistakes and how to avoid them

### ミス1: `*` を雑に使う
**問題:** resource/action の両方が広がりすぎる  
**回避:** 最初に「必要操作一覧」を作ってから policy 化する

### ミス2: 人間と CI の権限を共有する
**問題:** 侵害時の影響範囲が大きくなる  
**回避:** Human / workload / CI 用 principal を分ける

### ミス3: 本番と開発で同じ role を使う
**問題:** 開発経路から本番事故につながる  
**回避:** 環境別 role・account/project 分離を前提にする

### ミス4: 権限追加の理由を記録しない
**問題:** 後で削れず、肥大化し続ける  
**回避:** policy 追加時に「誰の、何のためか」をメモする

### ミス5: managed policy を丸ごと信頼する
**問題:** 思ったより広い permission を含むことがある  
**回避:** 中身を読む。特に本番 deploy 系は必ず確認する

---

## 6) One interview-style question
**質問:**  
「CI/CD パイプラインに本番 deploy 権限を与えるとき、`AdministratorAccess` を避けつつ、どうやって最小権限で設計しますか？」

**考えるポイント:**
- デプロイ対象サービスは何か
- 読み取りが必要な secrets / registry / artifact は何か
- 書き込み対象 resource はどこまでか
- 人間の承認フローと機械の実行権限をどう分けるか

---

## 7) Next-step reading links
- OWASP Top 10: https://owasp.org/www-project-top-ten/
- AWS IAM Best Practices: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- AWS Policy evaluation logic: https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_evaluation-logic.html
- Google Cloud IAM overview: https://cloud.google.com/iam/docs/overview
- Google Cloud best practices for access control: https://cloud.google.com/iam/docs/using-iam-securely
- Terraform IAM patterns (HashiCorp docs hub): https://developer.hashicorp.com/terraform
- Kubernetes RBAC: https://kubernetes.io/docs/reference/access-authn-authz/rbac/

---

## 学習メモ
- 今日の号は **Beginner**。
- 次の Cloud Security 回で **Middle** に進めるなら、前提として以下を満たしておくと良いです。
  - AWS/GCP の基本用語がわかる
  - CLI で現在の identity を確認できる
  - least privilege の考え方を説明できる

### 次回予告
**Cloud Security: IAM Permission Boundary / Role Separation の実践** — **Middle**  
前提: 今日の内容（least privilege / principal 分離 / action-resource-condition の理解）

---

技術は「全部知ること」より、**危ない広さを見抜いて少しずつ狭める力**が大事です。  
今日の 30 分で、まずは「この権限、本当に必要？」と問い返せる目を作っていきましょう。
