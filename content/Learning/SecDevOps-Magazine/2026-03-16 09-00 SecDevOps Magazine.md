# 2026-03-16 SecDevOps Magazine
#security #devops #docker #kubernetes #terraform #linux #cloudsecurity #observability #daily
[[Home]]

おはようございます！今日のテーマは **Cloud Security（IAMと権限設計）** です。  
このマガジンは、**Beginner → Middle → Advanced** を1サイクルとして反復し、実務で通用する力を積み上げます。

---

## 学習アーク（ローテーション計画）
- **Arc A: Application Security**  
  Secure Coding → OWASP Top 10 → Threat Modeling → Auth/Session Security → Incident Response
- **Arc B: DevOps Core**  
  Linux command mastery → Docker hardening → CI/CD security → Secrets management → Terraform/IaC best practices → Kubernetes fundamentals/security
- **Arc C: Required Added Topics**  
  Cloud Security（AWS/GCP IAM）→ Observability（Prometheus/Grafana/OpenTelemetry）→ Kubernetes incident drills（failure/rollback/recovery）

> 今日のIssueは **Arc C / Beginner**。次回以降で Middle・Advanced に進みます。

---

## 1) Topic + Level
**Topic:** Cloud Security 入門: AWS/GCP IAMの最小権限設計（Least Privilege）  
**Level:** **Beginner**

---

## 2) Why it matters in real projects
本番障害や情報漏えいの多くは、脆弱性そのものよりも **過剰権限** を足がかりに被害が拡大します。  
IAMを正しく設計できると、次の効果があります。
- 侵害時の被害範囲を最小化（blast radius縮小）
- 監査対応（誰が何にアクセスできるか説明可能）
- 開発速度を落とさず安全性を上げる（Role分離・一時クレデンシャル）

---

## 3) Core concepts（clear explanations）
- **Principal（主体）**: User/Role/Service Account など「誰が」
- **Permission（権限）**: 「何をできるか」
- **Resource（対象）**: S3 bucket / GCS bucket / KMS key など「どこに」
- **Policy Binding**: 主体と権限と対象を結ぶ定義
- **Least Privilege**: 必要最小限のみ許可
- **Deny by default**: 明示許可がない限り拒否
- **Separation of Duties**: 申請者・承認者・実行者を分離

### AWSの基本
- IAM Policy（JSON）で Action/Resource/Condition を定義
- Role + STS（AssumeRole）で短期認証情報を利用

### GCPの基本
- IAM Role（Primitive/Predefined/Custom）を Principal に付与
- 可能な限り Project全体ではなく、Resource単位で最小付与

---

## 4) Hands-on mini lab（30-60 min）
**Lab名:** 「読み取り専用ロールを作り、過剰権限を削る」

### 目標
1. まずは広すぎる権限を確認
2. 読み取り専用ロールへ置換
3. 操作失敗（拒否）を意図的に確認し、最小権限を検証

### 手順（AWS例）
1. テスト用Roleを作成（最初は `ReadOnlyAccess`）
2. `aws s3 ls` は成功、`aws s3 rb ...` は失敗することを確認
3. CloudTrailで失敗イベント（AccessDenied）を確認
4. 不要Actionをさらに削ったカスタムポリシーに変更

### 手順（GCP例）
1. サービスアカウント作成
2. `roles/viewer` をプロジェクトまたは限定リソースに付与
3. `gcloud storage ls` は成功、削除系は失敗を確認
4. Cloud Audit Logsで拒否イベント確認

---

## 5) Command cheatsheet
```bash
# Linux: 現在の認証情報・環境確認
env | grep -E 'AWS|GOOGLE|KUBE|TF_VAR'
whoami

# AWS CLI
aws sts get-caller-identity
aws iam list-attached-role-policies --role-name MyRole
aws s3 ls
aws s3 rm s3://example-bucket/test.txt   # 権限不足なら失敗するはず

# GCP CLI
gcloud auth list
gcloud config get-value project
gcloud projects get-iam-policy $PROJECT_ID --format=json | jq '.bindings[] | {role, members}'
gcloud storage ls

# Terraform (IAM as Code)
terraform init
terraform fmt
terraform validate
terraform plan

# Kubernetes（将来のIncident Drill準備）
kubectl auth can-i get pods -A
kubectl auth can-i delete pods -A
```

---

## 6) Common mistakes and how to avoid them
1. **`*`（ワイルドカード）多用**  
   - 回避: Action/Resourceを具体化し、Conditionを使う
2. **人間ユーザーに長期キー配布**  
   - 回避: SSO + Role引受（短期トークン）
3. **本番と開発で権限境界が曖昧**  
   - 回避: アカウント/プロジェクト分離 + 権限テンプレート化
4. **監査ログを見ない**  
   - 回避: CloudTrail / Cloud Audit Logs を週次レビュー
5. **IaC化せず手動変更**  
   - 回避: Terraform管理に寄せ、PRレビュー必須化

---

## 7) One interview-style question
**Q.** 「Least Privilegeを守りつつ、開発チームの速度を落とさないIAM運用設計をどう作りますか？」  
（ヒント: Role分離、Just-In-Time access、監査ログ、IaC、定期棚卸し）

---

## 8) Next-step reading links
- OWASP Top 10: https://owasp.org/www-project-top-ten/
- AWS IAM Best Practices: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- Google Cloud IAM Overview: https://cloud.google.com/iam/docs/overview
- Terraform IAM patterns (HashiCorp Learn): https://developer.hashicorp.com/terraform/tutorials
- OpenTelemetry Docs: https://opentelemetry.io/docs/
- Kubernetes Security Checklist (CNCF): https://kubernetes.io/docs/concepts/security/

---

## 次回予告（Difficulty Progression）
- **次回（Middle）予定:** Observability実践（Prometheus/Grafana/OpenTelemetry）  
  **Prerequisites:**
  - Linux基本コマンド（ps, top, journalctl, grep）
  - HTTP基礎（status code / latency）
  - Dockerコンテナの基本操作（run, logs, exec）

- **その次（Advanced）予定:** Kubernetes Incident Drill（障害注入→rollback→recovery）  
  **Prerequisites:**
  - kubectl基本（get/describe/logs）
  - Deployment / ReplicaSet / probes の理解
  - CI/CDまたはGitOpsの基本フロー

倫理・防御・法令順守を前提に、毎日1つずつ「現場で使える力」を増やしていきましょう。