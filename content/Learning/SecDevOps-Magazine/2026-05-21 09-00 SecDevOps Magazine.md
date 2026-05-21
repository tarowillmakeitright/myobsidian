---
tags: [security, devops, docker, kubernetes, terraform, linux, cloudsecurity, observability, daily]
---

[[Home]]

# SecDevOps Magazine — 2026-05-21

## 1) Topic + Level
**Topic:** Cloud Security 入門 — AWS/GCP IAMとPermission Designの基本  
**Level:** **Beginner**

> 学習アーク: `Beginner → Middle → Advanced` の反復サイクル（Cloud Securityトラック第1回）

## 2) Why it matters in real projects
本番障害や情報漏えいの多くは、アプリのバグだけでなく**過剰権限（Over-privileged IAM）**から発生します。  
たとえば「CI/CD用ユーザーが本番DB削除までできる」「開発者ロールで全S3バケットを読める」などは、攻撃者にとって非常においしい入口です。

IAM設計を最初に固めると、以下が改善します。
- 侵害時の被害範囲を最小化（Blast Radius縮小）
- 監査対応（だれが何をできるか）を説明しやすい
- 運用ミスによる事故を減らせる

## 3) Core concepts
- **Principal**: 権限を持つ主体（User / Role / Service Account）
- **Policy**: 何を許可/拒否するかの定義
- **Least Privilege**: 必要最小限の権限のみ付与
- **Deny優先**: 明示DenyはAllowより強い（AWS/GCPとも実務上重要）
- **Separation of Duties**: 開発・デプロイ・監査権限を分離
- **Short-lived Credential**: 長期キーより一時的認証情報（STS, Workload Identity）

実務の鉄則:
1. 人間ユーザーに直接強権限を配らない（Role経由）
2. ワイルドカード `*` を常用しない
3. 条件（IP, 時間, リソースタグ）を活用する
4. 監査ログ（CloudTrail / Cloud Audit Logs）前提で設計する

## 4) Hands-on mini lab (30-60 min)
**目的:** 「読み取り専用ロール」と「誤った過剰権限」を比較し、最小権限設計の感覚を掴む。  
**所要時間:** 45分

### 手順（ローカル検証中心）
1. AWS IAM Policy Simulator（またはGCP IAM Troubleshooter）を開く
2. 次の2パターンを作る
   - A: `ReadOnly`に近い限定ポリシー
   - B: `Action: *` / `Resource: *` の過剰ポリシー
3. S3/GCSの「List」「Get」「Delete」操作をシミュレーション
4. どこまで許可されるかを比較し、差分をメモ
5. Aポリシーに条件（例: 特定バケットのみ）を追加して再テスト

### 完了条件
- 「必要操作だけ許可」のポリシーを1つ作成できる
- 過剰権限ポリシーの危険性を具体的に説明できる

## 5) Command cheatsheet
```bash
# Linux: 現在の認証情報確認（AWS CLI）
aws sts get-caller-identity

# 例: IAMロール一覧
aws iam list-roles --max-items 20

# 例: 特定ユーザーのアタッチ済みポリシー
aws iam list-attached-user-policies --user-name <USER_NAME>

# GCP: 現在のアカウント確認
gcloud auth list

# GCP: プロジェクトIAMバインディング確認
gcloud projects get-iam-policy <PROJECT_ID>

# Terraform: IAM関連変更の差分確認（適用前）
terraform plan

# Kubernetes: 現在コンテキスト確認（クラウド連携時の事故防止）
kubectl config current-context
```

## 6) Common mistakes and how to avoid them
- **ミス1: Admin権限を配りすぎる**  
  → 役割別Roleを作り、緊急時だけ昇格（break-glass）にする。

- **ミス2: 長期Access Keyを放置**  
  → ローテーション、自動失効、一時認証情報へ移行。

- **ミス3: リソース範囲未指定（`Resource: *`）**  
  → バケット名、プロジェクト、タグ条件でスコープを明示。

- **ミス4: 監査ログを見ない**  
  → CloudTrail / Cloud Audit Logsの定期レビューを運用に組み込む。

## 7) One interview-style question
「あなたが新規プロジェクトの最初のセキュリティ担当なら、開発速度を落とさずにLeast Privilegeをどう導入しますか？具体的なロール設計と運用フローを説明してください。」

## 8) Next-step reading links
- OWASP Top 10: https://owasp.org/www-project-top-ten/
- AWS IAM Best Practices: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- GCP IAM Overview: https://cloud.google.com/iam/docs/overview
- Terraform Security Best Practices (HashiCorp): https://developer.hashicorp.com/terraform/tutorials/configuration-language/sensitive-variables
- Kubernetes RBAC: https://kubernetes.io/docs/reference/access-authn-authz/rbac/
- OpenTelemetry Docs: https://opentelemetry.io/docs/

---

## Curriculum Progression Note
次号（Middle予定）では、今回のIAM基礎を前提に以下を扱います。
- **予定トピック:** CI/CD Security（OIDC連携で秘密鍵レス化）
- **Prerequisites（Middle）:**
  - Principal / Policy / Roleの違いを説明できる
  - Least Privilegeの設計意図を説明できる
  - `terraform plan` の差分読解ができる

Advanced号では、Kubernetes incident drills（障害注入→検知→rollback→復旧）に進みます。