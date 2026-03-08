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

# SecDevOps Magazine — 2026-03-06

## 1) Topic + Level
**Topic:** Cloud Security (AWS/GCP IAM & permission design) 入門：**最小権限（Least Privilege）を設計する**  
**Level:** **Beginner**

> 学習アーク: Beginner → Middle → Advanced の3日サイクル（次回はMiddle）。

---

## 2) Why it matters in real projects
本番事故の多くは「脆弱なコード」だけでなく、**強すぎる権限**が原因で被害が拡大します。  
たとえば、CI/CD用のサービスアカウントに `*` 権限が付いていると、トークン漏えい時に全環境が危険になります。

IAM設計を最初に正しく行うと：
- 侵害時の**Blast Radius（被害範囲）**を小さくできる
- 監査（ISO/SOC2等）で説明しやすい
- チーム開発で「誰が何をできるか」が明確になる

---

## 3) Core concepts (clear explanations)
- **Principal（主体）**: 人間ユーザー、Role、Service Account など
- **Permission（権限）**: 実行可能なアクション（例: `s3:GetObject`）
- **Policy（ポリシー）**: 権限の定義書
- **Resource（対象）**: バケット、VM、Secrets、DBなど
- **Least Privilege**: 必要最小限のみ許可
- **Deny by default**: 明示許可が無ければ拒否
- **Separation of Duties（職務分離）**: deploy権限と本番DB管理権限を分離
- **Short-lived credentials**: 長期鍵より一時クレデンシャルを優先

実務のコツ：
1. まず「業務タスク」を列挙（例: artifact読み取り、デプロイ実行）
2. タスクを最小アクションに分解
3. ワイルドカードを減らす
4. 監査ログ（CloudTrail / Cloud Audit Logs）で実利用を確認し継続調整

---

## 4) Hands-on mini lab (30-60 min)
**Lab:** CI/CD bot 用の最小権限Roleを作る（AWS例、ローカル検証中心）

### ゴール
- `my-app-artifacts` バケットの読み取りのみ許可
- それ以外は拒否
- 実際に許可/拒否をCLIで確認

### 手順（目安45分）
1. IAMポリシーJSONを作成（S3 read-only to single bucket）
2. Roleにアタッチ
3. `aws s3 ls s3://my-app-artifacts` が成功することを確認
4. `aws s3 rm s3://my-app-artifacts/test.txt` が拒否されることを確認
5. CloudTrailでイベント確認（許可と拒否の記録）

**発展（時間が余れば）**
- GCPでも同様に `roles/storage.objectViewer` ベースで最小権限を試す

---

## 5) Command cheatsheet
```bash
# Linux: JSONを整形して確認
cat policy.json | jq .

# AWS: 現在の呼び出し主体を確認
aws sts get-caller-identity

# AWS: ポリシー作成
aws iam create-policy \
  --policy-name MyAppArtifactsReadOnly \
  --policy-document file://policy.json

# AWS: S3 読み取りテスト（許可されるべき）
aws s3 ls s3://my-app-artifacts

# AWS: S3 削除テスト（拒否されるべき）
aws s3 rm s3://my-app-artifacts/test.txt

# GCP: アクティブアカウント確認
gcloud auth list

# Terraform: IAM定義の静的確認
terraform fmt
terraform validate
terraform plan
```

---

## 6) Common mistakes and how to avoid them
1. **`Action: "*"` を安易に使う**  
   - 回避: まずRead-onlyから始め、必要時に1権限ずつ追加

2. **`Resource: "*"` の放置**  
   - 回避: バケット名・プロジェクト・特定ARNに絞る

3. **人間ユーザーに長期アクセスキーを配る**  
   - 回避: SSO + 一時クレデンシャルへ移行

4. **CI/CD secrets を平文で保存**  
   - 回避: Secrets Manager / Secret Manager / Vaultを利用しローテーション

5. **監査ログを見ない**  
   - 回避: 週1で「不要権限の棚卸し」を運用化

---

## 7) One interview-style question
「本番障害時、デプロイBotのトークン漏えいが発覚しました。  
あなたが最初の30分で実施する**封じ込め（containment）**と、再発防止のIAM改善を説明してください。」

---

## 8) Next-step reading links
- OWASP Top 10: https://owasp.org/www-project-top-ten/
- AWS IAM Best Practices: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- Google Cloud IAM Overview: https://cloud.google.com/iam/docs/overview
- CIS Benchmarks (Cloud/K8s/Linux): https://www.cisecurity.org/cis-benchmarks
- OpenTelemetry Docs: https://opentelemetry.io/docs/
- Kubernetes Security Checklist: https://kubernetes.io/docs/concepts/security/

---

### 次号予告（Middle）
**Observability（Prometheus/Grafana/OpenTelemetry）で「攻撃や障害を見える化」**  
※ 前提知識：Linux基本操作、HTTPの基礎、メトリクス/ログの違いをざっくり理解していること。
