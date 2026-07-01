# 2026-07-01 09-00 SecDevOps Magazine
[[Home]]

#security #devops #docker #kubernetes #terraform #linux #cloudsecurity #observability #daily

---

## 今日の学習アーク
- **Arc 1 / Advanced**
- 今週の流れ: **Linux command mastery → Observability → Kubernetes incident drills**
- 6/29 の Beginner で Linux の観察力を作り、6/30 の Middle で Prometheus / Grafana / OpenTelemetry による可視化を学びました。
- 今日はその続きとして、**Kubernetes incident drills（failure / rollback / recovery）** を扱います。実務で重要なのは「壊さないこと」だけでなく、**壊れたときに安全に戻せること**です。

### Advanced の前提知識
- `kubectl get`, `describe`, `logs`, `rollout status` の基本が分かる
- metrics / logs / traces の役割分担を説明できる
- Deployment と Service の違いを理解している
- rollout 後に error rate / latency / readiness を見る意味が分かる

---

## 1) Topic + Level
**Kubernetes Incident Drills / failure・rollback・recovery を安全に練習する**

**Level: Advanced**

---

## 2) Why it matters in real projects
本番運用では、障害は「起きるかどうか」ではなく、**起きたときにどう振る舞うか**が差になります。

よくある現場の失敗はこうです。
- 新しいイメージを deploy したら readiness probe が通らず、Service が不安定になる
- config change の影響で 500 が増えたのに、切り戻し判断が遅れる
- Pod は Running なのに、実際のユーザー影響は継続している
- rollback はしたが、secret / env / migration の整合性確認が足りず「戻したのに直っていない」状態になる
- incident 中に担当者ごとの見方がバラバラで、復旧より先に混乱が増える

Kubernetes incident drills を普段から練習しておくと、次の力が付きます。
- **failure detection**: 何を見て異常と判断するか
- **rollback execution**: どのコマンドで、どこまで安全に戻すか
- **recovery validation**: 戻したあとに何を確認して「直った」と言えるか
- **incident communication**: チームで同じ指標・同じ言葉を使えるか

AppSec の文脈でも重要です。たとえば認証・セッション・権限周りの変更で障害が出た場合、素早い rollback は可用性だけでなく、**過剰権限・認可漏れ・想定外挙動の拡大防止**にもつながります。

つまり incident drills は、ただの運用練習ではなく、**信頼性とセキュリティを守る筋トレ**です。

---

## 3) Core concepts

### A. Failure / Rollback / Recovery は別フェーズ
この 3 つを混ぜると判断が鈍ります。

- **Failure**: 何が壊れたかを把握する段階
- **Rollback**: 被害を止めるために前の安定状態へ戻す段階
- **Recovery**: 本当に正常化したか確認する段階

特に現場では、rollback 実行で安心して recovery 確認を雑にしがちです。ですが実際には、
- Pod が立った
- rollout が完了した
- しかしユーザーエラーは継続している

ということが普通にあります。

### B. 「Kubernetes が健康」≠「アプリが健康」
`kubectl get pods` が全部 Running でも安心できません。

見るべき健康状態は少なくとも 3 層あります。
1. **Kubernetes health**: Pod, ReplicaSet, readiness, events
2. **Application health**: HTTP status, auth flow, DB connection, queue backlog
3. **User impact**: login できるか、API が成功するか、遅延が許容範囲か

Advanced では、この 3 層を切り分けて見る習慣が大事です。

### C. Rollout failure の典型パターン
よくある壊れ方を先に知っておくと、観察が速くなります。

- **Bad image**: 起動に失敗する、CrashLoopBackOff
- **Bad config**: env / ConfigMap / Secret の値ミス
- **Probe mismatch**: readiness/liveness の設定が厳しすぎる
- **Permission issue**: ServiceAccount / RBAC / IAM 連携不足
- **Dependency issue**: DB, cache, external API へつながらない
- **Migration issue**: アプリは起動するが schema 整合性で失敗する

### D. Rollback の判断基準を先に持つ
incident 中に「どうする？」と相談し始めると遅いです。

判断材料の例:
- error rate が deploy 前より明確に上昇している
- p95/p99 latency が急増している
- readiness が一定時間回復しない
- 認証成功率が閾値を割っている
- deploy と障害の開始時刻が一致している

重要なのは、**“まだ調査中”でも止血のために戻す価値があるか** を考えることです。

### E. `kubectl rollout undo` は魔法ではない
Rollback は便利ですが、前提があります。

- 以前の ReplicaSet が残っているか
- DB migration が後方互換か
- Secret / ConfigMap の変更が deploy と独立していないか
- external dependency の変更が戻せるか

つまり rollback できても、**状態依存の変更**は自動では戻りません。ここを理解していないと「戻したのに直らない」事故になります。

### F. Recovery validation は “元に戻った証拠集め”
Recovery では次を確認します。
- rollout status が正常
- readiness が安定
- error rate が基準値に戻る
- latency が回復する
- 代表的な user flow（例: login → API call）が成功する
- logs に新しい異常が出ていない

できれば、**technical recovery** と **user recovery** を分けて考えると良いです。

### G. Security 観点での incident drill
障害対応は可用性だけでなく、防御にも関係します。

たとえば確認対象は以下です。
- 401 / 403 が急増していないか
- permission denied が想定外に増えていないか
- session/token validation error が出ていないか
- rollback 後に過剰権限の暫定設定が残っていないか
- debug log に secret が漏れていないか

復旧を急ぐと、つい「一時的に全部許可」が出やすいので要注意です。**復旧の速さより、危ない近道を選ばないこと**のほうが長期的には大事です。

### H. Drill は “筋書きのある練習” にする
学習目的なら、毎回ランダム障害よりも筋書きがあったほうが伸びます。

今回の drill の筋書き:
1. 正常版を deploy
2. 意図的に壊れた版へ更新
3. 異常を観察
4. rollback
5. recovery を検証
6. 何を見て、何を見落としたかを書く

これで incident 対応が「なんとなくの勘」から「再現できる手順」になります。

---

## 4) Hands-on mini lab (30-60 min)
### ゴール
- Deployment の更新失敗を観察する
- `kubectl rollout` 系コマンドで rollback する
- rollback 後の recovery validation を行う
- incident 時に見る順番を固める

### 前提
- ローカル Kubernetes（`minikube` / `kind` / `k3d` など）を使える
- `kubectl` が使える
- 学習用ローカル環境のみ。本番クラスタでは実施しない

### Step 1: 作業用 namespace を作る
```bash
kubectl create namespace drill-lab
```

### Step 2: 正常な Deployment を apply
`good-deploy.yaml`:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
  namespace: drill-lab
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
        - name: web
          image: nginx:1.27
          ports:
            - containerPort: 80
          readinessProbe:
            httpGet:
              path: /
              port: 80
            initialDelaySeconds: 3
            periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: web
  namespace: drill-lab
spec:
  selector:
    app: web
  ports:
    - port: 80
      targetPort: 80
```

```bash
kubectl apply -f good-deploy.yaml
kubectl rollout status deployment/web -n drill-lab
kubectl get pods -n drill-lab -o wide
kubectl get svc -n drill-lab
```

### Step 3: 正常状態を観察
```bash
kubectl describe deployment web -n drill-lab
kubectl get rs -n drill-lab
kubectl logs -n drill-lab deploy/web --tail=20
```

メモすること:
- Pod 数
- Ready 状態
- ReplicaSet 名
- Event に異常がないこと

### Step 4: 壊れた更新を入れる
今回は **存在しない image tag** を使って failure を起こします。

```bash
kubectl set image deployment/web web=nginx:does-not-exist -n drill-lab
kubectl rollout status deployment/web -n drill-lab --timeout=60s
```

### Step 5: failure を観察
```bash
kubectl get pods -n drill-lab
kubectl describe deployment web -n drill-lab
kubectl get rs -n drill-lab
kubectl describe pod -n drill-lab <failing-pod-name>
kubectl get events -n drill-lab --sort-by=.lastTimestamp
```

見るポイント:
- 新しい ReplicaSet が作られているか
- ImagePullBackOff / ErrImagePull が出ているか
- 古い Pod が残っていて Service がまだ生きているか
- rollout が完了しない理由を 1 文で説明できるか

### Step 6: rollback する
```bash
kubectl rollout undo deployment/web -n drill-lab
kubectl rollout status deployment/web -n drill-lab
```

### Step 7: recovery validation をする
```bash
kubectl get pods -n drill-lab
kubectl describe deployment web -n drill-lab
kubectl get rs -n drill-lab
kubectl logs -n drill-lab deploy/web --tail=20
```

確認すること:
- Ready 2/2 に戻ったか
- 古い安定 ReplicaSet に戻ったか
- Event に新しい異常が出ていないか
- 「戻ったあと正常が継続している」と言える根拠があるか

### Step 8: 余裕があれば probe failure も試す
image ではなく readiness を壊す練習も有効です。

```bash
kubectl patch deployment web -n drill-lab \
  --type='json' \
  -p='[{"op":"replace","path":"/spec/template/spec/containers/0/readinessProbe/httpGet/path","value":"/healthz-does-not-exist"}]'

kubectl rollout status deployment/web -n drill-lab --timeout=60s
kubectl get pods -n drill-lab
kubectl rollout undo deployment/web -n drill-lab
```

### Step 9: ふりかえり
次の問いに短く答えてください。
1. どの時点で rollback を決断できたか
2. `get pods` だけでは足りなかった理由は何か
3. Recovery を証明するには何が必要だったか
4. 本番なら metrics / traces をどこに足したいか

### 後片付け
```bash
kubectl delete namespace drill-lab
```

---

## 5) Command cheatsheet
### Linux
```bash
watch -n 2 kubectl get pods -n drill-lab
grep -R "readinessProbe\|livenessProbe\|image:" .
date
printf 'incident note: rollback executed\n'
```

### Kubernetes
```bash
kubectl create namespace drill-lab
kubectl apply -f good-deploy.yaml
kubectl rollout status deployment/web -n drill-lab
kubectl rollout history deployment/web -n drill-lab
kubectl rollout undo deployment/web -n drill-lab
kubectl set image deployment/web web=nginx:does-not-exist -n drill-lab
kubectl describe deployment web -n drill-lab
kubectl describe pod <pod-name> -n drill-lab
kubectl get rs -n drill-lab
kubectl get events -n drill-lab --sort-by=.lastTimestamp
kubectl logs -n drill-lab deploy/web --tail=50
kubectl delete namespace drill-lab
```

### Docker（イメージ理解の補助）
```bash
docker pull nginx:1.27
docker images | grep nginx
docker inspect nginx:1.27 | head
```

### Terraform / IaC（incident 前の予防レビュー）
```bash
terraform fmt -recursive
terraform validate
grep -R "readinessProbe\|livenessProbe\|resources\|serviceAccount" .
grep -R "kubernetes_deployment\|helm_release" .
```

---

## 6) Common mistakes and how to avoid them
### ミス1: `kubectl get pods` だけで判断する
**問題:** Running / Pending だけでは user impact が分かりません。
**回避:** `describe`, `events`, `rollout status`, logs を必ず組み合わせる。

### ミス2: rollback を遅らせすぎる
**問題:** 原因究明にこだわって被害時間を伸ばします。
**回避:** 原因調査と止血を分ける。閾値を超えたら戻す。

### ミス3: rollback 後に安心して確認を止める
**問題:** technical rollback は成功でも user recovery は未確認かもしれません。
**回避:** readiness・error rate・主要フロー成功を確認する。

### ミス4: ConfigMap / Secret / migration の影響を忘れる
**問題:** image だけ戻しても整合性が壊れたままです。
**回避:** “何を変更したか” を deploy artifact 以外も含めて確認する。

### ミス5: probe をよく分からないまま厳しく設定する
**問題:** アプリは正常化途中でも不健康扱いされ続けます。
**回避:** 起動時間・依存先接続時間に合わせて `initialDelaySeconds` や `timeoutSeconds` を調整する。

### ミス6: 復旧のために危険な権限緩和をする
**問題:** 一時対応が新しい security incident を生みます。
**回避:** `cluster-admin` 付与や `0.0.0.0/0` 開放のような雑な近道を避ける。

### ミス7: incident メモを残さない
**問題:** 次回また同じ混乱を繰り返します。
**回避:** 発生時刻、観測、判断、rollback 実行時刻、回復確認時刻を 1 行ずつでも書く。

---

## 7) One interview-style question
**質問:**
Kubernetes 上の API で新しい Deployment 後に readiness failure と 5xx 増加が発生しました。あなたはどのシグナルを見て rollback を決め、rollback 後に何をもって recovery 完了と判断しますか？

**考える観点:**
- rollout status と ReplicaSet の状態
- readiness / logs / events のどれが決定打になるか
- error rate / latency / auth failure の確認
- DB migration や ConfigMap 差分をどう扱うか
- 「戻しただけ」で終わらせないための確認手順

---

## 8) Next-step reading links
- Kubernetes Deployments: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Kubernetes Probes (liveness / readiness / startup): https://kubernetes.io/docs/concepts/configuration/liveness-readiness-startup-probes/
- kubectl rollout reference: https://kubernetes.io/docs/reference/kubectl/generated/kubectl_rollout/
- Kubernetes Debug Running Pods: https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/
- Kubernetes RBAC reference: https://kubernetes.io/docs/reference/access-authn-authz/rbac/
- OWASP Incident Response Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/Incident_Response_Cheat_Sheet.html
- OWASP Kubernetes Security Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/Kubernetes_Security_Cheat_Sheet.html
- Google SRE Workbook - Incident Response: https://sre.google/workbook/incident-response/
- Prometheus Alerting overview: https://prometheus.io/docs/alerting/latest/overview/
- OpenTelemetry documentation: https://opentelemetry.io/docs/

---

## 次号予告
**Beginner 予告:** Cloud Security / AWS・GCP の IAM と permission design を、最小権限の考え方からやり直します。

### 次号のつながり
- 今日の incident drill は「壊れたときに戻す」力でした。
- 次号はその前段として、**そもそも危ない権限設計で壊れないようにする**学習に進みます。
- これで Arc 2 を **Beginner → Middle → Advanced** で再スタートできます。
