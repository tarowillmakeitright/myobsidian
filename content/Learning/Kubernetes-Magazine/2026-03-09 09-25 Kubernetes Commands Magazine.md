# 2026-03-09 Kubernetes Commands Magazine

#kubernetes #k8s #devops #learning #daily
[[Home]]

---

## 今日の学習アーク（Beginner → Middle → Advanced）

> テーマは「**アプリを安全にデプロイし、運用で詰まらないための kubectl 基本動作**」。
> 難易度を段階的に上げて、毎日繰り返し学習できる構成です。

---

## 1) Topic + Level

### 🟢 Beginner
**Topic:** Pod / Deployment / Service を `kubectl` で作って公開する

### 🟡 Middle（前提あり）
**Topic:** Readiness/Liveness Probe と RollingUpdate で安全に更新する  
**Prerequisites:**
- Pod / Deployment / Service の基本を理解している
- `kubectl get/describe/logs` を使える

### 🔴 Advanced（前提あり）
**Topic:** Namespace・Context・RBAC を意識した「事故らない運用コマンド設計」  
**Prerequisites:**
- `kubectl apply -f` の運用経験
- 複数環境（dev/stg/prod）を触る想定ができる
- Kubernetes の基本オブジェクト概念

---

## 2) Why it matters for real app development

- 開発では「動く」だけでなく、**壊さずに更新できること**が重要。
- Probe と rollout 設計が甘いと、デプロイ直後に 5xx が増える。
- Context/Namespace を誤ると、**本番を誤操作**するリスクがある。
- つまり Kubernetes は、アプリ機能開発と同じくらい「**安全なデリバリー**」の設計対象。

---

## 3) Core kubectl / Kubernetes concepts

### Beginner の核
- `kubectl get`：状態一覧
- `kubectl describe`：詳細（イベント含む）
- `kubectl logs`：アプリログ確認
- `Deployment`：宣言的なレプリカ管理
- `Service`：Pod の到達性を安定化

### Middle の核
- `readinessProbe`：トラフィックを受けてよいか
- `livenessProbe`：死活監視（再起動の判断）
- `kubectl rollout status/history/undo`：更新の追跡とロールバック

### Advanced の核
- `kubectl config current-context` / `get-contexts`：操作先クラスタ確認
- `-n <namespace>`：操作スコープ固定
- `kubectl auth can-i`：権限確認
- RBAC（Role/RoleBinding）：最小権限で事故面積を縮小

---

## 4) App development での使い方（kubernetes.io/docs ベストプラクティス準拠）

- 変更は基本 **宣言的（YAML + apply）** で管理し、Git で差分追跡。
- アプリ公開前に readinessProbe を通すことで、未準備 Pod への流入を防ぐ。
- ローリングアップデート時は `maxUnavailable` を厳しめにし、可用性を維持。
- Secret は **manifest に平文直書きしない**。Secret リソース + 外部秘匿基盤を検討。
- 運用前に `context` と `namespace` を毎回明示し、誤爆を防ぐ。

---

## 5) 30–60分ミニラボ（実践）

### ゴール
- nginx アプリを Deployment + Service で立てる
- Probe を追加して安全更新
- rollout 失敗時に undo できる

### 手順（45分想定）

1. **Namespace 作成（5分）**
```bash
kubectl create namespace k8s-mag-lab
kubectl config set-context --current --namespace=k8s-mag-lab
```

2. **Deployment / Service 作成（10分）**
```bash
kubectl create deployment web --image=nginx:1.25
kubectl expose deployment web --port=80 --target-port=80 --type=ClusterIP
kubectl get all
```

3. **YAML へエクスポートして Probe 追加（15分）**
```bash
kubectl get deployment web -o yaml > web-deploy.yaml
```
`web-deploy.yaml` の container に以下を追加（例）:
```yaml
readinessProbe:
  httpGet:
    path: /
    port: 80
  initialDelaySeconds: 5
  periodSeconds: 5
livenessProbe:
  httpGet:
    path: /
    port: 80
  initialDelaySeconds: 10
  periodSeconds: 10
```
適用:
```bash
kubectl apply -f web-deploy.yaml
kubectl rollout status deployment/web
```

4. **安全な更新とロールバック（10分）**
```bash
kubectl set image deployment/web nginx=nginx:1.26
kubectl rollout status deployment/web
kubectl rollout history deployment/web
```
問題があれば:
```bash
kubectl rollout undo deployment/web
```

5. **後片付け（5分）**
> ⚠️ 破壊的操作。対象 Namespace を再確認してから実行。
```bash
kubectl config current-context
kubectl get ns
kubectl delete namespace k8s-mag-lab
```

---

## 6) Command cheatsheet

```bash
# 参照
kubectl get pods -A
kubectl get deploy,svc -n <ns>
kubectl describe pod <pod> -n <ns>
kubectl logs <pod> -n <ns>

# 適用・差分
kubectl apply -f app.yaml -n <ns>
kubectl diff -f app.yaml -n <ns>

# 更新追跡
kubectl rollout status deploy/<name> -n <ns>
kubectl rollout history deploy/<name> -n <ns>
kubectl rollout undo deploy/<name> -n <ns>

# 安全確認
kubectl config current-context
kubectl config get-contexts
kubectl auth can-i delete pods -n <ns>
```

---

## 7) Common mistakes and safe practices

### よくあるミス
- `kubectl apply -f .` を誤ディレクトリで実行して意図しないリソース適用
- `default` namespace のまま作業して混線
- probe 未設定で、起動直後 Pod にトラフィックが流れて障害
- Secret を Git 管理の manifest に平文保存

### 安全運用
- 実行前に **context + namespace** を声出し確認
- 破壊系（delete, scale 0, replace --force）は対象を `get` で再確認
- `kubectl diff` を挟んで変更を可視化
- 本番は最小権限 RBAC + 監査ログを有効化

---

## 8) Interview-style question

**Q.** readinessProbe と livenessProbe の違いを説明し、両方が必要な理由を実運用の障害シナリオで答えてください。  
**A の観点例:**
- readiness: ルーティング制御（未準備インスタンスを外す）
- liveness: 自己回復（ハング時の再起動）
- 片方のみだと「受けるべきでない通信」または「復旧不能なハング」を防げない

---

## 9) Next-step resources（公式優先）

- Kubernetes Concepts Overview  
  https://kubernetes.io/docs/concepts/overview/
- Deployments  
  https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Services  
  https://kubernetes.io/docs/concepts/services-networking/service/
- Probes (Liveness/Readiness/Startup)  
  https://kubernetes.io/docs/concepts/configuration/liveness-readiness-startup-probes/
- kubectl Cheat Sheet  
  https://kubernetes.io/docs/reference/kubectl/cheatsheet/
- Configure Access to Multiple Clusters（context運用）  
  https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/
- RBAC Authorization  
  https://kubernetes.io/docs/reference/access-authn-authz/rbac/
- Secret Good Practices  
  https://kubernetes.io/docs/concepts/security/secrets-good-practices/

---

### 明日の予告（反復アーク）
次回は同じ Beginner→Middle→Advanced 構成で、
**ConfigMap/Secret 注入 + 環境差分管理（Kustomize 入門）** を扱います。