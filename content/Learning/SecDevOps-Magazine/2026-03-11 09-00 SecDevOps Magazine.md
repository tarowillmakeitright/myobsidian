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

# SecDevOps Magazine — 2026-03-11 (09:00)

## 今日の学習アーク
- **Arc 03 / Day 1**
- **Level:** Beginner（次回: Middle → 次々回: Advanced）
- **今日の主題:** **Cloud Security 基礎（AWS/GCP IAM と Permission設計）**

> Middle/Advanced回では、今日の内容（IAMの基本概念・最小権限・ロール分離）を前提として進みます。

---

## 1) Topic + Level
**Cloud Security: IAM & Permission Design 入門（Beginner）**

---

## 2) なぜ実務で重要か
本番障害や情報漏えいの多くは、ゼロデイよりも**権限過多（over-privileged access）**から始まります。  
開発者・CI/CD・運用者の権限を適切に分離できると、以下が実現できます。

- 侵害時の被害範囲を最小化（blast radius reduction）
- 監査対応（誰が何をしたか）を容易化
- 誤操作による本番事故を防止
- DevOps速度を保ちながら安全性を向上

---

## 3) Core concepts（やさしく要点）

### A. IAMの基本
- **Principal**: ユーザー/ロール/サービスアカウント（操作主体）
- **Action**: 実行したい操作（例: `s3:GetObject`, `compute.instances.get`）
- **Resource**: 対象リソース（バケット、VM、Secretなど）
- **Condition**: 条件（IP制限、MFA必須、時間帯など）

許可は「誰が」「何を」「どこに」「どの条件で」を明確にすると設計しやすくなります。

### B. 最小権限（Least Privilege）
最初から広い権限を与えず、必要操作だけを許可します。  
コツは **Read-only → 必要分だけWrite追加** の順で設計すること。

### C. 人とマシンの権限分離
- 人間（開発者・運用者）: SSO + MFA + 短期セッション
- マシン（CI/CD, Workload）: ロール/Workload Identity + 短命トークン

長期固定キーの配布は可能な限り避けます。

### D. 職務分離（Separation of Duties）
- 開発者: アプリ更新は可能、IAM変更は不可
- セキュリティ管理者: IAMポリシー管理
- CI/CD: デプロイ対象環境限定の権限

### E. 監査可能性（Auditability）
CloudTrail / Cloud Audit Logs などで、認証失敗・権限エラー・特権操作を追跡可能にします。

---

## 4) Hands-on mini lab（30–60分）
**Lab: 「CI/CD用ロールを最小権限で作る」**

### ゴール
- バケットへの読み取りと、特定プレフィックスへの書き込みのみ許可
- IAM変更や削除操作は不可

### 手順（AWS例、概念はGCPでも同様）
1. ダミーS3バケットを用意（例: `secdevops-lab-artifacts`）
2. CI用ロール `role-ci-deploy-lab` を作成
3. 以下を満たすポリシーを付与
   - 許可: `s3:GetObject`（全体）
   - 許可: `s3:PutObject`（`releases/*` のみ）
   - 明示拒否: `s3:DeleteObject`（必要なら）
4. `aws sts assume-role` で一時認証を取得
5. できる/できない操作を検証
   - `releases/app-v1.tar.gz` へPut（成功）
   - `prod-secrets/secret.txt` へPut（失敗）
   - 任意オブジェクトDelete（失敗）
6. 結果をメモ化（成功ケース/失敗ケース/エラー文）

**発展（余力があれば）**
- CloudTrailでAPI実行履歴を確認
- GCP版で同等のRole Bindingを再現

---

## 5) Command cheatsheet

### Linux
```bash
# 直近で変更したファイル確認
find . -type f -mmin -60 | head

# 環境変数に秘密情報が紛れていないか軽く確認（共有前に）
env | grep -Ei 'key|token|secret|pass'
```

### AWS CLI（IAM検証系）
```bash
# 呼び出し主体の確認
aws sts get-caller-identity

# ロール引き受け
aws sts assume-role \
  --role-arn arn:aws:iam::<ACCOUNT_ID>:role/role-ci-deploy-lab \
  --role-session-name lab

# S3操作テスト
aws s3 cp ./app-v1.tar.gz s3://secdevops-lab-artifacts/releases/app-v1.tar.gz
aws s3 cp ./secret.txt s3://secdevops-lab-artifacts/prod-secrets/secret.txt
```

### Terraform（IAMをコード化）
```bash
terraform fmt
terraform validate
terraform plan
```

### Kubernetes（将来の連携確認）
```bash
kubectl auth can-i get pods -n production
kubectl auth can-i create secrets -n production
```

---

## 6) Common mistakes と回避策
1. **`*` 権限を多用してしまう**  
   - 回避: action/resourceを明示し、Conditionを活用する

2. **人とCIが同じ権限セット**  
   - 回避: 人間用ロールとマシン用ロールを分離する

3. **長期Access Keyを放置**  
   - 回避: 短期トークン中心、ローテーションを自動化

4. **拒否系テストをしない**  
   - 回避: 「失敗すること」を必ずテストケースに入れる

5. **監査ログを有効化しただけで見ていない**  
   - 回避: 週次で高リスク操作イベントをレビュー

---

## 7) Interview-style question
CI/CDのデプロイロール設計で、なぜ「最小権限 + 一時クレデンシャル + 職務分離」の3点セットが重要ですか？  
実際の障害/侵害シナリオを1つ挙げて説明してください。

---

## 8) Next-step reading links
- OWASP ASVS: https://owasp.org/www-project-application-security-verification-standard/
- AWS IAM best practices: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- GCP IAM overview: https://cloud.google.com/iam/docs/overview
- CIS Benchmarks (Cloud/K8s/Linux): https://www.cisecurity.org/cis-benchmarks
- OpenTelemetry Docs: https://opentelemetry.io/docs/
- Kubernetes Security Checklist: https://kubernetes.io/docs/concepts/security/

---

## ローテーション計画（固定トラックを循環）
以下を**Beginner → Middle → Advanced**で回し続けます。

1. Application Security（secure coding / OWASP / threat modeling / auth-session / incident response）
2. DevOps Core（Docker hardening / Kubernetes fundamentals-security / Terraform-IaC / Linux mastery / CI-CD security / secrets management）
3. **Cloud Security（AWS/GCP IAM & permission design）**
4. **Observability（Prometheus / Grafana / OpenTelemetry）**
5. **Kubernetes incident drills（failure / rollback / recovery）**

### 次号予告（Middle）
- テーマ: **Observability実践（SLI/SLO、OpenTelemetry計装、Grafana可視化）**
- 前提知識: Linux基本コマンド、HTTP基礎、今日のIAM基礎
