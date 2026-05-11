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

# SecDevOps Magazine — 2026-05-11 (09:00)
[[Home]]

今週から「Beginner → Middle → Advanced」の学習アークを回していきます。  
**今回（Issue 1）は Beginner**。まずは土台を固め、次回以降で実戦レベルへ進みます。

---

## 1) Topic + Level
**Topic:** Cloud Security 入門（AWS/GCP IAM & Permission Design の基本）  
**Level:** **Beginner**

---

## 2) Why it matters in real projects
本番事故の多くは「脆弱なコード」だけでなく、**過剰権限（over-privileged IAM）** から起きます。  
たとえば CI/CD 用のサービスアカウントに `*:*` 相当の権限があると、漏えい時に全環境が一気に侵害されます。

IAM 設計は AppSec と DevOps の接点です：
- AppSec 視点: 攻撃面（attack surface）を最小化
- DevOps 視点: 運用を止めずに安全性を上げる

---

## 3) Core concepts（clear explanations）
- **Least Privilege（最小権限）**  
  必要な操作だけ許可。`管理者だから全部OK` を避ける。

- **Role-Based Access / Service Account 分離**  
  人間ユーザーと機械（CI/CD, app runtime）の権限を分ける。

- **Deny by default**  
  許可していない操作は拒否する設計を基本にする。

- **Temporary credentials**  
  長期固定キーではなく、期限付きトークン（STS, Workload Identity など）を優先。

- **Permission boundary / Condition**  
  「このリソースだけ」「このタグだけ」「この時間帯だけ」などの条件で絞る。

---

## 4) Hands-on mini lab（30–60 min）
**目的:** 「過剰権限」から「最小権限」へ絞る体験をする。

### ラボ手順（ローカル検証ベース）
1. IAM ポリシーを 2 つ作る（ファイルでOK）
   - `policy-broad.json`（広すぎる）
   - `policy-least.json`（S3 バケット読み取りだけ等）

2. AWS なら IAM Policy Simulator / GCP なら Policy Troubleshooter で、
   - 許可されるアクション差分を確認

3. CI 用ロールを想定し、
   - 「Artifact pull」「ログ出力」「特定バケット読取」のみ許可
   - それ以外（IAM変更・全S3列挙等）は拒否

4. 結果をメモ
   - 何を削ったか
   - 削っても業務が回る理由

> 学習ポイント: “動く最小権限” は 1 回で完成しない。観測（ログ）→調整の反復が前提。

---

## 5) Command cheatsheet
```bash
# Linux: 権限定義ファイル確認
ls -l policy-*.json
cat policy-least.json | jq .

# Docker: 将来のCIジョブ想定で最小ベース確認
docker run --rm -it alpine:3.20 sh

# Kubernetes: ServiceAccountの現状把握（クラスタがある場合）
kubectl get sa -A
kubectl auth can-i get pods --as=system:serviceaccount:default:default

# Terraform: IAMをコード化する前提確認
terraform fmt
terraform validate
terraform plan
```

---

## 6) Common mistakes and how to avoid them
- **ミス1: とりあえず AdministratorAccess を付与**  
  → 回避: 最初は ReadOnly + 必要操作を追加する。

- **ミス2: 人間とCI/CDで同じ資格情報を共有**  
  → 回避: principal を分離。監査ログの追跡可能性を確保。

- **ミス3: 長期アクセスキーを放置**  
  → 回避: 期限付きクレデンシャルへ移行。ローテーションを自動化。

- **ミス4: 権限を削って壊れるのが怖くて放置**  
  → 回避: ステージングで検証 → 監査ログ見ながら段階的に縮小。

---

## 7) One interview-style question
「CI/CD パイプライン用ロールに最小権限を設計するとき、最初の 3 ステップをどう定義しますか？また、運用しながら安全に権限を削る方法を説明してください。」

---

## 8) Next-step reading links
- OWASP Top 10: https://owasp.org/www-project-top-ten/
- AWS IAM Best Practices: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- Google Cloud IAM Best Practices: https://cloud.google.com/iam/docs/best-practices
- Kubernetes RBAC: https://kubernetes.io/docs/reference/access-authn-authz/rbac/
- OpenTelemetry Docs: https://opentelemetry.io/docs/

---

## Progression & Rotation Plan（次号予告）
- **Issue 2 (Middle):** Docker hardening + secrets management（前提: Linux基本コマンド, コンテナ実行経験）
- **Issue 3 (Advanced):** Kubernetes incident drill（failure → rollback → recovery）（前提: kubectl基本操作, Deployment/Service理解）
- **Issue 4 (Beginner):** OWASPリスクとsecure coding基礎
- **Issue 5 (Middle):** Observability（Prometheus/Grafana/OpenTelemetry 実装）
- **Issue 6 (Advanced):** Terraform/IaC セキュリティレビュー実践

このサイクルで、Application Security / DevOps core / Cloud Security / Observability / K8s incident drills を継続的に回します。