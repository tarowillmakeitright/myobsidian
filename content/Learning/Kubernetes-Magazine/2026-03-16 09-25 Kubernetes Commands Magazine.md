---
tags:
  - kubernetes
  - k8s
  - devops
  - learning
  - daily
---
[[Home]]

# Daily Kubernetes Commands Magazine — 2026-03-16

## 学習アーク概要（Beginner → Middle → Advanced）
**テーマ:** Deployment を安全に更新・検証・ロールバックする

- **Beginner:** Deployment / Pod / Service の基本操作
- **Middle:** RollingUpdate と ReadinessProbe を使った無停止更新
  - **前提知識:** Pod, Deployment, Service, `kubectl get/describe/logs`
- **Advanced:** 更新失敗時の即時切り戻し（rollback）と安全確認フロー
  - **前提知識:** RollingUpdate, Probe, ReplicaSet の概念, `kubectl rollout`

---

## 1) Topic + Level

### Beginner
**Topic:** Deployment と Service でアプリを公開する

### Middle
**Topic:** ReadinessProbe + RollingUpdate で安全に更新する

### Advanced
**Topic:** 失敗リリースを検知し、`rollout undo` で安全に戻す

---

## 2) なぜ実アプリ開発で重要か
- 本番では「動く」だけでなく、**止めずに更新できること**が重要。
- リリース時の障害は、更新設計（Probe・段階的更新・監視）で大きく減らせる。
- `kubectl` の基礎運用ができると、CI/CD 失敗時にも迅速に一次対応できる。

---

## 3) コア kubectl / Kubernetes 概念
- **Deployment**: 宣言的に desired state（例: レプリカ数、イメージ）を管理。
- **ReplicaSet**: Deployment の各リビジョンを実体として保持。
- **Service (ClusterIP/NodePort/LoadBalancer)**: Pod の入れ替わりを隠蔽し、安定した接続先を提供。
- **ReadinessProbe**: 「トラフィックを受けてよい状態」判定。未Ready PodはService配下に入らない。
- **RollingUpdate**: Pod を段階的に入れ替え。`maxUnavailable` / `maxSurge` で更新速度と安全性を制御。
- **Rollout history/undo**: リリース履歴確認と切り戻し。

---

## 4) アプリ開発時の使い方（kubernetes.io/docs のベストプラクティス寄り）
1. **マニフェストは Git 管理**し、`kubectl apply -f` で宣言的に適用。
2. **`readinessProbe` を必ず設定**し、起動中Podに誤ってトラフィックを流さない。
3. **段階更新（RollingUpdate）**を使い、全台同時停止を防ぐ。
4. **`kubectl diff -f` で事前差分確認**してから apply。
5. **`-n <namespace>` を明示**し、誤環境適用を防ぐ。
6. **Secret を平文で Git 管理しない**（Sealed Secrets / External Secrets / CI Secret 管理を検討）。

---

## 5) 30-60分ハンズオンミニラボ（約45分）

> ローカルクラスタ（kind / minikube / Docker Desktop Kubernetes）想定

### 0. 事前安全チェック（5分）
```bash
kubectl config current-context
kubectl get ns
```
- 期待しない context（本番など）なら**即停止**。

### 1. Beginner: 初期デプロイ（10分）
```bash
kubectl create ns mag-lab
kubectl -n mag-lab create deployment web --image=nginx:1.25
kubectl -n mag-lab expose deployment web --port=80 --target-port=80 --type=ClusterIP
kubectl -n mag-lab get all
```

### 2. Middle: ReadinessProbe + RollingUpdate 設定（15分）
以下を `web-deploy.yaml` として保存:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
  namespace: mag-lab
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

```bash
kubectl diff -f web-deploy.yaml
kubectl apply -f web-deploy.yaml
kubectl -n mag-lab rollout status deployment/web
```

### 3. Advanced: 意図的に失敗更新 → ロールバック（15分）
```bash
kubectl -n mag-lab set image deployment/web nginx=nginx:does-not-exist
kubectl -n mag-lab rollout status deployment/web --timeout=60s
kubectl -n mag-lab get pods
kubectl -n mag-lab rollout history deployment/web
kubectl -n mag-lab rollout undo deployment/web
kubectl -n mag-lab rollout status deployment/web
```

### 4. 後片付け（任意）
```bash
kubectl delete ns mag-lab
```
> ⚠️ `delete` 実行前に namespace と context を必ず再確認。

---

## 6) Command Cheatsheet
```bash
# コンテキスト/Namespace確認
kubectl config current-context
kubectl config get-contexts
kubectl get ns

# 参照系（安全）
kubectl -n <ns> get deploy,rs,pods,svc
kubectl -n <ns> describe deploy <name>
kubectl -n <ns> logs deploy/<name>

# 変更前確認
kubectl diff -f <file>.yaml

# 適用
kubectl apply -f <file>.yaml

# ロールアウト
kubectl -n <ns> rollout status deploy/<name>
kubectl -n <ns> rollout history deploy/<name>
kubectl -n <ns> rollout undo deploy/<name>

# 事故防止
kubectl -n <ns> delete -f <file>.yaml
```

---

## 7) よくあるミスと安全策

### ミス1: 間違った context に apply/delete
- **安全策:** `kubectl config current-context` を毎回確認。エイリアス化しても確認を省略しない。

### ミス2: Namespace 未指定で default に適用
- **安全策:** 常に `-n <namespace>`、または manifest に `metadata.namespace` を明記。

### ミス3: Secret を manifest に平文記載
- **安全策:** Secret管理基盤を使う。最低でも Git に生値を置かない。

### ミス4: Probe 未設定で更新時に 5xx 増加
- **安全策:** readiness/liveness/startupProbe をアプリ特性に合わせて設定。

### ミス5: `kubectl apply -f .` で意図しないファイルまで適用
- **安全策:** 対象ファイル/ディレクトリを限定。`kubectl diff` で事前確認。

---

## 8) 面接っぽい一問
**Q.** RollingUpdate 中に一時的なエラーを最小化するには、`maxUnavailable` と `readinessProbe` をどう設計しますか？

**A.（要点）**
- `readinessProbe` で「受け付け可能」判定を厳密化。
- `maxUnavailable` を小さく（例: 0〜1）して同時ダウンを抑制。
- 必要に応じ `maxSurge` を増やして先に新Podを増やし、余力を持って切替える。

---

## 9) 次の一歩（公式ドキュメント中心）
- Kubernetes Concepts Overview  
  https://kubernetes.io/docs/concepts/
- Deployments  
  https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Probes (Liveness, Readiness, Startup)  
  https://kubernetes.io/docs/concepts/configuration/liveness-readiness-startup-probes/
- kubectl Cheat Sheet  
  https://kubernetes.io/docs/reference/kubectl/cheatsheet/
- Configuration Best Practices  
  https://kubernetes.io/docs/concepts/configuration/overview/
- Secrets (good practices)  
  https://kubernetes.io/docs/concepts/configuration/secret/

---

### 今日のひとこと
「`apply` の前に `current-context` と `diff` を見る習慣」が、いちばん安い障害対策。