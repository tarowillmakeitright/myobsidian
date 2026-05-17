---
tags: [docker, containers, devops, learning, daily]
---

# Docker Commands Magazine — 2026-05-17

[[Home]]

> 毎日9:20発行 / 実務で使える Docker コマンドを、初級 → 中級 → 上級の学習アークで積み上げる。

---

## 1) Topic + Level

### 🟢 Beginner
**トピック:** `docker run` / `docker ps` / `docker logs` で「動かす・確認する・観察する」

### 🟡 Middle
**トピック:** `docker exec` / `docker cp` / `docker inspect` で「稼働中コンテナを調査・修正」
**前提:** `docker run`, `docker ps`, `docker logs` を使ってコンテナ起動とログ確認ができること

### 🔴 Advanced
**トピック:** `docker build`（BuildKit）/ マルチステージビルド / `docker compose up` で「本番を意識したイメージ構築と複数サービス運用」
**前提:** コンテナ内部への入り方（`docker exec`）と、基本的なファイルコピー（`docker cp`）を理解していること

---

## 2) Why it matters for real app development

- ローカル開発で**環境差分（OS/ライブラリ）を減らせる**
- チーム開発で「自分のPCでは動く」を減らし、**再現性の高いデバッグ**ができる
- CI/CDへ接続しやすく、**デプロイ品質と速度**を改善できる
- BuildKit + マルチステージで、**小さい・速い・安全なイメージ**を作りやすい

---

## 3) Core Docker command explanations

### Beginner コマンド
- `docker run --name web -d -p 8080:80 nginx:alpine`
  - Nginx コンテナをバックグラウンド起動
  - `-p 8080:80` は「ホスト8080 → コンテナ80」
- `docker ps`
  - 起動中コンテナ一覧
- `docker logs -f web`
  - `web` コンテナのログを追跡表示

### Middle コマンド
- `docker exec -it web sh`
  - 稼働中コンテナ内でシェル実行（調査用）
- `docker inspect web`
  - IP、マウント、環境変数、ネットワーク設定をJSONで確認
- `docker cp ./index.html web:/usr/share/nginx/html/index.html`
  - ローカルファイルをコンテナへコピー（暫定修正に便利）

### Advanced コマンド
- `DOCKER_BUILDKIT=1 docker build -t myapp:dev .`
  - BuildKit有効でビルド（キャッシュ効率・機能向上）
- `docker compose up -d --build`
  - 複数サービスをビルド＋起動
- `docker image ls`, `docker history myapp:dev`
  - イメージサイズやレイヤー構造を確認

---

## 4) How Docker is used while building apps (docs.docker.com best practices 準拠)

- **1コンテナ1責務**を基本にする（Web/API/DBを分離）
- Dockerfileは**軽量ベースイメージ**を優先（例: `alpine`, `distroless` 適材適所）
- **マルチステージビルド**でビルド依存を最終イメージに残さない
- `.dockerignore` を設定し、不要ファイル（`.git`, `node_modules`, secrets）を送らない
- 機密情報は
  - ❌ `ENV API_KEY=...` / 直書き
  - ✅ Docker secrets / 実行時注入 / CIのシークレットストア
- コンテナは可能なら**非rootユーザー**で実行
- ヘルスチェック、明示タグ、イメージスキャンをCIに組み込む

---

## 5) 30-60 minute hands-on mini lab

**目標:** Nginxコンテナを起動し、静的ページを配信。最後に簡易Compose化する。

### Step 1 (10分): 起動と観察
1. `docker run --name web -d -p 8080:80 nginx:alpine`
2. `docker ps`
3. `docker logs -f web`
4. ブラウザで `http://localhost:8080` を確認

### Step 2 (15分): コンテナ調査
1. `docker inspect web | less`
2. `docker exec -it web sh`
3. `cat /etc/nginx/nginx.conf` など設定を確認

### Step 3 (15分): コンテンツ差し替え
1. ローカルで `index.html` を作成
2. `docker cp ./index.html web:/usr/share/nginx/html/index.html`
3. ブラウザを更新して反映確認

### Step 4 (10-20分): Compose化
1. `compose.yaml` を作成（`nginx:alpine`, `ports: ["8080:80"]`）
2. `docker compose up -d`
3. `docker compose ps`

**完了条件:**
- 起動確認・ログ確認・内部確認・ページ差し替え・Compose起動が一通りできる

---

## 6) Command cheatsheet

```bash
# 起動/停止
docker run --name web -d -p 8080:80 nginx:alpine
docker stop web && docker start web

# 観察
docker ps
docker logs -f web
docker inspect web

# コンテナ内部
docker exec -it web sh

# ファイルコピー
docker cp ./index.html web:/usr/share/nginx/html/index.html

# イメージ/ビルド
DOCKER_BUILDKIT=1 docker build -t myapp:dev .
docker image ls
docker history myapp:dev

# Compose
docker compose up -d --build
docker compose ps
docker compose logs -f
```

---

## 7) Common mistakes and safe practices

### よくあるミス
- `latest` タグ固定で再現性が崩れる
- Dockerfileに秘密情報を埋め込む
- `docker exec` で手修正して満足し、Dockerfileへ反映しない
- 不要な巨大コンテキストをビルド送信して遅くなる

### 安全運用の注意
- `docker system prune`, `docker image prune`, `docker container rm -f`, `docker rmi` は**破壊的**
  - 実行前に必ず対象を確認（`docker ps -a`, `docker image ls`, `docker volume ls`）
  - 共有環境では合意を取ってから実行
- 本番相当データを扱うVolumeは削除前にバックアップ
- シークレットは `.env` 直置きでもGit管理外を徹底し、可能なら secrets 機構へ移行

---

## 8) Interview-style question

**Q.** `docker exec` で本番コンテナに入って直接修正する運用は、なぜ推奨されないことが多いですか？代替アプローチは？

**A（要点）:**
- 修正内容がイメージに残らず、再起動/再デプロイで消える
- 変更履歴が追えず監査性が低い
- 環境ドリフトを招く
- 代替は「Dockerfile/ソース修正 → 再ビルド → 再デプロイ（Immutable Infrastructure）」

---

## 9) Next-step resources (official docs 優先)

- Docker Docs Home: https://docs.docker.com/
- Get started: https://docs.docker.com/get-started/
- Dockerfile best practices: https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Multi-stage builds: https://docs.docker.com/build/building/multi-stage/
- BuildKit overview: https://docs.docker.com/build/buildkit/
- Compose getting started: https://docs.docker.com/compose/gettingstarted/
- Docker Engine security: https://docs.docker.com/engine/security/

---

次号予告: **「データ永続化（Volumes）とバックアップ戦略」**（Beginner→Advancedで段階学習）