---
tags:
  - kubernetes
  - k8s
  - devops
  - learning
  - daily
---

[[Home]]

# Kubernetes Commands Magazine — 2026-06-27 09:25

## 1) Topic + Level
**Topic:** `kubectl get` / `kubectl describe` / `kubectl logs` でアプリの状態を安全に観察する
**Level:** Beginner

この号は Kubernetes 学習アークの最初の一歩です。いきなり Deployment を壊したり更新したりする前に、まずは **「今クラスタで何が起きているかを安全に読む力」** を作ります。

---

## 2) Why it matters for real app development
実際のアプリ開発では、ローカルで動いたものが Kubernetes 上ではうまく動かないことがよくあります。たとえば次のような場面です。

- API コンテナは起動したが `CrashLoopBackOff` になっている
- Pod は Running なのに画面から API へつながらない
- Deployment を更新したあと、一部の Pod だけ古いまま残っている
- 設定ミスなのか、アプリのバグなのか切り分けが必要

このとき最初に必要なのは、むやみに `apply` や `delete` を打つことではなく、**状態の観察**です。
`kubectl get` / `describe` / `logs` は、開発チームが障害の初動でほぼ確実に使う基本セットです。

---

## 3) Core kubectl/Kubernetes concept explanations

### `kubectl`
Kubernetes API Server と話すための CLI です。クラスタを直接触っているように見えて、実際には API に問い合わせています。

### Pod
アプリコンテナが動く最小単位です。ふつうは 1 つ以上のコンテナを含みます。アプリ開発では「コンテナが実際に起動している場所」と考えるとわかりやすいです。

### Deployment
Pod を宣言的に管理する仕組みです。Pod が落ちたら作り直し、更新時には段階的に入れ替えます。アプリの通常運用では Pod を直接作るより Deployment を使うのが基本です。

### Namespace
リソースを論理的に分ける区画です。`default` に何でも置くと見通しが悪くなるので、アプリ単位・環境単位で分けるのが実務的です。

### `kubectl get`
一覧を素早く見るコマンドです。まず全体像を把握するために使います。

例:
```bash
kubectl get pods
kubectl get deployments
kubectl get pods -n demo
kubectl get pods -o wide
```

### `kubectl describe`
1つのリソースを詳しく見るコマンドです。イベント、イメージ、再起動回数、失敗理由などを確認できます。

例:
```bash
kubectl describe pod demo-nginx
kubectl describe deployment demo-nginx
```

### `kubectl logs`
コンテナの標準出力・標準エラーを見ます。アプリの例外、起動失敗、設定不足の検知に必須です。

例:
```bash
kubectl logs demo-nginx
kubectl logs demo-nginx --previous
kubectl logs demo-nginx -f
```

`--previous` は再起動前のログ確認に便利です。CrashLoop の調査でよく使います。

---

## 4) How Kubernetes is used while building apps
Kubernetes の公式ドキュメントでも、アプリ開発では次の流れが自然です。

1. **マニフェストで desired state を定義する**  
   Deployment や Service を YAML で管理する
2. **Pod/Deployment の状態を観察する**  
   `get` で全体、`describe` で詳細、`logs` でアプリ内の失敗を見る
3. **問題を切り分ける**  
   - スケジューリング問題か
   - イメージ取得失敗か
   - readiness/liveness probe 失敗か
   - アプリ内部の例外か
4. **安全に修正して再適用する**  
   いきなりクラスタ全体へ影響する操作をせず、対象 namespace/context を確認してから変更する

実務では「とりあえず Pod を消す」より、**まず観察・原因特定・最小変更** が大事です。これは kubernetes.io/docs の宣言的運用・ワークロード管理の考え方とも相性がいいです。

---

## 5) 30-60 minute hands-on mini lab
**ラボ名:** Nginx Pod を観察して、状態とログを読む
**想定時間:** 35〜45分

### 目的
- `kubectl config current-context` で接続先確認
- Namespace を分けて安全に作業
- Pod/Deployment の状態確認
- `describe` と `logs` で観察

### 前提
- `kubectl` が使える
- ローカルクラスタ（minikube / kind / Docker Desktop Kubernetes など）か、検証用クラスタがある
- **本番クラスタではやらないこと**

### Step 0: 先に安全確認
```bash
kubectl config current-context
kubectl get ns
```

> **注意:** `kubectl apply -f ...` や `kubectl delete ...` を打つ前に、必ず current context と namespace を確認してください。クラスタや namespace の取り違えは典型的な事故です。

### Step 1: 検証用 namespace を作る
```bash
kubectl create namespace k8s-magazine-lab
```

### Step 2: Deployment を作る
```bash
kubectl create deployment demo-nginx \
  --image=nginx:1.27 \
  -n k8s-magazine-lab
```

### Step 3: 状態をざっと見る
```bash
kubectl get deployments -n k8s-magazine-lab
kubectl get pods -n k8s-magazine-lab
kubectl get pods -n k8s-magazine-lab -o wide
```

見たいポイント:
- READY が `1/1` になっているか
- STATUS が `Running` か
- RESTARTS が 0 か
- どの Node に載ったか

### Step 4: Pod 名を確認して詳細を見る
```bash
kubectl get pods -n k8s-magazine-lab
kubectl describe pod <pod名> -n k8s-magazine-lab
```

見たいポイント:
- Image
- Container State
- Events
- Pod IP
- Start Time

### Step 5: ログを見る
```bash
kubectl logs <pod名> -n k8s-magazine-lab
```

Nginx は静かなことも多いので、ログが少なくても正常です。「ログが大量に出ていない＝異常」とは限りません。

### Step 6: Service を公開して確認する
```bash
kubectl expose deployment demo-nginx \
  --port=80 \
  --target-port=80 \
  --type=ClusterIP \
  -n k8s-magazine-lab

kubectl get svc -n k8s-magazine-lab
kubectl describe svc demo-nginx -n k8s-magazine-lab
```

ここでは **Service が Pod 群への安定した入口** を作る概念だけつかめば十分です。

### Step 7: 余裕があれば Pod をわざと増やす
```bash
kubectl scale deployment demo-nginx --replicas=3 -n k8s-magazine-lab
kubectl get pods -n k8s-magazine-lab
kubectl get deployment demo-nginx -n k8s-magazine-lab
```

観察ポイント:
- Pod が 3 つに増える
- Deployment が desired/current/available を管理している

### Step 8: 後片付け
```bash
kubectl delete namespace k8s-magazine-lab
```

> **注意:** `delete namespace` はその namespace 配下をまとめて削除します。必ず対象名を再確認してから実行してください。本番や共有環境では特に慎重に。

---

## 6) Command cheatsheet
```bash
# 接続先確認
kubectl config current-context

# namespace 一覧
kubectl get ns

# Pod 一覧
kubectl get pods -n <namespace>

# Deployment 一覧
kubectl get deployments -n <namespace>

# 詳細確認
kubectl describe pod <pod名> -n <namespace>
kubectl describe deployment <deployment名> -n <namespace>

# ログ確認
kubectl logs <pod名> -n <namespace>
kubectl logs <pod名> -n <namespace> -f
kubectl logs <pod名> -n <namespace> --previous

# Service 確認
kubectl get svc -n <namespace>
kubectl describe svc <service名> -n <namespace>

# スケール変更
kubectl scale deployment <deployment名> --replicas=3 -n <namespace>
```

---

## 7) Common mistakes and safe practices

### よくあるミス
1. **context を見ずに apply/delete する**  
   別クラスタに対して実行すると事故になります。

2. **namespace を省略する**  
   `default` に作ってしまい、どこに何があるかわからなくなります。

3. **Pod を直接いじりすぎる**  
   Deployment 管理下の Pod を消しても、コントローラが再作成します。まず上位リソースを見るべきです。

4. **ログだけ見て Kubernetes 側のイベントを見ない**  
   原因がアプリではなく、ImagePullBackOff や probe failure のことがあります。

5. **Secret を YAML に直書きする**  
   Git に載ると危険です。学習時でも機密値はサンプル値にし、本物を入れないこと。

### 安全な実務プラクティス
- `kubectl config current-context` を習慣化する
- 検証用 namespace を分ける
- 破壊的操作の前に対象を `get` して再確認する
- Secret や認証情報をマニフェストへ平文で書かない
- まず `get` → `describe` → `logs` の順で観察する
- 共有クラスタでは `delete` より原因分析を優先する

---

## 8) One interview-style question
**Q.** Pod が `CrashLoopBackOff` になっているとき、あなたはどの順番で調査しますか？

**考え方の例:**
1. `kubectl config current-context` と namespace を確認
2. `kubectl get pods` で再起動回数や状態を見る
3. `kubectl describe pod` で Events と Container State を確認
4. `kubectl logs --previous` で直前の失敗ログを確認
5. Deployment や ConfigMap/Secret 参照、probe 設定などを見直す

面接では「とりあえず再起動」ではなく、**観察→仮説→確認** の順で話せると強いです。

---

## 9) Next-step resources
まずは公式ドキュメント中心で進むのが安全です。

- Kubernetes Concepts Overview  
  https://kubernetes.io/docs/concepts/overview/

- Pods  
  https://kubernetes.io/docs/concepts/workloads/pods/

- Deployments  
  https://kubernetes.io/docs/concepts/workloads/controllers/deployment/

- Service  
  https://kubernetes.io/docs/concepts/services-networking/service/

- kubectl Quick Reference  
  https://kubernetes.io/docs/reference/kubectl/quick-reference/

- Debug Pods and ReplicationControllers  
  https://kubernetes.io/docs/tasks/debug/debug-application/debug-pods/

---

## 次号予告
**Middle 予告:** `kubectl apply` / `rollout status` / `rollout undo` で安全にアプリ更新する

**Middle の前提条件:**
- Pod / Deployment / Service の役割がわかる
- `kubectl get` / `describe` / `logs` を使って基本調査ができる
- namespace と current context の確認を習慣化している
