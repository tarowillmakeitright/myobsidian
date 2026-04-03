---
tags: [kubernetes, k8s, devops, learning, daily]
---

# Daily Kubernetes Commands Magazine — 2026-04-03 (09:25)
[[Home]]

#kubernetes #k8s #devops #learning #daily

実務で使える Kubernetes 学習アーク（Beginner → Middle → Advanced）を、段階的に進めます。

---

## 1) Topic + Level

### Beginner
**トピック:** `kubectl get/describe/logs` で「いま何が起きているか」を把握する

### Middle
**トピック:** Deployment のローリングアップデートとロールバック運用
**前提知識:**
- Pod / Deployment / ReplicaSet の基本
- `kubectl get`, `kubectl describe`, `kubectl logs` を使って状態確認できる

### Advanced
**トピック:** Namespace + Context を意識した安全な運用（誤操作防止）
**前提知識:**
- kubeconfig/context の概念
- `kubectl apply -f` の適用範囲を理解している
- Deployment 更新運用の経験がある

---

## 2) Why it matters for real app development

- アプリ開発では「動く」よりも「安定して運用できる」ことが重要。
- 不具合時に `kubectl` で即座に状況把握できると、MTTR（復旧時間）を短縮できる。
- Deployment 更新戦略（rollout）を理解すると、ダウンタイムを最小化しながら継続的デリバリーが可能。
- Context/Namespace を明示する習慣は、本番クラスターへの誤操作事故を防ぐ（実務上かなり重要）。

---

## 3) Core kubectl/Kubernetes concept explanations

### Beginner: 観測の基本
- `kubectl get` : リソース一覧を確認
- `kubectl describe` : イベントや詳細状態を確認
- `kubectl logs` : コンテナログを確認

### Middle: 宣言的更新
- Deployment は「望ましい状態」を保持。
- `kubectl apply -f` で宣言を適用し、差分更新。
- `kubectl rollout status/history/undo` で更新の可視化・復元。

### Advanced: 安全ガード
- Context = どのクラスターへ操作するか
- Namespace = どの論理空間へ操作するか
- `--context`, `-n` を明示しない操作は、意図しない環境変更を招きやすい。

---

## 4) How Kubernetes is used while building apps (kubernetes.io/docs ベストプラクティス準拠)

- 開発初期: Deployment + Service で最小構成を定義（宣言的管理）。
- 機能追加時: イメージタグ更新 → `rollout status` で安全に確認。
- 障害調査時: `get/describe/logs/events` の順で観測し、推測ではなく事実ベースで対応。
- セキュリティ:
  - Secret をマニフェストへ平文直書きしない。
  - 可能なら Secret 管理を分離し、アクセス権を最小化（RBAC）。
  - `latest` タグ常用を避け、追跡可能なタグ/ダイジェストを使う。

---

## 5) 30-60 minute hands-on mini lab

**想定時間:** 45分

### Step 0: 事前安全確認（5分）
```bash
kubectl config get-contexts
kubectl config current-context
kubectl get ns
```
- いまの context が学習用クラスターか必ず確認。
- 本番で試さない。

### Step 1: Namespace 作成（5分）
```bash
kubectl create namespace k8s-mag-lab
kubectl -n k8s-mag-lab get all
```

### Step 2: Deployment 作成（10分）
```bash
kubectl -n k8s-mag-lab create deployment web --image=nginx:1.25
kubectl -n k8s-mag-lab get deploy,po
kubectl -n k8s-mag-lab describe deployment web
```

### Step 3: Service 公開（5分）
```bash
kubectl -n k8s-mag-lab expose deployment web --port=80 --type=ClusterIP
kubectl -n k8s-mag-lab get svc
```

### Step 4: ローリングアップデート（10分）
```bash
kubectl -n k8s-mag-lab set image deployment/web nginx=nginx:1.27
kubectl -n k8s-mag-lab rollout status deployment/web
kubectl -n k8s-mag-lab rollout history deployment/web
```

### Step 5: 疑似障害とロールバック（10分）
```bash
kubectl -n k8s-mag-lab set image deployment/web nginx=nginx:badtag
kubectl -n k8s-mag-lab rollout status deployment/web
kubectl -n k8s-mag-lab rollout undo deployment/web
kubectl -n k8s-mag-lab rollout status deployment/web
```

### Step 6: 片付け（任意）
```bash
# 破壊的操作: 対象 namespace と context を再確認してから実行
kubectl delete namespace k8s-mag-lab
```

---

## 6) Command cheatsheet

```bash
# 安全確認
kubectl config current-context
kubectl -n <ns> get all

# 観測
kubectl -n <ns> get pods
kubectl -n <ns> describe pod <pod-name>
kubectl -n <ns> logs <pod-name>
kubectl -n <ns> get events --sort-by=.metadata.creationTimestamp

# 更新
kubectl -n <ns> apply -f app.yaml
kubectl -n <ns> set image deployment/<name> <container>=<image:tag>
kubectl -n <ns> rollout status deployment/<name>
kubectl -n <ns> rollout history deployment/<name>
kubectl -n <ns> rollout undo deployment/<name>
```

---

## 7) Common mistakes and safe practices

### よくあるミス
- `kubectl apply -f .` を意図せず広範囲に実行。
- context 未確認で本番へ適用。
- Secret を Git 管理下マニフェストへ直書き。
- `:latest` で再現不能なデプロイ。

### 安全プラクティス
- 破壊的コマンド前に **context / namespace / 対象リソース** を声出し確認。
- `--context` と `-n` を明示。
- まず `kubectl diff -f ...`（利用可能環境なら）で差分確認。
- Secret は専用管理（Kubernetes Secret + 外部シークレット管理）し、最小権限でアクセス。

> ⚠️ 注意: `kubectl delete`, `kubectl apply` はスコープ誤りが事故に直結。特に `-A` や `--all`、ディレクトリ適用は慎重に。

---

## 8) One interview-style question

**質問:**
本番 Deployment 更新後に一部 Pod が Ready にならず、ユーザー影響が出始めました。`kubectl` でどの順に確認し、どのタイミングで rollback を判断しますか？

（狙い: 観測→原因切り分け→安全復旧の思考プロセス）

---

## 9) Next-step resources (official kubernetes.io 優先)

- Kubernetes Concepts
  - https://kubernetes.io/docs/concepts/
- kubectl Overview
  - https://kubernetes.io/docs/reference/kubectl/
- Deployment
  - https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Update strategy / Rollback
  - https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#rolling-back-a-deployment
- Configuration Best Practices
  - https://kubernetes.io/docs/concepts/configuration/overview/
- Secrets
  - https://kubernetes.io/docs/concepts/configuration/secret/
- Good Practices for Kubernetes Secrets
  - https://kubernetes.io/docs/concepts/security/secrets-good-practices/
- Multi-tenancy / Namespaces
  - https://kubernetes.io/docs/concepts/security/multi-tenancy/

---

次号予告（Advanced寄り）: `readinessProbe/livenessProbe` と `resources requests/limits` で「落ちにくい」アプリ運用。