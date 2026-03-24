# Daily Kubernetes Commands Magazine — 2026-03-24

Tags: #kubernetes #k8s #devops #learning #daily  
Links: [[Home]]

---

## 今号の学習アーク（Beginner → Middle → Advanced）

- **Beginner:** Pod/Deployment の基本運用（`kubectl get/describe/logs`）
- **Middle:** Service と ConfigMap/Secret を使った安全なアプリ設定
- **Advanced:** Rolling Update / Rollback と運用トラブルシュート（本番想定）

> ねらい: 「動かす」だけでなく、**安全に・継続的に運用できる Kubernetes 操作**を身につける。

---

## 1) Topic + Level

### 🟢 Beginner
**トピック:** Deployment と Pod の観察・デバッグ入門

### 🟡 Middle
**トピック:** Service 接続と設定分離（ConfigMap/Secret）
**前提条件:**
- Pod/Deployment の作成・確認ができる
- `kubectl get/describe/logs` を使える

### 🔴 Advanced
**トピック:** 安全なリリース（RollingUpdate/Rollback）と障害切り分け
**前提条件:**
- Deployment, Service, ConfigMap, Secret の基本を理解している
- namespace/context の概念を理解している

---

## 2) Why it matters for real app development

- 実アプリでは「デプロイ成功」よりも、**障害時に復旧できること**が重要。
- アプリ設定（環境差分）をイメージに埋め込まず、**ConfigMap/Secret で外出し**する設計は必須。
- リリース時は失敗前提で、**段階更新と即時ロールバック**ができると MTTR（復旧時間）が大幅に短くなる。

---

## 3) Core kubectl/Kubernetes concept explanations

- **Pod:** 最小デプロイ単位。通常は直接ではなく Deployment 経由で管理。
- **Deployment:** ReplicaSet を通じて Pod の望ましい状態を維持。更新戦略を持つ。
- **Service (ClusterIP):** Pod の IP 変動を隠蔽し、安定した名前解決を提供。
- **ConfigMap/Secret:** 設定と機密情報をイメージから分離。
- **Namespace:** 環境やチーム単位の論理分離。
- **Context:** `kubectl` がどのクラスタ/ユーザー/namespace に向いているか。

よく使う確認:
```bash
kubectl config get-contexts
kubectl config current-context
kubectl get ns
```

---

## 4) How Kubernetes is used while building apps（kubernetes.io/docs ベストプラクティス準拠）

- 開発中:
  - `Deployment` でアプリを反復デプロイ
  - `readinessProbe/livenessProbe` を設定し、壊れた Pod を自動検知
- 環境差分管理:
  - DB ホストなど非機密は ConfigMap
  - パスワード/トークンは Secret（※Git に平文コミットしない）
- リリース:
  - `RollingUpdate` で無停止に近い更新
  - 異常時は `kubectl rollout undo` で即戻す
- 運用:
  - `kubectl logs`, `kubectl describe`, `kubectl get events` で一次切り分け

---

## 5) 30–60 minute hands-on mini lab

> ローカルクラスタ（minikube/kind など）推奨。破壊的コマンド前に context 確認。

### Step A（Beginner, 15分）: Deployment を立てて観察
```bash
kubectl create namespace mag-lab
kubectl config set-context --current --namespace=mag-lab

kubectl create deployment web --image=nginx:1.25
kubectl get pods -w
kubectl describe deployment web
kubectl logs deploy/web
```

### Step B（Middle, 15分）: Service + ConfigMap + Secret
```bash
kubectl expose deployment web --port=80 --target-port=80 --type=ClusterIP
kubectl get svc web

kubectl create configmap web-config --from-literal=APP_MODE=staging
kubectl create secret generic web-secret --from-literal=API_TOKEN='change-me-locally'

kubectl set env deploy/web --from=configmap/web-config
kubectl set env deploy/web --from=secret/web-secret
kubectl rollout status deploy/web
```

### Step C（Advanced, 20分）: 更新とロールバック
```bash
kubectl set image deployment/web nginx=nginx:1.27
kubectl rollout status deployment/web
kubectl rollout history deployment/web

# 問題が出た想定でロールバック
kubectl rollout undo deployment/web
kubectl rollout status deployment/web
```

### Step D（任意, 5分）: 後片付け
```bash
# ⚠️ 削除前に namespace/context を再確認
kubectl config current-context
kubectl get ns
kubectl delete namespace mag-lab
```

---

## 6) Command cheatsheet

```bash
# 状態確認
kubectl get pods,deploy,svc -n <ns>
kubectl describe pod <pod> -n <ns>
kubectl logs <pod> -n <ns>
kubectl logs deploy/<name> -n <ns>

# 設定と適用
kubectl apply -f <file.yaml>
kubectl diff -f <file.yaml>

# 更新/復旧
kubectl set image deploy/<name> <container>=<image>:<tag>
kubectl rollout status deploy/<name>
kubectl rollout history deploy/<name>
kubectl rollout undo deploy/<name>

# 安全確認（超重要）
kubectl config current-context
kubectl config view --minify
kubectl get ns
```

---

## 7) Common mistakes and safe practices

### よくあるミス
1. `kubectl apply -f .` を意図しないディレクトリで実行して事故る
2. context を見ずに本番クラスタへ操作
3. Secret を YAML に平文で置いて Git へ push
4. `kubectl delete` を namespace 指定なしで実行

### 安全プラクティス
- 破壊的操作前に毎回:
  - `kubectl config current-context`
  - `kubectl get ns`
- `apply` 前に `kubectl diff -f ...` で差分確認
- Secret は外部シークレット管理や暗号化（Sealed Secrets/SOPS 等）を検討
- マニフェストに最小権限（RBAC）と resource requests/limits を設定

---

## 8) Interview-style question

**質問:**
Deployment の RollingUpdate 中に一部 Pod が Ready にならず更新が止まりました。あなたなら `kubectl` でどの順番で確認し、どの条件なら rollback を判断しますか？

**評価ポイント（セルフチェック）:**
- `rollout status` / `describe` / `logs` / `events` の順で切り分けできるか
- readinessProbe 失敗とアプリ内部エラーを区別できるか
- ユーザー影響を基準に rollback 判断を説明できるか

---

## 9) Next-step resources（公式優先）

- Kubernetes Concepts  
  https://kubernetes.io/docs/concepts/
- Workloads: Deployments  
  https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Service  
  https://kubernetes.io/docs/concepts/services-networking/service/
- ConfigMap  
  https://kubernetes.io/docs/concepts/configuration/configmap/
- Secret  
  https://kubernetes.io/docs/concepts/configuration/secret/
- kubectl Cheat Sheet  
  https://kubernetes.io/docs/reference/kubectl/cheatsheet/
- Configure Access to Multiple Clusters (contexts)  
  https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/

---

### 今日の一言
「速くデプロイできる人」より、**安全に戻せる人**が本番では強い。