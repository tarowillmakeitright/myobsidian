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

# SecDevOps Magazine — 2026-03-31 09:00
[[Home]]

## 1) Topic + Level
**Cloud Security（AWS IAM最小権限設計）+ Terraform IaC ガードレール**
**Level: Beginner**

> この号は学習アークの **Beginner** 回です。次回以降は Middle → Advanced と段階的に進みます。

## 2) Why it matters in real projects
本番事故の多くは「ハッキングそのもの」より、**過剰権限（`*` 権限）** や **誤設定の放置** から始まります。

- 開発スピード優先で `AdministratorAccess` を付ける
- CI/CD 用ロールに不要な権限を持たせる
- 誰が何をできるか可視化できていない

この状態だと、1つの認証情報漏えいが**横展開（lateral movement）**を招き、S3・KMS・EKS まで連鎖的に影響します。

**最小権限（Least Privilege）** と **IaC（Terraform）での再現可能な管理** は、セキュリティと開発速度を同時に守る土台です。

## 3) Core concepts（clear explanations）
### A. IAM の基本3点
- **Principal**: 誰が（ユーザー/ロール/サービス）
- **Action**: 何を（`s3:GetObject` など）
- **Resource**: どこに対して（特定の ARN）

この3つを明示して、必要最小限に絞るのが基本です。

### B. Deny が最優先
IAM ポリシー評価では **明示的 Deny が Allow より強い**。
「原則禁止 + 必要分だけ許可」が安全設計の王道です。

### C. Terraform で権限を“コード化”する意味
- 変更履歴が残る（レビュー可能）
- 手作業ドリフトを減らせる
- 監査で「なぜこの権限か」を説明しやすい

### D. AppSec 接続ポイント
アプリ脆弱性（SSRF, RCE 等）があっても、実行ロールが最小権限なら被害半径を限定できます。
**AppSec と Cloud Security は分離できない**、という視点が重要です。

## 4) Hands-on mini lab（30–60 min）
**目標:** 「読み取り専用 S3 アクセスロール」を Terraform で作り、過剰権限を避ける

### 手順
1. Terraform プロジェクト作成
2. 特定バケットのみ `s3:ListBucket` と `s3:GetObject` を許可
3. `terraform plan` で差分確認
4. `aws iam simulate-principal-policy` で権限検証
5. NG例（`s3:*` on `*`）と比較

### サンプル（最小構成）
```hcl
provider "aws" {
  region = "ap-northeast-1"
}

resource "aws_iam_role" "app_readonly_role" {
  name = "app-readonly-s3-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "s3_readonly_specific" {
  name = "s3-readonly-specific-bucket"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = ["s3:ListBucket"],
        Resource = ["arn:aws:s3:::example-secdevops-bucket"]
      },
      {
        Effect = "Allow",
        Action = ["s3:GetObject"],
        Resource = ["arn:aws:s3:::example-secdevops-bucket/*"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.app_readonly_role.name
  policy_arn = aws_iam_policy.s3_readonly_specific.arn
}
```

**達成条件（Done）**
- `terraform plan` が意図どおり
- `GetObject` は成功、`PutObject/DeleteObject` は拒否される
- `Resource: "*"` を使っていない

## 5) Command cheatsheet
```bash
# Linux 基本
pwd
ls -la
mkdir -p iam-lab && cd iam-lab

# Terraform
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
terraform destroy

# AWS IAM 検証（例）
aws iam list-roles
aws iam get-role --role-name app-readonly-s3-role
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::<ACCOUNT_ID>:role/app-readonly-s3-role \
  --action-names s3:GetObject s3:PutObject \
  --resource-arns arn:aws:s3:::example-secdevops-bucket/test.txt

# 参考: K8s 権限確認（次号以降で深掘り）
kubectl auth can-i get pods --as=system:serviceaccount:default:demo
```

## 6) Common mistakes and how to avoid them
1. **`Action: "*"` を使う**  
   - 回避: 必要 API を列挙。まず ReadOnly から始める。

2. **`Resource: "*"` のまま運用**  
   - 回避: ARN を具体化。バケット/パス/環境ごとに分離。

3. **CI/CD ロールに人間用権限を混在**  
   - 回避: ロールを用途分離（app / ci / ops）。

4. **ポリシーをテストしない**  
   - 回避: `simulate-principal-policy` を PR チェックに組み込む。

5. **緊急対応の恒久化**  
   - 回避: 一時昇格には期限を設定し、事後に必ず削除。

## 7) One interview-style question
**質問:**
「本番障害対応で一時的に広い IAM 権限を付与しました。再発防止のため、あなたならどのように“安全に速く”運用へ戻しますか？」

**期待される観点:**
- 期限付きアクセス（JIT）
- 監査ログ（CloudTrail）確認
- 恒久ロールの最小権限化
- Terraform への反映とレビュー
- Runbook 更新

## 8) Next-step reading links
- OWASP Top 10: https://owasp.org/www-project-top-ten/
- AWS IAM ベストプラクティス: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- Terraform Security Best Practices（HashiCorp）: https://developer.hashicorp.com/terraform/tutorials/security
- CIS AWS Foundations Benchmark: https://www.cisecurity.org/benchmark/amazon_web_services
- Kubernetes Security Checklist: https://kubernetes.io/docs/concepts/security/
- OpenTelemetry Overview: https://opentelemetry.io/docs/
- Prometheus Docs: https://prometheus.io/docs/introduction/overview/
- Grafana Docs: https://grafana.com/docs/

---
### Learning Arc Note（ローテーション計画）
- Day 1（今日）Beginner: Cloud IAM 最小権限 + Terraform 基礎
- Day 2 Middle: Docker hardening + secrets 管理 + CI 連携
- Day 3 Advanced: Kubernetes incident drill（障害注入→rollback→復旧）+ Observability 相関分析
- Day 4 Beginner: OWASP リスクと secure coding 実践
- Day 5 Middle: Threat modeling（DFD, trust boundary）
- Day 6 Advanced: Auth/session 設計レビュー + incident response 演習

※ 以後、Beginner → Middle → Advanced の順で繰り返し、AppSec/DevOps/Cloud/Observability/K8s Drill を循環させます。
