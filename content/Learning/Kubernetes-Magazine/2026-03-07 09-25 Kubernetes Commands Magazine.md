---
tags: [kubernetes, k8s, devops, learning, daily]
---
[[Home]]

# Kubernetes Commands Magazine — 2026-03-07 09:25

> 今日の学習アーク: **Beginner → Middle → Advanced**
> テーマは「アプリを安全にデプロイし、段階的に運用レベルへ引き上げる」

---

## 1) Topic + Level

### 🟢 Beginner
**Topic:** Deployment と Pod の基本操作（`get/describe/logs/apply`）

### 🟡 Middle
**Topic:** RollingUpdate・Service・Namespace を使った実運用寄りデプロイ
**Prerequisites:**
- Pod / Deployment の基本概念
- `kubectl get/describe/logs/apply` を使える
- YAML マニフェストの最小構成を読める

### 🔴 Advanced
**Topic:** ConfigMap/Secret・Probes・Resource 制御・安全なロールアウト/ロールバック
**Prerequisites:**
- Deployment と Service の運用経験
- RollingUpdate の流れを理解
- Namespace と context の違いを説明できる

---

## 2) Why it matters for real app development

- ローカルで動くアプリを**チーム開発・本番運用**へ持っていく際、Kubernetes は「再現性のある実行環境」を提供する。
- `kubectl` の正しい使い方を身につけると、**障害対応速度**と**リリースの安全性**が上がる。
- 設定・シークレット・リソース制御を理解すると、**セキュアで安定したアプリ運用**が可能になる。

---

## 3) Core kubectl/Kubernetes concept explanations

- **Pod**: コンテナ実行の最小単位（通常は直接運用せず Deployment 経由）
- **Deployment**: Pod の望ましい状態を宣言し、更新・復旧を管理
- **Service**: Pod 群への安定したアクセス点（ClusterIP/NodePort/LoadBalancer）
- **Namespace**: 論理的な分離単位（環境やチームで分割）
- **ConfigMap / Secret**: 設定値と機密情報の分離管理
- **Probe (liveness/readiness)**: 生存確認とトラフィック受け入れ可否の制御
- **Resource requests/limits**: スケジューリングと暴走抑止
- **Context**: `kubectl` が操作対象にするクラスタ/ユーザー/namespace の組

---

## 4) How Kubernetes is used while building apps (kubernetes.io/docs best practices aligned)

実アプリ開発では次の流れが推奨される:

1. **宣言的管理（YAML + apply）**
   - imperative コマンド乱用より、Git で管理したマニフェストを `kubectl apply -f` で適用
2. **環境差分を Namespace/設定で分離**
   - dev/stg/prod を混在させない
3. **Secret を平文でリポジトリ保存しない**
   - 可能なら外部 secret manager 連携を検討
4. **readiness/liveness probe を入れる**
   - 起動中 Pod に誤ってトラフィックを流さない
5. **段階的ロールアウト + rollout status 監視**
   - 失敗時は素早く rollback
6. **最小権限・最小公開**
   - 不要な権限/公開ポートを作らない

参考（公式）:
- Concepts: https://kubernetes.io/docs/concepts/
- Configuration Best Practices: https://kubernetes.io/docs/concepts/configuration/overview/
- Deployments: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Probes: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/
- Secrets: https://kubernetes.io/docs/concepts/configuration/secret/

---

## 5) 30-60 minute hands-on mini lab

> 想定: ローカルクラスタ（minikube / kind / Docker Desktop Kubernetes）
> 目安: 45分

### Step 0: 安全確認（最重要）
```bash
kubectl config current-context
kubectl config get-contexts
kubectl get ns
```
- **本番 context でないことを確認**してから進める。

### Step 1 (Beginner: 10-15分)
Nginx Deployment を作成し状態確認:
```bash
kubectl create ns mag-lab
kubectl -n mag-lab create deployment web --image=nginx:1.25
kubectl -n mag-lab get deploy,pod -o wide
kubectl -n mag-lab describe deployment web
kubectl -n mag-lab logs deploy/web
```

### Step 2 (Middle: 15-20分)
Service 公開と RollingUpdate:
```bash
kubectl -n mag-lab expose deployment web --port=80 --target-port=80 --type=ClusterIP
kubectl -n mag-lab get svc
kubectl -n mag-lab set image deployment/web nginx=nginx:1.27
kubectl -n mag-lab rollout status deployment/web
kubectl -n mag-lab rollout history deployment/web
```

### Step 3 (Advanced: 15-20分)
readinessProbe + resources + ConfigMap 適用:

`web-advanced.yaml` を作成:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: web-config
  namespace: mag-lab
data:
  APP_MODE: "learning"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
  namespace: mag-lab
spec:
  replicas: 2
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 0
      maxSurge: 1
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
        envFrom:
        - configMapRef:
            name: web-config
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 3
          periodSeconds: 5
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            cpu: "300m"
            memory: "256Mi"
```

適用と確認:
```bash
kubectl apply -f web-advanced.yaml
kubectl -n mag-lab rollout status deploy/web
kubectl -n mag-lab get pod
kubectl -n mag-lab describe pod -l app=web
```

### Cleanup（破壊的操作なので注意）
```bash
# 実行前に context と namespace を再確認
kubectl config current-context
kubectl delete ns mag-lab
```

---

## 6) Command cheatsheet

```bash
# 状態確認
kubectl get pod -A
kubectl get deploy,svc -n <namespace>
kubectl describe pod <pod> -n <namespace>
kubectl logs <pod> -n <namespace>

# デプロイ更新
kubectl apply -f <file.yaml>
kubectl set image deploy/<name> <container>=<image>:<tag> -n <namespace>
kubectl rollout status deploy/<name> -n <namespace>
kubectl rollout history deploy/<name> -n <namespace>
kubectl rollout undo deploy/<name> -n <namespace>

# コンテキスト/名前空間安全確認
kubectl config current-context
kubectl config get-contexts
kubectl config set-context --current --namespace=<namespace>

# ドライラン（安全）
kubectl apply --dry-run=server -f <file.yaml>
```

---

## 7) Common mistakes and safe practices

### よくあるミス
1. **誤クラスタに apply/delete**（context 未確認）
2. **default namespace に混在デプロイ**
3. **Secret を YAML 平文で Git 管理**
4. **probe 未設定で不安定リリース**
5. **requests/limits 未設定でノード圧迫**

### 安全プラクティス
- 破壊的コマンド前に必ず:
  - `kubectl config current-context`
  - `kubectl get ns`
- `kubectl apply --dry-run=server -f ...` で事前検証
- 本番は段階的 rollout + status 監視 + rollback 手順を事前準備
- Secret は最小露出（平文直書き・貼り付け共有を避ける）
- `-A` やワイルドカード指定時は対象範囲を口に出して確認する習慣

---

## 8) One interview-style question

**Q.** `readinessProbe` と `livenessProbe` の違いは何ですか？また、誤設定するとどのような障害が起こりますか？

（答えるときの観点: トラフィック制御 vs 再起動判定、起動直後の false negative、連続再起動による可用性低下）

---

## 9) Next-step resources (official docs preferred)

- Kubernetes Concepts: https://kubernetes.io/docs/concepts/
- kubectl Cheat Sheet: https://kubernetes.io/docs/reference/kubectl/cheatsheet/
- Deployments: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Services: https://kubernetes.io/docs/concepts/services-networking/service/
- Probes: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/
- ConfigMap: https://kubernetes.io/docs/concepts/configuration/configmap/
- Secrets: https://kubernetes.io/docs/concepts/configuration/secret/
- Resource Management: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/

---

### 今日のひとこと
「速く apply する人」より「安全に rollback できる人」が本番では強い。