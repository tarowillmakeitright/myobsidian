# 2026-03-25 Docker Commands Magazine

Tags: #docker #containers #devops #learning #daily
Links: [[Home]]

---

## 今日の学習アーク（Beginner → Middle → Advanced）

> テーマ: **Dockerで「開発環境を再現可能にする」実践コマンド集**

---

## 1) Topic + Level

### Beginner（初級）
**Topic:** `docker run` / `docker ps` / `docker logs` で「まず動かして観察する」

### Middle（中級）
**Topic:** `docker build` / `docker exec` / `docker compose up` で「開発ワークフローを作る」
**Prerequisites:**
- Beginnerの内容（コンテナ起動・停止・ログ確認）ができる
- Dockerfileの基本命令（`FROM`, `COPY`, `RUN`, `CMD`）を見たことがある

### Advanced（上級）
**Topic:** マルチステージビルド + ヘルスチェック + セキュア運用（最小権限・秘密情報管理）
**Prerequisites:**
- Middleの内容（build/compose/exec）を使ってローカル開発ができる
- イメージレイヤーとキャッシュの概念を理解している

---

## 2) なぜ実アプリ開発で重要か

- **環境差分を減らす**: 「自分のPCでは動く」を減らし、チーム全員で同じ環境を再現できる。
- **オンボーディング高速化**: 新メンバーが `docker compose up` で短時間に開発開始できる。
- **CI/CDに接続しやすい**: ローカルとCIで同じDockerfileを使うと、ビルド再現性が上がる。
- **セキュリティ品質向上**: 最小イメージ、非root実行、秘密情報の外出しでリスク低減。

---

## 3) Core Docker command explanations

### 初級コマンド
- `docker run -d --name web -p 8080:80 nginx:alpine`
  - イメージからコンテナを起動。`-d` バックグラウンド、`-p` ポート公開。
- `docker ps` / `docker ps -a`
  - 稼働中 / 全コンテナを一覧。
- `docker logs -f web`
  - コンテナログを追尾表示（トラブルシュートの基本）。
- `docker stop web && docker rm web`
  - 停止して削除（明示的クリーンアップ）。

### 中級コマンド
- `docker build -t myapp:dev .`
  - Dockerfileからイメージを作成。`-t` でタグ付け。
- `docker exec -it myapp sh`
  - 実行中コンテナへ入って状態確認。
- `docker compose up -d`
  - 複数サービス（app/db等）をまとめて起動。
- `docker compose logs -f app`
  - compose管理下サービスのログ追尾。

### 上級コマンド
- `docker build --target runner -t myapp:prod .`
  - マルチステージの最終ステージだけを成果物化。
- `docker inspect myapp --format '{{json .State.Health}}'`
  - ヘルスチェック状態を確認。
- `docker compose config`
  - Compose設定の最終解決結果を検証（ミス防止）。

---

## 4) アプリ開発時のDocker活用（docs.docker.comベストプラクティス準拠）

- **小さく保つ**: 軽量ベースイメージ（例: alpine系）やマルチステージで最終イメージを縮小。
- **キャッシュを活かすDockerfile順序**: 依存関係インストールを先に、頻繁に変わるアプリコードを後に。
- **.dockerignoreを必ず使う**: 不要ファイル（`.git`, `node_modules`, 秘密ファイル）をビルドコンテキストに含めない。
- **1コンテナ1責務を意識**: app, db, cacheをComposeで分離。
- **Secretsをイメージに焼き込まない**: `ENV`直書きやDockerfileへの秘密埋め込みを避ける。環境変数/secret機構で注入。
- **非rootユーザーで実行**: 可能なら `USER` を指定し権限を最小化。

---

## 5) 30-60分ミニラボ

### ゴール
Node.js API + Redis を Composeで起動し、ログ確認・ヘルス確認・安全な片付けまで実施。

### 所要時間
45分目安

### 手順
1. **プロジェクト作成（5分）**
   - `mkdir docker-lab && cd docker-lab`
   - `app/` に最小API（`/health` を返す）を用意。

2. **Dockerfile作成（10分）**
   - マルチステージ（builder/runner）で作る。
   - `USER node` など非root実行を設定。

3. **compose.yaml作成（10分）**
   - `app` と `redis` の2サービス。
   - `depends_on` と `healthcheck` を追加。
   - 秘密情報は `.env` かローカル環境変数から読み込む（ファイルへ直書きしない）。

4. **起動・確認（10分）**
   - `docker compose up -d --build`
   - `docker compose ps`
   - `docker compose logs -f app`
   - `curl http://localhost:3000/health`

5. **デバッグ（5分）**
   - `docker exec -it <app_container> sh`
   - プロセス/環境変数を確認（秘密値は表示・共有しない）。

6. **安全な終了（5分）**
   - `docker compose down`
   - 不要なものだけ明示削除。

---

## 6) Command cheatsheet

```bash
# 起動・確認
docker run -d --name web -p 8080:80 nginx:alpine
docker ps
docker logs -f web

# ビルド
docker build -t myapp:dev .
docker image ls

# Compose
docker compose up -d --build
docker compose ps
docker compose logs -f app
docker compose down

# 調査
docker exec -it myapp sh
docker inspect myapp

# ⚠ 破壊的操作（実行前に対象確認）
docker rm -f <container>
docker rmi <image>
docker system prune
```

---

## 7) よくあるミス & 安全プラクティス

- **ミス:** `docker system prune` を何も確認せず実行
  - **安全策:** `docker ps -a`, `docker image ls`, `docker volume ls` で対象を確認してから実行。
  - **警告:** prune系は停止中コンテナ・未使用ネットワーク/イメージ等を削除。必要な資産を失う可能性あり。

- **ミス:** `docker rm -f` / `docker rmi` を雑に使う
  - **安全策:** 名前・タグを明示し、作業中プロジェクト外に影響しないか確認。

- **ミス:** 秘密情報をDockerfileやcomposeに直書き
  - **安全策:** `.env`（管理注意）やシークレット管理機能を使用。Gitへコミットしない。

- **ミス:** root実行のまま本番投入
  - **安全策:** `USER` 設定、不要パッケージ削減、最小権限原則を適用。

---

## 8) 面接風質問（1問）

**Q.** Dockerfileのレイヤーキャッシュを最大化してCI時間を短縮するには、命令順序をどう設計しますか？また、その設計がセキュリティに与える影響は？

---

## 9) 次の学習リソース（公式優先）

- Docker Docs Home
  - https://docs.docker.com/
- Get Started
  - https://docs.docker.com/get-started/
- Dockerfile best practices
  - https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Multi-stage builds
  - https://docs.docker.com/build/building/multi-stage/
- Compose overview
  - https://docs.docker.com/compose/
- Compose file reference
  - https://docs.docker.com/reference/compose-file/
- Docker Scout / image security
  - https://docs.docker.com/scout/

---

### 明日の予告（次アーク）
「イメージ最適化と脆弱性対応」
- Beginner: イメージサイズ削減の基本
- Middle: キャッシュ戦略と依存固定
- Advanced: SBOM/スキャン結果をCIに組み込む
