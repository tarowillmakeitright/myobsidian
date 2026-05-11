---
tags:
  - kubernetes
  - k8s
  - devops
  - learning
  - daily
---

# 2026-05-11 09:25 Kubernetes Commands Magazine
[[Home]]

## 今日の学習アーク（Beginner → Middle → Advanced）
1. **Beginner:** `kubectl get/describe/logs` で「いま起きていること」を正確に観測する
2. **Middle:** Deployment のローリングアップデートとロールバックを安全に運用する
3. **Advanced:** Readiness/Liveness Probe とリソース制御で、障害に強い本番運用を設計する

---

## 1) Topic + Level
### Beginner
**トピック:** 観測の基本コマンド（`get`, `describe`, `logs`）

### Middle
**トピック:** 安全なデプロイ戦略（Deployment 更新・履歴・ロールバック）
**前提条件:**
- Pod / Deployment / ReplicaSet の関係を説明できる
- `kubectl get pods -n <namespace>` が使える
- namespace/context の違いを理解している

### Advanced
**トピック:** Probe + リソース制御（requests/limits）で可用性と安定性を上げる
**前提条件:**
- Deployment マニフェストを編集して `kubectl apply -f` できる
- ローリングアップデートの流れを理解している
- アプリのヘルスチェックエンドポイント（例: `/healthz`）の意味を理解している

---

## 2) なぜ実アプリ開発で重要か
- **障害対応が速くなる:** まず観測（get/describe/logs）ができないと、原因切り分けが遅れる。
- **リリース事故を減らせる:** Deployment の履歴とロールバックを使えば、壊れたリリースを短時間で戻せる。
- **SLO/SLAを守りやすい:** Probe とリソース制御で「起動したが使えないPod」や「ノード圧迫」を抑制できる。

---

## 3) コア概念（kubectl / Kubernetes）
### A. `kubectl get`
- リソース一覧を取得。現在状態の俯瞰に使う。
- 例: `kubectl get pods -n demo -o wide`

### B. `kubectl describe`
- イベント・条件・スケジューリング情報を詳細表示。
- 例: `kubectl describe pod <pod名> -n demo`

### C. `kubectl logs`
- アプリ内部のエラー確認。
- 例: `kubectl logs <pod名> -n demo --tail=100`

### D. Deployment の更新/履歴
- `kubectl set image` で更新、`rollout status/history/undo` で運用。
- 「更新できたか」だけでなく「戻せるか」が本番品質。

### E. Readiness/Liveness Probe
- **Readiness:** 受信可能状態か（Service へ流すか）
- **Liveness:** プロセスが生存/健全か（再起動要否）

### F. requests/limits
- **requests:** スケジューリング時の最低必要量
- **limits:** 上限。暴走時の被害を局所化

---

## 4) 実アプリ開発での使い方（kubernetes.io/docs ベストプラクティス準拠）
- マニフェストは Git 管理し、`kubectl apply -f` で宣言的に適用する。
- 本番では namespace を分離（例: `dev`, `stg`, `prod`）し、誤操作を減らす。
- 更新前に `kubectl config current-context` と `kubectl get ns` で対象確認。
- Probe を設定し、Readiness が通る前にトラフィックを流さない。
- `resources.requests/limits` を明示し、クラスタ全体の安定性を守る。
- Secret は `Secret` リソースや外部Secret管理を利用し、**平文をマニフェストへ埋め込まない**。

---

## 5) 30〜60分ミニラボ
**テーマ:** 「安全な更新 + 障害時ロールバック」を体験する（約45分）

### 事前安全チェック（超重要）
```bash
kubectl config current-context
kubectl get ns
```
- 期待しない context の場合は中断。
- `prod` 相当 namespace へ誤適用しない。

### 手順
1. **namespace 作成**
```bash
kubectl create ns k8s-mag-demo
```

2. **初期Deployment作成（nginx:1.25）**
```bash
kubectl create deployment web --image=nginx:1.25 -n k8s-mag-demo
kubectl expose deployment web --port=80 --type=ClusterIP -n k8s-mag-demo
kubectl rollout status deployment/web -n k8s-mag-demo
```

3. **状態観測（Beginnerパート）**
```bash
kubectl get all -n k8s-mag-demo
kubectl describe deployment web -n k8s-mag-demo
kubectl get pods -n k8s-mag-demo
```

4. **イメージ更新（Middleパート）**
```bash
kubectl set image deployment/web nginx=nginx:1.27 -n k8s-mag-demo
kubectl rollout status deployment/web -n k8s-mag-demo
kubectl rollout history deployment/web -n k8s-mag-demo
```

5. **意図的に不正タグへ更新し、失敗を観測**
```bash
kubectl set image deployment/web nginx=nginx:does-not-exist -n k8s-mag-demo
kubectl rollout status deployment/web -n k8s-mag-demo
kubectl get pods -n k8s-mag-demo
kubectl describe pods -n k8s-mag-demo
```

6. **ロールバック（Middle→Advanced運用意識）**
```bash
kubectl rollout undo deployment/web -n k8s-mag-demo
kubectl rollout status deployment/web -n k8s-mag-demo
kubectl rollout history deployment/web -n k8s-mag-demo
```

7. **片付け（破壊的コマンド注意）**
```bash
# 実行前に対象namespaceを再確認
kubectl delete ns k8s-mag-demo
```

---

## 6) コマンドチートシート
```bash
# 文脈確認
kubectl config current-context
kubectl config get-contexts

# 基本観測
kubectl get pods -A
kubectl get deploy -n <ns>
kubectl describe pod <pod> -n <ns>
kubectl logs <pod> -n <ns> --tail=100

# デプロイ更新・追跡
kubectl set image deployment/<name> <container>=<image>:<tag> -n <ns>
kubectl rollout status deployment/<name> -n <ns>
kubectl rollout history deployment/<name> -n <ns>
kubectl rollout undo deployment/<name> -n <ns>

# 宣言的適用
kubectl apply -f <manifest.yaml>
kubectl diff -f <manifest.yaml>
```

---

## 7) よくあるミス & 安全策
### よくあるミス
- `kubectl apply -f .` を意図しないディレクトリで実行
- context 未確認で本番クラスタへ適用
- `latest` タグ依存で再現性が崩壊
- Secret を ConfigMap や平文 YAML に記載
- `kubectl delete` を `-n` 指定忘れで実行

### 安全策
- 破壊的操作の前に必ず: `kubectl config current-context` / 対象 namespace 再確認
- `kubectl diff -f` で変更差分を先に確認
- イメージは固定タグ（可能なら digest）を利用
- 機密情報は Secret + RBAC 最小権限で管理
- 本番操作はレビュー済みマニフェストを使い、手打ちコマンドを減らす

---

## 8) 面接スタイル質問（1問）
**質問:**
Deployment のローリングアップデート中に一部 Pod が起動失敗している場合、あなたはどの `kubectl` コマンドをどの順番で使って原因特定し、どの判断基準でロールバックを実行しますか？

---

## 9) 次の一歩（公式ドキュメント中心）
- Kubernetes Concepts: Workloads
  - https://kubernetes.io/docs/concepts/workloads/
- Deployments
  - https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- kubectl Overview
  - https://kubernetes.io/docs/reference/kubectl/
- Probes (Liveness, Readiness, Startup)
  - https://kubernetes.io/docs/concepts/configuration/liveness-readiness-startup-probes/
- Manage Resources for Containers
  - https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/
- Secrets
  - https://kubernetes.io/docs/concepts/configuration/secret/
- Good Practices for Kubernetes Secrets
  - https://kubernetes.io/docs/concepts/security/secrets-good-practices/

---

次号予告: **Ingress と Service (ClusterIP/NodePort/LoadBalancer) の使い分け** を Beginner→Advanced で掘り下げます。
