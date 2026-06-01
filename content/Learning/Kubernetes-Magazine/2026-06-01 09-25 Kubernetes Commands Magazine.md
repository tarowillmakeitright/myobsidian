---
tags: [kubernetes, k8s, devops, learning, daily]
---

# 2026-06-01 09:25 Kubernetes Commands Magazine
[[Home]]

## 今日のテーマ
**Deployment のローリングアップデートと安全なロールバック運用**

---

## 1) Topic + Level
### 🟢 Beginner
**Topic:** `kubectl` の基本確認コマンド（`get` / `describe` / `logs`）で「壊さず見る」習慣を作る

### 🟡 Middle
**Topic:** `Deployment` の更新戦略（RollingUpdate）を理解し、ダウンタイム最小でアプリ更新する

**Prerequisites:**
- Pod / ReplicaSet / Deployment の基本概念
- `kubectl get` と `kubectl apply -f` を使ったことがある
- namespace と context を確認する習慣がある

### 🔴 Advanced
**Topic:** 段階的リリース運用（可観測性確認 + rollback基準 + 安全ガード）

**Prerequisites:**
- Middle の内容を実施済み
- readiness/liveness probe の違いを説明できる
- `kubectl rollout history` / `kubectl rollout undo` を使える

---

## 2) Why it matters for real app development
実アプリ開発では、**機能追加より「安全に出す」能力**が重要です。
Deployment の更新を誤ると次が起こります。

- 一部Podが起動不能になり、API 5xxが急増
- Secret/Configの反映漏れで本番だけ壊れる
- 焦って `delete` して復旧をさらに遅らせる

逆に、更新・監視・ロールバックを定型化すると、

- リリース速度を上げても障害率を抑えられる
- 小さな変更を頻繁に安全投入できる
- チームで再現可能な運用知識が蓄積される

---

## 3) Core kubectl/Kubernetes concept explanations
- **Deployment**: 望ましい状態（例: replicas=3, image=v2）を宣言し、裏でReplicaSetを切り替えるコントローラ。
- **RollingUpdate**: 一気に置換せず、古いPodを段階的に新しいPodへ入れ替える方式。
  - `maxUnavailable`: 同時に止めてもよいPod数
  - `maxSurge`: 一時的に増やしてよいPod数
- **readinessProbe**: 「トラフィックを受けてよいか」の判定。これが通るまでServiceのエンドポイントに入らない。
- **rollout status/history/undo**:
  - `status`: 更新の進行監視
  - `history`: リビジョン履歴確認
  - `undo`: 安全に前版へ戻す

---

## 4) Building apps with Kubernetes (kubernetes.io/docs aligned)
アプリ開発時は、公式ドキュメントの推奨に沿って以下を守ると実践的です。

1. **宣言的運用（YAML + apply）**
   - `kubectl apply -f` を中心にし、手作業変更を減らす
2. **Probeを必ず定義**
   - readiness/liveness を設定し、不健康Podの早期検知
3. **ConfigとSecretを分離**
   - 設定値は ConfigMap、機密は Secret（ただし平文コミット禁止）
4. **段階的リリース + rollout監視**
   - apply直後に `rollout status` / `get pods -w` / `logs` を確認
5. **失敗時の最短復旧を準備**
   - rollback手順を先に決める（誰が、何分で、どの条件で戻すか）

---

## 5) 30–60 minute mini lab
**目標:** Nginx Deployment を更新し、問題を検知してロールバックする

### 手順（約45分）

#### Step 0: 事故防止チェック（3分）
```bash
kubectl config current-context
kubectl get ns
```
- 本当に対象クラスタか確認
- 学習用namespaceを使う（例: `magazine-lab`）

#### Step 1: namespace作成（2分）
```bash
kubectl create namespace magazine-lab
kubectl config set-context --current --namespace=magazine-lab
```

#### Step 2: 初版Deployment作成（10分）
`deploy.yaml` を作成:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 1
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
kubectl apply -f deploy.yaml
kubectl rollout status deploy/web
kubectl get pods -o wide
```

#### Step 3: 正常更新（8分）
```bash
kubectl set image deploy/web nginx=nginx:1.26
kubectl rollout status deploy/web
kubectl rollout history deploy/web
```
- Podが段階的に入れ替わることを確認

#### Step 4: 意図的な失敗更新（10分）
```bash
kubectl set image deploy/web nginx=nginx:does-not-exist
kubectl rollout status deploy/web --timeout=60s
kubectl get pods
kubectl describe deploy/web
```
- ImagePullBackOff等を確認

#### Step 5: ロールバック（5分）
```bash
kubectl rollout undo deploy/web
kubectl rollout status deploy/web
kubectl get pods
```

#### Step 6: 振り返り（5–10分）
- どのタイミングで異常に気づけたか
- どのコマンドが原因分析に効いたか
- rollback判断基準を1行で書く

---

## 6) Command cheatsheet
```bash
# 現在の対象確認
kubectl config current-context
kubectl config view --minify

# 基本観察
kubectl get deploy,pods,rs
kubectl describe deploy/web
kubectl logs deploy/web --all-pods

# 反映と監視
kubectl apply -f deploy.yaml
kubectl rollout status deploy/web
kubectl get pods -w

# 更新
kubectl set image deploy/web nginx=nginx:1.26

# 履歴と復旧
kubectl rollout history deploy/web
kubectl rollout undo deploy/web
```

---

## 7) Common mistakes and safe practices
### よくあるミス
1. **context誤りで別クラスタ操作**
2. `kubectl delete` を雑に実行（namespace未確認）
3. Secret値をYAMLに平文記載しGitへpush
4. `latest` タグ利用で再現不能リリース
5. rollout失敗時に原因確認せず連続apply

### 安全プラクティス
- 破壊的操作の前に必ず確認:
  - `kubectl config current-context`
  - `kubectl get ns`
  - `kubectl -n <namespace> ...` を明示
- `delete` 前に対象を先に `get` / `describe`
- Secretは外部シークレット管理や暗号化手段を利用し、**平文をリポジトリに置かない**
- 画像タグは固定（例: `1.26.1`）
- applyは小さく頻繁に、失敗時はまず `describe` / `events` / `logs`

⚠️ **Warning:** `kubectl delete -f` / `kubectl delete namespace` / `kubectl apply` はスコープを誤ると大きな影響があります。実行前に context・namespace・対象manifestを必ず再確認してください。

---

## 8) Interview-style question
「本番Deploymentのローリングアップデート中に一部PodがReadyにならず、エラーレートが上昇しました。あなたはどの順番で何を確認し、どの条件でロールバックを判断しますか？」

（期待される観点: rollout status、describe/events、logs、probe設定、依存先障害、SLO閾値、復旧時間）

---

## 9) Next-step resources (official preferred)
- Kubernetes Documentation（公式トップ）  
  https://kubernetes.io/docs/home/
- Deployments  
  https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Perform a Rolling Update on a Deployment  
  https://kubernetes.io/docs/tutorials/kubernetes-basics/update/update-intro/
- Probes (Liveness, Readiness, Startup)  
  https://kubernetes.io/docs/concepts/configuration/liveness-readiness-startup-probes/
- Secret  
  https://kubernetes.io/docs/concepts/configuration/secret/
- kubectl Cheat Sheet  
  https://kubernetes.io/docs/reference/kubectl/cheatsheet/

---

次号予告（難易度アーク継続）:
Beginner: Service/Ingress基礎 → Middle: HPA導入 → Advanced: 負荷試験に基づくオートスケール調整
