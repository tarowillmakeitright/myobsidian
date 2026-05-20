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

# SecDevOps Magazine — 2026-05-20

## 1) Topic + Level
**Docker Hardening + Secrets Management + Terraform Guardrails**  
**Level: Middle（学習アーク 2/3: Beginner → Middle → Advanced）**

**前提（Prerequisites）**
- Beginner相当: IAMの基本（Principal / Action / Resource / Condition）
- Linux基本操作（`grep`, `find`, `chmod`, `cat`）
- Dockerfileを1本は書いたことがある

---

## 2) Why it matters in real projects
実務では「アプリの脆弱性」より先に、**コンテナ設定ミス**や**Secrets流出**で事故が起きることが多いです。  
例えば以下は典型例です。

- Dockerイメージが `root` 実行のまま本番投入される
- `.env` や鍵ファイルがイメージ層に焼き込まれる
- Terraformで広すぎる権限（`*`）をそのまま適用する

この3つは、攻撃者にとっては「侵入後の横展開」を一気に簡単にします。  
だからこそ、**ビルド時点での安全設計（Shift Left）**がDevOpsの生産性と安全性を同時に守ります。

---

## 3) Core concepts（clear explanations）
### A. Docker Hardening の3本柱
1. **最小ベースイメージ**（alpine/distroless等）
2. **非root実行**（`USER` を明示）
3. **不要機能を削る**（package最小化、read-only rootfs、capability削減）

### B. Secrets Management の原則
- Secretを**コード・イメージ・Git履歴に置かない**
- 実行時注入（Kubernetes Secret + External Secrets / Cloud Secret Manager）
- 短命認証（OIDC, STS, Workload Identity）を優先

### C. Terraform Guardrails
- `terraform validate` だけでは不十分。**ポリシー検証**を追加する
- `tfsec` / `checkov` / OPA(Conftest) で「危険な設定をapply前に落とす」
- 例: 「0.0.0.0/0 を本番DBに許可しない」「admin権限ロール作成を禁止」

### D. CI/CD Security 接続点
- PR段階: lint + IaC scan + secret scan
- Merge後: build署名、SBOM生成、署名検証付きdeploy
- 本番反映: 承認ゲート + 監査ログ保存

---

## 4) Hands-on mini lab（30-60 min）
**目的:** 「安全でない構成を検知して、安全な形に直す」一連を体験する

### 手順
1. **わざと脆弱なDockerfile**を作る（`USER root`、`COPY . .`、秘密情報を環境変数直書き）
2. `docker build` 後、`docker history` でSecrets痕跡を確認
3. Dockerfileを修正（multi-stage + 非root + 不要ファイル除外）
4. Terraformに危険ルール（例: 全開放SG）を書き、`tfsec` または `checkov` で検出
5. ルールを最小権限に修正し、再スキャンでPass
6. （可能なら）CIローカル模擬としてシェルで `scan -> fail -> fix -> pass` を再現

**完了条件**
- イメージ内にSecretが残っていない
- コンテナが非rootで起動する
- IaCスキャンでHigh/Criticalが0になる

---

## 5) Command cheatsheet
### Linux
```bash
# 誤って置いた秘密情報候補を検索
grep -RInE "(AKIA|SECRET|PASSWORD|TOKEN|PRIVATE KEY)" .

# ファイル権限の過剰設定を確認
find . -type f -perm -o+w
```

### Docker
```bash
# イメージ履歴（Secrets混入痕跡チェック）
docker history <image:tag>

# 実行ユーザー確認
docker inspect <container_or_image> --format '{{.Config.User}}'

# コンテナをread-only root filesystemで起動
docker run --read-only --cap-drop ALL --security-opt no-new-privileges <image:tag>
```

### Kubernetes
```bash
# Secretオブジェクト確認（メタデータ中心）
kubectl get secrets -n <ns>

# Pod実行ユーザー/権限設定の確認
kubectl get pod <pod> -n <ns> -o jsonpath='{.spec.securityContext}'

# RBAC動作確認
kubectl auth can-i get secrets -n <ns>
```

### Terraform
```bash
terraform fmt -recursive
terraform validate
terraform plan

# 例: tfsec（導入済みなら）
tfsec .

# 例: checkov（導入済みなら）
checkov -d .
```

---

## 6) Common mistakes and how to avoid them
1. **`COPY . .` で不要ファイル全部同梱**  
   → `.dockerignore` を必須化。`.env`, `.git`, `*.pem` を除外。

2. **`latest` タグ固定で再現性崩壊**  
   → ベースイメージはdigest固定（`@sha256:...`）で追跡可能にする。

3. **Kubernetes Secretを「暗号化済みだから安全」と誤解**  
   → etcd暗号化・RBAC最小化・アクセス監査をセットで実施。

4. **Terraformレビューが目視頼み**  
   → PRで自動スキャン必須化。High以上はマージブロック。

5. **CIに長期鍵を保存**  
   → OIDC federationへ移行し、短命トークン化。

---

## 7) One interview-style question
「あなたのチームでは Docker + Kubernetes + Terraform を使っています。  
“SecretをGitにもイメージにも残さず、かつ本番デプロイを自動化する” ために、
CI/CDパイプライン・IAM設計・Runtime設定をどう組み合わせますか？
失敗時のロールバックと監査証跡も含めて説明してください。」

---

## 8) Next-step reading links
- OWASP Top 10: https://owasp.org/www-project-top-ten/
- OWASP Cheat Sheet (Secrets Management): https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html
- Docker Security: https://docs.docker.com/engine/security/
- Kubernetes Pod Security Standards: https://kubernetes.io/docs/concepts/security/pod-security-standards/
- Terraform Security Best Practices (HashiCorp): https://developer.hashicorp.com/terraform/tutorials/cloud-get-started/cloud-security
- tfsec: https://aquasecurity.github.io/tfsec/
- Checkov: https://www.checkov.io/
- OpenTelemetry: https://opentelemetry.io/docs/

---

### 次号予告（Advanced）
**Kubernetes Incident Drill（failure / rollback / recovery）+ Observability（Prometheus/Grafana/OpenTelemetry）+ Cloud IAM緊急対応**  
前提: 今号のDocker hardening・Secrets管理・Terraformガードレールを実装できること