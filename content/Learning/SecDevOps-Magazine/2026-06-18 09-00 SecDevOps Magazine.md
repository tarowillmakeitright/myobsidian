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

# 2026-06-18 09-00 SecDevOps Magazine

## 1) Topic + Level
**Observability: Prometheus Alerting / Grafana Dashboard / OpenTelemetry の実務導入**  
**Level: Middle**

> 学習アーク: Observability 2/3  
> 前提知識: Metrics / Logs / Traces の基本、Prometheus の scrape 概念、Grafana の基本操作、Docker の基本操作。  
> 次回予定: Advanced（SLO / high-cardinality / distributed tracing の深掘り）

## 2) Why it matters in real projects
実務では、監視を入れただけでは強くなれません。大事なのは、**異常を早く見つけ、原因に近い場所まで素早く絞り込めること**です。

たとえば本番でこんな状況はよく起きます。

- API のレスポンスは遅いが、CPU は高くない
- デプロイ直後から 5xx がじわじわ増えた
- Kubernetes 上では Pod は Running だが、ユーザー体験は壊れている
- 認証失敗が急増しているが、攻撃なのか設定ミスなのか判断がつかない

ここで必要なのが、**メトリクス・ログ・トレースをつないで考える運用**です。

Observability の Middle レベルでは、単に「見る」段階から進んで、

- 何を alert すべきか
- どの dashboard が判断に効くか
- trace と log をどう関連づけるか
- ノイズを減らしながら、本当に危ない変化を拾うか

を考えます。

セキュリティ面でも重要です。認証エラー率、権限拒否、異常なリクエスト増加、特定 endpoint の連続失敗などは、**性能問題にも攻撃兆候にも見える**ことがあります。だからこそ、DevOps と Security を分けずに観測設計する価値があります。

## 3) Core concepts
### 3-1. 「監視項目」ではなく「判断材料」を設計する
初心者は CPU / Memory グラフを並べがちですが、実務で効くのは **サービスの健康状態を直接表す指標**です。

まず優先したいのは次です。

- **Request rate**: どれくらい使われているか
- **Error rate**: どれくらい失敗しているか
- **Latency**: どれくらい遅いか
- **Saturation**: 詰まり始めていないか

これを API、worker、DB、ingress のようにレイヤーごとに持つと、調査が速くなります。

### 3-2. Alert は「壊れたこと」ではなく「対応が必要なこと」に鳴らす
良くない alert の典型:

- CPU 80% 超えただけで通知
- 一瞬の spike で即通知
- どのサービスが影響を受けたか分からない
- 毎日鳴るので誰も信じなくなる

良い alert は、**ユーザー影響や運用アクションに直結**しています。

例:
- 5 分間の 5xx rate が 3% を超えた
- p95 latency が通常の 2 倍以上で継続した
- `/login` の認証失敗率が急増した
- Kubernetes の rollout が progress deadline exceeded になった

Prometheus では、**閾値 + 継続時間 + 対象ラベル**を意識すると alert の質が上がります。

### 3-3. Grafana dashboard は「眺める画面」ではなく「調査の入口」
良い dashboard は、見た瞬間に次の行動が決まります。

たとえば API dashboard なら:

1. 全体の traffic / error / latency
2. endpoint 別の内訳
3. instance / pod 別の偏り
4. deploy 時刻の annotation
5. 関連 log / trace への導線

つまり「異常がある」だけでなく、**どこを掘るべきか**が見える必要があります。

### 3-4. OpenTelemetry の価値は「つながること」
OpenTelemetry を入れると、1 リクエストの流れを trace として追いやすくなります。

例:
- ingress → app → auth service → DB
- どこで待ったか
- どの span が error か
- 同じ request ID / trace ID を log に出せるか

これにより、
- 「アプリが遅い」のか
- 「外部 API が遅い」のか
- 「DB 接続待ち」なのか
- 「認証 backend が不安定」なのか

を切り分けやすくなります。

### 3-5. Cardinality を甘く見ると運用が壊れる
Middle レベルで大事なのが **high-cardinality** の理解です。

Prometheus では、label の種類が増えすぎるとメモリもクエリも重くなります。

危ない例:
- `user_id`
- `session_id`
- `email`
- `request_path` に生の ID を含める
- `ip_address` をそのまま label にする

安全な考え方:
- 個人識別子は label にしない
- path はテンプレート化する（`/users/:id`）
- 必要なら log / trace 側に詳細を持たせる

これは性能だけでなく、**プライバシーと security telemetry の設計**にも関わります。

### 3-6. Security 観点で見るべきシグナル
Observability は性能だけの話ではありません。次のシグナルは defensive な運用で特に有効です。

- `/login` の失敗率増加
- `403` / `401` の急増
- IAM / RBAC denied の増加
- Secret 読み取り失敗
- 短時間での token refresh 異常
- 通常と異なる region / source からの API 使用増加

これらをメトリクス・ログ・イベントで組み合わせると、**攻撃・設定ミス・障害**の見分けが少しずつできるようになります。

## 4) Hands-on mini lab (30-60 min)
### ゴール
Docker Compose で Prometheus + Grafana を立て、簡単なサンプルメトリクスを観測しつつ、alert と dashboard の考え方を体験する。

### 前提
- Docker / Docker Compose が使える
- ローカル環境でのみ実施する
- 外部公開しない

### Step 1: 作業ディレクトリを作る
```bash
mkdir -p ~/lab/obs-middle/{prometheus,grafana}
cd ~/lab/obs-middle
```

### Step 2: `docker-compose.yml` を作る
```yaml
services:
  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - ./prometheus/alerts.yml:/etc/prometheus/alerts.yml:ro

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=admin

  node-exporter:
    image: prom/node-exporter:latest
    ports:
      - "9100:9100"
```

### Step 3: `prometheus/prometheus.yml` を作る
```yaml
global:
  scrape_interval: 15s

rule_files:
  - /etc/prometheus/alerts.yml

scrape_configs:
  - job_name: prometheus
    static_configs:
      - targets: ['prometheus:9090']

  - job_name: node
    static_configs:
      - targets: ['node-exporter:9100']
```

### Step 4: `prometheus/alerts.yml` を作る
```yaml
groups:
  - name: demo-alerts
    rules:
      - alert: HighCPUUsage
        expr: 100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 70
        for: 3m
        labels:
          severity: warning
        annotations:
          summary: "CPU usage is high on {{ $labels.instance }}"
          description: "CPU utilization has been above 70% for 3 minutes."
```

### Step 5: 起動する
```bash
docker compose up -d
```

### Step 6: 画面を確認する
- Prometheus: `http://localhost:9090`
- Grafana: `http://localhost:3000`
  - login: `admin / admin`

### Step 7: Prometheus でクエリを試す
```promql
up
```

```promql
rate(node_cpu_seconds_total[5m])
```

```promql
100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```

### Step 8: Grafana で dashboard を作る
最低限、次の 3 パネルを作る。

- CPU usage
- Memory usage
- `up` の状態

ポイント:
- タイトルを意味のあるものにする
- 単位を設定する（% / bytes など）
- 1 画面で「今危ないか」が分かる配置にする

### Step 9: 疑似的に負荷をかける
```bash
docker exec -it $(docker ps --filter name=node-exporter -q | head -n1) sh
```

`node-exporter` コンテナには余計なツールが少ないので、代わりにホスト側で軽い負荷をかけてもよいです。

例:
```bash
yes > /dev/null &
YES_PID=$!
sleep 180
kill $YES_PID
```

CPU usage の変化や alert 条件に近づく様子を見ます。

### Step 10: セキュリティ視点で振り返る
次を言語化してメモする。

- どの alert が「本当に起きてほしくない異常」を表しているか
- 認証失敗や 403 増加なら、どんな metric 名にするか
- 個人情報や token を label に入れないために何を気をつけるか

### 発展課題
余力があれば次を試す。

- Grafana annotation として deploy 時刻を記録する
- Nginx / app exporter を追加する
- request ID と trace ID を log に出す設計を考える

## 5) Command cheatsheet
### Linux
```bash
pwd
ls -la
mkdir -p ~/lab/obs-middle/{prometheus,grafana}
cd ~/lab/obs-middle
ps aux | grep yes
kill <PID>
ss -ltnp | grep -E '3000|9090|9100'
```

### Docker / Compose
```bash
docker compose up -d
docker compose ps
docker compose logs -f prometheus
docker compose logs -f grafana
docker compose down
```

### Prometheus / Observability
```promql
up
rate(node_cpu_seconds_total[5m])
avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m]))
100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```

### Kubernetes に応用するときの視点
```bash
kubectl get pods -A
kubectl top pods -A
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

## 6) Common mistakes and how to avoid them
### ミス 1: CPU / Memory だけ見て安心する
**問題:** ユーザー影響があるのに、infra 指標では見えないことがある。  
**回避:** error rate、latency、request rate を必ず見る。

### ミス 2: Alert を増やしすぎてノイズ化する
**問題:** 毎日鳴る alert は無視される。  
**回避:** 「誰がどう対応するか」を説明できる alert だけ残す。

### ミス 3: label に個人識別子を入れる
**問題:** cardinality 爆発、性能悪化、情報漏えいリスク。  
**回避:** user_id / email / token / raw IP を label にしない。

### ミス 4: Dashboard がきれいなだけで調査に使えない
**問題:** 異常は見えても、次の一手が分からない。  
**回避:** service → endpoint → pod → log / trace の流れを意識して並べる。

### ミス 5: Trace を入れたのに log と結びつかない
**問題:** 調査が分断される。  
**回避:** request ID / trace ID を log に出し、検索キーをそろえる。

### ミス 6: セキュリティイベントを observability から切り離す
**問題:** auth 異常や denied 増加を性能問題として見逃す。  
**回避:** 401 / 403 / login failure / RBAC denied も主要シグナルとして扱う。

## 7) One interview-style question
**Q.** Prometheus で application metrics を設計するとき、なぜ `user_id` や `session_id` を label に入れるべきではないのでしょうか？ 運用・性能・セキュリティの 3 つの観点から説明してください。

## 8) Next-step reading links
- Prometheus docs: https://prometheus.io/docs/introduction/overview/
- Prometheus alerting rules: https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/
- Grafana docs: https://grafana.com/docs/grafana/latest/
- OpenTelemetry docs: https://opentelemetry.io/docs/
- Google SRE book（Monitoring 分野）: https://sre.google/sre-book/monitoring-distributed-systems/
- OWASP Logging Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html
- Kubernetes monitoring basics: https://kubernetes.io/docs/tasks/debug/debug-cluster/resource-metrics-pipeline/

---

今日のポイントはシンプルです。  
**Observability は「見ること」ではなく、「迷わず判断するための材料を作ること」。**

本番で強い人は、ツールに詳しい人というより、**どの signal を残せば未来の自分が助かるか**を考えられる人です。今日の 30〜60 分は、その感覚を作る時間にしてください。
