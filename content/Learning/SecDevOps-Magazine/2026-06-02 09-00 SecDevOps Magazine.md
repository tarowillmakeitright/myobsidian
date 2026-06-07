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

# SecDevOps Magazine — 2026-06-02

**学習アーク:** Arc 1（Beginner → Middle → Advanced の3日サイクル）  
**本日のレベル:** **Beginner**  
**今日のテーマ:** **Cloud Security (AWS/GCP IAM) + アプリ運用に必要な最小権限設計の基礎**

---

## 1) Topic + Level
**Cloud Security: IAM と Permission Design の基本（Beginner）**

---

## 2) なぜ実務で重要か
本番事故の多くは「高度なゼロデイ」より先に、**権限の広すぎる設定**から起きます。  
例:
- CI/CD 用のキーが漏れて、全リソース削除まで可能だった
- 開発者ロールが本番DBへ直接アクセスできた
- 監査ログ閲覧ロールが書き込み権限まで持っていた

IAM は「守りの土台」です。ここが弱いと、アプリの secure coding を頑張っても被害範囲が一気に拡大します。

---

## 3) Core concepts（やさしく要点）

### A. Principle of Least Privilege（最小権限）
- 人/サービスには「今必要な操作だけ」を付与
- `*`（ワイルドカード）と `AdministratorAccess` を常用しない

### B. 認証（Authentication）と認可（Authorization）を分ける
- 認証: 誰かを確認する（MFA, OIDC, SSO）
- 認可: 何ができるか決める（IAM Policy, Role Binding）

### C. 長期鍵より短期クレデンシャル
- Access Key の固定運用はリスク大
- Role Assume / Workload Identity / OIDC Federation を優先

### D. Deny の価値
- AWS: `Explicit Deny` は `Allow` より優先
- GCP: Org Policy / IAM Conditions で「禁止」を先に置く設計が安全

### E. 監査可能性（Auditability）
- 「誰がいつ何をしたか」を追えること
- AWS CloudTrail / GCP Cloud Audit Logs は必須

---

## 4) Hands-on mini lab（30–60分）
**目的:** 「読み取り専用ロール」と「デプロイ専用ロール」を分け、過剰権限を削る練習

### 手順（ローカルで設計演習）
1. 2つの業務を定義
   - `viewer`: ログ・メトリクス確認だけ
   - `deployer`: コンテナ更新だけ（インフラ破壊は不可）
2. AWS/GCP それぞれで「許可アクション」を箇条書き
3. `危険アクション` を別リスト化（例: `iam:*`, `kms:ScheduleKeyDeletion`, `resourcemanager.projects.delete`）
4. Terraform の疑似ポリシーとして `.tf` に記述
5. 最後に自己レビュー:
   - 不要な `*` はないか？
   - 本番アクセスに MFA/条件付き制御を入れたか？
   - 監査ログが有効か？

> 余力があれば: AWS IAM Policy Simulator または GCP Policy Troubleshooter で想定アクセスを検証。

---

## 5) Command cheatsheet

### Linux
```bash
# 環境変数に鍵を直書きしない（確認のみ）
env | grep -Ei 'aws|gcp|google|key|secret'

# 権限ファイルのパーミッション確認
ls -l ~/.aws ~/.config/gcloud 2>/dev/null
```

### AWS CLI
```bash
# 現在の実行主体確認
aws sts get-caller-identity

# アタッチ済みポリシー確認（例）
aws iam list-attached-role-policies --role-name my-deployer-role

# ポリシーシミュレーション（例）
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::123456789012:role/my-deployer-role \
  --action-names ecr:GetAuthorizationToken ecs:UpdateService iam:CreateUser
```

### GCP CLI
```bash
# 現在のアカウントとプロジェクト確認
gcloud auth list
gcloud config list project

# プロジェクトIAM確認
gcloud projects get-iam-policy <PROJECT_ID>
```

### Terraform
```bash
# フォーマット＆静的チェック
terraform fmt -recursive
terraform validate

# 実行計画（差分確認）
terraform plan
```

---

## 6) Common mistakes と回避策

1. **最初から Admin 権限を配る**  
   - 回避: まず ReadOnly から開始、必要操作を監査ログで観測して追加

2. **人間ユーザーに長期鍵を発行し続ける**  
   - 回避: SSO + MFA + 短期トークンに移行

3. **CI/CD ロールが広すぎる**  
   - 回避: デプロイ対象（特定ECR/ECS/Artifact Registry/GKE Namespace）に限定

4. **Deny ルールがない**  
   - 回避: 破壊系アクションに Explicit Deny / Org Policy 制限を追加

5. **ログを取っているだけで見ていない**  
   - 回避: 週次レビュー項目を運用手順に組み込む

---

## 7) Interview-style question
「`deployer` ロールで本番反映は可能にしつつ、IAMユーザー作成やKMS削除は禁止したい。AWSならどのように Policy を分割し、どこで Explicit Deny を使いますか？」

---

## 8) Next-step reading links
- OWASP Top 10: https://owasp.org/www-project-top-ten/
- AWS IAM Best Practices: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- Google Cloud IAM overview: https://cloud.google.com/iam/docs/overview
- Terraform Security Best Practices (HashiCorp): https://developer.hashicorp.com/terraform/tutorials/security
- Kubernetes RBAC: https://kubernetes.io/docs/reference/access-authn-authz/rbac/

---

## 次号予告（Middle / 前提つき）
**予定テーマ:** CI/CD Security + Secrets Management（Middle）  
**前提知識:**
- IAM最小権限の基本（今日の内容）
- Docker image/build の基本
- YAML（GitHub Actions / GitLab CI）を読めること

「守る設計」を毎日1つ積むだけで、半年後の事故率は確実に下がります。今日もナイス積み上げ。