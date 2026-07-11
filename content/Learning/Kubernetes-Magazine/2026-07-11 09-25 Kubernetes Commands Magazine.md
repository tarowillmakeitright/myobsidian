---
tags:
  - kubernetes
  - k8s
  - devops
  - learning
  - daily
---

# 2026-07-11 Kubernetes Commands Magazine

[[Home]]

#kubernetes #k8s #devops #learning #daily

## 今回のテーマ
**kubectl で Deployment / Service / ConfigMap を安全に扱い、アプリ開発の土台を作る**

この号は、ローカル開発や検証クラスターでよく使う基本操作から始めて、実務で重要な「設定の外出し」「安全な apply」「トラブルシュート」へ段階的に進みます。

---

## Beginner｜Deployment と Pod の基本観察

### 1) Topic + Level
**トピック:** `kubectl get / describe / logs` でアプリの状態を読む  
**レベル:** Beginner

### 2) なぜ実アプリ開発で重要か
アプリを Kubernetes に載せると、まず必要になるのは「いま何が動いているか」を把握する力です。ローカルでは動いていたアプリでも、コンテナ化・クラスタ配置後は以下のような問題が起きます。

- Pod が起動しない
- ImagePull に失敗する
- 環境変数不足でクラッシュする
- readiness/liveness の不整合で Service から疎通できない

`kubectl get` / `describe` / `logs` は、開発者が最初に身につけるべき観察系コマンドです。闇雲に再 apply する前に、状態を読む習慣が品質と安全性を上げます。

### 3) コア概念
- **Pod**: コンテナを動かす最小単位
- **Deployment**: Pod を望ましい数・更新戦略で維持する宣言的リソース
- **ReplicaSet**: Deployment が裏で管理する Pod 集合
- **kubectl get**: 一覧確認
- **kubectl describe**: 詳細・イベント確認
- **kubectl logs**: アプリ標準出力の確認

### 4) アプリ開発での使われ方
Kubernetes のベストプラクティスでは、アプリ設定・公開方法・ヘルスチェック・ロールアウトを分離して管理します。開発中は特に以下が重要です。

- **まず Deployment の状態を見る**
- **イベントを見て原因を特定する**
- **アプリログとクラスタイベントを分けて考える**
- **再現性のある YAML と宣言的 apply を使う**

これは kubernetes.io/docs の「宣言的管理」「ワークロード管理」「トラブルシュート」の考え方に沿っています。

### 5) 30-60分ミニラボ
**目標:** nginx Deployment を作り、状態確認コマンドに慣れる

**前提:**
- kind / minikube / Docker Desktop Kubernetes などの検証環境
- `kubectl config current-context` で接続先確認済み

**手順:**

1. 作業用 Namespace を作る
```bash
kubectl create namespace k8s-magazine
```

2. Deployment を作る
```bash
kubectl -n k8s-magazine create deployment web --image=nginx:1.27
```

3. 状態を見る
```bash
kubectl -n k8s-magazine get deploy,pods,rs -o wide
kubectl -n k8s-magazine describe deployment web
kubectl -n k8s-magazine logs deploy/web
```

4. Pod 名を確認して詳細を見る
```bash
kubectl -n k8s-magazine get pods
kubectl -n k8s-magazine describe pod <pod-name>
```

5. レプリカ数を増やす
```bash
kubectl -n k8s-magazine scale deployment web --replicas=3
kubectl -n k8s-magazine get pods -w
```

6. 監視を止めたら最終状態を確認
```bash
kubectl -n k8s-magazine get deploy,pods
```

**学びどころ:**
- Deployment を増やすと Pod が自動で増える
- `describe` の Events がかなり重要
- `logs` は「アプリの声」、`describe` は「クラスタの声」

### 6) Command Cheatsheet
```bash
kubectl config current-context
kubectl get ns
kubectl -n k8s-magazine get deploy,pods,rs
kubectl -n k8s-magazine describe deployment web
kubectl -n k8s-magazine logs deploy/web
kubectl -n k8s-magazine scale deployment web --replicas=3
kubectl -n k8s-magazine get pods -w
```

### 7) よくあるミスと安全策
**よくあるミス**
- Namespace を付け忘れて別環境を見ている
- `logs` だけ見て Events を見ない
- `kubectl apply` を何度も打って原因調査を飛ばす

**安全策**
- 実行前に必ず `kubectl config current-context` を確認
- 可能なら `-n <namespace>` を明示する
- `delete` や広い `apply -f .` の前に対象を目視する
- 本番クラスタでは `kubectl delete pod ...` を軽く打たない

### 8) 面接っぽい質問
**Q. `kubectl logs` と `kubectl describe pod` は何が違い、どちらを先に見るべきですか？**

### 9) 次の一歩リソース
- Overview: https://kubernetes.io/docs/concepts/overview/
- Deployments: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- kubectl overview: https://kubernetes.io/docs/reference/kubectl/
- Debug running pods: https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/

---

## Middle｜Service と ConfigMap でアプリを「使える形」にする

### 1) Topic + Level
**トピック:** Service で公開し、ConfigMap で設定を外出しする  
**レベル:** Middle

**前提知識:**
- Pod / Deployment の役割がわかる
- `kubectl get`, `describe`, `logs` を使える
- Namespace を分ける意味がわかる

### 2) なぜ実アプリ開発で重要か
アプリ開発では「動く」だけでは足りません。別コンポーネントから安定して呼べること、設定を環境ごとに切り替えられることが必要です。

- Service がないと Pod IP 変動に弱い
- 設定をイメージに焼くと dev/stg/prod の切り替えがつらい
- ConfigMap を使うとアプリ設定の責務分離がしやすい

これは 12-factor app 的な考えとも相性がよく、Kubernetes 上のアプリ運用で非常に実務的です。

### 3) コア概念
- **Service**: Pod 群への安定したアクセス入口
- **ClusterIP**: クラスタ内部向けの標準 Service 種別
- **ConfigMap**: 秘密ではない設定データ
- **環境変数注入 / volume mount**: アプリへ設定を渡す代表パターン

> 注意: **秘密情報は ConfigMap に入れない**。API キーやパスワードは Secret 等で扱い、Git に平文で置かない。

### 4) アプリ開発での使われ方
実務では以下の流れが定番です。

- アプリ本体は Deployment
- 通信入口は Service
- 設定値は ConfigMap
- 秘密値は Secret
- Ingress/Gateway は後段で追加

ベストプラクティスとして、設定変更が多い値はマニフェストからアプリ本体イメージを分離し、環境差分を YAML 側で管理します。

### 5) 30-60分ミニラボ
**目標:** ConfigMap を使う Deployment を作り、Service 経由で疎通確認する

**手順:**

1. ConfigMap を作る
```bash
kubectl -n k8s-magazine create configmap web-config \
  --from-literal=APP_ENV=dev \
  --from-literal=APP_MESSAGE='hello from configmap'
```

2. 以下の YAML を `web-config-demo.yaml` として保存
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-config-demo
  namespace: k8s-magazine
spec:
  replicas: 2
  selector:
    matchLabels:
      app: web-config-demo
  template:
    metadata:
      labels:
        app: web-config-demo
    spec:
      containers:
        - name: app
          image: busybox:1.36
          command: ["sh", "-c"]
          args:
            - |
              while true; do
                echo "APP_ENV=${APP_ENV} APP_MESSAGE=${APP_MESSAGE}";
                nc -lk -p 8080 -e echo "ok from ${APP_ENV}";
              done
          env:
            - name: APP_ENV
              valueFrom:
                configMapKeyRef:
                  name: web-config
                  key: APP_ENV
            - name: APP_MESSAGE
              valueFrom:
                configMapKeyRef:
                  name: web-config
                  key: APP_MESSAGE
          ports:
            - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: web-config-demo
  namespace: k8s-magazine
spec:
  selector:
    app: web-config-demo
  ports:
    - port: 80
      targetPort: 8080
```

3. 適用前に差分確認
```bash
kubectl diff -f web-config-demo.yaml
```

4. 適用
```bash
kubectl apply -f web-config-demo.yaml
```

5. 確認
```bash
kubectl -n k8s-magazine get deploy,svc,pods
kubectl -n k8s-magazine describe svc web-config-demo
kubectl -n k8s-magazine logs deploy/web-config-demo
```

6. ポートフォワードしてアクセス
```bash
kubectl -n k8s-magazine port-forward svc/web-config-demo 8080:80
```
別ターミナルで:
```bash
curl http://127.0.0.1:8080
```

7. ConfigMap を更新して再観察
```bash
kubectl -n k8s-magazine create configmap web-config \
  --from-literal=APP_ENV=staging \
  --from-literal=APP_MESSAGE='updated config' \
  -o yaml --dry-run=client | kubectl apply -f -
```

8. 必要なら Pod 再作成で設定反映を確認
```bash
kubectl -n k8s-magazine rollout restart deployment web-config-demo
kubectl -n k8s-magazine rollout status deployment web-config-demo
```

**学びどころ:**
- Service が Pod 変動を吸収する
- ConfigMap は「秘密でない設定」の置き場
- `kubectl diff` を挟むだけで事故が減る

### 6) Command Cheatsheet
```bash
kubectl -n k8s-magazine create configmap web-config --from-literal=APP_ENV=dev
kubectl diff -f web-config-demo.yaml
kubectl apply -f web-config-demo.yaml
kubectl -n k8s-magazine get svc,endpoints
kubectl -n k8s-magazine port-forward svc/web-config-demo 8080:80
kubectl -n k8s-magazine rollout restart deployment web-config-demo
kubectl -n k8s-magazine rollout status deployment web-config-demo
```

### 7) よくあるミスと安全策
**よくあるミス**
- Secret にすべき値を ConfigMap に入れる
- Service の selector ラベルが Pod と一致していない
- `kubectl apply -f .` で関係ない YAML まで適用する

**安全策**
- 機密は Secret や外部 secret 管理を使う
- `kubectl get endpoints` で Service 接続先を確認する
- `kubectl diff` → `kubectl apply -f <file>` の順を習慣化
- apply 前にファイル対象・context・namespace を声に出して確認するくらいでちょうどいい

### 8) 面接っぽい質問
**Q. Pod に直接つながず Service を使う理由は何ですか？ ConfigMap と Secret はどう使い分けますか？**

### 9) 次の一歩リソース
- Service: https://kubernetes.io/docs/concepts/services-networking/service/
- ConfigMap: https://kubernetes.io/docs/concepts/configuration/configmap/
- Secrets: https://kubernetes.io/docs/concepts/configuration/secret/
- Declarative config: https://kubernetes.io/docs/tasks/manage-kubernetes-objects/declarative-config/

---

## Advanced｜安全な apply・rollout・トラブルシュートを実務レベルで回す

### 1) Topic + Level
**トピック:** `kubectl diff`, `rollout`, `set image`, `rollout undo` を使って安全に更新する  
**レベル:** Advanced

**前提知識:**
- Deployment / Service / ConfigMap の基本を理解している
- `kubectl apply` と YAML 管理に慣れている
- ログ確認・イベント確認の基本ができる

### 2) なぜ実アプリ開発で重要か
本番・検証環境では「変更そのもの」より「安全に変更できること」が価値になります。

- 誤った image 更新でアプリ停止
- readiness 不備でロールアウト失敗
- 別 context に誤 apply
- 不要な delete で復旧工数が増える

開発者が rollout 系コマンドを理解していると、デプロイ失敗時の切り戻しが速くなり、CI/CD の挙動理解も深まります。

### 3) コア概念
- **Declarative apply**: 望ましい状態を宣言して同期
- **kubectl diff**: 実適用前の差分確認
- **rollout status**: 更新進行状況の確認
- **set image**: コンテナイメージ更新
- **rollout undo**: 以前のリビジョンへ戻す
- **readinessProbe**: 受信可能になってからトラフィック投入

### 4) アプリ開発での使われ方
ベストプラクティスに沿うなら、開発チームは次の流れを理解しておくと強いです。

1. マニフェスト変更前に差分確認
2. 小さく apply
3. rollout status 監視
4. logs / describe / events で異常確認
5. 必要なら rollback

これは GitOps や CI/CD にも直結する基礎で、単に `kubectl apply` を知っているだけより一段実務寄りです。

### 5) 30-60分ミニラボ
**目標:** 意図的に更新し、状態確認とロールバックを試す

**手順:**

1. 現在イメージを確認
```bash
kubectl -n k8s-magazine get deployment web -o jsonpath='{.spec.template.spec.containers[0].image}'
echo
```

2. 安全な更新を実施
```bash
kubectl -n k8s-magazine set image deployment/web nginx=nginx:1.27.1
kubectl -n k8s-magazine rollout status deployment/web
```

3. 履歴確認
```bash
kubectl -n k8s-magazine rollout history deployment/web
```

4. わざと存在しないタグにして失敗を観察
```bash
kubectl -n k8s-magazine set image deployment/web nginx=nginx:does-not-exist
kubectl -n k8s-magazine rollout status deployment/web --timeout=60s
```

5. 原因確認
```bash
kubectl -n k8s-magazine get pods
kubectl -n k8s-magazine describe pod <failing-pod-name>
kubectl -n k8s-magazine get events --sort-by=.metadata.creationTimestamp
```

6. ロールバック
```bash
kubectl -n k8s-magazine rollout undo deployment/web
kubectl -n k8s-magazine rollout status deployment/web
```

7. 最後に履歴再確認
```bash
kubectl -n k8s-magazine rollout history deployment/web
```

**発展:**
- readinessProbe を追加してロールアウト挙動を見る
- `kubectl apply --server-side -f ...` の用途を調べる
- CI/CD でどこまで自動化すべきか考える

### 6) Command Cheatsheet
```bash
kubectl diff -f deployment.yaml
kubectl apply -f deployment.yaml
kubectl -n k8s-magazine set image deployment/web nginx=nginx:1.27.1
kubectl -n k8s-magazine rollout status deployment/web
kubectl -n k8s-magazine rollout history deployment/web
kubectl -n k8s-magazine rollout undo deployment/web
kubectl -n k8s-magazine get events --sort-by=.metadata.creationTimestamp
```

### 7) よくあるミスと安全策
**よくあるミス**
- `kubectl apply -f .` をクラスタルート相当で実行
- context を間違えて本番に apply
- `delete namespace` や `delete all --all` を軽く実行
- rollout 失敗中に原因確認せず再更新する

**安全策**
- **破壊的コマンド前に必ず警告レベルで確認すること**
  - `kubectl delete ...`
  - `kubectl delete namespace ...`
  - `kubectl delete all --all -n ...`
  - 広範囲 `kubectl apply -f .`
- 実行前チェック:
```bash
kubectl config current-context
kubectl config view --minify --output 'jsonpath={..namespace}' ; echo
```
- 変更前に `kubectl diff` を使う
- 本番ではレビュー済み YAML / CI 経由を優先する
- Secret を manifest に平文で置かない

### 8) 面接っぽい質問
**Q. `kubectl apply` と `kubectl set image` はどう使い分けますか？ ロールアウト失敗時にどの順で調査しますか？**

### 9) 次の一歩リソース
- Rolling updates: https://kubernetes.io/docs/tutorials/kubernetes-basics/update/update-intro/
- Deployment rollout: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#rolling-back-a-deployment
- Probes: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/
- Debug applications: https://kubernetes.io/docs/tasks/debug/debug-application/
- kubectl cheatsheet: https://kubernetes.io/docs/reference/kubectl/cheatsheet/

---

## 今日のまとめ
- Beginner では **観察系 kubectl** を固める
- Middle では **Service と ConfigMap** でアプリを実用形にする
- Advanced では **安全な更新とロールバック** を身につける

Kubernetes は「コマンド暗記」より、**宣言的に管理しつつ、観察して、安全に変える** という筋力が大事です。今日のラボはその基礎としてかなり実戦的です。

## 明日への布石
次回はこの流れを引き継いで、以下に進むと自然です。

- Ingress / Gateway API 入門
- readiness/liveness probe 設計
- Resource requests/limits と HPA の基礎
- Secret 管理と external secret パターン
