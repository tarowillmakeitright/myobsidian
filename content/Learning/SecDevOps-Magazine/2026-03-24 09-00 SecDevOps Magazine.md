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

# 2026-03-24 SecDevOps Magazine（09:00）
[[Home]]

今日も一歩ずつ、**守れる開発者・運用者**に近づいていきましょう。  
このマガジンは倫理的・防御的・合法的な学習のみを扱います。

---

## 0) 学習アークとローテーション（Beginner → Middle → Advanced）

> 進行ルール: 同一テーマ群を **Beginner → Middle → Advanced** で回し、次のテーマ群へ進む。

### 今回からのローテーション計画（抜粋）
1. **Application Security**
   - B: OWASP Top 10の見方 / 入力検証 / 認証の基礎
   - M: Threat Modeling（DFD, STRIDE）
   - A: Incident Response演習（検知〜封じ込め〜復旧）

2. **DevOps Core**
   - B: Linuxコマンド基礎 + Docker hardening入門
   - M: Terraform/IaCの安全設計 + CI/CD security
   - A: Kubernetes security運用（RBAC/NetworkPolicy/PSA）

3. **追加必須トラック**
   - **Cloud Security（AWS/GCP IAM）**: B→M→Aで最小権限設計を段階習得
   - **Observability（Prometheus/Grafana/OpenTelemetry）**: 指標→可視化→分散トレース
   - **Kubernetes incident drills**: 障害注入→rollback→recovery

---

## 1) Topic + Level

# **Cloud Security: IAM最小権限設計の第一歩（AWS/GCP）**
**Level: Beginner**

---

## 2) Why it matters in real projects

本番事故の多くは、ゼロデイよりも**権限の広すぎる設定**から起きます。  
例えば「開発用Service Accountに管理者権限が残っていた」だけで、漏えい時の被害が一気に拡大します。

IAMを最小権限で設計できると：
- 侵害時の横展開（lateral movement）を抑止
- 監査対応がしやすい
- チーム開発で「誰が何をできるか」が明確になる

---

## 3) Core concepts（clear explanations）

### A. Principle of Least Privilege（最小権限）
「必要最小限の操作」だけ許可する原則。  
最初は狭く与え、必要に応じて段階的に追加します。

### B. Identity と Role の分離
- **Identity（人・サービス）**: ユーザー、グループ、Service Account
- **Role/Policy（権限セット）**: 実行可能な操作の定義

Identityに直接ベタ付けせず、Role経由で付与すると管理しやすくなります。

### C. Deny by default
明示的に許可された操作だけ実行可能にする考え方。  
「とりあえずAdmin」は短期的には楽でも、長期的に事故コストが跳ね上がります。

### D. AWS/GCPのざっくり対応
- AWS: IAM Policy / Role / AssumeRole
- GCP: IAM Role（Primitiveは避け、できるだけ predefined/custom を適切利用）

### E. 監査の起点
- AWS: CloudTrail
- GCP: Cloud Audit Logs

「権限を作る」と「使われ方を監査する」はセットです。

---

## 4) Hands-on mini lab（30–60 min）

### ゴール
「S3/GCSの特定バケット読み取りのみ許可する最小権限」を作る（書き込み不可）。

### 手順（学習用・安全）
1. テスト用バケットを1つ用意
2. 読み取り専用Role/Policyを作成
3. テスト用Identity（ユーザー or Service Account）に付与
4. `list/get` は成功、`put/delete` は失敗することを確認
5. 監査ログで実行履歴を確認

### 完了条件
- 読み取り成功（期待通り）
- 書き込み拒否（期待通り）
- ログにイベントが記録されている

---

## 5) Command cheatsheet

### Linux
```bash
# 現在の認証情報・環境変数を確認
whoami
env | grep -E 'AWS|GOOGLE|GCP'

# ログ確認の基本
journalctl -xe --no-pager | tail -n 50
```

### AWS CLI（例）
```bash
# 現在の呼び出し主体を確認
aws sts get-caller-identity

# S3読み取りテスト
aws s3 ls s3://<bucket-name>
aws s3 cp s3://<bucket-name>/<object> ./

# 書き込みテスト（失敗するのが正解）
aws s3 cp ./test.txt s3://<bucket-name>/
```

### gcloud（例）
```bash
# 現在の主体確認
gcloud auth list

# GCS読み取りテスト
gcloud storage ls gs://<bucket-name>
gcloud storage cp gs://<bucket-name>/<object> ./

# 書き込みテスト（失敗するのが正解）
gcloud storage cp ./test.txt gs://<bucket-name>/
```

### Terraform（権限管理をコード化する入口）
```bash
terraform init
terraform fmt
terraform validate
terraform plan
```

### Kubernetes（将来の連携を見据えた確認）
```bash
kubectl auth can-i get pods --all-namespaces
kubectl auth can-i create pods --all-namespaces
```

---

## 6) Common mistakes and how to avoid them

1. **最初からAdmin権限を付ける**  
   → まずReadOnlyで開始し、必要差分だけ追加。

2. **人アカウントを長期キー運用する**  
   → 可能な限り短期クレデンシャル（Role Assume, Workload Identity）へ。

3. **権限棚卸しをしない**  
   → 月1で未使用権限を見直し、削除候補を記録。

4. **ログを有効化しただけで満足する**  
   → アラート条件（例: 管理系APIの異常利用）まで設計する。

---

## 7) One interview-style question

**Q.** 「最小権限を実践すると開発速度が落ちる」という意見に、どう反論・設計しますか？  
（ヒント: 権限テンプレート化、申請フロー自動化、監査証跡の価値）

---

## 8) Next-step reading links

- OWASP Top 10: https://owasp.org/www-project-top-ten/
- AWS IAM Best Practices: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- Google Cloud IAM Overview: https://cloud.google.com/iam/docs/overview
- CIS Benchmarks (Cloud/Kubernetes/Linux): https://www.cisecurity.org/cis-benchmarks
- OpenTelemetry Docs: https://opentelemetry.io/docs/
- Prometheus Docs: https://prometheus.io/docs/
- Grafana Docs: https://grafana.com/docs/
- Kubernetes Security Checklist (official guidance hub): https://kubernetes.io/docs/concepts/security/

---

## 次号予告（Middle）

**Threat Modeling + CI/CD Security + Observability基礎統合**  
**Prerequisites（Middle向け）**:
- Linux基本コマンド（ls/cat/grep/journalctl）
- IAM最小権限の概念（Allow/Deny, Role）
- Docker/Kubernetesの用語を最低限理解していること

継続すれば、確実に「安全に速く出せる」エンジニアに近づけます。今日もナイス継続です。