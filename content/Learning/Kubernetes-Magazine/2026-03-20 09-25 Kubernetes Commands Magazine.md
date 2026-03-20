---
tags: [kubernetes, k8s, devops, learning, daily]
---
# Daily Kubernetes Commands Magazine — 2026-03-20 (09:25)
[[Home]]

#kubernetes #k8s #devops #learning #daily

本日のテーマは、**Beginner → Middle → Advanced** の学習アークで、実務に直結する Kubernetes 運用・開発スキルを段階的に身につけます。

---

## 1) Topic + Level

### 🟢 Beginner
**Topic:** Pod/Deployment の基本と `kubectl` での安全な確認フロー

### 🟡 Middle
**Topic:** Service + ConfigMap/Secret の実践運用（アプリ設定の分離）
**Prerequisites:**
- Pod / Deployment の基本理解
- `kubectl get/describe/logs` を使える
- YAML マニフェストを読める

### 🔴 Advanced
**Topic:** RollingUpdate + Probes + Resource requests/limits で信頼性を高める
**Prerequisites:**
- Service による公開の仕組み理解
- ConfigMap/Secret の使い分け
- `kubectl apply -f` と差分運用（宣言的管理）の経験

---

## 2) Why it matters for real app development

- 開発では「ローカルで動く」だけでなく、**本番で安定して動くこと**が重要。Kubernetes はその土台。
- Deployment による更新戦略、Probe による自己回復、Resource 制御により、障害時の影響を最小化できる。
- ConfigMap/Secret で設定とコードを分離すると、環境差分（dev/stg/prod）を安全に管理できる。

---

## 3) Core kubectl/Kubernetes concept explanations

- **Pod**: コンテナ実行の最小単位。
- **Deployment**: Pod の望ましい状態を維持・更新するコントローラ。
- **Service**: Pod 群への安定したアクセス経路。
- **ConfigMap**: 非機密設定。
- **Secret**: 機密情報（パスワード、トークン等）を保持。※平文コミット禁止。
- **Probe (liveness/readiness/startup)**: 健康状態とトラフィック受け入れ可否を判定。
- **requests/limits**: スケジューリングと暴走防止の基準。
- **kubectl describe/logs/events**: 不具合切り分けの基本観測セット。

---

## 4) How Kubernetes is used while building apps（kubernetes.io/docs ベストプラクティス準拠）

実務フロー例：
1. 開発者がコンテナ化したアプリを Deployment として宣言
2. 設定値は ConfigMap、機密値は Secret で注入（マニフェストへ直書きしない）
3. Service で接続先を固定化し、アプリ間通信を安定化
4. readinessProbe を設定し、起動完了前の Pod へトラフィックを流さない
5. requests/limits を設定してクラスタ全体の安定性を担保
6. `kubectl rollout status/history/undo` で安全にリリース運用

> セキュリティ実務ポイント:
> - Secret を Git に平文で保存しない
> - `kubectl config current-context` を毎回確認して誤操作防止
> - 破壊的操作（`delete`, 広範囲 `apply`）前に namespace/context を再確認

---

## 5) 30-60 minute hands-on mini lab

### ゴール
Nginx ベースアプリを Deployment + Service で公開し、ConfigMap/Secret、Probe、RollingUpdate を確認する。

### 所要時間
45 分

### 手順

#### Step 0: 事前安全確認（5分）
```bash
kubectl config current-context
kubectl get ns
```
- 作業 namespace を決める（例: `k8s-magazine`）

```bash
kubectl create ns k8s-magazine
kubectl config set-context --current --namespace=k8s-magazine
```

#### Step 1: Deployment 作成（10分）
```bash
kubectl create deployment web --image=nginx:1.27
kubectl get pods -w
```

#### Step 2: Service 公開（5分）
```bash
kubectl expose deployment web --port=80 --target-port=80 --type=ClusterIP
kubectl get svc
```

#### Step 3: ConfigMap/Secret 作成（10分）
```bash
kubectl create configmap web-config --from-literal=APP_MODE=dev
kubectl create secret generic web-secret --from-literal=API_TOKEN='dummy-token'
kubectl get configmap,secret
```

> 注意: Secret の値を画面共有/ログに露出しない。`kubectl get secret -o yaml` の扱いに注意。

#### Step 4: Probe と Resource を追加（10分）
`kubectl edit deployment web` で以下を追加（概要）:
- readinessProbe: `httpGet /` port 80
- resources.requests: cpu `100m`, memory `128Mi`
- resources.limits: cpu `300m`, memory `256Mi`

反映確認:
```bash
kubectl rollout status deployment/web
kubectl describe pod -l app=web
```

#### Step 5: Rolling Update とロールバック（5-10分）
```bash
kubectl set image deployment/web nginx=nginx:1.26
kubectl rollout status deployment/web
kubectl rollout history deployment/web
# 必要なら
kubectl rollout undo deployment/web
```

#### Step 6: 後片付け（任意）
```bash
# 破壊的コマンド: context/namespace を必ず再確認
kubectl config current-context
kubectl delete ns k8s-magazine
```

---

## 6) Command cheatsheet

```bash
# 状態確認
kubectl get pods,svc,deploy
kubectl describe deploy web
kubectl logs -l app=web --tail=100
kubectl get events --sort-by=.metadata.creationTimestamp

# 安全確認
kubectl config current-context
kubectl config view --minify | grep namespace:

# デプロイ運用
kubectl apply -f manifest.yaml
kubectl rollout status deploy/web
kubectl rollout history deploy/web
kubectl rollout undo deploy/web

# 設定管理
kubectl create configmap NAME --from-literal=KEY=VALUE
kubectl create secret generic NAME --from-literal=KEY=VALUE

# デバッグ
kubectl exec -it POD_NAME -- sh
kubectl port-forward svc/web 8080:80
```

---

## 7) Common mistakes and safe practices

### よくあるミス
- `default` namespace に誤ってデプロイ
- 本番 context のまま `kubectl delete` 実行
- Secret をマニフェストに平文記載して Git へ push
- Probe 未設定で不安定 Pod にトラフィック流入
- requests/limits 未設定でノード資源を圧迫

### 安全プラクティス
- コマンド前に **context / namespace を声出し確認**
- 変更前に `kubectl diff -f ...` を活用
- ラベル設計を統一（`app`, `component`, `version`）
- 段階的ロールアウト + 監視（events/logs/metrics）
- Secret は外部シークレット管理（例: External Secrets 等）も検討

---

## 8) Interview-style question

**Q.** readinessProbe と livenessProbe は何が違い、誤設定するとどんな障害が起きますか？

**A.（要点）**
- readinessProbe: トラフィックを受け入れてよいか判定
- livenessProbe: プロセスが生きているか判定し、失敗時に再起動
- 誤設定例: readiness が厳しすぎると常時 Unready、liveness が厳しすぎると再起動ループ

---

## 9) Next-step resources（公式中心）

- Kubernetes Concepts
  - https://kubernetes.io/docs/concepts/
- Deployments
  - https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Services
  - https://kubernetes.io/docs/concepts/services-networking/service/
- ConfigMap
  - https://kubernetes.io/docs/concepts/configuration/configmap/
- Secrets
  - https://kubernetes.io/docs/concepts/configuration/secret/
- Probes (Liveness/Readiness/Startup)
  - https://kubernetes.io/docs/concepts/configuration/liveness-readiness-startup-probes/
- Manage Resources for Containers
  - https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/
- kubectl Cheat Sheet
  - https://kubernetes.io/docs/reference/kubectl/cheatsheet/

---

次号予告（学習アーク継続）:
- Ingress + TLS 基礎
- HPA とメトリクス
- NetworkPolicy による通信制御
