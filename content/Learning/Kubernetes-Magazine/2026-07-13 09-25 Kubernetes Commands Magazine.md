---
tags:
  - kubernetes
  - k8s
  - devops
  - learning
  - daily
---

[[Home]]

# Kubernetes Commands Magazine — 2026-07-13

## 今日のテーマ + レベル
**テーマ:** `kubectl apply` と `kubectl rollout` を使った安全なデプロイ更新
**レベル:** Beginner

> 次の学習弧:
> - **Middle 予告:** Deployment の戦略更新と readiness/liveness probe
> - **Advanced 予告:** Progressive Delivery の考え方と rollout undo / canary 的運用

---

## 1) なぜ実アプリ開発で重要か
アプリ開発では、コードを書くだけでなく、**安全に新バージョンを出すこと**が極めて重要です。Kubernetes の Deployment は、アプリの Pod を望ましい状態に保ちつつ、段階的に更新できます。

`kubectl apply` と `kubectl rollout` を理解すると、次のような現場タスクに直結します。

- 新しい API サーバーのバージョンを安全に反映する
- デプロイ後に問題が出たとき、状態を確認する
- rollout の失敗を早く検知する
- 無闇な再作成ではなく、Kubernetes の宣言的管理に沿って運用する

つまり、**「アプリを動かす」から「壊さずに更新する」へ進む最初の一歩**です。

---

## 2) Core kubectl / Kubernetes 概念

### `kubectl apply`
マニフェスト YAML に書かれた**望ましい状態**をクラスタに適用します。

- 命令的に 1 個ずつ操作するより、再現性が高い
- Git 管理しやすい
- Kubernetes のベストプラクティスである宣言的運用に近い

例:
```bash
kubectl apply -f deployment.yaml
```

### Deployment
Deployment は、Pod の数や更新方法を管理するリソースです。

主な役割:
- Pod の複製数を維持
- 新しいイメージへの更新を管理
- 問題時のロールバック支援

### Rollout
Deployment の更新進行状況を確認する仕組みです。

よく使うコマンド:
```bash
kubectl rollout status deployment/myapp
kubectl rollout history deployment/myapp
kubectl rollout undo deployment/myapp
```

### ReplicaSet
Deployment の裏で実際に世代管理される単位です。通常は直接触るより、Deployment 経由で扱います。

---

## 3) アプリ開発中に Kubernetes がどう使われるか
kubernetes.io/docs の考え方に沿うと、アプリ開発では次の流れが基本です。

1. アプリをコンテナ化する
2. Deployment で実行状態を定義する
3. Service でアクセス経路を定義する
4. 更新時は YAML を修正し `kubectl apply` する
5. `kubectl rollout status` で安全に更新確認する

実務でのイメージ:
- 開発者が新バージョンのイメージを作る
- CI/CD または手元で Deployment の image を更新
- Kubernetes が段階的に Pod を差し替える
- readiness probe が通った Pod だけがトラフィックを受ける

この設計により、**アプリの停止時間を減らし、更新を観察可能にする**のが Kubernetes の強みです。

---

## 4) 30〜60分ミニラボ
**目的:** Deployment を apply し、イメージ更新と rollout 確認を体験する

### 前提
- `kubectl` が使える
- 作業対象クラスタの context を確認済み
- できればローカル検証用クラスタ（minikube, kind, Docker Desktop Kubernetes など）

### 重要な安全確認
本番クラスタでいきなり試さないでください。まず以下を確認:

```bash
kubectl config current-context
kubectl get ns
```

**破壊的操作や apply 対象の誤りは非常に多い事故です。**
- `kubectl apply -f .` は対象を広く取りすぎることがある
- `kubectl delete` 実行前は namespace / context を必ず再確認
- Secret を YAML に平文で書かない

### 手順1: Namespace を作る
```bash
kubectl create namespace magazine-lab
```

### 手順2: Deployment マニフェストを作る
`deployment.yaml`

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
          image: nginx:1.25
          ports:
            - containerPort: 80
```

適用:
```bash
kubectl apply -f deployment.yaml
```

### 手順3: 状態確認
```bash
kubectl get deployments -n magazine-lab
kubectl get pods -n magazine-lab
kubectl rollout status deployment/web-demo -n magazine-lab
```

見るポイント:
- replicas が 2/2 になっているか
- Pod が Running か
- rollout completed successfully が出るか

### 手順4: イメージ更新
より新しい nginx タグへ変更します。

```bash
kubectl set image deployment/web-demo nginx=nginx:1.27 -n magazine-lab
kubectl rollout status deployment/web-demo -n magazine-lab
```

### 手順5: 変更履歴確認
```bash
kubectl rollout history deployment/web-demo -n magazine-lab
kubectl describe deployment web-demo -n magazine-lab
```

### 手順6: 問題がある想定でロールバック確認
実際に壊れたイメージを使わなくても、コマンド確認だけしておくと良いです。

```bash
kubectl rollout undo deployment/web-demo -n magazine-lab
kubectl rollout status deployment/web-demo -n magazine-lab
```

### 手順7: 後片付け
**削除前に context / namespace を必ず再確認。**

```bash
kubectl config current-context
kubectl delete namespace magazine-lab
```

---

## 5) コマンド・チートシート

### 基本確認
```bash
kubectl config current-context
kubectl get ns
kubectl get deploy -A
kubectl get pods -n magazine-lab
```

### apply / 更新
```bash
kubectl apply -f deployment.yaml
kubectl set image deployment/web-demo nginx=nginx:1.27 -n magazine-lab
```

### rollout 確認
```bash
kubectl rollout status deployment/web-demo -n magazine-lab
kubectl rollout history deployment/web-demo -n magazine-lab
kubectl rollout undo deployment/web-demo -n magazine-lab
```

### 詳細確認
```bash
kubectl describe deployment web-demo -n magazine-lab
kubectl logs -n magazine-lab <pod-name>
kubectl get events -n magazine-lab --sort-by=.metadata.creationTimestamp
```

---

## 6) よくあるミスと安全な運用

### よくあるミス
1. **context を確認せず apply / delete する**
   - ローカルのつもりが本番だった、は定番事故です。

2. **namespace を省略して別環境に適用する**
   - `default` namespace に意図せず作られることがあります。

3. **`kubectl apply -f .` で範囲を誤る**
   - 想定外の YAML まで適用する危険があります。

4. **Secret を Git 管理の YAML に平文で置く**
   - 絶対に避けるべきです。Secret 管理は別手段を検討しましょう。

5. **rollout を見ずに「適用できたからOK」と判断する**
   - apply 成功 ≠ アプリが正常稼働、です。

### 安全な実務プラクティス
- `kubectl config current-context` を毎回見る
- namespace を明示する
- まず `get`, `describe`, `rollout status` で観察する
- Secret は外部 Secret 管理や安全な仕組みを使う
- 本番前に小さな検証環境で試す
- YAML を Git 管理し、変更理由を残す

---

## 7) 面接っぽい一問
**質問:** `kubectl apply` と `kubectl create` の違いは何ですか？また、継続運用で `apply` がよく使われる理由は？

**考えるポイント:**
- 宣言的 vs 命令的
- 再適用のしやすさ
- GitOps / 構成管理との相性

---

## 8) 次のステップ資料
まずは公式ドキュメント優先で読むのがおすすめです。

- Kubernetes Documentation ホーム  
  https://kubernetes.io/docs/

- Deployment 概要  
  https://kubernetes.io/docs/concepts/workloads/controllers/deployment/

- kubectl Overview  
  https://kubernetes.io/docs/reference/kubectl/

- Perform a Rolling Update Using a Deployment  
  https://kubernetes.io/docs/tutorials/kubernetes-basics/update/update-intro/

- Configuration Best Practices  
  https://kubernetes.io/docs/concepts/configuration/overview/

- Secret の扱い  
  https://kubernetes.io/docs/concepts/configuration/secret/

---

## 9) 次号予告（Middle）
**テーマ案:** readinessProbe / livenessProbe と RollingUpdate 戦略

### Middle の前提知識
- Deployment を作成・更新できる
- Pod / Service / namespace の基本が分かる
- `kubectl get`, `describe`, `logs`, `rollout status` を使ったことがある

次号では、**「起動しただけではトラフィックを流してはいけない」**という実務感覚に踏み込みます。ここを理解すると、Kubernetes を単なる実行基盤ではなく、**安全なアプリ運用基盤**として使えるようになります。
