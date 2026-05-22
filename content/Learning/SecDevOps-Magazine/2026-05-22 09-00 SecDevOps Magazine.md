---
tags: [security, devops, docker, kubernetes, terraform, linux, cloudsecurity, observability, daily]
---

[[Home]]

# SecDevOps Magazine — 2026-05-22

## 1) Topic + Level
**Topic:** CI/CD Security（Middle）— OIDC Federationで「Secretsを置かない」デプロイ設計  
**Level:** **Middle**

> 学習アーク: `Beginner → Middle → Advanced` の反復サイクル（Cloud Security / DevOps Coreトラック第2回）

**Prerequisites（この号の前提）**
- IAMの基本（Principal / Policy / Role）を説明できる
- Least Privilegeの考え方を理解している
- `terraform plan` の差分を読める

## 2) Why it matters in real projects
多くのCI/CD事故は、アプリ本体より先に**パイプラインの秘密情報漏えい**から始まります。  
例: GitHub ActionsのRepository Secretsに長期AWSキーを置き、漏えい後に本番へ不正アクセスされる。

OIDC Federation（例: GitHub Actions ↔ AWS STS / GCP Workload Identity）を使うと、
- 長期秘密鍵を保存しない（Secret sprawl削減）
- 実行時に短命トークンを発行（被害時間を短縮）
- `sub`/`aud` 条件で「どのrepo・どのbranch・どのworkflowか」を厳密制御

結果として、速度を落とさずに安全性を上げられます。

## 3) Core concepts
- **OIDC Federation**: CI実行基盤をIdPとして信頼し、一時クレデンシャルを発行
- **AssumeRoleWithWebIdentity（AWS）**: OIDCトークンを使ってRoleを一時引受
- **Workload Identity Federation（GCP）**: サービスアカウント鍵なしで権限付与
- **Trust Policy条件**: `aud`, `sub`, `repository`, `ref` などで利用元を制限
- **Environment Protection**: mainブランチのみ本番権限、レビュー承認必須など
- **Artifact Integrity**: build artifactへの署名/検証（例: cosign）

実務のポイント:
1. 「誰でも使えるRole」を作らない（repo/branch/workflowで絞る）
2. dev/stg/prodでRole分離
3. deploy権限とinfra変更権限を分離
4. 失敗ログに機密値を出さない

## 4) Hands-on mini lab (30-60 min)
**目的:** GitHub Actions + AWS OIDCで、長期Access Keyなしデプロイ基盤を体験する。  
**所要時間:** 45〜60分

### 手順
1. AWSでOIDC Provider（token.actions.githubusercontent.com）を登録
2. GitHub Actions専用IAM Roleを作成
   - Trust Policyに `aud=sts.amazonaws.com`
   - `sub=repo:<ORG>/<REPO>:ref:refs/heads/main` を指定
3. Permission Policyは最小権限（例: 特定S3バケットへのPut/Getのみ）
4. GitHub Actions workflowで `aws-actions/configure-aws-credentials` を使用
5. `aws sts get-caller-identity` を実行し、Assumed Roleを確認
6. あえて別branchで実行し、Role取得が拒否されることを確認

### 完了条件
- Repository Secretsに長期AWSキーを置かずにCI実行できる
- main以外からの実行を拒否できる
- 「どの条件で許可/拒否したか」を説明できる

## 5) Command cheatsheet
```bash
# Linux: workflowローカルlint（例）
yamllint .github/workflows/*.yml

# AWS: OIDC連携後の呼び出し主体確認
aws sts get-caller-identity

# AWS: role trust policy確認
aws iam get-role --role-name <ROLE_NAME> \
  --query 'Role.AssumeRolePolicyDocument' --output json

# Docker: build時に秘密値を平文埋め込みしない（BuildKit secrets）
DOCKER_BUILDKIT=1 docker build \
  --secret id=npm_token,src=.secrets/npm_token .

# Terraform: OIDC/IAM変更の差分確認
terraform fmt -recursive
terraform validate
terraform plan

# Kubernetes: デプロイロールバック（incident drillの導入準備）
kubectl rollout status deploy/<APP>
kubectl rollout history deploy/<APP>
kubectl rollout undo deploy/<APP>
```

## 6) Common mistakes and how to avoid them
- **ミス1: Trust Policyが広すぎる（repo制限なし）**  
  → `sub` をrepo + branch + workflow単位で制限する。

- **ミス2: prodとdevで同一Role**  
  → 環境ごとにRole分離。prodは承認フロー必須。

- **ミス3: CIログにtoken/環境変数を出力**  
  → `set -x` を避け、マスキング設定を徹底。

- **ミス4: 失効戦略なし**  
  → Roleポリシー変更、workflow保護、緊急停止手順（break-glass）を事前定義。

## 7) One interview-style question
「あなたのチームで“Secretsを置かないCI/CD”に移行する場合、OIDCのTrust Policyをどう設計し、開発体験を損なわずに本番権限を守りますか？」

## 8) Next-step reading links
- GitHub Actions OIDC: https://docs.github.com/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-cloud-providers
- AWS OIDC Federation for GitHub: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html
- GCP Workload Identity Federation: https://cloud.google.com/iam/docs/workload-identity-federation
- OWASP CI/CD Security: https://owasp.org/www-project-top-10-ci-cd-security-risks/
- Kubernetes Rollout/Rollback: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- OpenTelemetry Docs: https://opentelemetry.io/docs/

---

## Curriculum Progression Note
次号（Advanced予定）は **Kubernetes incident drills（failure / rollback / recovery）** を扱います。

**Advancedの予定Prerequisites**
- OIDC Federationの基本フローを説明できる
- CI/CDの権限分離（dev/stg/prod）を設計できる
- `kubectl rollout` の基本操作ができる

この3号アーク完了後、次サイクルで以下をローテーション予定：
- Application Security（Threat Modeling / Auth & Session Security / Incident Response）
- DevOps Core（Docker hardening / Terraform IaC / Linux command mastery）
- Added Topics（Cloud Security / Observability / K8s incident drills）

※ すべて倫理的・防御的・合法な学習目的に限定。