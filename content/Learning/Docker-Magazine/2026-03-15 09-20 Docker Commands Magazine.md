---
tags: [docker, containers, devops, learning, daily]
created: 2026-03-15 09:20
---

# Docker Commands Magazine — 2026-03-15
[[Home]]

> 今日の学習アーク: **Beginner → Middle → Advanced**
> テーマ: **開発で本当に使う Docker コマンド運用（build / run / compose / debug）**

---

## 1) Topic + Level

### 🟢 Beginner
**Topic:** `docker run` と `docker exec` で開発コンテナを動かす基礎

### 🟡 Middle
**Topic:** `docker build`（マルチステージ含む）と `docker compose up` による開発環境標準化
**Prerequisites:**
- `docker run`, `docker ps`, `docker logs` の基本を説明できる
- イメージとコンテナの違いを理解している

### 🔴 Advanced
**Topic:** BuildKit キャッシュ最適化 + Compose プロファイル + 安全なクリーンアップ運用
**Prerequisites:**
- Dockerfile の基本命令（FROM, COPY, RUN, CMD）を使える
- Compose で複数サービス（app + db）を起動した経験がある

---

## 2) Why it matters for real app development

- **環境差分の解消:** 「自分のPCでは動く」問題を減らせる
- **オンボーディング高速化:** 新メンバーが `docker compose up` で即開発開始
- **CI/CD接続が容易:** ローカルとCIで同じビルド手順を再利用
- **セキュリティ向上:** 実行環境の固定化、不要ツールを含まない軽量イメージ作成が可能

---

## 3) Core Docker command explanations

### Beginner Core
- `docker run -d --name web -p 8080:80 nginx:alpine`
  - イメージからコンテナを起動。`-d` はバックグラウンド、`-p` はポート公開
- `docker ps` / `docker ps -a`
  - 稼働中 / 全コンテナ一覧
- `docker logs -f web`
  - ログ追跡（`-f` は follow）
- `docker exec -it web sh`
  - 稼働中コンテナへ対話シェル接続

### Middle Core
- `docker build -t myapp:dev .`
  - Dockerfile からイメージ作成
- `docker compose up -d`
  - 複数サービスをまとめて起動
- `docker compose logs -f app`
  - app サービスのログ追跡
- `docker compose down`
  - サービス停止・ネットワーク削除（volume は通常保持）

### Advanced Core
- `DOCKER_BUILDKIT=1 docker build --progress=plain -t myapp:dev .`
  - BuildKit で効率化、詳細ビルドログ確認
- `docker buildx build --platform linux/amd64,linux/arm64 -t myorg/myapp:latest .`
  - マルチアーキ向けビルド（配布用途）
- `docker compose --profile debug up -d`
  - 必要時だけ追加サービスを起動（例: phpmyadmin, mailhog）

---

## 4) How Docker is used while building apps (docs.docker.com aligned)

実務フロー例（推奨）:
1. **開発用Dockerfile** と **本番用Dockerfile（またはマルチステージ）** を分離/整理
2. `.dockerignore` を整備し、不要ファイル送信を削減
3. 依存解決レイヤーを先に置いてキャッシュ効率化
4. `docker compose` で app/db/redis などをコード化
5. 秘密情報は **環境変数や secret 管理** を使い、イメージに焼き込まない
6. CI で同一 Dockerfile を使って build/test し、再現性を担保

> Best practice要点: 小さいイメージ、最小権限、秘密情報をイメージに含めない、キャッシュ活用、責務分離。

---

## 5) 30–60 minute hands-on mini lab

**Lab: Node.js API + Redis を Compose で起動し、ログ確認まで行う（45分目安）**

### Step 1 (10分): プロジェクト作成
```bash
mkdir docker-mag-lab && cd docker-mag-lab
cat > app.js <<'EOF'
const express = require('express');
const redis = require('redis');
const app = express();
const client = redis.createClient({ url: 'redis://redis:6379' });
client.connect();
app.get('/', async (_, res) => {
  const n = await client.incr('hits');
  res.send(`hello docker, hits=${n}`);
});
app.listen(3000, () => console.log('listening on 3000'));
EOF

cat > package.json <<'EOF'
{
  "name": "docker-mag-lab",
  "version": "1.0.0",
  "main": "app.js",
  "scripts": {"start": "node app.js"},
  "dependencies": {"express": "^4.19.2", "redis": "^4.6.14"}
}
EOF
```

### Step 2 (10分): Dockerfile 作成
```Dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
```

### Step 3 (10分): compose.yaml 作成
```yaml
services:
  app:
    build: .
    ports:
      - "3000:3000"
    depends_on:
      - redis
  redis:
    image: redis:7-alpine
```

### Step 4 (10分): 起動・検証
```bash
docker compose up -d --build
curl http://localhost:3000
curl http://localhost:3000
docker compose logs -f app
```

### Step 5 (5分): 停止
```bash
docker compose down
```

**確認ポイント:**
- hits が増えること
- app ログに listen が出ること
- コンテナ間通信が service 名（redis）でできること

---

## 6) Command cheatsheet

```bash
# 状態確認
docker ps
docker images
docker compose ps

# 実行・ログ
docker run -d --name sample -p 8080:80 nginx:alpine
docker logs -f sample
docker exec -it sample sh

# ビルド
docker build -t myapp:dev .
DOCKER_BUILDKIT=1 docker build -t myapp:dev .

# Compose
docker compose up -d --build
docker compose logs -f app
docker compose down

# クリーンアップ（⚠ 要注意）
# docker system prune -a
# docker image rm -f <image>
# docker rm -f <container>
```

---

## 7) Common mistakes and safe practices

### よくあるミス
- `.env` や秘密鍵を `COPY . .` でイメージに入れてしまう
- `latest` タグ固定で再現性が崩れる
- なんでも root 実行にする
- 不要な `prune` を本番ホストで実行する

### 安全運用
- `.dockerignore` に `.env`, `.git`, `node_modules` などを明記
- イメージタグはバージョン固定（例: `node:20-alpine`）
- 可能なら non-root ユーザーで実行
- **破壊的コマンド前に必ず確認:**
  - `docker system prune -a`
  - `docker image rm -f ...`
  - `docker rm -f ...`
- Secret は Dockerfile/compose 直書き禁止（環境変数・secret機構・外部シークレット管理を利用）

---

## 8) Interview-style question

**Q.** `docker compose down -v` と `docker compose down` の違いは？ 開発DBのデータ保全の観点でどう使い分けますか？

（答えるときの要点: volume削除有無、初期化したい時だけ `-v`、普段はデータ保持）

---

## 9) Next-step resources (official docs first)

- Docker docs home: https://docs.docker.com/
- Get started: https://docs.docker.com/get-started/
- Dockerfile best practices: https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Multi-stage builds: https://docs.docker.com/build/building/multi-stage/
- Compose overview: https://docs.docker.com/compose/
- Build cache: https://docs.docker.com/build/cache/
- Secrets (Build/Compose): https://docs.docker.com/build/building/secrets/

---

### 明日の予告（学習アーク継続）
- Beginner: ボリュームとバインドマウントの違い
- Middle: 開発体験を上げる hot reload 構成
- Advanced: セキュアな本番イメージ最適化（脆弱性スキャン含む）
