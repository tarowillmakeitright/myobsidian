---
tags: [kubernetes, k8s, devops, learning, daily]
created: 2026-03-28
---

# Daily Kubernetes Commands Magazine — 2026-03-28 09:25
[[Home]]

> 今日の学習アーク: **Beginner → Middle → Advanced**
> テーマは一貫して「Deployment を安全に更新し、トラブル時に観測・復旧する」です。

---

## 1) Beginner
### Topic + Level
**Topic:** Deployment の基本操作と安全なロールアウト確認  
**Level:** Beginner

### なぜ実アプリ開発で重要か
アプリの新バージョンを本番に出す際、`kubectl apply` だけでは不十分です。  
**「出したあとに壊れていないかを確認し、必要なら戻せる」**ことが、障害時間短縮と信頼性に直結します。

### コア概念（kubectl / Kubernetes）
- `Deployment`: Pod の望ましい状態を管理し、段階的更新を行う
- `ReplicaSet`: Deployment が内部で使う世代管理オブジェクト
- `kubectl apply -f`: 宣言的にリソース反映
- `kubectl rollout status`: 更新完了を待機・監視
- `kubectl get/describe/logs`: 状態確認の基本3点セット

### アプリ開発時にどう使うか（kubernetes.io/docs ベストプラクティス準拠）
- マニフェストを Git 管理し、宣言的適用（`apply`）を基本にする
- `resources.requests/limits` と `readinessProbe` を設定して安全に配備
- 更新後は `rollout status` と `kubectl get pods` で観測してから次工程へ

### 30–60分ミニラボ（目安40分）
1. Namespace 作成
   ```bash
   kubectl create namespace mag-lab
   ```
2. 以下を `deploy-nginx.yaml` として保存し適用
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
             image: nginx:1.27
             ports:
               - containerPort: 80
             resources:
               requests:
                 cpu: "100m"
                 memory: "128Mi"
               limits:
                 cpu: "300m"
                 memory: "256Mi"
             readinessProbe:
               httpGet:
                 path: /
                 port: 80
               initialDelaySeconds: 5
               periodSeconds: 5
   ```
   ```bash
   kubectl apply -f deploy-nginx.yaml
   kubectl rollout status deployment/web -n mag-lab
   kubectl get pods -n mag-lab -o wide
   ```
3. イメージ更新（ロールアウト）
   ```bash
   kubectl set image deployment/web nginx=nginx:1.27.1 -n mag-lab
   kubectl rollout status deployment/web -n mag-lab
   kubectl rollout history deployment/web -n mag-lab
   ```

### コマンドチートシート
```bash
kubectl config current-context
kubectl get ns
kubectl get deploy,pods -n mag-lab
kubectl describe deploy web -n mag-lab
kubectl logs -l app=web -n mag-lab --tail=100
kubectl rollout status deployment/web -n mag-lab
kubectl rollout history deployment/web -n mag-lab
```

### よくあるミス & 安全策
- ミス: `default` namespace に誤適用  
  安全策: 先に `-n` を明示、または `metadata.namespace` を宣言
- ミス: いきなり広範囲 apply  
  安全策: `kubectl apply --dry-run=server -f ...` で事前検証
- ミス: クラスタ文脈（context）違いで本番操作  
  安全策: **必ず `kubectl config current-context` を確認してから実行**

### 面接風質問（1問）
Deployment の更新確認で `kubectl rollout status` を使う利点を、`kubectl get pods` だけを見る場合と比較して説明してください。

### 次の一歩（公式ドキュメント）
- Deployment: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- kubectl overview: https://kubernetes.io/docs/reference/kubectl/
- Probes: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/

---

## 2) Middle
### Topic + Level
**Topic:** ConfigMap / Secret と環境差分管理、ローリング更新の実践  
**Level:** Middle

### 前提知識（Prerequisites）
- Deployment の基本（作成・更新・rollout status）
- Pod のライフサイクルを大まかに理解
- YAML と namespace の基本

### なぜ実アプリ開発で重要か
実案件では「設定値の変更」がデプロイ頻度より多いです。  
機密情報（DB パスワード等）を安全に扱い、環境（dev/stg/prod）ごとの差分を管理できないと、事故や漏えいにつながります。

### コア概念
- `ConfigMap`: 非機密設定の外出し
- `Secret`: 機密データ（※平文マニフェスト直書き禁止）
- `envFrom` / `valueFrom`: Pod へ設定注入
- `kubectl diff`: 適用前差分確認
- ローリング更新時の `maxUnavailable` / `maxSurge`

### アプリ開発時の活用（ベストプラクティス）
- 機密値は Secret 管理し、**Git に平文保存しない**
- 設定変更前に `kubectl diff -f`、反映時は `apply --server-side` など運用方針を統一
- 最小権限（RBAC）で Secret 参照権限を制御

### 30–60分ミニラボ（目安50分）
1. ConfigMap と Secret 作成（サンプル値）
   ```bash
   kubectl create configmap web-config -n mag-lab --from-literal=APP_MODE=staging
   kubectl create secret generic web-secret -n mag-lab --from-literal=API_TOKEN='replace-me'
   ```
2. Deployment に環境変数として注入（`deploy-web-env.yaml`）
   ```yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: web
     namespace: mag-lab
   spec:
     replicas: 2
     strategy:
       type: RollingUpdate
       rollingUpdate:
         maxUnavailable: 0
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
             image: nginx:1.27.1
             envFrom:
               - configMapRef:
                   name: web-config
               - secretRef:
                   name: web-secret
   ```
3. 差分確認→適用→監視
   ```bash
   kubectl diff -f deploy-web-env.yaml
   kubectl apply -f deploy-web-env.yaml
   kubectl rollout status deployment/web -n mag-lab
   ```

### コマンドチートシート
```bash
kubectl get configmap,secret -n mag-lab
kubectl describe configmap web-config -n mag-lab
kubectl get secret web-secret -n mag-lab -o yaml
kubectl diff -f deploy-web-env.yaml
kubectl apply --dry-run=server -f deploy-web-env.yaml
kubectl rollout restart deployment/web -n mag-lab
```

### よくあるミス & 安全策
- ミス: Secret を Git にコミット  
  安全策: External Secrets/Vault/SOPS 等の仕組みを使う
- ミス: Secret の値を `kubectl get -o yaml` でそのまま共有  
  安全策: 出力取り扱い最小化、チャット貼り付け禁止
- ミス: 本番で `kubectl apply -f .`  
  安全策: 対象ファイルを明示、`kubectl diff` とレビューを必須化

### 面接風質問（1問）
ConfigMap と Secret の使い分けを説明し、実運用で Secret を安全に扱う方法を1つ以上挙げてください。

### 次の一歩（公式ドキュメント）
- ConfigMap: https://kubernetes.io/docs/concepts/configuration/configmap/
- Secret: https://kubernetes.io/docs/concepts/configuration/secret/
- Managing resources: https://kubernetes.io/docs/concepts/cluster-administration/manage-deployment/

---

## 3) Advanced
### Topic + Level
**Topic:** 障害時デバッグ、ロールバック、PodDisruptionBudget と可用性設計  
**Level:** Advanced

### 前提知識（Prerequisites）
- Deployment/ReplicaSet/rollout の理解
- ConfigMap/Secret の基本運用
- readiness/liveness probe とリソース制限の基礎

### なぜ実アプリ開発で重要か
本番運用では「壊さない」だけでなく、**壊れたときに早く直す**能力が求められます。  
観測・切り戻し・可用性制御（PDB）を知っていると、障害影響を最小化できます。

### コア概念
- `kubectl rollout undo`: 迅速な切り戻し
- `kubectl describe` + `events`: 障害原因の一次切り分け
- `kubectl debug` / ephemeral containers（環境対応時）
- `PodDisruptionBudget`: メンテやノード更新時の同時停止数を制限

### アプリ開発時の活用（ベストプラクティス）
- rollout 失敗時は「原因調査→必要なら rollback」を標準手順化
- PDB を設定し、クラスタ運用時の可用性低下を防ぐ
- 監視（メトリクス/ログ/イベント）と変更履歴を関連づける

### 30–60分ミニラボ（目安55分）
1. 故障を意図的に起こす（存在しないイメージへ更新）
   ```bash
   kubectl set image deployment/web nginx=nginx:does-not-exist -n mag-lab
   kubectl rollout status deployment/web -n mag-lab
   kubectl describe pods -n mag-lab
   kubectl get events -n mag-lab --sort-by=.lastTimestamp
   ```
2. ロールバック
   ```bash
   kubectl rollout undo deployment/web -n mag-lab
   kubectl rollout status deployment/web -n mag-lab
   ```
3. PDB 適用（`pdb-web.yaml`）
   ```yaml
   apiVersion: policy/v1
   kind: PodDisruptionBudget
   metadata:
     name: web-pdb
     namespace: mag-lab
   spec:
     minAvailable: 1
     selector:
       matchLabels:
         app: web
   ```
   ```bash
   kubectl apply -f pdb-web.yaml
   kubectl get pdb -n mag-lab
   ```

### コマンドチートシート
```bash
kubectl rollout history deployment/web -n mag-lab
kubectl rollout undo deployment/web -n mag-lab
kubectl get events -n mag-lab --sort-by=.lastTimestamp
kubectl describe pod <pod-name> -n mag-lab
kubectl get pdb -n mag-lab
kubectl top pod -n mag-lab   # metrics-server導入時
```

### よくあるミス & 安全策
- ミス: 障害中に焦って `kubectl delete pod --all -n ...`  
  安全策: **破壊的操作前に影響範囲を明確化し、実行前に再確認**
- ミス: rollback せず再applyを繰り返して悪化  
  安全策: まず直近安定リビジョンへ戻し、落ち着いて原因分析
- ミス: context 誤りで別クラスタ操作  
  安全策: `kubectl config get-contexts` と `current-context` を毎回確認

### 面接風質問（1問）
本番でデプロイ失敗（ImagePullBackOff）が発生した場合、あなたの初動手順を時系列で説明してください（観測・切り戻し・再発防止を含む）。

### 次の一歩（公式ドキュメント）
- Debug running Pods: https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/
- Rollback a Deployment: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#rolling-back-a-deployment
- Pod Disruptions / PDB: https://kubernetes.io/docs/concepts/workloads/pods/disruptions/

---

## 安全運用メモ（毎回必読）
- `kubectl` 実行前チェック:
  1. `kubectl config current-context`
  2. `kubectl get ns`
  3. 対象 namespace とファイルを再確認
- **破壊的コマンド注意**: `delete`, `replace --force`, 広範囲 `apply -f .` は要注意
- Secret をマニフェストに直書きしない（平文保存・貼り付け禁止）
- 可能な限り `--dry-run=server` と `kubectl diff` を先に実施

---

### 明日の予告
次号は「Service/Ingress とアプリ公開（内部通信→外部公開→TLSの基本）」を予定。