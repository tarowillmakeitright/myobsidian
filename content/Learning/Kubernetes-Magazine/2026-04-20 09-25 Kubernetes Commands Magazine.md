# Daily Kubernetes Commands Magazine

- Date: 2026-04-20
- Time: 09:25 (Asia/Tokyo)
- Tags: #kubernetes #k8s #devops #learning #daily
- Link: [[Home]]

---

## 今回のテーマ
**安全に始める Kubernetes デプロイ運用：`kubectl apply` / `get` / `describe` / `logs` / `rollout` を使った段階的実践**

> 学習アーク: **Beginner → Middle → Advanced**

---

## [Beginner] ローカルで「壊さずに」デプロイ状況を観察する

### 1) Topic + Level
- **Topic:** Pod / Deployment の基本確認コマンド
- **Level:** Beginner

### 2) なぜ実アプリ開発で重要か
- 本番障害の初動は、まず「今なにが動いているか」を正確に把握すること。
- `get` / `describe` / `logs` を安全に使えると、無駄な再デプロイや誤操作を減らせる。

### 3) コア概念（kubectl / Kubernetes）
- `kubectl get`: 現在のリソース状態を一覧表示
- `kubectl describe`: イベントや詳細状態を確認（失敗原因の手がかり）
- `kubectl logs`: コンテナ標準出力を確認（アプリ側エラーの一次調査）
- Namespace: 環境分離の基本単位。**常に対象 namespace を意識**する。

### 4) アプリ開発での使い方（kubernetes.io/docs ベストプラクティス準拠）
- まず Read-Only コマンドで状況把握（`get`, `describe`, `logs`）
- 変更系コマンド前に `--context` / `-n` で対象を明示
- 監視対象を Deployment 単位で見る（Pod 単体だけで判断しない）

### 5) 30–60分ミニラボ（約35分）
1. namespace 作成
   - `kubectl create namespace mag-lab`
2. nginx Deployment 作成
   - `kubectl -n mag-lab create deployment web --image=nginx:1.25`
3. 状態確認
   - `kubectl -n mag-lab get deploy,pods,rs -o wide`
4. 詳細確認
   - `kubectl -n mag-lab describe deployment web`
5. ログ確認
   - `kubectl -n mag-lab logs deploy/web --tail=50`
6. 後片付け（※削除対象を再確認してから）
   - `kubectl delete namespace mag-lab`

### 6) コマンドチートシート
- `kubectl config get-contexts`
- `kubectl config current-context`
- `kubectl -n <ns> get pods`
- `kubectl -n <ns> describe pod <pod-name>`
- `kubectl -n <ns> logs deploy/<deploy-name> --tail=100`

### 7) よくあるミス & 安全策
- ミス: default namespace に誤デプロイ
  - 安全策: `-n` を必ず付与
- ミス: 間違ったクラスタに操作
  - 安全策: 実行前に `kubectl config current-context` を確認
- ミス: いきなり delete
  - 安全策: `get` / `describe` で対象再確認、必要なら同僚レビュー

### 8) 面接風質問
- 「`kubectl get` と `kubectl describe` の使い分けを、障害調査の流れで説明してください。」

### 9) 次の学習リソース
- Kubernetes Concepts: https://kubernetes.io/docs/concepts/
- kubectl overview: https://kubernetes.io/docs/reference/kubectl/
- Debug running pods: https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/

---

## [Middle] 宣言的運用で安全に更新する（apply と rollout）

### Prerequisites
- Beginner の内容（Namespace, get/describe/logs の基本）
- YAML の基本構文

### 1) Topic + Level
- **Topic:** Deployment を宣言的に更新し、ロールアウト状態を確認する
- **Level:** Middle

### 2) なぜ実アプリ開発で重要か
- チーム開発では「誰がいつ何を変更したか」を追える宣言的運用が不可欠。
- `rollout status/history` を使えるとリリース品質が上がる。

### 3) コア概念
- `kubectl apply -f`: マニフェストとの差分を適用
- Deployment strategy（RollingUpdate）
- `kubectl rollout status/history/undo`: デプロイ進行・履歴・ロールバック

### 4) アプリ開発での使い方
- Git 管理された manifest を apply
- 小さく段階的に変更（image tag, replicas など）
- rollout を確認してから次の変更へ進む

### 5) 30–60分ミニラボ（約45分）
1. `mag-rollout` namespace 作成
2. 以下の `deploy.yaml` 作成（例）

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
  namespace: mag-rollout
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
```

3. 適用と確認
   - `kubectl apply -f deploy.yaml`
   - `kubectl -n mag-rollout rollout status deploy/web`
4. image を `nginx:1.27` に変更して再 apply
5. 履歴確認
   - `kubectl -n mag-rollout rollout history deploy/web`
6. （任意）失敗想定タグに変えて rollback 練習
   - `kubectl -n mag-rollout rollout undo deploy/web`

### 6) コマンドチートシート
- `kubectl apply -f <file>`
- `kubectl diff -f <file>`
- `kubectl -n <ns> rollout status deploy/<name>`
- `kubectl -n <ns> rollout history deploy/<name>`
- `kubectl -n <ns> rollout undo deploy/<name>`

### 7) よくあるミス & 安全策
- ミス: `kubectl apply -f .` で意図しない大量適用
  - 安全策: 適用範囲を明示、先に `kubectl diff -f <target>`
- ミス: latest タグ運用で再現不能
  - 安全策: 固定タグ・イミュータブルタグを利用
- ミス: Secret を平文で Git 管理
  - 安全策: Secret は外部シークレット管理/暗号化手段を利用し、平文コミット禁止

### 8) 面接風質問
- 「宣言的運用（apply）と命令的運用（set image など）の違いを、監査性・再現性の観点で説明してください。」

### 9) 次の学習リソース
- Declarative config: https://kubernetes.io/docs/tasks/manage-kubernetes-objects/declarative-config/
- Deployment: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- kubectl diff: https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#diff

---

## [Advanced] 本番を意識した安全運用（Context固定・権限最小化・事故防止）

### Prerequisites
- Middle の内容（apply/rollout/diff）
- RBAC と ServiceAccount の基礎
- CI/CD からのデプロイ経験（入門レベルで可）

### 1) Topic + Level
- **Topic:** 誤操作防止を組み込んだ運用フロー
- **Level:** Advanced

### 2) なぜ実アプリ開発で重要か
- 本番事故の多くは「コマンドは正しいが対象が違う」。
- Context 固定・権限分離・事前検証を習慣化すると重大インシデントを減らせる。

### 3) コア概念
- kubeconfig context と namespace の明示
- RBAC（Role/RoleBinding）で最小権限
- `--dry-run=server` と `kubectl diff` による事前確認
- Audit 観点での「誰が何を適用したか」の追跡

### 4) アプリ開発での使い方
- CI では環境ごとに ServiceAccount を分離
- 人手運用時は `current-context` を毎回確認
- 本番系は destructive コマンド前に二段階確認（対象・影響範囲）

### 5) 30–60分ミニラボ（約50分）
1. `prod-sim` namespace 作成
2. read-only Role 作成し、ServiceAccount にバインド
3. 権限テスト
   - `kubectl auth can-i get pods -n prod-sim --as=system:serviceaccount:prod-sim:viewer-sa`
   - `kubectl auth can-i delete pods -n prod-sim --as=system:serviceaccount:prod-sim:viewer-sa`
4. 適用前検証
   - `kubectl apply --dry-run=server -f deploy.yaml`
   - `kubectl diff -f deploy.yaml`
5. 誤爆防止チェックリストを作成してから apply

### 6) コマンドチートシート
- `kubectl config current-context`
- `kubectl config view --minify`
- `kubectl auth can-i <verb> <resource> -n <ns> --as=<subject>`
- `kubectl apply --dry-run=server -f <file>`
- `kubectl diff -f <file>`

### 7) よくあるミス & 安全策
- ミス: `kubectl delete -f .` や `kubectl delete ns <name>` を誤クラスタで実行
  - 安全策: **破壊的コマンド前に context / namespace /対象一覧を必ず表示して確認**
- ミス: cluster-admin 権限の常用
  - 安全策: 作業単位で最小権限アカウントを使い分け
- ミス: Secret を manifest に直書き
  - 安全策: Secret は外部管理、ログ出力や画面共有時の露出にも注意

### 8) 面接風質問
- 「本番クラスタへの `kubectl apply` で、あなたが実施する“事故防止の事前チェック”を時系列で説明してください。」

### 9) 次の学習リソース
- RBAC: https://kubernetes.io/docs/reference/access-authn-authz/rbac/
- Configure access to multiple clusters: https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/
- Good practices for Kubernetes Secrets: https://kubernetes.io/docs/concepts/security/secrets-good-practices/
- kubectl auth can-i: https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#auth

---

## 今日のまとめ
- **Beginner:** まずは観察系コマンドで安全に現状把握
- **Middle:** apply + rollout で再現性ある更新
- **Advanced:** context確認・最小権限・事前検証で本番事故を予防

次回は「Service/Ingress とトラフィック経路の可視化（Beginner→Advanced）」へ進むと、アプリ公開までの理解が一段深まります。
