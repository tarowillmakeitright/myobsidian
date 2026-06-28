---
tags:
  - kubernetes
  - k8s
  - devops
  - learning
  - daily
---

[[Home]]

# Kubernetes Commands Magazine — 2026-06-28 09:25

## 1) Topic + Level
**Topic:** `kubectl apply` / `kubectl rollout status` / `kubectl rollout undo` でアプリを安全に更新する  
**Level:** Middle

**Prerequisites:**
- Pod / Deployment / Service の基本がわかる
- `kubectl get` / `kubectl describe` / `kubectl logs` で状態確認ができる
- `kubectl config current-context` と namespace 確認を習慣化している

この号では、Kubernetes 上でアプリを **「変える」** ときの基本を扱います。観察だけでなく、Deployment を更新し、進行状況を見て、問題があればロールバックする流れです。実務でかなり重要な山場です。

---

## 2) Why it matters for real app development
実際のアプリ開発では、コードを書いて終わりではなく、**安全に新バージョンを出す** ところまでが仕事です。

たとえば次のような場面があります。

- API コンテナの新イメージをデプロイしたい
- 環境変数や probe 設定を更新したい
- 一部の Pod だけ新バージョンに切り替えながら状態を確認したい
- 更新後に 500 エラーが増えたので、すぐ前の安定版へ戻したい

Kubernetes の Deployment は、この「段階的に入れ替える」「進捗を追う」「戻す」を支える仕組みです。  
アプリ開発では、**速く出すこと** と同じくらい **安全に戻せること** が大事です。

---

## 3) Core kubectl/Kubernetes concept explanations

### `kubectl apply`
YAML マニフェストに書かれた desired state をクラスタへ反映します。  
「この状態になっていてほしい」を宣言し、Kubernetes 側が現在との差分を埋めます。

例:
```bash
kubectl apply -f deployment.yaml
kubectl apply -f k8s/ -n demo
```

> **重要:** `apply` は便利ですが、対象 context / namespace / ファイル範囲を取り違えると事故になります。特に `kubectl apply -f .` やディレクトリ丸ごと適用は、何が含まれているかを必ず確認してください。

### Deployment の rolling update
Deployment は Pod を一気に入れ替えるのではなく、通常は **rolling update** で段階的に更新します。  
新 Pod を作り、準備できたら古い Pod を減らす流れです。

更新戦略では主に次を見ます。
- `maxUnavailable`: 更新中に使えなくてよい Pod 数
- `maxSurge`: 一時的に増やしてよい Pod 数

### `kubectl rollout status`
Deployment の更新が進行中か、完了したか、止まっているかを確認します。

例:
```bash
kubectl rollout status deployment/web -n demo
```

### `kubectl rollout history`
Deployment の更新履歴を確認します。

例:
```bash
kubectl rollout history deployment/web -n demo
```

### `kubectl rollout undo`
直前、または指定 revision の Deployment 状態へ戻します。

例:
```bash
kubectl rollout undo deployment/web -n demo
kubectl rollout undo deployment/web --to-revision=3 -n demo
```

### readinessProbe
Pod が **トラフィックを受けてよい状態か** を判定します。  
rolling update 中に readiness が通らない Pod は Service の送り先に入りません。アプリを安全に入れ替えるうえで重要です。

### 宣言的運用
Kubernetes では、`kubectl edit` や場当たり的な手作業よりも、**YAML を Git などで管理し、apply で反映する** 方が再現性・レビュー性・監査性が高くなります。

---

## 4) How Kubernetes is used while building apps
kubernetes.io/docs の考え方に沿うと、アプリ開発での更新フローはだいたいこうなります。

1. **Deployment マニフェストで desired state を定義する**  
   イメージ、replicas、probe、resources、labels を宣言する

2. **小さく安全に更新する**  
   rolling update を使い、いきなり全 Pod を止めない

3. **rollout の進行を観察する**  
   `kubectl rollout status`、`get pods`、`describe`、`logs` を使って失敗の早期検知を行う

4. **問題があれば素早く戻す**  
   `rollout undo` で安定状態へ戻す

5. **Secret や設定を安全に扱う**  
   本物の認証情報を YAML に直書きしない。学習用サンプルでも秘密値はダミーにする

実務では、単に `kubectl set image` で場当たり的に更新するより、**マニフェスト管理 + apply + rollout 監視** のほうが圧倒的に安全です。

---

## 5) 30-60 minute hands-on mini lab
**ラボ名:** Nginx Deployment を更新し、進捗確認とロールバックを体験する  
**想定時間:** 40〜55分

### 目的
- 検証用 namespace で Deployment を作る
- `kubectl apply` で変更を反映する
- `kubectl rollout status` で進行を見る
- 意図的に問題のある更新を入れて `rollout undo` を試す

### 前提
- `kubectl` が使える
- kind / minikube / Docker Desktop Kubernetes などの検証環境がある
- **本番クラスタでは絶対にやらないこと**

### Step 0: 安全確認
```bash
kubectl config current-context
kubectl get ns
```

> **注意:** `apply` や `delete` の前に current context と namespace を必ず確認してください。共有クラスタや本番クラスタでの取り違えは典型的な事故です。

### Step 1: 検証用 namespace を作成
```bash
kubectl create namespace k8s-rollout-lab
```

### Step 2: 最初の Deployment を作る
以下を `deployment-v1.yaml` として保存します。

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
  namespace: k8s-rollout-lab
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
```

適用します。

```bash
kubectl apply -f deployment-v1.yaml
kubectl rollout status deployment/web -n k8s-rollout-lab
kubectl get pods -n k8s-rollout-lab
```

### Step 3: Service を作る
以下を `service.yaml` として保存します。

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web
  namespace: k8s-rollout-lab
spec:
  selector:
    app: web
  ports:
    - port: 80
      targetPort: 80
```

```bash
kubectl apply -f service.yaml
kubectl get svc -n k8s-rollout-lab
```

### Step 4: 正常な更新を試す
`deployment-v1.yaml` の image を `nginx:1.27.1` など利用可能なタグへ変更し、再適用します。

```bash
kubectl apply -f deployment-v1.yaml
kubectl rollout status deployment/web -n k8s-rollout-lab
kubectl rollout history deployment/web -n k8s-rollout-lab
kubectl get pods -n k8s-rollout-lab
```

観察ポイント:
- 古い Pod がすぐ全滅せず、段階的に入れ替わるか
- rollout が完了するか
- 新しい Pod が readiness を通ってから切り替わるか

### Step 5: 失敗する更新をわざと作る
今度は image を存在しないタグにします。例:

```yaml
image: nginx:does-not-exist
```

再適用:

```bash
kubectl apply -f deployment-v1.yaml
kubectl rollout status deployment/web -n k8s-rollout-lab
```

別ターミナルまたは続けて確認:

```bash
kubectl get pods -n k8s-rollout-lab
kubectl describe deployment web -n k8s-rollout-lab
kubectl describe pod <pod名> -n k8s-rollout-lab
```

観察ポイント:
- `ImagePullBackOff` や `ErrImagePull` が出るか
- rollout が完了しないか
- Events に失敗理由が出るか

### Step 6: ロールバックする
```bash
kubectl rollout undo deployment/web -n k8s-rollout-lab
kubectl rollout status deployment/web -n k8s-rollout-lab
kubectl rollout history deployment/web -n k8s-rollout-lab
kubectl get pods -n k8s-rollout-lab
```

これで、前の安定状態へ戻る流れを体験できます。

### Step 7: 後片付け
```bash
kubectl delete namespace k8s-rollout-lab
```

> **注意:** namespace 削除はその中のリソースをまとめて削除します。対象名を声に出して確認するくらいでちょうどいいです。

---

## 6) Command cheatsheet
```bash
# 接続先確認
kubectl config current-context

# namespace 一覧
kubectl get ns

# マニフェスト適用
kubectl apply -f deployment.yaml
kubectl apply -f k8s/

# Deployment の状態確認
kubectl get deployments -n <namespace>
kubectl get pods -n <namespace>

# rollout の進行確認
kubectl rollout status deployment/<name> -n <namespace>

# rollout 履歴確認
kubectl rollout history deployment/<name> -n <namespace>

# ロールバック
kubectl rollout undo deployment/<name> -n <namespace>
kubectl rollout undo deployment/<name> --to-revision=<revision> -n <namespace>

# 詳細確認
kubectl describe deployment <name> -n <namespace>
kubectl describe pod <pod名> -n <namespace>

# ログ確認
kubectl logs <pod名> -n <namespace>
kubectl logs <pod名> -n <namespace> --previous
```

---

## 7) Common mistakes and safe practices

### よくあるミス
1. **`kubectl apply -f .` を雑に実行する**  
   意図していない YAML まで反映してしまうことがあります。

2. **current context を見ずに更新する**  
   検証環境のつもりが本番だった、は本当に起きます。

3. **namespace を明示しない**  
   リソースが思った場所に入らず、トラブルシュートが難しくなります。

4. **readinessProbe を軽視する**  
   アプリがまだ準備できていないのにトラフィックを受けて、更新直後に障害化します。

5. **Secret をマニフェストへ平文で書く**  
   Git 履歴や共有ファイルから漏れます。学習資料でも本物は使わないこと。

6. **失敗時にすぐ delete 連打する**  
   原因が見えなくなります。まず `describe` と Events を見るべきです。

### 安全な実務プラクティス
- `kubectl config current-context` を更新前の儀式にする
- 検証用 namespace を分ける
- `kubectl diff -f ...` を使える環境なら事前差分確認を習慣化する
- マニフェストは Git 管理し、レビュー可能にする
- readiness/liveness を理解してから本番投入する
- 破壊的操作の前に、対象 Deployment / namespace / revision を再確認する
- 認証情報は Secret や外部 Secret 管理と組み合わせ、平文直書きを避ける

---

## 8) One interview-style question
**Q.** Kubernetes で新バージョンの Deployment を出したあと、一部 Pod が起動失敗しているとき、どう対処しますか？

**考え方の例:**
1. current context / namespace を確認する
2. `kubectl rollout status` で更新状態を確認する
3. `kubectl get pods` で失敗 Pod を特定する
4. `kubectl describe pod` と `kubectl logs --previous` で原因を見る
5. 影響が大きければ `kubectl rollout undo` で安定版へ戻す
6. readinessProbe、イメージタグ、設定差分を見直して再修正する

面接では、「止まったら気合いで再実行」ではなく、**安全確認 → 観察 → ロールバック判断 → 再修正** の流れを話せると強いです。

---

## 9) Next-step resources
- Deployments  
  https://kubernetes.io/docs/concepts/workloads/controllers/deployment/

- Update API Objects in Place Using kubectl patch  
  https://kubernetes.io/docs/tasks/manage-kubernetes-objects/update-api-object-kubectl-patch/

- kubectl Quick Reference  
  https://kubernetes.io/docs/reference/kubectl/quick-reference/

- Perform a Rolling Update on a Deployment  
  https://kubernetes.io/docs/tutorials/kubernetes-basics/update/update-intro/

- Debug Running Pods  
  https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/

- Good Practices for Kubernetes Secrets  
  https://kubernetes.io/docs/concepts/security/secrets-good-practices/

---

## 次号予告
**Advanced 予告:** ConfigMap / Secret / probes / resources を含めて、アプリ運用に近い Deployment 設計を考える

**Advanced の前提条件:**
- Deployment と rolling update の仕組みがわかる
- `kubectl apply` / `rollout status` / `rollout undo` を安全に使える
- 失敗更新時に `describe` / `logs` / Events を見て切り分けできる
- Secret を平文で扱わない重要性を理解している
