# 2026-03-26 09:25 Kubernetes Commands Magazine
#kubernetes #k8s #devops #learning #daily
[[Home]]

---

## 今号のテーマ
**「`kubectl apply` と宣言的運用の基本」**

学習アークは **Beginner → Middle → Advanced** の順で進みます。今回は同一テーマを難易度別に掘り下げます。

---

## Beginner（初級）

### 1) Topic + Level
- **Topic:** Deployment を `kubectl apply` で管理する
- **Level:** Beginner

### 2) Why it matters（なぜ実開発で重要か）
- アプリのリリースを「手作業」から「再現可能な手順」に変えられる。
- YAML を Git 管理することで、誰がいつ何を変更したか追跡しやすい。
- チーム開発で環境差分を減らし、障害時の切り戻しがしやすくなる。

### 3) Core concept（kubectl/Kubernetes 基本概念）
- **宣言的管理（Declarative）**: 「こうなっていてほしい状態（desired state）」を YAML で表現。
- **`kubectl apply -f`**: 現在状態との差分を取り、望ましい状態へ収束させる。
- **Deployment**: Pod を複製・更新管理するコントローラ。
- **Namespace**: リソースの論理分離。

### 4) 実開発での使い方（kubernetes.io/docs ベストプラクティス準拠）
- マニフェストを `base/overlays` などで環境別に分離（例: Kustomize）。
- まず `kubectl diff -f` で差分確認、次に `kubectl apply -f`。
- 変更後は `kubectl rollout status deployment/<name>` で健全性を確認。

### 5) 30-60分ミニラボ
**目標:** Nginx Deployment を宣言的に作成・更新する（約40分）

1. Namespace 作成
   ```bash
   kubectl create namespace magazine-lab
   ```
2. `deployment.yaml` 作成（replicas: 2, image: nginx:1.27）
3. 適用前に差分確認
   ```bash
   kubectl diff -n magazine-lab -f deployment.yaml
   ```
4. 適用
   ```bash
   kubectl apply -n magazine-lab -f deployment.yaml
   ```
5. 確認
   ```bash
   kubectl get deploy,pods -n magazine-lab
   kubectl rollout status deploy/nginx -n magazine-lab
   ```
6. image を `nginx:1.27.1` に変更して再 apply
7. ロールアウト履歴確認
   ```bash
   kubectl rollout history deploy/nginx -n magazine-lab
   ```

### 6) Command Cheatsheet
```bash
kubectl config get-contexts
kubectl config current-context
kubectl get ns
kubectl get deploy -n <ns>
kubectl get pods -n <ns>
kubectl describe deploy <name> -n <ns>
kubectl diff -f <file> -n <ns>
kubectl apply -f <file> -n <ns>
kubectl rollout status deploy/<name> -n <ns>
kubectl rollout history deploy/<name> -n <ns>
```

### 7) Common mistakes + Safe practices
- **ミス:** `default` Namespace に誤適用  
  **対策:** 常に `-n` 指定、または `kubectl config set-context --current --namespace=<ns>` を利用。
- **ミス:** いきなり `apply` して意図しない変更  
  **対策:** 先に `kubectl diff`。
- **ミス:** Secret を平文で YAML/Git に置く  
  **対策:** 機密値は Secret 管理＋外部シークレット基盤（Vault/External Secrets など）を検討。

### 8) Interview-style question
- 「`kubectl create` と `kubectl apply` の違いを、チーム運用の観点で説明してください。」

### 9) Next-step resources
- Kubernetes Objects 概要: https://kubernetes.io/docs/concepts/overview/working-with-objects/
- Declarative Config: https://kubernetes.io/docs/tasks/manage-kubernetes-objects/declarative-config/
- Deployment: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/

---

## Middle（中級）

### Prerequisites
- Deployment/Pod の基本を理解している
- `kubectl get/describe/logs` を使える

### 1) Topic + Level
- **Topic:** Rolling Update と可用性を意識した更新戦略
- **Level:** Middle

### 2) Why it matters
- 本番アプリでは「止めずに更新」が必須。
- 更新失敗時に即時検知・ロールバックできる運用が必要。

### 3) Core concept
- **RollingUpdate**: `maxUnavailable` / `maxSurge` で更新時の余力を制御。
- **Readiness Probe**: トラフィック受け入れ可能な Pod のみ Service に参加。
- **Rollback**: `kubectl rollout undo` で前リビジョンへ戻す。

### 4) 実開発での使い方
- readiness/liveness probe を定義して「起動しただけの Pod」へ流入させない。
- リソース requests/limits を設定し、スケジューリングを安定化。
- 本番は段階デプロイ（small batch）＋監視メトリクスで判定。

### 5) 30-60分ミニラボ
**目標:** 安全な更新とロールバックを体験（約50分）

1. 既存 Deployment に readinessProbe を追加
2. `strategy.rollingUpdate` を設定（例: maxUnavailable: 0, maxSurge: 1）
3. `kubectl apply` 実行
4. 更新観察
   ```bash
   kubectl rollout status deploy/nginx -n magazine-lab
   kubectl get rs -n magazine-lab
   ```
5. 意図的に壊れた image tag に変更して apply
6. 失敗確認後、ロールバック
   ```bash
   kubectl rollout undo deploy/nginx -n magazine-lab
   kubectl rollout status deploy/nginx -n magazine-lab
   ```

### 6) Command Cheatsheet
```bash
kubectl set image deploy/<name> <container>=<image> -n <ns>
kubectl rollout status deploy/<name> -n <ns>
kubectl rollout history deploy/<name> -n <ns>
kubectl rollout undo deploy/<name> -n <ns>
kubectl get rs -n <ns>
kubectl logs deploy/<name> -n <ns> --tail=100
```

### 7) Common mistakes + Safe practices
- **ミス:** probe 未設定で更新時に 502/503 発生  
  **対策:** readinessProbe を必ず設計。
- **ミス:** `:latest` タグ使用で再現性喪失  
  **対策:** バージョン固定タグ or digest を使用。
- **ミス:** クラスタ全体対象の誤操作  
  **対策:** 実行前に `current-context` と Namespace を毎回確認。

### 8) Interview-style question
- 「`maxUnavailable=0` にするメリット・デメリットを説明してください。」

### 9) Next-step resources
- Rolling Updates: https://kubernetes.io/docs/tutorials/kubernetes-basics/update/update-intro/
- Probes: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/
- Resource Management: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/

---

## Advanced（上級）

### Prerequisites
- RollingUpdate/Probe/Rollback を実務レベルで使える
- Service/Ingress/ConfigMap/Secret の役割を説明できる

### 1) Topic + Level
- **Topic:** Server-Side Apply とフィールド管理、運用ガードレール
- **Level:** Advanced

### 2) Why it matters
- 複数ツール（kubectl, CI/CD, GitOps Controller）が同一リソースを操作する環境で競合を減らせる。
- 変更責任の境界が明確になり、大規模運用での事故防止に効く。

### 3) Core concept
- **Server-Side Apply (SSA)**: API サーバ側でフィールド所有を管理。
- **Field Manager**: どのクライアントがどのフィールドを管理しているかを追跡。
- **Conflict Detection**: 別管理者のフィールド上書きを検出。

### 4) 実開発での使い方
- CI は専用 `--field-manager` を持ち、手動運用と責務分離。
- 本番適用前にステージングで `kubectl diff --server-side` 検証。
- `--dry-run=server` を組み合わせ、Admission/Webhook 含め事前検証。

### 5) 30-60分ミニラボ
**目標:** SSA 競合を理解し、安全な適用手順を作る（約60分）

1. `kubectl apply --server-side --field-manager=mag-ci -f deployment.yaml -n magazine-lab`
2. 別端末/別 manager 想定で同一フィールド変更を試す
3. 競合エラーを確認
4. 管理責務を分離（例: CI は image/replicas、運用は annotations）
5. 事前検証フローを実施
   ```bash
   kubectl diff --server-side -f deployment.yaml -n magazine-lab
   kubectl apply --server-side --dry-run=server -f deployment.yaml -n magazine-lab
   ```

### 6) Command Cheatsheet
```bash
kubectl apply --server-side --field-manager=<manager> -f <file> -n <ns>
kubectl diff --server-side -f <file> -n <ns>
kubectl apply --dry-run=server -f <file> -n <ns>
kubectl get deploy <name> -n <ns> -o yaml
kubectl auth can-i apply deploy -n <ns>
```

### 7) Common mistakes + Safe practices
- **ミス:** 管理者を分けずに同一フィールドを多重更新  
  **対策:** フィールド責務をドキュメント化。
- **ミス:** 権限過多アカウントで CI 実行  
  **対策:** 最小権限 RBAC（namespace scoped）を徹底。
- **ミス:** 破壊的コマンドの誤爆（例: 広範囲 delete）  
  **対策:** 破壊的操作前に必ず対象確認。`--all` やワイルドカード使用時は **context / namespace / label selector** を再確認。

> ⚠️ **Destructive command warning**  
> `kubectl delete`、`kubectl apply -f <dir>`（広範囲適用）、`kubectl replace --force` は本番障害につながる可能性があります。実行前に次を必ず確認:
> 1. `kubectl config current-context`  
> 2. 対象 Namespace (`-n`)  
> 3. 対象リソース（`-l` やファイル範囲）

### 8) Interview-style question
- 「Server-Side Apply を導入すると、GitOps/CI と手動オペレーションの衝突をどう減らせますか？」

### 9) Next-step resources
- Server-Side Apply: https://kubernetes.io/docs/reference/using-api/server-side-apply/
- Field Management: https://kubernetes.io/docs/reference/using-api/server-side-apply/#field-management
- RBAC: https://kubernetes.io/docs/reference/access-authn-authz/rbac/
- Secrets good practices: https://kubernetes.io/docs/concepts/security/secrets-good-practices/

---

## 今日のまとめ
- `apply` は宣言的運用の中心。
- 中級では「止めない更新」、上級では「競合しない運用設計」が鍵。
- 常に **context / namespace / scope** を明示し、破壊的操作は二重確認。
- Secret は平文で Git 管理しない。
