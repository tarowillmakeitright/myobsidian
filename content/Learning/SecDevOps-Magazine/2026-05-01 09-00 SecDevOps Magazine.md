# SecDevOps Magazine — 2026-05-01 (09:00)
#security #devops #docker #kubernetes #terraform #linux #cloudsecurity #observability #daily
[[Home]]

---

## 今日のテーマ + レベル
**Cloud Security (AWS/GCP IAM & Permission Design) — Beginner**

> 学習アーク: **Beginner → Middle → Advanced** を3回繰り返す設計で進行します。  
> 今号はアーク1のBeginner（基礎固め）です。

### 今後のローテーション予定（抜粋）
- AppSec: Secure Coding / OWASP / Threat Modeling / Auth & Session / Incident Response
- DevOps Core: Docker Hardening / Kubernetes Fundamentals & Security / Terraform & IaC / Linux Mastery / CI/CD Security / Secrets Management
- Required Tracks:
  - Cloud Security（AWS/GCP IAM）
  - Observability（Prometheus/Grafana/OpenTelemetry）
  - Kubernetes Incident Drills（failure/rollback/recovery）

---

## 1) なぜ実務で重要か
IAM設計は、クラウド環境の**被害範囲（blast radius）**を決めます。  
実務では「侵入を100%防ぐ」よりも、侵入後に**横展開させない**設計が現実的です。

- 誤った `*:*` 権限は、単一の漏えいから大規模事故に直結
- 最小権限（least privilege）により事故時の影響を限定
- 監査（CloudTrail / Audit Logs）と組み合わせるとインシデント対応が速くなる

---

## 2) コア概念（わかりやすく）

### A. Principal / Action / Resource / Condition
IAMの基本は「**誰が（Principal）**、**何を（Action）**、**どれに（Resource）**、**どんな条件で（Condition）**」です。

### B. Deny優先
多くのIAM評価では、`Deny` が `Allow` より優先されます。  
危険操作を明示的にDenyする設計は事故予防に有効です。

### C. Role中心設計（人に直接権限を付けない）
ユーザーへ直接付与ではなく、Role/Groupベースで管理。  
退職・異動・権限見直し時の運用負荷を減らせます。

### D. 一時クレデンシャル優先
長期Access Keyの常用を避け、STS等の短命トークンを優先。  
漏えい時の有効期間を短くできます。

### E. 権限境界とレビュー
Permission Boundary / 組織ポリシー / 定期レビューを使い、
「開発スピードを落とさずに安全側へ寄せる」ことが重要です。

---

## 3) Hands-on Mini Lab（30–60分）
**目的:** 過剰権限を検出し、最小権限ポリシーに落とす流れを体験

### 手順
1. サンプルポリシーを作る（まずは過剰）
2. `Action` と `Resource` を絞る
3. 危険操作にDenyを追加
4. `aws iam simulate-principal-policy`（または同等機能）で確認
5. 変更前後で「可能操作の差」を記録

### 期待アウトプット
- Before/Afterポリシー（JSON）
- 許可操作一覧の差分メモ
- 「削れなかった権限」と理由

---

## 4) Command Cheatsheet

### Linux
```bash
# JSON整形
cat policy.json | jq .

# 差分確認
diff -u policy_before.json policy_after.json
```

### AWS CLI（例）
```bash
# アカウント確認
aws sts get-caller-identity

# ポリシーシミュレーション（例）
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::123456789012:role/AppRole \
  --action-names s3:GetObject s3:PutObject s3:DeleteObject \
  --resource-arns arn:aws:s3:::my-bucket/*
```

### GCP（例）
```bash
# 現在プロジェクト確認
gcloud config get-value project

# IAMポリシー確認
gcloud projects get-iam-policy <PROJECT_ID>
```

### Terraform（IAMをコード化する場合）
```bash
terraform fmt
terraform validate
terraform plan
```

---

## 5) よくあるミスと回避策

1. **`Action: "*"`, `Resource: "*"`の常用**  
   - 回避: まず監査ログで実使用Actionを収集してから絞る

2. **人ユーザーに直接ポリシー付与**  
   - 回避: Group/Role経由に統一し、例外を台帳管理

3. **長期キーの放置**  
   - 回避: 一時クレデンシャル優先、ローテーション自動化

4. **検証なしで本番反映**  
   - 回避: simulate / staging / canary反映の3段階

5. **Deny設計を怖がる**  
   - 回避: 重大破壊系（削除・権限昇格）から段階導入

---

## 6) Interview-style Question
「開発速度を落とさずに、IAMを最小権限へ移行する計画をどう設計しますか？  
技術面（ロール設計・監査・自動検証）と運用面（例外管理・レビュー頻度）を分けて説明してください。」

---

## 7) Next-step Reading Links
- OWASP Top 10: https://owasp.org/www-project-top-ten/
- AWS IAM Best Practices: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- Google Cloud IAM Overview: https://cloud.google.com/iam/docs/overview
- NIST Least Privilege (concept): https://csrc.nist.gov/glossary/term/least_privilege
- OpenTelemetry Docs: https://opentelemetry.io/docs/
- Kubernetes Security Checklist (CNCF related refs): https://kubernetes.io/docs/concepts/security/

---

## Difficulty Progression Notes
- **本号:** Beginner（前提知識なしでOK）
- **次のMiddle号の前提:**
  - IAM基本用語（Principal/Action/Resource/Condition）
  - JSONポリシーを読める
  - CLIで現在権限を確認できる
- **次のAdvanced号の前提:**
  - 権限境界（Boundary）と組織ポリシー運用経験
  - IaCでIAMを管理した経験
  - 監査ログから権限改善につなげた経験

次号は **Observability（Prometheus/Grafana/OpenTelemetry）— Middle** を予定。