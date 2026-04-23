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

# SecDevOps Magazine — 2026-04-23

## 1) Topic + Level
**Topic:** Cloud Security（AWS/GCP IAM & Permission Design 入門）  
**Level:** **Beginner**  
**Learning Arc:** Arc 1（Beginner → Middle → Advanced の1周目開始）

---

## 2) Why it matters in real projects
IAM（Identity and Access Management）は、クラウド環境の「玄関の鍵」です。  
本番障害や情報漏えいの多くは、ゼロデイ攻撃よりも**過剰権限（Over-privileged Access）**や運用ミスから起きます。

- 開発者が `*:*` 権限を持っている
- CI/CD のサービスアカウントが本番全削除できる
- 退職者アカウントが残っている

こうした事故は、攻撃者が来る前に自分たちで防げる領域です。  
だからこそ、AppSecとDevOpsの共通基礎として IAM 設計は最優先です。

---

## 3) Core concepts（clear explanations）

### A. Principle of Least Privilege（最小権限）
「必要な操作だけ許可する」が基本。  
`AdministratorAccess` を配るのは速いですが、事故時の被害半径を最大化します。

### B. Identity と Role の分離
- **Human Identity**: 人間のログイン（SSO/MFA前提）
- **Workload Identity / Role**: アプリやCIが使う実行権限

人と機械の権限を混ぜないことで、監査・ローテーション・事故対応が楽になります。

### C. Deny by default + Explicit allow
何も許可しなければ拒否（default deny）。  
必要な操作だけ `Allow` し、危険操作は `Deny` で上書き防御を入れる。

### D. Permission boundary / policy layering
- AWS: IAM Policy + Permission Boundary + SCP
- GCP: IAM Role + Organization Policy

1枚のポリシーで完璧を狙わず、レイヤーで防御します。

### E. Auditability（追跡可能性）
- AWS CloudTrail
- GCP Audit Logs

「誰が、いつ、何をしたか」を残せない権限設計は、インシデント時に詰みます。

---

## 4) Hands-on mini lab（30–60 min）
**Lab:** 「CI/CD用ロールに“必要最小限”を与える」

### Goal
Terraform で「S3バケットへの読み書きのみ可能」な AWS IAM Role/Policy を作る。  
（発展: `iam:*` や `ec2:*` が不可能であることを確認）

### Steps
1. ローカルで作業ディレクトリ作成
2. Terraformで IAM Policy + Role を定義
3. `terraform plan` で差分確認
4. 過剰権限を含む悪い例（`Action="*"`）を比較
5. （可能なら）`aws iam simulate-principal-policy` で権限検証

### Minimal Terraform example
```hcl
resource "aws_iam_policy" "ci_s3_rw" {
  name   = "ci-s3-rw-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:ListBucket"]
        Resource = [
          "arn:aws:s3:::my-artifact-bucket",
          "arn:aws:s3:::my-artifact-bucket/*"
        ]
      }
    ]
  })
}
```

### Done条件
- 許可アクションが目的操作のみに限定されている
- `*` ワイルドカード濫用が除去されている
- 監査ログ有効化の確認メモを残している

---

## 5) Command cheatsheet
```bash
# Linux: 監査しやすい作業ログ
history | tail -n 30

# Terraform
terraform init
terraform fmt
terraform validate
terraform plan

# AWS IAM確認
aws iam list-policies --scope Local
aws iam get-policy --policy-arn <POLICY_ARN>
aws iam get-policy-version --policy-arn <POLICY_ARN> --version-id <VERSION>

# （可能なら）権限シミュレーション
aws iam simulate-principal-policy \
  --policy-source-arn <ROLE_ARN> \
  --action-names s3:PutObject iam:CreateUser \
  --resource-arns arn:aws:s3:::my-artifact-bucket/test.txt

# Docker/K8s 文脈での最小権限意識（次号への橋渡し）
docker run --read-only --cap-drop ALL nginx:alpine
kubectl auth can-i get pods --as=system:serviceaccount:default:app-sa -n default
```

---

## 6) Common mistakes and how to avoid them
1. **`Action: "*"` を暫定で入れて放置**  
   → 対策: 期限付きTODO化 + 48時間以内に権限分割。

2. **本番と開発で同じロール共有**  
   → 対策: 環境ごとにロール分離。`prod` は手動承認を要求。

3. **人間ユーザーに長期アクセスキー配布**  
   → 対策: SSO + 短期クレデンシャル + MFA。

4. **監査ログを見ない（有効化だけ）**  
   → 対策: 週次で異常権限イベントを1つ確認する運用を固定化。

---

## 7) One interview-style question
「あなたのチームで CI 用ロールに `AdministratorAccess` が付与されていました。  
デリバリー速度を落とさずに最小権限へ移行する計画を、段階的に説明してください。」

---

## 8) Next-step reading links
- OWASP Top 10: https://owasp.org/www-project-top-ten/  
- AWS IAM Best Practices: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html  
- GCP IAM Overview: https://cloud.google.com/iam/docs/overview  
- Terraform Security Best Practices (HashiCorp): https://developer.hashicorp.com/terraform/tutorials/cloud-get-started/cloud-security  
- Kubernetes RBAC: https://kubernetes.io/docs/reference/access-authn-authz/rbac/  
- OpenTelemetry Docs: https://opentelemetry.io/docs/

---

## 次号予告（Difficulty progression）
- **Middle（予定）:** Observability 基礎（Prometheus/Grafana/OpenTelemetry）で「検知できるシステム」を作る  
  - **Prerequisites:** Linux基本コマンド、HTTPステータス、コンテナ基礎
- **Advanced（予定）:** Kubernetes incident drill（failure/rollback/recovery）実戦演習  
  - **Prerequisites:** `kubectl` 基本、Deployment/ReplicaSet理解、ログ調査経験

小さく安全に、でも毎日確実に積み上げよう。今日の最小権限1つが、将来の重大事故を1つ減らします。
