# SecDevOps Magazine — 2026-05-27

#security #devops #docker #kubernetes #terraform #linux #cloudsecurity #observability #daily
[[Home]]

## 今号テーマ
**Cloud Security 入門（AWS/GCP IAM & Permission Design） + 観測可能性の土台（OpenTelemetry）**  
**Level: Beginner**

> 学習アーク（3日循環）: **Beginner → Middle → Advanced** を繰り返し。  
> 明日予告（Middle）: IAM最小権限の設計レビュー + Terraformでの権限制御。  
> 明後日予告（Advanced）: Kubernetes Incident Drill（障害注入→rollback→recovery）と監査ログ分析。

---

### 1) Topic + Level
**Cloud Security 入門: IAMの考え方（AWS/GCP）と Permission Design の基本**  
**Beginner**

### 2) なぜ実案件で重要か
クラウド事故の多くは、脆弱性そのものより**権限ミス**で被害が拡大します。  
例: 読み取り専用のはずのサービスアカウントが書き込み権限を持っていた、退職者のアクセスが残っていた、など。  
IAM設計を理解しておくと、アプリ脆弱性があっても「被害半径」を小さくできます。

### 3) Core concepts（やさしく）
- **Principal**: 誰がアクセスするか（user/role/service account）
- **Policy**: 何を許可/拒否するか
- **Resource**: どの対象か（S3 bucket, GCS bucket, Secrets など）
- **Action**: 何をするか（read/write/delete/assume など）
- **Least Privilege（最小権限）**: 必要最小限だけ許可する
- **Deny-by-default**: 明示許可がない操作は不可
- **短命クレデンシャル**: 長期キーより、ロール引受やWorkload Identity優先

OpenTelemetryの最小理解:
- **Logs / Metrics / Traces** を同じ文脈で見られると、インシデント初動が速くなる
- `trace_id` をログに残すだけでも調査効率が大幅に改善

### 4) Hands-on mini lab（30-60分）
**目標:** 「過剰権限を検出し、最小権限に縮める」感覚を掴む

1. サンプルIAMポリシーを作る（最初は広め）
2. 実際のアクセス操作を2〜3個だけ実行
3. 不要権限を削る
4. 監査ログ/アクセスログで拒否イベントを確認
5. アプリログへ `trace_id` を追加（任意）

ミニ成果物:
- before/after のポリシー差分
- 削除した権限リスト
- 「なぜ削って安全か」の1段落メモ

### 5) Command cheatsheet
```bash
# Linux: 最近のログ確認
journalctl -n 100 --no-pager

# Docker: コンテナ環境変数の確認（秘密情報露出チェック）
docker inspect <container> | grep -i -E 'env|secret|token'

# Kubernetes: SAとRoleBindingの把握
kubectl get sa -A
kubectl get rolebinding,clusterrolebinding -A
kubectl auth can-i get secrets --as system:serviceaccount:default:default -n default

# Terraform: 変更内容の確認（適用前レビュー）
terraform fmt -recursive
terraform validate
terraform plan
```

### 6) Common mistakes と回避策
- **ミス:** `*` 権限を安易に使う  
  **回避:** まず read-only で開始し、必要操作ごとに追加
- **ミス:** 人間ユーザーに永続キー配布  
  **回避:** SSO + 短命トークンへ移行
- **ミス:** 監査ログを見ない  
  **回避:** denyイベントを毎日5分見る習慣化
- **ミス:** K8sでdefault service account使い回し  
  **回避:** ワークロードごとに専用SA

### 7) Interview-style question
「もし本番API Podが侵害されても、`customer-data` への書き込みを防ぐには、IAM/Kubernetes RBACをどう分離設計しますか？」

### 8) Next-step reading links
- OWASP Top 10: https://owasp.org/www-project-top-ten/
- AWS IAM Best Practices: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- Google Cloud IAM Overview: https://cloud.google.com/iam/docs/overview
- OpenTelemetry Docs: https://opentelemetry.io/docs/
- Kubernetes RBAC: https://kubernetes.io/docs/reference/access-authn-authz/rbac/
- Terraform Security Best Practices (HashiCorp): https://developer.hashicorp.com/terraform/tutorials/cloud-get-started/cloud-security

---

## 学習ロードマップ（ローテーション）
- **Application Security**: secure coding / OWASP / threat modeling / auth-session / incident response
- **DevOps Core**: Docker hardening / Kubernetes fundamentals & security / Terraform IaC / Linux command mastery / CI/CD security / secrets management
- **Added tracks (必須)**: Cloud Security / Observability / Kubernetes incident drills

次号以降はこの3系統を混ぜて、**Beginner → Middle → Advanced** の反復で実務力を積み上げます。