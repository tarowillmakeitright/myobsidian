# 2026-06-30 09-25 Kubernetes Commands Magazine

#kubernetes #k8s #devops #learning #daily
[[Home]]

## 今日のテーマ + レベル
**Arc 1 / Beginner**
**テーマ:** `kubectl get / describe / logs / apply` で Deployment と Pod を安全に観察・更新する

---

## 1) なぜ重要か（実アプリ開発とのつながり）
アプリ開発で Kubernetes を使う場面では、コードを書くことと同じくらい「**いま何が動いているかを正確に把握すること**」が重要です。

たとえば本番やステージングで次のような状況は日常的に起きます。
- 新しいイメージをデプロイしたが、Pod が起動しない
- アプリは動いているように見えるが、Service 経由で通信できない
- コンテナは再起動を繰り返しているが、原因が分からない
- `kubectl apply` をしたつもりが、別の namespace や context に適用してしまった

今日の内容は、そうした事故を防ぎながら、**最小限のコマンドでクラスタの状態を読む力**を作る基礎です。
Kubernetes を「とりあえず apply する箱」ではなく、**意図した状態を安全に運用するための仕組み**として扱えるようになる第一歩です。

---

## 2) コア概念の整理

### `kubectl get`
Kubernetes リソースの一覧や現在状態を見る基本コマンドです。

例:
```bash
kubectl get pods
kubectl get deployments
kubectl get svc
kubectl get pods -n demo
```

見るポイント:
- **READY**: コンテナが期待通り起動しているか
- **STATUS**: Running / Pending / CrashLoopBackOff など
- **RESTARTS**: 再起動が増えていないか
- **AGE**: いつ作られたか

### `kubectl describe`
一覧だけでは見えない詳細を確認します。

例:
```bash
kubectl describe pod <pod名>
kubectl describe deployment <deployment名>
```

見るポイント:
- Events（ImagePullBackOff、Probe失敗、スケジューリング失敗など）
- 使用イメージ
- labels / selectors
- Service と Deployment の紐づき

### `kubectl logs`
コンテナ標準出力を確認します。

例:
```bash
kubectl logs <pod名>
kubectl logs -f <pod名>
kubectl logs <pod名> -c <container名>
```

見るポイント:
- アプリの起動失敗
- ポート不一致
- 環境変数不足
- 外部依存先への接続失敗

### `kubectl apply -f`
マニフェストに書かれた「望ましい状態」をクラスタに反映します。

例:
```bash
kubectl apply -f app.yaml
```

重要な考え方:
- Kubernetes は**宣言的**に使うのが基本
- 「手でその場しのぎに修正」より、**YAML を更新して apply** が再現性の面で強い
- ただし `apply` の対象・context・namespace を誤ると事故になりやすい

---

## 3) アプリ開発中に Kubernetes はどう使われるか
kubernetes.io/docs のベストプラクティスに沿うと、アプリ開発では Kubernetes をだいたい次のように使います。

### まず Deployment でアプリを管理する
Pod 単体を直接運用するより、通常は **Deployment** を使います。
理由:
- ReplicaSet を通じて Pod を自己修復できる
- ローリング更新しやすい
- スケールしやすい

### Service で通信面を固定する
Pod の IP は変わるので、アプリ同士は通常 **Service** 経由で通信します。
- フロント → API
- API → 内部ワーカー
- 監視やメトリクス収集先の固定

### labels / selectors を丁寧に設計する
Kubernetes は多くの紐づけを label で行います。
- Deployment がどの Pod を管理するか
- Service がどの Pod に流すか

ここが雑だと、
- Service が Pod を拾わない
- 間違った Pod を拾う
- 意図しない通信断

につながります。

### Secret を YAML に直書きしない
実務では非常に重要です。
- API キー
- DB パスワード
- トークン

を Git 管理するマニフェストにベタ書きしないこと。
今日のラボでも、**機密値はダミーにする**か、Secret を別管理する前提で扱ってください。

### namespace / context を常に確認する
本番事故の定番です。
開発中は apply 前に最低でも次を確認します。
```bash
kubectl config current-context
kubectl get ns
```
必要なら:
```bash
kubectl get pods -n demo
kubectl apply -f app.yaml -n demo
```

---

## 4) 30〜60分ミニラボ
**目的:** Nginx の Deployment と Service を作成し、`get → describe → logs → apply` の流れを安全に体験する

### 前提
次のいずれかのローカルクラスタがあること
- minikube
- kind
- k3d
- 学習用の安全な検証クラスタ

**本番クラスタではやらないこと。**

### Step 0: context を確認
```bash
kubectl config current-context
kubectl get nodes
```

### Step 1: 作業用 namespace を作る
```bash
kubectl create namespace demo
kubectl get ns
```

### Step 2: マニフェストを作る
`app.yaml`
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-demo
  namespace: demo
spec:
  replicas: 2
  selector:
    matchLabels:
      app: web-demo
  template:
    metadata:
      labels:
        app: web-demo
    spec:
      containers:
        - name: nginx
          image: nginx:1.27
          ports:
            - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: web-demo
  namespace: demo
spec:
  selector:
    app: web-demo
  ports:
    - port: 80
      targetPort: 80
  type: ClusterIP
```

### Step 3: apply する
```bash
kubectl apply -f app.yaml
```

### Step 4: 状態を確認する
```bash
kubectl get deployments -n demo
kubectl get pods -n demo
kubectl get svc -n demo
```

期待:
- Deployment が `AVAILABLE` になっている
- Pod が 2 つ Running
- Service に ClusterIP が付与されている

### Step 5: 詳細を見る
```bash
kubectl describe deployment web-demo -n demo
kubectl describe svc web-demo -n demo
```

確認ポイント:
- Deployment の selector が `app: web-demo`
- Pod template の label も `app: web-demo`
- Service selector も `app: web-demo`

### Step 6: logs を見る
まず Pod 名を取得:
```bash
kubectl get pods -n demo
```
そのうち 1 つに対して:
```bash
kubectl logs <pod名> -n demo
```
Nginx はログが少ない場合もありますが、**ログ取得の導線**を確認するのが目的です。

### Step 7: レプリカ数を変えて再 apply
`replicas: 2` を `replicas: 3` に変えて再実行:
```bash
kubectl apply -f app.yaml
kubectl get pods -n demo
```

ここで「YAML を変更して apply する」宣言的運用の基本を体験します。

### Step 8: 安全な片付け
```bash
kubectl delete namespace demo
```

**注意:** `kubectl delete` は破壊的です。実行前に必ず context と対象 namespace を再確認してください。

---

## 5) コマンドチートシート
```bash
# 現在の接続先確認
kubectl config current-context

# namespace 一覧
kubectl get ns

# Pod / Deployment / Service 一覧
kubectl get pods -n demo
kubectl get deployments -n demo
kubectl get svc -n demo

# 詳細確認
kubectl describe pod <pod名> -n demo
kubectl describe deployment web-demo -n demo
kubectl describe svc web-demo -n demo

# ログ確認
kubectl logs <pod名> -n demo
kubectl logs -f <pod名> -n demo

# 反映
kubectl apply -f app.yaml

# 削除（要注意）
kubectl delete namespace demo
```

---

## 6) よくあるミスと安全策

### ミス1: 間違った context に apply する
**危険度高め。**

安全策:
```bash
kubectl config current-context
```
を apply / delete 前に必ず打つ。
可能ならプロンプトや alias で context を見える化する。

### ミス2: namespace を意識していない
`default` に作ってしまい、どこへ行ったか分からなくなる。

安全策:
- manifest に `namespace:` を明示する
- コマンドにも `-n demo` を付ける癖をつける

### ミス3: Service selector と Pod label が一致していない
Service はあるのに通信できない、の典型例。

安全策:
- Deployment template labels
- Deployment selector
- Service selector

の 3 点をセットで確認する。

### ミス4: Secret をマニフェストに直書きする
Git 履歴や共有ファイルに残ってしまう。

安全策:
- 学習用でも本物の認証情報は使わない
- Secret 管理は別手段で行う前提を持つ
- スクリーンショットや共有時にも値を隠す

### ミス5: `delete` の対象を雑に指定する
例:
```bash
kubectl delete -f .
```
や
```bash
kubectl delete pod --all
```
は、文脈を誤るとかなり危険です。

安全策:
- 破壊的コマンド前に context / namespace を再確認
- 学習環境専用 namespace を作ってその中で試す
- 一気に広い範囲へ apply/delete しない

---

## 7) Middle / Advanced へ進む前提

### 次の Middle に進む前提
- Pod / Deployment / Service の役割を説明できる
- `kubectl get`, `describe`, `logs`, `apply` を使える
- label と selector の対応を読める
- namespace を意識して操作できる

### その先の Advanced に進む前提
- rolling update と rollout の基本が分かる
- readinessProbe / livenessProbe の役割を理解している
- ConfigMap / Secret の責務分離を理解している
- 失敗時に `describe` と `logs` から切り分けを始められる

### 予告
- **Middle 候補:** `kubectl rollout`, `scale`, `set image`, `rollout undo`
- **Advanced 候補:** Probe・resource requests/limits・ConfigMap/Secret・障害切り分け

---

## 8) 面接ふう質問
**質問:**
`kubectl get pods` では Pod が Running なのに、アプリにアクセスできません。最初にどこを確認しますか？

**考え方の例:**
1. Service が存在するか
2. Service selector と Pod labels が一致しているか
3. targetPort / containerPort が合っているか
4. `kubectl describe svc` と `kubectl describe pod` でイベントや設定を確認する
5. `kubectl logs` でアプリ側の起動状態を確認する

Running は「コンテナが落ちていない」だけで、**通信可能・正常提供中とは限らない**のがポイントです。

---

## 9) 次の一歩（公式ドキュメント中心）
- Kubernetes Concepts Overview  
  https://kubernetes.io/docs/concepts/overview/

- Pods  
  https://kubernetes.io/docs/concepts/workloads/pods/

- Deployments  
  https://kubernetes.io/docs/concepts/workloads/controllers/deployment/

- Services  
  https://kubernetes.io/docs/concepts/services-networking/service/

- kubectl Overview  
  https://kubernetes.io/docs/reference/kubectl/

- Debug Running Pods  
  https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/

- Configuration Best Practices  
  https://kubernetes.io/docs/concepts/configuration/overview/

---

## 今日のひとこと
Kubernetes 学習の最初の山は、「作る」ことより **ちゃんと観察する** ことです。
`get` で全体を見る、`describe` で理由を見る、`logs` で中身を見る、`apply` は慎重にやる。まずはこの型を身体に入れるのが正解です。
