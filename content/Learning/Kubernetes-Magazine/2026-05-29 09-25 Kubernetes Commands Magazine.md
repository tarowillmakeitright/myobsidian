---
tags: [kubernetes, k8s, devops, learning, daily]
---

# 2026-05-29 09:25 Kubernetes Commands Magazine

[[Home]]

今日のテーマは **「kubectl apply / diff / rollout を使った安全なデプロイ運用」** です。  
難易度アークは **Beginner → Middle → Advanced** の順で進みます。

---

## 1) Topic + Level

### Beginner
**Topic:** `kubectl get/describe/logs` で状態を読む基礎

### Middle（前提あり）
**Topic:** `kubectl apply` + `kubectl diff` + `kubectl rollout` で安全に更新
**前提:**
- Pod / Deployment / Service の基本概念を知っている
- YAML マニフェストを1回以上書いたことがある
- `kubectl config current-context` の意味が分かる

### Advanced（前提あり）
**Topic:** Progressive Delivery 観点での段階的リリース（RollingUpdateの調整・失敗時ロールバック）
**前提:**
- Deployment の更新フローを理解
- readinessProbe / livenessProbe の役割を説明できる
- `kubectl rollout status/history/undo` を使った経験がある

---

## 2) Why it matters for real app development

実アプリ開発では「動く」だけでなく、**止めずに更新できること** が重要です。  
`kubectl apply` を雑に使うと、意図しない差分適用で障害を起こします。逆に `diff` → `apply` → `rollout status` の流れを守ると、

- 本番のヒューマンエラーを減らせる
- 失敗時に素早く戻せる
- チームで再現可能なデプロイ手順を作れる

という効果があり、開発速度と信頼性を両立できます。

---

## 3) Core kubectl/Kubernetes concept explanations

- **Declarative管理（宣言的）**
  - 「こうあるべき状態」をYAMLで宣言し、Kubernetesが収束させる。
  - 中心コマンド: `kubectl apply -f ...`

- **差分確認**
  - 適用前に差分を見る: `kubectl diff -f ...`
  - 事故防止に非常に有効。

- **Rollout管理**
  - 更新状況確認: `kubectl rollout status deployment/<name>`
  - 履歴確認: `kubectl rollout history deployment/<name>`
  - 失敗時に戻す: `kubectl rollout undo deployment/<name>`

- **Context/Namespaceの明示**
  - 誤クラスタ・誤Namespace適用は典型事故。
  - 実行前に `kubectl config current-context` と `-n <namespace>` を固定。

---

## 4) How Kubernetes is used while building apps（kubernetes.io/docs準拠の実務寄り）

開発中の典型フロー:

1. アプリ更新（コード変更）
2. イメージビルド・タグ付け（immutable tag推奨、例: git SHA）
3. Deployment マニフェストの image 更新
4. `kubectl diff` で変更確認
5. `kubectl apply` で適用
6. `kubectl rollout status` で監視
7. 必要なら `rollout undo`

ベストプラクティス:

- `latest` タグの常用を避ける（追跡不能になる）
- readinessProbe を設定し、準備前トラフィックを防ぐ
- Secret は `Secret` リソース/外部Secret管理で扱い、平文埋め込みを避ける
- 本番前に context と namespace を二重確認

---

## 5) 30-60 minute hands-on mini lab

**目標:** Deploymentを安全に更新し、失敗時にロールバックできるようになる

### 所要時間
40分目安

### 手順

1. **作業前チェック（5分）**
```bash
kubectl config current-context
kubectl get ns
```

2. **Namespace作成（5分）**
```bash
kubectl create namespace magazine-lab
```

3. **初期デプロイ（10分）**
`deploy-v1.yaml`（例）:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
  namespace: magazine-lab
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
        image: nginx:1.25.5
        ports:
        - containerPort: 80
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 3
          periodSeconds: 5
```

```bash
kubectl apply -f deploy-v1.yaml
kubectl rollout status deployment/web -n magazine-lab
kubectl get pods -n magazine-lab
```

4. **更新前に差分確認（10分）**
`nginx:1.25.5` → `nginx:1.26` に変更して:
```bash
kubectl diff -f deploy-v1.yaml
kubectl apply -f deploy-v1.yaml
kubectl rollout status deployment/web -n magazine-lab
```

5. **失敗想定のロールバック演習（10分）**
（意図的に存在しないイメージタグに変更して適用）
```bash
kubectl rollout status deployment/web -n magazine-lab
kubectl rollout history deployment/web -n magazine-lab
kubectl rollout undo deployment/web -n magazine-lab
kubectl rollout status deployment/web -n magazine-lab
```

6. **後片付け（任意）**
```bash
kubectl delete namespace magazine-lab
```
> ⚠️ `delete` は破壊的です。context と対象 namespace を必ず確認してから実行。

---

## 6) Command cheatsheet

```bash
# コンテキスト確認（最重要）
kubectl config current-context

# 名前空間を指定して一覧
kubectl get deploy,pods -n <namespace>

# マニフェスト差分確認
kubectl diff -f <manifest.yaml>

# 適用
kubectl apply -f <manifest.yaml>

# ロールアウト監視
kubectl rollout status deployment/<name> -n <namespace>

# 履歴とロールバック
kubectl rollout history deployment/<name> -n <namespace>
kubectl rollout undo deployment/<name> -n <namespace>

# 詳細/イベント確認
kubectl describe deployment/<name> -n <namespace>
kubectl get events -n <namespace> --sort-by=.metadata.creationTimestamp
```

---

## 7) Common mistakes and safe practices

### よくあるミス
- `kubectl apply -f .` を誤ディレクトリで実行
- 本番contextのまま検証コマンドを実行
- Secret値をYAMLに平文でコミット
- rollout失敗を見ずに「apply成功=デプロイ成功」と誤認

### 安全策
- 実行前ルーティン: `current-context` / `namespace` / `diff`
- `-n <namespace>` を必ず明示
- Secretは平文管理しない（Gitに置かない）
- 破壊的コマンド（delete/replace）前に対象を声出し確認
- 可能なら本番適用前にレビュー（4-eyes）

---

## 8) Interview-style question

**Q.** `kubectl apply` と `kubectl replace` の違いは？ 本番運用で `diff` を挟む理由も説明してください。  
**A.（要点）**
- `apply`: 宣言状態との差分を反映（宣言的運用向き）
- `replace`: リソースを置き換える（意図しない欠落が起きやすい）
- `diff` を挟むことで、適用前に変更の影響範囲を可視化し事故を減らせる

---

## 9) Next-step resources（公式優先）

- Kubernetes Concepts（公式）  
  https://kubernetes.io/docs/concepts/
- Deployments（公式）  
  https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- kubectl Cheat Sheet（公式）  
  https://kubernetes.io/docs/reference/kubectl/cheatsheet/
- Configure Access to Multiple Clusters（公式）  
  https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/
- Secrets Good Practices（公式）  
  https://kubernetes.io/docs/concepts/security/secrets-good-practices/

---

明日の予告: **ConfigMap/Secret/環境変数注入の実践（Beginner→Advanced）**
