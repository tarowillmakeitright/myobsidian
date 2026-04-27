---
tags:
  - kubernetes
  - k8s
  - devops
  - learning
  - daily
---

# 2026-04-27 09:25 Kubernetes Commands Magazine
[[Home]]

今日のテーマは、**同じアプリ開発文脈で Beginner → Middle → Advanced と段階的に深める学習アーク**です。  
題材: **Deployment の安全な更新と運用（rollout / probe / rollback）**

---

## A. Beginner（初級）
### 1) Topic + Level
**Topic:** Deployment を `kubectl` でデプロイ・確認する基本  
**Level:** Beginner

### 2) Why it matters（実アプリでなぜ重要か）
ローカルで動いたアプリを「チームで再現可能」にし、同じ手順で環境差異を減らせるから。  
`kubectl apply` と `kubectl get/describe/logs` が使えるだけで、開発中の不具合切り分け速度が大きく上がる。

### 3) Core concept（コア概念）
- **Deployment**: Pod の望ましい状態を宣言し、ReplicaSet 経由で維持
- **Pod**: コンテナ実行の最小単位
- **Service**: Pod への安定したアクセス経路
- **`kubectl apply -f`**: 宣言的に状態を適用
- **`kubectl get` / `describe` / `logs`**: 状態確認の基本三点

### 4) App 開発での使い方（best practices 準拠）
- マニフェストを Git 管理し、`apply` で再現可能な運用を行う
- `latest` タグ固定は避け、**明示タグ**（例: `myapp:1.0.3`）を使う
- まず namespace を分ける（dev/stg/prod の衝突防止）

### 5) 30–60分ミニラボ
**目標:** nginx Deployment を作って状態確認する（30分）

```bash
# 0) いま触るクラスタ確認（超重要）
kubectl config current-context
kubectl config get-contexts

# 1) namespace 作成
kubectl create namespace magazine-lab

# 2) Deployment 作成
kubectl -n magazine-lab create deployment web --image=nginx:1.27

# 3) Service 作成
kubectl -n magazine-lab expose deployment web --port=80 --type=ClusterIP

# 4) 状態確認
kubectl -n magazine-lab get deploy,rs,pod,svc
kubectl -n magazine-lab describe deployment web
kubectl -n magazine-lab logs deploy/web
```

### 6) Command cheatsheet（初級）
```bash
kubectl config current-context
kubectl get ns
kubectl create ns <name>
kubectl -n <ns> get all
kubectl -n <ns> describe deploy <name>
kubectl -n <ns> logs deploy/<name>
kubectl apply -f <file.yaml>
```

### 7) Common mistakes + safe practices
- **誤り:** context 未確認で別クラスタに apply  
  **対策:** 実行前に毎回 `kubectl config current-context`
- **誤り:** `default` namespace に全部投入  
  **対策:** 学習時から namespace を明示
- **誤り:** いきなり `kubectl delete -f .`  
  **対策:** 削除コマンド前に対象ファイル・namespace・context を再確認

### 8) Interview question（初級）
「Deployment と Pod を直接作る方法の違いは？運用でどちらを選ぶべきか？」

### 9) Next-step resources
- https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- https://kubernetes.io/docs/tasks/access-application-cluster/access-cluster/
- https://kubernetes.io/docs/reference/kubectl/

---

## B. Middle（中級）
### Prerequisites
- Beginner 内容を実施済み
- `kubectl get/describe/logs` で最低限の調査ができる
- Deployment / Service の役割を説明できる

### 1) Topic + Level
**Topic:** RollingUpdate と rollout 管理（履歴・一時停止・再開・ロールバック）  
**Level:** Middle

### 2) Why it matters
実アプリ更新では「止めない更新」が必須。  
不具合時に**素早く戻す（rollback）**運用を持つことが、可用性とユーザー体験に直結する。

### 3) Core concept
- **RollingUpdate**: Pod を段階的に入れ替える
- **`kubectl rollout status`**: 更新進行を監視
- **`kubectl rollout history`**: 改訂履歴確認
- **`kubectl rollout undo`**: 前版へ復帰
- **`maxUnavailable / maxSurge`**: 更新時の安全性パラメータ

### 4) App 開発での使い方
- CI/CD で image tag を更新 → `apply`
- 更新後は `rollout status` を自動確認
- 問題時に `rollout undo` を標準手順化
- readinessProbe を設定して「準備できた Pod のみ」トラフィック受け入れ

### 5) 30–60分ミニラボ
**目標:** 更新とロールバックを体験（45分）

```bash
# 1) 既存 web を更新
kubectl -n magazine-lab set image deployment/web nginx=nginx:1.27.1
kubectl -n magazine-lab rollout status deployment/web
kubectl -n magazine-lab rollout history deployment/web

# 2) 意図的に壊れたイメージへ（学習用）
kubectl -n magazine-lab set image deployment/web nginx=nginx:does-not-exist
kubectl -n magazine-lab rollout status deployment/web --timeout=60s
kubectl -n magazine-lab get pods
kubectl -n magazine-lab describe pod -l app=web

# 3) ロールバック
kubectl -n magazine-lab rollout undo deployment/web
kubectl -n magazine-lab rollout status deployment/web
```

### 6) Command cheatsheet（中級）
```bash
kubectl -n <ns> set image deployment/<name> <container>=<image:tag>
kubectl -n <ns> rollout status deployment/<name>
kubectl -n <ns> rollout history deployment/<name>
kubectl -n <ns> rollout undo deployment/<name>
kubectl -n <ns> get events --sort-by=.metadata.creationTimestamp
```

### 7) Common mistakes + safe practices
- **誤り:** タグなし/曖昧タグで更新追跡不能  
  **対策:** immutable に近いバージョンタグ運用
- **誤り:** readinessProbe なしで切替、5xx 発生  
  **対策:** probe 設定と rollout 監視をセット運用
- **誤り:** 失敗時ログを見ず再 apply 連打  
  **対策:** `describe` と events で原因特定してから再実行

### 8) Interview question（中級）
「RollingUpdate の `maxUnavailable` と `maxSurge` をどう設計すると、可用性と更新速度を両立できますか？」

### 9) Next-step resources
- https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#strategy
- https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/
- https://kubernetes.io/docs/concepts/cluster-administration/logging/

---

## C. Advanced（上級）
### Prerequisites
- Middle 内容を実施済み
- rollout/rollback を自力で実行できる
- probe の必要性を理解している

### 1) Topic + Level
**Topic:** ConfigMap/Secret の安全運用 + 本番を意識した apply 戦略  
**Level:** Advanced

### 2) Why it matters
実アプリでは設定変更や機密情報の扱いが最頻出。  
ここを誤ると情報漏えい・障害・監査問題に直結する。

### 3) Core concept
- **ConfigMap**: 非機密設定
- **Secret**: 機密データ（ただし base64 は暗号化ではない）
- **`envFrom` / volume マウント**: 設定注入方法
- **Server-Side Apply**: フィールド所有を明確化
- **`kubectl diff`**: 変更前確認で事故予防

### 4) App 開発での使い方
- 機密情報は Secret + 外部シークレット管理（可能なら）
- Git に平文シークレットを置かない（SealedSecrets/External Secrets 等を検討）
- 本番適用前に `kubectl diff`、適用後に `rollout status`
- RBAC 最小権限で Secret 参照範囲を制限

### 5) 30–60分ミニラボ
**目標:** 安全な設定注入と変更確認（60分）

```bash
# 0) context / namespace 再確認（破壊的誤操作防止）
kubectl config current-context
kubectl get ns

# 1) ConfigMap 作成
kubectl -n magazine-lab create configmap web-config --from-literal=APP_MODE=dev

# 2) Secret 作成（実運用では値を履歴に残さない工夫を）
kubectl -n magazine-lab create secret generic web-secret --from-literal=API_KEY='dummy-key'

# 3) 変更差分を先に確認（例: マニフェストを用意した前提）
kubectl -n magazine-lab diff -f ./k8s/

# 4) 適用
kubectl -n magazine-lab apply -f ./k8s/

# 5) 反映確認
kubectl -n magazine-lab rollout status deployment/web
kubectl -n magazine-lab describe deploy web
```

### 6) Command cheatsheet（上級）
```bash
kubectl -n <ns> create configmap <name> --from-literal=KEY=VALUE
kubectl -n <ns> create secret generic <name> --from-literal=KEY=VALUE
kubectl -n <ns> get secret <name> -o yaml
kubectl -n <ns> diff -f <dir-or-file>
kubectl -n <ns> apply -f <dir-or-file> --server-side
kubectl auth can-i get secrets -n <ns>
```

### 7) Common mistakes + safe practices
- **誤り:** Secret を Git に平文保存  
  **対策:** 平文コミット禁止、外部 secret 管理連携
- **誤り:** `kubectl apply -f .` をリポジトリルートで実行  
  **対策:** 対象ディレクトリを限定し、`kubectl diff` を先に実施
- **誤り:** `kubectl delete` のスコープ誤り（全 namespace 削除等）  
  **対策:** `--namespace` 明示、`--context` 明示、実行前に対象表示
- **注意:** `kubectl get secret -o yaml` の出力共有は機密漏えいリスク

### 8) Interview question（上級）
「Kubernetes で Secret を安全に扱うために、アプリ・CI/CD・クラスタ権限の3層でどう設計しますか？」

### 9) Next-step resources
- https://kubernetes.io/docs/concepts/configuration/configmap/
- https://kubernetes.io/docs/concepts/configuration/secret/
- https://kubernetes.io/docs/reference/using-api/server-side-apply/
- https://kubernetes.io/docs/concepts/security/

---

## 安全メモ（毎回の運用チェック）
1. `kubectl config current-context` を最初に確認  
2. `--namespace` を省略しない  
3. 破壊的コマンド（delete/replace/force）は対象を表示してから実行  
4. Secret をログ・画面共有・Git に残さない

次号予告（学習アーク継続）: **Pod 障害調査（CrashLoopBackOff 深掘り） Beginner → Middle → Advanced**
