---
tags:
  - kubernetes
  - k8s
  - devops
  - learning
  - daily
---

# 2026-06-22 09:25 Kubernetes Commands Magazine
[[Home]]

#kubernetes #k8s #devops #learning #daily

## 今日のテーマ
**ConfigMap・Secret・Deployment を使った安全なアプリ設定変更**

実務では「アプリ本体のイメージ」と「環境ごとの設定」を分けて扱えるかどうかで、運用のしやすさと事故率が大きく変わります。今日は **Beginner → Middle → Advanced** の順で、Kubernetes 上で設定を安全に扱う流れを学びます。

---

## Beginner — ConfigMapでアプリ設定を外出しする

### 1) Topic + Level
**Topic:** ConfigMapの基本と `kubectl create configmap` / `kubectl apply`
**Level:** Beginner

### 2) Why it matters for real app development
開発中のアプリでは、以下をコードに埋め込まない設計が重要です。

- 環境ごとのAPIエンドポイント
- ログレベル
- 機能フラグ
- タイムアウト値

これをイメージに焼き込むと、設定変更のたびにビルド・配布・再デプロイが必要になります。ConfigMap を使うと、**アプリの設定をコンテナイメージから切り離し**、環境ごとに安全かつ再現性のある運用がしやすくなります。

### 3) Core kubectl/Kubernetes concept explanations
- **ConfigMap**: 機密ではない設定値を保存するKubernetesオブジェクト
- **Deployment**: Podを望ましい状態で維持する仕組み
- **`kubectl apply`**: 宣言的にマニフェストを適用する基本操作
- **環境変数注入**: ConfigMap の値をコンテナ内の `env` として使う方法
- **volumeマウント**: ConfigMap をファイルとしてコンテナ内へ渡す方法

### 4) How Kubernetes is used while building apps
kubernetes.io/docs のベストプラクティスでは、アプリ本体と設定を分離し、環境差分をマニフェストや設定オブジェクトで管理します。これは以下に直結します。

- 開発・検証・本番で同じイメージを使いやすい
- Gitで設定変更をレビューしやすい
- ロールバック時に設定差分も追いやすい
- CI/CDで安全に反映しやすい

アプリ開発ではまず「設定を外出しできる設計」を作るのが定石です。

### 5) 30-60 minute hands-on mini lab
**目標:** ConfigMap を作成し、nginx Pod に設定値を環境変数として注入して確認する

**前提:**
- `kubectl` が使える
- テスト用クラスタ（kind / minikube / k3d など）がある
- 現在のcontextが学習用であることを必ず確認する

#### Step 1: context確認
```bash
kubectl config current-context
kubectl config get-contexts
kubectl get ns
```

#### Step 2: namespace作成
```bash
kubectl create namespace k8s-magazine
```

#### Step 3: ConfigMap作成
```bash
kubectl create configmap app-config \
  --from-literal=APP_ENV=dev \
  --from-literal=LOG_LEVEL=info \
  -n k8s-magazine
```

#### Step 4: Deployment作成
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-web
  namespace: k8s-magazine
spec:
  replicas: 1
  selector:
    matchLabels:
      app: demo-web
  template:
    metadata:
      labels:
        app: demo-web
    spec:
      containers:
        - name: web
          image: nginx:1.27
          env:
            - name: APP_ENV
              valueFrom:
                configMapKeyRef:
                  name: app-config
                  key: APP_ENV
            - name: LOG_LEVEL
              valueFrom:
                configMapKeyRef:
                  name: app-config
                  key: LOG_LEVEL
```

保存例: `demo-configmap.yaml`

```bash
kubectl apply -f demo-configmap.yaml
kubectl get pods -n k8s-magazine
kubectl describe pod -n k8s-magazine
```

#### Step 5: Pod内で環境変数確認
```bash
kubectl exec -it deploy/demo-web -n k8s-magazine -- /bin/sh
printenv | grep -E 'APP_ENV|LOG_LEVEL'
exit
```

#### Step 6: ConfigMap確認
```bash
kubectl get configmap app-config -n k8s-magazine -o yaml
```

**学びどころ:**
- 設定がイメージではなくKubernetes側にある
- Podがその設定を参照している
- 設定変更とアプリ更新を分けて考えられる

### 6) Command cheatsheet
```bash
kubectl create namespace k8s-magazine
kubectl create configmap app-config --from-literal=KEY=value -n k8s-magazine
kubectl get configmap -n k8s-magazine
kubectl describe configmap app-config -n k8s-magazine
kubectl apply -f demo-configmap.yaml
kubectl get deploy,pods -n k8s-magazine
kubectl exec -it deploy/demo-web -n k8s-magazine -- /bin/sh
kubectl config current-context
```

### 7) Common mistakes and safe practices
**よくあるミス**
- 本番クラスタのcontextのまま練習用マニフェストを apply する
- default namespace にそのまま作業する
- ConfigMap にパスワードやAPIキーを入れてしまう

**安全策**
- `kubectl config current-context` を毎回確認する
- 学習用 namespace を分ける
- 機密情報は ConfigMap ではなく Secret を使う
- `kubectl apply --dry-run=server -f <file>` で事前確認する

> 注意: `kubectl apply` は対象ファイルや current-context を間違えると想定外の範囲に変更を入れます。apply 前に **context / namespace / 対象ファイル** を必ず確認してください。

### 8) Interview-style question
**質問:** ConfigMap を使うと、なぜアプリのデプロイ運用がしやすくなるのですか？

### 9) Next-step resources
- Kubernetes ConfigMap: https://kubernetes.io/docs/concepts/configuration/configmap/
- Configure a Pod to Use a ConfigMap: https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/
- kubectl Cheat Sheet: https://kubernetes.io/docs/reference/kubectl/cheatsheet/

---

## Middle — Secretを使って機密情報を安全に扱う

### Prerequisites
- ConfigMap の役割がわかる
- Pod / Deployment / namespace の基本がわかる
- `kubectl get`, `describe`, `apply` を使ったことがある

### 1) Topic + Level
**Topic:** Secret の基本、安全な参照方法、ConfigMapとの使い分け
**Level:** Middle

### 2) Why it matters for real app development
実アプリではDBパスワード、APIトークン、外部サービス認証情報が必要です。これを誤って以下に置くと危険です。

- Gitリポジトリ
- ConfigMap
- 平文のマニフェスト
- CIログ

Kubernetes Secret は「万能な秘密保管庫」ではありませんが、少なくとも **ConfigMap と分離して機密扱いを明示** でき、アクセス制御や外部シークレット管理との連携の土台になります。

### 3) Core kubectl/Kubernetes concept explanations
- **Secret**: 機密データを扱うためのオブジェクト
- **base64**: Secret YAML でよく見るが、暗号化そのものではない
- **env / volume 参照**: Pod に安全寄りの形で受け渡す方法
- **RBAC**: Secret の参照権限を絞る上で重要
- **etcd暗号化**: クラスタ側の保護として重要な論点

### 4) How Kubernetes is used while building apps
アプリ開発では「設定」と「秘密情報」を分離するのが基本です。

- ConfigMap: 非機密設定
- Secret: 機密設定

さらに、本番では External Secrets Operator やクラウドKMS/Secret Manager連携に進むことが多いです。Kubernetesの標準機能を理解しておくと、後でより安全な仕組みに移行しやすくなります。

### 5) 30-60 minute hands-on mini lab
**目標:** Secret を作成し、Pod から環境変数として参照する

#### Step 1: Secret作成
```bash
kubectl create secret generic app-secret \
  --from-literal=DB_USER=appuser \
  --from-literal=DB_PASSWORD='change-me-demo' \
  -n k8s-magazine
```

#### Step 2: Secret参照付きDeploymentへ更新
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-web
  namespace: k8s-magazine
spec:
  replicas: 1
  selector:
    matchLabels:
      app: demo-web
  template:
    metadata:
      labels:
        app: demo-web
    spec:
      containers:
        - name: web
          image: nginx:1.27
          env:
            - name: APP_ENV
              valueFrom:
                configMapKeyRef:
                  name: app-config
                  key: APP_ENV
            - name: DB_USER
              valueFrom:
                secretKeyRef:
                  name: app-secret
                  key: DB_USER
            - name: DB_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: app-secret
                  key: DB_PASSWORD
```

保存例: `demo-secret.yaml`

```bash
kubectl apply --dry-run=server -f demo-secret.yaml
kubectl apply -f demo-secret.yaml
kubectl rollout status deploy/demo-web -n k8s-magazine
```

#### Step 3: Secretの存在確認
```bash
kubectl get secret app-secret -n k8s-magazine
kubectl describe secret app-secret -n k8s-magazine
```

#### Step 4: 参照確認
```bash
kubectl exec -it deploy/demo-web -n k8s-magazine -- /bin/sh
printenv | grep -E 'DB_USER|DB_PASSWORD'
exit
```

**重要な観察ポイント**
- Secret は見た目上 base64 だが、それだけで安全になったわけではない
- `kubectl describe secret` は値を直接全部見せないが、アクセス権限の管理は依然重要
- 実運用でシークレットをGitへコミットしない設計が必要

### 6) Command cheatsheet
```bash
kubectl create secret generic app-secret --from-literal=DB_USER=appuser -n k8s-magazine
kubectl get secret -n k8s-magazine
kubectl describe secret app-secret -n k8s-magazine
kubectl apply --dry-run=server -f demo-secret.yaml
kubectl rollout status deploy/demo-web -n k8s-magazine
kubectl exec -it deploy/demo-web -n k8s-magazine -- /bin/sh
```

### 7) Common mistakes and safe practices
**よくあるミス**
- Secret の YAML を平文生成してそのままGitにコミットする
- Secret を ConfigMap と同じ感覚で扱う
- `kubectl get secret -o yaml` の出力を共有チャットへ貼る
- Podログに秘密情報を出してしまう

**安全策**
- デモ以外の本物の秘密値はリポジトリに置かない
- RBACで Secret 読み取りを最小化する
- etcd暗号化や外部シークレット管理を検討する
- アプリ側でも秘密情報をログへ出さない

> 注意: Secret は「見えにくい」だけで、扱いを誤れば漏えいします。**base64 は暗号化ではありません。**

### 8) Interview-style question
**質問:** Kubernetes Secret は ConfigMap と何が違い、どこまで安全だと言えますか？

### 9) Next-step resources
- Secrets: https://kubernetes.io/docs/concepts/configuration/secret/
- Good practices for Kubernetes Secrets: https://kubernetes.io/docs/concepts/security/secrets-good-practices/
- Encrypt data at rest: https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/

---

## Advanced — 安全に設定変更を反映し、事故を防ぐ

### Prerequisites
- ConfigMap / Secret の基本がわかる
- Deployment の更新と Pod 再作成の流れがわかる
- `rollout status`, `describe`, `logs`, `exec` で調査できる

### 1) Topic + Level
**Topic:** 設定変更時のロールアウト、安全確認、変更範囲の見極め
**Level:** Advanced

### 2) Why it matters for real app development
実務では「設定を変えただけ」のつもりでも、以下の事故が起きます。

- 間違った namespace に apply
- 本番contextに誤投入
- Secret 名や key 名のタイポで起動失敗
- 一部Podだけ古い設定のまま残る
- `kubectl delete` で対象を広く消しすぎる

Advanced では、**変更前確認 → 反映 → ロールアウト監視 → 切り戻し判断** を安全に回すことが大切です。

### 3) Core kubectl/Kubernetes concept explanations
- **`kubectl apply --dry-run=server`**: APIサーバで妥当性確認
- **`kubectl diff -f`**: 何が変わるか確認
- **`kubectl rollout status`**: 更新進行を監視
- **`kubectl rollout undo`**: Deployment のロールバック
- **immutable ConfigMap/Secret**: 意図しない変更防止に使える場面がある
- **checksum annotation パターン**: 設定変更時にPodを安全に再起動させる実務パターン

### 4) How Kubernetes is used while building apps
アプリ開発では、単にマニフェストを書くだけでなく、以下の運用導線まで含めて設計します。

- PRレビューで差分確認
- CIで `kubectl diff` や schema validation
- CDで段階反映
- readiness probe で不完全起動を弾く
- rollback手順を先に決める

kubernetes.io/docs の考え方に沿うなら、**宣言的管理・最小権限・安全なロールアウト** が基本姿勢です。

### 5) 30-60 minute hands-on mini lab
**目標:** ConfigMap の値変更を安全に反映し、差分確認とロールアウト監視を行う

#### Step 1: ConfigMap更新用マニフェスト作成
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: k8s-magazine
data:
  APP_ENV: staging
  LOG_LEVEL: debug
```

保存例: `app-config-update.yaml`

#### Step 2: 変更前の確認
```bash
kubectl config current-context
kubectl diff -f app-config-update.yaml
kubectl apply --dry-run=server -f app-config-update.yaml
```

#### Step 3: 適用
```bash
kubectl apply -f app-config-update.yaml
kubectl get configmap app-config -n k8s-magazine -o yaml
```

#### Step 4: Deploymentを再起動して変更反映
ConfigMap を env 経由で使う場合、Pod再作成が必要になることがあります。

```bash
kubectl rollout restart deploy/demo-web -n k8s-magazine
kubectl rollout status deploy/demo-web -n k8s-magazine
```

#### Step 5: 反映後確認
```bash
kubectl exec -it deploy/demo-web -n k8s-magazine -- /bin/sh
printenv | grep -E 'APP_ENV|LOG_LEVEL'
exit
```

#### Step 6: トラブル時の確認
```bash
kubectl get events -n k8s-magazine --sort-by=.metadata.creationTimestamp
kubectl describe deploy demo-web -n k8s-magazine
kubectl describe pod -n k8s-magazine
kubectl logs -n k8s-magazine deploy/demo-web
```

#### Step 7: 後片付け（必要なら）
```bash
kubectl delete namespace k8s-magazine
```

> 削除は破壊的です。`kubectl delete namespace k8s-magazine` を実行する前に、**current-context** と削除対象を必ず再確認してください。

### 6) Command cheatsheet
```bash
kubectl diff -f app-config-update.yaml
kubectl apply --dry-run=server -f app-config-update.yaml
kubectl apply -f app-config-update.yaml
kubectl rollout restart deploy/demo-web -n k8s-magazine
kubectl rollout status deploy/demo-web -n k8s-magazine
kubectl describe deploy demo-web -n k8s-magazine
kubectl logs -n k8s-magazine deploy/demo-web
kubectl get events -n k8s-magazine --sort-by=.metadata.creationTimestamp
kubectl delete namespace k8s-magazine
```

### 7) Common mistakes and safe practices
**よくあるミス**
- apply 前に diff を見ない
- ConfigMap変更だけして Pod が再読込する前提で考えてしまう
- `delete namespace` や `delete -f` を雑に打つ
- Secret/ConfigMapの名前変更で参照切れを起こす

**安全策**
- `kubectl diff` と `--dry-run=server` を習慣化する
- context・namespace・対象ファイルの三点確認をする
- readiness / liveness probe を設定し、壊れたPodを早期検知する
- 機密情報はマニフェストに直書きしない
- 本番ではGitOpsやレビュー済み変更経路を使う

### 8) Interview-style question
**質問:** ConfigMap を更新したのにアプリへ反映されない場合、どこを確認し、どう安全に反映しますか？

### 9) Next-step resources
- Declarative Object Management: https://kubernetes.io/docs/tasks/manage-kubernetes-objects/declarative-config/
- Update configuration via ConfigMap: https://kubernetes.io/docs/tutorials/configuration/updating-configuration-via-a-configmap/
- Deployment concepts: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Configure probes: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/

---

## 今日のまとめ
今日は以下の学習弧で進めました。

1. **Beginner:** ConfigMap で非機密設定を外出しする
2. **Middle:** Secret で機密情報を分離し、安全性の前提を理解する
3. **Advanced:** 差分確認・dry-run・rollout監視で安全に設定変更を反映する

Kubernetes を実務で使うときは、単に `kubectl apply` できることよりも、**何をどこに適用するかを安全に判断できること** のほうがずっと重要です。

明日以降の発展候補:
- readiness / liveness probe の実践
- Service / Ingress とアプリ公開
- requests / limits と安定運用
- RBAC と ServiceAccount の最小権限設計
