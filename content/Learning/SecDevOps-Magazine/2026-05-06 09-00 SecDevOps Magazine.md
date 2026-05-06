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

# SecDevOps Magazine — 2026-05-06

**Learning Arc:** Arc 01 / Day 1  
**今日の難易度:** **Beginner**  
**進行ルール:** Beginner → Middle → Advanced を繰り返しながら、Application Security / DevOps / Cloud Security / Observability / K8s Incident Drill をローテーション

---

## 1) Topic + Level
**Topic:** Cloud Security 入門 — AWS/GCP における IAM と Permission Design の基本  
**Level:** Beginner

> 次回予告（Middle）: IAM Policy の最小権限化 + Terraform での権限分離（実施前提: Linux基本操作、JSON/YAML読解）

---

## 2) Why it matters in real projects
現場のセキュリティ事故は、ゼロデイよりも **過剰権限**（`*:*` 許可、共有アカウント、長期キー放置）から起きることが多いです。  
クラウドでは「誰が・何に・どこまでアクセスできるか」を設計できると、次の価値が出ます。

- 誤操作や内部不正の被害範囲を最小化できる
- 監査対応（誰が何をしたか）を説明しやすい
- CI/CD や運用自動化を安全にスケールできる

---

## 3) Core concepts
### A. Principal / Resource / Action / Condition
IAMは基本的にこの4要素で考えます。
- **Principal**: 実行主体（User, Role, Service Account）
- **Resource**: 対象（S3 bucket, GCS bucket, KMS key など）
- **Action**: 操作（read/write/delete/list）
- **Condition**: 条件（IP, 時間, タグ, MFA など）

### B. Least Privilege（最小権限）
「必要な操作だけ」を許可する。最初は狭く、必要時に追加。

### C. Role ベース運用
- 人間ユーザーへ直接強権限を付けない
- Role/Service Account を用途ごとに分離
- 短期クレデンシャル（STS等）を優先

### D. Deny と Boundary
- 明示的 Deny は強い安全柵
- Permission Boundary / Organization Policy で上限を作る

---

## 4) Hands-on mini lab (30-60 min)
**目標:** 「読み取り専用」と「デプロイ用」の権限を分離し、過剰権限を検出する

### 手順（ローカル検証ベース）
1. IAMポリシーJSONを2つ作成
   - `readonly-policy.json`（読み取りのみ）
   - `deploy-policy.json`（特定リソースへの限定書き込み）
2. `rg`/`grep`でワイルドカード権限を検出
3. Terraform テンプレートに最小権限を反映（ダミーでも可）
4. 「この権限でできること/できないこと」を文章化

### 成果物
- `iam/readonly-policy.json`
- `iam/deploy-policy.json`
- `terraform/iam-role.tf`
- `notes/permission-review.md`

---

## 5) Command cheatsheet
```bash
# Linux: ファイル確認
ls -la
cat iam/readonly-policy.json

# Linux: 危険なワイルドカード検出
rg '"Action"\s*:\s*"\*"|"Resource"\s*:\s*"\*"' iam/

# jq: JSON整形
jq . iam/readonly-policy.json

# Terraform: フォーマット/検証
terraform fmt
terraform validate

# Docker: セキュリティ文脈での基礎確認（関連復習）
docker scout quickview 2>/dev/null || echo "docker scout not configured"

# Kubernetes: 文脈つなぎ（次のK8sセキュリティ回に備える）
kubectl auth can-i get pods --all-namespaces
```

---

## 6) Common mistakes and how to avoid them
1. **`Action: "*"` を常用する**  
   → 最初はReadOnlyから開始し、実運用ログを見て必要操作を追加。

2. **人間ユーザーに永続アクセスキーを配る**  
   → Role引受（AssumeRole）と短期クレデンシャルへ寄せる。

3. **本番と開発で同じ権限セットを使う**  
   → 環境別Role + Permission Boundaryで上限管理。

4. **監査ログを見ない**  
   → CloudTrail / Cloud Logging の定期レビューを運用化。

---

## 7) One interview-style question
「S3/GCS バケットに対して、アプリ実行ロールには読み取りのみ、CIロールには特定プレフィックス配下のみ書き込み許可を与えたい。最小権限の設計方針と、誤設定を検知する仕組みを説明してください。」

---

## 8) Next-step reading links
- OWASP Top 10: https://owasp.org/www-project-top-ten/  
- AWS IAM Best Practices: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html  
- Google Cloud IAM Overview: https://cloud.google.com/iam/docs/overview  
- Kubernetes RBAC: https://kubernetes.io/docs/reference/access-authn-authz/rbac/  
- OpenTelemetry Docs: https://opentelemetry.io/docs/  
- Terraform Security Best Practices (HashiCorp): https://developer.hashicorp.com/terraform/tutorials/security

---

## Rotation Plan (preview)
- Day 2 (Middle): CI/CD Security + Secrets Management（前提: Git/CI基礎、YAML読解）
- Day 3 (Advanced): Kubernetes Incident Drill（failure → rollback → recovery）
- Day 4 (Beginner): OWASPリスクとSecure Coding基礎
- Day 5 (Middle): Observability（Prometheus/Grafana/OpenTelemetry）
- Day 6 (Advanced): Threat Modeling + Incident Response 演習
