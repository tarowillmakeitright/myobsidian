---
tags:
  - kubernetes
  - k8s
  - devops
  - learning
  - daily
---

[[Home]]

# 2026-07-08 09:25 Kubernetes Commands Magazine

#kubernetes #k8s #devops #learning #daily

## 今回のテーマ
**安全に始める Kubernetes の基本操作: `kubectl get` / `describe` / `logs` / `apply` を軸に、アプリ開発で必要な“観察→適用→確認”の流れを身につける**

---

## 1) Topic + Level

### Beginner
**トピック:** Pod / Deployment / Service を `kubectl` で読む・確認する

### Middle
**トピック:** Deployment マニフェストを安全に `apply` し、ロールアウトを確認する

**前提条件:**
- Pod / Deployment / Service の役割をざっくり理解している
- `kubectl get pods` と `kubectl logs` を触ったことがある
- YAML の基本的な読み方がわかる

### Advanced
**トピック:** `namespace`・`context`・`selector` を意識しながら、事故を避けてアプリ更新を進める

**前提条件:**
- Deployment の更新とロールアウト確認を一通り行える
- `kubectl apply -f ...` の意味を理解している
- ラベル (`labels`) とセレクタ (`selectors`) の基本を知っている

---

## 2) Why it matters for real app development

Kubernetes は「アプリを作る人」にとって、単なる運用ツールではない。
実際の開発では次のような場面で毎日関わる。

- 新しい API バージョンを安全にデプロイしたい
- 本番に近い環境で、コンテナが本当に動くか確認したい
- 「動かない」の原因がアプリなのか、設定なのか、クラスタなのか切り分けたい
- 複数人開発で、再現可能な形で環境を管理したい

特に `kubectl` の基本操作は、以下の開発ループで重要。

1. **状態を見る** (`get`, `describe`, `logs`)
2. **設定を反映する** (`apply`)
3. **更新結果を確かめる** (`rollout status`, `get pods`)
4. **問題があれば調査する** (`describe`, `logs`, `events`)

この流れを雑にやると、
- 間違った namespace に apply
- 本番 context に apply
- 広すぎる対象を delete
- Secret を YAML に直書き

みたいな事故が起きる。
だから今日の号では「便利」より先に**安全で実務的な使い方**を押さえる。

---

## 3) Core kubectl / Kubernetes concept explanations

### `kubectl`
Kubernetes API とやり取りするための CLI。クラスタ内部を直接触るのではなく、API サーバー経由で状態を取得・変更する。

### Pod
コンテナを実行する最小単位。通常、アプリを直接 Pod 単体で長期運用するより、Deployment 経由で管理する。

### Deployment
アプリの望ましい状態を定義するリソース。たとえば「nginx を 2 個動かしたい」「イメージをこのバージョンにしたい」を宣言できる。

### Service
Pod 群への安定したアクセス経路を提供する。Pod 自体は入れ替わるので、アプリ間通信は Service を使うのが基本。

### Namespace
クラスタ内の論理的な区切り。`default` のまま使い続けるより、用途ごとに分けた方が事故を減らせる。

### Context
`kubectl` が「どのクラスタ・どのユーザー・どの namespace」を向くかの設定。**apply 前に context 確認は必須級。**

### `apply`
マニフェストに書いた“望ましい状態”をクラスタへ反映するコマンド。Kubernetes らしい宣言的運用の基本。

### `describe`
詳細情報とイベントを確認するコマンド。`get` では見えない失敗理由を見るときに強い。

### `logs`
コンテナ標準出力を読む。アプリの例外、起動失敗、設定ミスの初動確認でほぼ毎回使う。

### `rollout status`
Deployment 更新が成功したかを確認する。`apply` しただけで満足しないための重要コマンド。

---

## 4) How Kubernetes is used while building apps

[kubernetes.io/docs](https://kubernetes.io/docs/) の考え方に沿うと、アプリ開発では次の流れが基本になる。

### 4-1. ローカル開発 → コンテナ化
- アプリをコンテナイメージにする
- 設定はイメージへ焼き込みすぎず、環境差分は外から注入する

### 4-2. マニフェストで実行条件を定義
- Deployment にレプリカ数、イメージ、ポート、ヘルスチェックを記述
- Service に通信入口を定義
- Secret や ConfigMap を使って設定を分離

### 4-3. `kubectl` で反映し、状態を見る
- `kubectl apply -f` で変更を反映
- `kubectl rollout status` で更新完了を確認
- `kubectl get pods`, `describe`, `logs` で状態を追う

### 4-4. ベストプラクティス寄りの視点
- **Secret を manifest に平文で直書きしない**
- **`latest` タグ頼みを避ける**
- **namespace を分ける**
- **ラベルを整理する**
- **適用前に context / namespace を確認する**
- **本番でいきなり広範囲な `delete` や `apply -f .` をしない**

実務では「Kubernetes を知っている」より、**安全に観察して、小さく反映して、確実に戻せる**方が価値が高い。

---

## 5) 30-60 minute hands-on mini lab

### 目的
ローカルクラスタ（minikube / kind / Docker Desktop Kubernetes など）で、Deployment を作成し、`get` → `describe` → `logs` → `apply` → `rollout status` の基本ループを体験する。

### 想定時間
40〜50分

### 事前準備
- `kubectl` が使える
- ローカルの検証用クラスタが起動済み
- **本番クラスタでは絶対にやらない**

### Step 0: 作業前の安全確認
```bash
kubectl config current-context
kubectl config view --minify --output 'jsonpath={..namespace}'; echo
```

確認ポイント:
- いま見ている context は本当に検証用か
- namespace が意図どおりか

必要なら検証用 namespace を作る。

```bash
kubectl create namespace k8s-magazine-lab
```

以後は namespace を明示する。

```bash
kubectl get ns
```

### Step 1: Deployment マニフェストを作る
`deployment.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-demo
  namespace: k8s-magazine-lab
spec:
  replicas: 2
  selector:
    matchLabels:
      app: web-demo
  template:
    metadata:
      labels:
        app: web-demo
    spec:
      containers:
        - name: nginx
          image: nginx:1.27
          ports:
            - containerPort: 80
```

### Step 2: 反映する
```bash
kubectl apply -f deployment.yaml
```

### Step 3: 状態を見る
```bash
kubectl get deployment -n k8s-magazine-lab
kubectl get pods -n k8s-magazine-lab -o wide
kubectl describe deployment web-demo -n k8s-magazine-lab
```

見るポイント:
- Desired / Current / Available の数
- Events に失敗が出ていないか
- Pod が 2 つ起動しているか

### Step 4: ログを見る
```bash
kubectl logs -n k8s-magazine-lab deploy/web-demo
```

補足:
- Deployment 指定でログを取ると、対象 Pod のログへたどりやすい
- 複数 Pod がある場合は個別 Pod 名でも確認してよい

### Step 5: Service を追加する
`service.yaml`

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-demo
  namespace: k8s-magazine-lab
spec:
  selector:
    app: web-demo
  ports:
    - port: 80
      targetPort: 80
```

```bash
kubectl apply -f service.yaml
kubectl get svc -n k8s-magazine-lab
```

### Step 6: Deployment を更新する
Deployment の `replicas` を 3 に変更して再適用。

```yaml
spec:
  replicas: 3
```

```bash
kubectl apply -f deployment.yaml
kubectl rollout status deployment/web-demo -n k8s-magazine-lab
kubectl get pods -n k8s-magazine-lab
```

### Step 7: ラベルで確認する
```bash
kubectl get pods -n k8s-magazine-lab -l app=web-demo
```

### Step 8: 後片付け
**ここは削除コマンドなので、対象 namespace を必ず見直してから実行。**

```bash
kubectl delete namespace k8s-magazine-lab
```

---

## 6) Command cheatsheet

### 状態確認
```bash
kubectl get pods
kubectl get pods -A
kubectl get deploy -n <namespace>
kubectl get svc -n <namespace>
kubectl get pods -o wide
```

### 詳細確認
```bash
kubectl describe pod <pod-name> -n <namespace>
kubectl describe deployment <deployment-name> -n <namespace>
```

### ログ確認
```bash
kubectl logs <pod-name> -n <namespace>
kubectl logs -f <pod-name> -n <namespace>
kubectl logs deploy/<deployment-name> -n <namespace>
```

### 反映・更新
```bash
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl rollout status deployment/<deployment-name> -n <namespace>
```

### コンテキスト・名前空間確認
```bash
kubectl config current-context
kubectl config get-contexts
kubectl get ns
```

### ラベルで絞る
```bash
kubectl get pods -l app=web-demo -n <namespace>
```

### 削除（要注意）
```bash
kubectl delete -f deployment.yaml
kubectl delete namespace <namespace>
```

---

## 7) Common mistakes and safe practices

### よくあるミス 1: 間違った context に apply
**危険:** 開発用のつもりで本番へ反映する事故。

**安全策:**
- `kubectl config current-context` を毎回見る
- 重要作業前に namespace も確認する
- 検証では `-n <namespace>` を明示する癖をつける

### よくあるミス 2: `kubectl apply -f .` を雑に実行
**危険:** 意図しない YAML まで反映される。

**安全策:**
- 対象ファイルを絞る
- ディレクトリ一括適用は構成を把握しているときだけ
- まず内容を読み返してから適用する

### よくあるミス 3: Secret を manifest に平文で書く
**危険:** Git や共有環境に流出しやすい。

**安全策:**
- 平文シークレットの直書きを避ける
- Secret 管理は組織の標準手順に従う
- 少なくとも学習時から「書かない癖」を持つ

### よくあるミス 4: `latest` イメージに頼る
**危険:** 何が動いているか曖昧になる。

**安全策:**
- バージョンタグを明示する
- 更新の差分を追える形にする

### よくあるミス 5: `delete` の対象確認不足
**危険:** namespace や resource を誤って消す。

**安全策:**
- 削除前に resource 名と namespace を声に出して確認するレベルでよい
- 破壊的操作前は一度 `get` して対象を確認する
- 学習環境でも雑な削除習慣をつけない

### よくあるミス 6: `describe` を見ずにログだけ追う
**危険:** スケジューリング失敗や ImagePullBackOff の根本原因を見落とす。

**安全策:**
- まず `get`
- 次に `describe`
- その後 `logs`

この順番はかなり実務向き。

---

## 8) One interview-style question

**質問:**
`kubectl apply -f deployment.yaml` を実行した後、アプリが利用できないままになっています。あなたならどんな順番で調査しますか？

**考えるポイント:**
- context / namespace は正しいか
- Deployment は更新されたか
- Pod は起動しているか
- `describe` にイベント異常はないか
- コンテナログに起動失敗がないか
- Service の selector は Pod ラベルと一致しているか

面接では、単にコマンド名を挙げるだけでなく、**なぜその順番なのか**まで言えると強い。

---

## 9) Next-step resources

まずは公式ドキュメント優先で進めるのが安全。

- Kubernetes Documentation 公式トップ  
  https://kubernetes.io/docs/

- kubectl Overview  
  https://kubernetes.io/docs/reference/kubectl/

- Deployments  
  https://kubernetes.io/docs/concepts/workloads/controllers/deployment/

- Pods  
  https://kubernetes.io/docs/concepts/workloads/pods/

- Services  
  https://kubernetes.io/docs/concepts/services-networking/service/

- Namespaces  
  https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/

- Labels and Selectors  
  https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/

- Secrets  
  https://kubernetes.io/docs/concepts/configuration/secret/

- Debug Running Pods  
  https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/

---

## まとめ

今日の要点はこれ。

- `kubectl` は「見る → 反映する → 確かめる」の道具
- 実務では `get` / `describe` / `logs` / `apply` / `rollout status` が基本線
- 便利さより、**context・namespace・削除対象の確認**が先
- Secret の平文管理や雑な `apply` は避ける
- Kubernetes 学習は、まず Deployment と Service の安全運用を固めると伸びやすい

次回は Middle 寄りに、**ConfigMap / Secret / env 注入 / readinessProbe** あたりへ進むと、かなり「アプリ開発のための Kubernetes」らしくなる。