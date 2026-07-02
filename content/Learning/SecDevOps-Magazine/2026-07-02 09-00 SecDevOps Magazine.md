# 2026-07-02 09-00 SecDevOps Magazine
[[Home]]

#security #devops #docker #kubernetes #terraform #linux #cloudsecurity #observability #daily

---

## 今日の学習アーク
- **Arc 2 / Beginner**
- 今週の流れ: **Cloud Security → Secrets Management → CI/CD Security**
- 7/1 の Advanced では **Kubernetes incident drills（failure / rollback / recovery）** を扱いました。
- 今日から新しい学習アークとして、**Cloud Security / AWS・GCP の IAM と permission design** を基礎から積み上げます。
- ここを弱いまま進むと、AppSec でも DevOps でも「動くけれど危ない」設計になりがちです。まずは **最小権限 (least privilege)** を、自分の手で説明できる状態にしましょう。

### Beginner の位置づけ
- まだ IAM を「ユーザーに権限を付ける仕組み」くらいにしか見えていなくても大丈夫です。
- 今日は **誰に / 何を / どこまで許すか** を整理する回です。
- 次号以降の Middle / Advanced では、service account、workload identity、CI/CD 用の権限分離、監査ログの見方へ進みます。

---

## 1) Topic + Level
**Cloud Security / AWS・GCP の IAM と permission design を最小権限から理解する**

**Level: Beginner**

---

## 2) Why it matters in real projects
クラウド事故のかなり多くは、難しいゼロデイより先に **権限の広すぎる設定** から始まります。

現場で本当によくあるのは、こんなパターンです。
- 開発を急いで `AdministratorAccess` を付けっぱなしにする
- CI/CD 用トークンに、本番インフラを全部触れる権限を与える
- 1 つの service account を複数のアプリで共用する
- S3 / GCS のアクセス境界が曖昧で、想定外の読み取りが起きる
- 「とりあえず動いた」IAM 設計を、誰も後で見直していない

IAM の設計が雑だと、攻撃者にとってはこう見えます。
- 1 つ資格情報を取れれば横展開しやすい
- 権限昇格しやすい
- 誤操作でも被害範囲が広い
- 監査時に「誰が何をできるか」が説明できない

逆に、permission design がしっかりしていると次の利点があります。
- 漏えいや誤操作が起きても **blast radius** を小さくできる
- AppSec で重要な認可設計の感覚がインフラにもつながる
- DevOps で必要な自動化を維持しつつ、危険な万能権限を減らせる
- incident 時に「どの credential を止めれば被害が止まるか」が見えやすい

IAM は地味ですが、地盤です。地盤が弱いと、Kubernetes も Terraform も CI/CD も全部不安定になります。

---

## 3) Core concepts

### A. IAM は「認証」と「認可」を分けて考える
まずここが土台です。

- **Authentication（認証）**: あなたは誰か
- **Authorization（認可）**: その人 / その仕組みは何をしてよいか

クラウドでは、ログインできること自体より、**ログインしたあと何ができるか** の設計が重要です。

### B. Permission design の基本は 4 つの問い
IAM を考えるときは、次の 4 つを毎回セットで考えます。

1. **Who**: 誰が使うのか
2. **What**: 何のリソースに触るのか
3. **Which actions**: 何の操作だけ必要か
4. **When / where / conditions**: どの条件で許すか

例:
- Who: GitHub Actions の deploy workflow
- What: 本番の特定 Artifact Registry / ECR / GKE / ECS
- Which actions: push / deploy / read logs のみ
- Conditions: main branch の release job のみ、短命 credential のみ

これが曖昧だと、だいたい権限が広くなります。

### C. Least Privilege は「最初から全部絞る」より「用途ごとに分ける」
Beginner が最初につまずきやすいのは、「最小権限 = すべての action を細かく暗記して削ること」と思い込む点です。

実務では、先に次をやるほうが強いです。
- 人間用アカウントと機械用アカウントを分ける
- 開発 / 検証 / 本番を分ける
- 読み取り専用・デプロイ専用・運用専用を分ける
- アプリごとに service account / role を分ける

つまり least privilege は、**細かい deny テクニックの前に、責務を分離する設計** です。

### D. AWS IAM と GCP IAM の見え方の違い
両方とも考え方は似ていますが、見え方が少し違います。

#### AWS のざっくり像
- principal（user / role / service）
- policy（JSON で action / resource / condition を書く）
- role を引き受ける（assume role）
- managed policy と inline policy がある

AWS では **Action と Resource を明示する感覚** が強いです。
例:
- `s3:GetObject`
- `ec2:DescribeInstances`
- `iam:PassRole`

#### GCP のざっくり像
- principal（user / group / service account）
- role（predefined / custom）
- resource hierarchy（organization / folder / project / resource）
- IAM binding で principal に role を付ける

GCP では **どの階層にどの role を付けるか** の感覚が非常に重要です。
プロジェクト全体に Editor を付けると、思った以上に広くなりがちです。

### E. Human credential と Workload credential は分ける
これは本当に大事です。

- **Human**: 管理者、開発者、SRE が使う
- **Workload**: アプリ、CI/CD、cron job、Terraform が使う

同じ credential を両方で使うと、監査も incident response も崩れます。

理想はこうです。
- 人間は SSO + MFA + 短命セッション
- workload は role / service account / workload identity
- 長期アクセスキーはできるだけ避ける

### F. Permission Boundary を「未来の事故防止」として考える
IAM は今だけでなく、将来の雑な運用を防ぐためにも使います。

たとえば:
- 開発者は sandbox では広め、本番では限定
- CI role は deploy だけ、IAM 変更は不可
- Terraform role は infra 管理用だが secrets 読み取りは不可

ここで大事なのは、**“この人なら信用できるから広くていい”** ではなく、**“事故っても被害が広がらない設計にする”** ことです。

### G. よく危ない権限
初心者のうちから危険ワードに敏感になると伸びます。

AWS の例:
- `*:*`
- `Action: "*"`
- `Resource: "*"`
- `iam:PassRole` を広く許す
- `sts:AssumeRole` を雑に広く許す
- 本番に `AdministratorAccess`

GCP の例:
- `roles/owner`
- `roles/editor`
- 共有 service account に広範な権限
- 1 つの project 全体に強い role をまとめて付与

全部が即アウトとは限りませんが、**「なぜ必要なのか説明できない強権限」は危険** と考えてください。

### H. 監査で見るべき最初の視点
IAM を学ぶときは作ることばかりに意識が向きますが、守る側では「今どうなっているか」を説明できることが重要です。

最初に見る問い:
- 管理者権限を持つ principal は誰か
- 長期 credential は残っていないか
- 退職者・未使用アカウントはないか
- CI/CD はどこまでできるか
- 本番データ読み取り権限は誰にあるか
- 監査ログで利用状況を追えるか

### I. AppSec とのつながり
IAM を学ぶと、アプリの authorization 設計も見えやすくなります。

共通する考え方:
- 「ログインできる」より「何ができるか」が本質
- 権限は役割ごとに分ける
- 過剰権限は脆弱性を大きくする
- 監査可能性が重要
- 一時的な例外権限は放置しない

つまり Cloud IAM は、インフラ版の認可設計トレーニングでもあります。

---

## 4) Hands-on mini lab (30-60 min)
### ゴール
- IAM 設計を “何となく” ではなく、用途別に分解して考える
- AWS / GCP それぞれで「広すぎる権限」を見抜く練習をする
- CI/CD 用 deploy 権限の最小単位を言語化する

### 前提
- 実際の本番アカウント変更はしない
- コンソールを見るだけでも可
- 学習用メモを残す

### Step 1: 3 種類の principal を紙か Markdown に書く
次の 3 つを分けて書きます。
- 開発者（human）
- CI/CD（machine）
- アプリ本体（workload）

それぞれについて、次を書きます。
- 何をする役割か
- どの環境に触るか
- 読み取りだけか、変更も必要か

### Step 2: 危険な “万能権限案” を先に書く
あえて雑な案を書きます。

例:
- 開発者全員に管理者権限
- CI に本番全部管理できる権限
- アプリに secrets 全読み取り権限

次に、それぞれがなぜ危険かを 1 行で書きます。

### Step 3: AWS 観点で最小化を考える
次のケースを想定します。
- CI が Docker image を ECR に push
- その後 ECS または EKS へ deploy
- S3 のアプリ設定バケットは read のみ

考えること:
- push に必要な action は何か
- deploy に必要な action は何か
- S3 は read のみで足りるか
- IAM 作成権限や広い `PassRole` は本当に必要か

### Step 4: GCP 観点で最小化を考える
次のケースを想定します。
- CI が Artifact Registry に image を push
- GKE へ deploy
- Secret Manager から特定 secret だけ読む

考えること:
- どの role を project 全体ではなく限定付与できるか
- default service account を流用していないか
- Secret Manager は特定 secret に絞れるか

### Step 5: 1 つだけ「安全な deploy role の要件」を書く
テンプレ:
```text
Deploy role requirements:
- principal:
- environment:
- allowed actions:
- explicitly not allowed:
- credential lifetime:
- audit log to review:
```

### Step 6: 監査の入口を確認する
可能なら以下を確認します。
- AWS: IAM role 一覧、Access Analyzer、CloudTrail の有無
- GCP: IAM ページ、Policy Analyzer、Cloud Audit Logs の有無

見つけたいこと:
- 強すぎる role
- 使われていない principal
- 共有されすぎた service account

### Step 7: ふりかえり
次の問いに短く答えます。
1. いちばん危険だった万能権限は何か
2. 人間用と workload 用を分ける理由は何か
3. deploy role に不要な権限は何か
4. 次に深掘りしたいのは secrets / CI/CD / Kubernetes のどれか

---

## 5) Command cheatsheet
### Linux
```bash
mkdir -p ~/lab/cloud-iam-beginner
cd ~/lab/cloud-iam-beginner
grep -R "AdministratorAccess\|roles/owner\|roles/editor\|PassRole\|AssumeRole" .
cat notes.md
printf 'principal,resource,action,condition\n' > iam-checklist.csv
date
```

### AWS CLI（読むだけの例）
```bash
aws sts get-caller-identity
aws iam list-roles
aws iam list-policies --scope Local
aws iam get-role --role-name <role-name>
aws s3 ls
aws cloudtrail describe-trails
```

### GCP CLI（読むだけの例）
```bash
gcloud auth list
gcloud config list
gcloud projects get-iam-policy <project-id>
gcloud iam service-accounts list
gcloud logging logs list
gcloud projects describe <project-id>
```

### Terraform / IaC
```bash
terraform fmt -recursive
terraform validate
grep -R "aws_iam\|google_project_iam\|google_service_account\|assume_role_policy" .
grep -R "\*\" .
```

### Kubernetes（workload identity を意識する入口）
```bash
kubectl get serviceaccounts -A
kubectl describe serviceaccount <name> -n <namespace>
kubectl get deploy -A
kubectl describe deploy <name> -n <namespace>
```

---

## 6) Common mistakes and how to avoid them
### ミス1: とりあえず管理者権限を付ける
**問題:** 速いけれど、漏えい時も誤操作時も被害が最大化します。
**回避:** まず人間用・CI 用・アプリ用を分ける。

### ミス2: 1 つの service account を何でも屋にする
**問題:** 監査しにくく、1 箇所の compromise で横展開しやすくなります。
**回避:** アプリ・job・環境ごとに分ける。

### ミス3: 長期アクセスキーを放置する
**問題:** 漏えいしても気づきにくく、回収も遅れます。
**回避:** 可能な限り短命 credential、role、workload identity を使う。

### ミス4: `PassRole` / `AssumeRole` を軽く見る
**問題:** 直接の権限が弱くても、別 role を踏み台にして強くなれることがあります。
**回避:** どの role を誰が引き受けられるかを明示的に絞る。

### ミス5: project / account 全体に role を付ける
**問題:** 本来は 1 サービスだけでよい権限が全体に広がります。
**回避:** resource scope をできるだけ狭くする。

### ミス6: default account を使い回す
**問題:** “誰のための権限か” が不明になり、後で縮めにくいです。
**回避:** 用途別に名前のある role / service account を作る。

### ミス7: 権限を作って終わる
**問題:** 使われていない強権限や、例外対応の置き忘れが残ります。
**回避:** 定期的に review し、監査ログと未使用 principal を確認する。

---

## 7) One interview-style question
**質問:**
あなたが新しい CI/CD pipeline の権限を設計するとします。AWS または GCP で、なぜ管理者権限を避けるべきか、そして deploy に必要な最小権限をどう切り出すかを説明してください。

**考える観点:**
- human credential と machine credential の分離
- push / deploy / read secret の切り分け
- resource scope の狭め方
- audit log と credential lifetime の考え方
- compromise 時の blast radius

---

## 8) Next-step reading links
- AWS IAM User Guide: https://docs.aws.amazon.com/IAM/latest/UserGuide/introduction.html
- AWS IAM policy examples: https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_examples.html
- AWS IAM Access Analyzer: https://docs.aws.amazon.com/IAM/latest/UserGuide/what-is-access-analyzer.html
- Google Cloud IAM overview: https://cloud.google.com/iam/docs/overview
- Google Cloud best practices for using service accounts: https://cloud.google.com/iam/docs/best-practices-service-accounts
- Google Cloud Policy Intelligence overview: https://cloud.google.com/policy-intelligence/docs/overview
- OWASP Authorization Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Cheat_Sheet.html
- OWASP Secrets Management Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html
- Kubernetes Service Accounts: https://kubernetes.io/docs/concepts/security/service-accounts/
- Terraform IAM patterns (AWS provider docs entry point): https://registry.terraform.io/providers/hashicorp/aws/latest/docs

---

## 次号予告
**Middle 予告:** Secrets Management を、環境変数・Secret Manager・Kubernetes Secret・CI/CD の注入経路という実務線で整理します。

### Middle の前提知識
- least privilege の意味を説明できる
- human / CI / workload の権限を分ける理由が分かる
- AWS/GCP で “広すぎる権限” の例をいくつか挙げられる

次号では、今日の IAM 設計を土台にして、**「正しい権限があっても secret の扱いが雑だと危ない」** という現実に進みます。