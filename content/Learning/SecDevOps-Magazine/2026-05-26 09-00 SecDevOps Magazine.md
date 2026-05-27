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

# SecDevOps Magazine — 2026-05-26

今日のテーマは **Cloud Security (AWS/GCP IAM & Permission Design)**。
学習アーク（Beginner → Middle → Advanced）のうち、今回は **Beginner** 回です。次回以降の Middle / Advanced に進むための土台を作ります。

---

## 1) Topic + Level
**Topic:** Cloud Security: IAMとPermission Designの基本（AWS/GCP）  
**Level:** **Beginner**

---

## 2) Why it matters in real projects
クラウド事故の多くは、脆弱な暗号ではなく **権限設定ミス** で起きます。  
たとえば、開発用サービスアカウントに本番の管理者権限が残っているだけで、
- 誤操作で本番停止
- 秘密情報の漏えい
- 監査不備によるコンプライアンス違反
につながります。

**IAM設計は「攻撃を防ぐ」だけでなく、「事故を小さくする」ための最重要レイヤー**です。

---

## 3) Core concepts（clear explanations）
### A. Principle of Least Privilege（最小権限）
「必要な操作だけ許可し、それ以外は拒否」が原則。  
最初から広い権限を配ると、運用が楽でもリスクが爆増します。

### B. Identity / Role / Policy の分離
- **Identity**: 人 or ワークロード（User, Service Account）
- **Role**: 職務単位の権限セット（例: ReadOnly, Deployer）
- **Policy**: 許可/拒否ルール（何を、どこまで）

設計の基本は、**個人に直接権限を付けず、Role経由で割り当てる**こと。

### C. AWS と GCP の考え方（対応づけ）
- AWS: IAM User / Role + Policy JSON
- GCP: Principal（user/serviceAccount）+ IAM Role（primitive/predefined/custom）

UIは違っても本質は同じで、
1) 主体（誰が）
2) 操作（何を）
3) 対象（どのリソースに）
を明示することが重要です。

### D. Deny と境界制御
- AWS では **Explicit Deny が最優先**
- 組織全体では SCP / Organization Policy 等で上限を作る

チーム単位の事故を防ぐには、**個別権限 + 組織ガードレール** の二層構造が実践的です。

### E. Auditability（監査可能性）
CloudTrail / Cloud Audit Logs に「誰が何をしたか」を残す。  
最小権限だけでは不十分で、**追跡可能性**があって初めて incident response につながります。

---

## 4) Hands-on mini lab（30–60 min）
### Lab goal
「読み取り専用ロール」と「限定デプロイロール」を作り、過剰権限を検出する。

### Timebox
45分想定

### Steps
1. **権限棚卸し（10分）**
   - 現在の user/service account のロール一覧を確認
   - `*` 権限や Admin 相当を洗い出す

2. **ReadOnly role 作成（10分）**
   - 対象をプロジェクト/アカウント内の特定サービスに限定
   - 人間ユーザーはまず ReadOnly に寄せる

3. **Deployer role 作成（15分）**
   - デプロイに必要な API のみ許可
   - 削除系操作（delete/terminate）を可能なら分離

4. **検証（10分）**
   - 想定操作は通るか
   - 想定外操作は deny されるか
   - 監査ログに記録されるか

### Completion criteria
- 2種類のロールが動作
- 1つ以上の過剰権限を削減
- 失敗ログ（deny）を確認

---

## 5) Command cheatsheet
### Linux（棚卸し補助）
```bash
# JSONを整形して読む
cat iam-policy.json | jq .

# 権限定義ファイル内のワイルドカード検出
grep -R '"\*"' policies/
```

### AWS CLI
```bash
# 現在のCaller確認
aws sts get-caller-identity

# アタッチ済みポリシー確認（例: role）
aws iam list-attached-role-policies --role-name MyDeployerRole

# インラインポリシー確認
aws iam list-role-policies --role-name MyDeployerRole
```

### GCP CLI
```bash
# 現在の認証主体
gcloud auth list

# プロジェクトIAMポリシー確認
gcloud projects get-iam-policy <PROJECT_ID> --format=json

# サービスアカウント一覧
gcloud iam service-accounts list --project <PROJECT_ID>
```

### Terraform（IaCで権限管理）
```bash
# 変更差分を事前確認
terraform plan

# lint/validate
terraform validate
```

---

## 6) Common mistakes and how to avoid them
1. **最初から Admin を配る**  
   - 回避: 一旦 ReadOnly + 必要時に権限追加（Just-in-time発想）

2. **人に直接権限付与して属人化**  
   - 回避: Group/Role ベースに統一、個人直付けを禁止

3. **ワイルドカード多用（action:* / resource:*）**  
   - 回避: サービス・リソース単位で段階的に絞る

4. **監査ログを見ない**  
   - 回避: 週次で deny/permission error をレビューして設計改善

5. **本番と開発で同じ権限境界**  
   - 回避: 環境ごとに role を分離し、昇格経路を明文化

---

## 7) One interview-style question
**Q.** 「最小権限を守りながら、開発速度を落とさない IAM 運用をどう設計しますか？」  
（ヒント: Role テンプレート化、申請自動化、期限付き昇格、監査ログの定期レビュー）

---

## 8) Next-step reading links
- OWASP Top 10: https://owasp.org/www-project-top-ten/
- AWS IAM Best Practices: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- AWS Well-Architected Security Pillar: https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/welcome.html
- GCP IAM Overview: https://cloud.google.com/iam/docs/overview
- GCP IAM Best Practices: https://cloud.google.com/iam/docs/using-iam-securely
- NIST Least Privilege (conceptual): https://csrc.nist.gov/glossary/term/least_privilege

---

## Curriculum rotation note
必須トラックは日次でローテーションし、3段階難易度アークを循環します。
- 今回: **Cloud Security / Beginner**
- 次回候補（Middle, 前提あり）:
  - Observability（Prometheus/Grafana/OpenTelemetry）
  - Kubernetes incident drills（failure/rollback/recovery）
  - CI/CD security（署名・検証・SBOM）

**Middle/Advancedの前提（Prerequisites）**
- Linux基本操作（ファイル/プロセス/ネットワーク）
- Docker基本（image/container/volume/network）
- Kubernetes基本（Pod/Deployment/Service）
- Terraform基本（state/plan/apply）
