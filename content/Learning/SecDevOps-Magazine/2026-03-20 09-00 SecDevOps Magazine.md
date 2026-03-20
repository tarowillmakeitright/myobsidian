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

# SecDevOps Magazine — 2026-03-20 09:00

## 1) Topic + Level
**Topic:** Docker Hardening + CI/CD Security + Secrets Management（Kubernetes Incident DrillのDay 2）  
**Level:** **Middle**

**Prerequisites（Middle受講条件）:**
- Beginner回で扱った `kubectl logs / describe / rollout undo` を実行できる
- Observabilityの3本柱（Metrics / Logs / Traces）を説明できる
- IAM最小権限（Least Privilege）の基本概念を理解している

> 学習アーク（Beginner → Middle → Advanced）
> - Day 1（完了）: Incident Drill入門 + 観測の基礎
> - Day 2（今日）: **安全な配布パイプライン設計（Middle）**
> - Day 3（次回）: 侵害想定の復旧演習 + 権限昇格経路の封じ込み（Advanced）

---

## 2) Why it matters in real projects
実務で多い事故は、アプリ脆弱性そのものよりも **「ビルド〜デプロイの運用ミス」** で起きます。たとえば:
- Docker imageに不要なツールや秘密情報が入り、攻撃面が拡大
- CIトークンが強すぎて、侵害時に本番まで横展開
- 障害時に「戻せる」が「原因を見える化」できず再発

Middleレベルでは、**作る（Build）・運ぶ（CI/CD）・守る（IAM/Secrets）・観測する（Observability）** を一本の流れで扱うのが重要です。

---

## 3) Core concepts（clear explanations）
### A. Docker Hardening（コンテナの最小化）
- `FROM` は軽量イメージ（例: `alpine` or distroless）を検討
- root実行を避ける（`USER 10001` など）
- 不要パッケージを削減し、CVE露出を減らす
- `.dockerignore` で秘密情報や不要ファイルを除外

### B. CI/CD Security（供給網の防御）
- Pipelineごとに最小権限のOIDC/IAM Roleを分離
- `main` ブランチへの保護（required review / signed commit）
- image署名（cosign）と検証を導入
- IaC（Terraform）に対して `fmt/validate/plan` + policy check（tfsec等）

### C. Secrets Management（秘密情報の取り扱い）
- `.env` の平文コミット禁止
- K8s Secretは「保管手段」であり暗号化・アクセス制御とセットで考える
- CIでは短命トークンを使い、長期キーを避ける

### D. Cloud Security + Observability 接続
- AWS/GCP IAMは「デプロイできる範囲」を厳密に制限
- Prometheus/Grafanaでデプロイ後のError率・Latencyを可視化
- OpenTelemetry Traceで「どのリリースで劣化したか」を追跡

---

## 4) Hands-on mini lab（30-60 min）
**目標:** 「安全なリリースの最小セット」を30〜60分で体験する

1. **Dockerfile hardening**
   - 非rootユーザー化
   - 不要ファイル除外（`.dockerignore`）
2. **CI想定チェック（ローカル代替）**
   - `trivy image` で脆弱性スキャン
   - `terraform fmt/validate/plan` を実行
3. **Kubernetesにデプロイ（v2）**
   - あえて環境変数ミスを入れて失敗させる
4. **Incident drill（Middle版）**
   - `rollout status` で失敗把握
   - `rollout undo` で復旧
   - 失敗時メトリクス/ログ/トレースで原因を1つ特定
5. **Cloud IAM見直し**
   - CIロールから不要権限1つ削除（例: `*` → 明示Action）

**完了条件:**
- 脆弱性スキャン結果を1つ改善
- rollbackを5分以内に完了
- 「権限」「監視」「手順」の再発防止メモを3行残す

---

## 5) Command cheatsheet
```bash
# Linux
id
cat /etc/os-release
grep -R "SECRET\|TOKEN\|PASSWORD" . --exclude-dir=.git

# Docker
docker build -t app:secure .
docker run --rm app:secure id
docker history app:secure

# Security scan (example)
trivy image app:secure

# Kubernetes
kubectl get deploy,pods
kubectl rollout status deploy/myapp
kubectl logs deploy/myapp --tail=100
kubectl rollout undo deploy/myapp

# Terraform (IaC)
terraform fmt -recursive
terraform validate
terraform plan

# IAM check (AWS example)
aws sts get-caller-identity
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::123456789012:role/ci-role \
  --action-names ecr:PutImage ecs:UpdateService
```

---

## 6) Common mistakes and how to avoid them
1. **Dockerをrootのまま本番投入**
   - 回避: `USER` 明示、read-only filesystem、必要capability最小化

2. **CIに管理者権限を付けっぱなし**
   - 回避: OIDC + 短命認証 + 環境別Role分離（dev/stg/prod）

3. **SecretをGitに含める**
   - 回避: Secret scanner（gitleaks等）をPRゲート化

4. **監視ダッシュボードはあるがアラート運用がない**
   - 回避: SLOベースでAlert定義、オンコールRunbookとセット運用

5. **rollbackできた時点で調査終了**
   - 回避: Postmortemに「技術要因 + プロセス要因 + 再発防止期限」を残す

---

## 7) One interview-style question
「あなたのチームでは、CI/CD用IAM Roleが広すぎる状態で運用されていました。  
サービス停止を避けながら最小権限化を進める計画を、**段階（即時対応 / 1週間 / 1か月）** に分けて説明してください。Observabilityをどう使って安全性を担保しますか？」

---

## 8) Next-step reading links
- OWASP Top 10: https://owasp.org/www-project-top-ten/
- Dockerfile best practices: https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Kubernetes Security Checklist: https://kubernetes.io/docs/concepts/security/
- Kubernetes Rollout/Undo: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Terraform Best Practices: https://developer.hashicorp.com/terraform
- AWS IAM Best Practices: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- Google Cloud IAM secure usage: https://cloud.google.com/iam/docs/using-iam-securely
- Prometheus Docs: https://prometheus.io/docs/introduction/overview/
- Grafana Docs: https://grafana.com/docs/
- OpenTelemetry Docs: https://opentelemetry.io/docs/

---

次号（Advanced）は、**Kubernetes incident drill の実戦編（failure注入→証跡収集→rollback/recovery→恒久対策）** を扱います。  
焦らず、でも毎日1つずつ積み上げれば、現場で「守れるエンジニア」になれます。