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

# SecDevOps Magazine — 2026-06-24

## 1) Topic + Level
**Cloud Security / AWS・GCP における IAM 権限境界とクロスアカウント信頼設計の実践**  
**Level: Advanced**

**前提知識（Prerequisites）**
- Beginner レベルの IAM 基本要素（User / Group / Role / Policy / Service Account）を説明できること
- Middle レベルの Least Privilege、環境分離、CI/CD 用ロール分離を理解していること
- AWS AssumeRole / GCP Service Account の基本的な流れを知っていること
- JSON/YAML のポリシーや Terraform コードを読んで、どこが broad permission か判断できること

---

## 2) Why it matters in real projects
Advanced レベルの IAM 設計で本当に問われるのは、**「許可するか」ではなく「事故っても広がらないか」**です。

現実の現場では、こんな構成が普通にあります。

- 開発用 AWS account と本番 AWS account が分かれている
- GCP では project が複数あり、監査・運用・アプリで権限が交差する
- GitHub Actions や GitLab CI が cloud に OIDC 連携している
- Terraform が複数環境をまたいで apply する
- SRE や incident responder が緊急時だけ強い権限を使う

このとき怖いのは、単純な `admin` 付与だけではありません。むしろ危険なのは以下です。

- 信頼ポリシーが広すぎて、想定外の principal が AssumeRole できる
- `iam:PassRole` や `sts:AssumeRole` の経路が放置されている
- Terraform 実行ロールが infra 全体を踏み抜ける
- 組織レベルの guardrail がなく、個別ポリシーだけで頑張っている

つまり IAM は identity 設定ではなく、**クラウド全体の横移動耐性を決めるアーキテクチャ**です。ここを理解すると、侵害後の blast radius をかなり小さくできます。

---

## 3) Core concepts

### 3-1. Allow より先に “信頼境界” を設計する
多くの人は「このロールに何を許可するか」から考えます。でも Advanced では順番が逆です。

まず考えるべきは次です。

- **誰がその権限を取れるのか**
- **どの条件で取れるのか**
- **どの環境から取れるのか**
- **取ったあと、さらにどこへ横移動できるのか**

AWS なら trust policy、GCP なら principal binding や service account impersonation がここに当たります。

危ない例:
- 任意の GitHub repo から OIDC で deploy role を取れる
- `sts:AssumeRole` の対象が `*`
- GCP で `roles/iam.serviceAccountTokenCreator` を広く付けている

強い権限そのものより、**その権限への入口**のほうが危険なことは珍しくありません。

### 3-2. 権限境界は “できることの上限” を決める
IAM Policy だけだと、誰かが別ポリシーを追加した瞬間に設計が崩れることがあります。そこで必要なのが boundary / guardrail です。

AWS で使う代表例:
- Permission Boundary
- SCP (Service Control Policy)
- Resource-based policy
- Condition (`aws:PrincipalArn`, `aws:RequestedRegion`, `aws:ResourceTag/*`)

GCP で使う代表例:
- Organization Policy
- Folder / Project 階層での role 設計
- IAM Conditions
- Deny Policy（使う環境では非常に有効）

重要なのは、**“このロールは本来こうあるべき” ではなく “仮にミスってもここは超えられない” を先に作ること**です。

### 3-3. Cross-account / Cross-project は “片道” を意識する
安全な連携は、基本的に片道で考えます。

たとえば:
- CI account → staging deploy は許可
- CI account → prod deploy は承認付き + 専用 workflow のみ
- staging account → prod account は直接不可
- 監査 account → 各環境 read-only は許可
- 各環境 → 監査 account への逆方向権限は不要

これを曖昧にすると、staging compromise から prod への横移動ルートが生まれます。

**相互接続を便利にしすぎると、攻撃者にも便利**です。

### 3-4. `PassRole` / impersonation / token 作成権限は特に危険
多くの実務事故は、直接 admin がなくても起きます。

なぜなら、次の権限があると“他人の強い権限を借りる”ことができるからです。

- AWS: `iam:PassRole`
- AWS: `sts:AssumeRole`
- GCP: `roles/iam.serviceAccountUser`
- GCP: `roles/iam.serviceAccountTokenCreator`

たとえば「ECS タスク起動はできるが admin はない」ように見えても、強い task role を `PassRole` できれば結果的に権限昇格が起きます。

Advanced レベルでは、**“その principal が直接何をできるか” だけでなく “何になれるか” を見る**のが必須です。

### 3-5. Terraform 実行権限は環境ごと・操作ごとに分ける
Terraform は便利ですが、強すぎる 1 本の apply role は危険です。

分け方の例:
- `tf-plan-dev`
- `tf-apply-dev`
- `tf-plan-staging`
- `tf-apply-staging`
- `tf-plan-prod`
- `tf-apply-prod`

さらに prod では:
- 手動承認必須
- 特定 branch / tag からのみ実行
- state backend と KMS key も専用
- 許可リソース種別を絞る

Terraform の事故は「コードのミス」だけでなく、**実行主体に権限がありすぎること**で深刻化します。

### 3-6. Break-glass は設計してこそ意味がある
緊急時の強権限は現実には必要です。ただし設計なしの break-glass は普通の backdoor です。

最低限必要な条件:
- MFA 必須
- 使える人を最小化
- 利用時に即時通知
- 監査ログを集中保存
- 有効時間を短くする
- 事後レビューを必須化

break-glass は「存在すること」が大事なのではなく、**常用できないようにしてあること**が大事です。

### 3-7. 良い IAM 設計は“説明可能”である
Advanced で本当に差が出るのはここです。

次に即答できる状態を目指します。

- 本番へ deploy できる principal は誰か
- その principal はどこから credential を得るか
- その credential はどの条件で失効・拒否されるか
- 本番の DB backup を読める経路は何か
- staging 侵害時に prod へ行けるルートは残っていないか

説明できない設計は、たいてい運用者本人も全体像を掴めていません。

---

## 4) Hands-on mini lab (30-60 min)
**テーマ: CI/CD の OIDC + Terraform 実行ロールを棚卸しし、横移動ルートを 1 本ずつ潰す**

### ゴール
- OIDC / AssumeRole / impersonation の入口を確認する
- broad な trust relationship を見つける
- Terraform prod apply に追加制約を入れる
- `PassRole` / service account impersonation の危険経路を特定する

### 想定シナリオ
- GitHub Actions が AWS と GCP にデプロイする
- Terraform で staging / prod を管理している
- 本番障害対応用に break-glass principal が存在する

### 手順

#### Step 1: 入口を洗い出す
以下を表にします。

- 人間ユーザー
- CI/CD
- Terraform
- Kubernetes workload
- 監査ツール
- break-glass

各項目について次を埋めます。
- どの identity を使うか
- どこで認証するか
- 何に Assume/impersonate できるか
- その先で何ができるか

#### Step 2: AWS 側の trust policy を確認する
見るポイント:
- `Principal` が広すぎないか
- GitHub OIDC の `sub` 条件が repo / branch / environment まで絞られているか
- `sts:AssumeRole` の対象が `*` になっていないか
- prod role を staging workflow が取れないか

#### Step 3: GCP 側の service account 利用権限を確認する
見るポイント:
- `roles/iam.serviceAccountUser`
- `roles/iam.serviceAccountTokenCreator`
- deploy 用 service account が prod 専用か
- project 横断で不要な impersonation 経路がないか

#### Step 4: Terraform 実行ロールを分割する
最低でも次に分けます。
- plan と apply
- staging と prod
- app deploy と infra modify

可能なら追加で:
- prod apply は protected branch のみ
- KMS / secrets / IAM 変更は別承認

#### Step 5: 横移動ルートを 2 本書く
例:
1. CI staging role → AssumeRole broad → prod deploy role
2. developer read 権限 → service account token 作成 → prod artifact bucket 読み取り

それぞれに対して、**最小の対策を 1 つ**書きます。

### 仕上げ課題
次の質問に 5 行ずつで答えてください。

- いま一番危険な “権限そのもの” は何ですか？
- いま一番危険な “信頼関係” は何ですか？
- それを今日 1 時間で改善するなら何を変えますか？

このラボは exploit ではなく防御設計の練習です。実際の本番権限をいきなり変更しなくても、**まず見取り図を描けること**が強さになります。

---

## 5) Command cheatsheet

### Linux / general
```bash
# JSON を整形
jq . trust-policy.json

# Terraform / IAM 関連を横断検索
grep -R "AssumeRole\|PassRole\|serviceAccountTokenCreator\|oidc" .

# 差分を見る
diff -u before.json after.json

# YAML/JSON の候補を一覧
find . \( -name "*.tf" -o -name "*.json" -o -name "*.yaml" -o -name "*.yml" \)
```

### AWS IAM / STS
```bash
# 現在の identity
aws sts get-caller-identity

# ロール一覧
aws iam list-roles

# ロール詳細
aws iam get-role --role-name prod-deploy-role

# アタッチ済みポリシー
aws iam list-attached-role-policies --role-name prod-deploy-role

# インラインポリシー
aws iam list-role-policies --role-name prod-deploy-role

# 特定ポリシー version の取得
aws iam get-policy --policy-arn arn:aws:iam::123456789012:policy/prod-deploy
aws iam get-policy-version --policy-arn arn:aws:iam::123456789012:policy/prod-deploy --version-id v1
```

### GCP IAM
```bash
# 現在の認証確認
gcloud auth list

# 現在の project
gcloud config get-value project

# IAM policy 取得
gcloud projects get-iam-policy PROJECT_ID

# Service Account 一覧
gcloud iam service-accounts list

# 指定 SA のポリシー確認
gcloud iam service-accounts get-iam-policy SA_NAME@PROJECT_ID.iam.gserviceaccount.com
```

### Terraform
```bash
# フォーマット
terraform fmt -recursive

# 構文確認
terraform validate

# 実行計画
terraform plan

# state 一覧
terraform state list

# provider / module を確認
terraform providers
```

### Kubernetes / CI 観点
```bash
# 現在の context
kubectl config current-context

# ServiceAccount 一覧
kubectl get sa -A

# RoleBinding / ClusterRoleBinding の確認
kubectl get rolebinding,clusterrolebinding -A

# GitHub Actions OIDC / cloud credential の設定を探す
grep -R "id-token:\|aws-actions/configure-aws-credentials\|google-github-actions/auth" .github/
```

---

## 6) Common mistakes and how to avoid them

### ミス1: trust policy を雑に書く
**問題:** 権限本体が正しくても、想定外の principal が role を取れます。  
**回避:** repo / branch / environment / principal 条件まで絞る。

### ミス2: `PassRole` や service account impersonation を軽く見る
**問題:** 間接的な権限昇格ルートになります。  
**回避:** 「何をできるか」だけでなく「何になれるか」を棚卸しする。

### ミス3: staging と prod の Terraform 実行主体が同じ
**問題:** 検証環境の compromise がそのまま本番変更に繋がります。  
**回避:** plan/apply・環境・承認フローを分離する。

### ミス4: guardrail を個別 policy に任せる
**問題:** 将来の追加変更で簡単に崩れます。  
**回避:** SCP / Organization Policy / Boundary / Condition で上限を先に決める。

### ミス5: break-glass を通常運用で使ってしまう
**問題:** 非常口が普段の入口になります。  
**回避:** MFA・通知・期限・事後レビューを必須にする。

### ミス6: 監査ログがあれば安心だと思う
**問題:** ログは後追い確認でしかなく、横移動自体は止めません。  
**回避:** preventive control と detective control を分けて考える。

---

## 7) One interview-style question
**質問:**  
「GitHub Actions から AWS と GCP の両方へ deploy する環境があります。あなたなら、どのように trust relationship・実行ロール・環境分離・緊急時権限を設計して、staging 侵害から prod への横移動を防ぎますか？」

**考えるポイント:**
- OIDC の条件設計
- AssumeRole / impersonation の制限
- staging / prod 分離
- Terraform apply 権限の分割
- `PassRole` / token 作成権限の抑制
- break-glass の統制

---

## 8) Next-step reading links
- AWS IAM Best Practices  
  https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- AWS Policy evaluation logic  
  https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_evaluation-logic.html
- AWS IAM condition keys  
  https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_condition-keys.html
- Google Cloud IAM overview  
  https://cloud.google.com/iam/docs/overview
- Google Cloud IAM Conditions overview  
  https://cloud.google.com/iam/docs/conditions-overview
- Google Cloud service account impersonation  
  https://cloud.google.com/iam/docs/service-account-impersonation
- Terraform documentation  
  https://developer.hashicorp.com/terraform
- OWASP Cheat Sheet Series  
  https://cheatsheetseries.owasp.org/

---

## ひとこと
Advanced の IAM は、policy を書く技術というより**事故の広がり方を想像して先に柵を置く技術**です。  
派手さはないですが、ここが強い人は本番を守れます。