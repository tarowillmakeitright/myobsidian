---
tags: [kubernetes, k8s, devops, learning, daily]
---

# Daily Kubernetes Commands Magazine — 2026-04-17

[[Home]]

> 今日のテーマは **「kubectl apply / diff / rollout を安全に使ってアプリ変更をリリースする」**。  
> 学習アークは **Beginner → Middle → Advanced** の順で進みます。

---

## 1) Topic + Level

### Beginner（初級）
**Topic:** `kubectl get/describe/logs` と `kubectl apply -f` の基本

### Middle（中級）
**Topic:** `kubectl diff` + `kubectl rollout status/history/undo` で安全に段階リリース

**Prerequisites（前提知識）**
- Pod / Deployment / Service の基本を知っている
- `kubectl get pods -n <namespace>` を実行した経験がある
- YAML マニフェストを1つ以上読んだことがある

### Advanced（上級）
**Topic:** Server-Side Apply、フィールド管理、変更衝突の理解と運用設計

**Prerequisites（前提知識）**
- `kubectl apply` と `kubectl rollout undo` を使って更新/ロールバックした経験
- Deployment の rollingUpdate（maxSurge/maxUnavailable）を理解
- namespace / context の切り替え事故を避ける基本習慣がある

---

## 2) Why it matters for real app development

実アプリ開発では「コードを直す」より「安全に本番へ届ける」方が難しいです。  
`apply` 系の運用を正しく行うと、次の価値が出ます。

- **再現性**: 手作業より Git 管理された YAML で同じ状態を再現できる
- **可観測性**: `rollout status` で更新成功/失敗を追跡できる
- **復旧性**: `rollout undo` で障害時に素早く戻せる
- **安全性**: `diff` で事前確認し、誤爆（別namespace/別cluster）を防げる

---

## 3) Core kubectl / Kubernetes concept explanations

- **Declarative運用（宣言的）**
  - 「こうなってほしい状態」を YAML で宣言し、Kubernetes が収束させる
  - `kubectl apply -f` はこの宣言を反映する代表コマンド

- **Deployment の rollout**
  - 新しい ReplicaSet を作って段階的に切り替える
  - ヘルスチェック（readiness/liveness）が適切でないと更新停止や障害が起こる

- **`kubectl diff`**
  - 適用前の差分確認。レビュー前提の運用で非常に重要

- **Server-Side Apply（SSA）**
  - API Server がフィールド所有者（field manager）を管理
  - チームやツール間の「誰がどの設定を持つか」を明確にできる

---

## 4) How Kubernetes is used while building apps（kubernetes.io/docs aligned）

アプリ開発フローに沿うと、以下が実務的です。

1. **ローカル/CIでイメージ作成**
2. **マニフェストをGit管理**（環境別overlayを分離）
3. **apply前に diff**（人間レビュー + 自動チェック）
4. **rollout status を監視**
5. **失敗時は rollout undo**
6. **Secretは平文コミットしない**（External Secrets / Secret Manager連携を検討）

> ベストプラクティス: 変更は小さく、観測しながら段階投入。  
> いきなり巨大変更を一括 apply しない。

---

## 5) 30–60分ハンズオン mini lab

**Lab Goal:** Nginx Deployment のイメージ更新を安全に実施し、失敗時にロールバックする。

**所要時間:** 45分目安

### Step 0: 事故防止（最重要）
```bash
kubectl config current-context
kubectl get ns
```
- いま触る cluster/context が正しいか必ず確認
- 本番クラスタなら一旦止まる（作業手順を再確認）

### Step 1: 作業用 namespace 作成
```bash
kubectl create namespace magazine-lab
kubectl config set-context --current --namespace=magazine-lab
```

### Step 2: Deployment 作成（v1）
`deploy-v1.yaml`
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
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 3
          periodSeconds: 5
```

```bash
kubectl apply -f deploy-v1.yaml
kubectl rollout status deployment/web
kubectl get pods -o wide
```

### Step 3: 更新前に差分確認（v2へ）
`deploy-v2.yaml` を作り、image を `nginx:1.26` に変更。

```bash
kubectl diff -f deploy-v2.yaml
kubectl apply -f deploy-v2.yaml
kubectl rollout status deployment/web
kubectl rollout history deployment/web
```

### Step 4: 意図的な失敗更新を試す
image を存在しないタグ（例: `nginx:does-not-exist`）に変更して適用。

```bash
kubectl apply -f deploy-bad.yaml
kubectl rollout status deployment/web
kubectl get pods
kubectl describe pod <失敗しているPod名>
```

### Step 5: ロールバック
```bash
kubectl rollout undo deployment/web
kubectl rollout status deployment/web
```

### Step 6: 後片付け（破壊コマンド注意）
```bash
# ⚠️ 削除対象が本当に lab namespace か確認
kubectl config view --minify | grep namespace
kubectl delete namespace magazine-lab
```

---

## 6) Command cheatsheet

```bash
# 文脈確認（超重要）
kubectl config current-context
kubectl config get-contexts
kubectl config view --minify

# 観察
kubectl get all -n <ns>
kubectl describe deployment <name> -n <ns>
kubectl logs -f deploy/<name> -n <ns>

# 変更
kubectl diff -f app.yaml
kubectl apply -f app.yaml
kubectl apply --server-side -f app.yaml

# ロールアウト管理
kubectl rollout status deployment/<name> -n <ns>
kubectl rollout history deployment/<name> -n <ns>
kubectl rollout undo deployment/<name> -n <ns>

# 安全確認
kubectl auth can-i delete pods -n <ns>
```

---

## 7) Common mistakes and safe practices

### よくあるミス
- `default` namespace のまま apply してしまう
- context を確認せず本番に apply
- `kubectl delete -f .` など作用範囲が曖昧な破壊操作
- Secret を平文で Git に入れる
- readinessProbe なしで更新し、壊れたPodがトラフィックを受ける

### 安全プラクティス
- **毎回最初に context/namespace 確認**
- **`apply` 前に `diff`**
- **本番は段階リリース + rollout監視**
- **削除系は対象を明示**（`-n`, リソース名を具体化）
- **Secret は外部管理**（KMS/Vault/External Secrets など）

> ⚠️ 破壊的コマンド（`delete`, `replace --force`）は、対象clusterとnamespaceを2回確認してから実行。

---

## 8) Interview-style question

**Q.** `kubectl apply` と `kubectl replace` の違いは？本番運用で `apply` が好まれる理由を説明してください。  
（ヒント: 宣言的管理、差分反映、他ツールとの共存、ロールバックのしやすさ）

---

## 9) Next-step resources（公式優先）

- Kubernetes Documentation Home  
  https://kubernetes.io/docs/home/
- Overview of kubectl  
  https://kubernetes.io/docs/reference/kubectl/
- Declarative Management of Kubernetes Objects Using Configuration Files  
  https://kubernetes.io/docs/tasks/manage-kubernetes-objects/declarative-config/
- Update a Deployment  
  https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#updating-a-deployment
- Rollback a Deployment  
  https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#rolling-back-a-deployment
- Server-Side Apply  
  https://kubernetes.io/docs/reference/using-api/server-side-apply/
- Good Practices for Kubernetes Secrets  
  https://kubernetes.io/docs/concepts/security/secrets-good-practices/

---

次号予告: **ConfigMap/Secretの安全な注入と、アプリ設定の環境分離（Beginner→Advanced）**