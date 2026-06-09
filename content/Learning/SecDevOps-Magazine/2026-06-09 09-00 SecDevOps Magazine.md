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
date: 2026-06-09
series: SecDevOps Magazine
level: Beginner
topic: Cloud Security
---

# 2026-06-09 09-00 SecDevOps Magazine

#security #devops #docker #kubernetes #terraform #linux #cloudsecurity #observability #daily

[[Home]]

## 1) Topic + Level
**Cloud Security: AWS/GCP IAM と Permission Design 入門**  
**Level: Beginner**

> 学習アーク: Cloud Security 基礎編の 1 本目。次回の Middle では「複数ロール設計と Terraform での IAM 管理」、Advanced では「クロスアカウント/組織設計・権限境界・監査対応」に進む想定です。

## 2) Why it matters in real projects
IAM 設計は、クラウドにおける「玄関の鍵」と「部屋ごとの入室権限」を同時に決める作業です。ここを雑にすると、次のような事故が起きます。

- 開発者に本番の削除権限があり、うっかり重要リソースを消す
- CI/CD 用のサービスアカウントが強すぎて、漏えい時に被害が拡大する
- 監査で「誰が何にアクセスできるのか説明できない」
- 緊急時に権限が複雑すぎて復旧が遅れる

実務では、**速く作ること**と**安全に運用すること**を両立する必要があります。だからこそ IAM は後回しではなく、最初に整える価値があります。

## 3) Core concepts

### 3-1. Identity と Permission は別で考える
- **Identity**: 人間ユーザー、サービスアカウント、ロールなど「誰が」
- **Permission**: その identity が「何をできるか」

この 2 つを混ぜると設計が崩れます。まず主体を分け、その後で必要最小限の権限を付けます。

### 3-2. Least Privilege（最小権限）
基本原則はシンプルです。

- 必要な人に
- 必要な操作だけ
- 必要な対象に対して
- 必要な期間だけ

たとえば「S3 バケットを読むだけでよい CI ジョブ」に `AdministratorAccess` を付けるのは典型的な過剰権限です。

### 3-3. Human と Machine を分ける
- **Human**: 開発者、運用者、監査担当
- **Machine**: CI/CD、アプリ本体、バックアップ、監視

人と機械で権限の性質が違います。人には MFA や一時昇格、機械には短命クレデンシャルや限定ロールが向いています。

### 3-4. Role-based design
最初から個人ごとに細かく付与し始めると破綻します。まずは役割ベースで考えます。

例:
- `dev-readonly`
- `dev-deploy-staging`
- `prod-incident-readonly`
- `ci-terraform-plan`

「人に権限を与える」より、**ロールを設計してそこに人やシステムを乗せる**方が運用しやすいです。

### 3-5. Scope を絞る
Permission は 3 方向で絞れます。

- **Action**: 何ができるか（read/list/get/update/delete など）
- **Resource**: どの対象か（特定バケット、特定プロジェクト、特定 namespace）
- **Condition**: どんな条件か（IP、タグ、時刻、MFA、有効期限）

### 3-6. AWS と GCP のざっくり対応
- **AWS IAM User / Role / Policy**
- **GCP Principal / Service Account / IAM Role / Binding**

違いはありますが、考え方はほぼ同じです。

- 主体を明確にする
- 権限を役割でまとめる
- 強い権限は少数に限定する
- 監査しやすい形にする

## 4) Hands-on mini lab (30-60 min)
**目的:** 「読み取り専用」と「限定的なデプロイ権限」を分けて考える練習をする

### 想定シナリオ
あなたは小さな Web アプリを運用しています。

- 開発者 A: ログ閲覧はしたい
- CI/CD: staging へのデプロイだけしたい
- 誰にも本番削除権限は渡したくない

### 手順

#### Part 1: 権限表を作る（15 分）
下の表をノートに埋めます。

| Identity | Needed Actions | Forbidden Actions | Scope |
|---|---|---|---|
| developer | read logs, read metrics | delete infra, modify prod IAM | staging/prod read-only |
| ci-deployer | deploy app to staging | access prod DB, change IAM | staging only |
| incident-reader | read prod status/logs | write/change/delete | prod read-only |

ポイントは、**できることより、させないことも書く**ことです。

#### Part 2: AWS の最小例を読む（10 分）
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
        "arn:aws:s3:::example-app-logs",
        "arn:aws:s3:::example-app-logs/*"
      ]
    }
  ]
}
```

考えること:
- なぜ `PutObject` が入っていないのか
- なぜ対象バケットが限定されているのか
- もし `"Resource": "*"` にしたら何が起きるか

#### Part 3: GCP のロール付与を読む（10 分）
```bash
gcloud projects add-iam-policy-binding my-staging-project \
  --member="serviceAccount:ci-deployer@my-staging-project.iam.gserviceaccount.com" \
  --role="roles/container.developer"
```

考えること:
- なぜ人間ユーザーではなくサービスアカウントか
- staging project 限定にする意味は何か
- `roles/owner` を付けると何が危険か

#### Part 4: Terraform で表現してみる（15-20 分）
```hcl
resource "aws_iam_policy" "app_logs_readonly" {
  name        = "app-logs-readonly"
  description = "Read-only access to application logs bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::example-app-logs",
          "arn:aws:s3:::example-app-logs/*"
        ]
      }
    ]
  })
}
```

できればここまで考えてみてください。
- 本番用と staging 用をどう分けるか
- `plan` 実行者と `apply` 実行者を分けるべきか
- 監査しやすい命名規則は何か

## 5) Command cheatsheet

### Linux
```bash
# 認証情報が環境変数にベタ置きされていないか確認
env | grep -Ei 'aws|gcp|google|secret|token|key'

# シェル履歴に秘密情報を入れない意識づけ
history | tail -n 20

# 権限設計メモを素早く作る
mkdir -p labs/iam && cd labs/iam
touch iam-notes.md
```

### AWS CLI
```bash
# 現在の呼び出し主体を確認
aws sts get-caller-identity

# アタッチ済みポリシー確認（例）
aws iam list-attached-role-policies --role-name ci-deployer

# インラインポリシー確認（例）
aws iam list-role-policies --role-name ci-deployer
```

### GCloud CLI
```bash
# 現在の認証主体を確認
gcloud auth list

# プロジェクト IAM ポリシー確認
gcloud projects get-iam-policy my-staging-project

# サービスアカウント一覧
gcloud iam service-accounts list
```

### Terraform
```bash
# フォーマット
terraform fmt

# 構文チェック
terraform validate

# 変更確認
terraform plan
```

## 6) Common mistakes and how to avoid them

### ミス 1: とりあえず Admin を付ける
**問題:** 最短で動くが、後で剥がせなくなる。  
**回避:** 最初に read-only / deploy / incident などの基本ロールを作る。

### ミス 2: 人と CI/CD に同じ権限を渡す
**問題:** 監査しづらく、漏えい時の影響範囲も大きい。  
**回避:** human と machine を必ず分離する。

### ミス 3: 本番と staging を同じ権限境界で扱う
**問題:** テスト用権限が本番に流れ込む。  
**回避:** 環境単位で scope を分ける。アカウント/プロジェクト分離も検討する。

### ミス 4: Resource を `*` にしがち
**問題:** 意図しないリソースまで触れる。  
**回避:** まず対象を限定し、必要になったら広げる。

### ミス 5: 長寿命キーを放置する
**問題:** 漏えいしても気づきにくい。  
**回避:** 可能な限りロール引き受け、短命トークン、Workload Identity を使う。

## 7) One interview-style question
**質問:** ある CI/CD パイプラインが staging へデプロイするだけなのに、`AdministratorAccess` を持っています。どんなリスクがあり、どう設計し直しますか？

**考える観点:**
- 侵害時の blast radius
- IAM 変更権限の有無
- 本番リソースへの横展開
- staging 専用ロール化
- deploy に必要な action/resource だけへ絞る

## 8) Next-step reading links
- OWASP Cheat Sheet Series: Authorization Cheat Sheet  
  https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Cheat_Sheet.html
- AWS IAM Best Practices  
  https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- Google Cloud IAM Overview  
  https://cloud.google.com/iam/docs/overview
- Terraform IAM patterns (AWS Provider docs 起点)  
  https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- Google Cloud: Best practices for enterprise organizations  
  https://cloud.google.com/docs/enterprise/best-practices-for-enterprise-organizations

---

## 明日の予告
次号候補（ローテーション）:
- **Middle:** Observability — Prometheus / Grafana / OpenTelemetry の最小構成
- **Middle:** Docker Hardening — rootless, capability, image provenance
- **Beginner:** Kubernetes Incident Drill — Pod 障害の見方と rollback の基礎

継続のコツは、**1 日 1 テーマを深くやること**です。広く触って終わりではなく、今日の 1 本を「手を動かして理解した」に変えていきましょう。
