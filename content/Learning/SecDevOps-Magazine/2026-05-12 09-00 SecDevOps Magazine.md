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

# SecDevOps Magazine — 2026-05-12

**Learning Arc:** Arc 01 / Day 1  
**Difficulty:** **Beginner**  
**Prerequisite for this issue:** なし（基礎から開始）  
**次回予告（Middle）Prerequisite:** Linux基本操作、Dockerfileの読み書き、HTTP/認証の基礎

---

## 1) Topic + Level

**Topic:** 「Secure SDLCの土台を作る：OWASP Top 10 × Docker Hardening × Cloud IAM最小権限」  
**Level:** **Beginner**

---

## 2) Why it matters in real projects

実案件では、脆弱性は“高度な攻撃”より先に“基本ミスの積み重ね”で発生します。  
たとえば:
- APIに認可チェック漏れ（Broken Access Control）
- Dockerコンテナを`root`実行のまま本番投入
- AWS/GCPで過剰権限IAMを放置

この3つは、アプリ・インフラ・クラウド境界をまたいで事故を拡大させます。  
今日のゴールは、**「最小権限」「再現可能な設定」「観測可能性」の起点を作ること**です。

---

## 3) Core concepts（clear explanations）

### A. OWASP Top 10（特にA01: Broken Access Control）
- **認証(Authentication)**: あなたは誰か
- **認可(Authorization)**: 何をしてよいか
- よくある失敗: 「ログイン済みなら全部OK」実装

### B. Docker Hardening 基礎
- `USER root`のまま動かさない
- イメージを小さく保つ（攻撃面削減）
- Secretsをイメージに焼き込まない

### C. Cloud IAM（AWS/GCP）最小権限
- 人・CI・サービスごとに権限分離
- `*`（ワイルドカード）権限禁止
- “必要な操作だけ許可”を明文化

### D. Observability最初の一歩
- **Metrics**: 数値（CPU, request count）
- **Logs**: 文字ログ（エラー詳細）
- **Traces**: リクエストの経路
- まずは「失敗を見つける指標」を1つ決める（例: 5xx率）

### E. Kubernetes Incident Drill 入門
- 障害は“起きる前提”で設計
- Drillは「誰が」「何分で」「何を戻すか」を練習する場
- 今日は“ロールバックの型”だけ覚える

---

## 4) Hands-on mini lab（30-60 min）

### 目標
ローカルで「脆弱な設定 → 改善」を1サイクル体験する。

### 手順（約45分）
1. **脆弱なDockerfileを作る**（root実行、不要パッケージあり）  
2. **改善版Dockerfileを作る**（non-root、最小構成）  
3. **IAMポリシー（サンプルJSON）を過剰権限→最小権限へ修正**  
4. **簡易SLO指標を決める**（例: エラーレート < 1%）  
5. **K8sロールバックコマンドを実行練習**（クラスタ不要、コマンド確認中心）

### サンプル改善Dockerfile
```Dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production && npm cache clean --force
COPY . .
RUN addgroup -S app && adduser -S app -G app
USER app
EXPOSE 3000
CMD ["node", "server.js"]
```

### IAM改善イメージ（考え方）
- NG: `Action: "*", Resource: "*"`
- OK: 必要な`Action`を限定し、`Resource`も特定ARN/対象へ絞る

---

## 5) Command cheatsheet

```bash
# Linux: 実行ユーザー確認
id
whoami

# Docker: イメージビルドと実行
docker build -t app-sec-lab:1 .
docker run --rm -p 3000:3000 app-sec-lab:1

docker inspect app-sec-lab:1 --format '{{.Config.User}}'

# Kubernetes: デプロイ履歴・ロールバック（練習）
kubectl rollout history deployment/myapp -n default
kubectl rollout undo deployment/myapp -n default
kubectl rollout status deployment/myapp -n default

# Terraform: フォーマットと静的チェック
terraform fmt -recursive
terraform validate

# Logs（例）
journalctl -u docker --since "1 hour ago"
```

---

## 6) Common mistakes and how to avoid them

1. **「認証した=認可済み」と誤解**  
   - 対策: エンドポイント単位で権限判定を実装・テスト

2. **Dockerをroot実行のまま放置**  
   - 対策: `USER`指定をCIで必須チェック

3. **IAMポリシーをコピペ運用**  
   - 対策: 変更理由をPRに明記、四半期ごと棚卸し

4. **監視項目が多すぎて見ない**  
   - 対策: 最初は3指標（Latency/Error/Traffic）に絞る

5. **障害訓練が“読むだけ”で終わる**  
   - 対策: 実際に`rollout undo`を打つ演習を定例化

---

## 7) One interview-style question

**Q.** 「本番APIでBroken Access Controlを防ぐため、アプリコード・CI/CD・クラウドIAMの3層で何を実装しますか？」  
**期待される観点:**
- アプリ: resource ownershipチェック、RBAC/ABAC
- CI/CD: セキュリティテスト（SAST/DAST）とpolicy gate
- IAM: 最小権限、短命credential、監査ログ

---

## 8) Next-step reading links

- OWASP Top 10: https://owasp.org/www-project-top-ten/  
- OWASP ASVS: https://owasp.org/www-project-application-security-verification-standard/  
- Docker security best practices: https://docs.docker.com/engine/security/  
- Kubernetes Security Checklist: https://kubernetes.io/docs/concepts/security/overview/  
- Terraform security practices (HashiCorp docs): https://developer.hashicorp.com/terraform  
- AWS IAM best practices: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html  
- Google Cloud IAM best practices: https://cloud.google.com/iam/docs/best-practices  
- OpenTelemetry docs: https://opentelemetry.io/docs/  
- Prometheus docs: https://prometheus.io/docs/introduction/overview/  
- Grafana docs: https://grafana.com/docs/

---

### Curriculum rotation note
次号は**Middle**として、以下を前提に進みます：
- Linux: ファイル権限/プロセス/ネットワーク基本
- Docker: マルチステージビルド、イメージレイヤ理解
- Kubernetes: Deployment/Service/ConfigMap基礎
- Security: 認証と認可の違いを説明できること

このマガジンは **Beginner → Middle → Advanced** を循環し、
Application Security / DevOps Core / Cloud Security / Observability / K8s Incident Drills を継続ローテーションします。
