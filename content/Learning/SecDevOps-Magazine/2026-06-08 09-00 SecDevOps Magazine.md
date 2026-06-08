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

# SecDevOps Magazine — 2026-06-08

## 1) Topic + Level
**Cloud Security: IAM設計の基本と最小権限の考え方**  
**Level: Beginner**

---

## 2) Why it matters in real projects
AWS/GCP では、設定ミスそのものがインシデントになります。特に IAM は「便利だから広く許可する」をやると、開発速度は一時的に上がっても、事故の爆発半径が一気に広がります。

実務ではこんな場面で効きます。
- 開発者に本番権限をそのまま渡さない
- CI/CD に必要最低限の権限だけを付ける
- Terraform 実行用ロールを分離する
- 監査ログから「誰が何をしたか」を追えるようにする
- 侵害後の lateral movement を防ぐ

IAM は「クラウドの root of trust に一番近い運用」です。ここが雑だと、アプリが安全でも全体は危ういです。

---

## 3) Core concepts

### IAM の目的
IAM (Identity and Access Management) は、**誰が**、**何に対して**、**どこまで** 操作できるかを制御する仕組みです。

### 最小権限 (Least Privilege)
必要な操作だけ許可し、それ以外は許可しない考え方です。

悪い例:
- `AdministratorAccess` を人にも CI にも配る
- `*:*` をとりあえず付ける

良い例:
- S3 の特定バケットだけ読み書き
- Cloud Run / ECS デプロイ専用ロール
- Terraform 用に対象リソース範囲を限定

### 人とマシンの権限を分ける
- **Human identity**: 開発者、運用者、監査者
- **Workload identity**: CI/CD、アプリ、バッチ、Kubernetes Pod

この2つを混ぜると追跡性と安全性が崩れます。

### ロールベースで考える
個人ごとに細かく権限を盛るより、役割で分けます。

例:
- `developer-readonly-prod`
- `staging-deployer`
- `terraform-network-admin`
- `incident-responder`

### 永続鍵より一時クレデンシャル
長寿命 Access Key は漏えい時に危険です。可能なら次を優先します。
- AWS IAM Role / STS
- GCP Service Account + short-lived token
- OIDC federation (GitHub Actions → cloud)

### Deny / 境界 / 条件付き許可
単純な Allow だけでなく、条件で縛るのが重要です。
- 特定リージョンだけ許可
- MFA 必須
- 特定タグ付きリソースだけ許可
- 本番への変更は承認済み経路のみ

### 監査ログ
- AWS: CloudTrail
- GCP: Cloud Audit Logs

権限設計は「使える」だけでなく「追える」ことも大事です。

---

## 4) Hands-on mini lab (30-60 min)
**テーマ: 「広すぎる権限」を「最小権限」に落とす練習**

### ゴール
CI/CD が S3 バケットへアーティファクトをアップロードするケースを想定し、広すぎるポリシーを修正します。

### 想定環境
- AWS CLI が入っている手元環境
- ダミーのバケット名を使う
- 実環境がなければ、JSON ポリシー比較だけでも十分学べます

### 手順

#### Step 1: 悪い例を見る
以下のような過剰権限を読む。

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

考えるポイント:
- 何ができすぎる？
- 侵害されたらどこまで被害が広がる？

#### Step 2: 必要操作を洗い出す
CI が本当に必要なのは例えば以下だけ。
- `s3:PutObject`
- `s3:GetObject`
- `s3:ListBucket`

対象も限定。
- バケット: `my-app-artifacts`
- プレフィックス: `releases/*`

#### Step 3: 最小権限ポリシーを書く

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:ListBucket"],
      "Resource": "arn:aws:s3:::my-app-artifacts"
    },
    {
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:PutObject"],
      "Resource": "arn:aws:s3:::my-app-artifacts/releases/*"
    }
  ]
}
```

#### Step 4: さらに改善する
次の観点でレビュー。
- 削除権限 `s3:DeleteObject` は本当に必要か？
- 本番と staging を分離しているか？
- CI 用ロールは人が Assume できないか？

#### Step 5: 振り返り
1. 必要な Action は何だったか
2. Resource を `*` から具体化できたか
3. 人とマシンの権限を分離できたか

---

## 5) Command cheatsheet

### Linux
```bash
cat policy.json
jq . policy.json
grep -R "AdministratorAccess\|\*:\*\|Resource\": \"\*\"" .
```

### AWS CLI
```bash
aws iam list-roles
aws iam get-role --role-name my-ci-role
aws iam list-attached-role-policies --role-name my-ci-role
aws iam get-policy --policy-arn arn:aws:iam::123456789012:policy/my-policy
aws iam get-policy-version --policy-arn arn:aws:iam::123456789012:policy/my-policy --version-id v1
```

### Terraform (IAM を IaC 化する時の基本)
```bash
terraform init
terraform fmt
terraform validate
terraform plan
```

### 参考: GCP で見るコマンド
```bash
gcloud projects get-iam-policy PROJECT_ID
gcloud iam service-accounts list
```

---

## 6) Common mistakes and how to avoid them

### ミス1: とりあえず Admin を配る
**回避:** まず必要操作を列挙してから権限化する。最初から広げない。

### ミス2: 人と CI が同じ資格情報を使う
**回避:** Human role と workload identity を分離する。責任境界を明確にする。

### ミス3: `Resource: "*"` を放置する
**回避:** バケット、パス、プロジェクト、サービスアカウント単位まで絞る。

### ミス4: 長寿命キーを GitHub Secrets に置きっぱなし
**回避:** OIDC federation や short-lived token を優先する。

### ミス5: 権限を追加するだけで棚卸ししない
**回避:** 四半期ごとに unused permissions と role の用途をレビューする。

### ミス6: Incident 用の緊急権限が通常運用に混ざる
**回避:** break-glass role を分け、利用時は監査と承認を必須にする。

---

## 7) One interview-style question
「CI/CD 用ロールに `AdministratorAccess` を付けるのが危険な理由を、最小権限・監査性・侵害時影響範囲の3点で説明してください。」

---

## 8) Next-step reading links
- OWASP Cheat Sheet Series: Authorization Cheat Sheet  
  https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Cheat_Sheet.html
- AWS IAM Best Practices  
  https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- Google Cloud IAM Overview  
  https://cloud.google.com/iam/docs/overview
- Terraform IAM policy resources (AWS provider docs)  
  https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- CIS Benchmarks overview  
  https://www.cisecurity.org/cis-benchmarks

---

## 学習アークメモ
今回の号は **Beginner**。次の流れで難易度を上げる想定です。

1. **Beginner**: IAM と最小権限の基本
2. **Middle**: CI/CD と OIDC federation、Terraform での権限分離
   - **Prerequisites:** IAM の基本、ロール/ポリシー、Terraform の基本操作
3. **Advanced**: マルチアカウント権限設計、permission boundary、incident 対応用 break-glass 設計
   - **Prerequisites:** 中級の CI/CD 権限設計、監査ログ、組織単位のアクセス制御理解

明日は Middle 寄りで、**CI/CD security × Cloud IAM** か **Docker hardening** に進めると流れがきれいです。
