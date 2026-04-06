# Kubernetes Commands Magazine — 2026-04-06 09:25

#kubernetes #k8s #devops #learning #daily  
[[Home]]

---

## 今回の学習アーク（Beginner → Middle → Advanced）
テーマは **「安全にアプリをデプロイし、観測し、段階的に更新する」** です。  
実務で最も事故が起きやすい「適用先ミス」「削除コマンド」「Secret管理」を重点的に扱います。

---

## 1) Topic + Level

### Beginner
**Topic:** `kubectl` の基本操作と安全確認（context/namespace/get/describe/logs）

### Middle
**Topic:** Deployment と Service の実践運用（rollout・スケール・自己修復）
**前提知識:**
- `kubectl get/describe/logs` が使える
- Pod / Deployment / Service の役割をざっくり説明できる
- context と namespace を確認する習慣がある

### Advanced
**Topic:** 安全な更新戦略（RollingUpdate・履歴確認・ロールバック・PodDisruptionBudget 入門）
**前提知識:**
- Deployment の作成/更新/確認ができる
- readiness/liveness probe の目的を説明できる
- `kubectl rollout` 系コマンドの基本を理解している

---

## 2) なぜ実アプリ開発で重要か

- 開発チームは「作る」だけでなく「壊さず届ける」責任がある
- Kubernetes は本番運用での再現性（宣言的管理）を高める
- 事故の多くは設定値ミスより、**操作対象ミス（cluster/context/namespace）** で起きる
- `kubectl` を安全に扱えると、障害時の初動（観測→切り分け→復旧）が速くなる

---

## 3) コア概念（kubectl / Kubernetes）

- **Context**: どのクラスタに対して操作するか
- **Namespace**: クラスタ内の論理的な分離単位
- **Pod**: コンテナ実行単位（通常は直接運用より Deployment 経由）
- **Deployment**: レプリカ数維持、更新戦略、ロールバック管理
- **Service**: Pod 群への安定したアクセス経路
- **Probe**: liveness/readiness でヘルス判定
- **宣言的適用（apply）**: マニフェストを望ましい状態として管理

> 安全原則: 「実行前に対象確認（context/namespace）」「広範囲 delete を避ける」「Secret を平文で保存しない」

---

## 4) アプリ開発での使い方（kubernetes.io/docs のベストプラクティス準拠）

1. **ローカル/CI でマニフェストを検証**  
   - `kubectl apply --dry-run=client -f ...` で構文と生成内容を確認
2. **namespace を分ける（dev/stg/prod）**  
   - 誤操作の blast radius を下げる
3. **Deployment + readinessProbe を基本形にする**  
   - 準備できた Pod のみにトラフィックを流す
4. **rollout で段階更新**  
   - `rollout status/history/undo` を使い、失敗時に即戻せる体制を作る
5. **Secret/Config 分離**  
   - 機密は Secret、一般設定は ConfigMap
   - Git に平文 Secret を置かない（Sealed Secrets / External Secrets なども検討）

---

## 5) 30〜60分ハンズオン・ミニラボ

### ゴール
Nginx アプリを安全にデプロイし、更新し、問題時にロールバックできることを体験する。

### 手順（45分想定）

#### Step 0: 事前安全確認（5分）
```bash
kubectl config get-contexts
kubectl config current-context
kubectl get ns
```
- ここで **対象クラスタが意図通りか必ず確認**

#### Step 1: 学習用 namespace 作成（5分）
```bash
kubectl create namespace k8s-mag-lab
kubectl config set-context --current --namespace=k8s-mag-lab
kubectl get ns
```

#### Step 2: Deployment / Service 作成（10分）
```bash
kubectl create deployment web --image=nginx:1.25
kubectl expose deployment web --port=80 --type=ClusterIP
kubectl get deploy,rs,pods,svc
kubectl rollout status deployment/web
```

#### Step 3: 観測（5分）
```bash
kubectl describe deployment web
kubectl logs -l app=web --tail=50
```

#### Step 4: 安全な更新（10分）
```bash
kubectl set image deployment/web nginx=nginx:1.27
kubectl rollout status deployment/web
kubectl rollout history deployment/web
```

#### Step 5: ロールバック演習（5分）
```bash
kubectl rollout undo deployment/web
kubectl rollout status deployment/web
```

#### Step 6: 後片付け（必要なら）（5分）
```bash
# 破壊的操作: 対象namespaceを再確認してから実行
kubectl get all -n k8s-mag-lab
kubectl delete namespace k8s-mag-lab
```

> ⚠️ `delete namespace` は破壊的です。誤った context で実行すると重大事故になります。

---

## 6) Command Cheatsheet

```bash
# 対象確認
kubectl config current-context
kubectl config get-contexts
kubectl get ns

# 基本観測
kubectl get pods -A
kubectl get deploy,svc -n <namespace>
kubectl describe pod <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace> --tail=100

# デプロイ更新
kubectl apply -f <manifest.yaml>
kubectl rollout status deployment/<name> -n <namespace>
kubectl rollout history deployment/<name> -n <namespace>
kubectl rollout undo deployment/<name> -n <namespace>

# 安全確認付き dry-run
kubectl apply --dry-run=client -f <manifest.yaml>
```

---

## 7) よくあるミスと安全策

- ミス: `default` namespace のまま本番操作  
  安全策: `--namespace` 明示 or context に namespace 固定

- ミス: `kubectl delete -f .` を誤ディレクトリで実行  
  安全策: 実行前に `pwd` と対象ファイルを確認、`--dry-run=client` を使う

- ミス: Secret を YAML に平文記載して Git 管理  
  安全策: Secret 管理方式を導入（最低でも repo 分離・暗号化）

- ミス: `kubectl apply` を誤 context へ実行  
  安全策: 実行直前に `kubectl config current-context` を確認

- ミス: readiness 未設定で更新し、起動直後 Pod に流入  
  安全策: readinessProbe を設定し段階リリース

---

## 8) 面接っぽい確認問題（1問）

**Q.** `kubectl apply` と `kubectl create` の違いは？また、本番運用で `apply` が好まれる理由は？

**A.（要点）**
- `create` は新規作成向けで、既存リソースへの再実行に弱い
- `apply` は宣言的に「望ましい状態」へ収束させる
- GitOps/CI と相性が良く、差分管理・再現性・継続運用に向く

---

## 9) 次の一歩（公式ドキュメント中心）

- Kubernetes Documentation (Home)  
  https://kubernetes.io/docs/home/
- Overview / Concepts  
  https://kubernetes.io/docs/concepts/
- kubectl Cheat Sheet  
  https://kubernetes.io/docs/reference/kubectl/cheatsheet/
- Deployments  
  https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Services  
  https://kubernetes.io/docs/concepts/services-networking/service/
- Probes (liveness/readiness/startup)  
  https://kubernetes.io/docs/concepts/configuration/liveness-readiness-startup-probes/
- Secrets  
  https://kubernetes.io/docs/concepts/configuration/secret/
- Configure Access to Multiple Clusters  
  https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/

---

### 次号予告（学習アーク継続）
次は同じ流れ（Beginner→Middle→Advanced）で、
**「ConfigMap/Secret とアプリ設定注入、環境差分管理、事故らない設定変更」** を扱います。