---
tags: [security, devops, docker, kubernetes, terraform, linux, cloudsecurity, observability, daily]
---

# SecDevOps Magazine — 2026-05-16
[[Home]]

## 1) Topic + Level
**Cloud Security (AWS/GCP IAM & Permission Design) — Beginner**

---

## 2) Why it matters in real projects
クラウド事故の多くは、脆弱性そのものより **権限設計ミス** から起きます。  
たとえば「開発用ユーザーに本番削除権限がある」「CI/CDトークンが全リソースに管理者権限を持つ」といった状態は、
1回の認証情報漏えいで大規模インシデントに直結します。  
IAMを最初に正しく設計できると、**被害範囲（blast radius）を最小化** し、運用速度と安全性を両立できます。

---

## 3) Core concepts (clear explanations)
- **Principal（主体）**: 人間ユーザー、サービスアカウント、ロールなど「誰が」操作するか。
- **Action（操作）**: `s3:GetObject` や `compute.instances.get` のように「何を」するか。
- **Resource（対象）**: バケット、インスタンス、シークレットなど「どこに」対して行うか。
- **Condition（条件）**: IP、MFA有無、タグ、時間帯など「どの条件なら許可するか」。
- **Least Privilege（最小権限）**: 必要最小限だけ許可し、余計な権限を与えない原則。
- **Explicit Deny（明示的拒否）**: 許可より優先される拒否。ガードレールとして強力。
- **Role-based access**: 個人に直付けせず、役割（Role）に権限を集約して管理。

**初心者の最重要ポイント:**  
「とりあえず `Administrator`」を避け、**読み取り専用→必要に応じて追加** の順に設計する。

---

## 4) Hands-on mini lab (30-60 min)
**目的:** 「読み取り専用 + 限定的な追記権限」の感覚をつかむ

### Lab A (AWS IAM)
1. テスト用IAM UserまたはRoleを作成（本番アカウント不可、検証環境で実施）
2. `AmazonS3ReadOnlyAccess` を付与
3. S3一覧/取得はできるが削除できないことをCLIで確認
4. カスタムポリシーで特定バケットへの `PutObject` のみ追加
5. 他バケットに書き込みできないことを確認

### Lab B (GCP IAM)
1. テスト用ProjectでService Account作成
2. `roles/viewer` を付与
3. 読み取り可能・変更不可を確認
4. 特定リソースだけ `roles/storage.objectCreator` を追加
5. 書き込み先が限定されることを確認

> 余力があれば: 監査ログ（AWS CloudTrail / GCP Audit Logs）で「誰が何をしたか」を1件追跡する。

---

## 5) Command cheatsheet
```bash
# Linux: 現在の認証情報を確認
env | grep -E 'AWS|GOOGLE|GCP'

# AWS CLI
aws sts get-caller-identity
aws s3 ls
aws s3 cp ./sample.txt s3://your-allowed-bucket/path/sample.txt
aws s3 rm s3://your-allowed-bucket/path/sample.txt   # 拒否されるか確認

# GCP CLI
gcloud auth list
gcloud config list project
gsutil ls
gsutil cp ./sample.txt gs://your-allowed-bucket/path/sample.txt

# Terraform (IAMをIaC管理する前提)
terraform init
terraform plan
terraform apply
terraform show
```

---

## 6) Common mistakes and how to avoid them
1. **全員に強すぎる権限を配る**  
   - 回避: 職務ごとRole分離、最初はReadOnlyから。
2. **長期アクセスキーを放置**  
   - 回避: 可能な限りRole/Workload Identity利用、キー定期ローテーション。
3. **ワイルドカード `*` を多用**  
   - 回避: Action/Resourceを具体化、必要最小限に限定。
4. **本番と検証で同じ権限設計**  
   - 回避: 環境ごとに境界を分離し、事故時の影響を局所化。
5. **監査ログを見ない**  
   - 回避: 週次で「拒否イベント」「権限エラー」をレビューし改善。

---

## 7) One interview-style question
「CI/CDパイプライン用の資格情報が漏えいした場合、被害を最小化するIAM設計をどう作りますか？  
AWSまたはGCPの具体例で、Role設計・権限境界・監査の3点を説明してください。」

---

## 8) Next-step reading links
- OWASP Top 10: https://owasp.org/www-project-top-ten/
- AWS IAM Best Practices: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- GCP IAM Best Practices: https://cloud.google.com/iam/docs/best-practices
- Kubernetes RBAC: https://kubernetes.io/docs/reference/access-authn-authz/rbac/
- OpenTelemetry Docs: https://opentelemetry.io/docs/

---

## Difficulty progression note
このマガジンは **Beginner → Middle → Advanced** を循環する学習アークで進行します。  
次回（Middle予定）では、以下を前提に進みます：
- IAM基本概念（Principal / Action / Resource / Condition）を説明できる
- ReadOnlyと書き込み限定ポリシーの違いを理解している
- CLIで「許可される操作／拒否される操作」を検証した経験がある
