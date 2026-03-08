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

# SecDevOps Magazine — 2026-03-03 (09:00)

## 今日の学習アーク
- **Arc: Cloud Security & IAM基礎 → 運用可視化 → 障害対応**
- **Day 1/3: Beginner**（明日 Middle、明後日 Advanced 想定）
- ローテーション対象トラック:
  - Application Security（OWASP / 認証・セッション / 脅威モデリング）
  - DevOps Core（Docker / Kubernetes / Terraform / Linux / CI/CD / Secrets）
  - 追加必須（Cloud Security, Observability, Kubernetes incident drills）

---

## 1) Topic + Level
**Topic:** Cloud Security 入門: **AWS/GCP IAM と Permission Design の基本**  
**Level:** **Beginner**

## 2) なぜ実案件で重要か
IAMの設計ミスは、アプリ脆弱性と同じくらい事故につながります。例えば:
- 過剰権限のCI/CDトークンが漏洩 → 本番環境に不正変更
- 開発用サービスアカウントが本番データを読める → 情報漏えい
- 監査ログが不足 → インシデント調査不能

**最小権限 (Least Privilege)** を最初から設計できると、被害範囲を劇的に縮小できます。

## 3) Core concepts（わかりやすく）
- **Principal（誰が）**: User, Role, Service Account
- **Action（何を）**: 例 `s3:GetObject`, `compute.instances.get`
- **Resource（どこに）**: 特定バケット/プロジェクト/名前空間
- **Condition（いつ・どんな条件で）**: IP制限、タグ条件、時間帯など
- **Deny優先**: 明示的DenyがAllowより強い
- **Role分離**:
  - 人間: SSO + 短命セッション
  - マシン: Workload Identity / IAM Role for Service Account
- **監査可能性**: CloudTrail / Cloud Audit Logs を必ず有効化

## 4) Hands-on mini lab（30-60分）
**目標:** 「読み取り専用ロール」と「デプロイ専用ロール」を分離して、過剰権限を検出する。

### 手順（ローカル検証＋設計演習）
1. TerraformでIAMポリシーを2種類作成（ReadOnly / Deployer）。
2. `terraform plan` で差分確認し、権限をコメントで説明。
3. 想定攻撃シナリオを書く（例: Deployerキー漏えい時の被害）。
4. 被害を減らすための改善を1つ追加（条件付きポリシー、期限付きトークンなど）。

### 成果物
- `iam-readonly.tf`
- `iam-deployer.tf`
- `threat-notes.md`（攻撃シナリオと対策）

## 5) Command cheatsheet
```bash
# Linux: 権限確認の基本
id
whoami

# Terraform
terraform init
terraform fmt
terraform validate
terraform plan

# Docker: 実行ユーザー確認（コンテナ権限の意識）
docker ps
docker inspect <container> --format '{{.Config.User}}'

# Kubernetes: ServiceAccountとRBAC確認
kubectl get sa -A
kubectl get role,rolebinding,clusterrole,clusterrolebinding -A
kubectl auth can-i get secrets --as=system:serviceaccount:default:default -n default
```

## 6) Common mistakes と回避策
- **ミス1: `*` 権限を安易に使う**
  - 回避: Action/Resourceを具体化し、まずReadOnlyから開始
- **ミス2: 人とマシンで同じ権限セット**
  - 回避: Human Role と Workload Role を分離
- **ミス3: 長寿命アクセスキーを放置**
  - 回避: 短命クレデンシャル + ローテーション
- **ミス4: 監査ログ未整備**
  - 回避: ログを「最初に」有効化、保存期間も定義

## 7) Interview-style question
「CI/CD用ロールに `AdministratorAccess` を与えると何が問題で、代わりにどんなPermission Designをしますか？」

## 8) Next-step reading links
- OWASP Top 10: https://owasp.org/www-project-top-ten/
- AWS IAM Best Practices: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- Google Cloud IAM Overview: https://cloud.google.com/iam/docs/overview
- Kubernetes RBAC: https://kubernetes.io/docs/reference/access-authn-authz/rbac/
- Terraform Security Best Practices (HashiCorp docs): https://developer.hashicorp.com/terraform
- OpenTelemetry Docs: https://opentelemetry.io/docs/
- Prometheus Docs: https://prometheus.io/docs/
- Grafana Docs: https://grafana.com/docs/

---

## 明日の予告（Middle）
- **Observability実践:** Prometheus + Grafana + OpenTelemetry の最小構成
- **Prerequisite:**
  - 今日のIAM基礎（Principal/Action/Resource）を理解
  - `kubectl get pods -A` と `docker logs` を使える

## 今週後半の予告（Advanced）
- **Kubernetes Incident Drill:** 障害注入→Rollback→Recovery（ポストモーテム付き）
- **Prerequisite:**
  - Middle回のメトリクス/ログ/トレース基礎
  - Deployment rollout と rollback コマンド理解
