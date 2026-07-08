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
links:
  - "[[Home]]"
created: 2026-07-07 09:00
---

# SecDevOps Magazine — 2026-07-07

[[Home]]

#security #devops #docker #kubernetes #terraform #linux #cloudsecurity #observability #daily

## 今日の学習テーマ
**Docker Hardening 入門 + Linux 権限の基本**
**Level: Beginner**

### 1) Topic + Level
Docker Hardening 入門: 「とりあえず動く」コンテナから、「本番でも事故りにくい」コンテナへ。

### 2) Why it matters in real projects
実務では、コンテナを使っただけでは安全になりません。むしろ、
- root で動くコンテナ
- 不要な package を大量に含む image
- secrets を image に焼き込む運用
- latest タグ依存
のような状態は、攻撃面を広げます。

Docker Hardening を理解すると、開発スピードを落としすぎずに、**脆弱性の露出・権限の過剰付与・事故時の被害範囲**を減らせます。これは Application Security と DevOps の接点そのものです。

### 3) Core concepts
#### A. 最小権限 (Least Privilege)
コンテナ内の process を root のまま動かさず、必要最小限の user / capability で実行します。

- `USER appuser` を使う
- `--cap-drop=ALL` を基本に考える
- `--read-only` で filesystem を極力読み取り専用にする

**考え方:** 攻撃されても「できること」を少なくしておく。

#### B. 最小構成 (Minimal Base Image)
base image が大きいほど、不要な package や脆弱性も増えやすいです。

- `debian:latest` を雑に使うより、用途に合う軽量 image を選ぶ
- multi-stage build で build tool を runtime image から外す

**考え方:** 実行に不要なものは、本番 image に入れない。

#### C. Immutable Infrastructure の感覚
コンテナに SSH して手作業で直すのではなく、**Dockerfile を直して再 build / 再 deploy** するのが基本です。

**考え方:** 手修正は再現性を壊す。変更はコードに残す。

#### D. Secrets Management の原則
API key や password を Dockerfile / image / Git repository に埋め込まない。

避けるべき例:
- `ENV DB_PASSWORD=...`
- `.env` をそのまま image に `COPY`
- source code に token を直書き

使う方向性:
- 環境変数の注入
- secret manager
- CI/CD の secret store

#### E. Tag 固定と Supply Chain 意識
`latest` は便利ですが、いつ中身が変わるかわかりません。

- version tag を明示する
- できれば digest pinning も検討する
- image の出所を確認する

これは将来の **CI/CD security** や **Kubernetes security** に直結します。

### 4) Hands-on mini lab (30-60 min)
#### 目標
「危ない Dockerfile」と「少し安全な Dockerfile」を比べて、差分を体感します。

#### Step 1: 危ない例を作る
`Dockerfile.bad`
```dockerfile
FROM node:latest
WORKDIR /app
COPY . .
RUN npm install
ENV APP_ENV=production
ENV DEMO_SECRET=hardcoded-secret
CMD ["npm", "start"]
```

観察ポイント:
- `latest` を使用
- root 実行のまま
- hardcoded secret
- `npm install` で再現性が弱い
- `.dockerignore` がなければ不要ファイルが入る可能性

#### Step 2: 改善版を作る
`Dockerfile.good`
```dockerfile
FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:20-alpine
WORKDIR /app
COPY --from=build /app/package*.json ./
RUN npm ci --omit=dev && npm cache clean --force
COPY --from=build /app/dist ./dist

RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

ENV NODE_ENV=production
CMD ["node", "dist/index.js"]
```

#### Step 3: `.dockerignore` を追加
```gitignore
node_modules
.git
.env
npm-debug.log
Dockerfile.bad
```

#### Step 4: build して metadata を見る
```bash
docker build -f Dockerfile.bad -t app-bad .
docker build -f Dockerfile.good -t app-good .
docker image ls | grep app-
```

#### Step 5: 実行 user を確認
```bash
docker run --rm app-good id
docker run --rm app-bad id
```

期待する違い:
- `app-bad` は root になりやすい
- `app-good` は appuser で動く

#### Step 6: 追加 hardening を試す
```bash
docker run --rm --read-only --cap-drop=ALL app-good
```

もし動かなくなったら、それは学びです。アプリがどの書き込みや capability を必要としているか見える化できます。

### 5) Command cheatsheet
#### Linux
```bash
id
whoami
ps aux
ss -tulpn
ls -lah
chmod 640 file.txt
chown appuser:appgroup file.txt
```

#### Docker
```bash
docker build -t myapp .
docker image ls
docker history myapp
docker inspect myapp
docker run --rm myapp id
docker run --rm --read-only --cap-drop=ALL myapp
docker exec -it <container> sh
```

#### まず覚えたい意味
- `docker history`: image layer の確認
- `docker inspect`: 詳細設定の確認
- `--read-only`: root filesystem を読み取り専用にする
- `--cap-drop=ALL`: Linux capability を全部落とす
- `USER`: コンテナ内の実行 user を指定

### 6) Common mistakes and how to avoid them
#### ミス1: 「開発で動いたから本番もOK」
**回避:** 本番では権限・secrets・image size・再現性を別軸で確認する。

#### ミス2: `latest` を使い続ける
**回避:** version tag を固定する。変更は意図的に行う。

#### ミス3: root 実行を放置する
**回避:** Dockerfile に `USER` を入れる。`docker run ... id` で必ず確認する。

#### ミス4: `.env` や鍵を image に含める
**回避:** `.dockerignore` を設定し、secret は外部注入する。

#### ミス5: build tool を runtime に残す
**回避:** multi-stage build を使って runtime image を細くする。

### 7) One interview-style question
**質問:**
「Docker コンテナを non-root user で動かすべき理由を、セキュリティと運用の両面から説明してください。」

**考えるポイント:**
- 権限昇格や被害拡大の抑制
- host への影響範囲の縮小
- principle of least privilege
- file permission や volume 運用との関係

### 8) Next-step reading links
- OWASP Docker Security Cheat Sheet  
  https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html
- Docker Docs: Build best practices  
  https://docs.docker.com/build/building/best-practices/
- Docker Docs: Multi-stage builds  
  https://docs.docker.com/build/building/multi-stage/
- CIS Docker Benchmark overview  
  https://www.cisecurity.org/benchmark/docker
- Node.js Docker Official Image guide  
  https://hub.docker.com/_/node

---

## 学習アークメモ
この magazine は **Beginner → Middle → Advanced** を繰り返す学習アークで進めます。

### Current Arc: Container Security Foundations
- **Day 1 / Beginner:** Docker Hardening の基礎 ← 今日
- **Next / Middle 予定:** Kubernetes Pod Security / SecurityContext
  - **Prerequisites:** Dockerfile の基本、container user、Linux permission の理解
- **Then / Advanced 予定:** Kubernetes incident drill（権限ミスや rollout failure からの rollback / recovery）
  - **Prerequisites:** kubectl 基本、Deployment/Pod の仕組み、logging の読み方

### 今後ローテーションする主要トラック
- Application Security: secure coding / OWASP risks / threat modeling / auth & session security / incident response
- DevOps Core: Docker hardening / Kubernetes fundamentals & security / Terraform & IaC best practices / Linux command mastery / CI/CD security / secrets management
- Added Required Topics:
  - Cloud Security: AWS/GCP IAM & permission design
  - Observability: Prometheus / Grafana / OpenTelemetry
  - Kubernetes incident drills: failure / rollback / recovery

明日は Middle に進める前提で、**container と Linux 権限の基礎**を自分の言葉で説明できる状態を目指しましょう。