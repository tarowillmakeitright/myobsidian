---
tags: [security, devops, docker, kubernetes, terraform, linux, cloudsecurity, observability, daily]
---

[[Home]]

# SecDevOps Magazine — 2026-04-16

## 号情報
- **Issue:** #1
- **Topic + Level:** **Cloud Security (AWS/GCP IAM & permission design) — Beginner**
- **学習アーク:** Beginner → Middle → Advanced（3日サイクルで反復）
- **Middle/Advancedの前提:**
  - Linux基本コマンド（ls/cat/grep/curl）
  - Gitの基本操作
  - Docker/Kubernetes の超基礎（用語レベル）

---

## 1) Topic + Level
**Cloud Security (AWS/GCP IAM & permission design) — Beginner**

「最小権限（Least Privilege）」を軸に、IAMユーザー/ロール/ポリシーの設計を学ぶ。

---

## 2) Why it matters in real projects
本番事故の多くは、脆弱なコードそのものよりも**過剰権限**で被害が拡大します。  
例：CI/CD用の資格情報が漏えいし、管理者権限でクラウド全体が改変される。

IAM設計を早期に固めると、以下の効果が出ます。
- インシデント時の被害範囲を限定できる
- 監査対応（誰が何にアクセス可能か説明）が容易になる
- チーム開発での権限付与が再現可能になる（IaC化しやすい）

---

## 3) Core concepts（要点）
1. **Principal（主体）**
   - AWS: User / Role
   - GCP: User / Service Account
2. **Action（何をするか）**
   - 例: `s3:GetObject`, `compute.instances.get`
3. **Resource（どこに対して）**
   - 例: 特定バケット、特定プロジェクト
4. **Condition（いつ許可するか）**
   - 例: 特定IP、MFA必須、タグ一致時のみ
5. **最小権限の原則**
   - 「とりあえず管理者」を禁止
   - 必要な操作だけ・必要な範囲だけ許可

---

## 4) Hands-on mini lab（30–60分）
**目的:** 読み取り専用ロールを作成し、過剰権限との差を確認する。

### 手順
1. TerraformでIAMロール/ポリシーを作成（ReadOnly）
2. テスト用ユーザー or サービスアカウントにアタッチ
3. 許可操作（読む）は成功、禁止操作（書く/削除）は失敗することを確認
4. CloudTrail / Cloud Logging で拒否ログを確認

### 成果物
- `iam-readonly.tf`
- 検証ログ（許可/拒否のスクリーンショットまたはメモ）
- 「なぜ拒否されたか」の1段落まとめ

---

## 5) Command cheatsheet
### Linux
```bash
whoami
env | grep -E 'AWS|GOOGLE|GCP'
grep -R "iam\|policy\|role" .
```

### Terraform
```bash
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
terraform destroy
```

### AWS CLI（例）
```bash
aws sts get-caller-identity
aws iam list-attached-user-policies --user-name <user>
aws s3 ls s3://<bucket>
```

### GCP CLI（例）
```bash
gcloud auth list
gcloud projects get-iam-policy <project-id>
gsutil ls gs://<bucket>
```

### Kubernetes（将来トラックへの接続）
```bash
kubectl auth can-i get pods --all-namespaces
kubectl auth can-i delete deployments -n default
```

---

## 6) Common mistakes and how to avoid them
1. **`*:*` に近いポリシーを配る**
   - 回避: まずReadOnlyから開始し、必要操作をログベースで追加
2. **人間ユーザーに長期キーを持たせる**
   - 回避: 可能な限りRole / Workload Identityを使用
3. **環境（dev/stg/prod）で権限分離しない**
   - 回避: アカウント/プロジェクト分離 + 明示的な境界
4. **監査ログを見ない**
   - 回避: 拒否イベントを毎週レビュー

---

## 7) One interview-style question
あなたがSREとして参加した直後、全開発者に `AdministratorAccess` が付与されていました。  
**最初の1週間で、可用性を落とさずに最小権限へ移行する計画をどう作りますか？**

---

## 8) Next-step reading links
- OWASP Top 10: https://owasp.org/www-project-top-ten/
- AWS IAM Best Practices: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- GCP IAM Overview: https://cloud.google.com/iam/docs/overview
- Terraform Security Best Practices (HashiCorp Learn): https://developer.hashicorp.com/terraform/tutorials/state/resource-lifecycle
- Kubernetes RBAC: https://kubernetes.io/docs/reference/access-authn-authz/rbac/
- OpenTelemetry Docs: https://opentelemetry.io/docs/

---

## ローテーション計画（必須トラックを循環）
- Day 1 (Beginner): **Cloud Security (IAM)** ✅
- Day 2 (Middle): **Observability (Prometheus/Grafana/OpenTelemetry)**
- Day 3 (Advanced): **Kubernetes incident drills (failure/rollback/recovery)**
- Day 4 (Beginner): **Secure Coding + OWASPリスク**
- Day 5 (Middle): **CI/CD Security + Secrets Management**
- Day 6 (Advanced): **Threat Modeling + Incident Response演習**
- Day 7 (Beginner): **Docker Hardening + Linux command mastery**
- Day 8 (Middle): **Terraform/IaC Best Practices**
- Day 9 (Advanced): **Auth/Session Security deep dive**

この9日アークを反復し、Beginner → Middle → Advanced を継続的に回す。
