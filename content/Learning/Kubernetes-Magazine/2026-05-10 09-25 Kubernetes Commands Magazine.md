---
tags: [kubernetes, k8s, devops, learning, daily]
---

# Daily Kubernetes Commands Magazine — 2026-05-10
[[Home]]

## 今号テーマ
**「kubectl apply / rollout / logs を使った安全なデプロイ運用」**

---

## 1) Topic + Level

### 🟢 Beginner
**Topic:** `kubectl get / describe / logs` でアプリ状態を読む

### 🟡 Middle（前提あり）
**Topic:** `kubectl apply` と `rollout` で段階的に更新する
**Prerequisites:**
- Pod / Deployment / Service の基本概念
- YAML マニフェストを読める
- `kubectl config current-context` の意味を理解している

### 🔴 Advanced（前提あり）
**Topic:** `readinessProbe` と `rollingUpdate` を組み合わせた無停止更新
**Prerequisites:**
- Deployment の更新戦略（RollingUpdate）を理解
- `kubectl rollout history/undo` を使ったロールバック経験
- アプリのヘルスチェックエンドポイント（例: `/healthz`）を用意できる

---

## 2) なぜ実アプリ開発で重要か

本番障害の多くは「コードそのもの」より、**デプロイ手順ミス**や**状態確認不足**で起きます。  
Kubernetes では、
- 正しい context/namespace の確認
- 差分を意識した適用
- rollout 監視
- 異常時の即時ロールバック

ができると、リリース事故を大幅に減らせます。CI/CD の中身を理解するうえでも必須です。

---

## 3) Core kubectl / Kubernetes Concepts

- **Pod**: コンテナ実行の最小単位
- **Deployment**: Pod の望ましい状態を宣言し、更新・復旧を管理
- **Service**: Pod 群への安定したアクセス経路
- **Namespace**: リソース分離単位
- **Context**: どのクラスタに操作するか（誤操作防止の最重要ポイント）

よく使う基本コマンド:
- `kubectl get <resource>`: 一覧
- `kubectl describe <resource> <name>`: 詳細イベント含む調査
- `kubectl logs`: コンテナログ確認
- `kubectl apply -f`: 宣言的に適用
- `kubectl rollout status/history/undo`: 更新監視と復旧

---

## 4) アプリ開発中での Kubernetes 活用（kubernetes.io/docs ベストプラクティス準拠）

実務フロー例:
1. マニフェストを Git 管理（宣言的運用）
2. 適用前に **context/namespace を毎回確認**
3. `kubectl apply` で反映
4. `kubectl rollout status` で完了待ち
5. `kubectl logs` / `describe` で検証
6. 問題時は `kubectl rollout undo`

ベストプラクティス:
- Secret 値をマニフェストに平文で直書きしない
- readinessProbe を設定して、準備完了前にトラフィックを流さない
- `latest` タグ固定を避け、追跡可能なタグを使う
- `kubectl delete` は対象を明示し、広範囲指定を避ける

---

## 5) 30〜60分ミニラボ

### ゴール
Nginx Deployment を作成し、ローリングアップデート→状態確認→ロールバックまで体験する。

### 手順

#### Step 0: 安全確認（5分）
```bash
kubectl config current-context
kubectl get ns
```
> ⚠️ 本番クラスタでないことを必ず確認。

#### Step 1: Deployment 作成（10分）
`k8s/deploy.yaml`
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
  namespace: default
spec:
  replicas: 2
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 0
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
        image: nginx:1.25.5
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
kubectl apply -f k8s/deploy.yaml
kubectl rollout status deployment/web
kubectl get pods -l app=web -o wide
```

#### Step 2: 更新（10分）
`image: nginx:1.25.5` を `nginx:1.25.4` に変更して再適用。
```bash
kubectl apply -f k8s/deploy.yaml
kubectl rollout status deployment/web
kubectl rollout history deployment/web
```

#### Step 3: 失敗を想定した復旧（10分）
（任意）存在しないタグにして失敗挙動を観察後、ロールバック。
```bash
kubectl rollout undo deployment/web
kubectl rollout status deployment/web
```

#### Step 4: 調査（5〜10分）
```bash
kubectl describe deployment web
kubectl get events --sort-by=.metadata.creationTimestamp | tail -n 20
kubectl logs deploy/web --tail=50
```

#### Step 5: 後片付け（5分）
```bash
kubectl delete deployment web
```
> ⚠️ `kubectl delete -f .` のような広範囲削除は避ける。

---

## 6) Command Cheatsheet

```bash
# 現在の接続先確認
kubectl config current-context

# リソース確認
kubectl get deploy,pods,svc -n default

# 詳細調査
kubectl describe pod <pod-name> -n default
kubectl logs <pod-name> -n default --tail=100

# 適用と監視
kubectl apply -f k8s/deploy.yaml
kubectl rollout status deployment/web -n default
kubectl rollout history deployment/web -n default

# ロールバック
kubectl rollout undo deployment/web -n default
```

---

## 7) よくあるミス & 安全運用

### よくあるミス
- context を確認せず本番へ apply/delete
- namespace 指定漏れで意図しない場所に作成
- Secret を Git 管理に平文コミット
- rollout 完了前に「デプロイ成功」と判断

### 安全運用
- 実行前に毎回: `kubectl config current-context`
- 可能なら `-n <namespace>` を常に明示
- Secret は Kubernetes Secret + 外部 Secret 管理を併用
- 破壊的操作前に対象を `kubectl get` で再確認
- `delete` は単体リソース指定を原則にする

---

## 8) 面接っぽい一問

**Q.** `readinessProbe` と `livenessProbe` の違いを説明し、デプロイの安全性にどう影響するか述べてください。  
**A（要点）:**
- readinessProbe: トラフィックを受けて良いか判定（未準備PodをServiceから外す）
- livenessProbe: ハングしたコンテナを再起動する判定
- readiness がないと更新時に未準備Podへ流入し、エラー率が上がりやすい

---

## 9) Next-step Resources（公式優先）

- Kubernetes Concepts Overview  
  https://kubernetes.io/docs/concepts/overview/
- Deployments  
  https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- kubectl Cheat Sheet  
  https://kubernetes.io/docs/reference/kubectl/cheatsheet/
- Probes (Liveness/Readiness/Startup)  
  https://kubernetes.io/docs/concepts/configuration/liveness-readiness-startup-probes/
- Secret Good Practices  
  https://kubernetes.io/docs/concepts/security/secrets-good-practices/

---

次号予告: **ConfigMap/Secret と環境差分管理（Kustomize入門）**