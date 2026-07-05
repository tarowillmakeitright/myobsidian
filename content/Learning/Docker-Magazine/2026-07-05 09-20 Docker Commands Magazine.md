---
tags:
  - docker
  - containers
  - devops
  - learning
  - daily
---

[[Home]]

# Docker Commands Magazine — 2026-07-05

**テーマ:** Dockerコマンドで学ぶ「開発環境の再現・確認・安全な後片付け」  
**学習アーク:** Beginner → Middle → Advanced

---

# 1. Beginner — `docker run`, `docker ps`, `docker logs`

## なぜ重要か
実アプリ開発では、まず「同じ環境でアプリを起動できること」が大前提です。  
ローカルPCごとの差異を減らし、チーム全員が同じ実行環境で確認できるようになると、

- 「自分の環境では動くのに」が減る
- 初期セットアップが速くなる
- 動作確認や不具合再現がしやすくなる

という大きなメリットがあります。

## コアコマンド解説

### `docker run`
コンテナを新しく作成して起動します。

```bash
docker run --name hello-nginx -d -p 8080:80 nginx:stable
```

- `--name hello-nginx`: コンテナ名を付ける
- `-d`: バックグラウンド起動
- `-p 8080:80`: ホストの8080番をコンテナの80番へ転送
- `nginx:stable`: 使用するイメージ

### `docker ps`
起動中のコンテナ一覧を確認します。

```bash
docker ps
```

停止済みも含めるなら:

```bash
docker ps -a
```

### `docker logs`
コンテナの標準出力・標準エラーを確認します。

```bash
docker logs hello-nginx
```

追従表示:

```bash
docker logs -f hello-nginx
```

## アプリ開発での使われ方
Docker公式ドキュメントのベストプラクティスに沿うと、`docker run` は

- 依存サービスの試験起動
- 動作確認用の一時環境
- 学習用の最小再現

に向いています。  
本格的なアプリ開発では、単発の `docker run` だけで運用するより、後で `Dockerfile` や Compose に整理して再現性を高めるのが実践的です。

また、ログ確認を前提に「アプリは標準出力へログを出す」設計にしておくと、コンテナ運用で追跡しやすくなります。

## 30〜60分ミニラボ
**目標:** Nginxコンテナを起動し、状態確認とログ確認を一通り行う

1. Nginxを起動

```bash
docker run --name hello-nginx -d -p 8080:80 nginx:stable
```

2. コンテナ一覧を確認

```bash
docker ps
```

3. ブラウザで `http://localhost:8080` を開く
4. ログを確認

```bash
docker logs hello-nginx
```

5. 停止して再確認

```bash
docker stop hello-nginx
docker ps -a
```

6. 後片付け

```bash
docker rm hello-nginx
```

## コマンドチートシート

```bash
docker run --name <name> -d -p <host_port>:<container_port> <image>:<tag>
docker ps
docker ps -a
docker logs <container>
docker logs -f <container>
docker stop <container>
docker rm <container>
```

## よくあるミスと安全策
- `-p` の向きを逆にする
  - `8080:80` は「ホスト8080 → コンテナ80」
- `docker ps` に出ない＝削除された、ではない
  - 停止中は `docker ps -a` で確認
- ログが見えない
  - アプリがファイルにだけ書いている可能性あり。コンテナでは標準出力が基本
- 既存ポートと競合する
  - 8080が使用中なら 8081:80 などに変更

## 面接っぽい質問
`docker run -p 8080:80 nginx` の `8080:80` は何を意味しますか？ また、なぜローカル開発でポート公開が必要になることがありますか？

## 次の一歩
- Docker Get Started  
  https://docs.docker.com/get-started/
- Running containers  
  https://docs.docker.com/get-started/docker-concepts/running-containers/
- Viewing container logs  
  https://docs.docker.com/reference/cli/docker/container/logs/

---

# 2. Middle — `docker exec`, `docker inspect`, `docker cp`

**前提知識:** `docker run`, `docker ps`, `docker logs`, コンテナの基本概念

## なぜ重要か
実務では「起動できた」だけでは不十分で、

- コンテナの中で何が起きているか
- 環境変数やネットワーク設定が正しいか
- ファイルを確認・回収できるか

を調べる場面が多いです。障害調査や開発中の確認に必須の視点です。

## コアコマンド解説

### `docker exec`
起動中コンテナの中でコマンドを実行します。

```bash
docker exec -it hello-nginx sh
```

- `-it`: 対話シェル用
- `sh`: コンテナ内のシェル

### `docker inspect`
コンテナやイメージの詳細情報をJSONで表示します。

```bash
docker inspect hello-nginx
```

IPアドレスだけ見たい例:

```bash
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' hello-nginx
```

### `docker cp`
ホストとコンテナ間でファイルをコピーします。

```bash
docker cp hello-nginx:/etc/nginx/nginx.conf ./nginx.conf
```

## アプリ開発での使われ方
Docker公式の考え方に沿うと、`docker exec` は「デバッグ・確認用」であり、恒久的な変更作業の主役にしないのが重要です。  
つまり、コンテナ内で手作業変更して直すのではなく、

- 設定変更 → `Dockerfile` や設定ファイルに反映
- 環境差分の修正 → Compose や build 設定に反映

が基本です。

`inspect` はネットワーク、マウント、環境変数の確認に有用です。  
`cp` はログや生成ファイルの回収に便利ですが、アプリ本体の管理は bind mount やビルド手順で再現可能にしておくほうが健全です。

## 30〜60分ミニラボ
**目標:** コンテナ内部確認と設定ファイル回収を体験する

1. Nginxコンテナを起動

```bash
docker run --name hello-nginx -d -p 8080:80 nginx:stable
```

2. シェルに入る

```bash
docker exec -it hello-nginx sh
```

3. コンテナ内で以下を試す

```sh
pwd
ls /etc/nginx
cat /etc/nginx/nginx.conf | head
exit
```

4. 詳細情報を確認

```bash
docker inspect hello-nginx
```

5. 設定ファイルをホストへコピー

```bash
docker cp hello-nginx:/etc/nginx/nginx.conf ./nginx.conf
```

6. ファイル内容をホスト側で確認

```bash
head ./nginx.conf
```

## コマンドチートシート

```bash
docker exec -it <container> sh
docker exec <container> <command>
docker inspect <container>
docker inspect -f '{{.State.Status}}' <container>
docker cp <container>:<path> <host_path>
docker cp <host_path> <container>:<path>
```

## よくあるミスと安全策
- `exec` で直した内容が永続化されると思い込む
  - コンテナ再作成で消えることが多い。再現可能な定義へ戻す
- `inspect` の大量JSONで迷子になる
  - `-f` で必要な項目だけ抜く
- `docker cp` で本番っぽい秘密情報を雑に持ち出す
  - secrets, `.env`, 鍵ファイルの取り扱いは最小限に
- root前提で触ってしまう
  - 実運用では非rootコンテナを意識する

## 面接っぽい質問
`docker exec` を使って設定を書き換える運用が、なぜ再現性や保守性の観点で問題になりやすいのでしょうか？

## 次の一歩
- Docker CLI reference (`exec`)  
  https://docs.docker.com/reference/cli/docker/container/exec/
- Docker CLI reference (`inspect`)  
  https://docs.docker.com/reference/cli/docker/inspect/
- Docker CLI reference (`cp`)  
  https://docs.docker.com/reference/cli/docker/container/cp/
- Best practices for writing Dockerfiles  
  https://docs.docker.com/develop/develop-images/dockerfile_best-practices/

---

# 3. Advanced — `docker build`, `docker image ls`, `docker compose up`

**前提知識:** コンテナ起動・ログ確認・コンテナ内部確認・ファイルコピーの基本

## なぜ重要か
ここからが「使う側」から「作る側」へのステップです。  
実アプリ開発では、単に既存イメージを起動するだけでなく、

- アプリ用イメージを自分で作る
- チームで同じビルド手順を共有する
- Web + DB など複数サービスをまとめて起動する

ことが必要です。これができると、開発・CI・本番で一貫した流れを作りやすくなります。

## コアコマンド解説

### `docker build`
`Dockerfile` からイメージを作成します。

```bash
docker build -t my-node-app:dev .
```

- `-t`: イメージ名とタグ
- `.`: ビルドコンテキスト

### `docker image ls`
ローカルのイメージ一覧を確認します。

```bash
docker image ls
```

### `docker compose up`
複数サービスをまとめて起動します。

```bash
docker compose up --build
```

- `--build`: 必要なら先にビルド

## アプリ開発での使われ方
Docker公式ベストプラクティスに沿うと、重要なのは次の点です。

- 小さく明確な `Dockerfile` を保つ
- 不要ファイルを `.dockerignore` で除外する
- 秘密情報をイメージに焼き込まない
- 依存関係レイヤーを活かしてビルドキャッシュを効かせる
- 1コンテナ1責務を意識する

特に secrets は要注意です。  
`ENV API_KEY=...` のように `Dockerfile` や Compose に直書きすると、イメージ履歴や設定から漏れるリスクがあります。機密値は secrets 機構や安全な環境注入方法を使うべきです。

## 30〜60分ミニラボ
**目標:** Node.jsアプリをビルドし、Composeで起動する

### 1) 作業ディレクトリ作成

```bash
mkdir docker-magazine-lab
cd docker-magazine-lab
```

### 2) `app.js` を作成

```js
const http = require('http');
const port = 3000;

http.createServer((req, res) => {
  res.writeHead(200, {'Content-Type': 'text/plain'});
  res.end('Hello from Docker Magazine!\n');
}).listen(port, () => {
  console.log(`Server running on port ${port}`);
});
```

### 3) `Dockerfile` を作成

```Dockerfile
FROM node:22-alpine
WORKDIR /app
COPY app.js .
EXPOSE 3000
CMD ["node", "app.js"]
```

### 4) `.dockerignore` を作成

```gitignore
.git
node_modules
npm-debug.log
.env
```

### 5) ビルド

```bash
docker build -t my-node-app:dev .
```

### 6) 単体起動

```bash
docker run --name my-node-app -d -p 3000:3000 my-node-app:dev
```

確認:

```bash
docker logs my-node-app
curl http://localhost:3000
```

### 7) `compose.yaml` を作成

```yaml
services:
  app:
    build: .
    ports:
      - "3000:3000"
```

### 8) Composeで起動

先に同名コンテナがあれば停止・削除:

```bash
docker stop my-node-app
docker rm my-node-app
```

その後:

```bash
docker compose up --build
```

## コマンドチートシート

```bash
docker build -t <image>:<tag> .
docker image ls
docker compose up
docker compose up --build
docker compose down
docker compose logs
docker compose ps
```

## よくあるミスと安全策
- ビルドコンテキストに不要ファイルを入れすぎる
  - `.dockerignore` を使う
- `latest` タグ前提で運用する
  - 意図したタグを明示する
- secret を `Dockerfile`, `compose.yaml`, `.env` の扱い不備で漏らす
  - イメージに焼き込まない。公開リポジトリへ置かない
- コンテナ内変更を「完成版」だと思う
  - 必ず `Dockerfile` / Compose / ソースに反映する
- rootで動かす前提の設計
  - 可能なら非rootユーザー利用を検討する

### 危険コマンドへの注意
以下は便利ですが、削除系で影響範囲が広いです。実行前に対象を確認してください。

```bash
docker rm -f <container>
docker rmi <image>
docker system prune
docker image prune
docker container prune
```

**注意:**
- `prune` 系は未使用リソースをまとめて削除します
- 開発中の停止コンテナや未使用イメージも消えることがあります
- 共有マシンや作業途中の環境では特に慎重に

安全確認の例:

```bash
docker ps -a
docker image ls
docker system df
```

## 面接っぽい質問
`.dockerignore` はなぜ重要ですか？ その役割を、ビルド速度・セキュリティ・イメージ管理の観点から説明してください。

## 次の一歩
- Build images with Dockerfile  
  https://docs.docker.com/build/concepts/dockerfile/
- Dockerfile best practices  
  https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Docker Compose overview  
  https://docs.docker.com/compose/
- Compose file reference  
  https://docs.docker.com/reference/compose-file/
- Multi-stage builds  
  https://docs.docker.com/build/building/multi-stage/

---

# 今日のまとめ
- **Beginner:** `run`, `ps`, `logs` で「起動して観察する」
- **Middle:** `exec`, `inspect`, `cp` で「中身を理解して調べる」
- **Advanced:** `build`, `image ls`, `compose up` で「再現可能な開発環境を作る」

Dockerは「コマンド暗記」より、**再現性・安全性・チーム開発との相性**で理解すると実務に強くなります。  
次回は、今日の流れを土台に **ボリューム・ネットワーク・キャッシュ最適化** へ進むと伸びやすいです。
