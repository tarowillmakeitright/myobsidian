---
tags: [kubernetes, k8s, devops, learning, daily]
---

# 2026-05-25 Kubernetes Commands Magazine
[[Home]]

## 今日のテーマ
**Topic:** Pod を安全に運用するための基本〜実践（`kubectl get/describe/logs/exec` と Deployment ロールアウト確認）

**Learning Arc:** Beginner → Middle → Advanced

---

## 1) Topic + Level

### Beginner
**レベル:** Beginner  
**題材:** `kubectl get`, `kubectl describe`, `kubectl logs` で「状態を見る」

### Middle
**レベル:** Middle  
**題材:** Deployment の更新とロールアウト確認（`rollout status/history/undo`）

**前提知識:**
- Pod / Deployment の基本概念
- `kubectl get pods -n <namespace>` が読める
- コンテナログの見方（stdout/stderr）

### Advanced
**レベル:** Advanced  
**題材:** トラブル時の安全な切り分け（`kubectl exec`, イベント確認、コンテキスト事故防止）

**前提知識:**
- Deployment の更新フローを理解している
- readiness/liveness probe の目的を説明できる
- namespace / context の違いを理解している

---

## 2) なぜ実アプリ開発で重要か

実アプリ開発では、**不具合の多くは「デプロイ後」に見つかる**ため、まず安全に現状把握する力が重要です。  
特に以下が日常的に発生します。

- 新版反映後に一部 Pod だけ起動失敗
- 外形監視は OK でも内部でエラー増加
- 環境違い（staging/prod）で同じ manifest が挙動を変える

このとき、無闇に `delete` や `apply -f .` を実行すると被害が広がります。  
**観測（get/describe/logs/events）→ 仮説 → 最小変更** がプロ現場の基本です。

---

## 3) コア概念（kubectl / Kubernetes）

- **Pod:** 最小実行単位。通常は直接運用せず、Deployment など上位リソースで管理。
- **Deployment:** ReplicaSet を介して Pod を宣言的に更新・維持。
- **Namespace:** 論理分離。`default` 依存は事故源。
- **Context:** `kubectl` が接続するクラスタ/認証/namespace の組。
- **Event:** Kubernetes が記録する状態変化・失敗ヒント。
- **Rollout:** Deployment 更新の進行状態。失敗時 rollback が可能。

---

## 4) アプリ開発時の使い方（kubernetes.io/docs ベストプラクティス整合）

- **宣言的管理を優先:** `kubectl apply -f` は対象ファイルを限定し、Git 管理された manifest を使う。
- **最小権限 + Secret 分離:** 秘密情報は manifest 直書きしない（Secret / External Secret / CI 連携）。
- **ヘルスチェック活用:** readiness/liveness/startup probe を適切に設定し、障害時の自動回復性を高める。
- **ロールアウト監視:** 更新時は `kubectl rollout status` を必ず確認。
- **観測先行:** まず `get/describe/logs/events` で証拠収集してから修正。

---

## 5) 30〜60分ミニラボ

**ゴール:** 安全に Deployment 更新を行い、失敗時に原因確認・ロールバックできるようになる。

### 事前準備（5分）
```bash
kubectl config get-contexts
kubectl config current-context
kubectl get ns
```

> ⚠️ **注意:** 作業前に `current-context` と `namespace` を必ず確認。prod で誤実行しない。

### Step 1: 学習用 namespace 作成（5分）
```bash
kubectl create namespace k8s-mag-lab
kubectl config set-context --current --namespace=k8s-mag-lab
```

### Step 2: サンプル Deployment 適用（10分）
`nginx-deploy.yaml` を作成:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
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
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 3
          periodSeconds: 5
```

適用:
```bash
kubectl apply -f nginx-deploy.yaml
kubectl get deploy,pods
kubectl rollout status deploy/web
```

### Step 3: 観測（10分）
```bash
kubectl describe deploy web
kubectl get events --sort-by=.metadata.creationTimestamp | tail -n 20
kubectl logs deploy/web --tail=50
```

### Step 4: 意図的な更新と確認（10〜15分）
```bash
kubectl set image deploy/web nginx=nginx:1.26
kubectl rollout status deploy/web
kubectl rollout history deploy/web
```

### Step 5: ロールバック（5分）
```bash
kubectl rollout undo deploy/web
kubectl rollout status deploy/web
kubectl get pods -o wide
```

### Step 6: 後片付け（任意）（3分）
```bash
kubectl config set-context --current --namespace=default
kubectl delete namespace k8s-mag-lab
```

> ⚠️ `kubectl delete namespace ...` は破壊的操作。対象クラスタ・対象 namespace を再確認してから実行。

---

## 6) Command Cheatsheet

```bash
# コンテキスト/namespace確認
kubectl config current-context
kubectl config get-contexts
kubectl get ns

# 状態確認
kubectl get pods -A
kubectl get deploy -n <ns>
kubectl describe pod <pod> -n <ns>
kubectl get events -n <ns> --sort-by=.metadata.creationTimestamp

# ログ
kubectl logs <pod> -n <ns> --tail=100
kubectl logs -f <pod> -n <ns>
kubectl logs deploy/<name> -n <ns>

# Deployment運用
kubectl rollout status deploy/<name> -n <ns>
kubectl rollout history deploy/<name> -n <ns>
kubectl rollout undo deploy/<name> -n <ns>
kubectl set image deploy/<name> <container>=<image>:<tag> -n <ns>

# デバッグ
kubectl exec -it <pod> -n <ns> -- /bin/sh
```

---

## 7) よくあるミス & Safe Practices

### よくあるミス
1. `default` namespace のまま操作して意図しないリソース変更
2. `kubectl apply -f .` で想定外 manifest まで適用
3. ログ未確認のまま再起動・再作成を繰り返す
4. Secret を YAML に平文記載して Git にコミット
5. 本番 context のまま `delete` 実行

### Safe Practices
- 毎回 `kubectl config current-context` を確認
- `-n <namespace>` を明示する癖をつける
- 破壊的コマンド前は「対象クラスタ・対象 namespace・対象リソース」を声に出して確認
- Secret は専用管理（Kubernetes Secret + 外部シークレット管理）
- 更新時は `rollout status` を最後まで見る

---

## 8) 面接風クエスチョン

**Q.** Deployment 更新後に一部 Pod が Ready にならず、サービスエラーが増えています。最初の10分でどの順番で何を確認しますか？  
（期待される観点: context/namespace確認、rollout status、describe、events、logs、直近変更、rollback判断）

---

## 9) 次の学習リソース（公式中心）

- Kubernetes Documentation (Home)  
  https://kubernetes.io/docs/
- Overview: Kubernetes Components / Objects  
  https://kubernetes.io/docs/concepts/overview/
- Workloads: Deployments  
  https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- kubectl Cheat Sheet  
  https://kubernetes.io/docs/reference/kubectl/cheatsheet/
- Probes (Liveness, Readiness, Startup)  
  https://kubernetes.io/docs/concepts/configuration/liveness-readiness-startup-probes/
- Configure Access to Multiple Clusters (Contexts)  
  https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/
- Secret Good Practices  
  https://kubernetes.io/docs/concepts/security/secrets-good-practices/

---

次号予告（学習アーク継続）:  
Beginner: ConfigMap/Secret 基本分離 → Middle: 環境別設定戦略 → Advanced: Secret 運用自動化と監査
