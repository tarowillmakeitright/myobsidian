---
tags: [docker, containers, devops, learning, daily]
---

# 2026-04-08 Docker Commands Magazine

[[Home]]

## 今日の学習アーク（Beginner → Middle → Advanced）
テーマ: **開発で毎日使う Docker 実践コマンド（ビルド・起動・確認・後片付け）**

---

## 1) Topic + Level

### Beginner（初級）
**トピック:** `docker build` / `docker run` / `docker ps` / `docker logs` の基本ループ

### Middle（中級）
**トピック:** `docker compose` で複数コンテナ開発（App + DB）
**前提知識:**
- Beginner のコマンドを理解している
- Dockerfile の基本（`FROM`, `COPY`, `RUN`, `CMD`）を読める

### Advanced（上級）
**トピック:** BuildKit と multi-stage build で安全・高速なイメージ運用
**前提知識:**
- Middle の compose 運用ができる
- レイヤーキャッシュ、イメージタグ、`.dockerignore` の意義を説明できる

---

## 2) なぜ重要か（実アプリ開発での意味）

- ローカル環境差分を減らし、**「自分のPCでは動く問題」**を減らせる
- 開発→テスト→デプロイで同一イメージを使いやすくなり、**再現性**が上がる
- compose で依存サービス（DB/Redis等）をコード化し、**チームオンボーディング**が速くなる
- multi-stage + 最小イメージで、**ビルド時間・脆弱性面積・配布サイズ**を改善できる

---

## 3) Core Docker command explanations

### 基本コマンド（初級）
- `docker build -t myapp:dev .`
  - カレントディレクトリの Dockerfile からイメージ作成
- `docker run --name myapp -p 8080:8080 myapp:dev`
  - コンテナ起動、ホスト8080→コンテナ8080を公開
- `docker ps` / `docker ps -a`
  - 起動中 / 全コンテナ一覧
- `docker logs -f myapp`
  - ログ追跡（`-f` で追尾）
- `docker exec -it myapp sh`
  - 起動中コンテナに入って確認（本番では監査方針に従う）

### compose コマンド（中級）
- `docker compose up -d`
  - 複数サービスをバックグラウンド起動
- `docker compose ps`
  - サービス状態確認
- `docker compose logs -f app`
  - appサービスのログ追跡
- `docker compose down`
  - 停止・ネットワーク削除（volume削除は明示しない限り維持）

### ビルド最適化コマンド（上級）
- `DOCKER_BUILDKIT=1 docker build -t myapp:bk .`
  - BuildKit を有効化
- `docker image ls`
  - イメージサイズやタグ確認
- `docker history myapp:bk`
  - レイヤー構成確認（秘密情報混入チェックにも有用）

---

## 4) 実アプリ開発での使い方（docs.docker.com ベストプラクティス寄せ）

- **小さいベースイメージ**を選ぶ（必要最小限）
- **multi-stage build** で build 時依存と runtime を分離
- `.dockerignore` を整備し、不要ファイル混入を防ぐ
- **1コンテナ1責務**を基本に、連携は compose で定義
- 設定は環境変数で注入し、**秘密情報をイメージに焼き込まない**
- `latest` 固定運用を避け、意味のあるタグ（例: `1.4.2`, `2026-04-08`）を使う

> 安全注意: `ENV SECRET=...` や Dockerfile への直書き、compose への平文埋め込みは避ける。シークレットは環境管理・シークレット管理機構で扱う。

---

## 5) 30-60分ミニラボ（目安45分）

### ゴール
Node.js API + PostgreSQL を compose で起動し、ログ確認と安全な後片付けまで行う。

### 手順
1. **10分: 最小 API を用意**
   - `Dockerfile` を作成し、`docker build -t docker-mag-api:dev .`
2. **10分: 単体コンテナ実行**
   - `docker run --rm -p 3000:3000 docker-mag-api:dev`
   - `curl http://localhost:3000/health` で確認
3. **15分: compose 化（app + db）**
   - `compose.yaml` 作成（app, db, volume）
   - `docker compose up -d`
   - `docker compose logs -f app`
4. **10分: 改善と確認**
   - `.dockerignore` 追加
   - multi-stage 化（builder/runtime分離）
   - `docker image ls` でサイズ比較

### 完了条件
- `docker compose ps` で app/db が healthy または起動状態
- ヘルスチェック API が応答
- 変更後イメージサイズが削減または構成改善を説明できる

---

## 6) Command cheatsheet

```bash
# Build & Run
docker build -t myapp:dev .
docker run --name myapp --rm -p 8080:8080 myapp:dev

# Inspect
docker ps
docker logs -f myapp
docker exec -it myapp sh

# Compose
docker compose up -d
docker compose ps
docker compose logs -f app
docker compose down

# Images
docker image ls
docker history myapp:dev
```

---

## 7) よくあるミスと安全策

- ミス: `COPY . .` で秘密情報や巨大ファイルまで混入
  - 安全策: `.dockerignore` を必ず整備
- ミス: `latest` 依存で再現不能
  - 安全策: バージョンタグ固定
- ミス: 開発中の勢いで破壊的クリーンアップ
  - 安全策: 対象確認してから実行

⚠️ **破壊的コマンド注意（要確認）**
- `docker system prune -a`
- `docker image rm -f <image>`
- `docker rm -f <container>`

実行前に `docker ps -a`, `docker image ls`, `docker volume ls` で対象を確認し、チーム共有環境では影響範囲を明示すること。

---

## 8) 面接っぽい質問（1問）

**質問:**
「開発用 Dockerfile を本番向けに改善するとき、multi-stage build と `.dockerignore` はそれぞれ何を防ぎ、どの指標（セキュリティ・速度・サイズ・再現性）に効きますか？」

---

## 9) 次の一歩（公式ドキュメント中心）

- Docker Docs: Overview
  - https://docs.docker.com/get-started/docker-overview/
- Build best practices
  - https://docs.docker.com/build/building/best-practices/
- Multi-stage builds
  - https://docs.docker.com/build/building/multi-stage/
- Docker Compose getting started
  - https://docs.docker.com/compose/gettingstarted/
- Docker Engine security
  - https://docs.docker.com/engine/security/
- Manage sensitive data (secrets)
  - https://docs.docker.com/engine/swarm/secrets/

---

次号予告: **ネットワークとボリュームの設計（Beginner→Advanced）**
