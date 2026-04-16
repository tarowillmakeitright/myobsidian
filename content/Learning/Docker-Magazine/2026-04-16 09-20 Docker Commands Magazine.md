---
tags: [docker, containers, devops, learning, daily]
---

# Docker Commands Magazine — 2026-04-16 (09:20)
[[Home]]

#docker #containers #devops #learning #daily

今日の学習アークは **Beginner → Middle → Advanced** の3段階です。実務で「安全に・速く・再現可能に」開発するための流れで構成しています。

---

## 1) Topic + Level

### Beginner: `docker run` と `docker exec` で開発コンテナを使う

### Middle: `docker compose up` で Web + DB のローカル開発環境を構築する
**前提条件:**
- `docker run`, `docker ps`, `docker logs` の基本操作ができる
- イメージ/コンテナ/ボリュームの違いをざっくり説明できる

### Advanced: マルチステージビルド + BuildKit キャッシュで本番向け最適化
**前提条件:**
- Dockerfile の基本命令 (`FROM`, `COPY`, `RUN`, `CMD`) を理解
- compose を使った複数サービス起動経験がある

---

## 2) Why it matters（なぜ実アプリ開発で重要か）

- **環境差分バグを減らせる**: 「自分のPCでは動く」を減らし、チーム全員で同じ実行環境を共有できる
- **立ち上げが速い**: 新メンバーでも `compose up` で開発環境を短時間で再現
- **CI/CD に直結**: ローカルと同じビルド手順を CI に持ち込みやすい
- **セキュリティ強化**: 最小イメージ・非root実行・秘密情報の分離が実施しやすい

---

## 3) Core Docker command explanations（コマンド解説）

- `docker pull <image>`: レジストリからイメージ取得
- `docker run [options] <image>`: コンテナ起動
  - `-d`: バックグラウンド
  - `-p host:container`: ポート公開
  - `--name`: コンテナ名
  - `-e KEY=VAL`: 環境変数（※秘密情報は注意）
- `docker ps` / `docker ps -a`: 起動中 / 全コンテナ確認
- `docker logs -f <container>`: ログ追跡
- `docker exec -it <container> sh|bash`: コンテナ内シェル
- `docker build -t <name:tag> .`: Dockerfile からビルド
- `docker compose up -d` / `docker compose down`: 複数サービス起動/停止
- `docker image ls`, `docker container ls`, `docker volume ls`, `docker network ls`: リソース確認

---

## 4) App 開発での使い方（docs.docker.com ベストプラクティス準拠）

- **開発/本番で Dockerfile を整理**
  - マルチステージで build ツールを最終イメージに持ち込まない
- **`.dockerignore` を整備**
  - `node_modules`, `.git`, ローカル秘密ファイルを送らない
- **1コンテナ1責務を意識**
  - Web/API/DB を compose で分離
- **イメージは固定タグを優先**
  - `latest` 依存を減らし再現性を上げる
- **シークレットをイメージへ焼き込まない**
  - `ENV PASSWORD=...` や Dockerfile 直書きを避ける
  - compose の `env_file` や実行時注入、必要なら Docker secrets を検討
- **非rootユーザー実行を検討**
  - アプリ実行権限を最小化

参考（公式）:
- Dockerfile best practices: https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Multi-stage builds: https://docs.docker.com/build/building/multi-stage/
- Compose overview: https://docs.docker.com/compose/

---

## 5) 30-60分ミニラボ

### 目標
Node.js API + PostgreSQL の開発環境を compose で起動し、ログ確認・接続確認まで行う。

### 手順（目安45分）

1. 作業ディレクトリ作成（5分）
   - `mkdir docker-mag-lab && cd docker-mag-lab`

2. `docker-compose.yml` 作成（10分）
   - `app` と `db` サービスを定義
   - `db` に named volume を付与

3. `app` 用 Dockerfile 作成（10分）
   - `node:20-alpine` ベース
   - `WORKDIR /app`
   - `COPY package*.json ./` → `npm ci`
   - `COPY . .`
   - `CMD ["npm","run","dev"]`

4. 起動と検証（10分）
   - `docker compose up -d --build`
   - `docker compose ps`
   - `docker compose logs -f app`

5. コンテナ内確認（5分）
   - `docker compose exec app sh`
   - 環境変数・依存関係を確認

6. 後片付け（5分）
   - `docker compose down`
   - ボリュームを残す/消す違いを確認

**発展課題（+15分）**
- Dockerfile をマルチステージ化し、最終イメージサイズを比較

---

## 6) Command cheatsheet

```bash
# 基本確認
docker version
docker info

# イメージ/コンテナ
docker pull nginx:1.27
docker run -d --name web -p 8080:80 nginx:1.27
docker ps
docker logs -f web
docker exec -it web sh

# ビルド
docker build -t myapp:dev .

# Compose
docker compose up -d --build
docker compose ps
docker compose logs -f
docker compose down
```

---

## 7) Common mistakes & safe practices

### よくあるミス
- `latest` タグに依存して突然挙動が変わる
- `.env` や秘密鍵をイメージに COPY してしまう
- `docker system prune -a` を意味を理解せず実行して環境破壊
- DB データを anonymous volume に置いて消失

### 安全運用のポイント
- 破壊的コマンド実行前に必ず対象確認:
  - `docker ps -a`, `docker image ls`, `docker volume ls`
- **警告（破壊的）**:
  - `docker system prune`, `docker image prune -a`, `docker rm -f`, `docker rmi`
  - 実行前に削除対象と復旧可能性を必ず確認
- シークレットは Git 管理・Dockerfile 直書きしない
- 可能なら非rootで実行し、最小権限を維持

---

## 8) Interview-style question

「`docker run` と `docker compose up` の使い分けを、ローカル開発とチーム運用の観点で説明してください。さらに、再現性を高めるためにタグ運用と設定ファイル管理をどう設計しますか？」

---

## 9) Next-step resources（公式優先）

- Get Started: https://docs.docker.com/get-started/
- Dockerfile reference: https://docs.docker.com/reference/dockerfile/
- Build cache: https://docs.docker.com/build/cache/
- Compose file reference: https://docs.docker.com/reference/compose-file/
- Docker Engine security: https://docs.docker.com/engine/security/
- Manage sensitive data & secrets: https://docs.docker.com/engine/swarm/secrets/

---

次号予告: **Beginner(ボリューム基礎) → Middle(開発ホットリロード最適化) → Advanced(イメージ署名/サプライチェーン対策)**