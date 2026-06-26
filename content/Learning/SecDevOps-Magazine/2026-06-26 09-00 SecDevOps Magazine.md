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

# SecDevOps Magazine — 2026-06-26

## 1) Topic + Level
**Observability Middle / Prometheus・Grafana・OpenTelemetry で “遅いAPIの真犯人” を切り分ける**  
**Level: Middle**

**Prerequisites:**
- Metrics / Logs / Traces の役割を説明できる
- Prometheus が `/metrics` を scrape する流れを理解している
- Grafana で基本グラフを見たことがある
- Docker Compose の基本操作ができる

---

## 2) Why it matters in real projects
Beginner では「見える状態を作る」ことが入口でした。実務の次の壁は、**見えていても判断できない** ことです。

たとえば現場では、こんな事故が普通に起きます。

- API の p95 latency だけが急に悪化した
- CPU は平常なのにユーザー体感は遅い
- DB エラーは少ないのにタイムアウトが増えた
- デプロイ直後から 401 / 403 / 5xx がじわじわ増えた
- Kubernetes 上では Pod は生きているのに、実際のリクエストは詰まっている

ここで必要なのは「監視画面を見る力」ではなく、**仮説を立てて切り分ける力** です。

Observability の中級で大事なのは、単にメトリクスを集めることではありません。

- **どの指標を先に見るか**
- **アプリ起因か、インフラ起因か、依存先起因か**
- **性能劣化なのか、セキュリティ異常なのか**
- **新しいデプロイが原因か、それともトラフィック特性の変化か**

を短時間で切り分けることです。

防御側の視点でも重要です。ブルートフォース、token misuse、権限設定ミス、想定外リトライ、過剰なスクレイピング、bot 的アクセスは、**“セキュリティイベント” と “性能問題” の顔を両方持つ** ことが多いからです。

つまり中級の Observability は、SRE のためだけではなく、**AppSec と DevOps が同じ地図を持つための技術** です。

---

## 3) Core concepts

### 3-1. RED と USE を混ぜて考える
実務で強い観測の基本パターンとして、まず 2 つ覚えると便利です。

- **RED**: Rate / Errors / Duration
  - API やサービスの健康状態を見る
- **USE**: Utilization / Saturation / Errors
  - CPU、memory、disk、network など基盤資源を見る

ざっくり言うと、
- **ユーザー体感の異常** は RED で見る
- **土台の詰まり** は USE で見る

たとえば API が遅いとき、いきなり CPU グラフを見るのではなく、先に
- リクエスト数は増えたか
- エラー率は上がったか
- p95 / p99 は悪化したか

を確認し、その後で
- CPU saturation
- memory pressure
- DB connection pool
- Pod restart

を見ると、切り分けが速くなります。

### 3-2. “平均” ではなく分布を見る
実務では平均 latency はかなり危険です。

- 平均 200ms
- でも p95 は 1.8s
- p99 は 5s

みたいなことが普通にあります。これは「大多数は普通だが、一部のリクエストがひどく遅い」状態です。

中級からは次を意識します。
- **p50**: 典型的な速さ
- **p95**: だいたいの悪い体験
- **p99**: かなり悪い端の体験

セキュリティ視点でも重要で、攻撃や misuse は平均値より **裾の悪化** に出やすいです。

### 3-3. Golden Signals を “依存先” まで伸ばす
Google SRE 文脈の Golden Signals は有名ですが、重要なのはアプリ単体で終わらせないことです。

見るべき代表例:
- app request rate
- app error rate
- app latency
- DB query latency
- DB connection saturation
- upstream HTTP dependency latency
- cache hit ratio
- auth failure rate

よくある失敗は、「アプリが遅い」からアプリのコードだけ疑うことです。実際には、
- RDS 接続待ち
- DNS 解決遅延
- 外部 API の劣化
- rate limit
- 認証基盤の詰まり

が真犯人のことも多いです。

### 3-4. Logs は “検索用文章” ではなく “構造化データ” にする
中級からは plain text の雰囲気ログだけでは厳しくなります。

悪い例:
```text
something bad happened while processing user request
```

良い方向:
```json
{"level":"error","route":"/login","status":401,"user_id":"anonymous","client_ip":"203.0.113.10","trace_id":"abc123","msg":"auth failed"}
```

構造化ログの利点:
- route ごとに集計しやすい
- 401 / 403 / 500 を絞りやすい
- trace_id で traces と結びつけやすい
- セキュリティ調査で時系列相関しやすい

**Observability が弱いチームほど、ログを人間向け文章に寄せすぎます。** 中級からは機械で絞れる形を意識します。

### 3-5. Trace は “どこで時間を食ったか” を見る
Trace は単に「きれいな画面」のためではありません。

見るポイント:
- どの span が最も遅いか
- 外部呼び出し待ちか
- DB query か
- auth middleware か
- retry が連鎖していないか

特に API の遅さで便利なのは、**アプリコードの処理時間** と **依存先待ち時間** を分けて見られることです。

これができると、
- 開発者はコード最適化が必要か判断しやすい
- DevOps はインフラや接続数の問題を疑いやすい
- AppSec は auth / session / WAF / policy まわりの異常を追いやすい

### 3-6. Alert は “症状” と “原因候補” を混ぜない
初心者の頃は何でも alert にしがちです。でも中級では設計を分けます。

- **症状アラート**: ユーザー影響に近いもの
  - 5xx 増加
  - p95 latency 悪化
  - availability 低下
- **原因候補アラート**: 掘るための手がかり
  - Pod restart 増加
  - DB connection saturation
  - node disk pressure
  - auth backend timeout

この分離がないと、アラートが多すぎて本当に痛いものを見落とします。

### 3-7. セキュリティ異常は “失敗の偏り” に出る
AppSec 視点で中級者が見たいのは、単なる失敗数ではなく **偏り** です。

たとえば:
- `/login` だけ 401 が急増
- 特定の User-Agent だけ 429 が多い
- ある namespace だけ secret mount error が多い
- 管理 API だけ p99 が極端に悪い
- 同じ source IP が短時間で大量 token refresh

このとき重要なのは、
- route
- status code
- client identity
- source IP / ASN
- user / service account
- deployment version

で切って見られることです。

### 3-8. Deployment と観測を結びつける
実務では「問題が起きた日」ではなく、**“何を変えた直後か”** が鍵です。

最低でも次を結びつけると強いです。
- deploy time
- image tag / release version
- config change
- feature flag change
- Terraform apply / infra rollout

Grafana annotation やログの release label があるだけで、原因調査はかなり速くなります。

---

## 4) Hands-on mini lab (30-60 min)
**テーマ: 遅い API を Metrics + Logs + Traces の頭で切り分ける練習**

### ゴール
- p95 latency 悪化を確認する
- 遅延の原因が “CPU不足” ではなく “アプリ側 sleep/依存先待ち” っぽいと判断する
- access log と metrics を突き合わせる
- 監視を見る順番を自分で言語化する

### 準備
Docker / Docker Compose が使えるローカル環境を想定します。

### Step 1: 作業ディレクトリを作る
```bash
mkdir -p ~/lab/observability-middle
cd ~/lab/observability-middle
```

### Step 2: `docker-compose.yml` を作る
```yaml
services:
  web:
    image: nginx:alpine
    ports:
      - "8080:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./html:/usr/share/nginx/html:ro

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
```
```

### Step 3: `prometheus.yml` を作る
```yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: prometheus
    static_configs:
      - targets: ["prometheus:9090"]
```

### Step 4: `nginx.conf` を作る
```nginx
events {}
http {
  log_format main '$remote_addr - $remote_user [$time_local] '
                  '"$request" $status $body_bytes_sent '
                  'rt=$request_time ua="$http_user_agent"';

  access_log /var/log/nginx/access.log main;

  server {
    listen 80;

    location / {
      root /usr/share/nginx/html;
      index index.html;
    }

    location /slow {
      return 200 'slow endpoint\n';
      add_header Content-Type text/plain;
    }
  }
}
```

### Step 5: `html/index.html` を作る
```html
<html><body><h1>ok</h1></body></html>
```

### Step 6: 起動する
```bash
docker compose up -d
```

### Step 7: 通常アクセスと遅延アクセスを混ぜて流す
まず通常アクセス:
```bash
for i in $(seq 1 30); do curl -s http://localhost:8080/ > /dev/null; done
```

次に遅延を疑うリクエストをまとめて打つ:
```bash
for i in $(seq 1 20); do curl -s http://localhost:8080/slow > /dev/null; done
```

### Step 8: アクセスログを見る
```bash
docker compose exec web sh -c 'tail -n 50 /var/log/nginx/access.log'
```

見るポイント:
- `/` と `/slow` の比率
- status code
- `rt=` の値
- 特定 UA や特定 IP に偏りがないか

### Step 9: “もしこれが本番なら” の切り分けメモを書く
以下をノートに 5 分で書いてください。

1. 最初に見るダッシュボードは何か  
2. 次に見るログ条件は何か  
3. 遅延原因がアプリ / DB / 外部 API / auth のどれかをどう切るか  
4. セキュリティ異常なら何が兆候になるか

### Step 10: 発展課題
余裕があれば次を追加してください。
- `/login` への 401 を模したアクセスを作る
- 特定 User-Agent だけ大量リクエストを送る
- `docker stats` を見て CPU では説明しにくいことを確認する

```bash
for i in $(seq 1 30); do curl -A 'suspicious-bot/1.0' -s http://localhost:8080/slow > /dev/null; done

docker stats --no-stream
```

**このラボの本質:**
今日は完璧な OpenTelemetry パイプライン構築が目的ではありません。  
**「現象を見て、どこから疑うか」を口で説明できるようになること** が勝ちです。

---

## 5) Command cheatsheet

### Linux
```bash
# 待ち受けポート確認
ss -lntp

# プロセス確認
ps aux | grep -E 'nginx|prometheus|grafana'

# ログを追う
journalctl -xe --no-pager

# 簡易ベンチ的に叩く
for i in $(seq 1 10); do curl -w '%{http_code} %{time_total}\n' -o /dev/null -s http://localhost:8080/slow; done
```

### Docker / Compose
```bash
# 起動

docker compose up -d

# 状態確認

docker compose ps

# ログ確認

docker compose logs -f web

docker compose logs -f prometheus

# コンテナ内ログ確認

docker compose exec web sh -c 'tail -n 100 /var/log/nginx/access.log'

# リソース確認

docker stats --no-stream

# 停止

docker compose down
```

### Kubernetes
```bash
# Pod 状態確認
kubectl get pods -A

# 特定 Pod の詳細
kubectl describe pod <pod-name> -n <namespace>

# ログ確認
kubectl logs <pod-name> -n <namespace>

# 直近イベント確認
kubectl get events -A --sort-by=.lastTimestamp | tail -n 30

# 再起動回数確認
kubectl get pods -A --output=wide
```

### Terraform / IaC
```bash
# 監視・ログ・トレース関連コード検索
grep -R "prometheus\|grafana\|otel\|opentelemetry\|alert" .

# 変更の書式と妥当性確認
terraform fmt -recursive
terraform validate

# plan で監視系リソース差分を見る
terraform plan
```

---

## 6) Common mistakes and how to avoid them

### ミス1: ダッシュボードを上から順番に眺める
**問題:** 調査が遅く、ノイズに飲まれます。  
**回避:** 先に RED、その後 USE。ユーザー影響 → 原因候補の順で見る。

### ミス2: 遅い = CPU 高いはず、と決め打ちする
**問題:** 外部 API、DB 接続待ち、lock、auth backend timeout を見落とします。  
**回避:** CPU が平常でも latency は壊れると覚える。

### ミス3: ログに route / status / trace_id を残さない
**問題:** 401 が増えたのか、500 が増えたのか、どの処理かを追えません。  
**回避:** 構造化ログで最低限のキーを固定する。

### ミス4: “エラー率” だけ見て 401 / 403 を無視する
**問題:** セキュリティ事故や auth 問題を取り逃します。  
**回避:** 5xx だけでなく 401 / 403 / 429 も分けて追う。

### ミス5: 新デプロイとの相関を見ない
**問題:** 原因調査が長引きます。  
**回避:** release version や deploy timestamp を必ず観測データに結びつける。

### ミス6: Alert を増やしすぎて全部同じ重さにする
**問題:** 本当に痛い障害が埋もれます。  
**回避:** 症状アラートと原因候補アラートを分ける。

### ミス7: “botっぽい変なアクセス” を performance issue とだけ見る
**問題:** 防御判断が遅れます。  
**回避:** User-Agent、source IP、path、status 偏りを必ず見る。

---

## 7) One interview-style question
**質問:**  
「本番で `/login` の p95 latency が急に悪化し、401 も増えています。CPU と memory は平常です。あなたなら Metrics・Logs・Traces・Deployment 情報をどの順で見て、アプリ不具合・認証基盤障害・攻撃兆候をどう切り分けますか？」

**考えるポイント:**
- 最初に確認する RED 指標は何か
- 401 と latency を同時に見る意味
- route / User-Agent / source IP / release version で切る価値
- trace があると auth middleware や upstream dependency をどう見られるか
- どこから “性能問題” ではなく “セキュリティ異常” を疑うか

---

## 8) Next-step reading links
- Prometheus best practices  
  https://prometheus.io/docs/practices/naming/
- Grafana documentation  
  https://grafana.com/docs/
- OpenTelemetry documentation  
  https://opentelemetry.io/docs/
- SRE Golden Signals overview  
  https://sre.google/sre-book/monitoring-distributed-systems/
- OWASP Logging Cheat Sheet  
  https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html
- OWASP Kubernetes Top Ten  
  https://owasp.org/www-project-kubernetes-top-ten/
- Kubernetes debug running pods  
  https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/

---

## ひとこと
中級の Observability は、ツール暗記ではありません。  
**“遅い”“失敗している”“怪しい” を同じ地図の上で切り分けられること** が本当の前進です。

Beginner で「見える」を作ったなら、今日は **「見て判断する」** に進む日です。