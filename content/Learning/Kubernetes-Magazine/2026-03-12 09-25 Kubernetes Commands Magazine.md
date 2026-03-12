---
tags: [kubernetes, k8s, devops, learning, daily]
---

# 2026-03-12 Kubernetes Commands Magazine
[[Home]]

#kubernetes #k8s #devops #learning #daily

## 今号のテーマ
**Topic:** Deployment を安全に更新する（`rollout` と `probe` の実践）  
**Level:** Beginner（学習アーク: Beginner → Middle → Advanced の 1 周目）

---

## 1) なぜ実アプリ開発で重要か
本番運用では「新機能を出す速さ」と「落とさない安定性」の両立が必須です。  
Kubernetes の Deployment 更新（RollingUpdate）を正しく使えると、以下が可能になります。

- 無停止に近い形でアプリを更新
- 問題発生時に迅速なロールバック
- ヘルスチェックで壊れた Pod を自動で切り離し

これは CI/CD の土台であり、実サービスの信頼性に直結します。

---

## 2) コア概念（kubectl / Kubernetes）

### Deployment
- Pod の望ましい状態（レプリカ数・コンテナイメージなど）を宣言管理するリソース。
- 更新時は ReplicaSet を切り替えて段階的に新 Pod を増やす（RollingUpdate）。

### rollout
- `kubectl rollout status` で更新進捗を確認。
- `kubectl rollout history` で改訂履歴を確認。
- `kubectl rollout undo` で直前バージョンへ戻せる。

### readinessProbe / livenessProbe
- **readinessProbe**: トラフィックを受けられる準備ができたか。
- **livenessProbe**: プロセスが生きているか。失敗時は再起動。
- readiness を適切に設定しないと、起動途中 Pod にトラフィックが流れて障害化しやすい。

---

## 3) アプリ開発中での使い方（kubernetes.io/docs ベストプラクティス準拠）

実装〜デプロイ時の実務フロー例:

1. アプリに `/healthz`（liveness）と `/readyz`（readiness）を実装
2. Deployment に probe を設定
3. `resources.requests/limits` を設定（スケジューリングと保護）
4. `kubectl apply -f` 前に **context / namespace を確認**
5. `rollout status` を監視し、異常時は `rollout undo`

> Best Practice メモ:
> - 機密情報は Secret/外部シークレット管理を使い、マニフェストへ平文直書きしない
> - `latest` タグ固定を避け、イメージタグを明示
> - 本番では `--dry-run=server` や段階適用で事故を減らす

---

## 4) 30〜60分ミニラボ（Beginner）

**目標:** nginx Deployment を更新し、rollout と rollback を体験する。

**前提:**
- `kubectl` が使える
- テスト用クラスタ（kind / minikube / dev namespace）

### Step 0: 安全確認（3分）
```bash
kubectl config current-context
kubectl get ns
```
- 期待する開発用 context か必ず確認。

### Step 1: Namespace 作成（2分）
```bash
kubectl create ns magazine-lab
kubectl config set-context --current --namespace=magazine-lab
```

### Step 2: 初回デプロイ（10分）
```bash
kubectl create deployment web --image=nginx:1.25
kubectl scale deployment web --replicas=3
kubectl get pods -w
```

### Step 3: Service 公開（5分）
```bash
kubectl expose deployment web --port=80 --type=ClusterIP
kubectl get svc
```

### Step 4: イメージ更新と監視（10分）
```bash
kubectl set image deployment/web nginx=nginx:1.27
kubectl rollout status deployment/web
kubectl rollout history deployment/web
```

### Step 5: ロールバック練習（10分）
```bash
kubectl rollout undo deployment/web
kubectl rollout status deployment/web
```

### Step 6: 後片付け（任意・3分）
```bash
kubectl delete ns magazine-lab
```
⚠️ `delete` は対象 namespace を再確認してから実行。

---

## 5) コマンドチートシート

```bash
# コンテキスト/名前空間確認
kubectl config current-context
kubectl config view --minify | grep namespace:

# Deployment 操作
kubectl create deployment web --image=nginx:1.25
kubectl set image deployment/web nginx=nginx:1.27
kubectl scale deployment web --replicas=3

# rollout 管理
kubectl rollout status deployment/web
kubectl rollout history deployment/web
kubectl rollout undo deployment/web

# 状態確認
kubectl get deploy,rs,pods,svc
kubectl describe deployment web
kubectl logs deploy/web --all-containers=true --tail=100
```

---

## 6) よくあるミス & 安全運用

### よくあるミス
1. **誤コンテキストに apply/delete** して本番を壊す  
2. `:latest` で差分追跡不能  
3. readiness 未設定で起動直後に 5xx 増加  
4. Secret を Git 管理して漏えい

### 安全プラクティス
- 実行前に必ず:
  - `kubectl config current-context`
  - `kubectl get ns`
- 破壊的操作前に対象を絞る:
  - `-n <namespace>` を明示
  - ラベルセレクタを活用
- 適用前検証:
  - `kubectl apply --dry-run=server -f <file>`
- Secret は:
  - 平文直書きしない
  - 必要最小権限（RBAC）
  - 監査ログ/アクセス制御を有効化

---

## 7) 面接っぽい一問

**Q.** readinessProbe と livenessProbe の違いを説明し、誤設定するとどんな障害が起きるか述べてください。  
**A.（要点）** readiness はトラフィック受け入れ可否、liveness は再起動要否。readiness 不備で未初期化 Pod に流入しエラー増、liveness 過敏設定で再起動ループが起こる。

---

## 8) 次のステップ（公式中心）

- Kubernetes Deployment
  - https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Rolling Updates
  - https://kubernetes.io/docs/tutorials/kubernetes-basics/update/update-intro/
- Probes (Liveness/Readiness/Startup)
  - https://kubernetes.io/docs/concepts/configuration/liveness-readiness-startup-probes/
- kubectl Cheat Sheet
  - https://kubernetes.io/docs/reference/kubectl/cheatsheet/
- Configure Access to Multiple Clusters（context事故防止）
  - https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/
- Secrets Good Practices
  - https://kubernetes.io/docs/concepts/security/secrets-good-practices/

---

## 次号予告（Middle）
**Level: Middle（Prerequisites 必須）**
- Deployment/Service の基本操作
- rollout/rollback の実行経験
- YAML の基本理解

次号では **ConfigMap/Secret + 環境変数注入 + ローリング更新戦略（maxUnavailable/maxSurge）** を扱い、より実運用に近い安全な更新パターンへ進みます。
