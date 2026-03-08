---
tags: [kubernetes, k8s, devops, learning, daily]
created: 2026-03-06 09:25
---

# Daily Kubernetes Commands Magazine (2026-03-06 09:25)
[[Home]]

今日のテーマは、**Beginner → Middle → Advanced** の学習アークで進めます。  
題材は「**アプリ開発で実際に使う Deployment 運用と安全な kubectl 操作**」です。

---

## Arc 1 — Beginner

### 1) Topic + Level
**Topic:** Deployment/Pod の基本と安全な `kubectl` 操作  
**Level:** Beginner

### 2) Why it matters（なぜ実務で重要か）
ローカルでは動くアプリでも、本番では「再起動」「複製」「更新」が必要です。  
Kubernetes の Deployment を理解すると、アプリの安定稼働・ローリングアップデート・障害復旧を標準化できます。

### 3) Core concept（kubectl/Kubernetes の要点）
- `Pod`: コンテナ実行単位（短命・再作成される）
- `Deployment`: Pod の望ましい状態（レプリカ数・更新戦略）を管理
- `Service`: Pod への安定したアクセス経路
- よく使うコマンド:
  - `kubectl get pods,deploy,svc`
  - `kubectl describe pod <name>`
  - `kubectl logs <pod>`
  - `kubectl apply -f <file>`

### 4) App開発での使い方（kubernetes.io/docs ベストプラクティス準拠）
- マニフェストを Git 管理し、`kubectl apply -f` で宣言的に反映
- イメージタグは `:latest` ではなく明示タグを利用
- 設定値は ConfigMap、機密値は Secret（ただし平文管理しない）
- `resources.requests/limits` を設定してノイジーネイバーを回避

### 5) 30–60分ミニラボ
**目標:** NGINX Deployment を作成し、更新と確認を体験（約40分）
1. Namespace 作成
   - `kubectl create namespace lab-beginner`
2. Deployment 作成（例: nginx:1.27）
   - `kubectl -n lab-beginner create deployment web --image=nginx:1.27`
3. レプリカを3へ
   - `kubectl -n lab-beginner scale deployment web --replicas=3`
4. 状態確認
   - `kubectl -n lab-beginner get deploy,pods -o wide`
5. ローリング更新
   - `kubectl -n lab-beginner set image deployment/web nginx=nginx:1.27.1`
   - `kubectl -n lab-beginner rollout status deployment/web`
6. ロールバック体験
   - `kubectl -n lab-beginner rollout undo deployment/web`

### 6) Command cheatsheet
```bash
kubectl config get-contexts
kubectl config current-context
kubectl get ns
kubectl -n lab-beginner get all
kubectl -n lab-beginner describe deploy web
kubectl -n lab-beginner logs -l app=web --tail=100
kubectl -n lab-beginner rollout history deploy/web
```

### 7) Common mistakes + safe practices
- ❌ `kubectl apply -f .` を誤ディレクトリで実行（意図しない大量反映）
- ❌ context 未確認のまま本番クラスタへ操作
- ❌ Secret を Git に平文コミット
- ✅ 実行前に `kubectl config current-context` を毎回確認
- ✅ 破壊的操作前は対象を明示（`-n`, リソース名）
- ✅ 可能なら `--dry-run=client -o yaml` で事前確認

### 8) Interview-style question
「Deployment と StatefulSet はどう使い分けますか？実アプリ例（Web API / DB）で説明してください。」

### 9) Next-step resources（公式中心）
- Kubernetes Concepts: https://kubernetes.io/docs/concepts/
- Deployment: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- kubectl overview: https://kubernetes.io/docs/reference/kubectl/

---

## Arc 2 — Middle

### Prerequisites
- Pod / Deployment / Service の基本理解
- `kubectl get/describe/logs/apply` を使えること

### 1) Topic + Level
**Topic:** Probes・Resources・RollingUpdate の実践運用  
**Level:** Middle

### 2) Why it matters
本番障害の多くは「起動直後の不安定」「過負荷」「無停止更新失敗」が原因です。  
readiness/liveness/startup probe と resources 設定は、ユーザー影響を最小化する中核です。

### 3) Core concept
- `readinessProbe`: トラフィックを受ける準備可否
- `livenessProbe`: プロセス異常時の自動再起動
- `startupProbe`: 起動が遅いアプリの誤再起動防止
- `resources.requests/limits`: スケジューリングと上限
- RollingUpdate: `maxSurge`, `maxUnavailable` の調整

### 4) App開発での使い方
- API サーバーに `/healthz` `/readyz` を実装
- readiness OK になるまで Service に載せない
- CPU/メモリ request を実測ベースで設定し、limit で暴走抑制
- 本番前に `rollout status` と失敗時 `rollout undo` を手順化

### 5) 30–60分ミニラボ
**目標:** Probe と resources を持つ Deployment を適用（約50分）
1. `lab-middle` Namespace 作成
2. 以下項目を含む manifest を作成・適用
   - readiness/liveness/startup probe
   - requests/limits
   - RollingUpdate 設定
3. `kubectl apply -f deployment.yaml -n lab-middle`
4. `kubectl describe pod` で Probe 状態確認
5. わざと失敗する image に更新し、`rollout status` の失敗と `rollout undo` を確認

### 6) Command cheatsheet
```bash
kubectl -n lab-middle apply -f deployment.yaml
kubectl -n lab-middle get deploy,pods
kubectl -n lab-middle describe pod <pod-name>
kubectl -n lab-middle rollout status deploy/app
kubectl -n lab-middle rollout undo deploy/app
kubectl top pod -n lab-middle
```

### 7) Common mistakes + safe practices
- ❌ liveness を厳しすぎる設定にして再起動ループ
- ❌ requests 未設定でノード圧迫
- ❌ rollout 監視せず更新完了と思い込む
- ✅ startupProbe で起動時間を吸収
- ✅ canary 的に少数環境で先に検証
- ✅ `kubectl diff -f` で差分確認してから apply

### 8) Interview-style question
「readinessProbe と livenessProbe を逆に設定すると、どんな障害が起きますか？」

### 9) Next-step resources
- Probes: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/
- Resource Management: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/
- Rolling Updates: https://kubernetes.io/docs/tutorials/kubernetes-basics/update/update-intro/

---

## Arc 3 — Advanced

### Prerequisites
- Probe / resources / rollout 運用経験
- Namespace・RBAC・NetworkPolicy の基本概念

### 1) Topic + Level
**Topic:** セキュア運用（RBAC・Secret運用・NetworkPolicy・Context安全）  
**Level:** Advanced

### 2) Why it matters
実務では「動く」だけでなく「安全に動く」が必須です。  
過剰権限、Secret漏洩、誤クラスタ操作は重大インシデントに直結します。

### 3) Core concept
- RBAC: 最小権限（Role/RoleBinding, ClusterRole）
- Secret: 機密情報を分離（ただし暗号化・外部Secret管理も検討）
- NetworkPolicy: 通信許可を明示
- Context/Namespace 安全: `current-context` と `-n` 明示を習慣化

### 4) App開発での使い方
- CI/CD 用 ServiceAccount を用途別に分離
- アプリ設定は ConfigMap、機密は Secret + 外部シークレットマネージャ
- マイクロサービス間通信を NetworkPolicy で制限
- 本番適用前に `kubectl auth can-i` で権限検証

### 5) 30–60分ミニラボ
**目標:** 最小権限と通信制限の基本を体験（約60分）
1. `lab-advanced` Namespace 作成
2. 読み取り専用 Role/RoleBinding 作成
3. `kubectl auth can-i get pods --as=system:serviceaccount:lab-advanced:viewer -n lab-advanced`
4. deny-all ベースの NetworkPolicy を適用
5. 必要通信のみ許可する Policy を追加
6. Pod 間疎通の成否を確認

### 6) Command cheatsheet
```bash
kubectl auth can-i list pods -n lab-advanced --as=system:serviceaccount:lab-advanced:viewer
kubectl -n lab-advanced get role,rolebinding,sa
kubectl -n lab-advanced get networkpolicy
kubectl -n lab-advanced describe networkpolicy <name>
kubectl config current-context
kubectl config set-context --current --namespace=lab-advanced
```

### 7) Common mistakes + safe practices
- ❌ ClusterRoleBinding を安易に広範囲付与
- ❌ Secret を manifest に直書きし、共有チャットへ貼り付け
- ❌ `kubectl delete -f` を対象確認せず実行
- ✅ 破壊的コマンド前に「context / namespace / 対象リソース」を声出し確認
- ✅ `kubectl delete` は `--dry-run=client -o yaml` やラベル絞り込みで慎重に
- ✅ 監査ログ・変更履歴を残す（GitOps/PR レビュー）

### 8) Interview-style question
「本番で `kubectl apply -f` する際、誤クラスタ適用を防ぐための実務的ガードレールを設計してください。」

### 9) Next-step resources
- RBAC: https://kubernetes.io/docs/reference/access-authn-authz/rbac/
- Secrets good practices: https://kubernetes.io/docs/concepts/security/secrets-good-practices/
- Network Policies: https://kubernetes.io/docs/concepts/services-networking/network-policies/
- kubectl auth can-i: https://kubernetes.io/docs/reference/kubectl/generated/kubectl_auth/kubectl_auth_can-i/

---

## 今日の安全メモ（重要）
- `kubectl config current-context` を確認してから実行
- `-n <namespace>` を明示し、適用・削除のスコープミスを防止
- `kubectl apply -f <path>` は対象を限定（`-f .` の乱用を避ける）
- Secret をコード/チャット/ログに露出しない
- 破壊的操作（delete/replace/force）は必ず事前確認・レビュー
