# SecDevOps Magazine — 2026-03-30 09:00

[[Home]]

#security #devops #docker #kubernetes #terraform #linux #cloudsecurity #observability #daily

---

## 1) Topic + Level
**Topic:** Cloud Security 基礎（AWS/GCP IAM と Permission Design の最小権限）  
**Level:** **Beginner**  
**Learning Arc:** B→M→A の反復アーク（今号は Day 1 / Beginner）

---

## 2) Why it matters in real projects
実務では、脆弱性そのものよりも **「権限の広さ」** が被害を拡大させます。  
たとえばアプリに SSRF やトークン漏えいが起きても、IAM が最小権限なら横展開を抑えられます。逆に `*:*` 権限だと、1つのミスが本番全体停止につながります。  

**AppSec × DevOps の接点** として、IAM 設計は「安全な実装」「安全な運用」「監査可能性」を同時に満たす土台です。

---

## 3) Core concepts (clear explanations)
- **Least Privilege（最小権限）**
  - 必要な操作だけ許可する。対象リソースも可能な限り限定する。
- **Deny by Default**
  - 明示許可がない限り拒否。事故時の被害を最小化。
- **Role-based Access**
  - ユーザー直付けより、Role/Service Account を使って責務単位で管理。
- **Separation of Duties（職務分離）**
  - デプロイ権限、監査権限、削除権限を分離し、誤操作と不正のリスクを低減。
- **短命クレデンシャル**
  - 長期キーを避け、OIDC/STS など短時間トークンを利用。
- **監査ログ**
  - AWS CloudTrail / GCP Audit Logs で「誰が何をしたか」を追跡可能にする。

---

## 4) Hands-on mini lab (30-60 min)
**Lab: 「読み取り専用 + 監査可能」な IAM を作る**

### ゴール
- S3/GCS の特定バケットに対する ReadOnly 権限を作成
- CLI で想定外操作（削除・書き込み）が拒否されることを確認
- 監査ログで試行を確認

### 手順（AWS例）
1. `readonly-policy.json` を作成（対象バケット限定）
2. IAM Policy を作成
3. Role を作成して policy をアタッチ
4. AssumeRole で一時クレデンシャル取得
5. `aws s3 ls` は成功、`aws s3 rm` は失敗することを確認
6. CloudTrail で deny イベント確認

### 手順（GCP例）
1. サービスアカウント作成
2. バケット単位で `roles/storage.objectViewer` を付与
3. `gsutil ls` 成功、`gsutil cp`（書き込み）失敗を確認
4. Audit Logs で記録確認

---

## 5) Command cheatsheet
```bash
# Linux: 権限確認
id
whoami

# AWS IAM
aws iam create-policy --policy-name S3ReadOnlyScoped --policy-document file://readonly-policy.json
aws sts assume-role --role-arn arn:aws:iam::<ACCOUNT_ID>:role/S3ReadOnlyRole --role-session-name secdevops-lab
aws s3 ls s3://my-sec-lab-bucket
aws s3 rm s3://my-sec-lab-bucket/test.txt   # 失敗するのが正しい

# GCP IAM
gcloud iam service-accounts create secdevops-lab-sa
gcloud projects add-iam-policy-binding <PROJECT_ID> \
  --member="serviceAccount:secdevops-lab-sa@<PROJECT_ID>.iam.gserviceaccount.com" \
  --role="roles/storage.objectViewer"
gsutil ls gs://my-sec-lab-bucket
gsutil cp local.txt gs://my-sec-lab-bucket/   # 失敗するのが正しい

# Kubernetes(参照): 権限確認の第一歩
kubectl auth can-i get pods -n default

# Terraform(参照): planで差分確認
terraform init
terraform plan
```

---

## 6) Common mistakes and how to avoid them
- **ミス1: `Action: "*"`, `Resource: "*"` を暫定で入れたまま運用**
  - **回避:** 期限付きチケット化 + 週次で権限レビュー
- **ミス2: 人間ユーザーに直接強い権限を付与**
  - **回避:** Role/Group 経由に統一、緊急昇格は一時的に
- **ミス3: 長期アクセスキーを CI/CD に保存**
  - **回避:** OIDC federation + short-lived token
- **ミス4: ログを有効化しただけで見ていない**
  - **回避:** 失敗イベント（AccessDenied）を定期レビュー対象に

---

## 7) One interview-style question
本番環境で「開発速度を落とさずに最小権限を実現する設計」を説明してください。  
（ヒント: Role分離、環境別ポリシー、短命トークン、監査自動化）

---

## 8) Next-step reading links
- OWASP Top 10: https://owasp.org/www-project-top-ten/
- AWS IAM Best Practices: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- Google Cloud IAM Overview: https://cloud.google.com/iam/docs/overview
- NIST Least Privilege (SP 800-53 family): https://csrc.nist.gov/
- Kubernetes RBAC: https://kubernetes.io/docs/reference/access-authn-authz/rbac/
- OpenTelemetry Docs: https://opentelemetry.io/docs/

---

### 次号予告（Middle）
**Prerequisites（次号に必要）**
- IAMの基本語彙（Role/Policy/Principal）
- CLIでの基本操作（aws/gcloud）
- 「なぜ最小権限が必要か」を説明できること

次号は **Middle: CI/CD Security + Secrets Management（OIDC連携実装）** に進みます。実務でそのまま使えるパイプライン防御を扱います。