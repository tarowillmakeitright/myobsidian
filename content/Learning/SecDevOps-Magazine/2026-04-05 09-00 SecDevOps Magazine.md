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

# SecDevOps Magazine — 2026-04-05

## 今日の学習アーク
- **Arc 03 / Day 1**
- **Topic:** Cloud Security（AWS/GCP IAM & Permission Design）
- **Level:** **Beginner**
- 進行ルール: Beginner → Middle → Advanced を反復
- 次回（Middle）に向けた前提: IAMの基本概念（Principal / Action / Resource / Condition）を説明できること

---

## 1) Topic + Level
**Cloud Security 入門: IAMを「最小権限」で設計する**（Beginner）

## 2) なぜ実務で重要か
本番事故の多くは「脆弱なコード」だけでなく、**過剰権限**で拡大します。  
たとえばCI用ユーザーに `*:*` を与えると、漏えい時に全環境が危険になります。  
IAM設計は、アプリ・インフラ・運用の境界を守る「最後の防波堤」です。

## 3) Core concepts
- **認証 (Authentication)**: 「誰か」を確認する（User/Role/Service Account）。
- **認可 (Authorization)**: 「何をしてよいか」を決める（Policy/Role Binding）。
- **最小権限 (Least Privilege)**: 必要最小限の権限のみ付与。
- **職務分離 (Separation of Duties)**: 開発・運用・監査の権限を分ける。
- **短命クレデンシャル**: 長期キーより、STS/OIDCなどの短期発行を優先。
- **明示的Deny優先**: AWS IAMではDenyがAllowより強い。
- **監査可能性**: CloudTrail / Audit Logsで「誰が何をしたか」を追える設計にする。

## 4) Hands-on mini lab（30-60分）
**ゴール:** 「読み取り専用ロール」を作り、不要権限を削る習慣を身につける。

### Lab A（AWS想定）
1. 読み取り専用PolicyをJSONで作成（S3の特定バケットのみ `Get/List`）。
2. Roleにアタッチ。
3. `aws sts assume-role` で一時認証情報を取得。
4. `aws s3 ls`（許可対象）と `aws s3 rm`（拒否されるべき）を試す。
5. CloudTrailで呼び出し記録を確認。

### Lab B（GCP想定）
1. カスタムRole（Viewer相当 + 必要最小限）を作成。
2. 対象ProjectにService Accountを作成してRoleを付与。
3. `gcloud auth activate-service-account` で確認。
4. 許可/拒否の境界をテスト。
5. Cloud Audit Logsで検証。

## 5) Command cheatsheet
```bash
# Linux
id
whoami
env | grep -E 'AWS|GOOGLE|KUBE'

# AWS IAM / STS (例)
aws sts get-caller-identity
aws iam list-attached-role-policies --role-name ReadOnlyAppRole
aws sts assume-role --role-arn arn:aws:iam::<ACCOUNT_ID>:role/ReadOnlyAppRole --role-session-name secdevops-lab

# GCP IAM (例)
gcloud auth list
gcloud projects get-iam-policy <PROJECT_ID>
gcloud iam roles describe <ROLE_ID> --project <PROJECT_ID>

# Terraform（IaC管理する場合）
terraform init
terraform plan
terraform apply
terraform state list
```

## 6) よくあるミスと回避策
- **ミス:** `AdministratorAccess` を暫定で付けっぱなし  
  **回避:** 期限付きチケット + 期限到来で自動削除。
- **ミス:** 人間ユーザーに長期Access Keyを配布  
  **回避:** SSO/OIDC + 短期トークンへ移行。
- **ミス:** Resourceスコープが `*` のまま  
  **回避:** バケット名/ARN/Projectを必ず限定。
- **ミス:** 変更後の検証なし  
  **回避:** 許可テスト + 拒否テスト + 監査ログ確認をセットで実施。

## 7) Interview-style question
「CI/CDパイプライン用の権限を設計するとき、なぜ“最小権限 + 短期認証情報 + 監査ログ”を同時に設計すべきですか？実際の侵害シナリオを1つ挙げて説明してください。」

## 8) Next-step reading links
- OWASP Top 10: https://owasp.org/www-project-top-ten/
- AWS IAM ベストプラクティス: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- GCP IAM 概要: https://cloud.google.com/iam/docs/overview
- Terraform Security Best Practices (HashiCorp): https://developer.hashicorp.com/terraform/language/style
- OpenTelemetry Docs: https://opentelemetry.io/docs/
- Kubernetes Security Checklist: https://kubernetes.io/docs/concepts/security/

---

## ローテーション予告（次号以降）
- Day 2（Middle）: Observability（Prometheus/Grafana/OpenTelemetry）
  - 前提: Metrics/Logs/Traces の違いを説明できること
- Day 3（Advanced）: Kubernetes Incident Drill（failure / rollback / recovery）
  - 前提: kubectl 基本操作、Deployment/Serviceの理解
- Day 4（Beginner）: OWASPリスクとSecure Coding
- Day 5（Middle）: Docker Hardening + Secrets Management
- Day 6（Advanced）: CI/CD Security + Threat Modeling 実戦
