---
tags: [kubernetes, k8s, devops, learning, daily]
---

# Kubernetes Commands Magazine — 2026-03-15 (09:25)
[[Home]]

> 今日の学習アーク: **Beginner → Middle → Advanced**
> テーマ: **アプリ開発で必須の「デプロイ確認と安全な更新」**

---

## 1) Topic + Level

### 🟢 Beginner
**Topic:** Pod / Deployment の状態を `kubectl` で読む

### 🟡 Middle（前提あり）
**Topic:** Rolling Update と Rollout 管理
**前提:**
- Pod / Deployment / Service の基本を理解している
- `kubectl get/describe/logs` を使ったことがある

### 🔴 Advanced（前提あり）
**Topic:** 本番想定の安全な変更運用（context/namespace/差分確認）
**前提:**
- Rolling Update / Rollback の基本
- namespace と kubeconfig context の概念
- CI/CD で `kubectl apply` を扱う基礎経験

---

## 2) Why it matters for real app development

- 開発現場では「動いた」よりも **安全に更新できるか** が重要。
- バグ修正・セキュリティパッチ適用時に、無停止に近い更新（Rolling Update）が必要。
- `kubectl` の読み方・更新手順を誤ると、**別クラスタや別namespaceへ誤適用** しやすい。
- 小さな確認（context確認、dry-run、diff）が、障害・情報漏えい・停止事故を大幅に減らす。

---

## 3) Core kubectl/Kubernetes concept explanations

### Deployment
- ReplicaSet を通じて Pod の desired state を維持する。
- イメージ変更時に rollout が走り、段階的に新Podへ置き換える。

### Service
- Pod の入れ替わりを隠蔽し、安定したアクセス先を提供する。

### Rollout
- `kubectl rollout status/history/undo` で更新状況・履歴・ロールバックを管理。

### Context / Namespace
- `kubectl config current-context` で接続先クラスタ確認。
- `-n <namespace>` を明示し、誤爆を防ぐ。

### apply / diff / dry-run
- `kubectl diff -f` で差分確認。
- `kubectl apply --server-side --dry-run=server -f` でサーバ検証。
- 問題なければ `kubectl apply -f`。

---

## 4) How Kubernetes is used while building apps（kubernetes.io/docs best practices準拠）

アプリ開発の実務では、次の流れが定番です。

1. **マニフェストをGitで管理**（宣言的構成）
2. 変更前に **context/namespaceを確認**
3. `kubectl diff` + `dry-run` で事前検証
4. `kubectl apply` で反映
5. `kubectl rollout status` と `kubectl logs` で検証
6. 異常時は `kubectl rollout undo` で迅速復旧

ベストプラクティス:
- Secret値をマニフェストへ平文で埋め込まない
- `latest` タグ固定を避け、追跡可能なタグ（例: `v1.2.3`）を使う
- 本番は readiness/liveness probe と resources requests/limits を設定
- `kubectl delete` は対象を絞って実行（`-n`, `-l`, `--context`）

---

## 5) 30-60 minute hands-on mini lab

**ラボ名:** 「Nginxアプリを安全に更新してロールバックする」

> 目安: 40分

### Step 0: 事前安全確認（5分）
```bash
kubectl config current-context
kubectl get ns
kubectl create ns mag-lab
```

### Step 1: 初回デプロイ（10分）
`deployment.yaml`（例）:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
  namespace: mag-lab
spec:
  replicas: 3
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
        image: nginx:1.25.5
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: web-svc
  namespace: mag-lab
spec:
  selector:
    app: web
  ports:
  - port: 80
    targetPort: 80
```

```bash
kubectl apply --server-side --dry-run=server -f deployment.yaml
kubectl diff -f deployment.yaml
kubectl apply -f deployment.yaml
kubectl -n mag-lab get pods,svc
```

### Step 2: ローリングアップデート（10分）
```bash
kubectl -n mag-lab set image deploy/web nginx=nginx:1.27.0
kubectl -n mag-lab rollout status deploy/web
kubectl -n mag-lab rollout history deploy/web
```

### Step 3: 障害想定 & ロールバック（10分）
あえて存在しないタグを設定して失敗を体験：
```bash
kubectl -n mag-lab set image deploy/web nginx=nginx:9.99-doesnotexist
kubectl -n mag-lab rollout status deploy/web --timeout=60s
kubectl -n mag-lab get pods
kubectl -n mag-lab rollout undo deploy/web
kubectl -n mag-lab rollout status deploy/web
```

### Step 4: 後片付け（5分）
```bash
# 破壊的操作: 実行前に context/namespace を再確認
kubectl config current-context
kubectl delete ns mag-lab
```

---

## 6) Command cheatsheet

```bash
# 安全確認
kubectl config current-context
kubectl config get-contexts
kubectl get ns

# 観測
kubectl get pods -A
kubectl -n <ns> describe deploy/<name>
kubectl -n <ns> logs deploy/<name> --tail=100

# 反映前チェック
kubectl diff -f <file.yaml>
kubectl apply --server-side --dry-run=server -f <file.yaml>

# 反映
kubectl apply -f <file.yaml>

# 更新運用
kubectl -n <ns> set image deploy/<name> <container>=<image:tag>
kubectl -n <ns> rollout status deploy/<name>
kubectl -n <ns> rollout history deploy/<name>
kubectl -n <ns> rollout undo deploy/<name>

# 破壊的操作（要注意）
kubectl -n <ns> delete <resource>/<name>
```

---

## 7) Common mistakes and safe practices

### よくあるミス
1. `kubectl apply -f .` をルートで実行して想定外の資源を反映
2. context確認せず本番クラスタへ適用
3. namespace未指定でdefaultに作成
4. SecretをGitにコミット（平文）
5. `:latest` で再現不能なデプロイ

### 安全プラクティス
- 反映前に必ず：
  1) `kubectl config current-context`
  2) `kubectl diff -f ...`
  3) `--dry-run=server`
- `-n` を常につける（alias化してもよい）
- Secretは `Secret` リソース + 外部秘匿管理（KMS/External Secrets等）で管理
- 破壊的コマンド（delete, replace, applyの広範囲実行）は対象とスコープを口に出して確認

⚠️ **警告:** `kubectl delete ns <name>` や `kubectl delete -f` は破壊的です。実行前に context/namespace/対象ファイルを再確認してください。

---

## 8) One interview-style question

**Q.** Deployment の Rolling Update 中に一部Podが起動失敗し続けています。ユーザー影響を最小化しながら原因調査と復旧を行う手順を説明してください。

**期待される観点（要点）:**
- rollout status / history で状況把握
- describe / events / logs で原因特定
- readiness probe・イメージタグ・環境変数・リソース設定の確認
- 速やかな rollback (`rollout undo`) の判断
- 再発防止（事前diff/dry-run、段階リリース、監視）

---

## 9) Next-step resources（公式中心）

- Kubernetes Documentation (Home)
  - https://kubernetes.io/docs/home/
- Deployments
  - https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- kubectl Overview
  - https://kubernetes.io/docs/reference/kubectl/
- Configure Access to Multiple Clusters
  - https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/
- Secrets
  - https://kubernetes.io/docs/concepts/configuration/secret/
- Probes (Liveness/Readiness/Startup)
  - https://kubernetes.io/docs/concepts/configuration/liveness-readiness-startup-probes/
- Resource Management for Pods and Containers
  - https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/

---

次号予告（学習アーク継続）:
- Beginner: ConfigMap と環境変数注入
- Middle: Secret と External Secrets の運用設計
- Advanced: HPA + requests/limits を使ったスケーリング最適化
