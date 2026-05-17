---
tags: [kubernetes, k8s, devops, learning, daily]
---

# Daily Kubernetes Commands Magazine
**Date:** 2026-05-17 09:25 (Asia/Tokyo)  
**Learning Arc:** Beginner → Middle → Advanced  
**Link:** [[Home]]

---

## 1) Topic + Level

### Beginner（初級）
**Topic:** `kubectl`の基本操作と安全確認（context / namespace / get / describe / logs）

### Middle（中級）
**Topic:** Deployment のローリングアップデートと Service での公開

**Prerequisites（前提知識）:**
- Pod / Deployment / Service の基本概念
- `kubectl get/describe/logs` の実行経験
- namespace と context の意味を理解していること

### Advanced（上級）
**Topic:** ConfigMap/Secret + probes + requests/limits を使った本番寄り運用

**Prerequisites（前提知識）:**
- Deployment の更新戦略（RollingUpdate）
- Service 経由でアプリ公開した経験
- YAML マニフェスト編集に慣れていること

---

## 2) Why it matters（実アプリ開発でなぜ重要か）

- 開発チームでは、**まず壊さずに状況確認する力**（get/describe/logs）が最重要。
- リリース時は Deployment 更新を安全に進め、**ダウンタイムを避ける設計**が必要。
- 本番では設定値や資格情報、ヘルスチェック、リソース制御が必須で、ここを誤ると障害や情報漏えいにつながる。

---

## 3) Core kubectl / Kubernetes concepts（コア概念）

- **Context**: どのクラスタに向いているか。誤操作防止の最優先確認ポイント。  
  - `kubectl config current-context`
- **Namespace**: リソースの論理分離。環境（dev/stg/prod）分離に有効。  
  - `kubectl get ns`
- **Deployment**: Pod の宣言的管理（レプリカ数、更新戦略）。
- **Service**: Pod 群への安定したアクセス窓口。
- **ConfigMap / Secret**: 設定値と機密値を分離して注入。
- **Probes**: アプリ健全性を Kubelet が判断（liveness/readiness/startup）。
- **Requests/Limits**: スケジューリングと過負荷防止のための資源定義。

---

## 4) App building alignment（kubernetes.io/docs ベストプラクティス準拠）

実装時は以下を徹底:

1. **宣言的管理**（YAML を Git 管理）
2. **最小権限 / 秘密情報分離**（Secret は平文コミットしない）
3. **段階的デプロイ**（`rollout status/history/undo`）
4. **可観測性の確保**（logs + describe + events を最初に確認）
5. **リソース明示**（requests/limits 必須）

参考（公式）:
- Overview: https://kubernetes.io/docs/concepts/overview/
- Deployments: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Services: https://kubernetes.io/docs/concepts/services-networking/service/
- ConfigMap: https://kubernetes.io/docs/concepts/configuration/configmap/
- Secret: https://kubernetes.io/docs/concepts/configuration/secret/
- Probes: https://kubernetes.io/docs/concepts/configuration/liveness-readiness-startup-probes/
- Resource Management: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/

---

## 5) 30–60分 Mini Lab（実践）

### Goal
Nginx Deployment を作成し、Service で公開、設定注入、更新・ロールバックを安全に体験する。

### 所要時間
約45分

### 手順

#### 0. 事故防止チェック（3分）
```bash
kubectl config current-context
kubectl get ns
kubectl config view --minify | grep namespace:
```
> ⚠️ **WARNING**: `delete`/`apply` 実行前に context と namespace を必ず確認。誤クラスタ事故を防ぐ。

#### 1. Namespace 作成（5分）
```bash
kubectl create ns k8s-mag-lab
kubectl config set-context --current --namespace=k8s-mag-lab
kubectl get ns
```

#### 2. Deployment & Service 作成（10分）
```bash
kubectl create deployment web --image=nginx:1.27
kubectl expose deployment web --port=80 --target-port=80 --type=ClusterIP
kubectl get deploy,po,svc
kubectl rollout status deployment/web
```

#### 3. ConfigMap 作成と環境変数注入（10分）
```bash
kubectl create configmap web-config --from-literal=APP_MODE=lab
kubectl set env deployment/web --from=configmap/web-config
kubectl rollout status deployment/web
kubectl describe deployment web | grep -A3 "Environment"
```

#### 4. ローリングアップデート（8分）
```bash
kubectl set image deployment/web nginx=nginx:1.27.1
kubectl rollout status deployment/web
kubectl rollout history deployment/web
```

#### 5. ロールバック体験（5分）
```bash
kubectl rollout undo deployment/web
kubectl rollout status deployment/web
kubectl rollout history deployment/web
```

#### 6. ログとイベント確認（5分）
```bash
kubectl logs deploy/web --tail=50
kubectl get events --sort-by=.lastTimestamp | tail -n 20
```

#### 7. 後片付け（任意, 3分）
```bash
# 破壊的操作: 対象namespaceを最終確認してから実行
kubectl config view --minify | grep namespace:
kubectl delete ns k8s-mag-lab
```

---

## 6) Command Cheatsheet

```bash
# 現在の接続先確認
kubectl config current-context
kubectl config get-contexts

# 名前空間
kubectl get ns
kubectl config set-context --current --namespace=<ns>

# 参照系（安全）
kubectl get all -n <ns>
kubectl describe pod <pod> -n <ns>
kubectl logs deploy/<name> -n <ns> --tail=100

# デプロイ更新
kubectl set image deployment/<name> <container>=<image>:<tag>
kubectl rollout status deployment/<name>
kubectl rollout history deployment/<name>
kubectl rollout undo deployment/<name>

# 事前差分確認
kubectl diff -f <manifest.yaml>
```

---

## 7) Common mistakes & safe practices

### よくあるミス
- `kubectl apply -f .` を誤ディレクトリで実行
- prod context のまま検証コマンドを実行
- Secret を平文 YAML で Git にコミット
- requests/limits 未設定でノイジーネイバー化

### 安全プラクティス
- **apply/delete前に**: `current-context` + `namespace` を確認
- `kubectl diff` で差分確認してから apply
- Secret は External Secrets / Sealed Secrets / KMS 等を検討
- 破壊的コマンドは対象を明示（`-n <ns>`、リソース名指定）
- 可能なら本番は GitOps ワークフロー経由で反映

---

## 8) Interview-style question

**Q.** `kubectl apply -f deployment.yaml` 後に Pod が Ready になりません。最初の10分で何をどの順番で確認しますか？

**A（期待される観点）:**
1. context / namespace の確認  
2. `kubectl get pods` で状態確認  
3. `kubectl describe pod` で Events（ImagePullBackOff, probe失敗など）確認  
4. `kubectl logs` でアプリログ確認  
5. Deployment/ReplicaSet の履歴と直近変更差分確認

---

## 9) Next-step resources（公式優先）

- Kubernetes Basics (Interactive): https://kubernetes.io/docs/tutorials/kubernetes-basics/
- kubectl Cheat Sheet: https://kubernetes.io/docs/reference/kubectl/cheatsheet/
- Debug Running Pods: https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/
- Production Best Practices（Security含む）: https://kubernetes.io/docs/setup/best-practices/
- Secrets Good Practices: https://kubernetes.io/docs/concepts/security/secrets-good-practices/

---

次号予告（学習アーク継続）:
- Beginner: labels/selectors の実戦
- Middle: Ingress + TLS 基礎
- Advanced: HPA とメトリクス監視の導入
