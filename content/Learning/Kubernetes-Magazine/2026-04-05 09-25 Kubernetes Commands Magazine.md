---
tags:
  - kubernetes
  - k8s
  - devops
  - learning
  - daily
---

# Kubernetes Commands Magazine — 2026-04-05 09:25
[[Home]]

今日の学習アークは **Beginner → Middle → Advanced** の3段階です。  
テーマは一貫して **「安全な Deployment 運用と段階的デバッグ」**。

---

## 1) Topic + Level

### Beginner
**Topic:** Deployment を `kubectl apply` で作成し、状態を読む

### Middle
**Topic:** Rolling Update / Rollback と rollout 管理

**Prerequisites (Middle):**
- Pod / Deployment / Service の基本概念
- `kubectl get`, `kubectl describe`, `kubectl logs` の基本操作

### Advanced
**Topic:** 障害調査（イベント・プローブ・リソース制限）と安全な修復フロー

**Prerequisites (Advanced):**
- Middle の内容（rollout の更新と戻し）が実施できる
- readinessProbe / livenessProbe / requests/limits の意味を理解している

---

## 2) Why it matters for real app development

- アプリ開発では、**「作る」より「安全に更新し続ける」**時間の方が長いです。  
- Deployment 運用を理解すると、
  - 新機能を止めずに配信できる
  - 失敗時にすぐロールバックできる
  - 事故原因をイベントや状態から短時間で切り分けできる
- これは本番での MTTR（復旧時間）短縮に直結します。

---

## 3) Core kubectl / Kubernetes concepts

- **apply**: 宣言的管理。マニフェストを「望ましい状態」として適用する。  
  - 例: `kubectl apply -f deployment.yaml`
- **get / describe / logs / events**: 状態確認の基本4点。
- **rollout**: Deployment の更新状況・履歴・巻き戻しを管理。  
  - `kubectl rollout status/history/undo`
- **readinessProbe**: ルーティング可能か判定（失敗時は Service から外れる）。
- **livenessProbe**: 生存判定（失敗が続くと再起動）。
- **requests / limits**: スケジューリングと OOM/CPU 枯渇回避の基本。
- **namespace/context**: 操作対象の誤りを防ぐ安全ガード。

---

## 4) App building での Kubernetes 利用（公式ベストプラクティス準拠）

実務では次の流れが基本です。

1. マニフェストを Git 管理（宣言的）
2. `kubectl diff` で差分確認
3. `kubectl apply -f <dir>` を **対象 namespace 明示**で実行
4. `kubectl rollout status` で更新完了確認
5. 異常時は `kubectl describe pod` / `kubectl get events` / `kubectl logs` で調査
6. 必要なら `kubectl rollout undo` で即時復旧

> 重要: Secret を平文でマニフェストに埋め込まない。  
> Git に機密を書かない（Sealed Secrets / External Secrets / CI 注入などを採用）。

---

## 5) 30-60分ハンズオン mini lab

**目標:** Nginx Deployment を安全に更新し、意図的失敗から復旧する

### 所要時間
- 45分目安

### 手順

#### Step 0: 安全確認（2分）
```bash
kubectl config current-context
kubectl get ns
```
作業用 namespace を作成:
```bash
kubectl create namespace k8s-mag-lab
```

#### Step 1: 初期 Deployment 作成（10分）
`deployment.yaml`:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
  namespace: k8s-mag-lab
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

適用:
```bash
kubectl apply -f deployment.yaml
kubectl -n k8s-mag-lab get deploy,pod
kubectl -n k8s-mag-lab rollout status deploy/web
```

#### Step 2: 安全な更新（10分）
イメージを更新:
```bash
kubectl -n k8s-mag-lab set image deploy/web nginx=nginx:1.26
kubectl -n k8s-mag-lab rollout status deploy/web
kubectl -n k8s-mag-lab rollout history deploy/web
```

#### Step 3: 意図的に壊して復旧（15分）
存在しないタグに変更（失敗を学ぶ）:
```bash
kubectl -n k8s-mag-lab set image deploy/web nginx=nginx:does-not-exist
kubectl -n k8s-mag-lab rollout status deploy/web
```
別ターミナルで調査:
```bash
kubectl -n k8s-mag-lab get pod
kubectl -n k8s-mag-lab describe pod <pod名>
kubectl -n k8s-mag-lab get events --sort-by=.metadata.creationTimestamp
```

ロールバック:
```bash
kubectl -n k8s-mag-lab rollout undo deploy/web
kubectl -n k8s-mag-lab rollout status deploy/web
```

#### Step 4: 片付け（必要時、5分）
```bash
kubectl delete namespace k8s-mag-lab
```
⚠️ 削除コマンドは対象 namespace を必ず目視確認してから実行。

---

## 6) Command cheatsheet

```bash
# コンテキスト/名前空間確認
kubectl config current-context
kubectl config get-contexts
kubectl get ns

# 適用前チェック
kubectl diff -f deployment.yaml
kubectl apply -f deployment.yaml

# 状態確認
kubectl -n k8s-mag-lab get deploy,pod,rs
kubectl -n k8s-mag-lab describe deploy web
kubectl -n k8s-mag-lab logs deploy/web
kubectl -n k8s-mag-lab get events --sort-by=.metadata.creationTimestamp

# ロールアウト
kubectl -n k8s-mag-lab rollout status deploy/web
kubectl -n k8s-mag-lab rollout history deploy/web
kubectl -n k8s-mag-lab rollout undo deploy/web

# イメージ更新
kubectl -n k8s-mag-lab set image deploy/web nginx=nginx:1.26
```

---

## 7) Common mistakes and safe practices

### よくあるミス
- `default` namespace に誤って apply
- 本番 context のまま検証コマンドを実行
- `kubectl delete` の対象を確認せず実行
- Secret を YAML に平文で記述し Git へ push
- readinessProbe 未設定で、起動途中 Pod にトラフィックが流れる

### 安全プラクティス
- 実行前に毎回: `kubectl config current-context` と `-n <namespace>` 明示
- 変更前に `kubectl diff -f ...`
- 破壊的操作前に「対象・影響範囲・復旧手段」を確認
- Secret は外部シークレット管理または暗号化方式を使う
- 本番変更時は rollout 監視 + rollback 手順を事前準備

**破壊的コマンド警告:**  
`kubectl delete`, `kubectl apply -f <directory>`, `kubectl replace --force` はスコープ誤りで大事故になりやすい。  
必ず context / namespace / 対象リソースを二重確認してから実行。

---

## 8) Interview-style question

**Q.** `readinessProbe` と `livenessProbe` の違いは何ですか？また、片方しか設定しない場合に起こり得る問題を説明してください。  

（答えるときの観点: トラフィック制御 / 再起動制御 / 障害時挙動 / ユーザー影響）

---

## 9) Next-step resources (official docs 중심)

- Kubernetes Documentation (Home):  
  https://kubernetes.io/docs/home/
- Deployment:  
  https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- kubectl Overview:  
  https://kubernetes.io/docs/reference/kubectl/
- Probes (Liveness/Readiness/Startup):  
  https://kubernetes.io/docs/concepts/configuration/liveness-readiness-startup-probes/
- Resource Management for Pods and Containers:  
  https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/
- Debug Running Pods:  
  https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/
- Secrets Good Practices:  
  https://kubernetes.io/docs/concepts/security/secrets-good-practices/

---

次号予告（Advanced へ接続）:  
**ConfigMap/Secret の安全運用 + Rolling Update 戦略（maxSurge/maxUnavailable）を実務目線で深掘り**
