---
tags:
  - kubernetes
  - k8s
  - devops
  - learning
  - daily
---

# Daily Kubernetes Commands Magazine - 2026-03-27
[[Home]]

#kubernetes #k8s #devops #learning #daily

本日のテーマは **「ConfigMap / Secret / Deployment を使った安全なアプリ設定運用」** です。  
難易度を **Beginner → Middle → Advanced** の学習アークで進めます。

---

## 1) Topic + Level

### Beginner
**Topic:** ConfigMap と Deployment の基本（環境変数注入）

### Middle
**Topic:** Secret の安全な利用とローリングアップデート
**前提知識:**
- Pod / Deployment の基本
- `kubectl get/describe/logs` を使った確認
- ConfigMap の基本利用

### Advanced
**Topic:** kustomize で環境差分を管理しつつ安全に apply
**前提知識:**
- Secret と ConfigMap の違い
- Deployment の更新戦略（RollingUpdate）
- `kubectl apply -k` の基本

---

## 2) Why it matters for real app development

実運用では「コード」と同じくらい「設定管理」が重要です。  
API エンドポイント、機能フラグ、DB接続情報などをコンテナイメージに埋め込むと、環境ごとの差し替えやセキュリティ事故が起きやすくなります。

- **ConfigMap:** 機密ではない設定（例: `APP_MODE`, `FEATURE_X_ENABLED`）
- **Secret:** 機密情報（例: APIトークン、パスワード）
- **Deployment:** 安全に段階的更新（ダウンタイム最小化）

これらを正しく使えると、開発速度と運用安全性が同時に上がります。

---

## 3) Core kubectl / Kubernetes concepts

### ConfigMap
- 機密でない設定値を分離管理
- Podへ環境変数 or ファイルとして注入可能

```bash
kubectl create configmap app-config --from-literal=APP_MODE=production
kubectl get configmap app-config -o yaml
```

### Secret
- base64 は暗号化ではない（可読化可能）
- 取り扱いは最小権限・最小露出が基本

```bash
kubectl create secret generic app-secret --from-literal=API_TOKEN='replace-me'
kubectl get secret app-secret -o yaml
```

### Deployment
- Desired State を宣言し、ローリング更新を実行

```bash
kubectl apply -f deployment.yaml
kubectl rollout status deployment/web
kubectl rollout history deployment/web
```

---

## 4) App development での実践利用（kubernetes.io/docs ベストプラクティス準拠）

- **イメージに設定を書き込まない**（設定は ConfigMap/Secret へ）
- **Secret を Git に平文でコミットしない**
- **`kubectl apply` 前に対象を確認**
  - `kubectl config current-context`
  - `kubectl -n <namespace> get all`
- **小さく安全に更新**（1つずつ変更→`rollout status` で確認）
- **Namespace を分離**（dev/stg/prod）
- **`kubectl diff` 活用** で変更差分を事前確認

---

## 5) 30-60分ハンズオン mini lab

### ゴール
Nginx Deployment に ConfigMap/Secret を注入し、設定変更時の挙動を確認する。

### 手順（45分想定）

#### 0. 事前安全確認（5分）
```bash
kubectl config current-context
kubectl get ns
```

> ⚠️ **注意:** 本番コンテキストで実行しない。学習用クラスター（kind/minikube/dev namespace）で実施。

#### 1. namespace 作成（3分）
```bash
kubectl create ns k8s-mag-lab
kubectl config set-context --current --namespace=k8s-mag-lab
```

#### 2. ConfigMap/Secret 作成（7分）
```bash
kubectl create configmap web-config --from-literal=APP_MODE=dev
kubectl create secret generic web-secret --from-literal=API_TOKEN='dummy-token'
```

#### 3. Deployment 適用（10分）
`deployment.yaml`（手元に作成）:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
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
        env:
        - name: APP_MODE
          valueFrom:
            configMapKeyRef:
              name: web-config
              key: APP_MODE
        - name: API_TOKEN
          valueFrom:
            secretKeyRef:
              name: web-secret
              key: API_TOKEN
```

```bash
kubectl apply -f deployment.yaml
kubectl rollout status deployment/web
kubectl get pods -o wide
```

#### 4. 値変更と再デプロイ確認（10分）
```bash
kubectl create configmap web-config --from-literal=APP_MODE=prod -o yaml --dry-run=client | kubectl apply -f -
kubectl rollout restart deployment/web
kubectl rollout status deployment/web
```

#### 5. 後片付け（任意、5分）
```bash
# ⚠️ 削除前に対象namespaceを必ず確認
kubectl config view --minify --output 'jsonpath={..namespace}'
kubectl delete ns k8s-mag-lab
```

---

## 6) Command cheatsheet

```bash
# 現在のコンテキスト確認
kubectl config current-context

# namespace 操作
kubectl get ns
kubectl create ns <name>

# ConfigMap / Secret
kubectl create configmap <name> --from-literal=KEY=VALUE
kubectl create secret generic <name> --from-literal=KEY=VALUE
kubectl get configmap <name> -o yaml
kubectl get secret <name> -o yaml

# Deployment
kubectl apply -f deployment.yaml
kubectl get deploy,pods
kubectl describe deployment <name>
kubectl rollout status deployment/<name>
kubectl rollout history deployment/<name>
kubectl rollout restart deployment/<name>

# 差分確認（安全）
kubectl diff -f deployment.yaml
```

---

## 7) Common mistakes and safe practices

### よくあるミス
1. **Secret を Git に平文コミット**
2. **`default` namespace に何でも作る**
3. **コンテキスト未確認で `kubectl delete` / `apply`**
4. **`kubectl apply -f .` で意図しないリソースまで適用**

### 安全プラクティス
- `kubectl config current-context` を実行してから操作
- `-n <namespace>` を明示
- `kubectl diff` → `kubectl apply` の順
- 破壊的コマンド前に対象を声出し確認（context / namespace / resource）
- Secret は外部 secret manager（例: External Secrets, CSI Secret Store）連携を検討

---

## 8) Interview-style question

**Q.** ConfigMap と Secret の違いは何ですか？また、Secret を使っていれば完全に安全と言えますか？

**A.（要点）**
- ConfigMap は非機密設定、Secret は機密用途
- ただし Secret の base64 は暗号化ではない
- etcd 暗号化、RBAC、監査ログ、外部 secret manager 連携まで含めて設計して初めて実運用で安全性が高まる

---

## 9) Next-step resources（公式優先）

- ConfigMap: https://kubernetes.io/docs/concepts/configuration/configmap/
- Secret: https://kubernetes.io/docs/concepts/configuration/secret/
- Deployments: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Configure Pod with ConfigMap: https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/
- Distribute credentials securely: https://kubernetes.io/docs/tasks/inject-data-application/distribute-credentials-secure/
- Kustomize: https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/
- kubectl cheat sheet: https://kubernetes.io/docs/reference/kubectl/cheatsheet/

---

次号予告（学習アーク継続）:  
**Beginner:** Service / ClusterIP 基礎  
**Middle:** Ingress + TLS の入口設計  
**Advanced:** HPA + requests/limits + metrics-server による自動スケール
