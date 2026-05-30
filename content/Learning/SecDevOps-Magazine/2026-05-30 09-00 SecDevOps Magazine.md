---
tags: [security, devops, docker, kubernetes, terraform, linux, cloudsecurity, observability, daily]
---

# SecDevOps Magazine — 2026-05-30 09:00
[[Home]]

> 今日から「Beginner → Middle → Advanced」を繰り返す学習アークで進めます。  
> **今回: Beginner（第1回）**  
> 次回以降で Middle / Advanced に段階的に接続していきます。

---

## 1) Topic + Level
**Topic:** Docker Hardening + Linux基礎運用 + Cloud IAMの入口（最小権限の考え方）  
**Level:** **Beginner**

---

## 2) Why it matters in real projects
本番障害や情報漏えいの多くは、「高度なゼロデイ」より先に **基本設定の甘さ** から起きます。  
たとえば:
- コンテナを root で動かし続ける
- 不要なポート公開
- IAM 権限の過剰付与（`*` 許可）
- 監視が弱く、異常を早期検知できない

この号は、アプリセキュリティと DevOps をつなぐ土台（守りの初手）を固める回です。

---

## 3) Core concepts（clear explanations）
### A. Docker Hardening（基礎）
- **最小権限実行**: `USER` を使って non-root で実行する
- **最小イメージ**: 不要パッケージを減らし攻撃面を縮小
- **固定タグより digest**: 再現性向上（サプライチェーン管理）
- **不要な capability を落とす**: `--cap-drop=ALL` など

### B. OWASPリスクとの接続
- 設定ミスは **Security Misconfiguration** に直結
- 認証情報管理ミスは **Identification and Authentication Failures** に波及

### C. Cloud Security（IAMの入口）
- **Allow-all を避ける**
- ロール分離（開発者/CI/CD/運用）
- 監査ログを前提にした権限設計

### D. Observability（入口）
- **Metrics / Logs / Traces** の3本柱
- まずは「失敗を可視化」する（HTTP 5xx, restart 回数, latency）

### E. Kubernetes incident drills（予告）
- 今回は概念のみ。次のMiddle回で実際に「壊して戻す」演習へ接続

---

## 4) Hands-on mini lab（30-60 min）
**Lab名:** 「脆弱なDocker実行を1時間で改善する」

### ゴール
1. root実行コンテナを non-root 化  
2. 不要ポート公開を止める  
3. secrets を環境変数直書きから分離  
4. 最低限のメトリクス確認ポイントを決める

### 手順
1. 既存 Dockerfile を確認（`USER` がないことを確認）
2. 以下のように修正
   - `RUN adduser` で実行ユーザー追加
   - `USER appuser`
3. コンテナ実行時オプションを改善
   - `--read-only`
   - `--cap-drop=ALL`
   - 必要なポートだけ `-p`
4. secrets は `.env` 直書きせず、ローカル演習では `--env-file` を使用
5. 観測項目を記録
   - 起動成功率
   - エラーログ件数
   - レスポンス遅延（ざっくり）

**完了条件**
- `docker inspect` で実行ユーザーが root でない
- 不要ポート公開が消えている
- secrets が Dockerfile 内にハードコードされていない

---

## 5) Command cheatsheet
### Linux
```bash
id
ss -lntp
ps aux | head
journalctl -u docker --since "1 hour ago"
```

### Docker
```bash
docker build -t app:hardening-v1 .
docker run --read-only --cap-drop=ALL -p 8080:8080 --env-file .env app:hardening-v1
docker inspect <container_id> | grep -i '"User"'
docker logs <container_id> --since 30m
```

### Kubernetes（次回以降へ向けた最小）
```bash
kubectl get pods -A
kubectl describe pod <pod_name> -n <namespace>
kubectl rollout history deploy/<name> -n <namespace>
```

### Terraform（IAM設計の入口）
```bash
terraform fmt
terraform validate
terraform plan
```

---

## 6) Common mistakes and how to avoid them
- **ミス1:** `latest` タグ固定で安心する  
  → digest pinning と定期更新ポリシーを併用
- **ミス2:** 「開発だから」と root 実行を放置  
  → 開発段階から non-root を標準化
- **ミス3:** IAM に一時的な `*` を入れて戻し忘れる  
  → 期限付きチケットとレビュー必須化
- **ミス4:** 監視は後で…となる  
  → 最初にSLO未満の検知条件（5xx率など）を1つ置く

---

## 7) One interview-style question
「Docker コンテナを non-root で動かすことは、攻撃成功時の被害範囲にどう影響しますか？ 具体例を挙げて説明してください。」

---

## 8) Next-step reading links
- OWASP Top 10: https://owasp.org/www-project-top-ten/
- Docker security docs: https://docs.docker.com/engine/security/
- Kubernetes security checklist (CIS参考): https://kubernetes.io/docs/concepts/security/
- Terraform security best practices (HashiCorp): https://developer.hashicorp.com/terraform
- AWS IAM best practices: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- Google Cloud IAM overview: https://cloud.google.com/iam/docs/overview
- OpenTelemetry docs: https://opentelemetry.io/docs/
- Prometheus docs: https://prometheus.io/docs/introduction/overview/
- Grafana docs: https://grafana.com/docs/

---

## 学習アーク（進行管理）
- **Arc 1（Container & AppSec基礎）**
  - Day 1: Beginner（今日）
  - Day 2: Middle（Prereq: Linux基礎コマンド, Dockerfile編集経験）
  - Day 3: Advanced（Prereq: Middle完了 + 基本的なKubernetes運用経験）

- **Arc 2（Cloud IAM & Secrets）**
- **Arc 3（Observability実践）**
- **Arc 4（Kubernetes incident drills: failure/rollback/recovery）**

明日以降はトピックをローテーションし、各Arcで Beginner→Middle→Advanced を繰り返します。
