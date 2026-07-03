---
tags:
  - kubernetes
  - k8s
  - devops
  - learning
  - daily
---

[[Home]]

# 2026-07-03 09:25 Kubernetes Commands Magazine

## 今日のテーマ
**Topic:** はじめての `kubectl apply / get / describe / logs` で Web アプリのデプロイ状態を読む
**Level:** Beginner

> この号は Beginner 回です。次の学習弧として Middle → Advanced に進める前提知識も最後に明記します。

---

## 1) なぜ実アプリ開発で重要か

Kubernetes は「コンテナを動かす場所」ではなく、**アプリを継続的に安全運用するための実行基盤**です。

アプリ開発の現場では、コードを書くだけでは終わりません。

- デプロイ後に Pod が立ち上がらない
- 環境変数やイメージタグが違う
- Service 経由で通信できない
- 本番で再現しない不具合をログから追う

こういう場面で最初に使うのが `kubectl` です。特に `apply` `get` `describe` `logs` は、
**「作る」「見る」「原因を探る」** の最短ループを回すための基本セットです。

開発者がこの 4 つを雑に使うと、
- 間違った namespace に適用する
- 違う context のクラスタに反映する
- 広すぎる `kubectl delete` を打つ
- manifest に秘密情報を書いて Git に残す

といった事故が起きます。逆に、基礎を丁寧に固めると、ローカル検証・ステージング・本番のどこでも落ち着いて扱えるようになります。

---

## 2) コア概念: `kubectl` と Kubernetes の基本

### `kubectl apply`
YAML manifest をクラスタに反映するコマンドです。

```bash
kubectl apply -f deployment.yaml
```

意味としては「この宣言状態に近づけてください」です。手で Pod を直接いじるより、**manifest を source of truth にする**のが基本です。

### `kubectl get`
現在の状態を一覧で見ます。

```bash
kubectl get pods
kubectl get deployments
kubectl get svc
```

Kubernetes は宣言的ですが、実際に反映された状態を必ず確認する必要があります。

### `kubectl describe`
対象リソースの詳細を見ます。

```bash
kubectl describe pod <pod-name>
kubectl describe deployment <deployment-name>
```

イベント、スケジューリング失敗、イメージ取得失敗、probe 異常など、**トラブルの一次情報**が取れます。

### `kubectl logs`
コンテナの標準出力ログを見ます。

```bash
kubectl logs <pod-name>
kubectl logs <pod-name> -c <container-name>
```

アプリケーションエラー、起動失敗、設定不整合の確認に最重要です。

### 関連する Kubernetes リソース

#### Pod
コンテナ実行の最小単位。通常は直接 Pod を運用せず、Deployment 経由で扱います。

#### Deployment
アプリの desired state を管理します。
- レプリカ数
- 利用イメージ
- ローリングアップデート
- 再作成

#### Service
Pod の IP は変わるので、安定した到達先として Service を使います。

---

## 3) アプリ開発時にどう使うか

Kubernetes 公式ドキュメントの考え方に沿うと、開発中も次の流れが実践的です。

1. **manifest を Git 管理する**
2. **直接 Pod を作るより Deployment を使う**
3. **イメージタグを明示する**（`latest` 乱用を避ける）
4. **Namespace を明示する**
5. **Secret を平文で manifest に書かない**
6. **apply 前に context と対象範囲を確認する**

たとえば Web アプリを作るときは、

- アプリの Deployment を作る
- Service でアクセス経路を作る
- `kubectl get` で状態確認
- `kubectl describe` でイベント確認
- `kubectl logs` で起動ログ確認

というループを回します。

これは「Kubernetes を操作する」のではなく、
**アプリのリリース品質を上げるために Kubernetes を観測する**感覚に近いです。

---

## 4) 30–60 分ミニラボ

### ゴール
`nginx` を Deployment と Service で立ち上げ、`apply → get → describe → logs` を一通り体験する。

### 前提
- `kubectl` が使える
- テスト用クラスタがある（例: minikube, kind, Docker Desktop Kubernetes など）
- **本番クラスタではやらない**

### Step 0: 先に安全確認

```bash
kubectl config current-context
kubectl get ns
```

**必ず今の context を確認**してください。違うクラスタに apply する事故は本当に多いです。

必要なら専用 namespace を作ります。

```bash
kubectl create namespace magazine-lab
```

### Step 1: manifest を作る

`k8s-web.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-demo
  namespace: magazine-lab
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
          image: nginx:1.27.0
          ports:
            - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: web-demo
  namespace: magazine-lab
spec:
  selector:
    app: web-demo
  ports:
    - port: 80
      targetPort: 80
```

### Step 2: apply する

```bash
kubectl apply -f k8s-web.yaml
```

### Step 3: 状態を見る

```bash
kubectl get deployments -n magazine-lab
kubectl get pods -n magazine-lab
kubectl get svc -n magazine-lab
```

見るポイント:
- Deployment の `READY`
- Pod が `Running` になっているか
- Service に ClusterIP が付いているか

### Step 4: describe で詳細を見る

```bash
kubectl describe deployment web-demo -n magazine-lab
kubectl describe pods -n magazine-lab
```

見るポイント:
- Events に失敗がないか
- Image pull のエラーがないか
- ReplicaSet 作成状況

### Step 5: logs を確認する

Pod 名を取得してログを見る:

```bash
kubectl get pods -n magazine-lab
kubectl logs <pod-name> -n magazine-lab
```

`nginx` では大量のアプリログは出ませんが、**ログを取りに行く基本操作**の確認には十分です。

### Step 6: ポートフォワードでアクセスする

```bash
kubectl port-forward svc/web-demo 8080:80 -n magazine-lab
```

別ターミナルで:

```bash
curl http://127.0.0.1:8080
```

HTML が返れば成功です。

### Step 7: 軽い変更を反映する

replicas を `2` → `3` に変えて再度 apply:

```bash
kubectl apply -f k8s-web.yaml
kubectl get deployments -n magazine-lab
kubectl get pods -n magazine-lab
```

ここで「宣言を変えて apply すると状態が追従する」感覚を掴めます。

### Step 8: 後片付け

```bash
kubectl delete -f k8s-web.yaml
```

**注意:** `kubectl delete -f` でも、対象ファイルの中身と namespace を再確認してから実行してください。

---

## 5) コマンド・チートシート

### 基本確認

```bash
kubectl config current-context
kubectl get ns
kubectl get all -n magazine-lab
```

### 反映

```bash
kubectl apply -f k8s-web.yaml
kubectl apply -f ./manifests/
```

### 状態確認

```bash
kubectl get deployments -n magazine-lab
kubectl get pods -n magazine-lab -o wide
kubectl get svc -n magazine-lab
```

### 詳細確認

```bash
kubectl describe deployment web-demo -n magazine-lab
kubectl describe pod <pod-name> -n magazine-lab
```

### ログ

```bash
kubectl logs <pod-name> -n magazine-lab
kubectl logs -f <pod-name> -n magazine-lab
kubectl logs <pod-name> -c nginx -n magazine-lab
```

### 便利操作

```bash
kubectl port-forward svc/web-demo 8080:80 -n magazine-lab
kubectl rollout status deployment/web-demo -n magazine-lab
```

### 削除（慎重に）

```bash
kubectl delete -f k8s-web.yaml
kubectl delete deployment web-demo -n magazine-lab
kubectl delete service web-demo -n magazine-lab
```

---

## 6) よくあるミスと安全策

### ミス 1: 間違った context に apply する
**危険度:** 高い

**安全策:**
```bash
kubectl config current-context
```
を毎回確認。シェルプロンプトに context 表示を入れるのも有効です。

### ミス 2: namespace を省略して別環境に当てる
**危険度:** 高い

**安全策:**
- manifest に `metadata.namespace` を明示
- コマンドにも `-n` を付ける習慣を持つ

### ミス 3: `latest` タグを使う
**問題:** 何が動いているか分からなくなる

**安全策:**
- 固定タグを使う
- 理想は digest pinning まで進む

### ミス 4: Secret を manifest に直書きする
**危険度:** 高い

**安全策:**
- Git に API key やパスワードを入れない
- Secret 管理は専用フローを使う
- 少なくとも学習用でも「平文を残さない」癖をつける

### ミス 5: `kubectl delete` の対象を雑に指定する
**危険度:** 高い

特に危ない例:
```bash
kubectl delete pod --all -A
kubectl delete -f ./
```

**安全策:**
- 実行前に scope を声に出して確認する
- `-n <namespace>` を明示する
- `-f` の対象ディレクトリを広くしすぎない
- 本番ではレビュー済み manifest / GitOps フローを優先する

### ミス 6: `describe` を見ずに勘で直す
**問題:** 根本原因が見えない

**安全策:**
トラブル時はまず:
1. `get`
2. `describe`
3. `logs`
の順で事実を集める。

---

## 7) 面接っぽい質問

**Q. `kubectl get pod` と `kubectl describe pod` の違いを、実務での使い分けまで含めて説明してください。**

考え方の例:
- `get` は一覧・状態の俯瞰
- `describe` は詳細・イベント・失敗原因の確認
- まず `get` で異常対象を見つけ、次に `describe` で深掘る

---

## 8) Middle / Advanced へ進む前提知識

### 次の Middle で扱う予定
- readinessProbe / livenessProbe
- rolling update
- ConfigMap と Secret の分離
- `kubectl rollout` と障害時の切り戻し

**Prerequisites for Middle:**
- Deployment / Pod / Service の役割が分かる
- `kubectl apply/get/describe/logs` を迷わず使える
- namespace と context の事故がなぜ危険か説明できる

### さらに Advanced で扱う予定
- requests / limits
- HPA
- multi-container Pod の観測
- セキュアな manifest 運用
- 本番向けデバッグ手順

**Prerequisites for Advanced:**
- Probe と rollout の挙動を理解している
- ConfigMap / Secret の責務分離を説明できる
- 失敗時にイベント・ログ・更新履歴を追える

---

## 9) 次の一歩リソース

できるだけ公式を優先。

- Kubernetes Documentation ホーム  
  https://kubernetes.io/docs/home/

- Overview: Kubernetes Components  
  https://kubernetes.io/docs/concepts/overview/components/

- Workloads: Deployments  
  https://kubernetes.io/docs/concepts/workloads/controllers/deployment/

- Services, Load Balancing, and Networking  
  https://kubernetes.io/docs/concepts/services-networking/service/

- kubectl Overview  
  https://kubernetes.io/docs/reference/kubectl/

- Debug Pods and ReplicationControllers  
  https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/

- Configure Access to Multiple Clusters  
  https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/

---

## まとめ

今日の核はシンプルです。

- `apply` で宣言を反映する
- `get` で全体を見る
- `describe` でイベントを見る
- `logs` でアプリの事実を見る

Kubernetes 学習は、難しい抽象概念から入るより、
**「1つの Deployment を安全に観測できる」** ところから始めるのがいちばん強いです。

次号は Middle として、**probe と rollout を使って「動く」から「安全に更新できる」へ進む**構成がおすすめです。
