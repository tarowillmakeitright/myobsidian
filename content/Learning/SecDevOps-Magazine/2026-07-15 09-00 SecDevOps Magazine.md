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
date: 2026-07-15
level: Advanced
---

# SecDevOps Magazine — 2026-07-15

[[Home]]

#security #devops #docker #kubernetes #terraform #linux #cloudsecurity #observability #daily

今日は **Learning Arc 1 / Advanced**。Beginner の IAM 設計、Middle の CI/CD 権限分離と Secret Injection を受けて、障害時に「観測し、安全に戻し、復旧を確認する」Kubernetes incident drill を行います。次号から新しい Beginner → Middle → Advanced アークへ戻ります。

## 1) Topic + Level

**Kubernetes Incident Drill: 失敗した Deployment の検知・rollback・recovery** — **Advanced**

### 前提知識

- Deployment / Pod / ReplicaSet / Service の役割を説明できる
- `kubectl get`, `describe`, `logs`, `rollout` を使った経験がある
- readiness probe と liveness probe の違いを理解している
- ローカルの検証用 Kubernetes（kind、minikube、Docker Desktop など）が使える
- 本番では変更承認、権限境界、監査ログを守ること

> この演習は自分が管理するローカル検証環境だけで行います。第三者のシステムや本番環境では実施しません。

## 2) Why it matters in real projects

安全な CI/CD でも、壊れた image、誤った環境変数、probe の設定ミスは起こります。重要なのは「障害をゼロにする」だけでなく、**blast radius を抑え、短時間で安全な状態へ戻し、戻ったことを証拠で確認する能力**です。

Kubernetes では新しい Pod が Ready にならない rollout が途中で止まる場合があります。慌てて Deployment を直接編集すると、原因と操作履歴が曖昧になります。実務では次の順序を型にします。

1. 検知: ユーザー影響と rollout 状態を把握する
2. 切り分け: event、Pod 状態、ログ、変更差分を見る
3. 封じ込め: 追加変更を止め、必要なら rollback する
4. 復旧確認: availability とエラー率を確認する
5. 学習: timeline、原因、再発防止策を残す

## 3) Core concepts

### Desired state と controller reconciliation

Deployment に宣言した desired state と実際の Pod 状態の差を controller が埋め続けます。インシデント対応では「Pod を手で直す」のではなく、**どの宣言が誤っているか**を調べます。Pod を削除しても誤った Deployment が残れば、同じ問題が再作成されます。

### rollout、revision、rollback

Deployment 更新時には ReplicaSet が作られ、revision history が保持されます。`kubectl rollout undo` は過去の Pod template へ戻す操作です。ただし ConfigMap、Secret、DB migration、外部 API の変更まで自動で元に戻すわけではありません。rollback の可否は、アプリとデータの互換性を含めて設計します。

### Readiness と availability

readiness probe が失敗した Pod は Service の endpoint から外れます。これは壊れた Pod に通信を流さない重要な防波堤です。一方、probe が浅すぎると依存先の故障を見逃し、厳しすぎると一時的な遅延で全 Pod が外れます。

### Observability の役割

- **Metrics:** Prometheus で error rate、latency、ready replicas、restart count を見る
- **Logs:** 失敗理由と request / trace ID を確認する
- **Traces:** OpenTelemetry で遅延や失敗がどの service にあるか追う
- **Dashboard:** Grafana で deploy annotation と症状の時刻を重ねる

rollback 後は「Pod が Running」だけでは不十分です。ユーザー視点の成功率、P95 latency、主要 dependency を確認します。

## 4) Hands-on mini lab（45〜60分）

### ゴール

正常な nginx Deployment に存在しない image tag を投入し、rollout failure を観測して、直前 revision へ rollback します。

### 0. 安全確認（5分）

現在の context がローカル検証クラスタであることを確認します。

```bash
kubectl config current-context
kubectl cluster-info
```

想定外の context なら中止してください。専用 namespace を作ります。

```bash
kubectl create namespace incident-lab
kubectl config set-context --current --namespace=incident-lab
```

### 1. 正常系を作る（10分）

```bash
kubectl create deployment web --image=nginx:1.27-alpine --replicas=3
kubectl rollout status deployment/web --timeout=120s
kubectl expose deployment web --port=80
kubectl get deployment,pod,service
kubectl get endpoints web
```

baseline を記録します。

```bash
kubectl get deployment web -o jsonpath='{.status.readyReplicas}{"/"}{.status.replicas}{" ready\n"}'
kubectl rollout history deployment/web
```

### 2. 意図的に rollout を壊す（5分）

```bash
kubectl set image deployment/web nginx=nginx:this-tag-does-not-exist --record
kubectl rollout status deployment/web --timeout=60s
```

timeout または失敗が今回の想定結果です。

### 3. 証拠を集めて切り分ける（15分）

```bash
kubectl get deployment,replicaset,pod -o wide
kubectl describe deployment web
kubectl get events --sort-by=.metadata.creationTimestamp
kubectl get pod
kubectl describe pod <ImagePullBackOffのPod名>
kubectl rollout history deployment/web
```

確認ポイント:

- 新 revision の Pod が `ErrImagePull` / `ImagePullBackOff` になっている
- 古い ReplicaSet が availability を保っている
- event に image pull failure が記録されている
- 原因は cluster 全体ではなく、直近の image 変更だと説明できる

### 4. rollback する（10分）

```bash
kubectl rollout undo deployment/web
kubectl rollout status deployment/web --timeout=120s
kubectl get deployment,replicaset,pod
kubectl get endpoints web
```

### 5. recovery を検証する（5分）

```bash
kubectl port-forward service/web 8080:80
```

別 terminal で確認します。

```bash
curl -fsS http://127.0.0.1:8080/ >/dev/null && echo recovery-ok
```

合格条件:

- desired replicas と ready replicas が一致
- Service に ready endpoint が存在
- HTTP request が成功
- `rollout history` で変更と復旧の流れを追える

最後に namespace を削除します。

```bash
kubectl config set-context --current --namespace=default
kubectl delete namespace incident-lab
```

### 振り返り（任意・5分）

短い incident note を書きます。

- Detection: 何が最初の signal だったか
- Impact: ユーザー影響はあったか
- Cause: どの変更が原因だったか
- Mitigation: 何を、なぜ戻したか
- Prevention: CI で image existence / signature をどう検証するか

## 5) Command cheatsheet

### Kubernetes

```bash
kubectl config current-context                   # 操作対象を確認
kubectl get deploy,rs,pod -o wide                # rollout 全体像
kubectl describe deployment <name>               # condition と event
kubectl get events --sort-by=.metadata.creationTimestamp
kubectl logs <pod> --previous                     # restart 前のログ
kubectl rollout status deployment/<name> --timeout=120s
kubectl rollout history deployment/<name>
kubectl rollout undo deployment/<name>
kubectl rollout undo deployment/<name> --to-revision=<N>
kubectl get endpoints <service>                  # ready endpoint
kubectl diff -f manifest.yaml                     # apply 前の差分
```

### Linux / HTTP 確認

```bash
date -Is                                         # timeline の時刻
curl -fsS -o /dev/null -w '%{http_code} %{time_total}\n' URL
journalctl --since '15 min ago'                  # node 側調査時のみ
```

### Docker / image 確認

```bash
docker manifest inspect nginx:1.27-alpine        # tag の存在確認
docker image inspect nginx:1.27-alpine           # local metadata
```

### Terraform（クラスタ/IAM変更時）

```bash
terraform fmt -check
terraform validate
terraform plan -out=tfplan
terraform show tfplan
```

インシデント中に原因不明の `terraform apply` を追加しないこと。まず差分、所有者、影響範囲を確認します。

## 6) Common mistakes and how to avoid them

### 1. context を確認せず演習する

本番 cluster で壊す事故につながります。最初に `kubectl config current-context` を確認し、専用 namespace と最小権限の identity を使います。

### 2. Running を recovery と判断する

Running は process が存在するだけです。Ready replicas、endpoint、HTTP 成功率、latency、主要 user journey を確認します。

### 3. 原因調査を優先しすぎて影響を長引かせる

証拠を最低限保存したら、既知の安全な revision に戻せる場合は mitigation を優先します。詳細調査は復旧後にもできます。

### 4. rollback がすべてを戻すと思う

Deployment の rollback は DB migration、Secret、ConfigMap、外部 feature flag を必ずしも戻しません。変更単位ごとの rollback matrix と互換性方針を事前に作ります。

### 5. `latest` tag を使う

再現性と監査性が落ちます。immutable tag または digest pinning を使い、CI で provenance / signature を検証します。

### 6. event と timeline を保存しない

Kubernetes event は永続的な監査記録ではありません。時刻、revision、実行コマンド、dashboard snapshot を incident record に残します。

### 7. 広すぎる権限で対応する

焦るほど cluster-admin に寄りがちです。read-only 調査権限と rollback 実行権限を分け、break-glass access は期限、承認、監査を付けます。

## 7) One interview-style question

**質問:** 新しい Kubernetes Deployment の rollout 後に error rate が急増しました。あなたはどの順番で調査し、いつ rollback を判断しますか？

**回答の観点:**

- deploy 時刻と metrics / logs / traces の相関を見る
- user impact、error budget、blast radius を評価する
- `rollout status`、Pod condition、event、直近差分を確認する
- 証拠を保存し、既知の安全な revision と rollback の副作用を確認する
- DB / schema / config の後方互換性を確認する
- rollback 後に readiness、endpoint、成功率、latency、主要 user journey を検証する
- timeline と再発防止策を post-incident review に残す

## 8) Next-step reading links

- [Kubernetes: Performing a Rolling Update](https://kubernetes.io/docs/tutorials/kubernetes-basics/update/update-intro/)
- [Kubernetes: Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [Kubernetes: Configure Liveness, Readiness and Startup Probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)
- [Kubernetes: Auditing](https://kubernetes.io/docs/tasks/debug/debug-cluster/audit/)
- [Prometheus: Kubernetes monitoring mixin](https://monitoring.mixins.dev/kubernetes/)
- [OpenTelemetry: Kubernetes Getting Started](https://opentelemetry.io/docs/platforms/kubernetes/getting-started/)
- [Grafana: Kubernetes Monitoring](https://grafana.com/docs/grafana-cloud/monitor-infrastructure/kubernetes-monitoring/)
- [AWS IAM: Security best practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [Google Cloud IAM: Best practices](https://cloud.google.com/iam/docs/using-iam-securely)

## 次のアークへ

今回で **Beginner（Cloud IAM）→ Middle（CI/CD Security）→ Advanced（Kubernetes incident drill）** が完了しました。次号は Beginner に戻り、Application Security の **Threat Modeling または Auth / Session Security** から新しいアークを始めるのが自然です。

今日の到達点は、`kubectl rollout undo` を覚えることではありません。**観測 → 判断 → 安全な変更 → 復旧検証 → 学習**を一つの手順として回せることです。
