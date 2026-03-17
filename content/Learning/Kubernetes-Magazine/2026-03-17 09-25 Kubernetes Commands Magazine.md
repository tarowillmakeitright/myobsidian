---
tags: [kubernetes, k8s, devops, learning, daily]
---

# Kubernetes Commands Magazine — 2026-03-17 (09:25)
[[Home]]

#kubernetes #k8s #devops #learning #daily

> 今日のテーマは **「安全にアプリをデプロイし、状態を観測し、段階的に更新する」**。  
> 難易度を **Beginner → Middle → Advanced** の学習アークで進めます。

---

## Learning Arc 1 — Beginner

### 1) Topic + Level
**Topic:** Pod / Deployment の基本操作と安全な `kubectl` 実行  
**Level:** Beginner

### 2) Why it matters for real app development
実アプリ開発では「動いた」だけでは不十分で、**再現可能なデプロイ**と**安定した運用**が必要です。Deployment を使うことで、同じ構成を複数環境へ安全に適用しやすくなります。

### 3) Core kubectl/Kubernetes concept explanations
- **Pod:** コンテナ実行の最小単位（通常は直接管理せず Deployment 経由で扱う）
- **Deployment:** 宣言した desired state（レプリカ数・イメージ）を維持
- **Namespace:** リソースの論理分離（開発・検証・本番）
- **Context:** `kubectl` が接続するクラスタ/ユーザー設定

### 4) How Kubernetes is used while building apps (best practices aligned)
- アプリ開発時は「手動操作」より **宣言的 YAML 管理**を優先
- `kubectl apply -f` 前に対象 context/namespace を確認
- Pod 単体運用ではなく Deployment + Service で構成
- [Kubernetes Docs: Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)

### 5) 30-60 minute hands-on mini lab
**目標:** nginx Deployment を作成し、状態確認まで行う（約35分）

1. 現在の接続先確認（5分）
   ```bash
   kubectl config get-contexts
   kubectl config current-context
   kubectl get ns
   ```
2. 学習用 namespace 作成（5分）
   ```bash
   kubectl create ns magazine-lab
   ```
3. Deployment 作成（10分）
   ```bash
   kubectl -n magazine-lab create deployment web --image=nginx:1.27
   kubectl -n magazine-lab scale deployment web --replicas=2
   ```
4. 状態観測（10分）
   ```bash
   kubectl -n magazine-lab get deploy,rs,pods -o wide
   kubectl -n magazine-lab describe deployment web
   ```
5. 後片付け（任意・5分）
   ```bash
   # ⚠ 破壊的操作: 対象namespaceを再確認してから
   kubectl delete ns magazine-lab
   ```

### 6) Command cheatsheet
```bash
kubectl config current-context
kubectl get ns
kubectl create ns <name>
kubectl -n <ns> create deployment <name> --image=<image>
kubectl -n <ns> scale deployment <name> --replicas=<n>
kubectl -n <ns> get deploy,rs,pods
kubectl -n <ns> describe deployment <name>
```

### 7) Common mistakes and safe practices
- ミス: `default` namespace にそのまま作成  
  → 対策: `-n` を常に明示
- ミス: 別クラスタへ apply  
  → 対策: `kubectl config current-context` を実行してから操作
- ミス: `kubectl delete` の対象確認不足  
  → 対策: `kubectl get ...` で事前確認、必要なら `--dry-run=client -o yaml`

### 8) Interview-style question
**Q:** Deployment と Pod を直接作る方法の違いは？なぜ本番で Deployment が推奨される？

### 9) Next-step resources
- https://kubernetes.io/docs/concepts/workloads/pods/
- https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- https://kubernetes.io/docs/tasks/access-application-cluster/access-cluster/

---

## Learning Arc 2 — Middle

### 1) Topic + Level
**Topic:** Rolling Update / Rollback と可観測性の基本  
**Level:** Middle

**Prerequisites:**
- Deployment の作成/スケール経験
- `kubectl get/describe/logs` の基本利用

### 2) Why it matters for real app development
アプリは継続的に更新されます。Rolling Update が使えないと、停止時間や障害リスクが増えます。問題発生時に即 rollback できることが実運用の生命線です。

### 3) Core kubectl/Kubernetes concept explanations
- **RollingUpdate:** 段階的に新旧 Pod を入れ替え
- **Revision history:** Deployment の更新履歴
- **Readiness/Liveness probe:** トラフィック受け入れ可否・生存確認
- **Logs/Events:** 障害解析の入口

### 4) How Kubernetes is used while building apps (best practices aligned)
- 本番アプリは probe 設定を前提に rollout
- 変更後は `rollout status` で収束確認
- 失敗時は `rollout undo` を即時適用
- [Kubernetes Docs: Rolling Updates](https://kubernetes.io/docs/tutorials/kubernetes-basics/update/update-intro/)

### 5) 30-60 minute hands-on mini lab
**目標:** イメージ更新→監視→ロールバック（約45分）

1. 事前準備（10分）
   ```bash
   kubectl create ns rollout-lab
   kubectl -n rollout-lab create deployment app --image=nginx:1.27
   kubectl -n rollout-lab expose deployment app --port=80 --type=ClusterIP
   ```
2. 正常更新（10分）
   ```bash
   kubectl -n rollout-lab set image deployment/app nginx=nginx:1.28
   kubectl -n rollout-lab rollout status deployment/app
   kubectl -n rollout-lab rollout history deployment/app
   ```
3. 意図的な失敗更新（10分）
   ```bash
   kubectl -n rollout-lab set image deployment/app nginx=nginx:does-not-exist
   kubectl -n rollout-lab get pods
   kubectl -n rollout-lab describe deployment app
   kubectl -n rollout-lab get events --sort-by=.metadata.creationTimestamp
   ```
4. ロールバック（5分）
   ```bash
   kubectl -n rollout-lab rollout undo deployment/app
   kubectl -n rollout-lab rollout status deployment/app
   ```
5. 後片付け（任意・5分）
   ```bash
   # ⚠ 破壊的操作: namespace再確認
   kubectl delete ns rollout-lab
   ```

### 6) Command cheatsheet
```bash
kubectl -n <ns> set image deployment/<name> <container>=<image:tag>
kubectl -n <ns> rollout status deployment/<name>
kubectl -n <ns> rollout history deployment/<name>
kubectl -n <ns> rollout undo deployment/<name>
kubectl -n <ns> get events --sort-by=.metadata.creationTimestamp
kubectl -n <ns> logs <pod>
```

### 7) Common mistakes and safe practices
- ミス: `latest` タグ運用で差分追跡不可  
  → 対策: 明示タグ/ダイジェスト利用
- ミス: probe 未設定で不安定Podが配信対象に  
  → 対策: readiness/liveness を定義
- ミス: 失敗時に logs だけ見て events を見ない  
  → 対策: `describe` + `events` も必ず確認

### 8) Interview-style question
**Q:** Rolling Update 中に一部 Pod が起動しない場合、どのコマンドで原因特定し、どう rollback 判断する？

### 9) Next-step resources
- https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#rolling-back-a-deployment
- https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/
- https://kubernetes.io/docs/reference/kubectl/generated/kubectl_rollout/

---

## Learning Arc 3 — Advanced

### 1) Topic + Level
**Topic:** ConfigMap / Secret / ServiceAccount を使った安全なアプリ運用  
**Level:** Advanced

**Prerequisites:**
- Deployment 更新と rollback の経験
- YAML マニフェストの基本理解
- RBAC の基礎概念（Role/RoleBinding）

### 2) Why it matters for real app development
本番では「設定」「認証情報」「権限」を分離して管理する必要があります。特に Secret の扱いを誤ると即インシデントにつながります。

### 3) Core kubectl/Kubernetes concept explanations
- **ConfigMap:** 機密ではない設定値
- **Secret:** 機密情報（ただし暗号化・アクセス制御の設計が必要）
- **ServiceAccount + RBAC:** Pod の API 権限を最小化
- **Least Privilege:** 必要最小限アクセス

### 4) How Kubernetes is used while building apps (best practices aligned)
- 機密情報を Git に平文コミットしない
- Secret は環境変数直書きではなく Secret リソース参照
- Pod に過剰権限を与えない（default SA を安易に使わない）
- [Kubernetes Docs: Secrets good practices](https://kubernetes.io/docs/concepts/security/secrets-good-practices/)

### 5) 30-60 minute hands-on mini lab
**目標:** ConfigMap/Secret/ServiceAccount を使う Deployment を作る（約55分）

1. namespace と設定準備（10分）
   ```bash
   kubectl create ns secure-lab
   kubectl -n secure-lab create configmap app-config --from-literal=APP_MODE=staging
   kubectl -n secure-lab create secret generic app-secret --from-literal=API_TOKEN='dummy-token'
   ```
2. 最小権限の SA 作成（10分）
   ```bash
   kubectl -n secure-lab create serviceaccount app-sa
   ```
3. Deployment マニフェスト適用（20分）
   ```yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: secure-app
     namespace: secure-lab
   spec:
     replicas: 1
     selector:
       matchLabels:
         app: secure-app
     template:
       metadata:
         labels:
           app: secure-app
       spec:
         serviceAccountName: app-sa
         containers:
         - name: app
           image: nginx:1.27
           env:
           - name: APP_MODE
             valueFrom:
               configMapKeyRef:
                 name: app-config
                 key: APP_MODE
           - name: API_TOKEN
             valueFrom:
               secretKeyRef:
                 name: app-secret
                 key: API_TOKEN
   ```
   ```bash
   kubectl apply -f secure-app.yaml
   kubectl -n secure-lab get pods
   ```
4. 安全確認（10分）
   ```bash
   kubectl -n secure-lab describe pod -l app=secure-app
   kubectl -n secure-lab get sa
   ```
5. 後片付け（任意・5分）
   ```bash
   # ⚠ 破壊的操作: context/namespaceを再確認
   kubectl delete ns secure-lab
   ```

### 6) Command cheatsheet
```bash
kubectl -n <ns> create configmap <name> --from-literal=K=V
kubectl -n <ns> create secret generic <name> --from-literal=K=V
kubectl -n <ns> create serviceaccount <name>
kubectl apply -f <manifest.yaml>
kubectl -n <ns> describe pod <pod>
kubectl auth can-i --as=system:serviceaccount:<ns>:<sa> get pods -n <ns>
```

### 7) Common mistakes and safe practices
- ミス: Secret を YAML に平文で埋め込み Git 管理  
  → 対策: 外部 Secret 管理や暗号化ワークフローを利用
- ミス: `kubectl apply -f .` で想定外リソース反映  
  → 対策: 対象ファイルを明示、`--dry-run=server` 検討
- ミス: default ServiceAccount を全アプリで共用  
  → 対策: ワークロードごとに SA 分離＋最小権限

### 8) Interview-style question
**Q:** Secret を使っているのに漏えい事故が起きる典型パターンを3つ挙げ、Kubernetes 上での予防策を説明してください。

### 9) Next-step resources
- https://kubernetes.io/docs/concepts/configuration/configmap/
- https://kubernetes.io/docs/concepts/configuration/secret/
- https://kubernetes.io/docs/concepts/security/secrets-good-practices/
- https://kubernetes.io/docs/reference/access-authn-authz/rbac/

---

## Global Safety Notes (毎号共通)
- **破壊的コマンド前に必ず確認:**
  - `kubectl config current-context`
  - `kubectl get ns`
  - 対象 `-n <namespace>`
- **`delete` は特に慎重に**（本番で `--all` を安易に使わない）
- **Secrets を manifest に直書きしない**（Git 平文保存は避ける）
- **適用範囲の誤りに注意:** `kubectl apply -f .` は意図しない反映を招きやすい
- 本番相当環境では、変更前にレビュー + dry-run + rollout確認をセットで実施
