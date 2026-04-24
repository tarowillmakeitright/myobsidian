# 2026-04-24 Kubernetes Commands Magazine

Tags: #kubernetes #k8s #devops #learning #daily  
Links: [[Home]]

---

## 今号テーマ: **安全なデプロイ運用を支える `kubectl apply` / `diff` / `rollout`**

学習アーク（段階式）:
- **Beginner**: 宣言的デプロイの基本を理解して安全に反映する
- **Middle**: 変更差分確認と段階的ロールアウトを運用に組み込む
- **Advanced**: 本番を想定した検証・監査・ロールバック戦略を実装する

> ⚠️ 破壊的操作の前に必ず確認:
> - `kubectl config current-context`
> - `kubectl get ns`
> - `kubectl diff -f ...`（先に差分確認）
> - `--namespace` を明示（誤適用防止）
>
> 特に `delete` / `apply -f .` / `-A` は対象スコープ誤り事故が起きやすいです。

---

## 1) Topic + Level

### Beginner
**Topic:** `Deployment` を YAML で作り、`kubectl apply` で反映する

### Middle（前提あり）
**Topic:** `kubectl diff` + `rollout status/history` による安全な更新

**Prerequisites:**
- Beginnerの内容（Deployment作成・apply実行）ができる
- Pod / ReplicaSet / Deployment の関係を説明できる

### Advanced（前提あり）
**Topic:** `set image` / `rollout undo` / `record` 相当の監査情報で復旧性を高める

**Prerequisites:**
- Middleの内容（差分確認・ロールアウト監視）ができる
- 更新失敗時にロールバックが必要な理由を理解している

---

## 2) なぜ実アプリ開発で重要か

- 開発現場では「デプロイそのもの」よりも**安全に更新し続ける運用**が価値になります。
- 宣言的管理（YAML + apply）は、再現性・レビュー性・自動化（CI/CD）に直結します。
- `diff` を挟むだけで、誤った差分投入（replicasの意図しない変更等）を事前検知できます。
- `rollout status` / `undo` は障害時のMTTR短縮（復旧時間短縮）に直結します。

---

## 3) コア概念（kubectl/Kubernetes）

- **宣言的管理（Declarative）**: 「どう作るか」ではなく「あるべき状態」をYAMLで定義。
- **`kubectl apply`**: 既存状態とマニフェストの差分を反映。
- **`kubectl diff`**: 実際に反映する前に変更差分を確認。
- **`Deployment` と `ReplicaSet`**: Deploymentが更新戦略を管理し、ReplicaSetがPod集合を担う。
- **`rollout` 系コマンド**:
  - `status`: 展開完了待ち・監視
  - `history`: リビジョン確認
  - `undo`: 問題時に前リビジョンへ戻す

---

## 4) アプリ開発時のベストプラクティス（kubernetes.io/docs 準拠）

- **apply前に diff** をルール化し、レビューで差分を確認。
- **namespace明示** (`-n app-dev`) で誤環境反映を防止。
- **イメージタグ固定**（`latest`回避）で再現性担保。
- **Secretを平文でコミットしない**（Secret/外部シークレット管理を利用）。
- **小さく段階的に変更**（複数要素を一度に変えない）。
- **ロールアウト監視を自動化**（CIで `rollout status` まで確認）。

---

## 5) 30〜60分ミニラボ（実践）

### ゴール
Nginx Deploymentを安全に更新し、失敗時にロールバックする。

### 所要時間
40分目安

### 手順

1. **作業用Namespace作成**
```bash
kubectl create namespace k8s-mag-lab
kubectl config current-context
```

2. **初期Deployment作成（nginx:1.25.5）**
`deploy.yaml`:
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
          image: nginx:1.25.5
          ports:
            - containerPort: 80
```

適用:
```bash
kubectl diff -f deploy.yaml
kubectl apply -f deploy.yaml
kubectl rollout status deployment/web -n k8s-mag-lab
```

3. **更新（nginx:1.27.0）して差分確認**
- `deploy.yaml` のimageを `nginx:1.27.0` に変更
```bash
kubectl diff -f deploy.yaml
kubectl apply -f deploy.yaml
kubectl rollout status deployment/web -n k8s-mag-lab
kubectl rollout history deployment/web -n k8s-mag-lab
```

4. **意図的に不正タグで失敗を体験**
```bash
kubectl set image deployment/web nginx=nginx:not-a-real-tag -n k8s-mag-lab
kubectl rollout status deployment/web -n k8s-mag-lab
```
失敗を確認後、ロールバック:
```bash
kubectl rollout undo deployment/web -n k8s-mag-lab
kubectl rollout status deployment/web -n k8s-mag-lab
```

5. **後片付け（注意して実行）**
```bash
kubectl delete namespace k8s-mag-lab
```
> ⚠️ `delete` は対象確認必須。`current-context` と namespace を必ず再確認。

---

## 6) Command Cheatsheet

```bash
# 文脈確認
kubectl config current-context
kubectl config get-contexts

# 差分→適用
kubectl diff -f deploy.yaml
kubectl apply -f deploy.yaml

# 状態確認
kubectl get deploy,pods -n k8s-mag-lab
kubectl describe deployment web -n k8s-mag-lab

# ロールアウト管理
kubectl rollout status deployment/web -n k8s-mag-lab
kubectl rollout history deployment/web -n k8s-mag-lab
kubectl rollout undo deployment/web -n k8s-mag-lab

# 迅速なイメージ更新
kubectl set image deployment/web nginx=nginx:1.27.0 -n k8s-mag-lab
```

---

## 7) よくあるミス & 安全策

- **ミス:** `kubectl apply -f .` をルートで実行して意図外リソースまで反映
  - **安全策:** 明示ファイル指定（例: `-f k8s/deploy.yaml`）
- **ミス:** context確認せず本番へ適用
  - **安全策:** 実行前に `kubectl config current-context` を習慣化
- **ミス:** Secret値をYAMLに直書きしてGitへpush
  - **安全策:** Secret管理を分離（Kubernetes Secret + 外部マネージャ）
- **ミス:** 失敗時の戻し手順未整備
  - **安全策:** `rollout history/undo` を運用手順書に明記

---

## 8) 面接っぽい一問

**Q. `kubectl apply` と `kubectl replace` の違いは？実運用で `apply` が好まれる理由は？**

**A（要点）:**
- `apply` は宣言的で差分更新に向き、GitOps/CIに統合しやすい。
- `replace` はオブジェクト全置換に近く、意図しないフィールド消失リスクがある。
- 実運用は「差分管理・監査・再現性」が重要なため、通常は `apply` ベース。

---

## 9) 次の学習リソース（公式優先）

- Kubernetes Objects 概要:  
  https://kubernetes.io/docs/concepts/overview/working-with-objects/
- Declarative 設定管理:  
  https://kubernetes.io/docs/tasks/manage-kubernetes-objects/declarative-config/
- Deployment 概要:  
  https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- kubectl cheat sheet:  
  https://kubernetes.io/docs/reference/kubectl/cheatsheet/
- Secret の扱い:  
  https://kubernetes.io/docs/concepts/configuration/secret/

---

### 明日の予告（学習アーク継続）
**Service / Ingress / Probes を使った「到達性と健全性」の実践運用（Beginner→Advanced）**
