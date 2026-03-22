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

# SecDevOps Magazine — 2026-03-22

## 1) Topic + Level
**Topic:** Cloud Security 基礎 — AWS/GCP IAMで学ぶ「最小権限 (Least Privilege)」設計入門  
**Level:** **Beginner**（Learning Arc: Beginner → Middle → Advanced の1周目）

---

## 2) Why it matters in real projects
本番障害や情報漏えいの多くは、**「権限が広すぎる」**ことが引き金になります。  
たとえば CI/CD 用のサービスアカウントに `*` 権限を与えると、1つのトークン漏えいで環境全体が危険になります。

IAM 設計を最初から正しく行うと：
- 侵害時の被害範囲を最小化できる
- 監査対応（誰が何にアクセスできるか説明）が容易になる
- DevOps の自動化を安全にスケールできる

> このマガジンは**倫理的・防御的・合法的**な学習のみを扱います。攻撃手法の悪用は対象外です。

---

## 3) Core concepts（clear explanations）

### A. IAMの3要素
1. **Principal**（主体）: ユーザー、ロール、サービスアカウント
2. **Action**（操作）: `s3:GetObject`, `ec2:DescribeInstances` など
3. **Resource**（対象）: バケット、VM、Secret など

IAMは基本的に「誰が」「何を」「どこまで」できるかを明示します。

### B. 最小権限 (Least Privilege)
- 必要な操作のみ許可する
- 必要なリソースに限定する
- 必要な時間だけ有効にする（短命トークン、期限付き資格情報）

### C. Deny by Default
- 明示許可がない限り拒否
- 例外ルールを増やしすぎない

### D. Role分離（職務分離）
- 人間用ロール（運用者）と機械用ロール（CI/CD）を分離
- 読み取り専用、デプロイ専用、監査専用など用途を分ける

### E. IaCでIAMを管理
Terraform などで権限をコード化すると、
- 変更レビュー可能
- 差分が追える
- 再現性が高い

---

## 4) Hands-on mini lab（30-60 min）
**Goal:** Terraformで「過剰権限」から「最小権限」へ改善する練習

### 事前準備
- Terraform CLI
- AWS CLI または GCP CLI（どちらか）
- テスト用アカウント（本番禁止）

### 手順
1. `iam-lab/` ディレクトリを作成
2. 最初に“わざと広すぎる”ポリシーを定義（例: 読み書き全許可）
3. `terraform plan` で内容確認
4. 実運用想定に合わせてアクションを絞る（例: 読み取りのみ）
5. リソース対象を絞る（特定バケット/プロジェクトのみ）
6. 再度 `terraform plan` で差分確認
7. 変更理由を `README.md` に記録（監査ログの練習）

### サンプル（AWS風・概念）
```hcl
# 悪い例（広すぎ）
# Action = ["s3:*"]
# Resource = ["*"]

# 改善例（読み取り限定）
Statement = [{
  Effect = "Allow"
  Action = [
    "s3:GetObject",
    "s3:ListBucket"
  ]
  Resource = [
    "arn:aws:s3:::team-artifacts",
    "arn:aws:s3:::team-artifacts/*"
  ]
}]
```

**完了条件（Done）**
- 「誰が」「何を」「どこまで」が説明できる
- `*` 権限が消えている
- 変更理由を文章化できている

---

## 5) Command cheatsheet
```bash
# Linux: 現在の資格情報や環境変数確認
env | grep -E 'AWS|GOOGLE|KUBE|TF_' 

# Terraform
terraform init
terraform fmt
terraform validate
terraform plan

# AWS (例)
aws sts get-caller-identity
aws iam list-roles --max-items 20

# GCP (例)
gcloud auth list
gcloud projects get-iam-policy <PROJECT_ID>

# Kubernetes (権限確認の入口)
kubectl auth can-i get pods -n default
kubectl auth can-i create deployments -n prod

# Docker (参考: 実行権限の確認)
docker info | grep -i root
```

---

## 6) Common mistakes and how to avoid them
1. **`Action: *` を使う**  
   → まず必要操作を3つ以内で仮置きし、足りない分だけ追加

2. **人間とCI/CDで同じ権限を共有**  
   → ロールを分離し、トークン寿命を短くする

3. **本番で直接検証する**  
   → 検証環境 + `plan` レビュー + ペアレビューを徹底

4. **ポリシー更新理由を残さない**  
   → PR本文に「何を減らしたか」「なぜ必要か」を必ず記載

5. **秘密情報を平文で管理**  
   → Secrets Manager / Secret Manager / Vault を利用

---

## 7) One interview-style question
「CI/CD用ロールに最小権限を適用するとデプロイ失敗が増える場合、セキュリティを落とさずに運用性を改善するにはどう設計しますか？」

---

## 8) Next-step reading links
- OWASP Top 10: https://owasp.org/www-project-top-ten/
- AWS IAM Best Practices: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- Google Cloud IAM Overview: https://cloud.google.com/iam/docs/overview
- Terraform Security Best Practices (HashiCorp docs): https://developer.hashicorp.com/terraform
- Kubernetes RBAC: https://kubernetes.io/docs/reference/access-authn-authz/rbac/
- OpenTelemetry Docs（Observability導入の次ステップ）: https://opentelemetry.io/docs/

---

## Difficulty progression note（for upcoming issues）
- **Today:** Beginner（IAM最小権限の基礎）
- **Next (Middle) prerequisite:**
  - IAMの基本要素（Principal/Action/Resource）を説明できる
  - Terraform `plan` と `validate` を実行できる
- **Later (Advanced) prerequisite:**
  - CI/CDロール分離を実装済み
  - 監査ログ（CloudTrail / Cloud Audit Logs）の基礎理解

次号では Middle として、**CI/CD Secrets Management + OIDC連携**を扱います。