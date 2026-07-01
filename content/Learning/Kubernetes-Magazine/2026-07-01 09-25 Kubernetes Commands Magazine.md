---
tags:
  - kubernetes
  - k8s
  - devops
  - learning
  - daily
---

[[Home]]

# 2026-07-01 09:25 Kubernetes Commands Magazine

**今日のテーマ:** `kubectl get / describe / logs` でアプリの状態を安全に観察する

この号は **Beginner → Middle → Advanced** の学習アークで、同じ観察テーマを段階的に深めます。

---

## 1) Topic + Level

### Beginner
**Topic:** Pod / Deployment / Service を `kubectl get` で読む基礎

### Middle
**Topic:** `kubectl describe` と `kubectl logs` で障害の手がかりを掴む

**Prerequisites:**
- `kubectl get pods -n <namespace>` が読める
- Pod / Deployment / Service の役割をざっくり理解している
- namespace と context の概念を知っている

### Advanced
**Topic:** ラベル・セレクタ・イベント・複数コンテナを意識して、本番に近い観察を行う

**Prerequisites:**
- `kubectl describe pod` の出力で Events 欄を見たことがある
- `kubectl logs` の基本オプションを使える
- Deployment が ReplicaSet / Pod を管理する流れを理解している

---

## 2) Why it matters for real app development

Kubernetes を使った実アプリ開発では、最初に必要なのは「変更する力」より **安全に観察する力** です。

なぜ重要か:
- アプリが落ちた時、まず必要なのは再デプロイではなく **現状把握**
- 開発・検証・本番で共通して使える基本操作が `get / describe / logs`
- kubernetes.io のベストプラクティスでも、宣言的管理・最小権限・明示的な namespace 利用と同じくらい、**対象を間違えず確認する運用** が重要
- 事故の多くは「壊した」より「違う context / namespace を触った」から起きる

つまり、観察コマンドはデバッグだけでなく、**安全運用そのもの** です。

---

## 3) Core kubectl / Kubernetes concept explanations

### `kubectl get`
リソースの一覧や要約を見る基本コマンドです。

例:
```bash
kubectl get pods
kubectl get deployments
kubectl get svc -n web
kubectl get pods -o wide
```

ポイント:
- `pods`, `deployments`, `services` などリソース種別ごとに確認できる
- `-n` で namespace を明示すると事故が減る
- `-o wide` でノードや IP など追加情報を見られる

### `kubectl describe`
一覧より深い状態を確認するコマンドです。

例:
```bash
kubectl describe pod <pod-name> -n web
kubectl describe deployment <deployment-name> -n web
```

見るべき場所:
- Status
- Containers
- Image
- Readiness / Liveness
- Events

### `kubectl logs`
コンテナの標準出力・標準エラーを見るコマンドです。

例:
```bash
kubectl logs <pod-name> -n web
kubectl logs <pod-name> -c app -n web
kubectl logs -f <pod-name> -n web
kubectl logs --previous <pod-name> -n web
```

ポイント:
- 複数コンテナ Pod では `-c` が必要なことがある
- CrashLoopBackOff の調査では `--previous` が有効
- `-f` は tail -f 的に追跡する

### context / namespace
- **context** = どのクラスタ・認証情報・namespace を使うか
- **namespace** = クラスタ内の論理的な区画

安全確認:
```bash
kubectl config current-context
kubectl config get-contexts
kubectl get ns
```

**重要:** `apply` や `delete` を打つ前に、必ず **current-context** と **namespace** を確認すること。

---

## 4) How Kubernetes is used while building apps

アプリ開発では、Kubernetes は単なる実行基盤ではなく、以下の流れで使われます。

1. アプリをコンテナ化する
2. Deployment で desired state を宣言する
3. Service で通信経路を安定化する
4. readiness / liveness probe で健全性を扱う
5. `kubectl get / describe / logs` で状態確認する
6. マニフェストを Git で管理し、変更はレビュー可能にする

kubernetes.io の考え方に沿う実践ポイント:
- 手作業で即興変更しすぎず、**マニフェストを source of truth にする**
- Secret を平文で Git に入れない
- namespace を分けて環境分離する
- labels を整えて観察しやすくする
- 本番で破壊的コマンドを急いで打たず、まず read-only な確認を優先する

開発中の典型例:
- 新しい API をデプロイした
- Pod は Running だがアプリが 500 を返す
- `kubectl get pods` で再起動回数確認
- `kubectl describe pod` で probe failure や image pull error を確認
- `kubectl logs` でアプリ例外を確認

この流れができると、アプリ開発者としての Kubernetes 実務力がかなり上がります。

---

## 5) 30-60 minute hands-on mini lab

**目標:** Nginx Deployment を作り、正常状態と軽い障害調査を体験する

**想定時間:** 40分

### Step 0: 安全確認
```bash
kubectl config current-context
kubectl get ns
```

可能なら練習用 namespace を作成:
```bash
kubectl create namespace k8s-magazine-lab
```

### Step 1: Deployment 作成
```bash
kubectl create deployment web --image=nginx:1.27 -n k8s-magazine-lab
kubectl get deployments -n k8s-magazine-lab
kubectl get pods -n k8s-magazine-lab
```

### Step 2: Service 公開
```bash
kubectl expose deployment web --port=80 --target-port=80 --type=ClusterIP -n k8s-magazine-lab
kubectl get svc -n k8s-magazine-lab
```

### Step 3: 観察
```bash
kubectl get pods -o wide -n k8s-magazine-lab
kubectl describe deployment web -n k8s-magazine-lab
kubectl describe pod -l app=web -n k8s-magazine-lab
```

### Step 4: ログ確認
Pod 名を取得:
```bash
kubectl get pods -n k8s-magazine-lab
```

その後:
```bash
kubectl logs <pod-name> -n k8s-magazine-lab
```

### Step 5: レプリカ数を増やす
```bash
kubectl scale deployment web --replicas=3 -n k8s-magazine-lab
kubectl get pods -n k8s-magazine-lab
```

### Step 6: Middle 向け観察
ラベルで取得:
```bash
kubectl get pods -l app=web -n k8s-magazine-lab
kubectl describe pods -l app=web -n k8s-magazine-lab
```

### Step 7: Advanced 向け軽い障害調査
存在しないイメージに更新して、Events を観察する:

```bash
kubectl set image deployment/web nginx=nginx:does-not-exist -n k8s-magazine-lab
kubectl get pods -n k8s-magazine-lab
kubectl describe deployment web -n k8s-magazine-lab
kubectl describe pods -l app=web -n k8s-magazine-lab
```

見たいポイント:
- `ImagePullBackOff`
- `ErrImagePull`
- Events のエラーメッセージ

元に戻す:
```bash
kubectl set image deployment/web nginx=nginx:1.27 -n k8s-magazine-lab
kubectl rollout status deployment/web -n k8s-magazine-lab
```

### Step 8: 後片付け
**削除は対象確認後に実行:**
```bash
kubectl get all -n k8s-magazine-lab
kubectl delete namespace k8s-magazine-lab
```

**警告:** `kubectl delete namespace ...` はその namespace 配下をまとめて消します。現在の context と対象 namespace を必ず確認してください。

---

## 6) Command cheatsheet

```bash
# 現在の接続先確認
kubectl config current-context
kubectl config get-contexts

# 基本一覧
kubectl get pods -n <namespace>
kubectl get deployments -n <namespace>
kubectl get svc -n <namespace>
kubectl get events -n <namespace>

# 詳細確認
kubectl describe pod <pod-name> -n <namespace>
kubectl describe deployment <deployment-name> -n <namespace>

# ログ
kubectl logs <pod-name> -n <namespace>
kubectl logs -f <pod-name> -n <namespace>
kubectl logs <pod-name> -c <container-name> -n <namespace>
kubectl logs --previous <pod-name> -n <namespace>

# ラベル・セレクタ
kubectl get pods -l app=web -n <namespace>

# スケール
kubectl scale deployment <name> --replicas=3 -n <namespace>

# ロールアウト
kubectl rollout status deployment/<name> -n <namespace>

# 作成
kubectl create deployment web --image=nginx:1.27 -n <namespace>
kubectl expose deployment web --port=80 --target-port=80 --type=ClusterIP -n <namespace>
```

---

## 7) Common mistakes and safe practices

### よくあるミス
- `default` namespace のまま作業して、対象を見失う
- `kubectl apply -f .` を意図しないディレクトリで実行する
- current-context を確認せず、本番クラスタに変更を入れる
- Pod が落ちた瞬間に削除してしまい、原因調査の情報を消す
- Secret を YAML に平文で書く、または Git にコミットする
- `kubectl delete pod ...` を安易に実行して「直った気」になる

### 安全なやり方
- 変更前に毎回これを確認する:
```bash
kubectl config current-context
kubectl get ns
```
- `apply` / `delete` 前は対象を一覧で確認する:
```bash
kubectl get all -n <namespace>
```
- 調査は **get → describe → logs** の順で進める
- Secret は Kubernetes Secret や外部 secret manager を使い、平文マニフェストを避ける
- ラベルを整えて、対象選択を安定させる
- 破壊的コマンド前には scope を声に出して確認するくらいでちょうどいい

**特に注意:**
- `kubectl delete namespace ...`
- `kubectl delete -f ...`
- `kubectl apply -f .`
- `kubectl config use-context ...`

これらは便利ですが、**context / namespace / 対象パスの確認なしに打たない** こと。

---

## 8) One interview-style question

**Q.** `kubectl get pods` では Pod が Running なのに、アプリが正常に動いていないことがあります。次にどのコマンドをどういう順番で使って確認しますか？

**期待したい答えの方向性:**
- まず namespace / context を確認
- `kubectl describe pod` で Events, probes, image, restart 回数を確認
- `kubectl logs` でアプリの例外や起動失敗を見る
- 必要なら Deployment / Service 側も `describe` する
- Running は「アプリ正常」の保証ではないと説明できる

---

## 9) Next-step resources

公式ドキュメント中心:

- Overview: Kubernetes Documentation  
  https://kubernetes.io/docs/home/
- kubectl Overview  
  https://kubernetes.io/docs/reference/kubectl/
- Debug Services  
  https://kubernetes.io/docs/tasks/debug/debug-application/debug-service/
- Debug Running Pod  
  https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/
- Deployments  
  https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Services  
  https://kubernetes.io/docs/concepts/services-networking/service/
- Labels and Selectors  
  https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/
- Secrets  
  https://kubernetes.io/docs/concepts/configuration/secret/
- Configure Access to Multiple Clusters  
  https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/

---

## Closing note

今日の学習のゴールは、Kubernetes を「操作する」より先に、**安全に観察して正しく状況判断する** ことです。

Beginner は一覧を見る力、Middle は原因の手がかりを掴む力、Advanced は本番に近い観察精度を意識してください。次号ではこの流れを土台に、`kubectl exec / port-forward / rollout` あたりへ進むと実務につながりやすいです。
