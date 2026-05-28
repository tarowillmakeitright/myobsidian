---
tags:
  - kubernetes
  - k8s
  - devops
  - learning
  - daily
---

[[Home]]

# Kubernetes Commands Magazine — 2026-05-28 09:25

## 今号のテーマ
**Deployment と Service を安全に扱い、アプリを段階的に公開する**

---

## Beginner（初級）
### 1) Topic + Level
**Topic:** `kubectl get/describe/logs` で状況確認し、Deployment/Pod の基本を理解する

### 2) なぜ実務で重要か
本番障害の初動は「正しい観測」が9割です。Pod が落ちる原因（イメージ取得失敗、環境変数不足、Readiness 未達など）を最短で切り分ける力は、開発スピードと障害復旧時間（MTTR）に直結します。

### 3) コア概念（kubectl / Kubernetes）
- **Pod**: コンテナ実行の最小単位（基本は直接運用せず、上位リソースで管理）
- **Deployment**: Pod の宣言的管理（レプリカ数、ローリングアップデート）
- **Namespace**: 環境・チーム単位の論理分離
- よく使う観測コマンド:
  - `kubectl get`（一覧）
  - `kubectl describe`（イベント含む詳細）
  - `kubectl logs`（アプリログ）

### 4) アプリ開発時の使い方（ベストプラクティス）
- まず `kubectl config current-context` と `-n <namespace>` を徹底し、対象クラスタ/名前空間を誤らない
- デプロイ前後で `kubectl get deploy,po -n <ns>` を比較し、意図通り更新されたかを確認
- 問題発生時は `describe -> events -> logs` の順で切り分け

### 5) 30〜60分ミニラボ（初級）
**ゴール:** NGINX Deployment を作って状態確認できるようになる

1. 作業用 Namespace 作成
```bash
kubectl create namespace mag-lab
```
2. Deployment 作成
```bash
kubectl create deployment web --image=nginx:1.27 -n mag-lab
kubectl scale deployment web --replicas=2 -n mag-lab
```
3. 状態確認
```bash
kubectl get deploy,rs,po -n mag-lab
kubectl describe deployment web -n mag-lab
kubectl logs deploy/web -n mag-lab --tail=50
```
4. （任意）イメージをわざとミスして挙動観察
```bash
kubectl set image deployment/web nginx=nginx:does-not-exist -n mag-lab
kubectl get po -n mag-lab
kubectl describe po -n mag-lab
```
5. 正常イメージへ戻す
```bash
kubectl set image deployment/web nginx=nginx:1.27 -n mag-lab
kubectl rollout status deployment/web -n mag-lab
```

### 6) Command Cheatsheet（初級）
```bash
kubectl config current-context
kubectl get ns
kubectl get po -n mag-lab -o wide
kubectl describe po <pod-name> -n mag-lab
kubectl logs <pod-name> -n mag-lab --previous
kubectl rollout status deployment/web -n mag-lab
```

### 7) よくあるミス & 安全策
- ミス: 本番 context のまま操作する
  - 安全策: 実行前に毎回 `kubectl config current-context` を確認
- ミス: `default` namespace に混在
  - 安全策: チーム/環境ごとに namespace 分離
- ミス: 失敗時に logs だけ見る
  - 安全策: `describe` の Events を必ず確認

### 8) 面接っぽい質問
**Q:** `kubectl get pods` で `CrashLoopBackOff` のとき、最初に何を確認しますか？順序も説明してください。

### 9) 次の一歩（公式）
- Kubernetes Concepts: <https://kubernetes.io/docs/concepts/>
- Deployments: <https://kubernetes.io/docs/concepts/workloads/controllers/deployment/>
- kubectl Cheat Sheet: <https://kubernetes.io/docs/reference/kubectl/cheatsheet/>

---

## Middle（中級）
**Prerequisites:** Pod/Deployment の基本、`get/describe/logs` が使えること

### 1) Topic + Level
**Topic:** Service とラベル設計でアプリ通信を安定化する

### 2) なぜ実務で重要か
Pod は作り直されるため IP が変わります。Service で抽象化しないと、アプリ間通信が壊れやすくなります。マイクロサービス運用の基礎です。

### 3) コア概念
- **Label / Selector**: Service がどの Pod を振り分けるか決める
- **Service (ClusterIP)**: クラスタ内向け安定エンドポイント
- **Port/targetPort**: Service 側ポートと Pod 側ポートの対応

### 4) アプリ開発時の使い方
- `app`, `component`, `version` などラベルを最初に設計
- 依存先は Pod IP ではなく Service DNS 名で参照
- 本番では `readinessProbe` を使い、準備完了 Pod のみにトラフィックを流す

### 5) 30〜60分ミニラボ（中級）
**ゴール:** Deployment + Service を YAML で管理し、疎通確認する

1. マニフェスト作成（`k8s/web.yaml`）
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
  namespace: mag-lab
spec:
  replicas: 2
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
        - name: nginx
          image: nginx:1.27
          ports:
            - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: web
  namespace: mag-lab
spec:
  selector:
    app: web
  ports:
    - port: 80
      targetPort: 80
```
2. 適用
```bash
kubectl apply -f k8s/web.yaml
kubectl get svc,ep -n mag-lab
```
3. 疎通確認（ポートフォワード）
```bash
kubectl port-forward svc/web 8080:80 -n mag-lab
# 別ターミナルで curl http://127.0.0.1:8080
```
4. ラベル不一致を試す（学習用）
- Deployment の `app: web` を `app: web2` に変更して apply
- `Endpoints` が空になることを確認

### 6) Command Cheatsheet（中級）
```bash
kubectl get svc -n mag-lab
kubectl describe svc web -n mag-lab
kubectl get endpoints web -n mag-lab
kubectl get po -n mag-lab --show-labels
kubectl port-forward svc/web 8080:80 -n mag-lab
```

### 7) よくあるミス & 安全策
- ミス: Service selector と Pod label が不一致
  - 安全策: `kubectl get po --show-labels` と `describe svc` をセットで確認
- ミス: 直接 Pod IP に依存
  - 安全策: Service DNS を利用
- ミス: 秘密情報を環境変数直書き
  - 安全策: Secret を利用し、Git に平文コミットしない

### 8) 面接っぽい質問
**Q:** Service があるのに通信できないとき、どの Kubernetes リソースをどの順で確認しますか？

### 9) 次の一歩（公式）
- Service: <https://kubernetes.io/docs/concepts/services-networking/service/>
- DNS for Services and Pods: <https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/>
- Probes: <https://kubernetes.io/docs/concepts/configuration/liveness-readiness-startup-probes/>

---

## Advanced（上級）
**Prerequisites:** Deployment/Service の運用経験、YAML 管理、基本的な障害対応

### 1) Topic + Level
**Topic:** ローリングアップデートを安全に実施し、必要なら即ロールバックする

### 2) なぜ実務で重要か
本番更新では「止めない」「すぐ戻せる」が最重要です。Deployment の rollout 戦略と履歴管理を理解すると、リリース事故の影響を最小化できます。

### 3) コア概念
- **RollingUpdate**: 段階的に新旧 Pod を入れ替える
- **maxUnavailable / maxSurge**: 可用性と更新速度のトレードオフ調整
- **rollout history / undo**: 失敗時の復旧手段
- **readinessProbe**: 未準備 Pod にトラフィックを流さない安全装置

### 4) アプリ開発時の使い方
- CI/CD で `kubectl apply` 前に静的チェック（lint/validate）を実施
- デプロイ後は `rollout status` を必ず監視
- 問題があれば `rollout undo` で即復旧
- 大規模環境では canary / blue-green も検討

### 5) 30〜60分ミニラボ（上級）
**ゴール:** 安全な更新→失敗注入→ロールバックを体験

1. 事前確認
```bash
kubectl get deploy web -n mag-lab -o yaml > /tmp/web-backup.yaml
kubectl rollout history deployment/web -n mag-lab
```
2. 正常更新
```bash
kubectl set image deployment/web nginx=nginx:1.27.1 -n mag-lab
kubectl rollout status deployment/web -n mag-lab
```
3. 失敗更新（意図的）
```bash
kubectl set image deployment/web nginx=nginx:notfound -n mag-lab
kubectl rollout status deployment/web -n mag-lab
kubectl describe deployment/web -n mag-lab
```
4. ロールバック
```bash
kubectl rollout undo deployment/web -n mag-lab
kubectl rollout status deployment/web -n mag-lab
kubectl rollout history deployment/web -n mag-lab
```

### 6) Command Cheatsheet（上級）
```bash
kubectl set image deployment/web nginx=nginx:1.27.1 -n mag-lab
kubectl rollout status deployment/web -n mag-lab
kubectl rollout history deployment/web -n mag-lab
kubectl rollout undo deployment/web -n mag-lab
kubectl diff -f k8s/web.yaml
kubectl apply --server-side -f k8s/web.yaml
```

### 7) よくあるミス & 安全策
- ミス: `kubectl apply -f .` で想定外ファイルまで適用
  - 安全策: 対象ファイル明示 + `kubectl diff` で事前確認
- ミス: `kubectl delete` のスコープ誤り
  - 安全策: **実行前に context / namespace / 対象名を3点確認**
- ミス: Secret を manifest に平文埋め込み
  - 安全策: Secret 管理（外部 Secret Manager 連携含む）と RBAC 最小権限

> ⚠️ **破壊的コマンド注意**
> `delete`, `replace --force`, 広い `apply` は事故リスクが高いです。必ず以下を実施:
> 1. `kubectl config current-context` 確認
> 2. `-n <namespace>` 明示
> 3. `kubectl diff` / `--dry-run=server` で事前確認

### 8) 面接っぽい質問
**Q:** ローリングアップデート中に一部 Pod が Ready にならない場合、可用性を保ちながらどう判断・対応しますか？

### 9) 次の一歩（公式）
- Rolling Updates: <https://kubernetes.io/docs/tutorials/kubernetes-basics/update/update-intro/>
- Deployment strategy details: <https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#strategy>
- Secrets good practices: <https://kubernetes.io/docs/concepts/security/secrets-good-practices/>
- kubectl apply: <https://kubernetes.io/docs/reference/kubectl/generated/kubectl_apply/>

---

## 今日のまとめ
- 初級: 観測の基本（get/describe/logs）
- 中級: Service とラベルで安定通信
- 上級: 安全な rollout と即時 rollback

次号はこの流れを引き継ぎ、**ConfigMap/Secret とアプリ設定の分離**を扱うと実務接続がさらに強くなります。