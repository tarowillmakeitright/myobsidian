---
tags: [kubernetes, k8s, devops, learning, daily]
---

# 2026-05-16 09:25 Kubernetes Commands Magazine
[[Home]]

## 今号のテーマ
**ローカル開発から本番運用までの第一歩: `kubectl` で安全にアプリをデプロイ・観測する**

> 学習アーク: **Beginner → Middle → Advanced**

---

## 1) Topic + Level

### Beginner
**Topic:** Pod/Deployment/Service の基本を `kubectl` で扱う

### Middle（前提あり）
**Topic:** Namespace 分離・ConfigMap/Secret・Rolling Update の実践
**Prerequisites:**
- Beginner 内容を理解している
- YAML の基本（key/value, list）を読める
- `kubectl get/describe/logs/apply` を実行できる

### Advanced（前提あり）
**Topic:** Probe・Resource 制御・安全なデバッグと変更管理
**Prerequisites:**
- Middle 内容を理解している
- Deployment の更新戦略（RollingUpdate）を説明できる
- Namespace と Context の切り替えを安全に扱える

---

## 2) なぜ実アプリ開発で重要か

- **再現可能な開発環境**を作れる（チーム全員で同じ宣言的設定を使える）
- 本番で起きる問題の多くは、**設定差分・監視不足・リソース不足**に起因する
- `kubectl` と Kubernetes の基本概念を押さえると、
  - デプロイ失敗の切り分け
  - 段階的リリース
  - 安全なロールバック
  が実務で素早くできる
- セキュリティ面では、**Secret の扱い、権限、操作対象（context/namespace）確認**が事故防止に直結する

---

## 3) コア概念（kubectl/Kubernetes）

- **Pod**: コンテナ実行の最小単位。通常は直接運用せず Deployment 管理が基本。
- **Deployment**: Pod の望ましい状態を宣言し、更新や自己修復を行う。
- **Service**: Pod 群への安定したアクセス経路（ClusterIP/NodePort/LoadBalancer）。
- **Namespace**: 論理分離。環境（dev/stg/prod）やチームごとに分ける。
- **ConfigMap / Secret**: 設定値と機密値を分離して注入。**Secret を Git 平文で置かない**。
- **Probe (liveness/readiness/startup)**: ヘルスチェックで可用性を保つ。
- **Resource requests/limits**: スケジューリングと暴走防止に必須。

`kubectl` の基本思想:
- `get` で現状把握
- `describe` で詳細確認
- `logs` でアプリ視点の調査
- `apply` で宣言的更新
- `rollout` で更新状態/履歴/ロールバック管理

---

## 4) アプリ開発時の Kubernetes 活用（kubernetes.io/docs ベストプラクティス準拠）

- **宣言的管理 (`kubectl apply -f`) を基本にする**
  - 手動 ad-hoc 変更より、YAML をコード管理して再現性を確保
- **環境分離（Namespace）**
  - dev と prod を同じ Namespace に混在させない
- **設定と機密の分離**
  - 一般設定は ConfigMap、機密情報は Secret
  - さらに本番は External Secrets / Secret Manager 連携を検討
- **段階的リリース**
  - RollingUpdate + readinessProbe で安全に切替
- **観測性**
  - `kubectl logs`, `kubectl events`, `kubectl top`（metrics-server 前提）で一次調査
- **安全運用**
  - コマンド前に必ず `kubectl config current-context` と `-n <namespace>` を確認

---

## 5) 30〜60分ハンズオン・ミニラボ

### 目標
Nginx サンプルアプリを Namespace 上にデプロイし、ConfigMap/Secret、Rolling Update、Rollback を体験する。

### 手順（約45分）

#### Step 0: 事故防止チェック（5分）
```bash
kubectl config current-context
kubectl get ns
```
- 想定クラスタか確認
- 以降は `-n k8s-magazine` を明示する

#### Step 1: Namespace 作成（5分）
```bash
kubectl create namespace k8s-magazine
```

#### Step 2: Deployment + Service 作成（10分）
```bash
kubectl create deployment web --image=nginx:1.27 -n k8s-magazine
kubectl expose deployment web --port=80 --target-port=80 --type=ClusterIP -n k8s-magazine
kubectl get all -n k8s-magazine
```

#### Step 3: ConfigMap と Secret（10分）
```bash
kubectl create configmap web-config --from-literal=APP_MODE=dev -n k8s-magazine
kubectl create secret generic web-secret --from-literal=API_TOKEN='replace-me' -n k8s-magazine
kubectl get configmap,secret -n k8s-magazine
```
> 注意: `--from-literal` はシェル履歴に残る場合あり。実務では secret 管理基盤や安全な投入方法を使う。

#### Step 4: Rolling Update（10分）
```bash
kubectl set image deployment/web nginx=nginx:1.28 -n k8s-magazine
kubectl rollout status deployment/web -n k8s-magazine
kubectl rollout history deployment/web -n k8s-magazine
```

#### Step 5: Rollback（5分）
```bash
kubectl rollout undo deployment/web -n k8s-magazine
kubectl rollout status deployment/web -n k8s-magazine
```

#### Step 6: 観測（5分）
```bash
kubectl describe deployment web -n k8s-magazine
kubectl logs deploy/web -n k8s-magazine --tail=50
kubectl get events -n k8s-magazine --sort-by=.metadata.creationTimestamp
```

---

## 6) Command Cheatsheet

```bash
# コンテキスト/名前空間確認
kubectl config current-context
kubectl config get-contexts
kubectl get ns

# 基本確認
kubectl get pods -n <ns>
kubectl get deploy,svc -n <ns>
kubectl describe pod <pod> -n <ns>
kubectl logs <pod> -n <ns> --tail=100

# 宣言的適用
kubectl apply -f manifest.yaml -n <ns>
kubectl diff -f manifest.yaml -n <ns>

# 更新管理
kubectl set image deployment/<name> <container>=<image> -n <ns>
kubectl rollout status deployment/<name> -n <ns>
kubectl rollout history deployment/<name> -n <ns>
kubectl rollout undo deployment/<name> -n <ns>

# 安全な削除（対象確認後）
kubectl delete -f manifest.yaml -n <ns>
```

---

## 7) よくあるミス & 安全プラクティス

### よくあるミス
1. **context 間違い**で本番に apply/delete
2. `default` Namespace に全部投入して混乱
3. Secret を YAML/Git に平文保存
4. `kubectl delete` の対象を十分確認せず実行
5. readinessProbe 未設定で更新中に 5xx 発生

### 安全プラクティス
- 実行前ルーチン:  
  `kubectl config current-context` → `kubectl get ns` → `-n` 明示
- 破壊的操作前に必ず確認:  
  **「本当にこの context / namespace / manifest で削除するか？」**
- `kubectl apply` 前に `kubectl diff` を活用
- Secret は外部シークレット管理や暗号化ツール（例: Sealed Secrets, External Secrets）を検討
- 本番では最小権限（RBAC）を徹底

> ⚠️ 警告: `kubectl delete` / 広範囲 `apply -f .` はクラスタ影響が大きい。**対象・スコープ・コンテキストを二重確認**してから実行。

---

## 8) 面接風クエスチョン（1問）

**Q.** Deployment の Rolling Update 中に一部 Pod が起動するが Service で 502/503 が出る。最初に何を確認し、どう直す？

**期待される観点（要点）**
- readinessProbe の設定有無・条件
- `kubectl describe pod` でイベント確認
- `kubectl logs` でアプリ起動時間/依存先エラー確認
- resource requests/limits と OOMKill の有無
- 必要なら `rollout undo` で即時復旧

---

## 9) 次の一歩（公式中心）

- Kubernetes Concepts（公式）  
  https://kubernetes.io/docs/concepts/
- Kubectl Overview（公式）  
  https://kubernetes.io/docs/reference/kubectl/
- Deployments（公式）  
  https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Services, Load Balancing, and Networking（公式）  
  https://kubernetes.io/docs/concepts/services-networking/
- Configure a Pod to Use a ConfigMap（公式）  
  https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/
- Distribute Credentials Securely Using Secrets（公式）  
  https://kubernetes.io/docs/tasks/inject-data-application/distribute-credentials-secure/
- Probes（Liveness/Readiness/Startup）（公式）  
  https://kubernetes.io/docs/concepts/configuration/liveness-readiness-startup-probes/
- Resource Management for Pods and Containers（公式）  
  https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/

---

次号予告（学習アーク継続）:
- Beginner: `kubectl explain` と YAML 読解
- Middle: HPA とメトリクス活用
- Advanced: Pod Security / NetworkPolicy 入門
