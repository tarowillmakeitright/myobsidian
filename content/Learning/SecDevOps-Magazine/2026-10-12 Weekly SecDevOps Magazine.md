---
type: weekly-magazine
series: secdevops
difficulty: Specialized
focus: "AWS IAM: permissions boundary で委任された role 作成の権限昇格を防ぐ"
week: 2026-W42
prerequisites:
  - AWS IAM role・identity policy・trust policy の基礎
  - IAM JSON policy の Action・Resource・Condition の読み方
  - least privilege と explicit deny の概念
  - JSON と Python 3、POSIX shell の基本操作
estimated_minutes: 165
tags:
  - security
  - devops
  - weekly
  - deep-dive
---

# Weekly SecDevOps Magazine — 2026-10-12

[[Home]]

#security #devops #weekly #deep-dive

> [!warning] 倫理・安全・費用
> この号は、自分で作るローカル JSON と合成 CloudTrail event だけで学べる。実 AWS credential、account ID、role ARN、内部命名規則をファイルや画面共有へ貼らない。第三者 account の調査・変更をしない。実 account で IAM policy、permissions boundary、role を変更すると workload 停止や権限昇格を招くため、検証 account、承認、break-glass 手順、rollback を用意する。IAM 自体に追加料金は通常ないが、CloudTrail trail / Lake、S3、CloudWatch Logs、IAM Access Analyzer の一部機能（custom policy checks など）は課金対象になり得る。cleanup で実 IAM resource を削除する前に account、role 名、依存関係を再確認すること。

## 1. Weekly focus、難易度、前提、測定可能な学習成果

### Weekly focus

**platform team が application team に IAM role 作成を委任するとき、指定した permissions boundary を必須化し、その boundary の除去・差し替え・迂回を防いで、作成者自身を超える権限を持つ role が生まれないようにする。**

- **対象 criterion:** AWS/GCP IAM
- **Difficulty signal:** **Specialized** — IAM policy の相互作用が複雑であることを示す目安で、参加条件ではない
- **推定時間:** 165分（Foundation 30分、Practical implementation 75分、Production concerns 30分、incident drill 20分、cleanup / 振り返り10分）
- **レイヤー:** Foundation → Practical implementation → Production concerns → Optional advanced challenge

### 必要な知識・tools・environment・earlier concepts

- **必要知識:** IAM principal、role trust policy、identity-based policy、managed policy、`Action` / `Resource` / `Condition`、default deny / explicit deny
- **Tools:** Python 3.10以上、POSIX shell、テキストエディタ。任意で `jq`、AWS CLI v2
- **Environment:** Linux/macOS のローカル一時 directory。cloud account、network、実 credential は不要。任意の live check は所有する sandbox account のみ
- **Earlier concepts:** least privilege、separation of duties、policy as code、immutable identifier、fail closed、CloudTrail management event、`iam:PassRole`
- **今回扱わない範囲:** SCP 全体設計、cross-account trust、resource-based policy の全例、ABAC 全般。これらは boundary を補完する別の境界である

### 測定可能な学習成果

完了時に、次を証拠付きで実演できること。

1. permissions boundary は権限を**付与せず**、identity policy が付与し得る最大範囲を制限する、と説明できる。
2. `CreateRole` に `iam:PermissionsBoundary` condition を必須化し、未指定・別 boundary の作成要求を拒否できる。
3. `DeleteRolePermissionsBoundary`、任意 boundary への差し替え、無制限な `AttachRolePolicy`、過大な `PassRole` という4つの昇格経路を発見できる。
4. identity policy と boundary の積集合、explicit deny、SCP / session policy / resource policy との違いを図で説明できる。
5. CloudTrail event から boundary の作成・除去・差し替えを検知し、30分以内の封じ込め手順を作れる。

---

## 2. Production scenario と threat / failure model

### シナリオ

SaaS 企業の central platform team は、開発速度を上げるため、各 application team に `/app/` path 配下の execution role をセルフサービスで作らせたい。role は S3、SQS、CloudWatch Logs などを利用できるが、IAM administration、Organizations、KMS key policy 変更、security logging 停止は許可しない。

application team の deployer role に単純に次を許すと危険である。

```json
{
  "Effect": "Allow",
  "Action": ["iam:CreateRole", "iam:AttachRolePolicy", "iam:PassRole"],
  "Resource": "*"
}
```

攻撃者または誤操作した利用者は、`AdministratorAccess` を付けた role を作り、その role を Lambda / EC2 などへ渡し、service 経由で強い権限を行使できる。本人に `s3:*` がなくても、`iam:PassRole` と service の作成権限の組み合わせが権限昇格になる。

### 保護対象

- AWS account の管理権限と security control
- production data、KMS key、CloudTrail / Config / GuardDuty 等の監査機能
- platform team 管理の boundary policy
- application role の trust policy と attached policy
- 誰が、いつ、どの boundary を指定して role を作ったかという監査証跡

### threat / failure model

| ID | 脅威・失敗 | 必要な防御 |
|---|---|---|
| T1 | boundary を付けずに role を作成 | `CreateRole` を指定 boundary 付きの場合だけ Allow |
| T2 | 作成後に boundary を削除 | `DeleteRolePermissionsBoundary` を委任権限から除外し、上位 guardrail でも明示的に Deny |
| T3 | 弱い boundary に差し替え | `PutRolePermissionsBoundary` の resource と `iam:PermissionsBoundary` を固定 |
| T4 | AWS 管理の強い policy を attachment | boundary が実効権限を切る。加えて attach 可能 policy も allowlist 化 |
| T5 | 強い既存 role を service に渡す | `iam:PassRole` の Resource と `iam:PassedToService` を限定 |
| T6 | boundary policy 自体を編集・version 切替・削除 | boundary 管理を platform role のみに分離し、SCP / change approval で保護 |
| T7 | resource-based policy や role session ARN を通る例外 | boundary を単独の完全防御とみなさず、resource policy と principal 形式を review |
| F1 | boundary が必要 action を許さず deploy 停止 | canary role、policy simulation、CloudTrail denied event、承認済み rollback |

**非目標:** permissions boundary は SCP の代替ではない。account / OU 全体を強制する guardrail ではなく、個々の IAM user / role の最大権限を制限する仕組みである。

---

## 3. Deep conceptual explanation と重要な design trade-off

### 3.1 「許可」ではなく「上限」

role の identity policy が action を許し、かつ boundary もその action を許すときに限り、その2種類の policy に関する許可条件を満たす。

```text
effective identity permission
  = identity-policy Allow
  ∩ permissions-boundary Allow
  ∩ session-policy Allow（存在する場合）
  ∩ SCP/RCP Allow（該当する場合）
  − any explicit Deny
```

たとえば identity policy が `s3:*`、boundary が `s3:GetObject` と `s3:PutObject` だけを許すなら、実効範囲はその2 action までである。逆に boundary が `s3:*` を許していても、identity policy が何も許可しなければ実効権限は増えない。

> [!important]
> 上式は理解用の簡略化である。resource-based policy が IAM user ARN、role ARN、role session ARN のどれを Principal にするかなどで boundary の implicit deny の効き方が異なる。explicit deny は優先されるが、「boundary を付けたから resource policy を無視できる」と考えてはいけない。

### 3.2 boundary を付ける権限そのものを制約する

`iam:PermissionsBoundary` condition key は、`CreateRole` / `PutRolePermissionsBoundary` request が指定する boundary ARN を検査する。安全な委任には最低でも次が必要になる。

1. 作成可能な role path を `/app/` に限定する。
2. `CreateRole` は承認済み boundary ARN を指定したときだけ Allow する。
3. `PutRolePermissionsBoundary` も同じ boundary ARN のみ Allow する。
4. `DeleteRolePermissionsBoundary` を application team に与えない。
5. boundary policy の create version / set default / delete / detach 相当操作を与えない。
6. `PassRole` は `/app/` role と必要な service に限定する。

単なる「boundary を必須にする」だけでは、その boundary の編集者が同じ人なら意味がない。**boundary の利用者と管理者を分離する**ことが核心である。

### 3.3 explicit Deny と allowlist の選択

- **allowlist 型 boundary:** workload に必要な service/action だけ Allow。新 service は止まるが fail closed で強い。
- **denylist 型 boundary:** `NotAction` や重要 action の Deny を中心に構成。導入しやすいが、新 action / service の追加や抜け漏れに弱い。
- **推奨:** 高い保証が必要なら allowlist を基本にし、絶対禁止 action の explicit Deny を補助的に置く。最初は観測と canary を使い、業務に必要な action を段階的に追加する。

### 3.4 managed policy ARN の固定と version 管理

condition に boundary の ARN を固定しても、その managed policy の default version を攻撃者が差し替えられれば上限を書き換えられる。したがって `iam:CreatePolicyVersion`、`iam:SetDefaultPolicyVersion`、`iam:DeletePolicy`、`iam:DeletePolicyVersion` を境界管理者にだけ許可する。CI では policy document の review、Access Analyzer validation、差分承認、canary simulation を通す。

### 3.5 主な trade-off

| 判断 | 安全側 | 運用側の代償 |
|---|---|---|
| boundary | service/action allowlist | 新機能追加時に platform team の更新が必要 |
| role path | `/app/team-a/*` まで分離 | 組織変更・共有 workload の設計が複雑 |
| `PassRole` | role ARN + `iam:PassedToService` を固定 | 新しい compute service の採用時に変更が必要 |
| policy attachment | customer managed policy allowlist | inline policy / AWS managed policy の自由度が下がる |
| enforcement | SCP に boundary 強制の Deny を追加 | Organizations 管理と例外 account の設計が必要 |
| rollback | policy の旧 version を保持 | 旧 version が悪用可能にならない保管・切替権限が必要 |

---

## 4. Architecture / workflow diagram

```mermaid
flowchart LR
    D[Application Deployer] -->|CreateRole + approved boundary ARN| IAM[AWS IAM authorization]
    IDP[Delegation identity policy] --> IAM
    PB[Platform-managed permissions boundary] --> IAM
    SCP[Optional Organizations SCP] --> IAM
    IAM -->|all required allows; no explicit deny| R[/app/team-a/ role]
    IAM -->|missing/wrong boundary or forbidden mutation| X[AccessDenied]
    R -->|PassRole only for approved ARN/service| S[Lambda or ECS task]
    S --> W[Approved workload actions]
    CT[CloudTrail] <-->|CreateRole / PutRolePermissionsBoundary / DeleteRolePermissionsBoundary / AttachRolePolicy| IAM
    CT --> DET[EventBridge / SIEM detection]
    DET --> IR[Containment: disable deployer, quarantine role, restore boundary]
```

### Workflow の読み方

1. Deployer の identity policy は `/app/team-a/` role の管理操作だけを候補として許可する。
2. `CreateRole` request に承認済み boundary ARN がなければ condition が一致せず default deny になる。
3. 作成した role の workload permission は、attached identity policy と boundary の積集合になる。
4. `PassRole` は対象 role と渡し先 service の両方を絞る。
5. CloudTrail は IAM API 操作を記録する。`PassRole` 自体は API event ではないため、role を受け取る resource の作成・更新 event を調べる。

---

## 5. Guided 165-minute lab

### Lab のゴールと成果物

ローカルで次を作る。

- `boundary.json`: application role の最大権限
- `delegation.json`: role 作成者に与える委任 policy
- `requests.jsonl`: 正常・異常な IAM request の test cases
- `evaluate.py`: このラボ範囲だけを判定する小さな validator
- `cloudtrail.jsonl` と `detect.py`: boundary mutation の検知演習
- `evidence.txt`: checkpoint の出力

> [!note]
> `evaluate.py` は AWS IAM policy simulator の代替ではない。JSON の構造と本号の invariants を検査する教材であり、完全な IAM evaluation engine ではない。

### Phase 0 — Setup（10分）

```bash
LAB_DIR="$(mktemp -d -t iam-boundary-lab.XXXXXX)"
cd "$LAB_DIR"
umask 077
printf 'lab=%s\n' "$PWD" | tee evidence.txt
python3 --version | tee -a evidence.txt
```

**行ごとの説明:** 

1. `mktemp -d` は衝突しにくい disposable directory を作る。
2. `cd` は以後の生成物を lab 内に閉じ込める。
3. `umask 077` は新規ファイルを原則として所有者だけが読めるようにする。
4. `pwd` 相当を証跡へ残し、cleanup 対象を明確にする。
5. Python version を記録し、再現性を持たせる。

**Checkpoint 0:** `evidence.txt` に `iam-boundary-lab.` を含む絶対 path と Python 3.10+ がある。

### Phase 1 — Boundary policy を作る（20分）

`boundary.json` を次の内容で保存する。

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowApprovedWorkloadServices",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    },
    {
      "Sid": "DenySecurityControlMutation",
      "Effect": "Deny",
      "Action": [
        "iam:*",
        "organizations:*",
        "cloudtrail:StopLogging",
        "cloudtrail:DeleteTrail",
        "config:StopConfigurationRecorder",
        "config:DeleteConfigurationRecorder"
      ],
      "Resource": "*"
    }
  ]
}
```

**重要行の説明:**

- `AllowApprovedWorkloadServices`: identity policy が許可しても、この list 外は boundary 側の Allow がないため実効許可にならない。
- `Resource: "*"`: S3 object と SQS queue など異種 resource を一例にまとめた教材上の簡略化。本番は statement を service ごとに分け、resource ARN と condition を限定する。
- `DenySecurityControlMutation`: 将来 identity policy が誤って強くなっても、ここに列挙した control の変更を explicit deny する。
- `iam:*`: workload role に IAM 管理をさせない。AWS service が必要とする service-linked role 作成などは別の platform path で扱う。

構文を確認する。

```bash
python3 -m json.tool boundary.json >/dev/null
printf 'PASS boundary JSON syntax\n' | tee -a evidence.txt
```

**Expected output:** `PASS boundary JSON syntax`

### Phase 2 — Delegation policy を作る（25分）

`111122223333` は文書用の架空 account ID である。実 account ID に置換したファイルを公開しない。

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "CreateOnlyBoundedAppRoles",
      "Effect": "Allow",
      "Action": "iam:CreateRole",
      "Resource": "arn:aws:iam::111122223333:role/app/team-a/*",
      "Condition": {
        "ArnEquals": {
          "iam:PermissionsBoundary": "arn:aws:iam::111122223333:policy/platform/AppBoundary-v1"
        },
        "StringEquals": {
          "aws:RequestTag/Owner": "team-a"
        },
        "ForAllValues:StringEquals": {
          "aws:TagKeys": ["Owner"]
        }
      }
    },
    {
      "Sid": "RestoreOnlyApprovedBoundary",
      "Effect": "Allow",
      "Action": "iam:PutRolePermissionsBoundary",
      "Resource": "arn:aws:iam::111122223333:role/app/team-a/*",
      "Condition": {
        "ArnEquals": {
          "iam:PermissionsBoundary": "arn:aws:iam::111122223333:policy/platform/AppBoundary-v1"
        }
      }
    },
    {
      "Sid": "ManageOnlyTeamPolicies",
      "Effect": "Allow",
      "Action": [
        "iam:AttachRolePolicy",
        "iam:DetachRolePolicy",
        "iam:PutRolePolicy",
        "iam:DeleteRolePolicy",
        "iam:GetRole",
        "iam:ListAttachedRolePolicies",
        "iam:ListRolePolicies"
      ],
      "Resource": "arn:aws:iam::111122223333:role/app/team-a/*"
    },
    {
      "Sid": "PassOnlyTeamRolesToLambda",
      "Effect": "Allow",
      "Action": ["iam:GetRole", "iam:PassRole"],
      "Resource": "arn:aws:iam::111122223333:role/app/team-a/*",
      "Condition": {
        "StringEquals": {
          "iam:PassedToService": "lambda.amazonaws.com"
        }
      }
    }
  ]
}
```

**設計レビュー:**

- `Resource` は作成・管理・PassRole のすべてを team path に閉じる。
- `iam:PermissionsBoundary` が missing / wrong なら `CreateRole` と `PutRolePermissionsBoundary` の Allow が成立しない。
- `aws:RequestTag/Owner` と `aws:TagKeys` は ownership metadata を作成時に強制する。tag を認可に使うなら TagRole / UntagRole も厳密に設計する。
- `DeleteRolePermissionsBoundary` は意図的にない。
- boundary managed policy を編集する action もない。
- `PassRole` は Lambda にだけ許す。ただし Lambda の `CreateFunction` / `UpdateFunctionConfiguration` 権限も別 policy で resource 制約する必要がある。
- `ManageOnlyTeamPolicies` は教材上まだ広い。実運用では inline policy の危険 action を policy pipeline で拒否し、attach 可能 policy ARN も限定する。

### Phase 3 — Policy invariants を自動検査（30分）

`evaluate.py`:

```python
import json
from pathlib import Path

APP_PREFIX = "arn:aws:iam::111122223333:role/app/team-a/"
BOUNDARY = "arn:aws:iam::111122223333:policy/platform/AppBoundary-v1"
FORBIDDEN_DELEGATED = {
    "iam:DeleteRolePermissionsBoundary",
    "iam:CreatePolicyVersion",
    "iam:SetDefaultPolicyVersion",
    "iam:DeletePolicy",
}

policy = json.loads(Path("delegation.json").read_text())
statements = policy["Statement"]

def actions(stmt):
    value = stmt.get("Action", [])
    return {value} if isinstance(value, str) else set(value)

def find_allow(action):
    return [s for s in statements
            if s.get("Effect") == "Allow" and action in actions(s)]

errors = []
create = find_allow("iam:CreateRole")
if len(create) != 1:
    errors.append("CreateRole must have exactly one Allow")
else:
    s = create[0]
    if not s.get("Resource", "").startswith(APP_PREFIX):
        errors.append("CreateRole resource escapes team path")
    actual = s.get("Condition", {}).get("ArnEquals", {}).get(
        "iam:PermissionsBoundary")
    if actual != BOUNDARY:
        errors.append("CreateRole does not require approved boundary")

delegated = set().union(*(actions(s) for s in statements
                          if s.get("Effect") == "Allow"))
bad = delegated & FORBIDDEN_DELEGATED
if bad:
    errors.append("forbidden delegated actions: " + ",".join(sorted(bad)))

for s in find_allow("iam:PassRole"):
    if not s.get("Resource", "").startswith(APP_PREFIX):
        errors.append("PassRole escapes team path")
    service = s.get("Condition", {}).get("StringEquals", {}).get(
        "iam:PassedToService")
    if service != "lambda.amazonaws.com":
        errors.append("PassRole service is not restricted to Lambda")

if errors:
    print("FAIL")
    for error in errors:
        print("-", error)
    raise SystemExit(1)
print("PASS: delegation invariants hold")
```

実行する。

```bash
python3 -m json.tool delegation.json >/dev/null
python3 evaluate.py | tee -a evidence.txt
```

**Expected output:**

```text
PASS: delegation invariants hold
```

**Negative test:** `delegation.json` の任意 statement の action に `iam:DeleteRolePermissionsBoundary` を一時追加し、再実行する。

```text
FAIL
- forbidden delegated actions: iam:DeleteRolePermissionsBoundary
```

確認後、追加行を戻し、再度 PASS を得る。

**Checkpoint 3:** positive test と negative test の両方を `evidence.txt` または screenshot に残す。

### Phase 4 — Request table で権限境界を説明（15分）

次の期待結果を自分の言葉で `request-review.md` に記録する。

| Request | Delegation policy | Boundary | Expected | 理由 |
|---|---:|---:|---|---|
| approved boundary 付き `/app/team-a/api` 作成 | Allow | 未適用（作成要求中） | Allow | path / boundary / tag condition が一致 |
| boundary なしで同 role 作成 | condition 不一致 | — | Deny | CreateRole の Allow がない |
| 別 boundary で同 role 作成 | condition 不一致 | — | Deny | ARN が一致しない |
| `/security/admin` role 作成 | Resource 不一致 | — | Deny | team path 外 |
| app role に `AdministratorAccess` attach | 操作自体は教材 policy では Allow | boundary が制限 | attach 成功し得るが実効権限は上限内 | attach 成功と authorize 成功は別。ただし attach 自体も allowlist 推奨 |
| app role から `iam:CreateUser` | identity policy が Allow でも | explicit Deny | Deny | boundary の Deny が優先 |
| app role から `s3:GetObject` | Allow の場合 | Allow | Allow | 両者の積集合 |
| app role から `s3:DeleteObject` | Allow の場合 | Allow なし | Deny | boundary の implicit deny |
| boundary を削除 | action の Allow なし | — | Deny | default deny |
| app role を ECS に PassRole | `iam:PassedToService` 不一致 | — | Deny | Lambda のみ |

### Phase 5 — Detection と incident drill（30分）

`cloudtrail.jsonl` に以下の**合成 event**を保存する。

```json
{"eventTime":"2026-10-12T00:15:00Z","eventSource":"iam.amazonaws.com","eventName":"CreateRole","userIdentity":{"arn":"arn:aws:sts::111122223333:assumed-role/TeamADeployer/session-123"},"requestParameters":{"roleName":"api","path":"/app/team-a/","permissionsBoundary":"arn:aws:iam::111122223333:policy/platform/AppBoundary-v1"},"responseElements":{"role":{"arn":"arn:aws:iam::111122223333:role/app/team-a/api"}},"sourceIPAddress":"192.0.2.10"}
{"eventTime":"2026-10-12T00:22:00Z","eventSource":"iam.amazonaws.com","eventName":"DeleteRolePermissionsBoundary","userIdentity":{"arn":"arn:aws:sts::111122223333:assumed-role/TeamADeployer/session-evil"},"requestParameters":{"roleName":"api"},"errorCode":"AccessDenied","sourceIPAddress":"198.51.100.20"}
{"eventTime":"2026-10-12T00:25:00Z","eventSource":"iam.amazonaws.com","eventName":"PutRolePermissionsBoundary","userIdentity":{"arn":"arn:aws:sts::111122223333:assumed-role/UnexpectedAdmin/session-9"},"requestParameters":{"roleName":"api","permissionsBoundary":"arn:aws:iam::111122223333:policy/WeakBoundary"},"sourceIPAddress":"203.0.113.50"}
```

`detect.py`:

```python
import json
from pathlib import Path

APPROVED = "arn:aws:iam::111122223333:policy/platform/AppBoundary-v1"
WATCH = {"CreateRole", "PutRolePermissionsBoundary",
         "DeleteRolePermissionsBoundary"}

for line in Path("cloudtrail.jsonl").read_text().splitlines():
    e = json.loads(line)
    if e.get("eventSource") != "iam.amazonaws.com":
        continue
    name = e.get("eventName")
    if name not in WATCH:
        continue
    p = e.get("requestParameters") or {}
    boundary = p.get("permissionsBoundary")
    risky = (name == "DeleteRolePermissionsBoundary" or
             name in {"CreateRole", "PutRolePermissionsBoundary"}
             and boundary != APPROVED)
    status = "ALERT" if risky else "OK"
    result = "DENIED" if e.get("errorCode") else "SUCCEEDED"
    print(status, result, e["eventTime"], name,
          p.get("roleName"), e["userIdentity"].get("arn"))
```

```bash
python3 detect.py | tee -a evidence.txt
```

**Expected output:**

```text
OK SUCCEEDED 2026-10-12T00:15:00Z CreateRole api arn:aws:sts::111122223333:assumed-role/TeamADeployer/session-123
ALERT DENIED 2026-10-12T00:22:00Z DeleteRolePermissionsBoundary api arn:aws:sts::111122223333:assumed-role/TeamADeployer/session-evil
ALERT SUCCEEDED 2026-10-12T00:25:00Z PutRolePermissionsBoundary api arn:aws:sts::111122223333:assumed-role/UnexpectedAdmin/session-9
```

> [!important]
> failed attempt も reconnaissance や compromised session の兆候になり得る。`AccessDenied` を捨てない。一方、検知 query では `errorCode` の有無を区別し、成功した危険変更を最高 severity にする。

### Phase 6 — Cleanup（5分）

> [!warning] 破壊的操作
> 次は lab directory を削除する。`pwd` と path が `iam-boundary-lab.` を含むことを目視確認する。実 project directory では実行しない。

```bash
pwd
find "$LAB_DIR" -maxdepth 1 -type f -print
cd /
rm -rf -- "$LAB_DIR"
```

可能なら OS の trash command を使う。`rm -rf` を使う場合は `$LAB_DIR` が空でないことと、`/tmp` 等にある期待 path であることを確認する。

---

## 6. Configuration / commands の line-by-line 解説

### 任意: sandbox AWS account での validation（実環境変更なし）

`aws accessanalyzer validate-policy` は policy grammar と best practice findings を返す。実行には認証済み AWS CLI と権限が必要だが、policy を attach はしない。

```bash
aws accessanalyzer validate-policy \
  --policy-type IDENTITY_POLICY \
  --policy-document "file://$PWD/delegation.json" \
  --locale JA \
  --query 'findings[].{type:findingType,code:issueCode,learnMore:learnMoreLink}'
```

1. `validate-policy`: IAM Access Analyzer に policy の検査を依頼する。
2. `--policy-type IDENTITY_POLICY`: delegation policy が identity-based policy であると指定する。
3. `file://`: shell へ JSON を展開せずファイルを渡す。実 secret は policy に入れない。
4. `--locale JA`: finding message の locale を日本語にする。
5. `--query`: finding type、code、参照 URL だけを表示し、レビューしやすくする。

Basic validation と custom policy check は機能・料金が異なる。custom check を使う前に料金を確認する。finding 0件は business intent の正しさを保証しない。invariant test、review、sandbox simulation と組み合わせる。

### 任意: approved boundary を role 作成時に指定する形

> [!warning]
> 以下は実 IAM role を作成する変更操作である。所有する sandbox account で、承認済み name / path / boundary / trust policy を使う場合だけ実行する。本号の架空 ARN をそのまま使わない。

```bash
aws iam create-role \
  --role-name team-a-lab-api \
  --path /app/team-a/ \
  --permissions-boundary "$APPROVED_BOUNDARY_ARN" \
  --assume-role-policy-document file://trust-policy.json \
  --tags Key=Owner,Value=team-a
```

1. `--role-name`: organization の naming standard に沿う一意名。
2. `--path`: delegation policy の Resource ARN と一致する path。
3. `--permissions-boundary`: 作成時点から上限を付け、unbounded window を作らない。
4. `--assume-role-policy-document`: 誰が role を引き受けられるかを定義する。permission policy とは別物。
5. `--tags`: condition で要求した ownership tag。

### なぜ `PassRole` を別 statement にするのか

`iam:PassRole` は独立 API call ではなく、Lambda `CreateFunction` など role ARN を受け取る API の内部で評価される permission である。CloudTrail で `PassRole` event を探しても見つからない。受け取り側 API event の request parameters にある role ARN を追う。別 statement にすることで resource と `iam:PassedToService` condition を狭く保てる。

---

## 7. Detection / observability signals と incident drill

### 収集する signal

| Signal | Severity | 観点 |
|---|---:|---|
| successful `DeleteRolePermissionsBoundary` | Critical | 上限が消え、attached policy の許可が拡大し得る |
| approved でない ARN への successful `PutRolePermissionsBoundary` | Critical | 弱い上限への差し替え |
| boundary なし / 非承認 boundary の successful `CreateRole` | Critical | enforcement gap |
| 上記操作の `AccessDenied` 多発 | High | 悪用試行、automation drift、credential compromise |
| boundary managed policy の `CreatePolicyVersion` / `SetDefaultPolicyVersion` | Critical | 全 bounded role の上限が一括変更される |
| `/app/` role への high-privilege policy attach | High | boundary bypass の有無にかかわらず意図確認が必要 |
| Lambda / ECS 等の作成・更新 event に予期しない role ARN | High | 過大な PassRole または設定 drift |
| CloudTrail 配送停止・欠損 | Critical | detection blind spot |

### 推奨 log field

`eventTime`, `eventSource`, `eventName`, `awsRegion`, `sourceIPAddress`, `userAgent`, `userIdentity.arn`, `userIdentity.sessionContext.sessionIssuer.arn`, `requestParameters.roleName`, `requestParameters.permissionsBoundary`, `errorCode`, `errorMessage`, `requestID`。

### 20分 incident drill

**注入:** `PutRolePermissionsBoundary` が成功し、`api` role の boundary が `WeakBoundary` に変わった alert を受信した。

1. **0–5分: Triage**
   - event の成功 / 失敗、UTC 時刻、actor session、source IP、user agent、request ID を記録。
   - `GetRole` で現在の boundary ARN、`ListAttachedRolePolicies` / `ListRolePolicies` で付与 policy を確認。
   - boundary policy の default version と直近変更 event を確認。
2. **5–10分: Containment**
   - compromised が疑われる deployer session の発行元 IdP / role を無効化または deny する。break-glass operator を利用。
   - affected role を受け取る Lambda / ECS / EC2 等の新規 deploy を停止。
   - 承認済み boundary を再設定。ただし先に証拠と依存関係を記録する。
3. **10–15分: Scope**
   - 同 actor、source IP、session、時間帯について `CreateRole`, `AttachRolePolicy`, `PutRolePolicy`, `UpdateAssumeRolePolicy`, `PassRole` を伴う service event を検索。
   - `PassRole` event ではなく、Lambda `CreateFunction` / `UpdateFunctionConfiguration` 等の request にある role ARN を調べる。
   - affected role の temporary credential で行われた downstream API call を session identity から追う。
4. **15–20分: Recovery decision**
   - attached policy、trust policy、boundary が既知の良い状態と一致することを確認。
   - canary で必要 workload action が動き、禁止 action が deny されることを検証。
   - 根本原因が delegation policy、boundary 管理権限、SCP gap、credential compromise のどれかを分類。

**Drill deliverable:** `incident-timeline.md` に検知時刻、最初の成功した不正変更、actor、affected role、containment、証拠 source、再発防止 owner を記載する。

---

## 8. Common failure modes、unsafe patterns、remediation

| Failure / unsafe pattern | なぜ危険か | Remediation |
|---|---|---|
| `CreateRole` を `Resource: "*"` で許可 | security role や別 team role を作れる | path / name prefix を ARN で限定 |
| boundary condition なし | unbounded role を作れる | `iam:PermissionsBoundary` を `ArnEquals` で必須化 |
| `DeleteRolePermissionsBoundary` を委任 | 作成後に上限を外せる | application principal には与えず、SCP explicit Deny も検討 |
| 任意の `PutRolePermissionsBoundary` | 弱い boundary に交換可能 | approved ARN の condition を強制 |
| boundary policy の編集権限も委任 | 同じ ARN の内容を緩められる | platform administrator / pipeline に分離 |
| `iam:PassRole` が `Resource: "*"` | 強い既存 role を service に渡せる | role ARN と `iam:PassedToService` を限定 |
| boundary が権限を付与すると誤解 | identity policy がなく動かない、または review を誤る | identity policy と boundary の積集合を test |
| boundary だけで resource policy を無視 | principal 種別による例外を見逃す | resource policy、role ARN / session ARN を個別 review |
| Deny + `NotPrincipal` を resource policy で乱用 | boundary 付き principal が意図せず常に deny され得る | AWS 推奨の condition key を使う設計を検討 |
| AWS managed policy を無制限 attach | boundary があっても意図不明・将来変更の影響 | customer managed policy allowlist と review |
| `*` action を denylist のみで制御 | 新 service / action の抜け穴 | allowlist を基本に定期的な service authorization review |
| Access Analyzer PASS を完全保証と解釈 | business intent、resource policy、運用経路までは保証しない | invariant test + peer review + sandbox test + runtime detection |
| failed IAM event を破棄 | 攻撃試行や drift を見失う | success / failure を区別して双方を保存・alert |

---

## 9. Verification checklist と concrete lab deliverables

### Verification checklist

- [ ] focus、脅威、非目標を1分で説明できる
- [ ] boundary は permission grant ではなく maximum permission だと説明できる
- [ ] `boundary.json` と `delegation.json` が JSON として parse できる
- [ ] CreateRole の Resource が team path に限定されている
- [ ] `iam:PermissionsBoundary` が approved ARN と完全一致する
- [ ] `DeleteRolePermissionsBoundary` と boundary policy version 管理 action が委任されていない
- [ ] `PutRolePermissionsBoundary` が approved ARN だけを許す
- [ ] `iam:PassRole` の role ARN と service principal が限定されている
- [ ] positive invariant test が PASS する
- [ ] unsafe mutation を入れた negative test が FAIL する
- [ ] detection が denied deletion と successful wrong-boundary replacement を区別する
- [ ] incident drill で actor、affected role、変更前後、downstream use を追跡できる
- [ ] production 適用前に rollback、break-glass、canary、CloudTrail retention を確認した

### Lab deliverables

1. `boundary.json`
2. `delegation.json`
3. `evaluate.py` と positive / negative test 結果
4. `request-review.md`
5. `cloudtrail.jsonl` と `detect.py`
6. `evidence.txt`
7. `incident-timeline.md`
8. 3〜5行の design decision: allowlist / denylist、path、PassRole、boundary owner の選択理由

合格基準は、構文が通るだけでなく、**4つの昇格経路（未指定、削除、差し替え、PassRole）について防御と検知を説明できること**。

---

## 10. Assessment

### Questions

1. permissions boundary に `s3:GetObject` があり、role の identity policy にその action がない場合、実効許可はどうなるか。
2. `CreateRole` で approved boundary を必須にしても、deployer に `DeleteRolePermissionsBoundary` を許すと何が起こるか。
3. boundary ARN を固定したのに、その managed policy の `SetDefaultPolicyVersion` を同じ利用者が実行できる場合、なぜ危険か。
4. `iam:PassRole` の CloudTrail event が見つからないとき、どの event を調べるべきか。
5. IAM Access Analyzer policy validation が finding 0件なら、production deployment は自動承認してよいか。理由を述べよ。

### Interview / design question

100 team が単一 AWS account で self-service role を作る。各 team は自分の path だけを管理し、security logging と IAM を変更できず、Lambda にのみ自分の role を渡せる必要がある。permissions boundary、delegation policy、SCP、policy pipeline、CloudTrail detection の責任分担を設計し、boundary update の安全な rollout / rollback も説明せよ。

<details>
<summary>解答例を表示</summary>

1. **Deny。** boundary は上限であって許可を付与しない。identity policy と boundary の両方に必要な Allow がなければ default deny。
2. role 作成直後に boundary を外し、attached / inline identity policy の許可を上限なしで有効化できる。削除 action を委任せず、上位 guardrail と alert も置く。
3. ARN が同じでも default policy version の内容を弱くできるため、condition の固定を迂回できる。boundary document の version 管理は platform / security pipeline に分離する。
4. `PassRole` は API call ではない。role を受け取る resource の作成・更新 API、例として Lambda `CreateFunction` / `UpdateFunctionConfiguration`、その request parameter の role ARN を調べる。
5. **不可。** validation は grammar と best-practice findings に有用だが、組織固有の intent、すべての policy interaction、runtime path を保証しない。invariant test、peer approval、sandbox simulation、canary、runtime detection が必要。

**Design answer の要点:** team ごとに path と delegation role を分離し、CreateRole / PutRolePermissionsBoundary に approved ARN condition、DeleteRolePermissionsBoundary の禁止、PassRole の team path + service 制限を置く。boundary は workload allowlist と critical explicit deny を持ち、編集を security pipeline に限定。SCP は boundary なし role 作成・除去など account-wide invariant の最終防衛として使う。CI で syntax、Access Analyzer、new-access check、unit/invariant test、peer approval を実施。CloudTrail で boundary mutation、policy version、role attachment、service への role 設定を検知する。新 boundary version は shadow evaluation → canary team → small cohort → 全体の順で進め、旧 version への承認済み切替と break-glass を準備する。

</details>

---

## 11. Follow-up challenge と next-week prerequisite

### Optional advanced challenge

ローカル validator を拡張し、次を CI test にする。

1. team ごとの `role_prefix`, `approved_boundary`, `passed_to_services` を YAML / JSON data file に分離。
2. `DeleteRolePermissionsBoundary` だけでなく wildcard action（`iam:*`, `*`）も展開せず conservatively FAIL にする。
3. delegation policy の変更前後を比較し、新しい action / resource / service が増えたら approval を要求する。
4. 合成 CloudTrail に boundary policy の `CreatePolicyVersion` と Lambda `CreateFunction` を追加し、同一 actor / role ARN / 15分 window で相関する。
5. sandbox がある場合だけ IAM Access Analyzer custom policy check を評価する。**課金を先に確認**し、結果をローカル検査と比較する。

### Next-week prerequisite

次回候補の **observability / IAM change detection as code** に備え、次を説明できるようにする。

- CloudTrail management event の `userIdentity` と assumed-role session の関係
- EventBridge event pattern と SIEM query の違い
- alert の success / denied、severity、deduplication、suppression
- mean time to detect / contain と、証拠保全の基本

---

## 12. Current primary references

すべて AWS 公式文書。2026-10-12 確認。

1. [Permissions boundaries for IAM entities](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_boundaries.html) — boundary の定義、effective permission、resource-based policy との注意点
2. [Policy evaluation logic](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_evaluation-logic.html) — identity policy、boundary、SCP / RCP、explicit deny の評価
3. [Policies and permissions in IAM](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html) — policy type と boundary / SCP の役割
4. [Grant a user permissions to pass a role to an AWS service](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use_passrole.html) — `iam:PassRole` の resource / condition 制限と CloudTrail 上の追跡方法
5. [Validate policies with IAM Access Analyzer](https://docs.aws.amazon.com/IAM/latest/UserGuide/access-analyzer-policy-validation.html) — `validate-policy`、finding、custom check と料金注意
6. [Security best practices in IAM](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html) — temporary credential、least privilege、permissions guardrail、policy validation
7. [Logging IAM and AWS STS API calls with AWS CloudTrail](https://docs.aws.amazon.com/IAM/latest/UserGuide/cloudtrail-integration.html) — IAM / STS API event と identity correlation
8. [IAM JSON policy reference](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies.html) — policy element と condition key の一次資料

### 今週の要約

permissions boundary の価値は policy を1枚追加することではなく、**role 作成時に必須化し、消せず、弱いものへ替えられず、boundary 自体も編集できず、PassRole で迂回できない運用系**を作ることにある。権限上限、委任経路、policy supply chain、runtime detection を一つの control loop として設計する。
