---
tags:
  - kubernetes
  - k8s
  - devops
  - learning
  - daily
---

[[Home]]

# 2026-07-14 09:25 Kubernetes Commands Magazine

**Topic:** `kubectl get / describe / logs` で始めるアプリ開発者のための Kubernetes 基本観測
**Level:** Beginner
**Learning Arc:** Beginner → Middle → Advanced の第1回

> 次回以降はこの基礎を前提に、Service / ConfigMap / rollout / probe / namespace / manifest 運用へ段階的に進める。

---

## 1) Topic + Level

### 今日のテーマ
Kubernetes を使い始めたとき、最初に覚えるべきなのは「作る」ことよりも、**今どう動いているかを安全に見る**ことです。

今日の主役は次の3コマンドです。

- `kubectl get`
- `kubectl describe`
- `kubectl logs`

この3つは、アプリを Kubernetes 上で開発・デバッグ・運用するときの最初の足場になります。

### レベル
**Beginner**

### この回の到達目標
- Pod / Deployment の見え方を理解する
- `kubectl get` で一覧を見る
- `kubectl describe` で状態とイベントを読む
- `kubectl logs` でアプリの出力を確認する
- destructive な操作を避けながら、安全に調査する習慣を持つ

---

## 2) Why it matters for real app development

実際のアプリ開発では、Kubernetes は「ただコンテナを置く場所」ではありません。

たとえば以下のような場面で必ず観測が必要になります。

- デプロイしたのに画面が 500 を返す
- Pod は起動しているのにアプリが Ready にならない
- 開発環境では動くのにクラスタ上では落ちる
- 設定ミスなのか、イメージの問題なのか、ネットワークなのか切り分けたい

このとき、いきなり manifest を書き換えたり `kubectl delete` したりすると、原因の手がかりを消すことがあります。

だから最初に重要なのは **安全に観測すること**。

`get` / `describe` / `logs` は、

- 何が作られているか
- Kubernetes がどう判断しているか
- アプリ自身が何を出力しているか

をそれぞれ別の角度から見せてくれます。これは実務でかなり重要です。

---

## 3) Core kubectl / Kubernetes concept explanations

## `kubectl` とは何か
`kubectl` は Kubernetes API と会話するための標準 CLI です。

つまり `kubectl` は「Docker の代わり」ではなく、**クラスタの状態を見る・変更するための公式な入口**です。

---

## Pod
Pod は Kubernetes の最小実行単位です。

アプリ開発者の感覚でいうと、まずは

- コンテナが Kubernetes 上で実行される箱
- ログや状態を確認する最小単位

として理解しておけば十分です。

---

## Deployment
Deployment は Pod を安定して維持・更新するための宣言的リソースです。

たとえば：

- Pod が落ちたら再作成する
- レプリカ数を保つ
- 新しいイメージへ段階的に更新する

開発現場では、アプリ本体は Deployment として動くことが多いです。

---

## `kubectl get`
一覧をざっくり見るためのコマンドです。

```bash
kubectl get pods
kubectl get deployments
kubectl get services
```

見るポイント：

- `STATUS` はどうか
- `READY` は揃っているか
- `RESTARTS` が増えていないか
- 意図した namespace を見ているか

---

## `kubectl describe`
あるリソースの詳細を見るコマンドです。

```bash
kubectl describe pod <pod-name>
kubectl describe deployment <deployment-name>
```

特に重要なのは **Events** セクションです。

ここには、たとえば：

- イメージ pull 失敗
- probe 失敗
- スケジューリング失敗
- 再起動の理由

など、Kubernetes が観測した事実が出ます。

---

## `kubectl logs`
コンテナ標準出力・標準エラーを読むコマンドです。

```bash
kubectl logs <pod-name>
```

複数コンテナ入り Pod なら、コンテナ名指定が必要です。

```bash
kubectl logs <pod-name> -c <container-name>
```

再起動後の直前ログを見たい場合：

```bash
kubectl logs <pod-name> --previous
```

---

## namespace
同じクラスタでも、環境やチームごとに論理分離する仕組みです。

最初の事故あるあるは、**違う namespace を見て「何もない」と勘違いすること**です。

```bash
kubectl get pods -n default
kubectl get pods -n dev
kubectl get pods --all-namespaces
```

---

## context
`kubectl` は現在の context に対して実行されます。

つまり、**どのクラスタに対してコマンドを打っているか** は常に確認すべきです。

```bash
kubectl config current-context
kubectl config get-contexts
```

本番クラスタで誤って `apply` や `delete` を打つ事故は、context 未確認が原因になりがちです。

---

## 4) How Kubernetes is used while building apps

kubernetes.io/docs の考え方に沿うと、Kubernetes は「アプリを手でこねる場所」ではなく、**宣言した状態に近づける仕組み**として使います。

実務ではざっくり次の流れになります。

1. アプリをコンテナ化する
2. Deployment / Service などの manifest を用意する
3. `kubectl apply -f ...` でクラスタへ反映する
4. `kubectl get` で配置状況を見る
5. `kubectl describe` で Kubernetes 側の判断を確認する
6. `kubectl logs` でアプリの実ログを見る
7. 必要なら manifest を修正し、再適用する

ここで大事なのは、**まず観測してから変える**ことです。

Kubernetes のベストプラクティスに沿うなら：

- 本番設定を直接 ad-hoc にいじりすぎない
- manifest を source control で管理する
- Secret を平文で Git に置かない
- readiness / liveness のような健全性設計を後からでも入れる
- namespace と label を使って整理する

アプリ開発者にとって Kubernetes は、デプロイ先というより **運用を含めた実行環境の API** です。

---

## 5) 30–60 minute hands-on mini lab

### ラボ名
`kubectl get / describe / logs` で NGINX Pod と Deployment を観測する

### 想定時間
**35〜50分**

### 目的
- Pod 単体と Deployment 管理下の Pod の違いをざっくり掴む
- `get` / `describe` / `logs` の使い分けを実感する
- namespace と context の確認を癖にする

### 前提
- `kubectl` が使える
- 学習用クラスタがある（minikube, kind, Docker Desktop Kubernetes など）
- **本番クラスタでは絶対にやらない**

---

### Step 0: まず安全確認

```bash
kubectl config current-context
kubectl get namespaces
```

可能なら学習用 namespace を作る：

```bash
kubectl create namespace k8s-magazine-lab
```

以後はその namespace を明示します。

```bash
kubectl get pods -n k8s-magazine-lab
```

---

### Step 1: 単体 Pod を作る

```bash
kubectl run web --image=nginx:1.27 --restart=Never -n k8s-magazine-lab
```

状態確認：

```bash
kubectl get pod web -n k8s-magazine-lab
kubectl get pods -o wide -n k8s-magazine-lab
```

観察ポイント：

- `STATUS` が `Running` になるか
- Node がどこか
- IP が付いたか

---

### Step 2: describe で詳細を見る

```bash
kubectl describe pod web -n k8s-magazine-lab
```

特に見る場所：

- `Containers:`
- `State:`
- `Ready:`
- `Events:`

問い：

- イメージはどこから pull されたか？
- readinessProbe はあるか？
- event に warning はあるか？

---

### Step 3: logs を見る

```bash
kubectl logs web -n k8s-magazine-lab
```

NGINX の起動ログやアクセス関連ログが見えます。

リアルタイム監視：

```bash
kubectl logs -f web -n k8s-magazine-lab
```

別ターミナルで Pod 内に入ってみる場合：

```bash
kubectl exec -it web -n k8s-magazine-lab -- /bin/sh
```

Pod 内で簡単なアクセスを発生させる例：

```sh
wget -qO- http://127.0.0.1
exit
```

その後もう一度ログを見ると、アクセスログが増えることがあります。

---

### Step 4: Deployment を作る

```bash
kubectl create deployment web-deploy --image=nginx:1.27 -n k8s-magazine-lab
```

確認：

```bash
kubectl get deployments -n k8s-magazine-lab
kubectl get replicasets -n k8s-magazine-lab
kubectl get pods -n k8s-magazine-lab
```

ここで「Deployment → ReplicaSet → Pod」という関係を軽く意識します。

---

### Step 5: Deployment を describe する

```bash
kubectl describe deployment web-deploy -n k8s-magazine-lab
```

見るポイント：

- Desired / Current / Available replicas
- Pod template
- Events

次に Pod 側も見る：

```bash
kubectl get pods -n k8s-magazine-lab
kubectl describe pod <deploymentが作ったpod名> -n k8s-magazine-lab
```

---

### Step 6: よくある調査フローを真似る

次の順番で情報を集める練習をします。

1. `kubectl get deployments -n k8s-magazine-lab`
2. `kubectl get pods -n k8s-magazine-lab`
3. `kubectl describe deployment web-deploy -n k8s-magazine-lab`
4. `kubectl describe pod <pod-name> -n k8s-magazine-lab`
5. `kubectl logs <pod-name> -n k8s-magazine-lab`

この順番は実務でもかなり使います。

---

### Step 7: 片付け（実行前に対象確認）

**削除系コマンドは対象 namespace と context を再確認してから** 実行してください。

```bash
kubectl config current-context
kubectl get all -n k8s-magazine-lab
```

問題なければ：

```bash
kubectl delete deployment web-deploy -n k8s-magazine-lab
kubectl delete pod web -n k8s-magazine-lab
kubectl delete namespace k8s-magazine-lab
```

> `kubectl delete namespace ...` は配下リソースをまとめて消します。学習用 namespace だけに限定して使うこと。

---

## 6) Command cheatsheet

### 状況確認
```bash
kubectl config current-context
kubectl config get-contexts
kubectl get namespaces
kubectl get pods -A
kubectl get deployments -A
```

### namespace 指定
```bash
kubectl get pods -n k8s-magazine-lab
kubectl describe pod web -n k8s-magazine-lab
kubectl logs web -n k8s-magazine-lab
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
kubectl logs <pod-name> -c <container-name> -n <namespace>
kubectl logs <pod-name> --previous -n <namespace>
```

### 作成
```bash
kubectl run web --image=nginx:1.27 --restart=Never -n k8s-magazine-lab
kubectl create deployment web-deploy --image=nginx:1.27 -n k8s-magazine-lab
```

### 注意が必要な削除
```bash
kubectl delete pod web -n k8s-magazine-lab
kubectl delete deployment web-deploy -n k8s-magazine-lab
kubectl delete namespace k8s-magazine-lab
```

---

## 7) Common mistakes and safe practices

## よくあるミス

### 1. context を確認せずに実行する
これはかなり危険です。

**安全策:**
- まず `kubectl config current-context`
- 削除前は必ずもう一度確認
- 本番・開発で context 名を分かりやすくする

### 2. namespace を付け忘れる
`default` を見て「Pod がない」と勘違いしがちです。

**安全策:**
- `-n <namespace>` を明示する
- 迷ったら `-A` で全体を見る

### 3. `describe` を見ずにログだけ追う
問題がアプリではなく、スケジューリングや ImagePull にあることも多いです。

**安全策:**
- まず `get`
- 次に `describe`
- その後 `logs`

### 4. Secret を manifest に平文で書く
学習段階でも悪い癖になります。

**安全策:**
- API key や DB パスワードを YAML に直書きしない
- Git に secret をコミットしない
- Secret 管理は公式の Secret リソースや外部 secret 管理を学んでから扱う

### 5. `kubectl apply -f .` を雑に打つ
カレントディレクトリ内の意図しない manifest まで適用することがあります。

**安全策:**
- 対象ファイルを明示する
- 適用前にファイル内容を確認する
- context / namespace / scope を確認する

### 6. `kubectl delete` を広い範囲で実行する
ラベルや namespace 指定ミスで想定外に消す事故があります。

**安全策:**
- 削除前に `kubectl get ...` で対象確認
- 学習時も namespace を分ける
- 破壊的操作の前に「本当にそのクラスタか」を確認する

---

## 8) One interview-style question

**Q.** アプリが Kubernetes 上で起動しないと報告を受けました。最初に `kubectl logs` だけを見るのではなく、`kubectl get` と `kubectl describe` も合わせて使うべき理由を説明してください。

**考えるヒント:**
- `get` は何を把握するためのものか？
- `describe` の Events から何が分かるか？
- 問題がアプリ内部ではなく、Kubernetes 側の配置や起動判定にあるケースは？

---

## 9) Next-step resources

まずは公式ドキュメント優先で進めるのが安全です。

- Overview: Kubernetes とは  
  https://kubernetes.io/docs/concepts/overview/

- kubectl の基本  
  https://kubernetes.io/docs/reference/kubectl/

- Pods  
  https://kubernetes.io/docs/concepts/workloads/pods/

- Deployments  
  https://kubernetes.io/docs/concepts/workloads/controllers/deployment/

- Namespaces  
  https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/

- Debug Pods and ReplicationControllers  
  https://kubernetes.io/docs/tasks/debug/debug-application/debug-pods/

- Application troubleshooting  
  https://kubernetes.io/docs/tasks/debug/debug-application/

### 次回のおすすめテーマ
**Middle 予告:** `kubectl apply`, `rollout status`, `rollout history`, `rollout undo` で安全にアプリを更新する

**Middle の前提知識:**
- Pod と Deployment の違いが分かる
- `kubectl get / describe / logs` で基本調査ができる
- namespace と context の重要性を理解している

**Advanced 予告:** readinessProbe / livenessProbe / resources / ConfigMap / Secret の設計と安全運用

**Advanced の前提知識:**
- Deployment 更新フローを説明できる
- rollout の見方と戻し方を理解している
- manifest を source control で管理する意義が分かる

---

## まとめ

今日の最重要ポイントはこれです。

- Kubernetes 学習の最初は「作る」より「観測する」
- `kubectl get` で全体像を見る
- `kubectl describe` で Kubernetes 側の判断を読む
- `kubectl logs` でアプリの実ログを読む
- destructive なコマンドの前に **context / namespace / scope** を確認する

この3つを丁寧に使えるだけで、Kubernetes 上のアプリ開発はかなり事故りにくくなります。
