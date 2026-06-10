---
tags:
  - docker
  - containers
  - devops
  - learning
  - daily
---

[[Home]]

# 2026-06-10 Docker Commands Magazine

**テーマ:** Dockerコマンドで学ぶ「開発用コンテナの立ち上げ・観察・後片付け」  
**学習アーク:** Beginner → Middle → Advanced

---

# Issue 1 — Beginner

## 1) Topic + Level
**Topic:** コンテナを起動して、状態を確認して、停止する  
**Level:** Beginner

## 2) Why it matters for real app development
実アプリ開発では、ローカルPCに直接ミドルウェアを入れずに、**DB・Redis・開発用ツールをコンテナで使う**場面が非常に多いです。  
Dockerの基本コマンドを理解していると、次のような日常作業が安定します。

- 開発環境をすぐ再現できる
- チーム全員で同じ実行環境を使える
- 「自分のPCでは動くのに…」問題を減らせる
- 一時的な検証環境を安全に捨てられる

Docker公式ドキュメントでも、**再現可能・隔離された開発環境**を作ることが重要視されています。

## 3) Core Docker command explanations
### `docker pull`
イメージを取得します。
```bash
docker pull nginx:latest
```
- `nginx` = イメージ名
- `latest` = タグ
- 実務では `latest` 固定より、**バージョンタグを明示**する方が安全です

### `docker run`
コンテナを新規作成して起動します。
```bash
docker run --name my-nginx -d -p 8080:80 nginx:1.27
```
- `--name` コンテナ名を付ける
- `-d` バックグラウンド実行
- `-p 8080:80` ホスト8080番 → コンテナ80番へ公開

### `docker ps`
起動中のコンテナ一覧を確認します。
```bash
docker ps
```
全コンテナを見るなら:
```bash
docker ps -a
```

### `docker logs`
コンテナログを見ます。
```bash
docker logs my-nginx
```
追従表示:
```bash
docker logs -f my-nginx
```

### `docker stop`
安全に停止します。
```bash
docker stop my-nginx
```

### `docker rm`
停止済みコンテナを削除します。
```bash
docker rm my-nginx
```
**注意:** 実行中コンテナに `docker rm -f` を使うと強制停止を伴います。影響を理解してから使ってください。

## 4) How Docker is used while building apps
アプリ構築中の典型例:

- Webアプリ本体はローカルで動かす
- DB（Postgres/MySQL）はDockerで起動する
- RedisやMailhogなど補助サービスもDockerで動かす
- ログ確認・起動確認・停止削除を頻繁に行う

Docker公式ベストプラクティスに沿うなら、以下が重要です。

- **コンテナは使い捨て前提**で扱う
- 設定差異を減らすため、起動方法をドキュメント化する
- `latest` 依存を避け、**明示タグ**を使う
- アプリの状態はイメージ内に抱え込まず、必要に応じてボリュームや外部DBへ分離する

## 5) 30-60 minute hands-on mini lab
### ゴール
Nginxコンテナを起動し、ブラウザで確認し、ログを見て、停止・削除する。

### 手順
1. イメージ取得
```bash
docker pull nginx:1.27
```

2. コンテナ起動
```bash
docker run --name lab-nginx -d -p 8080:80 nginx:1.27
```

3. 状態確認
```bash
docker ps
```

4. ブラウザで確認  
`http://localhost:8080`

5. ログ確認
```bash
docker logs lab-nginx
```

6. 停止
```bash
docker stop lab-nginx
```

7. 削除
```bash
docker rm lab-nginx
```

### 余裕があれば
停止後に `docker ps -a` を見て、状態遷移を確認する。

## 6) Command cheatsheet
```bash
docker pull nginx:1.27
docker run --name lab-nginx -d -p 8080:80 nginx:1.27
docker ps
docker ps -a
docker logs lab-nginx
docker logs -f lab-nginx
docker stop lab-nginx
docker rm lab-nginx
```

## 7) Common mistakes and safe practices
### よくあるミス
- `latest` を使って毎回違う環境になる
- `docker ps` だけ見て、停止済みコンテナを見落とす
- ポート衝突（例: 8080が既に使用中）
- ログを見ずに「動かない」と判断する

### 安全策
- まずは **`docker logs` と `docker ps -a`** を確認
- 名前を付ける (`--name`) と管理しやすい
- 学習中でも **強制削除 (`rm -f`) は慎重に**
- 本番相当の情報や秘密情報を、環境変数やDockerfileへ雑に直書きしない

## 8) One interview-style question
**質問:** `docker run -d -p 8080:80 nginx:1.27` の `-d` と `-p 8080:80` はそれぞれ何を意味しますか？

## 9) Next-step resources
- Docker Get Started: https://docs.docker.com/get-started/
- Running containers: https://docs.docker.com/get-started/docker-concepts/running-containers/
- Docker CLI reference: https://docs.docker.com/reference/cli/docker/

---

# Issue 2 — Middle

## 1) Topic + Level
**Topic:** イメージを自分でビルドし、アプリをコンテナ化する  
**Level:** Middle

**Prerequisites:**
- `docker run`, `docker ps`, `docker logs`, `docker stop`, `docker rm` が分かる
- 基本的なWebアプリの実行方法を知っている
- ファイル/ディレクトリの基本操作ができる

## 2) Why it matters for real app development
実務では既成イメージを使うだけでなく、**自分のアプリをDockerイメージ化**します。  
これにより:

- 開発・CI・本番で同じ起動条件を共有できる
- 依存関係のズレを減らせる
- オンボーディングが速くなる
- デプロイ単位を明確にできる

## 3) Core Docker command explanations
### `docker build`
Dockerfileからイメージを作ります。
```bash
docker build -t my-node-app:0.1 .
```
- `-t` イメージ名:タグ
- `.` はビルドコンテキスト

### `docker images`
ローカルイメージ一覧を確認します。
```bash
docker images
```

### `docker exec`
実行中コンテナの中でコマンドを実行します。
```bash
docker exec -it my-node-app sh
```
- デバッグに便利
- ただし、**手作業で中を直しても再現性はない**ので、恒久対応は Dockerfile に戻す

### `docker inspect`
詳細情報をJSONで確認します。
```bash
docker inspect my-node-app
```

## 4) How Docker is used while building apps
アプリ開発中は、Dockerfileを通じて**実行環境をコード化**します。Docker公式のベストプラクティスに沿うと:

- ベースイメージは軽量・信頼できるものを選ぶ
- 不要ファイルを `.dockerignore` で送らない
- 1つのコンテナに役割を詰め込みすぎない
- レイヤーキャッシュを意識して、依存インストールとアプリコードCOPY順を工夫する
- **秘密情報を Dockerfile に埋め込まない**
- 本番向けには、必要ならマルチステージビルドを使って小さく安全に保つ

## 5) 30-60 minute hands-on mini lab
### ゴール
簡単なNode.jsアプリをコンテナ化して起動する。

### 作業ファイル
`app.js`
```js
const http = require('http');
const server = http.createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'text/plain' });
  res.end('Hello from Docker!\n');
});
server.listen(3000, () => console.log('Server running on 3000'));
```

`package.json`
```json
{
  "name": "docker-lab",
  "version": "1.0.0",
  "main": "app.js",
  "scripts": {
    "start": "node app.js"
  }
}
```

`Dockerfile`
```Dockerfile
FROM node:22-alpine
WORKDIR /app
COPY package.json ./
COPY app.js ./
EXPOSE 3000
CMD ["node", "app.js"]
```

### 実行手順
1. ビルド
```bash
docker build -t my-node-app:0.1 .
```

2. 起動
```bash
docker run --name my-node-app -d -p 3000:3000 my-node-app:0.1
```

3. 動作確認
```bash
curl http://localhost:3000
```

4. ログ確認
```bash
docker logs my-node-app
```

5. コンテナに入る
```bash
docker exec -it my-node-app sh
```

6. 停止・削除
```bash
docker stop my-node-app
docker rm my-node-app
```

## 6) Command cheatsheet
```bash
docker build -t my-node-app:0.1 .
docker images
docker run --name my-node-app -d -p 3000:3000 my-node-app:0.1
docker logs my-node-app
docker exec -it my-node-app sh
docker inspect my-node-app
docker stop my-node-app
docker rm my-node-app
```

## 7) Common mistakes and safe practices
### よくあるミス
- ビルドコンテキストに不要ファイルを大量に含める
- Dockerfileに `.env` や秘密鍵を `COPY` してしまう
- コンテナ内を手で修正して満足してしまう
- root前提で雑に作る

### 安全策
- `.dockerignore` を必ず用意する
- 秘密情報は **イメージに焼き込まない**
- 再現したい変更は Dockerfile/compose 定義へ戻す
- イメージタグを管理し、何をデプロイしたか追跡可能にする

## 8) One interview-style question
**質問:** `docker build` と `docker run` の役割の違いを説明してください。

## 9) Next-step resources
- Building images: https://docs.docker.com/get-started/docker-concepts/building-images/
- Dockerfile reference: https://docs.docker.com/reference/dockerfile/
- Best practices for writing Dockerfiles: https://docs.docker.com/develop/develop-images/dockerfile_best-practices/

---

# Issue 3 — Advanced

## 1) Topic + Level
**Topic:** 開発用マルチコンテナ構成と安全なクリーンアップ  
**Level:** Advanced

**Prerequisites:**
- Dockerfileの基本が分かる
- イメージ作成とアプリ起動を自力で試したことがある
- ポート公開、ログ確認、基本デバッグができる

## 2) Why it matters for real app development
実アプリでは、Webアプリ単体ではなく、**アプリ + DB + キャッシュ + 補助サービス**をまとめて扱います。  
この段階で重要なのは:

- サービス間接続を安全に設計する
- 永続データと使い捨てコンテナを分離する
- チームで同じ起動方法を共有する
- 後片付けを事故なく行う

## 3) Core Docker command explanations
### `docker compose up`
複数サービスをまとめて起動します。
```bash
docker compose up -d
```

### `docker compose ps`
compose管理下のサービス状態を確認します。
```bash
docker compose ps
```

### `docker compose logs`
複数サービスのログを確認します。
```bash
docker compose logs
```
特定サービスのみ:
```bash
docker compose logs web
```

### `docker compose down`
compose構成を停止・削除します。
```bash
docker compose down
```

### `docker volume ls`
ボリューム一覧を確認します。
```bash
docker volume ls
```

### `docker system prune`
未使用リソースを削除します。
```bash
docker system prune
```
**警告:** 未使用コンテナ・ネットワーク等を削除します。何が消えるか理解してから実行してください。  
さらに `-a` や `--volumes` を付けると影響が大きくなります。

## 4) How Docker is used while building apps
Docker公式の実践に沿うと、開発時のcompose利用では次が重要です。

- サービスごとに責務を分ける
- 永続データはボリュームで管理する
- 内部通信はcomposeネットワークに任せる
- 外部公開が不要なポートはむやみに公開しない
- 環境変数管理を整理し、**シークレットをcomposeファイルへ直書きしない**
- 開発便利機能と本番設定を分離する

## 5) 30-60 minute hands-on mini lab
### ゴール
Node.jsアプリ + Postgres を `docker compose` で起動し、サービスの状態とログを確認する。

### `compose.yaml`
```yaml
services:
  web:
    image: node:22-alpine
    working_dir: /app
    volumes:
      - ./:/app
    command: ["sh", "-c", "node app.js"]
    ports:
      - "3000:3000"
    depends_on:
      - db
    environment:
      POSTGRES_HOST: db
      POSTGRES_PORT: 5432

  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: appdb
      POSTGRES_USER: appuser
      POSTGRES_PASSWORD: change-me-for-local-only
    volumes:
      - pgdata:/var/lib/postgresql/data

volumes:
  pgdata:
```

### 事前注意
- 上記パスワードは**ローカル学習用の例**です
- 本番や共有環境では、秘密情報をcomposeへ直書きしないでください

### 実行手順
1. `app.js` を前Issueの簡易版で用意
2. 起動
```bash
docker compose up -d
```

3. 状態確認
```bash
docker compose ps
```

4. ログ確認
```bash
docker compose logs
```

5. DBボリューム確認
```bash
docker volume ls
```

6. 停止・削除
```bash
docker compose down
```

### 発展
ボリュームを残したまま再起動し、データ永続化の意味を確認する。

## 6) Command cheatsheet
```bash
docker compose up -d
docker compose ps
docker compose logs
docker compose logs web
docker compose down
docker volume ls
docker system prune
```

## 7) Common mistakes and safe practices
### よくあるミス
- DBの永続データまで簡単に消してしまう
- 不要なポートを外部公開する
- composeファイルに本物の秘密情報を書く
- `prune` 系コマンドを意味を知らずに打つ

### 安全策
- 削除前に「何を消すか」を確認する
- `docker compose down` と `docker compose down -v` の違いを理解する
- **`prune`, `rmi`, `rm -f` は破壊的になり得る**ので、学習環境でも注意する
- シークレットはイメージやcomposeに埋め込まない
- まず `docker ps -a`, `docker images`, `docker volume ls` で現状確認してから掃除する

## 8) One interview-style question
**質問:** `docker compose down` と `docker compose down -v` の違いは何ですか？ 開発環境ではどう使い分けますか？

## 9) Next-step resources
- Docker Compose overview: https://docs.docker.com/compose/
- Compose file reference: https://docs.docker.com/reference/compose-file/
- Volumes: https://docs.docker.com/engine/storage/volumes/
- Multi-container applications: https://docs.docker.com/get-started/docker-concepts/running-containers/multi-container-applications/

---

# 今日のまとめ

- Beginnerでは「起動・確認・停止・削除」の基本を押さえる
- Middleでは「自分のアプリをビルドして動かす」へ進む
- Advancedでは「複数サービス運用と安全な掃除」を学ぶ

Docker学習で大事なのは、単にコマンド暗記することではなく、**再現性・安全性・実務での使い方**まで結びつけることです。  
特に次の3点は毎回意識すると伸びます。

1. 何をイメージ化し、何をコンテナとして使い捨てるか
2. どこにデータを残し、どこを簡単に捨ててよいか
3. 秘密情報や破壊的コマンドをどう安全に扱うか
