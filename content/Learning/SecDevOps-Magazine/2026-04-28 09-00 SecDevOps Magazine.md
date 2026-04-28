# SecDevOps Magazine — 2026-04-28 09:00
#security #devops #docker #kubernetes #terraform #linux #cloudsecurity #observability #daily
[[Home]]

---

## 今日の学習アーク
- **Arc 1（Cloud Security）**: Beginner → Middle → Advanced
- 今日は **Day 3 / Advanced**
- **Prerequisites（この号の前提）**:
  - IAM Policy評価順（Explicit Deny / Allow / Implicit Deny）を説明できる
  - CI/CDロール分離（plan/apply）とPermission Boundaryの役割を理解している
  - `aws iam simulate-principal-policy` を使って許可/拒否の検証を行ったことがある
- 次アーク予告（Beginner）: **Observability（Prometheus/Grafana/OpenTelemetry）入門**

ローテーション対象（継続）:
- Application Security（OWASP, secure coding, threat modeling, auth/session, incident response）
- DevOps core（Docker hardening, Kubernetes security, Terraform/IaC, Linux, CI/CD security, secrets management）
- Added tracks（Cloud Security, Observability, Kubernetes incident drills）

---

## 1) Topic + Level
**Cloud Security（AWS/GCP）: クロスアカウント/クロスプロジェクト権限設計と緊急時アクセス統制**  
**Level: Advanced**

## 2) Why it matters in real projects
本番運用では、1つのアカウント/プロジェクトに全権限を集約すると、侵害時の被害が一気に拡大します。  
特にCI/CDトークン漏えいや過剰権限が発生したときに、
- 本番データへの横展開
- 監査不能（誰が何をしたか追えない）
- 緊急対応中の二次事故（強権限の誤操作）
が起きやすくなります。

**組織境界（AWS Organizations / GCP Folder）+ 最小権限 + 一時昇格（JIT）** を設計できると、速度を落とさず安全性を上げられます。

## 3) Core concepts（clear explanations）
- **Cross-account / Cross-project access**:
  - AWS: `AssumeRole` で作業主体を分離（開発→本番は直接不可）
  - GCP: Service Account Impersonation で直接キー配布を避ける
- **Guardrail層の分離**:
  - AWS: SCP（組織上限） + Permission Boundary（ロール上限） + IAM Policy（実行権限）
  - GCP: Org Policy（組織制約） + IAM Conditions（時間/属性条件）
- **Break-glass設計（緊急時アクセス）**:
  - 常時利用禁止、短時間のみ有効、MFA必須、利用理由の記録
  - 実行は必ず監査ログ（CloudTrail / Cloud Audit Logs）と紐づける
- **権限の“可視化”と“検証”**:
  - 付与したつもりの権限ではなく、実際に実行できる権限をシミュレーション/テストで確認

## 4) Hands-on mini lab（30-60 min）
**目標**: 「通常運用ロールは最小権限」「緊急時ロールはJIT + 監査必須」を実証する

### 手順
1. AWSで `prod-readonly-role`（通常用）と `prod-breakglass-role`（緊急用）を用意
2. `prod-breakglass-role` は以下の条件を追加
   - MFA必須
   - セッション時間を短く（例: 15〜30分）
   - チケットIDタグ（Session Tag）必須
3. OrganizationsのSCPで危険操作（例: `iam:*`, `organizations:LeaveOrganization`）を組織的に禁止
4. GCPで `viewer-sa`（通常）と `incident-admin-sa`（緊急）を分ける
5. `gcloud ... --impersonate-service-account` で通常/緊急の実行可否を検証
6. 監査ログで「誰が」「いつ」「なぜ」昇格したか追跡

### 完了条件
- 通常ロールでは破壊操作が拒否される
- 緊急ロールは条件（MFA/時間/タグ）を満たす時だけ許可
- ログから昇格理由（チケットID）を追える

## 5) Command cheatsheet（Linux/Docker/K8s/Terraform as relevant）
```bash
# AWS: 現在の実行主体確認
aws sts get-caller-identity

# AWS: AssumeRole（例）
aws sts assume-role \
  --role-arn arn:aws:iam::123456789012:role/prod-readonly-role \
  --role-session-name secdevops-lab

# AWS: ポリシーシミュレーション
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::123456789012:role/prod-readonly-role \
  --action-names s3:ListBucket ec2:TerminateInstances \
  --resource-arns '*'

# GCP: Impersonationで権限検証
gcloud auth list
gcloud projects get-iam-policy PROJECT_ID --format=json | jq '.bindings[] | {role, members}'
gcloud storage buckets list --impersonate-service-account=viewer-sa@PROJECT_ID.iam.gserviceaccount.com

# Terraform: IAM差分だけ先に確認
terraform init
terraform plan -target=aws_iam_role.prod_readonly -target=google_service_account.viewer_sa

# Linux: 監査ログの確認補助（JSON整形）
jq '. | {timestamp, eventName, userIdentity}' cloudtrail-sample.json
```

## 6) Common mistakes and how to avoid them
- **ミス1: 緊急ロールを常用してしまう**
  - 回避: 通常作業では使えない運用ルール + CIで検知
- **ミス2: AssumeRole/Impersonation条件が広すぎる**
  - 回避: Principal・時間・MFA・タグ条件を必須化
- **ミス3: Guardrailを1層しか使わない**
  - 回避: 組織上限（SCP/Org Policy）と実行権限（IAM）を分離
- **ミス4: ログは取っているが見ていない**
  - 回避: 週次で「昇格イベント一覧」をレビューし、不要権限を削る

## 7) One interview-style question
「AWSのSCP・Permission Boundary・IAM Policy、GCPのOrg Policy・IAM Conditionsを比較し、
“誤設定しても被害を最小化する多層防御設計”をどう実装しますか？」

## 8) Next-step reading links
- AWS IAM policy evaluation logic: https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_evaluation-logic.html
- AWS SCP examples: https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scps_examples.html
- AWS STS AssumeRole: https://docs.aws.amazon.com/STS/latest/APIReference/API_AssumeRole.html
- GCP IAM overview: https://cloud.google.com/iam/docs/overview
- GCP Service Account Impersonation: https://cloud.google.com/iam/docs/service-account-impersonation
- GCP Organization Policy: https://cloud.google.com/resource-manager/docs/organization-policy/overview
- Terraform IAM best practices (HashiCorp): https://developer.hashicorp.com/terraform/language

---

次号予告（Beginner）: **Observability入門 — メトリクス/ログ/トレースを1枚絵で理解する（Prometheus + Grafana + OpenTelemetry）**
