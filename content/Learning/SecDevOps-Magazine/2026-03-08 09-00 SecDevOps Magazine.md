---
tags: [security, devops, docker, kubernetes, terraform, linux, cloudsecurity, observability, daily]
---

# 2026-03-08 09:00 SecDevOps Magazine
[[Home]]

#security #devops #docker #kubernetes #terraform #linux #cloudsecurity #observability #daily

## 今日の学習アーク
- **Arc A（Application Security）**: Beginner → Middle → Advanced
- **Arc B（DevOps Core）**: Beginner → Middle → Advanced
- **Arc C（Cloud Security / Observability / K8s Drill）**: Beginner → Middle → Advanced

> 今日の号は **Beginner**。次号で Middle、次々号で Advanced に進む前提で設計します。

---

## 1) Topic + Level
**Cloud Security 基礎: AWS/GCP IAM と Permission Design 入門（Beginner）**

---

## 2) Why it matters in real projects
本番インシデントの多くは「高度な0day」より、**権限の過剰付与（Over-Permission）** や **共有アカウント運用** から発生します。  
IAM設計を誤ると、1つの漏えいが環境全体へ横展開（lateral movement）しやすくなります。

- 開発速度を落とさずに安全性を上げるには、最初にIAMの粒度を整えるのが最短
- CI/CD、Terraform、Kubernetes運用の土台は最終的にすべて「誰が何をできるか」
- 監査対応（ISO/SOC2等）でも IAM 設計の説明責任が問われる

---

## 3) Core concepts（clear explanations）
### A. 認証(Authentication) と 認可(Authorization)
- **Authentication**: 「あなたは誰か」を確認
- **Authorization**: 「何をしてよいか」を決定

### B. Least Privilege（最小権限）
- 必要最小限の Action / Resource / Condition だけ許可
- 最初は狭く付与し、必要に応じて広げる（逆は事故を生みやすい）

### C. Role ベース設計
- ユーザーへ直接権限を大量付与しない
- 人・アプリ・CI に合わせて Role を分離

### D. Deny の活用と境界
- AWSでは明示DenyがAllowより優先
- GCPでは Principal + Role の組み合わせ管理が主軸
- 組織ポリシー（SCP / Org Policy）で“越えてはいけない線”を作る

### E. セッション管理の基本（AppSec接続）
- 一時クレデンシャル（STS等）を優先
- 長期固定キーを減らす
- ローテーション＋監査ログ（CloudTrail/Cloud Audit Logs）を前提にする

---

## 4) Hands-on mini lab（30-60 min）
**目的**: 「読み取り専用 + 特定バケットのみ」な安全な権限設計を体験する

### Lab シナリオ（AWS例）
1. IAM Policy を作成（`s3:GetObject` を `arn:aws:s3:::my-sec-lab-bucket/*` のみに限定）
2. IAM Role（`sec-lab-readonly-role`）を作成し、上記Policyをアタッチ
3. テスト用ユーザー/ロールから AssumeRole で一時クレデンシャル取得
4. 許可されたバケットは読めるが、他バケットは拒否されることを確認
5. CloudTrail で API 実行履歴を確認

### GCP置き換え（任意）
- Custom Role または predefined role（`roles/storage.objectViewer`）を使い、対象バケットにのみ binding
- `gcloud projects get-iam-policy` / `gcloud storage ls` で挙動確認

**完了条件**
- Allowed / Denied を説明できる
- その理由を Policy 文で示せる
- 監査ログで操作主体を追跡できる

---

## 5) Command cheatsheet
### Linux
```bash
# JSONを見やすく整形
cat policy.json | jq .

# 実行主体を確認
aws sts get-caller-identity
```

### AWS CLI
```bash
# ポリシー作成
aws iam create-policy \
  --policy-name SecLabS3ReadOnly \
  --policy-document file://policy.json

# ロール作成
aws iam create-role \
  --role-name sec-lab-readonly-role \
  --assume-role-policy-document file://trust-policy.json

# ロールにポリシー付与
aws iam attach-role-policy \
  --role-name sec-lab-readonly-role \
  --policy-arn arn:aws:iam::<ACCOUNT_ID>:policy/SecLabS3ReadOnly

# AssumeRole
aws sts assume-role \
  --role-arn arn:aws:iam::<ACCOUNT_ID>:role/sec-lab-readonly-role \
  --role-session-name sec-lab-session
```

### GCP CLI
```bash
# IAMポリシー確認
gcloud projects get-iam-policy <PROJECT_ID>

# バケット一覧（権限テスト）
gcloud storage ls
```

### Terraform（IAM定義の最小例）
```hcl
resource "aws_iam_policy" "sec_lab_readonly" {
  name   = "SecLabS3ReadOnly"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:GetObject"]
      Resource = ["arn:aws:s3:::my-sec-lab-bucket/*"]
    }]
  })
}
```

### Docker / Kubernetes（次回以降で接続）
```bash
# 予告: PodのServiceAccount確認（K8s×IAM接続の前提）
kubectl get sa -A
```

---

## 6) Common mistakes and how to avoid them
1. **`Action: *` / `Resource: *` を常用する**  
   - 回避: 最初に read-only で作り、必要な操作だけ追加

2. **人間ユーザーに長期アクセスキーを配り続ける**  
   - 回避: SSO + 一時クレデンシャル中心に移行

3. **本番/検証でRoleを共用する**  
   - 回避: 環境ごとにRole分離、タグ/命名規則を統一

4. **ログを有効化しただけで見ない**  
   - 回避: 週1で「Denyイベント」「高権限操作」を定期レビュー

5. **IaC外で手動変更してドリフト**  
   - 回避: Terraform plan をPRに必須化、変更理由を残す

---

## 7) One interview-style question
「`Least Privilege` を実現すると開発速度が落ちる、という主張にどう反論しますか？  
CI/CD と IaC の観点を含めて、実務的な運用設計を説明してください。」

---

## 8) Next-step reading links
- OWASP Top 10: https://owasp.org/www-project-top-ten/
- AWS IAM Best Practices: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- Google Cloud IAM Overview: https://cloud.google.com/iam/docs/overview
- Terraform IAM Patterns (HashiCorp docs): https://developer.hashicorp.com/terraform
- Kubernetes RBAC: https://kubernetes.io/docs/reference/access-authn-authz/rbac/
- OpenTelemetry Overview: https://opentelemetry.io/docs/concepts/

---

## 次号予告（Middleへの橋渡し）
次回は **Middle: CI/CD Security + Secrets Management 実践** を予定。

**Prerequisites（Middle）**
- IAMの基本用語（Principal / Role / Policy）を説明できる
- 最小権限ポリシーを1つ書ける
- CloudTrail または Audit Logs を1回確認した経験がある

その次は **Advanced: Kubernetes Incident Drill（failure/rollback/recovery）+ Observability（Prometheus/Grafana/OpenTelemetry）統合演習**。

**Prerequisites（Advanced）**
- Dockerfile の基本とイメージ最小化の意味を理解
- `kubectl` で Pod/Deployment の状態確認ができる
- Terraform plan/apply の基本フローを説明できる
