# 2026-03-14 09-00 SecDevOps Magazine
[[Home]]

#security #devops #docker #kubernetes #terraform #linux #cloudsecurity #observability #daily

---

## 今日のテーマ + Level
**Cloud Security（AWS/GCP IAM & Permission Design 入門） + Beginner**

> 学習アーク: **Beginner → Middle → Advanced** を繰り返し進行
> - 今号（B）: IAMの最小権限設計
> - 次号予定（M）: TerraformでIAMロール分離 + CI/CD連携（※Prereq: IAM基礎、Terraform basics）
> - 次々号予定（A）: マルチアカウント/組織設計 + 監査自動化（※Prereq: Policy評価ロジック、IaC運用経験）

---

## 1) なぜ実務で重要か
クラウド事故の多くは、コードの脆弱性そのものよりも、**権限の持ちすぎ（Over-privileged IAM）** で被害が拡大します。  
たとえば「本来S3の読み取りだけ必要なジョブ」が `AdministratorAccess` を持っていると、漏えい時に環境全体へ横展開されるリスクがあります。

IAM設計は、Application Security と DevOps の接点です。
- AppSec視点: 侵害後の被害最小化（blast radius削減）
- DevOps視点: 自動化しつつ安全に運用（再現可能な権限管理）

---

## 2) コア概念（わかりやすく）

### A. Principle of Least Privilege（最小権限の原則）
「必要な操作だけ」「必要なリソースだけ」「必要な時間だけ」を許可する。

### B. IAM Policyの3要素
- **Action**: 何をしてよいか（例: `s3:GetObject`）
- **Resource**: どこに対してか（例: `arn:aws:s3:::my-bucket/*`）
- **Condition**: どんな条件でか（例: 特定IP、MFA必須、タグ条件）

### C. Deny優先
明示的 `Deny` は `Allow` より強い。ガードレール設計に使う。

### D. Roleベース運用（Userキー直持ちを避ける）
- 人・アプリともに、可能なら長期アクセスキーより **Role + 一時クレデンシャル** を使う。
- CI/CDやKubernetes Workloadにもロール付与（IRSA / Workload Identity）を検討。

---

## 3) Hands-on Mini Lab（30〜60分）
**目的:** 「読み取り専用ロール」を作り、過剰権限との差を体験する。

### 手順（AWS例）
1. テスト用S3バケットを作成（例: `secdevops-lab-bucket`）
2. 読み取り専用Policyを作成（`s3:GetObject` のみ）
3. RoleにPolicyをアタッチ
4. Roleを引き受け（AssumeRole）して `aws s3 cp` を実行
5. 書き込み操作 `aws s3 rm` や `put-object` を試し、拒否されることを確認
6. CloudTrailで拒否イベントを確認（Observabilityにつなげる観点）

### 期待結果
- 読み取りは成功
- 書き込み/削除は `AccessDenied`
- 監査ログに操作履歴が残る

---

## 4) Command Cheatsheet

### Linux
```bash
# 現在の認証情報確認
env | grep -E 'AWS_|GOOGLE_'

# JSON整形（jqがある場合）
cat policy.json | jq .
```

### AWS CLI
```bash
# 自分のCaller Identity確認
aws sts get-caller-identity

# ポリシーシミュレーション（許可判定）
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::123456789012:role/SecDevOpsReadOnlyRole \
  --action-names s3:GetObject s3:PutObject \
  --resource-arns arn:aws:s3:::secdevops-lab-bucket/*
```

### GCP（参考）
```bash
# 現在のアカウントとプロジェクト
gcloud auth list
gcloud config list project

# IAMバインディング確認
gcloud projects get-iam-policy <PROJECT_ID>
```

### Terraform（参考断片）
```hcl
resource "aws_iam_policy" "s3_readonly" {
  name   = "secdevops-s3-readonly"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:GetObject"]
      Resource = ["arn:aws:s3:::secdevops-lab-bucket/*"]
    }]
  })
}
```

---

## 5) よくあるミス & 回避策
1. **とりあえず AdministratorAccess を付ける**  
   → まず業務フローを分解し、必要Actionを最小集合で定義。

2. **Resourceを `*` のまま放置**  
   → バケット/プロジェクト/Namespace単位でスコープを狭める。

3. **長期アクセスキーをCIに直書き**  
   → OIDC連携やRole Assumeで短命トークンに移行。

4. **拒否ログを見ない**  
   → CloudTrail / Cloud Logging をダッシュボード化し、誤設定を早期検知。

---

## 6) Interview-style Question
「本番で動くバッチがS3読み取りだけ必要なのに `s3:*` が付いています。  
ダウンタイムを最小化しながら最小権限へ移行する手順を説明してください。」

---

## 7) Next-step Reading
- OWASP: https://owasp.org/
- AWS IAM Best Practices: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- Google Cloud IAM Overview: https://cloud.google.com/iam/docs/overview
- Terraform IAM patterns: https://developer.hashicorp.com/terraform
- CNCF Cloud Native Security Whitepaper: https://github.com/cncf/tag-security

---

## ローテーション計画（トラック網羅）
以下を循環し、**Beginner → Middle → Advanced** の学習アークで反復:
- Application Security: secure coding / OWASP / threat modeling / auth-session / incident response
- DevOps Core: Docker hardening / Kubernetes fundamentals-security / Terraform-IaC / Linux command mastery / CI-CD security / secrets management
- Added (必須):
  1. Cloud Security（AWS/GCP IAM & Permission Design）
  2. Observability（Prometheus/Grafana/OpenTelemetry）
  3. Kubernetes incident drills（failure/rollback/recovery）

次回は **Middle: Observability（Prometheus + OpenTelemetryで“異常検知→原因追跡”）** を予定。