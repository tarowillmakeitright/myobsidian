---
tags: [kubernetes, k8s, devops, learning, daily]
---

# 2026-05-08 09:25 Kubernetes Commands Magazine
[[Home]]

#kubernetes #k8s #devops #learning #daily

## Issueテーマ
**Topic:** `kubectl apply` / `kubectl diff` / `kubectl rollout` で安全にデプロイを回す
**Level:** Beginner（学習アーク 1 周目）

> 学習アーク方針: Beginner → Middle → Advanced を日次で反復し、同じ「安全なアプリ配備」を段階的に深掘りします。

---

## 1) なぜ実アプリ開発で重要か
ローカルで動いたアプリを本番相当環境へ届けるとき、
- **再現可能な反映（宣言的運用）**
- **差分の可視化**
- **ロールバック可能性**

の3つがないと事故率が上がります。`kubectl apply` と `rollout` 系コマンドは、CI/CD があっても最終確認の基礎になります。特に小規模チームでは、**「誰がいつ何を変えたか」** を YAML と履歴で追えることが品質に直結します。

---

## 2) コア概念（kubectl / Kubernetes）

### A. 宣言的管理（Declarative）
- `kubectl apply -f <file>` は「こうあってほしい状態」を API サーバへ送る。
- imperative (`kubectl run` など都度命令) より、**再適用・レビュー・Git管理**に強い。

### B. 差分確認
- `kubectl diff -f <file>` で反映前に差分を見る。
- 事故の多くは「想定外の変更」を見逃すこと。**apply 前 diff** は基本動作。

### C. ローリングアップデート
- Deployment 更新時、Pod を一気に落とさず順次入れ替える。
- `kubectl rollout status deployment/<name>` で進行確認。
- 失敗時は `kubectl rollout undo deployment/<name>` で前世代へ戻す。

---

## 3) アプリ構築時にどう使うか（kubernetes.io/docs ベストプラクティス準拠）

実務の基本ループ:
1. YAML を Git 管理（Deployment/Service など）
2. `kubectl diff` で差分確認
3. `kubectl apply` で反映
4. `kubectl rollout status` と `kubectl get events` で検証
5. 問題あれば `rollout undo`

特に以下を守る:
- **Namespace を明示**（`-n`）して誤反映を避ける
- **context を毎回確認**（`kubectl config current-context`）
- Secret をプレーンテキストで直書きしない（Sealed Secrets / External Secrets / CI の安全な注入を検討）

---

## 4) 30〜60分ミニラボ（Beginner）

### ゴール
nginx Deployment を安全に更新し、失敗時にロールバックする体験を得る。

### 前提
- 手元に検証用クラスタ（kind / minikube / Docker Desktop Kubernetes など）
- `kubectl` が利用可能

### 手順

#### 0. 作業 Namespace 作成（5分）
```bash
kubectl create namespace mag-lab
kubectl config set-context --current --namespace=mag-lab
kubectl config current-context
```

#### 1. 初回 Deployment 適用（10分）
`deploy.yaml` を作成:
```yaml
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
```

適用:
```bash
kubectl diff -f deploy.yaml
kubectl apply -f deploy.yaml
kubectl rollout status deployment/web
kubectl get pods -o wide
```

#### 2. バージョン更新（10分）
`nginx:1.25` → `nginx:1.27` に変更して:
```bash
kubectl diff -f deploy.yaml
kubectl apply -f deploy.yaml
kubectl rollout status deployment/web
kubectl rollout history deployment/web
```

#### 3. 意図的に不正イメージで失敗させる（10〜15分）
`nginx:does-not-exist` に変更して apply:
```bash
kubectl apply -f deploy.yaml
kubectl rollout status deployment/web
kubectl get pods
kubectl describe pod <失敗Pod名>
```

#### 4. ロールバック（5分）
```bash
kubectl rollout undo deployment/web
kubectl rollout status deployment/web
kubectl get pods
```

#### 5. 後片付け（任意）
```bash
kubectl delete namespace mag-lab
```

> ⚠️ `delete` は破壊的です。**context と namespace を再確認**してから実行してください。

---

## 5) コマンドチートシート

```bash
# 現在の接続先確認
kubectl config current-context
kubectl config get-contexts

# Namespace 明示
kubectl get pods -n mag-lab
kubectl apply -f deploy.yaml -n mag-lab

# 反映前チェック
kubectl diff -f deploy.yaml
kubectl apply --dry-run=server -f deploy.yaml -o yaml

# デプロイ確認
kubectl rollout status deployment/web
kubectl rollout history deployment/web
kubectl get events --sort-by=.lastTimestamp

# 失敗時
kubectl describe pod <pod>
kubectl logs <pod> --previous
kubectl rollout undo deployment/web
```

---

## 6) よくあるミス & 安全運用

### よくあるミス
1. **別クラスタに apply**（context 見忘れ）
2. **default namespace へ誤配備**（`-n` 指定忘れ）
3. **一気に delete/apply** して影響範囲を見誤る
4. Secret を Git に平文コミット

### 安全運用
- `kubectl config current-context` を実行してから apply/delete
- `kubectl diff` と `--dry-run=server` を習慣化
- 本番作業時は `-f` の対象ディレクトリ範囲を最小化
- Secret は専用管理（KMS/External Secrets 等）
- 破壊的コマンド（`delete`, `replace --force`, `scale 0`）前に**必ず警告確認**

---

## 7) 面接っぽい一問

**Q.** `kubectl apply` と `kubectl replace` の違いは？本番運用でどちらを優先すべき？

**A.（要点）**
- `apply`: 宣言的・差分反映・継続運用向き
- `replace`: オブジェクト全置換、運用を誤ると意図せぬ欠落が起きやすい
- 本番は通常 `apply` を優先し、`replace` は意図が明確な限定ケースで使う

---

## 8) 次のステップ（公式中心）

- Kubernetes Concepts（公式）  
  https://kubernetes.io/docs/concepts/
- Deployments（公式）  
  https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- kubectl Overview（公式）  
  https://kubernetes.io/docs/reference/kubectl/
- Declarative Config Management（公式）  
  https://kubernetes.io/docs/tasks/manage-kubernetes-objects/declarative-config/
- Configure Access to Multiple Clusters（公式）  
  https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/
- Good practices for Kubernetes Secrets（公式）  
  https://kubernetes.io/docs/concepts/security/secrets-good-practices/

---

## 次号予告（Middle）
**前提知識（Prerequisites）**
- Deployment / Service / Namespace の基本
- `kubectl apply`, `diff`, `rollout status/undo` が使える

**予定テーマ**
- ConfigMap/Secret の安全な注入
- Probe（liveness/readiness/startup）
- requests/limits と HPA 基礎
