---
tags:
  - kubernetes
  - k8s
  - devops
  - learning
  - daily
---

[[Home]]

# Kubernetes Commands Magazine — 2026-06-15 09:25

今日は **Deployment / rollout / Service / Horizontal scaling の実務導線** を、**Beginner → Middle → Advanced** の学習アークで進めます。

Kubernetes は「とりあえず Pod を動かす」だけで終わると実務で役に立ちません。実際のアプリ開発では、**安全に更新する・通信させる・負荷に耐える** までがセットです。今日はその入口を固めます。

---

## 1) Topic + Level

### Beginner
**Topic:** Deployment と `kubectl rollout` で安全にアプリを更新する

### Middle
**Topic:** Service で Deployment を安定公開し、更新中も接続先を保つ

**Prerequisites:**
- Pod / Deployment の基本がわかる
- `kubectl get`, `kubectl describe`, `kubectl logs` を触ったことがある
- labels / selectors の概念をざっくり理解している

### Advanced
**Topic:** HorizontalPodAutoscaler (HPA) とリソース要求でアプリ運用を実務に寄せる

**Prerequisites:**
- Deployment と Service の関係を理解している
- rolling update の流れを説明できる
- CPU / memory requests の意味を知っている
- metrics-server が必要になることを知っている

---

## 2) Why it matters for real app development

アプリ開発で Kubernetes が本当に効いてくるのは次の場面です。

- 新バージョンを**止めずにデプロイ**したい
- Pod の名前が変わっても、フロントや他サービスからは**同じ接続先**で使いたい
- アクセス増加時に**手作業ではなく自動でスケール**したい
- ロールアウト失敗時に**すぐ状態確認やロールバック**をしたい

つまり、Kubernetes は単なる実行環境ではなく、**アプリの変更を安全に届けるための運用レイヤー**です。

実務では、コード変更そのものよりも、**変更をどう安全に出すか** が事故率を左右します。`kubectl rollout`, `Service`, `HPA` はそこに直結します。

---

## 3) Core kubectl / Kubernetes concept explanations

### Deployment
Deployment は、**望ましい Pod の状態を宣言するためのリソース**です。

たとえば:
- レプリカ数を 2 に保つ
- 指定イメージの Pod を動かす
- イメージ更新時は rolling update で入れ替える

重要コマンド:

```bash
kubectl get deploy
kubectl describe deploy web
kubectl apply -f deployment.yaml
kubectl rollout status deploy/web
kubectl rollout history deploy/web
kubectl rollout undo deploy/web
```

### Rollout
rollout は Deployment の更新進行を扱います。

- `rollout status` : 更新が完了したか確認
- `rollout history` : 過去の revision を確認
- `rollout undo` : 問題時にロールバック

**実務ポイント:**
`kubectl apply` を打って終わりではなく、**必ず rollout の完了確認まで見る** のが安全です。

### Service
Service は、**Pod 群への安定したアクセス窓口**です。

Pod は作り直しで IP が変わるため、アプリ同士を Pod IP で直接つなぐのは危険です。Service があることで:
- 安定した名前でアクセスできる
- 背後の Pod が入れ替わっても接続先の表現を変えずに済む

主要タイプ:
- `ClusterIP`: クラスタ内通信用の基本
- `NodePort`: ノードのポートで公開
- `LoadBalancer`: クラウド LB と連携して公開

### Labels / Selectors
Deployment や Service は labels / selectors で対象を結びます。

例:
- Pod label: `app=web`
- Service selector: `app=web`

これがずれると、**Service が Pod を見つけられない** 事故になります。

### HPA
HorizontalPodAutoscaler は、CPU などのメトリクスに応じて**Pod 数を自動調整**します。

ただし HPA は魔法ではありません。
- 適切な `resources.requests` が必要
- metrics-server などメトリクス供給が必要
- アプリが水平分散しやすい設計であることが前提

---

## 4) How Kubernetes is used while building apps

[kubernetes.io/docs](https://kubernetes.io/docs/) の実務に沿って考えると、開発フローはだいたいこうなります。

1. アプリをコンテナ化する
2. Deployment で「何個、どのイメージで動かすか」を宣言する
3. Service でそのアプリへの安定入口を作る
4. readiness / liveness probe を付けて壊れた Pod や未準備 Pod を適切に扱う
5. rolling update で安全に更新する
6. 負荷が読めるようになったら HPA を導入する

ベストプラクティス寄りの考え方:
- **Pod 単体ではなく Deployment で管理する**
- **Service 経由で通信する**
- **マニフェストは宣言的に管理し、`apply` 後は状態確認する**
- **Secret を YAML に直書きしない**
- **`default` namespace と今の context を無確認で使わない**
- **本番でいきなり広い `kubectl apply -f .` をしない**

---

## 5) 30-60 minute hands-on mini lab

### ゴール
- Nginx Deployment を作る
- Service で公開する
- イメージタグを更新して rollout を観察する
- 余裕があれば HPA を作る

### 事前注意
**破壊的操作の前に、必ず context / namespace を確認。**

```bash
kubectl config current-context
kubectl get ns
kubectl config view --minify --output 'jsonpath={..namespace}'; echo
```

namespace が空なら default です。学習用 namespace を作るのが安全です。

### Step 1: 学習用 namespace を作成

```bash
kubectl create namespace k8s-magazine
kubectl config set-context --current --namespace=k8s-magazine
kubectl config view --minify --output 'jsonpath={..namespace}'; echo
```

### Step 2: Deployment を作成

`deployment.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
spec:
  replicas: 2
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
        - name: nginx
          image: nginx:1.27
          ports:
            - containerPort: 80
          resources:
            requests:
              cpu: "100m"
              memory: "128Mi"
            limits:
              cpu: "300m"
              memory: "256Mi"
          readinessProbe:
            httpGet:
              path: /
              port: 80
            initialDelaySeconds: 3
            periodSeconds: 5
          livenessProbe:
            httpGet:
              path: /
              port: 80
            initialDelaySeconds: 10
            periodSeconds: 10
```

適用:

```bash
kubectl apply -f deployment.yaml
kubectl get pods
kubectl rollout status deploy/web
```

### Step 3: Service を作成

`service.yaml`

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web
spec:
  selector:
    app: web
  ports:
    - port: 80
      targetPort: 80
  type: ClusterIP
```

適用:

```bash
kubectl apply -f service.yaml
kubectl get svc
kubectl get endpoints web
```

ここで endpoints に Pod IP が紐づいていれば、selector が合っています。

### Step 4: Rollout を試す

```bash
kubectl set image deploy/web nginx=nginx:1.27.1
kubectl rollout status deploy/web
kubectl rollout history deploy/web
kubectl get pods -w
```

観察ポイント:
- Pod が一気に全部消えず、順に入れ替わるか
- Service 名はそのままで、背後の Pod だけ変わるか

### Step 5: 問題を起こした想定でロールバック

存在しないタグで失敗例を試すなら、**学習環境だけ** で実施。

```bash
kubectl set image deploy/web nginx=nginx:does-not-exist
kubectl rollout status deploy/web
kubectl describe deploy web
kubectl get pods
```

戻す:

```bash
kubectl rollout undo deploy/web
kubectl rollout status deploy/web
```

### Step 6: Advanced — HPA を作る

metrics-server がある前提:

```bash
kubectl autoscale deployment web --cpu-percent=60 --min=2 --max=5
kubectl get hpa
```

HPA が Pending 的な状態なら、metrics-server 不足や requests 未設定を疑います。

### Step 7: 後片付け

**削除前に namespace を再確認。**

```bash
kubectl config current-context
kubectl get all
kubectl delete namespace k8s-magazine
```

`kubectl delete namespace ...` は破壊的です。**対象 namespace を声に出して確認するくらいでちょうどいい** です。

---

## 6) Command cheatsheet

```bash
# 現在の接続先・namespace確認
kubectl config current-context
kubectl config view --minify --output 'jsonpath={..namespace}'; echo

# 一覧確認
kubectl get deploy,pods,svc
kubectl get all
kubectl get endpoints web

# 詳細確認
kubectl describe deploy web
kubectl describe svc web
kubectl logs deploy/web

# 適用
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml

# 更新
kubectl set image deploy/web nginx=nginx:1.27.1
kubectl rollout status deploy/web
kubectl rollout history deploy/web
kubectl rollout undo deploy/web

# スケール
kubectl scale deploy/web --replicas=3
kubectl autoscale deployment web --cpu-percent=60 --min=2 --max=5
kubectl get hpa

# 監視
kubectl get pods -w
kubectl top pods

# クリーンアップ
kubectl delete -f service.yaml
kubectl delete -f deployment.yaml
kubectl delete namespace k8s-magazine
```

---

## 7) Common mistakes and safe practices

### よくあるミス

#### 1. `kubectl apply -f .` を雑に打つ
ディレクトリ配下の意図しない YAML まで適用して事故ります。

**安全策:**
- 対象ファイルを明示する
- 本番では review 済み manifest のみ適用する
- 可能なら Git 管理で差分確認する

#### 2. context / namespace を確認せず操作する
学習のつもりが本番を触る、は Kubernetes の定番事故です。

**安全策:**
- `kubectl config current-context` を先に打つ
- namespace を明示する
- 学習用 namespace を分ける

#### 3. Service selector と Pod label がズレる
Service が Pod を拾えず、通信できません。

**安全策:**
- `kubectl get endpoints <svc名>` で確認
- labels / selectors をコピペでなく意図して揃える

#### 4. readinessProbe なしで更新する
起動直後の Pod に流れて不安定になります。

**安全策:**
- Web アプリには readinessProbe を付ける
- livenessProbe は乱用せず、意味を持って設定する

#### 5. Secret を manifest にベタ書きする
Git に残ったら面倒では済みません。

**安全策:**
- Secret を平文でコミットしない
- 外部 secret manager や安全な注入手段を使う
- 少なくとも学習資料にも本物の値を書かない

#### 6. リソース requests 未設定で HPA を期待する
HPA の判断やスケジューリングが不安定になります。

**安全策:**
- CPU / memory requests を定義する
- 実測しながら見直す

---

## 8) One interview-style question

**質問:**
Deployment を Service の背後で rolling update する場合、なぜ readinessProbe が重要ですか？ また、readinessProbe が無いとどんな障害が起き得ますか？

**考えるポイント:**
- Service がどの Pod にトラフィックを送るか
- Pod が「起動した」と「リクエストを捌ける」は同じではないこと
- 更新時の一時的な 5xx や接続失敗

---

## 9) Next-step resources

公式を優先して進むならこの順がいいです。

- Kubernetes Documentation Home  
  https://kubernetes.io/docs/

- Deployments  
  https://kubernetes.io/docs/concepts/workloads/controllers/deployment/

- Services, Load Balancing, and Networking  
  https://kubernetes.io/docs/concepts/services-networking/service/

- Probes (liveness, readiness, startup)  
  https://kubernetes.io/docs/concepts/configuration/liveness-readiness-startup-probes/

- Horizontal Pod Autoscaling  
  https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/

- Resource Management for Pods and Containers  
  https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/

- Labels and Selectors  
  https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/

---

## Closing note

今日の実務感ある結論はこれです。

- **Deployment で安全に更新する**
- **Service で安定した接続先を作る**
- **readinessProbe で更新事故を減らす**
- **HPA は requests と metrics 前提で導入する**
- **context / namespace 未確認の `apply` と `delete` は危険**

Kubernetes はコマンド暗記より、**変更がどう安全に流れるか** を掴むほうが伸びます。今日はそのど真ん中。