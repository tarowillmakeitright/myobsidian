---
tags: [kubernetes, k8s, devops, learning, daily]
---

# 2026-03-21 09:25 Kubernetes Commands Magazine
[[Home]]

## 今号のテーマ
**Service と Ingress でアプリを安全に外部公開する（Beginner → Middle → Advanced）**

---

## Beginner（初級）
### 1) Topic + Level
**Topic:** Pod を Service（ClusterIP / NodePort）経由で公開する基礎
**Level:** Beginner

### 2) なぜ実アプリ開発で重要か
アプリを Pod 単体で動かしても、Pod の IP は再作成で変わります。Service を使うと、安定した接続先（仮想 IP / DNS 名）を提供でき、フロントエンドや他マイクロサービスから安全に接続できます。

### 3) コア概念（kubectl / Kubernetes）
- **Pod:** アプリ実行の最小単位
- **Service:** Pod 群への安定したネットワーク入口
- **selector:** Service がどの Pod を転送先にするか決めるラベル条件
- よく使うコマンド:
  - `kubectl get pod,svc`
  - `kubectl describe svc <name>`
  - `kubectl port-forward svc/<name> 8080:80`

### 4) 実アプリ開発での使い方（ベストプラクティス寄り）
- Deployment で複数 Pod を管理し、Service で抽象化する
- Service の selector と Deployment の labels を一致させる
- まずは ClusterIP + `port-forward` でローカル検証し、不要な外部公開を避ける

### 5) 30–60分ミニラボ
**目標:** NGINX Deployment を作り、Service 経由で到達確認

1. Namespace 作成
```bash
kubectl create namespace mag-lab
kubectl config set-context --current --namespace=mag-lab
```

2. Deployment 作成
```bash
kubectl create deployment web --image=nginx:1.27
kubectl scale deployment web --replicas=2
kubectl get pods -o wide
```

3. Service 作成（ClusterIP）
```bash
kubectl expose deployment web --port=80 --target-port=80 --name=web-svc
kubectl get svc web-svc
kubectl describe svc web-svc
```

4. ローカルから確認
```bash
kubectl port-forward svc/web-svc 8080:80
# 別ターミナル
curl -I http://127.0.0.1:8080
```

5. 後片付け（※削除対象を必ず確認）
```bash
kubectl get all
kubectl delete namespace mag-lab
```

### 6) Command Cheatsheet
```bash
kubectl get pods,deploy,svc
kubectl get endpoints
kubectl describe deployment web
kubectl logs deploy/web
kubectl port-forward svc/web-svc 8080:80
```

### 7) よくあるミス & 安全策
- ミス: selector 不一致で Service に転送先がない
  - 対策: `kubectl get endpoints <svc>` が空でないか確認
- ミス: いきなり NodePort/LoadBalancer で公開
  - 対策: まず ClusterIP + port-forward で動作確認
- 安全: `kubectl delete -f ...` 前にファイル内容と namespace を再確認

### 8) 面接風質問
「Service があれば Pod IP が変わっても問題ないのはなぜですか？ kube-proxy（または実装相当）の役割も含めて説明してください。」

### 9) 次の学習リソース（公式優先）
- Service 概要: https://kubernetes.io/docs/concepts/services-networking/service/
- Service チュートリアル: https://kubernetes.io/docs/tutorials/kubernetes-basics/expose/expose-intro/

---

## Middle（中級）
**前提（Prerequisites）:**
- Deployment / Service / Label Selector を理解している
- Namespace と `kubectl describe/get/logs` で基本調査ができる

### 1) Topic + Level
**Topic:** Ingress + Ingress Controller で HTTP ルーティング
**Level:** Middle

### 2) なぜ実アプリ開発で重要か
複数サービスを 1 つの入口（ドメイン/パス）に集約できるため、フロント API や管理画面などを整理して公開できます。証明書管理（TLS）やルール管理にもつながります。

### 3) コア概念
- **Ingress:** L7（HTTP/HTTPS）ルーティング定義
- **Ingress Controller:** Ingress を実際に処理する実装（例: NGINX Ingress）
- **pathType / host / backend:** どのリクエストをどの Service へ流すか

### 4) 実アプリ開発での使い方（ベストプラクティス）
- Ingress リソースだけでは動かない（Controller 必須）
- 環境ごとに host 名を分離（dev/stg/prod）
- 段階的に TLS を有効化し、平文 HTTP 公開を最小化

### 5) 30–60分ミニラボ
**目標:** 2 つのアプリを path ベースで振り分け

1. 事前確認（Controller 有無）
```bash
kubectl get ingressclass
kubectl get pods -A | grep -i ingress
```

2. サンプルアプリを2つ作成
```bash
kubectl create ns mag-ing
kubectl config set-context --current --namespace=mag-ing
kubectl create deployment app1 --image=hashicorp/http-echo -- /http-echo -text=app1
kubectl create deployment app2 --image=hashicorp/http-echo -- /http-echo -text=app2
kubectl expose deployment app1 --port=5678
kubectl expose deployment app2 --port=5678
```

3. Ingress 作成（例）
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ing
spec:
  ingressClassName: nginx
  rules:
  - host: lab.local
    http:
      paths:
      - path: /app1
        pathType: Prefix
        backend:
          service:
            name: app1
            port:
              number: 5678
      - path: /app2
        pathType: Prefix
        backend:
          service:
            name: app2
            port:
              number: 5678
```
```bash
kubectl apply -f ingress.yaml
kubectl get ingress app-ing
kubectl describe ingress app-ing
```

4. 動作確認（環境に応じて）
- ローカル検証時は hosts 設定 + curl
- もしくは Controller の公開方法に合わせてアクセス

5. 後片付け
```bash
kubectl delete ns mag-ing
```

### 6) Command Cheatsheet
```bash
kubectl get ingress,ingressclass
kubectl describe ingress app-ing
kubectl get svc -A
kubectl get events --sort-by=.metadata.creationTimestamp
```

### 7) よくあるミス & 安全策
- ミス: Ingress Controller 未導入なのに Ingress だけ apply
  - 対策: `kubectl get ingressclass` で事前確認
- ミス: `ingressClassName` 不一致
  - 対策: Controller 側の class 名と揃える
- 安全: 本番での `kubectl apply -f .` は危険（想定外 manifest 混入）
  - 対策: 対象ファイルを明示し、`kubectl diff -f <file>` で事前差分確認

### 8) 面接風質問
「Ingress と Service（NodePort/LoadBalancer）の責務の違いを説明し、どの構成をどんな場面で選ぶか答えてください。」

### 9) 次の学習リソース
- Ingress 概要: https://kubernetes.io/docs/concepts/services-networking/ingress/
- Ingress Controllers: https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/

---

## Advanced（上級）
**前提（Prerequisites）:**
- Service / Ingress の運用経験
- readiness/liveness probe の理解
- Kubernetes Secret / ConfigMap の基本

### 1) Topic + Level
**Topic:** 本番を意識した安全公開（TLS、Secret運用、段階的ロールアウト）
**Level:** Advanced

### 2) なぜ実アプリ開発で重要か
実サービスでは「公開できる」だけで不十分です。TLS 終端、秘密情報の管理、ゼロダウンタイム更新、誤操作防止が不可欠です。ここが弱いと、情報漏えいや障害直結になります。

### 3) コア概念
- **TLS on Ingress:** HTTPS 提供
- **Secret:** 認証情報・鍵などを保存（ただし暗号化設定・RBAC前提）
- **RollingUpdate:** 無停止に近い更新
- **readinessProbe:** 受け付け可能な Pod のみトラフィック投入

### 4) 実アプリ開発での使い方（ベストプラクティス）
- Secret を Git に平文コミットしない（Sealed Secrets / External Secrets など検討）
- 最小権限 RBAC と namespace 分離
- apply 前に context/namespace を毎回確認
  - `kubectl config current-context`
  - `kubectl config view --minify | grep namespace`

### 5) 30–60分ミニラボ
**目標:** readinessProbe + RollingUpdate + Secret 参照を確認

1. Namespace 作成
```bash
kubectl create ns mag-adv
kubectl config set-context --current --namespace=mag-adv
```

2. Secret 作成（デモ）
```bash
kubectl create secret generic app-secret --from-literal=API_KEY='dummy-value'
kubectl get secret app-secret
```

3. Deployment（readinessProbe + envFrom secretRef）適用
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 1
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
        envFrom:
        - secretRef:
            name: app-secret
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 3
          periodSeconds: 5
```
```bash
kubectl apply -f deploy.yaml
kubectl rollout status deployment/web
```

4. 更新シミュレーション
```bash
kubectl set image deployment/web nginx=nginx:1.27.1
kubectl rollout status deployment/web
kubectl rollout history deployment/web
```

5. 問題時ロールバック
```bash
kubectl rollout undo deployment/web
```

6. 後片付け
```bash
kubectl delete ns mag-adv
```

### 6) Command Cheatsheet
```bash
kubectl config current-context
kubectl config get-contexts
kubectl diff -f deploy.yaml
kubectl apply -f deploy.yaml
kubectl rollout status deploy/web
kubectl rollout history deploy/web
kubectl rollout undo deploy/web
kubectl auth can-i get secrets --namespace=mag-adv
```

### 7) よくあるミス & 安全策
- ミス: Secret を manifest に直書きして Git 管理
  - 対策: Secret 管理基盤（External Secrets 等）を利用、少なくとも値は平文保存しない
- ミス: `kubectl apply -f .` を誤った context で実行
  - 対策: **実行前に context と namespace を必ず確認**、`kubectl diff` 実施
- ミス: `kubectl delete` を広いスコープで実行
  - 対策: `--namespace` 指定、`-l` ラベル絞り込み、対象を `kubectl get` で先に一覧確認

### 8) 面接風質問
「readinessProbe が不適切だと RollingUpdate 時に何が起こりますか？ 具体的な障害シナリオと改善策を説明してください。」

### 9) 次の学習リソース
- Secret: https://kubernetes.io/docs/concepts/configuration/secret/
- Deployment / Rollout: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Probes: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/
- kubectl 概要: https://kubernetes.io/docs/reference/kubectl/

---

## 安全メモ（毎号共通）
- `kubectl` 実行前に **context / namespace** を確認
- 破壊的コマンド（delete, replace, applyの広範囲指定）前に対象を明示確認
- Secret を平文で manifest/Git に置かない
- 本番操作は `kubectl diff` → `apply` の順で変更確認
