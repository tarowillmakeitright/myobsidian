---
tags: [docker, containers, devops, learning, daily]
---

# Daily Docker Commands Magazine — 2026-05-01

[[Home]]

今日のテーマは **Beginner → Middle → Advanced** の学習アークで、実務に直結する Docker コマンド運用を段階的に身につける構成です。

---

## 1) Topic + Level

### Beginner
**トピック:** `docker run` / `docker ps` / `docker logs` で「まず動かして観察する」

### Middle（前提あり）
**トピック:** `Dockerfile` + `docker build` + `docker compose up` で開発環境を再現する

**前提知識:**
- Beginner の内容（コンテナ起動・停止・ログ確認）
- Linux 基本コマンド（`cd`, `ls`, `cat`）
- アプリの環境変数の意味をざっくり理解している

### Advanced（前提あり）
**トピック:** BuildKit / マルチステージビルド / 最小権限で本番品質に近づける

**前提知識:**
- Middle の内容（Dockerfile と Compose）
- イメージレイヤ・キャッシュの基本
- CI/CD でコンテナを使うイメージがある

---

## 2) なぜ実アプリ開発で重要か

- **ローカル差異を減らす:** 「自分のPCでは動く」を防ぐ。
- **オンボーディング高速化:** 新メンバーが `compose up` で環境起動できる。
- **デプロイ再現性:** 本番に近い実行単位（コンテナ）で検証できる。
- **セキュリティ改善:** ベースイメージ最小化、非root実行、秘密情報の分離で事故を減らす。

---

## 3) Core Docker command 解説

### Beginner コマンド
- `docker run -d --name web -p 8080:80 nginx:alpine`
  - `-d`: バックグラウンド実行
  - `--name`: 管理しやすい名前
  - `-p 8080:80`: ホスト8080 → コンテナ80
- `docker ps` / `docker ps -a`
  - 稼働中 / 全コンテナ確認
- `docker logs -f web`
  - `-f` で追尾しながらログ監視
- `docker stop web && docker rm web`
  - 停止してから削除（安全な基本フロー）

### Middle コマンド
- `docker build -t myapp:dev .`
  - カレントディレクトリの Dockerfile からビルド
- `docker compose up -d`
  - 複数サービス（app/db/cache 等）をまとめて起動
- `docker compose logs -f app`
  - サービス単位でログ確認
- `docker compose down`
  - ネットワーク等を含めて終了

### Advanced コマンド
- `DOCKER_BUILDKIT=1 docker build -t myapp:prod .`
  - BuildKit 有効化（高速化・高度機能）
- `docker buildx build --platform linux/amd64,linux/arm64 -t myorg/myapp:1.0 --push .`
  - マルチアーキ対応イメージ作成
- `docker image inspect myapp:prod`
  - メタデータ確認（ユーザー設定やレイヤ確認）

---

## 4) docs.docker.com ベストプラクティスに沿った実務利用

- **小さい安全なベースイメージを選ぶ**（例: `alpine`/distroless系、ただし互換性確認）
- **マルチステージビルドで成果物のみコピー**（ビルドツールを本番イメージに残さない）
- **`.dockerignore` を整備**（`.git`, `node_modules`, 秘密ファイルを除外）
- **`USER` で非root実行**
- **Secretsをイメージに焼き込まない**
  - `ENV API_KEY=...` を Dockerfile に書かない
  - `compose.yaml` に平文シークレットを直書きしない
- **ヘルスチェックや明示的なタグ運用**（`latest` 固定依存を避ける）

---

## 5) 30–60分ミニラボ

### ゴール
Node.js API + Redis を Compose で起動し、ログ確認と安全な後片付けまで行う。

### 手順（約45分）
1. プロジェクト作成（5分）
   - `mkdir docker-mag-lab && cd docker-mag-lab`
2. `app.js` 作成（10分）
   - `/` で "hello" を返す最小API
3. `Dockerfile` 作成（10分）
   - `node:20-alpine`
   - 依存インストール
   - `USER node` 指定
4. `compose.yaml` 作成（10分）
   - `app` と `redis` の2サービス
   - `ports`, `depends_on` を設定
5. 起動・確認（5分）
   - `docker compose up -d --build`
   - `docker compose ps`
   - `docker compose logs -f app`
6. テストと停止（5分）
   - `curl http://localhost:3000`
   - `docker compose down`

### 余力チャレンジ
- `.dockerignore` を追加しビルド時間差を比較
- `healthcheck` を追加して `docker ps` の状態を確認

---

## 6) Command Cheatsheet

```bash
# コンテナ実行/確認
docker run -d --name web -p 8080:80 nginx:alpine
docker ps
docker logs -f web
docker exec -it web sh

# イメージ/ビルド
docker build -t myapp:dev .
docker images
docker image inspect myapp:dev

# Compose
docker compose up -d --build
docker compose ps
docker compose logs -f app
docker compose down

# クリーンアップ（破壊的: 実行前に要確認）
# WARNING: 未使用リソースを削除
# docker system prune
# WARNING: 停止中コンテナ全削除
# docker container prune
# WARNING: 未使用イメージ削除
# docker image prune -a
```

---

## 7) よくあるミス & 安全な運用

### よくあるミス
- `latest` タグ前提で環境差分が出る
- `COPY . .` で不要/機密ファイルまで含める
- root実行のまま本番投入
- `docker system prune -a` を意味を理解せず実行

### Safe Practices
- バージョンタグ固定（例: `node:20.11-alpine`）
- `.dockerignore` を必ず用意
- 破壊的コマンド前に対象確認：
  - `docker ps -a`
  - `docker images`
  - `docker volume ls`
- Secrets は `.env` + 実行時注入、または Docker secrets を利用
- 共有PC/CIで `docker login` 情報の扱いを最小化

---

## 8) 面接っぽい一問

**Q.** `CMD` と `ENTRYPOINT` の違いを説明し、アプリコンテナでの使い分け例を挙げてください。

（考えるポイント: 実行コマンドの固定度、引数の上書き性、運用時の柔軟性）

---

## 9) 次のステップ（公式優先）

- Docker Get Started  
  https://docs.docker.com/get-started/
- Dockerfile best practices  
  https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Multi-stage builds  
  https://docs.docker.com/build/building/multi-stage/
- Compose overview  
  https://docs.docker.com/compose/
- BuildKit overview  
  https://docs.docker.com/build/buildkit/
- Docker Engine security  
  https://docs.docker.com/engine/security/

---

明日の予告（学習アーク継続）:
- Beginner: ボリュームの基礎
- Middle: ホットリロード開発
- Advanced: キャッシュ最適化と脆弱性スキャン導入
