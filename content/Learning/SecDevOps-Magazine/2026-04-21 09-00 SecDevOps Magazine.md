---
tags: [security, devops, docker, kubernetes, terraform, linux, cloudsecurity, observability, daily]
---

# SecDevOps Magazine — 2026-04-21 (09:00)
[[Home]]

今日から「Beginner → Middle → Advanced」を循環させる学習アークを開始します。  
**今号のレベルは Beginner**。まずは土台を固め、次号以降で段階的に実戦力へ引き上げます。

---

## 1) Topic + Level
**Cloud Security 基礎：IAM と Permission 設計の第一歩（Beginner）**

> トラック: Cloud Security（必須追加トピック） / Application Security（認可設計） / DevOps基礎（運用時の権限管理）

---

## 2) Why it matters in real projects
本番障害や情報漏えいの多くは、脆弱なコードだけでなく**過剰権限（Over-privileged IAM）**から起こります。  
たとえば「とりあえず Administrator 権限」で運用すると、1つの認証情報漏えいが全システム侵害に直結します。

実プロジェクトで IAM 設計が効く場面:
- CI/CD の実行ロールを最小権限化して、サプライチェーン攻撃の被害範囲を限定
- 開発者・運用者・監査者の責務分離（SoD: Segregation of Duties）
- インシデント時の封じ込め（失効・ロール切替・一時権限の停止）が迅速にできる

---

## 3) Core concepts（やさしく要点）
1. **Principle of Least Privilege（最小権限の原則）**  
   必要な操作だけを許可。`*` アクションや `*` リソースを常用しない。

2. **Identity と Resource の二層で考える**
   - Identity-based policy（誰が何をできるか）
   - Resource-based policy（そのリソースを誰に開くか）

3. **Deny 優先**
   多くの評価モデルでは明示的 Deny が Allow に勝つ。安全ガードとして有効。

4. **短命資格情報（Short-lived credentials）**
   長期 Access Key を減らし、ロール引受や Workload Identity を優先。

5. **Permission Boundary / Condition 活用**
   `Condition`（IP, MFA, タグ, 時間帯）で「できる操作」をさらに絞る。

---

## 4) Hands-on mini lab（30–60 min）
**ラボ名: 「CI Bot に S3 読み取り専用権限だけを与える」**

### 目標
- 過剰権限ロール（例: `s3:*`）をやめる
- `GetObject` のみ許可されたポリシーに置き換える
- 失敗ログを見て不足権限を最小追加する流れを体験

### 手順（AWS 例）
1. テスト用バケットを1つ作る（例: `secdevops-lab-bucket`）
2. 過剰権限ポリシー（悪い例）を確認
3. 以下の最小ポリシーを作成してロールにアタッチ
4. CLI で `aws s3 cp`（ダウンロード）は成功、`aws s3 rm` は失敗することを確認
5. CloudTrail/ログで拒否イベントを確認し、意図通りか検証

**最小ポリシー例（読み取り専用）**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:GetObject"],
      "Resource": ["arn:aws:s3:::secdevops-lab-bucket/*"]
    }
  ]
}
```

---

## 5) Command cheatsheet
### Linux
```bash
# 認証情報の確認
env | grep -E 'AWS_|GOOGLE_'

# JSON整形（jq）
cat policy.json | jq .
```

### AWS CLI
```bash
aws sts get-caller-identity
aws iam create-policy --policy-name LabS3ReadOnly --policy-document file://policy.json
aws iam attach-role-policy --role-name ci-bot-role --policy-arn arn:aws:iam::<ACCOUNT_ID>:policy/LabS3ReadOnly
aws s3 cp s3://secdevops-lab-bucket/sample.txt ./sample.txt
aws s3 rm s3://secdevops-lab-bucket/sample.txt   # 失敗するのが正しい
```

### Terraform（方針の雛形）
```hcl
resource "aws_iam_policy" "lab_s3_readonly" {
  name   = "LabS3ReadOnly"
  policy = file("policy.json")
}
```

---

## 6) Common mistakes and how to avoid them
- **ミス:** `Action: "*"`, `Resource: "*"` を暫定のまま放置  
  **回避:** 期限付き TODO 化 + 週次レビューで必ず縮小

- **ミス:** 人間ユーザーに長期キー配布  
  **回避:** SSO / ロール引受 / 短命トークンを標準化

- **ミス:** CI ロールに本番書き込み権限まで付与  
  **回避:** 環境別ロール分離（dev/stg/prod）+ 承認付き昇格

- **ミス:** Deny ルール未設計  
  **回避:** 破壊的 API（削除・鍵管理）にガードレール Deny を先に敷く

---

## 7) One interview-style question
「`Allow` が付いたポリシーと `Deny` が付いたポリシーが同時にマッチした場合、最終判定はどうなるか？ その性質を利用してどんな防御設計をしますか？」

---

## 8) Next-step reading links
- OWASP Top 10: <https://owasp.org/www-project-top-ten/>
- AWS IAM Best Practices: <https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html>
- Google Cloud IAM overview: <https://cloud.google.com/iam/docs/overview>
- NIST Least Privilege (concept): <https://csrc.nist.gov/glossary/term/least_privilege>
- OpenTelemetry Docs: <https://opentelemetry.io/docs/>
- Kubernetes Security Checklist (CNCF): <https://www.cncf.io/blog/2022/10/17/kubernetes-security-checklist/>

---

## 学習アーク（ローテーション計画）
以下を**Beginner → Middle → Advanced**で循環させます。

1. AppSec: Secure Coding / OWASP / Threat Modeling / Auth-Session / Incident Response  
2. DevOps Core: Docker hardening / Kubernetes fundamentals+security / Terraform(IaC) / Linux command mastery / CI/CD security / Secrets management  
3. Added: Cloud Security（IAM） / Observability（Prometheus/Grafana/OpenTelemetry） / Kubernetes incident drills（failure/rollback/recovery）

### 次号予告（レベル進行つき）
- **Issue 2 (Middle): Docker Hardening 実践**  
  **Prerequisites:** Linux ファイル権限、コンテナ基本（image/container/volume）、本号の最小権限の考え方

- **Issue 3 (Advanced): Kubernetes Incident Drill（障害注入→Rollback→Recovery）**  
  **Prerequisites:** kubectl 基本、Deployment/Service の理解、監視メトリクスの読み取り（CPU/Memory/Error rate）

- **Issue 4 (Beginner): Observability 入門（Prometheus + Grafana + OTel の役割分担）**

このサイクルを継続し、難易度を段階的に上げながら実務で使える形に定着させます。
