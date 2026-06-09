---
tags:
  - kubernetes
  - k8s
  - devops
  - learning
  - daily
---

[[Home]]

# Kubernetes Commands Magazine — 2026-06-09

## 今日のテーマ
**Topic:** `kubectl apply` と Declarative Config の基本から、`Deployment` の更新運用まで  
**Learning Arc:** Beginner → Middle → Advanced

---

# Beginner

## 1) Topic + Level
**Level:** Beginner  
**Topic:** `kubectl apply -f` で Deployment と Service を安全に作る

## 2) なぜ実アプリ開発で重要か
アプリ開発では、ローカルで動いたものを**再現可能な形で環境へ反映**できることが重要です。`kubectl apply` と YAML マニフェストを使うと、Web API やフロントエンド、バックエンドを「今どうあるべきか」で管理できます。これはチーム開発、CI/CD、レビュー、障害対応の土台になります。

## 3) コア概念の説明
- **Manifest**: Kubernetes リソースの定義ファイル。通常は YAML。
- **Declarative management**: 「どう作るか」ではなく「どうあるべきか」を宣言する管理方法。
- **Deployment**: Pod の望ましい状態を維持し、ローリングアップデートも担当する。
- **Service**: Pod 群への安定したアクセス経路を提供する。
- **`kubectl apply`**: マニフェストとの差分をもとに安全に状態を反映する基本コマンド。

## 4) アプリ開発での使われ方
実務では、アプリの Docker イメージをビルドしたあと、Deployment の `image:` を更新し、Service で通信経路を固定します。Kubernetes 公式ドキュメントの考え方に沿うなら、
- マニフェストは Git で管理する
- 1回限りの手作業よりも再現可能な宣言的運用を優先する
- Secret を平文で埋め込まない
- 名前空間やラベルを整備して管理しやすくする
という流れが基本です。

## 5) 30–60分ミニラボ
**目標:** NGINX Deployment と Service を作成し、`apply` / `get` / `describe` / `rollout` の基本を確認する。  
**前提:** `kubectl` が使えるローカル検証環境（minikube, kind, Docker Desktop Kubernetes など）

### 手順
1. 作業用ディレクトリを作る
2. Deployment マニフェストを作成する
3. Service マニフェストを作成する
4. `kubectl apply -f` で反映する
5. `kubectl get` と `kubectl describe` で状態確認する
6. レプリカ数を変更して再度 `apply` する
7. `rollout status` で反映を確認する

### 例: `deployment.yaml`
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-demo
  labels:
    app: web-demo
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

### 例: `service.yaml`
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
  type: ClusterIP
```

### 実行例
```bash
mkdir -p k8s-magazine-lab && cd k8s-magazine-lab

kubectl apply -f deployment.yaml
kubectl apply -f service.yaml

kubectl get deployments
kubectl get pods -l app=web-demo
kubectl get svc web-demo
kubectl describe deployment web-demo
kubectl rollout status deployment/web-demo
```

### 追加演習
`replicas: 2` を `3` に変えて再度 `kubectl apply -f deployment.yaml` を実行し、Pod 数が増えることを確認する。

## 6) Command Cheatsheet
```bash
kubectl config current-context
kubectl get namespaces
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl get all
kubectl get pods -o wide
kubectl describe deployment web-demo
kubectl logs -l app=web-demo
kubectl rollout status deployment/web-demo
```

## 7) よくあるミスと安全策
- **間違った context に apply する**  
  → 先に `kubectl config current-context` を確認する。
- **`kubectl apply -f .` の範囲をよく見ない**  
  → 予期しない YAML まで反映する事故がある。対象ファイルを明示する。
- **Secret を Deployment YAML に直書きする**  
  → 平文で Git に残るので避ける。Secret リソースや外部 Secret 管理を使う。
- **ラベルと selector の不一致**  
  → Service が Pod を拾えず通信できない。`app:` ラベルを統一する。
- **削除系コマンドを軽く打つ**  
  → `kubectl delete -f ...` や `kubectl delete deployment ...` は対象と context を再確認してから実行する。

## 8) 面接っぽい質問
**質問:** `kubectl create` ではなく `kubectl apply` が継続運用で好まれる理由は何ですか？

## 9) 次の一歩リソース
- Kubernetes 公式: Overview  
  https://kubernetes.io/docs/concepts/overview/
- Kubernetes 公式: Deployments  
  https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Kubernetes 公式: Declarative Management  
  https://kubernetes.io/docs/tasks/manage-kubernetes-objects/declarative-config/

---

# Middle

## 1) Topic + Level
**Level:** Middle  
**Topic:** `kubectl rollout` と Deployment 更新の安全運用

**Prerequisites:**
- Pod / Deployment / Service の基本が分かる
- `kubectl apply` で YAML を反映した経験がある
- ラベルと selector の役割を理解している

## 2) なぜ実アプリ開発で重要か
実サービスでは「デプロイできる」だけでは不十分で、**止めずに更新し、問題があれば戻せること**が必要です。Deployment の rollout 管理は、API サーバー更新、フロントエンド差し替え、バッチ基盤更新などで日常的に使います。

## 3) コア概念の説明
- **RollingUpdate**: 既存 Pod を一気に壊さず、段階的に新しい Pod へ置き換える。
- **`kubectl rollout status`**: 更新進行状況を確認する。
- **`kubectl rollout history`**: Deployment の更新履歴を見る。
- **`kubectl rollout undo`**: 問題があった変更を前の Revision に戻す。
- **Readiness Probe**: Pod がトラフィックを受けられる準備完了かを示す。安全な rollout の要。

## 4) アプリ開発での使われ方
アプリ更新時、コンテナイメージタグを変更して `apply` し、`rollout status` で反映確認、異常時は `undo` する、という流れは現場でかなり基本です。特に readiness probe がないと、起動直後でまだ使えない Pod にトラフィックが流れて障害を起こしやすくなります。

## 5) 30–60分ミニラボ
**目標:** イメージ更新、rollout 監視、履歴確認、ロールバックを体験する。

### 例: readiness probe 付き Deployment
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-demo
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 1
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

### 実行例
```bash
kubectl apply -f deployment.yaml
kubectl rollout status deployment/web-demo

kubectl set image deployment/web-demo nginx=nginx:1.27.1
kubectl rollout status deployment/web-demo
kubectl rollout history deployment/web-demo

kubectl get pods -l app=web-demo
kubectl describe deployment web-demo
```

### ロールバック演習
1. 存在しないタグや不適切な設定へ変更してみる（検証環境限定）
2. rollout が失敗する様子を確認する
3. `undo` で戻す

```bash
kubectl set image deployment/web-demo nginx=nginx:does-not-exist
kubectl rollout status deployment/web-demo
kubectl rollout undo deployment/web-demo
kubectl rollout status deployment/web-demo
```

## 6) Command Cheatsheet
```bash
kubectl set image deployment/web-demo nginx=nginx:1.27.1
kubectl rollout status deployment/web-demo
kubectl rollout history deployment/web-demo
kubectl rollout undo deployment/web-demo
kubectl describe rs
kubectl get events --sort-by=.metadata.creationTimestamp
```

## 7) よくあるミスと安全策
- **`:latest` を使う**  
  → 再現性が落ちる。固定タグや digest を優先する。
- **readiness probe なしで更新する**  
  → 起動途中 Pod にトラフィックが流れる。最低限の probe は入れる。
- **本番で直接 `set image` だけして終わる**  
  → Git 管理の manifest とズレる。後で必ず定義ファイルへ反映する。
- **失敗時に原因を見ず即 undo する**  
  → 復旧は大事だが、`describe`, `events`, `logs` で原因確認も必要。
- **広い権限の kubeconfig を使い回す**  
  → 誤操作範囲が増える。環境ごとに context / 権限を分ける。

## 8) 面接っぽい質問
**質問:** Readiness Probe がない Deployment で RollingUpdate をすると、どんな運用リスクがありますか？

## 9) 次の一歩リソース
- Kubernetes 公式: Update a Deployment  
  https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#updating-a-deployment
- Kubernetes 公式: Probes  
  https://kubernetes.io/docs/concepts/configuration/liveness-readiness-startup-probes/
- Kubernetes 公式: kubectl Cheat Sheet  
  https://kubernetes.io/docs/reference/kubectl/cheatsheet/

---

# Advanced

## 1) Topic + Level
**Level:** Advanced  
**Topic:** Namespace・ConfigMap・Secret 分離と `kubectl diff` を使った安全な変更管理

**Prerequisites:**
- Deployment / Service / rollout の基本が理解できる
- YAML ベースで複数リソースを扱ったことがある
- Kubernetes の namespace 概念を知っている

## 2) なぜ実アプリ開発で重要か
実務では、開発・検証・本番の環境差分、設定値の分離、変更前レビューが非常に重要です。特に複数人チームでは、**変更を apply する前に差分を見ること**、**機密値を manifest に直書きしないこと**、**namespace で安全に分離すること**が事故防止に直結します。

## 3) コア概念の説明
- **Namespace**: リソースの論理分離。環境・チーム単位の整理に役立つ。
- **ConfigMap**: 機密でない設定値を外出しする。
- **Secret**: 機密情報を扱うためのリソース。ただし base64 は暗号化ではない点に注意。
- **`kubectl diff`**: apply 前に差分確認できる。安全なレビューに有効。
- **`-n` / `--namespace`**: 操作対象の namespace を明示する重要オプション。

## 4) アプリ開発での使われ方
現場では、アプリコードとインフラ定義を Git 管理し、環境ごとの設定は ConfigMap/Secret で分離します。変更時は `kubectl diff -f` で差分確認し、意図しない replica 数変更や image 変更、ラベル変更を見落とさないようにします。Kubernetes 公式のベストプラクティスに沿うなら、Secret は専用管理、namespace 分離、最小権限、宣言的管理が基本です。

## 5) 30–60分ミニラボ
**目標:** namespace を切り、ConfigMap を参照する Deployment を作成し、`kubectl diff` と安全な apply を試す。

### 例: namespace
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: magazine-lab
```

### 例: configmap
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: web-config
  namespace: magazine-lab
data:
  APP_MODE: "staging"
  LOG_LEVEL: "info"
```

### 例: deployment
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
          image: nginx:1.27
          envFrom:
            - configMapRef:
                name: web-config
          ports:
            - containerPort: 80
```

### 実行例
```bash
kubectl apply -f namespace.yaml
kubectl apply -f configmap.yaml
kubectl diff -f deployment.yaml
kubectl apply -f deployment.yaml

kubectl get all -n magazine-lab
kubectl get configmap -n magazine-lab
kubectl describe deployment web-demo -n magazine-lab
```

### 発展演習
- `LOG_LEVEL` を `debug` に変えて `kubectl diff -f configmap.yaml` を確認する
- namespace を省略した場合にどこへ作られるか確認する
- Secret を使うべき値と ConfigMap でよい値を整理する

## 6) Command Cheatsheet
```bash
kubectl create namespace magazine-lab
kubectl apply -f namespace.yaml
kubectl apply -f configmap.yaml
kubectl diff -f deployment.yaml
kubectl apply -f deployment.yaml
kubectl get all -n magazine-lab
kubectl describe pod -n magazine-lab
kubectl config set-context --current --namespace=magazine-lab
```

## 7) よくあるミスと安全策
- **Secret を base64 だから安全と思い込む**  
  → base64 は可逆変換。機密管理の本質ではない。暗号化・外部 Secret 管理・RBAC を考える。
- **namespace 指定漏れ**  
  → default namespace に作ってしまう事故が起きやすい。`-n` 明示か current context の namespace 確認を行う。
- **`kubectl apply -f dir/` 前に差分確認しない**  
  → 意図しない変更をまとめて反映する危険がある。まず `kubectl diff`。
- **削除や再適用の対象を曖昧にする**  
  → `kubectl delete -f .` は特に危険。対象ファイル・namespace・context を必ず確認する。
- **本番 Secret をローカル検証用 manifest と混在させる**  
  → 分離する。Git へ平文投入しない。

## 8) 面接っぽい質問
**質問:** ConfigMap と Secret はどう使い分けますか？ また `kubectl diff` を運用に入れる利点は何ですか？

## 9) 次の一歩リソース
- Kubernetes 公式: Namespaces  
  https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/
- Kubernetes 公式: ConfigMap  
  https://kubernetes.io/docs/concepts/configuration/configmap/
- Kubernetes 公式: Secret  
  https://kubernetes.io/docs/concepts/configuration/secret/
- Kubernetes 公式: kubectl diff  
  https://kubernetes.io/docs/reference/kubectl/generated/kubectl_diff/

---

# 今日のまとめ
- Beginner では `kubectl apply` と Deployment / Service の基本を押さえる
- Middle では rollout / rollback / readiness probe で安全な更新を学ぶ
- Advanced では namespace 分離、ConfigMap / Secret、`kubectl diff` で事故を減らす

実務では、**宣言的管理・差分確認・安全な rollout・機密情報分離**の4点がかなり大事です。Kubernetes はコマンド暗記より、**どう安全に変更を届けるか**を理解すると一気に強くなります。
