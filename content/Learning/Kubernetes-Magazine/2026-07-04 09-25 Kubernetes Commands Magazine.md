---
tags:
  - kubernetes
  - k8s
  - devops
  - learning
  - daily
---

[[Home]]

# 2026-07-04 09:25 Kubernetes Commands Magazine

## 1) Topic + Level
**Topic:** `readinessProbe` / `livenessProbe` と `kubectl rollout` で、安全にアプリを更新する
**Level:** Middle

> この号は Middle 回です。Beginner で扱った `kubectl apply / get / describe / logs` を使える前提で、
> **「動けばよい」から「安全に更新できる」へ進む** 学習弧です。

**Prerequisites for Middle:**
- Deployment / Pod / Service の役割を説明できる
- `kubectl apply`, `get`, `describe`, `logs` を基本操作として使える
- context / namespace を確認せずに apply すると危険だと理解している

**Preview of Advanced:**
次の段階では、`requests/limits`、HPA、Secret/ConfigMap の実運用、デバッグと安全な本番変更を扱うと流れがきれいです。

---

## 2) Why it matters for real app development

実アプリ開発では、デプロイできることよりも、**壊さずに更新できること** の方が重要です。

よくある失敗:

- アプリは起動したが、まだDB接続準備が終わっていないのにトラフィックが流れる
- 新バージョンへ更新したら、一部Podが壊れているのに気づかず配信してしまう
- ローリングアップデート中に異常が起きても、どこを見ればよいか分からない
- `kubectl apply -f .` を雑に打って、意図しないmanifestまで反映する

Kubernetes は、単にコンテナを再起動する仕組みではなく、
**「アプリが利用可能かどうか」を見ながら段階的に置き換えるための実行基盤**です。

その中核が以下です。

- `readinessProbe`: そのPodにトラフィックを流してよいか
- `livenessProbe`: そのコンテナは生きているか、再起動すべきか
- `kubectl rollout`: 更新がどう進んでいるか、止まっていないか、戻せるか

これは実務でいうと、
**障害を広げずにアプリをリリースするための最低限の安全装置**です。

---

## 3) Core kubectl / Kubernetes concepts

### `readinessProbe`
Pod が **通信受付可能になってから** Service の配信対象になるための判定です。

たとえばアプリが起動後に:
- マイグレーション待ち
- キャッシュ初期化
- 外部APIやDB接続待ち

の時間を必要とする場合、readiness がないと「起動しただけの未準備Pod」に通信が行ってしまいます。

readiness に失敗している間は、Pod は存在していてもトラフィックの行き先に入りません。

### `livenessProbe`
コンテナが**ハングしているかどうか**を検出し、必要なら再起動させます。

ただし乱暴に設定すると危険です。起動が遅いアプリに厳しすぎる probe を入れると、
**起動中に何度も kill される再起動ループ**を起こします。

### `startupProbe`（補足）
起動が遅いアプリでは、liveness の代わりに startupProbe も重要です。
今日のメインではありませんが、
**「起動時間が長いアプリに liveness だけ入れるのは危険」** は覚えておく価値があります。

### `kubectl rollout status`
Deployment の更新進行状況を確認します。

```bash
kubectl rollout status deployment/web-demo -n magazine-lab
```

ローリングアップデートが成功したか、待機中か、詰まっているかを見る第一歩です。

### `kubectl rollout history`
どの revision があるかを見ます。

```bash
kubectl rollout history deployment/web-demo -n magazine-lab
```

### `kubectl rollout undo`
更新に問題があったときに戻します。

```bash
kubectl rollout undo deployment/web-demo -n magazine-lab
```

**注意:** 戻す前に、今の context / namespace / 対象Deployment を必ず確認してください。
本番で別Deploymentへ undo すると、修復ではなく別事故になります。

### RollingUpdate
Deployment は通常、古いPodを一気に消すのではなく、少しずつ新しいPodへ入れ替えます。

関連する代表設定:
- `maxUnavailable`: 同時に落としてよい数
- `maxSurge`: 一時的に増やしてよい数

これにより「無停止に近い更新」を目指せます。

---

## 4) How Kubernetes is used while building apps

kubernetes.io/docs のベストプラクティスに沿って考えると、アプリ開発中のKubernetes利用は次のようになります。

1. **Deployment を通じて更新する**
   - Pod 単体を直接いじるより、Deployment を source of truth にする

2. **ヘルスチェックをアプリ設計に含める**
   - `/healthz` や `/ready` のようなエンドポイントを用意する
   - 「プロセスが起動した」ではなく「サービス可能か」を分けて考える

3. **小さく安全にリリースする**
   - いきなり大きな変更を apply しない
   - `rollout status` で毎回確認する

4. **manifest に秘密情報を直書きしない**
   - APIキーやDBパスワードを Git 管理のYAMLへ埋め込まない
   - Secret を使う場合も、平文の残り方に注意する

5. **操作対象の範囲を必ず明示する**
   - `-n <namespace>` を付ける
   - `kubectl config current-context` を確認する
   - `kubectl apply -f .` や `kubectl delete -f .` のような広い指定は慎重に扱う

開発者にとってKubernetesは「インフラ担当だけのもの」ではなく、
**アプリの起動条件・依存性・更新手順を明示する開発環境の一部**です。

---

## 5) 30–60 minute hands-on mini lab

### ゴール
- readiness / liveness を持つ Deployment を作る
- イメージ更新を rollout で追う
- 失敗時に `describe`, `logs`, `rollout history`, `rollout undo` を使う

### 前提
- `kubectl` が使える
- テスト用クラスタがある（kind / minikube / Docker Desktop Kubernetes など）
- **本番クラスタでは実施しない**

### Step 0: 安全確認

```bash
kubectl config current-context
kubectl get ns
```

必要なら専用 namespace を作る:

```bash
kubectl create namespace magazine-lab
```

### Step 1: Deployment と Service を作る

`web-probe.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-probe-demo
  namespace: magazine-lab
spec:
  replicas: 2
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 1
  selector:
    matchLabels:
      app: web-probe-demo
  template:
    metadata:
      labels:
        app: web-probe-demo
    spec:
      containers:
        - name: nginx
          image: nginx:1.27.0
          ports:
            - containerPort: 80
          readinessProbe:
            httpGet:
              path: /
              port: 80
            initialDelaySeconds: 3
            periodSeconds: 5
          livenessProbe:
            httpGet:
              path: /
              port: 80
            initialDelaySeconds: 10
            periodSeconds: 10
---
apiVersion: v1
kind: Service
metadata:
  name: web-probe-demo
  namespace: magazine-lab
spec:
  selector:
    app: web-probe-demo
  ports:
    - port: 80
      targetPort: 80
```

適用:

```bash
kubectl apply -f web-probe.yaml
```

### Step 2: 状態確認

```bash
kubectl get deployments -n magazine-lab
kubectl get pods -n magazine-lab
kubectl rollout status deployment/web-probe-demo -n magazine-lab
```

さらに詳細確認:

```bash
kubectl describe deployment web-probe-demo -n magazine-lab
kubectl describe pods -n magazine-lab
```

見るポイント:
- Pod が `Running` でも readiness が通るまで配信対象にならないこと
- Events に probe 関連エラーがないこと

### Step 3: アクセス確認

```bash
kubectl port-forward svc/web-probe-demo 8080:80 -n magazine-lab
```

別ターミナル:

```bash
curl http://127.0.0.1:8080
```

### Step 4: 安全な更新を体験する

manifest の `image` を `nginx:1.27.0` から `nginx:1.27.1` に変更し、再適用:

```bash
kubectl apply -f web-probe.yaml
kubectl rollout status deployment/web-probe-demo -n magazine-lab
kubectl get pods -n magazine-lab
```

更新中の履歴確認:

```bash
kubectl rollout history deployment/web-probe-demo -n magazine-lab
```

### Step 5: 軽い失敗シナリオを作る

学習用として、`readinessProbe` の path を `/does-not-exist` に変えて再適用します。

```bash
kubectl apply -f web-probe.yaml
kubectl get pods -n magazine-lab
kubectl describe pods -n magazine-lab
kubectl rollout status deployment/web-probe-demo -n magazine-lab
```

観察ポイント:
- Pod 自体は起動しても readiness が通らない
- rollout が完了しない、または期待通り進まない
- `describe` の Events に失敗理由が出る

必要に応じてログ確認:

```bash
kubectl logs <pod-name> -n magazine-lab
```

### Step 6: 戻す

まず本当に対象が正しいか確認:

```bash
kubectl config current-context
kubectl get deployment -n magazine-lab
```

そのうえでロールバック:

```bash
kubectl rollout undo deployment/web-probe-demo -n magazine-lab
kubectl rollout status deployment/web-probe-demo -n magazine-lab
```

### Step 7: 後片付け

```bash
kubectl delete -f web-probe.yaml
```

**警告:** `kubectl delete -f` はファイルの中身と namespace を確認してから実行してください。ディレクトリ単位の delete は特に危険です。

---

## 6) Command cheatsheet

### 安全確認

```bash
kubectl config current-context
kubectl get ns
kubectl get all -n magazine-lab
```

### 反映

```bash
kubectl apply -f web-probe.yaml
```

### 状態確認

```bash
kubectl get deployments -n magazine-lab
kubectl get pods -n magazine-lab -o wide
kubectl get svc -n magazine-lab
kubectl rollout status deployment/web-probe-demo -n magazine-lab
```

### 詳細確認

```bash
kubectl describe deployment web-probe-demo -n magazine-lab
kubectl describe pod <pod-name> -n magazine-lab
```

### 履歴とロールバック

```bash
kubectl rollout history deployment/web-probe-demo -n magazine-lab
kubectl rollout undo deployment/web-probe-demo -n magazine-lab
```

### ログとアクセス

```bash
kubectl logs <pod-name> -n magazine-lab
kubectl logs -f <pod-name> -n magazine-lab
kubectl port-forward svc/web-probe-demo 8080:80 -n magazine-lab
```

### 慎重に使うコマンド

```bash
kubectl delete -f web-probe.yaml
kubectl apply -f .
kubectl delete -f .
```

最後の2つは**スコープ事故の温床**になりやすいので、学習中でも常用しすぎない方が安全です。

---

## 7) Common mistakes and safe practices

### ミス 1: readiness と liveness を同じ感覚で設定する
**問題:** 未準備状態と障害状態を区別できない

**安全策:**
- readiness は「トラフィック受付可否」
- liveness は「再起動が必要な壊れ方か」

役割を分けて考える。

### ミス 2: 起動が遅いアプリに厳しい liveness を入れる
**問題:** CrashLoopBackOff 的な再起動ループを招く

**安全策:**
- `initialDelaySeconds` を現実に合わせる
- 必要なら `startupProbe` を検討する
- staging で先に検証する

### ミス 3: rollout を確認せず apply だけして終わる
**問題:** 更新失敗に気づくのが遅れる

**安全策:**
毎回少なくとも以下を見る:

```bash
kubectl rollout status deployment/<name> -n <namespace>
kubectl describe deployment <name> -n <namespace>
```

### ミス 4: probe 失敗時にログだけ見て終わる
**問題:** Kubernetes 側のイベントを見落とす

**安全策:**
トラブル時は順番を固定する:
1. `get`
2. `describe`
3. `logs`
4. `rollout history`

### ミス 5: Secret を manifest に直書きする
**危険度:** 高い

**安全策:**
- パスワード・APIキーをYAMLへ直接書かない
- Git に平文秘密情報を残さない
- 学習用サンプルでも本物の値は使わない

### ミス 6: destructive なコマンドの対象確認を省く
**危険度:** 非常に高い

危ない例:

```bash
kubectl delete deployment --all -A
kubectl delete -f ./
kubectl apply -f ./
```

**安全策:**
- `current-context` を確認する
- namespace を明示する
- 対象ファイル / ディレクトリの中身を把握する
- 本番ではレビュー済みmanifestやGitOpsフローを優先する

---

## 8) One interview-style question

**Q. `readinessProbe` と `livenessProbe` の違いを説明し、それぞれを誤設定するとどんな障害が起きるか話してください。**

答えるときの観点:
- readiness は配信対象に入れてよいか
- liveness は再起動が必要な壊れ方か
- readiness がないと未準備Podへ通信が流れる
- liveness が厳しすぎると再起動ループになりうる

---

## 9) Next-step resources

できるだけ公式ドキュメントを優先。

- Kubernetes Documentation Home  
  https://kubernetes.io/docs/home/

- Configure Liveness, Readiness and Startup Probes  
  https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/

- Deployments  
  https://kubernetes.io/docs/concepts/workloads/controllers/deployment/

- kubectl rollout  
  https://kubernetes.io/docs/reference/kubectl/generated/kubectl_rollout/

- Debug Running Pods  
  https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/

- Pod Lifecycle  
  https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/

- Secrets  
  https://kubernetes.io/docs/concepts/configuration/secret/

---

## まとめ

今日の要点は3つです。

- `readinessProbe` で **配信してよい状態** を表現する
- `livenessProbe` で **再起動すべき壊れ方** を検出する
- `kubectl rollout` で **更新が安全に進んでいるか** を観測する

Kubernetes の実務力は、難しい用語を知っていることより、
**更新時に何を見て、どこで止めて、どう戻すか** を落ち着いて実行できることに出ます。

次号を Advanced に進めるなら、`requests/limits` と HPA、さらに Secret/ConfigMap の安全運用へ進むのが自然です。
