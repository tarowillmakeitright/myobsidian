---
tags:
  - kubernetes
  - k8s
  - devops
  - learning
  - daily
---

[[Home]]

# 2026-06-12 09:25 Kubernetes Commands Magazine

## 今日のテーマ
**ConfigMap と Secret を安全に使い分けながら、アプリ設定を Kubernetes に載せる**

Kubernetes を学ぶとき、最初は Pod や Deployment に目が行きがちですが、実務で詰まりやすいのは「設定をどう配るか」です。今日は **Beginner → Middle → Advanced** の流れで、`ConfigMap`、`Secret`、`env`、`volume mount`、`kubectl apply` の安全な使い方を固めます。

---

## 1) Topic + Level

### Beginner
**テーマ:** ConfigMap でアプリ設定を外出しする

### Middle
**テーマ:** Secret と ConfigMap を分離し、Deployment から安全に参照する

**前提知識:**
- Pod / Deployment / Service の基本を知っている
- `kubectl get`, `kubectl describe`, `kubectl logs` を触ったことがある
- YAML の基本的な見方がわかる

### Advanced
**テーマ:** 実運用を意識して、設定変更の反映方法・適用範囲・誤操作防止まで設計する

**前提知識:**
- ConfigMap / Secret の作成方法を理解している
- `kubectl apply -f` と namespace の概念を知っている
- アプリの再起動が設定反映に関係することを知っている

---

## 2) Why it matters for real app development

実アプリ開発では、コードと設定を分けるのが基本です。

たとえば以下は全部「設定」です。
- API のベース URL
- ログレベル
- 機能フラグ
- DB 接続先ホスト
- 外部サービスのタイムアウト
- 認証トークンやパスワード

これらをイメージの中に焼き込むと、環境ごとの差し替えがしづらくなります。Kubernetes では、

- **Secret ではない設定** → `ConfigMap`
- **機密情報** → `Secret`

として分離すると、開発・検証・本番で安全に運用しやすくなります。

特に実務では、次の事故がよく起きます。
- 本番 API キーを manifest にベタ書きして Git に入れる
- `kubectl apply -f .` で意図しないファイルまで適用する
- 別 namespace や別 context に apply してしまう
- ConfigMap を変えたのに Pod に反映されず混乱する

今日の内容は、こういう現場の事故を減らすための土台です。

---

## 3) Core kubectl / Kubernetes concept explanations

### ConfigMap
機密ではない設定値を保持する Kubernetes リソースです。

向いているもの:
- 環境変数
- アプリの設定ファイル
- フラグや接続先 URL

### Secret
機密情報を扱うためのリソースです。

向いているもの:
- API トークン
- パスワード
- 認証情報
- TLS 関連データ

**注意:** Secret は「暗号化された魔法の箱」ではありません。クラスタ設定次第では etcd 側の保護や RBAC、暗号化 at rest の有無が重要です。**「Git に平文で置かない」ための第一歩**として使う意識が大事です。

### Deployment
Pod を望ましい状態で管理するリソースです。アプリ更新や再作成を担当します。

### `kubectl apply`
宣言した YAML をクラスタへ適用します。

- 望ましい状態を反映する基本コマンド
- 便利だが、**適用対象の範囲を雑にすると危険**

### `env` と `volumeMount`
ConfigMap / Secret は主に次の2パターンでコンテナに渡します。

1. **環境変数として渡す**
   - シンプル
   - 12-factor app 的な構成に合いやすい
2. **ファイルとしてマウントする**
   - 設定ファイルをそのまま配りたいときに便利
   - アプリがファイル読込前提のときに向く

### namespace / context
- **namespace:** クラスタ内の論理的な分離単位
- **context:** `kubectl` が今どのクラスタ・認証情報・namespace に向いているか

本番事故の定番はこれです。
- 「開発環境のつもりで apply したら本番だった」

だから毎回、適用前に確認します。
- `kubectl config current-context`
- `kubectl get ns`
- `kubectl config view --minify`

---

## 4) How Kubernetes is used while building apps

Kubernetes 公式ドキュメントのベストプラクティス寄りに考えると、アプリ開発中はこんな流れになります。

1. **アプリ本体はコンテナイメージ化する**
2. **環境ごとの差分は ConfigMap / Secret に逃がす**
3. **Deployment から設定を参照する**
4. **namespace ごとに分離する**
5. **変更前に context / namespace / apply 対象を確認する**
6. **Secret を manifest に直書きしない運用を考える**
7. **設定変更後、アプリが再読込するか再起動が必要かを理解する**

実務で重要なのは、「Kubernetes に載せること」よりも、**安全に差分管理できること**です。

たとえば:
- 開発環境では `LOG_LEVEL=debug`
- 本番環境では `LOG_LEVEL=info`
- 開発用の API URL と本番用の API URL を分ける
- DB パスワードだけは Secret に入れる

この分離ができると、同じアプリイメージを複数環境へ持っていきやすくなります。

---

## 5) 30-60 minute hands-on mini lab

**目標:**
`ConfigMap` と `Secret` を使って、nginx Pod に設定を渡し、`kubectl` で安全に確認する。

**想定環境:**
- ローカル Kubernetes（minikube / kind / Docker Desktop Kubernetes など）
- namespace: `k8s-magazine-lab`

### Step 0: 事前の安全確認

```bash
kubectl config current-context
kubectl config view --minify --output 'jsonpath={..namespace}' ; echo
kubectl get ns
```

**チェックポイント:**
- いまどのクラスタに向いているか
- どの namespace を使うつもりか
- 本番クラスタではないこと

### Step 1: namespace を作る

```bash
kubectl create namespace k8s-magazine-lab
```

### Step 2: ConfigMap を作る

```bash
kubectl create configmap app-config \
  --from-literal=APP_MODE=learning \
  --from-literal=LOG_LEVEL=debug \
  -n k8s-magazine-lab
```

確認:

```bash
kubectl get configmap app-config -n k8s-magazine-lab -o yaml
```

### Step 3: Secret を作る

```bash
kubectl create secret generic app-secret \
  --from-literal=API_TOKEN='change-me-demo-token' \
  -n k8s-magazine-lab
```

確認:

```bash
kubectl get secret app-secret -n k8s-magazine-lab
```

**注意:** `-o yaml` や `-o json` で Secret を雑に表示すると、base64 化された値が見えてしまいます。学習中でも画面共有や履歴に残るので、むやみに表示しないほうが安全です。

### Step 4: Deployment manifest を作る

以下を `config-demo.yaml` として保存:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: config-demo
  namespace: k8s-magazine-lab
spec:
  replicas: 1
  selector:
    matchLabels:
      app: config-demo
  template:
    metadata:
      labels:
        app: config-demo
    spec:
      containers:
        - name: app
          image: nginx:1.27
          env:
            - name: APP_MODE
              valueFrom:
                configMapKeyRef:
                  name: app-config
                  key: APP_MODE
            - name: LOG_LEVEL
              valueFrom:
                configMapKeyRef:
                  name: app-config
                  key: LOG_LEVEL
            - name: API_TOKEN
              valueFrom:
                secretKeyRef:
                  name: app-secret
                  key: API_TOKEN
          ports:
            - containerPort: 80
```

### Step 5: apply 前に dry run 的に確認する

```bash
kubectl apply --dry-run=client -f config-demo.yaml
```

### Step 6: 適用する

```bash
kubectl apply -f config-demo.yaml
```

### Step 7: 状態確認

```bash
kubectl get pods -n k8s-magazine-lab
kubectl describe deployment config-demo -n k8s-magazine-lab
```

### Step 8: 環境変数が入っているか確認する

Pod 名を取得:

```bash
kubectl get pods -n k8s-magazine-lab
```

実際に中で確認:

```bash
kubectl exec -it deploy/config-demo -n k8s-magazine-lab -- /bin/sh
printenv | grep APP_MODE
printenv | grep LOG_LEVEL
exit
```

**重要:** `API_TOKEN` までむやみに `printenv` で確認しない癖をつけると安全です。見えた時点で漏えい面積が増えます。

### Step 9: ConfigMap を更新する

```bash
kubectl create configmap app-config \
  --from-literal=APP_MODE=learning \
  --from-literal=LOG_LEVEL=info \
  -n k8s-magazine-lab \
  --dry-run=client -o yaml | kubectl apply -f -
```

その後、Deployment の Pod が自動で設定再読込するとは限りません。今回のような環境変数方式では、**Pod 再作成が必要**です。

```bash
kubectl rollout restart deployment/config-demo -n k8s-magazine-lab
kubectl rollout status deployment/config-demo -n k8s-magazine-lab
```

### Step 10: 後片付け

**削除前に namespace を再確認すること。**

```bash
kubectl delete namespace k8s-magazine-lab
```

`delete namespace` は配下をまとめて消すので便利ですが、**対象 namespace を間違えると破壊的**です。実験用 namespace でのみ実施してください。

---

## 6) Command cheatsheet

### 状態確認

```bash
kubectl config current-context
kubectl config view --minify
kubectl get ns
kubectl get pods -n <namespace>
kubectl get deploy -n <namespace>
kubectl describe pod <pod-name> -n <namespace>
```

### ConfigMap / Secret

```bash
kubectl create configmap <name> --from-literal=KEY=VALUE -n <namespace>
kubectl create secret generic <name> --from-literal=KEY=VALUE -n <namespace>
kubectl get configmap <name> -n <namespace> -o yaml
kubectl get secret <name> -n <namespace>
```

### 適用・検証

```bash
kubectl apply --dry-run=client -f <file>
kubectl apply -f <file>
kubectl diff -f <file>
```

### 動作確認

```bash
kubectl logs deploy/<deployment-name> -n <namespace>
kubectl exec -it deploy/<deployment-name> -n <namespace> -- /bin/sh
kubectl rollout restart deployment/<deployment-name> -n <namespace>
kubectl rollout status deployment/<deployment-name> -n <namespace>
```

### 削除

```bash
kubectl delete -f <file>
kubectl delete namespace <namespace>
```

**警告:**
- `kubectl delete -f` は対象ファイルをよく確認してから実行
- `kubectl apply -f .` はディレクトリ内の意図しない manifest まで含むことがある
- `kubectl delete namespace` は非常に破壊的

---

## 7) Common mistakes and safe practices

### よくあるミス 1: Secret を Git に入れる
**問題:** manifest に平文のトークンやパスワードを書く

**安全策:**
- 学習段階でも「本物の秘密情報は置かない」
- 実務では external secret 管理や暗号化運用を検討する
- 少なくとも Git へ平文保存しない

### よくあるミス 2: context を見ずに apply
**問題:** 開発のつもりで本番へ適用

**安全策:**
- `kubectl config current-context` を毎回確認
- namespace を manifest に明示
- apply 前に `kubectl diff -f ...` や `--dry-run=client` を使う

### よくあるミス 3: ConfigMap 更新後に反映されない
**問題:** 「apply したのに変わらない」と混乱する

**安全策:**
- 環境変数注入なら Pod 再作成が必要なことを理解する
- `kubectl rollout restart` を使って意図的に更新する

### よくあるミス 4: Secret の中身を雑に表示する
**問題:** ターミナル履歴、画面共有、CI ログに残る

**安全策:**
- `kubectl get secret ... -o yaml` をむやみに使わない
- 必要最小限の確認だけ行う
- ログ・履歴・共有画面を意識する

### よくあるミス 5: まとめ apply / delete で事故る
**問題:** `kubectl apply -f .` や `kubectl delete -f .` で範囲誤認

**安全策:**
- ファイル単位で明示する
- namespace 単位の実験場を分ける
- 破壊的操作前は対象を声に出して確認したいレベルで慎重にする

---

## 8) One interview-style question

**質問:**
ConfigMap と Secret の違いは何ですか？ また、Deployment で環境変数として参照した値を更新したとき、なぜ Pod の再起動が必要になることがあるのでしょうか？

**考えるポイント:**
- どの情報をどちらに入れるべきか
- Secret は何を保証し、何を保証しないか
- コンテナ起動時に環境変数がどう注入されるか
- 実運用での安全な反映手順

---

## 9) Next-step resources

まずは公式を優先するのがいちばん堅いです。

- Kubernetes 公式ドキュメント: Concepts overview  
  https://kubernetes.io/docs/concepts/

- ConfigMap 公式  
  https://kubernetes.io/docs/concepts/configuration/configmap/

- Secret 公式  
  https://kubernetes.io/docs/concepts/configuration/secret/

- Configure all key-value pairs in a ConfigMap as container environment variables  
  https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/

- Distribute credentials securely using Secrets  
  https://kubernetes.io/docs/tasks/inject-data-application/distribute-credentials-secure/

- kubectl cheatsheet  
  https://kubernetes.io/docs/reference/kubectl/cheatsheet/

- Deployment 公式  
  https://kubernetes.io/docs/concepts/workloads/controllers/deployment/

- Good practices for Kubernetes Secrets  
  https://kubernetes.io/docs/concepts/security/secrets-good-practices/

---

## ひとこと

Kubernetes 学習では、派手なオーケストレーションより先に、**設定と秘密情報をちゃんと分ける癖**をつけるほうが実務価値が高いです。`kubectl` が打てるだけでは足りなくて、**どこに apply して、何が再起動されて、何が漏れうるか**まで見えてくると、かなり戦えるようになります。