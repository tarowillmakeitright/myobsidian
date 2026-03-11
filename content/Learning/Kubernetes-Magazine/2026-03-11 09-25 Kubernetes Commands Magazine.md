---
tags: [kubernetes, k8s, devops, learning, daily]
---

# Daily Kubernetes Commands Magazine — 2026-03-11 (09:25)
[[Home]]

> 今日の学習アーク: **Beginner → Middle → Advanced**
> テーマ: **アプリを安全にデプロイ・公開・運用するための基本動線（Deployment / Service / Rollout / Debug）**

---

## 1) Topic + Level

### 🟢 Beginner
**トピック:** `Deployment` と `Service (ClusterIP)` でアプリをクラスタ内公開する

### 🟡 Middle
**トピック:** `Service (NodePort/LoadBalancer)` と `rollout` を使った段階的リリース確認
**前提知識:**
- Pod / Deployment / Service の基本
- `kubectl get/describe/logs` が使える
- YAML マニフェストの基本構文

### 🔴 Advanced
**トピック:** `readinessProbe/livenessProbe`・`resources`・`Namespace` 分離と安全な更新運用
**前提知識:**
- Deployment の更新戦略（RollingUpdate）
- Service の種類と通信経路
- コンテナの基本的なヘルスチェック概念

---

## 2) Why it matters for real app development

実アプリ開発では、
- **止めずに更新する（可用性）**
- **安全に公開する（最小公開）**
- **問題を素早く切り分ける（運用性）**
が必須です。  
Kubernetes の `Deployment` / `Service` / `rollout` / `probe` を理解すると、開発〜本番運用まで同じ考え方で扱えるため、リリース品質が安定します。

---

## 3) Core kubectl / Kubernetes concepts

- **Deployment**: Pod の望ましい状態（レプリカ数・イメージ・更新方式）を宣言する
- **Service**: Pod の集合へ安定したアクセス手段を提供する
- **Labels / Selectors**: どの Pod を Service が束ねるか決める
- **Rollout**: Deployment の更新履歴・進行・巻き戻しを管理
- **Probe**:
  - `readinessProbe`: トラフィックを受けてよいか
  - `livenessProbe`: プロセスが生きているか
- **Namespace**: 環境やチーム単位で論理分離

---

## 4) App building での Kubernetes 活用（kubernetes.io/docs ベストプラクティス準拠）

- マニフェストは **宣言的（declarative）** に管理し、`kubectl apply -f` で反映
- 設定とシークレットを分離（`ConfigMap` / `Secret`）。**平文シークレットを Git に置かない**
- `resources.requests/limits` と `probes` を定義し、安定運用を前提化
- `kubectl rollout status` で更新の成否を必ず確認
- 本番前に `--dry-run=client` や `kubectl diff` で変更影響を確認

---

## 5) 30–60分ミニラボ

### ゴール
Nginx アプリをデプロイし、Service 公開、ローリングアップデート、障害時の切り分けを体験する。

### 手順

#### Step 0: 作業前の安全確認（超重要）
```bash
kubectl config current-context
kubectl get ns
```
- 意図しないクラスタ・Namespace で実行しない。

#### Step 1: Namespace 作成
```bash
kubectl create namespace k8s-mag-lab
kubectl config set-context --current --namespace=k8s-mag-lab
```

#### Step 2: Deployment 作成
```bash
kubectl create deployment web --image=nginx:1.25
kubectl scale deployment web --replicas=2
kubectl get pods -o wide
```

#### Step 3: Service 作成（ClusterIP）
```bash
kubectl expose deployment web --name=web-svc --port=80 --target-port=80
kubectl get svc
```

#### Step 4: 動作確認（ポートフォワード）
```bash
kubectl port-forward svc/web-svc 8080:80
# 別ターミナル
curl -I http://127.0.0.1:8080
```

#### Step 5: ローリングアップデート
```bash
kubectl set image deployment/web nginx=nginx:1.27
kubectl rollout status deployment/web
kubectl rollout history deployment/web
```

#### Step 6: トラブル想定（存在しないタグ）
```bash
kubectl set image deployment/web nginx=nginx:9.99
kubectl rollout status deployment/web
kubectl describe deployment web
kubectl get pods
```
失敗を確認後、ロールバック:
```bash
kubectl rollout undo deployment/web
kubectl rollout status deployment/web
```

#### Step 7: 後片付け
```bash
kubectl config set-context --current --namespace=default
kubectl delete namespace k8s-mag-lab
```
> ⚠️ `delete` は対象を必ず確認。`kubectl delete ns` は破壊的操作。

---

## 6) Command cheatsheet

```bash
# コンテキスト/名前空間確認
kubectl config current-context
kubectl get ns
kubectl config set-context --current --namespace=<ns>

# 基本リソース操作
kubectl get deploy,po,svc
kubectl describe deployment <name>
kubectl logs -l app=<label> --tail=100

# デプロイ/公開
kubectl create deployment <name> --image=<image>
kubectl expose deployment <name> --name=<svc> --port=80 --target-port=80
kubectl scale deployment <name> --replicas=3

# 更新/ロールバック
kubectl set image deployment/<name> <container>=<image:tag>
kubectl rollout status deployment/<name>
kubectl rollout history deployment/<name>
kubectl rollout undo deployment/<name>

# 安全確認
kubectl diff -f <manifest.yaml>
kubectl apply --dry-run=client -f <manifest.yaml>
```

---

## 7) Common mistakes and safe practices

### よくあるミス
1. **コンテキスト誤り**で本番に apply/delete
2. `default` Namespace に雑に作って混線
3. `:latest` タグで再現性を失う
4. Secret を YAML 平文でコミット
5. `kubectl delete -f .` のような広域削除

### 安全策
- 実行前に `kubectl config current-context` を習慣化
- Namespace を明示 (`-n <ns>` or context 固定)
- イメージは固定タグ/ダイジェストを使用
- Secret は External Secrets / Sealed Secrets 等を検討
- 破壊的コマンド前に対象確認:
  - `kubectl get ... -n <ns>`
  - `kubectl diff -f ...`
  - 必要ならレビュー後に実行

---

## 8) Interview-style question

**質問:**
`readinessProbe` と `livenessProbe` の違いを説明し、誤設定した場合に本番環境で起きる問題を1つずつ挙げてください。

**回答の観点（自己チェック）:**
- readiness は「トラフィック受付可否」、liveness は「再起動要否」
- readiness 不備: 正常前トラフィック流入で 5xx 増加
- liveness 不備: 不要再起動や CrashLoopBackOff

---

## 9) Next-step resources（公式優先）

- Kubernetes Concepts  
  https://kubernetes.io/docs/concepts/
- Deployments  
  https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Services, Load Balancing, and Networking  
  https://kubernetes.io/docs/concepts/services-networking/service/
- Probes (Liveness/Readiness/Startup)  
  https://kubernetes.io/docs/concepts/configuration/liveness-readiness-startup-probes/
- kubectl Cheat Sheet  
  https://kubernetes.io/docs/reference/kubectl/cheatsheet/
- ConfigMap  
  https://kubernetes.io/docs/concepts/configuration/configmap/
- Secret（安全な取り扱い）  
  https://kubernetes.io/docs/concepts/configuration/secret/
- Resource Management for Pods and Containers  
  https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/

---

次号予告（難易度アーク継続）: **ConfigMap/Secret と 12-Factor 設計、Ingress 基礎、デバッグ導線の強化**