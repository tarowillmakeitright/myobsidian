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

# SecDevOps Magazine — 2026-07-11

今日からこのマガジンは、**Beginner → Middle → Advanced** の順で繰り返す学習アークで進めます。  
今日は **Beginner** 回です。次回以降で Middle / Advanced に進み、各回で必要な前提知識も明示していきます。

---

## 1) Topic + Level
**Cloud Security / IAM設計入門 + Observabilityの入口 + Kubernetes incident drillsの土台**  
**Level: Beginner**

---

## 2) Why it matters in real projects
実務では、アプリの脆弱性そのものだけでなく、**「誰が何をできるか」**、**「異常をいつ検知できるか」**、**「障害時に安全に戻せるか」** が事故の大きさを左右します。

たとえば：
- IAM が広すぎると、1つの漏えいから本番全体に被害が広がる
- Observability が弱いと、障害や侵害の兆候を見逃す
- Kubernetes の rollback や recovery に慣れていないと、障害時に復旧が遅れる

つまり、**Secure Coding** だけでは守り切れません。  
**権限設計・可視化・復旧力** まで含めて、はじめて「安全に運用できるシステム」になります。

---

## 3) Core concepts

### A. IAM の基本: Least Privilege
**Least Privilege（最小権限）** とは、ユーザー・サービス・CI/CD に対して、**必要最小限の権限だけ**を与える考え方です。

ポイント：
- `admin` を安易に配らない
- 人間用アカウントとサービスアカウントを分ける
- 読み取り専用 (`read-only`) と変更権限 (`write`) を分ける
- 本番と検証環境で権限境界を分ける

AWS なら IAM Policy、GCP なら IAM Role Binding でこれを表現します。

### B. Permission Design
権限設計は「とりあえず動く」ではなく、**業務単位・システム単位・環境単位**で整理します。

設計の軸：
- **Who**: 誰が使うか（開発者、CI、運用者、アプリ）
- **What**: 何に触るか（S3, GCS, Secret, EC2, GKE など）
- **Which actions**: 何ができるべきか（read / write / deploy / delete）
- **Where**: どの環境か（dev / staging / prod）

### C. Observability の3本柱
Observability はよく次の 3 つで整理されます。
- **Metrics**: CPU 使用率、エラー率、レイテンシなどの数値
- **Logs**: 何が起きたかの記録
- **Traces**: リクエストが複数サービスをどう流れたか

代表技術：
- **Prometheus**: Metrics の収集
- **Grafana**: ダッシュボード表示
- **OpenTelemetry**: Logs / Metrics / Traces の計装標準

Beginner 段階では、まず **「何を見えるようにすべきか」** を理解するのが大事です。

### D. Kubernetes incident drills の考え方
Incident drill は、**障害を想定して安全に練習すること**です。

最初に覚えるべき観点：
- どの Pod / Deployment が壊れているか確認する
- 変更を戻す（rollback）方法を知っておく
- 影響範囲を縮める
- 復旧後に原因を記録する

Kubernetes では「壊れた時の観察」と「戻し方」の基本が重要です。

---

## 4) Hands-on mini lab (30-60 min)
**テーマ: 最小権限 + 可視化 + K8s復旧の入口を1回で触る**

### ゴール
- IAM 設計の考え方をメモ化する
- ローカルで Metrics を見る体験をする
- Kubernetes で rollout history / undo を体験する

### 前提
- Docker が使える
- `kubectl` が使える
- ローカル Kubernetes（minikube / kind / k3d のどれか）があると理想

### Part 1: IAM 設計メモを作る（10分）
次の 4 役を定義して、自分の言葉で権限を分けます。
- Developer
- CI/CD
- App Runtime
- Incident Responder

各役について書く：
- 触るリソース
- 必要な操作
- 不要な操作
- 本番アクセスの可否

### Part 2: Prometheus を Docker で起動（15-20分）
最小構成で Prometheus を触ります。

1. `prometheus.yml` を作成
2. Docker で起動
3. `up` メトリクスを確認

#### prometheus.yml
```yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: prometheus
    static_configs:
      - targets: ['localhost:9090']
```

起動例：
```bash
docker run --rm -p 9090:9090 \
  -v "$PWD/prometheus.yml:/etc/prometheus/prometheus.yml" \
  prom/prometheus
```

ブラウザで `http://localhost:9090` を開き、`up` を実行します。

観察ポイント：
- 収集対象が生きているか
- scrape 間隔はどれくらいか
- 「見える」だけで安心せず、何を alert にすべきか考える

### Part 3: Kubernetes rollout を試す（15-25分）
Nginx Deployment を作って、イメージ更新→履歴確認→rollback をやります。

```bash
kubectl create deployment web --image=nginx:1.25
kubectl rollout status deployment/web
kubectl set image deployment/web nginx=nginx:1.27
kubectl rollout status deployment/web
kubectl rollout history deployment/web
kubectl rollout undo deployment/web
kubectl rollout status deployment/web
```

確認：
- どの revision があるか
- rollback 後に Pod が戻るか
- `kubectl describe deployment web` でイベントが見えるか

### ラボの振り返り質問
- CI/CD に `*` 権限を与えるのはなぜ危険か？
- Metrics が見えても incident response が弱いケースは？
- rollback できても、根本原因が未解決なら何が起きるか？

---

## 5) Command cheatsheet

### Linux
```bash
ps aux
ss -lntp
journalctl -xe
curl -I http://localhost:9090
```

### Docker
```bash
docker ps
docker logs <container>
docker inspect <container>
docker run --rm -p 9090:9090 -v "$PWD/prometheus.yml:/etc/prometheus/prometheus.yml" prom/prometheus
```

### Kubernetes
```bash
kubectl get pods -A
kubectl get deploy
kubectl describe deployment web
kubectl logs <pod-name>
kubectl rollout status deployment/web
kubectl rollout history deployment/web
kubectl rollout undo deployment/web
```

### Terraform / IaC
今日は概念だけでも OK。よく使う確認コマンド：
```bash
terraform fmt
terraform validate
terraform plan
```

---

## 6) Common mistakes and how to avoid them

### ミス1: IAM を broad にしすぎる
**例:** `AdministratorAccess` を一時対応のまま放置する  
**回避策:** まず job function ごとに権限を切り、例外だけ期限付きにする

### ミス2: Observability を「ログだけ」で済ませる
**例:** 障害時にログは大量にあるが、エラー率やレイテンシ推移が分からない  
**回避策:** Metrics / Logs / Traces の役割を分けて考える

### ミス3: Kubernetes の rollback 手順を本番で初めて触る
**例:** 障害時に `undo` の対象や影響が分からず手が止まる  
**回避策:** 小さい Deployment で drill を繰り返す

### ミス4: IaC を書いても review しない
**例:** Terraform で権限を自動配布した結果、誤った権限が大量展開される  
**回避策:** `terraform plan` と peer review を必須化する

### ミス5: Secure Coding と運用セキュリティを分断する
**例:** アプリ修正だけで満足し、Secrets や CI 権限が放置される  
**回避策:** AppSec と DevOps を1本の流れとして扱う

---

## 7) One interview-style question
**質問:**  
「開発チームの CI/CD パイプラインに広すぎるクラウド権限が付いている場合、どんなリスクがありますか？ また、どう改善しますか？」

**考えるポイント:**
- 認証情報漏えい時の blast radius
- 本番環境の改変や secret 取得の可能性
- role 分離、短命 credential、最小権限、監査ログ

---

## 8) Next-step reading links
- OWASP Top 10  
  https://owasp.org/www-project-top-ten/
- OWASP Cheat Sheet Series  
  https://cheatsheetseries.owasp.org/
- AWS IAM Best Practices  
  https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- Google Cloud IAM Overview  
  https://cloud.google.com/iam/docs/overview
- Prometheus Getting Started  
  https://prometheus.io/docs/prometheus/latest/getting_started/
- Grafana Documentation  
  https://grafana.com/docs/
- OpenTelemetry Documentation  
  https://opentelemetry.io/docs/
- Kubernetes Deployment Rollback  
  https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Terraform Recommended Practices  
  https://developer.hashicorp.com/terraform

---

## 次回予告
次回は **Middle** 回として、以下のどれかを扱います。
- Docker hardening と container escape の防御視点
- Auth / Session Security の設計ミス
- Kubernetes 基本防御（RBAC / NetworkPolicy / Secret の扱い）

**Middle に進む前提知識:**
- Linux 基本コマンド
- Docker コンテナの起動とログ確認
- `kubectl get/describe/logs` の基本
- IAM の最小権限の意味
