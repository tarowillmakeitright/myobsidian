# Daily Kubernetes Commands Magazine — 2026-05-24
Tags: #kubernetes #k8s #devops #learning #daily
Links: [[Home]]

## 今号のテーマ
**「安全なアプリ配備と運用の基本ループ」**  
Beginner → Middle → Advanced の順で、実務でよく使う `kubectl` 操作を段階的に学びます。

---

## Arc 1 — Beginner
### 1) Topic + Level
**Topic:** Pod/Deployment の作成・確認・ロールアウト基礎  
**Level:** Beginner

### 2) なぜ実アプリ開発で重要か
ローカルで動くアプリを本番に近い環境へ載せる最初の一歩です。  
「動いた」だけでなく、**再現可能にデプロイできること**がチーム開発の前提になります。

### 3) コア概念（kubectl/Kubernetes）
- **Pod:** コンテナ実行の最小単位
- **Deployment:** Pod の望ましい状態（レプリカ数・イメージ）を宣言管理
- **ReplicaSet:** Deployment が裏で管理
- **Namespace:** リソースを論理分離
- 主要コマンド:
  - `kubectl get`
  - `kubectl describe`
  - `kubectl logs`
  - `kubectl rollout status`

### 4) アプリ開発での使い方（ベストプラクティス準拠）
- まず Namespace を切る（`dev` など）
- マニフェストを Git 管理し、`kubectl apply -f` で宣言適用
- イメージは `:latest` を避け、タグ固定（例: `myapp:1.2.3`）
- 変更後は `rollout status` と `logs` で健全性確認

### 5) 30-60分ミニラボ
1. `dev` Namespace 作成
2. Nginx Deployment（2レプリカ）を適用
3. Pod 状態とログ確認
4. イメージを更新してロールアウト確認

### 6) コマンドチートシート
```bash
kubectl config get-contexts
kubectl config current-context
kubectl create namespace dev
kubectl get ns
kubectl apply -n dev -f deployment.yaml
kubectl get deploy,pods -n dev -o wide
kubectl describe deploy web -n dev
kubectl logs -n dev deploy/web
kubectl rollout status deploy/web -n dev
kubectl set image deploy/web nginx=nginx:1.27 -n dev
kubectl rollout history deploy/web -n dev
```

### 7) よくあるミス & 安全策
- ミス: Context を確認せず apply/delete
  - 安全策: **毎回 `kubectl config current-context` を先に実行**
- ミス: `-n` 省略で default に誤適用
  - 安全策: 明示的に `-n dev`
- ミス: いきなり `kubectl delete -f .`
  - 安全策: 対象を絞る、事前に `kubectl get` / `kubectl diff`

### 8) 面接風質問
「Deployment と Pod を直接作る運用の違いを、障害復旧の観点で説明してください。」

### 9) 次の一歩（公式）
- https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- https://kubernetes.io/docs/tasks/run-application/run-stateless-application-deployment/
- https://kubernetes.io/docs/reference/kubectl/

---

## Arc 2 — Middle
### Prerequisites
- Deployment/Pod の基本が分かる
- `kubectl get/describe/logs` を使える

### 1) Topic + Level
**Topic:** Service と ConfigMap で「接続」と「設定」を分離する  
**Level:** Middle

### 2) なぜ実アプリ開発で重要か
アプリは「動く」だけでなく、**他サービスから安定して呼べること**と、**設定変更を安全に反映できること**が必要です。

### 3) コア概念
- **Service (ClusterIP):** Pod の集合へ安定した仮想IP/DNSを提供
- **ConfigMap:** 非機密設定を外部化
- **Label Selector:** Service がどの Pod を束ねるかを決定

### 4) 実装時のベストプラクティス
- 接続先は Pod IP 直書きせず Service DNS 名を使う
- 環境差分（dev/stg/prod）は ConfigMap や Kustomize で管理
- ConfigMap に秘密情報は置かない（Secret を使う）

### 5) 30-60分ミニラボ
1. Web Deployment を作成
2. `ClusterIP` Service を作成
3. `busybox` Pod から `wget` で Service 疎通確認
4. ConfigMap 経由で環境変数を注入し再デプロイ確認

### 6) コマンドチートシート
```bash
kubectl apply -n dev -f web-deployment.yaml
kubectl apply -n dev -f web-service.yaml
kubectl get svc -n dev
kubectl run -n dev tester --image=busybox:1.36 --restart=Never -it --rm -- sh
# (pod内) wget -qO- http://web-svc
kubectl create configmap web-config -n dev --from-literal=APP_MODE=dev
kubectl describe configmap web-config -n dev
kubectl rollout restart deploy/web -n dev
kubectl exec -n dev deploy/web -- printenv | grep APP_MODE
```

### 7) よくあるミス & 安全策
- ミス: Service selector と Pod label 不一致
  - 安全策: `kubectl get pod --show-labels` で検証
- ミス: ConfigMap に APIキー等を保存
  - 安全策: 機密は Secret + 外部シークレット管理
- ミス: `kubectl run` を本番で検証用に常設
  - 安全策: 一時 Pod は `--rm` で後始末

### 8) 面接風質問
「Service があるのに通信できないとき、どの順番で切り分けますか？」

### 9) 次の一歩（公式）
- https://kubernetes.io/docs/concepts/services-networking/service/
- https://kubernetes.io/docs/concepts/configuration/configmap/
- https://kubernetes.io/docs/tasks/debug/debug-application/

---

## Arc 3 — Advanced
### Prerequisites
- Service/ConfigMap/Deployment の実運用経験
- YAML マニフェストを読んで修正できる

### 1) Topic + Level
**Topic:** RollingUpdate + Probes + Requests/Limits で安全に継続デリバリー  
**Level:** Advanced

### 2) なぜ実アプリ開発で重要か
リリース時の停止や性能劣化を最小化し、**壊れたバージョンを自動ではじく仕組み**を作るために必須です。

### 3) コア概念
- **readinessProbe:** トラフィック受け入れ可能か
- **livenessProbe:** プロセス自己回復が必要か
- **resources.requests/limits:** スケジューリングと暴走抑制
- **RollingUpdate strategy:** `maxUnavailable`, `maxSurge` の調整

### 4) 実装時のベストプラクティス
- Probe なし本番運用を避ける
- Requests/Limits を設定してノード資源を保護
- 段階的ロールアウト後に `rollout status` / メトリクス確認
- 問題時は `kubectl rollout undo` を即実行できるようにする

### 5) 30-60分ミニラボ
1. Deployment に readiness/liveness を追加
2. Requests/Limits を設定
3. 意図的に失敗するイメージ/設定でロールアウトし挙動観察
4. `rollout undo` で復旧

### 6) コマンドチートシート
```bash
kubectl apply -n dev -f deploy-with-probes.yaml
kubectl get pod -n dev
kubectl describe pod -n dev <pod-name>
kubectl top pod -n dev
kubectl set image deploy/web nginx=nginx:broken -n dev
kubectl rollout status deploy/web -n dev
kubectl rollout undo deploy/web -n dev
kubectl get events -n dev --sort-by=.metadata.creationTimestamp
```

### 7) よくあるミス & 安全策
- ミス: Probe 閾値が厳しすぎて再起動ループ
  - 安全策: `initialDelaySeconds` / `failureThreshold` を段階調整
- ミス: Limit 未設定でノード逼迫
  - 安全策: 最低限の requests/limits を全Podに
- ミス: 破壊的コマンド誤爆（例: `kubectl delete ns dev`）
  - 安全策: 実行前に **対象・context・namespace を声出し確認**、可能ならレビュー

### 8) 面接風質問
「readinessProbe と livenessProbe を同じエンドポイントにしない方がよいケースを説明してください。」

### 9) 次の一歩（公式）
- https://kubernetes.io/docs/concepts/configuration/liveness-readiness-startup-probes/
- https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/
- https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/
- https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#rolling-update-deployment

---

## 安全メモ（毎号共通）
- Secret をマニフェストへ平文で埋め込まない
- `kubectl apply/delete` 前に **context / namespace / 対象ファイル** を確認
- 本番クラスタでは `--dry-run=client -o yaml` や `kubectl diff` を活用
- 破壊的操作（delete/replace/force）は必ず影響範囲を説明してから実行
