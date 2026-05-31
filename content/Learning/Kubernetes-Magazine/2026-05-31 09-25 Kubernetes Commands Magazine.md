---
tags: [kubernetes, k8s, devops, learning, daily]
---

# 2026-05-31 09:25 Kubernetes Commands Magazine
[[Home]]

## 今号のテーマ
**Kubernetesで安全にアプリを公開する基本動線（Beginner）**

---

## 1) Topic + Level
**Topic:** `kubectl` で Deployment / Service / Namespace を安全に扱う
**Level:** **Beginner（学習アーク 1/3）**

> 次回アーク予告:
> - Middle: RollingUpdate と probes、ConfigMap/Secret運用
> - Advanced: HPA、PDB、NetworkPolicy、運用時のデバッグ戦略

---

## 2) なぜ実アプリ開発で重要か
ローカルで動くアプリを「チームで再現可能な形」で本番に近い環境へ載せるとき、Kubernetesの基本操作は必須です。

特に以下が重要です:
- **再現性**: マニフェストで状態を宣言し、誰が実行しても同じ構成を作れる
- **可観測性**: `kubectl get/describe/logs` で状態確認・原因調査ができる
- **安全性**: Namespace分離や適切な適用範囲で事故（他環境への誤適用）を減らせる

---

## 3) コア概念（kubectl / Kubernetes）

### Namespace
- クラスタ内の論理的な区画
- 開発・検証用途を分ける第一歩
- 例: `dev`, `staging`, `prod`

### Deployment
- Podの望ましい状態（レプリカ数・イメージ）を宣言
- Kubernetesがその状態へ自動で近づける

### Service (ClusterIP)
- Pod集合への安定したアクセス窓口
- Pod IPが変わってもサービス名で到達できる

### `kubectl apply`
- 宣言したマニフェストを適用（差分反映）
- インフラをコードとして扱う基本コマンド

### `kubectl get / describe / logs`
- `get`: 一覧と状態確認
- `describe`: 詳細イベント（失敗理由）
- `logs`: アプリログ

---

## 4) アプリ開発での使い方（kubernetes.io/docs ベストプラクティス寄せ）

- **Namespaceを先に作る**: 誤爆防止
- **ラベルを揃える**: `app`, `component`, `env` などで追跡性向上
- **apply前に対象確認**: `kubectl config current-context` と `-n` 指定
- **SecretをGitに平文保存しない**: 値の直書き回避（Sealed Secrets / External Secrets 等を将来導入）
- **小さく反復**: 一度に大量変更せず、確認しながら進める

参考（公式）:
- Overview: https://kubernetes.io/docs/concepts/overview/
- Objects: https://kubernetes.io/docs/concepts/overview/working-with-objects/
- Namespaces: https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/
- Deployments: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Services: https://kubernetes.io/docs/concepts/services-networking/service/

---

## 5) 30〜60分ミニラボ（安全版）

**目標:** `k8s-learning` Namespaceにnginxをデプロイし、Service経由で到達確認する

### 前提
- `kubectl` が使える
- ローカルクラスタ（minikube / kind / k3d等）または検証クラスタ
- 破壊的操作を避けるため、**専用Namespaceのみ使用**

### 手順

1. コンテキスト確認（最重要）
```bash
kubectl config current-context
kubectl config get-contexts
```

2. Namespace作成
```bash
kubectl create namespace k8s-learning
```

3. Deployment作成
```bash
kubectl -n k8s-learning create deployment web --image=nginx:1.27
```

4. Service公開（ClusterIP）
```bash
kubectl -n k8s-learning expose deployment web --port=80 --target-port=80 --name=web-svc
```

5. 状態確認
```bash
kubectl -n k8s-learning get deploy,po,svc
kubectl -n k8s-learning describe deployment web
```

6. ローカル確認（port-forward）
```bash
kubectl -n k8s-learning port-forward svc/web-svc 8080:80
```
別ターミナルで:
```bash
curl -I http://127.0.0.1:8080
```

7. ログ確認
```bash
kubectl -n k8s-learning logs deploy/web
```

8. 後片付け（任意）
```bash
kubectl delete namespace k8s-learning
```

> ⚠️ 警告: `kubectl delete namespace ...` は配下リソースを全削除します。`-n` や対象名の確認を必ず行ってください。

---

## 6) Command Cheatsheet

```bash
# 現在の対象クラスタ
kubectl config current-context

# Namespace一覧
kubectl get ns

# 特定Namespaceの主要リソース確認
kubectl -n <ns> get deploy,po,svc

# 詳細調査
kubectl -n <ns> describe pod <pod-name>
kubectl -n <ns> logs <pod-name>

# マニフェスト適用
kubectl -n <ns> apply -f app.yaml

# 差分確認（可能なら先に実施）
kubectl -n <ns> diff -f app.yaml

# 注意して削除
kubectl -n <ns> delete -f app.yaml
```

---

## 7) よくあるミス & 安全プラクティス

### よくあるミス
- `default` Namespaceにそのまま作成して混線
- 別コンテキスト（本番）に気づかず `apply/delete`
- Secretをマニフェストに平文記載
- `:latest` タグ運用で再現不能

### 安全プラクティス
- 実行前ルーチン: `current-context` → `-n` 指定 → 対象名確認
- `kubectl diff` で変更差分を事前確認
- Secretは外部管理を検討し、少なくともGit平文保存を避ける
- イメージタグは固定（例: `nginx:1.27.0`）
- 破壊系コマンド前に「何が消えるか」を口に出して確認

---

## 8) 面接っぽい一問
**Q.** DeploymentとReplicaSetの関係を説明し、なぜ通常はDeploymentを操作するのか？

**考えるポイント:**
- 宣言的更新（RollingUpdate/rollback）
- ReplicaSetの世代管理
- 運用時の責務分離

---

## 9) 次の一歩（公式リソース中心）
- kubectl overview: https://kubernetes.io/docs/reference/kubectl/
- Deployment updates: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#strategy
- Probes: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/
- ConfigMap: https://kubernetes.io/docs/concepts/configuration/configmap/
- Secret (good practices): https://kubernetes.io/docs/concepts/security/secrets-good-practices/

---

## 次号（Middle）に向けた前提知識
- Namespace / Deployment / Service を `kubectl` で作成・確認できる
- `get/describe/logs` でトラブル時の一次切り分けができる
- `apply` 前に context と namespace を確認する習慣がある

（ここまでできれば、次回はRollingUpdateとprobesへ進めます）
