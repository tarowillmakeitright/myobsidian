# 2026-03-26 SecDevOps Magazine
#security #devops #docker #kubernetes #terraform #linux #cloudsecurity #observability #daily
[[Home]]

> Daily Security & DevOps Magazine（実践・防御・合法学習のみ）
> 
> **学習アーク（3日サイクル）**: Beginner → Middle → Advanced
> - Day 1（今日）: Cloud Security / IAM設計（Beginner）
> - Day 2: Terraform + IAM最小権限の実装（Middle, 前提あり）
> - Day 3: K8s障害訓練 + 監査ログ相関分析（Advanced, 前提あり）

---

## 1) Topic + Level
**Cloud Security: AWS/GCP IAM と Permission設計の基礎**  
**Level: Beginner**

---

## 2) Why it matters in real projects
実プロジェクトのインシデントで最も多い原因の1つは、脆弱なアプリコードそのものだけでなく、**過剰権限（Over-permission）**です。  
たとえば「開発用ユーザーに本番S3削除権限が残っていた」「CIが`*`権限で動いていた」といった状態は、ミス操作や侵害時の被害を一気に拡大させます。  
IAMを正しく設計すると、以下を実現できます。
- 侵害されても被害範囲を限定（blast radius縮小）
- 監査対応（誰が何をしたか）を明確化
- DevOpsの自動化（CI/CD, Terraform）を安全に運用

---

## 3) Core concepts
- **Least Privilege（最小権限）**: 必要な操作だけ許可。`*`を避ける。
- **Role-based access**: 人間ユーザーよりRole（AWS IAM Role / GCP Service Account）中心で設計。
- **Separation of duties（職務分離）**: 開発・運用・監査の権限を分ける。
- **Deny by default**: 明示許可のみ有効にする考え方。
- **Temporary credentials**: 長期キーより短命トークン（STS, Workload Identity）優先。
- **Policy as Code**: Terraformなどで権限をコード管理し、レビュー可能にする。

> 次回Middle/Advancedへ進む前提: Linux基本コマンド、JSON/YAML読解、AWS/GCP CLIの初歩

---

## 4) Hands-on mini lab (30-60 min)
**ラボ名: 「読み取り専用 + 環境分離」のIAMを作る**

### 目標
- `dev`と`prod`のアクセス境界を分離
- 読み取り専用Roleを作成
- Terraformで再現可能な状態にする（最小構成）

### 手順（例: AWS）
1. `dev-app-readonly` Roleを作成（CloudWatch Logs, S3特定バケットのGet/Listのみ）
2. `prod`リソースへの`Delete*`/`Put*`を許可しない
3. CLIでAssumeRoleしてアクセス検証
4. CloudTrailで操作履歴を確認

### 成功条件
- `aws s3 ls s3://dev-logs-bucket` は成功
- `aws s3 rm s3://dev-logs-bucket/test.txt` は失敗（AccessDenied）
- CloudTrailで試行ログを確認できる

---

## 5) Command cheatsheet
```bash
# Linux 基本
whoami
id
env | grep -E 'AWS|GOOGLE'

# AWS CLI（例）
aws sts get-caller-identity
aws iam list-roles --max-items 20
aws s3 ls
aws cloudtrail lookup-events --max-results 10

# GCP CLI（例）
gcloud auth list
gcloud projects get-iam-policy <PROJECT_ID>
gcloud logging read "resource.type=gce_instance" --limit 10

# Terraform（最小）
terraform init
terraform fmt
terraform validate
terraform plan
```

---

## 6) Common mistakes and how to avoid them
- **ミス1: `Action: "*"`, `Resource: "*"` を常用**  
  → まずReadOnlyから開始し、必要操作をログから段階的に追加。
- **ミス2: 人間ユーザーに長期Access Keyを配布**  
  → SSO + 一時クレデンシャルへ移行。
- **ミス3: dev/prodで同じRoleを使う**  
  → 環境ごとにRole分離し、命名規則を固定（`<env>-<service>-<purpose>`）。
- **ミス4: 監査ログを見ない**  
  → CloudTrail / Cloud Loggingの定期レビューをCIのチェック項目へ。

---

## 7) One interview-style question
「あなたが新規プロジェクトのIAM設計担当なら、**最小権限**を維持しつつ開発速度を落とさないために、どの運用ルール（申請・レビュー・例外対応）を設計しますか？」

---

## 8) Next-step reading links
- OWASP Top 10: https://owasp.org/www-project-top-ten/
- AWS IAM Best Practices: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- Google Cloud IAM Overview: https://cloud.google.com/iam/docs/overview
- Terraform Security Best Practices (HashiCorp): https://developer.hashicorp.com/terraform/tutorials/security
- Kubernetes Security Checklist (CNCF): https://kubernetes.io/docs/concepts/security/
- OpenTelemetry Docs: https://opentelemetry.io/docs/

---

### ローテーション予告（次号以降）
- **Middle**: TerraformでIAMをコード化 + CI/CD Security Gate（tfsec/checkov）
- **Advanced**: Kubernetes incident drill（障害注入→rollback→recovery） + Observability（Prometheus/Grafana/OpenTelemetry）で事後分析

継続のコツは「毎日1ラボ、毎回1つの失敗を潰す」です。今日も着実にいきましょう。