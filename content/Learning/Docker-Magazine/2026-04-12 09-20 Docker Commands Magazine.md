---
tags: [docker, containers, devops, learning, daily]
---

# 2026-04-12 Docker Commands Magazine
[[Home]]

本日のテーマは **「Dockerコマンドを実務に繋げる3段階学習（Beginner → Middle → Advanced）」**。  
各レベルは連続した学習アークとして設計しています。

---

## 1) Topic + Level

### Beginner（初級）
**Topic:** `docker run / ps / logs / exec / stop / rm` で「コンテナを安全に回す」

### Middle（中級）
**Topic:** `docker build / image / tag / push / compose up` で「開発環境を再現可能にする」

**Prerequisites:**
- Beginnerのコマンドを迷わず使える
- Linux基本操作（pwd, ls, cat）
- Gitの基本（clone, branch）

### Advanced（上級）
**Topic:** BuildKit・マルチステージ・キャッシュ最適化・セキュアなイメージ運用

**Prerequisites:**
- Middleの内容（Dockerfile作成、Compose運用）
- CI/CDの基本概念
- アプリ依存関係（npm/pip/maven等）の理解

---

## 2) なぜ実アプリ開発で重要か

- **環境差分を削減**: 「自分のPCでは動く」を減らせる
- **オンボーディング高速化**: 新メンバーが同じ構成を即再現
- **デバッグ効率向上**: logs/execで実行中コンテナを直接観察
- **デプロイ品質向上**: 同じイメージをステージング/本番へ運べる
- **セキュリティ改善**: 最小イメージ・不要権限削減・秘密情報分離が可能

---

## 3) Core Docker commands（要点解説）

- `docker run --name app -p 8080:80 nginx`
  - イメージからコンテナ起動。`-p` は **host:container** でポート公開
- `docker ps -a`
  - 稼働中/停止済みコンテナ一覧
- `docker logs -f app`
  - ログ追跡（障害切り分けの基本）
- `docker exec -it app sh`
  - 稼働中コンテナへ入って調査
- `docker stop app && docker rm app`
  - 停止 + 削除（再作成の癖をつける）
- `docker build -t myapp:dev .`
  - Dockerfileからイメージ作成
- `docker compose up -d`
  - 複数サービス（app/db/redis等）をまとめて起動
- `docker compose logs -f`
  - サービス横断ログ確認

---

## 4) 実装時の使い方（docs.docker.comベストプラクティス準拠）

- Dockerfileは **小さく・明示的に**（不要パッケージを入れない）
- **マルチステージビルド**で実行イメージを軽量化
- `.dockerignore` を使い、不要ファイル（node_modules, .git, secrets）を送らない
- 固定タグよりも、可能ならベースイメージをバージョン/ダイジェストで管理
- コンテナは基本 **ephemeral（使い捨て）**。永続データはvolumeへ
- 機密情報はイメージやCompose直書き禁止（環境変数管理/secret機構を使用）

参考:
- https://docs.docker.com/build/building/best-practices/
- https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- https://docs.docker.com/compose/

---

## 5) 30-60分ミニラボ

### Goal
Node.js API + Redis を Compose で立ち上げ、ログと接続確認まで行う。

### 手順（約45分）
1. プロジェクト作成
   - `mkdir docker-lab && cd docker-lab`
2. `app.js`, `package.json`, `Dockerfile`, `compose.yaml` を作成
3. イメージ作成
   - `docker build -t docker-lab-api:dev .`
4. 一式起動
   - `docker compose up -d`
5. 動作確認
   - `docker compose ps`
   - `docker compose logs -f app`
6. コンテナ内確認
   - `docker compose exec app sh`
7. 後片付け
   - `docker compose down`

### 追加チャレンジ（Advanced向け）
- Dockerfileをマルチステージ化
- BuildKitキャッシュを有効化してビルド時間比較
- non-rootユーザー実行へ変更

---

## 6) Command Cheatsheet

- 起動: `docker compose up -d`
- 停止: `docker compose stop`
- 削除（ネットワーク含む）: `docker compose down`
- ログ追跡: `docker compose logs -f <service>`
- シェル接続: `docker compose exec <service> sh`
- イメージ一覧: `docker images`
- 未使用リソース確認: `docker system df`

⚠ **破壊的コマンド注意**
- `docker system prune -a`
- `docker image rm -f <image>`
- `docker rm -f <container>`

これらは復旧困難な削除を起こす可能性があります。実行前に対象確認（`docker ps -a`, `docker images`）とバックアップを。

---

## 7) よくあるミス & 安全策

- ミス: `COPY . .` で秘密情報まで混入
  - 安全策: `.dockerignore` を必ず整備
- ミス: rootユーザーで常時実行
  - 安全策: `USER` を設定して権限最小化
- ミス: latestタグ依存で再現不能
  - 安全策: バージョン固定・定期更新
- ミス: `prune` を無警戒実行
  - 安全策: 事前に `docker system df` と一覧確認
- ミス: Composeファイルへ平文シークレット直書き
  - 安全策: シークレット管理機構（Docker secrets/外部secret manager）を利用

---

## 8) Interview-style Question

「本番障害で“コンテナ再起動で直る”状態が続いています。  
あなたなら `docker logs`, `docker inspect`, `docker exec` をどう使って原因を切り分け、再発防止まで設計しますか？」

---

## 9) Next-step resources（公式優先）

- Docker Get Started: https://docs.docker.com/get-started/
- Dockerfile reference: https://docs.docker.com/reference/dockerfile/
- BuildKit: https://docs.docker.com/build/buildkit/
- Multi-stage builds: https://docs.docker.com/build/building/multi-stage/
- Docker Compose docs: https://docs.docker.com/compose/
- Docker Engine security: https://docs.docker.com/engine/security/

---

次号予告: **「Beginner2: ボリューム/ネットワークを理解して“消えて困るデータ”を守る」**