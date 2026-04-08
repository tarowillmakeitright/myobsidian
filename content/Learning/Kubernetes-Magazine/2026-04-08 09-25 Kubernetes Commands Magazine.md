---
tags:
  - kubernetes
  - k8s
  - devops
  - learning
  - daily
---

[[Home]]

# Kubernetes Commands Magazine — 2026-04-08

今日のテーマは、**アプリ開発で毎日使う `kubectl` と Kubernetes運用の基本〜実践**を、
**Beginner → Middle → Advanced** の学習アークで進めます。

---

## 1) Topic + Level

### 🟢 Beginner
**Topic:** `kubectl get/describe/logs` で「いま何が起きているか」を把握する

### 🟡 Middle
**Topic:** `Deployment` の更新 (`set image`, `rollout`) と安全なデプロイ確認
**Prerequisites:**
- Beginner の内容（Pod/Deployment の見方）
- `Deployment` と `ReplicaSet` の関係をざっくり理解している

### 🔴 Advanced
**Topic:** 宣言的運用（`apply -f`）・差分確認・安全な変更管理（ドライラン/スコープ確認）
**Prerequisites:**
- Middle の内容（ロールアウト確認/ロールバック）
- YAML マニフェストを読める
- Namespace/Context の基本理解

---

## 2) Why it matters for real app development

- 開発チームでは「アプリが動かない」の原因切り分け速度が重要。`get/describe/logs` は最短ルート。
- リリース時は「更新できたか」より「安全に更新できたか」が重要。`rollout status/history/undo` は必須。
- 本番運用では「手作業の変更」より「宣言的な再現性」が重要。`apply` + 事前確認で事故率を下げられる。

---

## 3) Core kubectl/Kubernetes concept explanations

- **Pod**: コンテナ実行の最小単位。通常は直接運用せず、上位リソース（Deployment）で管理。
- **Deployment**: アプリの望ましい状態（レプリカ数・コンテナイメージ）を宣言し、ローリング更新を管理。
- **Namespace**: 環境やチームごとの論理分離。
- **Context**: `kubectl` がどのクラスタ/ユーザー/Namespace に向くかを決める接続先。
- **宣言的管理（Declarative）**: YAML に望ましい状態を書き、`kubectl apply -f` で同期。

---

## 4) How Kubernetes is used while building apps (kubernetes.io/docs aligned)

実開発の基本フロー（推奨プラクティス寄り）:

1. ローカルでイメージ作成・タグ付け
2. `Deployment` マニフェストに反映（image, resources, probes など）
3. `kubectl apply -f` 前に**対象 Context/Namespace を確認**
4. `kubectl rollout status` で更新完了を待つ
5. `kubectl logs` / `describe` で異常を確認
6. 問題時は `kubectl rollout undo` で素早く復旧

> ベストプラクティス:
> - Secret は平文で Git に置かない（Secret 管理基盤や暗号化ワークフローを使う）
> - 最初から liveness/readiness probe, resource requests/limits を意識
> - 「とりあえず `kubectl edit`」より、YAML 管理 + PR レビューを優先

---

## 5) 30–60分 Hands-on Mini Lab

### ゴール
- NGINX Deployment を作成
- イメージ更新をロールアウト確認
- 意図的に失敗更新してロールバック

### 手順（約45分）

#### Step 0: 安全確認（5分）
```bash
kubectl config current-context
kubectl get ns
```
- 触ってよいクラスタ/Namespace か確認。

#### Step 1: Namespace と初期デプロイ（10分）
```bash
kubectl create namespace mag-lab
kubectl -n mag-lab create deployment web --image=nginx:1.25
kubectl -n mag-lab get pods -w
```

#### Step 2: 状態確認（10分）
```bash
kubectl -n mag-lab get deploy,rs,pods
kubectl -n mag-lab describe deployment web
kubectl -n mag-lab logs deploy/web
```

#### Step 3: 正常な更新（10分）
```bash
kubectl -n mag-lab set image deployment/web nginx=nginx:1.27
kubectl -n mag-lab rollout status deployment/web
kubectl -n mag-lab rollout history deployment/web
```

#### Step 4: 失敗更新→復旧（10分）
```bash
kubectl -n mag-lab set image deployment/web nginx=nginx:does-not-exist
kubectl -n mag-lab rollout status deployment/web
kubectl -n mag-lab describe deployment web
kubectl -n mag-lab rollout undo deployment/web
kubectl -n mag-lab rollout status deployment/web
```

#### Step 5: 片付け（任意）
```bash
# ⚠️ 破壊的コマンド: 対象Namespaceを必ず再確認
kubectl delete namespace mag-lab
```

---

## 6) Command Cheatsheet

```bash
# 現在の接続先確認（最重要）
kubectl config current-context

# よく使う参照
kubectl get pods -A
kubectl -n <ns> get deploy,rs,pods
kubectl -n <ns> describe pod <pod-name>
kubectl -n <ns> logs <pod-name>

# Deployment 更新
kubectl -n <ns> set image deployment/<name> <container>=<image:tag>
kubectl -n <ns> rollout status deployment/<name>
kubectl -n <ns> rollout history deployment/<name>
kubectl -n <ns> rollout undo deployment/<name>

# 宣言的適用（安全確認つき）
kubectl apply --dry-run=server -f manifest.yaml
kubectl apply -f manifest.yaml
```

---

## 7) Common mistakes and safe practices

### よくあるミス
- `kubectl` の Context を確認せず本番クラスタに適用
- `default` Namespace に何でも入れて混乱
- `kubectl delete` を広いスコープで実行（`-A` や誤ラベル）
- Secret を平文でマニフェストに記載して共有

### 安全プラクティス
- 実行前に毎回:
  - `kubectl config current-context`
  - `kubectl -n <ns> get ...` で対象確認
- 破壊的操作前は「対象名」「Namespace」「Context」を声に出して確認
- `apply` 前に `--dry-run=server` でバリデーション
- 本番変更は宣言ファイル + レビューを基本にする

---

## 8) Interview-style question

**Q.** `kubectl apply` と `kubectl replace` の違いは？本番運用ではどちらをどう使い分ける？

**A（要点）:**
- `apply` は宣言的に差分適用し、継続運用と相性が良い（一般的に推奨）
- `replace` はリソース全体の置換に近く、意図しないフィールド消失のリスクがある
- 本番は通常 `apply` を中心に、変更履歴・レビュー・ロールバック手段と組み合わせる

---

## 9) Next-step resources (official docs)

- Kubernetes Concepts Overview  
  https://kubernetes.io/docs/concepts/overview/
- Deployments  
  https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- kubectl Cheat Sheet  
  https://kubernetes.io/docs/reference/kubectl/cheatsheet/
- Configuration Best Practices  
  https://kubernetes.io/docs/concepts/configuration/overview/
- Secrets (good practices)  
  https://kubernetes.io/docs/concepts/security/secrets-good-practices/
- Debug running pods  
  https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/

---

次号予告: **Service/Ingress/NetworkPolicy を通した「外部公開と通信制御」の実践**（Beginner→Advanced）