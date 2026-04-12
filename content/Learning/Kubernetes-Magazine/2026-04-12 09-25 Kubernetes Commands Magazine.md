---
tags: [kubernetes, k8s, devops, learning, daily]
---

# 2026-04-12 09:25 Kubernetes Commands Magazine
[[Home]]

## 今号の学習アーク
**テーマ:** 「安全に観測し、段階的に更新し、運用を守る」
- **Beginner:** Pod/Deployment の観測と基本操作
- **Middle:** Rollout と Probe で安全にリリース
- **Advanced:** RBAC + NetworkPolicy で実運用の防御線を作る

---

## 1) Topic + Level

### 🟢 Beginner: `kubectl get/describe/logs` で状態を正しく読む

### 🟡 Middle: `rollout` / `set image` / `undo` と Probe 設計
**前提知識:**
- Pod / Deployment / Service の基本
- `kubectl get`, `kubectl describe`, `kubectl logs` を使えること

### 🔴 Advanced: RBAC と NetworkPolicy による最小権限・通信制御
**前提知識:**
- Namespace の分離運用
- Deployment 更新手順（RollingUpdate）
- ラベルセレクタの理解

---

## 2) なぜ実アプリ開発で重要か

- 開発では「動く」だけでなく、**壊さずに継続運用**する必要がある。
- `kubectl` で正しく観測できないと、障害時に原因切り分けが遅れる。
- Rollout/Probe を理解していないと、デプロイ時に 5xx を量産しやすい。
- RBAC/NetworkPolicy を後回しにすると、誤操作・横展開リスクが増え、事故が大きくなる。

---

## 3) Core kubectl / Kubernetes concepts

### Beginner コア
- `kubectl get` : 一覧と現在状態の把握
- `kubectl describe` : イベント・失敗理由（ImagePullBackOff, Probe失敗など）
- `kubectl logs` : アプリの標準出力ログ確認
- `-n <namespace>` : どの名前空間を見ているかを常に明示

### Middle コア
- `kubectl rollout status` : 更新進行を監視
- `kubectl set image` : イメージ差し替え
- `kubectl rollout undo` : 直前リビジョンにロールバック
- Readiness/Liveness Probe : 受信可否と自己回復の判断を分離

### Advanced コア
- RBAC (Role/RoleBinding): 「誰が何をできるか」
- ServiceAccount: Pod が API を触るときの主体
- NetworkPolicy: Pod 間通信を明示許可（デフォルト拒否戦略）

---

## 4) アプリ構築時にどう使うか（kubernetes.io/docs に沿った実践）

- **宣言的管理を基本に**: `kubectl apply -f` でマニフェストをソース管理。
- **Namespace 分離**: 開発/検証/本番を分け、誤爆範囲を限定。
- **Probe を設計してから公開**: 起動直後の不安定時間を Readiness で吸収。
- **段階的ロールアウト**: `rollout status` 監視 + 異常時 `rollout undo`。
- **Secret は平文でGit保存しない**: `Secret` リソースや外部シークレット管理を利用。
- **最小権限**: SA に cluster-admin を安易に付けない。

---

## 5) 30–60分ハンズオン・ミニラボ（目安45分）

### Part A (15分) Beginner: 観測の基本
1. Namespace 作成
```bash
kubectl create namespace mag-lab
```
2. サンプルデプロイ
```bash
kubectl -n mag-lab create deployment web --image=nginx:1.25
kubectl -n mag-lab expose deployment web --port=80 --type=ClusterIP
```
3. 状態確認
```bash
kubectl -n mag-lab get pods,deploy,svc
kubectl -n mag-lab describe deploy web
kubectl -n mag-lab logs deploy/web
```

### Part B (15分) Middle: 安全な更新とロールバック
1. イメージ更新
```bash
kubectl -n mag-lab set image deploy/web nginx=nginx:1.27
kubectl -n mag-lab rollout status deploy/web
kubectl -n mag-lab rollout history deploy/web
```
2. 問題を想定して戻す
```bash
kubectl -n mag-lab rollout undo deploy/web
kubectl -n mag-lab rollout status deploy/web
```

### Part C (15分) Advanced: 権限と通信の防御
1. 読み取り専用 Role 作成（例）
2. ServiceAccount + RoleBinding を紐付け
3. NetworkPolicy で `app=web` への受信を同Namespace内の特定ラベルからのみ許可

> 実施時は CNI が NetworkPolicy をサポートしていることを確認（Calico/Cilium など）。

---

## 6) Command Cheatsheet

```bash
# 文脈確認（超重要）
kubectl config current-context
kubectl config get-contexts

# 基本観測
kubectl -n <ns> get pods,deploy,svc
kubectl -n <ns> describe pod <pod>
kubectl -n <ns> logs <pod>
kubectl -n <ns> logs deploy/<name> --tail=100 -f

# 更新運用
kubectl -n <ns> set image deploy/<name> <container>=<image:tag>
kubectl -n <ns> rollout status deploy/<name>
kubectl -n <ns> rollout history deploy/<name>
kubectl -n <ns> rollout undo deploy/<name>

# 安全確認付きで適用
kubectl diff -f manifest.yaml
kubectl apply -f manifest.yaml
```

---

## 7) よくあるミス & Safe Practices

### よくあるミス
- `default` Namespace のまま作業して本番と混線
- context 未確認で別クラスタに apply/delete
- `kubectl delete` を広いセレクタで実行
- Secret をマニフェストに平文記載
- Probe 未設定で更新時に不安定化

### Safe Practices
- **破壊系コマンド前に必ず確認**
  - `kubectl config current-context`
  - `kubectl -n <ns> get all`
  - 対象を `--namespace` と名前で明示
- `kubectl diff` で差分確認してから `apply`
- 本番は `--prune` や一括 delete を慎重運用
- Secret は Git 平文禁止（KMS/Vault/External Secrets 等を検討）

> ⚠️ 警告: `kubectl delete` / 広範囲 `apply` はクラスタ影響が大きい。**context・namespace・対象名**を3点確認してから実行すること。

---

## 8) 面接っぽい一問

**Q.** Readiness Probe と Liveness Probe の違いを、障害時の挙動まで含めて説明してください。さらに、ローリングアップデート時にどちらがユーザー影響低減に効くか理由も述べてください。

---

## 9) 次の一歩（公式ドキュメント中心）

- Kubernetes Concepts: Overview  
  https://kubernetes.io/docs/concepts/
- kubectl Cheat Sheet  
  https://kubernetes.io/docs/reference/kubectl/cheatsheet/
- Deployments  
  https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Probes (Liveness/Readiness/Startup)  
  https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/
- RBAC Authorization  
  https://kubernetes.io/docs/reference/access-authn-authz/rbac/
- Network Policies  
  https://kubernetes.io/docs/concepts/services-networking/network-policies/
- Secrets (good practices)  
  https://kubernetes.io/docs/concepts/configuration/secret/

---

### 明日の予告
次号は「ConfigMap/Secret の実践運用（アプリ設定の安全な外出し）」を **Beginner → Middle → Advanced** で扱います。
