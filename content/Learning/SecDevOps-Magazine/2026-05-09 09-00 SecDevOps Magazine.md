---
tags: [security, devops, docker, kubernetes, terraform, linux, cloudsecurity, observability, daily]
---

[[Home]]

# SecDevOps Magazine — 2026-05-09

おはよう！今日のテーマは **Application Security × DevOps** の実践力を、守りと運用の視点で確実に伸ばすことです。  
本誌は **倫理的・防御的・合法的な学習のみ** を対象にしています。

---

## 1) Topic + Level
**Cloud Security（AWS/GCP IAM & Permission Design） + Beginner**

### 2) Why it matters in real projects
IAM設計は、クラウド事故の“最初の防波堤”です。  
過剰な権限（`*` 許可、長期キーの放置）を残すと、単一アカウント侵害が本番全体へ波及します。逆に、最小権限・職務分離・短命クレデンシャルを徹底すれば、被害範囲を局所化できます。  
DevOpsではCI/CD・運用自動化・監視基盤がIAMに依存するため、セキュアな権限設計は“機能要件”そのものです。

### 3) Core concepts（clear explanations）
- **Least Privilege（最小権限）**  
  必要な操作だけ、必要な対象だけ、必要な時間だけ許可する。
- **Role-based access**  
  ユーザー直付けではなくRole中心で設計し、運用変更コストと事故率を下げる。
- **Separation of Duties（職務分離）**  
  例: `deploy` と `approve` を同一主体に持たせない。
- **Temporary Credentials**  
  AWS STS / GCP Workload Identity Federation で長期秘密鍵依存を減らす。
- **Policy Boundaries / Condition**  
  リソースタグ、IP、MFA有無、時刻条件で許可を絞る。
- **Auditability**  
  CloudTrail / Cloud Audit Logs により「誰が・何を・いつ」を追跡可能にする。

### 4) Hands-on mini lab（30-60 min）
**Lab: “CI用Roleを最小権限で作り、不要権限を削る”**

1. 目的を定義（例: `ECR push` + `EKS deploy` のみ）。
2. TerraformでRoleとPolicyを作成（ワイルドカード禁止）。
3. `aws iam simulate-principal-policy` 相当で許可を検証。  
4. 想定外のAPIが許可されていないことを確認。  
5. 監査ログ（CloudTrail）で操作記録を確認。  
6. 学びをメモ: 「必要だった権限」「削れた権限」「次回テンプレ化」。

### 5) Command cheatsheet
```bash
# Linux: まず身元確認
whoami
id

# AWS: 現在のCaller Identity確認
aws sts get-caller-identity

# AWS: IAMポリシーシミュレーション（例）
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::123456789012:role/ci-role \
  --action-names ecr:PutImage eks:DescribeCluster

# Terraform: 構文と計画
terraform fmt
terraform validate
terraform plan

# Kubernetes: 現在コンテキスト確認
kubectl config current-context
kubectl auth can-i get pods -n default
```

### 6) Common mistakes and how to avoid them
- **ミス:** `Action: "*"`, `Resource: "*"` を常用  
  **回避:** まず業務フローを分解し、必要APIを列挙してから最小集合で記述。
- **ミス:** 人間ユーザーに直接強権限を付与  
  **回避:** Role経由 + 承認フロー + 期限付き昇格。
- **ミス:** 長期Access KeyをCIに保存  
  **回避:** OIDC連携で短命トークン化。
- **ミス:** 権限変更後の回帰確認なし  
  **回避:** `plan` + シミュレーション + 監査ログ確認を定型化。

### 7) One interview-style question
「本番EKSデプロイ用CI Roleを設計するとき、最小権限をどう定義し、将来の権限肥大化をどう防ぎますか？」

### 8) Next-step reading links
- https://owasp.org/www-project-top-ten/
- https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- https://cloud.google.com/iam/docs/best-practices-for-using-iam
- https://opentelemetry.io/docs/
- https://kubernetes.io/docs/concepts/security/

---

## 学習アーク進行メモ（Beginner → Middle → Advanced）
- **今回:** Beginner（IAM最小権限の土台）
- **次回（Middle予定）:** Observability（Prometheus/Grafana/OpenTelemetry）
  - **Prerequisites:** Linux基本コマンド、Docker基礎、HTTPメトリクス概念
- **次々回（Advanced予定）:** Kubernetes incident drills（failure/rollback/recovery）
  - **Prerequisites:** kubectl操作、Deployment/Service理解、CI/CDの基本

この3段を1サイクルとして、AppSec・DevOps各トラックに展開していきます。