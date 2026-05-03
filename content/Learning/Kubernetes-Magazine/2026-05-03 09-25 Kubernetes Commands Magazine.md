# Daily Kubernetes Commands Magazine

#kubernetes #k8s #devops #learning #daily
[[Home]]

- 日付: 2026-05-03
- テーマ: **kubectl で始める安全なアプリ運用入門（デプロイ〜調査〜更新）**
- 学習アーク: **Beginner → Middle → Advanced**

---

## 1) Topic + Level

### Beginner
**Topic:** `kubectl` の基本操作（`get/describe/logs/apply`）でアプリ状態を把握する

### Middle
**Topic:** Rolling Update と Rollback を安全に扱う
**Prerequisites:**
- `Deployment` / `Pod` / `Service` の基本理解
- `kubectl get/describe/logs` を使った調査経験

### Advanced
**Topic:** ラベル・セレクタ・`kubectl diff`・`--dry-run` を使った変更管理（GitOps前提の実務運用）
**Prerequisites:**
- Deployment の更新フロー理解（`set image`, `rollout status`, `rollout undo`）
- YAML マニフェスト編集経験
- 本番/検証クラスターのコンテキスト分離の重要性を理解

---

## 2) Why it matters for real app development

Kubernetes 実務では「動かす」よりも「安全に変える」ことが重要です。特にアプリ開発では以下が頻発します。

- 新機能リリース時の段階的更新
- 障害時の原因切り分け（Pod ログ、イベント、ヘルスチェック）
- 急ぎのロールバック
- 誤操作防止（別クラスターに apply / delete してしまう事故）

この号の内容は、**開発速度を落とさずに事故率を下げる**ための実践コマンドセットです。

---

## 3) Core kubectl/Kubernetes concepts

- **Namespace**: リソースを論理分離する単位。開発・検証・本番を分ける基本。
- **Context**: `kubectl` が向くクラスター/ユーザー情報。誤 apply の主因になりやすい。
- **Deployment**: 宣言的に Pod の望ましい状態を管理する。
- **Rolling Update**: 稼働を止めずに新バージョンへ置き換える更新方式。
- **Rollback**: 更新失敗時に前リビジョンへ戻す。
- **Dry-run / Diff**: 実適用前に変更影響を確認する安全策。

---

## 4) App開発での使い方（kubernetes.io/docs ベストプラクティス準拠）

1. **まず context/namespace を固定してから操作**
   - `kubectl config current-context`
   - `kubectl -n <ns> ...` を徹底
2. **宣言的管理（YAML）を優先**
   - `kubectl apply -f` と `kubectl diff -f` を組み合わせる
3. **更新時は rollout 監視を必須化**
   - `kubectl rollout status deployment/<name>`
4. **障害調査はイベント・ログ・describe の3点セット**
5. **Secret を平文で Git に置かない**
   - `Secret` でも base64 は暗号化ではない点に注意

---

## 5) 30-60分ミニラボ（安全版）

> 想定: ローカル検証クラスター（kind / minikube / Docker Desktop Kubernetes）
> 本番クラスターで実施しないこと。

### Step 0: 事前安全確認（5分）
```bash
kubectl config current-context
kubectl get ns
```
- 想定外コンテキストなら **停止**。

### Step 1: Namespace と Deployment 作成（10分）
```bash
kubectl create ns k8s-mag
kubectl -n k8s-mag create deployment web --image=nginx:1.25
kubectl -n k8s-mag expose deployment web --port=80 --type=ClusterIP
kubectl -n k8s-mag get all
```

### Step 2: 状態確認（10分）
```bash
kubectl -n k8s-mag describe deployment web
kubectl -n k8s-mag get pods -o wide
kubectl -n k8s-mag logs deploy/web --tail=50
kubectl -n k8s-mag get events --sort-by=.lastTimestamp | tail -n 20
```

### Step 3: Rolling Update（10分）
```bash
kubectl -n k8s-mag set image deployment/web nginx=nginx:1.26
kubectl -n k8s-mag rollout status deployment/web
kubectl -n k8s-mag rollout history deployment/web
```

### Step 4: 意図的に戻す（Rollback, 5分）
```bash
kubectl -n k8s-mag rollout undo deployment/web
kubectl -n k8s-mag rollout status deployment/web
```

### Step 5: 宣言的変更の事前確認（10分）
以下の `web-patch.yaml` を作成:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
  namespace: k8s-mag
spec:
  replicas: 2
```
適用前確認:
```bash
kubectl diff -f web-patch.yaml
kubectl apply --dry-run=server -f web-patch.yaml
kubectl apply -f web-patch.yaml
kubectl -n k8s-mag get deploy web
```

### Step 6: 片付け（必要時のみ、5分）
```bash
kubectl delete ns k8s-mag
```
⚠️ **破壊的コマンド**。コンテキスト・対象 Namespace を再確認してから実行。

---

## 6) Command Cheatsheet

```bash
# 現在の向き先確認
kubectl config current-context
kubectl config get-contexts

# 名前空間つきで一覧
kubectl -n <ns> get all

# 深掘り調査
kubectl -n <ns> describe deploy/<name>
kubectl -n <ns> logs deploy/<name> --tail=100
kubectl -n <ns> get events --sort-by=.lastTimestamp

# 更新と監視
kubectl -n <ns> set image deployment/<name> <container>=<image:tag>
kubectl -n <ns> rollout status deployment/<name>
kubectl -n <ns> rollout history deployment/<name>
kubectl -n <ns> rollout undo deployment/<name>

# 安全な適用
kubectl diff -f <file>.yaml
kubectl apply --dry-run=server -f <file>.yaml
kubectl apply -f <file>.yaml
```

---

## 7) Common mistakes and safe practices

### よくあるミス
- `kubectl apply -f .` を誤ディレクトリで実行
- `default` namespace のまま作業
- `current-context` 未確認で本番へ操作
- Secret を平文でマニフェスト管理
- `delete` をリソース範囲未確認で実行

### 安全プラクティス
- コマンド前に必ず: `kubectl config current-context`
- 常に `-n <ns>` を明示
- 変更前は `kubectl diff` + `--dry-run=server`
- 破壊的操作前は対象を `kubectl get ...` で目視確認
- Secret は External Secrets / CSI Secrets Store / 専用シークレット管理を検討

---

## 8) Interview-style question

**Q.** `kubectl apply` と `kubectl replace` の違いは？本番運用で `apply` が好まれる理由を説明してください。

**期待ポイント（自己確認）:**
- 宣言的管理と差分適用
- 既存フィールドへの影響範囲
- Git 管理との相性
- 安全確認手順（diff/dry-run/rollout監視）

---

## 9) Next-step resources（公式優先）

- Kubernetes Concepts
  - https://kubernetes.io/docs/concepts/
- kubectl Cheat Sheet
  - https://kubernetes.io/docs/reference/kubectl/cheatsheet/
- Deployments
  - https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Rolling Updates & Rollbacks
  - https://kubernetes.io/docs/tutorials/kubernetes-basics/update/update-intro/
- Configuration Best Practices
  - https://kubernetes.io/docs/concepts/configuration/overview/
- Secrets Good Practices
  - https://kubernetes.io/docs/concepts/security/secrets-good-practices/
- Pod Security Standards
  - https://kubernetes.io/docs/concepts/security/pod-security-standards/

---

### 明日の予告（学習アーク継続）
- Beginner: `kubectl exec` / `port-forward` の安全な使い方
- Middle: Readiness/Liveness Probe 設計
- Advanced: Resource Requests/Limits と HPA 連携
