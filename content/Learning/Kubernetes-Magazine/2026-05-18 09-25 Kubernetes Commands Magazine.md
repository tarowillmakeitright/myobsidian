---
tags: [kubernetes, k8s, devops, learning, daily]
---

# Daily Kubernetes Commands Magazine - 2026-05-18

#kubernetes #k8s #devops #learning #daily  
[[Home]]

---

## 1) Topic + Level

### 🟢 Beginner
**テーマ:** `kubectl get / describe / logs` でアプリ状態を最短で把握する

### 🟡 Middle
**テーマ:** Label/Selector と Namespace を使って安全に対象を絞り込む
**前提知識:**
- Beginner の内容（`get/describe/logs`）
- Pod / Deployment の基本概念

### 🔴 Advanced
**テーマ:** Rollout 管理（`set image`, `rollout status/history/undo`）による安全な段階的リリース
**前提知識:**
- Middle の内容（Label/Selector, Namespace）
- Deployment の更新戦略（RollingUpdate）の基本

---

## 2) Why it matters for real app development

- 実運用では「壊れたかどうか」より先に、**どこが壊れたかを素早く特定**する力が重要。  
- Namespace/Label を使わない運用は、誤操作（別環境への apply/delete）につながりやすい。  
- Rollout を理解すると、デプロイ失敗時に**即時ロールバック**でき、障害時間を短縮できる。  

---

## 3) Core kubectl / Kubernetes concept explanations

### Beginner: 観測系3点セット
- `kubectl get` : リソース一覧を俯瞰（現在の状態）
- `kubectl describe` : 個別リソースの詳細（イベント、条件、失敗理由）
- `kubectl logs` : コンテナの実行ログ（アプリエラーの一次情報）

### Middle: 対象を絞る設計
- **Namespace**: 環境・チーム単位の論理分離（例: dev/stg/prod）
- **Label/Selector**: `app=web`, `tier=api` などで対象を機械的に抽出
- `-n` / `-l` を使うことで、事故を減らしつつ運用速度を上げる

### Advanced: Rollout 安全運用
- `kubectl set image` : Deployment のイメージ更新
- `kubectl rollout status` : 更新完了まで監視
- `kubectl rollout history` : リビジョン確認
- `kubectl rollout undo` : 問題時に前バージョンへ戻す

---

## 4) Building apps with Kubernetes (best-practice aligned)

kubernetes.io/docs の実務に沿うと、以下が基本フローです。

1. **宣言的設定（YAML）をGit管理**し、再現可能にする  
2. アプリを Deployment で管理し、Service で到達性を定義  
3. Namespace と Label を設計段階から決める  
4. 更新は rollout で観測し、異常時は即 rollback  
5. Secret は Secret リソースや外部Secret管理を使い、**平文直書きしない**

実装中は、まず `get/describe/logs` で状況把握 → selector で影響範囲特定 → rollout 制御、の順が最も安全です。

---

## 5) 30-60 minute hands-on mini lab

**目標:** 安全なデプロイ更新とロールバックを体験する（約45分）

### 事前準備（5分）
```bash
kubectl config current-context
kubectl config get-contexts
```
- いま触るクラスタが想定どおりか確認
- 不安なら作業前に `--context` を明示する

### Step 1: Namespace 作成（5分）
```bash
kubectl create namespace magazine-lab
kubectl config set-context --current --namespace=magazine-lab
```

### Step 2: Deployment + Service 作成（10分）
```bash
kubectl create deployment web --image=nginx:1.25
kubectl expose deployment web --port=80 --target-port=80 --type=ClusterIP
kubectl get all
```

### Step 3: 観測（10分）
```bash
kubectl get pods -l app=web
kubectl describe deployment web
kubectl logs deployment/web --tail=50
```

### Step 4: イメージ更新（10分）
```bash
kubectl set image deployment/web nginx=nginx:1.26
kubectl rollout status deployment/web
kubectl rollout history deployment/web
```

### Step 5: ロールバック演習（5分）
```bash
kubectl set image deployment/web nginx=nginx:badtag
kubectl rollout status deployment/web
kubectl rollout undo deployment/web
kubectl rollout status deployment/web
```

### 片付け（任意）
```bash
# 破壊的操作: 対象namespaceを必ず再確認してから実行
kubectl get ns
kubectl delete namespace magazine-lab
```

---

## 6) Command cheatsheet

```bash
# 文脈確認
kubectl config current-context
kubectl config get-contexts

# 一覧・詳細・ログ
kubectl get pods -n <ns>
kubectl describe pod <pod-name> -n <ns>
kubectl logs <pod-name> -n <ns> --tail=100

# ラベルで絞り込み
kubectl get pods -n <ns> -l app=web

# デプロイ更新と監視
kubectl set image deployment/<name> <container>=<image>:<tag> -n <ns>
kubectl rollout status deployment/<name> -n <ns>
kubectl rollout history deployment/<name> -n <ns>
kubectl rollout undo deployment/<name> -n <ns>
```

---

## 7) Common mistakes and safe practices

### よくあるミス
1. **context/namespace未確認で実行**して本番を更新
2. `kubectl delete` を広いスコープで実行
3. `kubectl apply -f .` で意図しないYAMLまで適用
4. Secret値を manifest や Git に平文保存

### 安全策
- 実行前に毎回 `kubectl config current-context` と `-n <ns>` を確認
- 破壊的コマンド前に対象を先に `get` して目視確認
- `apply` はディレクトリ丸ごとより、ファイル/フォルダを明示
- Secret は Kubernetes Secret + 適切なアクセス制御（RBAC）を利用
- 可能なら `--dry-run=client -o yaml` で事前確認

⚠️ **注意:** `delete namespace`, `delete -A`, `apply -f .` は特に事故率が高い。実行前に context・namespace・対象ファイルを必ず再確認。

---

## 8) Interview-style question

**質問:**  
「本番障害時、`kubectl get pods` で一部 Pod が `CrashLoopBackOff` になっています。あなたなら最初の5分でどの順に何を確認しますか？また、デプロイ直後なら rollback 判断をどう行いますか？」

---

## 9) Next-step resources (official docs first)

- Kubernetes Documentation (Home): https://kubernetes.io/docs/home/
- kubectl Overview: https://kubernetes.io/docs/reference/kubectl/
- Deployments: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Labels and Selectors: https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/
- Namespaces: https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/
- Configuration Best Practices: https://kubernetes.io/docs/concepts/configuration/overview/
- Secrets: https://kubernetes.io/docs/concepts/configuration/secret/
- RBAC: https://kubernetes.io/docs/reference/access-authn-authz/rbac/

---

次号予告（難易度アーク継続）:  
Beginner: ConfigMap/Secret の使い分け → Middle: probes 設計（liveness/readiness/startup） → Advanced: HPA とリソース設計の実践
