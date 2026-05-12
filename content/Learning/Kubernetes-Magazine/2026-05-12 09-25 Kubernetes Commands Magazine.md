---
tags: [kubernetes, k8s, devops, learning, daily]
---
[[Home]]

# Kubernetes Commands Magazine — 2026-05-12

## 今日のテーマ
**安全に始める Kubernetes デプロイ運用: `kubectl apply/get/describe/logs` を軸にした学習アーク**

---

## 1) Topic + Level

### Beginner
**Topic:** Pod/Deployment の基本操作と観察 (`apply`, `get`, `describe`, `logs`)

### Middle（前提あり）
**Topic:** Namespace と Label/Selector を使った安全な運用境界の作り方
**Prerequisites:**
- Beginner内容を理解していること
- YAML の基礎（key/value, 配列）
- `kubectl get`, `kubectl apply -f` を使えること

### Advanced（前提あり）
**Topic:** Rollout とトラブルシュート（`rollout status/history/undo` + Probe設計）
**Prerequisites:**
- Middle内容を理解していること
- Deployment の更新と ReplicaSet の概念
- Readiness/Liveness Probe の基本知識

---

## 2) なぜ実アプリ開発で重要か

- **再現性**: 手動デプロイではなく宣言的管理で、環境差分を減らせる。
- **可観測性**: `describe`/`logs` で問題切り分けが速くなる。
- **安全な変更**: Rollout により「段階的反映→失敗時ロールバック」が可能。
- **チーム開発適性**: Namespace/Label を設計しておくと、複数アプリ・複数開発者でも混線しにくい。

---

## 3) Core kubectl/Kubernetes concepts

- **Pod**: コンテナ実行の最小単位。
- **Deployment**: Pod の望ましい状態（レプリカ数・更新戦略）を管理。
- **Namespace**: 論理的な分離境界（環境・チーム単位）。
- **Label / Selector**: オブジェクトの分類と関連付け（Service → Pod など）。
- **宣言的運用 (`kubectl apply`)**: 望ましい状態を YAML で定義して反映。
- **状態確認**:
  - `kubectl get` = 一覧/現況
  - `kubectl describe` = 詳細イベント・失敗理由
  - `kubectl logs` = アプリログ確認

---

## 4) 実アプリ構築での使い方（kubernetes.io/docs ベストプラクティス準拠）

- **命名・ラベル規約を先に決める**（`app`, `component`, `part-of` など）。
- **Namespaceで環境分離**（`dev`, `stg`, `prod`）。
- **`kubectl apply -f <dir>` でマニフェストを管理**（Git と相性が良い）。
- **Secretの値をマニフェストに直書きしない**（平文漏えい防止）。
- **更新は Deployment 経由**、Pod 直操作を最小化。
- **変更前に対象コンテキスト確認**（`kubectl config current-context`）して誤爆防止。

参考（公式）:
- Overview: <https://kubernetes.io/docs/concepts/overview/>
- Deployments: <https://kubernetes.io/docs/concepts/workloads/controllers/deployment/>
- Labels/Selectors: <https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/>
- Namespaces: <https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/>
- kubectl conventions: <https://kubernetes.io/docs/reference/kubectl/conventions/>

---

## 5) 30–60分ミニラボ

### 目標
`dev` Namespace に Nginx Deployment を作成し、更新・確認・ロールバックまで体験する。

### 手順（安全版）

> ⚠️ **実行前チェック（重要）**
> - `kubectl config current-context` で対象クラスタ確認
> - 本番クラスタでは実施しない（学習用クラスタ推奨）

1. Namespace作成
```bash
kubectl create namespace dev
```

2. `nginx-deploy.yaml` を作成
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
  namespace: dev
  labels:
    app: web
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
          initialDelaySeconds: 5
          periodSeconds: 10
```

3. 反映と確認
```bash
kubectl apply -f nginx-deploy.yaml
kubectl get deploy,pods -n dev
kubectl describe deploy web -n dev
```

4. イメージ更新（擬似リリース）
```bash
kubectl set image deployment/web nginx=nginx:1.26 -n dev
kubectl rollout status deployment/web -n dev
kubectl rollout history deployment/web -n dev
```

5. ロールバック体験
```bash
kubectl rollout undo deployment/web -n dev
kubectl rollout status deployment/web -n dev
```

6. 後片付け（必要なら）
```bash
# ⚠️ 削除は対象Namespaceを再確認してから
kubectl delete namespace dev
```

---

## 6) Command Cheatsheet

```bash
# コンテキスト確認（誤操作防止）
kubectl config current-context

# 基本一覧
kubectl get ns
kubectl get pods -n dev
kubectl get deploy -n dev

# 反映
kubectl apply -f <file-or-dir>

# 詳細調査
kubectl describe pod <pod-name> -n dev
kubectl logs <pod-name> -n dev

# 更新・ロールアウト
kubectl set image deployment/web nginx=nginx:1.26 -n dev
kubectl rollout status deployment/web -n dev
kubectl rollout history deployment/web -n dev
kubectl rollout undo deployment/web -n dev
```

---

## 7) よくあるミス & Safe Practices

### よくあるミス
- `-n` を付け忘れて意図しない Namespace に適用。
- `kubectl apply -f .` を不用意に実行して想定外リソースまで反映。
- `delete` コマンドを current-context 未確認で実行。
- Secret を YAML に平文で記載して Git にコミット。

### Safe Practices
- 破壊的操作前に必ず:
  - `kubectl config current-context`
  - `kubectl get ns`
  - 対象名の再確認
- `apply` はファイル/ディレクトリを明示して最小スコープ実行。
- Secret は外部シークレット管理や暗号化手段を利用し、平文保存を避ける。
- 変更後は `rollout status` と `describe` をセットで確認。

---

## 8) Interview-style Question

**Q.** `kubectl apply` と `kubectl create` の違いを、運用観点（再適用・差分管理・CI/CD）で説明してください。さらに、なぜ本番運用で Deployment + rollout が推奨されるかを答えてください。

---

## 9) Next-step resources（公式優先）

- Kubernetes Concepts: <https://kubernetes.io/docs/concepts/>
- Workloads / Deployments: <https://kubernetes.io/docs/concepts/workloads/controllers/deployment/>
- kubectl Cheat Sheet: <https://kubernetes.io/docs/reference/kubectl/cheatsheet/>
- Configure Access to Multiple Clusters: <https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/>
- Secrets Good Practices: <https://kubernetes.io/docs/concepts/security/secrets-good-practices/>

---

次号予告（Advanced寄り）:
**「Service/Ingress と NetworkPolicy で作る、安全なアプリ公開パス」**
