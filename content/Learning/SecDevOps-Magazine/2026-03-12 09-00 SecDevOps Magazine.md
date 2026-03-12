# 2026-03-12 SecDevOps Magazine

#security #devops #docker #kubernetes #terraform #linux #cloudsecurity #observability #daily
[[Home]]

おはようございます。今日の1本は、**Cloud Security（IAM設計）**を軸に、AppSec/DevOpsの土台を固める回です。  
このマガジンは **Beginner → Middle → Advanced** を繰り返す学習アークで進みます。

---

## 1) Topic + Level
**Topic:** Cloud Security 入門: AWS/GCP の IAM と Permission Design（最小権限）  
**Level:** **Beginner**

> 学習アーク上の位置: Arc 1 / Day 1（Beginner）

---

## 2) Why it matters in real projects
実務のインシデントでは、脆弱性そのものよりも「**権限が広すぎる**」ことが被害拡大の主因になりがちです。  
例えば、1つのCIトークン漏えいで本番環境まで操作可能だと、サービス停止・情報漏えい・改ざんが連鎖します。

IAMを正しく設計すると:
- 侵害されても被害範囲を局所化できる（blast radius縮小）
- 監査対応がしやすい（誰が何をしたか追える）
- DevOps運用（CI/CD, Terraform, K8s連携）が安全に回る

---

## 3) Core concepts（clear explanations）
1. **Principal（主体）**
   - AWS: User / Role、GCP: User / Service Account など
   - 「誰が」操作するか

2. **Permission（許可）**
   - 「何を」できるか（例: S3 readのみ）

3. **Resource Scope（対象範囲）**
   - 「どこに」効くか（全リソース `*` は最後の手段）

4. **Condition（条件）**
   - 時間帯、IP、MFA、タグ条件などで絞る

5. **Least Privilege（最小権限）**
   - まず狭く付与し、必要な分だけ増やす

6. **Separation of Duties（職務分離）**
   - 開発者・運用者・監査者の権限を分離

7. **Short-lived Credentials（短命クレデンシャル）**
   - 長期キーより、Role Assume / Workload Identity を優先

---

## 4) Hands-on mini lab（30-60 min）
**ゴール:** 「CIが必要なS3バケットだけ読める」権限を作る

### 想定時間
40分

### 手順
1. 読み取り専用バケットを1つ決める（例: `app-artifacts-prod`）
2. AWSなら IAM Role、GCPなら Service Account を作成
3. `Get/List` のみ許可する最小ポリシーを作る
4. ローカル or CIランナーから一時クレデンシャルでアクセス
5. 想定外操作（delete/write）を実行し、**拒否されることを確認**
6. CloudTrail / Cloud Logging でアクセス記録を確認

### 成功条件
- read操作は成功
- write/deleteは失敗（AccessDenied）
- 監査ログに操作主体が残る

---

## 5) Command cheatsheet
### Linux
```bash
# 環境変数の確認（秘密は表示しすぎない）
env | grep -E 'AWS|GCP|GOOGLE'

# jqでJSON整形
cat policy.json | jq .
```

### AWS CLI（例）
```bash
# 呼び出し主体を確認
aws sts get-caller-identity

# バケット一覧（許可があれば）
aws s3 ls s3://app-artifacts-prod

# 書き込みテスト（失敗するのが正）
echo test > /tmp/test.txt
aws s3 cp /tmp/test.txt s3://app-artifacts-prod/
```

### GCP CLI（例）
```bash
# 現在のアカウント確認
gcloud auth list

# バケット内容表示（権限次第）
gsutil ls gs://app-artifacts-prod

# 書き込みテスト（失敗するのが正）
gsutil cp /tmp/test.txt gs://app-artifacts-prod/
```

### Terraform（最小構成の考え方）
```hcl
# ポイント: Resourceを絞る、Actionを絞る、*を減らす
```

---

## 6) Common mistakes and how to avoid them
- **ミス1: `Action:*` + `Resource:*` を常用**
  - 回避: まずRead Onlyから開始し、必要アクションをログで追加

- **ミス2: 人間ユーザーに長期Access Keyを配布**
  - 回避: SSO + Role Assume、短命トークンに移行

- **ミス3: CIと本番運用で同じ権限を共有**
  - 回避: 環境（dev/stg/prod）ごとにRole分離

- **ミス4: 権限設計をコード管理していない**
  - 回避: TerraformでIAMをIaC化し、PRレビュー対象にする

---

## 7) One interview-style question
「最小権限を目指しているのに、開発速度が落ちるという現場で、あなたならどのようにIAM運用を設計しますか？（監査性・開発体験・安全性のトレードオフを説明してください）」

---

## 8) Next-step reading links
- OWASP Top 10: https://owasp.org/www-project-top-ten/
- AWS IAM Best Practices: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- Google Cloud IAM Overview: https://cloud.google.com/iam/docs/overview
- Kubernetes RBAC: https://kubernetes.io/docs/reference/access-authn-authz/rbac/
- OpenTelemetry Docs: https://opentelemetry.io/docs/
- Prometheus Docs: https://prometheus.io/docs/
- Grafana Docs: https://grafana.com/docs/

---

## Rotation plan（必修トラック反映）
以下の12回サイクルで、全トラックを **Beginner → Middle → Advanced** 反復で回します。

1. Cloud Security（IAM設計）- Beginner ✅ 今日
2. Secure Coding / OWASP - Middle（前提: HTTP基礎, Git）
3. Threat Modeling - Advanced（前提: DFD, STRIDE基礎）
4. Docker Hardening - Beginner
5. Kubernetes Fundamentals/Security - Middle（前提: コンテナ基礎）
6. Kubernetes Incident Drill（failure/rollback/recovery）- Advanced（前提: kubectl, Deployment戦略）
7. Terraform/IaC Best Practices - Beginner
8. CI/CD Security + Secrets Management - Middle（前提: Pipeline基礎）
9. Auth/Session Security - Advanced（前提: OAuth2/OIDC基礎）
10. Linux Command Mastery（for SRE/SecOps）- Beginner
11. Observability（Prometheus/Grafana/OpenTelemetry）- Middle（前提: メトリクス/ログ基礎）
12. Incident Response（AppSec + DevOps連携）- Advanced（前提: ログ調査, 権限モデル理解）

次号は **Day 2: Secure Coding / OWASP - Middle** を予定します（前提を最初に5分で復習）。
