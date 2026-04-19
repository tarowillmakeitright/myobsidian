# Kubernetes Commands Magazine — 2026-04-19 (09:25)

Tags: #kubernetes #k8s #devops #learning #daily  
Link: [[Home]]

---

## 今号のテーマ
**Deployment のローリングアップデートを `kubectl` で安全に扱う（Beginner → Middle → Advanced 学習アーク）**

---

## 1) Topic + Level

### Beginner
**Topic:** `kubectl get/describe/logs` で Deployment / Pod の状態を読む

### Middle（前提あり）
**Topic:** `kubectl set image` と `kubectl rollout` で安全に更新・監視・ロールバック

- **Prerequisites:**
  - Beginner の内容（Pod/Deployment の基本観察）ができる
  - コンテナイメージタグ（例: `nginx:1.27`）の意味を理解している

### Advanced（前提あり）
**Topic:** `readinessProbe` と `strategy.rollingUpdate` を使った「落とさない更新設計」

- **Prerequisites:**
  - Middle の内容（rollout status/history/undo）が使える
  - YAML の基本編集ができる

---

## 2) なぜ実アプリ開発で重要か

Web アプリ開発では、機能追加より「安全に出す」ことが難所です。  
Kubernetes の更新運用を理解しておくと、以下が実現しやすくなります。

- デプロイ時のダウンタイム最小化
- 問題発生時の即時ロールバック
- 本番障害の初動（何が壊れたかを最短で把握）

つまり **開発速度と信頼性の両立** に直結します。

---

## 3) Core kubectl / Kubernetes 概念

- **Deployment**: Pod の望ましい状態（レプリカ数・イメージ）を宣言する
- **ReplicaSet**: Deployment が世代管理する Pod 集合
- **Rollout**: 新旧 ReplicaSet を段階的に切り替える更新過程
- **Readiness Probe**: 「トラフィックを受けてよい状態か」を判定
- **Rollback (`rollout undo`)**: 問題があれば直前安定版へ戻す

よく使う観察コマンド:

- `kubectl get deploy,rs,pod -n <namespace>`
- `kubectl describe deploy <name> -n <namespace>`
- `kubectl logs -f deploy/<name> -n <namespace>`
- `kubectl rollout status deploy/<name> -n <namespace>`

---

## 4) アプリ開発時の Kubernetes 実践（kubernetes.io/docs ベストプラクティス準拠）

- `latest` タグ固定を避け、**明示的なバージョンタグ**を使う
- 更新時は `kubectl rollout status` で完了確認する（投げっぱなしにしない）
- readiness を設定して「起動済みだが未準備」Pod へ流さない
- 失敗時は `kubectl rollout undo` でまず復旧、その後に原因分析
- Secret は Git 管理の平文 YAML に直接書かない

---

## 5) 30〜60分ハンズオン・ミニラボ

> ローカル検証想定（minikube / kind / dev cluster）。本番クラスタでは実行しないでください。

### Step 0: 事前安全確認（5分）

```bash
kubectl config current-context
kubectl get ns
```

作業 namespace を作成:

```bash
kubectl create ns mag-lab
```

### Step 1: デプロイ作成（10分）

```bash
kubectl create deployment web --image=nginx:1.25 -n mag-lab
kubectl scale deployment web --replicas=3 -n mag-lab
kubectl get deploy,rs,pod -n mag-lab
```

### Step 2: 安全な更新（10〜15分）

```bash
kubectl set image deployment/web nginx=nginx:1.27 -n mag-lab
kubectl rollout status deployment/web -n mag-lab
kubectl rollout history deployment/web -n mag-lab
```

### Step 3: 障害を想定したロールバック（10分）

存在しないタグに更新して失敗を観察:

```bash
kubectl set image deployment/web nginx=nginx:9.99 -n mag-lab
kubectl rollout status deployment/web -n mag-lab
kubectl get pod -n mag-lab
```

ロールバック:

```bash
kubectl rollout undo deployment/web -n mag-lab
kubectl rollout status deployment/web -n mag-lab
```

### Step 4: Advanced（任意, 15分）

`kubectl edit deployment web -n mag-lab` で以下を追加・調整:

- `readinessProbe`（`httpGet: path: /, port: 80`）
- `strategy.rollingUpdate.maxUnavailable: 0`
- `strategy.rollingUpdate.maxSurge: 1`

適用後に再度 `set image` で更新し、挙動の違いを確認。

### Step 5: 後片付け（注意して実行）

```bash
kubectl delete ns mag-lab
```

---

## 6) Command Cheatsheet

```bash
# 状態確認
kubectl get deploy,rs,pod -n <ns>
kubectl describe deploy <name> -n <ns>
kubectl logs -f deploy/<name> -n <ns>

# 更新
kubectl set image deployment/<name> <container>=<image:tag> -n <ns>
kubectl rollout status deployment/<name> -n <ns>

# 履歴/ロールバック
kubectl rollout history deployment/<name> -n <ns>
kubectl rollout undo deployment/<name> -n <ns>

# 文脈確認（事故防止）
kubectl config current-context
kubectl config get-contexts
```

---

## 7) よくあるミスと安全策

### ミス
- `kubectl apply -f .` で意図しない複数マニフェストを一括適用
- context を確認せず本番クラスタに操作
- `:latest` 利用で再現性が崩れる
- Secret を平文で Git コミット
- `kubectl delete` を namespace 指定なしで実行

### 安全策
- 実行前に毎回 `kubectl config current-context` を確認
- `-n <namespace>` を必ず明示
- 破壊的操作前に対象を `kubectl get ...` で再確認
- Secret は Kubernetes Secret + 外部シークレット管理を検討
- 本番前にステージングで rollout 検証

> ⚠️ **警告（破壊的コマンド）**  
> `kubectl delete ...`、`kubectl apply -f .`、`kubectl replace --force` は対象と context を誤ると広範囲に影響します。必ずクラスタ・namespace・ファイルスコープを確認してから実行してください。

---

## 8) 面接ふう質問（1問）

**質問:**  
「Deployment のローリングアップデート中に一部 Pod が Ready にならない場合、あなたは `kubectl` でどの順番に原因切り分けし、どの時点で rollback を判断しますか？」

---

## 9) 次の学習リソース（公式中心）

- Kubernetes Concepts: Workloads / Deployments  
  https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- kubectl Overview  
  https://kubernetes.io/docs/reference/kubectl/
- Perform a Rolling Update (Task)  
  https://kubernetes.io/docs/tutorials/kubernetes-basics/update/update-intro/
- Probes (Liveness/Readiness/Startup)  
  https://kubernetes.io/docs/concepts/configuration/liveness-readiness-startup-probes/
- Secrets (安全な扱い)  
  https://kubernetes.io/docs/concepts/configuration/secret/

---

### 次号予告（学習アーク継続）
- Beginner: `kubectl exec` / `port-forward` でアプリ診断
- Middle: ConfigMap/Secret を使った設定分離
- Advanced: HPA と requests/limits で安定運用
