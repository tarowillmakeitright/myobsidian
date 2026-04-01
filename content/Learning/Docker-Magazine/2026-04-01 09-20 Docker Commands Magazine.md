---
tags: [docker, containers, devops, learning, daily]
date: 2026-04-01
time: 09:20
---

# Docker Commands Magazine（2026-04-01）
[[Home]]

> 今日の学習アーク：**Beginner → Middle → Advanced**
> 目的：実務で使える Docker コマンドの理解を、段階的に積み上げる

---

## 1) Topic + Level

### 🟢 Beginner
**テーマ:** `docker run / ps / logs / exec` で「動かす・見る・入る」の基本を固める

### 🟡 Middle
**テーマ:** `Dockerfile` + `docker build` で再現可能な開発コンテナを作る
**前提知識（Prerequisites）:**
- Beginner の `run/ps/logs/exec` を使ってコンテナ操作ができる
- Linux の基本コマンド（`ls`, `cat`, `curl`）
- アプリの依存関係（npm/pip 等）の概念

### 🔴 Advanced
**テーマ:** `docker compose` で複数サービス（app + db）を安全に運用する
**前提知識（Prerequisites）:**
- Middle の Dockerfile 作成・ビルド・タグ付けができる
- ネットワーク/ポートの基本（公開ポートと内部ポート）
- `.env` と設定分離の意味

---

## 2) なぜ実アプリ開発で重要か

- **環境差分を潰せる**：ローカル・CI・本番で同じイメージを使える
- **オンボーディングが速い**：`docker compose up` で開発開始が早い
- **障害切り分けが容易**：`logs` とヘルスチェックで原因追跡しやすい
- **セキュリティ改善**：最小イメージ・非 root 実行・秘密情報の分離でリスク低減

Docker は「アプリを動かす箱」ではなく、**再現性ある開発/デリバリーの土台**です。

---

## 3) コア Docker コマンド解説

### Beginner コア
- `docker run -d --name web -p 8080:80 nginx:alpine`
  - `-d`: バックグラウンド実行
  - `--name`: コンテナ名付与
  - `-p 8080:80`: ホスト8080 → コンテナ80
- `docker ps` / `docker ps -a`
  - 起動中 / 全コンテナ確認
- `docker logs -f web`
  - `-f` で追尾表示
- `docker exec -it web sh`
  - 稼働中コンテナへ対話シェル接続

### Middle コア
- `docker build -t myapp:dev .`
  - カレントディレクトリの Dockerfile からイメージ作成
- `docker images`
  - 作成済みイメージ確認
- `docker run --rm -p 3000:3000 myapp:dev`
  - `--rm` で終了時にコンテナ自動削除

### Advanced コア
- `docker compose up -d`
  - 複数サービスを一括起動
- `docker compose logs -f app`
  - app サービスログを追尾
- `docker compose exec app sh`
  - app サービス内へ接続
- `docker compose down`
  - 停止/ネットワーク削除（volumeは `-v` 指定時のみ削除）

---

## 4) アプリ構築での Docker 活用（docs.docker.com ベストプラクティス準拠）

- **小さく保つ**：`alpine` など軽量ベース、不要ツールを入れない
- **レイヤー最適化**：依存関係インストールとアプリコピー順を工夫し、ビルドキャッシュ活用
- **.dockerignore を必ず使う**：`node_modules`, `.git`, 秘密ファイルを除外
- **秘密情報をイメージに埋め込まない**：
  - ❌ `ENV DB_PASSWORD=...` を Dockerfile に直書き
  - ✅ 実行時に環境変数注入 or secret 管理
- **1コンテナ1責務を意識**（Composeでサービス分離）
- **非 root ユーザーで実行**（可能な範囲で）
- **ヘルスチェック/再起動ポリシー**で可用性向上

---

## 5) 30〜60分ハンズオン・ミニラボ

**ラボ名:** Node API + Redis を Compose で起動して観察する（約45分）

### 手順
1. 作業ディレクトリ作成（5分）
```bash
mkdir -p docker-mag-lab && cd docker-mag-lab
```

2. `app.js` 作成（10分）
```js
const express = require('express');
const redis = require('redis');
const app = express();
const client = redis.createClient({ url: 'redis://redis:6379' });

client.connect();

app.get('/', async (_, res) => {
  const n = await client.incr('hits');
  res.send(`hello docker compose: ${n}`);
});

app.listen(3000, () => console.log('listening on 3000'));
```

3. `package.json` 作成（5分）
```json
{
  "name": "docker-mag-lab",
  "version": "1.0.0",
  "main": "app.js",
  "scripts": { "start": "node app.js" },
  "dependencies": {
    "express": "^4.19.2",
    "redis": "^4.6.14"
  }
}
```

4. Dockerfile 作成（10分）
```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev
COPY app.js ./
EXPOSE 3000
USER node
CMD ["npm", "start"]
```

5. `compose.yaml` 作成（10分）
```yaml
services:
  app:
    build: .
    ports:
      - "3000:3000"
    depends_on:
      - redis
    restart: unless-stopped
  redis:
    image: redis:7-alpine
    restart: unless-stopped
```

6. 起動・確認（5分）
```bash
docker compose up -d
docker compose ps
curl http://localhost:3000
docker compose logs -f app
```

7. 片付け（安全版）（数分）
```bash
docker compose down
```

**達成基準:**
- `curl` のアクセス回数が増えて返る
- `logs` で app の起動確認
- `compose down` で停止できる

---

## 6) コマンド・チートシート

```bash
# 主要確認
docker ps
docker images
docker inspect <container>

# 実行・デバッグ
docker run --rm -it alpine sh
docker logs -f <container>
docker exec -it <container> sh

# ビルド
docker build -t myapp:dev .

# Compose
docker compose up -d
docker compose ps
docker compose logs -f
docker compose exec app sh
docker compose down

# 注意が必要なクリーンアップ（破壊的）
# ↓実行前に削除対象を必ず確認
# docker system prune -a
# docker image rm -f <image>
# docker rm -f <container>
```

---

## 7) よくあるミスと安全プラクティス

### よくあるミス
- ポート競合（例: 3000 が既に使用中）
- Dockerfile で `COPY . .` を先に書き、キャッシュ効率が悪化
- `.dockerignore` 未設定で不要/機密ファイルを送る
- `latest` タグ固定で再現性が崩れる
- `docker system prune -a` を確認なしで実行して必要資産を消す

### 安全プラクティス
- 破壊的コマンド前に確認:
  - `docker ps -a`
  - `docker images`
  - `docker volume ls`
- イメージタグを明示（`myapp:2026-04-01` など）
- 秘密情報は `.env` / シークレット管理へ分離（**イメージへ埋め込まない**）
- 非 root 実行、最小権限、必要最小ポート公開

---

## 8) 面接風クエスチョン（1問）

**Q.** `docker run` と `docker compose up` の使い分けを、開発現場の具体例で説明してください。さらに、Compose で secrets を安全に扱う基本方針も述べてください。

---

## 9) 次の一歩（公式ドキュメント中心）

- Docker Get Started  
  https://docs.docker.com/get-started/
- Dockerfile best practices  
  https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Compose overview  
  https://docs.docker.com/compose/
- Compose file reference  
  https://docs.docker.com/reference/compose-file/
- Docker build cache  
  https://docs.docker.com/build/cache/
- Multi-stage builds  
  https://docs.docker.com/build/building/multi-stage/
- Docker secrets（機密情報の扱い）  
  https://docs.docker.com/engine/swarm/secrets/

---

次号予告：**Beginner「volume と bind mount」→ Middle「開発体験を上げるホットリロード」→ Advanced「CIでのイメージビルド最適化」**