# SecDevOps Magazine — 2026-04-04 (09:00)
[[Home]]

#security #devops #docker #kubernetes #terraform #linux #cloudsecurity #observability #daily

## 今日のIssue
### 1) Topic + Level
**Cloud Security (AWS/GCP IAM & Permission Design) + Middle**

> 学習アーク: **Beginner → Middle → Advanced** を3日単位で循環
> - Day 1: IAM基礎と最小権限（Beginner）
> - Day 2 (今日): クロスアカウント/組織設計・権限境界（Middle）
> - Day 3: 権限昇格パス検出と防御設計（Advanced）
>
> **前提知識（Prerequisites）**
> - IAM の基本要素（Principal / Action / Resource / Condition）
> - Least Privilege の考え方
> - CloudTrail / Cloud Audit Logs の基本

---

### 2) Why it matters in real projects
実案件では、単一アカウント運用からマルチアカウント/マルチプロジェクトへ拡張した瞬間に、権限管理の難易度が急上昇します。

- 開発・本番・監査で責務分離しないと、事故時の影響範囲が広がる
- CI/CD が複数環境をまたぐと、信頼境界（Trust Boundary）が曖昧になりやすい
- 「とりあえず管理者権限」で回すと、後から是正コストが爆増する

Middleレベルでは、**組織構造に合わせた権限設計**をできるようになるのが目的です。

---

### 3) Core concepts (clear explanations)
1. **Account/Project 分離（環境分離）**
   - `dev / stg / prod / security` を論理分離し、侵害時の横展開を抑える。
2. **Cross-account access（AWS AssumeRole / GCP Workload Identity Federation）**
   - 人やCIが直接キーを持たず、信頼関係経由で短期権限を取得する。
3. **Permission Boundary / SCP / Organization Policy**
   - 個別ロールの許可だけでなく、上位レイヤーで「超えてはいけない線」を定義。
4. **JITアクセス（Just-In-Time）**
   - 常時高権限を持たせず、必要時だけ時間制限付きで昇格。
5. **Tag/Labelベース制御（ABAC）**
   - `env=prod`, `team=platform` など属性でアクセス制御し、運用負荷を下げる。
6. **監査可能性（Traceability）**
   - 「誰が」「どこから」「どのロールで」「何をしたか」を追跡可能に設計する。

---

### 4) Hands-on mini lab (30–60 min)
**Lab: “CI/CD のクロスアカウント権限を安全に設計する”**（50分目安）

#### ゴール
- CIが `dev` アカウントから `prod` へデプロイ可能（最小権限のみ）
- 許可外操作は拒否
- 監査ログで追跡可能

#### 手順（AWS例）
1. `dev` と `prod` の2アカウント（または擬似環境）を想定
2. `prod` 側に `DeployRole` を作成し、信頼ポリシーを `dev` のCIロールに限定
3. `DeployRole` の許可を対象サービスの必要アクションだけに絞る（例: ECS更新、S3 artifact取得）
4. Permission Boundary または SCP で危険操作（例: `iam:*`, `organizations:*`）を明示制限
5. `dev` から `aws sts assume-role` 実行
6. 許可操作（デプロイ）は成功、禁止操作（IAM変更）は失敗を確認
7. CloudTrailで AssumeRole と実操作イベントを確認

#### 完了条件
- CI経由の必要操作のみ成功
- 高リスク操作は AccessDenied
- ログから実行主体と操作内容を辿れる

---

### 5) Command cheatsheet
```bash
# Linux: jqでCloudTrailイベントをざっくり確認（ローカルJSON想定）
jq '.Records[] | {eventTime, eventName, userIdentity: .userIdentity.arn}' cloudtrail.json

# AWS: ロール引き受け
aws sts assume-role \
  --role-arn arn:aws:iam::<prod-account-id>:role/DeployRole \
  --role-session-name ci-deploy-test

# AWS: 現在の実行主体を確認
aws sts get-caller-identity

# AWS: 許可された操作例（環境に合わせて変更）
aws ecs update-service --cluster app-cluster --service web --force-new-deployment

# AWS: 禁止されるべき操作例
aws iam create-user --user-name should-fail

# Kubernetes: 運用者視点の権限確認
kubectl auth can-i create deployments -n prod
kubectl auth can-i get secrets -n prod

# Terraform: IAM変更レビューを必ず先に
terraform fmt
terraform validate
terraform plan
```

---

### 6) Common mistakes and how to avoid them
1. **信頼ポリシーの Principal を広くしすぎる**
   - 回避: 特定ロール/特定OIDC subjectに限定。ワイルドカードを避ける。
2. **Permission Boundary/SCP を後回しにする**
   - 回避: 初期設計でガードレールを先に作る。
3. **CIに長期キーを残す**
   - 回避: OIDC + AssumeRole へ移行し、キーを廃止。
4. **監査ログを見ない運用**
   - 回避: “失敗ログ” も監視し、権限誤設定の早期発見につなげる。
5. **Terraform apply直前まで権限変更をレビューしない**
   - 回避: `plan` 差分レビューをPR必須にする。

---

### 7) One interview-style question
あなたは新しいSaaS基盤で `dev/stg/prod` を分離する設計担当です。
**「開発速度を維持しつつ、prod へのアクセスを最小化する IAM 設計」**を、
- ロール構成
- CI/CD の認証方式
- 監査ログ運用
の3点で説明してください。

---

### 8) Next-step reading links
- AWS IAM: Cross-account access: https://docs.aws.amazon.com/IAM/latest/UserGuide/tutorial_cross-account-with-roles.html
- AWS Organizations SCP: https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scps.html
- Google Cloud IAM best practices: https://cloud.google.com/iam/docs/best-practices
- Workload Identity Federation (GCP): https://cloud.google.com/iam/docs/workload-identity-federation
- NIST Zero Trust Architecture (SP 800-207): https://csrc.nist.gov/publications/detail/sp/800-207/final

---

## Rotation roadmap (必修トラック網羅)
以下を循環し、毎回 Beginner → Middle → Advanced の順で進行:

1. Application Security（secure coding / OWASP / threat modeling / auth-session / incident response）
2. DevOps Core（Docker hardening / Kubernetes fundamentals-security / Terraform-IaC / Linux command mastery / CI-CD security / secrets management）
3. Cloud Security（AWS/GCP IAM & permission design）
4. Observability（Prometheus / Grafana / OpenTelemetry）
5. Kubernetes incident drills（failure / rollback / recovery）

次号予告（Advanced）: **IAM権限昇格パスの発見・封じ込め演習（attack path → defensive controls）**（前提: Day1-2）
