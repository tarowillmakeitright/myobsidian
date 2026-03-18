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

# SecDevOps Magazine — 2026-03-18

## 今日のテーマ + Level
**Cloud Security 入門: IAM Permission Designの基本（AWS/GCP）**  
**Level: Beginner**

> 学習アーク（3日サイクル）: **Beginner → Middle → Advanced** を反復  
> - Day 1（今日）: IAM設計の基礎（Beginner）  
> - Day 2（次回）: 最小権限 + TerraformでIAM管理（Middle）※Prerequisite: IAM基礎理解、JSON policy読解  
> - Day 3（次々回）: 権限昇格経路の脅威モデリング + 監査自動化（Advanced）※Prerequisite: Day1-2 + CloudTrail/監査ログの基礎

---

## 1) なぜ実務で重要か
本番障害やインシデントの多くは「コードの脆弱性」だけでなく、**過剰権限（Overprivileged IAM）** から始まります。  
- CI/CD用のトークンに管理者権限が付いていた
- 開発用アカウントが本番リソースを削除できた
- 監査ログを読めるはずのロールが設定されていない

IAMは**クラウドの防火壁**です。ここを正しく作ると、事故の爆発半径（blast radius）を大幅に減らせます。

---

## 2) Core Concepts（やさしく）
### A. Principal / Action / Resource / Condition
IAMはほぼこの4つで考えます。  
- **Principal**: 誰が（User / Role / Service Account）
- **Action**: 何を（例: `s3:GetObject`, `ec2:StartInstances`）
- **Resource**: どこに（ARN / Project内Resource）
- **Condition**: どんな条件で（IP制限、MFA必須、時間帯など）

### B. Least Privilege（最小権限）
「できるだけ少ない許可を、必要な時間だけ」与える原則。  
最初は広めで検証し、ログを見て削るのが実践的。

### C. Roleベース設計
人に直接権限を積み上げるより、**Role（職務）単位**に集約。  
例: `app-readonly`, `deployer-staging`, `incident-responder`。

### D. 明示的Denyの重要性
Allowが複数あっても、**Denyが優先**される設計を理解すると事故防止力が上がります。

---

## 3) Hands-on Mini Lab（30〜60分）
### 目標
「S3読み取り専用Role」を作り、意図しない書き込みが拒否されることを確認する。

### 手順（AWS例）
1. テスト用バケットを作成（例: `secdevops-lab-logs`）
2. `s3:GetObject` と `s3:ListBucket` のみ許可するPolicyを作成
3. RoleにPolicyをアタッチ
4. AWS CLIでAssumeRoleして以下を検証
   - `aws s3 ls s3://secdevops-lab-logs` は成功
   - `aws s3 cp test.txt s3://secdevops-lab-logs/` は失敗
5. CloudTrailで拒否イベントを確認

### GCP版でやる場合
- Storage Object Viewerロールで同様に読み取り/書き込み挙動を比較
- Audit Logsで拒否イベントを確認

---

## 4) Command Cheatsheet
### Linux
```bash
# JSONを見やすく整形
cat policy.json | jq .

# 直近の操作ログ確認（ローカル）
history | tail -n 20
```

### AWS CLI
```bash
# 呼び出し元確認
aws sts get-caller-identity

# バケット一覧
aws s3 ls

# ロールを引き受ける（例）
aws sts assume-role \
  --role-arn arn:aws:iam::123456789012:role/s3-readonly-lab \
  --role-session-name lab-session
```

### Docker（補助: 権限付きキーをイメージに入れない確認）
```bash
# Dockerfile内のENVを確認（秘密情報混入の粗チェック）
grep -n "ENV\|ARG" Dockerfile
```

### Kubernetes（補助: kubeconfig権限チェック）
```bash
kubectl auth can-i get pods --all-namespaces
kubectl auth can-i delete deployments -n production
```

### Terraform（次回Middleへの準備）
```bash
terraform fmt
terraform validate
terraform plan
```

---

## 5) よくあるミスと回避策
1. **`*` を多用しすぎる**  
   - 回避: Action/Resourceを具体化し、レビュー時に`*`を禁止ルール化

2. **人に直接ポリシーを付ける**  
   - 回避: グループ/ロール経由に統一し、退職・異動時の運用を簡素化

3. **監査ログを見ない**  
   - 回避: CloudTrail/Audit Logsのダッシュボードを週次で確認

4. **緊急対応ロールが常時有効**  
   - 回避: Just-In-Time付与（時間制限） + 承認フロー

---

## 6) Interview-style Question
「本番環境でCI/CDロールに`AdministratorAccess`が付いていた場合、あなたならどの順序で安全に最小権限化しますか？  
“止血（短期）” と “恒久対応（中長期）” を分けて説明してください。」

---

## 7) Next-step Reading Links
- OWASP Top 10: https://owasp.org/www-project-top-ten/
- AWS IAM Best Practices: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- Google Cloud IAM Overview: https://cloud.google.com/iam/docs/overview
- CIS Benchmarks (Cloud/Kubernetes): https://www.cisecurity.org/cis-benchmarks
- OpenTelemetry Docs（Observability導入の入口）: https://opentelemetry.io/docs/
- Kubernetes Security Checklist: https://kubernetes.io/docs/concepts/security/

---

## 8) 明日への予告（Middle）
次号は **「TerraformでIAMをコード管理し、CI/CDにPolicyチェックを組み込む」** を扱います。  
Prerequisite（再掲）:  
- IAMの基本要素（Principal/Action/Resource/Condition）を説明できる
- JSON Policyを読める
- `terraform plan` の差分が読める

小さく始めて、毎日積み上げましょう。セキュアな設計は“才能”より“習慣”です。💪
