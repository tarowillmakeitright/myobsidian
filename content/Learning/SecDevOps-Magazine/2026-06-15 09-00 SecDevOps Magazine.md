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

# 2026-06-15 09-00 SecDevOps Magazine

## 1) Topic + Level
**Cloud Security: AWS/GCP IAM と Permission Design 入門**  
**Level: Beginner**

> 学習アーク: Cloud Security 1/3  
> 次回予定: Middle（複数ロール設計 / least privilege の分解 / Terraform への落とし込み）  
> 前提知識: なし

## 2) Why it matters in real projects
IAM の設計は、クラウド環境の「土台のセキュリティ」です。アプリケーションに脆弱性がなくても、権限が広すぎれば事故は起きます。たとえば以下のようなケースです。

- 開発者に `AdministratorAccess` を渡したまま本番運用してしまう
- CI/CD 用の Service Account が不要な削除権限まで持っている
- 一時的に付けた強い権限を戻し忘れ、横展開で定着する
- 監査時に「誰が何をできるのか」を説明できない

現場では、**機能を動かすこと**と同じくらい、**誰に何を許すかを明確に設計すること**が重要です。IAM が雑だと、侵害時の被害範囲が一気に広がります。逆に言えば、permission design がうまいチームは、障害にもインシデントにも強いです。

## 3) Core concepts
### IAM とは
IAM（Identity and Access Management）は、**誰が（identity）何に対して（resource）どんな操作を（action）できるか**を制御する仕組みです。

基本の見方はこの3つです。

- **Principal / Identity**: User, Role, Group, Service Account
- **Action**: `s3:GetObject`, `ec2:StartInstances`, `storage.objects.get` など
- **Resource**: バケット、VM、Secrets、DB など

### Least Privilege
**Least Privilege（最小権限）** は、「必要な操作だけを許可する」考え方です。  
重要なのは、単に権限を減らすことではなく、**業務に必要な範囲を言語化してから付与すること**です。

悪い例:
- 「動かないと困るから admin を渡す」

良い例:
- 「CI は container image を push できればよい」
- 「アプリはこの Secret を読むだけでよい」
- 「運用担当は本番 DB を削除できなくてよい」

### AWS と GCP のざっくり違い
#### AWS
- User / Group / Role / Policy の組み合わせで表現する
- 人間より **Role 中心** で考えると整理しやすい
- 実務では IAM Role + AssumeRole + managed/custom policy が基本線

#### GCP
- Principal に対して **Role を binding する** イメージが強い
- Project 単位で広く付けすぎる事故が起きやすい
- predefined role / custom role / service account の設計が重要

### 人間用権限とマシン用権限を分ける
これはかなり大事です。

- **Human access**: 開発者・運用者のログイン権限
- **Workload access**: アプリ、CI、Job、Function の実行権限

この2つを混ぜると、監査も事故調査も難しくなります。  
特に **Service Account や Role をアプリ単位で分ける** のは、後のインシデント対応で効いてきます。

### Permission Design の最初の型
初心者のうちは、まずこの型を守ると崩れにくいです。

1. **主体を分ける**  
   開発者、CI、アプリ、本番運用、監査を分離する
2. **環境を分ける**  
   dev / staging / prod で権限境界を作る
3. **操作を分ける**  
   read / write / deploy / admin / delete を混ぜない
4. **期限を意識する**  
   一時権限は永続化しない
5. **監査可能にする**  
   「なぜこの権限が必要か」を説明できる状態にする

## 4) Hands-on mini lab (30-60 min)
### ゴール
「静的なアクセスキーをばらまかず、用途ごとに権限を分ける」感覚をつかむ。

### ラボ概要
ローカルで IAM 設計メモを作り、Terraform 風の構造と CLI の確認観点を整理する。  
本番アカウント変更は不要。**安全に設計練習だけ行う**。

### 手順
#### Step 1: 3種類の主体を書く
ノートか Markdown に次を書き出します。

- `developer-readonly`
- `ci-image-pusher`
- `app-secret-reader`

それぞれについて、以下を1行で書きます。

- 何者か
- 何をするか
- 何をしてはいけないか

例:
- `ci-image-pusher`: CI がコンテナレジストリへ push する。VM 削除や Secret 読み取りは不要。

#### Step 2: 権限の境界を表にする
| Principal | Needed Actions | Not Needed |
|---|---|---|
| developer-readonly | list / describe / read logs | delete, rotate secrets |
| ci-image-pusher | push image | read prod secrets, delete infra |
| app-secret-reader | read one secret | list all secrets, change IAM |

#### Step 3: Terraform 風に分離してみる
以下のようなファイル構成を想像して、どこで role/policy を定義するか決めます。

```text
infra/
  iam/
    developers.tf
    ci.tf
    app.tf
```

それぞれに「1ファイル1責務」を意識して、誰向けの権限かを分離してください。

#### Step 4: AWS または GCP の閲覧コマンドだけ触る
もし手元に CLI が入っていて安全な環境があるなら、**参照系だけ** 実行します。

AWS 例:
```bash
aws sts get-caller-identity
aws iam list-roles --max-items 10
```

GCP 例:
```bash
gcloud auth list
gcloud config list
gcloud projects list --limit=5
```

#### Step 5: 振り返り
最後にこの問いに答えます。

- 一番危ない「まとめ権限」はどれか？
- CI に admin を渡したくなる理由は何か？
- それを避けるには、どの permission を明示すべきか？

## 5) Command cheatsheet
### Linux
```bash
whoami
pwd
mkdir -p infra/iam
cd infra/iam
ls -la
cat developers.tf
```

### AWS CLI
```bash
aws sts get-caller-identity
aws iam list-roles --max-items 10
aws iam list-policies --scope Local --max-items 10
```

### GCP CLI
```bash
gcloud auth list
gcloud config list
gcloud projects list --limit=5
gcloud iam roles list --limit=10
```

### Terraform (concept check)
```bash
terraform fmt
terraform validate
terraform plan
```

> 注意: `terraform apply` はこのラボでは不要です。今日は「設計を言語化する日」です。

## 6) Common mistakes and how to avoid them
### ミス1: とりあえず admin を渡す
**回避:** まず必要操作を verbs で列挙する。`read` / `write` / `deploy` / `delete` を混ぜない。

### ミス2: 人間とアプリで同じ権限を使う
**回避:** Human access と Workload access を別管理にする。Service Account / Role を用途ごとに分離する。

### ミス3: dev と prod の境界がない
**回避:** 環境ごとに principal を分ける。少なくとも production は別ロールにする。

### ミス4: Secret 読み取り権限が広すぎる
**回避:** 「1アプリが読む Secret は何か」を先に定義する。`list all` を避け、個別参照を意識する。

### ミス5: 監査説明ができない
**回避:** 権限ごとに一言コメントを書く。  
例: `ci-image-pusher = build artifact を registry に push するため`

## 7) One interview-style question
**質問:** ある開発チームが「運用を楽にするため」に CI/CD パイプラインへ広い管理者権限を付与しています。なぜ危険ですか？ また、最小権限に近づけるにはどんな分解をしますか？

**考えるポイント:**
- CI compromise 時の blast radius
- deploy 権限と infra admin 権限の分離
- secrets access の最小化
- environment ごとの権限分離

## 8) Next-step reading links
- AWS IAM concepts  
  <https://docs.aws.amazon.com/IAM/latest/UserGuide/introduction.html>
- AWS IAM best practices  
  <https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html>
- Google Cloud IAM overview  
  <https://cloud.google.com/iam/docs/overview>
- Google Cloud best practices for permissions  
  <https://cloud.google.com/iam/docs/using-iam-securely>
- Terraform IAM patterns (HashiCorp docs entry point)  
  <https://developer.hashicorp.com/terraform>
- OWASP Cheat Sheet Series  
  <https://cheatsheetseries.owasp.org/>

---

## 明日の予告
次号は **DevOps core** か **Observability** の Beginner レベルに進めると流れがきれいです。  
学習アークを意識して、Beginner → Middle → Advanced を繰り返しながら、実務で使える筋力を育てていきましょう。
