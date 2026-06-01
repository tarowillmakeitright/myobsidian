---
tags: [docker, containers, devops, learning, daily]
---

# Daily Docker Commands Magazine — 2026-06-01
[[Home]]

> 学習アーク: **Beginner → Middle → Advanced**
> 今日のテーマは、開発現場での「安全で実践的な Docker 運用」を段階的に身につける構成です。

---

## 1) Topic + Level

### Beginner
**トピック:** `docker run` / `docker ps` / `docker logs` で「まず動かして観察する」

### Middle
**トピック:** `Dockerfile` と `docker build` で再現可能な開発環境を作る
**前提条件:**
- Beginner の内容（コンテナ起動・停止・ログ確認）ができる
- 基本的な Linux コマンド（`cd`, `ls`, `cat`）

### Advanced
**トピック:** Docker Compose + マルチステージビルド + セキュアな設定管理
**前提条件:**
- Middle の内容（Dockerfile 作成、イメージビルド）ができる
- Web アプリの構成（app + DB + 環境変数）の基礎理解

---

## 2) なぜ実アプリ開発で重要か

- **環境差分の削減:** 「自分のPCでは動く」を減らし、チームで同じ実行環境を共有できる。
- **オンボーディング高速化:** 新メンバーが Docker で即座に同じ開発環境を再現可能。
- **CI/CD との親和性:** ローカルで使う手順をそのまま自動テスト・デプロイに近づけられる。
- **障害解析の効率化:** ログ・プロセス・ポートをコンテナ単位で追跡しやすい。

---

## 3) Core Docker command explanations

### Beginner コアコマンド
- `docker run --name web -d -p 8080:80 nginx:alpine`
  - `--name`: コンテナ名を固定
  - `-d`: バックグラウンド起動
  - `-p 8080:80`: ホスト8080→コンテナ80へポート公開
- `docker ps` / `docker ps -a`
  - 稼働中 / 全コンテナの確認
- `docker logs -f web`
  - `-f` でログ追従
- `docker stop web` / `docker rm web`
  - 停止と削除（分離して行うのが理解しやすい）

### Middle コアコマンド
- `docker build -t myapp:dev .`
  - カレントディレクトリの `Dockerfile` からイメージ作成
- `docker images`
  - 作成済みイメージ確認
- `docker run --rm -p 3000:3000 myapp:dev`
  - `--rm` で終了時にコンテナ自動削除（開発時に便利）

### Advanced コアコマンド
- `docker compose up --build`
  - 複数サービスを依存関係込みで起動、必要なら再ビルド
- `docker compose logs -f`
  - サービス横断でログ追跡
- `docker compose exec app sh`
  - 稼働中 app コンテナへシェル接続
- `docker compose down`
  - ネットワーク含め停止（volume を消す `-v` は要注意）

---

## 4) 実アプリ構築での使い方（docs.docker.com ベストプラクティス準拠）

- **小さいベースイメージを選ぶ**（例: `alpine` / slim 系）
- **レイヤーキャッシュを意識**
  - 依存ファイルコピー → install → アプリコードコピーの順でビルド高速化
- **`.dockerignore` を必ず使う**
  - `node_modules`, `.git`, `*.log` などを除外してビルド文脈を最小化
- **1コンテナ1責務を意識**
  - app と DB は Compose で分離
- **機密情報をイメージに焼き込まない**
  - `ENV PASSWORD=...` を Dockerfile に直書きしない
  - secrets や環境変数注入を使う
- **不要な root 実行を避ける**
  - 可能なら非 root ユーザーで実行

参考（公式）:
- Dockerfile best practices: https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Build cache: https://docs.docker.com/build/cache/
- Compose overview: https://docs.docker.com/compose/

---

## 5) 30–60分ハンズオンミニラボ

### ゴール
Node.js の簡単な API を Docker 化し、Compose で app を起動する。

### 手順（目安45分）
1. **プロジェクト準備（10分）**
   - `app.js`（Hello API）と `package.json` を作成
2. **Dockerfile 作成（10分）**
   - `node:20-alpine` ベース
   - `WORKDIR /app`
   - `COPY package*.json ./` → `npm ci --only=production`
   - `COPY . .`
   - `EXPOSE 3000`
   - `CMD ["node", "app.js"]`
3. **ビルド & 単体起動（10分）**
   - `docker build -t hello-api:dev .`
   - `docker run --rm -p 3000:3000 hello-api:dev`
4. **Compose 化（10分）**
   - `compose.yaml` に `app` サービス定義
   - `docker compose up --build`
5. **確認 & 片付け（5分）**
   - `curl http://localhost:3000`
   - `docker compose down`

---

## 6) Command cheatsheet

```bash
# 起動
docker run --name sample -d -p 8080:80 nginx:alpine

# 状態確認
docker ps
docker ps -a
docker images

# ログ
docker logs -f sample

# 停止/削除
docker stop sample
docker rm sample

# ビルド
docker build -t myapp:dev .

# Compose
docker compose up --build
docker compose logs -f
docker compose exec app sh
docker compose down
```

---

## 7) よくあるミス & 安全な運用

- **ミス:** Dockerfile に API キーやパスワードを直書き
  - **対策:** secrets / 環境変数の外部注入。リポジトリに機密を置かない。
- **ミス:** `latest` タグ固定で予期せぬ更新
  - **対策:** バージョンタグを明示（例 `node:20.12-alpine`）
- **ミス:** 不要なファイルまで COPY
  - **対策:** `.dockerignore` を整備
- **ミス:** root 実行のまま本番投入
  - **対策:** 非 root ユーザー化を検討

### ⚠️ 破壊的クリーンアップコマンドの注意
以下は**データ・イメージを消す可能性**があります。実行前に対象確認。
- `docker system prune`
- `docker image prune -a`
- `docker rmi ...`
- `docker rm -f ...`
- `docker compose down -v`

安全策:
1. 先に `docker ps -a` / `docker images` / `docker volume ls` で確認
2. 可能なら `--filter` で対象を限定
3. 本番・共有環境では即実行しない（レビューを挟む）

---

## 8) 面接っぽい確認質問（1問）

**質問:**
「`COPY package*.json` を先に行ってから `npm ci` を実行し、その後でアプリ本体を `COPY` するのはなぜですか？」

**狙い:**
Docker のレイヤーキャッシュを理解し、ビルド時間最適化を説明できるか確認。

---

## 9) Next-step resources（公式優先）

- Get started: https://docs.docker.com/get-started/
- Dockerfile reference: https://docs.docker.com/reference/dockerfile/
- Build best practices: https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Compose file reference: https://docs.docker.com/reference/compose-file/
- Docker Engine security: https://docs.docker.com/engine/security/
- Manage secrets (Swarm): https://docs.docker.com/engine/swarm/secrets/

---

次号予告（学習アーク継続）:
- Beginner: ボリューム基礎
- Middle: 開発用ホットリロード構成
- Advanced: 本番向けイメージ最適化と脆弱性スキャン
