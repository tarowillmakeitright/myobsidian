---
title: Kubernetes Commands Magazine
date: 2026-03-23
scheduled_time: 09:25
tags: [kubernetes, k8s, devops, learning, daily]
---

# Daily Kubernetes Commands Magazine (2026-03-23)
#kubernetes #k8s #devops #learning #daily
[[Home]]

> 今日の学習アーク: **ConfigMap / Secret / Deploymentの安全運用**
> 難易度を **Beginner → Middle → Advanced** で段階的に進めます。

---

## 1) Topic + Level

### Beginner: `kubectl config` と現在のコンテキスト確認
**Topic:** 「どのクラスタに対して操作しているか」を事故なく確認する

### Middle: ConfigMap/Secret を Deployment へ注入する
**Prerequisites:**
- Pod/Deploymentの基本を理解している
- `kubectl get/describe/logs` が使える

### Advanced: ローリング更新と安全なロールバック運用
**Prerequisites:**
- Deploymentの更新戦略（RollingUpdate）を理解している
- readinessProbe/livenessProbe の役割を理解している

---

## 2) Why it matters for real app development

実サービス開発では、次の3つが特に重要です。

1. **誤操作防止（環境事故防止）**  
   開発環境のつもりで本番に `apply/delete` してしまう事故は現実によく起きます。最初に context/namespace を確認する癖が品質と信頼を守ります。

2. **設定と機密情報の分離**  
   アプリ設定（ConfigMap）と機密情報（Secret）をコードやイメージから分離すると、再デプロイなしの設定変更や機密ローテーションがしやすくなります。

3. **無停止に近い更新運用**  
   Deployment のローリング更新・履歴管理・ロールバックは、障害時の復旧速度に直結します。

---

## 3) Core kubectl / Kubernetes concept explanations

### A. Context / Namespace
- `kubectl config current-context`: 現在操作対象のクラスタを表示
- `kubectl config get-contexts`: 利用可能な context 一覧
- `-n <namespace>`: 操作対象namespaceを明示

> 安全原則: **apply/delete前に context + namespace を必ず確認**

### B. ConfigMap と Secret
- **ConfigMap**: 非機密設定（環境変数、設定ファイル）
- **Secret**: 機密情報（パスワード、トークン）
  - etcd暗号化やRBAC最小権限を前提に運用
  - `stringData` は便利だが、Git管理時に平文混入しないよう注意

### C. Deployment と Rollout
- `kubectl rollout status deployment/<name>`: 更新状況の追跡
- `kubectl rollout history deployment/<name>`: 変更履歴確認
- `kubectl rollout undo deployment/<name>`: 直前リビジョンへ戻す

---

## 4) Building apps with Kubernetes (best-practice aligned)

kubernetes.io/docs の実践に沿うと、アプリ構築時は次の流れが基本です。

1. **マニフェストを宣言的に管理**（`kubectl apply -f`）
2. **設定をConfigMap/Secretへ分離**（イメージに秘密を埋め込まない）
3. **Probe + resources を定義**（健全性とスケジューリングの安定化）
4. **段階的ロールアウト + 観測**（`rollout status`, `logs`, `describe`）
5. **失敗時に即ロールバック**（履歴ベースで安全復帰）

特に本番では以下を徹底:
- `kubectl apply -f <file>` は**対象を限定**（ディレクトリ全体適用を無意識にやらない）
- SecretはGitに平文保存しない（外部Secret管理や暗号化ツールを併用）
- `kubectl delete` 実行前に `--dry-run=client -o yaml` や対象確認を習慣化

---

## 5) 30–60 min Hands-on mini lab

### Goal
ConfigMap/Secretを使ったDeploymentを作成し、設定変更と安全なロールバックを体験する。

### Step 0: 事前安全確認（5分）
```bash
kubectl config current-context
kubectl config get-contexts
kubectl get ns
```

### Step 1: Namespace作成（5分）
```bash
kubectl create ns k8s-mag-lab
```

### Step 2: ConfigMap/Secret作成（10分）
```bash
kubectl -n k8s-mag-lab create configmap app-config \
  --from-literal=APP_MODE=staging \
  --from-literal=LOG_LEVEL=info

kubectl -n k8s-mag-lab create secret generic app-secret \
  --from-literal=DB_PASSWORD='change-me-safe'
```

### Step 3: Deployment適用（15分）
`lab-deploy.yaml` を作成:
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
        env:
        - name: APP_MODE
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: APP_MODE
        - name: LOG_LEVEL
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: LOG_LEVEL
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: app-secret
              key: DB_PASSWORD
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 3
          periodSeconds: 5
```

適用:
```bash
kubectl apply -f lab-deploy.yaml
kubectl -n k8s-mag-lab rollout status deployment/web
kubectl -n k8s-mag-lab get pods -o wide
```

### Step 4: イメージ更新とロールバック（10–15分）
```bash
kubectl -n k8s-mag-lab set image deployment/web nginx=nginx:1.26
kubectl -n k8s-mag-lab rollout status deployment/web
kubectl -n k8s-mag-lab rollout history deployment/web

# 問題があれば戻す
kubectl -n k8s-mag-lab rollout undo deployment/web
kubectl -n k8s-mag-lab rollout status deployment/web
```

### Step 5: 後片付け（任意、5分）
```bash
# 破壊的コマンド: context/namespaceを再確認してから実行
kubectl config current-context
kubectl delete ns k8s-mag-lab
```

---

## 6) Command cheatsheet

```bash
# 安全確認
kubectl config current-context
kubectl config get-contexts
kubectl get ns

# 調査
kubectl get pods -A
kubectl describe pod <pod> -n <ns>
kubectl logs <pod> -n <ns>

# ConfigMap / Secret
kubectl create configmap <name> --from-literal=KEY=VALUE -n <ns>
kubectl create secret generic <name> --from-literal=KEY=VALUE -n <ns>
kubectl get secret <name> -n <ns> -o yaml

# Deployment運用
kubectl apply -f <file>
kubectl set image deployment/<name> <container>=<image> -n <ns>
kubectl rollout status deployment/<name> -n <ns>
kubectl rollout history deployment/<name> -n <ns>
kubectl rollout undo deployment/<name> -n <ns>
```

---

## 7) Common mistakes and safe practices

### よくあるミス
1. **間違ったcontextでapply/delete**
2. SecretをGitへ平文コミット
3. `kubectl apply -f .` で意図しない大量適用
4. Probe未設定で不安定ローリング更新

### 安全プラクティス
- 実行前チェック: `current-context` と `-n` 明示
- 破壊的操作前に対象を表示して再確認
- Secretは外部シークレット管理（例: External Secrets等）や暗号化運用
- 本番変更は小さく、`rollout status` を必ず監視

> ⚠️ 注意: `kubectl delete` や広範囲 `kubectl apply` は破壊的になり得ます。対象クラスタ・namespace・ファイル範囲を必ず確認してから実行してください。

---

## 8) Interview-style question

**Q.** Deploymentのローリング更新中に一部PodがReadyにならず更新が止まりました。あなたならどの順番で切り分けし、どの条件でロールバックしますか？

（観点例: `rollout status`, `describe pod`, `logs`, probe設定、依存先疎通、直前差分、SLO/SLA影響）

---

## 9) Next-step resources (official first)

- Kubernetes Concepts Overview  
  https://kubernetes.io/docs/concepts/
- Deployments  
  https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- ConfigMap  
  https://kubernetes.io/docs/concepts/configuration/configmap/
- Secrets  
  https://kubernetes.io/docs/concepts/configuration/secret/
- Configure Liveness, Readiness and Startup Probes  
  https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/
- kubectl Cheat Sheet  
  https://kubernetes.io/docs/reference/kubectl/cheatsheet/
- Good practices for Kubernetes Secrets  
  https://kubernetes.io/docs/concepts/security/secrets-good-practices/

---

次号予告（予定）: **Service / Ingress / NetworkPolicy で学ぶ公開経路と通信制御（Beginner→Advanced）**
