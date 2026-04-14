# 2026-04-14 09-00 SecDevOps Magazine
[[Home]]

Tags: #security #devops #docker #kubernetes #terraform #linux #cloudsecurity #observability #daily

---

## 今日のIssue

### 1) Topic + Level
**Cloud Security（AWS/GCP IAM & Permission Design）+ CI/CD Secrets基礎**  
**Level: Beginner**

> 学習アーク（3日サイクル）: **Beginner → Middle → Advanced** を反復  
> 次回予定（Middle）: IAM権限境界 + OIDC Federation + Secretsローテーション  
> 次々回予定（Advanced）: クロスクラウド最小権限設計 + 侵害前提の権限分離 + 監査自動化

---

### 2) Why it matters in real projects
本番事故の多くは、ゼロデイよりも**権限ミス**と**秘密情報の漏えい**で起きます。  
例えば:
- 開発用の広すぎるIAM権限が本番にも残る
- CIログにAPI keyが出る
- Terraform stateに機密が平文で残る

この領域を早く固めると、アプリ側の脆弱性（OWASP系）に加えて、**被害の拡大スピード**を大きく下げられます。

---

### 3) Core concepts（やさしく要点）
- **Least Privilege（最小権限）**: 「できること」を必要最小限にする
- **Deny by default**: 許可したもの以外は拒否
- **Role分離**: 人間・CI・アプリ実行時でRoleを分ける
- **Short-lived credentials**: 長期キーより短命トークン（OIDC/STＳ）を優先
- **Secret zero問題**: 最初の認証情報をどう安全に渡すか
- **監査可能性（Auditability）**: 誰がいつ何を実行したか追える状態

---

### 4) Hands-on mini lab（30-60分）
**ラボ名: 「CI用Roleを最小権限で作り、過剰権限を検出する」**

#### ゴール
1. 読み取り専用のサンプルRoleを作る（AWS or GCPのどちらか）
2. 過剰権限をわざと付けて、差分で改善する
3. Secretを環境変数直書きしない運用に切り替える

#### 手順（例: AWS）
1. `readonly-policy.json` を作成（S3の特定バケットのみ `GetObject`）
2. IAM Policy/Roleを作成してテストユーザーにアタッチ
3. `aws s3 cp` で許可/拒否を確認
4. いったん `s3:*` を付けて「危険な成功」を再現
5. Access Advisor / CloudTrailで利用状況確認
6. 最小権限ポリシーに戻して再テスト
7. CIのシークレットをVault/Secrets Managerに寄せる設計メモを残す

**完了条件**
- 「必要な操作だけ成功し、不要な操作は失敗」している
- なぜその権限にしたかを1段落で説明できる

---

### 5) Command cheatsheet
```bash
# Linux: 誤ってsecretを履歴に残さない
export HISTCONTROL=ignorespace
 history | tail -n 20

# Docker: 環境変数の見え方確認（本番ではsecret直渡しを避ける）
docker inspect <container_id> | grep -i -E 'env|secret'

# Kubernetes: Secretの存在確認（値は直接見ない運用が原則）
kubectl get secret -n <ns>
kubectl describe secret <name> -n <ns>

# Terraform: planで差分確認（apply前に必須）
terraform init
terraform plan
terraform show

# AWS IAM（例）
aws iam list-roles
aws iam get-role --role-name <role>
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::<account-id>:role/<role> \
  --action-names s3:GetObject s3:DeleteObject

# GCP IAM（例）
gcloud projects get-iam-policy <project-id>
gcloud iam roles describe <role-id> --project <project-id>
```

---

### 6) Common mistakes and how to avoid them
- **ミス:** `AdministratorAccess` を暫定で付けて放置  
  **回避:** チケットに失効日を入れ、期限で自動削除

- **ミス:** `.env` をGit管理に含める  
  **回避:** `.gitignore` + pre-commit secret scan（gitleaks等）

- **ミス:** Terraform stateをローカル平文で放置  
  **回避:** リモートbackend + 暗号化 + アクセス制御

- **ミス:** CIに長期キーを置きっぱなし  
  **回避:** OIDC Federationで短命資格情報に移行

---

### 7) One interview-style question
あなたが新規プロジェクトの初期設計担当です。  
**「開発速度を落とさずにLeast Privilegeを実装するには？」** を、
- IAM設計
- CI/CD
- 監査ログ
の3観点で5分で説明してください。

---

### 8) Next-step reading links
- OWASP Top 10: https://owasp.org/www-project-top-ten/
- AWS IAM Best Practices: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- Google Cloud IAM Overview: https://cloud.google.com/iam/docs/overview
- Kubernetes Security Checklist: https://kubernetes.io/docs/concepts/security/
- OpenTelemetry Docs: https://opentelemetry.io/docs/
- Prometheus Docs: https://prometheus.io/docs/
- Grafana Docs: https://grafana.com/docs/

---

## Rotation Preview（トピック循環の見取り図）
- Day A（Beginner）: Cloud Security + Secrets基礎
- Day B（Middle）: Observability（Prometheus/Grafana/OpenTelemetry）
- Day C（Advanced）: Kubernetes incident drills（failure/rollback/recovery）
- Day D（Beginner）: OWASP + Secure Coding
- Day E（Middle）: Docker hardening + Linux運用
- Day F（Advanced）: Terraform/IaC security + policy as code

> **Middleの前提条件:** Linux基本コマンド、Dockerイメージ/コンテナ基礎、HTTP認証の基本  
> **Advancedの前提条件:** Middle内容の実践経験、Kubernetes基礎運用、CI/CDパイプライン編集経験
