---
tags: [docker, containers, devops, learning, daily]
---

# 2026-04-24 09:20 Docker Commands Magazine
[[Home]]

## 今号テーマ
**「イメージ作成から本番運用までのDockerコマンド学習アーク」**

- **Beginner**: `docker run / ps / logs / exec` でコンテナの基本操作
- **Middle**: `docker build / compose up / compose logs` で開発環境を構築
- **Advanced**: `buildx / multi-stage build / scan相当のセキュリティ観点` で実践的な配布・最適化

---

## 1) Topic + Level

### Level 1 — Beginner
**トピック:** まずは「動かす・見る・入る」

扱う主コマンド:
- `docker run`
- `docker ps`
- `docker logs`
- `docker exec`
- `docker stop`

### Level 2 — Middle（前提条件あり）
**トピック:** Dockerfile + Composeでアプリ開発を回す

**前提条件:**
- Beginnerのコマンドを理解している
- Dockerfileの基本命令（`FROM`, `WORKDIR`, `COPY`, `RUN`, `CMD`）を読める

扱う主コマンド:
- `docker build`
- `docker compose up`
- `docker compose logs`
- `docker compose down`

### Level 3 — Advanced（前提条件あり）
**トピック:** 小さく安全なイメージを作り、再現性を高める

**前提条件:**
- Middleレベル（Dockerfile/Compose運用）
- Linuxファイル権限と環境変数の基礎

扱う主コマンド:
- `docker buildx build`
- `docker image inspect`
- `docker history`

---

## 2) なぜ実アプリ開発で重要か

- **環境差分を潰せる**: 「自分のPCでは動く」を減らせる
- **オンボーディングが速い**: 新規メンバーが `compose up` で即参加
- **CI/CDに接続しやすい**: Dockerfileがそのままビルド定義になる
- **セキュリティの共通基盤**: 最小イメージ、非root実行、秘密情報の分離ができる

---

## 3) Core Docker command explanations

### `docker run`
イメージからコンテナを起動する。
例:
```bash
docker run --name web -d -p 8080:80 nginx:alpine
```
- `-d`: バックグラウンド起動
- `-p 8080:80`: ホスト8080 → コンテナ80

### `docker ps`
起動中コンテナの確認。
```bash
docker ps
```

### `docker logs -f <container>`
ログの追跡。アプリの初期化失敗を最初に見る場所。

### `docker exec -it <container> sh`
コンテナ内部に入り、実行時状態を診断。

### `docker build -t <name:tag> .`
Dockerfileからイメージ作成。

### `docker compose up -d`
複数サービス（app/db/redis等）をまとめて起動。

### `docker compose down`
Composeで立てたリソースを停止・削除。

---

## 4) アプリ開発での使い方（docs.docker.comベストプラクティス準拠）

- **1プロジェクト1 Compose**: app + db + cache を定義し、チームで統一
- **マルチステージビルド**: ビルド用依存を最終イメージに残さない
- **`.dockerignore` を整備**: `.git`, `node_modules`, 秘密ファイルを送らない
- **イメージはタグ固定も併用**: `node:20-alpine` など明示して再現性向上
- **Secretsをイメージに焼き込まない**:
  - NG: `ENV API_KEY=...` をDockerfileに直書き
  - 推奨: 実行時注入（Composeの環境変数/secret管理）
- **非rootユーザーで実行**（可能な範囲で）

参考:
- Docker Docs (Best practices): https://docs.docker.com/build/building/best-practices/
- Docker Compose overview: https://docs.docker.com/compose/

---

## 5) 30-60分ハンズオン mini lab

### ゴール
Node.js API + Redis をComposeで起動し、ログ確認と簡単なトラブルシュートを行う。

### 手順（目安45分）

1. **作業ディレクトリ作成**（5分）
```bash
mkdir docker-mini-lab && cd docker-mini-lab
```

2. **`app.js` と `package.json` を用意**（10分）
- `express` で `/health` を返すだけのAPI

3. **Dockerfile作成**（10分）
- `node:20-alpine`
- `WORKDIR /app`
- `COPY package*.json ./` → `npm ci`
- `COPY . .`
- `CMD ["node", "app.js"]`

4. **compose.yaml作成**（10分）
- `app` と `redis` サービス
- `app` は `ports: ["3000:3000"]`
- `depends_on: [redis]`

5. **起動・確認**（10分）
```bash
docker compose up -d
docker compose ps
docker compose logs -f app
curl http://localhost:3000/health
```

6. **軽い障害対応演習**（任意）
- appコンテナ停止→再起動
```bash
docker compose stop app
docker compose start app
```
- ログから原因を読む習慣をつける

---

## 6) Command cheatsheet

```bash
# コンテナ起動
docker run -d --name web -p 8080:80 nginx:alpine

# 一覧とログ
docker ps
docker logs -f web

# コンテナ内シェル
docker exec -it web sh

# イメージビルド
docker build -t myapp:dev .

# Compose操作
docker compose up -d
docker compose ps
docker compose logs -f
docker compose down
```

---

## 7) よくあるミス & 安全な運用

### よくあるミス
- Dockerfileに秘密情報を直書き
- `latest` タグ依存で、突然挙動が変わる
- 不要ファイルをbuild contextに含めてビルド遅延
- root実行前提で権限トラブル

### 安全な運用
- `.dockerignore` を必ず設定
- 秘密情報は実行時注入（環境変数/secret管理）
- 破壊的コマンドは対象確認後に実行

⚠️ **破壊的コマンド注意**（実行前に必ず影響確認）:
- `docker system prune`
- `docker image prune -a`
- `docker rmi ...`
- `docker rm -f ...`

特に `-a` や `-f` は「今使っていないつもり」のリソースまで削除しやすい。チーム環境では事前共有推奨。

---

## 8) Interview-style question

**質問:**
「`docker run` と `docker compose up` は何が違い、開発チームではどちらをいつ使いますか？ また、再現性と運用保守の観点で説明してください。」

---

## 9) Next-step resources（公式中心）

- Docker Get Started: https://docs.docker.com/get-started/
- Dockerfile reference: https://docs.docker.com/reference/dockerfile/
- Build best practices: https://docs.docker.com/build/building/best-practices/
- Docker Compose docs: https://docs.docker.com/compose/
- Multi-stage builds: https://docs.docker.com/build/building/multi-stage/
- Docker Engine security: https://docs.docker.com/engine/security/

---

### 明日の予告（次アーク）
Beginner→Middle→Advanced を継続し、次回は **ボリューム/ネットワーク/ヘルスチェック** を中心に実運用寄りのトラブルシュートを扱います。
