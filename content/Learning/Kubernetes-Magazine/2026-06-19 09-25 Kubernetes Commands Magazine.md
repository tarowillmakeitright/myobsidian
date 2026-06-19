---
tags:
  - kubernetes
  - k8s
  - devops
  - learning
  - daily
---

[[Home]]

# 2026-06-19 09-25 Kubernetes Commands Magazine

## 今号のテーマ
**アプリ開発で毎日使う kubectl の基本導線：確認 → デプロイ → 調査 → 安全な更新**

この号は、Kubernetes 上でアプリを開発・運用するときに頻出する `kubectl` コマンドと、実務での使いどころを **Beginner → Middle → Advanced** の順で学ぶ構成です。

---

# Beginner
## 1) Topic + Level
**Topic:** `kubectl get / describe / logs` でアプリの状態を読む  
**Level:** Beginner

## 2) Why it matters for real app development
アプリ開発では「デプロイしたのに動かない」「Pod はあるのにアクセスできない」「コンテナが再起動している」といった状況確認が日常的に発生します。  
このとき最初に必要なのは、むやみに再作成や削除をすることではなく、**いま何が起きているかを安全に観察すること**です。

`kubectl get`、`kubectl describe`、`kubectl logs` は、障害調査の最初の 3 点セットです。これを使えると、開発中のデバッグ、レビュー環境の確認、CI/CD 後の検証が速くなります。

## 3) Core kubectl/Kubernetes concept explanations
- **Pod**: コンテナを実行する最小単位。通常は 1 つ以上のコンテナを含む
- **Deployment**: Pod を望ましい数・状態で維持するための宣言的リソース
- **Service**: Pod 群への安定したアクセス経路
- **Namespace**: リソースを論理分離する単位
- **`kubectl get`**: リソース一覧や状態を俯瞰して見る
- **`kubectl describe`**: イベントや詳細設定を見る
- **`kubectl logs`**: コンテナの標準出力・標準エラーを確認する

## 4) How Kubernetes is used while building apps
kubernetes.io/docs のベストプラクティスに沿うと、アプリ開発では次の流れが自然です。

- マニフェストで Deployment / Service を定義する
- `kubectl apply` で宣言的に反映する
- `kubectl get` で Pod/Deployment の状態を確認する
- `kubectl describe` でスケジューリングや probe 失敗などのイベントを見る
- `kubectl logs` でアプリの挙動を確認する
- 問題の根本を把握してから修正する

つまり Kubernetes は、単なる「実行場所」ではなく、**アプリのライフサイクルと観測性を支える土台**です。

## 5) 30-60 minute hands-on mini lab
### 目標
Nginx を 1 Pod デプロイし、状態確認とログ確認を体験する。

### 手順
1. 作業用 Namespace を作る
```bash
kubectl create namespace k8s-magazine-lab
```

2. Deployment を作成する
```bash
kubectl create deployment web --image=nginx:1.27 -n k8s-magazine-lab
```

3. 状態を確認する
```bash
kubectl get deployments -n k8s-magazine-lab
kubectl get pods -n k8s-magazine-lab -o wide
```

4. Pod の詳細を見る
```bash
kubectl describe pod -n k8s-magazine-lab <pod-name>
```

5. ログを見る
```bash
kubectl logs -n k8s-magazine-lab <pod-name>
```

6. Service を公開する
```bash
kubectl expose deployment web --port=80 --target-port=80 --type=ClusterIP -n k8s-magazine-lab
kubectl get svc -n k8s-magazine-lab
```

7. 後片付け
```bash
kubectl delete namespace k8s-magazine-lab
```

### 学習ポイント
- `get` は俯瞰
- `describe` はイベント確認
- `logs` はアプリ内部の手がかり
- 調査前に削除しない

## 6) Command cheatsheet
```bash
kubectl config current-context
kubectl get ns
kubectl get pods -n <namespace>
kubectl get deployments -n <namespace>
kubectl describe pod -n <namespace> <pod-name>
kubectl logs -n <namespace> <pod-name>
kubectl logs -f -n <namespace> <pod-name>
kubectl get events -n <namespace> --sort-by=.metadata.creationTimestamp
```

## 7) Common mistakes and safe practices
### よくあるミス
- Namespace を見落として、別環境のリソースを見てしまう
- `logs` を見ずに Pod を消して証拠を失う
- `describe` の Events を読まずに原因を推測で決めつける

### 安全策
- 作業前に必ず確認
```bash
kubectl config current-context
kubectl config view --minify --output 'jsonpath={..namespace}'; echo
```
- 本番・検証環境で Namespace を明示する
- 削除系コマンドの前に対象を `get` で確認する
- Secret をログやマニフェストに直接書かない

## 8) One interview-style question
**Q.** `kubectl get pod` と `kubectl describe pod` の違いは何ですか？実務ではどう使い分けますか？

## 9) Next-step resources
- Kubernetes overview  
  https://kubernetes.io/docs/concepts/overview/
- Pods  
  https://kubernetes.io/docs/concepts/workloads/pods/
- Deployment  
  https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Debug running pods  
  https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/

---

# Middle
## 1) Topic + Level
**Topic:** `kubectl apply` と Deployment のローリング更新を安全に扱う  
**Level:** Middle  
**Prerequisites:** Pod / Deployment / Service の基本、`kubectl get` と `kubectl logs` が読めること

## 2) Why it matters for real app development
開発現場ではアプリを何度も更新します。重要なのは、**更新を速く行うことではなく、壊さず戻せること**です。  
Deployment のローリングアップデートを理解していれば、ユーザー影響を最小限に抑えて新しいバージョンへ移行できます。

## 3) Core kubectl/Kubernetes concept explanations
- **`kubectl apply`**: 宣言した状態に近づける。継続運用向き
- **RollingUpdate**: 古い Pod を段階的に置き換える更新戦略
- **ReplicaSet**: Deployment 配下で Pod 世代を管理する
- **`kubectl rollout status`**: 更新の進行状況を確認
- **`kubectl rollout undo`**: 以前のリビジョンへ戻す

## 4) How Kubernetes is used while building apps
実務では Git 管理されたマニフェストを `apply` し、Deployment で更新を段階適用するのが基本です。  
Kubernetes 公式ドキュメントでも、宣言的管理・段階更新・状態確認・ロールバックの組み合わせが重要です。

アプリ開発フロー例:
- 開発者がイメージを更新
- マニフェストの image tag を変更
- `kubectl apply -f` で反映
- `kubectl rollout status` で安全確認
- 問題があれば `rollout undo`

## 5) 30-60 minute hands-on mini lab
### 目標
Deployment を YAML で作成し、イメージ更新とロールバックを試す。

### `deployment.yaml`
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-app
  namespace: k8s-magazine-lab
spec:
  replicas: 2
  selector:
    matchLabels:
      app: demo-app
  template:
    metadata:
      labels:
        app: demo-app
    spec:
      containers:
        - name: nginx
          image: nginx:1.27
          ports:
            - containerPort: 80
```

### 手順
1. Namespace 作成
```bash
kubectl create namespace k8s-magazine-lab
```

2. YAML を保存して反映
```bash
kubectl apply -f deployment.yaml
```

3. 状態確認
```bash
kubectl get deploy,rs,pods -n k8s-magazine-lab
kubectl rollout status deployment/demo-app -n k8s-magazine-lab
```

4. イメージを更新
```bash
kubectl set image deployment/demo-app nginx=nginx:1.28 -n k8s-magazine-lab
kubectl rollout status deployment/demo-app -n k8s-magazine-lab
```

5. 履歴確認
```bash
kubectl rollout history deployment/demo-app -n k8s-magazine-lab
```

6. ロールバック
```bash
kubectl rollout undo deployment/demo-app -n k8s-magazine-lab
kubectl rollout status deployment/demo-app -n k8s-magazine-lab
```

7. 後片付け
```bash
kubectl delete namespace k8s-magazine-lab
```

## 6) Command cheatsheet
```bash
kubectl apply -f deployment.yaml
kubectl diff -f deployment.yaml
kubectl get deploy,rs,pods -n <namespace>
kubectl set image deployment/<name> <container>=<image> -n <namespace>
kubectl rollout status deployment/<name> -n <namespace>
kubectl rollout history deployment/<name> -n <namespace>
kubectl rollout undo deployment/<name> -n <namespace>
```

## 7) Common mistakes and safe practices
### よくあるミス
- `kubectl apply -f .` を別ディレクトリで実行して意図しないマニフェストまで反映する
- context を確認せず本番クラスタへ apply する
- `latest` タグを使って、何がデプロイされたか追跡不能になる

### 安全策
- 反映前に差分確認
```bash
kubectl diff -f deployment.yaml
```
- 適用範囲を狭くする
- `kubectl config current-context` を毎回確認する
- イメージタグは固定する
- Secret は `env` に直書きせず Secret リソースや外部シークレット管理を使う
- 破壊的操作の前には対象 Namespace・ファイル・context を声に出して確認するくらいでちょうどいい

## 8) One interview-style question
**Q.** `kubectl apply` と `kubectl create` の違いは何ですか？継続的なアプリ運用ではどちらが向いていますか？理由も説明してください。

## 9) Next-step resources
- Declarative object management  
  https://kubernetes.io/docs/tasks/manage-kubernetes-objects/declarative-config/
- Deployment  
  https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Update API objects in place using kubectl patch  
  https://kubernetes.io/docs/tasks/manage-kubernetes-objects/update-api-object-kubectl-patch/

---

# Advanced
## 1) Topic + Level
**Topic:** ラベル・セレクタ・Namespace を使って安全に運用対象を絞る  
**Level:** Advanced  
**Prerequisites:** Deployment/ReplicaSet の関係、`kubectl apply`、ロールアウト確認、YAML の基本がわかること

## 2) Why it matters for real app development
チーム開発では、複数アプリ・複数環境・複数開発者が同じクラスタを共有することがあります。  
このとき事故を防ぐ鍵は、**正しい対象だけを見る・変える・削除する**ことです。

特に `delete`, `apply`, `label`, `get -A` まわりは強力なので、対象の絞り込みを誤ると影響範囲が大きくなります。

## 3) Core kubectl/Kubernetes concept explanations
- **Label**: リソースに付ける検索用メタデータ
- **Selector**: label に基づいて対象を選ぶ条件
- **Namespace**: チーム・環境・用途を分離する境界
- **`-l` / `--selector`**: 対象絞り込み
- **`-A` / `--all-namespaces`**: 全 Namespace 対象。便利だが慎重に使う

## 4) How Kubernetes is used while building apps
実務では、アプリ開発時に label 設計を先に決めておくと、デバッグ・監視・一括操作・GitOps 運用が安定します。  
たとえば以下のようなラベルはよく使われます。

- `app.kubernetes.io/name`
- `app.kubernetes.io/component`
- `app.kubernetes.io/part-of`
- `app.kubernetes.io/environment`

これにより、特定コンポーネントだけログ確認したり、ステージング環境だけ一覧化したりできます。

## 5) 30-60 minute hands-on mini lab
### 目標
複数 Deployment を作り、label selector で安全に対象を絞る。

### `frontend.yaml`
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: k8s-magazine-lab
  labels:
    app.kubernetes.io/name: frontend
    app.kubernetes.io/part-of: sample-shop
    app.kubernetes.io/environment: lab
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: frontend
  template:
    metadata:
      labels:
        app.kubernetes.io/name: frontend
        app.kubernetes.io/part-of: sample-shop
        app.kubernetes.io/environment: lab
    spec:
      containers:
        - name: nginx
          image: nginx:1.27
```

### `backend.yaml`
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: k8s-magazine-lab
  labels:
    app.kubernetes.io/name: backend
    app.kubernetes.io/part-of: sample-shop
    app.kubernetes.io/environment: lab
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: backend
  template:
    metadata:
      labels:
        app.kubernetes.io/name: backend
        app.kubernetes.io/part-of: sample-shop
        app.kubernetes.io/environment: lab
    spec:
      containers:
        - name: nginx
          image: nginx:1.27
```

### 手順
1. Namespace 作成
```bash
kubectl create namespace k8s-magazine-lab
```

2. 反映
```bash
kubectl apply -f frontend.yaml
kubectl apply -f backend.yaml
```

3. 一覧確認
```bash
kubectl get deploy -n k8s-magazine-lab
kubectl get pods -n k8s-magazine-lab --show-labels
```

4. ラベルで frontend だけ絞る
```bash
kubectl get pods -n k8s-magazine-lab -l app.kubernetes.io/name=frontend
```

5. システム全体の一部として絞る
```bash
kubectl get deploy -n k8s-magazine-lab -l app.kubernetes.io/part-of=sample-shop
```

6. 削除前の安全確認
```bash
kubectl get deploy -n k8s-magazine-lab -l app.kubernetes.io/name=backend
```

7. 対象を確認してから削除
```bash
kubectl delete deploy -n k8s-magazine-lab -l app.kubernetes.io/name=backend
```

8. 後片付け
```bash
kubectl delete namespace k8s-magazine-lab
```

## 6) Command cheatsheet
```bash
kubectl get pods -n <namespace> --show-labels
kubectl get all -n <namespace> -l app.kubernetes.io/name=<name>
kubectl get deploy -A -l app.kubernetes.io/part-of=<system>
kubectl label pod <pod-name> team=platform -n <namespace>
kubectl delete deploy -n <namespace> -l app.kubernetes.io/name=<name>
kubectl config get-contexts
```

## 7) Common mistakes and safe practices
### よくあるミス
- `-A` を付けたまま全 Namespace を見て混乱する
- selector の条件が広すぎて複数サービスをまとめて操作する
- `kubectl delete -l ...` を事前確認なしで実行する

### 安全策
- **破壊的コマンド前に必ず同じ selector で `get` を打つ**
- `delete` の前に `current-context` と Namespace を確認する
- `apply` は単一ファイルまたは明示ディレクトリで行う
- 機密情報は label や annotation に書かない
- Secret を Git 管理下の平文マニフェストへ埋め込まない

### 破壊的操作への警告
以下は便利ですが、誤ると被害が大きいです。
```bash
kubectl delete namespace <name>
kubectl delete -f .
kubectl apply -f .
kubectl delete deploy -A -l <selector>
```
実行前に **context / namespace / selector / 対象件数** を必ず確認してください。

## 8) One interview-style question
**Q.** なぜ Kubernetes 運用では label 設計が重要なのですか？`kubectl` の操作性や安全性の観点から説明してください。

## 9) Next-step resources
- Recommended labels  
  https://kubernetes.io/docs/concepts/overview/working-with-objects/common-labels/
- Labels and selectors  
  https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/
- Namespaces  
  https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/
- kubectl quick reference  
  https://kubernetes.io/docs/reference/kubectl/quick-reference/

---

# まとめ
今日の要点は 3 つです。

1. まず観察する: `get` / `describe` / `logs`  
2. 変更は宣言的かつ段階的に行う: `apply` / `rollout status` / `undo`  
3. 対象を狭く安全に操作する: `namespace` / `label` / `selector`

Kubernetes を実務で使うなら、「コマンドを知っている」だけでは足りません。  
**どの対象に、どの文脈で、どれだけ安全に実行するか** まで含めて身につけると、開発でも運用でも強くなれます。
