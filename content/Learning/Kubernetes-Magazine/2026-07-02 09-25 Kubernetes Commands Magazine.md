---
tags:
  - kubernetes
  - k8s
  - devops
  - learning
  - daily
---

[[Home]]

# Kubernetes Commands Magazine — 2026-07-02

## 今回のテーマ
**kubectlで安全にアプリをデプロイ・確認・更新する基本フロー**

**Level:** Beginner

---

## 1) なぜこれが実アプリ開発で重要か
アプリ開発では、コードを書くことと同じくらい「安全に動かすこと」が重要です。Kubernetes では、その操作の多くを `kubectl` で行います。

実際の開発現場では、たとえば次のような作業が日常的に発生します。

- 開発用 Namespace にアプリをデプロイする
- Pod が正しく起動したか確認する
- ログを見てエラー原因を調べる
- Deployment を更新してロールアウト状態を確認する
- 間違った Context や Namespace に操作していないか確認する

この一連の流れを安全に扱えないと、以下の事故につながります。

- 本番クラスタに誤って `apply` する
- 不要な `delete` で検証環境を壊す
- Pod の状態を正しく見ずに障害調査が遅れる
- Secret を Manifest に直書きして漏えいリスクを作る

つまり、`kubectl` は単なるコマンド集ではなく、**アプリを安全に届けて運用するための基本インターフェース**です。

---

## 2) コアとなる kubectl / Kubernetes 概念

### `context`
`kubectl` がどのクラスタに対して操作するかを決めます。

```bash
kubectl config get-contexts
kubectl config current-context
```

**超重要:** `apply` や `delete` の前には必ず現在の Context を確認します。

---

### `namespace`
クラスタ内の論理的な分離単位です。

```bash
kubectl get ns
kubectl config set-context --current --namespace=default
```

開発・検証・本番を分けるときの基本になります。

---

### `Pod`
コンテナを実行する最小単位です。通常、直接 Pod を運用するより、Deployment などの上位リソースから管理します。

```bash
kubectl get pods
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

---

### `Deployment`
アプリの望ましい状態を宣言し、Pod のレプリカ数や更新を管理します。

```bash
kubectl get deployments
kubectl rollout status deployment/<name>
```

アプリ更新時の中心になるリソースです。

---

### `Service`
Pod 群への安定したアクセス方法を提供します。Pod は入れ替わるので、Service を通して接続するのが基本です。

```bash
kubectl get svc
```

---

### `apply`
Manifest に書かれた望ましい状態をクラスタへ反映します。

```bash
kubectl apply -f app.yaml
```

ただし、**適用先の Context / Namespace を確認せずに実行するのは危険**です。

---

## 3) アプリ開発中に Kubernetes はどう使われるか
kubernetes.io/docs のベストプラクティスに沿うと、Kubernetes は「本番だけの仕組み」ではありません。アプリを作る途中でも活用されます。

### 開発時
- コンテナ化したアプリをクラスタ上で再現性高く動かす
- 開発用 Namespace で検証する
- ConfigMap や Secret を使って設定を分離する

### テスト時
- Deployment 更新とロールアウト確認
- 複数 Pod での挙動確認
- ログ・イベントの確認による不具合切り分け

### 運用寄りの開発時
- Readiness / Liveness Probe を意識したアプリ設計
- 環境変数や設定の外出し
- Secret をコードや Git に埋め込まない構成

### 実務上の大事な姿勢
- `kubectl apply -f .` のような広い適用は慎重に行う
- Secret を平文で Manifest に置かない
- まず `get`, `describe`, `logs` で状況を把握してから変更する
- 変更後は `rollout status` で反映結果を確認する

---

## 4) 30〜60分ミニラボ
**ゴール:** 安全確認をしながら NGINX Deployment をデプロイし、確認し、更新する

**所要時間:** 30〜60分

### 前提
- `kubectl` が使える
- 開発用またはローカルの Kubernetes クラスタがある
  - 例: minikube, kind, Docker Desktop Kubernetes など
- 本番クラスタでは実施しない

### Step 0: まず安全確認
```bash
kubectl config current-context
kubectl get ns
```

可能なら専用 Namespace を作ります。

```bash
kubectl create namespace k8s-magazine
kubectl config set-context --current --namespace=k8s-magazine
kubectl config view --minify | grep namespace
```

---

### Step 1: Deployment と Service の Manifest を作る
`nginx-demo.yaml` を作成します。

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-demo
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx-demo
  template:
    metadata:
      labels:
        app: nginx-demo
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
  name: nginx-demo
spec:
  selector:
    app: nginx-demo
  ports:
    - port: 80
      targetPort: 80
```

**安全ポイント:**
- Secret は入れていない
- いきなり外部公開せず、まず ClusterIP Service で作る

---

### Step 2: 適用前に内容確認
```bash
kubectl apply --dry-run=client -f nginx-demo.yaml
```

さらに、適用先確認も行います。

```bash
kubectl config current-context
kubectl config view --minify | grep namespace
```

問題なければ適用します。

```bash
kubectl apply -f nginx-demo.yaml
```

---

### Step 3: 状態確認
```bash
kubectl get deployments
kubectl get pods
kubectl get svc
kubectl rollout status deployment/nginx-demo
```

Pod の詳細確認:

```bash
kubectl describe pod <pod名>
```

---

### Step 4: ログ確認
```bash
kubectl logs deployment/nginx-demo
```

複数 Pod がある場合は個別 Pod を指定しても OK です。

```bash
kubectl get pods
kubectl logs <pod名>
```

---

### Step 5: イメージ更新を試す
NGINX のバージョンを変えてロールアウトを体験します。

```bash
kubectl set image deployment/nginx-demo nginx=nginx:1.27.1
kubectl rollout status deployment/nginx-demo
kubectl get pods
```

変更内容確認:

```bash
kubectl describe deployment nginx-demo
```

---

### Step 6: 後片付け（破壊的操作なので注意）
削除前に対象を必ず確認します。

```bash
kubectl get all
kubectl config current-context
kubectl config view --minify | grep namespace
```

問題なければ削除:

```bash
kubectl delete -f nginx-demo.yaml
```

Namespace ごと消す場合は特に慎重に。

```bash
# かなり破壊的。対象 Namespace を必ず確認してから
kubectl delete namespace k8s-magazine
```

---

## 5) コマンドチートシート

### 現在の接続先確認
```bash
kubectl config current-context
kubectl config get-contexts
kubectl config view --minify
```

### Namespace
```bash
kubectl get ns
kubectl create namespace k8s-magazine
kubectl config set-context --current --namespace=k8s-magazine
```

### 基本確認
```bash
kubectl get pods
kubectl get deployments
kubectl get svc
kubectl get all
```

### 詳細調査
```bash
kubectl describe pod <pod名>
kubectl logs <pod名>
kubectl logs deployment/<deployment名>
```

### デプロイと更新
```bash
kubectl apply -f nginx-demo.yaml
kubectl apply --dry-run=client -f nginx-demo.yaml
kubectl rollout status deployment/nginx-demo
kubectl set image deployment/nginx-demo nginx=nginx:1.27.1
```

### 削除
```bash
kubectl delete -f nginx-demo.yaml
```

---

## 6) よくあるミスと安全なやり方

### ミス1: Context を見ずに `apply` / `delete`
**危険:** 本番クラスタに誤操作する

**安全策:**
```bash
kubectl config current-context
kubectl config view --minify | grep namespace
```
を毎回確認する

---

### ミス2: `kubectl apply -f .` を雑に使う
**危険:** 余計な Manifest まで反映する

**安全策:**
- 対象ファイルを明示する
- `--dry-run=client` を使う
- ディレクトリ適用時は中身を把握してから実行する

---

### ミス3: Secret を Manifest に平文で書く
**危険:** Git や共有ファイルから漏れる

**安全策:**
- Secret を直接貼らない
- 専用の Secret 管理方式を使う
- リポジトリに資格情報を入れない

---

### ミス4: Pod だけ見て原因を早合点する
**危険:** イベントや Deployment 側の問題を見落とす

**安全策:**
- `get` → `describe` → `logs` の順で見る
- `rollout status` も確認する

---

### ミス5: 削除範囲を理解せずに `delete`
**危険:** Namespace 単位で消してしまう

**安全策:**
- 削除前に `get all` で対象確認
- Namespace と Context を再確認
- 本番ではレビューや承認フローを入れる

---

## 7) 面接っぽい一問
**質問:**
`Pod` に直接 `kubectl exec` や `kubectl delete pod` を行う運用より、`Deployment` を使ってアプリを管理するべきなのはなぜですか？

**考えるポイント:**
- 宣言的管理
- 自己修復
- レプリカ管理
- ロールアウト / ロールバック
- 運用再現性

---

## 8) 次の一歩（公式ドキュメント中心）

- Kubernetes Documentation ホーム  
  https://kubernetes.io/docs/

- Overview: Kubernetes とは  
  https://kubernetes.io/docs/concepts/overview/

- kubectl の基本  
  https://kubernetes.io/docs/reference/kubectl/

- Deployments  
  https://kubernetes.io/docs/concepts/workloads/controllers/deployment/

- Services  
  https://kubernetes.io/docs/concepts/services-networking/service/

- ConfigMap  
  https://kubernetes.io/docs/concepts/configuration/configmap/

- Secret  
  https://kubernetes.io/docs/concepts/configuration/secret/

- Debug Pods and ReplicationControllers  
  https://kubernetes.io/docs/tasks/debug/debug-application/debug-pods/

---

## 9) 次回予告
**Level: Middle（前提: Pod / Deployment / Service / Namespace / Context の基本理解）**

次回は、**ConfigMap・Secret・環境変数・Probe を使って「動くだけ」から「運用しやすいアプリ」へ進む**流れを扱うと良いです。

候補テーマ:
- ConfigMap と Secret の安全な使い分け
- Readiness / Liveness Probe の実践
- `kubectl describe` と Event を使ったトラブルシュート
