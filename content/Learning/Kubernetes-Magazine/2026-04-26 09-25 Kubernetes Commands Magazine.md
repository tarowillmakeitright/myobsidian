---
tags:
  - kubernetes
  - k8s
  - devops
  - learning
  - daily
---

# Kubernetes Commands Magazine — 2026-04-26

[[Home]]

本日のテーマは、**アプリ開発で最も事故が起きやすい「apply/delete/context管理」**を、
Beginner → Middle → Advanced の学習アークで実践的に身につける構成です。

---

## 1) Topic + Level

### Beginner
**Topic:** `kubectl config` と `kubectl get` で「今どのクラスタを見ているか」を安全に把握する

### Middle（前提あり）
**Topic:** `kubectl apply -f` の安全運用（namespace・ラベル・差分確認）
**Prerequisites:**
- `kubectl config current-context` の意味を説明できる
- Namespace の基本概念（論理分離）を理解している
- Deployment / Service の役割を知っている

### Advanced（前提あり）
**Topic:** ロールアウト管理とトラブル時の切り戻し（`rollout`, `describe`, `logs`）
**Prerequisites:**
- Deployment の更新フロー（ReplicaSet が切り替わる流れ）を理解している
- `kubectl apply` で manifest 更新経験がある
- Pod/Container の基本ステータス（Running, CrashLoopBackOff）を読める

---

## 2) Why it matters for real app development

- 本番事故の多くは、**コードそのものより運用コマンドの誤用**で起こる。
- 典型例：
  - 間違った context に apply して本番へ誤反映
  - `kubectl delete` の対象範囲ミス
  - namespace 指定漏れで別環境を更新
- 逆に、context/namespace/差分確認を習慣化すると、
  **リリースの安全性・再現性・チーム開発効率**が大きく上がる。

---

## 3) Core kubectl/Kubernetes concept explanations

- **Context**: 「どのクラスタ・どのユーザー・デフォルトnamespace」で操作するかのセット。
- **Namespace**: 1クラスタ内での論理的な環境分離（dev/stg/prod など）。
- **Declarative apply**: 「望ましい状態」を manifest に書き、Kubernetes が現実を近づける方式。
- **Deployment**: アプリのローリング更新・自己修復を担う。
- **Service**: Pod集合への安定したアクセス経路を提供。
- **Rollout**: 更新の進行確認、履歴確認、失敗時の undo に使う運用機能。

---

## 4) App building での Kubernetes 利用（kubernetes.io/docs ベストプラクティス寄り）

- manifest を Git 管理し、**手作業の即席変更を減らす**（宣言的運用）。
- 環境ごとに namespace を分ける（誤操作影響を局所化）。
- Secret は平文埋め込みしない。少なくとも Base64 は暗号化ではない点を理解する。
- デプロイ時は以下の順で確認：
  1. `current-context`
  2. target namespace
  3. 差分/対象ファイル
  4. rollout 状態
- 障害時は `get` → `describe` → `logs` の順で事実収集してから操作する。

---

## 5) 30–60分 Mini Lab（安全運用フロー体験）

> 目安: 45分
> 前提: 動作する Kubernetes クラスタ（ローカル可: kind/minikube）

### Step 0: 事前安全チェック（5分）
```bash
kubectl config get-contexts
kubectl config current-context
kubectl cluster-info
```

### Step 1: 学習用 namespace 作成（5分）
```bash
kubectl create namespace magazine-lab
kubectl get ns
```

### Step 2: Deployment/Service 作成（10分）
`lab-deploy.yaml` を作成して apply:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
  namespace: magazine-lab
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
          image: nginx:1.25
          ports:
            - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: web
  namespace: magazine-lab
spec:
  selector:
    app: web
  ports:
    - port: 80
      targetPort: 80
```

```bash
kubectl apply -f lab-deploy.yaml
kubectl -n magazine-lab get deploy,po,svc
```

### Step 3: ローリングアップデート（10分）
```bash
kubectl -n magazine-lab set image deploy/web nginx=nginx:1.26
kubectl -n magazine-lab rollout status deploy/web
kubectl -n magazine-lab rollout history deploy/web
```

### Step 4: トラブル調査の型（10分）
わざと存在しないタグへ変更:
```bash
kubectl -n magazine-lab set image deploy/web nginx=nginx:1.999
kubectl -n magazine-lab get po
kubectl -n magazine-lab describe deploy/web
kubectl -n magazine-lab logs deploy/web --all-pods=true --tail=50
```

### Step 5: 切り戻し（5分）
```bash
kubectl -n magazine-lab rollout undo deploy/web
kubectl -n magazine-lab rollout status deploy/web
```

### Step 6: 後片付け（必要なら）（5分）
```bash
# 破壊的操作: 対象namespaceを必ず再確認してから実行
kubectl get ns
kubectl delete namespace magazine-lab
```

---

## 6) Command Cheatsheet

```bash
# Context / Namespace
kubectl config current-context
kubectl config get-contexts
kubectl config use-context <context-name>
kubectl get ns
kubectl -n <ns> get all

# Apply / Inspect
kubectl apply -f <file-or-dir>
kubectl diff -f <file-or-dir>
kubectl -n <ns> describe deploy/<name>
kubectl -n <ns> logs deploy/<name> --all-pods=true --tail=100

# Rollout
kubectl -n <ns> rollout status deploy/<name>
kubectl -n <ns> rollout history deploy/<name>
kubectl -n <ns> rollout undo deploy/<name>

# Safe delete
kubectl delete -f <file>
kubectl delete namespace <ns>
```

---

## 7) Common mistakes and safe practices

### よくあるミス
- `current-context` を見ずに apply/delete
- `-n` 指定漏れで意図しない namespace を操作
- Secret を manifest に平文で直書き
- `kubectl delete` を勢いで実行

### 安全プラクティス
- 実行前に必ず `kubectl config current-context`
- apply 前に `kubectl diff -f ...` を確認
- 破壊的コマンド前は「対象クラスタ・namespace・リソース名」を声に出して確認
- Secret は外部シークレット管理や sealed-secrets などの仕組みを検討
- 本番相当では RBAC 最小権限 + 監査ログを有効化

**警告:**
- `kubectl delete namespace ...` は配下リソースをまとめて削除する
- `kubectl apply -f .` はディレクトリ配下を広範囲に変更しうる
- context を誤ると本番反映事故につながる

---

## 8) Interview-style question

「`kubectl apply` と `kubectl replace` の違いを説明し、
本番運用で `apply` を使う際に事故を減らすための確認手順を3つ挙げてください。」

---

## 9) Next-step resources（公式優先）

- Kubernetes Concepts Overview  
  https://kubernetes.io/docs/concepts/overview/
- kubectl Overview  
  https://kubernetes.io/docs/reference/kubectl/
- Declarative Management of Kubernetes Objects  
  https://kubernetes.io/docs/tasks/manage-kubernetes-objects/declarative-config/
- Debug Running Pods  
  https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/
- Deployment (Rollout/Rollback)  
  https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Configure Access to Multiple Clusters  
  https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/
