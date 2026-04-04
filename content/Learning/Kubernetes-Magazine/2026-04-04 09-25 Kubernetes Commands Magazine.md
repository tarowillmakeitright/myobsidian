---
tags: [kubernetes, k8s, devops, learning, daily]
---

# 2026-04-04 Kubernetes Commands Magazine

[[Home]]

#kubernetes #k8s #devops #learning #daily

## 今週の学習アーク
**テーマ:** kubectlで安全にアプリをデプロイ・運用する

- **Beginner:** Pod/Deployment/Service の基本操作
- **Middle:** ConfigMap/Secret + Rolling Update + Probe運用
- **Advanced:** Namespace/Contextを意識した安全運用 + トラブルシュート

---

## 1) Topic + Level

### 🟢 Beginner: 「まずは壊さずに動かす」
`kubectl get / describe / logs / apply` の基本を使い、DeploymentとServiceを扱う。

### 🟡 Middle: 「設定と更新を安全に回す」
**前提:** Beginner内容（Deployment/Serviceの作成・確認・ログ確認）ができること。  
ConfigMap/Secret、`rollout`、Probe（liveness/readiness）を使って更新事故を減らす。

### 🔴 Advanced: 「本番を意識した操作精度」
**前提:** Middle内容（ロールアウト制御、設定分離、Probe）ができること。  
Namespace/Contextの誤操作防止、段階的なデバッグ、変更前確認を徹底する。

---

## 2) Why it matters for real app development

ローカル開発では動くのに、Kubernetes上で落ちる原因の多くは次の3つです。

1. 設定値の管理ミス（環境差分）
2. 更新時の停止・エラー（デプロイ戦略不足）
3. 誤ったクラスタ/Namespaceに対する操作

`kubectl`を「とりあえず実行」ではなく、**確認→適用→検証→ロールバック**の流れで使えると、
実アプリ開発の速度と安全性が大きく上がります。

---

## 3) Core kubectl/Kubernetes concept explanations

- **Pod**: コンテナ実行の最小単位（通常は直接管理しない）
- **Deployment**: Podの望ましい状態を管理し、更新を段階実行
- **Service**: Pod集合への安定したアクセス経路
- **Namespace**: 論理的な隔離単位（チーム/環境分離）
- **Context**: `kubectl`が接続先と認証情報を切り替える単位
- **ConfigMap / Secret**: 設定と機密情報の分離（SecretもBase64であり暗号化そのものではない点に注意）
- **Probe**: アプリの生存確認・受付可能判定をKubernetesに伝える仕組み

---

## 4) How Kubernetes is used while building apps (best practices aligned)

開発時の推奨フロー（kubernetes.io/docs の実践に沿う）:

1. **ManifestをGit管理**し、宣言的に`kubectl apply -f`する
2. 機密情報はManifestに直書きせず、**Secret参照**で扱う
3. 更新時は`kubectl rollout status`で完了確認する
4. 不調時は `get` → `describe` → `logs` → `events` の順で調査する
5. `--namespace` と `kubectl config current-context` を毎回確認する

---

## 5) 30-60 minute hands-on mini lab

### 目標
- NginxアプリをDeployment+Serviceで公開
- ConfigMap経由で設定注入
- Rolling UpdateとRollbackを体験

### 手順（約45分）

#### Step 0: 事故防止チェック（5分）
```bash
kubectl config current-context
kubectl get ns
```
> ⚠️ **破壊的操作前の原則**: 対象クラスタ・Namespaceを確認。  
> `delete` は `--dry-run=client -o yaml` や対象リソース再確認を先に。

#### Step 1: Namespace作成と切替（5分）
```bash
kubectl create namespace k8s-mag-lab
kubectl config set-context --current --namespace=k8s-mag-lab
kubectl get all
```

#### Step 2: DeploymentとService作成（10分）
```bash
kubectl create deployment web --image=nginx:1.25
kubectl expose deployment web --port=80 --type=ClusterIP
kubectl get deploy,po,svc
kubectl describe deployment web
```

#### Step 3: ConfigMap作成（10分）
```bash
kubectl create configmap web-config --from-literal=APP_MODE=learning
kubectl get configmap web-config -o yaml
```
Deploymentを`kubectl edit deployment web`で編集し、`envFrom`でConfigMapを参照。
反映後:
```bash
kubectl rollout status deployment/web
kubectl get pods
```

#### Step 4: Rolling Updateと検証（10分）
```bash
kubectl set image deployment/web nginx=nginx:1.26
kubectl rollout status deployment/web
kubectl rollout history deployment/web
```

#### Step 5: 意図的に戻す（Rollback）（5分）
```bash
kubectl rollout undo deployment/web
kubectl rollout status deployment/web
kubectl rollout history deployment/web
```

#### Step 6: 後片付け（任意）
```bash
kubectl config set-context --current --namespace=default
kubectl delete namespace k8s-mag-lab
```
> ⚠️ `kubectl delete namespace ...` は影響範囲が大きい。対象名を必ず二重確認。

---

## 6) Command cheatsheet

```bash
# 現在の接続先確認
kubectl config current-context
kubectl config view --minify

# リソース確認
kubectl get all -n <ns>
kubectl describe pod <pod> -n <ns>
kubectl logs <pod> -n <ns>

# 宣言的適用
kubectl apply -f <manifest.yaml>
kubectl diff -f <manifest.yaml>

# 更新管理
kubectl set image deployment/<name> <container>=<image>:<tag>
kubectl rollout status deployment/<name>
kubectl rollout undo deployment/<name>

# トラブルシュート
kubectl get events -n <ns> --sort-by=.lastTimestamp
kubectl top pod -n <ns>   # metrics-serverが必要
```

---

## 7) Common mistakes and safe practices

### よくあるミス
- `default` Namespaceにそのままデプロイ
- `latest`タグ使用で再現性喪失
- SecretをGitにコミット
- `kubectl delete` をコンテキスト未確認で実行
- `apply -f .` で意図しないManifestまで適用

### 安全策
- 毎回 `kubectl config current-context` と `-n/--namespace` を明示
- イメージは固定タグ（可能ならdigest）
- Secretは外部シークレット管理または安全な配布経路を利用
- `kubectl diff -f` で変更内容を先に確認
- 破壊的コマンド前に対象を`get`で確認

---

## 8) Interview-style question

**Q.** DeploymentのRolling Update中に一部PodがReadyにならず更新が止まりました。  
どの順序で調査し、どのコマンドを使って原因を切り分けますか？

（期待される観点: rollout status / describe / logs / events / probe設定 / resource不足 / rollback判断）

---

## 9) Next-step resources (official docs first)

- Kubernetes Concepts  
  https://kubernetes.io/docs/concepts/
- kubectl Overview  
  https://kubernetes.io/docs/reference/kubectl/
- Deployments  
  https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Probes (Liveness/Readiness/Startup)  
  https://kubernetes.io/docs/concepts/configuration/liveness-readiness-startup-probes/
- ConfigMap  
  https://kubernetes.io/docs/concepts/configuration/configmap/
- Secret  
  https://kubernetes.io/docs/concepts/configuration/secret/
- Debug Running Pods  
  https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/
- Best Practices for Configuration  
  https://kubernetes.io/docs/concepts/configuration/overview/

---

### 明日の予告
次回は「Service typeとIngressの使い分け（ClusterIP/NodePort/LoadBalancer + Ingress）」を、
Beginner→Middle→Advancedで実運用目線で整理します。
