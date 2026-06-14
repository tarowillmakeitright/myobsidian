---
tags:
  - kubernetes
  - k8s
  - devops
  - learning
  - daily
---

[[Home]]

# Kubernetes Commands Magazine — 2026-06-14

#kubernetes #k8s #devops #learning #daily

今日は **Beginner → Middle → Advanced** の流れで、実アプリにかなり効く **「設定・機密情報・ヘルスチェックを安全に扱う Kubernetes 基本動作」** を学ぶ。
前回が「安全にデプロイして更新する」寄りだったので、今日は **アプリを“ちゃんと運用できる形”に近づける** 方向に進める。

---

## 1) Topic + Level

### Topic
**ConfigMap / Secret / Probe を kubectl で扱い、アプリ設定をコードから分離しつつ安全に運用する**

### Level Arc
- **Beginner:** ConfigMap を使ってアプリ設定を Pod に渡す
- **Middle:** Secret を使って機密情報を分離し、`kubectl describe` `logs` で安全に確認する
- **Advanced:** readinessProbe / livenessProbe と Deployment 更新を組み合わせ、壊れたリリースを避ける

### Prerequisites
- **Middle の前提:**
  - Pod / Deployment / Service の役割を理解している
  - `kubectl get` `kubectl apply` `kubectl logs` を一通り使ったことがある
  - YAML マニフェストの基本構造が読める
- **Advanced の前提:**
  - ConfigMap と Secret の役割の違いを説明できる
  - rolling update の概念を知っている
  - Namespace と current-context を確認する習慣がある

---

## 2) Why it matters for real app development

実アプリ開発で Kubernetes を使うとき、最初につまずきやすいのは「コンテナは動いたけど、**設定変更・機密管理・障害時の扱い** が雑なまま」という状態。

ここが整っていないと、こんな問題が起きる。

- **設定がイメージに埋め込まれて再ビルドだらけになる**
- **API キーや DB パスワードをマニフェストや Git に平文で置いてしまう**
- **起動直後はまだ不安定なのにトラフィックを受けてエラーが出る**
- **落ちている Pod と、まだ準備中の Pod の区別がつかない**
- **障害調査で `describe` / `events` / `logs` を見ずに勘で再起動してしまう**

Kubernetes の強みは、単にアプリを置く場所ではなく、
**「設定を分離し、状態を観察し、壊れたものを切り離しながら継続的に更新する仕組み」** を作れること。

特にアプリ開発では次の価値が大きい。

- **環境差分を ConfigMap / Secret で分離できる**
- **コンテナイメージを同じまま dev / staging / prod に展開しやすい**
- **readinessProbe で“受け付け可能になってから”流量を載せられる**
- **livenessProbe でハングしたプロセスの復旧を自動化しやすい**
- **宣言的マニフェストでチーム共有しやすい**

ただし、便利さの裏で事故も起きやすい。
**Secret の露出、apply 先の context ミス、`kubectl delete` の対象ミス** は定番事故。
だから今日は「使える」だけでなく、**安全に使う習慣** をセットで身につける。

---

## 3) Core kubectl / Kubernetes concept explanations

### Beginner

#### ConfigMap
**機密ではない設定値** をコンテナの外に出すためのリソース。

たとえば:
- アプリの実行モード
- ログレベル
- API エンドポイント
- feature flag 的な設定

作成例:

```bash
kubectl create configmap web-config \
  --from-literal=APP_ENV=dev \
  --from-literal=LOG_LEVEL=debug \
  -n k8s-config-lab
```

確認:

```bash
kubectl get configmap -n k8s-config-lab
kubectl describe configmap web-config -n k8s-config-lab
```

Pod/Deployment からは主に次の 2 通りで使う。

- **環境変数として読む**
- **ファイルとしてマウントする**

アプリ開発ではまず環境変数として使う形がわかりやすい。

#### `kubectl apply -f`
Kubernetes は宣言的運用が基本。
ConfigMap や Deployment も YAML にして `apply` することで、状態を再現しやすくなる。

```bash
kubectl apply -f configmap.yaml
kubectl apply -f deployment.yaml
```

安全ポイント:
- 実行前に `kubectl config current-context` を確認する
- `-n` や `metadata.namespace` を明示する
- 可能なら `kubectl diff -f ...` を挟む

#### `kubectl describe`
動かなかったときにまず見るコマンド。

```bash
kubectl describe pod <pod-name> -n k8s-config-lab
kubectl describe deployment web -n k8s-config-lab
```

見どころ:
- Events
- Image pull エラー
- probe 失敗
- 環境変数や Volume 参照の問題

#### `kubectl logs`
アプリ側が「設定をどう受け取ったか」を見る。

```bash
kubectl logs deployment/web -n k8s-config-lab
kubectl logs -f pod/<pod-name> -n k8s-config-lab
```

アプリが環境変数を読めていないとき、まずログを見る癖はかなり大事。

---

### Middle

#### Secret
**機密情報を扱うための Kubernetes リソース。**

たとえば:
- DB パスワード
- API トークン
- 認証情報
- TLS 証明書

作成例:

```bash
kubectl create secret generic web-secret \
  --from-literal=API_TOKEN='replace-me' \
  -n k8s-config-lab
```

確認:

```bash
kubectl get secret -n k8s-config-lab
kubectl describe secret web-secret -n k8s-config-lab
```

重要な注意:
- **base64 は暗号化ではない**
- Secret は「平文よりマシ」だが万能ではない
- Git に生の Secret YAML をコミットしない
- 本番では RBAC、暗号化 at rest、外部 secret manager も検討する

#### ConfigMap と Secret の違い

- **ConfigMap:** 機密でない設定
- **Secret:** 機密情報

混ぜると事故る。
たとえば `DB_PASSWORD` を ConfigMap に入れるのはダメ寄り。

#### Environment Variables vs Volume Mount

Kubernetes の設定注入方法は大きく 2 つ。

- **環境変数**
  - アプリから読みやすい
  - 小さい設定に向く
- **Volume マウント**
  - 設定ファイルをそのまま渡したいときに便利
  - nginx.conf や app config file 向き

アプリ開発ではまず環境変数で理解し、その後ファイルマウントへ広げると整理しやすい。

#### Namespace を分ける意味
設定や Secret の実験は、とくに Namespace 分離が大事。

```bash
kubectl get all -n k8s-config-lab
kubectl get secret -n k8s-config-lab
```

`default` で何でも触るより、学習用 Namespace を作ったほうが安全。

---

### Advanced

#### readinessProbe
Pod が **「起動している」ではなく「リクエストを受けられる」** 状態かを判断する。

```yaml
readinessProbe:
  httpGet:
    path: /healthz
    port: 8080
  initialDelaySeconds: 3
  periodSeconds: 5
```

これがないと、起動直後でまだ初期化中のアプリにも Service が流量を送ってしまう。

#### livenessProbe
プロセスがハングしたときに再起動判断をする。

```yaml
livenessProbe:
  httpGet:
    path: /healthz
    port: 8080
  initialDelaySeconds: 10
  periodSeconds: 10
```

注意:
- 雑に設定すると、起動が遅いアプリを永遠に殺し続ける
- readiness と liveness の役割を分けて考える

#### `kubectl rollout status`
Probe と Deployment 更新はセットで見ると実務感が出る。

```bash
kubectl rollout status deployment/web -n k8s-config-lab
kubectl rollout history deployment/web -n k8s-config-lab
kubectl rollout undo deployment/web -n k8s-config-lab
```

新しい Pod が Ready にならなければ、更新が止まったり失敗が見えたりする。
このときに `describe` `logs` `events` を見るのが定石。

#### `kubectl diff`
設定差分を apply 前に確認できる。

```bash
kubectl diff -f deployment.yaml
```

Secret や Probe まわりは変更影響が見えづらいので、差分確認はかなり価値がある。

---

## 4) How Kubernetes is used while building apps

kubernetes.io/docs の考え方に寄せると、アプリ開発中の Kubernetes 活用はだいたいこうなる。

### 実践フロー
1. **アプリをコンテナ化する**
2. **Deployment で実行形を定義する**
3. **設定を ConfigMap、機密を Secret に分離する**
4. **Service で安定した接続先を作る**
5. **readiness/liveness probe を入れる**
6. **`kubectl get` `describe` `logs` `rollout` で観察しながら更新する**

### 実アプリ開発での具体例

#### 例1: Web API の環境差分
- dev では `LOG_LEVEL=debug`
- prod では `LOG_LEVEL=info`
- DB 接続先や feature flag は環境ごとに変える

このとき、**同じアプリイメージ** を使いながら設定だけ切り替えるのが理想。
その役割を ConfigMap / Secret が担う。

#### 例2: DB 接続情報の取り扱い
アプリコードに直接書いたり、Dockerfile に焼き込んだり、Git 管理の YAML に平文で入れたりすると危ない。
Kubernetes では Secret へ分離し、Pod に注入する方向が基本。

#### 例3: 起動に時間がかかるアプリ
Java/Spring 系、マイグレーション直後、キャッシュウォームアップあり、外部依存あり、などでは **起動完了前に流量が来ると失敗しやすい**。
readinessProbe があると、Kubernetes は準備できるまで Service の対象から外してくれる。

### 公式ベストプラクティスに沿う考え方

- **設定はコードから分離する**
- **機密は Secret とアクセス制御で守る**
- **latest タグではなく固定タグや digest を使う**
- **controller（Deployment）を中心に管理する**
- **probe を使って正常性を宣言する**
- **変更前に差分と対象 context を確認する**
- **必要以上に広い権限で作業しない**

### 避けたい例

```yaml
env:
  - name: DB_PASSWORD
    value: super-secret-password
  - name: LOG_LEVEL
    value: debug
image: myapp:latest
```

問題点:
- Secret が平文
- 設定変更のたびにマニフェストレビューが重くなる
- `latest` で再現性が下がる
- probe がなく、起動中か準備完了か区別しづらい

---

## 5) 30-60 minute hands-on mini lab

### ラボテーマ
**ConfigMap / Secret / Probe を使って、簡易 Web アプリを“運用を意識した形”で動かす**

### 所要時間
約 45〜60 分

### ゴール
- 学習用 Namespace を作る
- ConfigMap と Secret を作る
- Deployment に環境変数として注入する
- readinessProbe / livenessProbe を設定する
- `describe` `logs` `rollout` で状態確認する
- 安全な後片付けをする

### 前提
- ローカル Kubernetes 環境（kind / minikube / Docker Desktop Kubernetes など）
- `kubectl` が使えること
- **本番クラスタや共有クラスタではやらないこと**

### Step 0: まず安全確認

```bash
kubectl config current-context
kubectl config get-contexts
```

> 警告: apply / delete 系コマンドの前に、**今の context が学習用クラスタか必ず確認**すること。

### Step 1: Namespace を作る

```bash
kubectl create namespace k8s-config-lab
kubectl get ns
```

### Step 2: ConfigMap を作る

```bash
kubectl create configmap web-config \
  --from-literal=APP_ENV=dev \
  --from-literal=LOG_LEVEL=debug \
  -n k8s-config-lab
```

確認:

```bash
kubectl describe configmap web-config -n k8s-config-lab
```

### Step 3: Secret を作る

```bash
kubectl create secret generic web-secret \
  --from-literal=API_TOKEN='replace-me' \
  -n k8s-config-lab
```

確認:

```bash
kubectl describe secret web-secret -n k8s-config-lab
```

> 注意: 実環境では、ターミナル履歴や画面共有にも気をつける。長期的には secret manager 連携の方が安全。

### Step 4: Deployment マニフェストを作る

`deployment.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
  namespace: k8s-config-lab
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
        - name: web
          image: hashicorp/http-echo:1.0.0
          args:
            - "-text=hello from k8s"
          ports:
            - containerPort: 5678
          env:
            - name: APP_ENV
              valueFrom:
                configMapKeyRef:
                  name: web-config
                  key: APP_ENV
            - name: LOG_LEVEL
              valueFrom:
                configMapKeyRef:
                  name: web-config
                  key: LOG_LEVEL
            - name: API_TOKEN
              valueFrom:
                secretKeyRef:
                  name: web-secret
                  key: API_TOKEN
          readinessProbe:
            tcpSocket:
              port: 5678
            initialDelaySeconds: 3
            periodSeconds: 5
          livenessProbe:
            tcpSocket:
              port: 5678
            initialDelaySeconds: 10
            periodSeconds: 10
```

### Step 5: Service マニフェストを作る

`service.yaml`

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web
  namespace: k8s-config-lab
spec:
  selector:
    app: web
  ports:
    - port: 80
      targetPort: 5678
  type: ClusterIP
```

### Step 6: apply 前に差分確認（可能なら）

```bash
kubectl diff -f deployment.yaml
kubectl diff -f service.yaml
```

### Step 7: apply する

```bash
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
```

### Step 8: 状態を見る

```bash
kubectl get all -n k8s-config-lab
kubectl get pods -n k8s-config-lab -o wide
kubectl describe deployment web -n k8s-config-lab
kubectl rollout status deployment/web -n k8s-config-lab
```

### Step 9: アクセス確認

```bash
kubectl port-forward svc/web 8080:80 -n k8s-config-lab
```

別ターミナルで:

```bash
curl http://127.0.0.1:8080
```

### Step 10: ログ・イベントを確認する

```bash
kubectl logs deployment/web -n k8s-config-lab
kubectl get events -n k8s-config-lab --sort-by=.metadata.creationTimestamp
```

### Step 11: 設定変更を試す

たとえば ConfigMap を YAML 管理にして `LOG_LEVEL` を変える、あるいは Deployment の replicas を 3 にしてみる。
その後:

```bash
kubectl rollout status deployment/web -n k8s-config-lab
```

### Step 12: 後片付け

まず再確認:

```bash
kubectl config current-context
kubectl get all -n k8s-config-lab
```

削除:

```bash
kubectl delete namespace k8s-config-lab
```

> 警告: `kubectl delete namespace k8s-config-lab` は **その Namespace 配下をまとめて削除**する。名前と context を 2 回確認してから実行すること。

---

## 6) Command cheatsheet

### 安全確認

```bash
kubectl config current-context
kubectl config get-contexts
kubectl get ns
kubectl get all -n <namespace>
```

### ConfigMap / Secret

```bash
kubectl get configmap -n <namespace>
kubectl describe configmap <name> -n <namespace>
kubectl create configmap <name> --from-literal=KEY=VALUE -n <namespace>

kubectl get secret -n <namespace>
kubectl describe secret <name> -n <namespace>
kubectl create secret generic <name> --from-literal=KEY=VALUE -n <namespace>
```

### apply / diff / delete

```bash
kubectl diff -f deployment.yaml
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl delete -f deployment.yaml
kubectl delete namespace <namespace>
```

### 調査

```bash
kubectl get pods -n <namespace> -o wide
kubectl describe pod <pod-name> -n <namespace>
kubectl describe deployment <name> -n <namespace>
kubectl logs deployment/<name> -n <namespace>
kubectl get events -n <namespace> --sort-by=.metadata.creationTimestamp
```

### rollout / access

```bash
kubectl rollout status deployment/<name> -n <namespace>
kubectl rollout history deployment/<name> -n <namespace>
kubectl rollout undo deployment/<name> -n <namespace>
kubectl port-forward svc/<service-name> 8080:80 -n <namespace>
```

> 注意:
> - `kubectl apply -f .` はディレクトリ配下の全 YAML を対象にしうる
> - `kubectl delete -f .` も同じく危険
> - Secret 内容を不用意に画面共有・コピペしない

---

## 7) Common mistakes and safe practices

### よくあるミス

#### 1. Secret を平文でマニフェストに書く
悪い例:

```yaml
env:
  - name: API_TOKEN
    value: abc123-super-secret
```

問題:
- Git、PR、ターミナル履歴、録画、スクショで漏れやすい

安全策:
- Secret を使う
- 外部 secret manager を検討する
- base64 を暗号化と勘違いしない

#### 2. ConfigMap と Secret を混同する
問題:
- 機密と非機密の境界が崩れる

安全策:
- 「これは漏れてよい設定か？」で分類する
- パスワードやトークンは Secret 側へ寄せる

#### 3. readinessProbe と livenessProbe を同じノリで雑に置く
問題:
- 起動が遅いアプリを liveness が殺し続ける
- 本来は待つべき状態で再起動ループになる

安全策:
- まず readiness を理解する
- liveness はアプリ特性を見て慎重に入れる
- 初期遅延やタイムアウトを雑に決めない

#### 4. ログを見ずに再起動する
問題:
- 原因が消える
- 同じ障害を繰り返す

安全策:
- `describe` → `logs` → `events` の順で状況確認
- Pod 単位の対症療法より manifest の修正を優先

#### 5. current-context を確認せずに apply / delete する
危険例:

```bash
kubectl apply -f .
kubectl delete namespace prod
```

安全策:
- `kubectl config current-context` を毎回確認
- Namespace を明示する
- 破壊的操作は対象を二重確認する

#### 6. `latest` イメージタグに頼る
問題:
- 何が動いているかわからなくなる
- rollback しづらい

安全策:
- 明示タグや digest を使う

#### 7. Secret の存在だけで安心する
問題:
- 誰が読めるか、どこに残るか、監査できるかは別問題

安全策:
- RBAC
- encryption at rest
- external secret manager
- 必要最小権限

---

## 8) One interview-style question

**質問:**
ConfigMap と Secret の違いを説明したうえで、なぜアプリ設定をコンテナイメージに焼き込まず Kubernetes リソースとして分離するのが望ましいのか、さらに readinessProbe と livenessProbe がデプロイの安全性にどう影響するのかを説明してください。

**考えるポイント:**
- 環境差分の管理
- 機密情報の扱い
- 同じイメージを複数環境へ出す利点
- 「起動している」と「受け付け可能」の違い
- 誤った probe 設計のリスク

---

## 9) Next-step resources

公式ドキュメント中心で進むのが一番堅い。

- Kubernetes Documentation home
  - https://kubernetes.io/docs/
- Configuration best practices
  - https://kubernetes.io/docs/concepts/configuration/overview/
- ConfigMaps
  - https://kubernetes.io/docs/concepts/configuration/configmap/
- Secrets
  - https://kubernetes.io/docs/concepts/configuration/secret/
- Liveness, Readiness, Startup Probes
  - https://kubernetes.io/docs/concepts/configuration/liveness-readiness-startup-probes/
- Deployments
  - https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Service
  - https://kubernetes.io/docs/concepts/services-networking/service/
- Debug running pods
  - https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/
- Organizing cluster access using kubeconfig files
  - https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/
- Resource Management for Pods and Containers
  - https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/
- Good practices for Kubernetes Secrets
  - https://kubernetes.io/docs/concepts/security/secrets-good-practices/

---

## 今日のひとこと

Kubernetes で実アプリっぽさが出るのは、**Deployment を作れた瞬間** より、
**設定を分離し、機密を守り、準備完了してから流量を受ける** ように設計できた瞬間。

`get` `describe` `logs` `rollout` に加えて、**ConfigMap / Secret / Probe** を安全に扱えるようになると、一気に“使える Kubernetes”に近づく。