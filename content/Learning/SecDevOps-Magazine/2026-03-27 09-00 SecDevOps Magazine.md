# SecDevOps Magazine — 2026-03-27
[[Home]]

#security #devops #docker #kubernetes #terraform #linux #cloudsecurity #observability #daily

---

## 1) Topic + Level
**Cloud Security（AWS IAM Permission Design）× DevOps Secrets管理 入門**  
**Level: Beginner**

> 学習アーク（3日サイクル）  
> Day 1: Beginner（今日）→ Day 2: Middle → Day 3: Advanced → 次のテーマで再びBeginner

---

## 2) Why it matters in real projects
本番事故の多くは、アプリのバグだけでなく **権限ミス（過剰権限）** と **秘密情報の露出** から始まります。  
たとえば：
- CI/CD 用ユーザーに `AdministratorAccess` を付けてしまう
- `.env` や API key を Git にコミットしてしまう
- Kubernetes の Secret を平文で扱ってしまう

この領域を早めに押さえると、OWASP の「Broken Access Control」やインシデント初動時の被害範囲を大きく減らせます。

---

## 3) Core concepts (clear explanations)
### A. Least Privilege（最小権限）
- 「必要な操作だけ許可する」が IAM 設計の原則
- `Action`, `Resource`, `Condition` を狭める
- まず Allow を最小に、必要時に追加

### B. Role ベース運用（長期キーを減らす）
- User の Access Key 常用はリスク
- 可能なら IAM Role + 短命クレデンシャル（STS）
- CI では OIDC 連携で鍵レス化を目指す

### C. Secrets 管理の基本
- ソースコードに秘密を書かない
- Secret は専用ストア（AWS Secrets Manager / SSM Parameter Store / Vault 等）に置く
- ローテーションと監査ログを有効化

### D. DevOps との接続
- Terraform で IAM をコード化（再現性・レビュー可能）
- CI/CD で Secret scanning を組み込む
- Kubernetes は RBAC + Secret 参照設計をセットで考える

---

## 4) Hands-on mini lab (30–60 min)
**Lab: 「CI用ロールを最小権限で作る + Secret を安全に参照する」**

### 目標
1. Terraform で「S3 読み取り専用」ポリシーを作る  
2. IAM Role にそのポリシーのみ付与  
3. 秘密情報を `.env` ではなく Parameter Store から取得する

### 手順（目安45分）
1. Terraform プロジェクト初期化（10分）
2. IAM Policy/Role 作成（15分）
3. `aws ssm get-parameter --with-decryption` で取得確認（10分）
4. 「やってはいけない例」を1つ作って差分確認（10分）

### 完了条件
- `terraform plan` に過剰権限がない
- 秘密情報が Git 管理下ファイルに含まれていない
- Role で想定外 API が拒否される（AccessDenied を確認）

---

## 5) Command cheatsheet
```bash
# Linux: 秘密が混ざっていないか簡易チェック
grep -R --line-number -E "(AKIA|SECRET|PASSWORD|TOKEN)" .

# Terraform
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply

# AWS IAM/SSM
aws iam list-roles
aws ssm put-parameter --name "/app/dev/db_password" --type "SecureString" --value "CHANGE_ME" --overwrite
aws ssm get-parameter --name "/app/dev/db_password" --with-decryption

# Docker: build時にsecretを直書きしない（BuildKit secret利用の方向性）
DOCKER_BUILDKIT=1 docker build .

# Kubernetes: Secret参照確認
kubectl get secret
kubectl describe pod <pod-name>
```

---

## 6) Common mistakes and how to avoid them
1. **`*` ワイルドカードで全部許可**  
   - 回避: `Action` と `Resource` を具体化。レビュー時に「本当に必要か」を1行ずつ確認。

2. **CI に長期 Access Key を保存**  
   - 回避: OIDC + Role Assume に移行。期限付きクレデンシャルを使う。

3. **Secret を環境変数ファイルで配布**  
   - 回避: Secrets Manager/SSM 参照方式に統一。ローテーション手順を文書化。

4. **監査ログを見ていない**  
   - 回避: CloudTrail / 監査イベントを定期確認し、異常 API call を検出する。

---

## 7) One interview-style question
**質問:**  
「CI/CD パイプラインで AWS を操作する必要があります。なぜ IAM User の長期 Access Key より IAM Role（OIDC連携）を推奨しますか？セキュリティ面と運用面の両方で説明してください。」

---

## 8) Next-step reading links
- OWASP Top 10 (Broken Access Control): https://owasp.org/www-project-top-ten/
- AWS IAM Best Practices: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- AWS Well-Architected Security Pillar: https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/welcome.html
- Terraform Security Best Practices (HashiCorp): https://developer.hashicorp.com/terraform/tutorials/security
- Kubernetes RBAC: https://kubernetes.io/docs/reference/access-authn-authz/rbac/
- OpenTelemetry Docs（Observability導入の次ステップ）: https://opentelemetry.io/docs/

---

## 次号予告（Difficulty Progression）
**Middle（予定）:** Observability 実践（Prometheus/Grafana/OpenTelemetry）  
**Prerequisites:**
- Linux 基本操作（`grep`, `journalctl`, `ss`）
- Docker コンテナ実行とログ確認
- HTTP/メトリクスの基礎（latency, error rate, throughput）

**Advanced（予定）:** Kubernetes Incident Drill（障害注入→rollback→recovery）  
**Prerequisites:**
- `kubectl` 基本（get/describe/logs/rollout）
- Deployment/Service の基本理解
- 監視ダッシュボードを読めること（CPU/Memory/RED指標）
