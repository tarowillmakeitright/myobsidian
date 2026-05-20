---
tags:
  - kubernetes
  - k8s
  - devops
  - learning
  - daily
---

# 2026-05-20 Kubernetes Commands Magazine
[[Home]]

## 今回の学習アーク
Beginner → Middle → Advanced の順で、段階的に「安全に `kubectl` を使ってアプリ運用する力」を積み上げます。

---

## 1) Topic + Level

### Beginner（初級）
**Topic:** Pod / Deployment / Service の基本操作と安全な確認フロー

### Middle（中級）
**Topic:** ConfigMap・Secret・Namespace を使った設定分離と安全なデプロイ

**Prerequisites（前提知識）**
- Pod / Deployment / Service の役割を説明できる
- `kubectl get/describe/logs` を使った基本調査ができる
- YAML マニフェストの基本構文が読める

### Advanced（上級）
**Topic:** RollingUpdate・Probes・Resource requests/limits を使った本番運用に近い改善

**Prerequisites（前提知識）**
- Deployment 更新（`set image` / `rollout status`）を実行した経験
- ConfigMap / Secret の使い分け理解
- Namespace ごとの運用分離の必要性を理解

---

## 2) なぜ実アプリ開発で重要か

- ローカルでは動くアプリでも、クラスタでは**ネットワーク・設定・リソース制約**で失敗しやすい。  
- Kubernetes の基本オブジェクトを正しく扱えると、**再現可能なデプロイ**と**安全な変更**ができる。  
- 中上級の概念（Secret管理、Probe、RollingUpdate）は、障害時の影響を最小化し、**ユーザー影響を抑えたリリース**に直結する。

---

## 3) Core kubectl / Kubernetes Concept

### Beginner Core
- **Pod:** コンテナ実行の最小単位
- **Deployment:** Pod の望ましい状態を維持し、更新を管理
- **Service:** Pod への安定した到達点（仮想IP/DNS）

基本コマンド:
```bash
kubectl get pods
kubectl get deploy
kubectl get svc
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

### Middle Core
- **Namespace:** 環境・チーム単位の分離
- **ConfigMap:** 非機密設定
- **Secret:** 機密情報（ただし平文をGit保存しない運用が前提）

基本コマンド:
```bash
kubectl get ns
kubectl -n <ns> get all
kubectl -n <ns> create configmap app-config --from-literal=APP_MODE=staging
kubectl -n <ns> create secret generic app-secret --from-literal=API_KEY='***'
```

### Advanced Core
- **RollingUpdate:** 無停止に近い段階更新
- **readinessProbe / livenessProbe:** トラフィック受け入れ可否と自己修復判断
- **requests / limits:** スケジューリングと過負荷制御

基本コマンド:
```bash
kubectl rollout status deploy/<name>
kubectl rollout history deploy/<name>
kubectl rollout undo deploy/<name>
kubectl top pod -n <ns>   # metrics-server が必要
```

---

## 4) アプリ開発中での使い方（kubernetes.io/docs ベストプラクティス準拠）

- **宣言的管理を優先:** `kubectl apply -f` でマニフェストを管理し、差分を追跡する。  
- **適切なスコープ指定:** `-n <namespace>` を徹底し、誤操作を防止。  
- **コンテキスト確認を習慣化:** 本番誤爆防止のため、実行前に必ず `kubectl config current-context` と `kubectl get ns` を確認。  
- **Secret をマニフェストに直書きしない:** 機密は外部Secret管理や暗号化ワークフローと連携。  
- **小さく安全にリリース:** Deployment の段階更新とヘルスチェックでリスク低減。

---

## 5) 30〜60分ハンズオン・ミニラボ

**目的:** `Namespace + Deployment + Service + ConfigMap + Secret + RollingUpdate` を一連で体験

### Step 0: 破壊的操作への注意（最重要）
以下は実行前に必ず確認:
```bash
kubectl config current-context
kubectl get ns
```
> ⚠️ `delete` 系コマンドや `apply -f` は対象クラスタ/namespaceを誤ると重大事故になります。

### Step 1: Namespace 作成（5分）
```bash
kubectl create ns k8s-mag-lab
kubectl -n k8s-mag-lab get all
```

### Step 2: Deployment/Service 作成（10分）
`lab-app.yaml` を作成:
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
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            cpu: "300m"
            memory: "256Mi"
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 10
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 15
          periodSeconds: 20
---
apiVersion: v1
kind: Service
metadata:
  name: web-svc
  namespace: k8s-mag-lab
spec:
  selector:
    app: web
  ports:
  - port: 80
    targetPort: 80
```

適用:
```bash
kubectl apply -f lab-app.yaml
kubectl -n k8s-mag-lab get pods,deploy,svc
```

### Step 3: ConfigMap / Secret（10分）
```bash
kubectl -n k8s-mag-lab create configmap web-config --from-literal=APP_ENV=lab
kubectl -n k8s-mag-lab create secret generic web-secret --from-literal=TOKEN='dummy-token'
kubectl -n k8s-mag-lab get configmap,secret
```
> ⚠️ Secret の値をターミナル履歴・Git に残さない運用を徹底。

### Step 4: ローリングアップデート（10分）
```bash
kubectl -n k8s-mag-lab set image deploy/web nginx=nginx:1.27.1
kubectl -n k8s-mag-lab rollout status deploy/web
kubectl -n k8s-mag-lab rollout history deploy/web
```

### Step 5: トラブル時の確認（10分）
```bash
kubectl -n k8s-mag-lab describe deploy web
kubectl -n k8s-mag-lab get events --sort-by=.lastTimestamp
kubectl -n k8s-mag-lab logs deploy/web
```

### Step 6: 後片付け（必要なら、慎重に）
```bash
kubectl config current-context
kubectl delete ns k8s-mag-lab
```
> ⚠️ `kubectl delete ns` は削除範囲が大きいです。対象名を声に出して確認。

---

## 6) Command Cheatsheet

```bash
# コンテキスト/対象確認
kubectl config current-context
kubectl config get-contexts
kubectl get ns

# 基本参照
kubectl -n <ns> get pods,deploy,svc
kubectl -n <ns> describe pod <pod>
kubectl -n <ns> logs <pod>

# 適用/更新
kubectl apply -f <file.yaml>
kubectl -n <ns> set image deploy/<name> <container>=<image:tag>
kubectl -n <ns> rollout status deploy/<name>

# 切り戻し
kubectl -n <ns> rollout undo deploy/<name>

# 設定
kubectl -n <ns> create configmap <name> --from-literal=KEY=VALUE
kubectl -n <ns> create secret generic <name> --from-literal=KEY=VALUE
```

---

## 7) よくあるミス & 安全な運用

- **ミス:** `default` namespace のまま apply/delete する  
  **対策:** すべてのコマンドに `-n` を付ける。実行前に context を確認。

- **ミス:** Secret を YAML/Git に平文保存する  
  **対策:** 外部Secret管理、暗号化（例: Sealed Secrets など）を検討。

- **ミス:** `:latest` タグ運用で再現性を失う  
  **対策:** 明示タグ（可能なら digest）を固定。

- **ミス:** Probe 未設定で壊れたPodに流入  
  **対策:** readiness/liveness を実装して段階導入。

- **ミス:** 一気に大規模変更  
  **対策:** 小さい変更 + `rollout status/history` で観察。

---

## 8) 面接っぽい一問

**Q.** `readinessProbe` と `livenessProbe` の違いを説明し、未設定だとどんな障害が起きる可能性があるか？  
**A（要点）:** readiness は「トラフィックを受けてよいか」、liveness は「プロセスが生存しているか」。未設定だと、起動途中のPodにトラフィックが流れてエラー増加、ハングしたプロセスが自動復旧されない等が起こり得る。

---

## 9) 次の一歩（公式中心）

- Kubernetes Concepts  
  https://kubernetes.io/docs/concepts/
- kubectl Cheat Sheet  
  https://kubernetes.io/docs/reference/kubectl/cheatsheet/
- Deployments  
  https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Services  
  https://kubernetes.io/docs/concepts/services-networking/service/
- Probes (Liveness/Readiness/Startup)  
  https://kubernetes.io/docs/concepts/configuration/liveness-readiness-startup-probes/
- ConfigMap  
  https://kubernetes.io/docs/concepts/configuration/configmap/
- Secret（安全な取り扱い含む）  
  https://kubernetes.io/docs/concepts/configuration/secret/
- Resource Management for Pods and Containers  
  https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/

---

明日の予告: **Ingress と NetworkPolicy の基礎**（通信制御を安全に設計する入門）
