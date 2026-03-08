---
tags: [docker, containers, devops, learning, daily]
---

# Docker Commands Magazine — 2026-03-08 09:20
[[Home]]

#docker #containers #devops #learning #daily

本日のテーマは、**Beginner → Middle → Advanced** の学習アークで「開発で本当に使う Docker コマンド」を段階的に身につける構成です。

---

## 1) Topic + Level

### Beginner
**トピック:** コンテナの基本ライフサイクル（`docker run` / `ps` / `logs` / `stop` / `rm`）

### Middle
**トピック:** イメージ作成と再現可能な開発環境（`docker build` / `Dockerfile` / `docker exec`）
**前提条件:** Beginnerの内容（コンテナ起動・停止・確認）を理解していること

### Advanced
**トピック:** マルチコンテナ開発と運用準備（`docker compose up/down` / ヘルスチェック / ボリューム）
**前提条件:** Middleの内容（Dockerfileとビルド）を理解していること

---

## 2) Why it matters for real app development

- **環境差異の吸収:** 「自分のPCでは動く」を減らし、チーム全員で同じ実行環境を共有できる。
- **オンボーディング高速化:** 新メンバーは Docker で依存関係込みの環境を短時間で再現可能。
- **CI/CDとの整合:** ローカルで使うイメージとCIで使うイメージを近づけることで、デプロイ事故を減らせる。
- **セキュリティと責務分離:** コンテナ境界・最小権限・イメージ固定化により、リスクを局所化できる。

---

## 3) Core Docker command explanations

### Beginnerコマンド
- `docker run -d --name web -p 8080:80 nginx:alpine`
  - `-d`: バックグラウンド実行
  - `--name`: 管理しやすい名前を付与
  - `-p 8080:80`: ホスト8080 → コンテナ80
- `docker ps`
  - 稼働中コンテナ一覧を確認
- `docker logs -f web`
  - ログを追従してトラブル確認
- `docker stop web && docker rm web`
  - 停止して削除（開発中の整理）

### Middleコマンド
- `docker build -t myapp:dev .`
  - Dockerfileからイメージ作成
- `docker image ls`
  - ローカルイメージ確認
- `docker exec -it myapp sh`
  - 稼働コンテナ内でデバッグ

### Advancedコマンド
- `docker compose up -d`
  - 複数サービスをまとめて起動
- `docker compose logs -f api`
  - 特定サービスのログ確認
- `docker compose down`
  - スタック停止（必要なら`-v`でボリューム削除）

> ⚠️ 注意（破壊的コマンド）
> - `docker system prune`, `docker image prune -a`, `docker rm -f`, `docker rmi` は削除範囲を必ず確認。
> - 実行前に `docker ps -a` / `docker image ls` / `docker volume ls` で対象確認する。

---

## 4) How Docker is used while building apps (docs.docker.comベストプラクティス準拠)

実務での基本フロー:
1. **開発用Dockerfile作成**（軽量ベースイメージ、不要ファイル除外）
2. **`.dockerignore`整備**（`node_modules`, `.git`, secretsを除外）
3. **BuildKit活用**（高速ビルド・キャッシュ最適化）
4. **Composeで依存サービスを定義**（DB, Redis, API）
5. **環境変数は`.env`やsecret管理で注入**（イメージに埋め込まない）
6. **ヘルスチェックと再起動ポリシーで安定化**

ベストプラクティス要点:
- 最小ベースイメージを使う（例: `alpine`/slim系、ただし互換性を確認）
- 1コンテナ1責務を基本にする
- タグは固定化（`latest`常用を避ける）
- 非rootユーザー実行を検討
- シークレットをDockerfile/Composeへ直書きしない

---

## 5) 30-60 minute hands-on mini lab

### 目標
Node.js API + Redis を Compose で起動し、ログ確認と再起動挙動を体験する。

### 所要時間
約45分

### 手順
1. 作業ディレクトリ作成
```bash
mkdir -p docker-mag-lab && cd docker-mag-lab
```

2. `app.js` を作成
```js
const http = require('http');
const port = process.env.PORT || 3000;
http.createServer((req, res) => {
  res.end('Docker Magazine Lab OK\n');
}).listen(port, () => console.log(`listening on ${port}`));
```

3. `package.json` を作成
```json
{
  "name": "docker-mag-lab",
  "version": "1.0.0",
  "main": "app.js",
  "scripts": { "start": "node app.js" }
}
```

4. `Dockerfile` を作成
```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package.json ./
RUN npm install --omit=dev
COPY app.js ./
USER node
EXPOSE 3000
CMD ["npm", "start"]
```

5. `compose.yaml` を作成
```yaml
services:
  api:
    build: .
    ports:
      - "3000:3000"
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "wget", "-qO-", "http://localhost:3000"]
      interval: 10s
      timeout: 3s
      retries: 3
  redis:
    image: redis:7-alpine
    restart: unless-stopped
```

6. 起動と確認
```bash
docker compose up -d
docker compose ps
curl http://localhost:3000
```

7. ログ確認
```bash
docker compose logs -f api
```

8. 停止
```bash
docker compose down
```

> 追加課題（+15分）: `api` に環境変数を追加し、`docker compose config` で最終定義を確認。

---

## 6) Command cheatsheet

```bash
# 実行中コンテナ確認
docker ps

# 全コンテナ確認（停止含む）
docker ps -a

# イメージ作成
docker build -t myapp:dev .

# 単体コンテナ起動
docker run -d --name myapp -p 3000:3000 myapp:dev

# コンテナ内シェル
docker exec -it myapp sh

# Compose起動/停止
docker compose up -d
docker compose down

# ログ追従
docker compose logs -f
```

---

## 7) Common mistakes and safe practices

### よくあるミス
- `latest`タグ依存で、いつの間にか挙動が変わる
- `.env` をGit管理してシークレット漏えい
- コンテナにrootで入りっぱなし運用
- `prune`系を無確認実行して必要リソースを削除

### 安全運用のコツ
- イメージタグを固定（例: `node:20.11-alpine`）
- `.dockerignore` と `.gitignore` を明確化
- 機密情報は secret manager / 環境注入で扱う
- 削除系は「一覧確認 → 対象限定」で実行
- 本番想定では read-only filesystem / non-root 実行を検討

---

## 8) One interview-style question

**質問:**
「`docker run` と `docker compose up` の使い分けを、開発チームでの再現性・保守性の観点から説明してください。」

**意図（面接官視点）:**
単発実行と宣言的構成管理の違いを、実務メリット（再現性・共有・変更管理）に結びつけて話せるか。

---

## 9) Next-step resources (公式優先)

- Docker Docs Home  
  https://docs.docker.com/
- Get Started  
  https://docs.docker.com/get-started/
- Dockerfile best practices  
  https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Compose overview  
  https://docs.docker.com/compose/
- Compose file reference  
  https://docs.docker.com/reference/compose-file/
- Build cache / BuildKit  
  https://docs.docker.com/build/
- Docker security  
  https://docs.docker.com/engine/security/

---

次号予告: **ボリューム設計（bind mount vs named volume）と開発速度・安全性の両立**
