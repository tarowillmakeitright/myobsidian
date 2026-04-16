---
tags:
  - kubernetes
  - k8s
  - devops
  - learning
  - daily
---

# 2026-04-16 09:25 Kubernetes Commands Magazine

[[Home]]

今日のテーマは **「アプリ開発を支える Kubernetes 基本運用アーク」** です。  
難易度は **Beginner → Middle → Advanced** の順で進みます。

---

## 1) Topic + Level

### 🟢 Beginner: Namespace / Pod / logs で「まず壊さず観察する」
**トピック:** `kubectl get/describe/logs` を使った安全な状況把握

### 🟡 Middle: Deployment のローリング更新とヘルスチェック
**前提条件:**
- Beginner の内容（Namespace/POD観察）が理解できている
- Deployment / Service の基本概念を知っている

**トピック:** `kubectl apply`, `rollout`, `set image` による段階的デプロイ

### 🔴 Advanced: Config/Secret/Probe/Resource 制御で本番品質へ
**前提条件:**
- Middle の内容（ロールアウト監視・ロールバック）が使える
- YAML マニフェストを読み書きできる

**トピック:** 安全な設定管理・可用性・リソース制御の実践

---

## 2) Why it matters for real app development

- ローカルでは動くのに本番で落ちる原因の多くは、**観測不足・設定不足・リソース不足**です。
- Kubernetes では「デプロイする」だけでなく、**状態を見て・安全に更新し・すぐ戻せる**ことが重要です。
- この流れを身につけると、障害時の MTTR（復旧時間）短縮、リリース事故の低減、チーム開発の再現性向上につながります。

---

## 3) Core kubectl/Kubernetes concept explanations

- **Namespace**: 環境やチームを論理分離する単位（`-n` を必ず意識）
- **Pod**: コンテナ実行最小単位。直接運用より Deployment 管理が基本
- **Deployment**: Pod の宣言的管理（Desired State）。更新/履歴/ロールバックを担う
- **Service**: Pod 群への安定した到達点
- **Probe**:
  - `livenessProbe`: ハング検知・再起動
  - `readinessProbe`: 受け付け可能になるまでトラフィックを流さない
- **ConfigMap/Secret**: 設定と機密の分離（機密は Secret、ただし暗号化設定と RBAC も必須）
- **Resource requests/limits**: スケジューリングと OOM 制御の基礎

---

## 4) How Kubernetes is used while building apps (kubernetes.io/docs best practices aligned)

アプリ開発の実務フロー例:

1. **観測から開始**（`get/describe/logs/events`）  
   いきなり再デプロイしない。まず現状確認。
2. **宣言的運用**（`kubectl apply -f`）  
   手動変更よりマニフェスト管理（Git 管理）を優先。
3. **安全な更新**（ローリング更新 + `rollout status`）  
   進行確認なしに次操作しない。
4. **すぐ戻せる設計**（`rollout undo`）  
   失敗前提で rollback 手順を先に準備。
5. **設定分離**（ConfigMap/Secret）  
   アプリコードと環境依存値を分離。
6. **健全性管理**（readiness/liveness + requests/limits）  
   “起動しただけ” ではなく “安全に配信可能” を定義。

参考（公式）:
- Concepts: https://kubernetes.io/docs/concepts/
- Workloads/Deployments: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Probes: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/
- ConfigMap: https://kubernetes.io/docs/concepts/configuration/configmap/
- Secret: https://kubernetes.io/docs/concepts/configuration/secret/
- Resource Mgmt: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/

---

## 5) 30-60 minute hands-on mini lab

> 目安 45 分 / kind or minikube 推奨

### Step 0: 事前安全チェック（5分）
```bash
kubectl config current-context
kubectl get ns
```
- **狙い:** 誤クラスタ・誤環境操作を防ぐ

### Step 1: 学習用 Namespace 作成（5分）
```bash
kubectl create ns k8s-mag-lab
kubectl config set-context --current --namespace=k8s-mag-lab
kubectl get all
```

### Step 2: Deployment 作成（10分）
`deploy.yaml` を作成して apply:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
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
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 10
          periodSeconds: 10
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            cpu: "300m"
            memory: "256Mi"
```
```bash
kubectl apply -f deploy.yaml
kubectl rollout status deploy/web
kubectl get pods -o wide
```

### Step 3: ローリング更新と監視（10分）
```bash
kubectl set image deploy/web nginx=nginx:1.26
kubectl rollout status deploy/web
kubectl rollout history deploy/web
kubectl get rs
```

### Step 4: 意図的に失敗させ rollback（10分）
```bash
kubectl set image deploy/web nginx=nginx:does-not-exist
kubectl rollout status deploy/web
kubectl rollout undo deploy/web
kubectl rollout status deploy/web
```

### Step 5: ConfigMap + Secret 導入（5-10分）
```bash
kubectl create configmap web-config --from-literal=APP_MODE=dev
kubectl create secret generic web-secret --from-literal=API_KEY='dummy-value'
kubectl get configmap,secret
```
- 注意: 実運用では Secret 値を履歴に残さない運用（外部 Secret 管理）を検討

---

## 6) Command cheatsheet

```bash
# 文脈確認
kubectl config current-context
kubectl config get-contexts
kubectl get ns

# 観測
kubectl get pods -A
kubectl describe pod <pod>
kubectl logs <pod> --tail=100
kubectl get events --sort-by=.lastTimestamp

# デプロイ運用
kubectl apply -f <file>
kubectl rollout status deploy/<name>
kubectl rollout history deploy/<name>
kubectl rollout undo deploy/<name>
kubectl set image deploy/<name> <container>=<image:tag>

# 設定管理
kubectl create configmap <name> --from-literal=KEY=VALUE
kubectl create secret generic <name> --from-literal=KEY=VALUE

# 後片付け（要確認）
kubectl delete ns k8s-mag-lab
```

---

## 7) Common mistakes and safe practices

### よくあるミス
- `kubectl apply -f .` を意図せず広範囲に実行
- context/namespace 未確認で本番クラスタに操作
- Secret を平文 YAML で Git にコミット
- Probe 未設定で「起動してるのに使えない」状態を見逃す
- requests/limits 未設定でノード逼迫や OOM 発生

### 安全プラクティス
- 実行前に毎回 `kubectl config current-context` と `-n` 確認
- 変更前に `kubectl diff -f <file>` を活用
- 破壊的コマンド前は対象を具体確認（Namespace/Label/Resource）
- Secret は external secret manager / 暗号化（at-rest）/ RBAC 最小権限をセットで
- 本番変更は `rollout status` 完了確認までを1セットにする

> ⚠️ 警告: `kubectl delete`, `kubectl apply -f .`, `kubectl replace --force` は影響範囲を誤ると重大事故につながります。必ず context と対象スコープを再確認してください。

---

## 8) Interview-style question

**質問:**
Deployment のローリング更新中に一部 Pod が Ready にならず `rollout status` が完了しない場合、あなたならどの順番で原因を切り分けますか？  
（確認コマンドと、rollback の判断基準を説明してください）

---

## 9) Next-step resources (official preferred)

- Kubernetes Concepts: https://kubernetes.io/docs/concepts/
- kubectl Overview: https://kubernetes.io/docs/reference/kubectl/
- Deployments: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Probes: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/
- Secrets good practices: https://kubernetes.io/docs/concepts/security/secrets-good-practices/
- Resource Management: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/
- Debugging Applications: https://kubernetes.io/docs/tasks/debug/debug-application/

---

次回予告（学習アーク継続）:  
**Ingress + Service 設計（Beginner）→ HPA とメトリクス（Middle）→ NetworkPolicy + PodSecurity + マルチ環境戦略（Advanced）**
