---
tags: [kubernetes, k8s, devops, learning, daily]
---

# Daily Kubernetes Commands Magazine — 2026-05-02
[[Home]]

## 今号のテーマ
**Topic:** `kubectl apply / rollout / probe` を使った「安全な段階的デプロイ」  
**学習アーク:** Beginner → Middle → Advanced

---

## 1) Topic + Level

### 🟢 Beginner
**レベル:** Beginner  
**テーマ:** `kubectl apply` と `kubectl get/describe/logs` の基本で Deployment を動かす

### 🟡 Middle
**レベル:** Middle  
**前提知識:**
- Pod / Deployment / Service の基本概念
- `kubectl apply -f` と `kubectl get pods` を使ったことがある

**テーマ:** Readiness/Liveness Probe と RollingUpdate の理解

### 🔴 Advanced
**レベル:** Advanced  
**前提知識:**
- Deployment の更新手順（`rollout status/history/undo`）
- Probe の設定経験
- ConfigMap/Secret の使い分けの基礎

**テーマ:** 失敗時に即ロールバックできる安全な本番運用フロー

---

## 2) なぜ実アプリ開発で重要か

- デプロイは「動けばOK」ではなく、**止めないこと**が重要。
- Readiness がないと、起動途中 Pod にトラフィックが流れて 5xx を誘発しやすい。
- Rollout と Rollback を標準手順化すると、障害時の MTTR（復旧時間）を短縮できる。
- `kubectl` の安全運用（context確認・適用範囲確認）だけで、事故率を大幅に下げられる。

---

## 3) コア概念（kubectl / Kubernetes）

- **apply**: 宣言的に望ましい状態をクラスタへ反映する。
- **Deployment**: Pod のレプリカ管理と更新戦略を持つ。
- **RollingUpdate**: Pod を段階的に置き換え、無停止に近い更新を実現。
- **Readiness Probe**: 「この Pod はリクエスト受付可能か」を判定。
- **Liveness Probe**: 「この Pod は生きているか」を判定（異常時再起動）。
- **rollout**: 進行確認・履歴確認・ロールバックを行う運用コマンド群。

---

## 4) アプリ開発での実践利用（kubernetes.io/docs のベストプラクティス寄り）

- マニフェストは Git 管理（Infrastructure as Code）し、`kubectl apply -f` はレビュー済みファイルのみ実行。
- Secret を YAML に平文で直書きしない（環境差分は Secret/外部シークレット管理へ）。
- 本番前に `kubectl config current-context` を必ず確認。
- Deployment には Readiness/Liveness を明示して「起動=即配信」を避ける。
- `rollout status` を確認してから次の作業へ進む。

---

## 5) 30〜60分ミニラボ

### 目的
Nginx Deployment を更新し、Probe と Rollback を体験する。

### 手順（約45分）

1. **作業前の安全確認（5分）**
```bash
kubectl config current-context
kubectl get ns
```

2. **初期 Deployment 作成（10分）**
```yaml
# deploy.yaml
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
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 10
          periodSeconds: 10
```

```bash
kubectl apply -f deploy.yaml
kubectl rollout status deployment/web
kubectl get pods -l app=web
```

3. **安全な更新（10分）**
```bash
kubectl set image deployment/web nginx=nginx:1.27
kubectl rollout status deployment/web
kubectl rollout history deployment/web
```

4. **失敗を模擬してロールバック（10〜15分）**
```bash
kubectl set image deployment/web nginx=nginx:does-not-exist
kubectl rollout status deployment/web
kubectl get pods -l app=web
kubectl rollout undo deployment/web
kubectl rollout status deployment/web
```

5. **振り返り（5分）**
- どの時点で異常を検知したか
- `rollout undo` まで何分かかったか

---

## 6) Command Cheatsheet

```bash
# 文脈確認
kubectl config current-context
kubectl config get-contexts

# 適用
kubectl apply -f deploy.yaml

# 状態確認
kubectl get deploy,pods
kubectl describe deploy web
kubectl logs deploy/web

# ロールアウト
kubectl rollout status deployment/web
kubectl rollout history deployment/web
kubectl rollout undo deployment/web

# 差分確認（可能なら）
kubectl diff -f deploy.yaml
```

---

## 7) よくあるミス & 安全策

### よくあるミス
- 間違った context のまま `apply` / `delete`。
- `-n` 指定漏れで別 namespace を操作。
- Readiness 未設定で更新直後にエラー急増。
- Secret を Git 管理に平文でコミット。

### 安全策
- **破壊的コマンド前に必ず警告レベルで確認**: `kubectl delete ...` 実行前に `current-context` と対象 namespace を再確認。
- `kubectl apply -f .` のような広すぎる適用は避け、対象ファイルを明示。
- 先に `kubectl diff -f <file>` で変更影響を確認。
- Secret は `stringData` でも平文流出リスクがあるため、リポジトリ管理方針を厳格化。

---

## 8) 面接っぽい一問

**Q. Readiness Probe と Liveness Probe の違いを説明し、両方を設定しない場合に起きる本番障害を1つ挙げてください。**

---

## 9) 次の一歩（公式ドキュメント中心）

- Kubernetes Docs (Home)  
  https://kubernetes.io/docs/
- Deployments  
  https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Probes (Liveness/Readiness/Startup)  
  https://kubernetes.io/docs/concepts/configuration/liveness-readiness-startup-probes/
- kubectl Cheat Sheet  
  https://kubernetes.io/docs/reference/kubectl/cheatsheet/
- Configure Access to Multiple Clusters (context運用)  
  https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/
- Secrets (安全な扱い)  
  https://kubernetes.io/docs/concepts/configuration/secret/

---

**明日の予告（学習アーク継続）:**
Service/Ingress と NetworkPolicy を使った「公開範囲の最小化」