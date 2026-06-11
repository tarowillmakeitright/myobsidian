---
tags:
  - kubernetes
  - k8s
  - devops
  - learning
  - daily
---

[[Home]]

# Kubernetes Commands Magazine — 2026-06-11

## 今日のテーマ
**Topic:** Deployment を安全に更新する `kubectl rollout` / `set image` / `diff` / `apply --server-side --dry-run` の実践  
**Learning Arc:** Beginner → Middle → Advanced

---

# Beginner

## 1) Topic + Level
**Level:** Beginner  
**Topic:** `kubectl rollout status` と `kubectl rollout history` で Deployment の更新状態を読む

## 2) なぜ実アプリ開発で重要か
実アプリ開発では、コードを書くだけでは終わりません。新しいコンテナイメージを出したあとに、**ちゃんと段階的に置き換わったか・異常なく起動したか・前の版に戻せるか**を確認する必要があります。Deployment の更新を読めないと、
- リリースが終わったと思ったら一部 Pod が古いまま
- Probe 失敗で更新が止まっていた
- 本番障害時にどの revision が安全か分からない
といった事故につながります。

## 3) コア kubectl / Kubernetes 概念の説明
- **Deployment**: アプリの望ましい状態を宣言し、Pod の更新を管理するリソース。
- **RollingUpdate**: 既存 Pod を一気に消さず、段階的に新しい Pod に入れ替える更新方式。
- **ReplicaSet**: Deployment の各 revision を支える実体。履歴の裏側にいる存在。
- **`kubectl rollout status`**: 更新が完了したか、止まっているかを確認する。
- **`kubectl rollout history`**: 過去の revision を確認する。
- **Readiness Probe**: Pod が「起動済み」ではなく「トラフィックを受けてもよい」状態かを判断する。

## 4) アプリ構築中にどう使われるか
kubernetes.io のベストプラクティスに沿うと、アプリ構築時は **宣言的な manifest を軸にしつつ、rollout 状態を観測して安全に更新する** のが基本です。たとえば API サーバーの新バージョンをデプロイするとき、
- apply したらすぐ終わりにしない
- `rollout status` で更新完了を確認する
- 問題が起きたら history を確認する
- readiness/liveness を適切に定義して壊れた版を流し込まない
という流れが現実的です。

## 5) 30–60分ハンズオン・ミニラボ
**目標:** Deployment を作成し、更新の進み方と履歴を観察する。  
**前提:** kind / minikube / Docker Desktop Kubernetes など、ローカル検証クラスタがあること。

### 例: Deployment
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-rollout
spec:
  replicas: 2
  selector:
    matchLabels:
      app: web-rollout
  template:
    metadata:
      labels:
        app: web-rollout
    spec:
      containers:
        - name: web
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
kubectl config current-context
kubectl apply -f web-rollout.yaml
kubectl get deploy web-rollout
kubectl rollout status deployment/web-rollout
kubectl get rs
kubectl rollout history deployment/web-rollout
kubectl get pods -l app=web-rollout -w
```

### 観察ポイント
- rollout 完了まで待つとどんな表示になるか
- ReplicaSet がどう作られるか
- Pod が一度に全部入れ替わらず段階的に更新される前提を理解できるか

## 6) Command Cheatsheet
```bash
kubectl config current-context
kubectl get deployment
kubectl get rs
kubectl get pods -l app=web-rollout
kubectl rollout status deployment/web-rollout
kubectl rollout history deployment/web-rollout
kubectl describe deployment web-rollout
```

## 7) よくあるミスと安全策
- **apply したら成功だと思い込む**  
  → 必ず `kubectl rollout status` で完了確認。
- **context を見ずに更新確認する**  
  → 最初に `kubectl config current-context`。
- **namespace を省略して別環境を見る**  
  → 複数環境では `-n` を明示。
- **Probe を入れずに更新品質を Deployment 任せにする**  
  → readinessProbe を定義しないと壊れた版を拾いやすい。
- **広い範囲の `kubectl apply -f .` を雑に打つ**  
  → 適用対象を絞る。破壊的・広範囲な更新前には scope と context を再確認する。

## 8) 面接っぽい質問
**質問:** Deployment を更新したあと、なぜ `kubectl get pods` だけでは不十分で、`kubectl rollout status` や `history` も見るべきなのでしょうか？

## 9) 次の一歩リソース
- Kubernetes 公式: Deployments  
  https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Kubernetes 公式: kubectl Cheat Sheet  
  https://kubernetes.io/docs/reference/kubectl/cheatsheet/
- Kubernetes 公式: Configure Liveness, Readiness and Startup Probes  
  https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/

---

# Middle

## 1) Topic + Level
**Level:** Middle  
**Topic:** `kubectl set image` と `kubectl rollout undo` で安全に Deployment を進める

**Prerequisites:**
- Deployment / Pod / ReplicaSet の関係を理解している
- `kubectl rollout status` / `history` を使って状態確認できる
- コンテナイメージタグの意味を理解している

## 2) なぜ実アプリ開発で重要か
アプリ開発では、最も多い運用操作のひとつが「新しいイメージへの差し替え」です。ここで重要なのは、**変更を速く入れることより、問題発生時に安全に戻せること**です。`kubectl set image` と `rollout undo` を理解していると、
- リリース作業の観測性が上がる
- 失敗したイメージを素早くロールバックできる
- CI/CD の裏で何が起きているか説明できる
ようになります。

## 3) コア kubectl / Kubernetes 概念の説明
- **`kubectl set image`**: Deployment などのコンテナイメージを更新する。
- **revision**: 更新の履歴番号。ロールバックの基準になる。
- **`kubectl rollout undo`**: 直前または指定 revision に戻す。
- **image tag / digest**: `:latest` のような曖昧なタグより、固定タグや digest の方が再現性が高い。
- **ProgressDeadlineSeconds**: 更新が進まないときに失敗扱いにするための設定。

## 4) アプリ構築中にどう使われるか
実務では ideally GitOps や CI/CD が manifest 更新を担いますが、学習段階では `set image` を使うと **Deployment 更新の実態** を理解しやすいです。ただし本番運用では、
- 手元から直接直すより Git に戻す
- `:latest` を避ける
- Secret を manifest に平文で入れない
- ロールバック手順を事前に確認する
という基本が大切です。

## 5) 30–60分ハンズオン・ミニラボ
**目標:** イメージを更新し、更新履歴とロールバックを体験する。

### 実行例
```bash
kubectl apply -f web-rollout.yaml
kubectl rollout status deployment/web-rollout

kubectl set image deployment/web-rollout web=nginx:1.28
kubectl rollout status deployment/web-rollout
kubectl rollout history deployment/web-rollout
kubectl describe deployment web-rollout
```

### 失敗を再現する例
```bash
kubectl set image deployment/web-rollout web=nginx:does-not-exist
kubectl rollout status deployment/web-rollout
kubectl get pods -l app=web-rollout
kubectl describe pod -l app=web-rollout
kubectl get events --sort-by=.metadata.creationTimestamp
```

### ロールバック
```bash
kubectl rollout undo deployment/web-rollout
kubectl rollout status deployment/web-rollout
kubectl rollout history deployment/web-rollout
```

### 発展観察
- 失敗イメージ指定時に何が起きるか
- ReplicaSet 履歴がどう残るか
- ロールバック後に Ready 状態へ戻るか

## 6) Command Cheatsheet
```bash
kubectl set image deployment/web-rollout web=nginx:1.28
kubectl rollout status deployment/web-rollout
kubectl rollout history deployment/web-rollout
kubectl rollout undo deployment/web-rollout
kubectl rollout undo deployment/web-rollout --to-revision=2
kubectl get rs
kubectl get events --sort-by=.metadata.creationTimestamp
```

## 7) よくあるミスと安全策
- **`:latest` を使ってしまう**  
  → 再現性が落ちる。固定タグや digest を優先。
- **失敗後すぐに Pod を delete して証拠を消す**  
  → まず events / describe / rollout history を見る。
- **rollback 手順を知らないまま本番更新する**  
  → 先に `history` と `undo` を検証環境で練習。
- **Secret を含む env を画面共有・ログ貼り付けする**  
  → 値を露出しない。Secret は専用リソースか外部 secret 管理と組み合わせる。
- **namespace / context を誤って `set image` する**  
  → 更新系コマンド前は context・namespace・対象 Deployment 名を声に出して確認するくらいでちょうどいい。

## 8) 面接っぽい質問
**質問:** なぜ `nginx:latest` のような曖昧なタグより、固定バージョンや digest を使う方が安全なのでしょうか？ また、更新失敗時の最初の復旧手順は？

## 9) 次の一歩リソース
- Kubernetes 公式: Update API Objects in Place Using kubectl patch  
  https://kubernetes.io/docs/tasks/manage-kubernetes-objects/update-api-object-kubectl-patch/
- Kubernetes 公式: Deployments  
  https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Kubernetes 公式: Images  
  https://kubernetes.io/docs/concepts/containers/images/

---

# Advanced

## 1) Topic + Level
**Level:** Advanced  
**Topic:** `kubectl diff` と `apply --server-side --dry-run=server` で「壊す前に差分を見る」

**Prerequisites:**
- Deployment 更新と rollout / rollback の流れを理解している
- 宣言的管理（manifest ベース）の基本を理解している
- 複数 namespace / 複数クラスタ運用で誤適用の危険をイメージできる

## 2) なぜ実アプリ開発で重要か
中〜大規模のアプリ開発では、危険なのは「明らかな delete」よりも **意図しない apply** です。たとえば、
- つもりと違う namespace に反映する
- replicas を意図せず変更する
- probe や resource 制限を消してしまう
- Secret を平文で manifest に入れてしまう
といった事故はよくあります。`kubectl diff` と `server-side dry-run` を使うと、**実際に API server がどう解釈するかを事前確認**できます。

## 3) コア kubectl / Kubernetes 概念の説明
- **`kubectl diff`**: 現在のクラスタ状態と manifest の差分を見る。
- **`--dry-run=server`**: API server 側でバリデーションしつつ、実適用はしない。
- **Server-Side Apply**: フィールド管理を API server 側で扱う apply 方式。
- **Field ownership**: 誰がどのフィールドを管理するか。複数ツール併用時に重要。
- **Declarative management**: 手作業修正より、manifest を正として再現可能に保つ考え方。

## 4) アプリ構築中にどう使われるか
kubernetes.io の方針に沿うと、アプリ構築では **宣言的に定義し、適用前に差分確認し、スコープを限定して反映する** のが安全です。特に本番では、
- `kubectl diff -f ...` で差分確認
- `kubectl apply --server-side --dry-run=server -f ...` で API server 観点の検証
- 問題なければ限定したファイルだけ apply
- `kubectl apply -f .` や namespace 横断の雑な適用を避ける
という流れがかなり効きます。

## 5) 30–60分ハンズオン・ミニラボ
**目標:** Deployment manifest を変更し、反映前に差分と妥当性を確認する。

### 例: replicas と resources を追加した manifest 差分を試す
元の `web-rollout.yaml` をコピーして `web-rollout-v2.yaml` を作り、以下のように変更する。

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-rollout
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web-rollout
  template:
    metadata:
      labels:
        app: web-rollout
    spec:
      containers:
        - name: web
          image: nginx:1.28
          ports:
            - containerPort: 80
          resources:
            requests:
              cpu: "100m"
              memory: "128Mi"
            limits:
              cpu: "250m"
              memory: "256Mi"
          readinessProbe:
            httpGet:
              path: /
              port: 80
            initialDelaySeconds: 3
            periodSeconds: 5
```

### 実行例
```bash
kubectl config current-context
kubectl diff -f web-rollout-v2.yaml
kubectl apply --server-side --dry-run=server -f web-rollout-v2.yaml
kubectl apply -f web-rollout-v2.yaml
kubectl rollout status deployment/web-rollout
kubectl get deploy web-rollout -o yaml
```

### 追加演習
- namespace を manifest に明示した版も作り、適用対象の違いを比較する
- 故意に不正な field を入れて `--dry-run=server` で弾かれる様子を確認する
- Secret を manifest に直書きしない形へ書き換える方針を説明してみる

## 6) Command Cheatsheet
```bash
kubectl config current-context
kubectl config view --minify
kubectl diff -f web-rollout-v2.yaml
kubectl apply --server-side --dry-run=server -f web-rollout-v2.yaml
kubectl apply -f web-rollout-v2.yaml
kubectl rollout status deployment/web-rollout
kubectl explain deployment.spec.strategy
kubectl explain deployment.spec.template.spec.containers.resources
```

## 7) よくあるミスと安全策
- **`kubectl apply -f .` を深く考えずに実行する**  
  → 対象ファイルを限定する。何が含まれているか確認する。
- **diff を見ずに本番 apply する**  
  → 少なくとも重要変更では `kubectl diff` を習慣化。
- **client-side dry-run だけで安心する**  
  → 可能なら `--dry-run=server` で API server の検証を通す。
- **Secret を平文 manifest に入れる**  
  → Git に残りやすく危険。Secret / External Secrets / Sealed Secrets などを検討する。
- **削除・置換系コマンドのスコープ確認を怠る**  
  → `delete`, `replace`, 広範囲 apply 前には context / namespace / ファイル対象を再確認する。

## 8) 面接っぽい質問
**質問:** `kubectl diff` と `kubectl apply --server-side --dry-run=server` は、それぞれ何を防ぐために使いますか？ CI/CD パイプラインに入れるならどの順番がよいでしょうか？

## 9) 次の一歩リソース
- Kubernetes 公式: Declarative Management of Kubernetes Objects Using Configuration Files  
  https://kubernetes.io/docs/tasks/manage-kubernetes-objects/declarative-config/
- Kubernetes 公式: Server-Side Apply  
  https://kubernetes.io/docs/reference/using-api/server-side-apply/
- Kubernetes 公式: Dry Run  
  https://kubernetes.io/docs/reference/using-api/api-concepts/#dry-run
- Kubernetes 公式: Resource Management for Pods and Containers  
  https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/

---

# 今日のまとめ
- Beginner では `rollout status` / `history` で Deployment 更新を読む
- Middle では `set image` / `rollout undo` で更新と復旧の流れを体験する
- Advanced では `diff` / `server-side dry-run` で事故る前に差分と妥当性を確認する

Kubernetes の実務で強いのは、派手なコマンドを知っている人よりも、**更新前に差分を見て、更新中を観測し、失敗時に安全に戻せる人**です。特に、**Secret を manifest に直書きしないこと、`delete` や広範囲 `apply` の前に context / namespace / scope を必ず確認すること**は、毎回徹底したほうがいいです。
