---
tags:
  - kubernetes
  - k8s
  - devops
  - learning
  - daily
---

# Daily Kubernetes Commands Magazine (2026-05-01)
[[Home]]

今日のテーマは **「kubectl apply と宣言的デプロイの基本から安全運用まで」**。  
難易度は **Beginner → Middle → Advanced** の学習アークです。

---

## 1) Topic + Level

### Beginner
**Topic:** `kubectl` の基本操作と「宣言的管理（Declarative）」の第一歩

### Middle
**Topic:** Deployment の更新戦略（RollingUpdate）と安全なロールアウト管理

**Prerequisites（前提知識）:**
- Pod / Deployment / Service の基本概念
- `kubectl get`, `kubectl describe`, `kubectl logs` を使った閲覧経験
- YAML マニフェストの基本文法

### Advanced
**Topic:** コンテキスト誤操作を防ぐ実践、apply/delete のスコープ安全設計、差分確認運用

**Prerequisites（前提知識）:**
- Namespace 運用経験
- `kubectl config`（context / namespace）の理解
- Rolling update と rollback の実施経験

---

## 2) Why it matters for real app development

実アプリ開発では、以下が日常的に発生します。
- 新機能のデプロイ
- バグ修正の段階的リリース
- 障害時の迅速なロールバック
- 開発/検証/本番クラスタの安全な使い分け

`kubectl apply` を中心にした宣言的運用を正しく理解すると、**再現性・監査性・安全性** が上がり、チーム開発での事故（誤クラスタ操作、想定外削除、設定ドリフト）を大きく減らせます。

---

## 3) Core kubectl/Kubernetes concept explanations

- **Declarative（宣言的）管理**
  - 「どう実行するか」ではなく「あるべき状態」を YAML で定義し、`kubectl apply -f` で同期する。
- **Imperative（命令的）操作**
  - `kubectl run` や `kubectl scale` など、その場で命令する。
  - 学習初期は便利だが、チーム開発では宣言的な Git 管理が推奨。
- **Deployment**
  - Pod のレプリカ数維持、更新、履歴管理を担う。
- **RollingUpdate**
  - 無停止に近い形で新旧 Pod を入れ替える更新戦略。
- **Context / Namespace**
  - `kubectl` が「どのクラスタ」「どの namespace」に向くかを決める最重要設定。

---

## 4) How Kubernetes is used while building apps

kubernetes.io/docs のベストプラクティスに沿うと、アプリ開発では次の流れが実践的です。

1. アプリをコンテナ化（Dockerfile 等）
2. Deployment / Service マニフェストを作成
3. `kubectl apply -f` で反映（まずは開発 namespace）
4. `kubectl rollout status` で更新状態を監視
5. 問題時は `kubectl rollout undo` で即時ロールバック
6. 変更差分を Git でレビューし、本番へ段階的適用

ポイント:
- **Secret を平文で Git に置かない**（Sealed Secrets や External Secrets、または外部 Secret Manager を検討）
- `latest` タグ固定を避け、追跡可能なイメージタグを使う
- `kubectl apply` 前に対象 context/namespace を毎回確認

---

## 5) 30-60 minute hands-on mini lab

**ラボ名:** 安全な Deployment 更新とロールバック体験（45分目安）

> 前提: ローカル検証クラスタ（minikube / kind 等）で実施推奨。  
> 本番クラスタでは実施しないでください。

### Step 0: 事前安全確認（5分）
```bash
kubectl config current-context
kubectl config get-contexts
kubectl get ns
```
- 期待する context か確認
- 作業用 namespace を分離

### Step 1: namespace と初期デプロイ（10分）
```bash
kubectl create namespace mag-lab
kubectl -n mag-lab create deployment web --image=nginx:1.25.5
kubectl -n mag-lab expose deployment web --port=80 --type=ClusterIP
kubectl -n mag-lab get all
```

### Step 2: 宣言的 YAML 化して apply（10分）
```bash
kubectl -n mag-lab get deployment web -o yaml > web-deploy.yaml
```
`web-deploy.yaml` を最低限整形（不要メタデータ削除）し、イメージを `nginx:1.25.5` のまま管理対象化。

```bash
kubectl apply -f web-deploy.yaml
kubectl -n mag-lab rollout status deployment/web
```

### Step 3: バージョン更新と監視（10分）
`web-deploy.yaml` の image を `nginx:1.27` などへ変更し:
```bash
kubectl apply -f web-deploy.yaml
kubectl -n mag-lab rollout status deployment/web
kubectl -n mag-lab rollout history deployment/web
```

### Step 4: 問題を想定してロールバック（10分）
```bash
kubectl -n mag-lab rollout undo deployment/web
kubectl -n mag-lab rollout status deployment/web
kubectl -n mag-lab get pods
```

### Step 5: 片付け（必要時）
```bash
# 破壊的操作: 実行前に context と namespace を再確認
kubectl config current-context
kubectl delete namespace mag-lab
```

---

## 6) Command cheatsheet

```bash
# コンテキスト/名前空間確認
kubectl config current-context
kubectl config get-contexts
kubectl get ns

# 基本閲覧
kubectl get pods -A
kubectl describe pod <pod-name> -n <ns>
kubectl logs <pod-name> -n <ns>

# 宣言的適用
kubectl apply -f <file-or-dir>
kubectl diff -f <file-or-dir>

# ロールアウト管理
kubectl rollout status deployment/<name> -n <ns>
kubectl rollout history deployment/<name> -n <ns>
kubectl rollout undo deployment/<name> -n <ns>

# 削除（注意）
kubectl delete -f <file-or-dir>
kubectl delete namespace <ns>
```

---

## 7) Common mistakes and safe practices

### よくあるミス
1. **context を確認せず apply/delete** して本番を壊す
2. `kubectl apply -f .` で意図しない YAML まで適用
3. Secret を平文 YAML/Git に保存
4. `:latest` イメージで変更追跡不能
5. ロールアウト監視せず「適用したつもり」で終了

### 安全プラクティス
- 毎回最初に `kubectl config current-context`
- `-n <namespace>` を明示する
- `kubectl diff -f ...` で差分を先に確認
- 破壊的コマンド前に「対象クラスタ・対象 namespace」を復唱
- Secret は専用仕組みで管理（平文回避）
- 本番反映前にステージングで同一手順をリハーサル

---

## 8) Interview-style question

**Q.** `kubectl apply` と `kubectl replace` の違いを説明し、チーム開発で `apply` が好まれる理由を述べてください。  
**期待ポイント:** 宣言的運用、差分適用、既存状態との整合、GitOps との相性、誤更新リスク低減。

---

## 9) Next-step resources (official docs中心)

- Kubernetes Documentation (Home)  
  https://kubernetes.io/docs/
- Overview: Kubernetes Concepts  
  https://kubernetes.io/docs/concepts/
- kubectl Overview  
  https://kubernetes.io/docs/reference/kubectl/
- Declarative Management of Kubernetes Objects  
  https://kubernetes.io/docs/tasks/manage-kubernetes-objects/declarative-config/
- Deployment (concepts)  
  https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Rollback a Deployment  
  https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#rolling-back-a-deployment
- Secret (concepts)  
  https://kubernetes.io/docs/concepts/configuration/secret/
- Configure Access to Multiple Clusters  
  https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/

---

次号予告（学習アーク継続）:  
**Beginner:** ConfigMap/Secret の使い分け  
**Middle:** Readiness/Liveness Probe 設計  
**Advanced:** PodSecurity と NetworkPolicy の最小権限設計
