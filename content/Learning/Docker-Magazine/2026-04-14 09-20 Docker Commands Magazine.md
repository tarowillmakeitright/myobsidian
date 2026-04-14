---
tags: [docker, containers, devops, learning, daily]
---

# Docker Commands Magazine — 2026-04-14 09:20
[[Home]]

#docker #containers #devops #learning #daily

今日の学習アークは **Beginner → Middle → Advanced** の3段階です。
テーマは実務で最重要の「**Dockerイメージ作成と安全な運用フロー**」。

---

## 1) Topic + Level

### 🟢 Beginner
**トピック:** `docker run` / `docker ps` / `docker logs` で「コンテナを動かして観察する」

### 🟡 Middle
**トピック:** Dockerfileの最適化（レイヤー、キャッシュ、`.dockerignore`、マルチステージ）
**前提知識:** 
- Beginnerのコマンド操作
- Linux基本コマンド（`ls`, `cat`, `curl`）
- アプリ実行の流れ（例: Node/PythonでWeb起動）

### 🔴 Advanced
**トピック:** Composeで開発環境を安全に構成（app + db + volume + healthcheck）
**前提知識:**
- MiddleのDockerfile最適化
- 環境変数と`.env`の基本
- DB接続（ホスト名/ポート）の理解

---

## 2) なぜ重要か（実アプリ開発）

- ローカル環境差分（OS/ライブラリ差）での「自分のPCでは動く」問題を減らせる
- 開発・CI・本番で同じイメージを使い、再現性を高められる
- Composeで依存サービス（DB/Redis等）をまとめて管理でき、オンボーディングが速くなる
- セキュアなイメージ作成（最小化・秘密情報の分離）は本番事故を防ぐ

---

## 3) Core Docker command explanations

### Beginnerコマンド
- `docker run -d --name web -p 8080:80 nginx:alpine`
  - `-d`: バックグラウンド起動
  - `--name`: コンテナ名
  - `-p 8080:80`: ホスト8080 → コンテナ80
- `docker ps` / `docker ps -a`
  - 稼働中 / 全コンテナ一覧
- `docker logs -f web`
  - コンテナログを追跡
- `docker exec -it web sh`
  - 稼働中コンテナにシェル接続

### Middleコマンド
- `docker build -t myapp:dev .`
  - 現在ディレクトリをビルドコンテキストにしてイメージ化
- `docker image ls`
  - ローカルイメージ一覧
- `docker history myapp:dev`
  - レイヤー構造を確認し、肥大化ポイントを特定

### Advancedコマンド
- `docker compose up -d --build`
  - Compose定義に従い、必要ならビルドして起動
- `docker compose ps`
  - サービス状態確認
- `docker compose logs -f app`
  - 特定サービスのログ追跡
- `docker compose down`
  - 停止・ネットワーク削除（volumeは残る）

---

## 4) 実装時のDocker活用（docs.docker.comベストプラクティス準拠）

- **小さいベースイメージ**を選ぶ（例: `alpine`や公式slim系）
- **マルチステージビルド**でビルド用依存を最終イメージに残さない
- **`.dockerignore`を必ず用意**し、不要ファイル（`.git`, `node_modules`, `*.log`）を除外
- **1コンテナ1責務**を意識（app/db/proxyを分離）
- **秘密情報をイメージに焼き込まない**
  - NG: Dockerfileに `ENV API_KEY=...`
  - OK: 実行時環境変数・secret管理を使う
- **root以外のユーザーで実行**を検討
- **ヘルスチェック**を定義して運用監視しやすくする

---

## 5) 30-60分ミニラボ（45分想定）

### ゴール
最小WebアプリをDockerfile化し、Composeでapp+dbを起動。ログとヘルス確認まで行う。

### 手順
1. **(10分) Beginner復習**
   - `nginx:alpine` を `docker run` で起動
   - `docker ps`, `docker logs`, `docker exec` で観察

2. **(15分) Middle実践**
   - サンプルアプリにDockerfile作成
   - `.dockerignore`追加
   - `docker build -t myapp:dev .`
   - `docker history myapp:dev`でサイズ確認

3. **(20分) Advanced実践**
   - `compose.yaml` に `app`, `db`, `volumes` を定義
   - `docker compose up -d --build`
   - `docker compose ps` / `docker compose logs -f app`
   - appがdbへ接続できることを確認

### 余力課題
- appコンテナをnon-root実行に変更
- healthcheck追加
- イメージサイズ比較（変更前/後）

---

## 6) Command cheatsheet

```bash
# コンテナ起動/確認
docker run -d --name web -p 8080:80 nginx:alpine
docker ps
docker logs -f web
docker exec -it web sh

# ビルド/イメージ確認
docker build -t myapp:dev .
docker image ls
docker history myapp:dev

# Compose
docker compose up -d --build
docker compose ps
docker compose logs -f app
docker compose down
```

⚠️ **破壊的コマンド注意（実行前に対象確認）**

```bash
# 危険: 不要リソースを一括削除（意図しないデータ消失に注意）
docker system prune

# 危険: 未使用イメージ削除
docker image prune -a

# 危険: コンテナ強制削除
docker rm -f <container>

# 危険: イメージ強制削除
docker rmi -f <image>
```

実行前に `docker ps -a`, `docker image ls`, `docker volume ls` で対象を確認すること。

---

## 7) よくあるミス & 安全運用

- **ミス:** `.env`や鍵ファイルをイメージにCOPY
  - **対策:** `.dockerignore`で除外、実行時注入へ変更
- **ミス:** 開発便利のためroot実行を本番にも持ち込む
  - **対策:** 本番用Dockerfileで非rootユーザー
- **ミス:** `latest`タグ固定運用
  - **対策:** バージョンタグを明示し追跡可能に
- **ミス:** `prune`を無確認で実行
  - **対策:** 事前一覧確認 + 必要ならバックアップ
- **ミス:** Composeに平文シークレット直書き
  - **対策:** secret管理、環境別設定分離

---

## 8) 面接風質問（1問）

**質問:**
「Dockerfileのレイヤーキャッシュを活かしてビルド時間を短縮するには、`COPY` と `RUN` の順序をどう設計しますか？また、その設計がセキュリティにどう影響しますか？」

---

## 9) Next-step resources（公式優先）

- Docker Docs Home: https://docs.docker.com/
- Get Started: https://docs.docker.com/get-started/
- Dockerfile best practices: https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Multi-stage builds: https://docs.docker.com/build/building/multi-stage/
- Compose overview: https://docs.docker.com/compose/
- Compose file reference: https://docs.docker.com/reference/compose-file/
- Docker Engine security: https://docs.docker.com/engine/security/
- Build cache: https://docs.docker.com/build/cache/

---

明日の予告（次アーク候補）:
**「ネットワーク設計（bridge/host/none）とサービス間通信のデバッグ」**