---
tags: [kubernetes, k8s, devops, learning, daily]
level: [Beginner, Middle, Advanced]
date: 2026-04-02
---

# 2026-04-02 09:25 Kubernetes Commands Magazine
[[Home]]

## 今回の学習アーク（Beginner → Middle → Advanced）

---

## 1) Topic + Level

### Beginner
**Topic:** `kubectl get/describe/logs` で「まず観測する」

### Middle（前提あり）
**Topic:** Deployment のローリングアップデートとロールバック
**Prerequisites:**
- Pod / Deployment の基本概念
- `kubectl get`, `kubectl describe`, `kubectl logs` を使って状態確認できる

### Advanced（前提あり）
**Topic:** ConfigMap / Secret / probes / resources を使った「安全な本番寄り運用」
**Prerequisites:**
- Deployment と Service を YAML で作成できる
- ローリングアップデートとロールバックの実行経験
- 最低限の Linux / HTTP の理解（ヘルスチェックの意味）

---

## 2) Why it matters for real app development

- **観測（Beginner）**ができないと、障害時に「何が起きているか」を切り分けできません。
- **安全なデプロイ（Middle）**ができると、機能追加時の事故を最小化できます。
- **設定と機密情報の分離・ヘルスチェック（Advanced）**は、実アプリを壊さず運用する必須条件です。

開発現場では「作る力」だけでなく、**落とさず届け続ける力**が評価されます。

---

## 3) Core kubectl/Kubernetes concept explanations

### Beginner: 観測コマンド
- `kubectl get pods -n <ns>`: 一覧確認（全体の健康状態）
- `kubectl describe pod <pod> -n <ns>`: イベントや失敗理由の詳細
- `kubectl logs <pod> -n <ns>`: アプリログ確認
- `kubectl logs -f <pod>`: リアルタイム追跡

### Middle: Deployment 制御
- `kubectl rollout status deployment/<name>`: 展開の進行確認
- `kubectl set image deployment/<name> <container>=<image>:<tag>`: イメージ更新
- `kubectl rollout undo deployment/<name>`: ロールバック

### Advanced: 本番運用に近づける要素
- **ConfigMap**: 非機密設定（feature flag, 環境設定）
- **Secret**: 機密情報（パスワード、トークン）※平文コミット禁止
- **readinessProbe/livenessProbe**: トラフィック投入可否・自己回復判定
- **resources (requests/limits)**: ノード過負荷防止、安定運用の基礎

---

## 4) Kubernetes is used while building apps（kubernetes.io/docs ベストプラクティス準拠）

アプリ開発フローに沿うと以下が自然です：

1. **開発初期**: Pod/Deployment を立てて `get/describe/logs` で挙動確認
2. **機能追加期**: Deployment を段階的更新、`rollout status` で監視
3. **運用安定化**: 設定を ConfigMap、機密を Secret に分離
4. **信頼性向上**: Probe と resources を設定し、過負荷・無限再起動を予防

参考（公式）:
- Workloads: https://kubernetes.io/docs/concepts/workloads/
- Deployments: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- ConfigMap: https://kubernetes.io/docs/concepts/configuration/configmap/
- Secrets: https://kubernetes.io/docs/concepts/configuration/secret/
- Probes: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/
- Resource Management: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/

---

## 5) 30-60分ハンズオン・ミニラボ

### ゴール
- Nginx Deployment を作成
- ローリングアップデート → ロールバックを体験
- ConfigMap と Secret を参照する Pod を確認

### 手順（約45分）

#### Step 0: 事前確認（5分）
```bash
kubectl config current-context
kubectl get nodes
```
> ⚠️ **注意:** 本番クラスターでないことを必ず確認。context ミスは重大事故の原因。

#### Step 1: Namespace と Deployment 作成（10分）
```bash
kubectl create namespace mag-lab
kubectl -n mag-lab create deployment web --image=nginx:1.25
kubectl -n mag-lab expose deployment web --port=80 --type=ClusterIP
kubectl -n mag-lab get all
```

#### Step 2: 観測（10分）
```bash
kubectl -n mag-lab get pods
kubectl -n mag-lab describe deployment web
kubectl -n mag-lab logs deploy/web
```

#### Step 3: ローリングアップデート（10分）
```bash
kubectl -n mag-lab set image deployment/web nginx=nginx:1.26
kubectl -n mag-lab rollout status deployment/web
kubectl -n mag-lab rollout history deployment/web
```

#### Step 4: ロールバック（5分）
```bash
kubectl -n mag-lab rollout undo deployment/web
kubectl -n mag-lab rollout status deployment/web
```

#### Step 5: ConfigMap / Secret（5-10分）
```bash
kubectl -n mag-lab create configmap app-config --from-literal=APP_MODE=dev
kubectl -n mag-lab create secret generic app-secret --from-literal=API_TOKEN='dummy-token'
kubectl -n mag-lab get configmap,secret
```
> ⚠️ Secret は etcd 上で暗号化設定や RBAC と組み合わせて保護すること（本番運用必須）。

#### Optional Cleanup
```bash
kubectl delete namespace mag-lab
```
> ⚠️ **破壊的操作**: Namespace 削除は配下リソース全削除。実行前に対象を再確認。

---

## 6) Command cheatsheet

```bash
# 現在の接続先
kubectl config current-context

# リソース確認
kubectl get pods -A
kubectl get deploy,svc -n <ns>

# 詳細・ログ
kubectl describe pod <pod> -n <ns>
kubectl logs <pod> -n <ns>
kubectl logs -f deploy/<name> -n <ns>

# デプロイ更新
kubectl set image deployment/<name> <container>=<image>:<tag> -n <ns>
kubectl rollout status deployment/<name> -n <ns>
kubectl rollout undo deployment/<name> -n <ns>

# 設定と機密
kubectl get configmap,secret -n <ns>

# 安全確認（適用前の差分確認）
kubectl diff -f <manifest.yaml>
kubectl apply --server-side -f <manifest.yaml>
```

---

## 7) Common mistakes and safe practices

### よくあるミス
1. **context/namespace を見ずに apply/delete**
2. `kubectl delete -A` など広範囲コマンドの誤実行
3. Secret を Git に平文コミット
4. readinessProbe 未設定で、起動直後の不安定 Pod にトラフィック投入
5. requests/limits 未設定でノード圧迫

### 安全運用の実践
- 実行前に毎回 `kubectl config current-context` と `-n` を確認
- `kubectl diff -f` で差分確認してから `apply`
- Secret は外部 Secret 管理（例: CSI/External Secrets）も検討
- 本番変更は rollout 状態を監視し、即 rollback できる準備
- 破壊的コマンド前に「対象・範囲・復旧手順」を確認

---

## 8) Interview-style question

**Q.** Deployment の rolling update 中に一部 Pod が起動失敗している場合、どの順で調査し、どのコマンドで安全に復旧しますか？

（期待される観点：`rollout status` / `describe` / `logs` / probe 設定確認 / `rollout undo` 判断）

---

## 9) Next-step resources（公式中心）

- Kubernetes Documentation (Top): https://kubernetes.io/docs/
- kubectl Cheat Sheet: https://kubernetes.io/docs/reference/kubectl/cheatsheet/
- Debug Running Pods: https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/
- Deployment: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Probes: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/
- Secrets Good Practices: https://kubernetes.io/docs/concepts/security/secrets-good-practices/
- Configure Resource Management: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/

---

次号予告（学習アーク継続）:
- Beginner: `kubectl exec` とデバッグの基本
- Middle: Service/Ingress の通信設計
- Advanced: HPA とメトリクスベース自動スケーリング
