[[Home]]

#kubernetes #k8s #devops #learning #daily

# 2026-06-16 09:25 Kubernetes Commands Magazine

## 今日のテーマ + レベル
**テーマ:** `kubectl get` / `describe` / `logs` / `exec` でアプリの実行状態を読む
**レベル:** Beginner

> この学習アークは **Beginner → Middle → Advanced** の順で進みます。  
> 今日の号は **Beginner**。まずは「壊す前に観察する」Kubernetes運用の基本を固めます。

---

## 1) なぜ実アプリ開発で重要なのか
ローカルでは動くのに、Kubernetes に載せると次のような問題が起きます。

- コンテナは起動しているのにアプリに繋がらない
- Pod が再起動を繰り返す
- 環境変数や起動コマンドの違いで動作が変わる
- readiness / liveness の失敗で Service から外れる
- 本番障害時に「とりあえず再起動」して状況証拠を消してしまう

実務では、**変更より先に観察** が大事です。  
その最初の武器が `kubectl get` / `describe` / `logs` / `exec` です。

特にアプリ開発者にとっては、以下の力に直結します。

- デプロイ後の挙動確認
- アプリ障害の一次切り分け
- 設定ミスとコード不具合の切り分け
- SRE / Platform チームとの共通言語づくり

---

## 2) コア kubectl / Kubernetes 概念

### `kubectl get`
リソースの一覧や現在状態をざっと見る基本コマンドです。

例:
```bash
kubectl get pods
kubectl get pods -n demo
kubectl get deployments,services
kubectl get pods -o wide
```

見るポイント:
- `STATUS`
- `READY`
- `RESTARTS`
- `AGE`
- どの namespace を見ているか

### `kubectl describe`
一覧では見えない詳細を読むためのコマンドです。

例:
```bash
kubectl describe pod <pod名>
kubectl describe deployment <deployment名>
```

特に重要なのは **Events** セクションです。

- Image pull エラー
- Probe failure
- Scheduling failure
- CrashLoopBackOff の兆候

### `kubectl logs`
コンテナ標準出力・標準エラーを見るコマンドです。  
アプリ開発者が最初に触るべき診断手段です。

例:
```bash
kubectl logs <pod名>
kubectl logs <pod名> -c <container名>
kubectl logs -f <pod名>
kubectl logs --previous <pod名>
```

`--previous` は再起動前ログ確認にかなり重要です。

### `kubectl exec`
コンテナ内でコマンドを実行します。

例:
```bash
kubectl exec -it <pod名> -- sh
kubectl exec <pod名> -- printenv
kubectl exec <pod名> -- ls /app
```

ただし `exec` は便利ですが、**本番調査での常用は危険** です。
理由:
- 手作業が再現されにくい
- 監査性が落ちる
- コンテナイメージに入っていないツール前提で考えがち
- 誤操作の余地がある

Kubernetes 的には、まずは **宣言的設定・ログ・イベント・メトリクス** を優先し、`exec` は補助的に使うのが健全です。

---

## 3) アプリ開発中に Kubernetes はどう使われるか
Kubernetes は単に「コンテナを動かす箱」ではありません。  
アプリ開発では主に次の流れで使われます。

1. アプリをコンテナ化する
2. Deployment で希望する Pod 数や更新方法を宣言する
3. Service で通信入口を安定化する
4. ConfigMap / Secret で設定を注入する
5. readiness / liveness probe で健全性を伝える
6. `kubectl` でデプロイ後の状態を観察する

Kubernetes 公式のベストプラクティスに沿うなら、次を意識すると実務で強いです。

- **環境差分はイメージではなく設定で管理する**
- **Secrets を manifest に平文で埋めない**
- **Probe を設定して、Pod が「起動した」ではなく「使える」状態を表現する**
- **`latest` タグに頼らず、追跡可能なイメージタグを使う**
- **本番で広いスコープの apply/delete を雑に打たない**

開発者視点では、Kubernetes の価値は「同じアプリを安定した形で運び、観察し、更新できること」です。

---

## 4) 30〜60分ミニラボ
**目標:** Pod の状態確認・ログ確認・軽い内部確認を安全に体験する

### 前提
- `kubectl` が使える
- テスト用クラスタがある（kind / minikube / Docker Desktop Kubernetes など）
- **本番クラスタではやらない**

### 0. 最初の安全確認（超重要）
```bash
kubectl config current-context
kubectl config get-contexts
kubectl get ns
```

確認ポイント:
- 今どのクラスタに向いているか
- 練習用クラスタか
- どの namespace を使うか

必要なら専用 namespace を作ります。
```bash
kubectl create namespace k8s-magazine
```

### 1. サンプル Deployment を作成
```bash
kubectl create deployment web --image=nginx:1.27 -n k8s-magazine
kubectl get pods -n k8s-magazine
```

Pod が `Running` になるまで確認します。

### 2. Pod 一覧を読む
```bash
kubectl get pods -n k8s-magazine -o wide
kubectl get deployment -n k8s-magazine
```

見てほしい点:
- Pod 名の構造
- READY 列
- RESTARTS 列
- Node 配置

### 3. describe で詳細確認
Pod 名を取得:
```bash
kubectl get pods -n k8s-magazine
```

その後:
```bash
kubectl describe pod <pod名> -n k8s-magazine
```

注目点:
- Image
- Container ID
- Port
- Conditions
- Events

### 4. logs を確認
```bash
kubectl logs <pod名> -n k8s-magazine
```

nginx では最初あまりログが出ないことがあります。  
その場合は後でアクセスしてから再確認します。

### 5. Service を作ってアクセス
```bash
kubectl expose deployment web --port=80 --target-port=80 -n k8s-magazine
kubectl get svc -n k8s-magazine
kubectl port-forward svc/web 8080:80 -n k8s-magazine
```

別ターミナルで:
```bash
curl http://127.0.0.1:8080
```

その後、ログを再確認:
```bash
kubectl logs <pod名> -n k8s-magazine
```

### 6. exec で最小限の内部確認
```bash
kubectl exec -it <pod名> -n k8s-magazine -- sh
```

コンテナ内で:
```sh
hostname
nginx -v
ls /usr/share/nginx/html
exit
```

ここでやることは **観察のみ**。  
パッケージ追加やファイル改変はしないでください。

### 7. 軽いトラブル観察をしてみる
Deployment を存在しないイメージに更新してみます。
```bash
kubectl set image deployment/web nginx=nginx:does-not-exist -n k8s-magazine
kubectl get pods -n k8s-magazine
kubectl describe pod <新しいpod名> -n k8s-magazine
```

見るべき点:
- `ImagePullBackOff`
- Events に出る pull error

その後、元に戻します。
```bash
kubectl set image deployment/web nginx=nginx:1.27 -n k8s-magazine
kubectl rollout status deployment/web -n k8s-magazine
```

### 8. 後片付け
```bash
kubectl delete namespace k8s-magazine
```

> **警告:** `kubectl delete` は破壊的です。  
> 実行前に **context / namespace / 対象名** を必ず再確認してください。  
> `kubectl delete ns` や `kubectl delete -f` はスコープを誤ると痛いです。

---

## 5) コマンド・チートシート

### 状態確認
```bash
kubectl config current-context
kubectl get ns
kubectl get pods -A
kubectl get pods -n <namespace>
kubectl get deployments,svc -n <namespace>
kubectl get pods -o wide -n <namespace>
```

### 詳細確認
```bash
kubectl describe pod <pod名> -n <namespace>
kubectl describe deployment <deployment名> -n <namespace>
```

### ログ確認
```bash
kubectl logs <pod名> -n <namespace>
kubectl logs -f <pod名> -n <namespace>
kubectl logs <pod名> -c <container名> -n <namespace>
kubectl logs --previous <pod名> -n <namespace>
```

### コンテナ内確認
```bash
kubectl exec -it <pod名> -n <namespace> -- sh
kubectl exec <pod名> -n <namespace> -- printenv
kubectl exec <pod名> -n <namespace> -- ls /
```

### 安全寄りの補助
```bash
kubectl rollout status deployment/<name> -n <namespace>
kubectl get events -n <namespace> --sort-by=.metadata.creationTimestamp
```

---

## 6) よくあるミスと安全なやり方

### ミス1: 間違ったクラスタに打つ
ありがちです。かなり危険です。

**安全策:**
```bash
kubectl config current-context
kubectl config get-contexts
```
実行前に毎回見る習慣をつける。

### ミス2: namespace を意識しない
「Pod がない」と思ったら namespace 違い、は超定番です。

**安全策:**
- `-n <namespace>` を明示する
- まず `kubectl get pods -A` で全体像を見る

### ミス3: `exec` でその場しのぎ修正をする
コンテナ内で直接いじると、再起動で消えたり再現不能になります。

**安全策:**
- 修正は manifest / image / config に戻す
- `exec` は観察中心で使う

### ミス4: Secret を雑に扱う
`env` や `cat` で中身を見て、そのまま共有・記録してしまう事故があります。

**安全策:**
- Secret 値を terminal にむやみに表示しない
- manifest に平文で埋めない
- 学習用でもダミー値を使う

### ミス5: いきなり delete/apply する
対象が広いと事故ります。

**安全策:**
- `kubectl diff -f ...` が使える場面では先に差分を見る
- `kubectl apply -f` の対象ディレクトリを確認する
- `kubectl delete` 実行前に対象名を声に出して確認するくらいでちょうどいい

### ミス6: ログだけで判断し切る
ログに出ない問題もあります。

**安全策:**
次の順で見る癖をつける:
1. `get`
2. `describe`
3. `logs`
4. 必要なら `exec`

---

## 7) 面接っぽい質問
**質問:**  
Pod が `Running` なのにアプリにアクセスできない場合、`kubectl` を使ってどんな順序で切り分けますか？

**考えたい観点:**
- Pod の READY は通っているか
- Service の selector は合っているか
- endpoints は作られているか
- logs / describe に異常はないか
- readiness probe 失敗でトラフィック対象から外れていないか

---

## 8) 次の一歩（公式ドキュメント中心）

### まず読む
- Overview: Kubernetes とは  
  https://kubernetes.io/docs/concepts/overview/
- Pods  
  https://kubernetes.io/docs/concepts/workloads/pods/
- Deployments  
  https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Services  
  https://kubernetes.io/docs/concepts/services-networking/service/

### kubectl 基本
- kubectl Cheat Sheet  
  https://kubernetes.io/docs/reference/kubectl/cheatsheet/
- Debug running Pods  
  https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/

### 設定と安全性
- Secrets  
  https://kubernetes.io/docs/concepts/configuration/secret/
- Configure Liveness, Readiness and Startup Probes  
  https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/
- Good practices for Kubernetes Secrets  
  https://kubernetes.io/docs/concepts/security/secrets-good-practices/

---

## 9) 次号予告
**Middle 予告:**  
`kubectl apply` / `diff` / `rollout` / `scale` を使って、アプリ更新を安全に進める

**Middle の前提知識:**
- Pod / Deployment / Service の基本がわかる
- `kubectl get` / `describe` / `logs` の基本操作ができる
- namespace と context の違いを理解している

その次の **Advanced** では、`kubectl debug`、resource requests/limits、probe、障害切り分けの精度を上げる流れに進むのがおすすめです。
