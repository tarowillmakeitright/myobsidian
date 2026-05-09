---
tags: [kubernetes, k8s, devops, learning, daily]
---

# 2026-05-09 Kubernetes Commands Magazine
[[Home]]

#kubernetes #k8s #devops #learning #daily

## 今号のテーマ
**ConfigMap / Secret を安全に使ってアプリ設定を管理する**

---

## Level 1 — Beginner
### 1) Topic + Level
**Topic:** `kubectl config` と `ConfigMap` の基礎
**Level:** Beginner

### 2) なぜ実アプリ開発で重要か
ローカル・検証・本番で設定値（APIエンドポイント、機能フラグ等）が変わるのは普通です。設定をイメージに焼き込むと再ビルドが必要になり、運用が重くなります。ConfigMapを使うと、アプリ本体と設定を分離でき、デプロイの再現性と変更速度が上がります。

### 3) コア概念（kubectl/Kubernetes）
- `kubectl config current-context`: 今どのクラスタに向けて操作しているか確認
- `ConfigMap`: **機密情報ではない**設定データを保存
- `envFrom` / `valueFrom`: Pod内に環境変数として注入
- `kubectl apply -f`: 宣言的に適用

### 4) アプリ開発時の使い方（kubernetes.io/docs準拠）
- 設定はマニフェストまたはKustomize/Helm valuesで管理
- コンテナイメージは環境非依存にし、環境差分はConfigMapで吸収
- 変更追跡のためGitOps的にYAMLをバージョン管理

### 5) 30〜60分ミニラボ
1. 作業前チェック（誤爆防止）
   - `kubectl config current-context`
   - `kubectl get ns`
2. `ConfigMap` 作成
3. `Deployment` 作成（`envFrom` でConfigMapを読む）
4. Pod内で環境変数確認
5. ConfigMap更新 → `rollout restart` で反映

**サンプル:**
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: default
data:
  APP_ENV: "dev"
  LOG_LEVEL: "info"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - name: web
        image: nginx:1.27
        envFrom:
        - configMapRef:
            name: app-config
```

### 6) Command Cheatsheet
```bash
kubectl config current-context
kubectl apply -f cm-deploy.yaml
kubectl get configmap
kubectl describe configmap app-config
kubectl get pods -l app=web
kubectl exec -it deploy/web -- env | grep -E 'APP_ENV|LOG_LEVEL'
kubectl rollout restart deploy/web
kubectl rollout status deploy/web
```

### 7) よくあるミス & 安全策
- ミス: 本番contextのままapply
  - 安全策: **毎回** `kubectl config current-context` を先に実行
- ミス: Secretにすべき値をConfigMapに置く
  - 安全策: パスワード/トークンはSecretへ
- ミス: 一括applyの対象が広すぎる（`-f .`）
  - 安全策: 適用ディレクトリを限定、`kubectl diff -f ...` を先に確認

### 8) 面接風質問
「ConfigMapとSecretの違いを説明し、運用での使い分けを具体例つきで話してください。」

### 9) 次の一歩（公式）
- https://kubernetes.io/docs/concepts/configuration/configmap/
- https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/

---

## Level 2 — Middle
### 1) Topic + Level
**Topic:** Secretの安全な利用とローテーション
**Level:** Middle
**前提:** ConfigMap/Deploymentの基本、`kubectl apply/get/describe` が使えること

### 2) なぜ実アプリ開発で重要か
DB接続情報やAPIキー管理を誤ると即インシデントになります。Secret運用は機能要件ではなく、サービス信頼性の必須要件です。

### 3) コア概念
- `Secret`: 機密情報の格納（※Base64は暗号化ではない）
- `env.valueFrom.secretKeyRef` / volume mount
- `Encryption at Rest`（クラスタ側設定）
- RBACでアクセス最小化

### 4) アプリ開発時の使い方
- SecretはGit平文コミットしない
- CI/CDで注入、またはExternal Secrets等を利用
- 権限はnamespace・ServiceAccount単位で最小化

### 5) 30〜60分ミニラボ
1. ダミー資格情報でSecret作成
2. Podへ環境変数注入
3. SA/RBACで不要アクセスを拒否
4. Secret更新後に再デプロイ手順を確認

### 6) Command Cheatsheet
```bash
kubectl create secret generic db-secret \
  --from-literal=username=appuser \
  --from-literal=password='change-me'

kubectl get secret db-secret -o yaml
kubectl auth can-i get secrets --as=system:serviceaccount:default:default
kubectl describe pod <pod-name>
```

### 7) よくあるミス & 安全策
- ミス: Secret YAMLをそのままGitへ
  - 安全策: Sealed Secrets / External Secrets / CI注入
- ミス: Podログに機密値を出力
  - 安全策: アプリ側でマスキング、デバッグログ制御
- ミス: 全員がSecretを読めるRBAC
  - 安全策: `least privilege` 徹底

### 8) 面接風質問
「Kubernetes SecretはBase64ですが、なぜそれだけでは不十分ですか？実運用での補強策を説明してください。」

### 9) 次の一歩（公式）
- https://kubernetes.io/docs/concepts/configuration/secret/
- https://kubernetes.io/docs/concepts/security/secrets-good-practices/
- https://kubernetes.io/docs/reference/access-authn-authz/rbac/

---

## Level 3 — Advanced
### 1) Topic + Level
**Topic:** 安全なデプロイ運用（Context管理、段階適用、ロールバック）
**Level:** Advanced
**前提:** Deployment/Secret/RBACの基礎、障害対応の基本フローを理解していること

### 2) なぜ実アプリ開発で重要か
多くの障害は「アプリのバグ」だけでなく「運用コマンド事故」で起きます。誤ったクラスタ・namespaceへのapply/deleteを防ぐ設計が、可用性と信頼を守ります。

### 3) コア概念
- `kubectl diff`: 適用前差分確認
- `rollout history/undo`: 安全な切り戻し
- `--namespace` 明示、`--context` 明示
- `PodDisruptionBudget` / readinessProbe による無停止寄り運用

### 4) アプリ開発時の使い方
- 本番は「apply前 diff必須」をチームルール化
- 変更は小さく分割し、カナリア/段階展開
- readiness/liveness/startup probeを定義し、壊れたPodをトラフィックから外す

### 5) 30〜60分ミニラボ
1. Deploymentをv1→v2に更新
2. `kubectl diff` で差分確認後 `apply`
3. 疑似障害（不正imageタグ）を入れて `rollout status` 監視
4. `rollout undo` で復旧
5. 事故防止用に `--context` 指定運用を練習

### 6) Command Cheatsheet
```bash
kubectl --context=<dev-context> --namespace=default diff -f deploy.yaml
kubectl --context=<dev-context> --namespace=default apply -f deploy.yaml
kubectl rollout status deploy/web -n default
kubectl rollout history deploy/web -n default
kubectl rollout undo deploy/web -n default
kubectl get events -n default --sort-by=.metadata.creationTimestamp
```

### 7) よくあるミス & 安全策
- ミス: `kubectl delete -f .` を誤ディレクトリで実行
  - 安全策: 実行前に`pwd`確認、対象を明示、可能ならレビュー
- ミス: context未確認で本番へ反映
  - 安全策: シェルプロンプトにcontext表示、実行前チェックリスト化
- ミス: `apply` スコープが広すぎる
  - 安全策: サービス単位ディレクトリ + `kubectl diff` 必須

> ⚠️ **破壊的コマンド注意**
> `delete`, `replace --force`, 広範囲 `apply -f .` はクラスタ影響が大きいです。`current-context` / `namespace` / 対象ファイルを必ず3点確認してから実行してください。

### 8) 面接風質問
「本番クラスタで誤applyを防ぐために、技術面と運用面でどんな多層防御を設計しますか？」

### 9) 次の一歩（公式）
- https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- https://kubernetes.io/docs/tasks/manage-kubernetes-objects/declarative-config/
- https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/
- https://kubernetes.io/docs/concepts/workloads/pods/disruptions/

---

## 付録: 今日の実務ワンポイント
- `kubectl` 実行前3点確認: **context / namespace / 対象ファイル**
- Secretは「見えにくくする」だけでなく「漏れにくくする」設計へ（RBAC・ログ・CI運用）
- 小さい変更を速く安全に回すのが、結果的に一番速い
