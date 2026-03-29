---
tags:
  - kubernetes
  - k8s
  - devops
  - learning
  - daily
---

# 2026-03-29 09:25 Kubernetes Commands Magazine
[[Home]]

## 今号のテーマ
**Topic:** Deployment を安全に更新する（`rollout` / `set image` / `scale` / `describe`）  
**Level:** Beginner（学習アーク 1/3）

> 次号以降の予告: Middle（Probe/Resource/Strategy）→ Advanced（HPA + PDB + Canary設計）

---

## 1) なぜ実アプリ開発で重要か
アプリ開発では、コードの変更よりも「本番で安全に反映する運用」が事故率を左右します。  
`kubectl apply` だけで進めると、以下の事故が起きやすくなります。

- 更新中に Pod が全落ちして一時停止
- 間違ったイメージタグを本番へ投入
- rollout 失敗を見逃して障害が長引く

**安全な更新コマンドの基本セット**（`set image` / `rollout status` / `rollout undo`）を身につけると、
「壊さずに速く出す」開発体験に直結します。

---

## 2) コア概念（kubectl / Kubernetes）

### Deployment
- 宣言した Pod 数やテンプレートを維持するコントローラ
- RollingUpdate により、旧 Pod を段階的に新 Pod へ置換

### ReplicaSet
- Deployment が裏で管理する実体
- 旧バージョン / 新バージョンの Pod 数調整を担当

### Rollout
- Deployment 更新の進行状態
- `status` で監視、失敗時に `undo` で前版へ戻せる

### Namespace
- リソースの論理分離
- **習慣化ポイント:** 常に `-n <namespace>` を付ける（誤操作防止）

---

## 3) アプリ構築での使い方（kubernetes.io/docs ベストプラクティス準拠）

実運用に寄せるなら、次の流れが堅実です。

1. **明示的に Namespace を切る**（dev/stg/prod）
2. **固定タグより immutable tag（例: SHA）**を優先
3. `kubectl set image` 後は**必ず** `kubectl rollout status` を確認
4. 異常時は即 `kubectl rollout undo`
5. `kubectl describe` と `kubectl logs` で原因を特定

> 公式ドキュメントでも、Deployment による宣言的更新と rollout 監視が中核です。

---

## 4) 30〜60分ミニラボ（Beginner）

### ゴール
`nginx` Deployment を作成し、安全にバージョン更新 → 失敗を検知 → ロールバックする。

### 前提
- Kubernetes クラスタに接続済み（kind/minikube/managed いずれでも可）
- `kubectl` 利用可能

### 手順

#### Step 0: 作業先確認（超重要）
```bash
kubectl config current-context
kubectl get ns
```

#### Step 1: 専用 namespace 作成
```bash
kubectl create namespace magazine-lab
```

#### Step 2: Deployment 作成
```bash
kubectl -n magazine-lab create deployment web --image=nginx:1.25
kubectl -n magazine-lab scale deployment web --replicas=3
kubectl -n magazine-lab get pods -o wide
```

#### Step 3: 正常系アップデート
```bash
kubectl -n magazine-lab set image deployment/web nginx=nginx:1.26
kubectl -n magazine-lab rollout status deployment/web
kubectl -n magazine-lab rollout history deployment/web
```

#### Step 4: 意図的に失敗させる（存在しないタグ）
```bash
kubectl -n magazine-lab set image deployment/web nginx=nginx:9.99-does-not-exist
kubectl -n magazine-lab rollout status deployment/web --timeout=90s
```

失敗確認:
```bash
kubectl -n magazine-lab get pods
kubectl -n magazine-lab describe deployment web
kubectl -n magazine-lab get events --sort-by=.lastTimestamp | tail -n 20
```

#### Step 5: ロールバック
```bash
kubectl -n magazine-lab rollout undo deployment/web
kubectl -n magazine-lab rollout status deployment/web
kubectl -n magazine-lab get pods
```

#### Step 6: 後片付け（破壊的操作なので要確認）
```bash
# 本当にこの namespace を消してよいか確認してから実行
kubectl delete namespace magazine-lab
```

---

## 5) Command Cheatsheet

```bash
# 文脈確認
kubectl config current-context
kubectl config get-contexts

# リソース確認
kubectl -n <ns> get deploy,rs,pods
kubectl -n <ns> describe deployment <name>

# 更新
kubectl -n <ns> set image deployment/<name> <container>=<image>:<tag>
kubectl -n <ns> rollout status deployment/<name>
kubectl -n <ns> rollout history deployment/<name>
kubectl -n <ns> rollout undo deployment/<name>

# スケール
kubectl -n <ns> scale deployment/<name> --replicas=3
```

---

## 6) よくあるミス & 安全運用

### よくあるミス
- `default` namespace のまま本番相当を触る
- context を見ずに apply/delete
- `latest` タグ運用で再現不能
- rollout 失敗時に「待つだけ」で放置

### 安全運用チェック
- 実行前に **`kubectl config current-context`**
- コマンドに **`-n <namespace>`** を明示
- 破壊系（`delete`, `apply -f` 広範囲）前に対象を `get` で再確認
- Secret を manifest に平文で書かない（Git 直置き禁止）

> ⚠️ 注意: `kubectl delete -f .` や `kubectl apply -f .` は作業ディレクトリ次第で対象が拡大します。必ずファイルと context を確認してください。

---

## 7) Interview-style Question

**Q.** Deployment の更新中に一部 Pod が `ImagePullBackOff` になりました。サービス影響を最小化しつつ、あなたならどの順で確認・復旧しますか？  

**A（考え方の例）:**
1. `rollout status` で進行停止を確認
2. `describe deployment/pod` と event で根因特定（タグ誤り・認証・レジストリ障害）
3. 即時復旧が必要なら `rollout undo`
4. 原因修正後に再度 `set image`、監視しながら再展開

---

## 8) Next-step Resources（公式優先）

- Kubernetes Deployments  
  https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- kubectl overview  
  https://kubernetes.io/docs/reference/kubectl/
- Update API Objects in Place Using kubectl patch  
  https://kubernetes.io/docs/tasks/manage-kubernetes-objects/update-api-object-kubectl-patch/
- Configure Liveness, Readiness and Startup Probes（次の Middle 予習）  
  https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/
- Good Practices for Kubernetes Secrets  
  https://kubernetes.io/docs/concepts/security/secrets-good-practices/

---

## 次号（Middle）予告
**Topic:** Probe と Resource Requests/Limits で「落ちにくい」アプリ運用  
**Prerequisites:**
- Deployment / Pod / ReplicaSet の基本理解
- `kubectl get/describe/logs` を使った状態確認
- 今号の rollout 監視と undo を実行できること

