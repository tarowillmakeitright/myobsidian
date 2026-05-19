---
tags: [kubernetes, k8s, devops, learning, daily]
---

# Daily Kubernetes Commands Magazine (2026-05-19 09:25)

[[Home]]

## 今号のテーマ
**「kubectl で安全にデプロイを観察・更新する」**

---

## Beginner（初級）
### 1) Topic + Level
**Topic:** Pod / Deployment の状態確認の基本コマンド
**Level:** Beginner

### 2) なぜ実アプリ開発で重要か
アプリが「動かない」「遅い」「再起動を繰り返す」とき、最初に必要なのは正確な状況把握です。`kubectl get/describe/logs` を正しく使えると、原因切り分けが速くなり、障害対応時間を短縮できます。

### 3) コア概念（kubectl / Kubernetes）
- `kubectl get`：リソースの一覧・状態確認
- `kubectl describe`：イベントや詳細情報（失敗理由の把握に強い）
- `kubectl logs`：コンテナ標準出力ログ確認
- Namespace：環境やチーム単位の論理分離

### 4) アプリ開発時の使い方（kubernetes.io/docs ベストプラクティス寄り）
- 開発・検証・本番を Namespace で分離
- 障害調査は **get → describe → logs** の順で実施
- まず Read-only コマンドで観察してから変更操作へ

### 5) 30-60分ミニラボ（目安40分）
> 前提: `kubectl` がクラスタに接続済み

1. 現在コンテキスト確認（誤操作防止）
```bash
kubectl config current-context
kubectl config get-contexts
```
2. 検証用 Namespace 作成
```bash
kubectl create namespace magazine-lab
```
3. Nginx Deployment 作成
```bash
kubectl -n magazine-lab create deployment web --image=nginx:1.27
```
4. 状態確認
```bash
kubectl -n magazine-lab get deploy,po
kubectl -n magazine-lab describe deployment web
kubectl -n magazine-lab logs deploy/web
```
5. イメージをわざと不正にして失敗観察
```bash
kubectl -n magazine-lab set image deployment/web nginx=nginx:does-not-exist
kubectl -n magazine-lab get po
kubectl -n magazine-lab describe po -l app=web
```
6. 正しいイメージへ戻す
```bash
kubectl -n magazine-lab set image deployment/web nginx=nginx:1.27
kubectl -n magazine-lab rollout status deployment/web
```

### 6) コマンドチートシート
```bash
kubectl get ns
kubectl -n <ns> get po
kubectl -n <ns> describe po <pod>
kubectl -n <ns> logs <pod>
kubectl -n <ns> logs -f <pod>
kubectl -n <ns> rollout status deploy/<name>
```

### 7) よくあるミス & 安全策
- **ミス:** 間違った context で操作
  - **安全策:** 実行前に必ず `kubectl config current-context`
- **ミス:** `default` namespace に作業を混在
  - **安全策:** `-n <ns>` を明示
- **ミス:** いきなり delete/apply
  - **安全策:** 先に `get/describe` で現状確認

### 8) 面接っぽい質問
`kubectl describe pod` と `kubectl logs` は何が違い、障害調査でどの順に使いますか？

### 9) 次の一歩（公式）
- Overview: <https://kubernetes.io/docs/concepts/overview/>
- kubectl cheatsheet: <https://kubernetes.io/docs/reference/kubectl/cheatsheet/>
- Debug Pods: <https://kubernetes.io/docs/tasks/debug/debug-application/debug-pods/>

---

## Middle（中級）
### 前提（Prerequisites）
- Deployment / Pod / Namespace の基本を理解
- `kubectl get/describe/logs` を使える

### 1) Topic + Level
**Topic:** Rolling Update / Rollback を安全に運用する
**Level:** Middle

### 2) なぜ実アプリ開発で重要か
実運用ではゼロダウンタイム更新と、失敗時の迅速な切り戻しが必須です。Deployment の更新履歴・進行状況を把握できると、デリバリー品質が上がります。

### 3) コア概念
- RollingUpdate 戦略
- `rollout status/history/undo`
- ReplicaSet と世代管理

### 4) アプリ開発時の使い方（ベストプラクティス）
- 段階的更新（RollingUpdate）を標準化
- ヘルスチェック（readiness/liveness）前提で切替
- 不具合検知時は即 rollback できるよう履歴を維持

### 5) 30-60分ミニラボ（目安45分）
1. 既存 Deployment の更新履歴確認
```bash
kubectl -n magazine-lab rollout history deployment/web
```
2. バージョン更新
```bash
kubectl -n magazine-lab set image deployment/web nginx=nginx:1.28
kubectl -n magazine-lab rollout status deployment/web
```
3. 履歴確認
```bash
kubectl -n magazine-lab rollout history deployment/web
```
4. 不具合想定で rollback
```bash
kubectl -n magazine-lab rollout undo deployment/web
kubectl -n magazine-lab rollout status deployment/web
```
5. 変更差分を宣言的に確認（可能なら）
```bash
kubectl -n magazine-lab get deploy web -o yaml
```

### 6) コマンドチートシート
```bash
kubectl -n <ns> set image deploy/<name> <container>=<image:tag>
kubectl -n <ns> rollout status deploy/<name>
kubectl -n <ns> rollout history deploy/<name>
kubectl -n <ns> rollout undo deploy/<name>
```

### 7) よくあるミス & 安全策
- **ミス:** `:latest` タグ利用で再現性低下
  - **安全策:** バージョン固定タグ（可能なら digest）
- **ミス:** readiness 未設定で更新時にエラー配信
  - **安全策:** readinessProbe を必ず定義
- **ミス:** 本番でいきなり `apply -f .`
  - **安全策:** 対象ファイルと namespace を明示、レビュー後実行

### 8) 面接っぽい質問
Deployment の RollingUpdate で、`maxUnavailable` と `maxSurge` の調整がユーザー体験にどう影響しますか？

### 9) 次の一歩（公式）
- Deployments: <https://kubernetes.io/docs/concepts/workloads/controllers/deployment/>
- Update strategy: <https://kubernetes.io/docs/tutorials/kubernetes-basics/update/update-intro/>
- Probes: <https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/>

---

## Advanced（上級）
### 前提（Prerequisites）
- Rolling Update / Rollback の実践経験
- YAML マニフェスト運用の基礎理解
- Service/Ingress の基本理解

### 1) Topic + Level
**Topic:** 宣言的運用（apply）と安全な変更管理（diff / dry-run）
**Level:** Advanced

### 2) なぜ実アプリ開発で重要か
チーム開発では、再現可能な IaC（Infrastructure as Code）が必須です。宣言的管理により、環境差分を減らし、レビュー可能な変更フローを作れます。

### 3) コア概念
- 宣言的管理: `kubectl apply -f`
- 変更確認: `kubectl diff`
- 事前検証: `--dry-run=client|server`
- field management / managedFields（誰が何を管理しているか）

### 4) アプリ開発時の使い方（ベストプラクティス）
- Git 管理された manifest を source of truth にする
- `diff` と `dry-run` を本適用前に必ず実施
- Secret を平文で Git に置かない（External Secrets / Sealed Secrets 等を検討）

### 5) 30-60分ミニラボ（目安55分）
1. Deployment マニフェストを出力
```bash
kubectl -n magazine-lab get deploy web -o yaml > web-deploy.yaml
```
2. （手動編集）replicas を 1→2 に変更
3. 差分確認
```bash
kubectl -n magazine-lab diff -f web-deploy.yaml
```
4. サーバー側 dry-run
```bash
kubectl -n magazine-lab apply --dry-run=server -f web-deploy.yaml
```
5. 本適用
```bash
kubectl -n magazine-lab apply -f web-deploy.yaml
kubectl -n magazine-lab get deploy web
```
6. 後片付け（必要なら）
```bash
kubectl delete ns magazine-lab
```

### 6) コマンドチートシート
```bash
kubectl -n <ns> get <kind> <name> -o yaml
kubectl -n <ns> diff -f <file.yaml>
kubectl -n <ns> apply --dry-run=server -f <file.yaml>
kubectl -n <ns> apply -f <file.yaml>
```

### 7) よくあるミス & 安全策
- **ミス:** `kubectl apply -f .` の対象誤り
  - **安全策:** 対象ファイルを明示、`kubectl diff` 先行
- **ミス:** Secret を平文で manifest/Git 管理
  - **安全策:** Secret 管理基盤を利用、最小権限でアクセス
- **ミス:** 誤ったクラスタへ破壊的コマンド実行
  - **安全策:** `current-context` と `-n` を毎回確認

> ⚠️ **注意（破壊的操作）**
> `kubectl delete` / `kubectl apply` はスコープ（file, namespace, context）を誤ると重大事故になります。実行前に必ず:  
> 1) `kubectl config current-context`  
> 2) 対象 namespace  
> 3) 対象ファイルの中身  
> を確認してください。

### 8) 面接っぽい質問
宣言的運用（apply）を採用する場合、命令的運用（set image など）と比べた利点・欠点を、チーム開発観点で説明してください。

### 9) 次の一歩（公式）
- Declarative config: <https://kubernetes.io/docs/tasks/manage-kubernetes-objects/declarative-config/>
- kubectl apply reference: <https://kubernetes.io/docs/reference/kubectl/generated/kubectl_apply/>
- Secret good practices: <https://kubernetes.io/docs/concepts/security/secrets-good-practices/>

---

## 今日の総括
- 初級: 観察系コマンドで状況把握
- 中級: 安全な更新と即時ロールバック
- 上級: 宣言的運用 + 事前検証で事故を防ぐ

次号はこの流れを維持しつつ、Service/Ingress/NetworkPolicy を絡めた実践編に進むと効果的です。