---
tags: [kubernetes, k8s, devops, learning, daily]
---

# Daily Kubernetes Commands Magazine
**Date:** 2026-04-13 09:25 (Asia/Tokyo)
**Links:** [[Home]]

---

## 今号の学習テーマ
**テーマ:** `kubectl apply` を軸にした安全なデプロイ運用（宣言的管理・ロールアウト確認・段階的更新）

本号は **Beginner → Middle → Advanced** の学習アークで、同じテーマを段階的に深めます。

---

## 1) Topic + Level

### 🟢 Beginner
**Topic + Level:** はじめての宣言的デプロイ（Deployment / Service を apply する）

### 🟡 Middle
**Topic + Level:** 安全な更新とロールバック（RollingUpdate / rollout）
**前提知識:**
- `kubectl get`, `kubectl describe`, `kubectl logs` が使える
- Deployment と Pod の関係を理解している
- Namespace の基本を知っている

### 🔴 Advanced
**Topic + Level:** 本番寄りの安全運用（Context確認・差分確認・Secret分離・段階的検証）
**前提知識:**
- Middle の内容を実行できる
- Readiness/Liveness Probe の役割を説明できる
- ConfigMap/Secret の使い分けを理解している

---

## 2) なぜ実アプリ開発で重要か

- アプリ開発では「コードを作る」だけでなく「安全に配る」ことが品質を決める。
- Kubernetes の宣言的運用（YAMLを正として apply）に慣れると、再現性とレビュー性が上がる。
- `rollout` を使えると、不具合リリース時に停止時間を最小化できる。
- Context/Namespace を誤ると、意図しない環境（本番）を壊す事故につながる。

---

## 3) コア概念（kubectl / Kubernetes）

- **Declarative（宣言的）**: 「どう実行するか」ではなく「あるべき状態」をYAMLで定義。
- **`kubectl apply -f`**: マニフェストの状態をクラスタへ反映（作成/更新）。
- **Deployment**: Podを望ましい数・更新戦略で管理。
- **Service (ClusterIP)**: Podの集合へ安定したアクセス先を提供。
- **`kubectl rollout`**: 更新状態の確認、履歴、ロールバック。
- **Namespace**: 論理分離。開発/検証/本番の誤操作防止に必須。
- **Context**: どのクラスタ・ユーザーに向けて実行するか。

---

## 4) アプリ開発での使い方（kubernetes.io/docs ベストプラクティス準拠）

- マニフェストはGit管理し、レビュー後に適用（GitOps的運用に接続しやすい）。
- SecretをYAMLに直書きしない（平文コミット禁止）。
- `kubectl config current-context` / `-n <namespace>` で対象を明示。
- 更新前に `kubectl diff -f` で変更差分を確認してから apply。
- デプロイ後は `kubectl rollout status` と `kubectl get events` で健全性確認。

参考（公式）:
- Declarative Config: https://kubernetes.io/docs/tasks/manage-kubernetes-objects/declarative-config/
- Deployments: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- kubectl Cheat Sheet: https://kubernetes.io/docs/reference/kubectl/cheatsheet/
- Secrets: https://kubernetes.io/docs/concepts/configuration/secret/

---

## 5) 30〜60分ミニラボ

### ゴール
- Deployment/Service を apply
- イメージ更新して rollout 確認
- 問題発生を想定して rollback

### 事前準備（5分）
```bash
kubectl config current-context
kubectl get ns
kubectl create namespace mag-lab
```

### Step A: 初回デプロイ（10〜15分）
`k8s/app.yaml`
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
  namespace: mag-lab
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
          readinessProbe:
            httpGet:
              path: /
              port: 80
            initialDelaySeconds: 3
            periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: web
  namespace: mag-lab
spec:
  selector:
    app: web
  ports:
    - port: 80
      targetPort: 80
```

```bash
kubectl diff -f k8s/app.yaml
kubectl apply -f k8s/app.yaml
kubectl -n mag-lab get deploy,po,svc
kubectl -n mag-lab rollout status deploy/web
```

### Step B: 更新と確認（10〜15分）
```bash
kubectl -n mag-lab set image deploy/web nginx=nginx:1.27
kubectl -n mag-lab rollout status deploy/web
kubectl -n mag-lab rollout history deploy/web
```

### Step C: 失敗を想定した復旧（10〜15分）
```bash
kubectl -n mag-lab set image deploy/web nginx=nginx:does-not-exist
kubectl -n mag-lab rollout status deploy/web
kubectl -n mag-lab describe deploy/web
kubectl -n mag-lab get events --sort-by=.lastTimestamp | tail -n 20
kubectl -n mag-lab rollout undo deploy/web
kubectl -n mag-lab rollout status deploy/web
```

### Step D: 片付け（注意して実行）（5分）
```bash
# ⚠️ namespaceごと削除。対象を必ず確認
kubectl get ns
kubectl delete ns mag-lab
```

---

## 6) コマンドチートシート

```bash
# 文脈確認
kubectl config current-context
kubectl config get-contexts

# 適用前チェック
kubectl diff -f <file>
kubectl apply -f <file>

# 基本確認
kubectl -n <ns> get all
kubectl -n <ns> describe deploy/<name>
kubectl -n <ns> logs deploy/<name>

# ロールアウト
kubectl -n <ns> rollout status deploy/<name>
kubectl -n <ns> rollout history deploy/<name>
kubectl -n <ns> rollout undo deploy/<name>

# イメージ更新
kubectl -n <ns> set image deploy/<name> <container>=<image:tag>
```

---

## 7) よくあるミス & 安全プラクティス

### よくあるミス
- `default` namespace のまま本番想定コマンドを実行
- `kubectl apply -f .` で意図しないファイルまで適用
- Secretをマニフェストに平文で記載してGitにpush
- Context未確認で別クラスタに apply/delete

### 安全プラクティス
- 破壊的コマンド前に必ず確認:
  - `kubectl config current-context`
  - `kubectl -n <ns> get ...`
- `delete` は対象を絞る（label/リソース名/namespace明示）
- `apply` はスコープを絞る（特定ファイル/ディレクトリ）
- Secretは外部Secret管理や少なくとも `kubectl create secret` を使い、平文直書きを避ける
- まず検証環境で試し、ロールアウト監視してから本番へ

---

## 8) 面接スタイル質問（1問）

**質問:**
`kubectl apply` と `kubectl create` の違いを説明し、チーム開発で apply が好まれる理由を、ロールバック戦略と合わせて話してください。

---

## 9) 次の一歩（公式ドキュメント中心）

1. Kubernetes Objects の基礎
   - https://kubernetes.io/docs/concepts/overview/working-with-objects/
2. Deployment の詳細（戦略・履歴・ロールバック）
   - https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
3. Probes（Readiness/Liveness/Startup）
   - https://kubernetes.io/docs/concepts/configuration/liveness-readiness-startup-probes/
4. Secretの安全な扱い
   - https://kubernetes.io/docs/concepts/configuration/secret/
5. 本番運用のセキュリティ観点（Pod Security Standards）
   - https://kubernetes.io/docs/concepts/security/pod-security-standards/

---

### 学習アーク予告（次号）
- Beginner: ConfigMapと環境変数の基本
- Middle: Secret + アプリ設定の分離
- Advanced: Kustomizeで環境差分管理（dev/stg/prod）
