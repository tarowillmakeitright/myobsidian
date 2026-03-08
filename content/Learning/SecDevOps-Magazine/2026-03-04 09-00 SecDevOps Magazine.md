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

# SecDevOps Magazine — 2026-03-04 (09:00)

## 今日の学習アーク
- **Arc: Cloud Security & IAM基礎 → Observability実装 → Kubernetes障害対応**
- **Day 2/3: Middle**（明日 Advanced）
- ローテーション対象トラック:
  - Application Security（脅威モデリング / 認証・セッション / インシデント対応）
  - DevOps Core（Docker / Kubernetes / Terraform / Linux / CI/CD / Secrets）
  - 追加必須（Cloud Security, Observability, Kubernetes incident drills）

---

## 1) Topic + Level
**Topic:** Observability実践: **Prometheus + Grafana + OpenTelemetry で「壊れる前に気づく」仕組みを作る**  
**Level:** **Middle**

**Prerequisites（Middle向け）:**
- Beginner回のIAM基礎（Least Privilege / Role分離）を理解している
- `kubectl get pods -A`、`docker logs`、`terraform plan` の基本操作ができる
- HTTPステータスコードとレイテンシの意味を説明できる

## 2) なぜ実案件で重要か
本番障害の多くは「壊れたこと」よりも「壊れているのに気づけないこと」が致命的です。Observabilityが弱いと、
- リリース後のエラー増加を検知できない
- どのサービスが原因か切り分けに時間がかかる
- インシデント対応が属人化し、復旧が遅れる

逆に、メトリクス・ログ・トレースを最低限そろえるだけで、MTTR（平均復旧時間）は大きく改善します。

## 3) Core concepts（わかりやすく）
- **Metrics（Prometheus）**: 数値の時系列。CPU、メモリ、RPS、エラーレート、p95レイテンシなど
- **Logs**: 何が起きたかの記録。アプリ例外、認証失敗、権限拒否など
- **Traces（OpenTelemetry）**: リクエストが複数サービスをどう通ったかの経路
- **Four Golden Signals**: Latency / Traffic / Errors / Saturation
- **SLOとAlert**:
  - SLI（計測指標）例: 成功率  
  - SLO（目標）例: 99.9%成功率  
  - Alert（通知条件）例: 5分間でエラー率>2%
- **セキュリティ観点**:
  - ログに秘密情報（token/password）を出さない
  - 監視基盤の権限もLeast Privilegeにする

## 4) Hands-on mini lab（30-60分）
**目標:** ミニサービスを監視し、「エラー率上昇を可視化→アラート条件設計」まで行う。

### 手順
1. `docker compose` で `app + prometheus + grafana` を起動。  
2. アプリに `/metrics` エンドポイントを追加（または有効化）。  
3. Grafanaでダッシュボード作成（RPS / Error Rate / p95 Latency）。  
4. OpenTelemetry SDKでHTTPリクエストのTraceを有効化。  
5. わざと5xxを増やす（例: 環境変数で失敗率20%）→ グラフ変化を確認。  
6. Alertルール案を作成（「5分平均でError Rate > 2%」など）。

### 成果物
- `docker-compose.yml`
- `prometheus.yml`
- `grafana-dashboard.json`
- `alert-rule-draft.md`
- `incident-note.md`（検知〜原因仮説〜改善案）

## 5) Command cheatsheet
```bash
# Linux: プロセス/ポート確認
ss -lntp
journalctl -u docker --since "30 min ago"

# Docker
docker compose up -d
docker compose ps
docker compose logs -f app

# Kubernetes（将来の移植を見据えた確認）
kubectl get pods -A
kubectl logs deploy/myapp -n default --tail=100
kubectl top pod -n default

# Terraform（監視基盤をIaC管理する前提）
terraform fmt
terraform validate
terraform plan

# Prometheus動作確認
curl -s http://localhost:9090/-/ready
curl -s http://localhost:9090/api/v1/targets | jq '.status'
```

## 6) Common mistakes と回避策
- **ミス1: ダッシュボードだけ作ってアラートがない**
  - 回避: 「誰が・何分以内に対応するか」まで定義する
- **ミス2: 指標が多すぎて重要シグナルが埋もれる**
  - 回避: まずGolden Signalsに絞る
- **ミス3: ログに機密情報を出力**
  - 回避: マスキング/構造化ログ/レビュー項目化
- **ミス4: 監視基盤が単一障害点になる**
  - 回避: 保存先冗長化とバックアップ計画を先に決める
- **ミス5: エラー率だけ見て遅延悪化を見逃す**
  - 回避: p95/p99レイテンシを必ず同時監視

## 7) One interview-style question
「`Error Rate` が低いのにユーザー体験が悪化している場合、どの指標とトレースをどう見て原因を切り分けますか？」

## 8) Next-step reading links
- OpenTelemetry Docs: https://opentelemetry.io/docs/
- Prometheus Docs (Concepts): https://prometheus.io/docs/concepts/
- Grafana Docs: https://grafana.com/docs/
- Google SRE Book (SLI/SLO): https://sre.google/sre-book/service-level-objectives/
- OWASP Logging Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html
- Kubernetes Observability: https://kubernetes.io/docs/concepts/cluster-administration/system-logs/
- AWS Well-Architected Security Pillar: https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/welcome.html

---

## 明日の予告（Advanced）
- **Kubernetes Incident Drill:** 障害注入 → Rollback → Recovery（ポストモーテム込み）
- **Prerequisites（Advanced向け）:**
  - 今日のObservability基礎（Metrics/Logs/Traces）
  - `kubectl rollout status/history/undo` を使える
  - 5xx増加時の一次切り分けフローを説明できる
