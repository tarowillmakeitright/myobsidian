# SecDevOps Magazine — 2026-04-06
[[Home]]

#security #devops #docker #kubernetes #terraform #linux #cloudsecurity #observability #daily

---

## 1) Topic + Level
**Cloud Security（AWS IAM/GCP IAM の最小権限設計）+ Secrets Management 入門**  
**Level: Beginner**

> 学習アーク: Beginner → Middle → Advanced を3日単位で回す想定。  
> 今日のBeginnerで「権限の絞り方」を固め、次回Middleで「CI/CDへの適用」、Advancedで「インシデント対応と権限復旧」へ進む。

---

## 2) なぜ実務で重要か
本番障害や情報漏えいの多くは、**過剰権限（Over-privileged IAM）**と**秘密情報の管理ミス**から始まります。  
特にDevOps環境では、CI/CD・Kubernetes・Terraformが連鎖して動くため、1つの権限設計ミスが全体に波及します。

- 攻撃者視点: 「使えるトークン1つ」あれば横展開できる
- 防御者視点: 最小権限 + 監査ログ + 早い検知が被害を小さくする
- 法務/コンプラ視点: 不要アクセスの放置は監査で重大指摘になりやすい

---

## 3) Core concepts（やさしく）
- **Least Privilege（最小権限）**: 必要な操作だけを許可する
- **Deny by default**: まず拒否、必要なものだけ許可
- **Role分離**: 人間用ロール / CIロール / 運用ロールを分ける
- **Short-lived credentials**: 長期キーより短命トークンを優先
- **Policy as Code**: IAM方針をTerraform等でコード管理
- **Observability連携**: CloudTrail/GCP Audit Logs + メトリクス可視化（Prometheus/Grafana/OpenTelemetry）
- **OWASPとの接点**: A01 Broken Access Control はIAM設計不備と直結

---

## 4) Hands-on mini lab（30–60分）
**目標:** 「読み取り専用ロール」と「デプロイ用ロール」を分離し、監査ログ確認まで行う

### Step A（10分）
ローカルで検証用ディレクトリを作成
```bash
mkdir -p ~/labs/iam-least-privilege && cd ~/labs/iam-least-privilege
```

### Step B（15分）
Terraformで最小権限ポリシーを定義（雛形）
```hcl
# main.tf (概念サンプル)
# 1) ReadOnly role
# 2) Deploy role (限定されたリソースのみ)
# 3) 不要なワイルドカード * を避ける
```

### Step C（10分）
`terraform validate` と `terraform plan` で権限差分を確認

### Step D（10分）
CI想定のサービスアカウント/ロールで「許可される操作」「拒否される操作」を1つずつ試す

### Step E（10分）
監査ログ（AWS CloudTrail or GCP Audit Logs）を確認し、拒否イベントを1件追跡

**完了条件:**
- ワイルドカード権限を1つ削減できた
- 拒否ログを説明できる
- ロール分離の理由を自分の言葉で言える

---

## 5) Command cheatsheet
```bash
# Linux
ls -la
grep -R "\*" .

# Terraform
terraform fmt
terraform validate
terraform plan
terraform show

# Docker（CIジョブ想定の最小例）
docker build -t iam-lab:local .
docker run --rm iam-lab:local

# Kubernetes（将来の連携）
kubectl auth can-i get pods --as=system:serviceaccount:default:ci-bot
kubectl auth can-i create deployments --as=system:serviceaccount:default:ci-bot

# AWS例（環境に応じて）
aws sts get-caller-identity
aws iam simulate-principal-policy --policy-source-arn <ROLE_ARN> --action-names s3:ListBucket

# GCP例（環境に応じて）
gcloud auth list
gcloud projects get-iam-policy <PROJECT_ID>
```

---

## 6) よくあるミスと回避策
1. **`Action: *` を残す**  
   → まず読み取り/書き込みを分離。不要Actionを1つずつ削る。

2. **人間とCIで同じ権限を使う**  
   → ロールを分け、トークン寿命も分ける。

3. **監査ログを見ない**  
   → 「拒否ログを毎日1件確認」を習慣化。

4. **Secretを環境変数にベタ置き**  
   → Secret Manager / Vault / K8s Secret + RBAC + ローテーション。

---

## 7) Interview-style question
「本番障害直後、CIロールに一時的に広い権限を与えた。復旧後にどの順番で権限を戻し、再発防止をどう設計しますか？」

---

## 8) Next-step reading links
- OWASP Top 10: Broken Access Control  
  https://owasp.org/Top10/A01_2021-Broken_Access_Control/
- AWS IAM Best Practices  
  https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- Google Cloud IAM Overview  
  https://cloud.google.com/iam/docs/overview
- Terraform Security Best Practices（HashiCorp）  
  https://developer.hashicorp.com/terraform/tutorials/cloud-get-started/cloud-security-basics
- OpenTelemetry Docs  
  https://opentelemetry.io/docs/
- Kubernetes RBAC  
  https://kubernetes.io/docs/reference/access-authn-authz/rbac/

---

### 次号予告（Middle）
**Prerequisite（中級に進む前提）**
- IAM Policy JSONの基本が読める
- `terraform plan` の差分を説明できる
- 「誰が」「何に」「いつ」アクセスしたかをログで追える

次号は **CI/CD Security（OIDC連携で長期鍵を消す）** を扱います。