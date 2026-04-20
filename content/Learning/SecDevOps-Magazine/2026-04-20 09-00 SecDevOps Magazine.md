---
tags: [security, devops, docker, kubernetes, terraform, linux, cloudsecurity, observability, daily]
---

[[Home]]

# SecDevOps Magazine — 2026-04-20

#security #devops #docker #kubernetes #terraform #linux #cloudsecurity #observability #daily

## 号情報
- **Issue:** #5
- **Topic + Level:** **CI/CD Security + Secrets Management 実装編 — Middle**
- **学習アーク:** Beginner → Middle → Advanced（3日サイクル反復）
- **Prerequisites（前提）:**
  - OWASP Top 10の主要カテゴリ（特にA05 Security Misconfiguration / A08 Software and Data Integrity Failures）を説明できる
  - GitHub Actions / GitLab CI / Jenkins いずれかで基本パイプラインを動かした経験
  - 環境変数・Secretの基礎理解（「コード直書きはNG」が分かる）

---

## 1) Topic + Level
**CI/CD Security + Secrets Management 実装編 — Middle**

今日は「速くデプロイする」と「安全にデプロイする」を両立させる日です。  
ポイントは、**パイプラインそのものを攻撃対象として扱うこと**です。

---

## 2) Why it matters in real projects
本番障害や情報漏えいは、アプリ本体だけでなくCI/CD経由で起きます。

- 侵害されたCIトークン → 攻撃者が改ざんイメージを配布
- 長寿命Secretの漏えい → クラウド環境に横展開侵入
- 署名なしアーティファクト → サプライチェーン改ざんを検知不能

現場で効く効果:
- リリース速度を落とさず、監査証跡を強化
- Secret漏えいの爆発半径（blast radius）を最小化
- 「誰が、何を、いつ、どこへデプロイしたか」を追跡可能に

---

## 3) Core concepts（要点）
1. **Pipeline as Production System**
   - CIランナーは本番同等の重要資産
   - 最小権限（Least Privilege）でトークン発行
   - ビルドとデプロイの権限分離

2. **Secrets Managementの基本原則**
   - Secretは「保存」「配布」「ローテーション」「失効」を設計する
   - 長寿命キーを避け、短命トークン（OIDC federation等）を優先
   - Secretをログ・Artifact・キャッシュに残さない

3. **Supply Chain Securityの3点セット**
   - 依存関係スキャン（SCA）
   - イメージスキャン（CVE）
   - 署名/検証（cosign, attestations）

4. **Policy Gate（止める勇気）**
   - 重大脆弱性でリリースを自動停止
   - 例外運用は期限付きで記録

5. **Cloud IAM連携（AWS/GCP）**
   - CIからクラウドへは固定アクセスキーより**Workload Identity / AssumeRole**
   - リポジトリ/ブランチ単位でIAM条件を絞る

---

## 4) Hands-on mini lab（30–60分）
**目的:** 「Secret直書きCI」を「短命認証 + スキャン + 署名」に置き換える。

### 構成（例）
- GitHub Actions（または同等CI）
- Dockerイメージをビルド
- Trivyで脆弱性スキャン
- cosignで署名（鍵管理はKeyless推奨）

### 手順
1. 既存パイプラインから平文Secret利用箇所を洗い出す
2. クラウド認証をOIDC連携へ変更（固定キー削除）
3. `trivy image` を追加し、High/CriticalでfailするGateを設定
4. ビルド成果物に署名し、検証ステップを追加
5. Secret誤出力テスト（`echo $SECRET`がマスク/拒否されるか）

### 完了条件
- リポジトリに固定クラウドキーが不要になっている
- Critical脆弱性検出時にデプロイが止まる
- 署名されていないイメージを拒否できる

---

## 5) Command cheatsheet
### Linux
```bash
# リポジトリ内の怪しい秘匿情報パターンを簡易検査
grep -RInE "(AKIA|SECRET|PASSWORD|TOKEN)" .

# 直近コミットで機密らしき差分確認
git log -p -n 3
```

### Docker
```bash
# イメージの脆弱性スキャン（Trivy）
trivy image myapp:latest

# SBOM生成（syft）
syft myapp:latest -o table
```

### Kubernetes
```bash
# Secret参照関係の確認（どのPod/Deployが使うか）
kubectl get deploy -A -o yaml | grep -n "secretKeyRef\|secretName"

# 事故時の即時ローテーション想定: Secret更新 → Rollout再起動
kubectl apply -f secret.yaml
kubectl rollout restart deploy/myapp -n prod
kubectl rollout status deploy/myapp -n prod
```

### Terraform
```bash
# IaC静的チェック
terraform fmt -recursive
terraform validate

# tfsec/checkovを使う場合（例）
tfsec .
checkov -d .
```

---

## 6) Common mistakes and how to avoid them
1. **「CIのSecret管理機能を使っているから安全」と思い込む**
   - 回避: ログ出力・Artifact・debug traceに漏れない設計まで確認する

2. **固定アクセスキーを“とりあえず”置きっぱなし**
   - 回避: OIDC連携へ移行し、期限付き権限へ統一する

3. **スキャンはするが、fail条件がない**
   - 回避: Severity閾値と例外期限を明文化し、自動Gate化する

4. **署名を導入したが検証していない**
   - 回避: Deploy前に必ずverifyを実行し、未署名を拒否する

5. **権限が広すぎるCIロール**
   - 回避: リポジトリ・環境（dev/stg/prod）・操作（read/write）で最小化

---

## 7) One interview-style question
あなたの組織で「CIの実行トークンが漏えいした可能性」が発覚しました。  
初動30分で行うべき封じ込め手順を、**IAM失効・Secretローテーション・デプロイ停止・監査ログ保全**の観点で優先順位付きで説明してください。

---

## 8) Next-step reading links
- OWASP CI/CD Security Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/CI_CD_Security_Cheat_Sheet.html
- GitHub Actions Security Hardening: https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions
- SLSA Framework: https://slsa.dev/
- Sigstore Cosign: https://docs.sigstore.dev/cosign/overview/
- Trivy: https://aquasecurity.github.io/trivy/
- AWS IAM Best Practices: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- Google Cloud IAM Best Practices: https://cloud.google.com/iam/docs/best-practices

---

## ローテーション計画（更新）
- Day 1 (Beginner): Cloud Security (IAM) ✅
- Day 2 (Middle): Observability ✅
- Day 3 (Advanced): Kubernetes incident drills ✅
- Day 4 (Beginner): Secure Coding + OWASPリスク ✅
- Day 5 (Middle): CI/CD Security + Secrets Management ✅（本日）
- Day 6 (Advanced): Threat Modeling + Incident Response演習
- Day 7 (Beginner): Docker Hardening + Linux command mastery
- Day 8 (Middle): Terraform/IaC Best Practices
- Day 9 (Advanced): Auth/Session Security deep dive

次号は**Advanced**。Prerequisitesとして「CI/CDでの権限分離とSecretローテーション手順を説明できること」を前提に、Threat Modeling + Incident Responseの実戦演習へ進む。