---
tags: [security, devops, docker, kubernetes, terraform, linux, cloudsecurity, observability, daily]
---

[[Home]]

# SecDevOps Magazine — 2026-05-13

## 1) Topic + Level
**Cloud Security (AWS/GCP IAM & Permission Design) — Beginner**

> 学習アーク: **Cloud Security Arc #1/3 (Beginner → Middle → Advanced)**  
> 次回予告: Arc #2 は「IAMの権限境界と最小権限の実装（Middle）」

---

## 2) Why it matters in real projects
実案件では、アプリ本体の脆弱性より先に**権限ミス**で事故が起きることがよくあります。  
たとえば:

- 開発用サービスアカウントに本番の管理権限が付いている
- CI/CD用トークンが過剰権限で、漏えい時に全環境へ影響
- 一時的に付けた `Administrator` 権限を戻し忘れる

IAM設計は、**侵害されても被害を最小化する最後の防波堤**です。  
セキュアコーディングやKubernetes運用と同じくらい、DevOpsの基礎体力になります。

---

## 3) Core concepts (clear explanations)
### A. Principal（誰が）
- AWS: User / Role / Federated identity
- GCP: User / Service Account / Group

「誰が操作するか」を明確にする。

### B. Action（何を）
- 例: `s3:GetObject`, `ec2:StartInstances`, `storage.objects.get`

操作の粒度を具体的に定義する。

### C. Resource（どこに）
- 例: 特定のS3バケットだけ、特定プロジェクトだけ

対象範囲を限定して、横展開リスクを下げる。

### D. Condition（どんな条件で）
- 例: 特定IPからのみ、MFA必須、特定タグ付きリソースのみ

同じ権限でも、条件で安全性が大きく変わる。

### E. Least Privilege（最小権限）
- 必要最小限の権限だけ付与
- まず狭く与えて、必要なら段階的に追加

### F. Role-based design（ロール設計）
- 人やサービスごとに直接権限を乱立させない
- 職務単位のRoleを作って再利用する

---

## 4) Hands-on mini lab (30–60 min)
**目的:** 「読み取り専用ロール」を作り、過剰権限との差を体感する

### Labシナリオ
1. テスト用バケット（またはGCSバケット）を1つ作る
2. `ReadOnly` ロールを作る（list/get のみ）
3. サービスアカウント（またはAWS Role）へアタッチ
4. 読み取り成功を確認
5. 書き込み/削除を試し、拒否されることを確認
6. 失敗ログを確認し、必要なら最小追加権限を検討

### 成果物
- ポリシーJSON（またはIAMバインディング）
- 「許可された操作」と「拒否された操作」のメモ
- 次回Middle向けに「何が足りなかったか」1行メモ

---

## 5) Command cheatsheet
### Linux
```bash
# 認証情報の環境変数を確認
env | grep -E 'AWS_|GOOGLE_|GCP_'

# jqでポリシーJSONを整形
cat policy.json | jq .
```

### AWS CLI
```bash
# 現在の主体を確認
aws sts get-caller-identity

# ロール一覧
aws iam list-roles --max-items 20

# ポリシーシミュレーション（例）
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::<ACCOUNT_ID>:role/ReadOnlyRole \
  --action-names s3:GetObject s3:PutObject \
  --resource-arns arn:aws:s3:::your-bucket/*
```

### GCP CLI
```bash
# 現在のアカウント確認
gcloud auth list

# プロジェクトIAMポリシー確認
gcloud projects get-iam-policy <PROJECT_ID>

# サービスアカウント一覧
gcloud iam service-accounts list
```

### Terraform (IaC)
```hcl
# 例: 最小権限ポリシーを分離して管理
resource "aws_iam_policy" "readonly_s3" {
  name   = "readonly-s3-policy"
  policy = file("policies/readonly-s3.json")
}
```

---

## 6) Common mistakes and how to avoid them
1. **`*` 権限を多用する**  
   - 回避: Action/Resourceを必ず具体化。レビューで `*` を検知するルール化。

2. **人アカウントへ直接権限を付ける**  
   - 回避: Group/Role経由に統一。個別付与を禁止。

3. **一時昇格を戻し忘れる**  
   - 回避: 有効期限付き付与（JIT）と定期棚卸し。

4. **CI/CDシークレットを長期固定キーに依存**  
   - 回避: OIDC連携 + 短命トークンへ移行。

5. **監査ログを見ない**  
   - 回避: CloudTrail / Cloud Audit Logs の定期確認を運用タスク化。

---

## 7) One interview-style question
「あなたが新規プロジェクトでIAM設計を任された場合、**最小権限**をどう実務に落とし込みますか？  
設計手順・レビュー方法・運用（棚卸し/監査）まで説明してください。」

---

## 8) Next-step reading links
- OWASP ASVS（アクセス制御の観点）  
  https://owasp.org/www-project-application-security-verification-standard/
- AWS IAM Best Practices  
  https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- Google Cloud IAM Best Practices  
  https://cloud.google.com/iam/docs/using-iam-securely
- CNCF Cloud Native Security Whitepaper  
  https://github.com/cncf/tag-security/tree/main/security-whitepaper
- OpenTelemetry Docs（次回Observabilityトラック準備）  
  https://opentelemetry.io/docs/

---

### Difficulty progression note
本マガジンは以下の難易度サイクルで進行します。
- Day A: **Beginner**（基礎理解 + 手を動かす）
- Day B: **Middle**（実装・設計判断）※Prerequisite: Beginner回の理解
- Day C: **Advanced**（障害/攻撃想定での運用最適化）※Prerequisite: Middle回の実践経験

ローテーション対象トラック:
- Application Security
- DevOps Core（Docker/Kubernetes/Terraform/Linux/CI-CD/Secrets）
- Cloud Security
- Observability
- Kubernetes Incident Drills
