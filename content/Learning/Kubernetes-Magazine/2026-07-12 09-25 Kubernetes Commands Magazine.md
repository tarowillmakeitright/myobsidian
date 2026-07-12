---
tags:
  - kubernetes
  - k8s
  - devops
  - learning
  - daily
---

[[Home]]

# 2026-07-12 09:25 Kubernetes Commands Magazine

## 今日のテーマ
**Topic:** `kubectl get / describe / logs` で始める、アプリ開発者のための Kubernetes 観察とトラブルシュート
**Level:** Beginner

---

## 1) なぜ重要か（実アプリ開発とのつながり）
Kubernetes を使った実アプリ開発では、最初に必要になるのは「作る」ことよりも**正しく観察すること**です。  
ローカルでは動いたアプリが、Kubernetes 上では次のような理由で動かないことがよくあります。

- Pod は起動したが Readiness が通らない
- 環境変数や ConfigMap の設定ミスでアプリが落ちる
- Service はあるのに通信できない
- イメージは pull できたが、アプリ内部で例外が出ている

このとき、いきなり `kubectl apply -f ...` や `kubectl delete ...` を繰り返すのは危険です。  
まず `get`・`describe`・`logs` で状況を把握できると、**安全に原因を切り分けられる開発者**になれます。

Kubernetes の実務では、デプロイ作業そのものより、**状態確認・原因調査・安全な修正**の割合がかなり大きいです。

---

## 2) コア概念の解説

### `kubectl get`
Kubernetes リソースの一覧や現在状態を確認する基本コマンドです。

例:
```bash
kubectl get pods
kubectl get deployments
kubectl get svc
```

主な用途:
- 何が存在しているか把握する
- Pod が `Running` / `CrashLoopBackOff` / `Pending` など、ざっくり状態確認する
- Namespace ごとの差を見る

---

### `kubectl describe`
特定リソースの詳細情報を確認します。

例:
```bash
kubectl describe pod <pod-name>
kubectl describe deployment <deployment-name>
```

主な用途:
- Events を見る
- Image pull error や probe 失敗を見つける
- Pod の環境、Volume、Node 配置などを確認する

`get` が「一覧の目」、`describe` は「詳細の目」です。

---

### `kubectl logs`
コンテナ標準出力・標準エラーを確認します。

例:
```bash
kubectl logs <pod-name>
kubectl logs <pod-name> -f
kubectl logs <pod-name> -c <container-name>
```

主な用途:
- アプリ例外の確認
- 起動失敗時のエラーメッセージ確認
- リクエスト処理や接続エラーの調査

複数コンテナ Pod では `-c` が重要です。

---

### Pod / Deployment / Service の最低限イメージ
- **Pod**: コンテナの実行単位
- **Deployment**: Pod を宣言的に管理し、再作成・更新する仕組み
- **Service**: Pod 群への安定したアクセス口

アプリ開発では、Deployment でアプリを動かし、Service で到達性を作り、`kubectl` で観察します。

---

## 3) Kubernetes はアプリ構築の中でどう使われるか
[kubernetes.io/docs](https://kubernetes.io/docs/) のベストプラクティスに沿うと、Kubernetes は単なる「コンテナ起動機」ではなく、**アプリを安全かつ再現可能に運用する基盤**です。

実務では主にこう使います。

### 1. アプリを宣言的に配置する
YAML で Desired State を定義し、環境差分を管理します。

### 2. アプリ状態を継続的に観察する
- Pod は起動しているか
- Readiness/Liveness は通るか
- ログに異常はないか
- ローリングアップデートが正常か

### 3. 設定と秘密情報を分離する
- 一般設定: ConfigMap
- 秘密情報: Secret

ただし、**Secret を平文で Git 管理しない**ことが重要です。  
学習中でも、マニフェストへ API キーや DB パスワードを直書きしない習慣をつけるべきです。

### 4. 安全に変更する
特に以下は要注意です。

- `kubectl apply -f .` を別ディレクトリで誤実行
- 期待しない context / namespace に対する apply
- `kubectl delete` をワイルドに実行

変更前には必ず次を確認します。

```bash
kubectl config current-context
kubectl get ns
```

必要なら明示的に:
```bash
kubectl -n <namespace> get pods
kubectl --context <context-name> get pods
```

---

## 4) 30〜60分ミニラボ
**テーマ:** nginx Pod を動かし、観察コマンドだけで状態を理解する
**想定時間:** 35〜45分
**対象:** Beginner

### ゴール
- Deployment を作る
- Pod / Deployment / Service を `get` で確認する
- `describe` でイベントと詳細を読む
- `logs` でアプリ出力を見る
- ありがちな観察フローを身につける

### 前提
- `kubectl` が使える
- 学習用クラスタ（minikube, kind, Docker Desktop Kubernetes など）がある
- 本番クラスタでは実施しない

### Step 0: コンテキスト確認
```bash
kubectl config current-context
kubectl get nodes
```

**安全確認:** ここが本番クラスタっぽい名前なら作業を止めること。

### Step 1: Namespace を作る
```bash
kubectl create namespace k8s-magazine-lab
```

### Step 2: Deployment を作る
```bash
kubectl -n k8s-magazine-lab create deployment web --image=nginx:1.27
```

### Step 3: 状態確認
```bash
kubectl -n k8s-magazine-lab get deployments
kubectl -n k8s-magazine-lab get pods
kubectl -n k8s-magazine-lab get pods -o wide
```

確認ポイント:
- Pod 名
- READY 列
- STATUS 列
- Node 配置

### Step 4: 詳細確認
Pod 名を取得して describe:
```bash
kubectl -n k8s-magazine-lab describe pod <pod-name>
```

見る場所:
- Containers
- Conditions
- Events

### Step 5: Service を作る
```bash
kubectl -n k8s-magazine-lab expose deployment web --port=80 --target-port=80 --type=ClusterIP
```

確認:
```bash
kubectl -n k8s-magazine-lab get svc
kubectl -n k8s-magazine-lab describe svc web
```

### Step 6: ログを見る
```bash
kubectl -n k8s-magazine-lab logs deployment/web
```

補足: nginx は大量ログが出ないこともあるので、必要ならアクセスを発生させるために port-forward を使う。

### Step 7: ローカルから確認
```bash
kubectl -n k8s-magazine-lab port-forward svc/web 8080:80
```

別ターミナルで:
```bash
curl http://127.0.0.1:8080
```

その後もう一度:
```bash
kubectl -n k8s-magazine-lab logs deployment/web
```

### Step 8: 軽いトラブル調査の練習
Deployment のイメージをわざと存在しないタグへ変えてみる。

```bash
kubectl -n k8s-magazine-lab set image deployment/web nginx=nginx:does-not-exist
kubectl -n k8s-magazine-lab get pods
kubectl -n k8s-magazine-lab describe pod <new-pod-name>
```

観察ポイント:
- `ImagePullBackOff`
- Events に何が出るか

元に戻す:
```bash
kubectl -n k8s-magazine-lab set image deployment/web nginx=nginx:1.27
kubectl -n k8s-magazine-lab rollout status deployment/web
```

### Step 9: 後片付け
```bash
kubectl delete namespace k8s-magazine-lab
```

**警告:** `kubectl delete namespace ...` は対象確認必須。コピペ前に名前を必ず見直すこと。

---

## 5) コマンド・チートシート

### 一覧確認
```bash
kubectl get pods
kubectl get pods -A
kubectl get deployments
kubectl get svc
kubectl get events -n <namespace>
```

### 詳細確認
```bash
kubectl describe pod <pod-name>
kubectl describe deployment <deployment-name>
kubectl describe svc <service-name>
```

### ログ確認
```bash
kubectl logs <pod-name>
kubectl logs <pod-name> -f
kubectl logs <pod-name> -c <container-name>
kubectl logs deployment/<deployment-name>
```

### Namespace / Context 明示
```bash
kubectl config current-context
kubectl get ns
kubectl -n <namespace> get pods
kubectl --context <context-name> get pods
```

### 補助
```bash
kubectl rollout status deployment/<deployment-name>
kubectl port-forward svc/<service-name> 8080:80
```

---

## 6) よくあるミスと安全策

### ミス1: 間違った context に apply / delete する
**危険:** 本番クラスタに誤適用する可能性があります。  
**安全策:** 変更前に毎回これを打つ。

```bash
kubectl config current-context
kubectl get ns
```

---

### ミス2: Namespace を省略する
**危険:** 「見えない」「消えた」と思ったら default namespace を見ていた、という事故が起きます。  
**安全策:** 学習中から `-n <namespace>` を癖にする。

---

### ミス3: Secret を manifest に平文で書く
**危険:** Git や共有ログに漏れやすいです。  
**安全策:**
- 学習でもダミー値を使う
- 実運用では Secret 管理を使う
- リポジトリへ本物の認証情報を置かない

---

### ミス4: `describe` を見ずに再 apply する
**危険:** 原因不明のまま状態を悪化させます。  
**安全策:**
1. `get`
2. `describe`
3. `logs`
4. それから修正

この順で調べると事故が減ります。

---

### ミス5: `kubectl apply -f .` のスコープを雑にする
**危険:** 想定外の manifest まで適用する恐れがあります。  
**安全策:**
- 対象ファイルを明示する
- ディレクトリ実行前に中身確認する
- `--context` や `-n` を明示する

例:
```bash
kubectl --context <lab-context> -n k8s-magazine-lab apply -f deployment.yaml
```

---

## 7) Interview-style Question
**Q.** Pod が `Running` なのにアプリへ正常アクセスできません。最初にどんな順番で調査しますか？

**考え方の例:**
1. `kubectl get pods -n <ns>` で READY / STATUS 確認
2. `kubectl describe pod <pod>` で probe / events / restarts 確認
3. `kubectl logs <pod> -n <ns>` でアプリ例外確認
4. `kubectl get svc -n <ns>` と `describe svc` で selector / port 確認
5. 必要なら `port-forward` でアプリ単体疎通を確認

面接では「やみくもに再デプロイしない」「観察→切り分け→修正」の順序を話せると強いです。

---

## 8) 次の学習ステップ（次号への橋渡し）
次は **Middle** として、`labels`, `selectors`, `kubectl expose`, `rollout`, `readinessProbe` に進むと自然です。

### Middle の前提
- Pod / Deployment / Service の役割がざっくり分かる
- `get` / `describe` / `logs` を一通り使える
- Namespace の概念が分かる

### Advanced の前提
- Deployment 更新と rollout の流れを説明できる
- Probe 失敗時の挙動を理解している
- ConfigMap / Secret の役割を区別できる

---

## 9) 公式中心の参考資料
- Kubernetes Documentation Home  
  https://kubernetes.io/docs/

- Overview: Kubernetes とは何か  
  https://kubernetes.io/docs/concepts/overview/

- kubectl の基本  
  https://kubernetes.io/docs/reference/kubectl/

- Pod 概念  
  https://kubernetes.io/docs/concepts/workloads/pods/

- Deployment 概念  
  https://kubernetes.io/docs/concepts/workloads/controllers/deployment/

- Service 概念  
  https://kubernetes.io/docs/concepts/services-networking/service/

- Debug Running Pods  
  https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/

- Configure Liveness, Readiness and Startup Probes  
  https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/

- Secret  
  https://kubernetes.io/docs/concepts/configuration/secret/

---

## まとめ
今日の要点は、Kubernetes 学習の最初の武器は **作成コマンドではなく観察コマンド** だということです。

- `get` で全体を見る
- `describe` で詳細と Events を読む
- `logs` でアプリの声を聞く

この3つを安全に使えるだけで、実アプリ開発の Kubernetes 調査力がかなり上がります。  
次号では Middle レベルとして、Service 接続・selector・rollout 周りに進めると、開発実務との接続がさらに強くなります。
