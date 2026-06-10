---
tags:
  - kubernetes
  - k8s
  - devops
  - learning
  - daily
---

[[Home]]

# Kubernetes Commands Magazine — 2026-06-10

## 今日のテーマ
**Topic:** `kubectl get` → `describe` → `logs` → `exec` / `port-forward` で進める安全なデバッグ導線  
**Learning Arc:** Beginner → Middle → Advanced

---

# Beginner

## 1) Topic + Level
**Level:** Beginner  
**Topic:** `kubectl get` / `describe` / `logs` で「何が起きているか」を読む

## 2) なぜ実アプリ開発で重要か
アプリ開発では「デプロイできたか」よりも、**なぜ動かないのかを短時間で切り分けられるか**が重要です。Pod が `CrashLoopBackOff` になった、Service につながらない、環境変数が違う、イベントで失敗している――こうした日常的な問題の入口になるのが `get` / `describe` / `logs` です。

## 3) コア概念の説明
- **Pod**: コンテナを実行する最小単位。
- **Status / Phase**: `Running`, `Pending`, `CrashLoopBackOff` など、今の状態を把握するための手がかり。
- **Event**: イメージ取得失敗、スケジューリング失敗、Probe 失敗などの履歴。
- **Container logs**: アプリ本体の標準出力・標準エラー。
- **Label selector**: `-l app=myapp` のように対象を安全に絞る方法。

## 4) アプリ開発での使われ方
Kubernetes 公式ドキュメントの考え方に沿うと、まず**観測してから変更する**のが基本です。実務では次の順で見ることが多いです。
- `kubectl get` で全体状態をざっくり確認
- `kubectl describe` でイベントや設定差分を確認
- `kubectl logs` でアプリの失敗理由を確認
- いきなり再作成・削除せず、原因を特定してから manifest や image、設定を直す

## 5) 30–60分ミニラボ
**目標:** 失敗する Pod を作り、`get` / `describe` / `logs` で原因を追う。  
**前提:** `kubectl` が使えるローカル検証環境（kind / minikube / Docker Desktop Kubernetes など）

### 例: わざと失敗する Pod
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: crash-demo
  labels:
    app: crash-demo
spec:
  containers:
    - name: app
      image: busybox:1.36
      command: ["sh", "-c", "echo starting; sleep 3; echo boom; exit 1"]
```

### 実行例
```bash
kubectl config current-context
kubectl apply -f crash-demo.yaml
kubectl get pod crash-demo -w
kubectl describe pod crash-demo
kubectl logs crash-demo
kubectl logs crash-demo --previous
kubectl get events --sort-by=.metadata.creationTimestamp
```

### 観察ポイント
- Pod が再起動を繰り返しているか
- `describe` の Events に何が出ているか
- `logs --previous` で直前の失敗ログが読めるか

## 6) Command Cheatsheet
```bash
kubectl config current-context
kubectl get pods
kubectl get pods -o wide
kubectl get pods -l app=crash-demo
kubectl describe pod crash-demo
kubectl logs crash-demo
kubectl logs crash-demo --previous
kubectl get events --sort-by=.metadata.creationTimestamp
```

## 7) よくあるミスと安全策
- **`kubectl delete pod ...` を反射的に打つ**  
  → 原因確認前に証拠を消しやすい。まず `describe` と `logs`。
- **context を見ずに調査する**  
  → 別クラスタを見ている事故が起きる。最初に `kubectl config current-context`。
- **複数 Pod のうち対象を曖昧にする**  
  → `-l` や名前指定で絞る。
- **イベントを見ない**  
  → スケジューリング失敗や ImagePull エラーを見落とす。
- **削除系コマンドを雑に使う**  
  → 検証環境でも対象確認。特に本番では delete 前に namespace / context / resource type を再確認する。

## 8) 面接っぽい質問
**質問:** Pod が `CrashLoopBackOff` のとき、最初にどのコマンドをどういう順番で使いますか？

## 9) 次の一歩リソース
- Kubernetes 公式: Debug Pods and ReplicationControllers  
  https://kubernetes.io/docs/tasks/debug/debug-application/debug-pods/
- Kubernetes 公式: kubectl Cheat Sheet  
  https://kubernetes.io/docs/reference/kubectl/cheatsheet/
- Kubernetes 公式: Pod Lifecycle  
  https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/

---

# Middle

## 1) Topic + Level
**Level:** Middle  
**Topic:** `kubectl exec` と `port-forward` でアプリ内部と通信経路を確認する

**Prerequisites:**
- Pod / Deployment / Service の基本が分かる
- `kubectl get` / `describe` / `logs` を使った確認ができる
- コンテナ内で動くプロセスとポートの概念を理解している

## 2) なぜ実アプリ開発で重要か
実務では「Pod は Running なのに API が返らない」「Service 経由だとつながらない」「アプリは起動しているが想定ポートで待ち受けていない」といった問題が頻出します。`exec` と `port-forward` を使うと、**クラスタを壊さずに内部を観察し、ローカルから安全に検証**できます。

## 3) コア概念の説明
- **`kubectl exec`**: 実行中コンテナ内でコマンドを実行する。
- **`kubectl port-forward`**: ローカルポートを Pod / Service に転送して安全に接続確認する。
- **Loopback debugging**: 外部公開せず、手元からだけ確認するデバッグ方法。
- **Service selector**: Service が正しい Pod を拾えているかの要点。
- **Readiness**: Pod が Running でも、実際にリクエスト受付可能とは限らない。

## 4) アプリ開発での使われ方
Kubernetes 公式のベストプラクティスに沿うなら、デバッグのために**不要な NodePort や LoadBalancer を乱立させるより、必要最小限の `port-forward` を使う**方が安全です。また `exec` は便利ですが、本番では変更のためではなく**観察のために限定**し、恒久対策は manifest やイメージ修正で行うのが筋です。

## 5) 30–60分ミニラボ
**目標:** Deployment と Service を作り、`exec` と `port-forward` で内部確認する。

### 例: Deployment
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-debug
spec:
  replicas: 1
  selector:
    matchLabels:
      app: web-debug
  template:
    metadata:
      labels:
        app: web-debug
    spec:
      containers:
        - name: web
          image: nginx:1.27
          ports:
            - containerPort: 80
```

### 例: Service
```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-debug
spec:
  selector:
    app: web-debug
  ports:
    - port: 80
      targetPort: 80
  type: ClusterIP
```

### 実行例
```bash
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl rollout status deployment/web-debug
kubectl get pods -l app=web-debug
kubectl get svc web-debug

POD=$(kubectl get pods -l app=web-debug -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it "$POD" -- sh
# コンテナ内で確認
# ps
# wget -qO- http://127.0.0.1:80
# exit

kubectl port-forward service/web-debug 8080:80
# 別ターミナルで
# curl http://127.0.0.1:8080
```

### 発展演習
- Service の selector をわざとずらして通信失敗を再現する
- `kubectl get endpoints web-debug` を見て、宛先が空になることを確認する
- 修正後に疎通が戻ることを確認する

## 6) Command Cheatsheet
```bash
kubectl get svc
kubectl get endpoints
kubectl get pods -l app=web-debug
kubectl exec -it <pod-name> -- sh
kubectl exec <pod-name> -- printenv
kubectl port-forward pod/<pod-name> 8080:80
kubectl port-forward service/web-debug 8080:80
curl http://127.0.0.1:8080
```

## 7) よくあるミスと安全策
- **本番 Pod に入って手で直す**  
  → その場しのぎで再現性がなくなる。観察だけに使い、修正はイメージや manifest に戻す。
- **`port-forward` で外部公開した気になる / 逆に不用意に共有する**  
  → 基本はローカル向け。共有時は扱いに注意。
- **selector 不一致を見落とす**  
  → `get svc` だけでなく `get endpoints` を見る。
- **秘密情報を `printenv` の出力ごと貼る**  
  → 共有時に Secret 値を漏らさない。
- **`exec` 前後で namespace を取り違える**  
  → `-n` 明示、または current context の namespace を確認する。

## 8) 面接っぽい質問
**質問:** Pod は Running なのに Service 経由で通信できない場合、どこを確認しますか？

## 9) 次の一歩リソース
- Kubernetes 公式: Get a Shell to a Running Container  
  https://kubernetes.io/docs/tasks/debug/debug-application/get-shell-running-container/
- Kubernetes 公式: Use Port Forwarding to Access Applications in a Cluster  
  https://kubernetes.io/docs/tasks/access-application-cluster/port-forward-access-application-cluster/
- Kubernetes 公式: Service  
  https://kubernetes.io/docs/concepts/services-networking/service/

---

# Advanced

## 1) Topic + Level
**Level:** Advanced  
**Topic:** `kubectl debug` / ephemeral container と namespace・context 意識で行う安全な本番寄り調査

**Prerequisites:**
- `get` / `describe` / `logs` / `exec` / `port-forward` を使った基本調査ができる
- Pod と Service の関係、namespace の役割を理解している
- 本番運用で「調査」と「変更」を分ける重要性を理解している

## 2) なぜ実アプリ開発で重要か
distroless イメージや最小構成コンテナでは、`sh` や `curl` が入っていないことがあります。そんなときでも、**稼働中ワークロードを大きく壊さずに観察する方法**が必要です。`kubectl debug` はそうした高度なトラブルシュートで役立ちます。ただし便利なぶん、context / namespace / 権限を誤ると本番調査事故につながるので安全意識が必須です。

## 3) コア概念の説明
- **Ephemeral Container**: 一時的なデバッグ用コンテナ。通常運用のアプリ本体とは分けて扱う。
- **`kubectl debug`**: デバッグコンテナ追加やコピー Pod 作成を支援するコマンド。
- **Namespace isolation**: 調査対象を限定し、誤操作範囲を狭める。
- **RBAC / least privilege**: 調査に必要な最小権限で操作する考え方。
- **Context safety**: どのクラスタ・どの namespace に向けているかを毎回確認する習慣。

## 4) アプリ開発での使われ方
実務では、アプリチームが distroless イメージを採用することは珍しくありません。その場合、コンテナへ `exec` しても十分なツールがありません。Kubernetes 公式ドキュメントの方針に沿って考えると、
- 普段は最小イメージで攻撃面を減らす
- 調査時のみ一時的な debug 手段を使う
- 機密情報を表示・転記しない
- 永続変更は debug セッションではなく Git / manifest に戻す
という運用が安全です。

## 5) 30–60分ミニラボ
**目標:** namespace を分けて debug 用 Pod を調査し、`kubectl debug` を体験する。  
**注意:** クラスタや Kubernetes バージョンによって `kubectl debug` の挙動差があります。

### 例: namespace
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: debug-lab
```

### 例: distroless 風に「中へ入りづらい」前提の Pod
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-demo
  namespace: debug-lab
spec:
  replicas: 1
  selector:
    matchLabels:
      app: api-demo
  template:
    metadata:
      labels:
        app: api-demo
    spec:
      containers:
        - name: api
          image: nginx:1.27
          ports:
            - containerPort: 80
```

### 実行例
```bash
kubectl apply -f namespace.yaml
kubectl apply -f deployment.yaml
kubectl rollout status deployment/api-demo -n debug-lab
kubectl get pods -n debug-lab
kubectl describe deployment api-demo -n debug-lab

POD=$(kubectl get pods -n debug-lab -l app=api-demo -o jsonpath='{.items[0].metadata.name}')

kubectl debug -n debug-lab -it "$POD" --image=busybox:1.36 --target=api
```

### 追加演習
- debug 前に `kubectl config current-context` と `kubectl get ns` を必ず確認する
- `-n debug-lab` を外すと危険な理由を説明できるようにする
- 調査結果をもとに「本来直すべき場所は manifest / image / probe / Service 設定のどこか」を整理する

## 6) Command Cheatsheet
```bash
kubectl config current-context
kubectl config view --minify
kubectl get ns
kubectl get pods -n debug-lab
kubectl describe pod -n debug-lab <pod-name>
kubectl debug -n debug-lab -it <pod-name> --image=busybox:1.36 --target=api
kubectl auth can-i create pods/ephemeralcontainers -n debug-lab
kubectl get events -n debug-lab --sort-by=.metadata.creationTimestamp
```

## 7) よくあるミスと安全策
- **debug を本番変更の手段にする**  
  → 調査用に留める。恒久対応は Git / CI/CD / manifest へ。
- **誤った context / namespace で `debug` する**  
  → もっとも危険。毎回 `current-context` と `-n` 明示。
- **Secret やトークンを画面共有・ログ貼り付けで露出する**  
  → 共有前に伏せる。manifest に平文で入れない。
- **破壊的コマンドを同じ流れで打つ**  
  → `delete`, 広範囲 `apply`, namespace 横断操作の前には必ず対象再確認。
- **debug 権限を全員に広く与える**  
  → RBAC で絞る。最小権限が基本。

## 8) 面接っぽい質問
**質問:** distroless ベースの本番コンテナを調査したいとき、`kubectl exec` だけでは不十分な理由と、`kubectl debug` を使うときの注意点を説明してください。

## 9) 次の一歩リソース
- Kubernetes 公式: Debug Running Pods  
  https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/
- Kubernetes 公式: Ephemeral Containers  
  https://kubernetes.io/docs/concepts/workloads/pods/ephemeral-containers/
- Kubernetes 公式: Debug Services  
  https://kubernetes.io/docs/tasks/debug/debug-application/debug-service/
- Kubernetes 公式: RBAC  
  https://kubernetes.io/docs/reference/access-authn-authz/rbac/

---

# 今日のまとめ
- Beginner では `get` / `describe` / `logs` で障害の入口を読む
- Middle では `exec` / `port-forward` でアプリ内部と通信経路を安全に観察する
- Advanced では `kubectl debug` と ephemeral container を使った本番寄り調査の考え方を学ぶ

Kubernetes は「デプロイする技術」でもありますが、実務では同じくらい**安全に調査する技術**が重要です。特に、**context確認・namespace明示・Secret非露出・破壊的コマンド前の再確認**は、毎回の習慣にしたほうが事故をかなり減らせます。
