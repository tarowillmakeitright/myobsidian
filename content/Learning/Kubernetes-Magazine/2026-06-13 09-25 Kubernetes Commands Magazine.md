---
tags:
  - kubernetes
  - k8s
  - devops
  - learning
  - daily
---

[[Home]]

# Kubernetes Commands Magazine — 2026-06-13

#kubernetes #k8s #devops #learning #daily

今日は **Beginner → Middle → Advanced** の流れで、実アプリ開発に直結する Kubernetes 学習を進める。
テーマは **「kubectl でアプリを安全にデプロイし、状態を観察し、更新する」**。

---

## 1) Topic + Level

### Topic
**Kubernetes の基本リソースを kubectl で扱いながら、アプリ開発で必要なデプロイ・確認・更新の流れを理解する**

### Level Arc
- **Beginner:** Pod / Deployment / Service を `kubectl get` `describe` `logs` `apply` で扱う
- **Middle:** Namespace、rolling update、ラベル、セレクタ、replicas を使って安全にアプリを更新する
- **Advanced:** ConfigMap / Secret / probes / rollout / context 管理を含めて、実運用寄りの安全な操作を理解する

### Prerequisites
- **Middle の前提:**
  - Pod と Deployment の違いをざっくり説明できる
  - `kubectl get pods` と `kubectl logs` を使ったことがある
  - YAML マニフェストを 1 回は `kubectl apply -f` したことがある
- **Advanced の前提:**
  - Service の役割を理解している
  - rolling update の概念を知っている
  - `kubectl config current-context` と Namespace の重要性を理解している

---

## 2) Why it matters for real app development

Kubernetes が実アプリ開発で重要なのは、**「コンテナを 1 個動かす」だけでなく、壊れにくく・更新しやすく・観測しやすい形でアプリを運用できる**から。

現場では特にここに効く。

- **再現可能なデプロイ**
  - マニフェストで desired state を定義し、チームで共有できる
- **安全な更新**
  - rolling update によって無停止に近い更新がしやすい
- **自己修復**
  - Pod が落ちても Deployment が再作成する
- **観測しやすさ**
  - `logs` `describe` `events` で障害調査の入り口を作れる
- **環境分離**
  - Namespace や context で開発・検証・本番を分けやすい
- **アプリ設計との接続**
  - ヘルスチェック、設定分離、Secret 管理など、アプリ実装にも影響する

ただし、Kubernetes は便利なぶん事故範囲も広い。特に **apply 先の context を見ずに実行する、広すぎる delete を打つ、Secret を平文で雑に扱う** と痛い。便利さより先に、**安全な確認習慣** を身につけるのが大事。

---

## 3) Core kubectl / Kubernetes concept explanations

### Beginner

#### `kubectl get`
リソースの一覧や状態を確認する。

```bash
kubectl get pods
kubectl get deployments
kubectl get svc
```

よく使う形:

```bash
kubectl get pods -o wide
kubectl get all
```

ポイント:
- `pods`: 実際に動く最小実行単位
- `deployments`: Pod を望ましい数・状態で維持する
- `svc` (`service`): Pod への安定したアクセス口を提供する

#### `kubectl describe`
個別リソースの詳細、イベント、失敗理由を見る。

```bash
kubectl describe pod myapp-abc123
kubectl describe deployment myapp
```

CrashLoopBackOff、ImagePullBackOff、probe 失敗などの調査で非常に重要。

#### `kubectl logs`
Pod やコンテナのログを見る。

```bash
kubectl logs pod/myapp-abc123
kubectl logs deployment/myapp
```

複数コンテナなら:

```bash
kubectl logs pod/myapp-abc123 -c app
```

追従するなら:

```bash
kubectl logs -f deployment/myapp
```

#### `kubectl apply -f`
マニフェストをクラスタへ適用する。

```bash
kubectl apply -f deployment.yaml
```

重要:
- 変更を宣言的に適用する
- 作成にも更新にも使える
- **実行前に context / namespace / 対象ファイルを確認する習慣** が必要

#### Pod / Deployment / Service の関係
- **Pod:** コンテナを包む実行単位
- **Deployment:** Pod を管理し、更新・自己修復・スケールを担う
- **Service:** Pod が入れ替わっても、安定した接続先を提供する

実務では **Pod を直接手で作るより Deployment を使う** のが基本。

---

### Middle

#### Namespace
同じクラスタ内でリソースを論理分離する。

```bash
kubectl get pods -n dev
kubectl apply -n dev -f deployment.yaml
```

安全の基本:
- 開発用 Namespace と本番用 Namespace を分ける
- 何も指定しない default Namespace へ雑に入れない

#### Labels と Selectors
Kubernetes が「どの Pod を管理・転送対象にするか」を決めるための仕組み。

例:

```yaml
metadata:
  labels:
    app: myapp
    tier: web
```

Service や Deployment はこのラベルを見て対象を選ぶ。

#### Replicas
同じ Pod を何個動かすか。

```yaml
spec:
  replicas: 3
```

開発でも「1 個なら動く」だけで終わらず、複数 Pod を前提に挙動を見る癖が大事。

#### Rolling Update
アプリ更新時に新しい Pod へ少しずつ置き換える。

```bash
kubectl rollout status deployment/myapp
kubectl rollout history deployment/myapp
```

問題があれば:

```bash
kubectl rollout undo deployment/myapp
```

これがあるから、Kubernetes では **安全なリリース手順** を作りやすい。

---

### Advanced

#### ConfigMap と Secret
アプリ設定と機密情報を、イメージから分離する。

- **ConfigMap:** 非機密な設定
- **Secret:** 機密情報

ただし注意:
- Secret は「暗号化そのもの」ではなく、扱いを分離する仕組み
- base64 は秘匿ではない
- Git に平文で置かない
- 本番では secret manager / encryption at rest / RBAC まで考える

#### Readiness Probe / Liveness Probe
アプリが「起動している」だけでなく「受け付け可能か」を Kubernetes に伝える。

- **livenessProbe:** ハングしたアプリを再起動する判断材料
- **readinessProbe:** まだリクエストを受ける準備がない Pod を Service から外す

これは実アプリ品質にかなり直結する。

#### Context 管理
同じ `kubectl apply -f` でも、context を間違えると本番へ飛ぶ。

確認コマンド:

```bash
kubectl config current-context
kubectl config get-contexts
```

安全策:
- 実行前に current-context を確認
- `-n` 明示を癖にする
- 危険な操作前は対象を再確認

#### `kubectl diff`
apply 前の差分確認に使える。

```bash
kubectl diff -f deployment.yaml
```

本番に近い環境ほど、**いきなり apply より diff → apply** が安全。

---

## 4) How Kubernetes is used while building apps

kubernetes.io/docs のベストプラクティスに寄せると、アプリ開発中の Kubernetes 活用は次の流れが実践的。

### 開発フローの定番
1. **アプリをコンテナ化する**
2. **Deployment と Service を定義する**
3. **設定は ConfigMap、機密は Secret に分離する**
4. **readiness / liveness probe を入れる**
5. **Namespace を分けて環境ごとに適用する**
6. **`kubectl get` `describe` `logs` `rollout status` で観察する**
7. **段階的に更新し、問題時は rollback できる状態にする**

### 公式ベストプラクティスに沿う考え方

- **Pod を直接運用の中心にしない**
  - 通常は Deployment などの controller を使う
- **宣言的管理を優先する**
  - `apply` ベースで状態を管理する
- **設定とコードを分離する**
  - イメージに環境依存設定を焼き込まない
- **Secret をマニフェストに平文で置かない**
  - 少なくとも Git 直コミットを避ける
- **ヘルスチェックを入れる**
  - 「起動した」だけでなく「受け付け可能」を判定する
- **リソース要求を意識する**
  - CPU / memory requests・limits を理解する
- **Namespace と RBAC で blast radius を下げる**
  - なんでも cluster-admin で触らない
- **変更前に差分と対象コンテキストを確認する**
  - 事故防止として非常に重要

### よくない例

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp
spec:
  containers:
    - name: myapp
      image: myapp:latest
      env:
        - name: DB_PASSWORD
          value: super-secret-password
```

問題点:
- Pod を直接作っていて自己修復・更新戦略が弱い
- `latest` 依存で再現性が低い
- Secret を平文で埋め込んでいる
- probe がない

### 改善方向
- Deployment を使う
- タグを固定する
- Secret / ConfigMap に分離する
- readinessProbe を設定する
- Namespace と labels を明示する

---

## 5) 30-60 minute hands-on mini lab

### ラボテーマ
**Nginx アプリを Deployment + Service としてデプロイし、更新・観察・安全確認まで行う**

### 所要時間
約 45 分

### ゴール
- Namespace を作る
- Deployment と Service を apply する
- `get` `describe` `logs` を使って状態確認する
- イメージ更新と rollout status を試す
- context / namespace 確認の大切さを体で覚える

### 前提
ローカル Kubernetes 環境（例: minikube, kind, Docker Desktop Kubernetes など）があること。

### 手順

#### 1. context を確認する

```bash
kubectl config current-context
kubectl config get-contexts
```

> ここで **本当にローカル検証環境か** を確認する。本番や共有クラスタに向けて作業しないこと。

#### 2. Namespace を作る

```bash
kubectl create namespace k8s-magazine-lab
```

確認:

```bash
kubectl get ns
```

#### 3. `deployment.yaml` を作る

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
  namespace: k8s-magazine-lab
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

#### 4. `service.yaml` を作る

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web
  namespace: k8s-magazine-lab
spec:
  selector:
    app: web
  ports:
    - port: 80
      targetPort: 80
  type: ClusterIP
```

#### 5. apply 前に差分確認（可能なら）

```bash
kubectl diff -f deployment.yaml
kubectl diff -f service.yaml
```

差分が見られない環境なら、そのまま進めてよい。

#### 6. apply する

```bash
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
```

#### 7. 状態確認

```bash
kubectl get all -n k8s-magazine-lab
kubectl get pods -n k8s-magazine-lab -o wide
kubectl describe deployment web -n k8s-magazine-lab
kubectl rollout status deployment/web -n k8s-magazine-lab
```

#### 8. ログ確認

```bash
kubectl logs deployment/web -n k8s-magazine-lab
```

#### 9. ポートフォワードでアクセス

```bash
kubectl port-forward svc/web 8080:80 -n k8s-magazine-lab
```

別ターミナルで:

```bash
curl http://127.0.0.1:8080
```

#### 10. イメージ更新を試す

```bash
kubectl set image deployment/web nginx=nginx:1.27.1 -n k8s-magazine-lab
kubectl rollout status deployment/web -n k8s-magazine-lab
kubectl rollout history deployment/web -n k8s-magazine-lab
```

#### 11. 問題があればロールバック

```bash
kubectl rollout undo deployment/web -n k8s-magazine-lab
```

#### 12. 後片付け

まず対象を再確認:

```bash
kubectl config current-context
kubectl get all -n k8s-magazine-lab
```

削除:

```bash
kubectl delete namespace k8s-magazine-lab
```

> 警告: `kubectl delete namespace ...` はその Namespace 配下をまとめて削除する。**対象 Namespace を 2 回確認**してから実行すること。

### 余力があれば
- ConfigMap を作って Nginx の設定差し替えを試す
- `kubectl get events -n k8s-magazine-lab --sort-by=.metadata.creationTimestamp` を見る
- requests / limits を追加して挙動を見る

---

## 6) Command cheatsheet

### 基本確認

```bash
kubectl config current-context
kubectl config get-contexts
kubectl get nodes
kubectl get ns
kubectl get pods -A
kubectl get all -n <namespace>
```

### リソース操作

```bash
kubectl apply -f deployment.yaml
kubectl apply -n dev -f service.yaml
kubectl diff -f deployment.yaml
kubectl delete -f deployment.yaml
kubectl delete namespace k8s-magazine-lab
```

### 調査

```bash
kubectl describe pod <pod-name> -n <namespace>
kubectl describe deployment <name> -n <namespace>
kubectl logs deployment/<name> -n <namespace>
kubectl logs -f pod/<pod-name> -n <namespace>
kubectl get events -n <namespace> --sort-by=.metadata.creationTimestamp
```

### rollout / update

```bash
kubectl rollout status deployment/<name> -n <namespace>
kubectl rollout history deployment/<name> -n <namespace>
kubectl rollout undo deployment/<name> -n <namespace>
kubectl set image deployment/<name> <container>=<image>:<tag> -n <namespace>
```

### デバッグ・接続

```bash
kubectl exec -it pod/<pod-name> -n <namespace> -- sh
kubectl port-forward svc/<service-name> 8080:80 -n <namespace>
```

> 注意:
> - `kubectl apply -f .` はディレクトリ配下の全 YAML を適用しうる。対象範囲を理解してから使う。
> - `kubectl delete -f .` も同様に危険。
> - `kubectl delete pod ...` は一時対処にはなるが、Deployment 管理下なら再作成される。

---

## 7) Common mistakes and safe practices

### よくあるミス

#### 1. current-context を見ずに apply する
問題:
- ローカルのつもりで本番へ apply する事故が起きる

安全策:

```bash
kubectl config current-context
kubectl config get-contexts
```

重要変更前は毎回確認する。

#### 2. Namespace を明示しない
問題:
- default Namespace に混ざる
- 想定外の環境へ作られる

安全策:
- マニフェストに `namespace:` を書く
- CLI でも `-n` を明示する

#### 3. Secret を平文で管理する
悪い例:

```yaml
env:
  - name: API_KEY
    value: abc123supersecret
```

問題:
- Git やレビュー画面、履歴、画面共有で漏れやすい

安全策:
- Secret リソースや外部 secret manager を使う
- base64 を暗号化と勘違いしない
- 機密はリポジトリへ直置きしない

#### 4. `latest` タグを使う
問題:
- いつのイメージか曖昧
- 再現性が下がる

安全策:
- 明示的なタグや digest を使う

#### 5. Pod 単位で手作業修復し続ける
問題:
- 再現性がない
- controller の設計意図から外れる

安全策:
- 修正は Deployment / manifest / image に戻す
- root cause を `describe` `logs` `events` で確認する

#### 6. 破壊的コマンドの範囲を理解していない
危険例:

```bash
kubectl delete namespace prod
kubectl delete -f .
kubectl apply -f .
```

安全策:
- 実行前に対象ディレクトリと context を確認
- 可能なら `kubectl diff` を使う
- 共有環境や本番では peer review 的な確認を入れる

#### 7. probes を入れない
問題:
- 起動しただけの壊れたアプリがトラフィックを受ける

安全策:
- readinessProbe をまず入れる
- livenessProbe は挙動を理解した上で追加する

---

## 8) One interview-style question

**質問:**
Deployment と Pod の違いを説明したうえで、なぜ実運用では Pod を直接管理するより Deployment を使うことが多いのか、さらに rolling update・rollback・readiness probe がどのように安全なアプリ更新に役立つかを説明してください。

**考えるポイント:**
- desired state と自己修復
- replicas 管理
- 無停止に近い更新
- 壊れた Pod を Service から外す仕組み
- 人手の運用ではなく宣言的運用へ寄せる理由

---

## 9) Next-step resources

まずは公式ドキュメント中心で進むのが堅い。

- Kubernetes Documentation home
  - https://kubernetes.io/docs/
- Overview / Kubernetes とは
  - https://kubernetes.io/docs/concepts/overview/
- Kubectl overview
  - https://kubernetes.io/docs/reference/kubectl/
- Deployments
  - https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Services
  - https://kubernetes.io/docs/concepts/services-networking/service/
- Namespaces
  - https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/
- Labels and Selectors
  - https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/
- ConfigMaps
  - https://kubernetes.io/docs/concepts/configuration/configmap/
- Secrets
  - https://kubernetes.io/docs/concepts/configuration/secret/
- Liveness, Readiness, Startup Probes
  - https://kubernetes.io/docs/concepts/configuration/liveness-readiness-startup-probes/
- Debug running pods
  - https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/
- Configure Access to Multiple Clusters
  - https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/
- Resource Management for Pods and Containers
  - https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/

---

## 今日のひとこと

Kubernetes は「覚えるコマンドが多いツール」ではなく、**壊れにくく、更新しやすく、観察しやすいアプリ運用を設計するための土台**。
まずは `get` `describe` `logs` `apply` `rollout` を安全に使い、**context 確認・Namespace 明示・Secret 分離** を習慣にするとかなり強い。