---
tags: [kubernetes, k8s, devops, learning, daily]
---

# 2026-03-18 09:25 Kubernetes Commands Magazine
[[Home]]

#kubernetes #k8s #devops #learning #daily

本日のテーマは、**実アプリ運用で最も頻出する「Deployment の安全な更新とトラブルシュート」**です。  
学習アークは **Beginner → Middle → Advanced** の順で進みます。

---

## Learning Arc 1 — Deployment を安全に更新する

## 1) Topic + Level
- **Beginner:** Deployment と Pod の基本観察（`get/describe/logs`）
- **Middle:** ローリングアップデートとロールバック（`set image/rollout`）
- **Advanced:** リリース安全性の強化（readiness/liveness、`kubectl diff`、`--dry-run=server`）

**Prerequisites**
- **Middle 前提:** Pod / Deployment / Service の基本概念、`kubectl get` が使える
- **Advanced 前提:** Middle の内容 + readinessProbe の意味、YAML マニフェスト編集経験

---

## 2) Why it matters for real app development
本番開発では「新バージョンを止めずに安全に出す」ことが重要です。Deployment を理解すると:
- ダウンタイムを抑えた更新ができる
- 不具合時に即ロールバックできる
- 変更前確認（diff/dry-run）で事故を減らせる

これは CI/CD パイプラインや日常運用の品質に直結します。

---

## 3) Core kubectl/Kubernetes concept explanations
- **Deployment**: 望ましい状態（例: レプリカ数、イメージ）を宣言し、ReplicaSet/Pod を管理
- **RollingUpdate**: Pod を少しずつ置き換え、可用性を維持
- **Readiness Probe**: 「この Pod にトラフィックを流してよいか」判定
- **Liveness Probe**: 「プロセスが生きているか」監視
- **`kubectl rollout`**: 更新状況確認・履歴確認・ロールバック
- **`kubectl diff`**: apply 前に差分確認（事故防止）
- **`--dry-run=server`**: API サーバ検証のみ実行し、実リソースは変更しない

---

## 4) How Kubernetes is used while building apps（kubernetes.io/docs 準拠）
アプリ開発での一般フロー:
1. 開発者がアプリコンテナをビルド
2. Deployment マニフェストで desired state を宣言
3. readiness/liveness を設定し、安全な配信条件を作る
4. `kubectl apply` 前に `kubectl diff` と `--dry-run=server` で確認
5. `kubectl rollout status` で更新監視
6. 問題時は `kubectl rollout undo` で迅速復旧

これは公式ドキュメントの宣言的管理・プローブ・安全なロールアウト運用と整合します。

---

## 5) 30–60分ハンズオン mini lab

### 目標
- Deployment の更新、監視、ロールバックを安全に体験

### 想定環境
- ローカルクラスタ（minikube/kind など）
- Namespace: `magazine-lab`

### 手順（約45分）

#### Step A（Beginner: 10-15分）観察
```bash
kubectl create namespace magazine-lab
kubectl -n magazine-lab create deployment web --image=nginx:1.25
kubectl -n magazine-lab expose deployment web --port=80 --type=ClusterIP

kubectl -n magazine-lab get deploy,rs,pods,svc
kubectl -n magazine-lab describe deployment web
kubectl -n magazine-lab logs deploy/web
```

#### Step B（Middle: 15-20分）更新とロールバック
```bash
# 変更前に何を触るか確認
kubectl -n magazine-lab set image deployment/web nginx=nginx:1.26 --record
kubectl -n magazine-lab rollout status deployment/web
kubectl -n magazine-lab rollout history deployment/web

# 意図的に存在しないタグへ（失敗を観察）
kubectl -n magazine-lab set image deployment/web nginx=nginx:DOES-NOT-EXIST
kubectl -n magazine-lab rollout status deployment/web --timeout=60s || true
kubectl -n magazine-lab get pods

# ロールバック
kubectl -n magazine-lab rollout undo deployment/web
kubectl -n magazine-lab rollout status deployment/web
```

#### Step C（Advanced: 15-20分）安全性チェック
`deployment-safe.yaml` を作成（readiness/liveness を追加）してから:
```bash
kubectl -n magazine-lab diff -f deployment-safe.yaml
kubectl -n magazine-lab apply --dry-run=server -f deployment-safe.yaml
kubectl -n magazine-lab apply -f deployment-safe.yaml
kubectl -n magazine-lab rollout status deployment/web
```

#### 後片付け（必要なら）
```bash
# 破壊的操作: 実行前に context/namespace を必ず確認
kubectl config current-context
kubectl get ns
kubectl delete ns magazine-lab
```

---

## 6) Command cheatsheet
```bash
# 現在の操作先確認（超重要）
kubectl config current-context
kubectl config get-contexts

# 基本観察
kubectl get pods -A
kubectl -n <ns> get deploy,rs,pods,svc
kubectl -n <ns> describe deploy <name>
kubectl -n <ns> logs deploy/<name>

# 更新
kubectl -n <ns> set image deploy/<name> <container>=<image:tag>
kubectl -n <ns> rollout status deploy/<name>
kubectl -n <ns> rollout history deploy/<name>
kubectl -n <ns> rollout undo deploy/<name>

# 安全確認
kubectl -n <ns> diff -f <file.yaml>
kubectl -n <ns> apply --dry-run=server -f <file.yaml>
kubectl -n <ns> apply -f <file.yaml>
```

---

## 7) Common mistakes and safe practices

### よくあるミス
1. **context 誤り**: 本番クラスタに対して作業してしまう
2. **namespace 誤り**: 意図しない namespace に apply/delete
3. **広すぎる apply/delete**: ディレクトリ全体や `-A` を安易に使う
4. **Secret を平文で Git 管理**: 認証情報漏えい
5. **Probe 未設定**: 壊れた Pod にトラフィックが流れる

### 安全プラクティス
- 作業前に `kubectl config current-context` と `-n <ns>` を固定
- `apply` 前に `kubectl diff` と `--dry-run=server`
- 破壊的コマンド（`delete`, `replace --force`）は対象を具体指定
- Secret は平文埋め込み回避（External Secrets / Secret 管理基盤を検討）
- 最小権限（RBAC）で運用

> ⚠️ 警告: `kubectl delete` / 広域 `kubectl apply -f .` 実行前は、必ず **context・namespace・対象リソース** を再確認してください。

---

## 8) Interview-style question
**質問:**  
「Deployment 更新時に readinessProbe を設定しないと、どんな障害が起きる可能性がありますか？ また、`rollout undo` はどのタイミングで使うべきですか？」

**回答の観点（自己チェック）:**
- 未準備 Pod へのルーティングによる 5xx 増加
- ロールアウト中のヘルス監視の重要性
- エラー率・レイテンシ悪化時の早期ロールバック判断

---

## 9) Next-step resources（公式中心）
- Kubernetes Concepts: Workloads / Deployments  
  https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Perform a Rolling Update on a Deployment  
  https://kubernetes.io/docs/tutorials/kubernetes-basics/update/update-intro/
- Probes (Liveness, Readiness, Startup)  
  https://kubernetes.io/docs/concepts/configuration/liveness-readiness-startup-probes/
- kubectl Cheat Sheet  
  https://kubernetes.io/docs/reference/kubectl/cheatsheet/
- Configure Access to Multiple Clusters (contexts)  
  https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/
- Secrets (good practices)  
  https://kubernetes.io/docs/concepts/configuration/secret/

---

明日の予告（次アーク候補）: **ConfigMap/Secret とアプリ設定管理（安全な注入・ローテーション）**