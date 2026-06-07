---
tags: [docker, containers, devops, learning, daily]
---

# 2026-06-02 Docker Commands Magazine

#docker #containers #devops #learning #daily  
[[Home]]

---

## 今回のテーマ
**DockerネットワークとComposeによるローカル開発環境の実践（Beginner → Middle → Advanced 学習アーク）**

---

## 1) Topic + Level

### 🟢 Beginner
**トピック:** `docker run` / `docker ps` / `docker logs` / `docker exec` で1コンテナを安全に扱う

### 🟡 Middle
**トピック:** Docker Composeで「アプリ + DB」を連携して起動する
**前提条件:**
- Beginnerレベルのコマンド操作ができる
- `Dockerfile` の基本（`FROM`, `COPY`, `RUN`, `CMD`）を理解している

### 🔴 Advanced
**トピック:** 開発効率とセキュリティを意識したCompose設計（ヘルスチェック・最小権限・秘密情報の分離）
**前提条件:**
- MiddleレベルのCompose操作ができる
- 環境変数/ボリューム/ネットワークの基礎を理解している

---

## 2) なぜ実アプリ開発で重要か

- ローカル環境の「動く/動かない」をチームで揃えられる（再現性）
- DBやキャッシュを含む実運用に近い構成を素早く検証できる
- ログ確認や一時シェル接続で障害切り分けが高速になる
- Composeを正しく使うと、開発速度と安全性（設定ミス・秘密情報漏えい防止）を両立できる

---

## 3) Core Docker command explanations

- `docker run --name web -p 8080:80 nginx:alpine`  
  コンテナを起動。`-p` でホスト公開、`--name` で識別しやすくする。

- `docker ps` / `docker ps -a`  
  稼働中/停止済みを含むコンテナ一覧を確認。

- `docker logs -f web`  
  ログを追跡（トラブルシュートの基本）。

- `docker exec -it web sh`  
  稼働中コンテナへ入って調査。アプリ確認・設定確認に使う。

- `docker compose up -d` / `docker compose down`  
  複数サービスをまとめて起動/停止。

- `docker network ls` / `docker network inspect <network>`  
  サービス間通信の確認。Composeでは通常プロジェクト専用ネットワークが自動作成される。

---

## 4) 実アプリ開発での使い方（docs.docker.com ベストプラクティス準拠）

- **1プロセス1責務**を意識してサービス分離（app, db, redis など）
- **イメージは軽量化**（例: `alpine` 系、不要パッケージを減らす）
- **レイヤーキャッシュを活かすDockerfile順序**（依存インストールを先に）
- **秘密情報をイメージに焼き込まない**（`ENV`直書き・`COPY .env`を避ける）
- **`.dockerignore` を整備**して不要ファイル/秘密ファイルをビルドコンテキストから除外
- **ヘルスチェック**と`depends_on`条件で起動順依存を緩和
- **非rootユーザー実行**を検討して権限を最小化

---

## 5) 30-60分ミニラボ

### 目標
Node.jsアプリ + PostgreSQLをComposeで起動し、接続確認まで行う。

### 手順（45分想定）

1. 作業ディレクトリ作成
```bash
mkdir docker-mag-lab && cd docker-mag-lab
```

2. `compose.yaml` 作成
```yaml
services:
  app:
    image: node:22-alpine
    working_dir: /app
    volumes:
      - ./:/app
    command: sh -c "node server.js"
    ports:
      - "3000:3000"
    environment:
      - DB_HOST=db
      - DB_PORT=5432
      - DB_USER=appuser
      - DB_NAME=appdb
      # 学習用: 本番ではパスワードを直書きしない
      - DB_PASSWORD=example-password
    depends_on:
      db:
        condition: service_healthy

  db:
    image: postgres:16-alpine
    environment:
      - POSTGRES_USER=appuser
      - POSTGRES_PASSWORD=example-password
      - POSTGRES_DB=appdb
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U appuser -d appdb"]
      interval: 5s
      timeout: 3s
      retries: 10
    volumes:
      - pgdata:/var/lib/postgresql/data

volumes:
  pgdata:
```

3. `server.js` 作成（最低限の疎通確認）
```js
const http = require('http');
const port = 3000;

http.createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'text/plain; charset=utf-8' });
  res.end('Docker Compose app is running\n');
}).listen(port, () => {
  console.log(`Server running on port ${port}`);
});
```

4. 起動
```bash
docker compose up -d
```

5. 確認
```bash
docker compose ps
docker compose logs -f app
curl http://localhost:3000
```

6. 後片付け
```bash
docker compose down
```

> `down` は通常安全ですが、`-v` を付けると named volume（今回の `pgdata`）も削除され、DBデータが消えます。実務では実行前に必ず確認してください。

---

## 6) Command cheatsheet

```bash
# 基本
docker ps
docker ps -a
docker images
docker logs -f <container>
docker exec -it <container> sh

# Compose
docker compose up -d
docker compose ps
docker compose logs -f
docker compose down

# ネットワーク
docker network ls
docker network inspect <network>

# クリーンアップ（要注意）
docker rm -f <container>          # 強制停止+削除
docker rmi <image>                # イメージ削除
docker system prune               # 未使用リソース削除
docker system prune -a            # さらに広範囲（危険）
```

⚠️ **警告（破壊的操作）**  
`prune`, `rmi`, `rm -f` は復元できない削除を引き起こします。実行前に対象確認（`docker ps -a`, `docker images`, `docker volume ls`）を必ず行ってください。

---

## 7) よくあるミスと安全運用

- **ミス:** `.env` をそのままイメージへ `COPY` して秘密情報流出  
  **対策:** `.dockerignore` に `.env` を追加。秘密は実行時注入。

- **ミス:** `latest` タグ固定で再現不能  
  **対策:** バージョンタグを明示（例: `postgres:16-alpine`）。

- **ミス:** root実行前提のまま本番投入  
  **対策:** 可能な範囲で非root化、権限最小化。

- **ミス:** 不要なポート公開（`0.0.0.0`）  
  **対策:** 必要最小限だけ公開。開発時でも公開範囲を意識。

- **ミス:** `docker compose down -v` を不用意に実行  
  **対策:** ボリューム削除の影響を理解し、事前バックアップ。

---

## 8) 面接っぽい確認質問

**Q.** `docker compose up` と `docker compose up --build` の違いは？また、どんな場面で `--build` を使うべき？

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
- Multi-stage builds  
  https://docs.docker.com/build/building/multi-stage/
- Docker Scout（イメージ脆弱性の確認）  
  https://docs.docker.com/scout/

---

### 次回予告（学習アーク継続）
- Beginner: ボリューム基礎とデータ永続化
- Middle: 開発/本番でComposeファイルを分割運用
- Advanced: BuildKit + キャッシュ最適化 + セキュアなCI連携
