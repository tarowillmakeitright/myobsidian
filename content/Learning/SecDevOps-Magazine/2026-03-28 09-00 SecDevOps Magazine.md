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

# SecDevOps Magazine — 2026-03-28

## 今日の学習アーク
- **アーク設計（反復）**: Beginner → Middle → Advanced を3日単位で循環
- **今回**: **Day 1 / Beginner**
- **次回予告**:
  - Day 2 (Middle): IAM権限境界 + Terraform Policy as Code（**前提**: IAM基本概念、Least Privilege）
  - Day 3 (Advanced): マルチクラウド権限監査 + CI/CD統合（**前提**: Middle内容 + Terraform実務経験）

---

## 1) Topic + Level
**Cloud Security: AWS/GCP IAM と Permission Design 入門**（**Beginner**）

---

## 2) なぜ実務で重要か
本番インシデントの多くは「コードのバグ」だけでなく、**権限設定ミス**から起きます。  
たとえば、
- 過剰な IAM 権限で誤操作が全環境に波及
- CI/CD 用トークンの権限が広すぎて、侵害時に被害拡大
- 監査ログの不足で「誰が何をしたか」追えない

つまり IAM 設計は、AppSec（防御）と DevOps（運用速度）を両立する土台です。

---

## 3) Core concepts（やさしく整理）
1. **Principal（誰）**
   - 人間ユーザー、サービスアカウント、CI ジョブなど
2. **Action（何を）**
   - `s3:GetObject`、`compute.instances.start` のような操作
3. **Resource（どれに）**
   - バケット、プロジェクト、特定のVMなど
4. **Effect（許可/拒否）**
   - Allow/Deny。原則は **Deny by default**
5. **Least Privilege**
   - 必要最小限のみ許可。ワイルドカード `*` は最後の手段
6. **Role-based access**
   - ユーザー直付けよりロール経由で管理（監査しやすい）
7. **短命クレデンシャル**
   - 長期キーを減らし、期限付きトークンを使う

> AppSec接点: 認証・セッション安全性（credential lifecycle）  
> DevOps接点: CI/CD, Terraform, secrets management に直結

---

## 4) Hands-on mini lab（30–60分）
**ラボ名: 「過剰権限を最小化する」**

### ゴール
- 既存の広すぎる権限を見つける
- 最小権限ポリシーを作る
- 変更後に業務が動くことを検証する

### 手順
1. （10分）テスト用 principal を1つ作成（例: `ci-readonly-test`）
2. （10分）最初はあえて広い権限（読み取り+書き込み）を付ける
3. （10分）アクセスログ/想定操作を確認して、必要操作を洗い出す
4. （15分）最小権限ポリシーへ縮小（不要 action 削除、resource を限定）
5. （10分）CI 想定コマンドを再実行し、成功/失敗を記録

### 完了条件
- 不要な操作は拒否される
- 必要な処理は成功する
- 変更前後の差分を説明できる

---

## 5) Command cheatsheet
### Linux
```bash
# 最近使った認証情報を確認（環境変数）
env | grep -E 'AWS|GOOGLE|GCP'

# 権限ファイルを検索
find . -type f | grep -E 'policy|iam|credentials|secret'
```

### AWS CLI（例）
```bash
# 現在の呼び出し主体を確認
aws sts get-caller-identity

# IAMロール一覧
aws iam list-roles --max-items 20

# ポリシーシミュレーション（許可可否を事前検証）
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::123456789012:role/ci-readonly-test \
  --action-names s3:GetObject s3:PutObject \
  --resource-arns arn:aws:s3:::example-bucket/*
```

### GCP CLI（例）
```bash
# 認証状態確認
gcloud auth list

# プロジェクトIAMポリシー確認
gcloud projects get-iam-policy <PROJECT_ID>

# サービスアカウント一覧
gcloud iam service-accounts list
```

### Terraform（IAM設計の土台）
```bash
# 構文/型チェック
terraform fmt -recursive
terraform validate

# 変更差分を可視化
terraform plan
```

---

## 6) Common mistakes と回避策
1. **`*` を多用する**
   - 回避: action と resource を具体化、段階的に削る
2. **人に直接権限を付与**
   - 回避: ロール中心設計 + グループ管理
3. **長期アクセスキー放置**
   - 回避: 短命トークン + ローテーション
4. **検証なしで本番反映**
   - 回避: `terraform plan`、policy simulation、ステージング確認
5. **監査ログを見ない**
   - 回避: CloudTrail / Cloud Audit Logs の定期レビュー

---

## 7) Interview-style question
「CI 用サービスアカウントにデプロイ権限が必要です。あなたなら **最小権限** をどう設計し、どう検証しますか？」

---

## 8) Next-step reading links
- OWASP Top 10: https://owasp.org/www-project-top-ten/
- AWS IAM Best Practices: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- Google Cloud IAM Overview: https://cloud.google.com/iam/docs/overview
- Terraform Security Best Practices (HashiCorp docs): https://developer.hashicorp.com/terraform
- CNCF Cloud Native Security Whitepaper: https://github.com/cncf/tag-security/tree/main/security-whitepaper
- OpenTelemetry Docs: https://opentelemetry.io/docs/
- Prometheus Docs: https://prometheus.io/docs/
- Grafana Docs: https://grafana.com/docs/

---

## ローテーション計画（固定トラックを回す）
- Application security: Secure Coding / OWASP / Threat Modeling / Auth-Session / Incident Response
- DevOps core: Docker Hardening / Kubernetes Security / Terraform IaC / Linux Mastery / CI-CD Security / Secrets Management
- Required add-ons: Cloud Security / Observability / Kubernetes Incident Drills

次号ではこの計画に沿って **Middle** 難易度に進みます。