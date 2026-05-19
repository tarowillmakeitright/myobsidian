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

# SecDevOps Magazine — 2026-05-19

## 今号のテーマ + レベル
**Cloud Security (AWS/GCP IAM & Permission Design) × CI/CD Security 基礎**  
**Level: Beginner（学習アーク 1/3: Beginner → Middle → Advanced）**

> ローテーション計画（直近）  
> - Day 1（今日）: Cloud IAM基礎 + CI/CD認可最小化（Beginner）  
> - Day 2: Docker hardening + Secrets管理（Middle）※前提あり  
> - Day 3: Kubernetes incident drill（rollback/recovery）+ Observability連携（Advanced）※前提あり

---

## 1) なぜ実務で重要か
IAMの設計ミスは、**最も多いクラウド事故の入口**です。  
「とりあえず Admin 権限」で始めると、CI/CDトークン流出や誤操作時に被害が一気に拡大します。

実務では以下が頻発します。
- 開発効率優先で権限が過剰化
- 人用アカウントと機械用アカウント（Service Account/Role）が混在
- 監査ログを見ても「誰が何をしたか」追えない

**最小権限（Least Privilege）+ 役割分離（Separation of Duties）+ 監査可能性（Auditability）**を最初から組み込むと、事故時の被害範囲と復旧時間が大きく変わります。

---

## 2) コア概念（やさしく）
### A. Principal / Resource / Action / Condition
IAMポリシーは基本的に次の4要素で考えると整理しやすいです。
- **Principal**: 誰が（User/Role/Service Account）
- **Resource**: 何に（S3 bucket, GCS bucket, KMS key など）
- **Action**: 何を（read/write/delete/assume など）
- **Condition**: どんな条件で（IP, 時間, タグ, MFA有無）

### B. Human と Workload を分離
- 人間: SSO + MFA必須、短命セッション
- ワークロード: Role/Service Account で実行、鍵の長期保存禁止

### C. Deny by default
- デフォルト拒否を前提に、必要最小だけ許可
- 「一時的な強権限」は期限付きで付与（JITアクセス）

### D. CI/CD Security の最小原則
- Buildジョブに「デプロイ権限」を与えすぎない
- 本番反映は別Role + 承認ステップ
- Secretsは環境変数直書きせず、Secret Manager/KMS連携

---

## 3) Hands-on Mini Lab（30〜60分）
**目的:** 「権限を絞ると何が起きるか」を体験する

### 準備
- ローカルに `aws` または `gcloud` CLI（どちらか片方でOK）
- テスト用プロジェクト/アカウント（本番禁止）

### 手順（クラウド共通の考え方）
1. **読み取り専用ロール**を作る（Storage/Bucketのlist/getのみ）
2. そのロールでCLI実行し、readは成功・writeは失敗することを確認
3. CI用の別ロールを作る（artifact pushのみ許可）
4. 「本番デプロイ権限」を敢えて付けない状態でパイプライン実行
5. 失敗ログを確認し、必要最小のActionだけ追加
6. 監査ログ（CloudTrail/Cloud Audit Logs）で実行主体を追跡

**ゴール:**
- 「できること」と「できないこと」を意図通りに制御できる
- ログから実行主体が明確に辿れる

---

## 4) Command Cheatsheet
### Linux
```bash
# 直近変更ファイル確認
find . -type f -mtime -1 | head

# 環境変数のうち機密っぽいものを目視チェック（本番で出力共有しない）
env | grep -Ei 'token|secret|key|password'
```

### AWS CLI（例）
```bash
# 現在の実行主体確認
aws sts get-caller-identity

# S3一覧（read許可テスト）
aws s3 ls s3://<bucket-name>

# 書き込みテスト（権限不足なら AccessDenied が正しい）
aws s3 cp ./test.txt s3://<bucket-name>/test.txt
```

### GCP CLI（例）
```bash
# 現在のアカウント/プロジェクト確認
gcloud auth list
gcloud config list project

# バケット一覧
gcloud storage ls

# 書き込みテスト（権限不足が期待値）
gcloud storage cp ./test.txt gs://<bucket-name>/test.txt
```

### Terraform（IAMをコード管理）
```bash
terraform init
terraform fmt
terraform validate
terraform plan
```

### Kubernetes（CI連携を想定した確認）
```bash
# 現在のcontext確認
kubectl config current-context

# 認可チェック（この主体ができる操作を確認）
kubectl auth can-i create deployments -n prod
```

---

## 5) よくあるミスと回避策
1. **`*`（ワイルドカード権限）を多用**  
   - 回避: Action/Resourceを明示、不要権限を四半期ごとに棚卸し

2. **長期アクセスキーをCIに置きっぱなし**  
   - 回避: OIDC連携や短命トークンを利用、ローテーション自動化

3. **開発/本番で同じRoleを使う**  
   - 回避: 環境ごとにRole分離、prodは追加承認を必須化

4. **監査ログを有効化していない**  
   - 回避: CloudTrail / Cloud Audit Logs を必須設定にし、保存期間を定義

5. **Kubernetesでcluster-adminを配りすぎる**  
   - 回避: Namespace単位のRBACから開始、`kubectl auth can-i`で検証

---

## 6) Interview-style Question
CI/CDパイプラインで「ビルドは可能だが本番デプロイは不可」にしたいです。  
AWSまたはGCPで、どのようにRole/Service Accountと権限境界を設計しますか？  
また、監査時に「誰がデプロイしたか」をどう証明しますか？

---

## 7) Next-step Reading Links
- OWASP Top 10: https://owasp.org/www-project-top-ten/  
- OWASP ASVS: https://owasp.org/www-project-application-security-verification-standard/  
- AWS IAM Best Practices: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html  
- Google Cloud IAM Best Practices: https://cloud.google.com/iam/docs/best-practices  
- Kubernetes RBAC: https://kubernetes.io/docs/reference/access-authn-authz/rbac/  
- CIS Benchmarks (Docker/Kubernetes/Linux): https://www.cisecurity.org/cis-benchmarks  
- OpenTelemetry Docs: https://opentelemetry.io/docs/  
- Prometheus Docs: https://prometheus.io/docs/  
- Grafana Docs: https://grafana.com/docs/

---

## 次号予告（Middle）
**Docker hardening + Secrets管理 + Terraformでのポリシーガードレール**  
前提: Linux基本コマンド、IAMのPrincipal/Action/Resourceの理解（今号）
