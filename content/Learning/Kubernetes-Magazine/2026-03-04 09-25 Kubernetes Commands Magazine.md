---
tags:
  - kubernetes
  - k8s
  - devops
  - learning
  - daily
---

# Daily Kubernetes Commands Magazine — 2026-03-04 09:25
[[Home]]

> 今日の学習アーク: **Beginner → Middle → Advanced**  
> テーマ: **アプリ開発で実際に使う「Deployment運用の基本から安全なロールアウトまで」**

---

## 1) Topic + Level

### 🟢 Beginner
**Topic:** Deployment / Pod / Service の基本操作と `kubectl` の見方

### 🟡 Middle（前提あり）
**Topic:** RollingUpdate・ヘルスチェック（readiness/liveness）で無停止に近づける

**Prerequisites（Middle）**
- Pod / Deployment / Service の役割を説明できる
- `kubectl get/describe/logs` を使って状態確認できる
- YAML マニフェストを apply した経験がある

### 🔴 Advanced（前提あり）
**Topic:** `kubectl rollout` と履歴管理、失敗時の rollback、context/namespace 安全運用

**Prerequisites（Advanced）**
- RollingUpdate の概念（maxUnavailable/maxSurge）を理解
- readinessProbe がトラフィック制御に関わることを理解
- 複数 namespace / context を触った経験がある

---

## 2) Why it matters for real app development

本番アプリでは「動く」だけでは不十分で、**止めずに更新し、問題時に安全に戻せること**が重要です。  
Kubernetes では Deployment を中心に、更新戦略・ヘルスチェック・ロールバックを組み合わせることで、ユーザー影響を最小化できます。

- 機能リリース時のダウンタイム低減
- 障害切り戻しの高速化
- チーム開発での再現可能な運用（Git + manifest）

---

## 3) Core kubectl/Kubernetes concept explanations

- **Pod**: コンテナ実行の最小単位（通常は直接運用しない）
- **Deployment**: Pod の望ましい状態を管理し、ローリング更新を提供
- **Service**: Pod 群への安定したアクセス経路
- **readinessProbe**: 「リクエストを受けて良いか」判定（未準備Podへの送信を避ける）
- **livenessProbe**: ハングしたコンテナの自己回復再起動
- **rollout**: Deployment 更新の進行管理・履歴・巻き戻し

よく使う確認系コマンド:
- `kubectl get pods -n <ns>`
- `kubectl describe deploy <name> -n <ns>`
- `kubectl logs -f deploy/<name> -n <ns>`
- `kubectl rollout status deploy/<name> -n <ns>`

---

## 4) How Kubernetes is used while building apps（kubernetes.io/docs ベストプラクティス準拠）

アプリ開発フロー例:
1. 開発者がイメージをビルドしタグ付け（例: `myapp:1.2.0`）
2. Deployment マニフェストの image を更新
3. `kubectl apply -f` で宣言的に適用
4. `kubectl rollout status` で更新監視
5. probe とリソース制限で安定運用
6. 問題時は `kubectl rollout undo`

ベストプラクティス:
- `latest` タグを避け、**不変タグ**を使う
- readiness/liveness を入れる
- requests/limits を設定
- Secret を平文でGit管理しない
- 本番は RBAC / namespace 分離 / context確認を徹底

---

## 5) 30–60 minute hands-on mini lab

**目標:** NGINX Deployment を安全に更新し、失敗時 rollback まで体験

### Step 0: 事前確認（5分）
```bash
kubectl config current-context
kubectl get ns
```
> ⚠️ **破壊的操作防止**: context と namespace を毎回確認。誤クラスタ適用を防ぐ。

### Step 1: Namespace と初期 Deployment 作成（10分）
```bash
kubectl create namespace magazine-lab
kubectl -n magazine-lab create deployment web --image=nginx:1.25
kubectl -n magazine-lab expose deployment web --port=80 --type=ClusterIP
kubectl -n magazine-lab get all
```

### Step 2: ロールアウト監視（5分）
```bash
kubectl -n magazine-lab rollout status deployment/web
kubectl -n magazine-lab get pods -w
```

### Step 3: 安全な更新（10分）
```bash
kubectl -n magazine-lab set image deployment/web nginx=nginx:1.26
kubectl -n magazine-lab rollout status deployment/web
kubectl -n magazine-lab rollout history deployment/web
```

### Step 4: 意図的に失敗させる（10分）
```bash
kubectl -n magazine-lab set image deployment/web nginx=nginx:does-not-exist
kubectl -n magazine-lab rollout status deployment/web
kubectl -n magazine-lab describe deployment/web
```
失敗イベント（ImagePullBackOff 等）を確認。

### Step 5: rollback（5分）
```bash
kubectl -n magazine-lab rollout undo deployment/web
kubectl -n magazine-lab rollout status deployment/web
```

### Step 6: 後片付け（任意・5分）
```bash
kubectl delete namespace magazine-lab
```
> ⚠️ `kubectl delete namespace` は配下リソースを全削除。対象 namespace を必ず再確認。

---

## 6) Command cheatsheet

```bash
# コンテキスト/名前空間確認
kubectl config current-context
kubectl config get-contexts
kubectl get ns

# 状態確認
kubectl get pods -n <ns>
kubectl get deploy -n <ns>
kubectl describe deploy <name> -n <ns>
kubectl logs -f deploy/<name> -n <ns>

# デプロイ更新/履歴/巻き戻し
kubectl set image deployment/<name> <container>=<image>:<tag> -n <ns>
kubectl rollout status deployment/<name> -n <ns>
kubectl rollout history deployment/<name> -n <ns>
kubectl rollout undo deployment/<name> -n <ns>

# 宣言的適用
kubectl apply -f <manifest.yaml>
kubectl diff -f <manifest.yaml>
```

---

## 7) Common mistakes and safe practices

### よくあるミス
1. **context確認忘れ**で別クラスタに apply/delete
2. `default` namespace に雑に投入
3. `:latest` 利用で再現性喪失
4. Secret を manifest に平文直書き
5. rollout 監視せず「適用して終わり」

### 安全策
- 実行前に `kubectl config current-context` と `-n <ns>` を固定
- 可能なら `kubectl diff -f` で差分確認してから apply
- Secret は `Secret` リソース + 外部シークレット管理（KMS/Vault等）を検討
- 破壊的コマンド前に対象を `get` / `describe` で二重確認
- 本番では RBAC 最小権限

---

## 8) One interview-style question

**Q.** readinessProbe と livenessProbe の違いを説明し、両方未設定だとローリングアップデート時にどんなリスクがあるか述べてください。

（回答の観点: トラフィック受け入れ可否判定 / プロセス生存監視 / 障害Podへの配信 / 早すぎる切替）

---

## 9) Next-step resources（公式 docs 優先）

- Kubernetes Concepts Overview  
  https://kubernetes.io/docs/concepts/overview/
- Deployments  
  https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Services  
  https://kubernetes.io/docs/concepts/services-networking/service/
- Probes (liveness, readiness, startup)  
  https://kubernetes.io/docs/concepts/configuration/liveness-readiness-startup-probes/
- kubectl Cheat Sheet  
  https://kubernetes.io/docs/reference/kubectl/cheatsheet/
- Configure Access to Multiple Clusters（context安全運用）  
  https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/
- Good Practices for Kubernetes Secrets  
  https://kubernetes.io/docs/concepts/security/secrets-good-practices/

---

次回予告（学習アーク継続）:  
**Beginner:** ConfigMap/Secret の使い分け → **Middle:** envFrom と volumeMount 実践 → **Advanced:** External Secrets + RBAC 最小権限設計
