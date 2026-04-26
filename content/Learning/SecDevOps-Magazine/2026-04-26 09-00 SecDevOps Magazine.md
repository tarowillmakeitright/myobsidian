# SecDevOps Magazine — 2026-04-26 09:00
#security #devops #docker #kubernetes #terraform #linux #cloudsecurity #observability #daily
[[Home]]

---

## 今日の学習アーク
- **Arc 1（Cloud Security）**: Beginner → Middle → Advanced
- 今日は **Day 1 / Beginner**
- 次回以降の前提（Prerequisites）:
  - **Middle 前提**: IAM policy JSONの基本構文、CLIでの検証手順
  - **Advanced 前提**: クロスアカウント設計、権限境界（Permission Boundary）、監査ログ分析

ローテーション対象（今週〜翌週で順番に回す）:
- Application Security（OWASP, secure coding, threat modeling, auth/session, incident response）
- DevOps core（Docker hardening, Kubernetes security, Terraform/IaC, Linux, CI/CD security, secrets management）
- Added tracks（Cloud Security, Observability, Kubernetes incident drills）

---

## 1) Topic + Level
**Cloud Security: AWS IAMで最小権限（Least Privilege）を設計する入門**  
**Level: Beginner**

## 2) Why it matters in real projects
実運用では「権限の広すぎるロール」が事故の起点になりがちです。  
例: `AdministratorAccess`を一時的に付与したまま放置 → 誤操作や侵害時の被害が全域に拡大。  
IAMの設計を早い段階で学ぶと、アプリ開発・CI/CD・運用のすべてで**被害半径（blast radius）を小さく**できます。

## 3) Core concepts（clear explanations）
- **Principal**: 権限を使う主体（User / Role / AWS Service）
- **Action**: 実行したいAPI操作（例: `s3:GetObject`）
- **Resource**: 対象リソース（ARN）
- **Effect**: `Allow` or `Deny`
- **Policy Evaluationの基本**:
  1. 明示的Denyが最優先
  2. Allowが無ければ暗黙的Deny
  3. 必要最小限のAction/Resourceに絞る
- **実践原則**:
  - ワイルドカード`*`をむやみに使わない
  - ロールを用途ごとに分離（app/runtime, cicd, ops）
  - 監査ログ（CloudTrail）前提で設計する

## 4) Hands-on mini lab（30-60 min）
**目標**: 「特定バケットの読み取りだけ可能」なIAM Policyを作って検証する

### 手順
1. テスト用S3バケットを作成（例: `secdevops-lab-<unique>`）
2. サンプルファイルを1つ配置
3. 以下の最小権限Policyを作る
4. テスト用IAM User/Roleにアタッチ
5. AWS CLIで `GetObject` 成功 / `PutObject` 失敗 を確認

### サンプルPolicy（読取のみ）
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ReadOnlySpecificBucket",
      "Effect": "Allow",
      "Action": ["s3:GetObject"],
      "Resource": ["arn:aws:s3:::secdevops-lab-EXAMPLE/*"]
    },
    {
      "Sid": "ListBucket",
      "Effect": "Allow",
      "Action": ["s3:ListBucket"],
      "Resource": ["arn:aws:s3:::secdevops-lab-EXAMPLE"]
    }
  ]
}
```

### 完了条件
- `aws s3 cp s3://... ./` は成功
- `aws s3 cp ./local.txt s3://...` は `AccessDenied`
- どの操作が拒否されたか理由をメモ

## 5) Command cheatsheet
```bash
# AWS認証状態確認
aws sts get-caller-identity

# バケット一覧
aws s3 ls

# オブジェクト取得（成功想定）
aws s3 cp s3://secdevops-lab-EXAMPLE/sample.txt ./sample.txt

# オブジェクトアップロード（失敗想定）
echo "test" > local.txt
aws s3 cp ./local.txt s3://secdevops-lab-EXAMPLE/local.txt

# IAMポリシーJSONの静的チェック（jq）
cat policy.json | jq .

# 監査（CloudTrailイベント確認はコンソールでも可）
aws cloudtrail lookup-events --max-results 10
```

## 6) Common mistakes and how to avoid them
- **ミス1: とりあえず `*` 許可**
  - 回避: まず操作を3つ以内に限定し、Resource ARNを明示
- **ミス2: 本番ロールで直接検証**
  - 回避: 必ず検証用ロール/アカウントでテスト
- **ミス3: Deny理由を見ない**
  - 回避: CloudTrail / エラーメッセージを記録し、再発防止に活用
- **ミス4: 権限見直しの定期運用がない**
  - 回避: 月次で不要Policyを棚卸し（CIに検査を組み込む）

## 7) One interview-style question
「`s3:GetObject` は許可しているのにダウンロードできないケースを2つ挙げ、切り分け手順を説明してください。」

## 8) Next-step reading links
- OWASP Top 10: https://owasp.org/www-project-top-ten/
- AWS IAM Best Practices: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- AWS Policy evaluation logic: https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_evaluation-logic.html
- Kubernetes Security Checklist: https://kubernetes.io/docs/concepts/security/
- OpenTelemetry Docs: https://opentelemetry.io/docs/
- Terraform Security (HashiCorp): https://developer.hashicorp.com/terraform/tutorials/cloud-get-started/cloud-security

---

次号予告（Middle）: **Cloud IAMの権限境界 + CI/CDロール分離設計**
