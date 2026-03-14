---
tags: [kubernetes, k8s, devops, learning, daily]
---

# 2026-03-14 Kubernetes Commands Magazine
[[Home]]

## 今日の学習アーク（Beginner → Middle → Advanced）
**共通トピック:** アプリ開発で使う「Deployment + Service + Config/Secret の安全運用」

---

## 1) Topic + Level

### Beginner
**トピック:** `kubectl` の基本観察コマンドで「今の状態」を正しく読む

### Middle
**トピック:** Deployment と Service でアプリを安全に公開・更新する
**前提知識:** Pod/Deployment/Service の基本、`kubectl get/describe/logs`

### Advanced
**トピック:** ConfigMap/Secret と rollout 戦略で本番に近い運用を行う
**前提知識:** Deployment の更新、YAML 編集、名前空間の理解

---

## 2) なぜ実アプリ開発で重要か
- 開発で最も多い障害は「コード」より「設定ミス」「環境差分」「更新手順ミス」。
- Kubernetes は、**宣言的な設定**と**ロールアウト管理**で、再現性の高いデプロイを実現する。
- `kubectl` で状態確認→原因特定→安全に修正、の流れを持つと、障害対応速度が大きく上がる。

---

## 3) コア概念（kubectl/Kubernetes）
- **Deployment**: Pod の望ましい状態を管理（レプリカ数、更新戦略）。
- **Service (ClusterIP/NodePort/LoadBalancer)**: Pod 群への安定したアクセス経路。
- **ConfigMap**: 非機密設定を外出し。
- **Secret**: 機密データを扱うオブジェクト（ただし暗号化・RBAC設計は別途必須）。
- **rollout**: 段階的更新とロールバック管理。
- **namespace/context**: 操作対象を誤ると事故の原因。常に明示確認。

---

## 4) アプリ開発での使い方（kubernetes.io/docs ベストプラクティス準拠）
- マニフェストは Git 管理し、`kubectl apply -f` で宣言的運用。
- まず `kubectl diff -f ...` で差分確認してから適用。
- Secret を YAML に平文で直書きしない（CI/CDのSecret管理や外部Secret連携を検討）。
- 本番相当では liveness/readiness probe を設定し、無停止更新を前提にする。
- 障害時は `get` → `describe` → `logs` → `rollout status/history` の順で追う。

---

## 5) 30–60分ミニラボ
**目標:** nginx アプリをデプロイし、安全に更新→問題時ロールバック。

### 手順
1. **作業用 namespace 作成**
```bash
kubectl create namespace mag-lab
kubectl config set-context --current --namespace=mag-lab
kubectl config current-context
```

2. **Deployment + Service 作成**
```bash
kubectl create deployment web --image=nginx:1.25
kubectl expose deployment web --port=80 --target-port=80 --type=ClusterIP
kubectl get all
```

3. **状態確認（Beginner）**
```bash
kubectl get pods -o wide
kubectl describe deployment web
kubectl logs deploy/web --tail=50
```

4. **ローリング更新（Middle）**
```bash
kubectl set image deployment/web nginx=nginx:1.26
kubectl rollout status deployment/web
kubectl rollout history deployment/web
```

5. **意図的に不正タグへ更新（検証）**
```bash
kubectl set image deployment/web nginx=nginx:does-not-exist
kubectl rollout status deployment/web
kubectl describe pod -l app=web
```
原因を確認後、
```bash
kubectl rollout undo deployment/web
kubectl rollout status deployment/web
```

6. **ConfigMap/Secret 追加（Advanced）**
```bash
kubectl create configmap web-config --from-literal=APP_MODE=prod
kubectl create secret generic web-secret --from-literal=API_TOKEN='dummy-token'
kubectl get configmap,secret
```
> 注意: 学習用ダミー値のみ。実運用の秘密情報は安全な経路で管理。

所要時間目安: 40〜55分

---

## 6) コマンドチートシート
```bash
# 文脈確認（超重要）
kubectl config get-contexts
kubectl config current-context
kubectl get ns

# 観察
kubectl get all -n <ns>
kubectl describe pod <pod> -n <ns>
kubectl logs <pod> -n <ns> --tail=100

# 変更（適用前に差分）
kubectl diff -f k8s/
kubectl apply -f k8s/

# ロールアウト
kubectl rollout status deploy/<name> -n <ns>
kubectl rollout history deploy/<name> -n <ns>
kubectl rollout undo deploy/<name> -n <ns>

# 削除（要注意）
kubectl delete -f k8s/ -n <ns>
```

---

## 7) よくあるミス & 安全策
- **ミス:** context/namespace を確認せず apply/delete。
  - **安全策:** 実行前に `kubectl config current-context` と `-n` 明示。
- **ミス:** Secret を Git にコミット。
  - **安全策:** 平文管理禁止。外部Secret管理・暗号化・権限制御。
- **ミス:** `kubectl delete` を広いスコープで実行。
  - **安全策:** 先に `kubectl get` で対象確認。必要ならラベル限定。
- **ミス:** 障害時に再デプロイ連打。
  - **安全策:** `describe/logs/events/rollout history` で原因確認後に対応。

> ⚠️ 破壊的コマンド警告: `delete` や広域 `apply` は、**クラスタ/namespace/対象リソース**を二重確認してから実行。

---

## 8) 面接風クエスチョン（1問）
**質問:** Deployment 更新後に一部Podが Ready にならず、サービス遅延が増えました。あなたは `kubectl` でどの順番で調査し、どの条件で rollback を判断しますか？

---

## 9) 次の一歩（公式ドキュメント優先）
- Kubernetes Concepts: https://kubernetes.io/docs/concepts/
- Deployments: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Services: https://kubernetes.io/docs/concepts/services-networking/service/
- ConfigMap: https://kubernetes.io/docs/concepts/configuration/configmap/
- Secrets: https://kubernetes.io/docs/concepts/configuration/secret/
- kubectl Cheat Sheet: https://kubernetes.io/docs/reference/kubectl/cheatsheet/
- Configure Access to Multiple Clusters (context): https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/

---

次号予告: **Ingress と TLS（cert-managerを含む）で安全な公開**（Beginner→Advanced の同アーク継続）
