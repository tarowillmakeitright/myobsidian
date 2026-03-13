# 2026-03-13 09:00 SecDevOps Magazine

#security #devops #docker #kubernetes #terraform #linux #cloudsecurity #observability #daily

[[Home]]

---

## 1) Topic + Level
**Cloud Security: AWS/GCP IAM & Permission Design 入門**  
**Level: Beginner（学習アーク 1 / Day 1）**

> 次回予告（アーク進行）:  
> - Day 2（Middle）: IAMの権限境界 + Terraformでの最小権限実装  
> - Day 3（Advanced）: マルチアカウント/組織設計とインシデント対応演習

---

## 2) Why it matters in real projects
現場のセキュリティ事故は、ゼロデイよりも**過剰権限（Over-Permission）**や**誤設定**が原因になることが多いです。  
特にDevOps環境では、CI/CD・Kubernetes・Terraformがクラウド権限と密接に連携するため、IAM設計が甘いと被害が一気に広がります。

- 開発者ロールが `*:*` だと、ミス操作で本番破壊が起きる
- CIトークン漏えい時に、権限が広すぎると横展開される
- 監査ログに基づく追跡ができないと、インシデント対応が遅れる

**IAMは“クラウド時代の認証・認可の土台”**です。ここを固めると、Application Security と DevOps Security の両方が強くなります。

---

## 3) Core concepts（clear explanations）
1. **Principal（誰が）**  
   ユーザー、グループ、Role、Service Account など

2. **Action（何を）**  
   `s3:GetObject` / `ec2:StartInstances` / `storage.objects.get` など

3. **Resource（どこに）**  
   特定のバケット、プロジェクト、KMSキーなど

4. **Condition（どんな条件で）**  
   IP制限、MFA必須、タグ一致、時間帯制限など

5. **Least Privilege（最小権限）**  
   “必要な操作だけ”を許可する。最初は狭く、必要時に広げる。

6. **Separation of Duties（職務分離）**  
   開発・運用・監査権限を分ける。1つの認証情報に全権限を持たせない。

7. **短命クレデンシャル優先**  
   長期Access Keyより、Role引受（STS）やWorkload Identityを優先。

---

## 4) Hands-on mini lab（30-60 min）
**Labテーマ:** 「CI用ロールを最小権限にする（AWS例 + Terraform雛形）」

### ゴール
- 既存の広い権限（例: `AdministratorAccess`）を排除
- CIが必要なS3操作だけ実行可能にする
- 失敗ログを確認し、許可不足を安全に追加する運用を体験

### 手順（目安45分）
1. **現状確認（10分）**
   - CIユーザー/ロールのアタッチポリシーを確認
   - CloudTrailで最近の利用アクションを確認

2. **最小権限ポリシー作成（15分）**
   - `s3:PutObject`, `s3:GetObject`, `s3:ListBucket` のみに限定
   - Resourceを対象バケットに限定

3. **Terraform化（10分）**
   - IAM PolicyをTerraformで管理
   - `terraform plan` で差分確認

4. **検証（10分）**
   - CIジョブ実行
   - 必要操作が失敗したら、CloudTrail/Eventログを根拠に最小追加

> 守るべき原則: 「動く最小権限」を段階的に作る。最初から完璧を狙わない。

---

## 5) Command cheatsheet
### Linux
```bash
# 直近の作業ログ確認
history | tail -n 20

# JSON整形（jq）
cat policy.json | jq .
```

### AWS CLI
```bash
# 呼び出し元の確認
aws sts get-caller-identity

# ロールに付与されたポリシー確認
aws iam list-attached-role-policies --role-name ci-role

# インラインポリシー確認
aws iam list-role-policies --role-name ci-role
```

### Terraform
```bash
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

### Kubernetes（参考：CI権限と接続する場合）
```bash
# 現在コンテキスト
kubectl config current-context

# 権限チェック例
kubectl auth can-i get pods -n default
```

### Docker（参考：CIジョブ検証）
```bash
docker build -t app:test .
docker run --rm app:test
```

---

## 6) Common mistakes and how to avoid them
1. **`Action: "*"`, `Resource: "*"` を常用する**  
   - 回避: まず監査ログから必要操作を抽出し、明示的に列挙する

2. **人間ユーザーに長期Access Keyを配布**  
   - 回避: SSO + MFA + Role引受に移行する

3. **本番・開発で同じロールを使う**  
   - 回避: 環境ごとに分離し、誤操作 blast radius を最小化

4. **権限変更をコード管理しない**  
   - 回避: Terraform/IaCでレビュー可能にする（Pull Request必須）

5. **失敗時に一気に権限を広げる**  
   - 回避: エラーログ根拠で1アクションずつ追加する

---

## 7) One interview-style question
**Q.** 「CIパイプラインが時々失敗するため、`AdministratorAccess` を付与して安定化させたい」という提案があります。セキュリティと運用効率のバランスをどう設計しますか？

**考えるポイント:**
- 失敗アクションの特定方法（CloudTrail/ログ）
- 一時的な緩和策の期限管理
- 最小権限へ戻すためのSLO/運用ルール

---

## 8) Next-step reading links
- OWASP Top 10: https://owasp.org/www-project-top-ten/
- AWS IAM Best Practices: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- Google Cloud IAM Overview: https://cloud.google.com/iam/docs/overview
- Terraform IAM Policy as Code patterns: https://developer.hashicorp.com/terraform
- Kubernetes RBAC: https://kubernetes.io/docs/reference/access-authn-authz/rbac/
- OpenTelemetry Overview（次回以降のObservability導入準備）: https://opentelemetry.io/docs/concepts/

---

### 学習アーク進行メモ
- 今日: **Beginner（Cloud IAM基礎）**
- 次回（Middle）前提知識:  
  - IAM Policy JSONの基本構文を読める  
  - `terraform plan/apply` を実行したことがある
- 次々回（Advanced）前提知識:  
  - Role/Service Account分離設計の経験  
  - 監査ログ（CloudTrail / Cloud Audit Logs）の基本読解

明日も「小さく作って安全に改善」を積み上げていきましょう。