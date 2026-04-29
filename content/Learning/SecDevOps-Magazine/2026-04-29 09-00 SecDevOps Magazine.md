---
tags: [security, devops, docker, kubernetes, terraform, linux, cloudsecurity, observability, daily]
---

# SecDevOps Magazine — 2026-04-29
[[Home]]

## 今日の学習アーク
- **Arc A（Application Security）**: Beginner → Middle → Advanced を3日サイクルで反復
- **Arc B（DevOps Core）**: Beginner → Middle → Advanced を3日サイクルで反復
- **Arc C（Cloud/Observability/Incident Drill）**: Beginner → Middle → Advanced を3日サイクルで反復
- **本号の難易度**: **Beginner**（次号でMiddleへ進行）

---

## 1) Topic + Level
**Cloud Security (AWS/GCP IAM & permission design) + Beginner**

## 2) なぜ実務で重要か
IAMの設計ミスは、アプリ脆弱性がなくても本番環境への不正アクセスや情報漏えいに直結します。  
実務では「開発速度」と「最小権限 (Least Privilege)」のバランスが常に課題です。最初に正しい型を作れると、後続のDocker/Kubernetes/Terraform運用が一気に安全になります。

## 3) Core concepts（要点整理）
- **Principal / Identity**: 人・サービスアカウント・ロールなど、操作主体
- **Policy**: 何を許可/拒否するかを記述したルール
- **Least Privilege**: 必要最小限だけ許可する原則
- **Separation of Duties**: 役割分離（例: deploy権限とbilling管理権限を分離）
- **Deny-by-default**: 明示許可がない限り拒否
- **短命認証情報 (Short-lived credentials)**: 永続キーを避け、期限付きトークンを使う

> 今日のゴール: 「とりあえずAdmin」から卒業し、用途別ロールの最小権限設計を作れるようになる。

## 4) Hands-on mini lab（30–60分）
**ラボ名: 最小権限ロールの設計レビュー（ローカル擬似演習）**

### 手順
1. 次の3つの職務を定義する（メモでOK）
   - `app-deployer`
   - `log-reader`
   - `security-auditor`
2. 各職務に「必要操作だけ」を列挙
   - 例: `app-deployer` はデプロイ実行可、IAM編集不可
3. “危険操作” を明示的に洗い出す
   - 例: `*:*`、IAM書き換え、鍵作成、監査ログ停止
4. 1つの仮想ポリシーを作り、レビュー観点で自己採点
   - 不要権限がないか
   - 監査可能か
   - 緊急時の昇格フローを分離しているか

### 完了条件
- 3ロール分の許可/拒否が説明できる
- 「なぜその権限が必要か」を1行で言える

## 5) Command cheatsheet
```bash
# Linux: 現在ユーザーとグループ確認
id
whoami
groups

# Linux: 権限確認（読み取り中心）
ls -l
getfacl ./

# Docker: 実行コンテナの権限確認
docker ps
docker inspect <container> --format '{{.HostConfig.Privileged}}'

# Kubernetes: 現在コンテキストと認可チェック
kubectl config current-context
kubectl auth can-i get pods -A
kubectl auth can-i create clusterrole

# Terraform: 設計の静的確認
terraform fmt -check
terraform validate
terraform plan
```

## 6) Common mistakes & 回避策
- **ミス1: 最初から管理者権限を配る**
  - 回避: まずReadOnlyで開始し、必要時に差分追加
- **ミス2: 人間ユーザーに長期アクセスキーを配布**
  - 回避: SSO + 短命トークン運用へ移行
- **ミス3: 役割の責務が曖昧**
  - 回避: ロール名に職務を入れる（deploy, audit, read）
- **ミス4: 監査ログを見ない**
  - 回避: 週次で異常APIコールをレビュー

## 7) Interview-style question
「あなたが新規プロジェクトのIAM設計を任されたとき、`Least Privilege` を維持しながらデプロイ速度を落とさないために、最初の1週間で何を設計・自動化しますか？」

## 8) Next-step reading links
- OWASP Top 10: https://owasp.org/www-project-top-ten/
- OWASP ASVS: https://owasp.org/www-project-application-security-verification-standard/
- AWS IAM Best Practices: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- Google Cloud IAM overview: https://cloud.google.com/iam/docs/overview
- Kubernetes RBAC: https://kubernetes.io/docs/reference/access-authn-authz/rbac/
- OpenTelemetry docs: https://opentelemetry.io/docs/

---

## トラック進行メモ（ローテーション保証）
- **Application Security**: 次号予定 → OWASPリスク（Middle, 前提: HTTP/認証の基礎）
- **DevOps Core**: 次号予定 → Docker Hardening（Middle, 前提: Dockerfile基礎）
- **Added topics**:
  - Cloud Security: 本日 Beginner 実施済み
  - Observability: 次々号予定（Beginner→Middleアーク開始）
  - K8s incident drills: 近日開始（Beginner: 障害分類とrollback基礎）

> Middle/Advanced号では必ず前提知識を明記し、Beginner号で学んだ内容を再利用して積み上げる。
