---
tags:
  - kubernetes
  - k8s
  - devops
  - learning
  - daily
---

# Kubernetes Commands Magazine — 2026-03-13
[[Home]]

今日のテーマは **「アプリを安全にデプロイし、段階的に運用レベルまで引き上げる kubectl 実践」** です。  
難易度を **Beginner → Middle → Advanced** の学習アークで進めます。

---

## 1) Topic + Level

### 🟢 Beginner
**Topic:** Pod / Deployment の基本操作（`get`, `describe`, `logs`, `apply`）

### 🟡 Middle
**Topic:** Service と Namespace を使ったアプリ公開・分離
**Prerequisites:**
- Pod / Deployment の基本を理解している
- `kubectl apply -f` と `kubectl get` を使える

### 🔴 Advanced
**Topic:** Rolling Update / Rollback と運用時の安全確認（context・scope・差分確認）
**Prerequisites:**
- Service/Namespace の基本を理解している
- Deployment の更新を `apply` で実行した経験がある

---

## 2) Why it matters for real app development

実アプリ開発では、ローカルで動いただけでは不十分で、**「安全に」「再現可能に」「止めずに」更新できること**が重要です。

- Deployment により、同じ構成を何度でも再現できる
- Service でアプリへの接続点を安定化できる
- Rolling Update / Rollback で障害時の復旧を速くできる
- Namespace と context 管理で、誤操作（本番に誤適用）リスクを下げられる

---

## 3) Core kubectl / Kubernetes concepts

- **Pod**: コンテナ実行の最小単位（通常は直接運用せず Deployment 管理）
- **Deployment**: Pod の望ましい状態（レプリカ数・イメージ）を宣言管理
- **Service**: Pod 群への安定したアクセス方法（ClusterIP/NodePort/LoadBalancer）
- **Namespace**: リソースを論理分離する単位
- **Context**: `kubectl` が向くクラスタ/ユーザー/Namespace の組

よく使う確認:
- `kubectl config current-context`
- `kubectl get ns`
- `kubectl get deploy,po,svc -n <namespace>`

---

## 4) Building apps with Kubernetes (kubernetes.io/docs aligned)

kubernetes.io/docs の推奨に沿うと、以下の流れが実務的です。

1. **マニフェストを宣言的に管理**（`kubectl apply -f`）
2. **環境ごとに Namespace 分離**（dev/stg/prod）
3. **可視化コマンドを習慣化**（`get/describe/logs/events`）
4. **更新は段階的に**（Rolling Update + `rollout status`）
5. **復旧手順を常備**（`rollout undo`）

> ⚠️ Secret を平文で Git に置かない。  
> Secret/Config の扱いは RBAC と最小権限を前提にする。

---

## 5) 30–60分ハンズオン・ミニラボ

**想定時間:** 45分  
**前提:** `kubectl` が利用可能な学習用クラスタ（kind/minikube など）

### Step 0: 事故防止チェック（5分）
```bash
kubectl config current-context
kubectl get ns
```
- 学習用 context であることを確認してから実行する。

### Step 1: Namespace と Deployment 作成（10分）
```bash
kubectl create namespace magazine-lab
kubectl create deployment web --image=nginx:1.25 -n magazine-lab
kubectl get deploy,po -n magazine-lab
```

### Step 2: Service 公開と疎通確認（10分）
```bash
kubectl expose deployment web --port=80 --target-port=80 --type=ClusterIP -n magazine-lab
kubectl get svc -n magazine-lab
kubectl describe svc web -n magazine-lab
```

### Step 3: 更新とロールアウト監視（10分）
```bash
kubectl set image deployment/web nginx=nginx:1.26 -n magazine-lab
kubectl rollout status deployment/web -n magazine-lab
kubectl get po -n magazine-lab -w
```

### Step 4: 問題を想定したロールバック（5分）
```bash
kubectl rollout undo deployment/web -n magazine-lab
kubectl rollout status deployment/web -n magazine-lab
```

### Step 5: ログ/イベント調査（5分）
```bash
kubectl logs -l app=web -n magazine-lab --tail=50
kubectl get events -n magazine-lab --sort-by=.metadata.creationTimestamp
```

### Step 6: 後片付け（任意）
```bash
# 破壊的コマンド: 対象 namespace を必ず確認
kubectl delete namespace magazine-lab
```

---

## 6) Command Cheatsheet

```bash
# コンテキスト/名前空間確認
kubectl config current-context
kubectl config get-contexts
kubectl get ns

# 主なリソース確認
kubectl get deploy,po,svc -n <ns>
kubectl describe deploy <name> -n <ns>
kubectl logs -l app=<label> -n <ns>

# 宣言的適用（対象に注意）
kubectl apply -f <file-or-dir> -n <ns>

# 更新/復旧
kubectl set image deployment/<name> <container>=<image>:<tag> -n <ns>
kubectl rollout status deployment/<name> -n <ns>
kubectl rollout history deployment/<name> -n <ns>
kubectl rollout undo deployment/<name> -n <ns>

# 差分確認（可能なら先に実施）
kubectl diff -f <file-or-dir> -n <ns>
```

---

## 7) Common mistakes and safe practices

### よくあるミス
1. **context を確認せず apply/delete** して本番に誤操作
2. `kubectl apply -f .` で意図しないファイルまで適用
3. Secret をマニフェストに平文記載してコミット
4. `latest` タグ使用で再現性が崩れる

### 安全プラクティス
- 実行前に `kubectl config current-context` を確認
- `-n <namespace>` を明示
- `kubectl diff -f ...` で事前差分確認
- 破壊的操作（`delete`, 広範囲 `apply`）前に対象を読み上げ確認
- イメージは固定タグ（できれば digest）を使う
- Secret は専用手段で管理し、アクセスは最小権限に

> ⚠️ **破壊的コマンド注意**: `kubectl delete` は対象と scope（namespace/context）を二重確認してから。

---

## 8) Interview-style question

**Q.** Deployment の Rolling Update 中に一部 Pod が Ready にならず更新が止まりました。あなたならどの順序で調査し、どの条件で Rollback を判断しますか？  
**A（考え方の例）:**
1. `rollout status` で停止状況把握
2. `describe deploy/po` と `events` で失敗理由特定（ImagePull, Probe, Resource など）
3. `logs` でアプリ起動失敗有無確認
4. 即時復旧優先なら `rollout undo`、原因切り分けは別環境で継続
5. 再発防止として probe/resources/tag 固定/CI検証を見直す

---

## 9) Next-step resources (official first)

- Kubernetes Concepts Overview  
  https://kubernetes.io/docs/concepts/overview/
- Deployments  
  https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Services, Load Balancing, and Networking  
  https://kubernetes.io/docs/concepts/services-networking/service/
- Namespaces  
  https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/
- kubectl Cheat Sheet  
  https://kubernetes.io/docs/reference/kubectl/cheatsheet/
- Configure Access to Multiple Clusters (contexts)  
  https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/
- Secret (good practices含む)  
  https://kubernetes.io/docs/concepts/configuration/secret/

---

次号予告（学習アーク継続）:  
**Beginner:** ConfigMap/Secret 基礎  
**Middle:** Probe と Resource Requests/Limits  
**Advanced:** HPA と運用監視の実践
