---
tags: [kubernetes, k8s, devops, learning, daily]
---

# Daily Kubernetes Commands Magazine (2026-04-30 09:25)

[[Home]]

## 今号のテーマ
**Topic:** `kubectl apply` と Declarative 運用の基本から安全なロールアウトまで  
**Learning Arc:** Beginner → Middle → Advanced

---

## 🟢 Beginner: `kubectl apply` とマニフェスト管理の第一歩

### 1) Topic + Level
- **Topic:** `kubectl apply -f` で Deployment/Service を宣言的に作る
- **Level:** Beginner

### 2) なぜ実アプリ開発で重要か
ローカルで動いたアプリをチームで再現可能にデプロイするには、手作業コマンドより**マニフェスト（YAML）**が必須です。`apply` による宣言的管理は、環境差分を減らし、レビュー可能な運用（GitOpsの土台）を作れます。

### 3) コア概念（kubectl/Kubernetes）
- **Declarative（宣言的）**: 「どう作るか」ではなく「あるべき状態」を書く
- **`kubectl apply`**: マニフェストとの差分を適用して状態を近づける
- **Deployment**: Podの望ましい数・更新戦略を管理
- **Service (ClusterIP)**: Pod群への安定したアクセス先

### 4) アプリ開発時の使われ方（kubernetes.io/docs ベストプラクティス準拠）
- アプリの設定をYAMLで管理し、PRレビューで変更意図を共有
- Deploymentでローリングアップデートし、無停止に近い更新を実現
- ServiceでPod再作成に依存しない接続先を提供
- マニフェストは最小権限・最小公開（必要ポートだけ）を意識

### 5) 30-60分ミニラボ
**目標:** NGINX Deployment + Service を declarative に作成し、更新まで体験

1. 作業用Namespace作成
```bash
kubectl create namespace magazine-lab
kubectl config set-context --current --namespace=magazine-lab
```

2. `deployment.yaml` を作成
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
        image: nginx:1.27
        ports:
        - containerPort: 80
```

3. `service.yaml` を作成
```yaml
apiVersion: v1
kind: Service
metadata:
  name: web
spec:
  selector:
    app: web
  ports:
  - port: 80
    targetPort: 80
```

4. 適用と確認
```bash
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl get deploy,po,svc
kubectl rollout status deployment/web
```

5. レプリカ数を2→3に変更して再適用
```bash
kubectl apply -f deployment.yaml
kubectl get deploy web
```

6. 片付け（※削除前に対象確認）
```bash
kubectl get all
kubectl delete namespace magazine-lab
```

### 6) Command Cheatsheet
```bash
kubectl apply -f <file-or-dir>
kubectl get deploy,po,svc
kubectl describe deployment <name>
kubectl logs deploy/<name>
kubectl rollout status deployment/<name>
kubectl rollout history deployment/<name>
kubectl config current-context
kubectl config view --minify
```

### 7) よくあるミス & Safe Practices
- **ミス:** 間違ったコンテキストに apply/delete
  - **安全策:** 実行前に `kubectl config current-context` を必ず確認
- **ミス:** `kubectl delete -f .` で想定外リソースを削除
  - **安全策:** 対象ディレクトリを限定し、`kubectl get` で事前確認
- **ミス:** Secret値を平文でGit管理
  - **安全策:** 機密情報はSecretや外部シークレット管理を使用し、平文コミット禁止

### 8) 面接っぽい一問
> `kubectl apply` と `kubectl create` の運用上の違いは？チーム開発でどちらを主に使うべき？理由も説明してください。

### 9) 次の一歩（公式ドキュメント）
- Declarative Management: https://kubernetes.io/docs/tasks/manage-kubernetes-objects/declarative-config/
- Deployment: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Service: https://kubernetes.io/docs/concepts/services-networking/service/

---

## 🟡 Middle: 安全な更新戦略とトラブル時の切り戻し

### Prerequisites
- Deployment/Service の基本
- `kubectl apply/get/describe/logs` が使える

### 1) Topic + Level
- **Topic:** RollingUpdate と `kubectl rollout undo`
- **Level:** Middle

### 2) なぜ実アプリ開発で重要か
本番では「デプロイ成功」より「**安全に戻せる**」ことが重要です。更新で不具合が出た時、素早いロールバックがSLO/SLAを守ります。

### 3) コア概念
- **RollingUpdate:** Podを段階的に置換して停止時間を抑える
- **readinessProbe:** 受け付け可能なPodだけService配下に入れる
- **rollout history/undo:** 改訂履歴の確認と切り戻し

### 4) 実開発での使い方
- 新バージョンを段階適用し、監視指標（エラー率/レイテンシ）で判定
- readiness/livenessを適切に設計して不良Podの流入を防止
- 問題時は即時 `rollout undo`、原因分析は別トラックで実施

### 5) 30-60分ミニラボ
1. 既存 `deployment.yaml` に readinessProbe を追加
2. イメージタグを変更（例: `nginx:1.27` → `nginx:1.27.1`）
3. `kubectl apply -f deployment.yaml`
4. 更新監視
```bash
kubectl rollout status deployment/web
kubectl rollout history deployment/web
```
5. 失敗想定で無効タグに変更し再適用（例: 存在しないタグ）
6. 異常確認後ロールバック
```bash
kubectl rollout undo deployment/web
kubectl rollout status deployment/web
```

### 6) Command Cheatsheet
```bash
kubectl set image deployment/web nginx=nginx:1.27.1
kubectl rollout status deployment/web
kubectl rollout history deployment/web
kubectl rollout undo deployment/web
kubectl get events --sort-by=.lastTimestamp
```

### 7) よくあるミス & Safe Practices
- **ミス:** readiness未設定で起動直後Podへトラフィック流入
  - **安全策:** readinessProbeを必須化
- **ミス:** 切り戻し手順が未検証
  - **安全策:** ステージングで rollback 訓練を定例化
- **ミス:** `kubectl apply -f` 対象が広すぎる
  - **安全策:** 環境ごとディレクトリ分離、`--context` 明示

### 8) 面接っぽい一問
> readinessProbe と livenessProbe は何が違う？誤設定するとどんな障害が起きる？

### 9) 次の一歩（公式ドキュメント）
- Rolling Updates: https://kubernetes.io/docs/tutorials/kubernetes-basics/update/update-intro/
- Probes: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/
- Rollback: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#rolling-back-a-deployment

---

## 🔴 Advanced: 本番向け安全運用（Context管理・Secret管理・変更前検証）

### Prerequisites
- Middleの内容（rollout/rollback/probe）
- Namespace/Context を使った複数環境運用経験

### 1) Topic + Level
- **Topic:** 破壊的操作の予防、Secret安全運用、変更の事前検証
- **Level:** Advanced

### 2) なぜ実アプリ開発で重要か
事故の多くは「コマンド自体」より「対象ミス」です。誤コンテキストでの delete/apply は即障害に直結。さらにSecret流出はインシデント化しやすく、予防設計が必須です。

### 3) コア概念
- **Context/Namespace 明示:** どのクラスタに打つかを固定
- **`kubectl diff` / `--dry-run=server`:** 変更前に差分と妥当性を確認
- **Secret:** マニフェスト直書き回避、RBAC最小権限、監査ログ

### 4) 実開発での使い方
- CIで `kubectl diff` とスキーマ検証を通してから apply
- 本番は break-glass 手順以外で直接操作を減らす
- Secretは外部システム（例: External Secrets）連携を検討
- `kubectl` 実行は常に `current-context` 可視化を習慣化

### 5) 30-60分ミニラボ
1. 現在コンテキスト確認
```bash
kubectl config current-context
kubectl config view --minify
```
2. 変更前差分確認
```bash
kubectl diff -f deployment.yaml
kubectl apply --dry-run=server -f deployment.yaml
```
3. Secretの安全作成（値をシェル履歴に残しにくい手段を選ぶ）
```bash
kubectl create secret generic app-config \
  --from-literal=API_ENDPOINT=https://example.internal \
  --dry-run=client -o yaml > secret.yaml
```
> `secret.yaml` をGitにコミットしない。必要ならSOPS等で暗号化管理。

4. 適用前に対象Namespaceを再確認して apply
```bash
kubectl get ns
kubectl apply -f secret.yaml
```

### 6) Command Cheatsheet
```bash
kubectl config get-contexts
kubectl config current-context
kubectl -n <namespace> get all
kubectl diff -f <file-or-dir>
kubectl apply --dry-run=server -f <file>
kubectl auth can-i <verb> <resource>
```

### 7) よくあるミス & Safe Practices
- **ミス:** `kubectl delete` を本番コンテキストで誤実行
  - **警告:** 破壊的コマンド前に `current-context` / namespace / 対象リソースを3点確認
- **ミス:** Secretを平文YAMLで共有チャット貼り付け
  - **安全策:** 値はマスク、共有は手順のみ
- **ミス:** `apply -f .` で意図しない追加変更
  - **安全策:** 対象を限定し `kubectl diff` を必須化

### 8) 面接っぽい一問
> あなたのチームで「誤クラスタへの `kubectl apply`」を防ぐ仕組みを、運用ルールと技術的ガードの両面で提案してください。

### 9) 次の一歩（公式ドキュメント）
- kubeconfig/context: https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/
- Secret: https://kubernetes.io/docs/concepts/configuration/secret/
- kubectl diff: https://kubernetes.io/docs/reference/kubectl/generated/kubectl_diff/
- kubectl apply: https://kubernetes.io/docs/reference/kubectl/generated/kubectl_apply/

---

## まとめ
- Beginnerで宣言的運用の基礎を固める
- Middleで安全な更新と切り戻しを体得する
- Advancedで事故予防（対象確認・差分確認・秘密情報保護）を仕組み化する

次号はこの流れを引き継ぎ、**ConfigMap/Secretの分離設計 → Helm/Kustomizeでの環境差分管理**へ進むと実務接続が強くなります。
