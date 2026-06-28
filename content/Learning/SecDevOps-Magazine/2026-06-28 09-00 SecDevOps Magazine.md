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

# SecDevOps Magazine — 2026-06-28

## 1) Topic + Level
**Cloud Security / AWS・GCP の IAM と権限設計入門: “とりあえず Admin” を卒業する**  
**Level: Beginner**

---

## 2) Why it matters in real projects
クラウド運用で本当に多い事故のひとつが、**機能不全ではなく権限の設計ミス**です。

たとえば現場では、こんなことが起きます。

- 開発を急ぐあまり `AdministratorAccess` に近い権限を広く配ってしまう
- CI/CD 用のサービスアカウントが、本来不要な本番リソース削除までできてしまう
- S3 bucket や GCS bucket のアクセス権が広すぎて、意図しないデータ露出につながる
- Terraform 実行用ロールが強すぎて、1 回の誤 apply で blast radius が大きくなる
- Kubernetes から cloud API を触る workload に、必要以上の IAM 権限を付けてしまう

AppSec の視点では、認証後にどこまで操作できるかは被害規模を決めます。DevOps の視点では、運用自動化・IaC・CI/CD・監視・バックアップなど、あらゆる仕組みが権限に依存しています。

つまり IAM は「後でまとめて整える管理項目」ではなく、**安全な開発速度を支える土台**です。

Beginner の今日は、難しい組織設計や federation の深掘りより前に、まず次を体に入れるのが目的です。

- 誰が
- どのリソースに
- 何をできるか
- 本当にその権限が必要か

この 4 つを言語化できるだけで、クラウドの事故率はかなり下がります。

---

## 3) Core concepts

### 3-1. IAM は “人や仕組みに鍵を配る設計”
IAM は Identity and Access Management の略です。

ざっくり言うと、
- **Who**: 誰が（人、CI/CD、アプリ、Pod、VM など）
- **What**: 何に（S3, EC2, GCS, Cloud Run, KMS など）
- **Which action**: 何を（read, write, deploy, delete, assume など）
- **Under what condition**: どんな条件で（環境、時間、IP、タグ、namespace など）

を決める仕組みです。

セキュリティの初心者は「ログインできるかどうか」で考えがちですが、本質はその後です。  
**入れた人が何をできるか** が、被害の大きさを決めます。

### 3-2. 認証と認可は別物
よく混ざる 2 つです。

- **Authentication（認証）**: あなたは誰か
- **Authorization（認可）**: あなたは何をしてよいか

たとえば SSO で AWS Console や GCP Console に入れたとしても、それは認証が通っただけです。そこから
- production bucket を読めるのか
- IAM policy を変えられるのか
- KMS key を使えるのか
- compute を削除できるのか

は認可の話です。

AppSec でも同じで、**ログイン成功 = 安全** ではありません。認可が甘いと、内部不正や credential compromise の被害が一気に広がります。

### 3-3. Least Privilege は “必要最小限だけ許す”
クラウド権限設計の基本中の基本が **Least Privilege（最小権限）** です。

考え方はシンプルです。
- 使わない操作は許可しない
- 使わないリソースには触れさせない
- 常時不要な権限は持たせない
- まず狭く与えて、足りなければ広げる

悪い例:
- 開発者全員に broad admin 権限
- CI に全環境 deploy 権限
- 監視ツールに write/delete 権限

良い方向:
- 読み取り専用は read-only に分離
- 本番 deploy 権限は限定されたロールに絞る
- バックアップ復元権限と日常運用権限を分ける

最小権限は面倒に見えますが、**事故時の被害半径を小さくする最重要設計**です。

### 3-4. AWS では Policy + Role、GCP では Principal + Role Bindings で考える
細部は違いますが、入門段階ではこう整理すると分かりやすいです。

#### AWS
- **IAM User**: 人に直接使うことは減りつつある
- **IAM Role**: 人・EC2・Lambda・EKS workload などが引き受ける権限
- **Policy**: どの action をどの resource に許すか/拒否するか

AWS は policy document をかなり細かく書けます。たとえば S3 の特定 bucket に対して `GetObject` だけ許す、のような粒度です。

#### GCP
- **Principal**: user / group / service account など
- **Role**: viewer, editor, custom role などの権限集合
- **Binding**: principal に role を結びつける

GCP は project / folder / organization など、**どの階層に role を付けるか** が大事です。上位に広く付けると、影響が広がります。

### 3-5. 人の権限とマシンの権限を分ける
初心者がよくやってしまうのが、
- 人が使う権限
- CI/CD が使う権限
- アプリが使う権限

を混ぜることです。

でも実務では、これらは目的が違います。

- **人**: 調査、レビュー、限定的な変更
- **CI/CD**: build, push, deploy
- **アプリ**: runtime で必要な read/write
- **運用ジョブ**: backup, scan, rotation

これを分けると、ある credential が漏れても全部は壊れません。  
**アイデンティティ分離は、そのまま blast radius の縮小です。**

### 3-6. “権限を配る単位” は環境ごとに分ける
最低限、次は分けたいです。

- dev
- staging
- production

dev の便利さをそのまま production に持ち込むと危険です。たとえば
- dev では broad read を許す
- prod では read-only を基本にする
- prod 変更は特定ロールと承認フローに限定する

という形です。

IaC でも同じで、Terraform 実行主体を環境ごとに分けるだけで事故を減らせます。

### 3-7. Deny, Scope, Conditions を意識する
Beginner では全部覚えなくて大丈夫ですが、次の 3 つは重要です。

- **Scope**: どの resource まで効くか
- **Action**: 何の操作を許すか
- **Condition**: どんな条件なら許すか

たとえば:
- 特定 bucket のみ
- 読み取りだけ
- 特定 tag が付いた resource のみ
- 特定 service account 経由のみ

まで絞れることがあります。

「この人は S3 を使うから S3 全部OK」ではなく、  
**どの S3 を、何の目的で、何だけできればよいか** に分解するのが大事です。

### 3-8. IAM は Kubernetes・Terraform・Secrets 管理にもつながる
今日のテーマは Cloud Security ですが、他の DevOps トラックとも直結しています。

- **Kubernetes**: workload identity / IRSA / service account 権限
- **Terraform**: apply 主体の権限が強すぎると危険
- **Secrets management**: secret を読める主体は最小化すべき
- **CI/CD security**: deploy bot に不要な delete 権限を持たせない
- **Incident response**: 緊急時の break-glass 権限を通常運用と分ける

つまり IAM を理解すると、単独の cloud topic を超えて SecDevOps 全体がつながって見えてきます。

---

## 4) Hands-on mini lab (30-60 min)
**テーマ: AWS/GCP 風の “最小権限レビュー” をローカルで練習する**

### ゴール
- broad 権限と最小権限の差を見分ける
- “誰が何に何をするか” を文章で整理できるようにする
- Terraform や Kubernetes に出てきても怖くない IAM の考え方を作る

今日は防御的・合法的な学習として、**本物の cloud 環境を壊さず** ローカルの policy review で進めます。

### Step 1: 作業ディレクトリを作る
```bash
mkdir -p ~/lab/cloud-iam-beginner
cd ~/lab/cloud-iam-beginner
```

### Step 2: AWS 風の broad policy を作る
`aws-too-broad.json`:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:*",
      "Resource": "*"
    }
  ]
}
```

### Step 3: AWS 風の narrowed policy を作る
`aws-readonly-bucket.json`:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::team-artifacts",
        "arn:aws:s3:::team-artifacts/*"
      ]
    }
  ]
}
```

### Step 4: GCP 風の role binding メモを作る
`gcp-bindings.md`:
```md
# Bad example
- principal: ci-bot@project.iam.gserviceaccount.com
- role: roles/editor
- scope: project-wide

# Better example
- principal: ci-bot@project.iam.gserviceaccount.com
- role: custom deploy role
- scope: staging project only
- allowed actions: deploy Cloud Run, read Artifact Registry, write logs
```

### Step 5: diff とレビューをする
```bash
diff -u aws-too-broad.json aws-readonly-bucket.json || true
cat gcp-bindings.md
```

### Step 6: 自分で 3 問だけ答える
ノートに次を書いてください。

1. broad policy の何が危険か  
2. narrowed policy でもまだ足りない/広すぎる点は何か  
3. CI/CD 用 principal に production 削除権限を与えない理由は何か

### Step 7: Terraform 観点の練習
`main.tf` のようなファイルがある想定で、権限に関係しそうな箇所を検索します。
```bash
grep -R "iam\|role\|policy\|service_account\|assume_role" .
```

### Step 8: Kubernetes 観点の練習
service account と cloud 権限がつながる想定で、権限レビュー観点を 3 つ書きます。
例:
- この Pod は本当に object storage write が必要か
- namespace ごとに権限を分けているか
- secret 読み取り権限が広すぎないか

### このラボの勝ち条件
今日は AWS CLI や gcloud を大量に叩くことが勝ちではありません。  
**「Admin を配る」から「目的に合った権限を設計する」へ頭を切り替えること** が勝ちです。

---

## 5) Command cheatsheet

### Linux
```bash
# 作業ディレクトリ作成
mkdir -p ~/lab/cloud-iam-beginner
cd ~/lab/cloud-iam-beginner

# JSON / Markdown 確認
cat aws-too-broad.json
cat aws-readonly-bucket.json
cat gcp-bindings.md

# 差分確認
diff -u aws-too-broad.json aws-readonly-bucket.json || true

# 権限関連キーワード検索
grep -R "iam\|policy\|role\|service_account\|assume_role\|kms" .
```

### Docker / Container 周辺で権限を考える時
```bash
# イメージ名や実行設定を確認
docker ps
docker inspect <container_id>

# Compose 定義の確認
grep -R "environment\|secrets\|volumes" docker-compose.yml compose.yaml .
```

### Kubernetes
```bash
# service account の確認
kubectl get serviceaccounts -A

# Pod がどの service account を使うか確認
kubectl get pods -A -o wide
kubectl describe pod <pod-name> -n <namespace>

# RBAC の基本確認
kubectl get roles,rolebindings,clusterroles,clusterrolebindings -A
```

### Terraform / IaC
```bash
# フォーマットと検証
terraform fmt -recursive
terraform validate

# 権限系コードの検索
grep -R "aws_iam\|google_project_iam\|google_service_account\|policy\|role" .

# 差分確認
terraform plan
```

---

## 6) Common mistakes and how to avoid them

### ミス1: とりあえず Admin を配る
**問題:** 一番速そうに見えて、事故と横展開の温床になります。  
**回避:** 最初は read-only や限定 role から始め、必要分だけ足す。

### ミス2: 人と CI/CD とアプリで同じ権限を使う
**問題:** 1 つ漏れると全部に波及します。  
**回避:** principal を分離し、用途ごとに別ロールにする。

### ミス3: dev の便利権限を prod に持ち込む
**問題:** 本番事故の blast radius が大きくなります。  
**回避:** 環境ごとに role と scope を分ける。

### ミス4: resource を `*` にしがち
**問題:** 思った以上に広く効きます。  
**回避:** bucket 名、project、service、tag、namespace などで対象を絞る。

### ミス5: read 権限は安全だと思い込む
**問題:** secrets、顧客データ、ログ、設定情報の漏えいにつながります。  
**回避:** read も機密度で考え、必要最小限にする。

### ミス6: Terraform 実行主体の権限を見ない
**問題:** IaC が正しくても、apply 主体が強すぎると危険です。  
**回避:** コードだけでなく、実行 identity の権限もレビューする。

### ミス7: 緊急用権限を常用する
**問題:** break-glass が日常化すると統制が崩れます。  
**回避:** 通常権限と緊急権限を分離し、使用履歴を残す。

---

## 7) One interview-style question
**質問:**  
「CI/CD 用のサービスアカウントに本番 deploy 権限を与える必要があります。あなたなら、AWS または GCP でどのように最小権限を考え、どの単位で権限を絞り、何を絶対に与えすぎないようにしますか？」

**考えるポイント:**
- principal を人間用と分けるか
- staging と production を分離するか
- deploy に必要な action だけに絞れるか
- secrets / IAM 管理 / delete 権限をどう扱うか
- 監査しやすい設計になっているか

---

## 8) Next-step reading links
- AWS IAM User Guide  
  https://docs.aws.amazon.com/IAM/latest/UserGuide/introduction.html
- AWS IAM policy examples  
  https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_examples.html
- Google Cloud IAM overview  
  https://cloud.google.com/iam/docs/overview
- Google Cloud best practices for IAM  
  https://cloud.google.com/iam/docs/using-iam-securely
- OWASP Authorization Cheat Sheet  
  https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Cheat_Sheet.html
- OWASP Secrets Management Cheat Sheet  
  https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html
- Kubernetes Service Accounts  
  https://kubernetes.io/docs/concepts/security/service-accounts/

---

## 今日のひとこと
強いクラウド運用は、派手な機能より先に **権限の雑さを減らすこと** から始まります。  
今日は “使える” より一段進んで、**“安全に使える” を設計する日** にしましょう。