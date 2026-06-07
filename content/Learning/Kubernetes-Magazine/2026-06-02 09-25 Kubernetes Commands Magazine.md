---
tags: [kubernetes, k8s, devops, learning, daily]
---

# Daily Kubernetes Commands Magazine
**Date:** 2026-06-02 09:25 (Asia/Tokyo)  
**Links:** [[Home]]

---

## 今号のテーマ
**「`kubectl apply` と宣言的運用の基本」**

---

## 1) Topic + Level
### 🟢 Beginner
**Topic:** `kubectl get/describe/logs/apply` を使った「観測 → 反映」の最小ループ

### 🟡 Middle
**Topic:** Namespace を分けた安全な apply 運用と rollout 監視
**Prerequisites:**
- Pod / Deployment / Service の基本を理解している
- `kubectl get` / `kubectl apply -f` を1回以上実行したことがある

### 🔴 Advanced
**Topic:** Server-Side Apply・field ownership・差分確認での衝突回避
**Prerequisites:**
- `kubectl rollout` と `kubectl diff` を使ったことがある
- YAML のマージ挙動（labels/annotations/spec）を概念として理解している

---

## 2) Why it matters for real app development
アプリ開発では「ローカルでは動くが本番で壊れる」を減らすために、**状態を宣言して再現可能にする**ことが重要です。  
Kubernetes の宣言的運用（`apply`）を正しく使うと:
- 環境差分を減らせる
- 変更履歴を追える（Git と相性がよい）
- ロールアウト失敗時の切り戻し判断が速くなる

特にチーム開発では、手作業の `kubectl edit` 乱用より、YAML 管理 + 安全な apply 手順のほうが事故率を大きく下げます。

---

## 3) Core kubectl/Kubernetes concept explanations
- **宣言的運用 (declarative):**
  「こうあってほしい状態」を YAML に書き、`kubectl apply` で反映する運用。
- **命令的運用 (imperative):**
  `kubectl run` などでその場の操作を直接実行する運用。
- **Deployment:**
  Pod の望ましい数・更新戦略を管理する上位リソース。
- **Rollout:**
  Deployment 更新の進行。`kubectl rollout status` で監視可能。
- **Namespace:**
  リソース分離単位。誤操作スコープを狭める安全装置。
- **Diff / Dry-run:**
  変更前に差分・適用結果を確認し、本番事故を防ぐ。

---

## 4) How Kubernetes is used while building apps (best-practice aligned)
kubernetes.io/docs の実践に沿うと、開発時は次の流れが堅実です。

1. **マニフェストを Git 管理**（手動変更を減らす）
2. **Namespace ごとに環境分離**（dev/stg/prod）
3. `kubectl diff` → `kubectl apply` → `kubectl rollout status` の順で実施
4. 失敗時は `kubectl describe` / `kubectl logs` で原因特定
5. Secret は平文で埋め込まず、Secret リソース + RBAC で最小権限化

---

## 5) 30–60分ミニラボ
**目的:** 安全な apply ループを体験する（Beginner→Middle→Advanced の弧）

### 事前準備（5分）
```bash
kubectl config current-context
kubectl get nodes
```
> ⚠️ **重要:** いま接続中の context が本当に学習用クラスタか必ず確認。

### Step A (Beginner, 10–15分)
`magazine-lab.yaml` を作成:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
  namespace: k8s-mag
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
---
apiVersion: v1
kind: Service
metadata:
  name: web
  namespace: k8s-mag
spec:
  selector:
    app: web
  ports:
  - port: 80
    targetPort: 80
```

```bash
kubectl create namespace k8s-mag
kubectl apply -f magazine-lab.yaml
kubectl get all -n k8s-mag
kubectl rollout status deploy/web -n k8s-mag
```

### Step B (Middle, 10–15分)
replicas を `3` に変更し、差分確認して適用:
```bash
kubectl diff -f magazine-lab.yaml
kubectl apply -f magazine-lab.yaml
kubectl get deploy web -n k8s-mag -o wide
```

### Step C (Advanced, 15–20分)
Server-Side Apply で field manager を明示:
```bash
kubectl apply --server-side --field-manager=magazine -f magazine-lab.yaml
kubectl get deploy web -n k8s-mag -o yaml | grep -A4 managedFields
```

競合の学習（任意）:
- 別 manager 名で同一フィールドを更新して衝突挙動を確認
- `--force-conflicts` は検証環境のみで実施

### 後片付け（5分）
```bash
kubectl delete namespace k8s-mag
```
> ⚠️ **破壊的操作:** `delete` 実行前に namespace 名を再確認。`default` や本番 namespace を消さないこと。

---

## 6) Command cheatsheet
```bash
# 現在の接続先確認
kubectl config current-context

# 主要リソース確認
kubectl get deploy,po,svc -n <namespace>

# 差分確認（適用前）
kubectl diff -f <file>.yaml

# 適用
kubectl apply -f <file>.yaml

# ロールアウト監視
kubectl rollout status deploy/<name> -n <namespace>

# 詳細調査
kubectl describe pod <pod> -n <namespace>
kubectl logs <pod> -n <namespace>

# Server-Side Apply
kubectl apply --server-side --field-manager=<manager> -f <file>.yaml
```

---

## 7) Common mistakes and safe practices
### よくあるミス
- context を確認せず apply/delete する
- `-n` を付け忘れて default namespace に誤反映
- Secret を YAML に平文で直書きして Git に push
- `kubectl apply -f .` で意図しないファイルまで一括反映

### 安全プラクティス
- 実行前に `kubectl config current-context` を習慣化
- 反映前に `kubectl diff`、反映後に `kubectl rollout status`
- Secret は Secret リソースに分離し、必要最小権限の RBAC を適用
- 破壊的コマンド前に対象を復唱（context / namespace / resource）

---

## 8) Interview-style question
**Q.** `kubectl apply` と `kubectl replace` の違いは？実運用で apply が好まれる理由を説明してください。  
**Aの観点（自己チェック用）:**
- 宣言的運用と差分適用
- 既存フィールド保持のしやすさ
- チーム運用/GitOps との整合性

---

## 9) Next-step resources (official preferred)
- Kubernetes Concepts Overview  
  https://kubernetes.io/docs/concepts/overview/
- Declarative Management of Kubernetes Objects  
  https://kubernetes.io/docs/tasks/manage-kubernetes-objects/declarative-config/
- kubectl Cheat Sheet  
  https://kubernetes.io/docs/reference/kubectl/cheatsheet/
- Server-Side Apply  
  https://kubernetes.io/docs/reference/using-api/server-side-apply/
- Configure Access to Multiple Clusters（context安全運用）  
  https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/

---

次号予告（難易度アーク継続）: **ConfigMap / Secret / envFrom の安全な使い分け**