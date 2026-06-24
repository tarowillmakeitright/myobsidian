---
tags:
  - kubernetes
  - k8s
  - devops
  - learning
  - daily
---

#kubernetes #k8s #devops #learning #daily
[[Home]]

# 2026-06-24 09-25 Kubernetes Commands Magazine

## 1) Topic + Level
**テーマ:** `kubectl get / describe / logs / exec` でアプリ開発中の Pod 状態を安全に観察する
**レベル:** Beginner

> この号は Kubernetes 学習アークの初回を想定した Beginner 編です。次号以降で Middle → Advanced に進み、難易度を段階的に上げていきます。

---

## 2) Why it matters for real app development
Kubernetes を使った実アプリ開発では、最初に必要になるのは「デプロイすること」よりも、**動いているワークロードを正しく観察すること**です。

ローカル開発では `docker logs` や直接プロセス確認で済んでいたものが、Kubernetes では以下のように少し抽象化されます。

- アプリは Pod の中で動く
- 再起動や再スケジューリングで実体が入れ替わる
- 複数 Pod にスケールする
- Node 障害や readiness/liveness の影響を受ける

そのため、開発者が最初に身につけるべきなのは次の流れです。

1. `kubectl get` で全体像を見る
2. `kubectl describe` でイベントや状態を掘る
3. `kubectl logs` でアプリ視点を確認する
4. 必要時のみ `kubectl exec` で内部確認する

この流れを覚えるだけで、**「動かない理由がまったく見えない」状態からかなり早く脱出**できます。

---

## 3) Core kubectl/Kubernetes concept explanations

### Pod
Kubernetes でコンテナを動かす最小単位です。通常、アプリケーションコンテナは Pod の中で実行されます。

### Namespace
環境やチームごとにリソースを分ける論理的な区画です。`default` に全部入れるより、用途ごとに分けた方が安全です。

### kubectl get
リソースの一覧をざっくり見るコマンドです。

例:
```bash
kubectl get pods
kubectl get pods -n default
kubectl get deployments
kubectl get svc
```

### kubectl describe
一覧だけでは分からない詳細状態、イベント、イメージ、条件、マウント、失敗理由を確認します。

例:
```bash
kubectl describe pod <pod-name>
```

### kubectl logs
アプリケーションの標準出力・標準エラー出力を見ます。Kubernetes での基本的なログ確認手段です。

例:
```bash
kubectl logs <pod-name>
kubectl logs -f <pod-name>
```

### kubectl exec
Pod 内でコマンドを実行します。最終手段ではないですが、**常用しすぎない**のが大事です。まずは logs / events / manifest を見てから使うのが実務的です。

例:
```bash
kubectl exec -it <pod-name> -- /bin/sh
```

### なぜ `describe` と `logs` を分けて考えるのか
- `describe`: Kubernetes 観点の失敗要因を見る
  - ImagePullBackOff
  - CrashLoopBackOff
  - probe failure
  - scheduling failure
- `logs`: アプリ観点の失敗要因を見る
  - 例外
  - 設定値不足
  - DB 接続失敗
  - 起動時エラー

両方見るのが基本です。

---

## 4) How Kubernetes is used while building apps
[kubernetes.io/docs](https://kubernetes.io/docs/) のベストプラクティスに沿うと、アプリ開発中の Kubernetes 利用は「とりあえずクラスタに投げる」ではなく、**宣言的に管理しつつ、観察可能性を高める**方向になります。

開発中によくある流れ:

- Deployment でアプリをデプロイする
- Service でアクセス経路を作る
- readinessProbe / livenessProbe で状態確認する
- ConfigMap / Secret で設定を外出しする
- `kubectl logs`, `describe`, `get events` で調査する

実務で特に重要なのは次の点です。

### 1. 設定をイメージに埋め込まない
環境差分は ConfigMap / Secret に分離します。

### 2. Secret をマニフェストにベタ書きしない
Git 管理する YAML に平文シークレットを書かないこと。学習中でもここは最初から癖をつけるべきです。

### 3. `kubectl apply` の対象を明確にする
`kubectl apply -f .` は便利ですが、**今どのディレクトリにいて、何が適用されるのか**を必ず確認してください。

### 4. クラスタ文脈を毎回確認する
本番クラスタに対して `kubectl delete` や `apply` を誤実行する事故は本当に起きます。作業前に必ず確認します。

```bash
kubectl config current-context
kubectl config get-contexts
```

### 5. `exec` より先に宣言とログを確認する
アプリの中に入って手で直すのではなく、**manifest と設定の改善に戻す**のが Kubernetes 的です。

---

## 5) 30-60 minute hands-on mini lab
**所要時間:** 30〜45分
**目的:** Nginx Pod を動かし、`get` → `describe` → `logs` → `exec` の基本観察フローを体験する

### 事前条件
- `kubectl` が使える
- 学習用クラスタがある（minikube / kind / Docker Desktop Kubernetes など）
- **本番クラスタでは実施しないこと**

### Step 0: コンテキスト確認
```bash
kubectl config current-context
kubectl get ns
```

**確認ポイント:** 学習用クラスタであることを先に確認する。

### Step 1: Namespace を作る
```bash
kubectl create namespace k8s-magazine-lab
```

### Step 2: Nginx Deployment を作る
```bash
kubectl create deployment web --image=nginx:1.27 -n k8s-magazine-lab
```

### Step 3: Pod 一覧を見る
```bash
kubectl get pods -n k8s-magazine-lab
kubectl get deploy -n k8s-magazine-lab
```

### Step 4: Deployment と Pod の詳細を見る
まず Deployment 名を確認し、その後 Pod 名を確認して `describe` します。

```bash
kubectl describe deployment web -n k8s-magazine-lab
kubectl get pods -n k8s-magazine-lab
kubectl describe pod <pod-name> -n k8s-magazine-lab
```

**見るポイント:**
- Image
- Conditions
- Events
- Restart Count
- Pod IP
- Node

### Step 5: ログを見る
```bash
kubectl logs <pod-name> -n k8s-magazine-lab
```

Nginx は静かなこともあるので、後でアクセスしてから再確認しても良いです。

### Step 6: Service を作る
```bash
kubectl expose deployment web --port=80 --type=ClusterIP -n k8s-magazine-lab
kubectl get svc -n k8s-magazine-lab
```

### Step 7: Pod 内を確認する
```bash
kubectl exec -it <pod-name> -n k8s-magazine-lab -- /bin/sh
```

中で以下を試します。
```sh
hostname
ls /usr/share/nginx/html
cat /etc/os-release
exit
```

### Step 8: ラベルで絞る
```bash
kubectl get pods -n k8s-magazine-lab --show-labels
kubectl get pods -n k8s-magazine-lab -l app=web
```

### Step 9: 後片付け
**削除前に namespace 名を再確認してください。**

```bash
kubectl delete namespace k8s-magazine-lab
```

> `delete namespace` は配下のリソースをまとめて消します。対象を必ず見直してから実行してください。

---

## 6) Command cheatsheet
```bash
# コンテキスト確認
kubectl config current-context
kubectl config get-contexts

# 一覧確認
kubectl get pods
kubectl get pods -A
kubectl get deploy -n <namespace>
kubectl get svc -n <namespace>

# 詳細確認
kubectl describe pod <pod-name> -n <namespace>
kubectl describe deployment <deploy-name> -n <namespace>

# ログ確認
kubectl logs <pod-name> -n <namespace>
kubectl logs -f <pod-name> -n <namespace>

# Pod 内確認
kubectl exec -it <pod-name> -n <namespace> -- /bin/sh

# ラベル確認
kubectl get pods -n <namespace> --show-labels
kubectl get pods -n <namespace> -l app=<label>

# イベント確認
kubectl get events -n <namespace> --sort-by=.metadata.creationTimestamp
```

---

## 7) Common mistakes and safe practices

### よくあるミス 1: Namespace を付け忘れる
`default` を見て「Pod がない」と勘違いしがちです。

**安全策:**
- `-n <namespace>` を明示する
- `kubectl get ns` で存在確認する

### よくあるミス 2: `logs` だけ見て Kubernetes 側の異常を見落とす
アプリログに何も出ないのに Pod が起動しないことは普通にあります。

**安全策:**
- `describe` と `get events` を必ずセットで見る

### よくあるミス 3: 本番コンテキストに気づかず触る
かなり危険です。

**安全策:**
- 作業前に `kubectl config current-context`
- destructive なコマンド前に一呼吸置く
- shell prompt などで context を見える化する

### よくあるミス 4: `kubectl apply -f .` の範囲を把握していない
意図しない YAML まで適用されることがあります。

**安全策:**
- `ls` や `find` で対象ファイルを確認する
- できればディレクトリを整理する
- 変更前にレビューする

### よくあるミス 5: Secret を YAML に平文で置く
学習環境でも癖になると危ないです。

**安全策:**
- シークレットを公開リポジトリに置かない
- Secret 管理は別途安全な方法を使う
- 学習時はダミー値を使う

### よくあるミス 6: `exec` でその場修正して終わる
Kubernetes では再作成で消えるので、再現性がありません。

**安全策:**
- 原因を manifest / image / config に戻して修正する

---

## 8) One interview-style question
**質問:**
Pod が `Running` に見えるのに、アプリが正常に使えない場合、あなたは `kubectl` でどの順番で何を確認しますか？

**考え方のヒント:**
- Pod 状態
- readiness
- events
- logs
- Service / Endpoint
- Namespace / label selector の整合性

---

## 9) Next-step resources
まずは公式ドキュメントを軸に進めるのが一番堅いです。

- Kubernetes Documentation
  - https://kubernetes.io/docs/
- Overview
  - https://kubernetes.io/docs/concepts/overview/
- Pods
  - https://kubernetes.io/docs/concepts/workloads/pods/
- Deployments
  - https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- kubectl Overview
  - https://kubernetes.io/docs/reference/kubectl/
- Debugging Applications
  - https://kubernetes.io/docs/tasks/debug/debug-application/
- Secrets
  - https://kubernetes.io/docs/concepts/configuration/secret/
- ConfigMaps
  - https://kubernetes.io/docs/concepts/configuration/configmap/

---

## 次号予告
**Middle 予定:** Deployment / Service / labels / selectors を使って「アプリを更新しながら安全に公開する」

**前提知識:**
- Pod の基本
- `kubectl get / describe / logs / exec`
- Namespace の基本
