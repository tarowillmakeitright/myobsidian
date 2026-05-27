---
tags: [kubernetes, k8s, devops, learning, daily]
---

# 2026-05-27 Kubernetes Commands Magazine
[[Home]]

## Issueテーマ
**Kubernetesで安全にアプリをデプロイして運用する基礎〜実践（kubectl中心）**

---

## Beginner（初級）
### 1) Topic + Level
**Topic:** `kubectl get / describe / logs`で「今何が起きているか」を把握する
**Level:** Beginner

### 2) なぜ実アプリ開発で重要か
アプリ障害の初動は「状態の可視化」です。PodがCrashLoopしているのか、ImagePullに失敗しているのか、Readinessが落ちているのかを最短で掴めると、復旧時間（MTTR）を大きく短縮できます。

### 3) コア概念（kubectl/Kubernetes）
- `kubectl get`：リソース一覧（現在地の把握）
- `kubectl describe`：イベント/詳細情報（失敗理由の深掘り）
- `kubectl logs`：コンテナ標準出力確認（アプリ起因の調査）
- Namespace：環境分離の基本（dev/stg/prod）

### 4) アプリ開発中での使い方（kubernetes.io/docs準拠）
- まず`get`で対象を絞り、`describe`でイベントを見る流れを固定化
- `logs`は`--tail`や`-f`を使い、必要最小限のログ確認
- 調査対象をNamespaceで限定（誤操作防止）

### 5) 30-60分ミニラボ
1. Nginxを1Podで起動
2. Pod状態を確認
3. Pod詳細イベント確認
4. ログ確認
5. 故意に存在しないイメージへ更新し、失敗イベントを観察

```bash
# 0) 安全確認（最重要）
kubectl config current-context
kubectl config get-contexts

# 1) namespace作成
kubectl create namespace lab-beginner

# 2) デプロイ
kubectl -n lab-beginner create deployment web --image=nginx:1.25

# 3) 状態確認
kubectl -n lab-beginner get pods -o wide
kubectl -n lab-beginner get deploy

# 4) 詳細確認
kubectl -n lab-beginner describe pod <POD_NAME>

# 5) ログ確認
kubectl -n lab-beginner logs deploy/web --tail=50

# 6) 失敗を作って観察（学習目的）
kubectl -n lab-beginner set image deploy/web nginx=nginx:does-not-exist
kubectl -n lab-beginner get pods
kubectl -n lab-beginner describe pod <POD_NAME>
```

### 6) コマンドチートシート
- `kubectl get pods -A`
- `kubectl get pods -n <ns>`
- `kubectl describe pod <pod> -n <ns>`
- `kubectl logs <pod> -n <ns> --tail=100`
- `kubectl logs -f <pod> -n <ns>`

### 7) よくあるミス & 安全策
- ミス：本番contextのまま作業
  - 安全策：作業前に`kubectl config current-context`を毎回実行
- ミス：`-n`未指定で別Namespaceを見て混乱
  - 安全策：常に`-n`明示
- ミス：ログだけ見てイベントを見ない
  - 安全策：`describe`→`logs`の順番を定着

### 8) 面接風質問
「Podが`ImagePullBackOff`のとき、最初の3手を説明してください。」

### 9) 次の一歩（公式）
- https://kubernetes.io/docs/tasks/debug/debug-application/
- https://kubernetes.io/docs/reference/kubectl/

---

## Middle（中級）
### Prerequisites
- Beginner内容を実施済み
- Deployment / Service / Label Selectorの基本理解

### 1) Topic + Level
**Topic:** `kubectl apply`と`rollout`で安全にリリースする
**Level:** Middle

### 2) なぜ実アプリ開発で重要か
実運用では「変更を安全に出して安全に戻せる」ことが重要です。Rollout履歴と状態確認ができると、障害時に素早くロールバックできます。

### 3) コア概念
- 宣言的管理（`kubectl apply -f`）
- Deploymentのローリングアップデート
- `kubectl rollout status/history/undo`
- Readiness Probeと無停止リリースの関係

### 4) アプリ開発での使い方
- マニフェストをGit管理して`apply`
- `rollout status`が完了するまで監視
- 問題時は`rollout undo`で即時復旧
- Secretは平文でGitに置かない（External SecretやSealed Secrets等を検討）

### 5) 30-60分ミニラボ
```bash
# namespace
kubectl create namespace lab-middle

# deployment作成
kubectl -n lab-middle create deployment api --image=nginx:1.25
kubectl -n lab-middle expose deployment api --port=80 --type=ClusterIP

# リリース確認
kubectl -n lab-middle rollout status deploy/api
kubectl -n lab-middle rollout history deploy/api

# 新バージョンへ更新
kubectl -n lab-middle set image deploy/api nginx=nginx:1.26
kubectl -n lab-middle rollout status deploy/api

# 問題を想定してロールバック
kubectl -n lab-middle rollout undo deploy/api
kubectl -n lab-middle rollout status deploy/api
```

### 6) コマンドチートシート
- `kubectl apply -f k8s/ -n <ns>`
- `kubectl diff -f k8s/ -n <ns>`
- `kubectl rollout status deploy/<name> -n <ns>`
- `kubectl rollout history deploy/<name> -n <ns>`
- `kubectl rollout undo deploy/<name> -n <ns>`

### 7) よくあるミス & 安全策
- ミス：`kubectl apply -f .`で想定外ファイルまで適用
  - 安全策：適用ディレクトリを明示し、事前に`kubectl diff`
- ミス：Readiness未設定で更新中にエラー流入
  - 安全策：Probe設定を必須化
- ミス：Secretをmanifestに直書き
  - 安全策：Secret管理基盤を使い、レビューで検出

### 8) 面接風質問
「`kubectl apply`と`kubectl replace`の違い、運用での使い分けは？」

### 9) 次の一歩（公式）
- https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- https://kubernetes.io/docs/tasks/manage-kubernetes-objects/declarative-config/
- https://kubernetes.io/docs/concepts/configuration/secret/

---

## Advanced（上級）
### Prerequisites
- Middle内容を実施済み
- Readiness/Liveness Probe、requests/limits、HPAの基礎理解

### 1) Topic + Level
**Topic:** 本番運用を意識した安全な変更管理（Context/Scope/権限/破壊的操作回避）
**Level:** Advanced

### 2) なぜ実アプリ開発で重要か
本番障害の多くは「誤った対象への操作」です。特に`delete`や広域`apply`ミスは影響範囲が大きい。変更前のスコープ確認と権限最小化は、機能実装と同等に重要です。

### 3) コア概念
- Context/Namespaceの明示運用
- Server-side dry-runで事前検証
- RBACによる最小権限
- Label selectorで対象を厳密化

### 4) アプリ開発での使い方
- CI/CDで`kubectl diff`と`--dry-run=server`を必須に
- 本番は限定ServiceAccount + RBACでapply
- 変更対象は`-l app=...`等で明示
- 破壊的操作前に「対象・件数・context」を3点確認

### 5) 30-60分ミニラボ
```bash
kubectl create namespace lab-advanced
kubectl -n lab-advanced create deployment app1 --image=nginx:1.25
kubectl -n lab-advanced create deployment app2 --image=httpd:2.4

# ラベル確認
kubectl -n lab-advanced get deploy --show-labels

# dry-runで安全確認
kubectl -n lab-advanced create configmap app-config \
  --from-literal=LOG_LEVEL=info \
  --dry-run=server -o yaml

# 削除前に対象確認（重要）
kubectl -n lab-advanced get deploy -l app=app1

# 注意: 破壊的コマンド例（実行前に必ずcontext/namespace/selector確認）
# kubectl -n lab-advanced delete deploy -l app=app1
```

### 6) コマンドチートシート
- `kubectl config current-context`
- `kubectl auth can-i delete deployment -n <ns>`
- `kubectl apply -f <file> --dry-run=server -o yaml`
- `kubectl get all -n <ns> -l app=<name>`
- `kubectl delete <resource> -n <ns> -l app=<name> --wait=true`

### 7) よくあるミス & 安全策
- ミス：`kubectl delete`の対象誤り
  - 安全策：同じselectorで`get`して件数確認後に削除
- ミス：本番へ直接`apply`
  - 安全策：staging検証→差分確認→本番反映
- ミス：過大権限トークン運用
  - 安全策：RBAC最小化、監査ログ確認

### 8) 面接風質問
「本番クラスタで安全に`kubectl delete`を実行する手順を、具体的コマンド付きで説明してください。」

### 9) 次の一歩（公式）
- https://kubernetes.io/docs/concepts/security/rbac-good-practices/
- https://kubernetes.io/docs/reference/using-api/server-side-apply/
- https://kubernetes.io/docs/tasks/administer-cluster/manage-resources/

---

## 安全メモ（毎回チェック）
1. `kubectl config current-context`で接続先確認
2. `-n <namespace>`を必ず指定
3. `kubectl diff` / `--dry-run=server`で事前検証
4. 破壊的コマンド（delete/apply広域）は対象を`get`で再確認
5. Secretを平文でmanifestやGitに置かない

次号では、同じ学習アーク（Beginner→Middle→Advanced）で**ConfigMap/Secret/Probe設計**に進むと実践力が上がります。