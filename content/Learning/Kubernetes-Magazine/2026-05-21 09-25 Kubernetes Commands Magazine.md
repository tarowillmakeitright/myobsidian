# Daily Kubernetes Commands Magazine

- 日付: 2026-05-21 09:25 (Asia/Tokyo)
- タグ: #kubernetes #k8s #devops #learning #daily
- リンク: [[Home]]

---

## 今日の学習アーク（Beginner → Middle → Advanced）

> 今日のテーマは「`kubectl apply` / `kubectl diff` / ロールアウト確認を安全に回す実践フロー」です。  
> 実開発で最も事故が起きやすい「適用対象・Context間違い」を避ける運用を段階的に学びます。

---

## 1) Topic + Level

### Beginner
**Topic:** `kubectl` の基本確認と「どのクラスタに向けて実行しているか」を可視化する

### Middle（前提条件あり）
**Topic:** `kubectl apply -f` と `kubectl diff -f` で変更を安全に適用する

**Prerequisites:**
- `kubectl get` / `describe` / `logs` を使ったことがある
- Namespace の概念を理解している
- Deployment と Pod の関係をざっくり説明できる

### Advanced（前提条件あり）
**Topic:** ロールアウト戦略とトラブル時の切り戻し（`rollout` + `history` + `undo`）

**Prerequisites:**
- `kubectl apply` で Deployment を更新した経験がある
- Readiness Probe / Liveness Probe の目的を理解している
- 複数環境（dev/stg/prod）の Context 切り替えを運用している

---

## 2) なぜ実アプリ開発で重要か

- Kubernetes 運用事故の典型は「**誤Contextへ apply**」「**誤Namespaceへ apply**」「**削除系コマンドの誤爆**」。
- アプリ開発の速度を上げるには、変更を速く出すだけでなく、**安全に戻せること**が必須。
- `diff → apply → rollout確認` の流れは、CI/CD でもローカル検証でも再現性が高く、チーム開発の標準化に直結します。

---

## 3) コア kubectl / Kubernetes 概念

- **Context**: どのクラスタ・ユーザー・Namespace に向くかの設定。
  - 確認: `kubectl config current-context`
  - 一覧: `kubectl config get-contexts`
- **Namespace**: リソースの論理分離。事故防止に重要。
- **Declarative apply**: 望ましい状態を YAML で宣言して反映。
- **diff**: 実適用前に差分確認。`apply` 事故の抑止に非常に有効。
- **rollout**: Deployment 更新の進行確認・履歴確認・切り戻し。

---

## 4) アプリ開発時の実践（kubernetes.io/docs ベストプラクティス寄せ）

- マニフェストは Git 管理し、変更はレビュー可能にする（宣言的運用）。
- `kubectl apply` 前に必ず `kubectl diff` を実行。
- 本番想定 Namespace を明示（`-n`）し、デフォルト Namespace依存を避ける。
- Secret は平文で直書きしない。`Secret` リソース利用 + 適切なアクセス制御。
- 変更後は `kubectl rollout status` と `kubectl get events` で正常性を確認。
- 大きな削除や一括操作前には対象を列挙して二重確認。

---

## 5) 30–60分ミニラボ

**目的:** 安全な更新フロー（確認→差分→適用→監視→ロールバック）を体験する

### 事前準備（5分）
1. Context確認
```bash
kubectl config current-context
kubectl config get-contexts
```
2. 作業用Namespace作成
```bash
kubectl create namespace k8s-mag-lab
```

### ステップA: 初期デプロイ（10分）
`deploy-v1.yaml` を作成（nginx 1.25系など）し適用:
```bash
kubectl apply -n k8s-mag-lab -f deploy-v1.yaml
kubectl get deploy,pod -n k8s-mag-lab
kubectl rollout status deployment/web -n k8s-mag-lab
```

### ステップB: 安全な更新（15分）
イメージタグを更新した `deploy-v2.yaml` を準備し、まず差分確認:
```bash
kubectl diff -n k8s-mag-lab -f deploy-v2.yaml
kubectl apply -n k8s-mag-lab -f deploy-v2.yaml
kubectl rollout status deployment/web -n k8s-mag-lab
```

### ステップC: 障害想定と切り戻し（15分）
意図的に不正タグへ更新して失敗を観察:
```bash
kubectl set image deployment/web web=nginx:does-not-exist -n k8s-mag-lab
kubectl rollout status deployment/web -n k8s-mag-lab
kubectl rollout history deployment/web -n k8s-mag-lab
kubectl rollout undo deployment/web -n k8s-mag-lab
kubectl rollout status deployment/web -n k8s-mag-lab
```

### ステップD: 後片付け（5分）
⚠️ **破壊的コマンド**。Context/Namespaceを再確認してから実行:
```bash
kubectl config current-context
kubectl delete namespace k8s-mag-lab
```

---

## 6) Command Cheatsheet

```bash
# Context / Namespace
kubectl config current-context
kubectl config get-contexts
kubectl get ns

# 反映前チェック
kubectl diff -n <ns> -f <file.yaml>
kubectl apply --server-side -n <ns> -f <file.yaml>

# 状態確認
kubectl get deploy,pod -n <ns>
kubectl describe deploy <name> -n <ns>
kubectl get events -n <ns> --sort-by=.metadata.creationTimestamp

# ロールアウト
kubectl rollout status deployment/<name> -n <ns>
kubectl rollout history deployment/<name> -n <ns>
kubectl rollout undo deployment/<name> -n <ns>
```

---

## 7) よくあるミス & 安全策

### よくあるミス
- `kubectl apply -f .` を誤ディレクトリで実行
- `default` Namespaceに意図せずデプロイ
- 本番Contextのまま検証コマンド実行
- Secret を ConfigMap や平文 YAML に置く
- `kubectl delete` をラベル指定ミスで広範囲に実行

### 安全策
- 実行前チェックを習慣化:
  - `kubectl config current-context`
  - `kubectl get ns`
  - `kubectl diff ...`
- 破壊的操作の前に対象を先に `get` で列挙
- `-n <namespace>` を毎回明示
- Secret は専用リソースで管理し、Git直コミットを避ける
- 本番では特に「小さく変更→観測→次へ」の段階適用

---

## 8) Interview-style Question

**Q.** `kubectl apply` の前に `kubectl diff` を入れると、チーム開発でどんな事故を減らせますか？また、CI に組み込むならどのタイミングが有効ですか？

---

## 9) Next-step Resources（公式優先）

- Kubernetes Concepts: Overview  
  https://kubernetes.io/docs/concepts/overview/
- kubectl Cheat Sheet  
  https://kubernetes.io/docs/reference/kubectl/cheatsheet/
- Declarative Configuration  
  https://kubernetes.io/docs/tasks/manage-kubernetes-objects/declarative-config/
- Deployments  
  https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Secrets  
  https://kubernetes.io/docs/concepts/configuration/secret/
- Configure Access to Multiple Clusters  
  https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/

---

### 今日の一言
速さは大事。でも Kubernetes では「**安全に速く**」が本当の実力。  
`current-context → diff → apply → rollout` を手癖にすると、事故率が目に見えて下がります。
