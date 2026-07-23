---
type: weekly-magazine
series: kubernetes
difficulty: Intermediate
focus: Topology Spread Constraintsで障害ドメイン偏在を防ぐ
week: 2026-W30
prerequisites:
  - Pod・Deployment・ReplicaSet・ラベルセレクターの基礎
  - kube-schedulerとrequestsの基本
  - kubectl apply・get・describe・scaleの操作
estimated_minutes: 150
---

[[Home]]

# Weekly Kubernetes Magazine — Topology Spread Constraintsで障害ドメイン偏在を防ぐ

#kubernetes #k8s #weekly #deep-dive

> [!warning] 実行前の安全確認
> この号にはNodeへのラベル付与・削除、`apply`、`scale`、Namespaceの`delete`が含まれる。共有・本番クラスタでは実行しない。各変更前に `kubectl config current-context` と対象Namespaceを確認し、`k8s-spread-lab` 以外のアプリを操作しない。Nodeラベル変更はクラスタ全体へ影響し得るため、専用kindクラスタだけで行う。例にSecretは含めず、実在のトークン、パスワード、証明書を貼らない。

## 1. Focus・難易度・前提・環境・到達点

**Focus:** `topologySpreadConstraints` を使い、同一DeploymentのPodをNodeやAvailability Zone（AZ）へ測定可能な偏りで配置する。単に「散らす」のではなく、障害ドメイン数が不足した際に新規Podを止める設計まで扱う。

**難易度シグナル:** Intermediate（学習順序を強制する参加条件ではなく目安）

### 必要な知識・ツール・環境

- 既習概念: Pod / Deployment / ReplicaSet、Pod template、ラベルとselector、schedulerのfilterとscore、CPU/メモリrequests
- 必須ツール: Docker互換ランタイム、`kind`、`kubectl`、YAMLエディタ
- 推奨Kubernetes: v1.30以降。`minDomains` はv1.30以降で常時利用可能。古いクラスタでは機能ゲート状態を確認する
- クラスタ: control-plane 1台 + worker 3台。各workerを仮想zone `zone-a` / `zone-b` / `zone-c` としてラベル付けする
- 権限: Namespace、Deployment、Serviceを作成できること。ラボ専用クラスタでNodeラベルを変更できるcluster-scope権限
- 所要時間: 基礎25分 → 実装70分 → 本番考察30分 → 任意challenge 25分、合計約150分

### 測定可能な到達点

1. 3 Podが3 zoneへ `1 / 1 / 1` に配置された証拠をJSONPathで提示できる。
2. `maxSkew: 1`、`minDomains: 3`、`DoNotSchedule` の計算を説明できる。
3. 1 zoneのラベル喪失後、scale-outしたPodが `Pending` になり、`FailedScheduling` eventを根拠として原因を特定できる。
4. ラベルを復旧し、Deploymentが4/4 Availableへreconcileすることを検証できる。
5. hard制約とsoft制約、Pod anti-affinity、PDBの役割の違いを設計判断として説明できる。

---

## 2. Production scenario・SLO・障害仮定

3 AZクラスタで決済APIを3 replica運用している。Pod数だけは3だが、容量やrolloutのタイミング次第で同一AZへ偏れば、そのAZ障害が全停止へ直結する。目標は「3個ある」ではなく、**単一AZ喪失後も最低2個のReady endpointを残す配置**である。

### 仮想SLOと配置指標

- 月間可用性: 99.95%
- 単一AZ喪失時もReady endpointを2個以上維持
- 通常時のzone間Pod数の差（skew）: 最大1
- 新規Podのscheduling待ち: 平常時60秒未満
- zone情報が3 domain未満なら、SLOを偽って偏在させずhard制約で新規配置を停止
- rollout中も `maxUnavailable: 0`、`maxSurge: 1` とし、Ready容量を3未満へ落とさない

### 障害仮定

- Node故障、AZ断、Nodeラベル欠落、Node poolのscale-to-zeroを想定する。
- `topology.kubernetes.io/zone` が正しく全対象Nodeへ付くことを信頼境界に含める。
- Topology spreadは**新規schedule時の配置判断**であり、既存Podを自動移動して再均衡しない。
- 3 AZに散っていても、共有DBや外部APIが単一障害点ならアプリSLOは満たせない。
- hard制約は偏在を防ぐ一方、domainや容量が足りないとPendingを選ぶ。可用性と配置保証のどちらを優先するかはワークロードごとの判断である。

---

## 3. Control planeとreconciliationのメンタルモデル

Topology spread専用の常駐コントローラがPodを並べ替えるわけではない。関係するloopを分ける。

1. Deployment controllerが `.spec.replicas` と現存Pod数の差を検知し、ReplicaSet経由で未割当Podを作る。
2. kube-schedulerは未割当Podをwatchし、各Nodeを評価する。
3. PodTopologySpread pluginは、`labelSelector` に一致する既存Podを `topologyKey` の値ごとに数える。
4. `DoNotSchedule` では制約違反Nodeをfilterする。`ScheduleAnyway` では偏りを減らすNodeへscoreを高くするが、保証はしない。
5. schedulerが選択したNode名をPodへbindし、対象Nodeのkubeletがコンテナを起動する。
6. readiness成功後、PodはServiceのEndpointSliceでready endpointになる。
7. NodeラベルやPod数が後で変わってskewが悪化しても、schedulerは既存Podを退避・再配置しない。次のPod作成時に現在状態を再評価する。

`DoNotSchedule` 時の概念式は次の通り。

```text
eligible domainごとの一致Pod数を数える
global minimum = 最少Pod数
ただし eligible domains < minDomains なら global minimum = 0
候補domainの skew = 配置後のPod数 - global minimum
skew > maxSkew なら、その候補Nodeを除外
```

`labelSelector` がPod template自身のラベルと一致しないと、そのPod自身が計数対象にならない「ghost pod」状態になる。selector整合性は最重要checkpointである。

---

## 4. 設計オプションとトレードオフ

### A. `DoNotSchedule` + `minDomains`

- 長所: 必要domain数が欠けたとき、暗黙に1〜2 zoneへ寄せず配置保証を守る。
- 短所: 容量・ラベル・autoscaler連携不良でPodがPendingになる。復旧手順とalertが必須。
- 向く対象: 決済、認証、制御系など、偏在を隠すより明示的に失敗させたい重要workload。

### B. `ScheduleAnyway`

- 長所: schedulerが偏り低減を好みつつ、容量不足時も配置しやすい。
- 短所: skewは保証されず、最悪時には同一domainへ偏る。
- 向く対象: batch、低重要度API、Pendingより起動を優先するworkload。

### C. required Pod anti-affinity

- 同一domainへ一致Podを複数置かない強い表現には便利。
- 「各zoneの差を1以内」のような多replicaの均等分散はTopology spreadの方が自然。
- 大規模clusterではinter-Pod affinity/anti-affinityの評価コストにも注意する。

### D. Node affinity / nodeSelector

- 「どの種類のNodeへ置けるか」を制約する。Topology spreadは「eligibleなNode群の中でどう分散するか」を制御する。
- 両方を使う場合、eligible domainの集合が狭くなり、`minDomains` 不足を起こし得る。

### E. PDBとの組み合わせ

- Topology spread: 新規Podの**配置**を制御。
- PDB: Eviction API経由の**自発的中断速度**を制御。
- 一方だけではAZ障害、drain、rolloutすべてをカバーしない。

### F. zone間通信コスト

均等分散は耐障害性を上げる一方、zone間のDB通信・egress料金・latencyを増やすことがある。サービスのレプリカ配置だけでなく、依存先、traffic locality、データ複製方式と合わせて評価する。

---

## 5. Architecture / object relationship

```mermaid
flowchart TB
  U[Engineer / kubectl] --> API[kube-apiserver]
  API --> D[Deployment: checkout]
  D --> RS[ReplicaSet]
  RS --> P[未割当Pods]
  API --> S[kube-scheduler]
  S --> T[PodTopologySpread plugin]
  T --> NA[Node zone-a]
  T --> NB[Node zone-b]
  T --> NC[Node zone-c]
  NA --> PA[checkout Pod 1]
  NB --> PB[checkout Pod 2]
  NC --> PC[checkout Pod 3]
  PA --> ES[EndpointSlice]
  PB --> ES
  PC --> ES
  ES --> SV[Service: checkout]
  T -. counts Pods matching app=checkout per topology.kubernetes.io/zone .-> PA
  T -. maxSkew=1 / minDomains=3 .-> NB
```

---

## 6. Guided lab（約150分）

### Phase 0 — 専用cluster作成と安全確認（15分）

`kind-spread.yaml` を作る。

```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: spread-lab
nodes:
  - role: control-plane
  - role: worker
  - role: worker
  - role: worker
```

> [!warning] apply相当の作成前確認
> 次はローカルに新しいDockerコンテナ群を作る。既存cluster名との衝突がないか `kind get clusters` で確認する。

```bash
kind get clusters
kind create cluster --config kind-spread.yaml
kubectl config current-context
kubectl cluster-info --context kind-spread
kubectl get nodes -o wide
```

**期待:** current-contextは `kind-spread`。Nodeは4台で、最終的に `Ready`。

安全用shell変数を設定する（新しいterminalでは再設定する）。

```bash
export K8S_LAB_CONTEXT=kind-spread
export K8S_LAB_NS=k8s-spread-lab
test "$(kubectl config current-context)" = "$K8S_LAB_CONTEXT"
```

worker名を確認し、3 zoneを模擬する。

```bash
kubectl get nodes -l '!node-role.kubernetes.io/control-plane' -o name
kubectl label node spread-lab-worker topology.kubernetes.io/zone=zone-a --overwrite
kubectl label node spread-lab-worker2 topology.kubernetes.io/zone=zone-b --overwrite
kubectl label node spread-lab-worker3 topology.kubernetes.io/zone=zone-c --overwrite
kubectl get nodes -L topology.kubernetes.io/zone
```

**Checkpoint 0:** workerだけが `zone-a / zone-b / zone-c` を1つずつ持つ。Node名が異なる場合は出力に合わせてコマンドを置換する。

### Phase 1 — 完全なアプリmanifest（35分）

`spread-app.yaml` を作る。

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: k8s-spread-lab
  labels:
    purpose: training
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: checkout
  namespace: k8s-spread-lab
  labels:
    app.kubernetes.io/name: checkout
spec:
  replicas: 3
  revisionHistoryLimit: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 0
      maxSurge: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: checkout
  template:
    metadata:
      labels:
        app.kubernetes.io/name: checkout
    spec:
      automountServiceAccountToken: false
      topologySpreadConstraints:
        - maxSkew: 1
          minDomains: 3
          topologyKey: topology.kubernetes.io/zone
          whenUnsatisfiable: DoNotSchedule
          labelSelector:
            matchLabels:
              app.kubernetes.io/name: checkout
        - maxSkew: 1
          topologyKey: kubernetes.io/hostname
          whenUnsatisfiable: ScheduleAnyway
          labelSelector:
            matchLabels:
              app.kubernetes.io/name: checkout
      securityContext:
        runAsNonRoot: true
        seccompProfile:
          type: RuntimeDefault
      containers:
        - name: web
          image: nginxinc/nginx-unprivileged:1.27-alpine
          imagePullPolicy: IfNotPresent
          ports:
            - name: http
              containerPort: 8080
          readinessProbe:
            httpGet:
              path: /
              port: http
            periodSeconds: 3
            timeoutSeconds: 1
            failureThreshold: 3
          resources:
            requests:
              cpu: 25m
              memory: 32Mi
            limits:
              cpu: 200m
              memory: 128Mi
          securityContext:
            allowPrivilegeEscalation: false
            capabilities:
              drop: ["ALL"]
            readOnlyRootFilesystem: true
          volumeMounts:
            - name: cache
              mountPath: /var/cache/nginx
            - name: run
              mountPath: /var/run
      volumes:
        - name: cache
          emptyDir: {}
        - name: run
          emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: checkout
  namespace: k8s-spread-lab
spec:
  selector:
    app.kubernetes.io/name: checkout
  ports:
    - name: http
      port: 80
      targetPort: http
```

重要なYAMLの読み方:

- Deployment `.spec.selector`、Pod templateのlabel、Topology spreadの`labelSelector`、Service selectorの4箇所を同じ値にする。
- zone制約はhard、hostname制約はsoft。zone保証を守りつつ、同一zone内でも可能ならNode分散する。
- `minDomains: 3` は3 zone未満を正常状態と数えない。
- `automountServiceAccountToken: false` はAPI認証情報が不要なweb containerへの不要なtoken mountを止める。
- requestsはschedulerが配置可能性を判断する基準、limitsはcontainerが使える上限。Topology条件を満たしてもrequest分の空きがなければPendingになる。
- non-root image、capability drop、read-only root filesystemを使い、書込みが必要なpathだけ`emptyDir`にする。

> [!warning] apply前確認
> `current-context` が `kind-spread` であること、YAML内Namespaceが `k8s-spread-lab` だけであることを確認する。

```bash
test "$(kubectl config current-context)" = "$K8S_LAB_CONTEXT"
kubectl apply --dry-run=server -f spread-app.yaml
kubectl diff -f spread-app.yaml || true
kubectl apply -f spread-app.yaml
kubectl -n "$K8S_LAB_NS" rollout status deployment/checkout --timeout=120s
```

`--dry-run=server` はAPI serverでvalidation/admissionを実行するが保存しない。`diff` の終了コード1は差分ありを意味し、必ずしもエラーではない。

### Phase 2 — 配置と通信を検証（25分）

```bash
kubectl -n "$K8S_LAB_NS" get pods -l app.kubernetes.io/name=checkout \
  -o custom-columns='POD:.metadata.name,NODE:.spec.nodeName,READY:.status.conditions[?(@.type=="Ready")].status'

kubectl -n "$K8S_LAB_NS" get pods -l app.kubernetes.io/name=checkout \
  -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.nodeName}{"\n"}{end}'

for node in spread-lab-worker spread-lab-worker2 spread-lab-worker3; do
  zone=$(kubectl get node "$node" -o jsonpath='{.metadata.labels.topology\.kubernetes\.io/zone}')
  count=$(kubectl -n "$K8S_LAB_NS" get pod -l app.kubernetes.io/name=checkout \
    --field-selector "spec.nodeName=$node" --no-headers 2>/dev/null | wc -l)
  printf '%s\t%s\t%s pods\n' "$zone" "$node" "$count"
done

kubectl -n "$K8S_LAB_NS" get endpointslice \
  -l kubernetes.io/service-name=checkout -o wide
kubectl -n "$K8S_LAB_NS" run curl --rm -i --restart=Never \
  --image=curlimages/curl:8.12.1 -- curl -fsS http://checkout/
```

**期待出力（名前・IPは異なる）:**

```text
zone-a  spread-lab-worker   1 pods
zone-b  spread-lab-worker2  1 pods
zone-c  spread-lab-worker3  1 pods
pod "curl" deleted
<!DOCTYPE html> ... Welcome to nginx! ...
```

**Checkpoint 1:** 3 Podが別zone、Deploymentは `3/3` Available、EndpointSliceにはready endpointが3つ。偏っていたら、Node label、Podのselector、Eventsを先に確認し、闇雲にdeleteしない。

### Phase 3 — failure injectionと証拠収集（35分）

インシデント仮定: cloud integrationの不具合でworker3からzoneラベルが消えた。既存Podは直ちに移動しないが、その状態でHPA相当のscale-outが起きる。

> [!danger] 障害注入前確認
> Nodeラベル変更はnamespaceで隔離されない。必ず専用 `kind-spread` contextであることをtestし、変更前の値を記録する。

```bash
test "$(kubectl config current-context)" = "$K8S_LAB_CONTEXT"
kubectl get node spread-lab-worker3 \
  -o jsonpath='{.metadata.labels.topology\.kubernetes\.io/zone}{"\n"}'
kubectl label node spread-lab-worker3 topology.kubernetes.io/zone-
kubectl get nodes -L topology.kubernetes.io/zone
kubectl -n "$K8S_LAB_NS" scale deployment/checkout --replicas=4
kubectl -n "$K8S_LAB_NS" get pods -w
```

新Podが `Pending` のままならwatchを `Ctrl-C` で止め、証拠を集める。

```bash
PENDING_POD=$(kubectl -n "$K8S_LAB_NS" get pod \
  --field-selector=status.phase=Pending \
  -o jsonpath='{.items[0].metadata.name}')
printf 'pending=%s\n' "$PENDING_POD"
kubectl -n "$K8S_LAB_NS" describe pod "$PENDING_POD"
kubectl -n "$K8S_LAB_NS" get events --sort-by=.metadata.creationTimestamp \
  --field-selector reason=FailedScheduling
kubectl -n "$K8S_LAB_NS" get deployment checkout
```

**期待する証拠:**

- 新Podは `Pending`、`.spec.nodeName` は空。
- Eventに `FailedScheduling` とPod topology spread constraintを満たせない趣旨が現れる。
- Deployment desiredは4だがAvailableは3。既存3 Podは直ちに移動しない。
- eligible zoneが2で `minDomains: 3` を下回るためglobal minimumは0。どちらかへ4個目を置くと候補zoneの計数が2となり、`2 - 0 > maxSkew 1` で拒否される。

#### evidence-driven incident判断

1. **症状:** rollout/scaleが進まずPending。
2. **事実:** Pod status、FailedScheduling event、Nodeのzone列を保存。
3. **仮説:** imageやreadinessではなく、Topology spreadのeligible domain不足。
4. **反証:** `kubectl describe pod` にimage pullやresource不足が主因としてないことを確認。
5. **復旧策:** workload制約を緩める前に、正しいNode labelを復元する。

#### rollback / recovery

```bash
test "$(kubectl config current-context)" = "$K8S_LAB_CONTEXT"
kubectl label node spread-lab-worker3 topology.kubernetes.io/zone=zone-c --overwrite
kubectl -n "$K8S_LAB_NS" rollout status deployment/checkout --timeout=120s
kubectl -n "$K8S_LAB_NS" get pods -o wide
kubectl -n "$K8S_LAB_NS" get deployment checkout
```

**Checkpoint 2:** Pending Podがscheduleされ、Deploymentは `4/4` Available。分布は `2 / 1 / 1` のいずれかで、skewは1。

SLO上3 replicaへ戻す場合:

```bash
kubectl -n "$K8S_LAB_NS" scale deployment/checkout --replicas=3
kubectl -n "$K8S_LAB_NS" rollout status deployment/checkout --timeout=120s
```

scale-downでどのPodが消えるかはzone均等化を保証しない。結果が偏った場合、Topology spreadが既存Podの再均衡装置ではないことの証拠になる。

### Phase 4 — cleanup（5分）

> [!danger] delete前の最終確認
> 次の1つ目はNamespace内の全ラボリソース、2つ目は専用kind cluster全体を削除する。context名と対象を声に出して確認する。別clusterでは実行しない。

```bash
test "$(kubectl config current-context)" = "$K8S_LAB_CONTEXT"
kubectl get all -n "$K8S_LAB_NS"
kubectl delete namespace "$K8S_LAB_NS" --wait=true
kind delete cluster --name spread-lab
kind get clusters
```

cluster自体を削除するならNamespace削除は省略可能だが、ここでは削除対象を確認する訓練として明示している。

---

## 7. kubectlとYAMLの要点

- `kubectl get nodes -L <label>`: Node一覧へ指定label列を追加し、欠落・誤記をすぐ比較する。
- `kubectl label node NAME key=value --overwrite`: 既存値を明示的に更新する。末尾の `key-` はそのlabelを削除する構文なので特に注意。
- `kubectl apply --dry-run=server`: 実際のAPI version、schema、admissionを使って非永続validationする。
- `kubectl describe pod`: schedulerの判断は末尾Eventsに出る。Pending時はlogsより先に見る。
- `--field-selector=status.phase=Pending`: API側でPod phaseを絞る。label selectorとは別物。
- `kubectl scale`: Deploymentのdesired replica数を変更し、controllerのreconciliationを起こす。Podを直接作る操作ではない。
- `topologyKey`: Node labelの**キー**。同じ値を持つNode群が1 domainになる。
- `maxSkew`: domain間で許す最大偏差。hardとsoftで評価方法が異なる。
- `minDomains`: 必要なeligible domainの最小数。Nodeが存在するだけでなく、Node affinity/selector等も満たす必要がある。
- `whenUnsatisfiable`: `DoNotSchedule` はfilter、`ScheduleAnyway` はscoreによる優先。

---

## 8. Production concerns

### Security / RBAC

Nodeラベル変更はcluster-scopeで、一般アプリ運用者へ与えるには強すぎる。通常はcloud controllerまたは限定されたplatform teamが管理する。Node isolationや規制用途では、侵害されたkubeletが自己申告できない保護されたlabel prefixとNode authorizer / NodeRestriction admissionの採用を検討する。

観測だけを行う研修者にはNamespace内read権限へ絞る例:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: spread-observer
  namespace: k8s-spread-lab
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: spread-observer
  namespace: k8s-spread-lab
rules:
  - apiGroups: [""]
    resources: ["pods", "events", "services"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["apps"]
    resources: ["deployments", "replicasets"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["discovery.k8s.io"]
    resources: ["endpointslices"]
    verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: spread-observer
  namespace: k8s-spread-lab
subjects:
  - kind: ServiceAccount
    name: spread-observer
    namespace: k8s-spread-lab
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: spread-observer
```

このRoleはNodeを読めない。zone診断も必要ならcluster-wide `nodes/get,list,watch` を含むClusterRoleを別途慎重に設計する。Node更新権限は混ぜない。

### Namespace / context

- manifestの全namespaced objectへNamespaceを明記する。
- CIではcontextを暗黙にせず、`--context` と `--namespace` を明示する。
- admission policyでrequired label、resource requests、Topology spreadの組織標準を検査する案もある。

### Resource / autoscaling

- 各zoneにrequest分の余剰容量がなければhard制約はPendingを生む。
- Cluster Autoscalerがscale-to-zeroしたnode groupのzoneは、既存Nodeがないためschedulerからdomainとして見えない場合がある。autoscalerがTopology spreadと全domainを認識できるか検証する。
- HPAの最大replica数だけでなく、AZごとのNode上限とsurge容量をcapacity testする。
- scale-down後は分布が自動修正されない。必要ならDeschedulerを別コンポーネントとして評価するが、eviction、PDB、コストへの影響を先に検証する。

### Cost / latency

- 3 AZ Node poolは最低稼働Node数、load balancer、zone間egressを増やす。
- 均等配置してもtrafficがlocality-awareでなければcross-zone通信は残る。
- hard制約のためだけに低利用率Nodeを維持するコストと、AZ障害時損失を比較する。

### Observability / alert

- Pending Pod数と `FailedScheduling` eventをalert対象にする。
- Pod数をzone別に集計し、skewと「label欠落Node数」を可視化する。
- desired / updated / ready / available replicasを同時に見る。
- SLO違反判断ではPod phaseだけでなく、EndpointSliceのready endpointと実トラフィック成功率を見る。

---

## 9. Optional advanced challenge（25分）

次のいずれかを実施し、変更前後のEventsと配置表をdeliverableへ追加する。

1. zone制約を `ScheduleAnyway` へ変え、zone-c labelを削除した状態で4 replicaへscaleする。起動優先が配置保証をどう弱めるか比較する。
2. Deploymentを6 replicaへし、zoneとhostnameの二重制約で分布を観測する。
3. worker 1台をcordonし、rolling updateのsurge Podがどこへ置かれるかを予測してから実測する。
4. PDB `minAvailable: 2` を追加し、「schedule時の分散」と「drain時の中断制御」の独立性を説明する。

---

## 10. Verification checklist / concrete deliverables

- [ ] current-context `kind-spread` をapply/delete前に検証した
- [ ] worker 3台のzone label表を保存した
- [ ] manifestの4つのselectorが一致すると確認した
- [ ] server-side dry-runを通した
- [ ] 初期配置 `1 / 1 / 1` のPod名・Node名・zoneを記録した
- [ ] EndpointSliceにready endpointが3つあると確認した
- [ ] zone label欠落後のPending PodとFailedScheduling eventを保存した
- [ ] global minimumとskew計算を自分の言葉で説明した
- [ ] label復旧後に4/4 Availableと `2 / 1 / 1` を確認した
- [ ] Secretを作成・表示・記録していない
- [ ] 専用Namespaceまたは専用clusterだけをcleanupした

**提出物:** `kind-spread.yaml`、`spread-app.yaml`、初期/障害/復旧の3つの配置表、FailedScheduling event抜粋、hard/soft選択の200字設計メモ。

---

## 11. Assessment

### Q1. `maxSkew: 1` は常に全zoneへ1個ずつ置く指定か？

<details><summary>回答</summary>

いいえ。matching Pod数のdomain間偏差を制御する。replica数とdomain数が一致しなければ `2/1/1` もskew 1で正当。さらにhard/soft、eligible domain、global minimumの条件で結果が変わる。

</details>

### Q2. `minDomains: 3` でeligible zoneが2つになったとき、global minimumはいくつか？

<details><summary>回答</summary>

0。eligible domain数が`minDomains`未満ならglobal minimumを0としてskewを計算する。

</details>

### Q3. zone labelを既存PodのNodeから消すと、Podは自動的に別Nodeへ移るか？

<details><summary>回答</summary>

移らない。Topology spreadはschedulerの新規配置判断であり、既存Podの継続配置を自動修正しない。再均衡には再作成やDescheduler等、別の仕組みと安全設計が必要。

</details>

### Q4. `labelSelector` がPod template labelと一致しない場合の問題は？

<details><summary>回答</summary>

対象Podが分布計数に入らず、意図しない偏在が起こり得る。Deployment selector、template label、Topology spread selector、Service selectorを整合させる。

</details>

### Q5. `DoNotSchedule` と `ScheduleAnyway` の運用上の最大の違いは？

<details><summary>回答</summary>

前者は制約違反Nodeを候補から除外し、保証を守るためPendingを許容する。後者は偏りを減らすNodeを優先するだけで、起動を優先して制約違反配置も許容する。

</details>

### Interview / design question

「3 AZ、通常6 replica、HPA最大30、各zoneのnode groupはscale-to-zero可能、月間99.99%のAPI」に対し、Topology spread、PDB、requests、autoscaler、rollout surge、監視をどう組み合わせるか。AZ喪失中にhard制約を維持するか緩和するかを、ユーザー影響とデータ整合性を含めて説明せよ。

### Follow-up challenge

本ラボを `minDomains` なし、zone制約soft、required anti-affinityの3案で繰り返す。障害前・label欠落時・scale-out時の「Available数 / Pending数 / skew」を比較表にし、自分のサービスならどれを採用するかADRを1ページで書く。

---

## 12. 現行公式リファレンス

- [Pod Topology Spread Constraints — Kubernetes](https://kubernetes.io/docs/concepts/scheduling-eviction/topology-spread-constraints/)
- [Assigning Pods to Nodes — Kubernetes](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/)
- [Kubernetes Scheduler](https://kubernetes.io/docs/concepts/scheduling-eviction/kube-scheduler/)
- [Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [Resource Management for Pods and Containers](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)
- [Using RBAC Authorization](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
- [NodeRestriction admission controller](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/#noderestriction)

> 参照日は2026-07-23。Kubernetesの機能状態と既定値はリリースで変わり得るため、実クラスタのversionとfeature gateも照合する。
