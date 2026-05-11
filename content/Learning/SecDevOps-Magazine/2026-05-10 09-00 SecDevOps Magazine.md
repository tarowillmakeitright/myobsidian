# SecDevOps Magazine — 2026-05-10 (09:00)

Tags: #security #devops #docker #kubernetes #terraform #linux #cloudsecurity #observability #daily  
Link: [[Home]]

---

## 今日の学習テーマ（Issue 001）

### 1) Topic + Level
**Topic:** Cloud Security 基礎: IAM と Permission Design の第一歩（AWS/GCP）  
**Level:** **Beginner**

> 学習アーク: `Beginner → Middle → Advanced` を3日サイクルで反復。  
> - Day 1（今日）: 基礎概念と最小権限の実践  
> - Day 2（Middle）: クロスアカウント権限・ロール委譲・監査ログ運用（※Prerequisite: 今日の内容）  
> - Day 3（Advanced）: 権限昇格パス分析・組織ポリシー設計・Incident対応演習（※Prerequisite: Day1-2）

### 2) Why it matters in real projects
本番事故の多くは「脆弱なコード」だけでなく、**過剰権限の設定ミス**から起きます。  
たとえば CI/CD 用のサービスアカウントに `Admin` 権限を付けると、トークン漏えい時に環境全体が侵害される可能性があります。  
IAM 設計は、アプリケーションセキュリティ（OWASP の Broken Access Control）と DevOps 運用をつなぐ土台です。

### 3) Core concepts（わかりやすく）
- **Principal**: 人間ユーザー / サービスアカウント / ロールなど「誰が」
- **Action**: `s3:GetObject` や `compute.instances.get` など「何を」
- **Resource**: バケット、VM、Secret など「どこに対して」
- **Condition**: IP、タグ、時刻、MFA 必須など「どんな条件で」
- **Least Privilege**: 必要最小限だけ許可する
- **Deny by default**: 明示許可が無いものは拒否

実務の鉄則:
1. ワイルドカード `*` を安易に使わない  
2. 人間ユーザーには短命セッション（SSO/Role）を使う  
3. 本番と開発で権限を分離する  
4. 監査ログ（CloudTrail / Cloud Audit Logs）を必ず有効化する

### 4) Hands-on mini lab（30–60分）
**目標:** 「読み取り専用 + 特定バケットのみ」の最小権限ポリシーを作る

#### A. AWS 例（約25分）
1. テスト用 IAM Policy を JSON で作成（`s3:ListBucket`, `s3:GetObject` のみ）
2. 対象バケットを `arn:aws:s3:::my-sec-lab-bucket` に限定
3. IAM User または Role にアタッチ
4. `aws s3 ls` / `aws s3 cp` で許可・拒否を確認

#### B. GCP 例（約25分）
1. サービスアカウント作成
2. `roles/storage.objectViewer` を特定バケットにのみ付与
3. `gcloud storage ls` でアクセス確認
4. 不要ロールが無いか再確認

**成功条件:**
- 許可した操作だけ通る
- 想定外操作（削除・書き込み等）が拒否される
- どの権限が必要だったか説明できる

### 5) Command cheatsheet
```bash
# Linux: 現在の認証情報確認
whoami
env | grep -E 'AWS|GOOGLE|GCP'

# AWS IAM / S3
aws sts get-caller-identity
aws iam list-attached-user-policies --user-name <USER>
aws s3 ls s3://my-sec-lab-bucket
aws s3 cp s3://my-sec-lab-bucket/test.txt ./test.txt

# GCP IAM / Storage
gcloud auth list
gcloud projects get-iam-policy <PROJECT_ID>
gcloud storage ls gs://my-sec-lab-bucket
gcloud storage cp gs://my-sec-lab-bucket/test.txt ./test.txt

# Kubernetes (参照用: 次号以降で使用)
kubectl auth can-i get pods -n default

# Terraform (参照用: 次号以降で使用)
terraform init
terraform plan
```

### 6) Common mistakes and how to avoid them
1. **`AdministratorAccess` を常用**  
   - 回避: 作業単位でカスタムポリシー化。期限付き昇格を使う。
2. **本番・開発の権限混在**  
   - 回避: アカウント/プロジェクト/ロールを環境別に分離。
3. **サービスアカウント鍵の長期放置**  
   - 回避: Workload Identity / ロール引受を優先。鍵は短命化・ローテーション。
4. **監査ログ未設定**  
   - 回避: CloudTrail / Audit Logs を最初に有効化、アラート連携。

### 7) Interview-style question
「CI/CD パイプラインに必要な最小 IAM 権限をどう設計しますか？  
“ビルド・デプロイ・シークレット参照”の3工程に分けて、過剰権限を避ける方法を説明してください。」

### 8) Next-step reading links
- OWASP Top 10: Broken Access Control  
  https://owasp.org/Top10/
- AWS IAM Best Practices  
  https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- GCP IAM Overview  
  https://cloud.google.com/iam/docs/overview
- NIST Least Privilege (Zero Trust 関連)  
  https://csrc.nist.gov/publications

---

## ローテーション計画（必須トラック反映）
- **Application Security:** secure coding / OWASP / threat modeling / auth-session / incident response
- **DevOps Core:** Docker hardening / Kubernetes fundamentals & security / Terraform IaC / Linux command mastery / CI-CD security / secrets management
- **Added Topics:** Cloud Security / Observability（Prometheus・Grafana・OpenTelemetry）/ Kubernetes incident drills

次号（予定）: **Middle — Observability 実践（SLI/SLO + OpenTelemetry 基本計測）**  
※Prerequisite: Linux 基本コマンド、HTTP 基礎、今日の IAM 最小権限の理解
