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

# SecDevOps Magazine — 2026-03-09

## 今日の学習アーク
- **Arc名:** クラウド〜Kubernetes運用防衛の基礎体力づくり
- **進行:** Beginner → Middle → Advanced（3日サイクル）
- **今日の位置づけ:** **Day 1 / Beginner**
- **次回予告:**
  - Day 2 (Middle): Observability（Prometheus/Grafana/OpenTelemetry）で「異常の早期検知」
  - Day 3 (Advanced): Kubernetes incident drill（障害注入→rollback→recovery）

---

## 1) Topic + Level
**Topic:** Cloud Security（AWS/GCP IAM & permission design）入門：最小権限（Least Privilege）を実装する  
**Level:** **Beginner**

---

## 2) Why it matters in real projects
本番事故の多くは「攻撃そのもの」だけでなく、**権限が広すぎる設計ミス**で被害が拡大します。  
たとえば CI/CD 用の認証情報に `*` 権限があると、1つ漏えいしただけで S3/Secrets/Compute まで連鎖的に侵害される可能性があります。

IAM 設計は、AppSec の観点（被害最小化）と DevOps の観点（運用自動化の安全性）の交点です。  
**最小権限 + 役割分離 + 短期クレデンシャル**は、チーム開発の実戦で最も効く防御策の1つです。

---

## 3) Core concepts（やさしく）
1. **Principal（誰が）**
   - Human user / service account / role
2. **Action（何を）**
   - 例: `s3:GetObject`, `logs:PutLogEvents`
3. **Resource（どこに）**
   - 例: 特定バケット、特定プロジェクトのログのみ
4. **Condition（どんな条件で）**
   - 例: 特定IP、MFAあり、特定タグ付きリソース
5. **Deny優先**
   - Allow より明示的 Deny が強い（AWS/GCPで挙動差はあるが原則として重要）
6. **Role-based access + temporary credentials**
   - 固定キー配布を減らし、AssumeRole / Workload Identity を使う

**AppSec接続:** OWASP の Broken Access Control 対策の土台  
**DevOps接続:** CI/CD・Terraform 実行権限の最小化

---

## 4) Hands-on mini lab（30–60分）
### 目標
「読み取り専用ログ閲覧ロール」を作り、不要権限を削る。

### シナリオ（ローカル検証向け）
- Terraform で IAM role/policy を定義
- 対象は CloudWatch Logs（または GCP Logging）**読み取りのみ**
- 失敗例（広すぎる権限）→ 改善（最小権限）まで行う

### 手順
1. **初期ポリシー（わざと過剰）**を作る
   - `logs:*` + `Resource: *`
2. CLIで「実際に必要な操作」を確認
   - ロググループ一覧取得、特定ログ閲覧のみ
3. ポリシーを絞る
   - `logs:DescribeLogGroups`, `logs:FilterLogEvents` など必要最小限へ
   - Resource を対象ロググループARNへ限定
4. 再テスト
   - 必要操作は成功、不要操作（削除等）は拒否されることを確認
5. 学びを記録
   - 「必要Action一覧」「拒否されたAction」「次回の改善点」をメモ

**完了条件**
- 読み取りは通る
- 書き込み/削除は拒否
- Terraform コードにコメントで意図を残す

---

## 5) Command cheatsheet
```bash
# Linux: まずは手元確認
whoami
uname -a

# AWS CLI: 現在の認証主体確認
aws sts get-caller-identity

# CloudWatch Logs 参照（例）
aws logs describe-log-groups --max-items 5
aws logs filter-log-events \
  --log-group-name "/aws/lambda/sample-func" \
  --max-items 5

# Terraform: 安全な基本フロー
terraform fmt
terraform validate
terraform plan -out=tfplan
terraform apply tfplan

# 変更差分の確認（IaC運用で必須）
terraform show -json tfplan | jq '.resource_changes[] | {address, change: .change.actions}'

# Docker/K8s（今日の補助）
docker scout quickview 2>/dev/null || true
kubectl auth can-i get pods -A
```

---

## 6) Common mistakes and how to avoid them
1. **`Action: *` を残す**
   - 回避: 実行ログを見て必要 Action を列挙してから絞る
2. **`Resource: *` のまま本番投入**
   - 回避: ARN/プロジェクト単位で限定。タグ条件も活用
3. **人間ユーザーに長期アクセスキーを配布**
   - 回避: ロール引受（AssumeRole）/ SSO / Workload Identity
4. **CI/CD に管理者権限を与える**
   - 回避: パイプライン段階ごとにロール分離（build/deploy/read-only）
5. **失敗時の検証をしない**
   - 回避: 「拒否されるべき操作」を必ずテスト項目に含める

---

## 7) One interview-style question
あなたが新規プロジェクトの CI/CD 権限を設計するなら、  
**「開発速度を落とさず最小権限を実現する手順」**をどう定義しますか？  
（設計方針、ロール分離、監査、運用改善サイクルまで説明してください）

---

## 8) Next-step reading links
- OWASP Top 10（Access Controlの観点）  
  https://owasp.org/www-project-top-ten/
- AWS IAM Best Practices  
  https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- Google Cloud IAM Overview  
  https://cloud.google.com/iam/docs/overview
- Terraform Security Best Practices（HashiCorp）  
  https://developer.hashicorp.com/terraform/tutorials/configuration-language/security
- Kubernetes RBAC 公式  
  https://kubernetes.io/docs/reference/access-authn-authz/rbac/
- OpenTelemetry Docs（次回予習）  
  https://opentelemetry.io/docs/

---

## Prerequisites for upcoming levels
- **Middle（Observability回）に必要:**
  - `kubectl get/describe/logs` の基本
  - メトリクス/ログ/トレースの違いを説明できる
  - Prometheus の scrape 概念を知っている
- **Advanced（K8s Incident Drill回）に必要:**
  - Deployment / Rollout / ReplicaSet の関係理解
  - `kubectl rollout undo` と readiness/liveness probe の基本
  - 障害時の初動（影響範囲確認→切り戻し→再発防止）の流れ

---

今日の一言:  
**「守りやすいシステムは、速く作れるシステムでもある。」**  
まずは最小権限を “書いて・当てて・壊して確かめる” ところから始めよう。