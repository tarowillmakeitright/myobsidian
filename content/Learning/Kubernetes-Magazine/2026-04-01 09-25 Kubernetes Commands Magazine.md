---
tags: [kubernetes, k8s, devops, learning, daily]
---

# Kubernetes Commands Magazine — 2026-04-01 (09:25)
[[Home]]

> 今日の学習アーク: **Beginner → Middle → Advanced**
> テーマは「アプリ開発で使うConfigとデプロイ運用の基礎から実践」

---

## 1) Topic + Level

### 🟢 Beginner
**Topic:** ConfigMap と Secret の基本、`kubectl`で安全に扱う

### 🟡 Middle
**Topic:** Deployment のローリングアップデートとロールバック運用
**前提知識:** Pod / Deployment / ReplicaSet の関係、`kubectl get/describe/logs` が使えること

### 🔴 Advanced
**Topic:** 本番寄りの安全運用（Context確認・適用範囲管理・差分確認）
**前提知識:** Namespace運用、`kubectl apply -f`、`kubectl rollout`、YAMLマニフェスト作成経験

---

## 2) Why it matters for real app development

- **設定の外出し（ConfigMap/Secret）**ができると、コード変更なしで環境差分（dev/stg/prod）を吸収できる。
- **Deployment運用**を理解すると、ゼロダウンタイムに近い更新や障害時の即時ロールバックが可能になる。
- **安全な`kubectl`運用**（context/namespace/差分確認）を習慣化すると、誤爆による本番障害リスクを大幅に減らせる。

---

## 3) Core kubectl / Kubernetes concept explanations

### ConfigMap / Secret
- **ConfigMap**: 非機密設定（例: feature flag、API endpoint）
- **Secret**: 機密情報（例: DB password、API token）
  - ただし Secret は「暗号化済み」と誤解しがち。実体はBase64表現。**etcd暗号化・RBAC・外部Secret管理**を組み合わせる。

### Deployment
- Podを直接管理せず、Deploymentで宣言的に管理。
- `replicas`、`strategy`、`readinessProbe`を設定して安全に更新。

### Rollout / Rollback
- `kubectl rollout status deployment/<name>` で進行監視
- 問題発生時は `kubectl rollout undo deployment/<name>` で戻す

### Context / Namespace
- `kubectl config current-context` を毎回確認
- `-n <namespace>` を明示し、事故範囲を限定

---

## 4) App building での Kubernetes活用（kubernetes.io/docs準拠）

アプリ開発の標準フローに沿うと次の形が実践的です：

1. **アプリ本体は12-factorを意識**し、設定は環境変数/マウントで注入
2. 非機密はConfigMap、機密はSecretへ分離
3. Deploymentで更新戦略を定義（RollingUpdate）
4. readiness/liveness probeを設定して不良Podを自動切替
5. リリース時は`apply`前に差分確認、`rollout status`監視、必要なら`undo`

参考（公式）:
- Overview: https://kubernetes.io/docs/concepts/overview/
- Configuration: https://kubernetes.io/docs/concepts/configuration/
- Secrets: https://kubernetes.io/docs/concepts/configuration/secret/
- Deployments: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- kubectl Cheat Sheet: https://kubernetes.io/docs/reference/kubectl/cheatsheet/

---

## 5) 30–60分 Hands-on Mini Lab

### ゴール
- ConfigMap/Secretを使うDeploymentを作成
- ローリングアップデート→ロールバックを体験
- 安全確認コマンドを習慣化

### 所要時間
約45分

### 手順

#### Step 0: 事前安全チェック（5分）
```bash
kubectl config current-context
kubectl get ns
kubectl config view --minify --output 'jsonpath={..namespace}'; echo
```

> ⚠️ **警告**: 破壊的コマンド（`delete`, `replace --force`, 広範囲`apply`）前に、必ず context / namespace / 対象リソースを再確認。

#### Step 1: Namespace作成（3分）
```bash
kubectl create namespace k8s-mag-lab
```

#### Step 2: ConfigMap/Secret作成（7分）
```bash
kubectl -n k8s-mag-lab create configmap app-config \
  --from-literal=APP_MODE=staging \
  --from-literal=LOG_LEVEL=info

kubectl -n k8s-mag-lab create secret generic app-secret \
  --from-literal=DB_PASSWORD='change-me-strong-password'
```

> ✅ 実運用ではSecret値をシェル履歴に残さない工夫（`--from-file`、CI secret store、External Secrets）を推奨。

#### Step 3: Deployment作成（10分）
`deploy.yaml` を作成:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
  namespace: k8s-mag-lab
spec:
  replicas: 2
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
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
        image: nginx:1.25
        ports:
        - containerPort: 80
        envFrom:
        - configMapRef:
            name: app-config
        - secretRef:
            name: app-secret
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 3
          periodSeconds: 5
```

適用:
```bash
kubectl apply -f deploy.yaml
kubectl -n k8s-mag-lab rollout status deployment/web
```

#### Step 4: 更新とロールバック（10分）
```bash
kubectl -n k8s-mag-lab set image deployment/web nginx=nginx:1.26
kubectl -n k8s-mag-lab rollout status deployment/web
kubectl -n k8s-mag-lab rollout history deployment/web
```

問題を想定してロールバック:
```bash
kubectl -n k8s-mag-lab rollout undo deployment/web
kubectl -n k8s-mag-lab rollout status deployment/web
```

#### Step 5: 観察・確認（5分）
```bash
kubectl -n k8s-mag-lab get pods -o wide
kubectl -n k8s-mag-lab describe deployment web
kubectl -n k8s-mag-lab get events --sort-by=.lastTimestamp | tail -n 20
```

#### Step 6: 片付け（任意・5分）
```bash
kubectl delete namespace k8s-mag-lab
```

> ⚠️ `delete namespace` は配下リソースを全削除します。対象namespaceを再確認してから実行。

---

## 6) Command Cheatsheet

```bash
# 安全確認
kubectl config current-context
kubectl get ns
kubectl -n <ns> get all

# 作成・適用
kubectl -n <ns> create configmap <name> --from-literal=KEY=VALUE
kubectl -n <ns> create secret generic <name> --from-literal=KEY=VALUE
kubectl apply -f <file.yaml>

# 観察
kubectl -n <ns> get pods,deploy,svc
kubectl -n <ns> describe deployment <name>
kubectl -n <ns> logs <pod>

# 更新・復旧
kubectl -n <ns> set image deployment/<name> <container>=<image:tag>
kubectl -n <ns> rollout status deployment/<name>
kubectl -n <ns> rollout history deployment/<name>
kubectl -n <ns> rollout undo deployment/<name>
```

---

## 7) Common mistakes and safe practices

### よくあるミス
1. **Context違いで本番にapply**してしまう
2. `-n` 未指定でdefault namespaceに誤投入
3. SecretをGit管理に入れてしまう
4. `kubectl delete -f .` のような広範囲削除
5. ロールアウト監視せずに「デプロイ成功」と判断

### 安全プラクティス
- 実行前に `current-context` と `namespace` を毎回確認
- `kubectl diff -f` を活用して変更差分を先に確認
- Secretは外部Secret管理（Vault / External Secrets Operator など）を検討
- 本番はRBAC最小権限、監査ログ、etcd暗号化を有効化
- 破壊系コマンド前に「対象」「影響範囲」「ロールバック手順」を口頭確認

---

## 8) Interview-style question

**Q.** Deploymentのローリングアップデート中に一部PodがReadyにならない場合、あなたはどの順番で切り分けますか？

**A（考える観点）:**
1. `rollout status` / `rollout history` で進行状態確認
2. `describe pod` でイベント確認（ImagePull, Probe失敗など）
3. `logs` でアプリ起動エラー確認
4. Probe設定・リソース制限・依存先接続を確認
5. 影響が大きければ `rollout undo` で復旧を優先

---

## 9) Next-step resources（公式優先）

- Kubernetes Documentation (Top): https://kubernetes.io/docs/
- Concepts: https://kubernetes.io/docs/concepts/
- Configuration Best Practices: https://kubernetes.io/docs/concepts/configuration/overview/
- Secrets Good Practices: https://kubernetes.io/docs/concepts/security/secrets-good-practices/
- Deployment: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Probes: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/
- kubectl Cheat Sheet: https://kubernetes.io/docs/reference/kubectl/cheatsheet/

---

### 明日の予告（Progressive Arc）
次号は「Service/Ingressでアプリ公開（Beginner）→ HPAとリソース最適化（Middle）→ PodDisruptionBudgetと可用性設計（Advanced）」を扱います。