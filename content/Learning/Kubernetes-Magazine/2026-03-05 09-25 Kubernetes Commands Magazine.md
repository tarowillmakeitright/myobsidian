# Daily Kubernetes Commands Magazine — 2026-03-05

#kubernetes #k8s #devops #learning #daily
[[Home]]

---

## 今号の学習アーク
1. **Beginner**: Pod の観察とログ確認
2. **Middle**: Deployment のローリングアップデートとロールバック
3. **Advanced**: Ingress + Service 設計と運用時の安全確認

難易度を段階的に上げ、実アプリ開発で「壊さずに前進する」ための kubectl 実践を積み上げます。

---

## 1) Topic + Level

### 🟢 Beginner
**Topic:** Pod を正しく見る（`get` / `describe` / `logs`）

### 🟡 Middle
**Topic:** Deployment を安全に更新する（`set image` / `rollout status` / `rollout undo`）
**Prerequisites:**
- Pod / ReplicaSet / Deployment の基本構造を理解している
- `kubectl get pods` と `kubectl logs` を使える
- Namespace の概念を把握している

### 🔴 Advanced
**Topic:** Service + Ingress を使った公開設計とトラブルシュート
**Prerequisites:**
- ClusterIP / NodePort / LoadBalancer の違いを説明できる
- HTTP ルーティング（Host / Path）の概念がある
- Deployment の更新手順（Middle レベル）を実行できる

---

## 2) Why it matters for real app development

- **Beginner:** 本番障害の初動は「状況把握の速さ」で決まる。`describe` と `logs` が使えないと復旧が遅れる。
- **Middle:** デプロイは毎日の作業。ローリングアップデートとロールバックを安全に回せると、リリース速度と品質が両立する。
- **Advanced:** アプリ公開時の障害（繋がらない、404、TLS 絡み）は Service/Ingress 設計の理解不足で起こる。正しい分離と確認手順が不可欠。

---

## 3) Core kubectl/Kubernetes concept explanations

### Beginner: 観察系コマンド
- `kubectl get pods -n <ns>`: 一覧を素早く確認（状態・再起動回数）
- `kubectl describe pod <pod> -n <ns>`: Events まで含めた詳細確認
- `kubectl logs <pod> -n <ns> --tail=100`: 直近ログ確認
- `kubectl logs <pod> -c <container> -n <ns>`: マルチコンテナ時の明示

**ポイント:** 障害解析は「状態（get）→理由（describe）→証拠（logs）」の順が基本。

### Middle: 宣言的リソースと更新制御
- Deployment は desired state（望ましい状態）を宣言
- `kubectl set image deployment/<name> ...` でイメージ差し替え
- `kubectl rollout status deployment/<name>` で更新完了待ち
- `kubectl rollout history deployment/<name>` で履歴確認
- `kubectl rollout undo deployment/<name>` で安全に戻す

**ポイント:** 「更新できる」より「戻せる」ことが本番運用で重要。

### Advanced: Service と Ingress の責務分離
- Service: Pod への安定した到達点（L4）
- Ingress: HTTP/HTTPS ルーティング（L7、Ingress Controller が必要）
- app 開発では「アプリ実装」と「公開経路設定」を分離すると変更に強い

**ポイント:** いきなり Ingress を疑う前に Pod → Service → Ingress の順で層別確認。

---

## 4) How Kubernetes is used while building apps (kubernetes.io/docs ベストプラクティス準拠)

- **マニフェストは Git 管理**し、レビューを通して変更（手作業 drift を減らす）
- **Namespace を環境単位で分離**（dev/stg/prod）
- **ラベル設計を先に決める**（`app`, `component`, `version` など）
- **Readiness/Liveness Probe を設定**して不健康 Pod を自動切り離し
- **リソース requests/limits を定義**してノード枯渇や過剰スケジューリングを防止
- **Secret を manifest に平文で埋めない**（Git に置かない・表示ログに出さない）
- **最小権限（RBAC）**を徹底し、運用コマンドの実行者範囲を限定

参考（公式）:
- https://kubernetes.io/docs/concepts/configuration/overview/
- https://kubernetes.io/docs/concepts/security/secrets-good-practices/
- https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/
- https://kubernetes.io/docs/concepts/services-networking/service/
- https://kubernetes.io/docs/concepts/services-networking/ingress/

---

## 5) 30-60分ハンズオン mini lab

### 目標
- Pod 観察 → Deployment 更新 → ロールバック → Service/Ingress 疎通確認までを一連で実施

### 想定時間
- 45分

### 手順

#### Step 0: 安全確認（3分）
```bash
kubectl config current-context
kubectl get ns
```
- **実行前に必ず context を確認**（本番誤爆防止）
- 以降 `-n k8s-lab` を固定

#### Step 1: Namespace と Deployment 作成（10分）
```bash
kubectl create namespace k8s-lab
kubectl create deployment web --image=nginx:1.25 -n k8s-lab
kubectl get pods -n k8s-lab -w
```

#### Step 2: 観察（Beginner）（8分）
```bash
kubectl get pods -n k8s-lab -o wide
kubectl describe deployment web -n k8s-lab
POD=$(kubectl get pods -n k8s-lab -l app=web -o jsonpath='{.items[0].metadata.name}')
kubectl logs "$POD" -n k8s-lab --tail=50
```

#### Step 3: 更新とロールバック（Middle）（12分）
```bash
kubectl set image deployment/web nginx=nginx:1.26 -n k8s-lab
kubectl rollout status deployment/web -n k8s-lab
kubectl rollout history deployment/web -n k8s-lab
```

失敗を模擬（存在しないタグ）:
```bash
kubectl set image deployment/web nginx=nginx:does-not-exist -n k8s-lab
kubectl rollout status deployment/web -n k8s-lab --timeout=60s
kubectl rollout undo deployment/web -n k8s-lab
kubectl rollout status deployment/web -n k8s-lab
```

#### Step 4: Service と Ingress（Advanced）（10分）
```bash
kubectl expose deployment web --port=80 --target-port=80 --name=web-svc -n k8s-lab
kubectl get svc -n k8s-lab
```

Ingress（Controller 導入済み環境を前提）:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web-ing
  namespace: k8s-lab
spec:
  rules:
  - host: web.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-svc
            port:
              number: 80
```
```bash
kubectl apply -f ingress.yaml
kubectl describe ingress web-ing -n k8s-lab
```

#### Step 5: 後片付け（2分）
```bash
kubectl delete namespace k8s-lab
```
⚠️ **破壊的操作**。`k8s-lab` 以外を消さないこと。実行前に再確認。

---

## 6) Command cheatsheet

```bash
# Context / namespace
kubectl config current-context
kubectl config get-contexts
kubectl get ns

# Observe
kubectl get pods -n <ns>
kubectl describe pod <pod> -n <ns>
kubectl logs <pod> -n <ns> --tail=100

# Deployment update
kubectl set image deployment/<name> <container>=<image>:<tag> -n <ns>
kubectl rollout status deployment/<name> -n <ns>
kubectl rollout history deployment/<name> -n <ns>
kubectl rollout undo deployment/<name> -n <ns>

# Networking
kubectl get svc -n <ns>
kubectl get ingress -n <ns>
kubectl describe ingress <name> -n <ns>
```

---

## 7) Common mistakes and safe practices

### よくあるミス
- `kubectl apply -f .` を誤ディレクトリで実行
- `default` namespace に意図せずデプロイ
- 本番 context のまま検証コマンド実行
- Secret を YAML に平文記載して Git push
- `kubectl delete` をリソース範囲未確認で実行

### 安全策
- 毎回 `kubectl config current-context` を実行
- `-n <namespace>` を省略しない
- 変更前に `kubectl diff -f <file>` を使う
- 破壊的操作前に対象を `kubectl get ...` で再確認
- Secret は external secret manager / 暗号化ワークフローを検討

⚠️ **警告（重要）**
- `kubectl delete namespace <name>`
- `kubectl delete -f <file>`
- `kubectl apply -f .`

これらは影響範囲が大きいため、**context・namespace・対象ファイル**を必ず二重確認してから実行してください。

---

## 8) Interview-style question

**Q.** Deployment のローリングアップデート中に一部 Pod が起動失敗し続けています。サービス停止を最小化しつつ安全に復旧するために、`kubectl` コマンドを使ってどの順番で確認・対処しますか？

（期待される観点: rollout status / events / logs / rollout undo / readiness probe / image tag 妥当性）

---

## 9) Next-step resources（公式中心）

- Kubernetes Concepts
  - https://kubernetes.io/docs/concepts/
- Deployments
  - https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- kubectl Cheat Sheet
  - https://kubernetes.io/docs/reference/kubectl/cheatsheet/
- Services
  - https://kubernetes.io/docs/concepts/services-networking/service/
- Ingress
  - https://kubernetes.io/docs/concepts/services-networking/ingress/
- Secrets Good Practices
  - https://kubernetes.io/docs/concepts/security/secrets-good-practices/
- Configure Access to Multiple Clusters (context 管理)
  - https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/

---

次号予告: **Beginner→Middle→Advanced の次サイクル**として、ConfigMap/Secret 管理 → Probes/Resources 最適化 → HPA と可観測性（metrics）を扱います。