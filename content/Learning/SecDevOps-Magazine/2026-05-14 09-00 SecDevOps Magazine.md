---
tags: [security, devops, docker, kubernetes, terraform, linux, cloudsecurity, observability, daily]
---

[[Home]]

# SecDevOps Magazine — 2026-05-14

> 今日のテーマは **Cloud Security（AWS/GCP IAM & Permission Design）**。  
> 学習アークは Beginner → Middle → Advanced を循環させます。

## 学習アーク進行状況（ローテーション）
- Day 1（今日）: Cloud Security / **Beginner**
- Day 2: Application Security（OWASP + Secure Coding）/ **Middle**（前提: 入力検証・認証の基礎）
- Day 3: DevOps Core（Kubernetes Incident Drill）/ **Advanced**（前提: kubectl基礎・Deployment/Service理解）
- Day 4: Observability / **Beginner**
- Day 5: CI/CD Security / **Middle**（前提: GitHub ActionsまたはGitLab CIの基礎）
- Day 6: Terraform IaC Security / **Advanced**（前提: Terraform state/backend/workspace理解）

---

## 1) Topic + Level
**Cloud Security: IAM最小権限設計 入門（AWS/GCP） — Beginner**

## 2) Why it matters in real projects
本番事故の多くは「攻撃そのもの」より、**過剰権限** から拡大します。  
例: 読み取りだけのはずのCIユーザーが `AdministratorAccess` を持っていて、漏えい時に全リソース操作される。  
IAMを最小権限で設計すると、侵害されても被害半径（blast radius）を小さくできます。

## 3) Core concepts（要点）
- **Identity（誰が）**: User / Role / Service Account
- **Permission（何を）**: Action（例: `s3:GetObject`, `storage.objects.get`）
- **Resource（どこに）**: 対象ARN/リソースパス
- **Condition（いつ・どこから）**: IP、MFA、有効時間、タグ条件
- **Least Privilege（最小権限）**: 必要な操作だけ許可、ワイルドカード `*` を減らす
- **Separation of Duties（職務分離）**: デプロイ権限と監査権限を分ける

## 4) Hands-on mini lab（30–60 min）
### ゴール
「ログ閲覧専用ロール」を作り、不要な権限を削って検証する。

### 手順（AWS例）
1. CloudWatch Logs 読み取り用ポリシーを作成（`logs:FilterLogEvents`, `logs:GetLogEvents` のみ）
2. 対象Log GroupをResourceで限定
3. テスト用Roleにアタッチ
4. `aws iam simulate-principal-policy` で許可/拒否を確認
5. `Resource: *` を限定版に修正し、再テスト

### 手順（GCP例）
1. プロジェクトにカスタムロール作成（Log Viewer相当を最小化）
2. サービスアカウントへ付与
3. `gcloud projects get-iam-policy` で過剰権限を棚卸し
4. 不要ロール削除、再確認

## 5) Command cheatsheet
```bash
# Linux: 権限確認の基本
id
whoami

# AWS IAM: アタッチ済みポリシー確認
aws iam list-attached-role-policies --role-name my-log-reader-role

# AWS IAM: ポリシーシミュレーション
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::123456789012:role/my-log-reader-role \
  --action-names logs:GetLogEvents logs:DeleteLogGroup \
  --resource-arns arn:aws:logs:ap-northeast-1:123456789012:log-group:/prod/api:*

# GCP IAM: IAMポリシー確認
gcloud projects get-iam-policy my-project-id --format=json

# Terraform: IAM変更の差分確認
terraform plan
terraform show
```

## 6) Common mistakes and how to avoid them
- **ミス:** `Action: "*"` を常用  
  **回避:** まず監査ログで実際に必要なActionを抽出してから許可。
- **ミス:** 人間ユーザーに長期Access Keyを配布  
  **回避:** Role引受け/Workload Identity/Federationを優先。
- **ミス:** 共有管理者アカウント運用  
  **回避:** 個人ID + 監査証跡 + MFA必須化。
- **ミス:** Terraformで手動変更を放置（drift）  
  **回避:** 定期 `terraform plan` とPRレビュー。

## 7) Interview-style question
「CI/CD用サービスアカウントに `AdministratorAccess` が付いています。短期で安全性を上げる現実的な移行手順を、ダウンタイム最小で説明してください。」

## 8) Next-step reading links
- OWASP Top 10: https://owasp.org/www-project-top-ten/
- AWS IAM Best Practices: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- Google Cloud IAM Overview: https://cloud.google.com/iam/docs/overview
- Kubernetes Security Checklist: https://kubernetes.io/docs/concepts/security/
- OpenTelemetry Docs: https://opentelemetry.io/docs/

---

### 明日の予告（Middle）
**Application Security: Threat Modeling + OWASP Broken Access Control**  
前提知識: HTTP基礎、認証/認可の違い、基本的なCRUD API設計。
