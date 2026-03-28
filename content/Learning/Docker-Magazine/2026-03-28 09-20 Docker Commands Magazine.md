---
tags: [docker, containers, devops, learning, daily]
---

# Daily Docker Commands Magazine — 2026-03-28
[[Home]]

#docker #containers #devops #learning #daily

## 今日の学習アーク（Beginner → Middle → Advanced）

---

## 1) Topic + Level

### Beginner
**トピック:** `docker run` / `docker ps` / `docker logs` で「コンテナを起動して観察する」

### Middle
**トピック:** `Dockerfile` と `docker build` / `docker exec` で「開発向けイメージを作る」

**前提条件（Prerequisites）:**
- Beginner の内容（コンテナ起動・停止・ログ確認）ができる
- Linux 基本コマンド（`cd`, `ls`, `cat`）を理解している

### Advanced
**トピック:** `docker compose` とマルチステージビルドで「本番を意識した構成を作る」

**前提条件（Prerequisites）:**
- Middle の内容（Dockerfile 作成・ビルド・exec）ができる
- アプリとDBの分離、環境変数の役割を理解している

---

## 2) なぜ実アプリ開発で重要か

- **環境差異の削減:** 開発者ごとの差分（OS/ライブラリ差）を抑えられる
- **オンボーディング高速化:** `docker compose up` で開発環境を再現しやすい
- **CI/CD との整合:** ローカルと同じイメージをパイプラインで再利用できる
- **運用の見通し向上:** ログ・ヘルスチェック・ネットワーク分離などを早期に設計できる

---

## 3) Core Docker command explanations

### Beginner コマンド
- `docker run -d --name web -p 8080:80 nginx:alpine`
  - `-d`: バックグラウンド実行
  - `--name`: コンテナ名付与
  - `-p 8080:80`: ホスト8080→コンテナ80へポート公開
- `docker ps`
  - 起動中コンテナ一覧を確認
- `docker logs -f web`
  - コンテナログを追跡表示
- `docker stop web && docker rm web`
  - 停止して削除（開発での基本クリーンアップ）

### Middle コマンド
- `docker build -t myapp:dev .`
  - 現在ディレクトリの Dockerfile からイメージ作成
- `docker run --rm -it -p 3000:3000 myapp:dev`
  - `--rm`: 終了時にコンテナ自動削除
  - `-it`: 対話シェル向け
- `docker exec -it <container> sh`
  - 稼働中コンテナに入って調査
- `docker inspect <container>`
  - 設定値（ネットワーク/マウント/環境変数など）確認

### Advanced コマンド
- `docker compose up -d --build`
  - 複数サービスをまとめてビルド・起動
- `docker compose logs -f app`
  - 特定サービスのログ確認
- `docker compose exec app sh`
  - サービスコンテナ内で作業
- `docker compose down`
  - 構成を停止・削除（ネットワーク等を含む）

> ⚠️ **破壊的コマンド注意**
> - `docker system prune`, `docker image prune -a`, `docker rm -f`, `docker rmi -f` は、不要と判断したリソース以外を消すリスクがあります。実行前に対象を必ず確認してください。

---

## 4) 実アプリ構築での使い方（docs.docker.com ベストプラクティス準拠）

- **小さく安全なベースイメージを選ぶ**（例: `alpine`, `distroless` 系）
- **マルチステージビルド**でビルド依存を本番イメージから除外
- **`.dockerignore` を整備**し、不要ファイル（`node_modules`, `.git` 等）を送らない
- **レイヤーキャッシュ最適化**（依存解決レイヤーを先に配置）
- **1コンテナ1責務**を基本に、連携は Compose/ネットワークで管理
- **シークレットをイメージに焼き込まない**
  - `ENV PASSWORD=...` を Dockerfile に書かない
  - `.env` や秘密情報管理（Docker secrets / 外部Secret Manager）を使用
- **最小権限**（可能なら non-root ユーザーで実行）

参考（公式）:
- Dockerfile best practices: https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Multi-stage builds: https://docs.docker.com/build/building/multi-stage/
- Compose overview: https://docs.docker.com/compose/
- Docker Engine security: https://docs.docker.com/engine/security/

---

## 5) 30-60分ミニラボ

### 目標
Node.js API + Redis を Compose で立ち上げ、ログ確認と安全な設定確認まで行う。

### 所要時間
45分目安

### 手順
1. **雛形作成（10分）**
   - `app.js`（簡易API）と `package.json` を作成
   - `.dockerignore` を作成

2. **Dockerfile作成（10分）**
   - マルチステージで `deps` と `runtime` を分離
   - `USER node` など非root実行を設定

3. **compose.yaml作成（10分）**
   - `app` と `redis` サービスを定義
   - `ports`, `depends_on`, `environment` を設定
   - 秘密情報はハードコードしない

4. **起動と検証（10分）**
   - `docker compose up -d --build`
   - `docker compose ps`
   - `docker compose logs -f app`

5. **トラブルシュート練習（5分）**
   - `docker compose exec app sh`
   - 環境変数・接続確認

### 完了条件
- APIにアクセスできる
- appログに正常起動が出る
- Dockerfileに秘密情報が含まれていない

---

## 6) Command cheatsheet

```bash
# 単体コンテナ
docker run -d --name web -p 8080:80 nginx:alpine
docker ps
docker logs -f web
docker stop web && docker rm web

# イメージ作成・調査
docker build -t myapp:dev .
docker run --rm -it -p 3000:3000 myapp:dev
docker exec -it <container> sh
docker inspect <container>

# Compose
docker compose up -d --build
docker compose ps
docker compose logs -f app
docker compose exec app sh
docker compose down
```

---

## 7) よくあるミス & 安全な運用

- **ミス:** Dockerfile に API キーを直書き
  - **対策:** 環境変数注入 + Secret管理。イメージに埋め込まない。
- **ミス:** `latest` タグ固定で再現性が崩れる
  - **対策:** バージョン固定タグを使う（例 `node:20-alpine`）
- **ミス:** 不要な一括削除を実行
  - **対策:** `docker ps -a`, `docker images`, `docker volume ls` で対象確認後に削除
- **ミス:** rootユーザーで実行し続ける
  - **対策:** `USER` 命令で最小権限運用
- **ミス:** ビルドコンテキスト肥大化
  - **対策:** `.dockerignore` を最初に整備

> ⚠️ 再掲（破壊的）
> `prune` / `rmi` / `rm -f` は実行前に必ず対象確認。CI環境・共有端末では特に注意。

---

## 8) 面接風の一問

**Q.** 「開発環境では動くのに本番コンテナで動かない」場合、Docker観点で最初にどこを確認しますか？

**A.（例）**
1. イメージタグ差分（同一イメージか）
2. 環境変数/Secrets 注入差分
3. ポート/ネットワーク設定差分
4. 実行ユーザー・権限差分
5. ログとヘルスチェック結果

---

## 9) 次の一歩（公式中心）

- Get Started: https://docs.docker.com/get-started/
- Dockerfile reference: https://docs.docker.com/reference/dockerfile/
- Build cache optimize: https://docs.docker.com/build/cache/optimize/
- Compose file reference: https://docs.docker.com/reference/compose-file/
- Volumes: https://docs.docker.com/engine/storage/volumes/
- Networking: https://docs.docker.com/engine/network/

---

### 明日の予告（次アーク）
「イメージ軽量化と脆弱性スキャン（Scout含む）」を Beginner→Middle→Advanced で進めます。
