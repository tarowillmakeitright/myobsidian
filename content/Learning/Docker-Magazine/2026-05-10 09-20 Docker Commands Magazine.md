---
tags:
  - docker
  - containers
  - devops
  - learning
  - daily
---

# 2026-05-10 09:20 Docker Commands Magazine
[[Home]]

今日のテーマは、**Beginner → Middle → Advanced** の順で「実アプリ開発でそのまま使えるDockerコマンド運用」を一気に学ぶ構成です。

---

## 1) Topic + Level

### [Beginner] `docker run` / `docker ps` / `docker logs` で「まず動かして観測する」
**Topic:** コンテナの起動・確認・ログ確認の基本ループ

### [Middle] `docker build` / `docker exec` / `docker compose up` で「開発環境を再現可能にする」
**Prerequisites:**
- `docker run`でコンテナを起動できる
- ポート公開（`-p`）の意味が分かる
- イメージとコンテナの違いを説明できる

### [Advanced] `multi-stage build` + `docker compose`運用 + クリーンアップ戦略
**Prerequisites:**
- Dockerfileの基本命令（`FROM`, `RUN`, `COPY`, `CMD`）を理解している
- `docker compose up/down` を使ったことがある
- ローカル開発でボリュームマウントを使ったことがある

---

## 2) Why it matters for real app development

- **環境差分を潰せる**: 「自分のPCだけ動く」を減らせる
- **オンボーディングが速い**: 新メンバーが `docker compose up` ですぐ開発開始
- **デバッグ効率が上がる**: `docker logs` / `docker exec` で問題箇所に即アクセス
- **CI/CDと整合しやすい**: ローカルと同じDockerfileをパイプラインでも使える
- **セキュリティ改善**: 最小イメージ・非root・秘密情報分離など実践しやすい

---

## 3) Core Docker command explanations

### Beginner コアコマンド
- `docker run -d --name web -p 8080:80 nginx:alpine`
  - `-d`: バックグラウンド実行
  - `--name`: 管理しやすい名前を付与
  - `-p host:container`: ポート公開
- `docker ps` / `docker ps -a`
  - 稼働中 / 全コンテナ確認
- `docker logs -f web`
  - `-f` で追尾（リアルタイム確認）

### Middle コアコマンド
- `docker build -t myapp:dev .`
  - Dockerfileからイメージを作成
- `docker exec -it myapp sh`
  - 稼働中コンテナに入って調査
- `docker compose up -d`
  - 複数サービス（app/db/redisなど）を一括起動

### Advanced コアコマンド
- `docker build --target runtime -t myapp:prod .`
  - multi-stageの最終段のみを使い軽量化
- `docker compose logs -f --tail=200`
  - 複数サービスのログをまとめて分析
- `docker image prune` / `docker system df`
  - イメージ肥大化の把握と整理
  - ⚠️ **破壊的コマンド注意**: `prune`, `rmi`, `rm -f` は不要データだけでなく必要なものも消すリスクあり。実行前に対象確認必須。

---

## 4) How Docker is used while building apps (docs.docker.com best practices aligned)

実開発フローでの使い方（推奨）:

1. **開発用DockerfileとComposeを用意**
   - 依存関係をDockerfileに明示
   - app/db/cacheをComposeで定義

2. **Build cacheを活かすレイヤー順**
   - 依存定義ファイル（例: `package*.json`, `requirements.txt`）を先にCOPY
   - コード本体COPYを後にして再build時間短縮

3. **multi-stage buildで本番イメージ最小化**
   - buildに必要なツールを最終イメージに残さない

4. **`.dockerignore` を必ず整備**
   - `node_modules`, `.git`, ログ、秘密ファイルを送らない

5. **秘密情報はイメージに埋め込まない**
   - `ENV` や Dockerfile直書きでAPIキーを固定しない
   - Composeの環境変数・シークレット機構・外部シークレット管理を利用

6. **least privilege**
   - 可能なら非rootユーザーで実行
   - 不要ポートを公開しない

---

## 5) 30-60 minute hands-on mini lab

**目標:** Node.js API + Redis をComposeで起動し、ログ・exec・安全な後片付けまで体験

### Step A (10-15分): 雛形作成
1. `Dockerfile`（dev向け簡易）
2. `docker-compose.yml` で `app` と `redis` を定義
3. `.dockerignore` を作成（`node_modules`, `.git`, `.env` など）

### Step B (10-20分): 起動と確認
1. `docker compose up -d --build`
2. `docker compose ps`
3. `docker compose logs -f app`
4. ブラウザ/`curl`でヘルスチェック

### Step C (10-15分): デバッグ体験
1. `docker exec -it <app-container> sh`
2. コンテナ内で環境変数・ファイル確認
3. ログとの突き合わせ

### Step D (5-10分): 安全なクリーンアップ
1. `docker compose down`
2. `docker system df` で容量確認
3. 必要なら `docker image prune`（**実行前に対象確認**）

---

## 6) Command cheatsheet

```bash
# 起動

docker run -d --name web -p 8080:80 nginx:alpine

docker compose up -d --build

# 状態確認

docker ps

docker compose ps

docker system df

# ログ

docker logs -f web

docker compose logs -f --tail=200

# コンテナ内調査

docker exec -it web sh

# 停止/削除

docker stop web && docker rm web

docker compose down

# クリーンアップ（要注意）

docker image prune
# ⚠️ 使っていないイメージを削除。対象確認してから。
```

---

## 7) Common mistakes and safe practices

### よくあるミス
- Dockerfileに `.env` や秘密鍵をCOPYしてしまう
- `latest` タグ固定で再現性が崩れる
- `docker system prune -a` を理解せず実行して必要資産を消す
- root実行前提で本番運用する

### 安全プラクティス
- ベースイメージは明示タグ/ダイジェストで固定
- `.dockerignore` で不要・機密ファイル除外
- 秘密情報はイメージ外で注入（Secrets/環境注入）
- 破壊系コマンド前に `docker ps -a`, `docker images`, `docker volume ls` で対象確認

---

## 8) One interview-style question

**Q.** `docker compose up --build` と `docker compose up` の違いは？また、チーム開発で使い分ける基準は？

（答えるときの観点: イメージ再ビルド必要性、依存更新時、CIとの整合、時間コスト）

---

## 9) Next-step resources (official Docker docs)

- Docker Get Started: https://docs.docker.com/get-started/
- Dockerfile reference: https://docs.docker.com/reference/dockerfile/
- Compose file reference: https://docs.docker.com/reference/compose-file/
- Build best practices: https://docs.docker.com/build/building/best-practices/
- Multi-stage builds: https://docs.docker.com/build/building/multi-stage/
- Docker Engine security: https://docs.docker.com/engine/security/
- Prune unused objects: https://docs.docker.com/engine/manage-resources/pruning/

---

次号予告: **Beginnerに戻って「ボリュームと永続化」**を起点に、Middleで「開発体験最適化（ホットリロード）」、Advancedで「本番向けイメージ最適化＋脆弱性スキャン」に進みます。