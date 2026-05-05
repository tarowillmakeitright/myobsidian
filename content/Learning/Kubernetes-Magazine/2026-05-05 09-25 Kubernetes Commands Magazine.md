---
tags: [kubernetes, k8s, devops, learning, daily]
---

# Daily Kubernetes Commands Magazine — 2026-05-05
[[Home]]

#kubernetes #k8s #devops #learning #daily

> 今日のテーマは「デプロイの基本 → 安全な更新運用 → 本番トラブル対応」
> 
> 難易度アーク: **Beginner → Middle → Advanced**

---

## 1) Topic + Level

### Beginner
**Topic:** Deployment と Pod の関係を理解し、`kubectl` で安全に確認する

### Middle
**Topic:** RollingUpdate の確認とロールバック手順
**Prerequisites:**
- Pod / Deployment / ReplicaSet の基本を理解している
- `kubectl get/describe/logs` を使える
- namespace と context の概念を知っている

### Advanced
**Topic:** 本番を意識した「変更前確認 + 段階的適用 + 失敗時復旧」オペレーション
**Prerequisites:**
- RollingUpdate / rollout history / rollback を説明できる
- readinessProbe / livenessProbe の役割を理解している
- 複数 namespace で作業した経験がある

---

## 2) Why it matters for real app development

アプリ開発では「コードを書く」だけでなく、**安全に出す・戻す・観測する**が必須です。Kubernetes では以下が開発速度と品質に直結します。

- デプロイ時のダウンタイム最小化（RollingUpdate）
- 障害時の切り戻しの速さ（rollout undo）
- 誤操作回避（context/namespace/scope 確認）
- チーム開発での再現性（宣言的マニフェスト + dry-run）

つまり、`kubectl` の正しい使い方は「運用者向け」ではなく、**アプリ開発者の生産性そのもの**です。

---

## 3) Core kubectl / Kubernetes concept explanations

- **Pod**: コンテナの最小実行単位。通常は直接運用せず、上位リソースで管理。
- **Deployment**: Pod の望ましい状態（レプリカ数、イメージ、更新方法）を宣言する。
- **ReplicaSet**: Deployment が裏で管理する Pod 集合。
- **Service**: Pod への安定した到達点（IP/DNS）を提供。
- **Namespace**: リソース論理分離。
- **Context**: どのクラスタ・認証情報を使うか。

よく使う `kubectl` の見方:
- `get`: 一覧（現在状態）
- `describe`: 詳細（イベント含む）
- `logs`: コンテナログ
- `apply`: 宣言状態を反映
- `rollout`: 更新状況/履歴/ロールバック

---

## 4) How Kubernetes is used while building apps (kubernetes.io/docs aligned)

実務フローは概ね以下です（公式ドキュメントの推奨に沿う形）:

1. **宣言的マニフェスト管理**（Deployment/Service を YAML で管理）
2. **小さく変更して apply**（一度に大きく変えない）
3. **rollout status で更新監視**
4. **readinessProbe でトラフィック投入を制御**
5. **失敗時は rollout undo** で迅速に復旧
6. **Secret は Secret リソースで扱う**（平文を manifest に直書きしない）

> Best practice: `kubectl apply --server-side` や `--dry-run=server` を使って、サーバ側バリデーションを通してから本適用すると事故が減る。

---

## 5) 30-60 minute hands-on mini lab

**目標:** Deployment の更新〜ロールバックを安全に体験する（約45分）

### Step 0: 事前安全確認（5分）

```bash
kubectl config current-context
kubectl get ns
```

作業 namespace を決める:

```bash
kubectl create ns k8s-mag-lab
kubectl config set-context --current --namespace=k8s-mag-lab
kubectl config view --minify | grep namespace:
```

### Step 1: 初回デプロイ（10分）

```bash
kubectl create deployment web --image=nginx:1.25
kubectl expose deployment web --port=80 --target-port=80 --type=ClusterIP
kubectl get deploy,rs,pod,svc -o wide
```

### Step 2: ローリングアップデート（10分）

```bash
kubectl set image deployment/web nginx=nginx:1.26
kubectl rollout status deployment/web
kubectl rollout history deployment/web
kubectl get rs
```

### Step 3: 意図的に失敗を作る（10分）

```bash
kubectl set image deployment/web nginx=nginx:does-not-exist
kubectl rollout status deployment/web --timeout=60s
kubectl describe deployment web
kubectl get pod
```

失敗を確認後、ロールバック:

```bash
kubectl rollout undo deployment/web
kubectl rollout status deployment/web
kubectl get pod
```

### Step 4: クリーンアップ（5分）

```bash
kubectl delete ns k8s-mag-lab
```

⚠️ **削除系コマンド注意:** namespace 削除はその中のリソースを一括削除します。実クラスタでは対象を必ず再確認。

---

## 6) Command cheatsheet

```bash
# 現在の作業先確認
kubectl config current-context
kubectl config view --minify

# リソース確認
kubectl get deploy,rs,pod,svc -n <ns>
kubectl describe deploy <name> -n <ns>
kubectl logs deploy/<name> -n <ns>

# 更新
kubectl set image deployment/<name> <container>=<image>:<tag> -n <ns>
kubectl rollout status deployment/<name> -n <ns>
kubectl rollout history deployment/<name> -n <ns>
kubectl rollout undo deployment/<name> -n <ns>

# 安全適用
kubectl apply -f <file>.yaml --dry-run=server
kubectl diff -f <file>.yaml
kubectl apply -f <file>.yaml
```

---

## 7) Common mistakes and safe practices

### よくあるミス
- context を確認せず本番クラスタに apply/delete
- `default` namespace のまま作業してリソース混在
- Secret を平文で Git 管理
- `kubectl apply -f .` で意図しないファイルまで適用
- rollout 監視せずに「成功したつもり」で終了

### 安全プラクティス
- **毎回最初に** `kubectl config current-context` と namespace を確認
- 破壊的操作前に対象を明示: `-n <ns>` を必ず付与
- apply 前に `--dry-run=server` と `kubectl diff`
- Secret は Kubernetes Secret + 外部 secret 管理（必要に応じ Sealed Secrets / External Secrets 等）
- 小さな変更単位 + すぐ rollback できる状態を維持

⚠️ **特に注意:**
- `kubectl delete` は対象スコープを誤ると広範囲に影響
- `kubectl apply -f .` はディレクトリ内の想定外マニフェストも適用しうる

---

## 8) Interview-style question

**Q.** Deployment の RollingUpdate 中に新バージョン Pod が Ready にならず更新が止まりました。あなたなら `kubectl` でどの順番で調査・復旧しますか？

（期待される観点: rollout status / describe / events / logs / readinessProbe 設定確認 / rollback 判断）

---

## 9) Next-step resources (official first)

- Kubernetes Concepts Overview  
  https://kubernetes.io/docs/concepts/overview/
- Workloads: Deployments  
  https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- kubectl Cheat Sheet  
  https://kubernetes.io/docs/reference/kubectl/cheatsheet/
- Configure Liveness, Readiness and Startup Probes  
  https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/
- Secrets  
  https://kubernetes.io/docs/concepts/configuration/secret/
- kubectl apply (declarative management)  
  https://kubernetes.io/docs/tasks/manage-kubernetes-objects/declarative-config/

---

### 今日のひとこと
「速く作る」だけでなく、**安全に戻せる状態で出す**のが Kubernetes 時代の開発力。