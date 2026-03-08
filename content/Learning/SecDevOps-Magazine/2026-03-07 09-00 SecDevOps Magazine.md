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

# SecDevOps Magazine — 2026-03-07

## 1) Topic + Level
**Topic:** Cloud Security（AWS IAM & Permission Design の基本）  
**Level:** **Beginner**

> 学習アーク: Beginner → Middle → Advanced の3日サイクルで進行。  
> 明日の予定（Middle）: IAM Policy の条件付き制御 + Terraform での権限分離。  
> 明後日の予定（Advanced）: クロスアカウント設計とインシデント対応（権限誤設定の封じ込め）。

---

## 2) Why it matters in real projects
クラウド事故の多くは、実装バグよりも**権限設計ミス**で起きます。  
例: 「開発用ロールに本番S3削除権限が残っていた」「CI が過剰権限で全リソースを操作できた」。

IAM を正しく設計できると、次の効果があります。
- 侵害されても被害範囲（blast radius）を小さくできる
- 監査対応（誰が何をできるかの説明）がしやすい
- DevOps の自動化（CI/CD, Terraform）を安全に回せる

---

## 3) Core concepts（clear explanations）
### A. Principle of Least Privilege（最小権限）
「必要な操作だけ許可する」。`Action` と `Resource` を絞るのが基本。

### B. Identity と Role の分離
- **Human user**: 直接強い権限を持たせない
- **Role**: 用途ごと（app, ci, ops）に分離し、引き受け（assume）で使う

### C. Explicit Deny の強さ
IAM は `Deny` が `Allow` より優先。事故防止ガードレールに有効。

### D. 条件（Condition）で縛る
IP, MFA, タグ、時間帯などで制約可能。実務ではここが差になる。

### E. 監査ログ前提の運用
CloudTrail / GCP Audit Logs を前提に「後で追える設計」にする。

---

## 4) Hands-on mini lab（30-60 min）
**Goal:** 「読み取り専用ロール」と「限定S3書き込みロール」を作り、差を体感する。

### Step 0: 準備（5分）
- AWS CLI インストール
- Sandbox アカウント（本番不可）
- `aws configure` で接続設定

### Step 1: 読み取り専用ポリシー作成（10分）
`readonly-s3-policy.json`
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:ListAllMyBuckets", "s3:GetObject", "s3:ListBucket"],
      "Resource": ["arn:aws:s3:::*", "arn:aws:s3:::*/*"]
    }
  ]
}
```

### Step 2: 限定書き込みポリシー作成（10分）
`write-limited-policy.json`
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:PutObject"],
      "Resource": "arn:aws:s3:::secdevops-lab-bucket/*"
    },
    {
      "Effect": "Deny",
      "Action": ["s3:DeleteObject", "s3:DeleteBucket"],
      "Resource": "*"
    }
  ]
}
```

### Step 3: ポリシー適用と検証（15-20分）
- Role を2つ作成（`lab-readonly-role`, `lab-write-role`）
- それぞれで `aws s3 cp` / `aws s3 rm` を試す
- 期待通りに失敗するか確認（失敗ログが学習ポイント）

### Step 4: ふりかえり（5分）
- 「できること / できないこと」を表にする
- 過剰権限があったら修正

---

## 5) Command cheatsheet
### Linux
```bash
# JSON整形確認
cat readonly-s3-policy.json | jq .

# 直近コマンドの見直し
history | tail -n 20
```

### AWS CLI
```bash
# ポリシー作成
aws iam create-policy \
  --policy-name SecDevOpsReadOnlyS3 \
  --policy-document file://readonly-s3-policy.json

aws iam create-policy \
  --policy-name SecDevOpsWriteLimited \
  --policy-document file://write-limited-policy.json

# 自分の実行主体確認
aws sts get-caller-identity
```

### Terraform（参考）
```hcl
resource "aws_iam_policy" "write_limited" {
  name   = "SecDevOpsWriteLimited"
  policy = file("write-limited-policy.json")
}
```

### Docker/Kubernetes（次回につながる確認コマンド）
```bash
docker scout quickview
kubectl auth can-i get pods --all-namespaces
```

---

## 6) Common mistakes and how to avoid them
1. **`Resource: "*"` を多用する**  
   - 回避: まず対象 ARN を具体化。例外時だけ短期で広げ、期限を切る。

2. **人間ユーザーに長期 Access Key を持たせ続ける**  
   - 回避: Role + 一時クレデンシャルへ移行。

3. **CI に管理者権限を渡す**  
   - 回避: CI 専用ロールを作り、必要 Action のみ許可。

4. **Deny ガードレールを入れていない**  
   - 回避: 重大操作（削除・権限変更）に明示 Deny を検討。

5. **ログを見ないまま運用する**  
   - 回避: CloudTrail の定期レビューを sprint タスク化。

---

## 7) One interview-style question
「あなたが新規プロジェクトで AWS IAM を設計するとき、`admin` 権限を最初から配らずに開発速度を落とさないために、どんなロール分割と運用ルールを提案しますか？」

---

## 8) Next-step reading links
- OWASP Top 10: https://owasp.org/www-project-top-ten/
- AWS IAM Best Practices: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- AWS Well-Architected Security Pillar: https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/welcome.html
- Terraform IAM patterns（HashiCorp docs）: https://developer.hashicorp.com/terraform/docs
- Kubernetes RBAC: https://kubernetes.io/docs/reference/access-authn-authz/rbac/
- OpenTelemetry Overview: https://opentelemetry.io/docs/
- Prometheus Docs: https://prometheus.io/docs/
- Grafana Docs: https://grafana.com/docs/

---

次号予告: **Middle**（前提: 今日の IAM 基本と JSON policy が読めること）  
テーマ候補: 「CI/CD Security と Secrets Management の実践（OIDC + 短期資格情報）」