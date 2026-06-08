---
tags:
  - kubernetes
  - k8s
  - devops
  - learning
  - daily
---

# 2026-06-08 Kubernetes Commands Magazine

[[Home]]

# Kubernetes Commands Magazine — 実践学習号

## 今号のテーマ
**Topic:** `kubectl get / describe / logs / exec` でアプリ障害を安全に切り分ける  
**Level:** Beginner

---

## 1) なぜ重要か — 実アプリ開発とのつながり
アプリを Kubernetes 上で動かし始めると、最初にぶつかるのは「動かない理由がわからない」問題です。コード自体は正しくても、Pod が起動しない、環境変数が足りない、Readiness Probe で落ちる、Service に疎通しない、といった原因はよくあります。

そのとき現場で最初に使うのが、次の基本コマンドです。

- `kubectl get`
- `kubectl describe`
- `kubectl logs`
- `kubectl exec`

これらは、**アプリを壊さずに状態確認するための最重要セット**です。  
特に本番や共有検証環境では、いきなり `delete` や広範囲な `apply` を打つより、まず観察することが安全です。

---

## 2) コア概念の解説

### `kubectl get`
Kubernetes リソースの一覧や現在状態を確認します。

例:
```bash
kubectl get pods
kubectl get deployments
kubectl get svc
kubectl get pods -A
```

使いどころ:
- Pod が `Running` か `CrashLoopBackOff` かをざっくり確認
- Deployment / Service / ConfigMap などが存在するか確認
- namespace をまたいだ全体把握

---

### `kubectl describe`
対象リソースの詳細情報とイベントを見ます。

例:
```bash
kubectl describe pod <pod-name>
kubectl describe deployment <deployment-name>
```

見えるもの:
- イメージ名
- 環境変数の参照元
- Probe 設定
- Volume マウント
- Events（ImagePullBackOff, FailedScheduling, probe failure など）

**障害調査ではかなり重要**です。`get` だけでは分からない原因がここに出ます。

---

### `kubectl logs`
コンテナの標準出力・標準エラー出力を確認します。

例:
```bash
kubectl logs <pod-name>
kubectl logs <pod-name> -c <container-name>
kubectl logs <pod-name> --previous
```

使いどころ:
- アプリ例外
- 起動時エラー
- DB 接続失敗
- 直前に再起動したコンテナのログ確認（`--previous`）

---

### `kubectl exec`
Pod 内コンテナでコマンドを実行します。

例:
```bash
kubectl exec -it <pod-name> -- sh
kubectl exec <pod-name> -- printenv
kubectl exec <pod-name> -- ls /app
```

使いどころ:
- 環境変数確認
- ファイル配置確認
- プロセス状態の確認
- DNS/HTTP 疎通確認（イメージにコマンドがある場合）

**ただし注意:** `exec` は便利ですが、本番での無秩序な操作は避けるべきです。状態変更よりも、まず読み取り系コマンドで観察するのが基本です。

---

## 3) アプリ開発で Kubernetes がどう使われるか
Kubernetes は、アプリを「ただ置く場所」ではなく、**望ましい状態を維持する実行基盤**です。

実開発でよくある流れ:
1. アプリをコンテナ化する
2. Deployment でレプリカ数や更新戦略を定義する
3. Service で通信経路を安定化する
4. ConfigMap / Secret で設定を外出しする
5. Probe で健全性を管理する
6. ログ・イベント・メトリクスで運用する

kubernetes.io/docs のベストプラクティスに沿うなら、次を意識すると堅いです。

- **宣言的管理**を優先する（`kubectl apply -f ...`）
- **namespace を分ける**（dev/staging/prod）
- **Secret を平文で manifest に埋めない**
- **最小権限**を意識する
- **本番前に dry-run / context 確認**をする
- **Probe と resource requests/limits** を適切に設定する

このあたりの前提があると、単なるコマンド暗記ではなく、実務に結びつきます。

---

## 4) 30〜60分ミニラボ
**ラボ名:** Nginx Pod を立てて、状態確認とトラブル調査の基本をやる  
**想定時間:** 30〜45分  
**Level:** Beginner

### 目的
- Pod / Deployment / Service の基本確認
- `get` / `describe` / `logs` / `exec` の役割理解
- 危険な破壊操作を避けながら観察する習慣づけ

### 前提
- `kubectl` が使える
- ローカルクラスタ（minikube, kind, Docker Desktop, k3d など）または検証環境がある
- **現在の context が検証用であることを確認すること**

### Step 0: 先に安全確認
```bash
kubectl config current-context
kubectl get ns
```

本番クラスタや共有クラスタでないことを必ず確認してください。

---

### Step 1: namespace を作る
```bash
kubectl create namespace k8s-magazine-lab
```

以後は namespace を明示します。

---

### Step 2: Deployment を作る
```bash
kubectl create deployment web --image=nginx:1.27 -n k8s-magazine-lab
```

状態確認:
```bash
kubectl get deployment,pods -n k8s-magazine-lab
```

---

### Step 3: Pod 詳細を見る
Pod 名を確認:
```bash
kubectl get pods -n k8s-magazine-lab
```

Pod 詳細:
```bash
kubectl describe pod <pod-name> -n k8s-magazine-lab
```

見るポイント:
- Image
- Containers
- Conditions
- Events

---

### Step 4: ログを見る
```bash
kubectl logs <pod-name> -n k8s-magazine-lab
```

Nginx は大量ログがないこともあります。重要なのは「ログを見る場所」を体で覚えることです。

---

### Step 5: Pod 内に入る
```bash
kubectl exec -it <pod-name> -n k8s-magazine-lab -- sh
```

中で確認:
```sh
nginx -v
ls /usr/share/nginx/html
exit
```

---

### Step 6: Service を作る
```bash
kubectl expose deployment web --port=80 --target-port=80 -n k8s-magazine-lab
```

確認:
```bash
kubectl get svc -n k8s-magazine-lab
kubectl describe svc web -n k8s-magazine-lab
```

---

### Step 7: あえて観察する
以下を見て、Deployment / Pod / Service がどうつながっているか確認します。
```bash
kubectl get all -n k8s-magazine-lab
kubectl describe deployment web -n k8s-magazine-lab
```

---

### Step 8: 後片付け（破壊操作なので注意）
**削除対象 namespace を必ず目視確認してから実行**
```bash
kubectl delete namespace k8s-magazine-lab
```

> 注意: `kubectl delete` は強い操作です。namespace 名、context、対象範囲を見直してから実行してください。

---

## 5) コマンドチートシート

### 基本確認
```bash
kubectl config current-context
kubectl get pods
kubectl get pods -A
kubectl get all -n <namespace>
```

### 詳細確認
```bash
kubectl describe pod <pod-name> -n <namespace>
kubectl describe deployment <deployment-name> -n <namespace>
kubectl describe svc <service-name> -n <namespace>
```

### ログ
```bash
kubectl logs <pod-name> -n <namespace>
kubectl logs <pod-name> -c <container-name> -n <namespace>
kubectl logs <pod-name> --previous -n <namespace>
```

### Pod 内確認
```bash
kubectl exec -it <pod-name> -n <namespace> -- sh
kubectl exec <pod-name> -n <namespace> -- printenv
```

### 安全確認つき apply
```bash
kubectl config current-context
kubectl apply --dry-run=client -f manifest.yaml
kubectl apply -f manifest.yaml
```

---

## 6) よくあるミスと安全策

### ミス1: context を見ずに実行する
ありがちな事故です。検証環境のつもりで本番に打つと危険です。

**安全策:**
```bash
kubectl config current-context
```
を先に打つ。必要なら `kubectl config get-contexts` も見る。

---

### ミス2: namespace を省略する
「見つからない」「違うものを見ていた」が起こります。

**安全策:**
- `-n <namespace>` を明示する
- 共有環境では特に明示癖をつける

---

### ミス3: `kubectl apply -f .` を雑に実行する
意図しない manifest まで適用する危険があります。

**安全策:**
- 適用対象ファイルを限定する
- 先に `--dry-run=client` を使う
- 差分確認できる運用ならレビューを挟む

---

### ミス4: Secret を manifest に平文で書く
Git に載る、共有される、漏れる、の最悪パターンです。

**安全策:**
- 平文シークレットを直接コミットしない
- Secret 管理ツールや外部 secret manager の利用を検討する
- 少なくともサンプル manifest に本物の値を入れない

---

### ミス5: `exec` で本番コンテナを直接いじる
一時しのぎになり、再現不能やドリフトの原因になります。

**安全策:**
- `exec` は主に観察に使う
- 恒久対応はイメージ、manifest、設定管理に戻す

---

## 7) 面接っぽい一問
**質問:**  
`kubectl get pod` と `kubectl describe pod` の違いは何ですか？ また、Pod が起動しないときにどちらを先にどう使いますか？

**考え方のヒント:**
- `get` は一覧・要約
- `describe` は詳細・イベント
- 調査の流れとしては `get` → `describe` → `logs` が自然

---

## 8) 次のステップ（学習アーク）

### 次回予告: Middle
**Topic:** Deployment / ReplicaSet / rollout を理解して安全にアプリ更新する  
**Level:** Middle  
**Prerequisites:**
- Pod / Deployment / Service の基本が分かる
- `kubectl get`, `describe`, `logs` を触ったことがある
- namespace と context の概念を理解している

学べること:
- RollingUpdate
- `kubectl rollout status/history/undo`
- 更新事故を小さくする考え方

---

### その次: Advanced
**Topic:** Probe・resources・障害復旧を踏まえた本番運用の基礎  
**Level:** Advanced  
**Prerequisites:**
- Deployment 更新の流れが分かる
- rollout の基本操作ができる
- manifest を読んで主要項目を把握できる

学べること:
- readiness/liveness/startup probe
- requests / limits
- 再起動ループ時の調査導線
- 安全な変更手順

---

## 9) 公式中心の参考リンク
- Kubernetes Documentation: https://kubernetes.io/docs/home/
- Overview of kubectl: https://kubernetes.io/docs/reference/kubectl/
- Get started with kubectl: https://kubernetes.io/docs/reference/kubectl/quick-reference/
- Debug Pods and ReplicationControllers: https://kubernetes.io/docs/tasks/debug/debug-application/debug-pods/
- Deployments: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Services: https://kubernetes.io/docs/concepts/services-networking/service/
- Secrets: https://kubernetes.io/docs/concepts/configuration/secret/
- Configure Liveness, Readiness and Startup Probes: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/

---

## まとめ
今号は、Kubernetes 実務の入口として **「壊す前に観察する」基本コマンド群** に集中しました。

まずはこの順番を体に入れるのがおすすめです。
1. `kubectl config current-context`
2. `kubectl get`
3. `kubectl describe`
4. `kubectl logs`
5. 必要なら `kubectl exec`

Kubernetes はコマンドをたくさん覚えるより、**安全に観察して、宣言的に直す** ほうが大事です。  
次の Middle では、アプリ更新を事故らせない rollout 運用に進むと実務感がかなり増します。
