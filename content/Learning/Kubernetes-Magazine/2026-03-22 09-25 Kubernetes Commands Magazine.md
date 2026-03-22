---
tags: [kubernetes, k8s, devops, learning, daily]
---

[[Home]]

# Kubernetes Commands Magazine — 2026-03-22

## 今号の学習アーク
- **Beginner → Middle → Advanced** の順で、同じテーマを段階的に深掘りします。  
- テーマ: **アプリを安全に公開するための基本運用（Deployment / Service / Rollout / Troubleshooting）**

---

## 1) Topic + Level

### Beginner（初級）
**Topic:** Deployment と Service を kubectl で作って公開する

### Middle（中級）
**Topic:** Rolling Update / Rollback と probes（readiness/liveness）

**前提知識（Prerequisites）**
- Pod / Deployment / Service の基本
- `kubectl get/describe/logs` が使える
- YAML の基本構文

### Advanced（上級）
**Topic:** 安全な本番運用のための設定（requests/limits、PDB、context確認、段階的適用）

**前提知識（Prerequisites）**
- Rolling Update / Rollback の実運用イメージ
- probes とリソース管理の基本
- Namespace 運用と kubeconfig context の概念

---

## 2) なぜ実アプリ開発で重要か
- **Deployment** はアプリ更新時のダウンタイム最小化に直結。
- **Service** は Pod の入れ替わりを吸収し、安定した接続先を提供。
- **Readiness/Liveness** は「起動しただけ」のPodを誤ってトラフィックに乗せないために重要。
- **Rollout 管理** は不具合時の即時復旧（rollback）に必須。
- **安全運用（context確認・適用範囲確認）**を徹底しないと、誤クラスタ/誤Namespaceへの適用事故が起きる。

---

## 3) コア kubectl / Kubernetes 概念

### 初級コア
- `kubectl create deployment` / `kubectl expose deployment`
- `kubectl get pods,svc,deploy`
- **宣言的管理**（`kubectl apply -f`）の考え方

### 中級コア
- `kubectl rollout status/history/undo`
- `kubectl set image`
- **readinessProbe / livenessProbe** の役割分離

### 上級コア
- **resources.requests / resources.limits**（スケジューリングと保護）
- **PodDisruptionBudget (PDB)**（メンテ時の可用性維持）
- `kubectl config current-context` と `-n <namespace>` の明示
- `kubectl diff -f` で事前差分確認

---

## 4) アプリ開発での Kubernetes 活用（kubernetes.io/docs ベストプラクティス寄せ）
- マニフェストは Git 管理し、`apply` で宣言的に反映。
- イメージタグは固定（例: `1.2.3`）し、`latest` 常用を避ける。
- probes を設定して、トラフィック制御と自己修復を有効化。
- requests/limits を設定し、ノイジーネイバーやOOMリスクを低減。
- Secret は **平文で Git に置かない**。`kubectl create secret` や外部Secret管理を利用。
- 本番適用前に context/namespace/差分を確認する運用を標準化。

---

## 5) 30–60分ミニラボ

### 目標
Nginxアプリをデプロイし、更新→失敗→ロールバックまでを安全に体験する。

### 想定時間
45分

### 手順

#### Step 0: 安全確認（5分）
```bash
kubectl config current-context
kubectl get ns
kubectl create ns k8s-mag-lab
kubectl config set-context --current --namespace=k8s-mag-lab
kubectl config view --minify | grep namespace:
```

#### Step 1: 初期デプロイ（10分）
```bash
kubectl create deployment web --image=nginx:1.25
kubectl expose deployment web --port=80 --type=ClusterIP
kubectl get deploy,pod,svc -o wide
kubectl rollout status deployment/web
```

#### Step 2: マニフェスト化と probe 追加（15分）
```bash
kubectl get deploy web -o yaml > web-deploy.yaml
```
`web-deploy.yaml` に `readinessProbe` と `livenessProbe` を追加（`/` へHTTP GET, port 80）。

```bash
kubectl apply -f web-deploy.yaml
kubectl describe pod -l app=web
```

#### Step 3: ローリングアップデート（5分）
```bash
kubectl set image deployment/web nginx=nginx:1.26
kubectl rollout status deployment/web
kubectl rollout history deployment/web
```

#### Step 4: 意図的に失敗 → 復旧（10分）
```bash
kubectl set image deployment/web nginx=nginx:does-not-exist
kubectl rollout status deployment/web
kubectl get pods
kubectl describe pod -l app=web
kubectl rollout undo deployment/web
kubectl rollout status deployment/web
```

#### Step 5: 片付け（任意・5分）
```bash
# 破壊的操作: 実行前に context/namespace を必ず再確認
kubectl config current-context
kubectl config view --minify | grep namespace:
kubectl delete ns k8s-mag-lab
```

---

## 6) Command Cheatsheet
```bash
# 状態確認
kubectl get pods,deploy,svc -n <ns>
kubectl describe pod <pod> -n <ns>
kubectl logs <pod> -n <ns>

# 適用前安全確認
kubectl config current-context
kubectl config view --minify
kubectl diff -f app.yaml -n <ns>

# デプロイ/更新
kubectl apply -f app.yaml -n <ns>
kubectl set image deployment/<name> <container>=<image>:<tag> -n <ns>

# ロールアウト管理
kubectl rollout status deployment/<name> -n <ns>
kubectl rollout history deployment/<name> -n <ns>
kubectl rollout undo deployment/<name> -n <ns>

# スケール
kubectl scale deployment/<name> --replicas=3 -n <ns>
```

---

## 7) よくあるミスと安全策
- **ミス:** `kubectl apply -f .` を誤ディレクトリで実行  
  **安全策:** `kubectl diff -f`、対象ファイルを明示、PRレビュー。

- **ミス:** context確認せず本番へ適用  
  **安全策:** 実行前に `kubectl config current-context` を習慣化。

- **ミス:** Secret をYAML平文でコミット  
  **安全策:** Secret管理を分離し、リポジトリには暗号化/テンプレートのみ。

- **ミス:** probes未設定で不安定Podに流入  
  **安全策:** readiness/liveness を最低限設定。

- **注意（破壊的操作）:** `delete`, namespace単位削除、広範囲 `apply` は高リスク。  
  **実行前チェック:** context / namespace / 対象リソース / 差分。

---

## 8) 面接風質問（1問）
「readinessProbe と livenessProbe は何が違い、両方を設定しないと本番でどんな障害が起き得るか、実例を交えて説明してください。」

---

## 9) 次の一歩（公式ドキュメント中心）
- Kubernetes Documentation（入口）  
  https://kubernetes.io/docs/home/
- Deployments  
  https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Services  
  https://kubernetes.io/docs/concepts/services-networking/service/
- Probes（Liveness, Readiness, Startup）  
  https://kubernetes.io/docs/concepts/configuration/liveness-readiness-startup-probes/
- Resource Management for Pods/Containers  
  https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/
- Pod Disruptions / PDB  
  https://kubernetes.io/docs/concepts/workloads/pods/disruptions/
- kubectl Cheat Sheet  
  https://kubernetes.io/docs/reference/kubectl/cheatsheet/

---

### 今日のひとこと
**「速く apply するより、正しい context で安全に apply するほうが、結果的に最速。」**
