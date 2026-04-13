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

# SecDevOps Magazine — 2026-04-13

## 今日の学習アーク
- **Arc:** Cloud Security × DevOps Foundations
- **Level:** **Beginner**
- **進行:** Beginner → Middle → Advanced を3日サイクルで反復
- **次回予告:**
  - Day 2 (Middle): IAM権限境界 + Terraformで最小権限設計（前提: 今日のIAM基礎）
  - Day 3 (Advanced): マルチアカウント権限事故のインシデント対応演習（前提: IAM評価ロジック、IaC運用）

---

## 1) Topic + Level
**Topic:** Cloud Security（AWS/GCP IAM & permission design 入門）
**Level:** Beginner

---

## 2) なぜ実務で重要か
クラウド事故の多くは、0dayより先に**権限ミス（過剰権限・公開設定ミス）**で起こります。  
IAM設計を正しく始めると、以下が一気に改善します。
- 侵害時の被害範囲を最小化（blast radius削減）
- 監査対応が速くなる（誰が何をできるか説明可能）
- 開発速度を落とさず安全性を維持（Role分離で運用しやすい）

---

## 3) Core concepts（わかりやすく）
1. **Identity と Permission は分けて考える**
   - Identity: 「誰か」（User/Service Account/Role）
   - Permission: 「何ができるか」（Policy/Role Binding）

2. **最小権限（Least Privilege）**
   - 必要な操作だけ許可。`*` は原則禁止。

3. **Deny 優先の考え方**
   - AWSでは明示DenyがAllowより強い。
   - GCPでも組織ポリシー等で禁止ガードをかける。

4. **人間ユーザーに長期キーを持たせない**
   - 可能な限り一時クレデンシャル（STS / Workload Identity）へ。

5. **職務分離（Separation of Duties）**
   - 開発者、運用者、監査者でRoleを分離。

---

## 4) Hands-on mini lab（30〜60分）
**目標:** 「読み取り専用ロール」と「デプロイ専用ロール」を分け、過剰権限を検知する。

### 手順
1. TerraformでIAMロールを2種類定義
   - `app-readonly`
   - `app-deployer`
2. `app-deployer` から不要な権限（例: IAM管理権限）を削除
3. policy simulator / access analyzer 相当で検証
4. CIで `terraform fmt`, `terraform validate`, `terraform plan` を実行
5. 結果を「許可した操作一覧」としてノート化

**完成条件**
- 読み取りロールで書き込み不可
- デプロイロールでIAM改変不可
- Plan差分が説明できる

---

## 5) Command cheatsheet
### Linux
```bash
# 直近編集ファイル確認
ls -lt

# 変更差分確認（Git管理時）
git status && git diff
```

### Terraform
```bash
terraform init
terraform fmt -recursive
terraform validate
terraform plan -out=tfplan
terraform show -no-color tfplan > plan.txt
```

### Docker（補助: 認証情報をイメージへ焼かない）
```bash
# build時に不要な秘密情報が混入していないか確認
docker history <image>:<tag>
```

### Kubernetes（将来の連携用）
```bash
# 現在の権限確認（K8s RBAC）
kubectl auth can-i get pods -A
kubectl auth can-i create deployments -n default
```

---

## 6) よくあるミスと回避策
1. **`Action: "*"` / `roles/owner` を常用**
   - 回避: 最初は広め→ログ観測→不要権限を削る「絞り込み運用」へ。

2. **本番・検証で同一ロール共有**
   - 回避: 環境ごとにRole分離（prod/stg/dev）。

3. **人間ユーザーに固定アクセスキー配布**
   - 回避: SSO + 一時認証。キー棚卸しを定期実施。

4. **権限変更レビューがない**
   - 回避: PR必須 + CIでPolicy lint/静的チェック。

---

## 7) 面接っぽい一問
「“最小権限”を実現しつつ開発速度を落とさないために、あなたならIAM運用をどう設計しますか？  
具体的に、申請フロー・監査ログ・ロールテンプレートの3点で説明してください。」

---

## 8) Next-step reading links
- OWASP Top 10: https://owasp.org/www-project-top-ten/
- AWS IAM Best Practices: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- Google Cloud IAM overview: https://cloud.google.com/iam/docs/overview
- Terraform Security Best Practices (HashiCorp Learn): https://developer.hashicorp.com/terraform/tutorials/security
- OpenTelemetry Docs: https://opentelemetry.io/docs/
- Prometheus Docs: https://prometheus.io/docs/introduction/overview/
- Grafana Docs: https://grafana.com/docs/
- Kubernetes Security Checklist (CNCF): https://kubernetes.io/docs/concepts/security/

---

## ローテーション計画（トラック消化管理）
- Application Security: secure coding / OWASP / threat modeling / auth-session / incident response
- DevOps Core: Docker hardening / Kubernetes fundamentals-security / Terraform-IaC / Linux mastery / CI-CD security / secrets management
- Added tracks: Cloud Security / Observability / Kubernetes incident drills

**運用ルール:** 各トラックを週内で最低1回取り上げ、難易度は Beginner → Middle → Advanced の順で循環。Middle/Advanced 回では前提知識を明記する。
