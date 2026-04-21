---
tags: [kubernetes, k8s, devops, learning, daily]
---

# 2026-04-21 09:25 Kubernetes Commands Magazine
[[Home]]

本日のテーマは **「kubectl で安全にデプロイを観測・更新する」**。  
学習アークは **Beginner → Middle → Advanced** の順で進みます。

---

## 1) Topic + Level

### Beginner: Pod / Deployment の基本観測
**Topic:** `kubectl get/describe/logs` でアプリの状態を正しく把握する

### Middle: Rollout と段階的更新
**Prerequisites:**
- Beginner の `get/describe/logs` を使って状態確認できる
- Deployment / ReplicaSet / Pod の関係を理解している

**Topic:** `kubectl rollout` と `kubectl set image` で安全に更新・ロールバックする

### Advanced: 変更差分を先に確認する運用
**Prerequisites:**
- Middle の rollout 操作を理解している
- Namespace/Context を意識して操作できる

**Topic:** `kubectl diff` / `apply --server-side` / `--dry-run=server` で事故を防ぐ

---

## 2) Why it matters for real app development

- 開発現場では「動かない理由の切り分け」が最速でできる人が強い。`describe/logs/events` の読み方は障害対応の基礎。
- 本番更新では「壊さないデプロイ」が最重要。rollout 管理とロールバック手順を持つことで MTTR を短縮できる。
- GitOps/CI でも最終的な適用先は Kubernetes API。`diff` と `dry-run` で事前確認する習慣が、誤適用や大規模障害を防ぐ。

---

## 3) Core kubectl/Kubernetes concepts

- **Pod:** 最小実行単位。通常は直接ではなく Deployment から管理する。
- **Deployment:** 宣言的に Pod の希望状態を管理し、ローリングアップデートを提供。
- **ReplicaSet:** Deployment が内部的に使う Pod 複製管理リソース。
- **Namespace:** リソース分離の境界。`default` 依存を避ける。
- **Context:** `kubectl` が向くクラスタ/ユーザー/namespace の組。誤クラスタ操作防止の要。
- **Events / Logs / Describe:**
  - `logs`: アプリ内部のログ
  - `describe`: スケジューリングやProbe失敗などKubernetes視点の情報
  - `events`: 時系列で何が起きたか

---

## 4) App developmentでのKubernetes活用（kubernetes.io/docs ベストプラクティス寄せ）

- マニフェストは Git 管理し、`kubectl apply -f` で宣言的に適用。
- イメージ更新は Deployment 経由で行い、`rollout status` で完了確認。
- 機密情報（APIキー、DBパスワード）は Secret/外部Secret管理を使い、**平文で manifest に書かない**。
- `kubectl config current-context` と `-n <namespace>` を明示して、誤環境デプロイを防ぐ。
- 変更前に `kubectl diff` / `--dry-run=server` を実施して API 側で検証する。

---

## 5) 30–60分 Hands-on Mini Lab

### ゴール
Nginx Deployment を作成し、観測 → 更新 → 問題発生を想定したロールバックまで実施。

### 手順（目安45分）

1. **Namespace 作成 (5分)**
```bash
kubectl create namespace magazine-lab
kubectl config set-context --current --namespace=magazine-lab
kubectl config current-context
kubectl get ns
```

2. **Deployment 作成 (10分)**
```bash
kubectl create deployment web --image=nginx:1.25
kubectl get deploy,rs,pods -o wide
kubectl describe deployment web
```

3. **状態観測 (10分)**
```bash
kubectl get pods
kubectl logs deploy/web --tail=50
kubectl get events --sort-by=.lastTimestamp | tail -n 20
```

4. **安全な更新 (10分)**
```bash
kubectl set image deployment/web nginx=nginx:1.27
kubectl rollout status deployment/web
kubectl rollout history deployment/web
```

5. **ロールバック演習 (10分)**
```bash
kubectl set image deployment/web nginx=nginx:bad-tag
kubectl rollout status deployment/web
kubectl rollout undo deployment/web
kubectl rollout status deployment/web
```

6. **後片付け (任意)**
```bash
kubectl delete namespace magazine-lab
```

> ⚠️ 注意: `kubectl delete namespace` は配下リソースをまとめて削除します。実クラスタでは対象 namespace を必ず再確認。

---

## 6) Command Cheatsheet

```bash
# コンテキスト/ネームスペース確認
kubectl config current-context
kubectl config get-contexts
kubectl get ns

# 基本観測
kubectl get pods -A
kubectl describe pod <pod-name> -n <ns>
kubectl logs <pod-name> -n <ns> --tail=100
kubectl get events -n <ns> --sort-by=.lastTimestamp

# Deployment運用
kubectl get deploy -n <ns>
kubectl set image deployment/<name> <container>=<image>:<tag> -n <ns>
kubectl rollout status deployment/<name> -n <ns>
kubectl rollout history deployment/<name> -n <ns>
kubectl rollout undo deployment/<name> -n <ns>

# 安全確認
kubectl diff -f <manifest-dir> -n <ns>
kubectl apply --dry-run=server -f <manifest-dir> -n <ns>
kubectl apply -f <manifest-dir> -n <ns>
```

---

## 7) Common mistakes and safe practices

### よくあるミス
- `default` namespace のまま操作して、別アプリを壊す
- `current-context` を見ずに本番クラスタへ apply/delete
- Secret を ConfigMap や平文 YAML に置く
- `kubectl apply -f .` で意図しないファイルまで適用

### 安全運用
- 実行前に必ず:
  1. `kubectl config current-context`
  2. `kubectl get ns`
  3. 対象 `-n` を明示
- 破壊的操作（`delete`, 広範囲 `apply`）前は `kubectl diff` 実行
- マニフェストはディレクトリを分け、環境単位で適用範囲を限定
- Secret は最低でも Kubernetes Secret、可能なら External Secrets / KMS 連携

---

## 8) Interview-style question

**Q.** Deployment のローリングアップデート中に一部 Pod が Ready にならず更新が止まりました。あなたなら `kubectl` でどの順に調査し、どの条件で rollback を判断しますか？  
（期待される観点: rollout status/history, pod describe, events, readiness/liveness probe, image/tagミス, 影響範囲と復旧優先度）

---

## 9) Next-step resources（公式優先）

- Kubernetes Documentation (Home)  
  https://kubernetes.io/docs/home/
- Overview / Concepts  
  https://kubernetes.io/docs/concepts/overview/
- kubectl Cheat Sheet  
  https://kubernetes.io/docs/reference/kubectl/cheatsheet/
- Deployments  
  https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Configuration Best Practices  
  https://kubernetes.io/docs/concepts/configuration/overview/
- Secrets  
  https://kubernetes.io/docs/concepts/configuration/secret/
- Server-Side Apply  
  https://kubernetes.io/docs/reference/using-api/server-side-apply/

---

明日の予告: **ConfigMap/Secret を使った12-factor寄り設定管理（Beginner→Advanced）**
