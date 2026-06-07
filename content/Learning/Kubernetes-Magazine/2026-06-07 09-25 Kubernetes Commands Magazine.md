---
tags:
  - kubernetes
  - k8s
  - devops
  - learning
  - daily
---

[[Home]]

# Kubernetes Commands Magazine — 2026-06-07 09:25

今日のテーマは、**kubectl を使った安全なデバッグと運用の基礎から、実運用でのローリング更新確認まで**です。難易度は **Beginner → Middle → Advanced** の順で進み、手を動かしながら「アプリ開発の中で Kubernetes をどう使うか」をつかめる構成にしています。

---

## 1. Beginner — Pod / Deployment を `kubectl get`・`describe`・`logs` で読む

### 1) Topic + Level
**トピック:** `kubectl get`, `kubectl describe`, `kubectl logs` を使った基本観察
**レベル:** Beginner

### 2) Why it matters for real app development
アプリを Kubernetes に載せると、コードの問題だけでなく、**起動失敗・設定ミス・イメージ取得失敗・環境差分**も不具合の原因になります。
そのとき最初に必要なのは「変更すること」ではなく、**安全に状況を観察すること**です。

実際の開発では次のような場面で必須です。
- 新しい API サービスが起動しない
- フロントエンドからバックエンドにつながらない
- CI/CD 後に Pod が CrashLoopBackOff になった
- ステージング環境だけ挙動が違う

### 3) Core kubectl / Kubernetes concept explanations
- **Pod**: コンテナが動く最小実行単位
- **Deployment**: Pod を望ましい状態に保つ宣言的リソース
- **Namespace**: 環境やチームごとにリソースを整理する論理的な区切り
- **`kubectl get`**: 一覧表示。現状把握の入口
- **`kubectl describe`**: イベントや詳細状態を確認
- **`kubectl logs`**: アプリケーションログ確認

よく使う流れ:
1. `get` で対象を見つける
2. `describe` で状態・イベントを見る
3. `logs` でアプリ側のエラーを見る

### 4) How Kubernetes is used while building apps
Kubernetes 公式ドキュメントでも、アプリ運用では**宣言的にデプロイし、状態は観察系コマンドで確認する**流れが基本です。

開発中の実際の流れ:
- アプリのコンテナイメージをビルド
- Deployment/Service マニフェストでデプロイ
- `kubectl get pods` で起動確認
- `kubectl logs` でアプリ起動ログ確認
- readiness/liveness probe を設定して健全性を担保

ポイント:
- いきなり `kubectl delete pod` に頼らない
- まず `describe` と `logs` で原因を絞る
- マニフェストには Secret の平文を書かない

### 5) 30-60 minute hands-on mini lab
**目標:** nginx Deployment を作成し、観察コマンドで状態を理解する

#### 手順
1. 作業用 namespace を作る
2. nginx Deployment を作る
3. Pod と Deployment を確認する
4. ログとイベントを読む
5. replicas を増やして変化を見る

#### 例
```bash
kubectl create namespace k8s-magazine
kubectl config set-context --current --namespace=k8s-magazine

kubectl create deployment web --image=nginx:1.27
kubectl get deployments
kubectl get pods -o wide

kubectl describe deployment web
kubectl describe pod -l app=web
kubectl logs deployment/web

kubectl scale deployment web --replicas=3
kubectl get pods -w
```

#### 確認ポイント
- Deployment と Pod の関係が見えるか
- Event に何が出るか読めるか
- replicas を増やすと Pod が増えることを確認できたか

### 6) Command cheatsheet
```bash
kubectl get pods
kubectl get pods -A
kubectl get deployments
kubectl get svc
kubectl describe pod <pod-name>
kubectl describe deployment <deployment-name>
kubectl logs <pod-name>
kubectl logs deployment/<deployment-name>
kubectl config current-context
kubectl config view --minify
```

### 7) Common mistakes and safe practices
**よくあるミス**
- namespace を見ずに別環境を調べる
- `default` namespace 前提で作業する
- `logs` を見ずに再起動でごまかす
- `kubectl apply` や `delete` を現在の context 未確認で実行する

**安全策**
- 破壊的コマンドの前に必ず確認:
  - `kubectl config current-context`
  - `kubectl get ns`
- `delete`, `apply`, `scale` の前に対象を絞る
- `-A` を使うときは対象環境を見誤らない
- 本番では特に `kubectl delete` を反射的に打たない

> 警告: `kubectl delete`, `kubectl apply`, `kubectl scale` は対象 cluster / namespace を誤ると影響が大きいです。実行前に **context と namespace を必ず確認**してください。

### 8) One interview-style question
**質問:** `kubectl get pod` と `kubectl describe pod` の違いは何ですか？ それぞれどんな場面で使いますか？

### 9) Next-step resources
- Kubernetes Objects: https://kubernetes.io/docs/concepts/overview/working-with-objects/
- Pods: https://kubernetes.io/docs/concepts/workloads/pods/
- Deployments: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- kubectl Cheat Sheet: https://kubernetes.io/docs/reference/kubectl/cheatsheet/
- Debug Running Pods: https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/

---

## 2. Middle — Labels / Selectors / Service でアプリ接続を理解する

### Prerequisites
- Pod と Deployment の基本を理解している
- `kubectl get`, `describe`, `logs` を使って状態確認できる

### 1) Topic + Level
**トピック:** Label・Selector・Service を使ったアプリ接続の基本
**レベル:** Middle

### 2) Why it matters for real app development
実アプリでは「動いている Pod がある」だけでは不十分で、**アプリ同士が安定して通信できること**が重要です。
フロントエンド、API、DB Proxy、ジョブワーカーなど、複数コンポーネントをつなぐ土台が Service です。

### 3) Core kubectl / Kubernetes concept explanations
- **Label**: リソースに付けるキー/値の目印
- **Selector**: Label をもとに対象を選ぶ仕組み
- **Service**: Pod 群への安定したアクセス入口
- **Endpoints / EndpointSlices**: Service が実際にどの Pod に流すかの情報

重要なのは、Service は Pod 名ではなく **label selector** で Pod を見つける点です。
そのため、Pod が入れ替わっても Service 名は変わらず、アプリ間通信が安定します。

### 4) How Kubernetes is used while building apps
アプリ開発では、Deployment で API Pod を複数起動し、Service 経由でアクセスするのが基本です。
これは Kubernetes 公式の推奨パターンとも一致します。

典型例:
- `frontend` Deployment
- `api` Deployment
- `api-service` Service が `app=api` を選択
- `frontend` は `http://api-service` のように Service 名で接続

ベストプラクティス:
- ラベルは一貫した命名にする
- Service selector と Pod template labels を一致させる
- アプリを Pod IP 直指定しない

### 5) 30-60 minute hands-on mini lab
**目標:** 2 つの Deployment と 1 つの Service を作って、selector の役割を確認する

#### 手順
1. API 用 nginx Deployment を作る
2. Service を作って公開する
3. 一時 Pod から Service 経由で疎通確認する
4. ラベルを見て、どの Pod が Service 対象か確認する

#### 例
```bash
kubectl create namespace k8s-netlab
kubectl config set-context --current --namespace=k8s-netlab

kubectl create deployment api --image=nginx:1.27
kubectl expose deployment api --port=80 --target-port=80 --name=api-service

kubectl get deployments,pods,svc
kubectl get pod --show-labels
kubectl describe svc api-service
kubectl get endpointslices

kubectl run curlbox --image=curlimages/curl:8.8.0 --restart=Never -it --rm -- \
  curl -I http://api-service
```

#### 発展確認
```bash
kubectl label pod <pod-name> debug=false --overwrite
kubectl get pod --show-labels
```

その上で、Deployment の template label と Service selector を見比べて、通信対象の決まり方を説明してみてください。

### 6) Command cheatsheet
```bash
kubectl get svc
kubectl describe svc <service-name>
kubectl get endpointslices
kubectl get pods --show-labels
kubectl label pod <pod-name> key=value --overwrite
kubectl expose deployment <deployment-name> --port=80 --target-port=80 --name=<service-name>
kubectl run tmp --image=curlimages/curl:8.8.0 --restart=Never -it --rm -- sh
```

### 7) Common mistakes and safe practices
**よくあるミス**
- Service selector と Pod の labels が一致していない
- Pod IP をアプリ設定に直接書く
- namespace をまたいだ名前解決を誤解する
- 疎通確認に本番 Pod へ無闇に exec する

**安全策**
- `kubectl describe svc` で selector と endpoints を確認する
- 一時デバッグ Pod を使って疎通確認する
- 本番 workload への直接変更より、マニフェスト修正を優先する
- Secret や認証情報を環境変数に直書きしたマニフェストを共有しない

> 注意: `kubectl apply -f .` を広いディレクトリで実行すると、想定外の Service / Deployment まで更新することがあります。適用対象ファイルと context を必ず確認してください。

### 8) One interview-style question
**質問:** なぜ Kubernetes では Pod IP ではなく Service を使ってアプリ間通信するのですか？

### 9) Next-step resources
- Services, Load Balancing, and Networking: https://kubernetes.io/docs/concepts/services-networking/
- Service: https://kubernetes.io/docs/concepts/services-networking/service/
- Labels and Selectors: https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/
- DNS for Services and Pods: https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/

---

## 3. Advanced — Rollout / Probe / Revision を使った安全なリリース確認

### Prerequisites
- Deployment と Service の役割を理解している
- Labels / Selectors の仕組みを説明できる
- `kubectl logs` と `describe` でトラブル原因を追える

### 1) Topic + Level
**トピック:** `kubectl rollout` と probe を使った安全なデプロイ運用
**レベル:** Advanced

### 2) Why it matters for real app development
本番運用では、デプロイは「入れる」より **安全に進める・問題時に戻せる** ことが重要です。
ローリング更新、readiness probe、revision 履歴の理解があると、ユーザー影響を減らしながら継続的にアプリ改善できます。

### 3) Core kubectl / Kubernetes concept explanations
- **RollingUpdate**: Pod を段階的に入れ替える更新方式
- **Readiness Probe**: 受信可能になってから Service に載せる判定
- **Liveness Probe**: 異常時に再起動させる判定
- **Revision History**: Deployment の更新履歴
- **`kubectl rollout status`**: 更新の進行確認
- **`kubectl rollout history`**: 過去 revision の確認
- **`kubectl rollout undo`**: ロールバック

### 4) How Kubernetes is used while building apps
公式ベストプラクティスに沿うなら、アプリ更新時は:
- Deployment を宣言的に更新する
- readiness probe で未準備 Pod をトラフィックに入れない
- rollout status で進捗確認する
- 問題があれば revision を確認し安全に戻す

開発チームでは CI/CD が `kubectl apply` または GitOps で Deployment を更新し、運用者は rollout コマンドで確認することが多いです。

### 5) 30-60 minute hands-on mini lab
**目標:** 安全な更新とロールバックの流れを体験する

#### 例マニフェスト
`deployment.yaml`
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-web
spec:
  replicas: 2
  revisionHistoryLimit: 5
  selector:
    matchLabels:
      app: demo-web
  template:
    metadata:
      labels:
        app: demo-web
    spec:
      containers:
        - name: nginx
          image: nginx:1.27
          ports:
            - containerPort: 80
          readinessProbe:
            httpGet:
              path: /
              port: 80
            initialDelaySeconds: 3
            periodSeconds: 5
```

#### 手順
```bash
kubectl create namespace k8s-rollout
kubectl config set-context --current --namespace=k8s-rollout

kubectl apply -f deployment.yaml
kubectl rollout status deployment/demo-web
kubectl rollout history deployment/demo-web

kubectl set image deployment/demo-web nginx=nginx:1.28
kubectl rollout status deployment/demo-web
kubectl get pods

kubectl rollout history deployment/demo-web
```

#### 失敗を想定した学習
存在しないタグへ更新する例:
```bash
kubectl set image deployment/demo-web nginx=nginx:does-not-exist
kubectl rollout status deployment/demo-web
kubectl describe deployment demo-web
kubectl get pods
```

復旧:
```bash
kubectl rollout undo deployment/demo-web
kubectl rollout status deployment/demo-web
```

#### 学びどころ
- readiness probe があると何が守られるか
- 更新失敗時にどこを見るか
- undo がどの revision を戻すのか

### 6) Command cheatsheet
```bash
kubectl apply -f deployment.yaml
kubectl set image deployment/<name> <container>=<image>:<tag>
kubectl rollout status deployment/<name>
kubectl rollout history deployment/<name>
kubectl rollout undo deployment/<name>
kubectl describe deployment <name>
kubectl get rs
kubectl get pods
kubectl logs deployment/<name>
```

### 7) Common mistakes and safe practices
**よくあるミス**
- readiness probe なしで更新し、未起動 Pod に流してしまう
- `latest` タグ運用で何が入ったか分からなくなる
- 本番でいきなり `set image` して履歴管理が曖昧になる
- 失敗時に Pod 削除で対処し、根本原因を見失う

**安全策**
- イメージは明示タグを使う
- readiness / liveness を役割に応じて設定する
- `rollout status` と `history` をセットで確認する
- Secret は Secret リソースや外部 secret 管理を使い、マニフェストに平文で書かない
- 本番反映前に `kubectl config current-context` を確認する
- 破壊的変更前に影響範囲を言語化する

> 強い注意: `kubectl delete -f`, `kubectl delete namespace`, `kubectl apply -f .`, `kubectl replace --force` は破壊範囲が大きくなりやすいです。特に本番 cluster では **対象ファイル・namespace・context を毎回確認**してください。

### 8) One interview-style question
**質問:** readiness probe と liveness probe は何が違いますか？ また、ローリング更新時に readiness probe が重要な理由を説明してください。

### 9) Next-step resources
- Deployment: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Update API Objects in Place Using kubectl patch: https://kubernetes.io/docs/tasks/manage-kubernetes-objects/update-api-object-kubectl-patch/
- Configure Liveness, Readiness and Startup Probes: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/
- Debug Applications: https://kubernetes.io/docs/tasks/debug/debug-application/
- Best Practices for Configuration: https://kubernetes.io/docs/concepts/configuration/overview/
- Secrets: https://kubernetes.io/docs/concepts/configuration/secret/

---

## まとめ
今日の学習 arc は次の流れでした。

1. **Beginner**: まず観察する (`get`, `describe`, `logs`)
2. **Middle**: Service と labels でアプリ接続を理解する
3. **Advanced**: rollout と probe で安全に更新する

この順番は、実際のアプリ開発でもかなり実践的です。最初に「見える」、次に「つながる」、最後に「安全に更新できる」ようになると、Kubernetes の運用力が一気に上がります。

明日以降は、次の arc につなげると自然です。
- ConfigMap / Secret の安全な扱い
- Requests / Limits とリソース設計
- Ingress とアプリ公開
- Job / CronJob によるバッチ実行
