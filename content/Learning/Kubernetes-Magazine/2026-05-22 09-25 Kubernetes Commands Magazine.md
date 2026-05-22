---
tags: [kubernetes, k8s, devops, learning, daily]
---

# 2026-05-22 Kubernetes Commands Magazine

[[Home]]

## 今号のテーマ
**テーマ:** `kubectl apply` と宣言的デプロイの基礎〜運用（Beginner → Middle → Advanced）

---

## Beginner
### 1) Topic + Level
**Topic:** Deployment を `kubectl apply` で安全に作成・更新する  
**Level:** Beginner

### 2) なぜ実アプリ開発で重要か
アプリ開発では、コードだけでなく「どのコンテナを、何個、どの設定で動かすか」を再現可能に管理する必要があります。`apply` による宣言的管理は、
- 手順の属人化を減らす
- 環境差分（dev/stg/prod）を管理しやすくする
- 変更履歴を Git で追える
という実務上のメリットがあります。

### 3) コア概念（kubectl/Kubernetes）
- **Manifest (YAML):** 望ましい状態（desired state）を記述
- **kubectl apply -f:** 現在状態を望ましい状態へ収束
- **Deployment:** Pod の作成/更新/ロールアウトを管理
- **Service:** Pod への安定したアクセス経路を提供
- **Namespace:** リソースの論理分離

### 4) アプリ構築時の使い方（kubernetes.io/docs ベストプラクティス寄り）
- `kubectl run` のような即席コマンド中心ではなく、**YAML管理 + apply** を基本にする
- 1ファイルに詰め込みすぎず、`deployment.yaml` / `service.yaml` を分離
- `kubectl diff -f` で適用前差分を確認してから apply
- 本番系では apply 前に **context/namespace を必ず確認**

### 5) 30-60分ミニラボ
**所要:** 40分目安

1. 作業用 Namespace 作成
```bash
kubectl create namespace magazine-lab
kubectl config set-context --current --namespace=magazine-lab
kubectl config view --minify | grep namespace
```

2. `deployment.yaml` 作成（例: nginx 1.27）
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

3. `service.yaml` 作成
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

4. 差分確認→適用
```bash
kubectl diff -f deployment.yaml
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
```

5. 状態確認
```bash
kubectl get deploy,po,svc -o wide
kubectl rollout status deployment/web
```

6. レプリカ数を 3 に変更して再 apply
```bash
kubectl apply -f deployment.yaml
kubectl get po
```

### 6) Command Cheatsheet
```bash
kubectl config current-context
kubectl config view --minify
kubectl get ns
kubectl get deploy,po,svc -n <namespace>
kubectl describe deploy <name>
kubectl logs deploy/<name>
kubectl diff -f <file>
kubectl apply -f <file>
kubectl rollout status deploy/<name>
```

### 7) よくあるミスと安全策
- **ミス:** 間違った context のまま apply  
  **安全策:** `kubectl config current-context` を毎回確認
- **ミス:** default namespace に誤適用  
  **安全策:** `-n` 明示 or context に namespace 固定
- **ミス:** いきなり広範囲 apply (`kubectl apply -f .`)  
  **安全策:** 対象ファイルを絞る・`kubectl diff` 先行
- **注意（破壊的）:** `kubectl delete -f ...` は対象一括削除。実行前にファイル内容と context を再確認

### 8) 面接風チェック問題
`kubectl apply` と `kubectl create` の違いを、再実行性（idempotency）と GitOps 運用の観点で説明してください。

### 9) 次の一歩（公式リンク）
- Declarative Object Management: https://kubernetes.io/docs/tasks/manage-kubernetes-objects/declarative-config/
- Deployments: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- kubectl Cheat Sheet: https://kubernetes.io/docs/reference/kubectl/cheatsheet/

---

## Middle
### 1) Topic + Level
**Topic:** Rollout / Rollback / Probe 設計で安全に更新する  
**Level:** Middle  
**Prerequisites:** Deployment と Service の基本、`kubectl apply/get/describe/logs` を使える

### 2) なぜ実アプリ開発で重要か
本番運用で最も多い事故は「更新時のダウンタイム」「不健康な Pod へのトラフィック流入」です。Readiness/Liveness Probe と rollout 制御を理解すると、リリース失敗時の被害を最小化できます。

### 3) コア概念
- **RollingUpdate:** 段階的に Pod を入れ替える
- **maxUnavailable / maxSurge:** 同時停止数と追加起動数を制御
- **readinessProbe:** 準備完了前の Pod を Service から外す
- **livenessProbe:** ハング時の再起動判定
- **rollout history/undo:** 更新履歴確認と切り戻し

### 4) アプリ構築時の使い方
- readiness を実装してから本番トラフィックへ参加
- 重要システムは `maxUnavailable: 0` を検討
- 監視（メトリクス/ログ）を見ながら rollout
- 切り戻し手順（`rollout undo`）を事前に演習

### 5) 30-60分ミニラボ
**所要:** 45〜60分目安

1. 既存 Deployment に probe と strategy を追加
2. image タグを更新して rollout 開始
3. 進行確認
```bash
kubectl rollout status deploy/web
kubectl rollout history deploy/web
```
4. 故障バージョン（例: 存在しないタグ）へ更新し失敗を観察
5. ロールバック
```bash
kubectl rollout undo deploy/web
kubectl rollout status deploy/web
```

### 6) Command Cheatsheet
```bash
kubectl set image deploy/web nginx=nginx:1.27.1
kubectl rollout status deploy/web
kubectl rollout history deploy/web
kubectl rollout undo deploy/web
kubectl describe po <pod>
kubectl logs <pod> --previous
```

### 7) よくあるミスと安全策
- **ミス:** `latest` タグ運用で再現不能  
  **安全策:** 固定タグ（可能なら digest）使用
- **ミス:** probe 不在で起動直後 Pod に流入  
  **安全策:** readinessProbe を必須化
- **ミス:** ロールバック手順未検証  
  **安全策:** ステージングで定期演習

### 8) 面接風チェック問題
Readiness Probe と Liveness Probe の役割の違いを、障害時のトラフィック制御という観点で説明してください。

### 9) 次の一歩（公式リンク）
- Probes: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/
- Rolling Update: https://kubernetes.io/docs/tutorials/kubernetes-basics/update/update-intro/
- Deployment strategy: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#strategy

---

## Advanced
### 1) Topic + Level
**Topic:** ConfigMap/Secret・SecurityContext・リソース制限を含む本番向けマニフェスト設計  
**Level:** Advanced  
**Prerequisites:** Deployment 運用、rollout/rollback、Probe の理解

### 2) なぜ実アプリ開発で重要か
本番障害の根本原因は、機能バグだけでなく「設定ミス」「過剰権限」「リソース枯渇」が多いです。セキュアで制御された manifest は、可用性とセキュリティの土台になります。

### 3) コア概念
- **ConfigMap / Secret:** 設定と機密情報を分離
- **resources requests/limits:** スケジューリングと暴走抑制
- **SecurityContext:** 非 root 実行、権限最小化
- **ServiceAccount / RBAC:** 必要最小限アクセス

### 4) アプリ構築時の使い方（ベストプラクティス）
- Secret を YAML に平文で直書きしない（Git直コミット禁止）
- 環境変数だけに頼らず、監査可能な形で設定管理
- `runAsNonRoot`, `readOnlyRootFilesystem`, `allowPrivilegeEscalation: false` を検討
- requests/limits を必ず設定し、HPA 導入前に基準値を整える

### 5) 30-60分ミニラボ
**所要:** 50〜60分目安

1. ConfigMap と Secret（ダミー値）を作成
```bash
kubectl create configmap web-config --from-literal=APP_MODE=prod
kubectl create secret generic web-secret --from-literal=API_KEY=dummy-change-me
```

2. Deployment に envFrom / securityContext / resources を追加して apply
3. Pod 内確認
```bash
kubectl exec deploy/web -- printenv | grep APP_MODE
```

4. requests/limits を極端に下げた場合の挙動を観察（OOM/Throttle など）
5. 後片付け
```bash
kubectl delete ns magazine-lab
```
> ⚠️ **破壊的コマンド注意:** namespace 削除は配下全リソースを消去します。`current-context` と対象 namespace を再確認してから実行。

### 6) Command Cheatsheet
```bash
kubectl create configmap <name> --from-literal=KEY=VALUE
kubectl create secret generic <name> --from-literal=KEY=VALUE
kubectl get secret <name> -o yaml
kubectl auth can-i get pods --as=system:serviceaccount:<ns>:<sa>
kubectl top pod
kubectl delete ns <name>
```

### 7) よくあるミスと安全策
- **ミス:** Secret を Git に平文保存  
  **安全策:** 外部 Secret 管理（例: CSI/External Secrets）や暗号化ワークフロー検討
- **ミス:** requests/limits 未設定  
  **安全策:** 全 Pod に最低限設定、SLO と実測値で調整
- **ミス:** root 実行・過剰権限 SA  
  **安全策:** SecurityContext + RBAC 最小権限

### 8) 面接風チェック問題
「requests と limits をどう決めるか」を、開発初期と本番運用フェーズでそれぞれどう進めるか説明してください。

### 9) 次の一歩（公式リンク）
- Secrets: https://kubernetes.io/docs/concepts/configuration/secret/
- ConfigMap: https://kubernetes.io/docs/concepts/configuration/configmap/
- Security Context: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/
- Resource Management: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/
- RBAC: https://kubernetes.io/docs/reference/access-authn-authz/rbac/

---

## 安全メモ（毎号共通）
- `kubectl apply -f .` や `kubectl delete -f .` のような広範囲実行前に、**必ず context/namespace と対象ファイル範囲を確認**
- 本番クラスタでは `kubectl diff` / レビュー / 段階適用を徹底
- シークレット値をチャット・スクリーンショット・履歴に残さない
- 迷ったら「小さく適用して観察」を優先
