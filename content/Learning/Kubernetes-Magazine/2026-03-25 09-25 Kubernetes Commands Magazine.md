---
tags: [kubernetes, k8s, devops, learning, daily]
date: 2026-03-25
---

# Kubernetes Commands Magazine（2026-03-25 09:25）
[[Home]]

> 学習アーク: **Beginner → Middle → Advanced**
> 
> テーマは段階的に難易度を上げ、実運用での安全性（特に Secret 管理・破壊的コマンドの扱い）を重視します。

---

## 1) Topic + Level

### 🟢 Beginner
**Topic:** Pod/Deployment の基本操作と安全な `kubectl` 実行習慣

### 🟡 Middle
**Topic:** Service / ConfigMap / Rolling Update を使ったアプリ運用
**Prerequisites:**
- Pod と Deployment の作成・確認・削除ができる
- `kubectl get/describe/logs` の使い分けが分かる
- Namespace の基本が分かる

### 🔴 Advanced
**Topic:** probes・requests/limits・HPA を使った可用性とスケーリング設計
**Prerequisites:**
- Deployment と Service の関係を説明できる
- RollingUpdate と rollout undo を実行できる
- CPU/Memory requests/limits の意味を理解している

---

## 2) Why it matters for real app development

- 開発環境だけでなく、**本番運用での再現性・安全性・可観測性**を担保できる。
- 手元で動くアプリを「チームで継続運用できる状態」に引き上げるには、Deployment/Service/probes/autoscaling が必須。
- `kubectl` の誤操作（context ミス、namespace ミス、広範囲 apply/delete）を防ぐ習慣は、障害予防に直結する。

---

## 3) Core kubectl/Kubernetes concept explanations

- **Pod:** コンテナ実行の最小単位。通常は直接運用せず Deployment 経由で管理。
- **Deployment:** 宣言的にレプリカ数・更新戦略を管理。
- **Service (ClusterIP):** Pod の入れ替わりを隠蔽し、安定したアクセス先を提供。
- **ConfigMap / Secret:** 設定と機密情報を分離（※Secret でも base64 は暗号化ではない）。
- **Probe (liveness/readiness/startup):** ヘルス判定で自動復旧・トラフィック制御。
- **resources requests/limits:** スケジューリングと OOM/CPU 競合制御の基礎。
- **HPA:** メトリクスに応じて Pod 数を自動調整。

---

## 4) App building における Kubernetes 活用（kubernetes.io/docs ベストプラクティス準拠）

- マニフェストは **宣言的管理**（`kubectl apply -f`）し、変更は Git 管理。
- **Namespace を分離**して環境ごとに影響範囲を限定。
- **readinessProbe** を設定して、起動直後の不安定な Pod にトラフィックを流さない。
- **requests/limits** を設定し、ノイジーネイバー問題を軽減。
- **Secret をマニフェスト直書きしない**（平文・base64を Git に置かない）。
- ロールアウトは `rollout status` で監視し、異常時は `rollout undo`。

参考（公式）:
- https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- https://kubernetes.io/docs/concepts/services-networking/service/
- https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/
- https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/
- https://kubernetes.io/docs/concepts/configuration/secret/

---

## 5) 30–60分ハンズオンミニラボ

### 目標
Nginx アプリを Deployment + Service で公開し、RollingUpdate と rollback、Probe・resources の基礎を体験する。

### 手順（45分目安）

1. **作業前チェック（安全）**
```bash
kubectl config current-context
kubectl get ns
```
> ⚠️ 破壊的操作前に必ず context/namespace を確認。

2. **専用 Namespace 作成**
```bash
kubectl create namespace magazine-lab
kubectl config set-context --current --namespace=magazine-lab
```

3. **Deployment 作成**
```bash
kubectl create deployment web --image=nginx:1.25
kubectl scale deployment web --replicas=2
kubectl get pods -o wide
```

4. **Service 公開（ClusterIP）**
```bash
kubectl expose deployment web --port=80 --target-port=80 --name=web-svc
kubectl get svc
```

5. **Rolling Update 実施**
```bash
kubectl set image deployment/web nginx=nginx:1.27
kubectl rollout status deployment/web
kubectl rollout history deployment/web
```

6. **失敗を想定した rollback 練習**
```bash
kubectl set image deployment/web nginx=nginx:invalid
kubectl rollout status deployment/web
kubectl rollout undo deployment/web
kubectl rollout status deployment/web
```

7. **Probe / resources を追記（編集）**
```bash
kubectl edit deployment web
```
追加例（container に追記）:
```yaml
readinessProbe:
  httpGet:
    path: /
    port: 80
  initialDelaySeconds: 5
  periodSeconds: 10
resources:
  requests:
    cpu: "100m"
    memory: "128Mi"
  limits:
    cpu: "300m"
    memory: "256Mi"
```

8. **確認と後片付け**
```bash
kubectl get deploy,po,svc
# 後片付け（必要時のみ）
kubectl delete ns magazine-lab
```
> ⚠️ `kubectl delete ns ...` は対象確認後に実行。誤った namespace 削除は重大事故につながる。

---

## 6) Command cheatsheet

```bash
# コンテキスト/名前空間確認
kubectl config current-context
kubectl config view --minify | grep namespace:

# 基本観察
kubectl get pods -A
kubectl describe pod <pod>
kubectl logs <pod> --tail=100

# Deployment運用
kubectl get deploy
kubectl scale deploy <name> --replicas=3
kubectl set image deploy/<name> <container>=<image:tag>
kubectl rollout status deploy/<name>
kubectl rollout undo deploy/<name>

# Service
kubectl get svc
kubectl describe svc <name>

# 安全な apply の癖
kubectl diff -f <manifest.yaml>
kubectl apply -f <manifest.yaml>
```

---

## 7) Common mistakes and safe practices

### よくあるミス
- `default` namespace のまま本番操作する
- `kubectl apply -f .` で意図しないファイルまで反映
- Secret を YAML に平文/復号可能形式でコミット
- Probe 未設定で、起動中の不安定 Pod にリクエストが流れる

### 安全プラクティス
- 実行前に毎回 `current-context` と namespace を確認
- `kubectl diff` を挟んで差分確認してから apply
- 破壊系コマンド（delete/replace/patch）前は対象を `get` で再確認
- Secret は External Secrets やシークレットマネージャ連携を優先
- 本番作業は `--namespace` 明示、または context を分離

---

## 8) Interview-style question

**Q.** Deployment に readinessProbe を設定しない場合、ローリングアップデート時にどんな障害が起こり得ますか？また、どう防ぎますか？

**期待する観点:**
- Ready 判定前に Service が転送し、5xx/タイムアウト増加
- `readinessProbe` と適切な `maxUnavailable/maxSurge` 設定
- `rollout status` 監視と段階的リリース

---

## 9) Next-step resources（公式優先）

1. Deployments
   - https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
2. Probes
   - https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/
3. Resource Management
   - https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/
4. Secrets
   - https://kubernetes.io/docs/concepts/configuration/secret/
5. kubectl Cheat Sheet
   - https://kubernetes.io/docs/reference/kubectl/cheatsheet/
6. Horizontal Pod Autoscaler
   - https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/

---

次号予告（Advanced継続）: **Ingress + TLS + NetworkPolicy で公開境界を安全に設計する**
