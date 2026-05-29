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

# SecDevOps Magazine — 2026-05-29

## 今日の学習アーク
- **Arc 1 / Day 1**
- **レベル: Beginner**（次回は Middle、その次は Advanced へ進行）
- Middle/Advanced に進む前提として、今日は「最小権限」「監査ログ」「ロール分離」を体で理解する回。

---

## 1) Topic + Level
**Cloud Security (AWS/GCP IAM & Permission Design) + DevOps 基礎接続**  
**Level: Beginner**

---

## 2) Why it matters in real projects
本番障害や情報漏えいの多くは、脆弱なアプリコードだけでなく**過剰権限の IAM**から始まります。  
「とりあえず `AdministratorAccess`」は短期では速くても、長期では事故コストが跳ね上がる。  
DevOps では CI/CD、Terraform、Kubernetes 連携のすべてが権限に依存するため、IAM 設計は**セキュア開発の土台**です。

---

## 3) Core concepts（要点）
- **Least Privilege（最小権限）**
  - 必要な操作だけ許可。`*` を避け、Action/Resource を絞る。
- **Role Separation（役割分離）**
  - 人間用ロール（運用者）とマシン用ロール（CI/CD, workload）を分ける。
- **Temporary Credentials**
  - 長期キーより STS/OIDC を優先。漏えい時の被害時間を短縮。
- **Deny by default + explicit allow**
  - まず拒否。必要部分のみ明示許可。
- **Auditability**
  - CloudTrail / GCP Audit Logs で「誰が何をしたか」を追える状態にする。

---

## 4) Hands-on mini lab（30–60分）
**目的:** 「CI/CD が S3 バケットへ成果物を置くだけ」権限を最小で作る。

### 手順
1. Terraform で IAM Policy を作成（PutObject のみ許可）
2. CI 用 Role を作成し、その Policy のみアタッチ
3. テスト: 許可操作（PutObject）は成功、禁止操作（DeleteBucket）は失敗することを確認
4. CloudTrail（または監査ログ）で操作履歴を確認

### Terraform 例（AWS）
```hcl
resource "aws_iam_policy" "ci_upload_only" {
  name   = "ci-upload-only"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["s3:PutObject"],
        Resource = ["arn:aws:s3:::my-artifacts-bucket/*"]
      }
    ]
  })
}
```

---

## 5) Command cheatsheet
```bash
# Linux: 権限周りの基本確認
id
whoami
env | grep -E 'AWS|GOOGLE|KUBE'

# Terraform
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply

# AWS CLI (検証)
aws sts get-caller-identity
aws s3 cp ./artifact.zip s3://my-artifacts-bucket/builds/
aws s3 rb s3://my-artifacts-bucket   # <- 失敗するのが正解（権限不足）

# Kubernetes（将来の連携を意識）
kubectl auth can-i get pods -n default
```

---

## 6) Common mistakes and how to avoid them
- **ミス1: とりあえず管理者権限**
  - 回避: 最初に「必要操作一覧」を書き出し、Action を限定。
- **ミス2: 人間と CI が同じ資格情報を使う**
  - 回避: Role を分離。CI は OIDC/短期クレデンシャルへ。
- **ミス3: Resource を `*` にする**
  - 回避: バケット/パス/プロジェクト単位で絞る。
- **ミス4: ログを見ない**
  - 回避: 変更後に必ず監査ログを確認し、想定外操作がないか検証。

---

## 7) One interview-style question
「CI/CD に最小権限を適用する際、`運用の速さ` と `セキュリティ` のトレードオフをどう設計しますか？具体的にロール分離・監査・例外申請フローまで説明してください。」

---

## 8) Next-step reading links
- OWASP Top 10: https://owasp.org/www-project-top-ten/
- AWS IAM Best Practices: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- Google Cloud IAM: https://cloud.google.com/iam/docs/best-practices
- Terraform Security Guidance: https://developer.hashicorp.com/terraform/tutorials/security
- Kubernetes Security Checklist (CIS): https://www.cisecurity.org/benchmark/kubernetes
- OpenTelemetry Docs: https://opentelemetry.io/docs/
- Prometheus Docs: https://prometheus.io/docs/
- Grafana Docs: https://grafana.com/docs/

---

## 次号予告（進行管理）
- **次回 (Middle)**: Observability（Prometheus/Grafana/OpenTelemetry）で「セキュリティイベントを観測可能にする」
  - **Prerequisites:**
    - Linux 基本コマンド（grep/journalctl/curl）
    - Docker の基本（image/container/log）
    - 今日の IAM 最小権限の理解
- **次々回 (Advanced)**: Kubernetes Incident Drill（failure/rollback/recovery）
  - **Prerequisites:**
    - kubectl 基本操作
    - Deployment / Rollout の理解
    - CI/CD からのデプロイフロー理解
