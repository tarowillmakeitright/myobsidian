# Docker Commands Magazine — 2026-03-30
Tags: #docker #containers #devops #learning #daily  
Links: [[Home]]

---

## 今回の学習アーク（Beginner → Middle → Advanced）
- **Beginner:** `docker run` / `docker ps` / `docker logs` でローカル実行を安定化
- **Middle:** `docker compose` で複数サービス（Web + DB）を開発運用
- **Advanced:** マルチステージビルド + BuildKit で安全・軽量・再現性の高いイメージ作成

> セキュリティ前提: **シークレットを Dockerfile/compose に直書きしない**。`.env` の扱いと Secrets 管理を徹底。

---

## 1) Topic + Level

### Beginner（初級）
**Topic:** コンテナの起動・確認・停止の基本コマンド

### Middle（中級）
**Topic:** Docker Compose によるアプリ + DB のローカル開発環境
**Prerequisites:**
- `docker run`, `docker ps`, `docker logs` を使ったことがある
- ポート公開（`-p`）とボリューム（`-v`）の概念を理解している

### Advanced（上級）
**Topic:** マルチステージビルド / BuildKit / 最小権限での本番向けイメージ設計
**Prerequisites:**
- Dockerfile の基本命令（`FROM`, `COPY`, `RUN`, `CMD`）
- Compose でサービス起動経験
- Linux ユーザー・権限の基礎知識

---

## 2) なぜ実務で重要か
- **Beginner:** 開発中の「動かない」を最短で切り分けできる（ログ確認、状態確認）。
- **Middle:** チームで同一の開発環境を再現しやすくなり、オンボーディングが速い。
- **Advanced:** CI/CD でのビルド時間短縮、脆弱性面積の削減、供給網リスク低減につながる。

---

## 3) コア Docker コマンド解説

### Beginner 主要コマンド
- `docker run --name web -p 8080:80 nginx:alpine`
  - イメージからコンテナ起動、名前付与、ポート公開
- `docker ps` / `docker ps -a`
  - 稼働中 / 全コンテナ一覧
- `docker logs -f web`
  - ログ追跡
- `docker stop web && docker rm web`
  - 停止と削除（安全に段階実行）

### Middle 主要コマンド
- `docker compose up -d`
  - 複数サービスをバックグラウンド起動
- `docker compose ps`
  - サービス状態確認
- `docker compose logs -f app`
  - 特定サービスのログ追跡
- `docker compose down`
  - 停止・ネットワーク削除（通常運用）

### Advanced 主要コマンド
- `docker build -t sample-app:prod .`
  - Dockerfile からイメージ作成
- `docker buildx build --platform linux/amd64,linux/arm64 -t sample-app:multi --push .`
  - マルチアーキ対応（レジストリ push 前提）
- `docker image inspect sample-app:prod`
  - メタデータ確認（ユーザー、レイヤー等）
- `docker scout quickview sample-app:prod`（環境にあれば）
  - 脆弱性の初期確認

---

## 4) アプリ開発での使い方（Docker公式ベストプラクティス準拠）
- **小さく保つ:** 軽量ベースイメージを検討（例: alpine/slim。ただし互換性確認）。
- **再現性:** `package-lock.json` などロックファイルを先にコピーし、レイヤーキャッシュ最適化。
- **マルチステージ:** build用とruntime用を分離し、本番イメージを最小化。
- **最小権限:** `USER` を指定し root 実行を避ける。
- **秘密情報管理:** 
  - Dockerfile に `ENV PASSWORD=...` のような埋め込み禁止
  - Compose で平文直書き回避、必要なら secrets/外部シークレット管理を利用
- **クリーンアップ運用:** 開発端末での不用意な `prune` 常用を避ける（後述の警告参照）。

---

## 5) 30〜60分ハンズオンミニラボ

### ゴール
Node.js API + PostgreSQL を Compose で起動し、ログ確認と再起動まで体験。

### 手順（約45分）
1. **作業ディレクトリ作成**（5分）
   - `mkdir docker-lab && cd docker-lab`
2. **compose.yml 作成**（10分）
   - `app`（Node）と `db`（Postgres）2サービス
3. **起動**（5分）
   - `docker compose up -d`
4. **状態・ログ確認**（10分）
   - `docker compose ps`
   - `docker compose logs -f app`
5. **障害注入ミニ演習**（10分）
   - DB接続文字列を一時的に誤設定 → ログで原因特定 → 修正
6. **停止・後片付け**（5分）
   - `docker compose down`

### 追加チャレンジ（+15分）
- Dockerfile をマルチステージ化し、`docker image ls` でサイズ比較

---

## 6) コマンドチートシート

```bash
# 起動・確認
docker run --name web -p 8080:80 nginx:alpine
docker ps
docker logs -f web

# 停止・削除（個別）
docker stop web
docker rm web

# Compose
docker compose up -d
docker compose ps
docker compose logs -f app
docker compose down

# ビルド
docker build -t myapp:dev .
docker image ls

# システム情報
docker system df
```

---

## 7) よくあるミス & 安全運用
- **ミス:** `latest` タグ固定運用 → 予期せぬ更新
  - **対策:** バージョンタグを明示
- **ミス:** コンテナ内を root で実行
  - **対策:** Dockerfile で `USER` 指定
- **ミス:** `.env` や秘密鍵をイメージに COPY
  - **対策:** `.dockerignore` 整備、秘密情報は外部注入
- **ミス:** 破壊的クリーンアップを無確認実行
  - **対策（重要）:** 以下は実行前に影響確認
    - `docker system prune -a`
    - `docker image prune -a`
    - `docker rm -f <container>` / `docker rmi -f <image>`
  - **警告:** 未使用と思っていたデータ/イメージを失う可能性あり

---

## 8) 面接風質問（1問）
**質問:** 「Dockerfile のレイヤーキャッシュを効かせるため、Node.js アプリでは `COPY` と `RUN npm ci` の順序をどう設計しますか？またその理由は？」

---

## 9) 次の一歩（公式ドキュメント優先）
- Docker 公式 Getting Started: https://docs.docker.com/get-started/
- Dockerfile ベストプラクティス: https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Compose overview: https://docs.docker.com/compose/
- Multi-stage builds: https://docs.docker.com/build/building/multi-stage/
- BuildKit: https://docs.docker.com/build/buildkit/
- Docker secrets（概念理解）: https://docs.docker.com/engine/swarm/secrets/

---

明日予告: **「コンテナの永続化とバックアップ設計（Volume/Bind Mount）」**（Beginner→Advanced で継続）
