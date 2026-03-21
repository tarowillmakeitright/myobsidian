---
title: "SecDevOps Magazine"
date: 2026-03-21 09:00
tags: [security, devops, docker, kubernetes, terraform, linux, cloudsecurity, observability, daily]
---

# SecDevOps Magazine — 2026-03-21
[[Home]]

#security #devops #docker #kubernetes #terraform #linux #cloudsecurity #observability #daily

## 1) Topic + Level
**Cloud Security（AWS/GCP IAM & Permission Design） + Beginner**

> 学習アーク: **Cloud/IAM基礎編（Beginner）→ 権限分離実践（Middle）→ 組織横断ガードレール設計（Advanced）**

---

## 2) Why it matters in real projects
クラウド事故の多くは「ハッキング」より先に、**権限設定ミス**で起こります。  
例えば:
- 開発用ユーザーに本番削除権限がある
- CI/CD に過剰な `*` 権限を付ける
- 退職者アカウントの無効化漏れ

IAM 設計は、アプリの可用性・機密性・監査対応（法令/契約）を守る土台です。  
**最小権限（Least Privilege）**を最初から設計できると、Security と DevOps の両方が一気に強くなります。

---

## 3) Core concepts（clear explanations）
### A. Principal / Action / Resource / Condition
IAM は基本的にこの4要素で考えます。
- **Principal**: 誰が（ユーザー、ロール、サービスアカウント）
- **Action**: 何を（`s3:GetObject` / `compute.instances.get` など）
- **Resource**: どこに（バケット、プロジェクト、特定リソース）
- **Condition**: どんな条件で（IP、MFA、有効期限、タグ）

### B. Allow は足し算、Deny は最優先
- 許可（Allow）は積み上がる
- **明示的 Deny が常に優先**

### C. 人とシステムの権限を分離
- 人間: SSO + 短期認証 + 監査ログ
- システム: ロール/サービスアカウント + キーレス優先

### D. ロールベース運用
個人単位ではなく、役割（例: `app-readonly`, `ci-deployer`）単位で設計することで、保守性が上がります。

### E. 前提知識（Beginner向け）
- Linux基本コマンド（`cat`, `grep`, `jq`）
- JSON/YAML を読む力

---

## 4) Hands-on mini lab（30–60 min）
**テーマ:** 「読み取り専用ロール」と「過剰権限ロール」を比較し、監査観点で差を確認する

### ゴール
1. AWS/GCP で ReadOnly ロールを作る（または既存を利用）
2. わざと広すぎる権限ポリシー例（学習用）を確認
3. CLI で“できる操作”を比較
4. 最後に不要権限を削る

### 手順（安全・防御目的のみ）
1. テスト環境を用意（本番禁止）
2. ReadOnly ポリシーをアタッチした Principal を作成
3. 別途、過剰権限サンプル（例: ワイルドカード）を読み、何が危険かをメモ
4. `list/get` は通るが `delete/update` は拒否されることを確認
5. CloudTrail / Cloud Audit Logs でアクセス履歴を確認
6. 学んだ差分を「最小権限チェックリスト」にまとめる

**検証観点**
- “必要な業務”だけ通るか？
- 拒否ログが監査可能か？
- 一時的例外権限に期限を付けられているか？

---

## 5) Command cheatsheet
### Linux
```bash
# JSONポリシーの確認
cat policy.json | jq .

# 監査ログから principal を抽出（例）
grep -i "assumed-role\|serviceAccount" audit.log
```

### AWS CLI
```bash
# 呼び出し主体の確認
aws sts get-caller-identity

# ポリシーシミュレーション（許可/拒否の確認）
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::123456789012:role/app-readonly \
  --action-names s3:ListBucket s3:DeleteObject \
  --resource-arns arn:aws:s3:::example-bucket arn:aws:s3:::example-bucket/*
```

### GCP CLI
```bash
# 現在のアカウント確認
gcloud auth list

# プロジェクトのIAMバインディング確認
gcloud projects get-iam-policy PROJECT_ID --format=json | jq '.bindings[] | {role, members}'
```

### Terraform（IAMをコード化）
```bash
terraform init
terraform plan
terraform apply
```

```hcl
# 例: 読み取り専用ロール付与（GCP）
resource "google_project_iam_member" "viewer_bind" {
  project = var.project_id
  role    = "roles/viewer"
  member  = "group:dev-readonly@example.com"
}
```

---

## 6) Common mistakes and how to avoid them
1. **`Action: "*"` を常態化**  
   - 回避: まず ReadOnly + 必要権限だけ追加

2. **人間ユーザーに長期アクセスキーを配布**  
   - 回避: SSO + 短期クレデンシャルへ移行

3. **環境（dev/stg/prod）で同一ロールを使い回す**  
   - 回避: 環境ごとにロール分離、信頼ポリシーも分離

4. **例外権限が“暫定”のまま残る**  
   - 回避: 期限付き運用（チケット番号と失効日時を必須化）

5. **IaC化せずコンソール手作業のみ**  
   - 回避: Terraform 管理 + PR レビュー + CI policy check

---

## 7) One interview-style question
**Q.** 「最小権限を維持しつつ、緊急障害時にだけ強い権限を使える運用をどう設計しますか？」

（考えるヒント: Just-In-Time 権限、承認フロー、MFA、監査ログ、期限付きロール）

---

## 8) Next-step reading links
- OWASP Top 10: https://owasp.org/www-project-top-ten/
- AWS IAM Best Practices: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- Google Cloud IAM Overview: https://cloud.google.com/iam/docs/overview
- CIS Benchmarks（クラウド設定基準）: https://www.cisecurity.org/cis-benchmarks
- Terraform Security Best Practices: https://developer.hashicorp.com/terraform/tutorials/security

---

## 次号予告（Difficulty progression）
- **Middle:** Terraform で IAM 権限境界（Permission Boundary）と分離統治を実装
  - 前提: IAM JSON読解、Terraform基本操作、CLIでの検証経験
- **Advanced:** AWS/GCP 複数アカウント/プロジェクト横断の Guardrail 設計（SCP/Org Policy + 例外統制 + 監査自動化）
  - 前提: 組織構成理解、CI/CD、ログ基盤（SIEM/監査）

学習は「広く」より「小さく作って検証して改善」が最短です。今日の30分を積み上げましょう 💪