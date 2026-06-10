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
links:
  - "[[Home]]"
date: 2026-06-10
series: SecDevOps Magazine
level: Middle
topic: Observability
---

# 2026-06-10 09-00 SecDevOps Magazine

#security #devops #docker #kubernetes #terraform #linux #cloudsecurity #observability #daily

[[Home]]

## 1) Topic + Level
**Observability: Prometheus / Grafana / OpenTelemetry で作る最小監視スタック**  
**Level: Middle**

> 学習アーク: Observability 実践編の 2 本目。Beginner で「metrics / logs / traces の違い」を押さえた前提で、今回は実際に最小構成を組む回です。次回 Advanced では「障害時のボトルネック特定、SLO/Alert 設計、Kubernetes incident drill との接続」に進みます。

**Prerequisites:**
- Linux の基本コマンド（`curl`, `ps`, `ss`, `journalctl` など）
- Docker / Docker Compose の基本
- HTTP アプリが `/metrics` のようなエンドポイントを公開するイメージ
- Beginner レベルの監視知識（CPU 使用率やレスポンス時間が何を意味するか）

## 2) Why it matters in real projects
本番障害で本当に困るのは、「壊れた」ことそのものよりも、**どこが・なぜ・どのくらい壊れているのか分からない**状態です。

Observability が弱い現場では、よくこんなことが起きます。

- アプリが遅いのに、アプリ問題か DB 問題かネットワーク問題か切り分けできない
- CPU は正常なのにエラー率が上がっていて、気づくのが遅れる
- 「昨日から遅い」が感覚論になり、改善の優先順位が決まらない
- インシデント後に「その時どうなっていたか」を再現できない

逆に、Prometheus / Grafana / OpenTelemetry を最低限でも整えると、次ができるようになります。

- メトリクスで異常を早く見る
- ダッシュボードで傾向を掴む
- Trace で遅延箇所を追う
- インシデント drill や rollback 判断をデータで支える

つまり Observability は、**安心して変更を出すための土台**です。DevOps でも Security でも、「見えること」は防御力そのものです。

## 3) Core concepts

### 3-1. Monitoring と Observability は似ているけど同じではない
- **Monitoring**: 事前に決めた指標を見張る
- **Observability**: 未知の問題も、手元の情報から推測・調査できる状態を作る

監視だけだと「CPU 80% 超え」で止まりがちです。Observability はそこから一歩進んで、**なぜ 80% なのか**を追えるようにします。

### 3-2. 3 本柱: Metrics / Logs / Traces
- **Metrics**: 数値の時系列。CPU、メモリ、RPS、error rate、latency など
- **Logs**: イベントの記録。例外、認証失敗、デプロイ記録など
- **Traces**: 1 リクエストが複数サービスをどう流れたか

実務では、この 3 つがつながって初めて強いです。

- メトリクスで異常に気づく
- ログで具体的な失敗を見る
- トレースでどこが詰まっているか辿る

### 3-3. Prometheus の役割
Prometheus は、アプリや exporter が公開する `/metrics` を定期的に scrape して保存する仕組みです。

重要ポイント:
- pull 型が基本
- ラベル（`job`, `instance`, `status` など）で絞り込める
- PromQL で集計できる

たとえば `http_requests_total` があるだけでも、増加量やエラー率を計算できます。

### 3-4. Grafana の役割
Grafana は「可視化の顔」です。Prometheus だけでも数値は取れますが、Grafana があると次が楽になります。

- 時系列グラフを見る
- サービスごとの比較をする
- 障害時に共有しやすいダッシュボードを作る
- チームの共通言語にする

### 3-5. OpenTelemetry の役割
OpenTelemetry は、アプリから telemetry を標準的に出すための仕組みです。

- metrics
- logs
- traces

特に trace で強いです。アプリが複数サービスに分かれてくると、単なるログ grep だけでは追えません。OpenTelemetry を使うと、1 リクエストが API → app → DB → 外部 API と流れる様子を追いやすくなります。

### 3-6. RED / USE の見方
中級で覚えると強いフレームです。

**RED（サービス視点）**
- **Rate**: リクエスト数
- **Errors**: エラー数 / エラー率
- **Duration**: レイテンシ

**USE（インフラ視点）**
- **Utilization**
- **Saturation**
- **Errors**

アプリ障害かノード障害かを切り分けるときに役立ちます。

### 3-7. Security 的にも重要
Observability は運用だけでなく防御にも効きます。

- 認証失敗の急増を見つける
- 特定 API への異常アクセスを検知する
- 権限変更やデプロイ変更の時間帯を追う
- Incident Response の初動を速くする

「ログを残している」だけでは足りません。**見つけやすく、相関しやすく、振り返りやすい**ことが重要です。

## 4) Hands-on mini lab (30-60 min)
**目的:** Docker Compose で Prometheus + Grafana + サンプルアプリを立ち上げ、メトリクスが見える体験を作る

### ゴール
- Prometheus が `/metrics` を scrape できる
- Grafana で request rate と error rate を見られる
- 異常をわざと起こしてグラフが変わることを確認する

### Step 1: 作業ディレクトリを作る
```bash
mkdir -p ~/labs/observability-basic
cd ~/labs/observability-basic
```

### Step 2: `docker-compose.yml` を作る
```yaml
services:
  app:
    image: prom/node-exporter:latest
    container_name: demo-metrics-app
    ports:
      - "9100:9100"

  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml:ro

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    ports:
      - "3000:3000"
```

> まずは理解優先で最小構成にしています。実務では永続化 volume、認証、バージョン固定、ネットワーク分離も追加してください。

### Step 3: `prometheus.yml` を作る
```yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: "node-exporter"
    static_configs:
      - targets: ["app:9100"]
```

### Step 4: 起動する
```bash
docker compose up -d
```

確認:
```bash
docker compose ps
curl -s http://localhost:9100/metrics | head
curl -s http://localhost:9090/-/healthy
```

### Step 5: Prometheus でクエリしてみる
ブラウザで `http://localhost:9090` を開き、以下を試します。

- `up`
- `node_cpu_seconds_total`
- `node_memory_MemAvailable_bytes`

### Step 6: Grafana を開く
- URL: `http://localhost:3000`
- 初期ログイン: `admin / admin`（初回変更を忘れない）
- Data Source に Prometheus (`http://prometheus:9090`) を追加
- パネルを 2 つ作る
  - CPU 使用傾向
  - 空きメモリ

### Step 7: 変化を発生させる
別ターミナルで軽い負荷をかけます。
```bash
yes > /dev/null &
yes > /dev/null &
```

数分観察してから止めます。
```bash
pkill -f '^yes$'
```

確認ポイント:
- CPU 系メトリクスが上がったか
- Grafana の線が変わったか
- 「変化を起こす → 観測する」の往復ができたか

### Step 8: OpenTelemetry につなげて考える
今回は node-exporter 中心ですが、次をメモしてください。
- Web アプリならどのリクエストに trace を付けたいか
- auth failure をどのメトリクス/ログに出すか
- SLO を置くなら何を指標にするか

## 5) Command cheatsheet

### Linux
```bash
# リスニングポート確認
ss -lntp | grep -E '3000|9090|9100'

# プロセス確認
ps aux | grep -E 'prometheus|grafana|node-exporter'

# 直近ログ確認
journalctl -xe --no-pager | tail -n 50

# HTTP 応答確認
curl -I http://localhost:9090
curl -I http://localhost:3000
```

### Docker
```bash
# 起動状態
 docker compose ps

# ログ確認
 docker compose logs prometheus
 docker compose logs grafana

# コンテナ情報
 docker inspect prometheus | jq '.[0].NetworkSettings.Ports'

# 停止と削除
 docker compose down
```

### Prometheus / Metrics
```bash
# ヘルスチェック
curl -s http://localhost:9090/-/healthy

# metrics を直接見る
curl -s http://localhost:9100/metrics | less

# up 指標の確認イメージ
# Prometheus UI で: up
```

### Kubernetes（実務接続用の基本）
```bash
# 監視 namespace の確認
kubectl get ns

# Pod 状態確認
kubectl get pods -A | grep -Ei 'prometheus|grafana|otel'

# Service 確認
kubectl get svc -A | grep -Ei 'prometheus|grafana'

# Pod ログ確認
kubectl logs -n monitoring deploy/prometheus
```

### Terraform（監視基盤を IaC 化する時の基本）
```bash
terraform fmt -recursive
terraform validate
terraform plan
```

## 6) Common mistakes and how to avoid them

### ミス 1: ダッシュボードを作っただけで満足する
**問題:** 眺めるだけで、異常判断の基準がない。  
**回避:** Rate / Error / Duration を最低限決める。アラート条件の素案まで書く。

### ミス 2: `latest` イメージをそのまま本番監視基盤に使う
**問題:** 再現性が落ち、急な挙動変化の原因になる。  
**回避:** 監視基盤もバージョン固定し、更新手順を管理する。

### ミス 3: ログ・メトリクス・トレースが分断される
**問題:** 異常検知後の深掘りが遅い。  
**回避:** 少なくとも service 名、environment、version などの共通ラベル/属性を揃える。

### ミス 4: 高 cardinality ラベルを無邪気に増やす
**問題:** Prometheus が重くなり、コストも上がる。  
**回避:** `user_id` や raw URL 全件のような爆発しやすいラベルは避ける。

### ミス 5: Grafana の初期認証を放置する
**問題:** 監視画面がそのまま覗ける危険がある。  
**回避:** 初期パスワード変更、ネットワーク制限、SSO 導入を早めに行う。

### ミス 6: 「見えているから大丈夫」と思う
**問題:** 見えていても alert/対応手順がないと初動が遅れる。  
**回避:** ダッシュボード + アラート + インシデント手順をセットで考える。

## 7) One interview-style question
**質問:** Prometheus と Grafana を入れた直後のチームで、障害対応を速くするために最初に作るべき 3 つのメトリクスと、その理由を説明してください。

**考える観点:**
- RED を使うか
- インフラ系とアプリ系のバランス
- 「見るだけ」ではなく判断に使えるか
- アラートへつなげやすいか

## 8) Next-step reading links
- Prometheus Docs  
  https://prometheus.io/docs/introduction/overview/
- Grafana Docs  
  https://grafana.com/docs/grafana/latest/
- OpenTelemetry Concepts  
  https://opentelemetry.io/docs/concepts/
- Google SRE Book: Monitoring Distributed Systems  
  https://sre.google/sre-book/monitoring-distributed-systems/
- OWASP Logging Cheat Sheet  
  https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html
- Kubernetes Monitoring Basics  
  https://kubernetes.io/docs/tasks/debug/debug-cluster/resource-metrics-pipeline/

---

## 明日の予告
次号候補（Advanced ローテーション）:
- **Advanced:** Kubernetes Incident Drill — failure / rollback / recovery の実戦演習
- **Advanced:** Cloud Security — cross-account IAM と permission boundary
- **Middle:** Docker Hardening — rootless / capability drop / image provenance

Observability は、派手ではないけれど**強いチームの共通基盤**です。  
今日の 30〜60 分で「見えるようにする」感覚を掴めたら、明日の incident drill が一気に実務っぽくなります。