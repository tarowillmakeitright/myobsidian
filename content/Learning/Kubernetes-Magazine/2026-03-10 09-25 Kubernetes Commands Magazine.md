---
tags: [kubernetes, k8s, devops, learning, daily]
---

# 2026-03-10 Kubernetes Commands Magazine (09:25)
[[Home]]

#kubernetes #k8s #devops #learning #daily

本日のテーマは **「アプリ開発で使う Kubernetes 基本運用アーク（Beginner → Middle → Advanced）」** です。  
実務での安全性（Secrets管理・誤爆防止・最小権限）を最優先に、段階的に学びます。

---

## Learning Arc 1 — Beginner

### 1) Topic + Level
**Topic:** Pod / Deployment / Service の基本操作と `kubectl` 観測コマンド  
**Level:** Beginner

### 2) なぜ実アプリ開発で重要か
ローカルで動いたアプリでも、本番では「複数インスタンス」「再起動」「疎通確認」が必要です。  
Kubernetes の最小単位（Pod）と管理単位（Deployment）、公開単位（Service）を理解すると、**壊れにくく運用しやすいアプリ配置**が可能になります。

### 3) コア概念（kubectl / Kubernetes）
- **Pod**: コンテナ実行単位（通常は直接運用せず Deployment 経由）
- **Deployment**: Pod レプリカ管理、ローリング更新、自己修復
- **Service (ClusterIP)**: Pod 群への安定したアクセス窓口
- よく使う観測コマンド:
  - `kubectl get`（一覧）
  - `kubectl describe`（詳細イベント）
  - `kubectl logs`（ログ確認）
  - `kubectl rollout status`（更新状態）

### 4) 開発時の使い方（kubernetes.io/docs ベストプラクティス整合）
- マニフェストは宣言的に管理（Git 管理）
- `kubectl apply -f` は**対象ファイル/ディレクトリを明示**
- ラベル設計を先に決める（`app`, `tier`, `version` など）
- イメージタグは `latest` 固定を避け、追跡可能なタグを使う

### 5) 30–60分ミニラボ
**目標:** nginx を Deployment + Service で起動し、状態観測する（約40分）

1. Namespace 作成
```bash
kubectl create namespace magazine-lab
```

2. Deployment 作成
```bash
kubectl -n magazine-lab create deployment web --image=nginx:1.27
kubectl -n magazine-lab scale deployment web --replicas=2
```

3. Service 公開（ClusterIP）
```bash
kubectl -n magazine-lab expose deployment web --port=80 --target-port=80 --name=web-svc
```

4. 観測
```bash
kubectl -n magazine-lab get all
kubectl -n magazine-lab describe deployment web
kubectl -n magazine-lab logs deployment/web --tail=50
kubectl -n magazine-lab rollout status deployment/web
```

5. 後片付け（削除前に対象確認）
```bash
kubectl config current-context
kubectl get ns
kubectl delete namespace magazine-lab
```

### 6) コマンドチートシート
```bash
kubectl config get-contexts
kubectl config current-context
kubectl get ns
kubectl -n <ns> get pods,deploy,svc
kubectl -n <ns> describe pod <pod-name>
kubectl -n <ns> logs <pod-name> --tail=100
kubectl -n <ns> rollout status deploy/<name>
```

### 7) よくあるミス & 安全策
- ミス: `default` namespace に誤デプロイ  
  安全策: `-n` を毎回指定、もしくは `kubectl config set-context --current --namespace=<ns>`
- ミス: 間違った Context へ apply/delete  
  安全策: 実行前に `kubectl config current-context` を確認
- ミス: いきなり `kubectl delete -f .`  
  安全策: 対象ディレクトリを限定し、レビュー後に実行

> ⚠️ 破壊的コマンド（`delete`, `replace`, 広範囲 `apply -f .`）前には、**context / namespace / 対象パス**を必ず再確認。

### 8) 面接風質問
「Deployment と Pod を直接作る運用の違いは？本番で Deployment を使うべき理由を説明してください。」

### 9) 次の一歩（公式）
- Kubernetes Concepts: https://kubernetes.io/docs/concepts/
- Deployments: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Services: https://kubernetes.io/docs/concepts/services-networking/service/
- kubectl Cheat Sheet: https://kubernetes.io/docs/reference/kubectl/cheatsheet/

---

## Learning Arc 2 — Middle

### Prerequisites
- Pod / Deployment / Service の基本が分かる
- `kubectl get/describe/logs` が使える

### 1) Topic + Level
**Topic:** ConfigMap / Secret / Probes / Requests&Limits で「壊れにくいアプリ運用」  
**Level:** Middle

### 2) なぜ実アプリ開発で重要か
実アプリは設定値・機密情報・ヘルスチェック・リソース制御が必須です。  
これを適切に設計しないと、**障害復旧の遅延・情報漏えい・ノード圧迫**が発生します。

### 3) コア概念
- **ConfigMap**: 非機密設定の外出し
- **Secret**: 機密データ格納（平文コミット禁止）
- **livenessProbe/readinessProbe**: 死活と受信可能性を分離
- **resources.requests/limits**: スケジューリングと過負荷防止

### 4) 開発時の使い方（ベストプラクティス）
- Secret を Git に平文で置かない（External Secret / Sealed Secrets など検討）
- Probe は実アプリの実態に合わせる（起動時間を考慮）
- Requests 未設定を避ける（クラスタ健全性のため）
- `kubectl diff -f` で事前差分確認

### 5) 30–60分ミニラボ
**目標:** 環境変数設定 + Probe + リソース制限付き Deployment を適用（約50分）

1. Namespace
```bash
kubectl create namespace app-safe-lab
```

2. ConfigMap / Secret 作成
```bash
kubectl -n app-safe-lab create configmap app-config --from-literal=APP_MODE=staging
kubectl -n app-safe-lab create secret generic app-secret --from-literal=API_TOKEN='change-me'
```

3. マニフェスト適用（`safe-app.yaml`）
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: safe-app
  namespace: app-safe-lab
spec:
  replicas: 2
  selector:
    matchLabels:
      app: safe-app
  template:
    metadata:
      labels:
        app: safe-app
    spec:
      containers:
      - name: app
        image: nginx:1.27
        ports:
        - containerPort: 80
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
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            cpu: "300m"
            memory: "256Mi"
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 10
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 15
          periodSeconds: 20
---
apiVersion: v1
kind: Service
metadata:
  name: safe-app-svc
  namespace: app-safe-lab
spec:
  selector:
    app: safe-app
  ports:
  - port: 80
    targetPort: 80
```

```bash
kubectl diff -f safe-app.yaml
kubectl apply -f safe-app.yaml
kubectl -n app-safe-lab get pods
kubectl -n app-safe-lab describe pod -l app=safe-app
```

4. 後片付け
```bash
kubectl delete ns app-safe-lab
```

### 6) コマンドチートシート
```bash
kubectl -n <ns> get configmap,secret
kubectl -n <ns> describe deploy <name>
kubectl -n <ns> top pod
kubectl diff -f <file>
kubectl apply -f <file>
kubectl -n <ns> rollout history deploy/<name>
```

### 7) よくあるミス & 安全策
- ミス: Secret を YAML 平文で Git 管理  
  安全策: secret manager 連携、暗号化運用
- ミス: Probe が厳しすぎて再起動ループ  
  安全策: `initialDelaySeconds` と timeout を現実的に設定
- ミス: requests/limits 未設定  
  安全策: 最低値をテンプレート化して全サービスに適用

> ⚠️ `kubectl apply -f .` は想定外リソース更新の原因。必ず範囲を狭める。

### 8) 面接風質問
「readinessProbe と livenessProbe を分ける理由は？同一設定にするリスクは何ですか？」

### 9) 次の一歩（公式）
- ConfigMap: https://kubernetes.io/docs/concepts/configuration/configmap/
- Secret: https://kubernetes.io/docs/concepts/configuration/secret/
- Probes: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/
- Resource Management: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/

---

## Learning Arc 3 — Advanced

### Prerequisites
- Deployment/Service/ConfigMap/Secret/Probe を実運用レベルで扱える
- ローリングアップデートの挙動を理解している

### 1) Topic + Level
**Topic:** RollingUpdate 戦略・PodDisruptionBudget・NetworkPolicy による安全な本番運用  
**Level:** Advanced

### 2) なぜ実アプリ開発で重要か
本番では「止めずに更新」「メンテ時の可用性維持」「通信経路の最小化」が重要です。  
これらは SLO/SLA とセキュリティの両面に直結します。

### 3) コア概念
- **RollingUpdate**: `maxUnavailable` / `maxSurge` で無停止更新調整
- **PodDisruptionBudget (PDB)**: 自発的中断時の最小可用数を保証
- **NetworkPolicy**: Pod 間通信を必要最小限に制限（デフォルト許可を見直す）

### 4) 開発時の使い方（ベストプラクティス）
- 本番更新前に `rollout status` と `rollout undo` を準備
- PDB と HPA/Replica 設計を整合させる
- NetworkPolicy は段階導入（監視しつつ tighten）
- 破壊的変更は段階的 apply + 明示的 namespace 指定

### 5) 30–60分ミニラボ
**目標:** 更新戦略と可用性制約、基本通信制御を設定（約60分）

1. Namespace とベースデプロイ
```bash
kubectl create ns prod-like-lab
kubectl -n prod-like-lab create deployment api --image=nginx:1.27
kubectl -n prod-like-lab scale deploy api --replicas=3
```

2. RollingUpdate 設定
```bash
kubectl -n prod-like-lab patch deploy api -p '{"spec":{"strategy":{"type":"RollingUpdate","rollingUpdate":{"maxUnavailable":1,"maxSurge":1}}}}'
```

3. PDB 作成（`pdb.yaml`）
```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: api-pdb
  namespace: prod-like-lab
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: api
```

4. NetworkPolicy 作成（`np.yaml`、同 namespace 内からの 80 のみ許可）
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-allow-same-ns
  namespace: prod-like-lab
spec:
  podSelector:
    matchLabels:
      app: api
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector: {}
    ports:
    - protocol: TCP
      port: 80
```

5. 適用と検証
```bash
kubectl apply -f pdb.yaml
kubectl apply -f np.yaml
kubectl -n prod-like-lab get pdb
kubectl -n prod-like-lab describe pdb api-pdb
kubectl -n prod-like-lab rollout restart deploy/api
kubectl -n prod-like-lab rollout status deploy/api
```

6. 後片付け
```bash
kubectl delete ns prod-like-lab
```

### 6) コマンドチートシート
```bash
kubectl -n <ns> rollout restart deploy/<name>
kubectl -n <ns> rollout status deploy/<name>
kubectl -n <ns> rollout history deploy/<name>
kubectl -n <ns> rollout undo deploy/<name>
kubectl -n <ns> get pdb
kubectl -n <ns> get networkpolicy
```

### 7) よくあるミス & 安全策
- ミス: `maxUnavailable` が大きすぎて同時ダウン増加  
  安全策: 可用性要件に合わせて段階的に調整
- ミス: PDB とレプリカ数の不整合でドレイン詰まり  
  安全策: メンテ手順書に PDB 条件を明記
- ミス: NetworkPolicy で必要通信まで遮断  
  安全策: 先に通信要件を棚卸しし、段階適用

> ⚠️ `kubectl delete ns <name>` は強力な破壊操作。対象 namespace 名と context を二重確認すること。

### 8) 面接風質問
「ローリングアップデート中の可用性を維持するために、Deployment 戦略と PDB をどう設計しますか？」

### 9) 次の一歩（公式）
- Rolling Updates: https://kubernetes.io/docs/tutorials/kubernetes-basics/update/update-intro/
- Pod Disruptions: https://kubernetes.io/docs/concepts/workloads/pods/disruptions/
- Network Policies: https://kubernetes.io/docs/concepts/services-networking/network-policies/
- Production Best Practices (overview): https://kubernetes.io/docs/setup/best-practices/

---

## 今日のまとめ
- Beginner: まずは Deployment/Service と観測コマンドを確実に
- Middle: 設定分離・機密管理・Probe・リソース制御で運用耐性UP
- Advanced: 可用性（RollingUpdate/PDB）と通信制御（NetworkPolicy）で本番品質へ

次回はこのアークを繰り返し、テーマを **StatefulSet / Ingress / HPA / Job/CronJob / RBAC** に展開すると学習効率が高いです。
