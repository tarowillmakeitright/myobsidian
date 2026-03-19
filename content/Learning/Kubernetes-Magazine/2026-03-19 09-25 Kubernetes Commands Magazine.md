---
tags: [kubernetes, k8s, devops, learning, daily]
---

# Daily Kubernetes Commands Magazine - 2026-03-19
[[Home]]

> 今日のテーマは「**kubectl apply / diff / rollout を安全に使って、段階的にアプリを更新する**」です。  
> 学習アークは **Beginner → Middle → Advanced** で進みます。

---

## 1) Topic + Level

### Beginner
**Topic:** `kubectl apply` と `kubectl get/describe/logs` で、最小アプリをデプロイして状態を読む

### Middle
**Topic:** `kubectl diff` + `kubectl rollout` で、ダウンタイムを避けた更新運用

**Prerequisites (Middle):**
- Pod / Deployment / Service の基本概念
- YAML マニフェストを読める
- `kubectl get` / `describe` / `logs` が使える

### Advanced
**Topic:** Namespace/Context を意識した安全運用（誤爆防止） + 段階的検証

**Prerequisites (Advanced):**
- 複数 Namespace の運用経験（開発/検証/本番など）
- RollingUpdate の挙動理解
- `kubectl config` の基本理解（context, namespace）

---

## 2) Why it matters for real app development

実アプリ開発では「**作る**」だけでなく、**安全に変更し続ける**能力が重要です。  
`kubectl apply` での更新は便利ですが、対象 context や namespace を誤ると本番へ誤適用する事故につながります。

この号で扱う `diff` / `rollout` / `context確認` は、次の実務価値があります：
- 変更前に差分を確認し、事故を減らす
- 段階的に更新してユーザー影響を最小化
- 失敗時に素早くロールバック
- 「誰でも再現できる」運用手順を作る

---

## 3) Core kubectl / Kubernetes concepts

### `kubectl apply`
- 宣言的に「あるべき状態」を反映
- 既存リソースとの差分をもとに更新
- `-f` で単一ファイル、`-k` で Kustomize も可能

### `kubectl diff`
- 実際に apply する前に差分を確認
- 本番運用では **apply前の必須チェック** に近い

### `kubectl rollout`
- Deployment の更新進行・履歴・ロールバックを管理
- 代表例：
  - `rollout status deployment/<name>`
  - `rollout history deployment/<name>`
  - `rollout undo deployment/<name>`

### Context / Namespace
- Context は「どのクラスタ・ユーザー・namespace へ操作するか」の束
- 破壊的コマンド前は必ず `current-context` と `-n` を確認

---

## 4) App building best-practice alignment (kubernetes.io/docs)

アプリ開発時の推奨フロー（公式の考え方に沿う）：

1. **マニフェストをGit管理**（宣言的管理）
2. `kubectl diff` で変更確認
3. `kubectl apply -f ...` で反映
4. `kubectl rollout status` で更新完了を監視
5. `kubectl logs` / `describe` で事後確認
6. 問題時は `rollout undo` で即時復旧

さらに安全面として：
- Secret を平文で Git に置かない
- Config と Secret を分離
- 最小権限（RBAC）と namespace 分離を前提に設計

---

## 5) 30-60 minute hands-on mini lab

> ローカルクラスタ（minikube / kind / Docker Desktop Kubernetes）で実施推奨

### Goal
Deployment を v1 → v2 に更新し、問題発生を想定して rollback まで体験する。

### Step 0: 事前安全確認（2分）
```bash
kubectl config current-context
kubectl get ns
```
- 今いる context を声に出して確認
- 練習用 namespace を作成

```bash
kubectl create ns magazine-lab
kubectl config set-context --current --namespace=magazine-lab
```

### Step 1: v1をデプロイ（10分）
`deploy-v1.yaml` を作成：
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
        image: nginx:1.25
        ports:
        - containerPort: 80
---
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
```

```bash
kubectl apply -f deploy-v1.yaml
kubectl get pods,svc
kubectl rollout status deployment/web
```

### Step 2: v2へ更新（15分）
イメージを `nginx:1.27` に変更した `deploy-v2.yaml` を作る。  
適用前に差分確認：

```bash
kubectl diff -f deploy-v2.yaml
kubectl apply -f deploy-v2.yaml
kubectl rollout status deployment/web
kubectl rollout history deployment/web
```

### Step 3: 失敗を模擬しロールバック（15分）
わざと不正イメージタグへ変更（例 `nginx:does-not-exist`）して apply。

```bash
kubectl apply -f deploy-bad.yaml
kubectl rollout status deployment/web --timeout=60s
kubectl get pods
kubectl describe pod <失敗Pod名>
kubectl rollout undo deployment/web
kubectl rollout status deployment/web
```

### Step 4: 後片付け（3分）
```bash
kubectl config set-context --current --namespace=default
kubectl delete ns magazine-lab
```

⚠️ **注意:** `kubectl delete ns` は対象 namespace を完全削除します。実クラスタで実行しないこと。

---

## 6) Command cheatsheet

```bash
# 文脈確認
kubectl config current-context
kubectl config view --minify | grep namespace:

# 基本確認
kubectl get pods -n <ns>
kubectl describe deployment <name> -n <ns>
kubectl logs deploy/<name> -n <ns>

# 反映前チェック
kubectl diff -f app.yaml -n <ns>

# 反映
kubectl apply -f app.yaml -n <ns>

# ロールアウト管理
kubectl rollout status deployment/<name> -n <ns>
kubectl rollout history deployment/<name> -n <ns>
kubectl rollout undo deployment/<name> -n <ns>

# 事故防止
kubectl get all -n <ns>
kubectl auth can-i delete deployment -n <ns>
```

---

## 7) Common mistakes and safe practices

### よくあるミス
1. **context取り違え**で本番にapply
2. `-n` 指定忘れで default namespace に誤作成
3. `kubectl delete` を広いスコープで実行
4. Secret をマニフェストに直書きしてGit管理

### 安全プラクティス
- 破壊的コマンド前に必ず：
  - `kubectl config current-context`
  - `kubectl config view --minify | grep namespace:`
- `apply` 前に `diff` を習慣化
- `delete` は resource 種別と namespace を明示
- Secret は External Secrets / Sealed Secrets / Secret Manager 連携を検討
- 本番作業は `--context` 明示や read-only 確認コマンドから開始

⚠️ **Destructive command warning:**  
`kubectl delete`, `kubectl apply -f .`, `kubectl replace --force` は対象スコープを誤ると重大事故になります。実行前に context/namespace/対象リソースを必ず再確認してください。

---

## 8) Interview-style question

**Q.** `kubectl apply` と `kubectl create` の違いを説明し、運用で `kubectl diff` を挟むべき理由を述べてください。  
**期待される観点:** 宣言的運用、冪等性、変更可視化、誤変更防止、レビュー可能性。

---

## 9) Next-step resources (official preferred)

- Kubernetes Concepts  
  https://kubernetes.io/docs/concepts/
- Deployments  
  https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- kubectl Overview  
  https://kubernetes.io/docs/reference/kubectl/
- Declarative Config Management  
  https://kubernetes.io/docs/tasks/manage-kubernetes-objects/declarative-config/
- Update & Rollback a Deployment  
  https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#updating-a-deployment
- Configure Access to Multiple Clusters (context)  
  https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/
- Secrets Good Practices  
  https://kubernetes.io/docs/concepts/security/secrets-good-practices/

---

次号予告（学習アーク継続）:  
**Beginner:** ConfigMap/Secret の使い分け  
**Middle:** Probes（liveness/readiness/startup）で可用性向上  
**Advanced:** HPA + Requests/Limits でスケーリング最適化
