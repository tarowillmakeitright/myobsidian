---
tags: [security, devops, docker, kubernetes, terraform, linux, cloudsecurity, observability, daily]
---

# SecDevOps Magazine — 2026-05-03 09:00
[[Home]]

## 学習アーク（3日サイクル）
- **Day 1: Beginner**（基礎理解と安全な手順）
- **Day 2: Middle**（運用設計・トラブル対応）
- **Day 3: Advanced**（実戦的な防御設計・インシデント判断）
- これを繰り返して、段階的に Application Security + DevOps を定着させる。

---

## 1) Topic + Level
**Cloud Security (AWS/GCP IAM & Permission Design) + Secure Coding 接続編 — Beginner**

---

## 2) Why it matters in real projects
実プロジェクトでは、脆弱性そのものよりも「**権限の過大付与**」が事故を拡大させることが多いです。  
たとえば Web アプリの脆弱性（OWASP Top 10 の Broken Access Control など）を突かれても、IAM が最小権限なら被害は限定できます。逆に `*:*` に近い権限だと、1つの侵入口から本番全体に波及します。

**要点:**
- AppSec（アプリ防御）と DevOps（運用自動化）は分離不可
- IAM 設計は「最後の防波堤」
- 法的・倫理的にも、権限制御は監査説明責任の中心

---

## 3) Core concepts（clear explanations）
### A. Least Privilege（最小権限）
- 必要な操作だけ許可
- 対象リソースを限定（例: 特定の S3 bucket のみ）
- 時間・条件を限定（MFA 必須、IP 制限、Workload Identity など）

### B. Deny by default
- 明示許可がないものは拒否
- 例外ベースで穴を最小化

### C. Role separation（職務分離）
- 開発者、CI/CD、運用、監査で Role を分ける
- 事故時の blast radius（被害半径）を抑える

### D. Session security と短命認証情報
- 長期キーを避け、短命 token / AssumeRole / Workload Identity を使う
- Secrets 管理（Vault, AWS Secrets Manager, GCP Secret Manager）を前提に設計

### E. Threat modeling 接続
- 「侵入されたら何を取られるか」を IAM 視点で逆算
- 認可境界（誰がどの API を叩けるか）を先に図にする

---

## 4) Hands-on mini lab（30-60 min）
**目的:** IAM を「なんとなく付与」から「検証付き最小権限」へ。

### Lab シナリオ（防御・合法的学習のみ）
1. サンプルアプリ用の実行主体を作る（AWS Role または GCP Service Account）
2. 最初は ReadOnly 権限だけ付与
3. アプリ実行で不足権限をログから確認
4. 必要最小限の Action を1つずつ追加
5. 最後に不要権限を削除し、再テスト

### 完了条件
- ワイルドカード権限（`*`）を使わない
- 説明可能なポリシーコメントを残す
- 監査ログ（CloudTrail / Cloud Audit Logs）で実行履歴を確認

---

## 5) Command cheatsheet
### Linux
```bash
# 最近使った危険コマンドを振り返る（教育用途）
history | tail -n 30

# JSON を見やすく整形
cat policy.json | jq .
```

### Docker（権限設計に関連する実行原則）
```bash
# root で動かさない実行確認
docker inspect <container> --format '{{.Config.User}}'

# capability を追加しすぎてないか確認
docker inspect <container> | jq '.[0].HostConfig.CapAdd, .[0].HostConfig.CapDrop'
```

### Kubernetes
```bash
# 現在の権限確認（K8s RBAC）
kubectl auth can-i get secrets --as system:serviceaccount:default:app-sa -n default

# Role/RoleBinding の確認
kubectl get role,rolebinding -n default
```

### Terraform
```bash
# 構文・基本検証
terraform fmt -recursive
terraform validate

# 変更差分確認（本番適用前の必須ステップ）
terraform plan
```

---

## 6) Common mistakes and how to avoid them
1. **最初から Admin 権限を付ける**  
   → まず ReadOnly + ログ確認で段階追加。

2. **人間ユーザーと CI/CD を同じ権限で運用**  
   → Principal を分離し、用途別 Role を作る。

3. **長期 Access Key の放置**  
   → 短命 credential + rotation + secret manager。

4. **Kubernetes Secret への過剰アクセス**  
   → namespace 分割 + `kubectl auth can-i` で検証。

5. **Terraform apply 直打ち**  
   → `plan` レビューと承認プロセスを CI/CD に組み込む。

---

## 7) One interview-style question
「Web アプリに SSRF 脆弱性が見つかった場合、AWS/GCP IAM 設計で被害を最小化するには、**どの権限境界**を優先して見直しますか？理由も説明してください。」

---

## 8) Next-step reading links
- OWASP Top 10: https://owasp.org/www-project-top-ten/
- AWS IAM Best Practices: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- GCP IAM Best Practices: https://cloud.google.com/iam/docs/using-iam-securely
- Kubernetes RBAC: https://kubernetes.io/docs/reference/access-authn-authz/rbac/
- Terraform Security Best Practices (HashiCorp Learn): https://developer.hashicorp.com/terraform/tutorials/cloud-get-started/cloud-security
- OpenTelemetry Docs: https://opentelemetry.io/docs/
- Prometheus Docs: https://prometheus.io/docs/introduction/overview/
- Grafana Docs: https://grafana.com/docs/

---

## 次号予告（Middle、前提条件つき）
**予定トピック:** Observability（Prometheus/Grafana/OpenTelemetry）+ CI/CD Security 連携  
**Level:** Middle  
**Prerequisites:**
- Linux 基本コマンド（grep, jq, systemctl）
- Docker コンテナの基本理解（image/container/log）
- IAM 最小権限の基礎（本号）

その次（Advanced）では **Kubernetes incident drills（failure/rollback/recovery）** を実施予定。