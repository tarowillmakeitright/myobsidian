---
tags: [kubernetes, k8s, devops, learning, daily]
---

# 2026-04-15 09:25 Kubernetes Commands Magazine
[[Home]]

## 今日の学習アーク
**テーマ:** 安全なアプリデプロイと段階的ロールアウト（Beginner → Middle → Advanced）

---

## 1) Topic + Level

### 🟢 Beginner: Deployment と Pod の基本観察
**トピック:** `kubectl get/describe/logs` でアプリ状態を読む

### 🟡 Middle: Rollout 管理と更新戦略
**トピック:** `kubectl rollout` と Deployment 戦略（RollingUpdate）
**前提知識:**
- Pod / Deployment / Service の基本
- `kubectl get`, `kubectl describe`, `kubectl logs`

### 🔴 Advanced: 本番運用を想定した安全な変更適用
**トピック:** `kubectl apply --server-side`, `kubectl diff`, context/namespace 安全運用
**前提知識:**
- Deployment 更新・ロールバック経験
- namespace/context の概念
- readiness/liveness probe の基礎

---

## 2) Why it matters for real app development
- アプリ開発では「動く」だけでなく、**止めずに更新する**ことが重要。
- 誤った適用（クラスタ違い・namespace違い）は、本番障害に直結。
- ロールアウト管理を理解すると、デグレ発生時に即時 rollback できる。
- 実務では SRE/DevOps と協働するため、`kubectl` の安全運用は必須スキル。

---

## 3) Core kubectl/Kubernetes concepts
- **Pod:** コンテナ実行の最小単位。直接運用より、通常は Deployment 管理。
- **Deployment:** 宣言的に desired state（例: レプリカ数・イメージ）を管理。
- **ReplicaSet:** Deployment が内部で管理する Pod 集合。
- **RollingUpdate:** 無停止に近い形で段階更新する戦略。
- **readinessProbe:** 受信可能になってから Service 配下へ参加。
- **livenessProbe:** ハング時に再起動を促す。
- **Context / Namespace:** 操作対象のクラスタ・論理分離領域。誤操作防止の最重要ポイント。

---

## 4) How Kubernetes is used while building apps（kubernetes.io/docs に沿った実践）
- 開発時は Deployment + Service を基本セットとして利用。
- 更新時は `set image` や manifest 更新で段階ロールアウト。
- probe を設定して「起動完了前にトラフィックを受けない」状態を作る。
- Secret は `Secret` リソースや外部 Secret 管理を使い、**平文を manifest に直書きしない**。
- 適用前に `kubectl diff` で差分確認、対象 context/namespace を明示して事故を防ぐ。

参考（公式）:
- Deployments: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Rolling updates tutorial: https://kubernetes.io/docs/tutorials/kubernetes-basics/update/update-intro/
- Probes: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/
- Secrets good practices: https://kubernetes.io/docs/concepts/security/secrets-good-practices/

---

## 5) 30-60分ハンズオン・ミニラボ
**目標:** 安全にデプロイ→更新→問題検知→ロールバックを体験

### 0. 事前確認（5分）
```bash
kubectl config current-context
kubectl get ns
kubectl create namespace k8s-mag-lab
kubectl config set-context --current --namespace=k8s-mag-lab
```

### 1. 初回デプロイ（10分）
```bash
kubectl create deployment web --image=nginx:1.25
kubectl expose deployment web --port=80 --type=ClusterIP
kubectl get all
kubectl rollout status deployment/web
```

### 2. 段階更新（10分）
```bash
kubectl set image deployment/web nginx=nginx:1.26
kubectl rollout status deployment/web
kubectl rollout history deployment/web
```

### 3. 意図的に壊す→復旧（15分）
```bash
kubectl set image deployment/web nginx=nginx:DOES-NOT-EXIST
kubectl rollout status deployment/web --timeout=60s
kubectl describe deployment web
kubectl get pods
kubectl rollout undo deployment/web
kubectl rollout status deployment/web
```

### 4. 安全な宣言適用の練習（10-15分）
```bash
kubectl get deployment web -o yaml > web-deploy.yaml
# （ローカルで replicas を 2 に編集）
kubectl diff -f web-deploy.yaml
kubectl apply --server-side -f web-deploy.yaml
kubectl get deploy web
```

### 5. 後片付け（必要なら）
```bash
# 破壊的コマンド: 対象 namespace/context を必ず再確認
kubectl config current-context
kubectl get ns
kubectl delete namespace k8s-mag-lab
```

---

## 6) Command cheatsheet
```bash
# 現在の対象確認
kubectl config current-context
kubectl config view --minify | grep namespace:

# 観察
kubectl get pods,deploy,svc
kubectl describe pod <pod-name>
kubectl logs deploy/web

# 更新
kubectl set image deployment/web nginx=nginx:1.26
kubectl rollout status deployment/web
kubectl rollout history deployment/web
kubectl rollout undo deployment/web

# 安全適用
kubectl diff -f manifest.yaml
kubectl apply --server-side -f manifest.yaml

# スコープ明示（安全）
kubectl -n k8s-mag-lab get pods
kubectl --context <ctx> -n <ns> apply -f manifest.yaml
```

---

## 7) Common mistakes and safe practices
**よくあるミス**
1. 本番 context のまま apply/delete する
2. namespace 未指定で default に作成して見失う
3. Secret を Git 管理下の manifest に平文記載
4. rollout 失敗時に events/logs を見ずに再apply連打

**安全プラクティス**
- コマンド実行前に毎回 `current-context` と `namespace` を確認
- 変更前は `kubectl diff`、変更後は `rollout status`
- 機密情報は Secret + RBAC 最小権限で管理
- `delete` 系は必ず対象を絞る（`-n`, `--context`, ラベル指定）
- 破壊的操作前に「何を消すか」を一度 `get` で可視化

⚠️ **警告（破壊的操作）**
- `kubectl delete -f ...` / `kubectl delete ns ...` は影響範囲が大きい。実行前に対象クラスタ・namespace・manifest内容を必ず再確認。
- `kubectl apply -f` も scope 誤りで本番変更になり得るため、`--context` / `-n` 明示を推奨。

---

## 8) Interview-style question
**質問:**
Deployment の RollingUpdate 中に新バージョン Pod が readiness を満たさない場合、Service のトラフィックと rollout はどう振る舞うか？また復旧のために取るべき `kubectl` 手順を説明してください。

---

## 9) Next-step resources（公式優先）
- Kubernetes Concepts: https://kubernetes.io/docs/concepts/
- kubectl Cheat Sheet: https://kubernetes.io/docs/reference/kubectl/cheatsheet/
- Deployment: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Update application tutorial: https://kubernetes.io/docs/tutorials/kubernetes-basics/update/update-intro/
- Configure probes: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/
- Secrets good practices: https://kubernetes.io/docs/concepts/security/secrets-good-practices/
- Configure access to multiple clusters: https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/

---

次号予告（学習アーク継続）:
- Beginner: ConfigMap/Secret の使い分け
- Middle: HPA と requests/limits
- Advanced: NetworkPolicy と Zero Trust 的設計の基礎
