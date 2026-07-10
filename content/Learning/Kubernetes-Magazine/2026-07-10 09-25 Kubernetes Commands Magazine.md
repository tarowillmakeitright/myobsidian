---
tags:
  - kubernetes
  - k8s
  - devops
  - learning
  - daily
---

[[Home]]

# 2026-07-10 09:25 Kubernetes Commands Magazine

#kubernetes #k8s #devops #learning #daily

## 今回のテーマ
**Pod → Deployment → Service までを安全に扱いながら、アプリ開発でよく使う kubectl の基本操作を段階的に身につける**

今日は「ローカルで作ったアプリを Kubernetes 上でどう安全に載せて観察し、更新するか」を、Beginner → Middle → Advanced の流れで学ぶ。

---

## Beginner — Pod と kubectl の基本観察

### 1) Topic + Level
**Topic:** Pod を作って見る・調べる・ログを確認する
**Level:** Beginner

### 2) Why it matters for real app development
アプリ開発では、まず「コンテナが起動しているか」「何が原因で落ちているか」「期待したイメージが動いているか」を確認できないと先に進めない。Pod は Kubernetes の最小実行単位なので、ここを読めるとデバッグ速度がかなり変わる。

### 3) Core kubectl/Kubernetes concept explanations
- **Pod**: 1つ以上のコンテナをまとめて実行する最小単位。
- **kubectl get**: 一覧を見る基本コマンド。
- **kubectl describe**: 状態、イベント、失敗理由まで深掘り確認する。
- **kubectl logs**: アプリの標準出力ログを見る。
- **namespace**: リソースの論理分離。最初から `default` に何でも置かない習慣が大事。

### 4) How Kubernetes is used while building apps
アプリ開発中は、まず軽い検証 Pod や Deployment を作り、`get` / `describe` / `logs` で起動確認を回すことが多い。公式ドキュメントでも、宣言的な設定と観察可能性を重視している。つまり「何を作ったか」を YAML で残し、「今どうなっているか」を `kubectl` で確認するのが基本パターン。

### 5) 30-60 minute hands-on mini lab
**目標:** nginx Pod を作り、状態確認とログ確認を行う。

1. 作業用 namespace を作る
```bash
kubectl create namespace magazine-lab
```

2. nginx Pod を作る
```bash
kubectl run web --image=nginx:1.27 --namespace=magazine-lab
```

3. Pod の状態を見る
```bash
kubectl get pods -n magazine-lab
kubectl get pods -n magazine-lab -o wide
```

4. 詳細を確認する
```bash
kubectl describe pod web -n magazine-lab
```

5. ログを見る
```bash
kubectl logs web -n magazine-lab
```

6. Pod 内を軽く確認する
```bash
kubectl exec -it web -n magazine-lab -- /bin/bash
```
`exit` で戻る。

7. 余裕があればイメージ名をわざと間違えて、`ImagePullBackOff` を観察する
```bash
kubectl run broken --image=nginx:does-not-exist -n magazine-lab
kubectl get pods -n magazine-lab
kubectl describe pod broken -n magazine-lab
```

### 6) Command cheatsheet
```bash
kubectl config current-context
kubectl get ns
kubectl get pods -n magazine-lab
kubectl describe pod web -n magazine-lab
kubectl logs web -n magazine-lab
kubectl exec -it web -n magazine-lab -- /bin/bash
```

### 7) Common mistakes and safe practices
**よくあるミス**
- `default` namespace に何でも作る
- `kubectl logs` だけ見てイベントを見ない
- 現在の context を確認せずに別クラスタへ実行する

**安全な運用**
- 実行前に必ず context を確認する
```bash
kubectl config current-context
```
- 破壊的な操作の前に namespace と対象名を再確認する
- `kubectl delete` は本番クラスタで特に要注意
- Secret を Pod 定義にベタ書きしない

### 8) One interview-style question
**Q:** `kubectl get pod` と `kubectl describe pod` の違いは何ですか？ どんな場面で使い分けますか？

### 9) Next-step resources
- Pods: https://kubernetes.io/docs/concepts/workloads/pods/
- kubectl overview: https://kubernetes.io/docs/reference/kubectl/
- Debug running Pods: https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/

---

## Middle — Deployment で安全に更新する

### Prerequisites
- Pod の基本が分かる
- `kubectl get / describe / logs` を一通り使える

### 1) Topic + Level
**Topic:** Deployment でアプリを複数レプリカ運用し、ローリングアップデートを試す
**Level:** Middle

### 2) Why it matters for real app development
現実のアプリは Pod を1個だけ手で起動して終わりではない。バージョン更新、レプリカ管理、障害時の再作成まで含めて運用する必要がある。Deployment は Web アプリや API の標準的な入口。

### 3) Core kubectl/Kubernetes concept explanations
- **Deployment**: Pod の望ましい状態を管理する。
- **ReplicaSet**: 指定数の Pod を維持する実体。
- **RollingUpdate**: 無停止に近い形で新バージョンへ置き換える方式。
- **kubectl apply**: YAML に書いた望ましい状態を反映する。
- **kubectl rollout**: 更新状況や履歴を確認する。

### 4) How Kubernetes is used while building apps
アプリ開発では、Docker イメージをビルドしてレジストリへ push し、Deployment のイメージタグを書き換えて反映する流れが多い。公式のベストプラクティスに沿うなら、手打ちの一発変更よりも YAML を管理し、`apply` と `rollout status` で更新確認する方が安全。

### 5) 30-60 minute hands-on mini lab
**目標:** Deployment を作成し、イメージ更新とロールアウト確認を行う。

1. 以下の YAML を `deployment-nginx.yaml` として保存する
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-deploy
  namespace: magazine-lab
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
        - name: nginx
          image: nginx:1.27
          ports:
            - containerPort: 80
```

2. 適用する
```bash
kubectl apply -f deployment-nginx.yaml
```

3. 状態を見る
```bash
kubectl get deploy -n magazine-lab
kubectl get rs -n magazine-lab
kubectl get pods -n magazine-lab -l app=web
```

4. ロールアウト状況を確認する
```bash
kubectl rollout status deployment/web-deploy -n magazine-lab
```

5. イメージを更新する
```bash
kubectl set image deployment/web-deploy nginx=nginx:1.28 -n magazine-lab
```

6. 更新状況と履歴を見る
```bash
kubectl rollout status deployment/web-deploy -n magazine-lab
kubectl rollout history deployment/web-deploy -n magazine-lab
```

7. 失敗を試すなら、存在しないタグへ更新して観察する
```bash
kubectl set image deployment/web-deploy nginx=nginx:nope -n magazine-lab
kubectl rollout status deployment/web-deploy -n magazine-lab
kubectl describe deploy web-deploy -n magazine-lab
```

### 6) Command cheatsheet
```bash
kubectl apply -f deployment-nginx.yaml
kubectl get deploy,rs,pods -n magazine-lab
kubectl rollout status deployment/web-deploy -n magazine-lab
kubectl rollout history deployment/web-deploy -n magazine-lab
kubectl set image deployment/web-deploy nginx=nginx:1.28 -n magazine-lab
kubectl rollout undo deployment/web-deploy -n magazine-lab
```

### 7) Common mistakes and safe practices
**よくあるミス**
- `latest` タグを使って何がデプロイされたか分からなくなる
- `kubectl apply -f .` を広いディレクトリで実行して意図しない YAML まで反映する
- selector と labels の不一致

**安全な運用**
- イメージはできれば固定タグ、理想は digest で管理する
- `apply` 前に対象ファイルと namespace を確認する
- 本番では `kubectl diff -f <file>` を挟むとかなり安全
- Secret や認証情報は ConfigMap に入れず、用途に応じて Secret や外部 secret 管理を使う

### 8) One interview-style question
**Q:** Deployment と ReplicaSet の役割の違いを説明してください。また、なぜ普段は ReplicaSet ではなく Deployment を直接扱うことが多いのでしょうか？

### 9) Next-step resources
- Deployments: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Rolling updates: https://kubernetes.io/docs/tutorials/kubernetes-basics/update/update-intro/
- kubectl apply: https://kubernetes.io/docs/reference/kubectl/generated/kubectl_apply/

---

## Advanced — Service と宣言的運用をつなげる

### Prerequisites
- Deployment の基本を理解している
- YAML を使った `kubectl apply` と `rollout status` を使える
- ラベルとセレクタの関係を理解している

### 1) Topic + Level
**Topic:** Service で Deployment を安定公開し、アプリ接続の土台を理解する
**Level:** Advanced

### 2) Why it matters for real app development
Pod は入れ替わる。だからアプリ同士の通信先を Pod IP に固定してはいけない。Service を使うと、フロントエンドから API、API から内部サービスへの接続が安定する。これはマイクロサービスでもモノリス分割でも重要。

### 3) Core kubectl/Kubernetes concept explanations
- **Service**: Pod 群への安定したアクセス入口。
- **ClusterIP**: クラスタ内部向けの標準 Service 種別。
- **Labels / Selectors**: Service がどの Pod にトラフィックを送るか決める。
- **Endpoints / EndpointSlices**: Service の背後にいる実体 Pod 群。
- **port / targetPort**: Service 側ポートとコンテナ側ポートの対応。

### 4) How Kubernetes is used while building apps
アプリ開発では、Deployment で実行面を管理し、Service で通信面を固定するのが定番。さらに Ingress / Gateway API を重ねて外部公開へ進む。公式ドキュメントに沿うなら、Pod 直打ちではなく Service 越しに接続し、ラベル設計を丁寧にするのが良い。

### 5) 30-60 minute hands-on mini lab
**目標:** Deployment の前に ClusterIP Service を作り、名前解決と接続確認をする。

1. 以下の YAML を `service-nginx.yaml` として保存する
```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-svc
  namespace: magazine-lab
spec:
  selector:
    app: web
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
```

2. Service を作成する
```bash
kubectl apply -f service-nginx.yaml
```

3. Service と endpoints を確認する
```bash
kubectl get svc -n magazine-lab
kubectl get endpoints -n magazine-lab
kubectl get endpointslices -n magazine-lab
```

4. 一時的な curl Pod を作って疎通確認する
```bash
kubectl run curlbox \
  --image=curlimages/curl:8.8.0 \
  -n magazine-lab \
  --restart=Never \
  --command -- sleep 3600
```

5. Service 名でアクセスする
```bash
kubectl exec -it curlbox -n magazine-lab -- sh
curl http://web-svc
exit
```

6. ラベルをわざと変更し、Service が Pod を見失う挙動を観察する
```bash
kubectl label pod <pod-name> app=broken -n magazine-lab --overwrite
kubectl get endpoints -n magazine-lab
```
その後、元に戻す。

### 6) Command cheatsheet
```bash
kubectl apply -f service-nginx.yaml
kubectl get svc -n magazine-lab
kubectl get endpoints -n magazine-lab
kubectl get endpointslices -n magazine-lab
kubectl exec -it curlbox -n magazine-lab -- sh
kubectl port-forward svc/web-svc 8080:80 -n magazine-lab
```

### 7) Common mistakes and safe practices
**よくあるミス**
- Service の selector と Pod ラベルが一致していない
- `port` と `targetPort` を混同する
- `kubectl expose` だけで済ませて YAML を残さず、再現性を失う
- クラスタ全体へ影響する `kubectl delete -A` や広すぎる `apply` を軽く実行する

**安全な運用**
- 接続不良時は `svc` → `endpoints` → `pod labels` の順で確認する
- 外部公開前にまず ClusterIP で内部疎通確認する
- Secret、証明書、API キーを manifest に平文で置かない
- `kubectl config current-context` と `kubectl get ns` を先に見る癖をつける
- 破壊的コマンド前には「どの context / namespace / ファイルに効くか」を声に出すレベルで確認する

### 8) One interview-style question
**Q:** なぜ Kubernetes では Pod IP に直接依存せず、Service を介して通信する設計が推奨されるのでしょうか？

### 9) Next-step resources
- Services: https://kubernetes.io/docs/concepts/services-networking/service/
- Service networking tutorial: https://kubernetes.io/docs/tutorials/kubernetes-basics/expose/expose-intro/
- Labels and selectors: https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/
- Recommended labels: https://kubernetes.io/docs/concepts/overview/working-with-objects/common-labels/

---

## 実務でのまとめ
今日の流れはかなり実務寄り。

- **Beginner:** Pod を読めるようになる
- **Middle:** Deployment で安全に更新できるようになる
- **Advanced:** Service で安定した通信経路を作れるようになる

この3つがつながると、アプリを Kubernetes 上で「起動する」「更新する」「つなぐ」の最小ループが回せる。開発現場ではこのループがそのまま障害対応・機能追加・リリース確認の基礎になる。

---

## 安全メモ
- `kubectl delete` は対象を必ず明示する
- `kubectl apply -f .` はスコープ事故を起こしやすいので慎重に使う
- `kubectl config current-context` を毎回確認する
- 本番での変更前は `kubectl diff` と対象 namespace 確認を挟む
- Secret を YAML に平文で置かない

---

## 明日の予告
次は **ConfigMap / Secret / 環境変数注入** に進むと、アプリ設定を Kubernetes らしく扱えるようになる。