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

# SecDevOps Magazine — 2026-05-02

## 1) Topic + Level
**Cloud Security（AWS/GCP IAM & Permission Design） + Beginner**

> 学習アーク: **Beginner → Middle → Advanced**（3日サイクル）
> - Day 1（今日）: IAMの基本設計（Beginner）
> - Day 2: 最小権限の実装と検証（Middle）
> - Day 3: クロスアカウント/組織ポリシー設計と監査対応（Advanced）

---

## 2) Why it matters in real projects
本番障害や情報漏えいの多くは、アプリのバグだけでなく**権限設定ミス**から起きます。  
たとえば「開発用ユーザーに本番S3の削除権限が残っていた」「CIが過剰権限キーを持っていた」など。  
IAMを正しく設計できると、事故の**発生確率**と**影響範囲**を同時に下げられます。

---

## 3) Core concepts（clear explanations）

### 3.1 認証(Authentication)と認可(Authorization)
- **Authentication**: あなたが誰かを確認（User/Role/Service Account）
- **Authorization**: 何をしてよいかを決定（Policy/Role Binding）

### 3.2 最小権限（Least Privilege）
- 必要な操作だけ許可する
- `*`（ワイルドカード）や広すぎる管理者権限を避ける

### 3.3 IAM設計の基本単位
- **AWS**: IAM User / Role / Policy / Group
- **GCP**: Principal / Role / IAM Policy

### 3.4 人間ユーザーと機械ユーザーを分離
- 人間: SSO + MFA前提
- 機械（CI/CD, App）: ロール引受・短命クレデンシャル優先

### 3.5 Denyの意味
- 明示的Denyは強い（Allowより優先）
- 「例外を最初に決める」設計が事故防止に効く

---

## 4) Hands-on mini lab（30-60 min）
**目的**: 「読み取り専用アクセス」を最小権限で作る感覚をつかむ

### Lab A（AWS CLI）
1. 読み取り専用ポリシーJSONを作成
2. テスト用Roleにアタッチ
3. `simulate-principal-policy` で権限確認

```bash
cat > read-only-s3-policy.json <<'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:ListBucket"],
      "Resource": [
        "arn:aws:s3:::example-bucket",
        "arn:aws:s3:::example-bucket/*"
      ]
    }
  ]
}
EOF

aws iam create-policy \
  --policy-name ExampleS3ReadOnlyPolicy \
  --policy-document file://read-only-s3-policy.json

aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::<ACCOUNT_ID>:role/<ROLE_NAME> \
  --action-names s3:ListBucket s3:GetObject s3:DeleteObject \
  --resource-arns arn:aws:s3:::example-bucket arn:aws:s3:::example-bucket/test.txt
```

### Lab B（GCP gcloud）
1. プロジェクト単位でViewer系ロールを付与
2. 付与後に権限確認

```bash
PROJECT_ID="your-project-id"
MEMBER="user:you@example.com"

# 例: Storage Object Viewer を付与
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="$MEMBER" \
  --role="roles/storage.objectViewer"

# 確認
gcloud projects get-iam-policy "$PROJECT_ID" \
  --flatten="bindings[].members" \
  --filter="bindings.members:$MEMBER" \
  --format="table(bindings.role)"
```

> 余力があれば: 「Delete系操作が拒否される」ことを必ず検証する。

---

## 5) Command cheatsheet

### Linux
```bash
# JSON整形
cat policy.json | jq .

# 直近操作履歴確認
history | tail -n 20
```

### AWS IAM
```bash
aws iam list-policies --scope Local
aws iam get-policy --policy-arn <POLICY_ARN>
aws iam list-attached-role-policies --role-name <ROLE_NAME>
aws iam simulate-principal-policy --policy-source-arn <ROLE_ARN> --action-names s3:GetObject
```

### GCP IAM
```bash
gcloud projects get-iam-policy <PROJECT_ID>
gcloud projects add-iam-policy-binding <PROJECT_ID> --member=user:a@b.com --role=roles/viewer
gcloud projects remove-iam-policy-binding <PROJECT_ID> --member=user:a@b.com --role=roles/viewer
```

### Terraform（IAMの原則）
```bash
terraform init
terraform fmt
terraform validate
terraform plan
```

---

## 6) Common mistakes and how to avoid them
1. **最初からAdmin権限を付与する**  
   - 回避: まずReadOnlyで開始し、足りない権限だけ追加
2. **人間とCIで同じ資格情報を使う**  
   - 回避: Principalを分離し、ローテーション方針を別管理
3. **検証せず本番反映する**  
   - 回避: `simulate` / `plan` / stagingで先に確認
4. **長期アクセスキーを放置**  
   - 回避: 短命トークン化 + 定期失効チェック
5. **誰がどの権限を持つか見えない**  
   - 回避: 定期監査（週次）と権限棚卸し

---

## 7) One interview-style question
「あなたのチームで“開発速度を落とさずに最小権限を実現する”なら、IAM設計・運用フロー・監査をどう組み合わせますか？」

---

## 8) Next-step reading links
- OWASP Top 10: https://owasp.org/www-project-top-ten/  
- AWS IAM Best Practices: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html  
- GCP IAM Overview: https://cloud.google.com/iam/docs/overview  
- CIS Benchmarks（Cloud/Kubernetes/Linux）: https://www.cisecurity.org/cis-benchmarks  
- OpenTelemetry Docs: https://opentelemetry.io/docs/  
- Kubernetes Security Checklist: https://kubernetes.io/docs/concepts/security/overview/

---

## Progression note（for upcoming issues）
次号は **Middle** として、以下を扱います（Prerequisiteあり）:
- **予定テーマ**: Observability（Prometheus/Grafana/OpenTelemetry）でのセキュリティ監視設計
- **Prerequisites**:
  - Linux基本コマンド（grep, awk, journalctl）
  - コンテナの基本概念（image/container/volume/network）
  - IAMの基本（今日の内容）

この調子で、毎日1トピックずつ「守れる実装力」を積み上げていこう。小さく作って、必ず検証するのが最短ルート。