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

# SecDevOps Magazine — 2026-06-27

## 1) Topic + Level
**Kubernetes Incident Drills Advanced / Rollout 失敗からの rollback・recovery を 60 分で再現する**  
**Level: Advanced**

**Prerequisites:**
- Beginner レベルの Kubernetes 基本要素（Pod / Deployment / Service / ConfigMap）を説明できる
- Middle レベルの `kubectl get/describe/logs` と rollout 操作を使える
- readinessProbe / livenessProbe / ReplicaSet の役割を理解している
- Linux 基本コマンド（`grep`, `watch`, `xargs`, `curl`）を使える

---

## 2) Why it matters in real projects
本番の Kubernetes で本当に怖いのは、クラスタが完全停止する瞬間よりも、**「一見動いて見えるのに、ユーザー影響が広がっていく事故」**です。

たとえば現場では、こんなことが起きます。

- 新しい image を deploy したら readinessProbe が通らず、Pod が増えない
- ConfigMap の値ミスで API が起動後すぐ crash する
- Secret 更新後に auth 接続だけ失敗し、401/500 が増える
- rollback したつもりなのに、古い ReplicaSet が十分に残っておらず復旧が遅れる
- HPA や resource limit が絡み、障害時にさらに Pod が不安定になる

ここで差が出るのは、**知識量**だけではありません。事故時に

1. どこを見るか  
2. 何を切り分けるか  
3. いつ rollback するか  
4. どこまで戻せば安全か

を短時間で判断できるかです。

Kubernetes incident drill は、防御的で合法な学習としてとても価値があります。攻撃手法を学ぶためではなく、**変更失敗・設定ミス・復旧手順の弱さ**に備える訓練だからです。AppSec の観点でも、障害時は認証・権限・secret・network policy の不備が露出しやすく、DevOps の観点でも rollback 設計の甘さがそのまま MTTR に出ます。

つまりこのテーマは、単なる K8s 操作練習ではなく、**「壊れたあとにどう安全に戻すか」を身体で覚えるための実務訓練**です。

---

## 3) Core concepts

### 3-1. Incident drill は「事故の演習化」
本番で初めて rollback 手順を考えるのは遅すぎます。drill の目的は、意図的に小さな失敗を再現し、

- 検知
- 切り分け
- 一時回避
- rollback
- 正常性確認
- 振り返り

を短いループで練習することです。

大事なのは「完璧な復旧」より、**再現可能で説明可能な復旧**です。

### 3-2. rollout failure の典型パターン
Kubernetes の障害は infra 全壊より、Deployment 更新失敗の形で現れることが多いです。代表例は以下です。

- **Bad image**: tag ミス、壊れた build、起動不能
- **Bad config**: ConfigMap / Secret の値が不正
- **Probe failure**: readiness/liveness が厳しすぎる、path が違う
- **Permission mismatch**: service account / RBAC / IAM role for service account のズレ
- **Dependency outage**: DB, Redis, auth provider への接続失敗

このとき重要なのは、現象をすぐ分類することです。

- Pod が起動しないのか
- 起動するが Ready にならないのか
- Ready だがアプリが壊れているのか
- 一部だけ壊れているのか

分類が速いほど、無駄な深掘りが減ります。

### 3-3. rollback は「最後の手段」ではなく「設計済みの操作」
未熟なチームほど rollback を特別イベントとして扱います。でも実務では、rollback は**異常時の標準操作**です。

意識したいポイント:
- `kubectl rollout undo` が使える状態か
- 直前の ReplicaSet が残っているか
- ConfigMap / Secret / image tag / Helm values など、何を戻すべきか分かれているか
- DB migration のように rollback 不可な変更が混ざっていないか

「Deployment だけ戻せば終わる」と思い込むのが典型的な事故です。

### 3-4. recovery は「戻したあとに本当に治ったか」を証明する工程
rollback 後に Pod が Running でも、それだけでは不十分です。recovery は次まで確認して初めて成立します。

- Ready replica が期待数まで戻ったか
- 5xx / timeout / auth failure が収束したか
- 主要エンドポイントが正常応答か
- queue backlog や retry storm が残っていないか
- 監視・alert が静まったか

つまり recovery は **Kubernetes の状態確認 + アプリ観測 + ユーザー影響確認** の 3 点セットです。

### 3-5. blast radius を小さくする考え方
優れた incident response は、原因究明の前に被害拡大を止めます。

たとえば:
- canary / progressive delivery を使う
- replica を保ったまま段階更新する
- `maxUnavailable` を小さくする
- readinessProbe を正しく設計する
- feature flag で機能だけ戻せるようにする

これはセキュリティでも同じです。誤った認証設定や secret rotation の失敗も、blast radius を小さくしていれば被害を抑えられます。

### 3-6. kubectl の観測レイヤを分けて使う
障害時はコマンドを闇雲に打つのではなく、レイヤ別に見ると速いです。

- **一覧確認**: `get`
- **詳細確認**: `describe`
- **アプリ出力**: `logs`
- **変更履歴**: `rollout history`
- **状態遷移監視**: `rollout status`, `watch`
- **イベント確認**: `get events`

この順番が頭に入っているだけで、かなり強いです。

### 3-7. AppSec 視点で見るべき incident signal
Kubernetes 障害は単なる可用性問題に見えて、実はセキュリティ設定の歪みが原因のことがあります。

見るべき例:
- Secret mount error
- ServiceAccount token / IAM role mismatch
- auth backend timeout
- mTLS / certificate expiry
- admission policy 拒否
- NetworkPolicy による通信遮断

“アプリが落ちた” と “認証/権限が壊れた” は分けて見る癖が重要です。

### 3-8. drill の成果は runbook に落として初めて残る
演習して終わり、が一番もったいないです。残すべきなのは次です。

- 最初に見た dashboard / command
- rollback 判断の基準
- 復旧確認の checklist
- 誤検知しやすいポイント
- 次回の改善案

学習は drill の最中より、**drill 後の言語化**で定着します。

---

## 4) Hands-on mini lab (30-60 min)
**テーマ: 壊れた Deployment を観測し、rollback で安全に戻す**

### ゴール
- 意図的に bad rollout を作る
- `kubectl get/describe/logs/rollout` で原因を切り分ける
- `kubectl rollout undo` で復旧する
- 復旧確認 checklist を自分で実行する

### 想定環境
ローカルで軽く回せる `kind` または `minikube` を想定します。ここでは `kind` 例で進めます。

### Step 0: クラスタ作成
```bash
kind create cluster --name drill-lab
kubectl cluster-info --context kind-drill-lab
```

### Step 1: 正常なアプリを deploy
```bash
kubectl create namespace drill
kubectl -n drill create deployment web --image=nginx:1.27
kubectl -n drill expose deployment web --port=80 --target-port=80 --type=ClusterIP
kubectl -n drill rollout status deployment/web
kubectl -n drill get pods -o wide
```

期待結果:
- Pod が Running / Ready になる
- Deployment が successfully rolled out になる

### Step 2: bad rollout を作る
存在しない image tag に更新して、典型的な更新失敗を再現します。

```bash
kubectl -n drill set image deployment/web nginx=nginx:does-not-exist
kubectl -n drill rollout status deployment/web --timeout=60s || true
kubectl -n drill get pods
kubectl -n drill describe pod -l app=web
kubectl -n drill get events --sort-by=.lastTimestamp | tail -n 20
```

見るポイント:
- `ImagePullBackOff` / `ErrImagePull`
- event に image pull 失敗が出ているか
- 古い Pod は残っているか

### Step 3: rollout history を確認
```bash
kubectl -n drill rollout history deployment/web
kubectl -n drill describe deployment web
```

確認ポイント:
- revision が残っているか
- 新旧 ReplicaSet の数
- desired / updated / available replica の差

### Step 4: rollback 実行
```bash
kubectl -n drill rollout undo deployment/web
kubectl -n drill rollout status deployment/web
kubectl -n drill get pods
```

### Step 5: recovery を確認
```bash
kubectl -n drill get deploy web
kubectl -n drill get rs
kubectl -n drill get endpoints web
kubectl -n drill port-forward svc/web 8080:80 >/tmp/drill-portforward.log 2>&1 &
sleep 3
curl -I http://127.0.0.1:8080
```

期待結果:
- available replicas が復帰
- Service endpoint が戻る
- `curl` が 200 系応答を返す

### Step 6: 余裕があれば “設定ミス” パターンも練習
次は image ではなく config 由来の障害を作ります。

1. `kubectl edit deployment web` で存在しない env を必須化する  
2. もしくは readinessProbe の path を壊す  
3. 同じ手順で `describe`, `logs`, `events`, `rollout undo` を実施

### ふりかえりメモ
30〜60 分の最後に、次を 5 行で書いてください。
- 最初に見たコマンド
- rollback 判断をした時点の根拠
- recovery 完了と判断した指標
- 無駄だった調査
- 本番 runbook に足したい一文

---

## 5) Command cheatsheet

### Kubernetes 基本観測
```bash
kubectl get pods -A
kubectl get deploy -A
kubectl get rs -A
kubectl get events -A --sort-by=.lastTimestamp
kubectl describe deployment <name>
kubectl describe pod <pod-name>
kubectl logs <pod-name>
kubectl logs -f <pod-name>
```

### Rollout / Rollback
```bash
kubectl rollout status deployment/<name>
kubectl rollout history deployment/<name>
kubectl rollout undo deployment/<name>
kubectl set image deployment/<name> <container>=<image>:<tag>
```

### Linux 補助
```bash
watch -n 2 'kubectl -n drill get pods,rs,deploy'
grep -i 'error\|fail\|backoff' app.log
xargs -I{} kubectl -n drill describe pod {}
curl -I http://127.0.0.1:8080
```

### kind / ローカル lab
```bash
kind create cluster --name drill-lab
kind delete cluster --name drill-lab
kubectl config get-contexts
kubectl config use-context kind-drill-lab
```

---

## 6) Common mistakes and how to avoid them

### ミス 1: Pod が Running だから直ったと思う
**回避法:** `READY`, available replicas, endpoint, `curl`, error rate まで確認する。Running は復旧完了の証拠ではありません。

### ミス 2: `logs` だけを見て Kubernetes 側の event を見ない
**回避法:** `describe` と `get events` をセットにする。image pull, probe failure, scheduling 問題は event に強く出ます。

### ミス 3: rollback すべきなのに原因究明を続けすぎる
**回避法:** ユーザー影響が広がっているなら、先に blast radius を止める。原因分析は復旧後でもできます。

### ミス 4: config / secret / image を一体化して考える
**回避法:** 何を戻すべき変更かを分解する。Deployment だけ戻しても Secret の不整合が残ることがあります。

### ミス 5: latest tag を使う
**回避法:** 明示的な version/tag を使う。再現不能な rollback は drill の価値を下げます。

### ミス 6: readinessProbe を雑に置く
**回避法:** “起動した” ではなく “受け付け可能” を判定する probe にする。誤った readiness は障害を隠します。

### ミス 7: 復旧確認が人によって違う
**回避法:** runbook に checklist を固定化する。誰が対応しても同じ品質に近づけます。

---

## 7) One interview-style question
**質問:**  
新しい Kubernetes Deployment を更新した直後から 5xx が増えました。`kubectl get pods` では一部 Pod は Running です。あなたなら最初の 10 分で何を確認し、どの条件で rollback を判断しますか？

**考えるポイント:**
- `get` / `describe` / `logs` / `events` の順番
- available replica と Ready 状態
- 直前 revision の有無
- Service endpoint / アプリ疎通確認
- “原因特定前に rollback すべき閾値” の定義

---

## 8) Next-step reading links
- Kubernetes Docs: Deployment  
  https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Kubernetes Docs: Debug Applications  
  https://kubernetes.io/docs/tasks/debug/debug-application/
- Kubernetes Docs: Probes  
  https://kubernetes.io/docs/concepts/configuration/liveness-readiness-startup-probes/
- Google SRE Book: Addressing Cascading Failures  
  https://sre.google/sre-book/addressing-cascading-failures/
- OWASP Kubernetes Top 10  
  https://owasp.org/www-project-kubernetes-top-ten/
- Grafana Kubernetes Monitoring overview  
  https://grafana.com/docs/grafana-cloud/monitor-infrastructure/kubernetes-monitoring/

---

## 今日のひとこと
事故対応が強い人は、特別な魔法を持っているわけではありません。  
**「見る順番」と「戻す基準」を先に持っている人**が強いです。  
今日はその型を 1 本、手で覚える日にしましょう。
