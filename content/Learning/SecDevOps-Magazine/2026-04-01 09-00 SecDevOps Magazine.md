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

# SecDevOps Magazine — 2026-04-01 09:00
[[Home]]

#security #devops #docker #kubernetes #terraform #linux #cloudsecurity #observability #daily

## 1) Topic + Level
**Docker Hardening + CI/CD Security + Secrets Management（実装編）**
**Level: Middle**

> 学習アークの2段階目（Middle）です。次号は Advanced に進み、Kubernetes incident drill（failure/rollback/recovery）と Observability を統合します。

**Prerequisites（前提知識）**
- Docker 基本操作（build / run / exec / logs）
- Linux 基本コマンド（cat, grep, chmod, chown）
- GitHub Actions または GitLab CI の基本概念
- 「最小権限（least privilege）」の意味を説明できること

## 2) Why it matters in real projects
実務で多い事故は、アプリ本体よりも**周辺の運用設定**から起きます。

- `latest` イメージを無検証で本番投入
- コンテナが root で動作
- `.env` や CI 変数に秘密情報を平文保存
- 脆弱性スキャンを「あとでやる」運用

この状態では、1つの漏えいが**供給網（Software Supply Chain）全体のリスク**になります。
Docker hardening + CI/CD security + secrets 管理をセットで回すことで、
**開発速度を落とさずに事故確率を下げる**のが今日の狙いです。

## 3) Core concepts（clear explanations）
### A. Docker Hardening の軸
- **非 root 実行**: `USER` を指定し、権限を最小化
- **最小ベースイメージ**: attack surface を縮小（例: distroless, alpine）
- **不要機能の削減**: shell/debug ツールを本番イメージに残さない
- **read-only filesystem**（可能なら）: 改ざん耐性を上げる

### B. CI/CD Security の最低ライン
- **PR ごとに SAST / dependency scan / image scan**
- **Fail-fast**: High/Critical でパイプライン停止
- **署名・検証**: 可能ならコンテナイメージ署名（cosign 等）
- **権限分離**: CI のトークン権限を最小化

### C. Secrets Management
- **秘密はコード・イメージに埋め込まない**
- 取得は実行時（runtime）に限定
- ローテーション可能なストア（AWS Secrets Manager / GCP Secret Manager / Vault）を使う
- 監査ログを残す

### D. Cloud Security との接続（必須視点）
CI がクラウドへデプロイする場合、OIDC 連携で短命クレデンシャルを使うと安全性が上がります。
長期 Access Key の常設は避け、IAM permission design を最小化しましょう。

## 4) Hands-on mini lab（30-60 min）
**目標:** 「安全寄り Dockerfile + CI 脆弱性チェック + Secret 注入」を最小構成で体験

### 手順
1. 脆弱な Dockerfile（root, latest, 平文 ENV）を用意
2. Hardening 版 Dockerfile に修正（非 root・固定タグ・不要削減）
3. Trivy で image scan
4. CI で `HIGH,CRITICAL` を fail 条件に設定
5. `.env` を削除し、実行時に Secret を環境注入

### サンプル Dockerfile（改善版）
```dockerfile
FROM node:20-alpine3.20

WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev && npm cache clean --force

COPY . .
RUN addgroup -S app && adduser -S app -G app
USER app

ENV NODE_ENV=production
EXPOSE 3000
CMD ["node", "server.js"]
```

### サンプル CI（GitHub Actions 抜粋）
```yaml
name: secure-build
on: [pull_request]

jobs:
  scan:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      id-token: write
    steps:
      - uses: actions/checkout@v4
      - name: Build image
        run: docker build -t demo-secure:${{ github.sha }} .
      - name: Trivy scan
        uses: aquasecurity/trivy-action@0.24.0
        with:
          image-ref: demo-secure:${{ github.sha }}
          severity: HIGH,CRITICAL
          exit-code: '1'
```

**達成条件（Done）**
- コンテナが root ではなく起動
- Trivy で High/Critical 検出時に CI が失敗
- Secret がリポジトリ・Docker イメージ内に存在しない

## 5) Command cheatsheet
```bash
# Linux
id
cat /etc/os-release
grep -R "API_KEY\|SECRET\|PASSWORD" -n .

# Docker
docker build -t demo-secure:local .
docker run --rm -p 3000:3000 demo-secure:local
docker inspect demo-secure:local | jq '.[0].Config.User'
docker history demo-secure:local

# Trivy (image scan)
trivy image --severity HIGH,CRITICAL --exit-code 1 demo-secure:local

# Kubernetes（次号の incident drill 予習）
kubectl get pods -A
kubectl rollout history deploy/myapp -n prod
kubectl rollout undo deploy/myapp -n prod

# Terraform（IAM/OIDC の導入時）
terraform init
terraform plan
terraform apply
```

## 6) Common mistakes and how to avoid them
1. **`FROM xxx:latest` を使い続ける**
   - 回避: バージョン固定 + 定期更新日を決める。

2. **コンテナを root で実行**
   - 回避: `USER` 指定。書き込み先ディレクトリのみ権限付与。

3. **Secret を `.env` のまま共有**
   - 回避: Secret Manager へ移行し、実行時注入に統一。

4. **CI スキャン結果を“警告だけ”で流す**
   - 回避: High/Critical は fail、例外は期限付きで管理。

5. **CI ロールが広すぎるクラウド権限を持つ**
   - 回避: OIDC + 短命認証 + 最小 IAM ポリシー。

## 7) One interview-style question
**質問:**
「あなたのチームで“デプロイ速度を落とさず”に Docker hardening と CI security を導入するなら、最初の2週間で何を優先し、どの指標で効果測定しますか？」

**見るべき観点（例）**
- Block ルール（High/Critical）
- Mean time to remediate（脆弱性修正リードタイム）
- Secret 検出件数の減少
- 非 root コンテナ比率

## 8) Next-step reading links
- OWASP CI/CD Security: https://owasp.org/www-project-top-10-ci-cd-security-risks/
- Dockerfile Best Practices: https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Trivy Docs: https://trivy.dev/latest/
- Sigstore Cosign: https://docs.sigstore.dev/cosign/overview/
- AWS IAM Best Practices: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- GCP IAM Overview: https://cloud.google.com/iam/docs/overview
- Kubernetes Rollback: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#rolling-back-a-deployment
- OpenTelemetry Docs: https://opentelemetry.io/docs/
- Prometheus Docs: https://prometheus.io/docs/introduction/overview/
- Grafana Docs: https://grafana.com/docs/

---
### Learning Arc Note（進行管理）
- Day 1 Beginner: Cloud IAM 最小権限 + Terraform
- Day 2 Middle（今日）: Docker hardening + CI/CD security + Secrets management
- Day 3 Advanced（次号）: Kubernetes incident drill（failure/rollback/recovery）+ Observability（Prometheus/Grafana/OpenTelemetry）

この3段階を1サイクルとして、AppSec（OWASP, threat modeling, auth/session, incident response）とDevOps coreをローテーションします。
