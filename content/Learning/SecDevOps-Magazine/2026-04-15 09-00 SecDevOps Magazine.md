# 2026-04-15 09-00 SecDevOps Magazine
[[Home]]

Tags: #security #devops #docker #kubernetes #terraform #linux #cloudsecurity #observability #daily

---

## 今日のIssue

### 1) Topic + Level
**Observability（Prometheus / Grafana / OpenTelemetry）実践入門**  
**Level: Middle**

> 学習アーク（3日サイクル）: **Beginner → Middle → Advanced** を反復  
> 前回（Beginner）: Cloud Security（IAM/権限設計 + Secrets基礎）  
> 次回（Advanced予定）: Kubernetes incident drills（failure/rollback/recovery）

**Middleの前提条件（Prerequisites）**
- Linux基本コマンド（`grep`, `curl`, `ps`, `journalctl`）
- Dockerの基本（イメージ/コンテナ/ログ確認）
- HTTPの基本（status code, latencyの意味）
- 「最小権限・秘密情報管理」の基礎理解（前回内容）

---

### 2) Why it matters in real projects
本番で障害が起きると、最初に必要なのは「犯人探し」ではなく**状況把握の速さ**です。  
Observabilityが弱い現場では、
- アラートは鳴るが原因が分からない
- ロールバック判断が遅れる
- MTTR（平均復旧時間）が伸びる
という状態になりがちです。

一方、Metrics（数値）・Logs（記録）・Traces（経路）が揃っていると、
- どこで遅延が増えたか
- どの変更後にエラー率が上がったか
- どのサービス境界で詰まっているか
を短時間で絞れます。これはセキュリティ事故対応でも同じで、**検知から封じ込めまでの速度**に直結します。

---

### 3) Core concepts（clear explanations）
- **Metrics**: CPU, メモリ, レイテンシ, エラー率などの時系列データ。傾向把握とアラートに強い。
- **Logs**: 1イベント単位の詳細記録。原因深掘りに強い。
- **Traces**: リクエストが複数サービスを通る経路情報。分散システムのボトルネック可視化に必須。
- **Golden Signals**: Latency / Traffic / Errors / Saturation。まずはこの4つを押さえる。
- **SLI / SLO / Error Budget**: 品質目標を「感覚」ではなく「数値」で運用する枠組み。
- **Instrumentation**: OpenTelemetryでアプリに計測点を埋め込み、ベンダーロックを弱める設計。

---

### 4) Hands-on mini lab（30-60 min）
**ラボ名: 「5xx急増を10分以内に特定する観測基盤ミニ演習」**

#### ゴール
1. Prometheus + Grafana をローカルで起動
2. サンプルアプリに負荷をかけ、意図的に5xxを増やす
3. ダッシュボードとログを使って原因を切り分け
4. 監視観点を1つ改善（アラート条件またはメトリクス追加）

#### 手順
1. Docker ComposeでPrometheus/Grafana/サンプルWebを起動
2. Prometheusで`up`, `http_requests_total`, `http_request_duration_seconds`を確認
3. `hey`または`ab`で負荷をかける
4. サンプルアプリ側でエラーを発生させる（環境変数や擬似障害スイッチ）
5. Grafanaで
   - 5xx率
   - p95 latency
   - リクエスト量
   を同時表示
6. アプリログ（`docker logs`）で同時刻のエラー内容を確認
7. 原因仮説を1つ立て、再現→修正→再計測

**完了条件**
- 「どのメトリクス変化を根拠に原因を疑ったか」を説明できる
- 修正前後のグラフ差分（5xx率またはp95）を提示できる

---

### 5) Command cheatsheet
```bash
# Linux: 稼働確認・ログ確認
ps aux | grep -E 'prometheus|grafana'
journalctl -u docker --since "30 min ago"
curl -s http://localhost:9090/-/ready

# Docker: 監視スタック起動/確認
docker compose up -d
docker compose ps
docker compose logs -f prometheus
docker compose logs -f grafana

# Prometheus API: クエリ実行（例: up）
curl -G 'http://localhost:9090/api/v1/query' \
  --data-urlencode 'query=up'

# Kubernetes: 将来の展開を意識した基本確認
kubectl get pods -A
kubectl top pods -A
kubectl logs deploy/<app> -n <ns> --since=10m

# Terraform: 観測基盤IaC変更の前に差分確認
terraform fmt -recursive
terraform validate
terraform plan
```

---

### 6) Common mistakes and how to avoid them
- **ミス:** メトリクス名・ラベルがバラバラで比較できない  
  **回避:** 命名規約を先に決める（`service`, `env`, `status_code` など）

- **ミス:** 「メトリクスだけ」で終わり、ログと相関できない  
  **回避:** 重要ログに`trace_id`/`request_id`を必ず含める

- **ミス:** 高カーディナリティ（例: user_id）をラベルに入れてPrometheus肥大化  
  **回避:** ラベルは集計軸に限定し、個別IDはログ/トレース側へ

- **ミス:** アラートが多すぎて誰も見ない  
  **回避:** ページャー対象はSLO違反に直結するものだけに絞る

---

### 7) One interview-style question
本番で「APIの5xxが急増」という通知が来ました。  
あなたなら**最初の15分**で、
1. どのメトリクスを見て、
2. どのログ/トレースを当たり、
3. どの条件でロールバックを判断するか
を、実運用を想定して説明してください。

---

### 8) Next-step reading links
- OpenTelemetry Docs: https://opentelemetry.io/docs/
- Prometheus Querying Basics (PromQL): https://prometheus.io/docs/prometheus/latest/querying/basics/
- Grafana Alerting: https://grafana.com/docs/grafana/latest/alerting/
- Google SRE Workbook (Monitoring/Alerting): https://sre.google/workbook/table-of-contents/
- Kubernetes Monitoring: https://kubernetes.io/docs/tasks/debug/debug-cluster/resource-metrics-pipeline/
- OWASP Logging Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html

---

## Rotation Preview（トピック循環の見取り図）
- Day A（Beginner）: Cloud Security（AWS/GCP IAM & permission design）
- Day B（Middle）: Observability（Prometheus/Grafana/OpenTelemetry）
- Day C（Advanced）: Kubernetes incident drills（failure/rollback/recovery）
- Day D（Beginner）: OWASP + Secure Coding
- Day E（Middle）: Docker hardening + Linux command mastery
- Day F（Advanced）: Terraform/IaC security + CI/CD security

> **Advancedの前提条件:**
> - Middle（Observability）でメトリクス/ログ/トレース相関を実施した経験
> - Kubernetes基礎（Deployment/Service/rollout）
> - `kubectl rollout undo` や障害切り分けの基本操作
