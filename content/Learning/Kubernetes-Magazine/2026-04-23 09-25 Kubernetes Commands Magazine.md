# Kubernetes Commands Magazine — 2026-04-23 09:25

#kubernetes #k8s #devops #learning #daily
[[Home]]

---

## 今号のテーマ
**「`kubectl`で安全にデプロイを観察・更新する基本動線」**

学習アークは **Beginner → Middle → Advanced** の順で進みます。

---

## 1) Topic + Level

### Beginner
**Topic:** `kubectl get / describe / logs` でアプリ状態を読む

### Middle
**Topic:** `Deployment` のローリング更新と `kubectl rollout` 運用

**Prerequisites (Middle):**
- Pod / Deployment / Service の基本概念
- `kubectl get pods -n <namespace>` を読める
- コンテナイメージタグの意味（例: `1.0.0`, `1.0.1`）を理解

### Advanced
**Topic:** `apply` の安全運用（server-side apply / dry-run / 差分確認）

**Prerequisites (Advanced):**
- YAML マニフェストが読める
- ローリング更新とロールバックの流れを理解
- namespace/context の切り替えミスが事故につながることを理解

---

## 2) なぜ実アプリ開発で重要か

- 開発中の「動かない」を最短で切り分けるには、**状態観測 (`get/describe/logs`)** が必須。
- 本番リリースは「更新できる」だけでなく、**安全に戻せる（rollout undo）** ことが重要。
- チーム開発では「誰が何を適用したか」を明確化するため、**宣言的運用（apply + diff + dry-run）** が品質を支える。

---

## 3) コア概念（kubectl/Kubernetes）

- **Pod:** 最小実行単位。通常は直接運用せず、Deployment で管理。
- **Deployment:** Desired state（望ましい状態）を維持。更新時は ReplicaSet を切り替えてローリング。
- **Service:** Pod の入れ替わりに強い安定した到達点。
- **Namespace:** 論理分離。事故防止の第一歩。
- **Context:** どのクラスタに向けて `kubectl` を打つか。最重要安全ポイント。

よく使う観測コマンド:
- `kubectl get` : 一覧
- `kubectl describe` : 詳細イベント
- `kubectl logs` : コンテナログ
- `kubectl rollout status/history/undo` : 更新監視・履歴・巻き戻し

---

## 4) アプリ開発時にどう使うか（kubernetes.io/docs準拠の実務寄り）

実務の基本ループ:
1. マニフェストを Git 管理（宣言的）
2. `kubectl diff` で変更確認
3. `kubectl apply --server-side --dry-run=server -f ...` で事前検証
4. 問題なければ `kubectl apply -f ...`
5. `kubectl rollout status ...` と `kubectl logs ...` で健全性確認
6. 異常時は `kubectl rollout undo ...` で即復旧

Best practices（公式に沿った方向性）:
- namespace を分ける（dev/stg/prod）
- ラベルで追跡性を持たせる（`app`, `version`, `managed-by` など）
- Secret を YAML に直書きしない（平文コミット禁止）
- 破壊的コマンド前に context/namespace を二重確認

---

## 5) 30〜60分ミニラボ

### ゴール
Nginx Deployment を段階更新し、失敗を検知してロールバックする。

### 想定時間
45分

### 手順

#### 0. 安全確認（5分）
```bash
kubectl config current-context
kubectl get ns
```
- 期待しないクラスタなら **ここで中断**。

#### 1. 作業用 namespace 作成（5分）
```bash
kubectl create namespace k8s-mag-lab
kubectl config set-context --current --namespace=k8s-mag-lab
```

#### 2. 初期デプロイ（10分）
```bash
kubectl create deployment web --image=nginx:1.25
kubectl expose deployment web --port=80 --type=ClusterIP
kubectl get all
```

#### 3. 観測（10分）
```bash
kubectl describe deployment web
kubectl get pods -o wide
kubectl logs deploy/web --tail=50
```

#### 4. ローリング更新（10分）
```bash
kubectl set image deployment/web nginx=nginx:1.26
kubectl rollout status deployment/web
kubectl rollout history deployment/web
```

#### 5. 意図的に不正タグで失敗→復旧（10分）
```bash
kubectl set image deployment/web nginx=nginx:does-not-exist
kubectl rollout status deployment/web --timeout=60s
kubectl describe pod -l app=web
kubectl rollout undo deployment/web
kubectl rollout status deployment/web
```

#### 6. 後片付け（任意）
```bash
kubectl config set-context --current --namespace=default
kubectl delete namespace k8s-mag-lab
```

> ⚠️ `delete namespace` は破壊的です。対象 namespace 名を必ず再確認してください。

---

## 6) Command Cheatsheet

```bash
# 現在の接続先確認
kubectl config current-context
kubectl config get-contexts

# namespace 明示
kubectl get pods -n k8s-mag-lab

# 状態確認
kubectl get deploy,pods,svc
kubectl describe deployment web
kubectl logs deploy/web --tail=100

# 更新
kubectl set image deployment/web nginx=nginx:1.26
kubectl rollout status deployment/web
kubectl rollout history deployment/web
kubectl rollout undo deployment/web

# 宣言的運用の安全確認
kubectl diff -f manifests/
kubectl apply --dry-run=server -f manifests/
kubectl apply -f manifests/
```

---

## 7) よくあるミス & 安全策

### ミス1: 別クラスタに apply/delete
- **危険:** 本番事故
- **安全策:** 毎回 `kubectl config current-context` を先に実行

### ミス2: namespace 指定漏れ
- **危険:** default 汚染、想定外リソース更新
- **安全策:** `-n <ns>` 明示、または作業前に context の default namespace 設定

### ミス3: Secret を manifest に平文記載
- **危険:** Git漏えい
- **安全策:** External Secrets / Sealed Secrets / Secret manager 連携を使う。少なくとも平文コミット禁止。

### ミス4: `kubectl apply -f .` の作用範囲未確認
- **危険:** 意図しない一括変更
- **安全策:** 実行前に `kubectl diff` と対象ディレクトリ確認

### ミス5: 削除コマンドを勢いで実行
- **危険:** 復旧コスト大
- **安全策:** 削除前に対象を `get` で再確認。可能ならレビュー手順を挟む。

---

## 8) 面接風クエスチョン

**Q.** 「`kubectl apply` と `kubectl replace` の違いは？ 本番運用で apply が好まれる理由は？」

**Aの方向性（要点）:**
- apply は宣言的で、差分ベースで状態収束しやすい
- フィールド管理（特に server-side apply）で複数管理者の協調に向く
- replace はオブジェクト全置換になりやすく、運用時の安全性・再現性で不利になりがち

---

## 9) 次の一歩（公式中心）

- Kubernetes Concepts
  - https://kubernetes.io/docs/concepts/
- kubectl Overview
  - https://kubernetes.io/docs/reference/kubectl/
- Deployment
  - https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Perform a Rolling Update
  - https://kubernetes.io/docs/tutorials/kubernetes-basics/update/update-intro/
- Configure Access to Multiple Clusters
  - https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/
- Secrets Good Practices
  - https://kubernetes.io/docs/concepts/security/secrets-good-practices/

---

### 明日の予告（学習アーク継続）
次号は **Beginner: ConfigMap**, **Middle: Secret運用の実践**, **Advanced: probes + rollout戦略（maxSurge/maxUnavailable）** を予定。