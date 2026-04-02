# SecDevOps Magazine — 2026-04-02 (09:00)

#security #devops #docker #kubernetes #terraform #linux #cloudsecurity #observability #daily
[[Home]]

---

## 1) Topic + Level
**Cloud Security（AWS/GCP IAM & Permission Design）— Beginner**

> 学習方針: 倫理的・防御的・合法的な範囲で、最小権限（Least Privilege）を設計できるエンジニアを目指す。

---

## 2) Why it matters in real projects
本番障害やインシデントの多くは、**過剰な権限**・**共有アカウント**・**長期クレデンシャルの放置**が原因です。

現場では、次のような場面でIAM設計力が直接効きます。
- CI/CDが本番クラウドにデプロイする
- アプリがS3/GCSやSecretsにアクセスする
- 開発者や運用者の権限をチーム単位で分離する

IAMを適切に設計できると、
- 事故時の被害範囲を小さくできる
- 監査対応（誰が何をしたか）を説明しやすくなる
- DevOpsの速度を落とさずにセキュリティを上げられる

---

## 3) Core concepts（clear explanations）
### A. 認証（Authentication）と認可（Authorization）
- **認証**: 「あなたは誰か」を確認（例: SSO, MFA）
- **認可**: 「何をしてよいか」を制御（例: IAM Policy, Role）

### B. 最小権限（Least Privilege）
- 必要最小限のAction/Resourceだけ許可
- `*`（ワイルドカード）の多用は避ける

### C. Roleベース運用
- 人やアプリに直接ベタ権限を与えず、**Role**経由で付与
- AWSなら`AssumeRole`、GCPならService Accountのimpersonationを活用

### D. 短命な認証情報（Ephemeral Credentials）
- 長期Access Keyより、OIDCや短時間トークンを優先
- 漏えい時のリスクを時間で圧縮する

### E. Deny first / Boundary / 条件付き許可
- 「許可する」だけでなく、必要に応じて**明示的Deny**も設計
- 条件（IP, 時間, MFA必須）で事故を防ぐ

---

## 4) Hands-on mini lab（30–60 min）
**ラボ名: CI/CDデプロイ用の最小権限Roleを作る（ローカル検証）**

### 目的
Terraformで「読み取り中心 + 特定バケットへの書き込みのみ」権限を設計し、`terraform plan`で差分確認する。

### 手順（防御・合法用途のみ）
1. 新規ディレクトリを作成し、Terraform初期化
2. IAMポリシーをJSONで定義
   - 許可: `s3:ListBucket`（対象バケット1つ）
   - 許可: `s3:PutObject`（対象プレフィックス`artifacts/*`のみ）
   - 不許可: それ以外
3. Roleにポリシーをアタッチ
4. `terraform plan`で想定通りか確認
5. （任意）`aws iam simulate-principal-policy`で許可/拒否を検証

### 期待成果
- 「どの操作が許可され、何が拒否されるか」を説明できる
- 最小権限の具体化をコード（IaC）で再現できる

---

## 5) Command cheatsheet
```bash
# Linux
pwd
ls -la
mkdir -p iam-lab && cd iam-lab

# Terraform
terraform init
terraform fmt
terraform validate
terraform plan

# AWS CLI（検証系）
aws sts get-caller-identity
aws iam list-roles --max-items 20
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::123456789012:role/ci-deploy-role \
  --action-names s3:PutObject s3:DeleteObject s3:ListBucket \
  --resource-arns arn:aws:s3:::example-artifacts arn:aws:s3:::example-artifacts/artifacts/test.txt

# Docker（CIジョブでの静的チェック例）
docker run --rm -v "$PWD":/work -w /work hashicorp/terraform:latest terraform validate

# Kubernetes（将来の連携を意識）
kubectl auth can-i get secrets -n production
```

---

## 6) Common mistakes and how to avoid them
1. **`Action: "*"`や`Resource: "*"`を使う**
   - 回避: まずRead-onlyから始め、必要操作を監査ログで追加

2. **人間ユーザーに長期Access Keyを配る**
   - 回避: SSO + Role Assumeに移行、Key棚卸しを定期実施

3. **環境（dev/stg/prod）で権限境界が曖昧**
   - 回避: アカウント/プロジェクト分離 + 命名規約 + Boundary

4. **CI/CDが管理者権限で動く**
   - 回避: パイプライン専用Roleを作り、操作対象を限定

5. **レビューなしでIAM変更を適用**
   - 回避: PR必須 + `terraform plan`レビュー + 監査ログ確認

---

## 7) One interview-style question
**Q.** 「本番デプロイ用のCI Roleが`AdministratorAccess`になっていました。最小権限へ安全に移行する手順をどう設計しますか？」

（回答の観点）
- 現行操作の可視化（CloudTrail/監査ログ）
- 段階的な権限縮小（Read中心→必要Action追加）
- 失敗時ロールバック手順
- 承認フローと継続監査

---

## 8) Next-step reading links
- OWASP Top 10: https://owasp.org/www-project-top-ten/
- AWS IAM Best Practices: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- GCP IAM Overview: https://cloud.google.com/iam/docs/overview
- Terraform Security Best Practices (HashiCorp): https://developer.hashicorp.com/terraform/tutorials/cloud-get-started/cloud-security
- Kubernetes RBAC: https://kubernetes.io/docs/reference/access-authn-authz/rbac/
- OpenTelemetry Docs: https://opentelemetry.io/docs/

---

### Difficulty progression note（curriculum arc）
- **Today (Beginner):** IAM基礎と最小権限
- **Next (Middle, prerequisite):** IAM Policy Conditions / OIDC federation / Terraform module化  
  - 前提: IAM Policy JSONを読み書きできること、`terraform plan`を理解していること
- **Later (Advanced, prerequisite):** マルチアカウント権限設計 + 監査自動化 + インシデント時の緊急昇格設計  
  - 前提: Middle内容 + CloudTrail/監査ログの基礎

次号では、ローテーション方針に従って **Observability（Prometheus/Grafana/OpenTelemetry）** または **Kubernetes incident drills（failure/rollback/recovery）** に接続して、実運用で使える防御力を積み上げます。
