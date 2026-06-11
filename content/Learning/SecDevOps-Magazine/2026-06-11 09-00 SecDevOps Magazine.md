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
---

# 2026-06-11 SecDevOps Magazine

[[Home]]

#security #devops #docker #kubernetes #terraform #linux #cloudsecurity #observability #daily

## 今日のテーマ + Level
**Cloud Security: IAM と Permission Design の基礎 — Beginner**

> 学習アーク: **Cloud Security 1/3**
> 
> - Day 1: Beginner — IAM の基本と最小権限
> - Day 2: Middle — Role 分離、Terraform での権限設計
> - Day 3: Advanced — 権限昇格パス分析と監査設計

**前提知識:**
- Beginner なので必須前提はなし
- あると楽: Linux で `cat`, `grep`, `less` が使えること

---

## 1) なぜ実務で重要か
クラウド事故のかなりの割合は、脆弱なゼロデイよりも**権限の広すぎる設定**や**Secrets の扱いミス**から起きます。

たとえば実務では、こんな問題が頻出です。

- 開発用ユーザーに本番環境の Admin 権限が残っている
- CI/CD 用の Service Account が万能すぎる
- 退職・異動後の権限剥奪が遅れる
- S3 / GCS / Secret Manager へのアクセスが広すぎる
- 「とりあえず動かすため」に `*` を使い、そのまま定着する

IAM は地味ですが、**被害の大きさを直接左右するコントロール**です。
アプリケーションセキュリティ視点でも、認証後に何ができるかを決めるのは結局 Permission Design です。つまり IAM を理解すると、Cloud Security だけでなく **Auth / Session Security、Incident Response、DevOps 運用**まで全部つながってきます。

---

## 2) Core concepts

### A. Authentication と Authorization の違い
- **Authentication**: 「あなたは誰か」を確認する
- **Authorization**: 「あなたは何をしてよいか」を決める

IAM で特に大事なのは後者です。ログインできること自体より、**何が許可されているか**が事故を決めます。

### B. Principal / Role / Policy
クラウドによって名称は少し違いますが、考え方はほぼ共通です。

- **Principal**: ユーザー、グループ、Service Account、Role を引き受ける主体
- **Role**: 権限のまとまり
- **Policy**: 何を許可 / 拒否するかを書いたルール

ざっくり言うと、
**「誰に」「どの役割を」「どの条件で」与えるか**を設計するのが IAM です。

### C. Least Privilege（最小権限）
必要な操作だけ許可し、それ以外は与えない原則です。

悪い例:
- 開発者全員に `AdministratorAccess`
- CI に全リソース操作権限
- 読み取りだけでいい監視ツールに書き込み権限

良い例:
- ECR push 専用 Role
- S3 の特定バケット read-only
- Terraform apply 用 Role を環境ごとに分離

### D. Human / Workload / CI の分離
権限設計では、主体を混ぜないことが重要です。

- **Human**: 開発者、SRE、監査者
- **Workload**: アプリ、API、バッチ、Kubernetes Pod
- **CI/CD**: GitHub Actions, GitLab CI, Jenkins など

この 3 つを混ぜると、誰が何をしたのか見えにくくなり、事故対応が一気に難しくなります。

### E. 常時権限より一時権限
長寿命 Access Key より、以下を優先します。

- AWS STS の一時クレデンシャル
- GCP Workload Identity / 短寿命トークン
- SSO + Role Assume

理由はシンプルで、**漏れても被害時間を短くできる**からです。

### F. Permission Boundary を“業務単位”で考える
権限は人ベースではなく、業務ベースで考えると設計しやすくなります。

例:
- App Developer: アプリログ閲覧、非本番 deploy
- Security Reviewer: 設定閲覧、監査ログ閲覧
- Incident Responder: 緊急時のみ本番参照
- CI Pipeline: コンテナ push、限定的な deploy

### G. Deny の扱い
多くの環境で **明示的 Deny は Allow より強い**です。

これは事故防止に強力です。
たとえば:
- 本番 Secret の削除を Deny
- IAM Policy 自体の改変を限定
- 監査ログ停止を Deny

### H. ログと監査
IAM は設定して終わりではありません。
最低でも以下が必要です。

- 誰がいつ Assume Role したか
- 誰が Policy を変更したか
- どの Service Account がどの API を呼んだか
- 失敗したアクセス試行

AWS なら CloudTrail、GCP なら Cloud Audit Logs が基本です。

---

## 3) Hands-on mini lab（30–60分）
**テーマ:** 「広すぎる権限」を見つけて、最小権限に落とす練習

このラボはローカルでできます。実クラウド課金は不要です。

### ゴール
1. まず“危ない IAM 設計”を読む
2. どこが危ないか説明できるようになる
3. 最小権限ポリシーに書き直す
4. 監査観点を 3 つ挙げる

### Step 1: 作業ディレクトリを作る
```bash
mkdir -p ~/labs/iam-basics
cd ~/labs/iam-basics
```

### Step 2: 危ない AWS 例を作る
```bash
cat > aws-bad-policy.json <<'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "*",
      "Resource": "*"
    }
  ]
}
EOF
```

### Step 3: 危ない GCP 例をメモする
```bash
cat > gcp-bad-design.md <<'EOF'
# Bad Design
- CI service account に Project Editor を付与
- 本番と開発で同じ service account を共有
- Secret Manager への access を全開発者に許可
EOF
```

### Step 4: 問題点を洗い出す
以下を自分の言葉で `findings.md` に書いてください。

```bash
cat > findings.md <<'EOF'
# Findings
- Action=* / Resource=* は過剰権限
- CI と人間ユーザーの境界がない
- 環境分離がない
- Secret 参照範囲が広すぎる
- 監査時に責任追跡が難しい
EOF
```

### Step 5: 改善版ポリシーを書く
例として、ECR push 専用にかなり限定します。

```bash
cat > aws-better-policy.json <<'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:BatchCheckLayerAvailability",
        "ecr:CompleteLayerUpload",
        "ecr:InitiateLayerUpload",
        "ecr:PutImage",
        "ecr:UploadLayerPart"
      ],
      "Resource": "arn:aws:ecr:ap-northeast-1:123456789012:repository/sample-app"
    },
    {
      "Effect": "Allow",
      "Action": "ecr:GetAuthorizationToken",
      "Resource": "*"
    }
  ]
}
EOF
```

### Step 6: 比較レビュー
```bash
diff -u aws-bad-policy.json aws-better-policy.json || true
```

### Step 7: 監査観点を整理する
`audit-checklist.md` を作ります。

```bash
cat > audit-checklist.md <<'EOF'
# Audit Checklist
- 誰がこの権限を使うのか（Human / Workload / CI）
- 本当に必要な Action だけか
- 本番・開発の分離があるか
- 長寿命キーを使っていないか
- 変更ログが残るか
EOF
```

### ラボの達成条件
- `*:*` が危険な理由を説明できる
- “どの業務に必要な権限か”を言語化できる
- 最小権限の改善案を 1 つ書ける
- 監査ログで何を見るべきか答えられる

---

## 4) Command cheatsheet

### Linux
```bash
pwd
ls -la
mkdir -p ~/labs/iam-basics
cd ~/labs/iam-basics
cat file.json
less file.json
grep -n 'Action\|Resource\|Effect' aws-bad-policy.json
sort file.txt | uniq
find . -maxdepth 2 -type f
```

### AWS / IAM の考え方確認用
```bash
# 実行例イメージ（認証済み環境で使う）
aws sts get-caller-identity
aws iam list-roles
aws iam get-role --role-name ExampleRole
aws iam list-attached-role-policies --role-name ExampleRole
aws cloudtrail lookup-events --max-results 10
```

### GCP / IAM の考え方確認用
```bash
# 実行例イメージ（認証済み環境で使う）
gcloud auth list
gcloud config list
gcloud projects get-iam-policy PROJECT_ID
gcloud iam service-accounts list
gcloud logging read 'protoPayload.serviceName="iam.googleapis.com"' --limit=10
```

### Terraform（将来の Middle 回でつながる）
```bash
terraform init
terraform fmt
terraform validate
terraform plan
```

---

## 5) Common mistakes and how to avoid them

### ミス1: とりあえず Admin を配る
**なぜ起きる?**
- 納期が近い
- エラー解消を急ぐ
- 権限設計が面倒

**避け方:**
- 一時的な昇格は期限付き
- 恒久権限は Role 単位で見直す
- まず read-only から始める

### ミス2: 人間・CI・アプリで同じ資格情報を使う
**なぜ危険?**
- 誰の操作か追えない
- 漏えい時の影響範囲が広い

**避け方:**
- 主体ごとに Service Account / Role を分ける
- 用途名を明確にする（例: `ci-prod-deploy-role`）

### ミス3: 長寿命 Access Key を放置する
**なぜ危険?**
- 漏えい検知が遅れやすい
- 無効化忘れが起きやすい

**避け方:**
- SSO / Assume Role / Workload Identity を使う
- どうしても鍵が必要ならローテーション期限を決める

### ミス4: Secret を権限設計の外に置く
**なぜ危険?**
- IAM が厳しくても Secret 配布が雑だと終わる

**避け方:**
- Secret Manager / Parameter Store を使う
- “誰が読めるか”を権限レビュー対象に入れる

### ミス5: 監査ログを見ない
**なぜ危険?**
- 侵害後の調査で詰む
- 誤設定の発見が遅れる

**避け方:**
- CloudTrail / Audit Logs の確認を運用手順に入れる
- Policy 変更イベントを重点監視する

---

## 6) Interview-style question
**Q.** CI/CD 用の Service Account に強い権限を付けると便利ですが、なぜ危険で、どう設計すると現実的ですか？

**考えるポイント:**
- CI が侵害されたときの blast radius
- 本番 / 開発の分離
- push, deploy, secret read を分離できるか
- 短寿命認証を使えるか
- 監査可能性をどう担保するか

---

## 7) Next-step reading links
- OWASP Top 10: https://owasp.org/www-project-top-ten/
- OWASP Authorization Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Cheat_Sheet.html
- AWS IAM Best Practices: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- AWS Well-Architected Security Pillar: https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/welcome.html
- GCP IAM Overview: https://cloud.google.com/iam/docs/overview
- GCP Best Practices for IAM: https://cloud.google.com/iam/docs/using-iam-securely
- Terraform Recommended Practices: https://developer.hashicorp.com/terraform
- Kubernetes RBAC Concepts: https://kubernetes.io/docs/reference/access-authn-authz/rbac/

---

## 8) 明日の予告
次回の Cloud Security アークは **Middle**。
予定テーマは **「Terraform で IAM を管理するときの安全な分離設計」** です。

前提知識:
- 今日の Beginner 回を理解していること
- `terraform init / plan / validate` の流れを軽く知っていること
- “人間 / CI / Workload を分ける”発想があること

その次の回では **Advanced** として、
**権限昇格パスの洗い出し、監査ログの見方、Incident Response で優先して止めるべき権限** まで進めます。
