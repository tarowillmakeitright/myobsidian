---
tags:
  - docker
  - containers
  - devops
  - learning
  - daily
---

# 2026-04-17 09:20 Docker Commands Magazine
[[Home]]

## 今日の学習アーク（Beginner → Middle → Advanced）

---

## 1) Topic + Level

### Beginner
**Topic:** コンテナの基本操作（`docker run` / `docker ps` / `docker logs` / `docker exec`）

### Middle
**Topic:** Dockerfileでのアプリ開発フロー（`docker build` / `docker compose up`）
**Prerequisites:**
- Beginnerのコマンドを一通り実行できる
- Linuxコマンドの基本（`cd`, `ls`, `cat`）
- どれか1つのWebアプリ言語（Node/Python/Goなど）の基礎

### Advanced
**Topic:** 本番を意識した最適化と安全運用（マルチステージビルド、最小権限、不要データ削減）
**Prerequisites:**
- Middleまで完了
- Dockerfileのレイヤー概念を理解している
- `.env` と環境変数の基礎理解

---

## 2) なぜ実アプリ開発で重要か

- **環境差分を減らす**: 「ローカルでは動くのに本番で落ちる」を減らせる。
- **オンボーディングが速い**: 新メンバーが `docker compose up` で同じ開発環境を再現できる。
- **CI/CDに直結**: build・test・deploy の流れを同じコンテナイメージで扱える。
- **セキュリティ改善**: 最小ベースイメージ、非root実行、secret分離などが実践しやすい。

---

## 3) Core Docker command explanations

- `docker run --name app -p 8080:80 nginx:alpine`
  - イメージからコンテナを起動。`-p` は `ホスト:コンテナ` のポート公開。
- `docker ps` / `docker ps -a`
  - 稼働中 / 全コンテナを確認。
- `docker logs -f app`
  - コンテナ標準出力ログを追跡（`-f`）。
- `docker exec -it app sh`
  - 稼働中コンテナへシェル接続して調査。
- `docker build -t myapp:dev .`
  - Dockerfileからイメージ作成。
- `docker compose up -d`
  - 複数サービスをまとめて起動（DB + APIなど）。
- `docker compose down`
  - composeで作成したリソースを停止・削除（通常運用の終了）。

---

## 4) 実際のアプリ開発での使い方（docs.docker.com のベストプラクティス寄せ）

- **小さいベースイメージを優先**（例: `alpine`, `distroless` は要件に応じて）
- **マルチステージビルド**でビルド成果物のみ最終イメージへ
- **`.dockerignore` を整備**して不要ファイルをビルド文脈に含めない
- **1コンテナ1責務**を意識（API、DB、Workerを分離）
- **設定は環境変数で注入**し、機密情報はイメージに焼き込まない
- **コンテナを非rootで実行**（`USER` を明示）
- **healthcheck とログ設計**で運用時の検知性を上げる

> ⚠️ Secret安全運用: `Dockerfile` や `compose.yaml` に平文パスワード/APIキーを直書きしない。`.env` もGit管理しない（`.gitignore`）。本番ではシークレット管理機構（Docker secrets / 外部Secret Manager）を使う。

---

## 5) 30-60分ハンズオン・ミニラボ（目安45分）

### ゴール
Node系の簡易Web APIをDocker化し、Composeで起動。最後に安全な形へ改善。

### Step A（Beginner / 10-15分）
1. サンプル起動:
   - `docker run --name webdemo -p 8080:80 -d nginx:alpine`
2. 動作確認:
   - `docker ps`
   - `docker logs webdemo`
3. 片付け:
   - `docker stop webdemo && docker rm webdemo`

### Step B（Middle / 15-20分）
1. `Dockerfile` を作成（例: Nodeアプリ）
2. ビルド:
   - `docker build -t myapi:dev .`
3. 起動:
   - `docker run --name myapi -p 3000:3000 -d myapi:dev`
4. 検証:
   - `docker logs -f myapi`
   - `docker exec -it myapi sh`

### Step C（Advanced / 15分）
1. Dockerfileをマルチステージ化
2. `USER node` 等で非root実行
3. `.dockerignore` を追加
4. 再ビルドしてサイズ比較:
   - `docker images | grep myapi`

期待結果:
- 改善後イメージが小さくなる
- コンテナが非rootで起動できる
- 不要ファイルがイメージに含まれない

---

## 6) Command Cheatsheet

- 状態確認
  - `docker ps`
  - `docker ps -a`
  - `docker images`
- 実行・調査
  - `docker run ...`
  - `docker logs -f <container>`
  - `docker exec -it <container> sh`
- ビルド
  - `docker build -t <name:tag> .`
- Compose
  - `docker compose up -d`
  - `docker compose logs -f`
  - `docker compose down`
- 掃除（要注意）
  - `docker system df`
  - `docker image prune`
  - `docker container prune`

> ⚠️ 破壊的コマンド注意:
> - `docker system prune -a`
> - `docker rmi <image>`
> - `docker rm -f <container>`
>
> これらは復元困難な削除を含む。実行前に `docker ps -a` と `docker images` で対象確認。業務環境では必ず影響範囲を確認してから。

---

## 7) よくあるミス & 安全プラクティス

- **ミス:** `COPY . .` で `.git` や秘密ファイルまで入る
  - **対策:** `.dockerignore` を必須化
- **ミス:** rootでそのまま本番運用
  - **対策:** `USER` 指定 + 必要権限のみに絞る
- **ミス:** `latest` タグ固定で予期せぬ更新
  - **対策:** バージョンタグを明示（例 `node:22-alpine`）
- **ミス:** secretをDockerfileに `ENV` で埋め込み
  - **対策:** 実行時注入 + 秘匿ストア利用
- **ミス:** pruneを習慣的に実行
  - **対策:** まず `docker system df` で可視化、削除対象を限定

---

## 8) Interview-style Question

**Q.** 開発用イメージでは動くのに、本番用にマルチステージ化したら起動しなくなりました。どこを疑い、どう切り分けますか？

**考えるポイント（例）**
- 最終ステージに実行に必要なファイルだけ正しくコピーされているか
- `WORKDIR` / `CMD` / `ENTRYPOINT` の整合性
- 実行ユーザー変更（`USER`）で権限不足が起きていないか
- 環境変数やポート設定が本番ステージで欠落していないか

---

## 9) Next-step resources（公式優先）

- Docker Docs Home
  - https://docs.docker.com/
- Get Started
  - https://docs.docker.com/get-started/
- Dockerfile reference
  - https://docs.docker.com/reference/dockerfile/
- Build best practices
  - https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Multi-stage builds
  - https://docs.docker.com/build/building/multi-stage/
- Compose overview
  - https://docs.docker.com/compose/
- Docker Engine security
  - https://docs.docker.com/engine/security/

---

次号予告: **「Docker Networking実践（bridge / host / overlay の使い分け）」**
