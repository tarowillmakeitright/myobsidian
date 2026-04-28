# 2026-04-28 Kubernetes Commands Magazine

#kubernetes #k8s #devops #learning #daily

[[Home]]

---

## 今日のテーマ
**「kubectl apply / rollout / describe で安全に段階リリースを回す」**

学習アーク（段階的難易度）:
1. **Beginner**: Deployment を安全に作成・更新する
2. **Middle**: Rollout 戦略とトラブル時の切り戻し
3. **Advanced**: 本番運用を意識した検証・監査・安全ガード

---

## 1) Topic + Level

### Beginner
**Topic:** `kubectl apply` と `kubectl get/describe/logs` の基本運用

### Middle（前提条件あり）
**Topic:** `kubectl rollout` で更新状況の監視とロールバック

**Prerequisites:**
- Beginner の内容を実施済み
- Deployment / Pod / Service の基本概念を説明できる
- `kubectl config current-context` を確認する習慣がある

### Advanced（前提条件あり）
**Topic:** 安全な本番オペレーション（dry-run, diff, namespace固定, 監査ログ的確認）

**Prerequisites:**
- Middle の手順を一通り実施済み
- RollingUpdate の挙動（maxUnavailable / maxSurge）を理解している
- ラベル・セレクタ不整合が障害要因になると理解している

---

## 2) なぜ実アプリ開発で重要か

- アプリ開発では「**新機能を壊さずに出す**」ことが最重要。
- Kubernetes では Deployment を中心に、更新・監視・切り戻しを標準化できる。
- `apply` だけで突っ込むと、意図しない差分やコンテキスト誤りで事故る。
- `rollout status` と `undo` をセットで使えると、障害時の MTTR（復旧時間）を短縮できる。

---

## 3) コア概念（kubectl/Kubernetes）

- **Deployment**: ReplicaSet を管理し、Pod の更新を段階的に進める。
- **RollingUpdate**: 無停止に近い更新方式。`maxUnavailable` / `maxSurge` で更新速度と安全性を調整。
- **desired state**: マニフェストに「こうあってほしい状態」を宣言し、Kubernetes が収束させる。
- **kubectl apply**: 宣言的反映。`--server-side` や `--dry-run=server` を使うと安全性が上がる。
- **kubectl describe**: イベント込みで原因調査がしやすい。
- **kubectl rollout**: 更新進捗確認・履歴確認・ロールバックの中核。

---

## 4) アプリ開発時の Kubernetes 活用（公式ベストプラクティス整合）

- 小さな変更を Deployment に反映し、`rollout status` で都度確認。
- 本番前に `kubectl diff` と `kubectl apply --dry-run=server` を実施。
- Secret は平文直書きしない（Git に置かない）。
- `-n <namespace>` を常に明示し、誤操作範囲を最小化。
- `kubectl config current-context` を毎回確認し、誤クラスタ反映を防止。
- `kubectl delete` は対象を絞る（ラベル/名前空間）＋実行前に get/describe で再確認。

---

## 5) 30-60分ミニラボ

> 目標: 安全に Deployment を更新し、問題を検知したらロールバックする。

### 0. 事前安全確認（5分）
```bash
kubectl config current-context
kubectl get ns
```

### 1. Namespace 作成（5分）
```bash
kubectl create ns magazine-lab
kubectl get ns magazine-lab
```

### 2. 初期 Deployment 適用（10分）
`deploy-v1.yaml` を作成:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
  namespace: magazine-lab
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
```

適用:
```bash
kubectl apply --dry-run=server -f deploy-v1.yaml
kubectl apply -f deploy-v1.yaml
kubectl rollout status deployment/web -n magazine-lab
kubectl get pods -n magazine-lab -o wide
```

### 3. バージョン更新（10-15分）
`image: nginx:1.26` に変更して再適用。
```bash
kubectl diff -f deploy-v1.yaml
kubectl apply -f deploy-v1.yaml
kubectl rollout status deployment/web -n magazine-lab
kubectl rollout history deployment/web -n magazine-lab
```

### 4. 意図的な失敗→調査→復旧（10-15分）
存在しないタグ（例: `nginx:does-not-exist`）へ変更して適用。
```bash
kubectl apply -f deploy-v1.yaml
kubectl rollout status deployment/web -n magazine-lab --timeout=60s
kubectl describe deployment/web -n magazine-lab
kubectl get events -n magazine-lab --sort-by=.lastTimestamp | tail -n 20
kubectl rollout undo deployment/web -n magazine-lab
kubectl rollout status deployment/web -n magazine-lab
```

### 5. 後片付け（任意・注意）（5分）
```bash
# 破壊的操作: 必ず namespace と current-context を再確認してから
kubectl config current-context
kubectl delete ns magazine-lab
```

---

## 6) コマンドチートシート

```bash
# 安全確認
kubectl config current-context
kubectl get ns

# 反映前チェック
kubectl apply --dry-run=server -f <file>
kubectl diff -f <file>

# 反映と確認
kubectl apply -f <file>
kubectl get deploy,pods -n <ns>
kubectl describe deploy <name> -n <ns>
kubectl logs <pod> -n <ns>

# ロールアウト管理
kubectl rollout status deployment/<name> -n <ns>
kubectl rollout history deployment/<name> -n <ns>
kubectl rollout undo deployment/<name> -n <ns>

# 破壊系（注意）
kubectl delete -f <file>
kubectl delete ns <ns>
```

---

## 7) よくあるミス & 安全運用

### よくあるミス
- `default` namespace に誤って適用。
- 別クラスタ context のまま apply/delete。
- Secret を平文で manifest に書く。
- `kubectl delete` を広いセレクタで実行して想定外削除。

### 安全運用
- 毎回 `kubectl config current-context` を最初に実行。
- 可能なら `-n <namespace>` を必須化。
- `apply` 前に `--dry-run=server` と `diff`。
- Secret は `Secret` リソース + 外部シークレット管理（KMS/External Secrets 等）を検討。
- 破壊的コマンド前に「対象・範囲・context」を声に出して確認。

---

## 8) 面接風質問（1問）

**Q.** RollingUpdate 中に一部 Pod が起動失敗し続けています。`kubectl` だけで、原因調査から安全な復旧までの手順を説明してください。

---

## 9) 次の一歩（公式ドキュメント中心）

- Kubernetes Concepts（基礎全体）
  - https://kubernetes.io/docs/concepts/
- Deployment
  - https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- kubectl Cheat Sheet
  - https://kubernetes.io/docs/reference/kubectl/cheatsheet/
- Configure Access to Multiple Clusters
  - https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/
- Secrets Good Practices
  - https://kubernetes.io/docs/concepts/security/secrets-good-practices/
- Pod Security Standards
  - https://kubernetes.io/docs/concepts/security/pod-security-standards/

---

### 明日予告（学習アーク継続）
次回は **Service / Ingress / Probe（readiness・liveness）** を Beginner→Middle→Advanced で扱い、
「到達性・可用性・安全な公開」を実践ベースで掘り下げます。
