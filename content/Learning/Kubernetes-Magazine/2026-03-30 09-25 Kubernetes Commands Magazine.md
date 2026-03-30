# Kubernetes Commands Magazine — 2026-03-30 (09:25)
#kubernetes #k8s #devops #learning #daily
[[Home]]

---

## 今日の学習アーク（Beginner → Middle → Advanced）
**テーマ:** Deployment のローリングアップデートと安全な運用

---

## 1) トピック + レベル

### Beginner
**トピック:** `Deployment` と `Service` の基本操作（作成・確認・更新）

### Middle
**トピック:** ローリングアップデート / ロールバック / ヘルスチェック
**前提知識:**
- Pod / Deployment / Service の基本
- `kubectl get/describe/logs` が使える

### Advanced
**トピック:** 本番運用を意識した安全なデプロイ（進行監視・失敗時復旧・段階的適用）
**前提知識:**
- RollingUpdate 戦略（`maxSurge`, `maxUnavailable`）
- readiness/liveness probe の意味
- Namespace と Context の使い分け

---

## 2) なぜ実アプリ開発で重要か
- アプリ更新時に**無停止/低停止**でリリースできる。
- 障害時に素早く `rollout undo` で切り戻しできる。
- readiness/liveness を正しく設定すると、壊れた Pod をトラフィック経路から外せる。
- CI/CD で `kubectl apply` を使う際、適用範囲・クラスタ誤りを防ぐ設計が事故を減らす。

---

## 3) コア概念（kubectl / Kubernetes）
- **Deployment**: Pod の望ましい状態を宣言し、更新・復旧を管理。
- **Service (ClusterIP)**: Pod 群への安定したアクセス入口。
- **RollingUpdate**: Pod を少しずつ入れ替え、可用性を保つ。
- **readinessProbe**: 「リクエストを受けてよいか」の判定。
- **livenessProbe**: 「プロセスが生きているか」の判定。
- **kubectl rollout status/history/undo**: 更新追跡・履歴確認・切り戻し。
- **Context / Namespace**: 操作対象クラスタと論理分離領域。誤操作防止の最重要ポイント。

---

## 4) アプリ開発での実践利用（kubernetes.io/docs ベストプラクティス準拠）
- マニフェストは宣言的に管理し、`kubectl apply -f` で適用。
- 本番では readiness を先に整備し、壊れたリビジョンの流入を防ぐ。
- Secret は `Secret` リソースや外部シークレット管理を利用し、**平文を Git に置かない**。
- `kubectl config current-context` / `-n <namespace>` を毎回確認し、誤クラスタ適用を防止。
- `kubectl diff -f` で事前差分確認してから apply。

---

## 5) 30〜60分ミニラボ
**目標:** 安全なローリングアップデートとロールバックを体験する

### 所要時間
45分目安

### 手順
1. **Namespace 作成**
```bash
kubectl create namespace mag-lab
```

2. **初期デプロイ（nginx 1.25）**
```bash
kubectl -n mag-lab create deployment web --image=nginx:1.25
kubectl -n mag-lab expose deployment web --port=80 --target-port=80
kubectl -n mag-lab get all
```

3. **更新戦略を確認**
```bash
kubectl -n mag-lab get deploy web -o yaml | grep -A5 strategy:
```

4. **ローリングアップデート（nginx 1.27）**
```bash
kubectl -n mag-lab set image deployment/web nginx=nginx:1.27
kubectl -n mag-lab rollout status deployment/web
kubectl -n mag-lab rollout history deployment/web
```

5. **意図的に失敗する更新（存在しないタグ）**
```bash
kubectl -n mag-lab set image deployment/web nginx=nginx:9.99
kubectl -n mag-lab rollout status deployment/web --timeout=90s
kubectl -n mag-lab get pods
kubectl -n mag-lab describe pod <失敗Pod名>
```

6. **ロールバック**
```bash
kubectl -n mag-lab rollout undo deployment/web
kubectl -n mag-lab rollout status deployment/web
```

7. **後片付け（※削除コマンド注意）**
```bash
# 破壊的操作: 対象 namespace を必ず確認
kubectl config current-context
kubectl delete namespace mag-lab
```

### 学習チェック
- `rollout status` と `rollout history` を説明できるか
- 失敗更新から `undo` で戻せるか
- どの段階で Service が利用可能状態を保つか理解できたか

---

## 6) コマンドチートシート
```bash
# 対象確認（超重要）
kubectl config current-context
kubectl config get-contexts
kubectl get ns

# 基本観測
kubectl -n <ns> get deploy,po,svc
kubectl -n <ns> describe deploy <name>
kubectl -n <ns> logs -l app=<label> --tail=100

# デプロイ更新
kubectl -n <ns> set image deployment/<name> <container>=<image:tag>
kubectl -n <ns> rollout status deployment/<name>
kubectl -n <ns> rollout history deployment/<name>
kubectl -n <ns> rollout undo deployment/<name>

# 安全確認
kubectl -n <ns> diff -f <manifest.yaml>
kubectl -n <ns> apply -f <manifest.yaml>
```

---

## 7) よくあるミス & 安全策
- **ミス:** `default` namespace に誤適用
  - **安全策:** `-n` を明示、もしくは context の default namespace を事前設定

- **ミス:** 本番クラスタに test 用 manifest を apply
  - **安全策:** apply 前に `kubectl config current-context` を声出し確認

- **ミス:** Secret を Deployment の env に平文直書き
  - **安全策:** `Secret` リソース参照、Git には暗号化/外部管理を利用

- **ミス:** `kubectl delete -f .` の実行範囲を把握していない
  - **安全策:** 破壊的コマンド前に対象ディレクトリと context を再確認。必要なら `kubectl diff` を先に実行

- **ミス:** probe 未設定で障害 Pod にトラフィックが流れる
  - **安全策:** readiness/liveness を実装し、段階的に厳格化

---

## 8) 面接風クエスチョン（1問）
**質問:**
「RollingUpdate 中に一部 Pod が起動失敗した場合、サービス断を避けながら原因調査と復旧を行う手順を説明してください。`kubectl` コマンドも含めて答えてください。」

---

## 9) 次の一歩（公式ドキュメント中心）
- Deployment 概要: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Rolling updates: https://kubernetes.io/docs/tutorials/kubernetes-basics/update/update-intro/
- Probes (liveness/readiness/startup): https://kubernetes.io/docs/concepts/configuration/liveness-readiness-startup-probes/
- kubectl チートシート: https://kubernetes.io/docs/reference/kubectl/cheatsheet/
- Secret の扱い: https://kubernetes.io/docs/concepts/configuration/secret/
- Configuration Best Practices: https://kubernetes.io/docs/concepts/configuration/overview/

---

### 明日の予告
**予定アーク:** ConfigMap/Secret/環境変数注入の設計（安全な設定管理）
