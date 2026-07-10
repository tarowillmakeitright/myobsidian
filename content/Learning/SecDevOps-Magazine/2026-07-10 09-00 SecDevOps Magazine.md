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
links:
  - "[[Home]]"
created: 2026-07-10 09:00
---

# SecDevOps Magazine — 2026-07-10

[[Home]]

#security #devops #docker #kubernetes #terraform #linux #cloudsecurity #observability #daily

## 今日の学習テーマ
**Cloud Security: IAM と Permission Design の基本**  
**Level: Beginner**

**学習アーク:** Cloud Security 編の 1 本目。今日は **Beginner** として、AWS/GCP の IAM を「怖い設定画面」ではなく、**事故を防ぐための設計言語**としてつかむ回です。次回このアークが Middle / Advanced に進むときは、ロール分離、cross-account / project 境界、Terraform での権限制御、監査ログ連携に進めます。

**Prerequisites:** なし（Linux の基本コマンドが少し分かれば十分）

## 1) Topic + Level
**Cloud Security (AWS/GCP IAM & Permission Design) / Beginner**

今日の焦点は、「誰が・何に・どこまでアクセスできるか」を曖昧にしないことです。  
IAM は面倒な管理作業ではなく、**クラウド事故の被害範囲を決める最重要コントロール**です。

---

## 2) Why it matters in real projects
現実のクラウド事故は、超高度な 0day だけで起きるわけではありません。むしろ多いのは、次のような **権限設計ミス** です。

- 開発者用アカウントに `AdministratorAccess` を付けっぱなし
- CI/CD が本番環境まで全部触れる
- 退職・異動後の権限剥奪が漏れる
- 1 個の access key を複数人・複数用途で使い回す
- S3 / GCS / Secret Manager / KMS へのアクセス境界が曖昧
- 「とりあえず動かす」ために広い権限を付け、そのまま定着する

これが危険なのは、アプリに脆弱性が 1 個見つかったときでも、**侵害後に attacker がどこまで横展開できるか** を IAM が決めるからです。

つまり IAM は:
- **Application Security** では被害の横展開防止
- **DevOps** では CI/CD・IaC・運用自動化の安全性確保
- **Incident Response** では影響範囲の切り分け

に直結します。

---

## 3) Core concepts

### A. Authentication と Authorization は別
- **Authentication**: あなたは誰か
- **Authorization**: あなたは何をしてよいか

IAM の本質は後者です。ログインできることと、production の secret を読めることは別問題です。

### B. Least Privilege（最小権限）
最小権限は「何もできなくする」ことではなく、**役割に必要な操作だけ許可する**ことです。

悪い例:
- 開発者全員に管理者権限
- CI 用 service account に全 project / account の書き込み権限

良い方向:
- 読み取り専用ロールを分ける
- deploy 用と audit 用で権限を分離する
- 本番変更は限定された role だけにする

### C. Human / Workload / Automation を分ける
IAM で最初に分けるべきなのは、**人間** と **機械** です。

- Human user: 管理コンソール利用、承認、調査
- Workload identity / service account: アプリやバッチ
- CI/CD identity: deploy や build 専用

1 つの identity を全部兼用すると、追跡もしづらく、事故時の切り分けも困難になります。

### D. ロールベースで考える
個人ごとにバラバラに権限を付けるより、役割でまとめる方が管理しやすいです。

例:
- `developer-readonly`
- `security-audit`
- `ci-deploy-staging`
- `platform-admin`

この考え方は AWS の IAM Role / Policy、GCP の IAM Role / Binding にそのままつながります。

### E. 永続キーより短命認証情報
access key を長期間置きっぱなしにすると漏えい時の被害が大きくなります。可能なら:
- AWS: role assume / temporary credentials
- GCP: service account impersonation / workload identity

を優先します。

**原則:** 秘密を長く持たない。必要なときだけ短く使う。

### F. Permission Boundary を意識する
権限は「許可したもの」だけでなく、**越えてはいけない境界**でも考えます。

たとえば:
- staging から production を触れない
- observability 用アカウントはログ閲覧だけ
- Terraform 実行ロールは特定の resource prefix だけ

この境界設計が、のちの **Kubernetes security** や **Terraform / IaC best practices** にそのままつながります。

### G. 監査できる設計にする
良い IAM は「安全」だけでなく、**あとから説明できる**状態です。

確認したい問い:
- 誰がこの secret を読める？
- 誰が本番へ deploy できる？
- 誰が IAM 自体を書き換えられる？
- その変更はログに残る？

監査できない権限設計は、実質的に制御できていません。

---

## 4) Hands-on mini lab (30-60 min)

### 目標
「広すぎる権限」を見つけて、「役割別の最小権限」に落とす感覚をつかみます。  
実クラウドに変更を入れなくても学べるよう、まずは **設計演習 + CLI 確認** にします。

### Lab シナリオ
あなたのチームには次の 3 役があります。

1. **Developer**: ログ閲覧、staging deploy は可。本番 IAM 変更は不可  
2. **CI/CD**: build と staging deploy は可。本番 secret 読み取りは不可  
3. **Security Auditor**: 設定・ログ閲覧は可。変更は不可

### Step 1: 権限一覧を書き出す
メモで OK なので、次の resource ごとに「誰が何をできるか」を表にします。

- Object Storage（S3 / GCS）
- Secrets（Secrets Manager / Secret Manager）
- Compute / Runtime
- IAM 自体
- Logs / Monitoring

分類は最低でもこの 3 つ:
- Read
- Write
- Admin

### Step 2: “広すぎる権限” をマーキングする
次のようなものに印を付けます。

- `*` が多すぎる
- 全 environment 共通で権限がある
- 人間と CI/CD が同じ identity を使う
- 監査専用なのに変更権限がある
- secret 読み取りが deploy より広い

### Step 3: AWS なら policy を読む
AWS CLI があるなら、手元の sandbox / 学習アカウントで読み取りだけ確認します。

```bash
aws sts get-caller-identity
aws iam list-attached-user-policies --user-name YOUR_USER_NAME
aws iam list-attached-role-policies --role-name YOUR_ROLE_NAME
aws iam get-policy --policy-arn arn:aws:iam::ACCOUNT_ID:policy/POLICY_NAME
```

見るポイント:
- `Action` が広すぎないか
- `Resource` が `*` だらけではないか
- 本当にその role に必要なものだけか

### Step 4: GCP なら binding を読む
GCP CLI があるなら、project に対する IAM binding を確認します。

```bash
gcloud config get-value project
gcloud projects get-iam-policy PROJECT_ID \
  --format="table(bindings.role, bindings.members)"
```

見るポイント:
- `roles/owner` や `roles/editor` が広く配られていないか
- 人間 user と service account が混ざっていないか
- audit / read-only 用 role が分かれているか

### Step 5: 改善案を 3 つ書く
例:
- Developer から本番 secret 読み取りを外す
- CI/CD 用 identity を staging / production で分離する
- Auditor を read-only role に統一する

### 仕上げ
最後に 1 行でまとめます。

> 「今の環境で、侵害されたら一番被害が広がる identity は何か？」

この問いに答えられるなら、学習の芯をつかめています。

---

## 5) Command cheatsheet

### Linux / 共通
```bash
whoami
env | sort
cat ~/.aws/config
cat ~/.aws/credentials
ls -la ~/.config/gcloud/
```

### AWS IAM / Identity
```bash
aws sts get-caller-identity
aws iam list-users
aws iam list-roles
aws iam list-policies --scope Local
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::ACCOUNT_ID:role/ROLE_NAME \
  --action-names s3:GetObject
```

### GCP IAM / Identity
```bash
gcloud auth list
gcloud config get-value project
gcloud projects get-iam-policy PROJECT_ID
gcloud iam service-accounts list
```

### Terraform / IaC の視点で見るコマンド
```bash
terraform fmt
terraform validate
terraform plan
grep -R "AdministratorAccess\|roles/owner\|roles/editor" .
```

### Docker / CI 周辺で確認したいこと
```bash
grep -R "AWS_ACCESS_KEY_ID\|AWS_SECRET_ACCESS_KEY\|GOOGLE_APPLICATION_CREDENTIALS" .
docker history IMAGE_NAME
```

**意味:** 今日は Docker や Terraform を深掘りする回ではないですが、IAM の事故は CI/CD や image build とつながりやすいので、横断的に確認できるようにしておくと強いです。

---

## 6) Common mistakes and how to avoid them

### ミス 1: `AdministratorAccess` / `Owner` を配りすぎる
**問題:** 速くはなるが、事故時の blast radius が大きすぎる。  
**回避:** 最初から role を分ける。少なくとも read / deploy / admin を分離する。

### ミス 2: Human と CI/CD で同じ key を使う
**問題:** 誰が何をしたか追いづらい。漏えい時の調査も地獄。  
**回避:** 人間用 identity と automation 用 identity を必ず分離する。

### ミス 3: secret を読める人が多すぎる
**問題:** アプリ脆弱性がなくても、認証情報流出で横展開される。  
**回避:** secret access は deploy 権限よりさらに絞る。必要な role だけにする。

### ミス 4: `Resource: *` を雑に使う
**問題:** 意図しない resource まで対象になる。  
**回避:** bucket 名、project、secret 名、path prefix などで対象を絞る。

### ミス 5: 権限を足す運用だけで、剥がさない
**問題:** 権限は時間とともに膨らむ。  
**回避:** 月次・四半期で review。異動・退職・プロジェクト終了時に revoke を組み込む。

### ミス 6: IAM 変更を手作業に頼る
**問題:** 再現性がなく、監査が困難。  
**回避:** 可能な範囲で Terraform など IaC に寄せる。

---

## 7) One interview-style question

**質問:**  
開発速度を落とさずに IAM の最小権限を進めたいと言われました。あなたなら、AWS または GCP でどんな順番で改善しますか？

**答えるときの観点:**
- まずどの identity を棚卸しするか
- 人間と automation をどう分離するか
- read / write / admin をどう切るか
- 監査ログと定期レビューをどう組み込むか
- 既存運用を止めずにどう段階導入するか

---

## 8) Next-step reading links

- AWS IAM User Guide  
  https://docs.aws.amazon.com/IAM/latest/UserGuide/introduction.html
- AWS Well-Architected – Security Pillar  
  https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/welcome.html
- Google Cloud IAM Overview  
  https://cloud.google.com/iam/docs/overview
- Google Cloud – Best practices for IAM  
  https://cloud.google.com/iam/docs/best-practices
- OWASP – Least Privilege Principle  
  https://owasp.org/www-community/controls/Least_Privilege_Principle
- CNCF – Cloud Native Security Whitepaper  
  https://github.com/cncf/tag-security/tree/main/security-whitepaper

---

## 今日のひとこと
IAM は地味です。でも、地味だからこそ差がつきます。  
アプリが 1 個破られても全部は倒れない――その土台を作るのが権限設計です。  
派手さはなくても、これは強いエンジニアの仕事です。