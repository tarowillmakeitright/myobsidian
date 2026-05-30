---
tags: [kubernetes, k8s, devops, learning, daily]
---

# 2026-05-30 Kubernetes Commands Magazine
[[Home]]

## 今号のテーマ
**「kubectl apply と Rollout の安全運用」**

---

## 1) Topic + Level
### Beginner（初級）
**Topic:** `kubectl get / describe / logs` で稼働状況を把握する

### Middle（中級）
**Topic:** `kubectl apply` と `kubectl rollout` で安全にデプロイ更新する
**Prerequisites:**
- Pod / Deployment / Service の基本概念
- `kubectl get` と `kubectl describe` の利用経験
- YAML マニフェストの基本構文

### Advanced（上級）
**Topic:** ロールアウトの失敗検知・切り戻し・差分確認の運用設計
**Prerequisites:**
- Deployment の更新戦略（RollingUpdate）の理解
- `kubectl rollout history/undo/status` の基本操作
- Namespace / Context の切替と確認習慣

---

## 2) Why it matters for real app development
実アプリ開発では「デプロイそのもの」よりも、**安全に変更を反映し、問題時に素早く戻せること**が価値です。

- 小さな修正でも本番障害の引き金になりうる
- `kubectl apply` の誤用（対象Namespace違い、Context違い）で意図しない変更が発生しやすい
- `rollout status` と `undo` を習慣化すると、MTTR（復旧時間）を短縮できる

---

## 3) Core kubectl/Kubernetes concept explanations
- **Declarative（宣言的）運用:**
  `kubectl apply -f` は「こうなっていてほしい状態」を宣言し、Kubernetesが収束させる。
- **Deployment:**
  ReplicaSet を使って Pod の更新を段階的に進めるコントローラ。
- **Rollout:**
  Deployment更新の進行。`status` で監視、`history` で履歴確認、`undo` で切り戻し。
- **Namespace / Context:**
  どのクラスタ・どのNamespaceに操作しているかを常に明示確認。

---

## 4) How Kubernetes is used while building apps（kubernetes.io/docs ベストプラクティス準拠）
アプリ開発フローでは次の流れが実践的です。

1. **ローカルでコンテナ化**（Docker/BuildKit等）
2. **マニフェストをGit管理**（Infrastructure as Code）
3. **`kubectl diff` → `kubectl apply` の順で反映**
4. **`kubectl rollout status` で健全性確認**
5. 問題時は **`kubectl rollout undo`** で迅速に戻す

ベストプラクティス:
- Secret値をマニフェストに直書きしない
- 本番前に `--dry-run=client` や `kubectl diff` で差分確認
- ラベル設計を統一し、`kubectl get` の絞り込みを容易にする

---

## 5) 30-60 minute hands-on mini lab
**目標:** 安全に Deployment 更新し、失敗を検知して切り戻す

### 所要時間
45分

### 手順
1. **作業Namespace作成（5分）**
```bash
kubectl create namespace mag-lab
kubectl config set-context --current --namespace=mag-lab
kubectl config current-context
kubectl get ns
```

2. **初期デプロイ（10分）**
`deploy-v1.yaml` を作成（nginx:1.25 など）し適用。
```bash
kubectl apply -f deploy-v1.yaml
kubectl get deploy,pod -o wide
kubectl rollout status deploy/web
```

3. **安全確認付きで更新（10分）**
イメージを `nginx:1.26` に変更。
```bash
kubectl diff -f deploy-v2.yaml
kubectl apply -f deploy-v2.yaml
kubectl rollout status deploy/web
kubectl rollout history deploy/web
```

4. **意図的に失敗更新（10分）**
存在しないイメージタグへ変更（例: `nginx:notfound`）。
```bash
kubectl apply -f deploy-bad.yaml
kubectl rollout status deploy/web --timeout=60s
kubectl describe deploy/web
kubectl get events --sort-by=.metadata.creationTimestamp | tail -n 20
```

5. **切り戻し（10分）**
```bash
kubectl rollout undo deploy/web
kubectl rollout status deploy/web
kubectl get pod
```

### 検証ポイント
- `rollout status` が失敗を検知できたか
- `undo` 後に Pod が正常化したか
- どの時点で異常を早期発見できたか

---

## 6) Command cheatsheet
```bash
# 文脈確認（超重要）
kubectl config current-context
kubectl config view --minify --output 'jsonpath={..namespace}'

# 参照
kubectl get deploy,pod,svc
kubectl describe deploy <name>
kubectl logs deploy/<name> --tail=100

# 反映
kubectl diff -f <file.yaml>
kubectl apply -f <file.yaml>

# ロールアウト
kubectl rollout status deploy/<name>
kubectl rollout history deploy/<name>
kubectl rollout undo deploy/<name>

# 安全確認
kubectl apply --dry-run=client -f <file.yaml>
```

---

## 7) Common mistakes and safe practices
### よくあるミス
- **Context/Namespace確認せず apply** して別環境を更新
- `kubectl delete` を広いスコープで実行（例: `-A` や曖昧なラベル）
- Secret を平文でGitコミット
- `latest` タグ運用で再現性喪失

### 安全プラクティス
- 破壊的コマンド前に必ず確認:
  - `kubectl config current-context`
  - `kubectl get ns`
  - 対象リソースを `kubectl get ... -n ...` で先に目視
- `kubectl delete` 実行前に、まず `kubectl get` で対象件数を把握
- `apply` 前に `diff` と `--dry-run=client`
- Secret は External Secrets / Sealed Secrets / Secret Manager 連携を検討

> ⚠️ 注意: `kubectl delete`, `kubectl apply -f <dir>` は影響範囲が広くなりやすい。必ず対象クラスタ・対象Namespace・対象ファイルを再確認してから実行すること。

---

## 8) One interview-style question
**Q.** `kubectl apply` でDeployment更新後に一部Podが起動しない場合、あなたならどの順序で調査し、どの条件で `rollout undo` を判断しますか？

（観点例: rollout status, describe, events, logs, readiness/liveness probes, timeout基準）

---

## 9) Next-step resources（公式優先）
- Kubernetes Documentation（ホーム）
  https://kubernetes.io/docs/home/
- Overview of kubectl
  https://kubernetes.io/docs/reference/kubectl/
- Deployments
  https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- kubectl rollout
  https://kubernetes.io/docs/reference/kubectl/generated/kubectl_rollout/
- Configure Access to Multiple Clusters
  https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/
- Secrets Good Practices
  https://kubernetes.io/docs/concepts/security/secrets-good-practices/

---

次号予告（学習アーク継続）:
**Beginner → Middle → Advanced:** 「ConfigMap/Secret と環境差分管理（安全な設定注入編）」