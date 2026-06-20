---
tags:
  - kubernetes
  - k8s
  - devops
  - learning
  - daily
---

[[Home]]

# Kubernetes Commands Magazine — 2026-06-20 09:25

今日のテーマは **「kubectl apply / diff / rollout を使って、安全にアプリ変更を反映する」** です。  
難易度は **Beginner → Middle → Advanced** の学習アークで進めます。

---

## 1) Topic + Level

### Beginner
**Topic:** `kubectl apply` と `kubectl get` の基本で Deployment を安全に更新する

### Middle
**Topic:** `kubectl diff` と `kubectl rollout status/history/undo` で変更確認とロールバックを行う  
**Prerequisites:**
- Pod / Deployment / Service の基本を知っている
- YAML マニフェストを読める
- `kubectl apply -f ...` を一度以上使ったことがある

### Advanced
**Topic:** Namespace・context・ラベル選択を意識しながら、本番事故を避ける変更運用を設計する  
**Prerequisites:**
- kubeconfig / context / namespace の概念を理解している
- RollingUpdate の基本を知っている
- `kubectl rollout` 系コマンドを使ったことがある

---

## 2) Why it matters for real app development

実アプリ開発では、コードを書くだけではなく、**安全にデプロイして、問題があればすぐ戻せること** が重要です。

Kubernetes では次のような場面が毎日起こります。

- API サーバーの新バージョンをデプロイする
- 環境変数やリソース制限を調整する
- 変更前後の差分を確認する
- 問題発生時にロールバックする
- 間違った context / namespace に apply して事故るのを防ぐ

つまり `kubectl apply` だけ覚えても不十分で、**「何をどこに反映し、どう確認し、どう戻すか」** まで理解して初めて、現場で使える Kubernetes スキルになります。

---

## 3) Core kubectl / Kubernetes concept explanations

### `kubectl apply`
マニフェストの宣言状態をクラスターに反映します。  
「この状態にしたい」を Kubernetes に伝える基本コマンドです。

```bash
kubectl apply -f deployment.yaml
```

ポイント:
- imperative に 1 個ずつ操作するより、**宣言的** に管理できる
- Git 管理との相性がよい
- ただし **適用先 context / namespace を間違えると危険**

### `kubectl get`
現在の状態を確認します。

```bash
kubectl get pods
kubectl get deploy
kubectl get svc
```

ポイント:
- apply 後の確認に必須
- `-n <namespace>` を付けるクセをつけると事故が減る

### `kubectl diff`
apply する前に、現在との差分を表示します。

```bash
kubectl diff -f deployment.yaml
```

ポイント:
- 本番前の確認に非常に有効
- 「どのフィールドが変わるか」を先に見られる
- CI/CD の事前チェックにも向く

### `kubectl rollout`
Deployment などの更新状況や履歴、巻き戻しを扱います。

```bash
kubectl rollout status deploy/web
kubectl rollout history deploy/web
kubectl rollout undo deploy/web
```

ポイント:
- RollingUpdate の進行監視ができる
- 更新失敗時の初動が速くなる
- 「apply したら終わり」ではなく「反映が安定したか」まで見る

### context / namespace
`kubectl` が **どのクラスター** に対して、**どの namespace** を対象に操作するかを決めます。

```bash
kubectl config current-context
kubectl config get-contexts
kubectl get pods -n staging
```

ポイント:
- 事故の多くは「間違ったクラスターに apply」
- 本番系では毎回 current-context を確認する習慣が大事

---

## 4) How Kubernetes is used while building apps

kubernetes.io/docs のベストプラクティスに沿うと、アプリ開発中の Kubernetes 利用は次の流れになります。

1. **マニフェストをコードとして管理する**
   - Deployment / Service / ConfigMap などを Git 管理
   - 変更履歴が追える

2. **apply 前に差分確認する**
   - `kubectl diff` で意図しない変更を見つける
   - replicas, image, resources, labels の変更を確認

3. **段階的に反映する**
   - RollingUpdate で一気に全 Pod を落とさない
   - readinessProbe が整っていると安全

4. **反映後に状態確認する**
   - `kubectl rollout status`
   - `kubectl get pods`
   - 必要なら `kubectl describe` / `kubectl logs`

5. **シークレットを直接ベタ書きしない**
   - Secret を使う
   - Git に平文の秘密情報を入れない
   - `env:` に直接 API キーを書かない

6. **破壊的操作は狭いスコープで行う**
   - `kubectl delete -f ...` や `kubectl apply -f dir/` は対象を再確認
   - `-n`, `--context` を明示して誤爆防止

実務では Kubernetes は「アプリを載せる場所」ではなく、**安全に変更を継続的に届ける実行基盤** として使われます。

---

## 5) 30–60 minute hands-on mini lab

### ゴール
ローカルの学習用クラスター（minikube / kind / Docker Desktop Kubernetes など）で、Deployment を更新し、差分確認・ロールアウト監視・ロールバックを体験する。

> **注意:** 以下は学習用クラスター向けです。共有環境や本番クラスターでは実行前に対象 context を必ず確認してください。  
> **破壊的コマンド注意:** `kubectl delete` は対象 namespace と resource 名を確認してから実行してください。

### Step 0: context を確認

```bash
kubectl config current-context
kubectl get ns
```

必要なら学習用 namespace を作成:

```bash
kubectl create namespace k8s-magazine
```

### Step 1: Deployment マニフェストを作る

ファイル名: `web.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
  namespace: k8s-magazine
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
          resources:
            requests:
              cpu: "100m"
              memory: "128Mi"
            limits:
              cpu: "200m"
              memory: "256Mi"
---
apiVersion: v1
kind: Service
metadata:
  name: web
  namespace: k8s-magazine
spec:
  selector:
    app: web
  ports:
    - port: 80
      targetPort: 80
```

### Step 2: 反映前に diff を見る

```bash
kubectl diff -f web.yaml
```

初回は新規作成差分が見えるはずです。

### Step 3: apply する

```bash
kubectl apply -f web.yaml
```

### Step 4: 状態確認

```bash
kubectl get deploy,pods,svc -n k8s-magazine
kubectl rollout status deploy/web -n k8s-magazine
```

### Step 5: イメージ更新を試す

`nginx:1.25` を `nginx:1.27` に変更して保存。

差分確認:

```bash
kubectl diff -f web.yaml
```

反映:

```bash
kubectl apply -f web.yaml
kubectl rollout status deploy/web -n k8s-magazine
kubectl rollout history deploy/web -n k8s-magazine
```

### Step 6: ロールバックを試す

```bash
kubectl rollout undo deploy/web -n k8s-magazine
kubectl rollout status deploy/web -n k8s-magazine
kubectl rollout history deploy/web -n k8s-magazine
```

### Step 7: 後片付け

```bash
kubectl delete namespace k8s-magazine
```

> **警告:** `kubectl delete namespace ...` は namespace 配下のリソースをまとめて削除します。学習用 namespace だけに対して実行してください。

### 余裕があれば
- `kubectl describe deploy web -n k8s-magazine`
- `kubectl get rs -n k8s-magazine`
- `kubectl logs -l app=web -n k8s-magazine`

---

## 6) Command cheatsheet

```bash
# 現在の context 確認
kubectl config current-context

# context 一覧
kubectl config get-contexts

# namespace 一覧
kubectl get ns

# マニフェスト差分確認
kubectl diff -f web.yaml

# マニフェスト適用
kubectl apply -f web.yaml

# 特定 namespace で確認
kubectl get deploy,pods,svc -n k8s-magazine

# ロールアウト進行確認
kubectl rollout status deploy/web -n k8s-magazine

# 履歴確認
kubectl rollout history deploy/web -n k8s-magazine

# ロールバック
kubectl rollout undo deploy/web -n k8s-magazine

# 詳細確認
kubectl describe deploy web -n k8s-magazine

# ラベルで Pod ログ確認
kubectl logs -l app=web -n k8s-magazine
```

---

## 7) Common mistakes and safe practices

### よくあるミス

1. **間違った context に apply する**
   - `kubectl config current-context` を見ずに実行
   - ローカルのつもりが本番だった、が最悪パターン

2. **namespace を省略する**
   - default namespace に入ってしまい、見失う
   - 後から「反映されてない」と勘違いしやすい

3. **diff を見ずに apply する**
   - 不要な replicas 変更や image 変更に気づけない

4. **Secret をマニフェストへ平文で書く**
   - Git に残る
   - レビューや CI ログでも漏れうる

5. **`kubectl delete` の対象を雑に指定する**
   - `-f dir/` や広いラベル指定で消しすぎる

6. **apply 後に rollout 完了を確認しない**
   - 更新が途中失敗しても気づけない

### 安全な実践

- 毎回 `current-context` を確認する
- 本番に近いほど `--context` と `-n` を明示する
- `kubectl diff` → `kubectl apply` → `kubectl rollout status` を基本動線にする
- Secret は Secret 管理機構で扱い、マニフェストへ直接秘密を書かない
- `delete` 前に対象 resource 名・namespace・label selector を読み返す
- 可能なら apply 対象をディレクトリ丸ごとではなく、意図したファイル単位に絞る

---

## 8) Interview-style question

**質問:**  
`kubectl apply` の前に `kubectl diff` を使い、反映後に `kubectl rollout status` を確認するべき理由を説明してください。また、本番事故を防ぐために context / namespace の観点で何を確認するべきですか？

**考えるポイント:**
- 宣言的更新と差分確認
- ロールアウト失敗の早期検知
- kubeconfig context の誤操作防止
- namespace 明示によるスコープ制御

---

## 9) Next-step resources

まずは公式ドキュメント優先。

- Kubernetes Documentation Home  
  https://kubernetes.io/docs/

- Overview of kubectl  
  https://kubernetes.io/docs/reference/kubectl/

- Declarative Management of Kubernetes Objects Using Configuration Files  
  https://kubernetes.io/docs/tasks/manage-kubernetes-objects/declarative-config/

- Deployment  
  https://kubernetes.io/docs/concepts/workloads/controllers/deployment/

- Perform a Rolling Update on a Deployment  
  https://kubernetes.io/docs/tutorials/kubernetes-basics/update/update-intro/

- Debug Applications  
  https://kubernetes.io/docs/tasks/debug/debug-application/

- Secrets  
  https://kubernetes.io/docs/concepts/configuration/secret/

- Namespaces  
  https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/

---

## まとめ

今日の要点はシンプルです。

- **apply する前に diff を見る**
- **apply した後に rollout を確認する**
- **context / namespace を毎回意識する**
- **秘密情報をマニフェストに直接書かない**
- **削除系コマンドは対象スコープを二重確認する**

Kubernetes を実務で安全に使える人は、コマンドをたくさん知っている人というより、**変更の影響範囲を読める人** です。明日の号では、この流れを土台にして `describe` / `logs` / `events` を使ったトラブルシュート寄りの学習アークへ進めてもいいです。
