---
tags:
  - docker
  - containers
  - devops
  - learning
  - daily
---

[[Home]]

# 2026-07-02 09-20 Docker Commands Magazine

## 今回のテーマ
**Dockerコマンドで開発環境を安全に動かす：`docker run` / `docker exec` / `docker logs` / `docker compose up` を軸にした実践入門**

---

## 1) Topic + Level

### Beginner
**トピック:** コンテナを起動・確認・停止する基本コマンド

学ぶコマンド:
- `docker run`
- `docker ps`
- `docker stop`
- `docker logs`

### Middle
**トピック:** 実アプリ開発で使うコンテナ内部操作とCompose運用

**前提条件:**
- Beginnerの内容を理解している
- イメージとコンテナの違いがわかる
- ポート公開 (`-p`) の基本を知っている

学ぶコマンド:
- `docker exec`
- `docker compose up`
- `docker compose ps`
- `docker compose down`

### Advanced
**トピック:** 開発効率と安全性を意識したイメージ構築・調査・後片付け

**前提条件:**
- Middleの内容を理解している
- Dockerfileの基本命令 (`FROM`, `WORKDIR`, `COPY`, `RUN`) を見たことがある
- ボリューム・ネットワーク・レイヤーの概念をざっくり理解している

学ぶコマンド:
- `docker build`
- `docker image ls`
- `docker inspect`
- `docker compose logs`
- `docker system df`

---

## 2) Why it matters for real app development

Dockerは「自分のPCでは動くのに、他の人の環境では動かない」を減らすための土台です。実アプリ開発では特に次の価値があります。

- **環境差分の削減**
  - Node.jsやPython、DBのバージョン差異による不具合を減らせます。
- **チーム開発の再現性**
  - 新メンバーが同じ環境を短時間で起動できます。
- **本番に近い検証**
  - Webアプリ + DB + キャッシュなど複数サービスをローカルで再現できます。
- **CI/CDとの整合**
  - GitHub Actionsなどのビルド・テスト・デプロイと考え方を揃えやすいです。
- **安全な分離**
  - ホストOSに依存関係を直接汚しにくく、後始末もしやすいです。

実務では、Dockerを「配布可能なアプリ実行環境」として使う感覚が重要です。単なる便利CLIではなく、開発・テスト・運用の共通基盤です。

---

## 3) Core Docker command explanations

### `docker run`
コンテナを新しく作って起動します。

例:
```bash
docker run --name web-test -d -p 8080:80 nginx:latest
```

ポイント:
- `--name`: コンテナ名を付ける
- `-d`: バックグラウンド実行
- `-p 8080:80`: ホスト8080番をコンテナ80番へ転送
- `nginx:latest`: 使用イメージ

### `docker ps`
動いているコンテナを確認します。

例:
```bash
docker ps
```

停止済みも含めるなら:
```bash
docker ps -a
```

### `docker stop`
コンテナを安全に停止します。

例:
```bash
docker stop web-test
```

### `docker logs`
コンテナの標準出力・標準エラーを確認します。

例:
```bash
docker logs web-test
```

追尾するなら:
```bash
docker logs -f web-test
```

### `docker exec`
起動中コンテナの中でコマンドを実行します。

例:
```bash
docker exec -it web-test sh
```

用途:
- 設定ファイル確認
- プロセス状態確認
- アプリの動作調査

### `docker compose up`
複数コンテナをまとめて起動します。

例:
```bash
docker compose up -d
```

実務ではWebアプリ、DB、Redisなどをまとめて扱うときの基本です。

### `docker compose down`
Composeで起動した環境を停止・削除します。

例:
```bash
docker compose down
```

### `docker build`
Dockerfileからイメージを作ります。

例:
```bash
docker build -t myapp:dev .
```

### `docker inspect`
コンテナやイメージの詳細情報をJSONで確認します。

例:
```bash
docker inspect web-test
```

---

## 4) How Docker is used while building apps

docs.docker.com のベストプラクティスに沿うと、Dockerは「とりあえず全部コンテナに入れる道具」ではなく、**再現性・分離・最小化**のために使います。

### 開発中の使い方
- アプリ本体をコンテナで起動する
- DBやRedisなど依存サービスをComposeでまとめる
- ローカルソースをマウントしてホットリロードする
- `docker compose logs` でサービス単位にログ確認する

### イメージ作成時の考え方
- **小さく保つ**: 不要なパッケージを入れない
- **公式・信頼できるベースイメージを使う**
- **マルチステージビルドを使う**: ビルドに必要なものと実行に必要なものを分離する
- **`.dockerignore` を使う**: `node_modules`, `.git`, `.env` など不要・秘匿ファイルを送らない
- **1コンテナ1責務を意識する**: 役割を詰め込みすぎない

### セキュリティ上の重要ポイント
- **秘密情報をイメージに焼き込まない**
  - `COPY . .` で `.env` を巻き込む事故に注意
  - パスワードやAPIキーをDockerfileに直書きしない
- **root前提で動かさない設計を検討する**
- **不要なポートを公開しない**
- **本番では `latest` 固定依存を避け、必要に応じてタグを明示する**

### Compose運用の実践感
たとえばWebアプリ構築では次のような形が定番です。
- `app` サービス: Node/Python/Railsなどのアプリ本体
- `db` サービス: PostgreSQL/MySQL
- `redis` サービス: キャッシュやジョブキュー

これにより、READMEに「`docker compose up` で始められる開発環境」を提供できます。これは onboarding とCI連携の両面で強いです。

---

## 5) 30-60 minute hands-on mini lab

### 目標
Nginxコンテナを起動し、ログ確認・コンテナ内部確認・Composeによる複数サービス起動まで一通り触る。

### 所要時間
約45分

### 手順

#### Part A: 単体コンテナを動かす（15分）
1. Nginxを起動
```bash
docker run --name docker-mag-nginx -d -p 8080:80 nginx:latest
```

2. 稼働確認
```bash
docker ps
```

3. ブラウザで確認
- `http://localhost:8080`

4. ログ確認
```bash
docker logs docker-mag-nginx
```

5. コンテナ内部へ入る
```bash
docker exec -it docker-mag-nginx sh
```

中で次を試す:
```sh
ls /usr/share/nginx/html
exit
```

#### Part B: ComposeでWeb + DBを起動する（20分）
作業ディレクトリを作る:
```bash
mkdir -p docker-mag-lab && cd docker-mag-lab
```

`compose.yaml` を作成:
```yaml
services:
  web:
    image: nginx:latest
    ports:
      - "8081:80"

  db:
    image: postgres:16
    environment:
      POSTGRES_PASSWORD: change-me-for-local-dev
      POSTGRES_DB: sampleapp
      POSTGRES_USER: sampleuser
```

起動:
```bash
docker compose up -d
```

確認:
```bash
docker compose ps
```

ログ確認:
```bash
docker compose logs web
```
```bash
docker compose logs db
```

#### Part C: 後片付けと容量確認（10分）
Compose環境停止:
```bash
docker compose down
```

単体コンテナ停止:
```bash
docker stop docker-mag-nginx
```

容量確認:
```bash
docker system df
```

### 発展課題（余裕があれば）
- `compose.yaml` にボリュームを追加してDBデータ保持を試す
- `docker inspect` で `web` コンテナのポート設定を見る
- `.dockerignore` を調べて、何を除外すべきか書き出す

---

## 6) Command cheatsheet

```bash
# コンテナ起動
docker run --name sample -d -p 8080:80 nginx:latest

# 実行中コンテナ確認
docker ps

# 停止済み含め一覧
docker ps -a

# ログ確認
docker logs sample
docker logs -f sample

# コンテナ内部でシェル起動
docker exec -it sample sh

# Dockerfileからイメージ作成
docker build -t myapp:dev .

# Compose起動
docker compose up -d

# Compose状態確認
docker compose ps

# Composeログ
docker compose logs
docker compose logs web

# Compose停止・削除
docker compose down

# 詳細情報
docker inspect sample

# ディスク使用量確認
docker system df
```

---

## 7) Common mistakes and safe practices

### よくあるミス

#### 1. `latest` を無条件で信じる
- ある日突然挙動が変わることがあります。
- 学習用途では便利ですが、実務ではタグ固定や更新方針が重要です。

#### 2. `.env` や秘密情報をイメージに入れてしまう
- `COPY . .` が原因になりがちです。
- `.dockerignore` を必ず整備しましょう。
- Secretはイメージに焼き込まず、環境変数・Secret管理機構・安全な注入方法を使います。

#### 3. コンテナ削除とデータ削除を混同する
- DBコンテナを消しても、ボリュームが残る場合があります。
- 逆に `down -v` はボリュームまで消します。

#### 4. `docker exec` で直接直した内容が永続化されると思い込む
- コンテナ内部変更は再作成で消えることが多いです。
- 永続化すべき変更はDockerfileや設定ファイルに戻しましょう。

### 安全な運用のコツ
- まず `docker ps`, `docker compose ps`, `docker system df` で現状把握してから操作する
- 削除系コマンドは対象を明示する
- Composeファイルは最小構成から始める
- 使うイメージは公式または信頼できる配布元を優先する
- 本番に近い設定と、ローカル専用の緩い設定を混ぜすぎない

### 破壊的コマンドへの注意
以下は便利ですが、**実行前に何が消えるか必ず確認**してください。

```bash
# 未使用リソースを一括削除（要注意）
docker system prune

# イメージ削除（要注意）
docker rmi IMAGE_ID

# 強制削除（特に要注意）
docker rm -f CONTAINER_ID
```

特に次は危険度が高いです。
```bash
docker system prune -a
docker builder prune
docker compose down -v
```

学習中でも、破壊的コマンドを打つ前に以下を確認すると安全です。
- それは本当に不要か？
- 他プロジェクトで使っていないか？
- ボリュームやキャッシュまで消えないか？

---

## 8) One interview-style question

**質問:**
`docker run` と `docker exec` の違いを説明してください。また、アプリ障害の一次切り分けでどちらをどう使うか話してください。

**考えるポイント:**
- 新しいコンテナを作る操作か
- 既存コンテナに入る操作か
- ログ確認、設定確認、プロセス確認とどう組み合わせるか

---

## 9) Next-step resources

公式ドキュメント中心:
- Docker Get Started
  - https://docs.docker.com/get-started/
- Docker Guides
  - https://docs.docker.com/guides/
- Dockerfile best practices
  - https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Compose overview
  - https://docs.docker.com/compose/
- Compose file reference
  - https://docs.docker.com/reference/compose-file/
- Image best practices / building best practices
  - https://docs.docker.com/build/building/best-practices/
- Docker storage / volumes
  - https://docs.docker.com/storage/volumes/
- Docker Engine security
  - https://docs.docker.com/engine/security/

---

## 学習メモ
今日の重点は「コマンド暗記」ではなく、**実アプリ開発の流れの中でDockerコマンドをどう使うか**です。

おすすめの順番:
1. `docker run` で単体起動
2. `docker logs` と `docker exec` で観察
3. `docker compose up` で複数サービス化
4. `docker build` と `.dockerignore` で再現可能な開発環境へ進む

地味ですが、この順番がいちばん実務につながります。
