---
tags: [kubernetes, k8s, devops, learning, daily]
created: 2026-05-13 09:45
---

# Daily Kubernetes Commands Magazine — 2026-05-13
[[Home]]

今日のテーマは **「kubectl apply / rollout / describe を使った安全なデプロイ運用」**。  
難易度を **Beginner → Middle → Advanced** で段階的に進めます。

---

## 1) Topic + Level

### Beginner
**Topic:** Deploymentの基本操作（`kubectl apply`, `get`, `describe`）

### Middle
**Topic:** Rollout管理とトラブルシュート（`rollout status/history/undo`, `logs`）
**前提知識:** Pod/Deploymentの基本、YAMLの基本構文、Namespaceの概念

### Advanced
**Topic:** 安全な更新戦略（readiness/liveness probe, resource requests/limits, canary的段階適用）
**前提知識:** Middleの内容、Service経由のトラフィック、アプリのヘルスエンドポイント

---

## 2) なぜ実アプリ開発で重要か

- 実開発では「動く」だけでなく、**止めずに更新できること**が重要。Deployment + rollout運用はその中心。
- 障害時に `describe` / `logs` / `rollout undo` で切り戻せるかが、SRE/開発者の実務力に直結。
- 無計画な `apply` は本番障害の原因（誤Namespace、誤Context、誤manifest）。安全手順を先に固めることが必須。

---

## 3) Core kubectl/Kubernetes Concepts

- **Declarative管理 (`kubectl apply`)**: 望ましい状態をYAMLで宣言し、Kubernetesに収束させる。
- **Deployment**: Podのレプリカと更新戦略を管理。ローリングアップデートの基本単位。
- **ReplicaSet**: Deploymentの世代管理を裏で担当。
- **Rollout**: 新しいPodへ段階的に置換し、失敗時は停止/切り戻し可能。
- **`describe`**: イベント含む詳細確認。`get` だけで見えない原因（ImagePullBackOffなど）を特定。
- **Context / Namespace**: どのクラスタ・どの論理空間に対して実行しているか。事故防止の最重要ポイント。

---

## 4) アプリ開発での使い方（kubernetes.io/docsの実践に沿って）

- **マニフェストをGit管理**し、手作業の `kubectl edit` 依存を減らす。
- **Secretは平文で直書きしない**（Gitに載せない）。必要時はSecretリソースや外部Secret管理を利用。
- **readinessProbeを設定**して、起動直後の不安定Podへトラフィックを流さない。
- **resources requests/limits** を設定し、ノード圧迫や予期せぬEvictionを抑える。
- 適用前に **`kubectl config current-context` / `kubectl get ns` / `kubectl diff -f ...`** で確認。

---

## 5) 30–60分ミニラボ

> 目的: 小さなWebアプリを安全にデプロイし、失敗更新→切り戻しまで体験する

### 0. 事前確認（5分）
```bash
kubectl config current-context
kubectl get nodes
kubectl create ns k8s-magazine
```

### 1. 初回デプロイ（10分）
`deployment.yaml` を作成:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
  namespace: k8s-magazine
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
          image: nginx:1.25
          ports:
            - containerPort: 80
          readinessProbe:
            httpGet:
              path: /
              port: 80
            initialDelaySeconds: 3
            periodSeconds: 5
          resources:
            requests:
              cpu: "100m"
              memory: "128Mi"
            limits:
              cpu: "300m"
              memory: "256Mi"
```

適用と確認:
```bash
kubectl apply -f deployment.yaml
kubectl -n k8s-magazine get deploy,pods
kubectl -n k8s-magazine rollout status deploy/web
```

### 2. 意図的に失敗する更新（10–15分）
イメージを存在しないタグに変更（例: `nginx:does-not-exist`）して再 `apply`。

```bash
kubectl apply -f deployment.yaml
kubectl -n k8s-magazine rollout status deploy/web
kubectl -n k8s-magazine describe pod <失敗Pod名>
kubectl -n k8s-magazine get events --sort-by=.metadata.creationTimestamp | tail -n 20
```

### 3. ロールバック（5–10分）
```bash
kubectl -n k8s-magazine rollout history deploy/web
kubectl -n k8s-magazine rollout undo deploy/web
kubectl -n k8s-magazine rollout status deploy/web
```

### 4. 後片付け（任意）
```bash
# 破壊的コマンド: 対象Namespaceを必ず確認してから実行
kubectl get ns
kubectl delete ns k8s-magazine
```

---

## 6) Command Cheatsheet

```bash
# 文脈確認（最重要）
kubectl config current-context
kubectl config get-contexts
kubectl get ns

# 適用前チェック
kubectl diff -f deployment.yaml
kubectl apply --dry-run=server -f deployment.yaml

# 適用・確認
kubectl apply -f deployment.yaml
kubectl -n <ns> get deploy,pods,rs
kubectl -n <ns> describe deploy <name>
kubectl -n <ns> logs deploy/<name> --tail=100

# ロールアウト
kubectl -n <ns> rollout status deploy/<name>
kubectl -n <ns> rollout history deploy/<name>
kubectl -n <ns> rollout undo deploy/<name>
```

---

## 7) よくあるミス & 安全策

- **ミス:** 別クラスタにapplyしてしまう  
  **安全策:** 実行前に毎回 `kubectl config current-context`。

- **ミス:** default namespaceへ誤適用  
  **安全策:** manifestに `metadata.namespace` を明記し、`-n` を明示。

- **ミス:** SecretをYAML平文でGit管理  
  **安全策:** 機密情報はSecret管理（必要なら暗号化/外部Secretストア）。

- **ミス:** `kubectl delete` のスコープ誤り  
  **安全策:** 破壊的操作前に対象を `get` で確認。可能なら `--dry-run=server` / `kubectl diff` を活用。

- **ミス:** probe未設定で起動直後Podに流入  
  **安全策:** readinessProbeを必須化し、段階リリース。

---

## 8) 面接っぽい確認問題（1問）

**Q.** `kubectl apply` と `kubectl replace` の違いは？本番運用で `apply` が選ばれやすい理由を説明してください。  
**Aの方向性:** 宣言的管理・差分適用・GitOpsとの親和性、運用時の再現性/監査性。

---

## 9) 次の学習リソース（公式優先）

- Kubernetes Documentation (Home)  
  https://kubernetes.io/docs/
- Deployments  
  https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- kubectl Overview  
  https://kubernetes.io/docs/reference/kubectl/
- Probes (liveness/readiness/startup)  
  https://kubernetes.io/docs/concepts/configuration/liveness-readiness-startup-probes/
- Resource Management for Pods and Containers  
  https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/
- Secrets  
  https://kubernetes.io/docs/concepts/configuration/secret/
- Configure Access to Multiple Clusters (Contexts)  
  https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/

---

明日の予告（難易度ループ継続）:  
**Beginner:** Service/ClusterIP基本  
**Middle:** Ingress + TLS基礎  
**Advanced:** HPAとメトリクス駆動スケーリング
