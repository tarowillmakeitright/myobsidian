---
tags: [docker, containers, devops, learning, daily]
---

# 2026-04-15 Docker Commands Magazine
[[Home]]

**今日の学習アーク:** Beginner → Middle → Advanced  
**想定時間:** 各レベル 30〜60分（合計で段階的に実施）

---

## 1) Topic + Level

### 🟢 Beginner: `docker run` / `docker ps` / `docker logs` で「動かして観察する」

### 🟡 Middle: `docker build` / `docker exec` / `docker compose up` で「開発ループを回す」
**前提条件:**
- Beginner の内容（コンテナ起動・停止・ログ確認）ができる
- Linux 基本コマンド（`cd`, `ls`, `cat`）を使える

### 🔴 Advanced: マルチステージビルド + 非root実行 + ヘルスチェックで「本番運用に近づける」
**前提条件:**
- Middle の内容（Dockerfile ビルド・Compose 起動）ができる
- アプリの依存関係管理（npm/pip 等）の基本理解

---

## 2) なぜ重要か（実アプリ開発での意味）

- 開発環境の「動く/動かない」の差異を減らし、チーム全体の再現性を高める
- ローカルでも CI でも同じ手順を使えるため、バグ切り分けが速い
- Compose で DB/キャッシュ/API をまとめて起動でき、統合テストが現実的になる
- セキュアな Dockerfile（最小イメージ・非root・秘密情報の分離）は、そのまま本番品質につながる

---

## 3) コア Docker コマンド解説

### Beginner コマンド
- `docker run -d --name web -p 8080:80 nginx:alpine`
  - イメージからコンテナを起動。`-d` はバックグラウンド、`-p` はポート公開
- `docker ps`
  - 起動中コンテナ一覧
- `docker logs -f web`
  - ログを追跡（`Ctrl+C` で追跡終了）
- `docker stop web && docker rm web`
  - 停止して削除（検証後のクリーンアップ）

### Middle コマンド
- `docker build -t myapp:dev .`
  - Dockerfile からイメージ作成
- `docker exec -it myapp sh`
  - 稼働中コンテナに入って調査
- `docker compose up --build`
  - 複数サービスをまとめてビルド・起動
- `docker compose logs -f api`
  - 特定サービスログを追跡

### Advanced コマンド
- `docker build --target runner -t myapp:prod .`
  - マルチステージの最終実行ステージのみをビルド
- `docker inspect myapp | jq '.[0].Config.User'`
  - 実行ユーザー（非rootか）を確認
- `docker compose ps`
  - ヘルス状態含めサービス状態確認

---

## 4) アプリ開発での使い方（docs.docker.com ベストプラクティス準拠）

- **小さなベースイメージを選ぶ**（例: `alpine`, `distroless` など用途に応じて）
- **マルチステージビルド**でビルドツールと実行環境を分離
- **`.dockerignore` を整備**して不要ファイル送信を防止（速度・秘匿性に有効）
- **1コンテナ1責務**を意識（API と DB は分離し Compose で束ねる）
- **immutable なイメージ**を基本にし、設定は環境変数や secrets 側へ分離
- **秘密情報を image/compose に直書きしない**
  - NG: Dockerfile 内 `ENV API_KEY=...`
  - 推奨: Docker secrets / CI secrets / `.env` を適切管理（`.gitignore` 必須）
- **最小権限**
  - `USER` 指定で非root実行
  - 必要最小限のポート・権限だけ許可

参考（公式）:
- Docker Build best practices: https://docs.docker.com/build/building/best-practices/
- Compose file reference: https://docs.docker.com/reference/compose-file/
- Docker Engine security: https://docs.docker.com/engine/security/

---

## 5) 30〜60分ミニラボ

### ラボテーマ: 「Node API + Redis を Compose で起動し、ログとヘルスを確認」

**所要:** 45分目安

1. 作業ディレクトリ作成
```bash
mkdir docker-mag-lab && cd docker-mag-lab
```

2. `app.js` 作成（最小 API）
```js
const http = require('http');
const server = http.createServer((req, res) => {
  res.writeHead(200, {'Content-Type': 'text/plain'});
  res.end('hello docker lab\n');
});
server.listen(3000, () => console.log('listening on 3000'));
```

3. `package.json` 作成
```json
{
  "name": "docker-mag-lab",
  "version": "1.0.0",
  "main": "app.js",
  "scripts": {
    "start": "node app.js"
  }
}
```

4. `Dockerfile`（非root + 軽量）
```dockerfile
FROM node:22-alpine
WORKDIR /app
COPY package.json ./
COPY app.js ./
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser
EXPOSE 3000
CMD ["npm", "start"]
```

5. `compose.yaml` 作成
```yaml
services:
  api:
    build: .
    ports:
      - "3000:3000"
    healthcheck:
      test: ["CMD", "wget", "-qO-", "http://localhost:3000"]
      interval: 10s
      timeout: 3s
      retries: 3
  redis:
    image: redis:7-alpine
```

6. 起動・確認
```bash
docker compose up --build -d
docker compose ps
curl http://localhost:3000
docker compose logs -f api
```

7. 終了
```bash
docker compose down
```

> 注意: データを消すオプション（`-v`）は挙動を理解してから使用。

---

## 6) Command Cheatsheet

```bash
# 実行・確認
docker run -d --name web -p 8080:80 nginx:alpine
docker ps
docker logs -f web

# ビルド
docker build -t myapp:dev .

# コンテナ内調査
docker exec -it myapp sh

# Compose
docker compose up --build -d
docker compose ps
docker compose logs -f

docker compose down
```

---

## 7) よくあるミス & 安全な運用

- ミス: イメージを巨大化（`COPY . .` で不要物まで含む）
  - 対策: `.dockerignore` を必ず作る
- ミス: root 実行のまま本番投入
  - 対策: `USER` を指定、権限を最小化
- ミス: 秘密情報を Dockerfile / compose に直書き
  - 対策: secrets 管理に分離し、`.env` の Git 管理を禁止
- ミス: 不要な全削除コマンドを安易に実行
  - **警告:** 以下は破壊的。実行前に対象確認
    - `docker system prune`
    - `docker image prune -a`
    - `docker rmi ...`
    - `docker rm -f ...`
  - 対策: まず `docker ps -a` / `docker images` / `docker volume ls` で確認

---

## 8) 面接風 質問（1問）

「開発環境で Docker Compose を使うとき、`depends_on` だけでは不十分なケースがあるのはなぜですか？ヘルスチェックと合わせてどう設計しますか？」

---

## 9) 次の一歩（公式リソース中心）

- Get started: https://docs.docker.com/get-started/
- Build best practices: https://docs.docker.com/build/building/best-practices/
- Multi-stage builds: https://docs.docker.com/build/building/multi-stage/
- Compose getting started: https://docs.docker.com/compose/gettingstarted/
- Compose file reference: https://docs.docker.com/reference/compose-file/
- Engine security: https://docs.docker.com/engine/security/

---

**明日の予告（次アーク）:**
- Beginner: ボリューム基礎（永続化）
- Middle: 開発用 bind mount とホットリロード
- Advanced: BuildKit キャッシュ最適化 + SBOM/イメージスキャン導線
