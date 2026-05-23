---
tags: [kubernetes, k8s, devops, learning, daily]
---

# 2026-05-23 09:25 Kubernetes Commands Magazine
[[Home]]

#kubernetes #k8s #devops #learning #daily

今日の学習アークは **Beginner → Middle → Advanced** の3段階です。
テーマは一貫して **「安全に状況把握して、最小リスクで変更する」**。

---

## 1) Topic + Level

### Beginner
**Topic:** `kubectl get / describe / logs` でワークロードを安全に観測する

### Middle
**Topic:** Deployment の更新戦略（RollingUpdate）と `rollout` 操作
**Prerequisites:**
- Pod / Deployment の基本
- `kubectl get/describe/logs` でトラブル確認できる
- YAML の基本構文が読める

### Advanced
**Topic:** ConfigMap/Secret を使った設定分離 + `kubectl diff`/`--dry-run` による安全デプロイ
**Prerequisites:**
- Deployment の更新とロールバック経験
- namespace/context の概念理解
- CI/CD で `apply` したことがある（手動でも可）

---

## 2) Why it matters for real app development

- 開発現場では「まず壊れている原因を正確に掴む」ことが最優先。`get/describe/logs` はその基礎体力。  
- 本番更新は「止めない」「すぐ戻せる」が重要。Deployment の rollout 管理は実運用の中核。  
- 設定や機密情報をイメージに埋め込むと漏洩リスクが上がる。ConfigMap/Secret 分離と事前差分確認は、セキュリティと再現性の両方に効く。

---

## 3) Core kubectl/Kubernetes concept explanations

- **Namespace**: リソースを論理分離する単位。`-n` 指定忘れは事故の元。  
- **Context**: どのクラスタ/ユーザー/namespace を対象にするか。実行前に `kubectl config current-context` を確認。  
- **Deployment**: 宣言的に desired state（望ましい状態）を管理。ローリング更新・履歴・ロールバック可能。  
- **Pod**: 最小実行単位。通常は直接作り込まず、Deployment 経由で管理。  
- **ConfigMap / Secret**: 設定値と機密値を分離。Secret も平文管理せず、アクセス制御と暗号化を前提に扱う。

---

## 4) How Kubernetes is used while building apps (kubernetes.io/docs aligned)

実装フローの実務パターン:

1. **ローカルでコンテナ化**（例: APIサーバ）  
2. **Deployment + Service をマニフェスト化**（宣言的管理）  
3. **設定は ConfigMap、秘密は Secret** に分離  
4. `kubectl diff` / `kubectl apply --dry-run=server -f ...` で事前検証  
5. `kubectl apply -f ...` で反映し、`rollout status` で健全性確認  
6. 障害時は `describe` / `logs` で原因把握し、必要なら `rollout undo`

これは公式ドキュメントの「宣言的構成」「段階的更新」「設定と機密情報の分離」のベストプラクティスに沿う。

---

## 5) 30-60 minute hands-on mini lab

**目標:** nginx Deployment を安全に更新し、問題発生時にロールバックする

### 0. 事前安全確認（5分）
```bash
kubectl config current-context
kubectl get ns
```

> ⚠️ **重要:** いきなり `kubectl apply -f .` や `kubectl delete -f .` を実行しない。  
> 対象クラスタ・対象namespace・対象ファイルを毎回確認する。

### 1. 専用 namespace 作成（5分）
```bash
kubectl create ns k8s-mag-lab
kubectl config set-context --current --namespace=k8s-mag-lab
kubectl get ns
```

### 2. Deployment 作成（10分）
`deploy.yaml` を作成:
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
        image: nginx:1.25
        ports:
        - containerPort: 80
```

適用:
```bash
kubectl apply -f deploy.yaml
kubectl get deploy,pod
kubectl rollout status deploy/web
```

### 3. 観測コマンド練習（10分）
```bash
kubectl describe deploy web
kubectl get pod -l app=web
kubectl logs deploy/web --tail=50
```

### 4. ローリング更新（10分）
```bash
kubectl set image deploy/web nginx=nginx:1.27
kubectl rollout status deploy/web
kubectl rollout history deploy/web
```

### 5. 意図的に失敗してロールバック（10-15分）
```bash
kubectl set image deploy/web nginx=nginx:does-not-exist
kubectl rollout status deploy/web --timeout=60s
kubectl get pod
kubectl describe pod <失敗Pod名>
kubectl rollout undo deploy/web
kubectl rollout status deploy/web
```

### 6. 後片付け（任意）
```bash
kubectl config set-context --current --namespace=default
kubectl delete ns k8s-mag-lab
```

> ⚠️ `delete ns` は破壊的操作。対象が lab であることを再確認してから実行。

---

## 6) Command cheatsheet

```bash
# 現在の対象確認
kubectl config current-context
kubectl config view --minify

# 一覧・詳細・ログ
kubectl get all -n <ns>
kubectl describe pod <pod> -n <ns>
kubectl logs <pod> -n <ns> --tail=100

# デプロイ更新と確認
kubectl apply -f <file>.yaml
kubectl diff -f <file>.yaml
kubectl apply --dry-run=server -f <file>.yaml
kubectl rollout status deploy/<name>
kubectl rollout history deploy/<name>
kubectl rollout undo deploy/<name>

# イメージ更新
kubectl set image deploy/<name> <container>=<image>:<tag>
```

---

## 7) Common mistakes and safe practices

**よくあるミス**
- context/namespace を確認せず本番に `apply` してしまう
- `latest` タグ運用で再現不能になる
- Secret を Git に平文コミットする
- `kubectl delete` を広いスコープで実行する（例: `-A`, `all`）

**安全プラクティス**
- 実行前に **current-context / namespace / 対象ファイル** を声出し確認
- 変更前に `kubectl diff` と `--dry-run=server`
- イメージは固定タグ（または digest）
- Secret は外部シークレット管理（KMS/Vault/Sealed Secrets 等）とRBAC最小権限
- 破壊的コマンド前にはバックアップと対象絞り込み

---

## 8) Interview-style question

**Q.** `kubectl apply` と `kubectl replace` の違いは？本番運用で `apply` が好まれる理由を説明してください。  
**A（要点）:** `apply` は宣言的で差分ベース管理（フィールド管理）に向き、継続的な更新・GitOps との相性が良い。`replace` はオブジェクト全置換で、意図しないフィールド消失リスクがある。

---

## 9) Next-step resources (official docs 중심)

- Kubernetes Documentation Home  
  https://kubernetes.io/docs/home/
- Overview: Kubernetes Components  
  https://kubernetes.io/docs/concepts/overview/components/
- Workloads: Deployments  
  https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- kubectl Overview  
  https://kubernetes.io/docs/reference/kubectl/
- Debug Running Pods  
  https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/
- Configure a Pod to Use a ConfigMap  
  https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/
- Distribute Credentials Securely Using Secrets  
  https://kubernetes.io/docs/tasks/inject-data-application/distribute-credentials-secure/
- Good Practices for Kubernetes Secrets  
  https://kubernetes.io/docs/concepts/security/secrets-good-practices/

---

次号予告（学習アーク継続）:
- Beginner: probes（liveness/readiness/startup）
- Middle: requests/limits と HPA 基礎
- Advanced: multi-container Pod と sidecar 運用設計
