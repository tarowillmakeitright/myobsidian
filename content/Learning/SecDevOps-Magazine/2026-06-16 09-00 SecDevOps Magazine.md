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

# 2026-06-16 09-00 SecDevOps Magazine

## 1) Topic + Level
**Observability: Prometheus / Grafana / OpenTelemetry 入門**  
**Level: Beginner**

> 学習アーク: Observability 1/3  
> 次回予定: Middle（メトリクス設計 / Alerting / ダッシュボード設計）  
> 前提知識: なし

## 2) Why it matters in real projects
アプリやインフラは、**動いているだけでは不十分**です。実務では「遅い」「一部だけ失敗する」「本番でときどき落ちる」といった、テストでは見えにくい問題が必ず出ます。

そのときに必要なのが Observability です。Observability は、単に監視ツールを入れることではなく、**システムの内側で何が起きているかを説明できる状態を作ること**です。

たとえば現場では、こんな差が出ます。

- 観測できないチーム: 「なんか重い」「再現しない」「とりあえず再起動」
- 観測できるチーム: 「API の p95 latency が上がっている」「特定エンドポイントだけ 500 が増えている」「DB 接続待ちがボトルネック」

セキュリティの観点でも重要です。異常なエラーレート、急なトラフィック増加、不自然な認証失敗の連続など、**インシデントの初期兆候**は観測データに現れます。強いチームは、守りの力と運用の力を分けません。

## 3) Core concepts
### Observability とは何か
Observability は、**外から見えるデータを使って、内部状態を推測・説明できる性質**です。

まずは次の 3 本柱を覚えると整理しやすいです。

- **Metrics**: 数値の時系列データ。CPU、メモリ、リクエスト数、エラー率、latency など
- **Logs**: イベントの記録。エラー内容、認証失敗、処理の流れ、監査情報など
- **Traces**: 1 リクエストが複数サービスをどう通ったかの経路情報

### Prometheus の役割
Prometheus は、**メトリクス収集と保存**に強いツールです。

基本イメージ:
- アプリや Exporter が `/metrics` を公開する
- Prometheus が定期的に scrape する
- クエリで異常や傾向を見る
- Alertmanager と組み合わせて通知につなぐ

初心者はまず、Prometheus を「**時系列の体温計を集める係**」として理解すれば十分です。

### Grafana の役割
Grafana は、集めたデータを**見える化するダッシュボード**です。

- 今どこが危ないかを一目で見る
- リリース前後の変化を見る
- CPU よりもアプリの error rate や latency を重視する

大事なのは、きれいな画面を作ることではなく、**判断に使える画面にすること**です。

### OpenTelemetry の役割
OpenTelemetry は、メトリクス・ログ・トレースを**標準化して計測しやすくする仕組み**です。

初心者向けに雑に言うと、
- 「アプリに計測ポイントを入れる」
- 「そのデータを共通フォーマットで外に出す」
- 「Prometheus や別の backend に流す」

という橋渡しです。

### まず押さえるべき 4 つの観点
#### 1. Golden Signals
Web 系ではまず次を追えると強いです。
- **Latency**: 遅くなっていないか
- **Traffic**: どれくらい使われているか
- **Errors**: 失敗率はどうか
- **Saturation**: 資源が詰まっていないか

#### 2. RED / USE の考え方
- **RED**: Rate, Errors, Duration（主にサービス/API）
- **USE**: Utilization, Saturation, Errors（主にインフラ資源）

この 2 つを知ると、「何を測るべきか」で迷いにくくなります。

#### 3. 監視と Observability は違う
- **Monitoring**: 想定した異常を検知する
- **Observability**: 想定外の問題も調査しやすくする

通知だけ多くても、原因が追えなければ苦しいです。

#### 4. Security telemetry との接点
Observability は性能のためだけではありません。

- 認証失敗の急増
- 特定 IP / User-Agent からの異常アクセス
- 権限エラーの増加
- Secret 読み取り失敗や API abuse

こうした兆候を追えるようにしておくと、アプリ運用とセキュリティ運用がつながります。

## 4) Hands-on mini lab (30-60 min)
### ゴール
Docker で Prometheus と Grafana を立て、Node Exporter の基本メトリクスを見ながら、「観測する感覚」をつかむ。

### ラボの前提
- Docker が使える
- ローカル PC 上で安全に試す
- 本番接続や外部公開はしない

### 手順
#### Step 1: 作業ディレクトリを作る
```bash
mkdir -p ~/lab/observability-basic
cd ~/lab/observability-basic
mkdir -p prometheus
```

#### Step 2: Prometheus 設定を書く
`prometheus/prometheus.yml`

```yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: prometheus
    static_configs:
      - targets: ["prometheus:9090"]

  - job_name: node
    static_configs:
      - targets: ["node-exporter:9100"]
```

#### Step 3: docker-compose.yml を作る
```yaml
services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    command:
      - --config.file=/etc/prometheus/prometheus.yml
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro
    ports:
      - "9090:9090"

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    ports:
      - "3000:3000"

  node-exporter:
    image: prom/node-exporter:latest
    container_name: node-exporter
    ports:
      - "9100:9100"
```

#### Step 4: 起動する
```bash
docker compose up -d
```

#### Step 5: Prometheus を開く
- `http://localhost:9090`
- `up`
- `rate(process_cpu_seconds_total[1m])`
- `node_cpu_seconds_total`

まずは「数字が取れている」ことを確認します。

#### Step 6: Grafana を開く
- `http://localhost:3000`
- 初期ログイン後、Prometheus を Data Source として追加
- 簡単なパネルを 1 つ作る
  - 例: `up`
  - 例: `sum(rate(node_cpu_seconds_total[1m])) by (mode)`

#### Step 7: 変化を作って観察する
別ターミナルで少し負荷を作ります。

```bash
yes > /dev/null &
sleep 20
pkill yes
```

その前後で CPU 系メトリクスがどう変わるか見ます。

#### Step 8: セキュリティ視点で振り返る
次の問いに答えてください。
- 「今の構成で認証失敗」は見えるか？
- 「アプリの 500 エラー」は見えるか？
- 「不正な急増アクセス」はどのデータが必要か？

ここで気づいてほしいのは、**Exporter だけでは十分ではなく、アプリ側の計測設計も必要**だということです。

### 片付け
```bash
docker compose down
```

## 5) Command cheatsheet
### Linux
```bash
mkdir -p ~/lab/observability-basic/prometheus
cd ~/lab/observability-basic
pwd
ls -la
cat prometheus/prometheus.yml
ss -ltnp | grep -E '3000|9090|9100'
pkill yes
```

### Docker
```bash
docker compose up -d
docker compose ps
docker compose logs --tail=50 prometheus
docker compose logs --tail=50 grafana
docker compose logs --tail=50 node-exporter
docker compose down
```

### Prometheus / Metrics
```bash
curl -s http://localhost:9090/-/healthy
curl -s http://localhost:9100/metrics | head
curl -s 'http://localhost:9090/api/v1/query?query=up'
```

### Kubernetes（関連づけだけ覚える）
```bash
kubectl get pods -A
kubectl top pods -A
kubectl top nodes
kubectl get events -A --sort-by=.lastTimestamp
```

> 今日は Kubernetes にデプロイしなくて大丈夫です。まずはローカルで「観測の型」をつかむのが先です。

## 6) Common mistakes and how to avoid them
### ミス1: CPU とメモリだけ見て満足する
**回避:** アプリ視点のメトリクスを持つ。最低でも request count / error rate / latency を意識する。

### ミス2: ダッシュボードはあるが、何を見るか決まっていない
**回避:** まず 1 画面 1 目的にする。例: API 健康状態、デプロイ影響確認、障害一次切り分け。

### ミス3: ログとメトリクスがつながっていない
**回避:** エラー増加時に、関連ログを追える設計にする。request ID や trace ID を活用する。

### ミス4: アラートを増やしすぎる
**回避:** “通知されても行動できないアラート” を減らす。まずは重大なものだけに絞る。

### ミス5: Observability を後付けにする
**回避:** 実装時点で「何を測るか」を決める。OpenTelemetry などを使って、早めに計測ポイントを入れる。

### ミス6: セキュリティ兆候を別世界に追いやる
**回避:** 認証失敗数、403/401、権限拒否、管理 API 呼び出し増加なども観測対象に入れる。

## 7) One interview-style question
**質問:** ある Web API で「たまに遅い」「でも CPU は低い」という報告があります。あなたなら Observability の観点で、まず何を見て、どんな追加計測を提案しますか？

**考えるポイント:**
- p95 / p99 latency
- endpoint ごとのエラー率
- DB や外部 API 呼び出し時間
- trace によるボトルネック特定
- saturation が CPU 以外に出ていないか

## 8) Next-step reading links
- Prometheus official docs  
  <https://prometheus.io/docs/introduction/overview/>
- Grafana official docs  
  <https://grafana.com/docs/grafana/latest/>
- OpenTelemetry official docs  
  <https://opentelemetry.io/docs/>
- Google SRE book: Monitoring Distributed Systems  
  <https://sre.google/sre-book/monitoring-distributed-systems/>
- RED method overview  
  <https://grafana.com/blog/2018/08/02/the-red-method-how-to-instrument-your-services/>
- OWASP Logging Cheat Sheet  
  <https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html>

---

## 明日の予告
次号は **Middle** に進めるなら、

- **Cloud Security 2/3**: Role 分離と least privilege の分解
- **Observability 2/3**: Alert 設計、メトリクス設計、ダッシュボードの実務化
- **DevOps core Beginner**: Docker hardening / secrets management / CI/CD security の土台

のどれかがきれいです。Beginner → Middle → Advanced の弧を何度も回すことで、知識が「知っている」から「使える」に変わっていきます。
