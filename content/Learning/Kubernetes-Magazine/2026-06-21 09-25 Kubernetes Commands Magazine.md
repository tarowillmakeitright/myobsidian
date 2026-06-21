---
tags:
  - kubernetes
  - k8s
  - devops
  - learning
  - daily
---

# 2026-06-21 09:25 Kubernetes Commands Magazine
[[Home]]

# Daily Kubernetes Commands Magazine

今日は **「kubectl でアプリの状態を読み解き、安全にデプロイを進める」** がテーマです。  
難易度は **Beginner → Middle → Advanced** の順で上げます。  
全部を一気にやらなくても、30〜60分のラボを1本だけ回しても十分学びがあります。

---

## Issue 1 — Beginner
### Topic + Level
**Topic:** Pod / Deployment / Service の基本観察と `kubectl get/describe/logs`  
**Level:** Beginner

### Why it matters for real app development
アプリ開発では「コードを書いたあと、実際に動いているか」を確認する時間がかなり大きいです。  
Kubernetes では、まず **どのリソースが存在しているか**、**どこで失敗しているか**、**アプリのログに何が出ているか** を素早く確認できないと、開発も運用も前に進みません。

たとえば以下のような場面で必須です。
- 新しい API をデプロイしたのに 503 が返る
- Pod が再起動を繰り返している
- Service はあるのに通信できない
- 開発環境で「アプリの問題」なのか「Kubernetes 側の設定問題」なのかを切り分けたい

### Core kubectl / Kubernetes concept explanations
- **Pod**: コンテナが動く最小単位。通常はアプリの実行実体。
- **Deployment**: Pod を宣言的に管理する仕組み。レプリカ数やローリングアップデートを担当。
- **Service**: Pod 群への安定したアクセス経路。
- **Namespace**: 環境やチームごとにリソースを分ける論理境界。
- **`kubectl get`**: 一覧を見る。最初の入口。
- **`kubectl describe`**: 詳細とイベントを見る。詰まったらまずこれ。
- **`kubectl logs`**: アプリの標準出力ログを見る。アプリ起因かどうかを判断しやすい。

### How Kubernetes is used while building apps
実務では kubernetes.io/docs の基本方針どおり、以下の流れが安全です。
- マニフェストを Git で管理する
- Deployment でアプリを管理する
- Service で通信面を安定化する
- 可観測性の第一歩として `get / describe / logs` を使い分ける
- いきなり本番を触らず、**namespace と context を確認してから** apply する

つまり、Kubernetes は「ただコンテナを置く場所」ではなく、**アプリ変更を安全に観測・反映する土台** です。

### 30-60 minute hands-on mini lab
**目標:** nginx を Deployment と Service で起動し、状態確認コマンドに慣れる

#### 事前条件
- `kubectl` が使える
- 学習用クラスタ（minikube / kind / dev cluster など）がある
- 本番クラスタではやらない

#### 手順
1. 現在の接続先を確認
```bash
kubectl config current-context
kubectl get ns
```

2. 学習用 namespace を作る
```bash
kubectl create namespace magazine-lab
```

3. nginx Deployment を作成
```bash
kubectl create deployment web --image=nginx:1.27 -n magazine-lab
```

4. Service を公開
```bash
kubectl expose deployment web --port=80 --target-port=80 --type=ClusterIP -n magazine-lab
```

5. 状態観察
```bash
kubectl get all -n magazine-lab
kubectl describe deployment web -n magazine-lab
kubectl get pods -n magazine-lab -o wide
kubectl logs deployment/web -n magazine-lab
```

6. Pod 名を見つけてさらに確認
```bash
kubectl get pods -n magazine-lab
kubectl describe pod <pod名> -n magazine-lab
```

7. 余裕があればポートフォワードで確認
```bash
kubectl port-forward svc/web 8080:80 -n magazine-lab
```
ブラウザで `http://127.0.0.1:8080` を開く

### Command cheatsheet
```bash
kubectl config current-context
kubectl get ns
kubectl get all -n magazine-lab
kubectl get pods -o wide -n magazine-lab
kubectl describe deployment web -n magazine-lab
kubectl describe pod <pod名> -n magazine-lab
kubectl logs deployment/web -n magazine-lab
kubectl port-forward svc/web 8080:80 -n magazine-lab
```

### Common mistakes and safe practices
**よくあるミス**
- context を確認せず別クラスタへ apply する
- default namespace に何でも作る
- `get` だけで満足してイベントを見ない
- Pod 単体だけ見て Deployment / Service の整合を見ない

**安全策**
- 変更前に必ず `kubectl config current-context` を実行
- `-n <namespace>` を明示する癖をつける
- 削除系コマンドを打つ前に対象を `get` で再確認
- シークレット値をそのまま YAML に書かない

**警告**
- `kubectl delete pod ...` や `kubectl delete -f ...` は学習でも破壊的です。対象 namespace と context を見直してから実行してください。

### Interview-style question
**Q:** `kubectl get pods` では Running なのにアプリにアクセスできません。最初にどのリソースを追加で確認しますか？またその理由は？

### Next-step resources
- Kubernetes Objects: https://kubernetes.io/docs/concepts/overview/working-with-objects/
- Deployments: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Service: https://kubernetes.io/docs/concepts/services-networking/service/
- kubectl Overview: https://kubernetes.io/docs/reference/kubectl/

---

## Issue 2 — Middle
### Topic + Level
**Topic:** `kubectl apply`, rollout, readiness probe, 安全な更新確認  
**Level:** Middle

### Prerequisites
- Pod / Deployment / Service の基本を理解している
- `kubectl get`, `describe`, `logs` が使える
- YAML の基本構文を読める

### Why it matters for real app development
実務では「とりあえず起動」よりも、**壊さず更新すること** が重要です。  
API サーバやフロントエンドを更新するとき、readiness probe や rollout の見方が曖昧だと、起動直後の不安定 Pod にトラフィックが流れて障害になります。

### Core kubectl / Kubernetes concept explanations
- **`kubectl apply`**: 宣言した状態に近づける基本コマンド。
- **readinessProbe**: その Pod がトラフィックを受けてよいか判定する。
- **rollout**: Deployment 更新の進行。
- **`kubectl rollout status`**: 更新完了を確認する。
- **`kubectl rollout history`**: どんな更新があったか見る。
- **`kubectl rollout undo`**: 問題時のロールバック。

### How Kubernetes is used while building apps
kubernetes.io/docs のベストプラクティスに沿うと、アプリ開発では次の運用が定番です。
- マニフェストを明示的に管理する
- readiness probe を設定して未準備 Pod に流さない
- rollout の完了を確認してから次の作業へ進む
- 必要最小限の権限・設定だけを与える
- Secret は Secret リソースや外部シークレット管理を使い、平文で埋め込まない

### 30-60 minute hands-on mini lab
**目標:** readiness probe を持つ Deployment を apply し、更新とロールバックを体験する

#### 手順
1. 以下を `deploy-web.yaml` として保存
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
          image: nginx:1.27
          ports:
            - containerPort: 80
          readinessProbe:
            httpGet:
              path: /
              port: 80
            initialDelaySeconds: 3
            periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: web
  namespace: magazine-lab
spec:
  selector:
    app: web
  ports:
    - port: 80
      targetPort: 80
```

2. apply 前に内容確認
```bash
kubectl config current-context
kubectl diff -f deploy-web.yaml
```

3. 適用
```bash
kubectl apply -f deploy-web.yaml
```

4. rollout 確認
```bash
kubectl rollout status deployment/web -n magazine-lab
kubectl get pods -n magazine-lab
kubectl describe deployment web -n magazine-lab
```

5. イメージ更新
```bash
kubectl set image deployment/web nginx=nginx:1.28 -n magazine-lab
kubectl rollout status deployment/web -n magazine-lab
kubectl rollout history deployment/web -n magazine-lab
```

6. 問題があると想定してロールバック
```bash
kubectl rollout undo deployment/web -n magazine-lab
kubectl rollout status deployment/web -n magazine-lab
```

### Command cheatsheet
```bash
kubectl diff -f deploy-web.yaml
kubectl apply -f deploy-web.yaml
kubectl rollout status deployment/web -n magazine-lab
kubectl rollout history deployment/web -n magazine-lab
kubectl rollout undo deployment/web -n magazine-lab
kubectl set image deployment/web nginx=nginx:1.28 -n magazine-lab
kubectl describe deployment web -n magazine-lab
kubectl logs deployment/web -n magazine-lab
```

### Common mistakes and safe practices
**よくあるミス**
- `kubectl apply -f .` で意図しないファイルまで適用する
- readinessProbe を入れずに更新する
- rollout 完了前に「反映された」と判断する
- Secret を ConfigMap と同列に雑に扱う

**安全策**
- apply 前に `kubectl diff -f <file>` を使う
- `-f` の対象はディレクトリ丸ごとより明示ファイル優先
- ロールアウト後は `status` と `describe` を確認
- Secret は平文マニフェストに埋めない。Git に載せない

**警告**
- `kubectl apply -f .` や `kubectl delete -f .` はスコープ事故の典型です。作業ディレクトリと対象ファイルを毎回確認してください。

### Interview-style question
**Q:** readinessProbe がない Deployment を本番で更新すると、どんな障害が起こりやすいですか？

### Next-step resources
- Update API Objects in Place Using kubectl patch: https://kubernetes.io/docs/tasks/manage-kubernetes-objects/update-api-object-kubectl-patch/
- Perform a Rolling Update on a Deployment: https://kubernetes.io/docs/tutorials/kubernetes-basics/update/update-intro/
- Configure Liveness, Readiness and Startup Probes: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/
- Declarative Object Management: https://kubernetes.io/docs/tasks/manage-kubernetes-objects/declarative-config/

---

## Issue 3 — Advanced
### Topic + Level
**Topic:** Namespace / labels / selectors / dry-run / context-aware operations for safer multi-environment work  
**Level:** Advanced

### Prerequisites
- Deployment / Service / rollout の基本を理解している
- `kubectl apply`, `diff`, `logs`, `describe` を日常的に使える
- 開発・検証・本番など複数環境の違いを理解している

### Why it matters for real app development
実務で一番怖いのは、Kubernetes 自体より **人間の操作ミス** です。  
とくに複数 cluster / 複数 namespace / 複数アプリを扱う現場では、context 取り違えや selector ミスで別環境に影響を出しやすいです。

Advanced レベルでは、単にコマンドを知るだけでなく、**事故を減らすオペレーション設計** を身につけるのが重要です。

### Core kubectl / Kubernetes concept explanations
- **context**: どのクラスタ・認証先を見ているか。
- **label / selector**: リソースを安全かつ柔軟に束ねる仕組み。
- **`--dry-run=client|server`**: 実際に作らず検証する。
- **`-o yaml` / `-o json`**: 現在状態の確認や差分理解に使う。
- **`kubectl auth can-i`**: 今の権限で何ができるか確認する。
- **field selector / label selector**: 対象を絞り込んで確認精度を上げる。

### How Kubernetes is used while building apps
公式ドキュメントの考え方に沿うと、アプリ開発では以下が実践的です。
- 環境ごとに namespace や context を明確に分ける
- labels を設計して observability と運用を楽にする
- 本番操作の前に dry-run / diff / can-i を挟む
- Secret や機密値は専用手段で扱い、監査しやすくする
- 破壊的操作は小さく、明示的に、対象を絞って実行する

### 30-60 minute hands-on mini lab
**目標:** 複数 namespace を意識しながら、安全確認付きで Deployment を運用する

#### 手順
1. namespace を 2 つ作る
```bash
kubectl create namespace team-a
kubectl create namespace team-b
```

2. team-a にラベル付き Deployment を作る
```bash
kubectl create deployment api --image=nginx:1.27 -n team-a
kubectl label deployment api app=api tier=backend env=dev -n team-a
```

3. Pod 側のラベルも確認
```bash
kubectl get deployment api -n team-a -o yaml
kubectl get pods -n team-a --show-labels
```

4. 操作前に context / 権限 / 差分確認
```bash
kubectl config current-context
kubectl auth can-i update deployment -n team-a
kubectl auth can-i delete pods -n team-a
```

5. dry-run で Service マニフェスト生成
```bash
kubectl expose deployment api --port=80 --target-port=80 --type=ClusterIP -n team-a --dry-run=client -o yaml
```

6. server dry-run を使った apply 検証
```bash
kubectl apply --dry-run=server -f deploy-web.yaml
```

7. label selector を使って対象を絞る
```bash
kubectl get all -n team-a -l app=api
kubectl get pods -A -l app=api
```

8. 後片付け前に対象確認
```bash
kubectl get all -n team-a
kubectl get all -n team-b
```

### Command cheatsheet
```bash
kubectl config current-context
kubectl auth can-i update deployment -n team-a
kubectl auth can-i delete pods -n team-a
kubectl get pods -A -l app=api
kubectl get all -n team-a -l app=api
kubectl get deployment api -n team-a -o yaml
kubectl expose deployment api --port=80 --target-port=80 --type=ClusterIP -n team-a --dry-run=client -o yaml
kubectl apply --dry-run=server -f deploy-web.yaml
kubectl diff -f deploy-web.yaml
```

### Common mistakes and safe practices
**よくあるミス**
- context を見ずに prod へ apply / delete
- selector が広すぎて意図しない Pod を拾う
- namespace を指定せず default へ操作する
- Secret をサンプルだからと平文で残す

**安全策**
- 変更前の定型チェック: `current-context` → `namespace` → `diff` → `dry-run`
- `-l` で対象を絞ってから確認する
- 破壊的コマンドは一括より個別・明示的に実行する
- `kubectl delete all --all -n <ns>` のような強い削除は学習クラスタ以外で避ける

**強い警告**
- `kubectl delete all --all -n <namespace>` は破壊的です。学習用 namespace 以外で安易に使わないでください。  
- `kubectl apply -f` / `delete -f` は **context と対象パスの誤認** が最大事故要因です。実行前に必ず再確認してください。

### Interview-style question
**Q:** 複数環境を扱うチームで、`kubectl apply` の事故を減らすには、コマンド運用・ラベル設計・権限確認の観点で何を標準化しますか？

### Next-step resources
- Organizing Cluster Access Using kubeconfig Files: https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/
- Labels and Selectors: https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/
- Namespaces: https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/
- Secrets: https://kubernetes.io/docs/concepts/configuration/secret/
- kubectl Cheat Sheet: https://kubernetes.io/docs/reference/kubectl/cheatsheet/

---

## Quick recap
- **Beginner:** `get / describe / logs` でまず現状把握
- **Middle:** `apply / rollout / readinessProbe` で安全に更新
- **Advanced:** `context / namespace / labels / dry-run / can-i` で事故を減らす

## Safe habits to keep every day
- 先に `kubectl config current-context`
- namespace を明示
- apply 前に `kubectl diff`
- 破壊的操作の前に対象確認
- Secret を平文で置かない
- 学習は本番クラスタでやらない
