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

# SecDevOps Magazine — 2026-05-23

**Issueテーマ:** Cloud Security + IAM設計の基礎で「事故を起こしにくい権限」を作る  
**Level:** **Beginner**（学習アーク 1/3: Beginner → Middle → Advanced）

---

## 1) Topic + Level

**Topic:** Cloud Security（AWS/GCP IAM & permission design 入門）  
**Level:** Beginner

> 次回予告（Middle）: IAMロール分離 + CI/CDサービスアカウント最小権限化  
> 次々回予告（Advanced）: マルチアカウント/マルチプロジェクトでの境界設計とインシデント復旧

---

## 2) なぜ実務で重要か

クラウド事故の多くは「脆弱な暗号」より先に、**権限の与えすぎ**で起きます。  
たとえば開発用アカウントに本番削除権限があるだけで、1コマンドで重大障害になりえます。

IAM設計を最初に整えると:
- 誤操作の被害を局所化できる
- 監査対応（誰が何をしたか）を説明しやすい
- CI/CDの自動化を安全に進められる

---

## 3) Core concepts（やさしく要点）

### A. Principle of Least Privilege（最小権限）
「必要な操作だけ許可、不要は拒否」。  
最初は広く付けて後で絞る、ではなく、**最初から小さく**始める。

### B. Identity分離
- **Human user**（人間）
- **Workload identity**（CI/CDやアプリ）

この2つを混ぜない。事故時の追跡性が上がる。

### C. Role-based access
個人へ直接権限ベタ付けより、Role/Group経由で管理。  
異動・退職時の剥奪漏れを減らせる。

### D. Denyの使いどころ
Allowだけでなく、重要操作には明示Denyでガード（例: 本番リソース削除）。

### E. Auditability
CloudTrail/Audit Logsなどで「誰が・いつ・何を」を残す設計が前提。

---

## 4) Hands-on mini lab（30–60分）

**目標:** 「読み取り専用ロール」と「限定的な運用ロール」を分け、危険操作を防ぐ。

### 構成（ローカル検証想定）
- Linux端末
- AWS CLI or gcloud CLI（どちらか1つでOK）
- テスト用アカウント/プロジェクト

### 手順（AWS例）
1. ReadOnlyロール相当ポリシーを確認（managed policy参照）
2. 独自ポリシーを作成（例: S3の特定バケットreadのみ）
3. `iam:DeleteUser` や `ec2:TerminateInstances` を**許可しない**ことを確認
4. テストユーザー/ロールで`aws sts get-caller-identity`実行
5. 許可操作は成功、危険操作はAccessDeniedになることを確認
6. CloudTrailで実行ログを確認

### 手順（GCP例）
1. プロジェクトでViewer系ロールを付与したサービスアカウント作成
2. 追加で必要最小限のカスタムロール（例: 特定Storage Bucket閲覧）
3. `gcloud auth activate-service-account` で切替
4. 許可外操作（例: IAM変更）を試しPermissionDenied確認
5. Cloud Audit Logsで操作記録を確認

**完了条件**
- 「できる操作 / できない操作」を説明できる
- 失敗ログを監査ログから追える

---

## 5) Command cheatsheet

### Linux
```bash
whoami
id
env | grep -E 'AWS|GOOGLE|CLOUD'
```

### AWS IAM
```bash
aws sts get-caller-identity
aws iam list-attached-user-policies --user-name <user>
aws iam simulate-principal-policy \
  --policy-source-arn <principal-arn> \
  --action-names s3:ListBucket ec2:TerminateInstances
```

### GCP IAM
```bash
gcloud auth list
gcloud projects get-iam-policy <PROJECT_ID>
gcloud iam roles describe <ROLE_ID> --project <PROJECT_ID>
```

### Terraform（参考: IAM管理をコード化）
```bash
terraform init
terraform plan
terraform apply
```

### Kubernetes（将来トラック接続）
```bash
kubectl auth can-i get pods --namespace default
kubectl auth can-i delete deployments --namespace prod
```

---

## 6) よくあるミスと回避策

1. **`*`権限を暫定で付けっぱなし**  
   → 期限付きチケット化 + 週次で剥奪レビュー

2. **人間とCI/CDで同じ資格情報を使う**  
   → サービスアカウント/ロールを分離

3. **本番と開発の境界が曖昧**  
   → アカウント/プロジェクト分離 + 明示Deny

4. **監査ログ未確認**  
   → 変更後に必ずログで追跡可能性を検証

5. **Terraform外の手動変更ドリフト**  
   → IAM変更はIaC経由を原則化

---

## 7) Interview-style question

「最小権限を実現する際、最初の1週間で何を計測・監査し、どう段階的に権限を絞りますか？実務でのトレードオフも説明してください。」

---

## 8) Next-step reading links

- OWASP Top 10: https://owasp.org/www-project-top-ten/
- AWS IAM Best Practices: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- Google Cloud IAM Overview: https://cloud.google.com/iam/docs/overview
- Kubernetes RBAC: https://kubernetes.io/docs/reference/access-authn-authz/rbac/
- Terraform IAM patterns (HashiCorp docs): https://developer.hashicorp.com/terraform
- OpenTelemetry docs: https://opentelemetry.io/docs/
- Prometheus docs: https://prometheus.io/docs/
- Grafana docs: https://grafana.com/docs/

---

## ローテーション計画（短期）

- Day 1（今日）: Cloud Security IAM基礎（Beginner）
- Day 2: Docker hardening基礎 + Linux権限（Middle, 前提: Linux基本コマンド）
- Day 3: Kubernetes incident drill（Advanced, 前提: kubectl/Deployment/rollback理解）
- Day 4: OWASP + secure coding（Beginner）
- Day 5: CI/CD security + secrets management（Middle）
- Day 6: Observability（Prometheus/Grafana/OpenTelemetry）入門（Advanced寄りMiddle）

継続的に **Beginner → Middle → Advanced** を循環し、実務投入できる筋力を積み上げる。