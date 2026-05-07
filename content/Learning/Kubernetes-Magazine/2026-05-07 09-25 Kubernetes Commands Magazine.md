---
tags: [kubernetes, k8s, devops, learning, daily]
---

# 2026-05-07 Kubernetes Commands Magazine
[[Home]]

#kubernetes #k8s #devops #learning #daily

## 学習アーク1

### 1) Topic + Level
**Topic:** `kubectl get/describe/logs`で「動いているアプリの状態を安全に観測する」
**Level:** **Beginner（初級）**

### 2) なぜ実アプリ開発で重要か
アプリの不具合対応は、最初に「今どうなっているか」を正確に把握できるかで速度が決まります。  
`kubectl get` / `describe` / `logs` は、**デプロイ失敗・CrashLoopBackOff・疎通不良**を切り分ける最短ルートです。

### 3) コア概念（kubectl / Kubernetes）
- **Pod**: コンテナ実行単位。まずはここを見る。
- **Deployment**: Podの望ましい状態を維持・更新する宣言的リソース。
- **Service**: Pod群への安定した到達口。
- **Namespace**: 環境/チーム分離の基本。
- **観測系基本コマンド**
  - `kubectl get`: 一覧と状態確認
  - `kubectl describe`: イベント含む詳細確認
  - `kubectl logs`: 実行ログ確認

### 4) アプリ開発時の使い方（kubernetes.io/docs準拠の実践）
- まず `kubectl config current-context` で対象クラスタを確認（誤操作防止）。
- `-n <namespace>` を常に明示して、意図しない環境参照を避ける。
- 問題調査は以下順序が実務向け：
  1. `get` で全体状態
  2. `describe` でイベント原因
  3. `logs` でアプリ視点の原因
- 本番運用では `kubectl delete` 前に対象確認を徹底（誤削除防止）。

### 5) 30-60分ミニラボ
**目標:** Nginx Deploymentを作り、状態確認と障害の初動調査を体験する。  
**前提:** `kubectl` が使えるクラスタ（minikube/kind可）、default以外に作業用Namespaceを作成できる権限

1. 作業Namespace作成
```bash
kubectl create namespace lab-observe
```

2. Deployment作成
```bash
kubectl -n lab-observe create deployment web --image=nginx:1.27
kubectl -n lab-observe scale deployment web --replicas=2
```

3. 状態確認
```bash
kubectl -n lab-observe get deploy,rs,pod,svc -o wide
kubectl -n lab-observe describe deployment web
```

4. ログ確認
```bash
POD=$(kubectl -n lab-observe get pod -l app=web -o jsonpath='{.items[0].metadata.name}')
kubectl -n lab-observe logs "$POD" --tail=50
```

5. （任意）Service作成と確認
```bash
kubectl -n lab-observe expose deployment web --port=80 --target-port=80 --type=ClusterIP
kubectl -n lab-observe get svc web
```

6. 後片付け（**削除前に対象を再確認**）
```bash
kubectl get ns
kubectl -n lab-observe get all
kubectl delete namespace lab-observe
```

### 6) コマンドチートシート
```bash
# コンテキスト確認（超重要）
kubectl config current-context

# Namespace指定で一覧
kubectl -n <ns> get pods
kubectl -n <ns> get deploy,svc

# 詳細調査
kubectl -n <ns> describe pod <pod>
kubectl -n <ns> logs <pod> --tail=100
kubectl -n <ns> logs -f <pod>

# ラベルで絞る
kubectl -n <ns> get pod -l app=<name>
```

### 7) よくあるミス & 安全策
- ミス: context未確認で本番クラスタを触る  
  - 安全策: 作業前に必ず `kubectl config current-context`
- ミス: Namespace未指定で別環境を見てしまう  
  - 安全策: 常に `-n` をつける
- ミス: `kubectl delete` を広いスコープで実行  
  - 安全策: `get` で対象確認→必要なら `--dry-run=client -o yaml` で確認
- ミス: Secretをmanifestに平文記載  
  - 安全策: 平文直書き禁止。Secret管理は暗号化/外部Secret管理を検討

### 8) 面接っぽい一問
`kubectl get pods` で `CrashLoopBackOff` を見つけたとき、あなたなら最初の5分でどの順序で何を確認しますか？（コマンド込みで説明）

### 9) 次のステップ（公式ドキュメント中心）
- Kubernetes Concepts:  
  https://kubernetes.io/docs/concepts/
- kubectl Overview:  
  https://kubernetes.io/docs/reference/kubectl/
- Debug Running Pods:  
  https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/
- Deployments:  
  https://kubernetes.io/docs/concepts/workloads/controllers/deployment/

---

## 学習アーク2

### 1) Topic + Level
**Topic:** RollingUpdateと`kubectl rollout`で安全にリリースする
**Level:** **Middle（中級）**
**Prerequisites:**
- Pod/Deployment/Serviceの基本理解
- `kubectl get/describe/logs` で基本調査ができる

### 2) なぜ実アプリ開発で重要か
機能追加より難しいのは「壊さずに出す」こと。  
RollingUpdateを理解すると、**無停止に近い更新・即時ロールバック・変更追跡**が可能になり、障害時の復旧速度が上がります。

### 3) コア概念
- **RollingUpdate**: Podを段階的に入れ替える更新戦略
- **maxUnavailable / maxSurge**: 可用性と更新速度のトレードオフを決める
- **rollout status/history/undo**: 配布監視・履歴確認・巻き戻し

### 4) アプリ開発時の使い方
- CI/CDから `kubectl apply` する前に対象context/namespaceを厳密確認。
- イメージタグは`latest`固定を避け、追跡可能なタグを使う。
- リリース時は `rollout status` 完了まで監視し、異常時は `undo`。

### 5) 30-60分ミニラボ
1. Deployment作成
```bash
kubectl create ns lab-rollout
kubectl -n lab-rollout create deployment api --image=nginx:1.27
```
2. 更新戦略確認
```bash
kubectl -n lab-rollout get deploy api -o yaml | grep -A8 strategy:
```
3. イメージ更新（ローリング）
```bash
kubectl -n lab-rollout set image deployment/api nginx=nginx:1.27.1
kubectl -n lab-rollout rollout status deployment/api
```
4. 履歴・ロールバック
```bash
kubectl -n lab-rollout rollout history deployment/api
kubectl -n lab-rollout rollout undo deployment/api
kubectl -n lab-rollout rollout status deployment/api
```
5. 後片付け
```bash
kubectl delete ns lab-rollout
```

### 6) コマンドチートシート
```bash
kubectl -n <ns> set image deployment/<name> <container>=<image:tag>
kubectl -n <ns> rollout status deployment/<name>
kubectl -n <ns> rollout history deployment/<name>
kubectl -n <ns> rollout undo deployment/<name>
```

### 7) よくあるミス & 安全策
- ミス: `latest` タグで何が動いているか不明
  - 安全策: バージョン固定タグ運用
- ミス: rollout監視せずデプロイ完了扱い
  - 安全策: `rollout status` をパイプラインに必須化
- ミス: 一括applyで想定外リソース更新
  - 安全策: ディレクトリ適用時は対象ファイルとnamespaceを再確認

### 8) 面接っぽい一問
RollingUpdateで `maxUnavailable=0` を設定する利点と欠点を説明してください。

### 9) 次のステップ（公式）
- Performing a Rolling Update:  
  https://kubernetes.io/docs/tutorials/kubernetes-basics/update/update-intro/
- Deployment Strategy:  
  https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#strategy

---

## 学習アーク3

### 1) Topic + Level
**Topic:** ConfigMap/SecretとProbe設計で「壊れにくい」アプリ運用
**Level:** **Advanced（上級）**
**Prerequisites:**
- Deployment/rollout運用経験
- readiness/livenessの基本理解
- アプリ設定を環境変数/ファイル注入で扱った経験

### 2) なぜ実アプリ開発で重要か
本番障害は「コード」だけでなく「設定」「起動判定」でも起きます。  
ConfigMap/Secret分離とProbe設計を適切に行うと、**誤設定による停止・起動ループ・秘密情報露出**を大きく減らせます。

### 3) コア概念
- **ConfigMap**: 非機密設定
- **Secret**: 機密情報（ただし平文管理は避ける）
- **readinessProbe**: トラフィックを受ける準備判定
- **livenessProbe**: プロセス生存判定（再起動トリガ）
- **startupProbe**: 起動が遅いアプリ向けの保護

### 4) アプリ開発時の使い方
- 機密情報はmanifest直書きしない（Gitに残さない）。
- Secretは最小権限で参照し、ログ出力に混ざらない設計にする。
- Probeは実装実態に合わせる（過剰に厳しい閾値は障害誘発）。

### 5) 30-60分ミニラボ
1. NamespaceとConfigMap作成
```bash
kubectl create ns lab-config
kubectl -n lab-config create configmap app-config --from-literal=APP_MODE=prod
```
2. Secret作成（デモ値。実運用は外部Secret管理推奨）
```bash
kubectl -n lab-config create secret generic app-secret --from-literal=API_KEY='dummy-change-me'
```
3. Deployment作成（環境変数注入）
```bash
kubectl -n lab-config create deployment app --image=nginx:1.27
kubectl -n lab-config set env deployment/app --from=configmap/app-config
kubectl -n lab-config set env deployment/app --from=secret/app-secret
```
4. 設定反映と確認
```bash
kubectl -n lab-config rollout status deployment/app
kubectl -n lab-config describe deployment app
```
5. 後片付け
```bash
kubectl delete ns lab-config
```

### 6) コマンドチートシート
```bash
kubectl -n <ns> create configmap <name> --from-literal=KEY=VALUE
kubectl -n <ns> create secret generic <name> --from-literal=KEY=VALUE
kubectl -n <ns> set env deployment/<name> --from=configmap/<cm>
kubectl -n <ns> set env deployment/<name> --from=secret/<secret>
```

### 7) よくあるミス & 安全策
- ミス: SecretをYAMLに平文でコミット
  - 安全策: 直書き禁止。暗号化（Sealed Secrets等）または外部Secret Manager
- ミス: Probe閾値が厳しすぎて再起動ループ
  - 安全策: 起動時間を計測し `startupProbe` を活用
- ミス: `kubectl apply -f .` の誤爆
  - 安全策: 対象ディレクトリを限定し、context/namespaceを再確認

### 8) 面接っぽい一問
readinessProbeとlivenessProbeを同じエンドポイントにした場合のリスクは何ですか？運用でどう分けますか？

### 9) 次のステップ（公式）
- ConfigMap:  
  https://kubernetes.io/docs/concepts/configuration/configmap/
- Secret:  
  https://kubernetes.io/docs/concepts/configuration/secret/
- Probes:  
  https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/
- Security Best Practices:  
  https://kubernetes.io/docs/concepts/security/
