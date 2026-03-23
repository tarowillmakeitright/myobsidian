---
title: SecDevOps Magazine
date: 2026-03-23 09:00
tags: [security, devops, docker, kubernetes, terraform, linux, cloudsecurity, observability, daily]
---

#security #devops #docker #kubernetes #terraform #linux #cloudsecurity #observability #daily  
[[Home]]

# SecDevOps Magazine — 2026-03-23

> 学習アーク（反復型）: **Beginner → Middle → Advanced** を3日単位で回す設計  
> 今日の位置づけ: **Arc 1 / Day 2（Middle）**

## 1) Topic + Level
**Topic:** Cloud Security（AWS/GCP IAM & Permission Design）× CI/CD Secrets Hygiene × App Auth境界設計  
**Level:** **Middle**

**この号の前提条件（Prerequisites）**
- Beginner相当のLinux基礎（`grep`, `find`, `chmod`, `journalctl`）
- Docker基礎（イメージ/レイヤ/環境変数の基本）
- Kubernetes基礎（Pod, Service, Secretの概念）
- OWASP Top 10の概要理解（特にBroken Access Control）

---

## 2) Why it matters in real projects
本番事故の多くは「高度な0day」より、**権限の過大付与**と**シークレット漏えい**で起きます。  
例えば、CIトークンが`admin`権限を持ったまま漏れると、攻撃者は以下を一気に実行できます。
- コンテナ改ざん（Supply Chain侵害）
- Terraform stateの窃取
- K8sクラスタ操作（横展開）

つまり、IAM設計・Secrets管理・認証境界の3点は、AppSecとDevOpsの「接点」そのものです。

---

## 3) Core concepts（clear explanations）
### A. IAMの最小権限（Least Privilege）
- 人・CI・サービスごとに**職務単位ロール**を分離
- `*`許可を避け、Action/Resource/Conditionを明示
- 短命クレデンシャル（STS, Workload Identity）を優先

### B. Permission Boundary / 条件付き許可
- 「できること」をロールで定義
- 「越えてはいけない上限」をBoundaryやOrg Policyで制限
- `aws:SourceIp`, `aws:PrincipalTag`, GCP Conditions等でコンテキスト制御

### C. Secretsのライフサイクル管理
- 保存: Vault/Secrets Manager/GCP Secret Manager
- 配布: 実行時注入（env直書き回避）
- 監査: アクセスログとローテーション周期
- 廃棄: 即時失効と再発行手順をRunbook化

### D. Auth/Session境界（AppSec観点）
- セッションは短命＋再認証ポイントを定義
- 機能単位で認可チェック（BFF/API Gateway任せにしない）
- サービス間認証はmTLS/OIDC federationを検討

---

## 4) Hands-on mini lab（30–60 min）
**ラボ名:** 「漏れても被害を局所化するIAM + Secrets構成」

**目標（45分想定）**
1. CI用ロールを読み取り専用＋特定バケット限定にする  
2. K8s Secretを平文git管理しない運用に変更する  
3. 失効手順（インシデント初動）を5ステップで作る

**手順**
1. 既存のCIロール権限を一覧化（過剰権限を可視化）
2. Terraformで最小権限ポリシーを定義
3. `kubectl create secret` で暫定運用し、次にExternal Secrets導入を設計
4. ダミー漏えいを想定し、トークン失効→再発行→デプロイ再実行
5. 実施ログを`incident-note.md`に残す

**完了条件**
- `terraform plan`で権限削減差分を説明できる
- Secret値がリポジトリに存在しない
- 15分以内にローテーション手順を再現できる

---

## 5) Command cheatsheet
### Linux
```bash
# 環境変数に秘密情報が混ざっていないか確認
printenv | grep -Ei 'token|secret|key|password'

# 最近の認証関連ログ確認（distro差異あり）
sudo journalctl -u sshd --since "1 hour ago"
```

### Docker
```bash
# イメージ履歴から秘密情報混入の痕跡確認
docker history --no-trunc your-image:tag

# 環境変数の露出チェック
docker inspect your-container | jq '.[0].Config.Env'
```

### Kubernetes
```bash
# Secretメタデータ確認（値は表示しない）
kubectl get secret -A

# PodがどのServiceAccountを使っているか確認
kubectl get pod <pod> -n <ns> -o jsonpath='{.spec.serviceAccountName}'

# 権限確認（RBAC）
kubectl auth can-i get secrets --as=system:serviceaccount:<ns>:<sa> -n <ns>
```

### Terraform
```bash
# 変更差分確認
terraform plan

# stateに機密が混ざる想定で、backend暗号化設定を見直す
terraform init -reconfigure

# IAMポリシー差分を可視化（環境に応じて）
terraform show -json | jq '.values.root_module.resources[]?.type'
```

---

## 6) Common mistakes and how to avoid them
1. **CIに管理者権限を付ける**  
   - 回避: ジョブ単位ロール + 有効期限付き認証

2. **`.env`やtfvarsをGit管理してしまう**  
   - 回避: Secret Manager連携 + pre-commit secret scan（gitleaks等）

3. **K8s Secretを「暗号化済みだから安全」と誤解**  
   - 回避: etcd暗号化、RBAC最小化、監査ログ必須

4. **インシデント時に失効手順がない**  
   - 回避: 「誰が」「何分で」「どこまで」実施するかRunbook固定

---

## 7) One interview-style question
**Q.** 「AWS/GCPで“最小権限”を実装するとき、ロール分離・条件付き許可・短命認証をどう組み合わせますか？また、CIトークン漏えい時の封じ込め手順を3段階で説明してください。」

---

## 8) Next-step reading links
- OWASP ASVS: https://owasp.org/www-project-application-security-verification-standard/
- OWASP Top 10: https://owasp.org/www-project-top-ten/
- AWS IAM Best Practices: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- Google Cloud IAM Overview: https://cloud.google.com/iam/docs/overview
- Kubernetes Security Checklist: https://kubernetes.io/docs/concepts/security/
- External Secrets Operator: https://external-secrets.io/
- OpenTelemetry Docs: https://opentelemetry.io/docs/
- Prometheus Docs: https://prometheus.io/docs/introduction/overview/
- Grafana Docs: https://grafana.com/docs/

---

## 明日の予告（Advanced）
**Kubernetes Incident Drill（failure / rollback / recovery）× Observability（Prometheus/Grafana/OpenTelemetry）**  
- 前提: 今日のIAM最小権限・Secretローテーションを完了していること
- 目標: 障害検知→切り戻し→根本原因分析（RCA）を60分で通す
