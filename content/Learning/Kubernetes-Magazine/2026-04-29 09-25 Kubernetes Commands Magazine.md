---
tags: [kubernetes, k8s, devops, learning, daily]
---

# Daily Kubernetes Commands Magazine - 2026-04-29
[[Home]]

## 今回の学習アーク
- **Beginner:** `kubectl get/describe/logs` でワークロード観察
- **Middle:** Deployment のローリング更新と `kubectl rollout` 運用
- **Advanced:** ConfigMap/Secret の安全な適用と本番向け変更フロー

---

## 1) Topic + Level
### Beginner
**Topic:** Pod/Deployment の状態確認コマンド入門

### Middle
**Topic:** 安全なリリース運用（rollout / undo）
**前提知識:**
- `kubectl get` / `describe` / `logs` が使える
- Deployment と Pod の関係を理解している

### Advanced
**Topic:** 設定注入とセキュア運用（ConfigMap/Secret + apply 戦略）
**前提知識:**
- Deployment 更新手順（rollout status/history/undo）
- namespace/context を切って作業する習慣

---

## 2) なぜ実アプリ開発で重要か
- 開発現場では「動かない原因の切り分け」が最頻出。観察コマンドの精度が MTTR（復旧時間）を左右する。
- デプロイ時の事故（誤 image、誤 namespace、誤 context）は小さなミスで大障害につながる。
- Secret を manifest に直書きすると漏洩リスクが高く、監査・運用コストが跳ね上がる。

---

## 3) Core kubectl/Kubernetes concepts
- **desired state（宣言的管理）:** `apply` は「こうあるべき」を API Server に宣言。
- **reconciliation:** Controller が現在状態を desired state に収束させる。
- **Deployment / ReplicaSet / Pod:** Deployment が世代管理、ReplicaSet が Pod 数を維持。
- **rollout:** 更新進行の監視・履歴管理・ロールバック。
- **namespace/context:** 作業対象を限定する安全装置。

---

## 4) アプリ開発中での実践（kubernetes.io/docs ベストプラクティス寄り）
1. **毎回 context/namespace を明示確認**
   - `kubectl config current-context`
   - `kubectl get ns`
2. **変更前に dry-run / diff**
   - `kubectl apply --dry-run=server -f ...`
   - `kubectl diff -f ...`
3. **段階リリース**
   - まずステージング namespace で apply
   - 問題なければ本番へ
4. **Secret は Git 平文管理しない**
   - 少なくとも Base64 だけで「安全」と思わない（可逆）
   - External Secrets / Secret Manager 連携を検討
5. **障害対応は describe/events/logs の順で事実確認**
   - 推測より観測を先に

---

## 5) 30-60分ミニラボ（45分想定）
> ローカルクラスタ（kind/minikube）想定。破壊的コマンドは最後に明示。

### Step 0: 安全確認（5分）
```bash
kubectl config current-context
kubectl create ns magazine-lab
kubectl config set-context --current --namespace=magazine-lab
kubectl get ns
```

### Step 1: Beginner 観察（10分）
```bash
kubectl create deployment web --image=nginx:1.25
kubectl get deploy,rs,pods -o wide
kubectl describe deploy web
kubectl logs deploy/web
```
確認ポイント:
- Pod が Running になるまでの流れ
- `describe` の Events

### Step 2: Middle ローリング更新（15分）
```bash
kubectl set image deployment/web nginx=nginx:1.27
kubectl rollout status deployment/web
kubectl rollout history deployment/web
```
失敗を模擬（存在しない tag へ）:
```bash
kubectl set image deployment/web nginx=nginx:9.99
kubectl rollout status deployment/web
kubectl rollout undo deployment/web
kubectl rollout status deployment/web
```

### Step 3: Advanced 設定注入（10分）
```bash
echo 'APP_MODE=dev' > app.env
kubectl create configmap web-config --from-env-file=app.env
kubectl create secret generic web-secret --from-literal=API_KEY='dummy-key'
kubectl get configmap web-config -o yaml
kubectl get secret web-secret -o yaml
```
学習ポイント:
- Secret の値は Base64 であり暗号化ではない
- 本番は KMS/外部 Secret 管理を検討

### Step 4: 後片付け（5分）
⚠️ **破壊的操作。context/namespace を再確認してから実行**
```bash
kubectl config current-context
kubectl get ns | grep magazine-lab
kubectl delete ns magazine-lab
```

---

## 6) Command Cheatsheet
```bash
# 観察
kubectl get pods -A
kubectl describe pod <pod>
kubectl logs <pod> --previous
kubectl get events --sort-by=.metadata.creationTimestamp

# リリース運用
kubectl set image deployment/<name> <container>=<image:tag>
kubectl rollout status deployment/<name>
kubectl rollout history deployment/<name>
kubectl rollout undo deployment/<name>

# 安全確認
kubectl config current-context
kubectl config view --minify
kubectl diff -f k8s/
kubectl apply --dry-run=server -f k8s/
```

---

## 7) よくあるミス & Safe Practices
- **ミス:** `default` namespace に誤 apply  
  **対策:** `--namespace` 明示 or context に namespace 固定
- **ミス:** 本番 context のまま検証コマンド実行  
  **対策:** `current-context` を習慣化、プロンプトに context 表示
- **ミス:** Secret を YAML 直書きして Git push  
  **対策:** Secret manager 連携、少なくとも repo から分離
- **ミス:** `kubectl delete -f .` の適用範囲誤認  
  **対策:** 実行前に `kubectl diff` と対象 path を再確認
- **ミス:** ロールバック手順未確認で更新  
  **対策:** `rollout history` を見てから変更

---

## 8) Interview-style question
「本番で Deployment 更新後に一部 Pod が CrashLoopBackOff。あなたなら `kubectl` を使ってどの順番で原因を切り分け、いつロールバック判断しますか？」

---

## 9) Next-step resources（公式優先）
- Kubernetes Docs Home: https://kubernetes.io/docs/
- kubectl Overview: https://kubernetes.io/docs/reference/kubectl/
- Debug Running Pods: https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/
- Deployments: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Configuration Best Practices: https://kubernetes.io/docs/concepts/configuration/overview/
- Secrets: https://kubernetes.io/docs/concepts/configuration/secret/
- Configure Access to Multiple Clusters: https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/

---

次回予告（学習アーク継続）: Beginner→Middle→Advanced を維持しつつ、次は **Service/Ingress とトラブルシュート（接続不可系）** に進む。