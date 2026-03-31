---
tags:
  - kubernetes
  - k8s
  - devops
  - learning
  - daily
---

# Daily Kubernetes Commands Magazine — 2026-03-31
[[Home]]

今日のテーマは、**アプリ開発の現場で本当に使う Kubernetes 操作**を、
**Beginner → Middle → Advanced** の順で段階的に学ぶ構成です。

---

## 1) Topic + Level

### Beginner
**Topic:** Pod を安全に観察する `kubectl get/describe/logs` 基礎

### Middle
**Topic:** Deployment の更新戦略と Rollout 管理（`rollout`, `set image`, `scale`）
**Prerequisites:**
- Pod / Deployment の基本概念
- `kubectl get`, `kubectl describe`, `kubectl logs` を使える
- Namespace の基本理解

### Advanced
**Topic:** 本番運用を意識した「安全な適用」: Server-Side Apply / Dry-run / Diff / Context確認
**Prerequisites:**
- Deployment 更新と Rollback の経験
- YAML マニフェストの読解・編集
- 複数クラスタ/複数 Namespace を扱う基礎

---

## 2) Why it matters for real app development

- 開発では「動いた」だけでなく、**安全にデプロイ・観測・復旧**できることが重要。
- Kubernetes 操作ミス（誤 Context、誤 Namespace、広すぎる apply/delete）は、開発・本番問わず重大事故につながる。
- チーム開発では、再現可能なコマンド運用（dry-run, diff, rollout history）を持つことで、レビュー品質と運用信頼性が上がる。

---

## 3) Core kubectl/Kubernetes concept explanations

### Beginner 概念
- **Pod:** コンテナ実行の最小単位（通常は直接運用せず、Deployment配下で管理）
- `kubectl get`: 現在状態の一覧
- `kubectl describe`: 詳細イベント含む診断
- `kubectl logs`: コンテナ標準出力の確認

### Middle 概念
- **Deployment:** 宣言的に望ましい Pod 数・バージョンを管理
- **RollingUpdate:** 段階的に更新し、ダウンタイム最小化
- `kubectl rollout status/history/undo`: 更新の進行確認・履歴参照・切り戻し

### Advanced 概念
- **宣言的運用 (Declarative):** `kubectl apply -f` で望ましい状態へ収束
- **Server-Side Apply:** フィールド所有を管理し、競合を可視化しやすい
- `--dry-run=server`, `kubectl diff`: 実適用前の安全確認
- **Context/Namespace 安全確認:** 誤爆防止の最重要ポイント

---

## 4) How Kubernetes is used while building apps (kubernetes.io/docs best practices aligned)

- ローカル開発後、CI でイメージビルド→レジストリ Push→Deployment 更新が一般的。
- アプリの可用性確保のため、Deployment + Service を基本に構成。
- 設定値は ConfigMap / Secret を分離管理（**Secret を平文でGit管理しない**）。
- 適用前に `kubectl diff` と `--dry-run=server` を実施し、意図しない変更を防止。
- 障害時は `logs` と `describe`、`rollout history` を使い最短で原因切り分け。

参考（公式）:
- Overview: https://kubernetes.io/docs/concepts/overview/
- Deployments: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- kubectl Cheat Sheet: https://kubernetes.io/docs/reference/kubectl/cheatsheet/
- Configuration Best Practices: https://kubernetes.io/docs/concepts/configuration/overview/
- Secrets: https://kubernetes.io/docs/concepts/configuration/secret/

---

## 5) 30–60 minute hands-on mini lab

### 目標
Nginx Deployment を作成し、更新・監視・ロールバックまでを安全に体験する（約45分）。

### 手順

#### Step 0: 事前安全確認（5分）
```bash
kubectl config current-context
kubectl get ns
```
- 作業 Namespace を決める（例: `dev-magazine`）

```bash
kubectl create namespace dev-magazine
kubectl config set-context --current --namespace=dev-magazine
kubectl config view --minify | grep namespace:
```

#### Step 1: Deployment 作成（10分）
```bash
kubectl create deployment web --image=nginx:1.25
kubectl get deploy,pod -o wide
kubectl expose deployment web --port=80 --type=ClusterIP
kubectl get svc
```

#### Step 2: 観察（10分）
```bash
kubectl describe deployment web
kubectl logs deploy/web --tail=50
kubectl get events --sort-by=.metadata.creationTimestamp | tail -n 20
```

#### Step 3: バージョン更新 + rollout確認（10分）
```bash
kubectl set image deployment/web nginx=nginx:1.27
kubectl rollout status deployment/web
kubectl rollout history deployment/web
kubectl get pod -w
```

#### Step 4: 失敗想定の切り戻し（10分）
```bash
kubectl set image deployment/web nginx=nginx:invalid
kubectl rollout status deployment/web --timeout=60s
kubectl rollout undo deployment/web
kubectl rollout status deployment/web
```

#### Step 5: 後片付け（任意）
```bash
# ⚠ 削除前に context/namespace を再確認
kubectl config current-context
kubectl config view --minify | grep namespace:
kubectl delete namespace dev-magazine
```

---

## 6) Command cheatsheet

```bash
# 文脈確認（最重要）
kubectl config current-context
kubectl config view --minify

# 一覧・詳細・ログ
kubectl get all -n <ns>
kubectl describe deploy/<name> -n <ns>
kubectl logs deploy/<name> -n <ns>

# デプロイ更新
kubectl set image deployment/<name> <container>=<image>:<tag>
kubectl scale deployment/<name> --replicas=3
kubectl rollout status deployment/<name>
kubectl rollout history deployment/<name>
kubectl rollout undo deployment/<name>

# 安全な適用
kubectl diff -f manifests/
kubectl apply --dry-run=server -f manifests/
kubectl apply -f manifests/
```

---

## 7) Common mistakes and safe practices

### よくあるミス
1. **誤 Context で apply/delete**（本番に誤適用）
2. `kubectl delete -f .` のような広範囲削除
3. Secret を manifest に平文記載して Git へ push
4. `latest` タグ運用で差分追跡不能
5. Rollout 監視せずに更新完了と誤認

### 安全策
- 毎回最初に `kubectl config current-context` を実行
- `-n <namespace>` を明示（デフォルト依存を減らす）
- 適用前に `kubectl diff` + `--dry-run=server`
- Secret は外部Secret管理や暗号化手法を併用（少なくとも平文Git禁止）
- イメージは固定タグ（可能なら digest）
- **破壊的コマンド前に必ず警告確認:**
  - `kubectl delete ...`
  - `kubectl apply -f`（対象が広い場合）
  - `kubectl replace --force`

---

## 8) One interview-style question

**Q.** Deployment の RollingUpdate 中に一部 Pod が Ready にならず更新が止まりました。あなたなら `kubectl` でどう切り分け、どう安全に復旧しますか？

（期待される観点: `rollout status/history`, `describe`, `logs`, events確認、原因修正後の再適用、必要時 `rollout undo`）

---

## 9) Next-step resources (official first)

- Kubernetes Documentation Home
  - https://kubernetes.io/docs/home/
- Deployments（更新戦略・rollback）
  - https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- kubectl Quick Reference / Cheat Sheet
  - https://kubernetes.io/docs/reference/kubectl/
  - https://kubernetes.io/docs/reference/kubectl/cheatsheet/
- Configure Access to Multiple Clusters（context安全運用）
  - https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/
- Secrets Good Practices
  - https://kubernetes.io/docs/concepts/security/secrets-good-practices/

---

明日の予告（Learning Arc 継続）:
- Beginner: Service / DNS / Port-forward
- Middle: Probes (liveness/readiness/startup)
- Advanced: Resource requests/limits と HPA の実運用