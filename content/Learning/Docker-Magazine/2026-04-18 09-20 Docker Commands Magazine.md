---
tags: [docker, containers, devops, learning, daily]
---

# 2026-04-18 Docker Commands Magazine
[[Home]]

#docker #containers #devops #learning #daily

## 学習アーク 1

# 1) Topic + Level

### Beginner
**トピック:** `docker run` / `docker ps` / `docker logs` で「まず動かして観察する」

### Middle
**トピック:** `Dockerfile` と `docker build` / `docker compose up` で開発環境を再現する
**前提知識:**
- Beginner の内容（コンテナ起動・停止・ログ確認）
- Linux 基本コマンド（`cd`, `ls`, `cat`）
- アプリ実行の基本（例: Node/Python の `npm start` / `python app.py`）

### Advanced
**トピック:** マルチステージビルド + キャッシュ最適化 + セキュアな運用（rootless/least privilege）
**前提知識:**
- Middle の内容（Dockerfile と Compose）
- イメージレイヤーの概念
- CI/CD の基礎（ビルド→テスト→デプロイの流れ）

---

# 2) なぜ実アプリ開発で重要か

- **環境差分を潰せる**: 「自分のPCでは動く問題」を減らせる
- **オンボーディングが速い**: 新メンバーが `docker compose up` ですぐ開発開始
- **再現性が高い**: 同じ Dockerfile から同じ実行環境を作れる
- **運用までつながる**: 開発環境で使うコンテナ知識が、そのまま本番運用やCIで効く

---

# 3) Core Docker command explanations

## Beginner コマンド
- `docker run -d --name web nginx:alpine`
  - イメージからコンテナを起動（`-d` はバックグラウンド）
- `docker ps`
  - 起動中コンテナ一覧
- `docker logs -f web`
  - コンテナログを追跡
- `docker exec -it web sh`
  - コンテナ内シェルに入る
- `docker stop web && docker rm web`
  - 停止・削除

## Middle コマンド
- `docker build -t myapp:dev .`
  - Dockerfile からイメージ作成
- `docker compose up -d`
  - 複数サービス（app/dbなど）を起動
- `docker compose ps`
  - Compose 管理下サービスの状態確認
- `docker compose logs -f app`
  - 特定サービスのログ監視
- `docker compose down`
  - 環境停止（ネットワーク等を片付け）

## Advanced コマンド
- `docker build --target builder -t myapp:builder .`
  - マルチステージの途中ターゲットを検証
- `docker image inspect myapp:prod`
  - イメージ設定・メタ情報確認
- `docker history myapp:prod`
  - レイヤー履歴確認（肥大化ポイント把握）
- `docker scout quickview myapp:prod`（利用可能環境なら）
  - 依存パッケージの脆弱性確認

---

# 4) アプリ開発中での Docker 活用（docs.docker.com ベストプラクティス準拠）

- **小さいベースイメージを選ぶ**（例: `alpine`, `slim`）
- **マルチステージビルド**でビルドツールを最終イメージに残さない
- **`.dockerignore` を整備**して不要ファイル（`.git`, `node_modules`, secrets）を送らない
- **レイヤーキャッシュを活かす順序**で Dockerfile を書く
  - 依存定義ファイルを先にコピー→依存インストール→アプリ本体コピー
- **1コンテナ1責務を基本**にし、連携は Compose で管理
- **Secrets をイメージに焼かない**
  - `ENV` 直書きや `COPY .env` を避ける
  - 開発は `.env` / Compose secrets、本番はシークレット管理基盤を利用
- **非rootユーザーで実行**（可能な限り）

---

# 5) 30-60分ハンズオンミニラボ

## 目標
Node.js の簡易APIをコンテナ化し、Compose で起動。ログ確認と安全な設定まで行う。

## 手順（約45分）

1. **プロジェクト作成（10分）**
   - `app.js`（Hello API）
   - `package.json`

2. **Dockerfile 作成（10分）**
   - `node:20-slim` ベース
   - `WORKDIR /app`
   - `COPY package*.json ./` → `npm ci --only=production`
   - `COPY . .`
   - `USER node`
   - `CMD ["node", "app.js"]`

3. **.dockerignore 作成（5分）**
   - `node_modules`
   - `.git`
   - `.env`

4. **ビルド＆起動（10分）**
   - `docker build -t hello-api:dev .`
   - `docker run --rm -p 3000:3000 --name hello-api hello-api:dev`

5. **Compose 化（10分）**
   - `compose.yaml` を作成して `docker compose up -d`
   - `docker compose logs -f`

## チェックポイント
- `curl http://localhost:3000` で応答が返る
- コンテナが root ではなく node ユーザーで動いている
- `.env` をイメージに含めていない

---

# 6) Command cheatsheet

- 状態確認: `docker ps`, `docker compose ps`
- ログ確認: `docker logs -f <container>`, `docker compose logs -f <service>`
- コンテナへ入る: `docker exec -it <container> sh`
- ビルド: `docker build -t <name>:<tag> .`
- 起動/停止（単体）: `docker run ...`, `docker stop <name>`
- 起動/停止（Compose）: `docker compose up -d`, `docker compose down`
- イメージ確認: `docker images`, `docker image inspect <image>`

⚠ **破壊的操作に注意**
- `docker system prune`, `docker image prune -a`, `docker rmi`, `docker rm -f` は削除系。
- 実行前に `docker ps -a` / `docker images` で対象を必ず確認。
- 共有環境ではレビュー・承認後に実行する。

---

# 7) よくあるミスと安全策

## よくあるミス
- `COPY . .` で `.env` や秘密鍵を取り込む
- `latest` タグ固定で再現性が落ちる
- root 実行のまま本番運用
- 不要な `apt` キャッシュを残してイメージ肥大化
- `prune` を無確認で実行して必要リソースを消す

## 安全策
- `.dockerignore` を最初に作る
- イメージタグを明示（例: `myapp:1.4.2`）
- `USER` で非root化
- 削除前に一覧確認 + バックアップ
- シークレットは環境変数管理/secret manager へ（**イメージに含めない**）

---

# 8) Interview-style question

**質問:**
「Dockerfile のレイヤーキャッシュを効率化するために、`COPY package*.json` を先に置く理由を説明してください。さらに、この設計がCI時間やセキュリティにどう影響するかも述べてください。」

---

# 9) Next-step resources（公式優先）

- Docker Get Started:
  https://docs.docker.com/get-started/
- Dockerfile best practices:
  https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Multi-stage builds:
  https://docs.docker.com/build/building/multi-stage/
- Docker Compose overview:
  https://docs.docker.com/compose/
- Compose file reference:
  https://docs.docker.com/compose/compose-file/
- Docker Engine security:
  https://docs.docker.com/engine/security/
- Build cache:
  https://docs.docker.com/build/cache/

---

次号予告（学習アーク継続）: Beginner「ボリューム」→ Middle「開発用ホットリロード構成」→ Advanced「BuildKit + CI最適化」
