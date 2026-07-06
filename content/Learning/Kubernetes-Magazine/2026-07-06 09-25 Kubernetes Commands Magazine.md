---
tags:
  - kubernetes
  - k8s
  - devops
  - learning
  - daily
---

[[Home]]

# Kubernetes Commands Magazine — 2026-07-06

## 今日のテーマ
**トピック:** `kubectl apply` / `kubectl get` / `kubectl describe` を軸に学ぶ「Deployment と Service の基本運用」

この号は **Beginner → Middle → Advanced** の順で、同じ題材を少しずつ深く掘る構成です。実務では「まず作る」「状態を見る」「安全に更新する」「問題を切り分ける」の反復が大事なので、その流れに合わせています。

---

# Level 1 — Beginner
## トピック
**Deployment と Service を `kubectl` で安全に作成・確認する**

## 1) なぜ実アプリ開発で重要か
アプリをローカルで動かすだけなら `node app.js` や `docker run` でも足りますが、実際の開発やチーム運用では次が必要になります。

- 同じアプリを複数 Pod で安定稼働させる
- 更新時にダウンタイムを減らす
- Pod の作り直しが起きても同じ方法で再現できる
- 開発者全員が同じ宣言的設定を共有できる

Kubernetes では、**Deployment でアプリの望ましい状態を宣言し、Service で到達先を安定化する**のが基本です。これは kubernetes.io/docs の「宣言的設定」「コントローラによる自己修復」「ラベルによる疎結合」という考え方にそのまま沿っています。

## 2) コア概念
### `kubectl apply`
YAML に書いた「望ましい状態」をクラスタへ反映します。

- `create` は最初の作成向き
- `apply` は更新も含む宣言的運用向き
- 実務では `apply` ベースのほうが差分管理しやすい

### Deployment
Pod を直接増減するのではなく、Deployment に「何個・どんな Pod を維持したいか」を書きます。

- desired state を持つ
- RollingUpdate で安全に更新しやすい
- Pod が落ちても ReplicaSet 経由で再作成される

### Service
Pod の IP は変わり得るので、アプリ利用側は Pod を直接見ないほうが安全です。

- Service は安定した入口
- `selector` で対象 Pod を選ぶ
- アプリ内通信の基本になる

### `kubectl get` と `kubectl describe`
- `get`: 一覧を素早く見る
- `describe`: より詳細に見る
  - Events
  - image pull 失敗
  - probe 異常
  - scheduling 問題

## 3) アプリ開発中にどう使うか
開発中の典型フローはこうです。

1. コンテナイメージをビルドする
2. Deployment YAML を更新する
3. `kubectl apply -f` で反映する
4. `kubectl get pods,svc,deploy` で状態確認する
5. 問題があれば `kubectl describe pod` や `kubectl logs` で調べる

ベストプラクティスとしては次を守ると事故が減ります。

- **namespace を分ける**（dev/staging/prod）
- **context を確認してから apply/delete する**
- **Secret を平文で manifest に埋めない**
- **ラベルを揃える**（`app`, `tier`, `component` など）

## 4) 30〜60分ミニラボ
前提: kind / minikube / Docker Desktop Kubernetes のいずれかでローカルクラスタがあること。

### 手順A: namespace を作る
```bash
kubectl create namespace k8s-magazine
kubectl config set-context --current --namespace=k8s-magazine
```

### 手順B: Deployment を作る
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
```

適用:
```bash
kubectl apply -f deployment.yaml
kubectl get deployment,pods
```

### 手順C: Service を作る
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

適用:
```bash
kubectl apply -f service.yaml
kubectl get svc
```

### 手順D: 詳細確認
```bash
kubectl describe deployment web-demo
kubectl describe svc web-demo
kubectl get pods -o wide
```

### 手順E: ロールアウトの変化を見る
```bash
kubectl set image deployment/web-demo nginx=nginx:1.27.1
kubectl rollout status deployment/web-demo
kubectl get pods
```

## 5) コマンドチートシート
```bash
kubectl config current-context
kubectl config view --minify
kubectl get ns
kubectl get deploy,pods,svc
kubectl describe deployment web-demo
kubectl describe pod <pod-name>
kubectl logs <pod-name>
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl rollout status deployment/web-demo
kubectl set image deployment/web-demo nginx=nginx:1.27.1
```

## 6) よくあるミスと安全策
### ミス
- 本番 context のまま `apply` する
- `default` namespace に何でも入れる
- Pod 名で追いかけて、再作成後に混乱する
- Secret を YAML に直書きする

### 安全策
- 実行前に毎回これを確認する
```bash
kubectl config current-context
kubectl get ns
```
- `apply` 前に対象ファイルを見直す
- `delete` 系は特に scope/context を声に出して確認する
- 機密情報は Secret や外部 secret 管理を使い、Git に載せない

> **注意:** `kubectl delete -f ...` や `kubectl delete deployment ...` は破壊的です。対象 namespace / context を確認してから実行してください。

## 7) 面接っぽい一問
**質問:** Deployment と Pod を直接作る場合の違いは何ですか？

**考えるポイント:** 自己修復、スケーリング、宣言的更新、運用の再現性。

## 8) 次の学習リソース
- Kubernetes Concepts Overview  
  https://kubernetes.io/docs/concepts/overview/
- Deployment  
  https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Service  
  https://kubernetes.io/docs/concepts/services-networking/service/
- kubectl Overview  
  https://kubernetes.io/docs/reference/kubectl/

---

# Level 2 — Middle
## 前提知識
- Deployment と Service の役割が分かる
- `kubectl get` / `describe` / `apply` の基本操作ができる
- YAML の基本構造が読める

## トピック
**RollingUpdate・ラベル・セレクタを理解して安全にアプリ更新する**

## 1) なぜ実アプリ開発で重要か
実務では「作る」より「更新する」回数のほうが圧倒的に多いです。バージョン更新、設定変更、スケール変更のたびに、**止めずに・壊さずに・戻せること** が重要になります。

Deployment の RollingUpdate と、Service の selector の理解が浅いと次の事故が起きます。

- 更新後に新旧 Pod が想定外に混在する
- Service が Pod を拾えず通信断になる
- ラベル設計が雑で別アプリに誤接続する

## 2) コア概念
### ラベルとセレクタ
Kubernetes は多くの関連付けをラベルで行います。

例:
- Deployment → Pod template labels
- Service → selector

この整合性が崩れると、Service が Pod を見つけられません。

### RollingUpdate
Deployment は更新時に Pod を少しずつ入れ替えます。

主な利点:
- 一気に全停止しにくい
- 状態を見ながら進められる
- `rollout undo` で戻しやすい

### rollout status / history / undo
- `kubectl rollout status deployment/<name>`: 進行確認
- `kubectl rollout history deployment/<name>`: 履歴確認
- `kubectl rollout undo deployment/<name>`: ロールバック

## 3) アプリ開発中にどう使うか
アプリ開発では CI/CD から image tag を更新し、Deployment に反映する形が一般的です。

ベストプラクティス寄りの考え方:

- `latest` タグに依存しすぎない
- ラベルをチームで標準化する
- readinessProbe が通るまでトラフィックを流さない設計にする
- rollout の観察を自動化して「更新しただけ」で終わらせない

## 4) 30〜60分ミニラボ
### 手順A: Service セレクタ確認
```bash
kubectl get svc web-demo -o yaml
kubectl get pods --show-labels
```

Service の selector と Pod の labels が一致しているか確認します。

### 手順B: ラベルを少し拡張した Deployment に更新
`deployment.yaml`
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-demo
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web-demo
      tier: frontend
  template:
    metadata:
      labels:
        app: web-demo
        tier: frontend
    spec:
      containers:
        - name: nginx
          image: nginx:1.27.1
          ports:
            - containerPort: 80
```

適用:
```bash
kubectl apply -f deployment.yaml
kubectl rollout status deployment/web-demo
kubectl get pods --show-labels
```

### 手順C: 更新履歴を見る
```bash
kubectl rollout history deployment/web-demo
```

### 手順D: あえてミスを観察する
Service の selector に存在しないラベルを一時的に設定する前に、**ローカルファイルを複製して検証用に使う**。

例（危険な実験なので dev 環境のみ）:
```yaml
selector:
  app: web-demo
  tier: backend
```

反映後に:
```bash
kubectl get endpoints web-demo
kubectl describe svc web-demo
```

エンドポイントが空になり得ることを確認したら、すぐ元に戻します。

### 手順E: ロールバック
```bash
kubectl rollout undo deployment/web-demo
kubectl rollout status deployment/web-demo
```

## 5) コマンドチートシート
```bash
kubectl get pods --show-labels
kubectl get svc web-demo -o yaml
kubectl get endpoints web-demo
kubectl rollout status deployment/web-demo
kubectl rollout history deployment/web-demo
kubectl rollout undo deployment/web-demo
kubectl scale deployment web-demo --replicas=3
```

## 6) よくあるミスと安全策
### ミス
- `selector` と `labels` の不一致
- `:latest` で更新差分が追えない
- readiness を考えず更新して不安定化
- dev で試した YAML をそのまま prod へ反映

### 安全策
- ラベル命名規則を決める
- image tag は明示する
- 変更前に `kubectl diff -f <file>` を活用する
- namespace ごとにファイルや Kustomize/Helm 値を分ける

> **注意:** `kubectl apply -f .` は便利ですが、カレントディレクトリ配下の意図しない manifest まで反映する事故が起きます。適用対象を狭く保つほうが安全です。

## 7) 面接っぽい一問
**質問:** Service が Pod にトラフィックを送れないとき、最初に何を確認しますか？

**考えるポイント:** selector、labels、endpoints、Pod Ready 状態。

## 8) 次の学習リソース
- Labels and Selectors  
  https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/
- Updating a Deployment  
  https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#updating-a-deployment
- kubectl rollout  
  https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#rollout

---

# Level 3 — Advanced
## 前提知識
- Deployment / Service / labels / rollout の基本が分かる
- `kubectl logs` や `describe` で問題の切り分けができる
- namespace と context の重要性を理解している

## トピック
**Probe・リソース要求・Config/Secret 分離を踏まえた本番寄り運用**

## 1) なぜ実アプリ開発で重要か
本番で問題になるのは「とりあえず動く」よりも、**壊れ方が予測できるか** です。

- コンテナは起動したが準備完了前に通信を受けて失敗する
- リソース指定が甘く、隣のワークロードと取り合う
- 設定値や認証情報を image や plain YAML に埋めて漏れる

Kubernetes のベストプラクティスでは、アプリの可用性と安全性のために、**probes / requests & limits / Secret 分離 / 最小権限** を意識するのが重要です。

## 2) コア概念
### readinessProbe
アプリがリクエスト受付可能になってから Service 配下に入れるための仕組みです。

### livenessProbe
ハングしたコンテナを再起動させるための仕組みです。

### resources.requests / limits
スケジューリングと安定動作の基礎です。

- requests: 必要最低限
- limits: 上限

### ConfigMap と Secret
- ConfigMap: 非機密の設定
- Secret: 機密データ

ただし Secret も「YAML に平文 base64 を置けば安全」という意味ではありません。Git 管理・配布経路・RBAC・暗号化設定まで含めて考える必要があります。

## 3) アプリ開発中にどう使うか
アプリ開発では次の分離がかなり効きます。

- コード: コンテナイメージ
- 設定: ConfigMap
- 秘密情報: Secret または外部 secret manager
- 稼働条件: Deployment manifest

この分離により、同じイメージを dev/staging/prod に使い回しつつ、環境差分だけを切り替えやすくなります。

## 4) 30〜60分ミニラボ
### 手順A: ConfigMap を作る
```bash
kubectl create configmap web-demo-config \
  --from-literal=APP_MODE=dev \
  --from-literal=LOG_LEVEL=info
```

### 手順B: Secret は実データを Git に置かずに作る
```bash
kubectl create secret generic web-demo-secret \
  --from-literal=API_TOKEN='replace-me-locally'
```

> 実務では、shell 履歴・CI ログ・平文管理にも注意。より安全には Sealed Secrets や External Secrets Operator、クラウドの secret manager 連携を検討します。

### 手順C: Deployment に env / probe / resources を追加
`deployment-advanced.yaml`
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
      tier: frontend
  template:
    metadata:
      labels:
        app: web-demo
        tier: frontend
    spec:
      containers:
        - name: nginx
          image: nginx:1.27.1
          ports:
            - containerPort: 80
          env:
            - name: APP_MODE
              valueFrom:
                configMapKeyRef:
                  name: web-demo-config
                  key: APP_MODE
            - name: API_TOKEN
              valueFrom:
                secretKeyRef:
                  name: web-demo-secret
                  key: API_TOKEN
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
          resources:
            requests:
              cpu: "100m"
              memory: "128Mi"
            limits:
              cpu: "300m"
              memory: "256Mi"
```

適用:
```bash
kubectl apply -f deployment-advanced.yaml
kubectl rollout status deployment/web-demo
```

### 手順D: 状態確認
```bash
kubectl describe deployment web-demo
kubectl describe pod <pod-name>
kubectl get pod <pod-name> -o yaml
```

### 手順E: Secret の扱いを観察する
```bash
kubectl get secret web-demo-secret -o yaml
```

base64 で見えても「秘匿完了」ではないことを理解します。共有・保存・権限管理まで含めて安全設計が必要です。

## 5) コマンドチートシート
```bash
kubectl create configmap web-demo-config --from-literal=APP_MODE=dev
kubectl create secret generic web-demo-secret --from-literal=API_TOKEN='replace-me-locally'
kubectl get configmap web-demo-config -o yaml
kubectl get secret web-demo-secret -o yaml
kubectl describe pod <pod-name>
kubectl top pod
kubectl diff -f deployment-advanced.yaml
kubectl apply -f deployment-advanced.yaml
```

## 6) よくあるミスと安全策
### ミス
- readinessProbe なしで更新し、起動途中 Pod に流して失敗
- limits だけ設定して requests を忘れる
- Secret を Git にコミットする
- `kubectl apply -f .` や `kubectl delete -f .` を広いディレクトリで実行する
- `--context` や `--namespace` を意識せず本番事故

### 安全策
- probe 設計をアプリの実際の起動特性に合わせる
- requests/limits を計測ベースで決める
- Secret は manifest 直書き回避、権限最小化、監査前提で扱う
- 破壊的コマンド前に次を確認する
```bash
kubectl config current-context
kubectl config view --minify --output 'jsonpath={..namespace}'
```
- 大きな変更は `kubectl diff` と `rollout status` をセットで使う

> **重要な警告:** `kubectl delete`, `kubectl replace --force`, `kubectl apply -f .`, namespace をまたぐ一括操作は、誤 context だと深刻な障害につながります。特に本番では `--context` `--namespace` を明示し、対象リソースを最小化してください。

## 7) 面接っぽい一問
**質問:** readinessProbe と livenessProbe の違いを、実際の障害シナリオ込みで説明してください。

**考えるポイント:** 通信開始タイミング、再起動要否、誤設定時の影響。

## 8) 次の学習リソース
- Configure Liveness, Readiness and Startup Probes  
  https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/
- Resource Management for Pods and Containers  
  https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/
- Secrets  
  https://kubernetes.io/docs/concepts/configuration/secret/
- ConfigMaps  
  https://kubernetes.io/docs/concepts/configuration/configmap/
- Good Practices for Kubernetes Secrets  
  https://kubernetes.io/docs/concepts/security/secrets-good-practices/

---

## 今日の締め
今日の実務目線の要点はこれです。

- **Pod を直接いじるより Deployment を中心に考える**
- **Service は selector と labels の整合性が命**
- **更新は rollout を観察しながら進める**
- **Secret を manifest に雑に埋めない**
- **破壊的コマンドは context / namespace / scope を確認してから**

次号ではこの流れを引き継いで、`kubectl logs` / `kubectl exec` / `kubectl port-forward` を使った **トラブルシュート学習アーク** に進めると実務力がかなり上がります。