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

[[Home]]

# SecDevOps Magazine — 2026-03-17

> 今日の学習テーマは、**Cloud Security（AWS/GCP IAM & permission design）**です。  
> 学習アークは **Beginner → Middle → Advanced** の循環で進行します。今回は **Beginner** 回です。

## 1) Topic + Level
**Topic:** Cloud Security 基礎 — IAMと最小権限設計の第一歩（AWS/GCP）  
**Level:** **Beginner**

---

## 2) Why it matters in real projects
本番障害や情報漏えいの多くは「脆弱なコード」だけでなく、**過剰な権限（Over-privileged IAM）** が引き金になります。  
たとえば、CI/CD用のサービスアカウントに `*` 権限を与えると、侵害時にインフラ全体が操作されるリスクがあります。

実プロジェクトでは次が重要です：
- 開発速度を落とさず、必要最小限でアクセスを設計する
- 監査可能な形で「誰が・何を・いつ」実行できるかを明確化する
- インシデント時に被害範囲を限定できる設計にする

---

## 3) Core concepts (clear explanations)
### A. IAMの基本要素
- **Principal**: 操作主体（User / Role / Service Account）
- **Action**: 実行可能な操作（例: `s3:GetObject`, `compute.instances.get`）
- **Resource**: 対象リソース（Bucket, Instance など）
- **Condition**: 条件付き制御（IP, 時刻, タグ, MFA要件など）

### B. 最小権限（Least Privilege）
「今必要な操作だけ」を許可する設計。  
最初は狭く付与し、ログで不足を確認しながら段階的に広げるのが安全。

### C. 職務分離（Separation of Duties）
- 開発者、CI、運用、監査でロールを分離
- “人” と “機械（CI/CD）” の権限を分ける

### D. Deny優先と境界設計
- AWSでは Explicit Deny が Allow より優先
- GCPでは Organization Policy / IAM Conditions で境界制御
- 重要データには「アクセス可能な上限」を先に決める

### E. 短期認証情報の利用
- 長期キーの配布を避ける（Access Key固定運用は危険）
- ロール引き受け（AssumeRole）や Workload Identity を活用

---

## 4) Hands-on mini lab (30–60 min)
### ゴール
「読み取り専用の監査ロール」を作成し、過剰権限との差を確認する。

### 所要時間
約45分

### 手順
1. AWSまたはGCPの検証用プロジェクトを用意（本番不可）
2. 監査対象として、S3 Bucket（またはGCS Bucket）を1つ作成
3. `ReadOnly` 相当のロールを作成（対象バケット限定）
4. そのロールで一覧取得は成功、削除操作は失敗することを確認
5. CloudTrail / Cloud Loggingで失敗イベントを確認
6. 学びをメモ：
   - 何が許可され、何が拒否されたか
   - 次回 Middle で必要になる追加知識（IAM Policy JSONの粒度設計）

### 成功条件
- 読み取りは成功
- 書き込み/削除は拒否
- ログで拒否理由を追跡できる

---

## 5) Command cheatsheet
```bash
# ===== Linux 基本 =====
whoami
date
env | grep -E 'AWS|GOOGLE|GCP'

# ===== AWS CLI =====
aws sts get-caller-identity
aws s3 ls
aws s3api list-buckets

# IAMポリシーのシミュレーション（権限確認）
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::<ACCOUNT_ID>:role/<ROLE_NAME> \
  --action-names s3:ListBucket s3:DeleteObject \
  --resource-arns arn:aws:s3:::<BUCKET_NAME> arn:aws:s3:::<BUCKET_NAME>/*

# ===== GCP CLI =====
gcloud auth list
gcloud config list project
gsutil ls

# IAMバインディング確認（例）
gcloud projects get-iam-policy <PROJECT_ID>

# ===== Terraform（参考） =====
terraform init
terraform fmt
terraform validate
terraform plan
```

---

## 6) Common mistakes and how to avoid them
1. **`AdministratorAccess` を常用する**  
   → 検証時でも期限付き・限定スコープにする。

2. **人間ユーザーに長期キーを配る**  
   → SSO + 短期トークン、ロールベース認証へ移行。

3. **リソース限定を忘れる**  
   → `Resource: "*"` を避け、対象ARN/Resourceを具体化。

4. **CI/CDと運用者の権限を共用**  
   → 役割ごとにロール分離、監査ログで識別可能に。

5. **失敗ログを見ない**  
   → deniedイベントを毎回確認し、設計改善の入力にする。

---

## 7) One interview-style question
あなたが新規プロジェクトのクラウド基盤担当だとして、  
「開発速度を落とさずに最小権限を実現するIAM設計」をどう進めますか？  
初期設計、運用フロー、監査、例外対応まで説明してください。

---

## 8) Next-step reading links
- OWASP ASVS: https://owasp.org/www-project-application-security-verification-standard/
- AWS IAM Best Practices: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- Google Cloud IAM Overview: https://cloud.google.com/iam/docs/overview
- NIST Least Privilege (SP 800-53): https://csrc.nist.gov/publications
- OpenTelemetry Overview (次回 Observability 回への接続): https://opentelemetry.io/docs/concepts/

---

## 学習アーク予告（ローテーション）
- **次回（Middle）予定:** Observability（Prometheus/Grafana/OpenTelemetry）で「権限変更の監視」と「異常検知」
- **その次（Advanced）予定:** Kubernetes incident drills（failure/rollback/recovery）で権限誤設定が障害に与える影響を実演

> 前提知識メモ：
> - Middleに進む前提：Linux基本コマンド、IAMの4要素（Principal/Action/Resource/Condition）
> - Advancedに進む前提：Kubernetes基礎（Pod/Deployment/RBAC）と監視メトリクス読解
