---
tags: [kubernetes, k8s, devops, learning, daily]
---

# 2026-04-18 09:25 Kubernetes Commands Magazine
[[Home]]

今日のテーマは、**アプリ開発で毎日使う Kubernetes 操作を、初級→中級→上級の学習アークで積み上げる**です。  
安全第一で、`kubectl` の実践力を伸ばします。

---

## 学習アーク1（Beginner）
### 1) Topic + Level
**Topic:** Pod/Deployment を安全に確認・更新する基本  
**Level:** Beginner

### 2) Why it matters（実務で重要な理由）
- 開発中の「動かない」を最短で切り分けるには、`get/describe/logs` が必須。
- 単体 Pod 運用ではなく Deployment で管理することで、再起動・ロールアウトが安定する。

### 3) Core concept（kubectl/Kubernetes の要点）
- `kubectl get`：現在状態の一覧把握
- `kubectl describe`：イベント・失敗理由の深掘り
- `kubectl logs`：コンテナ標準出力を確認
- `Deployment`：Pod の宣言的管理（レプリカ数・更新戦略）

### 4) アプリ開発での使い方（kubernetes.io/docs に沿った実践）
- まず namespace を分ける（例: `dev`）
- `kubectl apply -f` で宣言的に適用し、`rollout status` で完了確認
- 変更後は `logs` と `describe` で挙動を検証

### 5) 30-60分ミニラボ
1. `kubectl create namespace dev`  
2. Nginx Deployment を作成（2 replicas）  
3. `kubectl get pods -n dev` / `kubectl describe deploy -n dev`  
4. イメージを `nginx:1.27` に更新し、`kubectl rollout status` で確認  
5. `kubectl logs` でログ確認

### 6) Command cheatsheet
```bash
kubectl config current-context
kubectl get ns
kubectl create ns dev
kubectl -n dev create deployment web --image=nginx:1.26
kubectl -n dev scale deployment web --replicas=2
kubectl -n dev get deploy,pods,rs
kubectl -n dev describe deployment web
kubectl -n dev logs deploy/web --tail=100
kubectl -n dev set image deployment/web nginx=nginx:1.27
kubectl -n dev rollout status deployment/web
kubectl -n dev rollout history deployment/web
```

### 7) Common mistakes & safe practices
- **ミス:** context を確認せず本番へ apply/delete  
  **安全策:** 実行前に必ず `kubectl config current-context` と `-n` 指定。
- **ミス:** `kubectl delete -f .` のような広いスコープ  
  **安全策:** 対象ファイル/namespace を明示。破壊的操作前に一呼吸。
- **ミス:** Secret を平文で manifest に直書き  
  **安全策:** 機密値は Git に置かない。Secret 管理を分離（少なくとも base64 を過信しない）。

### 8) Interview-style question
「Deployment と Pod を直接作る運用の違いを、ロールバック観点で説明してください。」

### 9) Next-step resources
- https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- https://kubernetes.io/docs/tasks/debug/debug-application/
- https://kubernetes.io/docs/reference/kubectl/

---

## 学習アーク2（Middle）
### 1) Topic + Level
**Topic:** Service/Probe/ConfigMap で“壊れにくい”アプリ公開  
**Level:** Middle  
**Prerequisites:** Pod/Deployment の基本、`get/describe/logs`、namespace 運用

### 2) Why it matters
- 「起動したけど通信できない」「たまに落ちる」を防ぐ鍵は Service と Probe。
- 設定値をイメージに焼き込まず、ConfigMap で環境差分管理できる。

### 3) Core concept
- `Service`：Pod 群への安定した到達点
- `readinessProbe`：準備完了前のトラフィック流入を防ぐ
- `livenessProbe`：ハング時の自己回復
- `ConfigMap`：非機密設定を外出し

### 4) アプリ開発での使い方
- Deployment + Service をセットで定義
- Probe の閾値（initialDelay/period/failureThreshold）を実アプリに合わせる
- ConfigMap を環境ごとに分離し、manifest は再利用

### 5) 30-60分ミニラボ
1. `dev` namespace に簡易 API Deployment を作成  
2. `readinessProbe` と `livenessProbe` を追加  
3. ClusterIP Service を作成して疎通確認  
4. ConfigMap から環境変数を注入  
5. Probe 設定を意図的に厳しくして失敗イベントを観察→調整

### 6) Command cheatsheet
```bash
kubectl -n dev expose deployment web --port=80 --target-port=80 --type=ClusterIP
kubectl -n dev get svc,endpoints
kubectl -n dev get pod -w
kubectl -n dev describe pod <pod-name>
kubectl -n dev create configmap app-config --from-literal=APP_MODE=dev
kubectl -n dev get configmap app-config -o yaml
kubectl -n dev apply -f deployment-with-probes.yaml
kubectl -n dev get events --sort-by=.lastTimestamp
```

### 7) Common mistakes & safe practices
- **ミス:** Probe が厳しすぎて再起動ループ  
  **安全策:** readiness と liveness の目的を分離、段階的調整。
- **ミス:** ConfigMap に秘密情報を混在  
  **安全策:** 機密は Secret/外部 Secret 管理へ分離。
- **ミス:** Service selector 不一致で通信不可  
  **安全策:** `labels` と `selector` を必ず突合。

### 8) Interview-style question
「readinessProbe と livenessProbe を同一設定にすると何が起きやすいですか？」

### 9) Next-step resources
- https://kubernetes.io/docs/concepts/services-networking/service/
- https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/
- https://kubernetes.io/docs/concepts/configuration/configmap/

---

## 学習アーク3（Advanced）
### 1) Topic + Level
**Topic:** 安全なロールアウト戦略（RollingUpdate/rollback/差分確認）  
**Level:** Advanced  
**Prerequisites:** Deployment/Service/Probe/ConfigMap の実運用、イベント解析

### 2) Why it matters
- 本番障害の多くは「変更時」に起こる。安全な更新手順が品質を決める。
- デプロイを速くするより、**安全に戻せる**設計が重要。

### 3) Core concept
- `RollingUpdate`：段階的更新（`maxSurge`, `maxUnavailable`）
- `rollout history/undo`：変更履歴と復旧
- 差分確認：適用前後の差異を理解して事故を減らす

### 4) アプリ開発での使い方
- 更新前に current context / namespace /対象 manifest を再確認
- 小さく更新し、`rollout status` とメトリクス/ログで検証
- 異常時は即 `rollout undo`。復旧後に原因分析を残す

### 5) 30-60分ミニラボ
1. Deployment に RollingUpdate 戦略を明示  
2. 正常版→不具合版イメージへ更新  
3. `rollout status/history` とイベントを確認  
4. `rollout undo` で復旧  
5. ポストモーテム観点で「検知・復旧時間・再発防止」をメモ

### 6) Command cheatsheet
```bash
kubectl -n dev apply -f deploy.yaml
kubectl -n dev get deploy web -o yaml
kubectl -n dev set image deployment/web nginx=nginx:bad-tag
kubectl -n dev rollout status deployment/web
kubectl -n dev rollout history deployment/web
kubectl -n dev rollout undo deployment/web
kubectl -n dev get events --sort-by=.lastTimestamp
kubectl diff -f deploy.yaml
```

### 7) Common mistakes & safe practices
- **ミス:** `kubectl apply -f` の対象ディレクトリを誤って広範囲適用  
  **安全策:** 事前に `kubectl diff -f <file-or-dir>`、適用単位を小さく。
- **ミス:** 本番でいきなり破壊的変更（ラベル変更/selector変更）  
  **安全策:** 段階移行、互換期間、ロールバック手順を先に準備。
- **ミス:** 削除系コマンドを確認なしで実行  
  **安全策:** `delete` 前に context/namespace/対象名を復唱。必要ならバックアップ。

### 8) Interview-style question
「`maxSurge=0` と `maxUnavailable=1` の組み合わせは、可用性と更新速度にどう影響しますか？」

### 9) Next-step resources
- https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#strategy
- https://kubernetes.io/docs/concepts/cluster-administration/manage-deployment/
- https://kubernetes.io/docs/tasks/manage-kubernetes-objects/declarative-config/
- https://kubernetes.io/docs/concepts/security/

---

## 今日の安全リマインド（重要）
- 破壊的コマンド（`delete`, 広域 `apply`）前に、**context / namespace / 対象** を必ず確認。
- Secret を manifest に直書きしない（特に Git 管理対象）。
- まず `dev` で検証し、段階的に環境展開する。
