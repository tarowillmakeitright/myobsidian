---
tags:
  - kubernetes
  - k8s
  - devops
  - learning
  - daily
links:
  - "[[Home]]"
---

# 2026-06-23 Kubernetes Commands Magazine

#kubernetes #k8s #devops #learning #daily
[[Home]]

---

## 今回のテーマ + レベル

**テーマ:** `kubectl apply` と Declarative 管理で始める安全な Deployment 運用  
**学習アーク:** Beginner → Middle → Advanced

- **Beginner:** Deployment と Pod の基本、`kubectl apply/get/describe/logs` を安全に使う
- **Middle:** ReplicaSet・rolling update・readinessProbe を理解して、壊さず更新する
  - **前提知識:** Pod / Deployment / YAML / `kubectl get` と `kubectl apply` の基本
- **Advanced:** namespace・context・差分確認・段階的変更を組み合わせた本番寄り運用
  - **前提知識:** Deployment 更新、Service の基本、probe、namespace、kubectl の基本操作

---

## 1) なぜ重要か（実アプリ開発とのつながり）

アプリ開発では、コードを書くだけでは終わりません。実際には次のような運用が毎日発生します。

- 新しいバージョンを安全にデプロイする
- 何台のアプリを動かすかを調整する
- 落ちた Pod を確認する
- 更新後に不具合が出ていないかを確かめる
- ステージングと本番で同じ考え方で運用する

`kubectl apply` を中心にした **Declarative（宣言的）な管理** は、アプリを「どう作るか」ではなく「どうあるべきか」を YAML で表現します。これはチーム開発・レビュー・再現性・CI/CD と非常に相性がよく、kubernetes.io のベストプラクティスにも沿ったやり方です。

つまり、Kubernetes を学ぶとは「クラスタ操作」だけでなく、**安全にアプリを継続リリースする筋力をつけること**です。

---

## 2) コア kubectl / Kubernetes 概念

### Beginner: 最低限ここだけ

#### Pod
- コンテナを動かす最小単位
- ただし、通常は Pod を直接作るより **Deployment** 経由で管理することが多い

#### Deployment
- アプリの望ましい状態を管理するリソース
- 例: 「nginx を 2 台、常に動かしておく」
- Pod が壊れても再作成される

#### `kubectl apply -f`
- YAML に書かれた「望ましい状態」をクラスタに適用する
- 手作業の `kubectl run` より再現性が高い
- Git 管理しやすい

#### `kubectl get`
- 今どうなっているかを見る
- 例: `kubectl get pods`, `kubectl get deploy`

#### `kubectl describe`
- 状態の詳細、イベント、失敗理由を見る
- トラブル時の基本コマンド

#### `kubectl logs`
- コンテナログを見る
- アプリが起動しない時の最初の確認先

### Middle: 更新と可用性

#### ReplicaSet
- Deployment の裏側で Pod 数を維持する仕組み
- 通常は Deployment を操作し、ReplicaSet は理解対象

#### Rolling Update
- 全停止せず、少しずつ新バージョンへ置き換える更新方式
- 実サービスで必須の考え方

#### readinessProbe
- 「この Pod はリクエストを受けてよいか？」を判定
- 起動直後でも準備できるまで Service 配下に入れない
- 安全なリリースの要

#### `kubectl rollout status`
- デプロイ更新の進行を確認
- 成功/停止を見届ける基本コマンド

#### `kubectl rollout undo`
- 更新失敗時にロールバックする
- 本番運用で非常に重要

### Advanced: 本番で事故らないための運用観点

#### namespace
- リソースを論理分離する仕組み
- dev / staging / prod を分ける基本

#### context
- どのクラスタに対して操作するか
- **一番危ない事故ポイントの一つ**
- apply や delete の前に毎回確認したい

#### `kubectl diff`
- 適用前の差分確認
- 本番前の「本当にその変更でいいか？」を確認できる

#### label / selector
- Service や Deployment が Pod を見つけるための仕組み
- label 設計が雑だと、意図しない Pod を拾うことがある

---

## 3) アプリ開発中に Kubernetes がどう使われるか

kubernetes.io/docs の実践寄りの考え方に沿うと、典型的には次の流れになります。

1. **アプリをコンテナ化する**
   - 例: Node.js / Go / Python アプリをイメージ化

2. **Deployment で実行する**
   - レプリカ数、使用イメージ、ポート、probe を YAML に定義

3. **Service で安定したアクセス先を作る**
   - Pod が入れ替わっても、Service 経由で通信を安定化

4. **ConfigMap / Secret で設定を分離する**
   - アプリ設定や認証情報をイメージに焼き込まない
   - **Secret でも平文管理は避ける**。Git にそのまま置かない

5. **rollout で段階的更新する**
   - いきなり全停止ではなく、可用性を保って更新する

6. **logs / describe / events で原因調査する**
   - 起動失敗、probe 失敗、ImagePullBackOff などを確認

7. **本番前に diff/context/namespace を確認する**
   - 「どこに何を適用するか」を明確にする

ベストプラクティスとしては、以下が特に重要です。

- `apply` 中心で再現可能なマニフェスト管理をする
- 秘密情報をマニフェストに直接埋め込まない
- readiness/liveness probe を明確にする
- namespace と labels を整理する
- apply/delete 前に context を確認する

---

## 4) 30〜60分ミニラボ

**目的:** Deployment を YAML で作成し、安全に更新し、状態確認とロールバックまで体験する

### 想定環境
- ローカル Kubernetes（minikube, kind, Docker Desktop Kubernetes など）
- `kubectl` が利用可能

### 事前注意
- 既存クラスタで実行する場合は **namespace を分ける**
- `kubectl config current-context` を必ず確認
- 本番クラスタでは行わないこと

### 手順 1: 作業用 namespace を作る

```bash
kubectl create namespace k8s-magazine-lab
kubectl config set-context --current --namespace=k8s-magazine-lab
kubectl config current-context
kubectl get ns
```

### 手順 2: Deployment を作る

`deployment.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-demo
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
          readinessProbe:
            httpGet:
              path: /
              port: 80
            initialDelaySeconds: 3
            periodSeconds: 5
```

適用:

```bash
kubectl apply -f deployment.yaml
kubectl get deploy,pods,rs
kubectl rollout status deployment/web-demo
```

### 手順 3: 状態を詳しく見る

```bash
kubectl describe deployment web-demo
kubectl describe pod -l app=web-demo
kubectl logs -l app=web-demo --tail=50
```

### 手順 4: Service を作る

`service.yaml`

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-demo
spec:
  selector:
    app: web-demo
  ports:
    - port: 80
      targetPort: 80
```

```bash
kubectl apply -f service.yaml
kubectl get svc
kubectl get endpoints web-demo
```

### 手順 5: 安全に更新する

`deployment.yaml` の image を変更:

```yaml
image: nginx:1.27.1
```

差分確認してから適用:

```bash
kubectl diff -f deployment.yaml
kubectl apply -f deployment.yaml
kubectl rollout status deployment/web-demo
kubectl rollout history deployment/web-demo
```

### 手順 6: 意図的に失敗を観察する

イメージを存在しないタグに変える:

```yaml
image: nginx:does-not-exist
```

```bash
kubectl apply -f deployment.yaml
kubectl rollout status deployment/web-demo
kubectl get pods
kubectl describe pod -l app=web-demo
```

何が起きたか観察:
- ImagePullBackOff / ErrImagePull
- rollout が進まない
- describe の Events に原因が出る

### 手順 7: ロールバックする

```bash
kubectl rollout undo deployment/web-demo
kubectl rollout status deployment/web-demo
kubectl get pods
```

### 手順 8: 後片付け

**破壊的です。対象 namespace を必ず確認してから実行。**

```bash
kubectl config view --minify --output 'jsonpath={..namespace}'; echo
kubectl delete namespace k8s-magazine-lab
```

**所要時間目安:** 35〜50分

---

## 5) コマンド cheatsheet

### 状態確認

```bash
kubectl get pods
kubectl get deploy
kubectl get rs
kubectl get svc
kubectl get events --sort-by=.metadata.creationTimestamp
```

### 詳細確認

```bash
kubectl describe deployment web-demo
kubectl describe pod <pod-name>
kubectl logs <pod-name>
kubectl logs -l app=web-demo --tail=100
```

### 適用・差分

```bash
kubectl apply -f deployment.yaml
kubectl diff -f deployment.yaml
kubectl apply -f .
```

### rollout 関連

```bash
kubectl rollout status deployment/web-demo
kubectl rollout history deployment/web-demo
kubectl rollout undo deployment/web-demo
```

### namespace / context 安全確認

```bash
kubectl config current-context
kubectl config view --minify
kubectl get ns
kubectl config set-context --current --namespace=k8s-magazine-lab
```

### ラベルで絞る

```bash
kubectl get pods -l app=web-demo
kubectl describe pod -l app=web-demo
kubectl logs -l app=web-demo --tail=50
```

---

## 6) よくあるミスと安全策

### ミス1: 間違った context / cluster に apply する
**危険度:** 非常に高い

**安全策:**
- `kubectl config current-context` を毎回確認
- 本番・検証で context 名を明確に分ける
- 適用前に `kubectl diff -f ...` を習慣化

### ミス2: `kubectl apply -f .` で意図しない YAML まで適用する
**危険度:** 高い

**安全策:**
- ディレクトリ適用は中身を把握している時だけ
- 可能ならファイル単位で apply
- PR / Git 管理前提で変更範囲を明確にする

### ミス3: Secret を平文で Git に置く
**危険度:** 非常に高い

**安全策:**
- シークレット値をマニフェストへ直書きしない
- Secret 管理専用の仕組みを使う（例: 外部 secret manager、暗号化運用）
- 開発環境でも「どうせ dev だから」で油断しない

### ミス4: readinessProbe を入れずに更新する
**問題:** 起動直後の壊れた Pod にトラフィックが流れる

**安全策:**
- HTTP/TCP/command の readinessProbe を適切に設定
- rollout 後に status を確認する

### ミス5: `delete` の対象スコープを見誤る
**危険度:** 高い

**安全策:**
- `kubectl get ... -n <namespace>` で対象確認
- namespace 指定を明示する
- delete 前に resource 名・selector を再確認する

### ミス6: Pod を直接直して満足する
**問題:** 再作成で消える

**安全策:**
- Pod 単体ではなく Deployment / manifest を直す
- 変更は YAML に残す

---

## 7) 面接っぽい一問

**質問:**  
`kubectl apply` を使う declarative 運用は、`kubectl run` や手作業での変更に比べて何が優れているのでしょうか？ また、実運用で気をつけるべき点は何ですか？

**考えるポイント:**
- 再現性
- Git 管理との相性
- レビュー可能性
- drift（手作業差分）の抑制
- context / namespace ミス防止
- Secret の扱い

---

## 8) 次のステップ資料

できるだけ公式ドキュメント中心に進むのがおすすめです。

- Kubernetes Concepts Overview  
  https://kubernetes.io/docs/concepts/overview/

- Deployments  
  https://kubernetes.io/docs/concepts/workloads/controllers/deployment/

- Pods  
  https://kubernetes.io/docs/concepts/workloads/pods/

- Services  
  https://kubernetes.io/docs/concepts/services-networking/service/

- Labels and Selectors  
  https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/

- Probes (Liveness, Readiness, Startup)  
  https://kubernetes.io/docs/concepts/configuration/liveness-readiness-startup-probes/

- kubectl Quick Reference  
  https://kubernetes.io/docs/reference/kubectl/quick-reference/

- kubectl Cheat Sheet  
  https://kubernetes.io/docs/reference/kubectl/cheatsheet/

- Configuration Best Practices  
  https://kubernetes.io/docs/concepts/configuration/overview/

- Secrets  
  https://kubernetes.io/docs/concepts/configuration/secret/

---

## 9) 今日のまとめ

- Kubernetes 学習の軸は「安全にアプリをデプロイ・更新・観察すること」
- `kubectl apply` は再現性の高い declarative 運用の基本
- Deployment / Service / readinessProbe / rollout は実務で頻出
- 事故防止の要点は **context・namespace・diff・Secret 管理**
- まずは小さな lab で apply → observe → fail → rollback を一周するのが強い

---

## 次号の候補

- Beginner: ConfigMap と Secret の正しい分離
- Middle: Service と Ingress でアプリ公開を整理する
- Advanced: requests/limits と HPA の基礎で安定運用に近づく
