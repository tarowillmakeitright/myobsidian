---
tags:
  - kubernetes
  - k8s
  - devops
  - learning
  - daily
---

[[Home]]

# 2026-06-17 09:25 Kubernetes Commands Magazine

## 今日のテーマ + レベル
**テーマ:** `kubectl apply` / `kubectl rollout` / `kubectl scale` / `kubectl expose` を使って、アプリ更新と公開の基本を安全に回す  
**レベル:** **Middle**

### 前提知識
- `kubectl get / describe / logs` を使って Pod の状態を読める
- Pod / Deployment / Service の役割をざっくり理解している
- kubeconfig の context と namespace を確認する習慣がある

---

## 1) なぜ実アプリ開発で重要なのか
アプリ開発では、**コードを書くこと**と同じくらい、**安全にデプロイして公開し、問題があれば戻せること**が重要です。

Kubernetes では次の流れが日常業務になります。

- 新しいイメージでアプリを更新する
- レプリカ数を増減して負荷に合わせる
- Service 経由でアプリをクラスタ内外に公開する
- デプロイ後に rollout 状態を確認する
- 不具合が出たら rollout を止める・戻す

つまり今日のテーマは、**「作ったアプリを壊さずに届ける」ための基本操作**です。  
ローカル開発だけでは見えにくい、**運用に耐えるリリースの作法**に直結します。

---

## 2) コアとなる kubectl / Kubernetes 概念

### Deployment
Deployment は、アプリの **望ましい状態** を宣言するリソースです。

たとえば:
- レプリカ数は 3
- このコンテナイメージを使う
- ラベルは `app=web`

Kubernetes はその宣言に合わせて ReplicaSet / Pod を管理します。

### apply
`kubectl apply -f ...` は、マニフェストに書かれた望ましい状態をクラスタに反映します。

```bash
kubectl apply -f deployment.yaml
```

ポイント:
- **宣言的** に管理できる
- 同じマニフェストを何度適用しても扱いやすい
- Git 管理と相性がいい

### rollout
Deployment 更新時、Kubernetes は Pod を順次入れ替えます。これが rollout です。

主な確認コマンド:

```bash
kubectl rollout status deployment/web
kubectl rollout history deployment/web
kubectl rollout undo deployment/web
```

### scale
負荷や検証目的でレプリカ数を増減できます。

```bash
kubectl scale deployment/web --replicas=3
```

### Service
Service は、変動する Pod 群に対して **安定したアクセス先** を提供します。

よく使う種類:
- `ClusterIP`: クラスタ内通信用
- `NodePort`: ノード経由で公開
- `LoadBalancer`: クラウドの LB と連携して外部公開

### expose
既存の Deployment や Pod から Service を作る簡易コマンドです。

```bash
kubectl expose deployment web --port=80 --target-port=8080 --type=ClusterIP
```

ただし本番では、**CLI 一発よりも manifest で管理する方が安全**です。

---

## 3) アプリ開発で Kubernetes はどう使われるか
kubernetes.io のベストプラクティスに沿うと、アプリ開発では次の考え方が重要です。

### 3-1. マニフェストを Git で管理する
- `kubectl apply` を手入力連打するより、YAML をレビュー可能な形で持つ
- 誰が何を変えたか追跡しやすい
- CI/CD に乗せやすい

### 3-2. Pod を直接運用しない
- 単体 Pod ではなく Deployment を使う
- 自己修復・更新・スケールの恩恵を受けられる

### 3-3. Service で疎結合にする
- Pod IP は変わる前提
- アプリ同士は Service 名でつなぐ
- フロントエンド → API → DB という構成で安定した接続点になる

### 3-4. 段階的 rollout を前提にする
- 一気に全部差し替えるより、RollingUpdate で徐々に更新する
- `rollout status` を見ながら安全に進める
- 問題があれば `rollout undo` を使う

### 3-5. Secret を manifest に直書きしない
- API key、DB パスワード、トークンを平文で Git に置かない
- Secret を使っても、**値の取り扱い**は別途厳格にする
- 学習中でも「あとで直す」は危険な習慣

---

## 4) 30〜60分ミニラボ
**目的:** Deployment を作成し、Service で公開し、rollout と scale を安全に体験する

### 想定環境
- `minikube` または `kind`
- `kubectl` 利用可能

### Step 0: 事故防止チェック
最初に必ず context / namespace を確認します。

```bash
kubectl config current-context
kubectl get ns
```

必要なら専用 namespace を作ります。

```bash
kubectl create namespace magazine-lab
kubectl config set-context --current --namespace=magazine-lab
```

### Step 1: Deployment manifest を作る
`web-deployment.yaml` を作成:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
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
          image: nginx:1.27
          ports:
            - containerPort: 80
```

適用:

```bash
kubectl apply -f web-deployment.yaml
kubectl get deployments,pods
```

### Step 2: Service を作る
まずは manifest で作る方法。

`web-service.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web
spec:
  selector:
    app: web
  ports:
    - port: 80
      targetPort: 80
  type: ClusterIP
```

適用:

```bash
kubectl apply -f web-service.yaml
kubectl get svc
```

### Step 3: 動作確認
Service と Endpoint を確認:

```bash
kubectl describe svc web
kubectl get endpoints web
```

minikube を使っているなら一時的にアクセス確認:

```bash
minikube service web --url
```

### Step 4: scale を試す

```bash
kubectl scale deployment/web --replicas=4
kubectl get pods -w
```

別ターミナルで:

```bash
kubectl get deployment web
```

観察ポイント:
- desired / current / available の違い
- Pod 名が増えること
- Service 側はそのままで裏側だけ増えること

### Step 5: イメージ更新で rollout を試す
nginx バージョンを更新:

```bash
kubectl set image deployment/web web=nginx:1.27.1
kubectl rollout status deployment/web
kubectl rollout history deployment/web
```

観察ポイント:
- Pod が段階的に入れ替わる
- Service 名は変わらない
- ユーザー視点では継続提供される設計になっている

### Step 6: rollback を試す

```bash
kubectl rollout undo deployment/web
kubectl rollout status deployment/web
kubectl rollout history deployment/web
```

### Step 7: 後片付け
**削除前に context / namespace を再確認。**

```bash
kubectl config current-context
kubectl delete namespace magazine-lab
```

> 注意: `kubectl delete` は破壊的です。共有クラスタ・本番クラスタでは、対象 namespace と context を声に出して確認するくらいでちょうどいいです。

---

## 5) コマンド cheatsheet

### 状態確認
```bash
kubectl get deployments
kubectl get pods
kubectl get svc
kubectl get endpoints
kubectl describe deployment web
kubectl describe svc web
```

### 適用
```bash
kubectl apply -f web-deployment.yaml
kubectl apply -f web-service.yaml
```

### スケール
```bash
kubectl scale deployment/web --replicas=3
```

### イメージ更新
```bash
kubectl set image deployment/web web=nginx:1.27.1
```

### rollout 確認・履歴・戻し
```bash
kubectl rollout status deployment/web
kubectl rollout history deployment/web
kubectl rollout undo deployment/web
```

### Service 作成（簡易）
```bash
kubectl expose deployment web --port=80 --target-port=80 --type=ClusterIP
```

### 安全確認
```bash
kubectl config current-context
kubectl get ns
kubectl get all -n magazine-lab
```

---

## 6) よくあるミスと安全策

### ミス1: 間違った context に apply / delete する
**危険:** 学習用のつもりで本番クラスタに反映してしまう。  
**安全策:**
- `kubectl config current-context` を毎回確認
- namespace を固定してから作業
- 破壊的操作前は 2 回確認

### ミス2: `default` namespace を雑に使い続ける
**危険:** 何がどこにあるか分からなくなる。  
**安全策:**
- 学習用 namespace を分ける
- アプリ単位・環境単位で整理する

### ミス3: Pod を直接作って運用しようとする
**危険:** 再作成や更新の管理が雑になる。  
**安全策:**
- 継続運用するアプリは Deployment を使う

### ミス4: Secret を YAML に平文で書く
**危険:** Git や画面共有で漏えいしやすい。  
**安全策:**
- 学習用でも実データを入れない
- Secret 管理は別レイヤーも含めて考える
- `.env` 感覚で雑に扱わない

### ミス5: `kubectl expose` を本番設計の代わりに使う
**危険:** その場しのぎで設定が再現不能になる。  
**安全策:**
- 本番相当では manifest を残す
- CLI は検証、YAML は再現性のため

### ミス6: rollout 完了前に「デプロイ成功」と判断する
**危険:** 一部 Pod だけ更新失敗しているのを見落とす。  
**安全策:**
- `kubectl rollout status` を必ず確認
- 必要なら `describe` と `logs` も見る

---

## 7) 面接っぽい一問
**質問:**  なぜ Kubernetes では Pod に直接アクセスするのではなく、Service を経由してアプリ同士を接続することが多いのですか？

**考えるポイント:**
- Pod IP は不変か？
- レプリカ数が増減したらどうなるか？
- ロードバランシングや名前解決に何が必要か？

---

## 8) 次の一歩リソース
できるだけ公式ドキュメント中心で。

- Kubernetes Concepts Overview  
  https://kubernetes.io/docs/concepts/overview/

- Deployments  
  https://kubernetes.io/docs/concepts/workloads/controllers/deployment/

- Services, Load Balancing, and Networking  
  https://kubernetes.io/docs/concepts/services-networking/service/

- kubectl Quick Reference  
  https://kubernetes.io/docs/reference/kubectl/quick-reference/

- Update API Objects in Place Using kubectl patch  
  https://kubernetes.io/docs/tasks/manage-kubernetes-objects/update-api-object-kubectl-patch/

- Debug Services  
  https://kubernetes.io/docs/tasks/debug/debug-application/debug-service/

---

## 9) 今日のまとめ
今日は、**Kubernetes 上でアプリを安全に更新・公開する基本操作**を扱いました。

覚えておきたい流れはこれです。

1. context / namespace を確認する  
2. Deployment を manifest で apply する  
3. Service で安定した入口を作る  
4. scale でレプリカを調整する  
5. rollout status で更新を確認する  
6. 問題があれば undo する  

**「とりあえず apply」ではなく、`どこへ・何を・どう戻せるか` を意識する**のが、実務で強い Kubernetes の使い方です。

---

**Tags:** #kubernetes #k8s #devops #learning #daily
