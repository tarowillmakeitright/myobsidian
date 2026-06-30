# 2026-06-30 SecDevOps Magazine
[[Home]]

#security #devops #docker #kubernetes #terraform #linux #cloudsecurity #observability #daily

---

## 今日の学習アーク
- **Arc 1 / Middle**
- 今週の流れ: **Linux command mastery → Observability → Kubernetes incident drills**
- 6/29 の Beginner で学んだ Linux 権限・プロセス・ログ確認を土台に、今日は **Prometheus / Grafana / OpenTelemetry を使った観測の実務基礎** に進みます。
- 次号以降の Advanced では、Kubernetes incident drills と rollback / recovery に接続して、**「見える」から「素早く戻せる」** へ進めます。

### Middle の前提知識
- `ps`, `grep`, `tail`, `journalctl` で基本的なログ確認ができる
- アプリ障害時に「プロセス」「ログ」「ポート」を切り分ける感覚がある
- HTTP の基本（status code, latency）の意味がわかる

---

## 1) Topic + Level
**Observability / Prometheus・Grafana・OpenTelemetry で“壊れ方が見える”状態を作る**

**Level: Middle**

---

## 2) Why it matters in real projects
実案件でつらいのは、障害そのものより **「何が起きているか分からない時間」** です。

たとえば、こんな場面はよくあります。
- API の一部だけ遅いが、アプリログでは原因が見えない
- Kubernetes 上では Pod は Running なのに、ユーザーは 500 を見ている
- CI/CD 後にエラー率が上がったが、どの変更が効いたのか追えない
- Auth や Session 周りの不具合が、DB・キャッシュ・外部 API のどこ由来か分からない
- Incident response の最初の 10 分で、勘ではなくデータで判断したい

ここで効くのが Observability です。

Monitoring を「死活監視」だけで終わらせず、
- **metrics** で全体傾向を見る
- **logs** で具体的な失敗を掘る
- **traces** で遅延の経路を追う

という 3 層で観測できると、AppSec と DevOps の両方が強くなります。

Security 的には、認証失敗の急増、セッション異常、権限エラー、異常トラフィックの検知が早くなります。DevOps 的には、リリース後の退行、ボトルネック、依存先障害、rollback 判断が速くなります。

つまり Observability は「便利なダッシュボード」ではなく、**安全に速く直すための共通言語** です。

---

## 3) Core concepts

### A. Observability は “システムの内側を外から説明できる力”
単に監視項目を並べるだけでは不十分です。

観測のゴールは、問題が起きたときに次を説明できることです。
- いつからおかしいか
- どの範囲に影響があるか
- 何が先に壊れたか
- どこが一番遅いか
- rollback すべきか、待てるか

つまり、Observability は「見えている感」ではなく、**判断に使える可視化** が本体です。

### B. Metrics / Logs / Traces の役割分担
#### Metrics
数値の時系列です。
例:
- request rate
- error rate
- latency
- CPU / memory
- queue backlog

強み:
- 全体傾向を速く見るのが得意
- Alert に向く
- リリース前後比較に強い

弱み:
- “なぜ” の深掘りには限界がある

#### Logs
イベントの記録です。
例:
- login failed
- permission denied
- db timeout
- token validation error

強み:
- 具体的な失敗内容が分かる
- Security イベントとの相性が良い

弱み:
- 多すぎると読めない
- 相関付けが弱いと「木を見て森を見ず」になる

#### Traces
1 リクエストが複数サービスをどう通ったかを追う記録です。
例:
- API Gateway → auth service → user service → DB

強み:
- どこで遅くなったかが追いやすい
- マイクロサービスや外部依存が多いほど効く

弱み:
- 計装が必要
- 最初は概念に慣れるまで少し重い

### C. Prometheus の基本
Prometheus は metrics を集めてクエリする定番ツールです。

押さえたいポイント:
- target から **pull** で metrics を取りにいくことが多い
- `/metrics` endpoint で公開される形式を読む
- 時系列データとして保存し、PromQL で問い合わせる

よく見る指標:
- `http_requests_total`
- `http_request_duration_seconds`
- `process_cpu_seconds_total`
- `up`

Middle では、まず
- **今生きているか**
- **エラー率は上がっているか**
- **遅延は悪化しているか**

の 3 軸が読めれば十分強いです。

### D. Grafana の基本
Grafana は “見る面” を整える役です。

重要なのは、きれいなダッシュボードを作ることではなく、**障害対応で見る順番を固定すること** です。

たとえば最初の 1 画面にあると強いもの:
- request volume
- error rate
- p95 / p99 latency
- CPU / memory
- deploy marker

これがあると、「いつから悪化したか」「デプロイと同時か」「アプリか infra か」がかなり分かります。

### E. OpenTelemetry の基本
OpenTelemetry は telemetry を取るための共通規格・計装の土台です。

覚えたい用語:
- **trace**: 1 リクエスト全体
- **span**: その中の 1 区間
- **attribute**: span に付く情報
- **instrumentation**: アプリに観測用コードを入れること

OpenTelemetry を使うと、言語やツールが違っても、trace / metric / log を比較的一貫した形で扱いやすくなります。

### F. SLI / SLO の入口
Middle では厳密な運用設計まで行かなくて大丈夫ですが、考え方は知っておくと強いです。

- **SLI**: 何を測るか（例: 成功率、応答時間）
- **SLO**: どこまでを良しとするか（例: 99.9% 成功率）

これがあると、
- どの error rate で rollback するか
- どの latency 悪化を incident とみなすか

が感覚ではなく基準になります。

### G. Security と Observability の接点
Observability は性能だけの話ではありません。

Security で見るべき例:
- login failure の急増
- 401 / 403 の急増
- privilege error の増加
- token validation 失敗
- secret 読み出し失敗
- 普段と違う path / user-agent / burst traffic

AppSec の文脈では、**認証・認可の異常を“早く、広く”見つける仕組み** として重要です。

### H. Goodhart’s law に注意する
指標は大事ですが、指標だけ追うと危険です。

例:
- 平均 latency だけ見て p95/p99 を見ない
- error 数だけ見て、どのユーザーが困っているかを見ない
- “アラートが鳴っていない” を健康と勘違いする

大事なのは、**数値・ログ・体感影響をつなげること** です。

---

## 4) Hands-on mini lab (30-60 min)
### ゴール
- ローカルで metrics を見る
- Prometheus で scrape 対象を理解する
- Grafana 的な視点で「どの指標を見るべきか」を整理する
- OpenTelemetry の trace を観測の地図として理解する

### 前提
- Docker が使える
- Linux シェルが使える
- 外部公開不要、ローカル学習のみ

### Step 1: 作業ディレクトリを作る
```bash
mkdir -p ~/lab/observability-middle
cd ~/lab/observability-middle
```

### Step 2: Prometheus 設定を書く
`prometheus.yml` を作成:
```yaml
global:
  scrape_interval: 5s

scrape_configs:
  - job_name: prometheus
    static_configs:
      - targets: ['localhost:9090']

  - job_name: node-exporter
    static_configs:
      - targets: ['node-exporter:9100']
```

### Step 3: Docker ネットワークを作る
```bash
docker network create obs-lab || true
```

### Step 4: node-exporter を起動
```bash
docker run -d --name node-exporter \
  --network obs-lab \
  -p 9100:9100 \
  prom/node-exporter
```

### Step 5: Prometheus を起動
```bash
docker run -d --name prometheus \
  --network obs-lab \
  -p 9090:9090 \
  -v "$PWD/prometheus.yml:/etc/prometheus/prometheus.yml:ro" \
  prom/prometheus
```

### Step 6: metrics を確認
```bash
curl -s http://127.0.0.1:9090/-/healthy
curl -s http://127.0.0.1:9100/metrics | head -20
```

### Step 7: Prometheus UI で基本クエリを試す
ブラウザで `http://127.0.0.1:9090` を開き、次を試します。
- `up`
- `rate(node_cpu_seconds_total[1m])`
- `node_memory_MemAvailable_bytes`
- `node_load1`

考えるポイント:
- target はちゃんと scrape されているか
- CPU 使用率の急上昇はどこで見えるか
- memory の余裕はどの指標で追えるか

### Step 8: 疑似的に負荷を作る
別ターミナルで軽く CPU を使います。
```bash
yes > /dev/null &
PID=$!
sleep 20
kill $PID
```
その間に Prometheus 側で `rate(node_cpu_seconds_total[1m])` を再確認します。

### Step 9: OpenTelemetry の考え方を文章化
次の 1 リクエストを想像して、span を紙やメモに書きます。
- browser
- nginx / api gateway
- auth service
- app service
- database

それぞれについて:
- どこで latency が乗るか
- どこで 401/403/500 が起きうるか
- どこに trace attribute を付けたいか

を書いてください。

### Step 10: ふりかえり
次の 4 問に短く答えます。
1. metrics だけでは分からないことは何か
2. logs だけではつらい理由は何か
3. traces があると嬉しい場面は何か
4. rollback 判断に使いたい 3 指標は何か

### 後片付け
```bash
docker rm -f prometheus node-exporter
# 必要なら
# docker network rm obs-lab
```

---

## 5) Command cheatsheet
### Linux
```bash
ps aux --sort=-%cpu | head
ss -tulpn
curl -s http://127.0.0.1:9090/-/healthy
curl -s http://127.0.0.1:9100/metrics | head -20
journalctl -n 50 --no-pager
```

### Docker
```bash
docker network create obs-lab
docker run -d --name node-exporter --network obs-lab -p 9100:9100 prom/node-exporter
docker run -d --name prometheus --network obs-lab -p 9090:9090 -v "$PWD/prometheus.yml:/etc/prometheus/prometheus.yml:ro" prom/prometheus
docker ps
docker logs prometheus
docker logs node-exporter
docker rm -f prometheus node-exporter
```

### Kubernetes（実務で関連づける時）
```bash
kubectl top pods -A
kubectl top nodes
kubectl get pods -A
kubectl logs <pod-name> -n <namespace>
kubectl describe pod <pod-name> -n <namespace>
```

### Terraform / IaC（監視設定レビューの入口）
```bash
grep -R "prometheus\|grafana\|otel\|opentelemetry\|alert" .
terraform fmt -recursive
terraform validate
terraform plan
```

---

## 6) Common mistakes and how to avoid them
### ミス1: CPU と memory だけ見て満足する
**問題:** ユーザー影響は error rate や latency に先に出ることが多いです。
**回避:** Golden Signals（latency, traffic, errors, saturation）を意識する。

### ミス2: 平均値だけ見る
**問題:** 一部ユーザーだけ極端に遅い問題を見逃します。
**回避:** 平均だけでなく p95 / p99 も見る。

### ミス3: ログに request ID や trace 情報がない
**問題:** ある 1 件の障害を追いにくいです。
**回避:** 相関 ID をログに残し、trace とつなげる設計をする。

### ミス4: ダッシュボードが多すぎて incident 中に迷う
**問題:** いざという時に見る順番が崩れます。
**回避:** “最初の 1 画面” を固定し、運用手順に組み込む。

### ミス5: Alert を増やしすぎる
**問題:** ノイズで本当に危ない signal が埋もれます。
**回避:** 行動につながる alert だけを残す。鳴った後に何をするか決める。

### ミス6: Security イベントを性能監視から切り離す
**問題:** 認証失敗増加や token error を見逃しやすいです。
**回避:** 401/403、login failure、permission denied も観測対象に入れる。

### ミス7: メトリクスのラベルを雑に増やす
**問題:** カーディナリティ爆発でコスト・性能が悪化します。
**回避:** `user_id` のような高カーディナリティ値を安易にラベル化しない。

---

## 7) One interview-style question
**質問:**
本番 API の deploy 後に「一部ユーザーだけ遅い」という報告が来ました。あなたは Prometheus・Grafana・Logs・Trace をどういう順番で見て、どの段階で rollback を検討しますか？

**考える観点:**
- request volume と error rate の変化
- p95 / p99 latency
- deploy 時刻との相関
- 特定 endpoint / auth / DB への偏り
- rollback で止血すべき閾値の定義

---

## 8) Next-step reading links
- Prometheus documentation: https://prometheus.io/docs/introduction/overview/
- Prometheus query basics (PromQL): https://prometheus.io/docs/prometheus/latest/querying/basics/
- Grafana documentation: https://grafana.com/docs/grafana/latest/
- OpenTelemetry documentation: https://opentelemetry.io/docs/
- Google SRE Book - Monitoring Distributed Systems: https://sre.google/sre-book/monitoring-distributed-systems/
- OWASP Logging Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html
- OWASP Secrets Management Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html
- Kubernetes resource metrics pipeline: https://kubernetes.io/docs/tasks/debug/debug-cluster/resource-metrics-pipeline/
- AWS Well-Architected - Operational Excellence: https://docs.aws.amazon.com/wellarchitected/latest/operational-excellence-pillar/welcome.html
- Google Cloud Observability docs: https://cloud.google.com/stackdriver/docs

---

## 次号予告
**Advanced 予告:** Kubernetes incident drills で、failure / rollback / recovery を 1 本の流れで演習します。

### Advanced の前提知識
- metrics / logs / traces の役割分担を説明できる
- Prometheus で `up`、error rate、latency 系指標を読む感覚がある
- デプロイ後の異常を “見る順番” として整理できる

次号では、今日の Observability を土台にして、実際に Kubernetes の rollout failure をどう検知し、どのタイミングで rollback し、どこまで recovery を確認するかを扱います。
