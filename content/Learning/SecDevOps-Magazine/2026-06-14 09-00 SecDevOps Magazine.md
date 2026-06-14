---
tags:
  - security
  - devops
  - docker
  - kubernetes
  - terraform
  - linux
  - cloudsecurity
  - observability
  - daily
---

[[Home]]

# SecDevOps Magazine — 2026-06-14

今日のテーマは **Kubernetes incident drills**。学習アーク上は **Middle** です。  
**前提知識:** Kubernetes 基本オブジェクト（Pod / Deployment / Service）、`kubectl` の基本操作、RollingUpdate の概念、コンテナログ確認。

## 1) Topic + Level
**Kubernetes incident drills: Failure / Rollback / Recovery + Level: Middle**

## 2) Why it matters in real projects
本番の Kubernetes 障害は、たいてい「壊れた」こと自体よりも、**どれだけ早く異常を特定し、影響範囲を絞り、復旧できるか** が勝負です。  
デプロイ直後に 500 エラーが増える、ConfigMap の変更でアプリが起動しない、readiness probe の設定ミスで Service 配下に正常 Pod がいなくなる——こうした事故は珍しくありません。

Kubernetes incident drill を日常的に回しておくと、以下の力がつきます。

- 障害時に最初に見るべき場所を迷わない
- Rollout / Rollback の流れを身体で覚えられる
- 「復旧したつもり」で終わらず、再発防止の観点を持てる
- SRE / DevOps / AppSec の境界をまたいで実務対応できる

特にセキュリティ面でも、誤設定・権限変更・秘密情報の差し替えミスは、**インシデント対応そのもの** です。Kubernetes を安全に運用するには、平時の構築だけでなく、障害対応の筋力が必要です。

## 3) Core concepts

### A. Failure の種類を分けて考える
Kubernetes 障害はざっくり 3 層に分けると見通しが良くなります。

1. **Workload レイヤー**
   - コンテナ起動失敗
   - CrashLoopBackOff
   - readiness / liveness probe 失敗
   - イメージタグ誤り

2. **Configuration レイヤー**
   - ConfigMap / Secret の値ミス
   - 環境変数の未設定
   - Resource requests/limits の不備
   - RBAC や ServiceAccount の権限不足

3. **Platform / Delivery レイヤー**
   - Deployment の不適切な更新戦略
   - Node 側のリソース不足
   - NetworkPolicy による通信遮断
   - CI/CD から壊れた manifest が投入された

障害調査では、「アプリが悪い」「クラスタが悪い」と曖昧にせず、**どのレイヤーの問題か** を先に切るのが重要です。

### B. Rollout と Rollback
`Deployment` は宣言的に更新され、ReplicaSet を切り替えながら rollout します。  
もし更新後に問題が出たら、`kubectl rollout undo deployment/<name>` で直前のリビジョンへ戻せます。

重要なのは、Rollback は万能薬ではないことです。

- DB schema 変更が後方互換でないと戻せない
- Secret/ConfigMap が壊れているとアプリだけ戻しても直らない
- 外部依存（IAM 権限や DNS）が原因なら manifest rollback では不十分

つまり Rollback は **高速な一次対応** には強いですが、**真因分析** は別途必要です。

### C. Recovery は「Pod が起動した」で終わらない
Recovery の定義を低くすると危険です。復旧判定では最低でも以下を見ます。

- Pod が Running / Ready か
- エラーログが消えたか
- Service 経由で応答するか
- 直近のデプロイ差分は何か
- 再発防止策を記録したか

**見かけの復旧** と **運用上の復旧** は別です。ユーザー影響がなくなって初めて復旧です。

### D. Observability との接続
障害対応力は `kubectl get pods` だけでは伸びません。  
Prometheus / Grafana / OpenTelemetry のような observability 基盤があると、

- デプロイ直後の error rate 上昇
- レイテンシ悪化
- 再起動回数の増加
- 特定サービスだけの異常

を時系列で追えます。  
Kubernetes incident drill は、**操作手順の練習** だけでなく、**メトリクスとログを根拠に判断する習慣** を作る練習でもあります。

### E. Security 観点で見る drill
障害 drill は防御学習としても有効です。たとえば:

- Secret を誤って差し替えた場合の影響確認
- RBAC を締めすぎてアプリが API を読めなくなった場合の切り分け
- NetworkPolicy による通信断を正常系と比較して確認

これは攻撃練習ではなく、**防御的・合法的な設定検証** です。壊れ方を知ると、安全な変更管理が上手くなります。

## 4) Hands-on mini lab (30-60 min)
**目的:** 壊れた Deployment を観測し、原因を切り分け、Rollback で復旧する。

### ラボ前提
- ローカル Kubernetes（minikube, kind, k3d のどれか）
- `kubectl` が使える
- `nginx` イメージを pull できる

### Step 1: 正常な Deployment を作る
```bash
kubectl create namespace drill
kubectl -n drill create deployment web --image=nginx:1.27
kubectl -n drill expose deployment web --port=80 --target-port=80
kubectl -n drill rollout status deployment/web
kubectl -n drill get pods,svc
```

確認ポイント:
- Pod が Ready になっているか
- Deployment の rollout が完了しているか

### Step 2: 故障を注入する（存在しないイメージタグ）
```bash
kubectl -n drill set image deployment/web nginx=nginx:does-not-exist
kubectl -n drill rollout status deployment/web --timeout=60s
```

期待される状態:
- rollout が止まる
- 新しい Pod が `ImagePullBackOff` または `ErrImagePull`

### Step 3: 観測する
```bash
kubectl -n drill get pods
kubectl -n drill describe pod <pod-name>
kubectl -n drill get events --sort-by=.lastTimestamp
kubectl -n drill rollout history deployment/web
```

見るポイント:
- `describe` に image pull error が出るか
- Events で何が起きているか
- 直前の revision は何か

### Step 4: Rollback する
```bash
kubectl -n drill rollout undo deployment/web
kubectl -n drill rollout status deployment/web
kubectl -n drill get pods
```

### Step 5: Recovery を検証する
```bash
kubectl -n drill port-forward svc/web 8080:80
curl -I http://127.0.0.1:8080
```

HTTP 200 系レスポンスが返れば一次復旧確認。  
余裕があれば次も試してください。

### 追加ドリル A: readiness probe ミス
Deployment を export して、存在しない path に readiness probe を向ける。  
結果として Pod は Running でも Ready にならず、Service が流せない状態を観察する。

### 追加ドリル B: Secret 差し替え事故
アプリ用 Secret をわざと壊した値にして再起動し、ログとイベントで切り分ける。  
ポイントは「Pod が生きていてもアプリが壊れている」ケースを区別すること。

## 5) Command cheatsheet

### Kubernetes 基本観測
```bash
kubectl get pods -A
kubectl get deploy -A
kubectl get events --sort-by=.lastTimestamp
kubectl describe pod <pod>
kubectl logs <pod>
```

### Rollout / Rollback
```bash
kubectl rollout status deployment/<name>
kubectl rollout history deployment/<name>
kubectl rollout undo deployment/<name>
kubectl rollout undo deployment/<name> --to-revision=<n>
```

### 変更確認
```bash
kubectl diff -f manifest.yaml
kubectl apply -f manifest.yaml
kubectl set image deployment/<name> <container>=<image>:<tag>
```

### Linux 補助コマンド
```bash
watch -n 2 kubectl -n drill get pods
curl -I http://127.0.0.1:8080
jq . file.json
grep -R "image:" .
```

### Docker 補助確認
```bash
docker pull nginx:1.27
docker pull nginx:does-not-exist
```

## 6) Common mistakes and how to avoid them

### ミス1: Pod が Running だから正常だと思い込む
**回避:** `READY` 列、probe 状態、Service 経由の疎通まで確認する。

### ミス2: いきなり再デプロイして証拠を消す
**回避:** まず `describe`, `logs`, `events`, `rollout history` を取る。初動で証拠保全の癖をつける。

### ミス3: Rollback すれば必ず直ると思う
**回避:** ConfigMap / Secret / DB / IAM / 外部サービスなど、Deployment 外の変更有無を確認する。

### ミス4: 手順だけ覚えて、判断基準がない
**回避:** 「何を見て異常と判断したか」を一行で記録する。例: `ImagePullBackOff + event 上の manifest unknown`。

### ミス5: 本番で初めて drill 的なことをやる
**回避:** ローカルクラスタや staging で、週1回でもよいので小さな障害演習を回す。

## 7) One interview-style question
**質問:**
Kubernetes の Deployment 更新後に一部 Pod が `Running` だがユーザーから 503 が報告されています。あなたならどの順番で確認し、どの条件なら rollback を判断しますか？

**考える観点:**
- Ready / NotReady の判定
- Service / Endpoint との関係
- readiness probe の失敗有無
- 直近変更が image, config, secret, RBAC のどれか
- rollback で戻る範囲と戻らない範囲

## 8) Next-step reading links
- Kubernetes Deployment: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Kubernetes Debug Running Pods: https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/
- Kubernetes Probes: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/
- Kubernetes RBAC: https://kubernetes.io/docs/reference/access-authn-authz/rbac/
- Prometheus Documentation: https://prometheus.io/docs/introduction/overview/
- Grafana Documentation: https://grafana.com/docs/
- OpenTelemetry Documentation: https://opentelemetry.io/docs/

---

## 学習メモ
- 今日の位置づけ: **Middle arc**
- 次に相性が良いテーマ:
  - Advanced: CI/CD security と progressive delivery rollback 設計
  - Beginner: Observability 基礎（metrics / logs / traces の違い）
  - Middle: Cloud Security の IAM permission design

一歩ずつで十分です。  
Kubernetes は「全部知ってから触る」より、**小さく壊して、小さく直す** を繰り返した人が強くなります。