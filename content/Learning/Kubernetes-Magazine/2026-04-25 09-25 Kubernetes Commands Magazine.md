---
tags: [kubernetes, k8s, devops, learning, daily]
---

# Daily Kubernetes Commands Magazine (2026-04-25 09:25)
[[Home]]

#kubernetes #k8s #devops #learning #daily

## 今号の学習アーク
Beginner → Middle → Advanced の順で、同じ「アプリを安全にデプロイして運用する」流れを段階的に深めます。

---

## 1) Topic + Level

### Beginner（初級）
**Topic:** `kubectl get/describe/logs` で「まず現状を正しく見る」

### Middle（中級）
**Topic:** Deployment のローリングアップデートとロールバック
**前提知識（Prerequisites）:**
- Pod / Deployment / Service の基本
- `kubectl get`, `kubectl describe`, `kubectl logs` を使える

### Advanced（上級）
**Topic:** probes・requests/limits・ConfigMap/Secret 分離を含む実運用向けデプロイ
**前提知識（Prerequisites）:**
- Deployment 更新戦略と `rollout` 操作
- YAML マニフェストの基本構文
- Linux/アプリログの基礎

---

## 2) Why it matters for real app development
- 開発現場では「動かない原因の切り分け速度」が品質と納期に直結します。
- 本番運用では、**安全なリリース（段階反映）**と**即時ロールバック**が事故影響を最小化します。
- Kubernetes のベストプラクティス（ヘルスチェック、リソース設定、機密情報分離）を最初から取り入れると、スケール時の障害率を下げられます。

---

## 3) Core kubectl / Kubernetes concept explanations

### `kubectl get`
- クラスタ内リソースの一覧・状態確認。
- まず `-n <namespace>` を明示する癖をつける。

### `kubectl describe`
- イベントや詳細状態（失敗理由）を見る。調査の一次情報。

### `kubectl logs`
- アプリログ確認。`-f` で追尾、`--previous` でクラッシュ前ログを確認。

### Deployment / ReplicaSet / Pod
- Deployment が望ましい状態を宣言し、ReplicaSet を通じて Pod 数や更新を管理。

### Rollout
- `kubectl rollout status/history/undo` で更新の進行監視・履歴確認・切り戻し。

### Probes
- readinessProbe: 受信可能判定（トラフィック投入制御）
- livenessProbe: ハング検知と再起動

### requests / limits
- スケジューリングとリソース暴走防止の要。

### ConfigMap / Secret
- 設定値と機密値をイメージから分離し、環境差分を管理。

---

## 4) How Kubernetes is used while building apps（kubernetes.io/docs 準拠）
1. **ローカル開発後にコンテナ化**し、Deployment で実行。
2. **readiness/liveness probes** を設定し、壊れた Pod への流入を防止。
3. **requests/limits** を設定してノード資源の取り合いを抑制。
4. **ConfigMap/Secret** で設定を外出し（シークレット直書き禁止）。
5. リリース時は **rolling update** + `rollout status` 監視。
6. 問題発生時は **`rollout undo`** ですぐ復旧。

---

## 5) 30–60 minute hands-on mini lab

### 目標
安全な Deployment 更新とロールバックを体験し、観測コマンドを一通り使う。

### 所要時間
45分前後

### 手順

#### Step 0: 事前確認（5分）
```bash
kubectl config current-context
kubectl get ns
```
> ⚠️ 破壊的操作防止: 作業前に context を必ず確認。想定外クラスタでの実行を防ぐ。

#### Step 1: 専用 namespace 作成（5分）
```bash
kubectl create namespace k8s-mag-lab
kubectl get ns k8s-mag-lab
```

#### Step 2: 初期 Deployment 適用（10分）
```bash
cat <<'EOF' | kubectl apply -n k8s-mag-lab -f -
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
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            cpu: "300m"
            memory: "256Mi"
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 3
          periodSeconds: 5
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 10
          periodSeconds: 10
EOF

kubectl rollout status deployment/web -n k8s-mag-lab
kubectl get pods -n k8s-mag-lab -o wide
```

#### Step 3: 更新を実施（10分）
```bash
kubectl set image deployment/web nginx=nginx:1.26 -n k8s-mag-lab
kubectl rollout status deployment/web -n k8s-mag-lab
kubectl rollout history deployment/web -n k8s-mag-lab
```

#### Step 4: 意図的に失敗イメージを適用して復旧（10分）
```bash
kubectl set image deployment/web nginx=nginx:does-not-exist -n k8s-mag-lab
kubectl rollout status deployment/web -n k8s-mag-lab
kubectl describe deployment/web -n k8s-mag-lab
kubectl get events -n k8s-mag-lab --sort-by=.lastTimestamp | tail -n 20

kubectl rollout undo deployment/web -n k8s-mag-lab
kubectl rollout status deployment/web -n k8s-mag-lab
```

#### Step 5: 後片付け（必要なら）（5分）
```bash
# 本当にこの namespace でよいか確認してから実行
kubectl delete namespace k8s-mag-lab
```
> ⚠️ `delete` は破壊的。対象 namespace/context を再確認してから実行。

---

## 6) Command cheatsheet
```bash
# コンテキスト確認
kubectl config current-context

# 主要参照
kubectl get pods -n <ns>
kubectl describe pod <pod> -n <ns>
kubectl logs <pod> -n <ns>
kubectl logs <pod> -n <ns> --previous

# デプロイ更新系
kubectl set image deployment/<name> <container>=<image> -n <ns>
kubectl rollout status deployment/<name> -n <ns>
kubectl rollout history deployment/<name> -n <ns>
kubectl rollout undo deployment/<name> -n <ns>

# マニフェスト適用（スコープ明示）
kubectl apply -n <ns> -f <file>
```

---

## 7) Common mistakes and safe practices

### よくあるミス
- `kubectl apply -f .` を意図せず実行し、関係ないマニフェストまで適用
- context/namespace 未確認で本番に対して操作
- Secret を YAML に平文でコミット
- probes 未設定で障害 Pod にトラフィックが入り続ける

### 安全策
- 実行前に `kubectl config current-context` と `-n` を毎回確認
- 変更前に `kubectl diff -f <file> -n <ns>` を使う
- Secret は Git 直置きしない（外部シークレット管理や暗号化手段を使う）
- 破壊的コマンド（`delete`, 広範囲 `apply`）は対象を声出し確認レベルで再チェック

---

## 8) One interview-style question
**Q.** Deployment の rolling update 中に一部 Pod が起動失敗しているとき、あなたはどの順番で調査し、どの条件でロールバック判断しますか？

（面接では、`rollout status` → `describe`/`events` → `logs` → 影響評価 → `rollout undo` の判断基準を具体化できると強い）

---

## 9) Next-step resources（公式中心）
- Kubernetes Documentation (Home): https://kubernetes.io/docs/
- kubectl Overview: https://kubernetes.io/docs/reference/kubectl/
- Deployments: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Probes (Liveness/Readiness/Startup): https://kubernetes.io/docs/concepts/configuration/liveness-readiness-startup-probes/
- Resource Management for Pods and Containers: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/
- ConfigMap: https://kubernetes.io/docs/concepts/configuration/configmap/
- Secret: https://kubernetes.io/docs/concepts/configuration/secret/
- Good Practices for Kubernetes Secrets: https://kubernetes.io/docs/concepts/security/secrets-good-practices/

---

次号予告: **Middle→Advanced ブリッジ編（Service/Ingress とゼロダウンタイム観点）**