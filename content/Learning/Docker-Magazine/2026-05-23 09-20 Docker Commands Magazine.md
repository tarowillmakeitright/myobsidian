---
tags: [docker, containers, devops, learning, daily]
---

# 2026-05-23 Docker Commands Magazine
[[Home]]

> 今日の学習アーク: **Beginner → Middle → Advanced**  
> テーマは段階的に繋がっています。Middle/Advanced には前提条件を明記。

---

## 1) Topic + Level

### Beginner
**トピック:** `docker run` / `docker ps` / `docker logs` で「コンテナを動かして観察する」

### Middle
**トピック:** `docker build` + `Dockerfile` 最適化（レイヤー、キャッシュ、`.dockerignore`）
**前提条件:** Beginner の内容（コンテナ起動・停止・ログ確認）ができること

### Advanced
**トピック:** 開発向け `docker compose`（複数サービス連携 + ヘルスチェック + 安全な設定）
**前提条件:** Middle の内容（Dockerfile 作成とビルド、タグ運用）ができること

---

## 2) Why it matters for real app development

- **再現性:** 開発環境を「コード化」して、メンバー間の差分を減らせる。
- **速度:** ローカル環境汚染を減らし、オンボーディング時間を短縮できる。
- **品質:** CI と同じコンテナ前提で動かせるため「自分のPCだけ動く」を減らせる。
- **安全性:** 実行ユーザー・最小イメージ・秘密情報分離を徹底すると、脆弱性リスクを下げられる。

---

## 3) Core Docker command explanations

### Beginner core
- `docker run --name web -p 8080:80 nginx:alpine`
  - イメージからコンテナを作成・起動。
  - `-p 8080:80` は **ホスト8080 → コンテナ80** を公開。
- `docker ps` / `docker ps -a`
  - 起動中 / 全コンテナ一覧。
- `docker logs -f web`
  - `-f` でリアルタイム追尾。
- `docker stop web && docker rm web`
  - 停止して削除（状態を初期化）。

### Middle core
- `docker build -t myapp:dev .`
  - カレントディレクトリをビルドコンテキストとしてイメージ作成。
- `docker image ls`
  - ローカルイメージ一覧。
- `docker history myapp:dev`
  - レイヤーの肥大化を確認。

### Advanced core
- `docker compose up -d`
  - 複数サービスをバックグラウンド起動。
- `docker compose ps`
  - サービス状態確認。
- `docker compose logs -f api`
  - 特定サービスのログ追尾。
- `docker compose down`
  - 構成停止・ネットワーク削除（ボリューム削除は `-v` 明示時のみ）。

---

## 4) How Docker is used while building apps (docs.docker.com 準拠の実践)

- **小さなベースイメージを選ぶ:** `alpine`/slim 系を検討（互換性は要確認）。
- **マルチステージビルド:** ビルド成果物だけ最終イメージへコピーし、不要なツールを残さない。
- **`.dockerignore` を適切に設定:** `node_modules`, `.git`, 大容量ログ等を除外し、ビルド高速化。
- **非rootユーザーで実行:** `USER app` などで権限最小化。
- **秘密情報をイメージに焼かない:**
  - `ENV PASSWORD=...` のような固定埋め込みは禁止。
  - Compose でも `.env` の取り扱いと配布範囲を厳格化。
- **タグ戦略:** `latest` 依存を避け、`myapp:1.4.2` のように明示。

---

## 5) 30-60 minute hands-on mini lab

### ゴール
Node.js API + Redis を Compose で起動し、API が Redis に接続できる状態を作る。

### 手順（約45分）

1. 作業フォルダ作成
```bash
mkdir -p docker-mag-lab && cd docker-mag-lab
```

2. `app.js` 作成（最小API）
```js
const express = require('express');
const Redis = require('ioredis');
const app = express();

const redis = new Redis({ host: process.env.REDIS_HOST || 'redis', port: 6379 });

app.get('/', async (_, res) => {
  const v = await redis.incr('hits');
  res.send(`hello docker, hits=${v}`);
});

app.listen(3000, () => console.log('api on 3000'));
```

3. `package.json` 作成
```json
{
  "name": "docker-mag-lab",
  "version": "1.0.0",
  "main": "app.js",
  "scripts": { "start": "node app.js" },
  "dependencies": {
    "express": "^4.19.2",
    "ioredis": "^5.4.1"
  }
}
```

4. `Dockerfile` 作成
```Dockerfile
FROM node:22-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev
COPY . .
EXPOSE 3000
USER node
CMD ["npm", "start"]
```

5. `.dockerignore` 作成
```gitignore
node_modules
npm-debug.log
.git
.DS_Store
```

6. `compose.yaml` 作成
```yaml
services:
  api:
    build: .
    ports:
      - "3000:3000"
    environment:
      REDIS_HOST: redis
    depends_on:
      redis:
        condition: service_healthy
  redis:
    image: redis:7-alpine
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 3s
      retries: 10
```

7. 起動・確認
```bash
docker compose up -d --build
docker compose ps
curl http://localhost:3000
curl http://localhost:3000
```

8. ログ確認・停止
```bash
docker compose logs -f api
docker compose down
```

---

## 6) Command cheatsheet

```bash
# コンテナ
docker run --name demo -d -p 8080:80 nginx:alpine
docker ps
docker logs -f demo
docker exec -it demo sh
docker stop demo && docker rm demo

# イメージ
docker build -t myapp:dev .
docker image ls
docker history myapp:dev

# Compose
docker compose up -d --build
docker compose ps
docker compose logs -f
docker compose down
```

---

## 7) Common mistakes and safe practices

### よくあるミス
- `COPY . .` 前に依存定義を分離せず、毎回フルビルドになって遅い。
- `latest` 固定で、環境差異を生む。
- アプリ秘密情報（APIキー等）を Dockerfile / compose に直書き。
- `root` 実行のまま本番投入。

### Safe practices
- Dockerfile は **キャッシュを意識した順番**（依存 → ソース）。
- 機密はシークレット管理へ。少なくとも Git 管理外に隔離。
- 不要ポート公開を避ける（`0.0.0.0` 公開は最小化）。
- 定期的にイメージ脆弱性スキャン（Docker Scout 等）を実施。

### ⚠️ 破壊的クリーンアップ注意
以下は削除範囲が広く、復旧困難な場合があります。実行前に対象確認:
- `docker system prune`
- `docker image prune -a`
- `docker rm -f <container>`
- `docker rmi <image>`

実行前に推奨:
```bash
docker ps -a
docker image ls
docker volume ls
```

---

## 8) Interview-style question

**質問:**
`docker build` を高速化しつつセキュリティも改善したい場合、Dockerfile の順序・ベースイメージ・実行ユーザー・機密情報管理をどう設計しますか？

**回答で見たい観点:**
- レイヤーキャッシュ最適化
- マルチステージ活用
- 最小権限（非root）
- secrets をイメージに残さない設計

---

## 9) Next-step resources (公式優先)

- Docker Docs Home: https://docs.docker.com/
- Get Started: https://docs.docker.com/get-started/
- Dockerfile best practices: https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Multi-stage builds: https://docs.docker.com/build/building/multi-stage/
- Compose overview: https://docs.docker.com/compose/
- Compose file reference: https://docs.docker.com/reference/compose-file/
- Docker Engine security: https://docs.docker.com/engine/security/
- Docker Scout: https://docs.docker.com/scout/

---

次号予告（学習アーク継続）:
- Beginner: ボリューム基礎（データ永続化）
- Middle: 開発用ホットリロード構成
- Advanced: CI での BuildKit キャッシュ最適化
