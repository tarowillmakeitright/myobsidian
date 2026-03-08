# Daily Kubernetes Commands Magazine — 2026-03-08 (09:25)
Tags: #kubernetes #k8s #devops #learning #daily
Links: [[Home]]

---

## 1) Topic + Level

**今号テーマ:** `kubectl apply / rollout / logs / exec` を使った「安全なデプロイと障害対応」の基本

- **Beginner:** Deployment を apply して状態確認する
- **Middle:** Rolling Update と Rollback で安全に更新する
  - **前提知識:** Pod / Deployment の基本、`kubectl get/describe/logs` の利用経験
- **Advanced:** マルチコンテナ Pod のデバッグ + 適用範囲ミス防止（context/namespace/selector）
  - **前提知識:** ReplicaSet の理解、namespace 運用、ラベル/セレクタ

---

## 2) Why it matters for real app development

実アプリ開発では、**「動くこと」より「安全に更新し続けられること」**が重要です。  
`kubectl apply` で宣言的に管理し、`rollout` で段階的に更新し、`logs/describe/exec` で障害対応する流れは、日常運用の最小セットです。  
CI/CD や本番運用でもそのまま使えるため、早い段階で身につける価値が高いです。

---

## 3) Core kubectl/Kubernetes concepts

- **Declarative management (`kubectl apply`)**
  - 「こうあるべき状態」を YAML に書き、クラスタ状態を収束させる。
  - `kubectl create` 単発より再現性が高い。
- **Deployment と Rollout**
  - Deployment は ReplicaSet を通して Pod を管理。
  - `rollout status/history/undo` で更新を追跡・復元。
- **観測の基本 (`get/describe/logs`)**
  - `get`: 一覧
  - `describe`: 詳細イベント（失敗原因特定に有効）
  - `logs`: コンテナ標準出力
- **`exec` の位置づけ**
  - 緊急デバッグ用。恒常運用は logs/metrics/trace 優先。

---

## 4) How Kubernetes is used while building apps (best-practice aligned)

kubernetes.io/docs の考え方に沿うと、アプリ開発フローは次の形が実践的です。

1. **マニフェストを Git 管理**（Deployment/Service/ConfigMap を分離）
2. **namespace を環境単位で分ける**（dev/stg/prod）
3. **`kubectl config current-context` を毎回確認**して誤操作防止
4. **`kubectl apply -f <dir>` は対象を明確化**（`-n` 指定必須）
5. **更新後に `rollout status` を確認**
6. 異常時は **`describe` → `logs` → 必要時のみ `exec`**
7. 秘密情報は **Secret や外部 Secret 管理**を使い、**平文を YAML に直書きしない**

---

## 5) 30–60 minute hands-on mini lab

### ゴール
- Nginx Deployment を作成
- イメージ更新を実施
- 意図的に失敗更新して rollback
- ログ/イベントから原因確認

### 事前準備
- ローカルクラスタ（例: minikube / kind）
- `kubectl` 利用可能

### 手順（45分目安）

#### Step 0: 安全確認（5分）
```bash
kubectl config current-context
kubectl get ns
```

#### Step 1: namespace と Deployment 作成（10分）
```bash
kubectl create namespace magazine-lab
kubectl -n magazine-lab create deployment web --image=nginx:1.25
kubectl -n magazine-lab expose deployment web --port=80 --type=ClusterIP
kubectl -n magazine-lab get all
```

#### Step 2: ロールアウト監視（5分）
```bash
kubectl -n magazine-lab rollout status deployment/web
kubectl -n magazine-lab get pods -o wide
```

#### Step 3: 正常な更新（10分）
```bash
kubectl -n magazine-lab set image deployment/web nginx=nginx:1.26
kubectl -n magazine-lab rollout status deployment/web
kubectl -n magazine-lab rollout history deployment/web
```

#### Step 4: 失敗更新を作って復旧（10分）
```bash
kubectl -n magazine-lab set image deployment/web nginx=nginx:does-not-exist
kubectl -n magazine-lab rollout status deployment/web
kubectl -n magazine-lab describe deployment web
kubectl -n magazine-lab get pods
kubectl -n magazine-lab rollout undo deployment/web
kubectl -n magazine-lab rollout status deployment/web
```

#### Step 5: 後片付け（任意、5分）
> ⚠ 破壊的操作。context と namespace を再確認してから実行。
```bash
kubectl config current-context
kubectl delete namespace magazine-lab
```

---

## 6) Command cheatsheet

```bash
# 文脈確認（最重要）
kubectl config current-context
kubectl config get-contexts

# 基本観測
kubectl get pods -n <ns>
kubectl describe pod <pod> -n <ns>
kubectl logs <pod> -n <ns>
kubectl logs <pod> -c <container> -n <ns>

# 適用と更新
kubectl apply -f <file-or-dir> -n <ns>
kubectl set image deployment/<name> <container>=<image> -n <ns>

# ロールアウト
kubectl rollout status deployment/<name> -n <ns>
kubectl rollout history deployment/<name> -n <ns>
kubectl rollout undo deployment/<name> -n <ns>

# 緊急デバッグ
kubectl exec -it <pod> -n <ns> -- /bin/sh
```

---

## 7) Common mistakes and safe practices

### よくあるミス
1. **context 間違い**で本番に apply/delete
2. `-n` を付け忘れて default namespace に誤適用
3. Secret を平文で Git コミット
4. `kubectl delete -f .` のような広すぎる削除
5. 失敗時に `logs` だけ見て `describe events` を見ない

### 安全プラクティス
- 実行前に毎回: `kubectl config current-context`
- namespace 明示: `-n <ns>` を習慣化
- 変更前後に: `rollout status` / `rollout history`
- Secret は外部管理（Vault, External Secrets 等）や K8s Secret を利用
- 破壊的コマンド前に対象確認:
  - `kubectl get <resource> -n <ns>`
  - `kubectl diff -f <dir> -n <ns>`（適用差分確認）

---

## 8) Interview-style question

**Q.** `kubectl apply` と `kubectl replace` の違いは？本番運用で apply が好まれる理由を説明してください。  
**A. の観点例:** 宣言的管理、差分適用、GitOps との親和性、運用の再現性、人的ミス低減。

---

## 9) Next-step resources (official docs first)

- Kubernetes Documentation (Home)  
  https://kubernetes.io/docs/
- Concepts: Overview / Objects / Workloads  
  https://kubernetes.io/docs/concepts/
- kubectl Quick Reference  
  https://kubernetes.io/docs/reference/kubectl/quick-reference/
- Deployments  
  https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Debug running Pods  
  https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/
- Configure Access to Multiple Clusters (contexts)  
  https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/
- Secrets (good practices)  
  https://kubernetes.io/docs/concepts/configuration/secret/

---

### 次号予告（学習アーク継続）
- Beginner: ConfigMap/Secret の安全な使い分け
- Middle: Readiness/Liveness Probe の設計
- Advanced: HPA と requests/limits を使った安定運用
