# SecDevOps Magazine — 2026-04-03 (09:00)
[[Home]]

#security #devops #docker #kubernetes #terraform #linux #cloudsecurity #observability #daily

## 今日のIssue
### 1) Topic + Level
**Cloud Security (AWS/GCP IAM & Permission Design) + Beginner**

> 学習アーク: **Beginner → Middle → Advanced** を3日単位で循環
> - Day 1 (今日): IAM基礎と最小権限（Beginner）
> - Day 2: クロスアカウント/組織設計・権限境界（Middle, 前提: IAM基礎）
> - Day 3: 権限昇格パス検出と防御設計（Advanced, 前提: Day1-2 + ログ分析）

---

### 2) Why it matters in real projects
クラウド侵害の多くは「ゼロデイ」よりも**過剰権限**や**誤設定**が起点です。  
開発速度を落とさずに安全性を上げるには、最初に IAM を正しく設計するのが最短ルートです。

- CI/CDトークンに Admin 権限がある → 1つ漏れるだけで全環境が危険
- 人間ユーザーに恒久キーを配る → 監査不能 + ローテーション漏れ
- 誰が何をできるか曖昧 → インシデント時に封じ込め不能

---

### 3) Core concepts (clear explanations)
1. **Principal / Action / Resource / Condition**
   - IAMポリシーは「誰が」「何を」「どの資源に」「どんな条件で」行えるか。
2. **Least Privilege（最小権限）**
   - 初期は狭く、必要に応じて拡張。`*` は最後の手段。
3. **Deny優先**
   - AWS/GCPともに「許可より明示的拒否が強い」設計を理解する。
4. **Role中心運用**
   - ユーザーに直接権限を盛らず、Role/Service Account経由で付与。
5. **短期認証情報（Short-lived credentials）**
   - 恒久キーより STS/OIDC 等を優先し、漏えい時の被害時間を短縮。
6. **監査ログ前提**
   - CloudTrail / Cloud Audit Logs を「後で見るもの」ではなく「設計要件」に。

---

### 4) Hands-on mini lab (30–60 min)
**Lab: “CIジョブ用ロールを最小権限で作る”**（45分目安）

#### ゴール
- S3バケット（artifact用）への `GetObject/PutObject` だけ許可
- それ以外は不可
- 監査ログに操作を残す

#### 手順（AWS例）
1. テスト用バケットを作成（例: `secdevops-artifacts-demo`）
2. CI用Roleを作成（信頼ポリシーはOIDC or 限定Principal）
3. インラインポリシーで `s3:GetObject`, `s3:PutObject` のみ許可
4. `aws sts assume-role` で一時資格情報を取得
5. 許可操作（upload/download）は成功、禁止操作（list all buckets等）は失敗を確認
6. CloudTrailでイベント確認（誰が/いつ/何を実行したか）

#### 完了条件
- 想定操作のみ成功
- 想定外操作は AccessDenied
- ログで追跡可能

---

### 5) Command cheatsheet
```bash
# Linux: 現在の環境変数から資格情報を確認
env | grep -E 'AWS_|GOOGLE_'

# AWS: 現在のID確認
aws sts get-caller-identity

# AWS: バケットへのアップロード(許可操作)
aws s3 cp ./demo.txt s3://secdevops-artifacts-demo/demo.txt

# AWS: 全バケット一覧(今回の最小権限では通常失敗)
aws s3 ls

# Docker: 実行中コンテナの権限ざっくり確認
docker ps
docker inspect <container_id> --format '{{.HostConfig.Privileged}}'

# Kubernetes: 現在コンテキストと権限確認の入口
kubectl config current-context
kubectl auth can-i get secrets -A

# Terraform: 変更前レビュー
terraform init
terraform plan
```

---

### 6) Common mistakes and how to avoid them
1. **`Action: "*"` を常用する**
   - 回避: まず read-only / 単一サービスから開始。CloudTrailで必要権限を追加。
2. **ユーザー直付けポリシーを乱発**
   - 回避: グループ/Role/Service Accountに集約。
3. **長期アクセスキーをCIに保存**
   - 回避: OIDC連携 + 一時クレデンシャルへ移行。
4. **監査ログを有効化して満足**
   - 回避: 「アラート条件」までセット（例: 異常な AssumeRole, root相当操作）。
5. **本番でいきなり適用**
   - 回避: ステージングで権限テスト→本番反映。

---

### 7) One interview-style question
あなたがチームの最初のセキュリティ担当として参加しました。  
「開発速度を落とさずに IAM を強化したい」と言われたとき、**最初の2週間で何を優先し、なぜか**を説明してください。

---

### 8) Next-step reading links
- OWASP Top 10: https://owasp.org/www-project-top-ten/
- AWS IAM Best Practices: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- Google Cloud IAM Best Practices: https://cloud.google.com/iam/docs/best-practices
- NIST Least Privilege overview: https://csrc.nist.gov/glossary/term/least_privilege
- Kubernetes RBAC: https://kubernetes.io/docs/reference/access-authn-authz/rbac/

---

## Rotation roadmap (必修トラック網羅)
以下を循環させ、毎回 Beginner → Middle → Advanced の順で進行:

1. Application Security（secure coding / OWASP / threat modeling / auth-session / incident response）
2. DevOps Core（Docker hardening / Kubernetes fundamentals-security / Terraform-IaC / Linux command mastery / CI-CD security / secrets management）
3. Cloud Security（AWS/GCP IAM & permission design）
4. Observability（Prometheus / Grafana / OpenTelemetry）
5. Kubernetes incident drills（failure / rollback / recovery）

次号予告（Middle）: **IAM権限境界 + 組織設計 + CI/CDフェデレーション実装**（前提: 今日のIAM基礎）
