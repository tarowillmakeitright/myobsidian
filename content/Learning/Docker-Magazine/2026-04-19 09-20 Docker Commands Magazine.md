---
tags:
  - docker
  - containers
  - devops
  - learning
  - daily
---

[[Home]]

# Docker Commands Magazine — 2026-04-19

日々の実務で使えるDockerコマンドを、**Beginner → Middle → Advanced**の順で段階的に学ぶ号です。

---

## 1) Topic + Level

### Beginner
**Topic:** コンテナの基本ライフサイクル（`pull` / `run` / `ps` / `logs` / `exec` / `stop` / `rm`）

### Middle
**Topic:** 開発環境の再現性を上げるDockerfile（`build` / `buildx` / `.dockerignore` / タグ運用）

**Prerequisites（前提）:**
- Beginner内容を実行できる
- Linuxコマンド基本（`cd`, `ls`, `cat`）
- アプリ実行コマンド（例: `npm start`, `python app.py`）の理解

### Advanced
**Topic:** Composeで複数サービス運用 + ヘルスチェック + セキュアな設定管理

**Prerequisites（前提）:**
- Middle内容のDockerfileを自力で書ける
- ネットワーク/ポートの基本理解
- RDB（PostgreSQL/MySQL等）の接続概念を理解

---

## 2) Why it matters for real app development

- **ローカル差異の削減:** 「自分のPCでは動く」を減らし、チーム全員で同じ環境を再現できる。
- **オンボーディング高速化:** 新メンバーが短時間で開発開始できる。
- **CI/CDとの整合:** ローカルで動くコンテナをそのままCIで検証しやすい。
- **運用事故の予防:** イメージサイズ最適化・秘密情報の分離・ヘルスチェックで本番トラブルを減らせる。

---

## 3) Core Docker command explanations

### Beginnerコマンド
- `docker pull nginx:stable`
  - レジストリからイメージ取得。
- `docker run -d --name web -p 8080:80 nginx:stable`
  - バックグラウンド起動、名前付け、ポート公開。
- `docker ps` / `docker ps -a`
  - 実行中 / 全コンテナ確認。
- `docker logs -f web`
  - ログ追跡（`-f`で追従）。
- `docker exec -it web sh`
  - 稼働中コンテナへ対話接続。
- `docker stop web && docker rm web`
  - 停止して削除。

### Middleコマンド
- `docker build -t myapp:dev .`
  - 現在ディレクトリをビルドコンテキストにしてイメージ化。
- `docker buildx build --platform linux/arm64 -t myapp:arm64 .`
  - BuildKit/Buildxでプラットフォーム指定ビルド。
- `docker image ls`
  - イメージ一覧。
- `docker run --rm myapp:dev`
  - 終了時にコンテナを自動削除（使い捨て実行向け）。

### Advancedコマンド
- `docker compose up -d`
  - compose.yamlの複数サービスを起動。
- `docker compose ps`
  - サービス状態確認。
- `docker compose logs -f app`
  - 特定サービスログ追従。
- `docker compose down`
  - スタック停止・ネットワーク削除。
- `docker compose config`
  - 最終解決済み設定の確認（ミス検出に有効）。

---

## 4) How Docker is used while building apps（docsベストプラクティス準拠）

- **マルチステージビルド**でビルド用依存を最終イメージから除外。
- **軽量ベースイメージ**（公式/信頼できるもの）を使う。
- **`.dockerignore`**で不要ファイル（`.git`, `node_modules`, 大容量生成物）を送らない。
- **レイヤーキャッシュ最適化**（依存定義ファイル→依存導入→アプリ本体の順にCOPY）。
- **Secretsをイメージに埋め込まない**（`ENV`固定値やDockerfile直書き禁止）。
  - 実行時に環境変数/secret機構で注入。
- **最小権限**（可能なら非rootユーザーで実行）。
- **ヘルスチェック**を設定し、死活監視可能にする。

---

## 5) 30–60分 Hands-on Mini Lab

### ゴール
Node.js API + PostgreSQLをComposeで起動し、ヘルスチェックと安全な設定を確認する。

### 所要時間
45分目安

### 手順
1. 作業ディレクトリ作成
```bash
mkdir -p docker-lab && cd docker-lab
```

2. `app.js`（最小API）作成
```js
const http = require('http');
const port = process.env.PORT || 3000;
http.createServer((req, res) => {
  if (req.url === '/health') {
    res.writeHead(200, {'Content-Type': 'application/json'});
    return res.end(JSON.stringify({status: 'ok'}));
  }
  res.writeHead(200);
  res.end('hello docker');
}).listen(port, () => console.log(`listening on ${port}`));
```

3. `package.json`作成
```json
{
  "name": "docker-lab",
  "version": "1.0.0",
  "main": "app.js",
  "scripts": {"start": "node app.js"}
}
```

4. `Dockerfile`作成
```Dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package.json ./
RUN npm install --omit=dev
COPY app.js ./
USER node
EXPOSE 3000
CMD ["npm", "start"]
```

5. `compose.yaml`作成（秘密値は直書きしない）
```yaml
services:
  app:
    build: .
    ports:
      - "3000:3000"
    healthcheck:
      test: ["CMD", "wget", "-qO-", "http://localhost:3000/health"]
      interval: 10s
      timeout: 3s
      retries: 5
    environment:
      - PORT=3000
    depends_on:
      db:
        condition: service_healthy

  db:
    image: postgres:16-alpine
    environment:
      - POSTGRES_USER=app
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
      - POSTGRES_DB=appdb
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U app -d appdb"]
      interval: 10s
      timeout: 5s
      retries: 5
```

6. `.env`作成（ローカル専用、Gitに含めない）
```bash
POSTGRES_PASSWORD=change-me-now
```

7. 起動・確認
```bash
docker compose up -d --build
docker compose ps
curl http://localhost:3000/health
```

8. ログ確認
```bash
docker compose logs -f app
```

9. 終了
```bash
docker compose down
```

---

## 6) Command cheatsheet

```bash
# 取得・起動
docker pull IMAGE:TAG
docker run -d --name NAME -p HOST:CONTAINER IMAGE:TAG

# 観察
docker ps
docker logs -f NAME
docker exec -it NAME sh

# ビルド
docker build -t REPO:TAG .
docker buildx build --platform linux/arm64 -t REPO:TAG .

# Compose
docker compose up -d
docker compose ps
docker compose logs -f SERVICE
docker compose down

# 注意: 破壊的（実行前に対象確認）
docker rm -f CONTAINER
docker rmi IMAGE
docker system prune
```

---

## 7) Common mistakes and safe practices

### よくあるミス
- `latest`タグ固定で意図せず挙動が変わる
- `.dockerignore`未設定でビルドが遅い/機密混入
- Dockerfileやcomposeに秘密情報を直書き
- 不要な`--privileged`やroot実行
- `docker system prune`を確認なしで実行

### 安全運用
- タグは明示（例: `node:20-alpine`, `postgres:16-alpine`）
- `.env`やsecret管理を使い、**イメージに秘密を残さない**
- 破壊系コマンド前に必ず確認:
  - `docker ps -a`
  - `docker image ls`
  - `docker volume ls`
- クリーンアップは段階的に（いきなり`prune`しない）

> ⚠️ 警告: `prune` / `rmi` / `rm -f` はデータや再利用資産を失う可能性があります。対象を確認してから実行してください。

---

## 8) Interview-style question

**Q.** 開発用Dockerfileでキャッシュ効率とセキュリティを両立させるには、`COPY`順序・ユーザー権限・秘密情報管理をどう設計しますか？

（回答ポイント: 依存定義先コピーでキャッシュ活用、非root実行、Build-time/Run-time secret分離、不要ファイル除外、最小ベースイメージ）

---

## 9) Next-step resources（公式優先）

- Docker Docs Home: https://docs.docker.com/
- Get Started: https://docs.docker.com/get-started/
- Dockerfile best practices: https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Multi-stage builds: https://docs.docker.com/build/building/multi-stage/
- Build cache: https://docs.docker.com/build/cache/
- Docker Compose overview: https://docs.docker.com/compose/
- Compose file reference: https://docs.docker.com/reference/compose-file/
- Docker Engine security: https://docs.docker.com/engine/security/
- Secrets (Swarm/secure patterns): https://docs.docker.com/engine/swarm/secrets/

---

次号予告（学習アーク継続）: 「Beginner: Volume基礎 → Middle: Bind mount設計 → Advanced: Backup/Restore戦略」