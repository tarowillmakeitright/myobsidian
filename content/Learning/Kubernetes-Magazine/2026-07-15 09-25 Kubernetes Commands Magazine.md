---
tags:
  - kubernetes
  - k8s
  - devops
  - learning
  - daily
---

[[Home]]

# 2026-07-15 09:25 Kubernetes Commands Magazine

## Topic + Level

**Topic:** Readiness / Liveness / Startup Probeで「起動中・受付可能・故障」を区別する  
**Level:** Middle  
**Learning Arc:** Beginner → **Middle** → Advanced（観測・安全な更新の次の一歩）

### 前提知識

- `kubectl get pods`、`kubectl describe pod`、`kubectl logs`を使える
- DeploymentをYAMLで作成し、`kubectl apply`と`kubectl rollout status`を実行できる
- ローカルの検証用クラスタ（kind / minikube / Docker Desktopなど）と`kubectl`がある
- Pod、Deployment、Serviceの役割を大まかに説明できる

### 今日の到達目標

- 3種類のProbeを、再起動・通信経路・起動猶予という観点で区別する
- Probe付きDeploymentを安全な専用Namespaceへ適用する
- `READY`、再起動回数、Events、EndpointSliceから結果を観測する
- Probeの誤設定が障害を増幅する理由を説明する

---

## なぜ実アプリ開発で重要か

コンテナのプロセスが動いていても、アプリがリクエストを処理できるとは限りません。DB接続やキャッシュ準備が終わっていない、負荷で一時的に受付不能、デッドロックして回復不能、といった状態があるためです。

Probeを正しく分けると、Kubernetesは次の判断を自動化できます。

- **Readiness:** 今このPodへServiceの通信を送ってよいか
- **Liveness:** このコンテナは再起動しなければ回復しないか
- **Startup:** 起動処理が終わるまでLiveness / Readinessの判定を待つべきか

DeploymentのRollingUpdateでは、新PodがReadyにならなければ安全な置換が進みません。つまりProbeは単なる監視設定ではなく、**リリース速度と可用性を左右するアプリ仕様**です。

---

## コア概念

### Readiness Probe

失敗するとPodはNotReadyになり、該当ServiceのEndpointSliceで通常通信の対象から外れます。コンテナ自体は再起動されません。一時的な依存先障害やウォームアップ中など、「生きているが受け付けられない」状態に使います。

### Liveness Probe

規定回数失敗するとkubeletがコンテナを再起動します。デッドロックなど、再起動しないと回復しない状態だけを検査します。DBや外部APIの一時障害をLivenessへ含めると、多数Podが同時再起動して障害を悪化させる恐れがあります。

### Startup Probe

成功するまでLiveness / Readinessを開始させません。起動が遅いアプリに大きな`initialDelaySeconds`を付けるより、起動専用の失敗許容時間を明示できます。許容時間の目安は概ね`failureThreshold × periodSeconds`です。

### Probe方式

- `httpGet`: HTTPアプリに適する。用途別の軽量エンドポイントを用意する
- `tcpSocket`: ポート接続可否のみを見る。アプリ内部の正常性までは分からない
- `exec`: コンテナ内コマンドを実行する。高頻度ではプロセス生成コストに注意
- `grpc`: gRPC Health Checking Protocolに対応するアプリ向け

### 主な調整値

- `periodSeconds`: 検査間隔
- `timeoutSeconds`: 1回のタイムアウト
- `failureThreshold`: 失敗と確定する連続回数
- `successThreshold`: 成功へ戻すのに必要な連続成功回数（Liveness / Startupは1固定）
- `initialDelaySeconds`: 最初の検査までの待ち時間。遅い起動にはStartup Probeを優先検討

---

## アプリ開発ではどう使うか

1. アプリに用途別のヘルスエンドポイントを実装する。`/readyz`は依存先を含む受付可否、`/livez`はプロセス内部の回復不能状態、`/startupz`は初期化完了を返す。
2. エンドポイントは高速・軽量にし、認証情報や内部エラーの詳細を返さない。
3. まずReadinessを導入し、実測した起動時間と障害時の挙動から閾値を決める。
4. ステージングでPod Events、再起動回数、EndpointSlice、rolloutを観測する。
5. マニフェストをGit管理し、`kubectl diff`、明示的なcontext / namespace、レビューを経て適用する。

Probeは外部監視の代わりではありません。メトリクス、ログ、トレース、ユーザー視点の監視も併用します。

---

## 30〜60分ミニラボ

### 0. 安全確認（5分）

このラボはローカルまたは検証クラスタ専用です。現在の接続先を必ず確認します。

```bash
kubectl config current-context
kubectl cluster-info
kubectl auth can-i create namespace
```

本番contextだった場合は中止し、検証用contextへ切り替えてください。

### 1. 専用Namespaceを作成（5分）

```bash
kubectl create namespace k8s-magazine
kubectl config view --minify
```

以降はすべて`-n k8s-magazine`を付け、操作範囲を限定します。

### 2. Probe付きアプリを準備（10分）

次を`probe-demo.yaml`として保存します。学習用に3つとも`/`を見ますが、実アプリでは用途別エンドポイントへ分離してください。

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: probe-demo
  namespace: k8s-magazine
spec:
  replicas: 2
  selector:
    matchLabels:
      app: probe-demo
  template:
    metadata:
      labels:
        app: probe-demo
    spec:
      containers:
        - name: web
          image: nginx:1.27-alpine
          ports:
            - name: http
              containerPort: 80
          resources:
            requests:
              cpu: 25m
              memory: 32Mi
            limits:
              cpu: 200m
              memory: 128Mi
          startupProbe:
            httpGet:
              path: /
              port: http
            periodSeconds: 2
            failureThreshold: 15
          readinessProbe:
            httpGet:
              path: /
              port: http
            periodSeconds: 5
            timeoutSeconds: 2
            failureThreshold: 2
          livenessProbe:
            httpGet:
              path: /
              port: http
            periodSeconds: 10
            timeoutSeconds: 2
            failureThreshold: 3
---
apiVersion: v1
kind: Service
metadata:
  name: probe-demo
  namespace: k8s-magazine
spec:
  selector:
    app: probe-demo
  ports:
    - name: http
      port: 80
      targetPort: http
```

注意: Secret値をYAMLへ直書きしないでください。この例はSecretを必要としません。実アプリではSecretリソースや外部Secret管理を使い、マニフェスト・ログ・Probe応答へ秘密を出さないようにします。

### 3. 差分確認して適用（10分）

```bash
kubectl apply --dry-run=server -f probe-demo.yaml
kubectl diff -f probe-demo.yaml
kubectl apply -f probe-demo.yaml
kubectl rollout status deployment/probe-demo -n k8s-magazine --timeout=90s
```

`diff`は差分があると終了コード1になることがあります。内容を確認してから`apply`してください。

### 4. Probeの結果を観測（10分）

```bash
kubectl get pods -n k8s-magazine -w
kubectl describe deployment probe-demo -n k8s-magazine
kubectl get endpointslice -n k8s-magazine -l kubernetes.io/service-name=probe-demo -o wide
kubectl get events -n k8s-magazine --sort-by=.metadata.creationTimestamp
```

別ターミナルでPod名を得て、設定と再起動回数も確認します。

```bash
POD=$(kubectl get pod -n k8s-magazine -l app=probe-demo -o jsonpath='{.items[0].metadata.name}')
kubectl get pod "$POD" -n k8s-magazine
kubectl describe pod "$POD" -n k8s-magazine
```

確認点:

- `READY`が`1/1`になる
- `RESTARTS`が増えていない
- EndpointSliceにReadyなPod IPが載る
- EventsにProbe失敗が連続していない

### 5. 安全な失敗実験（5〜10分）

Readinessだけを存在しないパスへ変えたコピーを作り、`kubectl diff`で「Podが通信対象から外れる」変化を予測してみましょう。実クラスタには適用せず、クライアント側dry-runで生成結果だけ確認します。

```bash
sed '0,/path: \/$/s//path: \/not-found/' probe-demo.yaml \
  | kubectl apply --dry-run=client -f - -o yaml >/dev/null
```

発展: コピーしたファイルで**readinessProbeのパスだけ**を`/not-found`へ変え、検証Namespaceで適用し、PodがRunningのまま`0/1`になることを観測します。Livenessは変更しません。

### 6. 後片付け（2分）

> ⚠️ `delete namespace`はNamespace内の全リソースを削除します。contextと名前を再確認し、このラボ専用Namespaceである場合だけ実行してください。

```bash
kubectl config current-context
kubectl get all -n k8s-magazine
kubectl delete namespace k8s-magazine
```

---

## Command Cheatsheet

```bash
# 接続先と権限
kubectl config current-context
kubectl config view --minify
kubectl auth can-i create deployments -n k8s-magazine

# 適用前検証
kubectl apply --dry-run=server -f app.yaml
kubectl diff -f app.yaml

# rollout / Pod観測
kubectl rollout status deployment/APP -n NS --timeout=90s
kubectl get pods -n NS -w
kubectl describe pod POD -n NS
kubectl logs POD -n NS --tail=100
kubectl get events -n NS --sort-by=.metadata.creationTimestamp

# Serviceの通信対象
kubectl get endpointslice -n NS -l kubernetes.io/service-name=SVC -o wide

# Probe定義だけ確認
kubectl get deployment APP -n NS -o jsonpath='{.spec.template.spec.containers[*].readinessProbe}'
```

---

## よくあるミスと安全策

- **ReadinessとLivenessを同じ意味にする:** 一時的な依存先障害で全Podを再起動しない。Livenessは自己回復不能だけに絞る。
- **Probeが重い:** DB全件問い合わせや外部API呼び出しを避け、短時間で終わる専用処理にする。
- **閾値が厳しすぎる:** 高負荷時にProbeがタイムアウトし、再起動がさらに負荷を増やす。実測値と余裕を持たせる。
- **Startup Probeなしで遅い起動をLivenessが殺す:** 起動時間の上限を測り、Startup Probeで猶予を設計する。
- **名前付きportの不一致:** `port: http`とcontainer portの`name: http`を一致させる。
- **context / namespace間違い:** 書き込み前に`current-context`と`diff`を確認し、常に`-n`を明記する。
- **いきなり`delete`や`apply`:** 対象一覧、dry-run、差分、権限、rolloutを順に確認する。
- **秘密情報をProbe URLやマニフェストへ書く:** トークンをquery string、HTTP header、YAMLへ直書きしない。Probe応答にも内部情報を含めない。
- **可変タグだけに依存:** 実運用では検証済みの不変タグ、可能ならdigest固定とイメージ署名・スキャンを検討する。

---

## Interview-style Question

**質問:** Readiness ProbeとLiveness Probeの両方が失敗したとき、KubernetesはPodにどう作用しますか。また、DB障害を両方の判定条件に含める設計にはどんな危険がありますか？

**回答の要点:** Readiness失敗ではPodがServiceの通常通信対象から外れ、Liveness失敗が閾値を超えるとコンテナが再起動されます。共有DB障害をLiveness条件にすると、全Podが一斉に再起動し、起動負荷や接続集中で復旧を妨げる可能性があります。DB障害中は多くの場合Readinessで通信を止め、Livenessはプロセス自身の回復不能状態に限定します。

---

## Next-step Resources

- [Liveness, Readiness, and Startup Probes（概念）](https://kubernetes.io/docs/concepts/workloads/pods/probes/)
- [Configure Liveness, Readiness and Startup Probes（公式チュートリアル）](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)
- [Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [Update a Deployment Without Downtime](https://kubernetes.io/docs/tasks/run-application/update-deployment-rolling/)
- [EndpointSlices](https://kubernetes.io/docs/concepts/services-networking/endpoint-slices/)

### 次回への橋渡し（Advanced）

次はProbeを前提に、`maxUnavailable` / `maxSurge`、`minReadySeconds`、`progressDeadlineSeconds`、PodDisruptionBudgetを組み合わせ、更新中の可用性をどう数値で守るかへ進みます。
