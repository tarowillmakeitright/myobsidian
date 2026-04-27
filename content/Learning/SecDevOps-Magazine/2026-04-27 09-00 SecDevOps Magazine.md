# SecDevOps Magazine — 2026-04-27 09:00
#security #devops #docker #kubernetes #terraform #linux #cloudsecurity #observability #daily
[[Home]]

---

## 今日の学習アーク
- **Arc 1（Cloud Security）**: Beginner → Middle → Advanced
- 今日は **Day 2 / Middle**
- **Prerequisites（この号の前提）**:
  - IAM policy JSONの基本構文を読める
  - `Allow` / `Deny` / 暗黙的Deny の評価順を説明できる
  - AWS CLIで許可/拒否を最低1回ずつ検証した経験
- **Advanced 予告の前提**:
  - クロスアカウント設計（AssumeRole）
  - Permission Boundary / SCPの使い分け
  - CloudTrailでの追跡と監査メモ作成

ローテーション対象（継続）:
- Application Security（OWASP, secure coding, threat modeling, auth/session, incident response）
- DevOps core（Docker hardening, Kubernetes security, Terraform/IaC, Linux, CI/CD security, secrets management）
- Added tracks（Cloud Security, Observability, Kubernetes incident drills）

---

## 1) Topic + Level
**Cloud Security: CI/CD用IAMロール分離とPermission Boundaryの実践**  
**Level: Middle**

## 2) Why it matters in real projects
実案件では、CI/CDパイプラインが「デプロイ権限の集中点」です。ここが広すぎると、
- 誤ったPRで本番リソースを削除
- 侵害されたCIトークンで権限横展開
- 監査時に「誰が何を変更したか」を証明しにくい
といった問題が起きます。

**ロール分離 + Permission Boundary** を導入すると、開発速度を落とさずに被害半径を小さくできます。

## 3) Core concepts（clear explanations）
- **Role分離**:
  - `ci-plan-role`（読み取り中心、差分確認）
  - `ci-apply-role`（限定的な書き込み）
  - `ops-breakglass-role`（緊急時のみ、強制MFA/短時間）
- **Trust Policy**:
  - どのPrincipalが`sts:AssumeRole`できるかを定義
  - OIDC（GitHub Actions等）では`sub`/`aud`条件で絞る
- **Permission Boundary**:
  - 「このロールは最大でもここまで」という上限ガード
  - 誤って強いPolicyを追加しても境界外は実行不可
- **条件付き制御（Condition）**:
  - `aws:RequestedRegion`で許可リージョン限定
  - `aws:ResourceTag`で対象リソースをタグで限定
  - `aws:PrincipalTag`で職務分離を強化

## 4) Hands-on mini lab（30-60 min）
**目標**: Terraform実行用Roleを2段階化し、Boundaryで過剰権限を防ぐ

### 手順
1. `ci-plan-role` と `ci-apply-role` を作成（Trust Policyは同じOIDC provider）
2. `ci-apply-role` に最小の実行Policyを付与（例: 特定タグ付きS3とCloudWatchのみ）
3. `permission-boundary-ci.json` を作成し、`ec2:*` や `iam:*` を明示的に不可にする
4. `ci-apply-role` にPermission Boundaryを設定
5. AWS CLIでシミュレーション実施
   - 想定操作（許可）: `s3:PutObject`（対象バケットのみ）
   - 想定操作（拒否）: `ec2:TerminateInstances`

### サンプルBoundary（抜粋）
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowLimitedServices",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    },
    {
      "Sid": "DenyPrivilegeEscalation",
      "Effect": "Deny",
      "Action": [
        "iam:*",
        "ec2:*",
        "organizations:*"
      ],
      "Resource": "*"
    }
  ]
}
```

### 完了条件
- `simulate-principal-policy`で許可/拒否の結果が設計通り
- CIロールに`AdministratorAccess`が不要なことを確認
- 「どの事故を防ぐ設計か」を1段落で説明できる

## 5) Command cheatsheet
```bash
# 誰として実行しているか
aws sts get-caller-identity

# ロールのTrust Policy確認
aws iam get-role --role-name ci-apply-role \
  --query 'Role.AssumeRolePolicyDocument' --output json

# アタッチ済みポリシー確認
aws iam list-attached-role-policies --role-name ci-apply-role

# Permission Boundary確認
aws iam get-role --role-name ci-apply-role \
  --query 'Role.PermissionsBoundary' --output json

# 許可シミュレーション（S3 Put想定）
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::123456789012:role/ci-apply-role \
  --action-names s3:PutObject \
  --resource-arns arn:aws:s3:::secdevops-lab-EXAMPLE/app.tfstate

# 拒否シミュレーション（EC2削除想定）
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::123456789012:role/ci-apply-role \
  --action-names ec2:TerminateInstances \
  --resource-arns '*'

# ポリシーJSON整形
jq . permission-boundary-ci.json
```

## 6) Common mistakes and how to avoid them
- **ミス1: Plan/Applyを同一ロールで実行**
  - 回避: 読み取り主体の`plan`と書き込み主体の`apply`を分離
- **ミス2: Boundaryを付けずに最小権限だけで満足**
  - 回避: 「将来の誤付与」対策としてBoundaryを必ず併用
- **ミス3: Trust Policyが広すぎる（repo全体許可）**
  - 回避: OIDC `sub` をブランチ/環境単位で制限
- **ミス4: 検証なしで本番反映**
  - 回避: `simulate-principal-policy`をCIの前段に組み込む

## 7) One interview-style question
「Permission BoundaryとSCPはどちらも“制限”ですが、責務の違いは何ですか？CI/CDロール設計で両方をどう併用しますか？」

## 8) Next-step reading links
- AWS IAM policy evaluation logic: https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_evaluation-logic.html
- Permissions boundaries for IAM entities: https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_boundaries.html
- IAM best practices: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- Terraform security best practices: https://developer.hashicorp.com/terraform/tutorials/cloud-get-started/cloud-security
- Kubernetes RBAC: https://kubernetes.io/docs/reference/access-authn-authz/rbac/
- OpenTelemetry docs: https://opentelemetry.io/docs/

---

次号予告（Advanced）: **クロスアカウントIAM設計 + 監査ログ主導のインシデント追跡**
