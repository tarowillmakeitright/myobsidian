---
tags: [kubernetes, k8s, devops, learning, daily]
---

# 2026-05-14 Kubernetes Commands Magazine
[[Home]]

#kubernetes #k8s #devops #learning #daily

本日のテーマは **「kubectl apply と宣言的運用の基本」**。  
難易度を **Beginner → Middle → Advanced** の学習アークで進めます。

---

## 1) Topic + Level

### Beginner
**Topic:** `kubectl apply` と `kubectl get/describe/logs` の基本

### Middle
**Topic:** Deployment のローリングアップデートと `kubectl rollout`

**Prerequisites:**
- Pod / Deployment / Service の基本概念
- `kubectl apply -f` と YAML の基本記法
- namespace の使い分けができる

### Advanced
**Topic:** Server-Side Apply とフィールド管理、差分確認を安全に行う運用

**Prerequisites:**
- Deployment 運用経験
- `kubectl diff`, `kubectl apply --server-side` の基本理解
- RBAC・監査ログの重要性を理解している

---

## 2) Why it matters for real app development

実アプリ開発では、ローカル→ステージング→本番で **同じ定義を再現性高く適用** できることが重要です。  
`apply` ベースの宣言的運用を身につけると、次の価値があります。

- 変更履歴の追跡（GitOpsと相性が良い）
- 手作業ミスの削減（「その場 edit」依存を減らす）
- ロールアウトやロールバックの標準化
- チーム開発での責務分離（開発者・SRE・セキュリティ）

---

## 3) Core kubectl/Kubernetes concept explanations

- **宣言的管理 (Declarative):**
  望ましい状態を YAML に記述し、`kubectl apply` でクラスタ状態を近づける方式。

- **`kubectl get` / `describe` / `logs`:**
  - `get`: 一覧・状態確認
  - `describe`: イベント・詳細診断
  - `logs`: コンテナログ確認

- **Deployment と rollout:**
  ReplicaSet を介して段階的に更新。`rollout status/history/undo` で安全運用。

- **Server-Side Apply (SSA):**
  API サーバ側でフィールド所有を管理。複数ツールでの競合検知がしやすい。

---

## 4) App building での Kubernetes 活用（kubernetes.io/docs ベストプラクティス準拠）

- **マニフェストは Git 管理**（変更レビューを必須化）
- **namespace 分離**（dev/stg/prod）
- **`kubectl diff` で適用前差分確認**
- **`rollout status` を CI に組み込む**
- **Secret を平文で Git に置かない**（Sealed Secrets / External Secrets / Secret 管理基盤）
- **最小権限 RBAC** と監査ログ活用

---

## 5) 30–60分 Hands-on Mini Lab

### Goal
Nginx Deployment を宣言的に運用し、更新・確認・ロールバックまで実施する。

### 所要時間
40分前後

### 手順

1. **作業用 namespace 作成**
```bash
kubectl create namespace k8s-mag-lab
```

2. **初期マニフェスト作成 (`deploy.yaml`)**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
  namespace: k8s-mag-lab
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
```

3. **適用と確認**
```bash
kubectl apply -f deploy.yaml
kubectl get deploy,pods -n k8s-mag-lab
kubectl rollout status deployment/web -n k8s-mag-lab
```

4. **更新（image変更）**
`nginx:1.27` → `nginx:1.27.1` に編集し、以下実行：
```bash
kubectl diff -f deploy.yaml
kubectl apply -f deploy.yaml
kubectl rollout status deployment/web -n k8s-mag-lab
```

5. **履歴・ロールバック確認**
```bash
kubectl rollout history deployment/web -n k8s-mag-lab
# 必要時のみ
kubectl rollout undo deployment/web -n k8s-mag-lab
```

6. **観察ポイント**
- Pod の再作成順序
- Event にエラーが出ていないか
- rollout 完了時間

> ⚠️ **破壊的コマンド注意:**
> `kubectl delete` 実行前に **context / namespace / 対象名** を必ず確認。
> `kubectl config current-context`

---

## 6) Command Cheatsheet

```bash
# 現在のcontext確認
kubectl config current-context

# リソース確認
kubectl get all -n <namespace>
kubectl describe pod <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace>

# 宣言的適用
kubectl diff -f <manifest.yaml>
kubectl apply -f <manifest.yaml>
kubectl apply --server-side -f <manifest.yaml>

# ロールアウト操作
kubectl rollout status deployment/<name> -n <namespace>
kubectl rollout history deployment/<name> -n <namespace>
kubectl rollout undo deployment/<name> -n <namespace>
```

---

## 7) Common mistakes and safe practices

### よくあるミス
- `default` namespace に誤適用
- 本番 context のまま作業
- `kubectl apply -f .` で想定外ファイルまで適用
- Secret を平文 YAML に書いてしまう

### 安全策
- コマンド前に `kubectl config current-context` を習慣化
- `-n <namespace>` を明示
- 適用前に `kubectl diff`
- Secret は専用管理（Git平文禁止）
- 重要操作は `--dry-run=server -o yaml` で事前確認

---

## 8) Interview-style question

**Q. `kubectl apply` と `kubectl replace` の違いは？本番運用ではどちらを優先し、なぜですか？**

（期待ポイント：宣言的運用、差分適用、運用時の安全性、競合管理）

---

## 9) Next-step resources (official docs)

- Kubernetes Concepts Overview  
  https://kubernetes.io/docs/concepts/overview/
- Declarative Object Management  
  https://kubernetes.io/docs/tasks/manage-kubernetes-objects/declarative-config/
- kubectl Cheat Sheet  
  https://kubernetes.io/docs/reference/kubectl/cheatsheet/
- Deployment (rolling update / rollback)  
  https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Server-Side Apply  
  https://kubernetes.io/docs/reference/using-api/server-side-apply/
- Secrets Good Practices  
  https://kubernetes.io/docs/concepts/security/secrets-good-practices/

---

明日の予告（学習アーク継続）:  
**ConfigMap/Secret の安全な使い分け + Probe（liveness/readiness/startup）実践**
