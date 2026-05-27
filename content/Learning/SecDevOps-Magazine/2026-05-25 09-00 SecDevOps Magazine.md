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

# SecDevOps Magazine — 2026-05-25

## 1) Topic + Level
**テーマ:** OWASP Top 10 と CI/CD セキュリティの接続設計  
**Level:** Beginner

---

## 2) Why it matters in real projects
現場では「アプリの脆弱性」と「デプロイ経路の脆弱性」が別チーム管理になり、攻撃面が分断されがちです。  
その結果、コードは安全でも CI/CD で secrets 漏えい、あるいは逆にパイプラインは堅くてもアプリ側に Injection が残る、という事故が起きます。

この回では **AppSec と DevOps を一本の流れ**として理解し、
- 開発（secure coding）
- 検査（SAST/Dependency Scan）
- 配布（artifact integrity）
- 実行（runtime visibility）
をつなげる基礎感覚を作ります。

---

## 3) Core concepts (clear explanations)
### A. OWASP Top 10 は「実装ミス」だけではない
- 例: **A01 Broken Access Control** はコードだけでなく、API Gateway や ingress 設定でも悪化する
- 例: **A05 Security Misconfiguration** は Dockerfile/K8s manifest/CI variables でも発生

### B. Shift-Left + Shift-Right
- **Shift-Left:** PR 時点で SAST・lint・secret scan
- **Shift-Right:** 本番で observability（logs/metrics/traces）を使って異常検知
- どちらか片方だけでは不十分

### C. 最小権限 (Least Privilege)
- IAM, CI runner token, Kubernetes ServiceAccount 全部に適用
- 「一時的に広い権限」は恒久的に残る前提で設計する

### D. インシデント対応の初速
- 兆候検知 → 影響範囲特定 → 封じ込め → 復旧 → 再発防止
- ログがない環境は“調査不能”になり、復旧が遅れる

---

## 4) Hands-on mini lab (30-60 min)
**ラボ名:** ローカル CI セキュリティ・ゲート体験（Docker + Trivy + gitleaks）  
**目標:** 「ビルドできる」ではなく「安全にビルドできる」を体感

### 手順
1. サンプルアプリ（任意の小さな Web アプリ）を準備
2. Dockerfile を作成（最初は intentionally weak でOK）
3. `trivy` で image scan
4. `gitleaks` で secret scan
5. 重大 issue が出たら Dockerfile/設定を修正
6. 再スキャンして改善差分を記録

### 完了条件
- Critical/High の主因を 1 つ以上修正
- 「何を直したか」を 3 行で説明できる

---

## 5) Command cheatsheet
```bash
# Linux 基本
uname -a
cat /etc/os-release

# Docker
docker build -t secdevops-lab:day1 .
docker images | head
docker run --rm secdevops-lab:day1

# Trivy (image scan)
trivy image --severity HIGH,CRITICAL secdevops-lab:day1

# gitleaks (repo scan)
gitleaks detect --source . --verbose

# Kubernetes (接続確認だけ)
kubectl version --client
kubectl config current-context

# Terraform (導入済みなら)
terraform fmt -recursive
terraform validate
```

---

## 6) Common mistakes and how to avoid them
1. **「scan を一回回して満足」**  
   → CI で毎回実行。例外は期限付きで管理。

2. **root ユーザーのままコンテナ実行**  
   → Dockerfile で `USER` を明示し、不要 capability を落とす。

3. **secrets を `.env` や repo に直置き**  
   → secret manager または CI secret store に集約。

4. **検知ルールを増やしすぎて運用崩壊**  
   → まず High/Critical と known exploited に集中。

---

## 7) One interview-style question
「あなたのチームで CI/CD にセキュリティゲートを1つだけ追加できるなら、どこに何を置きますか？理由と、開発速度への影響をどう最小化するかまで説明してください。」

---

## 8) Next-step reading links
- OWASP Top 10: https://owasp.org/www-project-top-ten/  
- OWASP ASVS: https://owasp.org/www-project-application-security-verification-standard/  
- CIS Docker Benchmark (overview): https://www.cisecurity.org/benchmark/docker  
- Trivy: https://aquasecurity.github.io/trivy/  
- OpenTelemetry Docs: https://opentelemetry.io/docs/

---

## Learning Arc Note (Progression)
- 今日: **Beginner**（基礎統合）
- 次回予定: **Middle**（前提: Docker/Kubernetes 基本操作、CI YAML の読解）
- 将来予定: **Advanced**（前提: IAM 設計、脅威モデリング、K8s 障害対応経験）

次号ではローテーションとして **Cloud Security (AWS/GCP IAM 設計)** と **Observability (Prometheus/Grafana/OpenTelemetry)** を組み合わせ、
その次で **Kubernetes incident drills（failure/rollback/recovery）** を扱います。
