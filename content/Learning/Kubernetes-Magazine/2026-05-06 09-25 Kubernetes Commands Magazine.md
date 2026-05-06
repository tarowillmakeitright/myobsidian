---
tags: [kubernetes, k8s, devops, learning, daily]
---

# Kubernetes Commands Magazine — 2026-05-06
[[Home]]

## 今号のテーマ（Beginner）
**Topic + Level:** Pod を安全にデプロイして観察する基本フロー（Beginner）

---

## 1) なぜ実アプリ開発で重要か
アプリ開発では「まず動かす」だけでなく、**再現可能に動かし続ける**ことが重要です。Kubernetes では、
- 宣言的な設定（YAML）で同じ状態を再現できる
- `kubectl` でデプロイ後の状態確認・原因調査ができる
- 将来のスケールやローリングアップデートにつながる

という基盤が得られます。最初に Pod / Deployment / Service の基本操作を安全に身につけると、後続の運用トラブルを大幅に減らせます。

---

## 2) コア概念（kubectl / Kubernetes）

### Pod
- コンテナを実行する最小単位
- 本番では Pod 単体より **Deployment 経由**で管理するのが一般的

### Deployment
- Pod の望ましい状態（レプリカ数、イメージ）を宣言
- 更新時のローリングアップデートを自動管理

### Service (ClusterIP)
- Pod 群への安定したアクセス先を提供
- Pod の IP が変わってもアプリ間通信を維持できる

### kubectl の基本
- `get`: 一覧
- `describe`: 詳細イベント
- `logs`: ログ確認
- `apply -f`: 宣言適用
- `diff -f`: 適用前差分確認（安全）

---

## 3) アプリ構築時の使い方（kubernetes.io/docs ベストプラクティス準拠）
- **宣言的管理を優先**: `kubectl apply -f` を中心にする
- **名前空間で分離**: 学習・開発用 namespace を作る
- **最小権限・秘密情報分離**: Secret を平文で Git に置かない
- **適用前に確認**: `kubectl config current-context` と `kubectl diff -f` を必ず実行
- **観測性の基本を先に**: `get/describe/logs` をセットで使う

参考（公式）:
- https://kubernetes.io/docs/concepts/overview/working-with-objects/
- https://kubernetes.io/docs/tasks/manage-kubernetes-objects/declarative-config/
- https://kubernetes.io/docs/concepts/workloads/controllers/deployment/

---

## 4) 30〜60分ミニラボ（安全重視）

### ゴール
nginx Deployment を作成し、Service 経由で到達確認。障害調査の基本コマンドまで実施。

### 前提（Beginner）
- `kubectl` インストール済み
- 動作するクラスター（kind / minikube / Docker Desktop など）

### 手順
1. **コンテキスト確認（最重要）**
   ```bash
   kubectl config current-context
   kubectl config get-contexts
   ```

2. **学習用 namespace 作成**
   ```bash
   kubectl create namespace lab-beginner
   ```

3. **マニフェスト作成**（`nginx-lab.yaml`）
   ```yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: web
     namespace: lab-beginner
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
             resources:
               requests:
                 cpu: "100m"
                 memory: "128Mi"
               limits:
                 cpu: "300m"
                 memory: "256Mi"
   ---
   apiVersion: v1
   kind: Service
   metadata:
     name: web
     namespace: lab-beginner
   spec:
     selector:
       app: web
     ports:
       - port: 80
         targetPort: 80
   ```

4. **適用前差分確認 → 適用**
   ```bash
   kubectl diff -f nginx-lab.yaml
   kubectl apply -f nginx-lab.yaml
   ```

5. **状態確認**
   ```bash
   kubectl get all -n lab-beginner
   kubectl rollout status deploy/web -n lab-beginner
   kubectl describe deploy/web -n lab-beginner
   ```

6. **ローカル確認（port-forward）**
   ```bash
   kubectl port-forward svc/web 8080:80 -n lab-beginner
   # 別ターミナルで
   curl -I http://127.0.0.1:8080
   ```

7. **トラブルシュート練習**
   - イメージを存在しないタグに変更して失敗を観察:
   ```bash
   kubectl set image deploy/web nginx=nginx:does-not-exist -n lab-beginner
   kubectl rollout status deploy/web -n lab-beginner
   kubectl describe pod -l app=web -n lab-beginner
   ```
   - 元に戻す:
   ```bash
   kubectl rollout undo deploy/web -n lab-beginner
   ```

8. **後片付け（破壊的コマンド注意）**
   ```bash
   # 実行前に context を再確認！
   kubectl config current-context
   kubectl delete namespace lab-beginner
   ```

---

## 5) コマンドチートシート
```bash
# コンテキスト/名前空間
kubectl config current-context
kubectl config get-contexts
kubectl get ns

# リソース確認
kubectl get pods -n <ns>
kubectl get deploy -n <ns>
kubectl get svc -n <ns>

# 詳細/ログ
kubectl describe pod <pod> -n <ns>
kubectl logs <pod> -n <ns>

# 宣言適用
kubectl diff -f app.yaml
kubectl apply -f app.yaml

# ロールアウト
kubectl rollout status deploy/<name> -n <ns>
kubectl rollout undo deploy/<name> -n <ns>
```

---

## 6) よくあるミス & 安全プラクティス

### よくあるミス
- `default` namespace のまま作業して対象が混ざる
- `kubectl apply -f .` を広いディレクトリで実行して意図しない適用
- `kubectl delete` を context 未確認で実行
- Secret を平文で YAML/Git に置く

### 安全プラクティス
- 破壊的操作前に毎回: `kubectl config current-context`
- 先に `kubectl diff -f ...` で変更確認
- namespace を固定し、`-n <ns>` を省略しない
- Secret は外部シークレット管理や暗号化ツール（例: Sealed Secrets, External Secrets）を検討
- 本番想定では RBAC 最小権限を徹底

---

## 7) 面接っぽい1問
**Q. Pod を直接作るより Deployment を使うべき理由は？**

**A（要点）:**
- 自己修復（Pod 障害時に再作成）
- レプリカ管理
- ローリングアップデート/ロールバック
- 宣言的な継続運用に向いている

---

## 8) 次のステップ（公式中心）
- Kubernetes Concepts:
  https://kubernetes.io/docs/concepts/
- Deployments:
  https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Services:
  https://kubernetes.io/docs/concepts/services-networking/service/
- kubectl cheatsheet:
  https://kubernetes.io/docs/reference/kubectl/cheatsheet/
- Configure Access to Multiple Clusters:
  https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/

---

## 予告（次号）
**Middle:** ConfigMap/Secret と probes（liveness/readiness/startup）を使った「壊れにくい API デプロイ」。
- 前提: Deployment/Service 基本、Pod ログ確認、namespace 運用
