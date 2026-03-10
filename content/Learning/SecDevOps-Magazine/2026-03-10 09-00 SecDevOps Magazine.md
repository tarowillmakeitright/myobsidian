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

# SecDevOps Magazine — 2026-03-10 09:00

おはようございます。今日のテーマは、**「Cloud Security: AWS/GCP IAM & Permission設計入門」**です。
実務で“事故らない権限管理”を作る第一歩を、手を動かして学びます。

---

## 1) Topic + Level
**Topic:** Cloud Security（AWS/GCP IAM & Permission Design）  
**Level:** **Beginner**（学習アーク 1/3）

> 学習アーク進行: **Beginner → Middle → Advanced** を繰り返し。  
> 次号（Middle）に進む前提: IAMポリシーJSONの基本読解、Role/User/Group/Service Accountの違いを説明できること。

---

## 2) Why it matters in real projects
- 権限ミスは、クラウド事故の最頻出原因（過剰権限・公開設定ミス）。
- DevOpsではCI/CD、Terraform、Kubernetes、監視基盤まで“権限”でつながっている。
- 最小権限（Least Privilege）を最初から設計できると、運用コストとインシデント対応時間が激減する。

---

## 3) Core concepts
- **Principal（主体）**: 人間ユーザー、Role、Service Account など。
- **Action（操作）**: 何をするか（例: `s3:GetObject`, `compute.instances.get`）。
- **Resource（対象）**: どこに対してか（特定バケット、特定プロジェクトなど）。
- **Condition（条件）**: 時間帯、IP、タグ、MFA有無など。
- **Deny優先**: 明示的DenyがAllowより強い（AWS）。
- **RBAC + ABAC**:
  - RBAC: 役割ベース（運用しやすい）
  - ABAC: 属性ベース（柔軟だが設計力が必要）
- **短期クレデンシャル**: 長期キーを避け、OIDC/Workload Identityで使い捨て認証へ。

---

## 4) Hands-on mini lab (30-60 min)
### 目標
「読み取り専用の監査ロール」を作り、過剰権限を検出する。

### 手順（ローカル演習）
1. AWSまたはGCPでテスト用アカウント/プロジェクトを準備。  
2. 読み取り専用ポリシーを1つ作成（`List/Get`中心）。  
3. そのポリシーをRoleにアタッチし、ユーザー/サービスに割り当て。  
4. 意図的に“禁止される操作”（削除など）を実行して `AccessDenied` を確認。  
5. CloudTrail（AWS）またはCloud Audit Logs（GCP）で拒否ログを確認。

### 成功条件
- 読み取り操作は成功
- 変更/削除操作は拒否
- 監査ログで拒否イベントを追跡できる

---

## 5) Command cheatsheet
```bash
# Linux: 最近の監査ログ確認（例）
journalctl -xe | tail -n 50

# AWS CLI: 現在の認証主体
aws sts get-caller-identity

# AWS CLI: S3一覧（許可されていれば成功）
aws s3 ls

# GCP CLI: 現在の認証主体
gcloud auth list

# GCP CLI: プロジェクトIAMポリシー表示
gcloud projects get-iam-policy <PROJECT_ID>

# Terraform: 設定チェック（IaCで権限管理する前提）
terraform fmt
terraform validate
terraform plan
```

---

## 6) Common mistakes and how to avoid them
- **ミス1: `*` を多用する**  
  → まずは必要最小のActionだけ許可。動かなければ段階的に追加。
- **ミス2: 人間ユーザーに長期アクセスキーを発行**  
  → SSO + 短期トークンに寄せる。
- **ミス3: 本番と検証で同じRoleを使う**  
  → 環境ごとにRole分離、命名規則を固定。
- **ミス4: 監査ログを見ない**  
  → 週次でDeniedイベントをレビューし、権限を継続改善。

---

## 7) One interview-style question
「**最小権限**を維持しつつ、開発速度を落とさないIAM運用を設計してください。  
あなたなら、申請フロー・例外対応・監査の3点をどう作りますか？」

---

## 8) Next-step reading links
- OWASP Top 10: https://owasp.org/www-project-top-ten/
- AWS IAM Best Practices: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- Google Cloud IAM Overview: https://cloud.google.com/iam/docs/overview
- CIS Benchmarks（Cloud/Kubernetes/Linux）: https://www.cisecurity.org/cis-benchmarks
- OpenTelemetry Docs: https://opentelemetry.io/docs/

---

## Rotation Preview（次号予告）
- **Middle:** Observability（Prometheus/Grafana/OpenTelemetry）で「権限異常の検知設計」
  - 前提: IAM基礎、メトリクス/ログ/トレースの違いを説明できる
- **Advanced:** Kubernetes Incident Drill（failure/rollback/recovery）
  - 前提: `kubectl`基本操作、Deployment/ReplicaSet/Serviceの理解

継続すると、AppSec（OWASP・認証/セッション・脅威モデリング）とDevOps（Docker/K8s/Terraform/Linux/CI/CD/Secrets）を横断して、実戦で使える“守れる開発力”が育ちます。