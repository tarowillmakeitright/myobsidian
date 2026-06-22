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

# 2026-06-22 09-00 SecDevOps Magazine

## 1) Topic + Level
**Cloud Security: IAMの基本設計とLeast Privilege入門**  
**Level: Beginner**

> 学習アーク: Cloud Security 連載の第1回（Beginner → Middle → Advanced の起点）

## 2) Why it matters in real projects
クラウド事故のかなりの割合は、難解なゼロデイよりも**権限の与えすぎ**、**共有アカウント**、**雑なロール設計**から起きます。  
AWS/GCP では「何をデプロイできるか」「誰がSecretsを読めるか」「CI/CDがどこまで本番に触れるか」がそのまま事故半径になります。

実プロジェクトでは特に次が重要です。

- 開発者に `admin` 相当を配り続けない
- CI/CD 用の権限を人間の権限と分ける
- 読み取り専用・デプロイ専用・監査専用を分離する
- インシデント時に「誰が何をしたか」を追跡できるようにする

IAM は地味ですが、**クラウド運用の土台**です。ここが雑だと、アプリが堅くても全体は脆くなります。

## 3) Core concepts
### IAM とは
IAM は **Identity and Access Management** の略です。  
「**誰が**」「**何に対して**」「**どの操作を**」できるかを定義します。

基本の見方は次の3つです。

- **Principal / Identity**: ユーザー、サービスアカウント、ロール
- **Resource**: S3 バケット、GCS バケット、Secrets、KMS、VM など
- **Action**: 読む、書く、削除する、一覧する、デプロイする

### Least Privilege
**必要最小権限**だけを与える考え方です。

悪い例:
- とりあえず `AdministratorAccess`
- CI/CD に本番全体のフル権限
- 1つのサービスアカウントを全アプリで共有

良い例:
- 読み取り専用ロールを分ける
- デプロイ用ロールは対象サービスだけ更新可能にする
- Secret 読み取りは必要なアプリだけに限定する

### Role と User を分けて考える
クラウドでは、長期固定のユーザー鍵よりも**Role / Service Account 中心**の設計が安全です。

- **人間**: SSO + 一時的な権限昇格が理想
- **アプリ**: 専用 Service Account / Role を使う
- **CI/CD**: パイプライン専用の Role を使う

### Permission Boundary を意識する
「この人は強い権限を作れるか？」まで考えるのが重要です。  
たとえば IAM を変更できる権限そのものが強すぎると、結果的に何でもできてしまいます。

### 監査可能性
強い設計は「拒否できる」だけではなく、**後から追える**ことも大切です。

- 誰が権限を付けたか
- 誰が Secret を読んだか
- 誰が本番へデプロイしたか

この観点で CloudTrail / GCP Audit Logs も後続の学習対象になります。

## 4) Hands-on mini lab (30-60 min)
### ゴール
ローカルで「権限を分ける発想」を体験します。  
今回は本番クラウドを触らなくてもできるように、**擬似 IAM 設計ラボ**として進めます。

### 準備
- Linux shell
- `mkdir`, `cat`, `grep`, `jq`（あれば便利）
- テキストエディタ

### Step 1: 作業ディレクトリ作成
```bash
mkdir -p ~/lab/iam-basics
cd ~/lab/iam-basics
```

### Step 2: 3種類の役割を定義
`roles.json` を作成:

```json
{
  "roles": [
    {
      "name": "viewer",
      "allowed": ["logs.read", "metrics.read", "storage.read"]
    },
    {
      "name": "deployer",
      "allowed": ["artifact.read", "deploy.create", "deploy.rollback"]
    },
    {
      "name": "secret-reader",
      "allowed": ["secret.read"]
    }
  ]
}
```

### Step 3: ユーザー/サービスごとの割り当て
`bindings.json` を作成:

```json
{
  "bindings": [
    {"identity": "alice", "role": "viewer"},
    {"identity": "ci-prod", "role": "deployer"},
    {"identity": "payment-api", "role": "secret-reader"}
  ]
}
```

### Step 4: 権限を目視確認
```bash
cat roles.json
cat bindings.json
```

考えてみてください。

- `alice` は本番デプロイできるか？ → できない
- `ci-prod` は Secret を読めるか？ → できない
- `payment-api` はログ閲覧できるか？ → できない

この「**分ける**」感覚が IAM 設計の第一歩です。

### Step 5: 危険な変更を試す
`ci-prod` に `secret-reader` も追加したらどうなるかを考えます。

```json
{"identity": "ci-prod", "role": "secret-reader"}
```

問い:
- CI が侵害されたら、どこまで被害が広がるか？
- デプロイ権限と Secret 読み取り権限を同居させるべきか？

### Step 6: 改善案を書く
`notes.md` を作って、次の問いに答えます。

- 本番 deployer に必要な最小権限は何か
- 読み取り専用オペレータに何を見せるべきか
- Secret を読む主体は人間かアプリか
- 緊急時の一時昇格はどうするか

### 発展（時間があれば）
AWS または GCP の公式サンプルを見て、次を調べます。

- AWS IAM policy の `Action`, `Resource`, `Effect`
- GCP IAM role と service account の違い

## 5) Command cheatsheet
### Linux
```bash
pwd
ls -la
mkdir -p ~/lab/iam-basics
cd ~/lab/iam-basics
cat roles.json
cat bindings.json
grep -n 'secret.read' roles.json
```

### jq
```bash
jq '.' roles.json
jq '.' bindings.json
jq -r '.roles[].name' roles.json
jq -r '.bindings[] | "\(.identity) -> \(.role)"' bindings.json
```

### AWS IAM（概念確認用）
```bash
aws iam list-roles
aws iam get-role --role-name ExampleRole
aws iam list-attached-role-policies --role-name ExampleRole
```

### GCP IAM（概念確認用）
```bash
gcloud projects get-iam-policy PROJECT_ID
gcloud iam service-accounts list
```

## 6) Common mistakes and how to avoid them
### ミス1: まず admin を配る
**回避策:** 最初に job function 単位で role を切る。人間・CI/CD・アプリを混ぜない。

### ミス2: 共有アカウント運用
**回避策:** 個人は個人、CI は CI、アプリはアプリで identity を分ける。監査可能性が上がります。

### ミス3: Secret 読み取りを広く付与
**回避策:** Secret は「必要なワークロードだけ」。閲覧者ロールと分離する。

### ミス4: IAM 管理権限の危険性を軽視
**回避策:** IAM を変更できる権限は超強い。付与範囲と承認フローを厳格にする。

### ミス5: CI/CD に本番フル権限
**回避策:** デプロイ対象を限定し、rollback も含めて必要最小限にする。

## 7) One interview-style question
**質問:** あるチームで、開発効率を優先して全員に `AdministratorAccess` を付けています。短期的には便利ですが、どんなリスクがあり、どのように段階的に改善しますか？

> 面接では、Least Privilege / role separation / auditability / temporary elevation をキーワードに話せると強いです。

## 8) Next-step reading links
- AWS IAM overview  
  https://docs.aws.amazon.com/IAM/latest/UserGuide/introduction.html
- AWS IAM policy elements  
  https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements.html
- Google Cloud IAM overview  
  https://cloud.google.com/iam/docs/overview
- Google Cloud service accounts overview  
  https://cloud.google.com/iam/docs/service-accounts
- OWASP Cheat Sheet Series  
  https://cheatsheetseries.owasp.org/

---

## 次号予告
次回は **Middle** レベルとして、**CI/CD 用 IAM の分離設計** か **Docker イメージ署名と supply chain 防御** に進むのがおすすめです。

**Middle の前提知識:**
- IAM の基本概念（identity / role / action / resource）
- Least Privilege の意味
- CI/CD が本番へデプロイする流れのイメージ
