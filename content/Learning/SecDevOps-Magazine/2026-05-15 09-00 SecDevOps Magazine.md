---
tags: [security, devops, docker, kubernetes, terraform, linux, cloudsecurity, observability, daily]
---

[[Home]]

# SecDevOps Magazine — 2026-05-15

## 学習アーク情報
- **Issue Level:** Beginner
- **今回のテーマ:** Cloud Security（AWS/GCP IAM & permission design）
- **進行ルール:** Beginner → Middle → Advanced の順で反復
- **次回予告:** Middle（前提: IAM基本、最小権限、Policy評価ロジック）

---

## 1) Topic + Level
**Cloud Security（AWS/GCP IAM & Permission Design） / Beginner**

## 2) なぜ実務で重要か
クラウド事故の多くは「脆弱な暗号」より先に、**権限の過剰付与**や**ロール設計ミス**で起きます。  
たとえば「開発用ユーザーが本番S3を削除できる」「CI/CDトークンが管理者権限を持つ」などは、侵害時の被害を一気に拡大させます。  
IAM設計は“守りの土台”で、アプリセキュリティ・DevOps・監査対応すべてに直結します。

## 3) Core concepts（やさしく）
- **Principal（誰が）**: user / role / service account
- **Action（何を）**: 例 `s3:GetObject`, `ec2:StartInstances`
- **Resource（どこに）**: 例 特定バケット、特定プロジェクト
- **Condition（どんな条件で）**: IP、MFA、時間帯、タグなど
- **Least Privilege（最小権限）**: 必要最小限だけ許可
- **Deny優先**: 明示的DenyはAllowより強い
- **Role分離**: 人間操作用ロール、CI/CDロール、運用ロールを分離
- **監査ログ**: AWS CloudTrail / GCP Cloud Audit Logs で追跡可能に

## 4) Hands-on mini lab（30–60分）
**目的:** 「読取専用ロール」と「デプロイ専用ロール」を分離し、権限差を確認する。  
（ローカル実行中心。既存のテストAWS/GCPアカウントを使用）

### 手順（AWS例）
1. `ReadOnlyAppRole` を作成（S3一覧/読取のみ）
2. `DeployRole` を作成（ECR push と ECS更新のみ）
3. 各ロールに対して `aws sts assume-role` で一時認証
4. ReadOnlyロールで更新系コマンドを実行して失敗を確認
5. Deployロールで許可済み操作のみ成功することを確認
6. CloudTrailで実行イベントを確認

### 成功条件
- ReadOnlyロールで `PutObject` / `UpdateService` が拒否される
- Deployロールで必要なデプロイ操作のみ成功
- すべての操作が監査ログで追跡できる

## 5) Command cheatsheet
```bash
# AWS: 現在の実行主体確認
aws sts get-caller-identity

# AWS: ロール引受（例）
aws sts assume-role \
  --role-arn arn:aws:iam::<ACCOUNT_ID>:role/ReadOnlyAppRole \
  --role-session-name secdevops-lab

# 返却クレデンシャルを環境変数にセットして確認
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
export AWS_SESSION_TOKEN=...
aws s3 ls

# 誤って禁止操作を試す（拒否されるのが正解）
aws s3 cp ./test.txt s3://your-bucket/test.txt

# GCP: 現在主体とプロジェクト確認
gcloud auth list
gcloud config list project

# GCP: SA権限確認（閲覧）
gcloud projects get-iam-policy <PROJECT_ID>

# Linux: 実行ログを残す
history | tail -n 30
```

## 6) Common mistakes と回避策
- **ミス1: `*` 権限を早期に使う**  
  → まずReadOnlyから開始し、必要なActionをログから追加。
- **ミス2: 人とCI/CDで同じ資格情報を共有**  
  → ロールを分離し、短命トークン（STS/Workload Identity）を使う。
- **ミス3: 本番/開発の境界が曖昧**  
  → アカウント（またはプロジェクト）分離 + 明示Deny。
- **ミス4: 監査ログを見ない**  
  → 定例で CloudTrail / Audit Logs をレビューし、不要権限を削除。

## 7) Interview-style question
「CI/CDパイプラインに管理者権限を与えずに、デプロイを成立させるIAM設計を説明してください。必要な権限の切り出し方と、侵害時の被害最小化策まで述べてください。」

## 8) Next-step reading links
- OWASP Top 10: https://owasp.org/www-project-top-ten/
- AWS IAM Best Practices: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- GCP IAM Best Practices: https://cloud.google.com/iam/docs/using-iam-securely
- CloudTrail User Guide: https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-user-guide.html
- OpenTelemetry Docs: https://opentelemetry.io/docs/
- Kubernetes Security Checklist (CNCF): https://kubernetes.io/docs/concepts/security/

---

## ローテーション計画（固定トラック）
以下を日次で循環し、難易度は Beginner → Middle → Advanced を繰り返します。

1. Application Security（secure coding / OWASP / threat modeling / auth-session / IR）
2. DevOps Core（Docker hardening / Kubernetes fundamentals-security / Terraform-IaC / Linux / CI-CD security / secrets）
3. Cloud Security（AWS/GCP IAM & permission design）
4. Observability（Prometheus / Grafana / OpenTelemetry）
5. Kubernetes incident drills（failure / rollback / recovery）

> Middle/Advanced回では必ず前提条件（Prerequisites）を明記します。