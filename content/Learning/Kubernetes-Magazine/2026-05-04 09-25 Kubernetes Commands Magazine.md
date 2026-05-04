---
tags: [kubernetes, k8s, devops, learning, daily]
---

# Daily Kubernetes Commands Magazine
**Date:** 2026-05-04 09:25 (Asia/Tokyo)  
**Learning Arc:** Beginner → Middle → Advanced

[[Home]]

---

## 1) Topic + Level

### Beginner（初級）
**Topic:** `kubectl get/describe/logs` で「動いているものを見る」

### Middle（中級）
**Topic:** Deployment のローリングアップデートとロールバックを安全に運用する

**Prerequisites:**
- Pod / Deployment / Service の基本を理解している
- `kubectl get`, `kubectl logs`, `kubectl describe` を使える
- Namespace と Context の概念を知っている

### Advanced（上級）
**Topic:** ConfigMap / Secret / Probe / Resource requests&limits を組み合わせた実運用向けデプロイ

**Prerequisites:**
- Deployment 更新フロー（`set image`, `rollout status`, `rollout undo`）を使える
- YAML マニフェストを読み書きできる
- セキュリティ上、Secret を平文で Git 管理しない理由を説明できる

---

## 2) Why it matters for real app development

アプリ開発では「コードを書く」だけでなく、**安全にデプロイし、問題時に素早く切り戻せること**が必須です。  
Kubernetes の運用力があると、次の価値が出ます。

- 障害時の初動（状況把握）が速くなる
- リリース失敗時の影響を最小化できる
- 環境差分（dev/stg/prod）を整理しやすくなる
- チームで同じ運用手順を共有できる

---

## 3) Core kubectl / Kubernetes concept explanations

- **Context**: どのクラスタ・ユーザーを操作するかの対象。誤操作防止の最重要ポイント。
- **Namespace**: リソースの論理的な分離。アプリ単位・チーム単位で整理。
- **Deployment**: Pod の望ましい状態を宣言し、更新を管理。
- **ReplicaSet**: Deployment が管理する Pod の世代管理。
- **Service**: Pod への安定した到達点。
- **ConfigMap / Secret**: 設定値と機密情報を分離。
- **Probe (liveness/readiness)**: Pod が生きているか / トラフィックを受けてよいか判定。
- **requests/limits**: CPU/メモリ使用量の期待値と上限。ノード資源の健全運用に必須。

---

## 4) How Kubernetes is used while building apps (best practices aligned)

実装〜運用では、以下の流れが実践的です（kubernetes.io/docs の推奨に沿う形）。

1. **マニフェストを宣言的に管理**（Deployment/Service など）
2. **設定と機密を分離**（ConfigMap と Secret を使い分け）
3. **readinessProbe を設定**し、準備完了前にトラフィックを受けない
4. **requests/limits を設定**して隣接ワークロードと資源競合しにくくする
5. **ローリングアップデート**で段階的に更新
6. **失敗時は rollout undo** で即切り戻し
7. **`kubectl diff` / `--dry-run` / context確認**で誤適用を防ぐ

---

## 5) 30-60 minute hands-on mini lab

**Goal:** 安全な更新と切り戻しを 1 サイクル体験する（約45分）

> 前提: ローカルクラスタ（kind / minikube など）または検証 namespace を利用。

### Step 0: 安全確認（5分）
```bash
kubectl config current-context
kubectl get ns
kubectl create ns k8s-magazine-lab
```

### Step 1: 初期デプロイ（10分）
```bash
kubectl -n k8s-magazine-lab create deployment web --image=nginx:1.25
kubectl -n k8s-magazine-lab expose deployment web --port=80 --type=ClusterIP
kubectl -n k8s-magazine-lab get all
```

### Step 2: 状態観測（10分）
```bash
kubectl -n k8s-magazine-lab describe deploy web
kubectl -n k8s-magazine-lab get pods -o wide
kubectl -n k8s-magazine-lab logs deploy/web --tail=50
```

### Step 3: ローリングアップデート（10分）
```bash
kubectl -n k8s-magazine-lab set image deploy/web nginx=nginx:1.27
kubectl -n k8s-magazine-lab rollout status deploy/web
kubectl -n k8s-magazine-lab rollout history deploy/web
```

### Step 4: 失敗想定とロールバック（10分）
```bash
kubectl -n k8s-magazine-lab set image deploy/web nginx=nginx:invalid-tag
kubectl -n k8s-magazine-lab rollout status deploy/web
kubectl -n k8s-magazine-lab rollout undo deploy/web
kubectl -n k8s-magazine-lab rollout status deploy/web
```

### Step 5: 後片付け（任意）
```bash
# 破壊的操作: 対象 namespace を必ず再確認してから実行
kubectl delete ns k8s-magazine-lab
```

---

## 6) Command cheatsheet

```bash
# Context / Namespace
kubectl config current-context
kubectl config get-contexts
kubectl -n <namespace> get all

# Observe
kubectl get pods -A
kubectl describe pod <pod>
kubectl logs <pod> --tail=100
kubectl logs -f deploy/<name>

# Deploy / Update
kubectl apply -f app.yaml
kubectl set image deploy/<name> <container>=<image:tag>
kubectl rollout status deploy/<name>
kubectl rollout history deploy/<name>
kubectl rollout undo deploy/<name>

# Safety helpers
kubectl diff -f app.yaml
kubectl apply --dry-run=server -f app.yaml
kubectl auth can-i delete pods -n <namespace>
```

---

## 7) Common mistakes and safe practices

### よくあるミス
- `current-context` を確認せず本番クラスタを触る
- `default` namespace に何でも投入してしまう
- `kubectl apply -f .` で想定外ファイルまで適用
- Secret を平文 YAML のまま Git に push する
- `delete` コマンドを対象確認なしで実行する

### 安全運用
- 実行前に **context / namespace / 対象リソース名** を毎回確認
- 破壊的コマンド前に `get` か `describe` で対象を再確認
- `kubectl diff` と `--dry-run=server` を標準手順にする
- Secret は External Secrets / SOPS / Sealed Secrets などで管理し、平文保存を避ける
- 本番では RBAC 最小権限 + 監査ログを有効化

⚠️ **Warning:** `kubectl delete`, `kubectl apply -f .`, `kubectl replace --force` は影響範囲を誤ると障害に直結。必ず scope/context を確認してから実行。

---

## 8) One interview-style question

**Q.** Deployment の更新時に readinessProbe がないと、ユーザー影響はどう発生し得ますか？また、`rollout status` と組み合わせてどのようにリスクを下げますか？

（回答の観点: 準備未完了 Pod への流入、エラー率上昇、段階更新監視、失敗時の rollback 判断）

---

## 9) Next-step resources (official first)

- Kubernetes Documentation (Main): https://kubernetes.io/docs/
- Overview / Concepts: https://kubernetes.io/docs/concepts/
- kubectl Overview: https://kubernetes.io/docs/reference/kubectl/
- Deployments: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Probes (liveness/readiness/startup): https://kubernetes.io/docs/concepts/configuration/liveness-readiness-startup-probes/
- ConfigMap: https://kubernetes.io/docs/concepts/configuration/configmap/
- Secret: https://kubernetes.io/docs/concepts/configuration/secret/
- Resource Management: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/
- Kubernetes Security Best Practices: https://kubernetes.io/docs/concepts/security/

---

**Tomorrow preview:** Middle→Advanced の橋渡しとして、`HPA + metrics-server + requests/limits調整` の実測チューニング編。