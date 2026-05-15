---
tags: [kubernetes, k8s, devops, learning, daily]
---

# 2026-05-15 09:25 Kubernetes Commands Magazine
[[Home]]

## 今日のテーマ
**ConfigMapとSecretを使った安全な設定管理（Beginner → Middle → Advanced）**

---

## 1) Topic + Level

### Beginner
**Topic:** ConfigMapの基本（アプリ設定をイメージから分離する）

### Middle
**Topic:** Secretの安全な利用（環境変数/Volumeマウント）
**Prerequisites:**
- Pod / Deployment の基本がわかる
- `kubectl get/describe/logs/apply` が使える
- YAMLの基本構文を読める

### Advanced
**Topic:** 本番運用を意識した設定更新戦略（ロールアウト・監査・誤操作防止）
**Prerequisites:**
- Deploymentのローリングアップデートを理解している
- Namespace運用の基本を理解している
- RBAC/最小権限の考え方を知っている

---

## 2) なぜ実アプリ開発で重要か

- アプリの設定値（APIエンドポイント、feature flag等）をコンテナイメージに焼き込むと、環境差分（dev/stg/prod）に弱くなる。
- Secret（トークン、パスワード等）をGitに直書きすると漏えいリスクが極めて高い。
- 設定変更時に安全にロールアウトできるかどうかで、障害確率と復旧速度が変わる。

実務では「**設定の外出し + 秘密情報の保護 + 変更の安全適用**」が必須。

---

## 3) Core kubectl / Kubernetes コンセプト

- **ConfigMap**: 非機密な設定データをKey-Valueで保持。
- **Secret**: 機密データを保持（ただしbase64は暗号化ではない）。
- **Namespace**: リソース分離単位。誤apply/誤delete防止にも重要。
- **Deployment**: Podの望ましい状態を管理。設定更新時のロールアウト管理に使う。
- **kubectl context / namespace**: 操作先クラスタ・名前空間の確認は事故防止の最重要ポイント。

よく使う確認:
```bash
kubectl config current-context
kubectl config view --minify --output 'jsonpath={..namespace}' ; echo
```

---

## 4) アプリ開発時のKubernetes利用（kubernetes.io/docs準拠の実践）

- 設定はConfigMap/Secretへ分離し、Deploymentから参照。
- Secretは平文でリポジトリに置かない（Sealed Secrets/External Secrets等も検討）。
- `kubectl apply -f` は**対象ファイル/namespace/contextを毎回確認**。
- 変更は段階的にロールアウトし、`kubectl rollout status` で完了確認。
- 本番ではRBACで書き込み権限を最小化。

---

## 5) 30-60分ミニラボ

### Goal
ConfigMap/Secretを使ってアプリ設定を外出しし、安全に更新確認する。

### 手順

#### Step 0: 事前安全確認（5分）
```bash
kubectl config current-context
kubectl get ns
```
作業用namespace作成:
```bash
kubectl create ns k8s-mag-lab
kubectl config set-context --current --namespace=k8s-mag-lab
kubectl config view --minify --output 'jsonpath={..namespace}' ; echo
```

#### Step 1: ConfigMap作成（10分）
```bash
kubectl create configmap app-config \
  --from-literal=APP_MODE=development \
  --from-literal=LOG_LEVEL=info
kubectl get configmap app-config -o yaml
```

#### Step 2: Secret作成（10分）
> 注意: 実運用ではCLI履歴に残るため、より安全な投入方法（外部Secret管理/CI注入）を推奨。
```bash
kubectl create secret generic app-secret \
  --from-literal=DB_PASSWORD='change-me-now'
kubectl get secret app-secret
```

#### Step 3: Deployment作成（10-15分）
`lab-deploy.yaml` を作成して適用:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-demo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: app-demo
  template:
    metadata:
      labels:
        app: app-demo
    spec:
      containers:
      - name: app
        image: nginx:1.27
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
```

```bash
kubectl apply -f lab-deploy.yaml
kubectl rollout status deploy/app-demo
kubectl get pods -o wide
```

#### Step 4: 設定変更と反映確認（10分）
```bash
kubectl patch configmap app-config -p '{"data":{"LOG_LEVEL":"debug"}}'
kubectl rollout restart deploy/app-demo
kubectl rollout status deploy/app-demo
```

#### Step 5: 後片付け（任意・5分）
⚠️ 削除コマンドは対象namespaceを必ず確認してから:
```bash
kubectl config view --minify --output 'jsonpath={..namespace}' ; echo
kubectl delete ns k8s-mag-lab
```

---

## 6) Command Cheatsheet

```bash
# context / namespace確認
kubectl config current-context
kubectl config view --minify --output 'jsonpath={..namespace}' ; echo

# ConfigMap / Secret
kubectl create configmap <name> --from-literal=key=value
kubectl create secret generic <name> --from-literal=key='value'
kubectl get configmap,secret
kubectl describe configmap <name>
kubectl describe secret <name>

# Deployment
kubectl apply -f <file>.yaml
kubectl get deploy,pods
kubectl rollout status deploy/<name>
kubectl rollout restart deploy/<name>

# Debug
kubectl logs deploy/<name>
kubectl describe pod <pod-name>
```

---

## 7) よくあるミス & 安全プラクティス

### よくあるミス
- `default` namespaceに誤ってapplyしてしまう
- 別クラスタcontextのまま操作してしまう
- SecretをGitへコミットしてしまう
- `kubectl delete -f .` など広範囲コマンドを無確認で実行

### 安全プラクティス
- 実行前に毎回 `current-context` と `namespace` を確認
- 破壊的操作前に `kubectl get` で対象を目視確認
- Secretはマニフェスト直書きを避け、秘密情報管理基盤を使う
- `apply` 対象をディレクトリ丸ごとではなく、意図したファイルに限定
- 本番権限はRBACで最小化

---

## 8) 面接スタイル質問（1問）

**Q. ConfigMapとSecretの違いは何ですか？また、Secretを使っていても追加で考慮すべきセキュリティ対策は？**

（期待される観点: 用途の違い、base64は暗号化でない点、etcd暗号化、RBAC、外部Secret管理、監査ログ）

---

## 9) 次の学習リソース（公式優先）

- Kubernetes Concepts: ConfigMap  
  https://kubernetes.io/docs/concepts/configuration/configmap/
- Kubernetes Concepts: Secret  
  https://kubernetes.io/docs/concepts/configuration/secret/
- Configure a Pod to Use a ConfigMap  
  https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/
- Distribute Credentials Securely Using Secrets  
  https://kubernetes.io/docs/tasks/inject-data-application/distribute-credentials-secure/
- Deployment / Rolling Updates  
  https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Good Practices for Kubernetes Secrets  
  https://kubernetes.io/docs/concepts/security/secrets-good-practices/

---

次号予告: **Service / Ingress / NetworkPolicyで「つながるけど守る」設計（Beginner→Advanced）**