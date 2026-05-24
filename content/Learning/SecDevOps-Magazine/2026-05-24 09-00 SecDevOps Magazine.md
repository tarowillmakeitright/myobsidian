---
tags: [security, devops, docker, kubernetes, terraform, linux, cloudsecurity, observability, daily]
---

# SecDevOps Magazine — 2026-05-24 (09:00)
[[Home]]

## 学習アーク進行（Beginner → Middle → Advanced）
- **Arc 1（Cloud Security + IAM）**
  - Day 1: Beginner（今日）
  - Day 2: Middle（前提: IAM基礎、least privilegeの設計経験）
  - Day 3: Advanced（前提: 組織/マルチアカウント運用、監査ログ運用）
- **Arc 2（Observability）**
  - Day 4: Beginner
  - Day 5: Middle（前提: metrics/logs/tracesの基本理解）
  - Day 6: Advanced（前提: SLO/SLI設計、障害対応経験）
- **Arc 3（Kubernetes Incident Drills）**
  - Day 7: Beginner
  - Day 8: Middle（前提: kubectl運用、Deployment/Service基礎）
  - Day 9: Advanced（前提: rollback戦略、障害復旧手順の実務経験）

> ローテーション対象トラック（継続反映）: secure coding, OWASP, threat modeling, auth/session security, incident response, Docker hardening, Kubernetes security/fundamentals, Terraform/IaC, Linux mastery, CI/CD security, secrets management, Cloud Security, Observability, K8s incident drills

---

## 1) Topic + Level
**Cloud Security (AWS/GCP IAM & permission design) + Application Security連携**
**Level: Beginner**

## 2) Why it matters in real projects
本番事故の多くは「コードの脆弱性」だけでなく、**過剰なIAM権限**から被害が拡大します。  
たとえばアプリの1つのAPIキー漏えいでも、IAMが`*`権限ならDB・ストレージ・CI/CDまで横展開されます。  
逆に、最小権限（least privilege）と職務分離が効いていれば、侵害範囲を局所化できます。

## 3) Core concepts
- **Principal（主体）**: 人間ユーザー/ロール/サービスアカウント
- **Permission（許可）**: 何を実行できるか（例: `s3:GetObject`, `storage.objects.get`）
- **Resource（対象）**: どのリソースに対してか（bucket, project, secret など）
- **Condition（条件）**: 時間、IP、タグ、MFA有無など
- **Least Privilege**: 必要最小限の権限のみ付与
- **Deny by default**: 明示許可がない限り拒否
- **Separation of Duties**: 開発・承認・デプロイ権限を分離

Application Securityとの接点:
- セッションハイジャック/SSRF/CIトークン漏えい時の横移動防止
- Incident Response時の「どこまで到達可能か」をIAMで即判断

## 4) Hands-on mini lab (30-60 min)
**目標:** 「読み取り専用ロール」と「危険な管理権限」を比較し、差分を理解する。  

### 手順
1. AWSまたはGCPでテスト用プロジェクト/アカウントを用意（本番禁止）。
2. 読み取り専用ロールを作成
   - AWS: `ReadOnlyAccess` + 対象絞り込み
   - GCP: `Viewer` + プロジェクト限定
3. わざと強すぎるロール（管理者相当）を別途作成（検証専用）
4. それぞれの認証情報で以下を試す
   - バケット一覧取得
   - Secret参照
   - IAM変更
5. どこまでできるかを比較表に記録
6. 最後に強権限ロールを削除し、監査ログを確認

**完了条件:**
- 「必要操作だけできる」権限セットを1つ作れる
- 不要権限を3つ以上削れた理由を説明できる

## 5) Command cheatsheet
```bash
# Linux: 現在の資格情報を確認
env | grep -E 'AWS|GOOGLE|KUBE|TF_VAR'

# AWS IAM (例)
aws sts get-caller-identity
aws iam list-attached-role-policies --role-name my-readonly-role
aws s3 ls

# GCP IAM (例)
gcloud auth list
gcloud projects get-iam-policy <PROJECT_ID>
gsutil ls

# Terraform: 権限定義のコード化
terraform init
terraform plan
terraform apply

# K8s文脈（将来のincident drill用）
kubectl auth can-i get secrets -n default
kubectl auth can-i create clusterrole
```

## 6) Common mistakes and how to avoid them
- **ミス:** `AdministratorAccess`を恒久付与  
  **回避:** break-glass用に限定し、通常運用ロールを分離
- **ミス:** 人間ユーザーに長期キーを発行し続ける  
  **回避:** SSO + 短期トークン運用へ移行
- **ミス:** CI/CDに過剰権限を渡す  
  **回避:** デプロイ対象ごとにロール分離、OIDC federation活用
- **ミス:** 監査ログを見ない  
  **回避:** CloudTrail / Cloud Audit Logs に定期アラート

## 7) One interview-style question
「あなたが運用中のWebアプリで、CIトークン漏えいが発生したと仮定します。IAM設計だけで“被害半径”をどう最小化しますか？具体的に3つの制御策を挙げてください。」

## 8) Next-step reading links
- OWASP Top 10: https://owasp.org/www-project-top-ten/
- AWS IAM best practices: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- Google Cloud IAM overview: https://cloud.google.com/iam/docs/overview
- Kubernetes RBAC: https://kubernetes.io/docs/reference/access-authn-authz/rbac/
- Terraform security best practices (HashiCorp): https://developer.hashicorp.com/terraform/tutorials/security

---

次号予告（Middle）: **Cloud IAMの権限境界（Permission Boundary / Custom Role）とCI/CD分離設計**  
前提: IAMの基本概念（Principal/Permission/Resource/Condition）を説明できること。
