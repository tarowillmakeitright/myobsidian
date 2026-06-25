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

# SecDevOps Magazine — 2026-06-25

## 1) Topic + Level
**Observability / Prometheus・Grafana・OpenTelemetry 入門: “落ちた後に祈る” から “落ちる前に気づく” へ**  
**Level: Beginner**

---

## 2) Why it matters in real projects
アプリが本番で遅くなったとき、実務で一番つらいのは **「壊れていること」そのものより、何が起きているか分からないこと** です。

よくある現場のつまずきはこんな感じです。

- CPU は高くないのに API が遅い
- Pod は `Running` なのにユーザーからは 500 が見える
- デプロイ後にエラー率が上がったが、どの変更が原因か追えない
- ログはあるが量が多すぎて、時系列で原因を掴めない
- アラートは鳴るのに「で、何を見ればいいの？」となる

ここで必要になるのが Observability です。

Observability は単なる監視ツールの寄せ集めではなく、**システムの内部状態を外から推測できるようにする設計思想**です。AppSec の観点でも重要で、異常な認証失敗、急な 5xx 増加、想定外トラフィック、攻撃兆候の初動把握に直結します。

つまり Observability が弱いと、障害対応もセキュリティ検知も遅れます。逆にここが強いと、**「落ちた理由を説明できるチーム」** になれます。

---

## 3) Core concepts

### 3-1. Monitoring と Observability は似ているけど同じではない
- **Monitoring**: あらかじめ決めた項目を監視する
- **Observability**: 未知の問題でも、手元のデータから原因を推測しやすくする

たとえば「CPU > 80%」を監視するのは Monitoring です。  
でも「特定の API だけ p95 latency が急増し、その直前に DB 接続待ちが増え、同じ時間帯に認証エラーも増えている」と辿れる状態は Observability に近いです。

実務では両方必要ですが、学習の最初は **metrics / logs / traces** の 3 本柱を区別できることが大事です。

### 3-2. Metrics: まず“全体の健康状態”を見る
Metrics は数値の時系列データです。Prometheus でよく扱います。

代表例:
- リクエスト数 (`requests_total`)
- エラー数 / エラー率
- レイテンシ（p50 / p95 / p99）
- CPU / memory
- Pod 再起動回数

Metrics の強み:
- 軽い
- グラフ化しやすい
- しきい値アラートに向く

初心者が最初に覚えるべきことは、**平均値だけ見ない**ことです。平均 latency が 200ms でも、一部ユーザーだけ 3 秒待たされているかもしれません。そこで p95 / p99 が大事になります。

### 3-3. Logs: 何が起きたかを文章で残す
Logs はイベント記録です。アプリのエラー内容、認証失敗、処理結果などが残ります。

例:
- `login failed for user=alice reason=invalid_password`
- `db timeout after 2000ms`
- `payment request rejected trace_id=...`

Logs の強み:
- 詳細が分かる
- 失敗理由を追いやすい
- セキュリティイベントの調査に重要

ただし、ログだけでは“全体像”が見えにくいです。だから Metrics と組み合わせます。

### 3-4. Traces: 1 回のリクエスト旅路を追う
Traces は、1 つのリクエストが複数サービスをどう通ったかを追うためのデータです。OpenTelemetry はここでよく使われます。

たとえば:
- API Gateway
- auth service
- application service
- database

という流れがあるとき、Trace があると **どこで時間を食っているか** が見えます。

初心者のうちは細かい実装より、まず次の理解で十分です。
- `trace_id`: 同じリクエストを追うための ID
- `span`: 各処理区間
- 親子関係: API → DB 呼び出し など

### 3-5. Prometheus は“数値を集める人”、Grafana は“見える化する人”
ざっくり言うと:

- **Prometheus**: exporter やアプリの `/metrics` を scrape して保存
- **Grafana**: Prometheus などのデータをグラフやダッシュボードで可視化

初心者が混同しやすいですが、Prometheus 自体はグラフを綺麗に作ることが主目的ではありません。  
**集める役** と **見せる役** を分けて理解すると整理しやすいです。

### 3-6. OpenTelemetry は“観測データの共通言語”に近い
OpenTelemetry は vendor そのものではなく、**instrumentation と telemetry 収集の標準化**に近い存在です。

これが重要なのは、将来ツールを変えても:
- ログの相関
- トレースの文脈
- メトリクスの命名規則

を比較的一貫して保ちやすいからです。

最初は「OpenTelemetry = trace を取るもの」と思われがちですが、実際には metrics / logs / traces の統一的な扱いに価値があります。

### 3-7. Security と Observability はかなり近い
AppSec 的にも Observability は重要です。

たとえば検知したいもの:
- 急なログイン失敗の急増
- 特定 IP / User-Agent からの異常アクセス
- 権限エラーの急増
- 新デプロイ直後の 403 / 500 上昇
- Kubernetes での Pod 再起動連鎖

つまり Observability は SRE だけの話ではなく、**防御側が“異常に早く気づくための基盤”**でもあります。

---

## 4) Hands-on mini lab (30-60 min)
**テーマ: Prometheus + Grafana + サンプルアプリで “見える状態” を作る**

### ゴール
- `/metrics` を見る
- Prometheus が metrics を集める流れを体感する
- Grafana で基本ダッシュボードを作る
- レイテンシやエラー率を観察する視点を持つ

### 準備
Docker が使えるローカル環境を想定します。

### Step 1: 作業ディレクトリを作る
```bash
mkdir -p ~/lab/observability-beginner
cd ~/lab/observability-beginner
```

### Step 2: `docker-compose.yml` を作る
```yaml
services:
  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml:ro

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3000:3000"

  node-exporter:
    image: prom/node-exporter:latest
    ports:
      - "9100:9100"
```

### Step 3: `prometheus.yml` を作る
```yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: prometheus
    static_configs:
      - targets: ["prometheus:9090"]

  - job_name: node-exporter
    static_configs:
      - targets: ["node-exporter:9100"]
```

### Step 4: 起動する
```bash
docker compose up -d
```

### Step 5: ブラウザで確認する
- Prometheus: `http://localhost:9090`
- Grafana: `http://localhost:3000`

Grafana 初期ログインの後、Prometheus を Data Source として追加します。

### Step 6: Prometheus で query を試す
以下を入れて結果を見ます。
- `up`
- `rate(node_cpu_seconds_total[5m])`
- `node_memory_MemAvailable_bytes`

### Step 7: Grafana で 2 枚だけグラフを作る
まずは十分です。
- CPU 使用傾向
- 利用可能メモリ

### Step 8: “もし障害が起きたら何を見るか” を書く
メモに次を書いてください。
- サービス停止時に最初に見る指標は？
- 遅延時に最初に見る指標は？
- セキュリティ異常を疑うなら、どんなログやメトリクスを見る？

### 発展ミニ課題
もし余裕があれば、サンプル Web アプリを 1 つ追加して `/metrics` を expose し、以下を観察してください。
- リクエスト数
- エラー数
- レイテンシ

**ポイント:** 完璧な環境を作ることが目的ではありません。  
今日は **「監視ツールを立てる」ではなく「何を見れば現象を説明できるか」** を掴むのが目的です。

---

## 5) Command cheatsheet

### Linux
```bash
# 現在のポート利用確認
ss -lntp

# コンテナ関連プロセス確認
ps aux | grep -E "prometheus|grafana|node-exporter"

# ログ確認
journalctl -xe --no-pager

# HTTP の生存確認
curl -I http://localhost:9090
curl -I http://localhost:3000
```

### Docker / Compose
```bash
# 起動
docker compose up -d

# 状態確認
docker compose ps

# ログ確認
docker compose logs -f prometheus
docker compose logs -f grafana

# 停止
docker compose down

# イメージ確認
docker images | grep -E "prom|grafana"
```

### Prometheus
```bash
# 設定ファイル確認
cat prometheus.yml

# メトリクス endpoint 確認
curl http://localhost:9100/metrics | head

# Prometheus targets を UI で確認
# http://localhost:9090/targets
```

### Kubernetes 観点で後々役立つ基本
```bash
# context 確認
kubectl config current-context

# Pod / Node の状態確認
kubectl get pods -A
kubectl get nodes

# イベント確認
kubectl get events -A --sort-by=.lastTimestamp
```

### Terraform / IaC 観点で後々役立つ基本
```bash
# 監視関連コードを検索
grep -R "prometheus\|grafana\|otel\|opentelemetry" .

# Terraform の基本確認
terraform fmt -recursive
terraform validate
```

---

## 6) Common mistakes and how to avoid them

### ミス1: CPU と memory だけ見て「監視できている」と思う
**問題:** アプリの遅延や認証異常は見逃しやすいです。  
**回避:** infra 指標だけでなく、リクエスト数・エラー率・レイテンシも見る。

### ミス2: 平均値だけ見る
**問題:** 一部の遅いリクエストが隠れます。  
**回避:** p95 / p99 latency を意識する。

### ミス3: ログに trace_id や request_id を入れない
**問題:** どの失敗がどのリクエストに対応するか辿れません。  
**回避:** 最低でも request_id / trace_id をログに残す設計を考える。

### ミス4: アラートを増やしすぎる
**問題:** 毎日鳴って無視されます。  
**回避:** 最初は少数精鋭で、サービス停止・高エラー率・極端な遅延に絞る。

### ミス5: ダッシュボードを“飾り”にする
**問題:** 見た目はきれいでも、障害時に使えません。  
**回避:** 「壊れたとき最初に何を見るか」を前提に作る。

### ミス6: Security イベントを observability から切り離す
**問題:** 認証失敗急増や異常トラフィックを後追いでしか見つけられません。  
**回避:** auth failure、403、rate limit hit なども監視対象に含める。

---

## 7) One interview-style question
**質問:**  
「本番 API が『たまに遅い』という報告が来たとき、Prometheus・Grafana・ログ・トレースをどう使い分けて、原因調査を進めますか？」

**考えるポイント:**
- まず全体影響を見るか、個別リクエストを見るか
- どのメトリクスを最初に確認するか
- ログで何を絞るか
- trace があると何が楽になるか
- セキュリティ異常の可能性をどう切り分けるか

---

## 8) Next-step reading links
- Prometheus documentation  
  https://prometheus.io/docs/introduction/overview/
- Grafana documentation  
  https://grafana.com/docs/
- OpenTelemetry documentation  
  https://opentelemetry.io/docs/
- Kubernetes monitoring basics  
  https://kubernetes.io/docs/tasks/debug/debug-cluster/resource-metrics-pipeline/
- OWASP Logging Cheat Sheet  
  https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html
- OWASP Incident Response Cheat Sheet  
  https://cheatsheetseries.owasp.org/cheatsheets/Incident_Response_Cheat_Sheet.html

---

## ひとこと
Observability の第一歩は、難しいツールを全部覚えることではありません。  
**「システムの不調を、勘ではなく証拠で説明できるようになること」** です。  
今日はその入口としてかなり良いテーマです。