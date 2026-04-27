---
tags: [docker, containers, devops, learning, daily]
---

# 2026-04-27 09:20 Docker Commands Magazine
[[Home]]

#docker #containers #devops #learning #daily

## 今号の学習アーク
**Beginner → Middle → Advanced** の順で、実アプリ開発に直結する形で進めます。

---

## 1) Topic + Level

### 🟢 Beginner
**トピック:** `docker run` / `docker ps` / `docker logs` で「まず動かして観察する」

### 🟡 Middle
**トピック:** `Dockerfile` + `docker build` + `docker compose up` で開発環境を再現する
**前提知識:**
- Beginnerのコマンドを使ってコンテナ起動・停止・ログ確認ができる
- Linux基本コマンド（`cd`, `ls`, `cat`）がわかる

### 🔴 Advanced
**トピック:** マルチステージビルドとBuildKitキャッシュ、最小権限実行で本番品質に寄せる
**前提知識:**
- Middleの内容（Dockerfile/Compose）を理解している
- Webアプリの依存関係管理（npm/pip/go mod等）の基礎がある

---

## 2) Why it matters for real app development
- **環境差分の削減**: 「自分のPCでは動く」を減らし、チーム開発を安定化。
- **オンボーディング短縮**: `docker compose up` で開発環境を素早く再現。
- **デプロイ品質向上**: イメージを小さく・安全に保つことで、起動速度とセキュリティを改善。
- **障害調査しやすい**: `logs`, `inspect`, `exec` で実行時状態を確認しやすい。

---

## 3) Core Docker command explanations
- `docker run IMAGE`:
  - 新規コンテナを作成して起動。
  - 例: `-d`(バックグラウンド), `-p 8080:80`(ポート公開), `--name`(名前付け), `--rm`(停止時削除)
- `docker ps` / `docker ps -a`:
  - 稼働中/全コンテナ一覧を確認。
- `docker logs -f CONTAINER`:
  - ログを追尾して挙動確認。
- `docker exec -it CONTAINER sh`:
  - 稼働中コンテナ内に入って調査。
- `docker build -t myapp:dev .`:
  - Dockerfileからイメージ作成。
- `docker compose up -d` / `docker compose down`:
  - 複数サービスをまとめて起動/停止。
- `docker image ls`, `docker volume ls`, `docker network ls`:
  - リソース可視化と整理。

---

## 4) 実アプリ構築での使い方（docs.docker.comベストプラクティス準拠）
- **1コンテナ1責務**を意識（Web/API/DBをComposeで分離）。
- **マルチステージビルド**でビルド成果物のみを本番イメージへ。
- **`.dockerignore`**で不要ファイル（`.git`, `node_modules`, secrets）を送らない。
- **非rootユーザー実行**を基本にする。
- **イメージは固定タグ/可能ならdigest指定**で再現性確保。
- **Secretsをイメージに焼き込まない**（`ENV`直書きや`COPY .env`を避ける）。
- **Composeでも秘密情報は安全に管理**（環境変数注入時は漏洩に注意、公開リポジトリへ置かない）。

参考（公式）:
- Docker Build best practices: https://docs.docker.com/build/building/best-practices/
- Multi-stage builds: https://docs.docker.com/build/building/multi-stage/
- Docker Compose: https://docs.docker.com/compose/
- Dockerfile reference: https://docs.docker.com/reference/dockerfile/

---

## 5) 30-60分ハンズオン mini lab
**テーマ:** Node.js APIをコンテナ化し、Composeで起動、ログ確認、改善まで

### Step 0 (5分)
```bash
mkdir docker-mini-lab && cd docker-mini-lab
cat > app.js <<'EOF'
const http = require('http');
const port = process.env.PORT || 3000;
http.createServer((req, res) => {
  res.end('Docker mini lab OK\n');
}).listen(port, () => console.log(`listen ${port}`));
EOF

cat > package.json <<'EOF'
{
  "name": "docker-mini-lab",
  "version": "1.0.0",
  "main": "app.js",
  "scripts": {"start": "node app.js"}
}
EOF
```

### Step 1 Beginner (10分): runで起動
```bash
docker run --rm -d --name web1 -p 3000:3000 -v "$PWD":/app -w /app node:20-alpine sh -c "npm install --silent && npm start"
docker ps
docker logs -f web1
```
ブラウザ/`curl http://localhost:3000` で確認。

### Step 2 Middle (15分): Dockerfile + compose
```bash
cat > .dockerignore <<'EOF'
node_modules
.git
.env
EOF

cat > Dockerfile <<'EOF'
FROM node:20-alpine
WORKDIR /app
COPY package.json ./
RUN npm install --omit=dev --silent
COPY app.js ./
EXPOSE 3000
USER node
CMD ["npm", "start"]
EOF

cat > compose.yaml <<'EOF'
services:
  web:
    build: .
    ports:
      - "3000:3000"
EOF

docker compose up --build -d
docker compose logs -f web
```

### Step 3 Advanced (15-20分): マルチステージ最適化
`Dockerfile`を次のように更新:
```Dockerfile
FROM node:20-alpine AS deps
WORKDIR /app
COPY package.json ./
RUN npm install --omit=dev --silent

FROM node:20-alpine
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY app.js package.json ./
EXPOSE 3000
USER node
CMD ["npm", "start"]
```

再ビルドしてサイズ比較:
```bash
docker build -t mini:single .
# (必要なら single版Dockerfileを別名で保持して比較)
docker image ls | grep mini
```

### 片付け（安全注意つき）
```bash
docker compose down
```
⚠️ `docker system prune`, `docker image prune -a`, `docker rm -f`, `docker rmi` は削除影響が大きいです。対象確認（`docker ps -a`, `docker image ls`）後に実行してください。

---

## 6) Command cheatsheet
```bash
# 起動/確認
docker run -d --name app -p 8080:80 nginx:alpine
docker ps
docker logs -f app
docker exec -it app sh

# build/compose
docker build -t myapp:dev .
docker compose up -d --build
docker compose logs -f
docker compose down

# 調査
docker inspect app
docker stats

# 危険操作（要確認）
docker rm -f <container>
docker rmi <image>
docker system prune
```

---

## 7) Common mistakes and safe practices
- **ミス:** `COPY . .`で秘密情報まで混入
  - **対策:** `.dockerignore`を整備、`.env`や鍵を除外
- **ミス:** rootで実行し続ける
  - **対策:** `USER`を設定（最小権限）
- **ミス:** `latest`タグ固定で再現不能
  - **対策:** 明示タグ（必要に応じdigest）を利用
- **ミス:** 無差別`prune`
  - **対策:** 事前に一覧確認、対象限定削除
- **ミス:** Composeファイルへ秘密情報を直書き
  - **対策:** secret管理を分離、リポジトリへ秘密を置かない

---

## 8) Interview-style question
「本番用Dockerイメージで、**サイズ削減・ビルド速度・セキュリティ**を同時に改善するには、Dockerfileをどう設計しますか？（具体的にマルチステージ、キャッシュ活用、実行ユーザー、秘密情報の扱いを説明してください）」

---

## 9) Next-step resources（公式優先）
- Get started: https://docs.docker.com/get-started/
- Dockerfile reference: https://docs.docker.com/reference/dockerfile/
- Build best practices: https://docs.docker.com/build/building/best-practices/
- Multi-stage builds: https://docs.docker.com/build/building/multi-stage/
- Compose file reference: https://docs.docker.com/reference/compose-file/
- Docker Engine security: https://docs.docker.com/engine/security/

---

次号予告（案）: **Beginner: volume基礎 → Middle: DB永続化 → Advanced: backup/restore戦略**