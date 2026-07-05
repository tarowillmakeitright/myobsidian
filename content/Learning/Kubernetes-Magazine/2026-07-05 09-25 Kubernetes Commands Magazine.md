---
tags:
  - kubernetes
  - k8s
  - devops
  - learning
  - daily
---

[[Home]]

# 2026-07-05 Kubernetes Commands Magazine

## 今号のテーマ
**Topic:** `kubectl describe / logs / exec を使って、アプリ障害を安全に切り分ける`
**Level:** Beginner

---

## 1) なぜ実アプリ開発で重要か
アプリ開発では「ローカルでは動くのに、Kubernetes 上では動かない」という場面が頻繁にあります。
特に多いのは次のようなケースです。

- Pod は起動したが Ready にならない
- コンテナが CrashLoopBackOff になる
- HTTP 500 や接続失敗が出る
- 環境変数や ConfigMap の反映漏れがある
- Service はあるのに通信できない

このとき最初に使うべき基本コマンドが `kubectl get`、`describe`、`logs`、`exec` です。
これらを順番に正しく使えると、**再デプロイ前に原因をかなり絞り込めます**。
本番運用でも開発環境でも必須の基礎力です。

---

## 2) コア概念の整理

### `kubectl get`
Kubernetes リソースの一覧や状態を確認します。

例:
```bash
kubectl get pods
kubectl get deploy
kubectl get svc
kubectl get pods -n default -o wide
```

見るポイント:
- STATUS
- READY
- RESTARTS
- NODE
- IP

### `kubectl describe`
リソースの詳細情報とイベントを確認します。

例:
```bash
kubectl describe pod <pod名>
kubectl describe deploy <deploy名>
```

特に重要:
- Events
- Image pull エラー
- Probe 失敗
- Mount 失敗
- Scheduling 失敗

### `kubectl logs`
コンテナ標準出力/標準エラーを確認します。

例:
```bash
kubectl logs <pod名>
kubectl logs <pod名> -c <container名>
kubectl logs <pod名> --previous
```

重要ポイント:
- 複数コンテナ Pod では `-c` が必要
- 再起動後の直前ログは `--previous`

### `kubectl exec`
実行中コンテナの中に入って確認します。

例:
```bash
kubectl exec -it <pod名> -- sh
kubectl exec <pod名> -- printenv
```

用途:
- 環境変数確認
- アプリ設定確認
- 名前解決や HTTP 疎通確認

**注意:**
`exec` は便利ですが、本番での常用は避けるべきです。まずは `get` → `describe` → `logs` の順に確認し、必要最小限で使います。

---

## 3) アプリ開発中に Kubernetes をどう使うか
kubernetes.io/docs のベストプラクティスに沿うと、アプリ開発では Kubernetes は「ただ置く場所」ではなく、**実行環境の差分を早く見つけるための観測基盤**として使います。

実務では次の流れが基本です。

1. Deployment でアプリを宣言的に管理する
2. Service で到達性を安定化する
3. readinessProbe / livenessProbe で状態を機械的に判定する
4. ConfigMap / Secret で設定をコードから分離する
5. 問題発生時は `get` / `describe` / `logs` で観測する

### 実務での良い使い方
- **Deployment を使う**: 単発 Pod 作成より再現性が高い
- **Probe を設定する**: 「起動しただけ」を成功と見なさない
- **Config を外出しする**: イメージ焼き直しを減らせる
- **ログを stdout/stderr に出す**: `kubectl logs` で追える
- **namespace を意識する**: 開発・検証・本番を分ける

### 避けたい使い方
- Pod に直接その場変更を入れる
- Secret を manifest に平文で書く
- `kubectl apply -f .` を文脈確認せず実行する
- 現在の context / namespace を確認せず削除系コマンドを打つ

---

## 4) 30〜60分ミニラボ
**目的:** Nginx を Deployment と Service で立て、観測系コマンドで状態確認する。

### 前提
- ローカル検証用クラスターがあること
  - 例: minikube / kind / Docker Desktop Kubernetes
- `kubectl` が使えること

### 0. 破壊的操作への注意
このラボは安全寄りですが、`apply` や `delete` の前に必ず次を確認してください。

```bash
kubectl config current-context
kubectl config view --minify --output 'jsonpath={..namespace}' ; echo
```

誤った context や namespace で実行すると、別環境に影響する可能性があります。

### 1. 専用 namespace を作る
```bash
kubectl create namespace k8s-magazine-lab
```

### 2. Deployment を作る
```bash
kubectl create deployment web --image=nginx:1.27 -n k8s-magazine-lab
```

### 3. Service を公開する
```bash
kubectl expose deployment web --port=80 --target-port=80 --type=ClusterIP -n k8s-magazine-lab
```

### 4. 状態を見る
```bash
kubectl get all -n k8s-magazine-lab
kubectl get pods -n k8s-magazine-lab -o wide
```

確認ポイント:
- Pod が Running か
- Deployment が AVAILABLE か
- Service に ClusterIP が割り当てられているか

### 5. Pod の詳細を見る
```bash
kubectl describe pod -n k8s-magazine-lab -l app=web
```

確認ポイント:
- Events にエラーがないか
- Image pull 状態
- Ready 条件

### 6. ログを見る
```bash
POD=$(kubectl get pods -n k8s-magazine-lab -l app=web -o jsonpath='{.items[0].metadata.name}')
kubectl logs "$POD" -n k8s-magazine-lab
```

### 7. コンテナの中を確認する
```bash
kubectl exec -it "$POD" -n k8s-magazine-lab -- sh
```

コンテナ内で試す:
```sh
nginx -v
cat /etc/nginx/nginx.conf | head
exit
```

### 8. Service 情報を見る
```bash
kubectl describe svc web -n k8s-magazine-lab
```

確認ポイント:
- Selector
- Endpoints

### 9. 余裕があれば: スケールして観測
```bash
kubectl scale deployment web --replicas=3 -n k8s-magazine-lab
kubectl get pods -n k8s-magazine-lab -w
```

### 10. 片付け
**削除前に context を再確認してください。**
```bash
kubectl config current-context
kubectl delete namespace k8s-magazine-lab
```

---

## 5) コマンドチートシート
```bash
# 現在の接続先確認
kubectl config current-context
kubectl config get-contexts

# 基本一覧
kubectl get pods
kubectl get pods -A
kubectl get deploy,svc -n <namespace>
kubectl get all -n <namespace>

# 詳細確認
kubectl describe pod <pod名> -n <namespace>
kubectl describe deploy <deploy名> -n <namespace>
kubectl describe svc <svc名> -n <namespace>

# ログ
kubectl logs <pod名> -n <namespace>
kubectl logs <pod名> -c <container名> -n <namespace>
kubectl logs <pod名> --previous -n <namespace>

# コンテナ内確認
kubectl exec -it <pod名> -n <namespace> -- sh
kubectl exec <pod名> -n <namespace> -- printenv

# ラベルで対象取得
kubectl get pods -l app=web -n <namespace>

# スケール
kubectl scale deployment <deploy名> --replicas=3 -n <namespace>
```

---

## 6) よくあるミスと安全な実践

### よくあるミス 1: namespace を見ていない
`default` に作ったつもりで別 namespace を見ている、またはその逆は非常に多いです。

安全策:
```bash
kubectl get pods -A
kubectl config view --minify --output 'jsonpath={..namespace}' ; echo
```

### よくあるミス 2: context を確認せず apply / delete
開発クラスタだと思って本番に apply/delete する事故は本当に起きます。

安全策:
- 実行前に `kubectl config current-context`
- 破壊的コマンド前に一呼吸置く
- エイリアスやプロンプトで context 表示を有効化する

### よくあるミス 3: Secret を平文で Git 管理
`Secret` リソースでも manifest に値を直書きすれば漏えいリスクは高いです。

安全策:
- Secret 値を平文でコミットしない
- 外部 secret manager の利用を検討する
- 開発中でもサンプル値と実値を分離する

### よくあるミス 4: `exec` でその場修正して満足する
コンテナ内で手修正しても再起動で消えます。

安全策:
- 原因調査には使う
- 修正は Dockerfile / manifest / ConfigMap / CI に戻す

### よくあるミス 5: `apply -f .` のスコープが広すぎる
意図しない manifest まで適用してしまうことがあります。

安全策:
- 対象ファイルを明示する
- ディレクトリ適用前に中身を確認する
- `kubectl diff -f <file>` を先に使う

---

## 7) 面接っぽい一問
**Q.** Pod が `Running` なのに、ユーザーからは「アプリが使えない」と報告されています。最初にどんな順番で `kubectl` を使って確認しますか？

**模範的な考え方:**
1. `kubectl get pods,svc,endpoints -n <namespace>` で全体状態確認
2. `kubectl describe pod <pod名>` で Events / Probe / Restart を確認
3. `kubectl logs <pod名>` でアプリログ確認
4. `kubectl describe svc <svc名>` で Selector / Endpoints を確認
5. 必要なら `kubectl exec` で環境変数や内部疎通を確認

ポイントは、**いきなりコンテナに入るのではなく、宣言状態 → イベント → ログ → 必要時のみ exec** の順に進めることです。

---

## 8) 次のステップ

### 次号への橋渡し（Middle）
**次の学習レベル:** Middle  
**予告テーマ:** `labels / selectors / rollout を使った安全なデプロイ確認`

**前提知識:**
- Pod / Deployment / Service の役割を理解している
- `kubectl get / describe / logs / exec` を使った基本確認ができる
- namespace と context の違いを説明できる

Middle では、複数 Pod をどうまとめて扱うか、ロールアウトをどう安全に追跡するかを学ぶと実務力がかなり上がります。

---

## 9) 公式リソース中心の参考リンク
- Kubernetes Documentation Home  
  https://kubernetes.io/docs/

- Overview of kubectl  
  https://kubernetes.io/docs/reference/kubectl/

- Debug Services  
  https://kubernetes.io/docs/tasks/debug/debug-application/debug-service/

- Debug Running Pods  
  https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/

- Probes (liveness, readiness, startup)  
  https://kubernetes.io/docs/concepts/configuration/liveness-readiness-startup-probes/

- Secrets good practices  
  https://kubernetes.io/docs/concepts/security/secrets-good-practices/

- Labels and Selectors  
  https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/

---

## 一言まとめ
今日は **「壊す前に観測する」** がテーマです。
Kubernetes では、まず `get` → `describe` → `logs`、必要なら `exec`。
この順番を体に入れるだけで、アプリ障害対応の精度と安全性がかなり上がります。
