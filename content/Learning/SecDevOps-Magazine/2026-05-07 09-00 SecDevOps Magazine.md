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

# SecDevOps Magazine — 2026-05-07

今日のテーマは、**Application Security × DevOpsの土台づくり**です。  
このシリーズは **Beginner → Middle → Advanced** を繰り返す学習アークで進めます。

- 今号: **Beginner**
- 次号予告: Middle（前提知識あり）
- その次: Advanced（運用想定の実践）

---

## 1) Topic + Level
**Topic:** Secure SDLCの入口 + Docker/LINUX/Kubernetes/Terraformの安全な最小運用  
**Level:** **Beginner**

---

## 2) Why it matters in real projects
本番事故の多くは「高度な攻撃」より前に、**基本設定ミス**で起きます。  
たとえば:
- アプリ: 入力検証不足（OWASP Top 10系）
- CI/CD: シークレット平文混入
- Docker: root実行のままデプロイ
- Kubernetes: 過剰なRBAC権限
- Cloud IAM: `*`許可のロール設計
- 監視: メトリクスがなく、異常検知が遅れる

つまり、基礎を早く固めるほど、開発速度と安全性を同時に上げられます。

---

## 3) Core concepts (clear explanations)

### Application Security
- **Secure Coding**: 「信頼しない入力」が原則。バリデーション、エスケープ、最小権限。
- **OWASP risks**: Broken Access Control / Injection / Security Misconfiguration は特に頻出。
- **Threat Modeling**: 何を守るか（Asset）→誰が脅かすか（Threat）→どこで壊れるか（Attack Surface）。
- **Auth/Session Security**: セッション固定化対策、トークン寿命、Secure/HttpOnly/SameSite。
- **Incident Response**: 検知→封じ込め→根絶→復旧→振り返り。

### DevOps Core
- **Docker Hardening**: non-root、最小ベースイメージ、不要パッケージ削減。
- **Kubernetes Fundamentals/Security**: Namespace分離、RBAC最小権限、readiness/liveness。
- **Terraform/IaC Best Practices**: state管理、`plan`レビュー、モジュール化、機密値分離。
- **Linux Command Mastery**: ログ調査、プロセス確認、権限監査。
- **CI/CD Security**: 依存関係スキャン、署名、Secretsの安全注入。
- **Secrets Management**: 環境変数直書き禁止、専用ストア利用（Vault/SSM等）。

### Added Topics（必須トラック）
- **Cloud Security (AWS/GCP IAM)**: 人・CI・ワークロードごとに権限を分離し、`least privilege`で設計。
- **Observability (Prometheus/Grafana/OpenTelemetry)**: メトリクス・ログ・トレースを結び、原因特定を高速化。
- **Kubernetes Incident Drills**: 障害を意図的に起こし、rollback/recovery手順を練習して本番耐性を上げる。

---

## 4) Hands-on mini lab (30–60 min)
**ラボ名:** 「安全な最小スタックを立てて、異常を観測する」

### 目標
1. non-root Dockerコンテナを起動  
2. Kubernetesに最小権限でデプロイ  
3. Terraformで“危険なIAM”を検出する練習  
4. Prometheus形式メトリクスを確認

### 手順（目安45分）
1. **Docker**（10分）
   - `nginx:alpine`をnon-rootで実行
   - `docker inspect`でユーザー確認

2. **Kubernetes**（15分）
   - Namespace `lab-secdevops`作成
   - 読み取り専用ServiceAccount/Role/RoleBindingを適用
   - Podをデプロイし`kubectl auth can-i`で権限検証

3. **Terraform + Cloud IAM設計レビュー**（10分）
   - サンプルHCLでワイルドカード権限（例: `Action="*"`）を見つける
   - `terraform validate`と`terraform plan`まで実行

4. **Observability**（10分）
   - アプリの`/metrics`エンドポイントをcurl
   - 「CPU/メモリ/HTTPエラー率」のどれを監視すべきかをメモ

5. **K8s Incident Drill（簡易）**（5分）
   - Deploymentに意図的に不正イメージタグを設定
   - `kubectl rollout undo`で復旧

---

## 5) Command cheatsheet
```bash
# Linux
id
ps aux | head
ss -lntp
journalctl -xe --no-pager | tail -n 50

# Docker hardening check
docker run --rm --user 10001:10001 nginx:alpine id
docker inspect <container_id> --format '{{.Config.User}}'

# Kubernetes basics/security
kubectl create ns lab-secdevops
kubectl -n lab-secdevops get all
kubectl -n lab-secdevops auth can-i get pods --as system:serviceaccount:lab-secdevops:reader-sa
kubectl -n lab-secdevops rollout status deploy/myapp
kubectl -n lab-secdevops rollout undo deploy/myapp

# Terraform
terraform fmt -recursive
terraform init
terraform validate
terraform plan

# Observability quick check
curl -s http://localhost:8080/metrics | head -n 30
```

---

## 6) Common mistakes and how to avoid them
1. **「とりあえず管理者権限」**  
   - 回避: IAM/RBACは最小権限から開始し、必要時に追加。

2. **シークレットをGitにコミット**  
   - 回避: `.env`直置き禁止、Secrets Manager/Vault利用、pre-commitで検査。

3. **監視が“導入だけ”で設計なし**  
   - 回避: SLI/SLOを先に決める（例: 5xx率、p95 latency）。

4. **K8s障害対応を本番で初経験**  
   - 回避: 定期的にincident drill（失敗注入→復旧）を実施。

5. **Terraform plan未レビューでapply**  
   - 回避: PRで`plan`差分レビューを必須化。

---

## 7) One interview-style question
あなたが新規プロジェクトの最初の1週間で、  
**Application Security / IAM / CI/CD / Observability** の最低ラインをどう設計するか、優先順位つきで説明してください。

---

## 8) Next-step reading links
- OWASP Top 10: https://owasp.org/www-project-top-ten/  
- OWASP ASVS: https://owasp.org/www-project-application-security-verification-standard/  
- Docker Security: https://docs.docker.com/engine/security/  
- Kubernetes Security Concepts: https://kubernetes.io/docs/concepts/security/  
- Terraform Best Practices (HashiCorp): https://developer.hashicorp.com/terraform  
- AWS IAM Best Practices: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html  
- Google Cloud IAM Overview: https://cloud.google.com/iam/docs/overview  
- Prometheus Docs: https://prometheus.io/docs/introduction/overview/  
- Grafana Docs: https://grafana.com/docs/  
- OpenTelemetry Docs: https://opentelemetry.io/docs/

---

### 次号（Middle）予告
**前提知識（Prerequisites）:**
- Linux基本コマンド（ps/ss/journalctl）
- Dockerイメージとコンテナの違い
- KubernetesのPod/Deployment/Serviceの基本
- Terraform `init/plan/apply` の流れ

次号では、脅威モデリングをCI/CDゲートに接続し、Kubernetes障害訓練をもう一段実戦化します。