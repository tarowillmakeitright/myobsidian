---
tags:
  - kubernetes
  - k8s
  - devops
  - learning
  - daily
---

# 2026-07-07 Kubernetes Commands Magazine

[[Home]]

## 今回のテーマ
**Topic:** `kubectl get / describe / logs` でアプリの状態を安全に観察する  
**学習アーク:** Beginner → Middle → Advanced

---

## [Beginner] まずは「見る」: Pod / Deployment / Service の基本観察

### 1) Topic + Level
- **Topic:** Kubernetesオブジェクトの基本確認
- **Level:** Beginner

### 2) なぜ実アプリ開発で重要か
アプリ開発では、"デプロイしたのに動かない"、"APIに接続できない"、"コンテナが再起動している"といった問題が日常的に起きます。  
その最初の一歩は**変更することではなく、現在の状態を正しく観察すること**です。`kubectl get`、`describe`、`logs` を使えると、障害切り分けが速くなり、不要な再デプロイや危険な操作を避けられます。

### 3) コア概念
- **Pod:** コンテナを実行する最小単位
- **Deployment:** Podを望ましい数・状態で維持する宣言的リソース
- **ReplicaSet:** Deployment配下でPod数を維持
- **Service:** Podへの安定したアクセス入口
- **Namespace:** リソースの論理的な分離単位
- **kubectl get:** 一覧や状態の概要確認
- **kubectl describe:** 詳細情報・イベント確認
- **kubectl logs:** コンテナの標準出力/エラー出力確認

### 4) アプリ開発での使われ方
Kubernetes公式ドキュメントのベストプラクティスでも、まずは宣言した状態と実際の状態の差分を観察して原因を絞る流れが重要です。  
開発中の一般的な流れ:
1. Deploymentをapply
2. PodがRunningになるか確認
3. Readiness/LivenessやImagePullエラーをdescribeで確認
4. アプリログをlogsで確認
5. Service経由で到達性を確認

アプリを作るときは、いきなりクラスタ全体を触るよりも、**対象Namespaceを明示して小さく安全に確認する**のが実践的です。

### 5) 30〜60分ミニラボ
**目標:** NGINX Deploymentを作成し、`get` / `describe` / `logs` を使って状態確認する

#### 手順
1. 作業用Namespaceを作る
```bash
kubectl create namespace magazine-lab
```

2. Deploymentを作成
```bash
kubectl -n magazine-lab create deployment web --image=nginx:1.27
```

3. Pod一覧を確認
```bash
kubectl -n magazine-lab get pods
kubectl -n magazine-lab get deployments
```

4. Deployment詳細を見る
```bash
kubectl -n magazine-lab describe deployment web
```

5. Pod名を取得して詳細確認
```bash
kubectl -n magazine-lab get pods
kubectl -n magazine-lab describe pod <POD_NAME>
```

6. ログ確認
```bash
kubectl -n magazine-lab logs <POD_NAME>
```

7. Serviceを作成
```bash
kubectl -n magazine-lab expose deployment web --port=80 --target-port=80 --type=ClusterIP
kubectl -n magazine-lab get svc
```

8. 後片付け（実行前に対象確認）
```bash
kubectl get ns
kubectl delete namespace magazine-lab
```

### 6) Command Cheatsheet
```bash
kubectl config current-context
kubectl get ns
kubectl -n <namespace> get pods
kubectl -n <namespace> get deploy
kubectl -n <namespace> get svc
kubectl -n <namespace> describe pod <pod>
kubectl -n <namespace> describe deploy <deployment>
kubectl -n <namespace> logs <pod>
kubectl -n <namespace> logs -f <pod>
```

### 7) よくあるミスと安全策
**よくあるミス**
- `default` Namespaceにそのまま作業してしまう
- `kubectl delete` をNamespace未指定で実行する
- Pod名が変わる前提を忘れて古い名前を見続ける
- `logs` を見ずに再applyして原因を消してしまう

**安全策**
- 先に `kubectl config current-context` で接続先確認
- `-n <namespace>` を毎回明示
- 破壊的操作前に `kubectl get ...` で対象確認
- Secret値をマニフェストへ直書きしない
- `kubectl apply -f .` はディレクトリ内容を必ず確認してから実行

### 8) 面接っぽい質問
**Q. `kubectl get pod` と `kubectl describe pod` の違いは？ どんな場面で使い分けますか？**

### 9) 次の一歩
- Kubernetes Objects: https://kubernetes.io/docs/concepts/overview/working-with-objects/kubernetes-objects/
- Overview of kubectl: https://kubernetes.io/docs/reference/kubectl/
- Debug Running Pods: https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/

---

## [Middle] イベントとロールアウトを見る: 「なぜ起動しないか」を追う

### 前提知識
- Pod / Deployment / Service の役割が分かる
- `kubectl get` / `describe` / `logs` を一通り使ったことがある

### 1) Topic + Level
- **Topic:** ロールアウト状態・イベント・再起動原因の確認
- **Level:** Middle

### 2) なぜ実アプリ開発で重要か
本番や検証環境では、単にPodが存在するだけでは不十分です。  
イメージ取得失敗、Readiness Probe失敗、設定ミスによるCrashLoopBackOffなど、**「作成されたが正常提供できない」状態**を見抜く必要があります。これは日々のデプロイ品質に直結します。

### 3) コア概念
- **Rollout:** Deployment更新の進行状況
- **Events:** Kubernetesが記録する状態変化やエラー情報
- **CrashLoopBackOff:** コンテナが繰り返し失敗して再起動している状態
- **Readiness Probe:** トラフィックを受けてよいかの判定
- **ImagePullBackOff / ErrImagePull:** イメージ取得失敗

重要コマンド:
- `kubectl rollout status deployment/<name>`
- `kubectl get events --sort-by=.metadata.creationTimestamp`
- `kubectl logs --previous <pod>`

### 4) アプリ開発での使われ方
アプリ開発では、コードの修正だけでなく、コンテナ起動コマンド・環境変数・Probe設定・イメージタグの整合性が重要です。  
Kubernetesでは、Deployment更新時にロールアウト状態を確認し、失敗時はイベント・ログ・Pod詳細を照合して原因を特定します。  
特に**best practiceとして不変タグや明示的な設定確認**が大切で、"とりあえずlatestで再apply" のような曖昧な運用は事故のもとです。

### 5) 30〜60分ミニラボ
**目標:** わざと失敗するDeploymentを作り、原因を追跡する

#### 失敗例: 存在しないイメージを使う
1. Namespace作成
```bash
kubectl create namespace rollout-lab
```

2. 失敗するDeployment適用
```bash
cat <<'EOF' | kubectl apply -n rollout-lab -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: broken-web
spec:
  replicas: 1
  selector:
    matchLabels:
      app: broken-web
  template:
    metadata:
      labels:
        app: broken-web
    spec:
      containers:
      - name: web
        image: nginx:not-a-real-tag
        ports:
        - containerPort: 80
EOF
```

3. 状態確認
```bash
kubectl -n rollout-lab get pods
kubectl -n rollout-lab rollout status deployment/broken-web
kubectl -n rollout-lab describe pod <POD_NAME>
kubectl -n rollout-lab get events --sort-by=.metadata.creationTimestamp
```

4. 正しいタグへ修正
```bash
kubectl -n rollout-lab set image deployment/broken-web web=nginx:1.27
kubectl -n rollout-lab rollout status deployment/broken-web
kubectl -n rollout-lab get pods
```

5. 後片付け
```bash
kubectl delete namespace rollout-lab
```

### 6) Command Cheatsheet
```bash
kubectl -n <namespace> rollout status deployment/<name>
kubectl -n <namespace> rollout history deployment/<name>
kubectl -n <namespace> get events --sort-by=.metadata.creationTimestamp
kubectl -n <namespace> logs <pod> --previous
kubectl -n <namespace> set image deployment/<name> <container>=<image:tag>
kubectl -n <namespace> get pods -w
```

### 7) よくあるミスと安全策
**よくあるミス**
- `:latest` を使って原因追跡しづらくする
- `rollout status` を見ずに更新完了と思い込む
- `describe` のEventsを読まずにアプリコードだけ疑う
- 本番でいきなり `kubectl edit` して履歴を曖昧にする

**安全策**
- イメージタグは固定する
- 更新後は `rollout status` を確認
- `logs --previous` で直前クラッシュも確認
- `kubectl apply --dry-run=server -f <file>` を活用
- Secretや認証情報をログに出さないアプリ設計を意識

### 8) 面接っぽい質問
**Q. Podが `ImagePullBackOff` のとき、あなたならどの順番で何を確認しますか？**

### 9) 次の一歩
- Deployments: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Update API Objects in Place Using kubectl patch: https://kubernetes.io/docs/tasks/manage-kubernetes-objects/update-api-object-kubectl-patch/
- Debug Applications: https://kubernetes.io/docs/tasks/debug/debug-application/

---

## [Advanced] 安全な適用と差分確認: apply / diff / context を事故なく使う

### 前提知識
- Deployment更新とロールアウト確認の基本が分かる
- YAMLマニフェストの読み書きができる
- Namespace / context の重要性を理解している

### 1) Topic + Level
- **Topic:** 宣言的運用での安全な変更確認
- **Level:** Advanced

### 2) なぜ実アプリ開発で重要か
チーム開発では、Kubernetesは「手で触る対象」ではなく、**コードとして安全に管理する対象**になります。  
`kubectl apply` は便利ですが、contextミス、対象ディレクトリミス、Namespace指定漏れ、Secret混入などが起きると大きな事故になります。  
安全に差分を確認してから適用する習慣は、実運用で非常に重要です。

### 3) コア概念
- **Declarative management:** "こうしたい" をYAMLで宣言する運用
- **kubectl apply:** 宣言内容に合わせて更新
- **kubectl diff:** 適用前に差分確認
- **Context:** どのクラスタへ操作するか
- **Server-side dry run:** APIサーバーで妥当性確認
- **Label selector:** 対象を安全に絞り込む方法

### 4) アプリ開発での使われ方
Kubernetes公式の考え方に沿うなら、アプリ開発では再現性とレビュー可能性が大事です。  
つまり、
- マニフェストはGit管理
- 適用前に差分確認
- Secretは専用リソースや外部Secret管理で扱う
- 環境ごとにNamespaceやoverlayで分離
- 破壊的コマンドは対象を明示して実行

これにより、"誰が何を変えたか" を追いやすくなり、事故率が下がります。

### 5) 30〜60分ミニラボ
**目標:** 安全にマニフェストを確認してから適用する流れを身につける

#### 手順
1. 作業ディレクトリ作成
```bash
mkdir -p ~/k8s-magazine-lab/advanced
cd ~/k8s-magazine-lab/advanced
```

2. Deploymentマニフェスト作成
```bash
cat <<'EOF' > deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sample-app
  namespace: safe-apply-lab
spec:
  replicas: 2
  selector:
    matchLabels:
      app: sample-app
  template:
    metadata:
      labels:
        app: sample-app
    spec:
      containers:
      - name: app
        image: nginx:1.27
        ports:
        - containerPort: 80
EOF
```

3. Namespace作成
```bash
kubectl create namespace safe-apply-lab
```

4. 適用前確認
```bash
kubectl config current-context
kubectl diff -f deployment.yaml
kubectl apply --dry-run=server -f deployment.yaml
```

5. 問題なければ適用
```bash
kubectl apply -f deployment.yaml
kubectl -n safe-apply-lab rollout status deployment/sample-app
```

6. replicasを3に変更して差分確認
```bash
sed -i 's/replicas: 2/replicas: 3/' deployment.yaml
kubectl diff -f deployment.yaml
kubectl apply --dry-run=server -f deployment.yaml
kubectl apply -f deployment.yaml
kubectl -n safe-apply-lab get deploy,pods
```

7. 後片付け前の確認
```bash
kubectl get ns
kubectl -n safe-apply-lab get all
kubectl delete namespace safe-apply-lab
```

### 6) Command Cheatsheet
```bash
kubectl config get-contexts
kubectl config current-context
kubectl diff -f <file>
kubectl apply --dry-run=server -f <file>
kubectl apply -f <file>
kubectl -n <namespace> rollout status deployment/<name>
kubectl -n <namespace> get all
kubectl delete -f <file>
```

### 7) よくあるミスと安全策
**よくあるミス**
- `kubectl apply -f .` で意図しないファイルまで適用
- 別クラスタのcontextのまま本番へ反映
- SecretをGitやYAMLへ平文で保存
- `kubectl delete -f .` を軽率に実行
- cluster-wideな操作をNamespaceリソースのつもりで実行

**安全策**
- 破壊的操作前に**context / namespace / 対象ファイル**を3点確認
- `kubectl diff` → `--dry-run=server` → `apply` の順で進める
- Secretはマニフェストに直書きしない。必要ならSecretリソースや外部シークレット管理を使う
- 本番相当では `apply -f <明示ファイル>` を優先
- ラベルやNamespaceで対象範囲を明確化
- `delete` 前には `get` と `describe` で対象を確認

### 8) 面接っぽい質問
**Q. `kubectl apply -f .` を本番運用で避けたい理由は何ですか？ 代わりにどんな安全策を取りますか？**

### 9) 次の一歩
- Declarative Object Management: https://kubernetes.io/docs/tasks/manage-kubernetes-objects/declarative-config/
- kubectl Cheat Sheet: https://kubernetes.io/docs/reference/kubectl/cheatsheet/
- Organizing Cluster Access Using kubeconfig Files: https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/
- Secrets Good Practices: https://kubernetes.io/docs/concepts/security/secrets-good-practices/

---

## 今日のまとめ
今日は、Kubernetesで**まず安全に観察する → 失敗原因を追う → 差分確認して安全に適用する**という、実アプリ開発に直結する流れを扱いました。  
特に大事なのは次の3点です。

1. **いきなり直さず、まず観察する** (`get` / `describe` / `logs`)
2. **更新後はロールアウトとイベントを見る**
3. **apply前にcontext・diff・dry-runを確認する**

この3つが身につくと、Kubernetes操作がかなり“事故りにくく”なります。
