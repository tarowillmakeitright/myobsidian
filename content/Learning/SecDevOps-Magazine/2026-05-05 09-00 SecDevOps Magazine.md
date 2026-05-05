---
tags: [security, devops, docker, kubernetes, terraform, linux, cloudsecurity, observability, daily]
---

[[Home]]

# SecDevOps Magazine — 2026-05-05

## 1) Topic + Level
**テーマ:** セキュアなアプリ配備の土台づくり（OWASP視点 + Docker hardening + IAM最小権限 + 基本Observability）  
**Level:** **Beginner**

> 学習アーク: 今号はBeginner。次号以降で Middle（脅威モデリング実践 / CI/CD security強化）→ Advanced（Kubernetes incident drill本番想定）へ進行。

---

## 2) Why it matters in real projects
実運用での事故は、単一の大きな脆弱性よりも「小さな設定ミスの連鎖」で起こることが多いです。  
たとえば以下の組み合わせ:
- Dockerコンテナが root 実行
- Cloud IAM が `*:*` に近い過剰権限
- ログ/メトリクス不十分で異常検知が遅延

この号では、**攻撃を学ぶためではなく防御を強くする**目的で、アプリ・インフラ・運用監視を一体で扱います。

---

## 3) Core concepts (clear explanations)
### A. Application Security（OWASPの入口）
- **Broken Access Control**: 認可不足で他人のデータにアクセスできる問題
- **Security Misconfiguration**: デフォルト設定放置、不要ポート公開、弱い権限など
- まずは「入力検証」「認可チェック」「安全なデフォルト」を徹底

### B. Docker Hardening（最小化）
- 非rootユーザーで実行（`USER`）
- 最小ベースイメージ（例: `alpine`, `distroless`）
- 不要パッケージを入れない、`latest`タグ固定を避ける

### C. Cloud Security（AWS/GCP IAM設計の基本）
- **Least Privilege（最小権限）**: 必要な操作だけ許可
- 人間ユーザーよりロール/サービスアカウント中心
- 一時クレデンシャル優先、長期キーを減らす

### D. Observability（見える化）
- **Metrics**: CPU、メモリ、リクエスト数、エラー率
- **Logs**: 何が起きたかの証跡
- **Traces**: リクエストの遅延箇所追跡
- Prometheus + Grafana + OpenTelemetry は標準スタック

### E. Kubernetes Incident Drill（予告）
- 今号は準備編。次のMiddle/Advancedで「障害注入→rollback→recovery」を実施

---

## 4) Hands-on mini lab (30-60 min)
**目標:** 小さなWebアプリを安全寄り設定でDocker実行し、メトリクスを可視化する

### 手順（45分想定）
1. 非rootユーザーで動く `Dockerfile` を作る
2. `docker run` 時に read-only filesystem + capability削減を適用
3. アプリに `/metrics` エンドポイント（簡易でOK）を用意
4. Prometheus で scrape、Grafana で 2つのパネル（RPS / Error率）作成
5. IAM設計演習: 「このアプリに必要なクラウド権限」を3つだけ列挙

### 期待成果
- “動く”だけでなく“守りながら動かす”感覚を獲得
- 設定ミスがどこで事故になるかを言語化できる

---

## 5) Command cheatsheet
### Linux
```bash
# 実行中プロセスと権限確認
ps aux | head
id

# ポート確認
ss -tulpen

# ログ確認
journalctl -xe --no-pager | head -n 50
```

### Docker
```bash
# イメージの脆弱性スキャン（Docker Scoutが使える環境なら）
docker scout quickview myapp:dev

# 非root/読み取り専用/権限最小で実行
docker run --read-only --cap-drop ALL --security-opt no-new-privileges \
  -p 8080:8080 myapp:dev

# 実行ユーザー確認
docker exec -it <container_id> id
```

### Kubernetes（基礎確認）
```bash
kubectl get pods -A
kubectl describe pod <pod-name> -n <namespace>
kubectl rollout status deploy/<name> -n <namespace>
```

### Terraform / IaC
```bash
terraform fmt -recursive
terraform validate
terraform plan

# 変更差分をレビューしやすく保存
terraform plan -out=tfplan
```

---

## 6) Common mistakes and how to avoid them
1. **「まず動かす」が長引いて本番も危険設定のまま**  
   - 対策: Definition of Done に「非root」「最小権限」「監視」を含める

2. **IAMを広く付与して後で絞るつもりが放置**  
   - 対策: 先に権限リストを文章化し、レビュー承認後に付与

3. **メトリクスだけ見てログを見ない**  
   - 対策: “数値の異常”→“ログで原因特定”の運用手順を固定化

4. **Kubernetes障害対応を本番で初体験してしまう**  
   - 対策: 定期的に incident drill（rollback/recovery）を実施

---

## 7) One interview-style question
「あなたのチームで、Dockerコンテナの実行権限を最小化しつつ、障害調査可能性（Observability）を落とさない設計を説明してください。」

---

## 8) Next-step reading links
- OWASP Top 10: https://owasp.org/www-project-top-ten/
- OWASP Cheat Sheet Series: https://cheatsheetseries.owasp.org/
- Docker Security: https://docs.docker.com/engine/security/
- Kubernetes Security Checklist (CNCF): https://kubernetes.io/docs/concepts/security/
- Terraform Best Practices: https://developer.hashicorp.com/terraform/language
- AWS IAM Best Practices: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- GCP IAM Overview: https://cloud.google.com/iam/docs/overview
- Prometheus Docs: https://prometheus.io/docs/introduction/overview/
- Grafana Docs: https://grafana.com/docs/
- OpenTelemetry Docs: https://opentelemetry.io/docs/

---

### 次号予告（Middle）
**予定テーマ:** 脅威モデリング + CI/CD security + Secrets Management（前提: 今号のDocker/IAM/Observability基礎）
