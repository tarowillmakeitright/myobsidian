---
tags:
  - docker
  - containers
  - devops
  - learning
  - daily
---

# 2026-07-07 09:20 Docker Commands Magazine

[[Home]]

#docker #containers #devops #learning #daily

## 今日のテーマ
**Dockerコマンドを軸に、アプリ開発で本当に使う基本運用を段階的に学ぶ**

---

# Issue 1 — Beginner
## Topic + Level
**テーマ:** `docker run` / `docker ps` / `docker logs` / `docker exec` の基本  
**Level:** Beginner

## なぜ実務で重要か
アプリ開発では「とりあえずローカルで動かす」「依存関係をホストに汚さず試す」「不具合時にログを見る」が日常です。Dockerの基本コマンドを理解しておくと、開発環境の再現性が上がり、チーム内で「自分の環境だけ動かない」を減らせます。

## コアDockerコマンド解説
### 1. `docker run`
コンテナを起動します。
```bash
docker run --name web-demo -d -p 8080:80 nginx
```
- `--name web-demo`: コンテナ名を付ける
- `-d`: バックグラウンド起動
- `-p 8080:80`: ホストの8080番をコンテナの80番へ転送
- `nginx`: 使用するイメージ

### 2. `docker ps`
起動中のコンテナを確認します。
```bash
docker ps
```
停止中も含めるなら:
```bash
docker ps -a
```

### 3. `docker logs`
コンテナの標準出力・標準エラーを確認します。
```bash
docker logs web-demo
```
追尾するなら:
```bash
docker logs -f web-demo
```

### 4. `docker exec`
起動中コンテナの中でコマンドを実行します。
```bash
docker exec -it web-demo sh
```
- `-it`: 対話シェル用
- `sh`: コンテナ内シェル

## アプリ開発での使い方
Docker公式のベストプラクティスに沿うと、開発時は「1コンテナ1責務」を基本にしつつ、使い捨て可能な実行環境として扱うのが重要です。

実務イメージ:
- フロントエンド開発者が `nginx` や `node` の動作確認を行う
- バックエンド開発者がローカルにDBを直接入れずにコンテナで立てる
- 障害調査時に `docker logs` や `docker exec` で中を確認する

ベストプラクティス上の意識:
- コンテナ内データは永続ではない前提で扱う
- 設定はイメージに焼き込まず、環境変数やマウントで分離する
- 秘密情報（APIキー、DBパスワード）をDockerfileやcomposeファイルへ直書きしない

## 30–60分ミニラボ
### 目標
Nginxコンテナを起動し、アクセス確認・ログ確認・コンテナ内確認まで行う。

### 手順
1. Nginxを起動
```bash
docker run --name web-demo -d -p 8080:80 nginx
```

2. 起動確認
```bash
docker ps
```

3. ブラウザでアクセス
- `http://localhost:8080`

4. ログ確認
```bash
docker logs web-demo
```

5. コンテナ内部に入る
```bash
docker exec -it web-demo sh
```

6. コンテナ内でファイル確認
```sh
ls /usr/share/nginx/html
cat /usr/share/nginx/html/index.html
exit
```

7. 停止
```bash
docker stop web-demo
```

8. 削除
```bash
docker rm web-demo
```

## コマンドチートシート
```bash
docker run --name NAME -d -p HOST_PORT:CONTAINER_PORT IMAGE
docker ps
docker ps -a
docker logs CONTAINER
docker logs -f CONTAINER
docker exec -it CONTAINER sh
docker stop CONTAINER
docker rm CONTAINER
```

## よくあるミスと安全な運用
- **ミス:** `-p` を付け忘れて外から見えない  
  → `docker ps` でポート公開を確認する
- **ミス:** 停止しただけで消えたと思い込む  
  → `docker ps -a` で残骸を確認する
- **ミス:** コンテナ内変更を永続化したつもりになる  
  → コンテナ再作成で消える前提を理解する
- **安全策:** 初学時でも `--name` を必ず付ける
- **安全策:** 公開ポートは必要最小限にする

## 面接っぽい質問
`docker run -d -p 8080:80 nginx` の `8080:80` は何を意味し、開発時にどんな利点がありますか？

## 次の一歩リソース
- Docker Get Started  
  https://docs.docker.com/get-started/
- Running containers  
  https://docs.docker.com/get-started/docker-concepts/running-containers/
- Viewing container logs  
  https://docs.docker.com/reference/cli/docker/container/logs/

---

# Issue 2 — Middle
## Topic + Level
**テーマ:** `docker build` / `docker images` / `docker tag` とDockerfileの基本設計  
**Level:** Middle

**Prerequisites:**
- `docker run`, `docker ps`, `docker logs` の基本が分かる
- コンテナとイメージの違いをざっくり説明できる

## なぜ実務で重要か
実務で本当に大事なのは「誰のPCでも同じビルドができること」です。Dockerfileを使えば、アプリの実行環境をコードとして管理できます。CI/CDでもそのまま使えるため、ローカル検証と本番の差分を減らせます。

## コアDockerコマンド解説
### 1. `docker build`
Dockerfileからイメージを作成します。
```bash
docker build -t my-node-app:dev .
```
- `-t`: イメージ名とタグ
- `.`: ビルドコンテキスト

### 2. `docker images`
ローカルにあるイメージ一覧を確認します。
```bash
docker images
```

### 3. `docker tag`
既存イメージに別名やバージョンタグを付けます。
```bash
docker tag my-node-app:dev my-node-app:v1
```

## アプリ開発での使い方
Docker公式のベストプラクティスでは、Dockerfileは以下を意識すると運用しやすくなります。

- 公式・信頼できるベースイメージを使う
- 余計なファイルをビルドコンテキストに含めない（`.dockerignore` を使う）
- レイヤーキャッシュを意識して依存ファイルを先にコピーする
- イメージへ秘密情報を埋め込まない
- 可能なら軽量なベースイメージを検討する

Node.jsアプリの典型例:
1. `package*.json` を先にコピー
2. `npm install` 実行
3. ソースコードをコピー
4. 起動コマンド定義

こうすると、コード変更だけでは依存インストール層を再利用でき、ビルドが速くなります。

## 30–60分ミニラボ
### 目標
簡単なNode.jsアプリをDockerfileからビルドして起動する。

### 作業用ファイル
#### `app.js`
```js
const http = require('http');
const port = 3000;

http.createServer((req, res) => {
  res.writeHead(200, {'Content-Type': 'text/plain; charset=utf-8'});
  res.end('Hello from Dockerized Node app\n');
}).listen(port, () => {
  console.log(`Server running on port ${port}`);
});
```

#### `package.json`
```json
{
  "name": "docker-magazine-demo",
  "version": "1.0.0",
  "main": "app.js",
  "scripts": {
    "start": "node app.js"
  }
}
```

#### `Dockerfile`
```Dockerfile
FROM node:22-alpine
WORKDIR /app
COPY package.json ./
RUN npm install
COPY app.js ./
EXPOSE 3000
CMD ["npm", "start"]
```

#### `.dockerignore`
```gitignore
node_modules
npm-debug.log
.git
```

### 手順
1. イメージをビルド
```bash
docker build -t my-node-app:dev .
```

2. イメージ確認
```bash
docker images
```

3. コンテナ起動
```bash
docker run --name my-node-app -d -p 3000:3000 my-node-app:dev
```

4. 動作確認
- `http://localhost:3000`

5. ログ確認
```bash
docker logs my-node-app
```

6. 別タグを付与
```bash
docker tag my-node-app:dev my-node-app:v1
```

## コマンドチートシート
```bash
docker build -t IMAGE:TAG .
docker images
docker tag SOURCE_IMAGE:TAG TARGET_IMAGE:TAG
docker run --name NAME -d -p 3000:3000 IMAGE:TAG
docker logs CONTAINER
```

## よくあるミスと安全な運用
- **ミス:** `.dockerignore` を用意せず不要ファイルを大量送信  
  → ビルド遅延・情報混入の原因になる
- **ミス:** `COPY . .` を早い段階で使ってキャッシュ効率を壊す  
  → 依存ファイルを先にコピーする
- **ミス:** `.env` や秘密鍵をイメージに入れる  
  → 秘密情報はランタイム注入する
- **安全策:** ベースイメージは出所を確認する
- **安全策:** タグは `latest` 依存を避け、意味のあるバージョンを使う

## 面接っぽい質問
Dockerfileで `package.json` を先に `COPY` してから `npm install` するのはなぜですか？

## 次の一歩リソース
- Building images  
  https://docs.docker.com/get-started/docker-concepts/building-images/
- Dockerfile reference  
  https://docs.docker.com/reference/dockerfile/
- Best practices for writing Dockerfiles  
  https://docs.docker.com/develop/develop-images/dockerfile_best-practices/

---

# Issue 3 — Advanced
## Topic + Level
**テーマ:** `docker compose up` / `docker compose logs` / `docker compose exec` で複数サービス開発を回す  
**Level:** Advanced

**Prerequisites:**
- Dockerfileを書いて `docker build` できる
- ポート公開・ログ確認・コンテナ内調査の基本が分かる
- アプリとDBを別プロセスで分ける意味を理解している

## なぜ実務で重要か
本番アプリは単体コンテナで完結しないことがほとんどです。Webアプリ、DB、キャッシュ、ワーカーなど複数サービスが連携します。Docker Composeを使うと、開発環境をコードでまとめて管理でき、オンボーディングや検証が一気に楽になります。

## コアDockerコマンド解説
### 1. `docker compose up`
複数サービスをまとめて起動します。
```bash
docker compose up -d
```
- `-d`: バックグラウンド起動

### 2. `docker compose logs`
サービスごとのログを確認します。
```bash
docker compose logs -f web
```

### 3. `docker compose exec`
指定サービスのコンテナ内でコマンド実行します。
```bash
docker compose exec web sh
```

### 4. `docker compose down`
構成を停止・破棄します。
```bash
docker compose down
```

## アプリ開発での使い方
Docker公式の考え方に沿うなら、Composeは「開発スタック定義」に向いています。

良い使い方:
- `web`, `db` など役割ごとにサービスを分離する
- 永続データはvolumeで分離する
- 環境差分は環境変数やoverrideで扱う
- 機密情報をcomposeファイルへ直書きしない
- ヘルスチェックや依存関係を考慮する

実務では、たとえば以下のように使います。
- 新メンバーが `docker compose up` で即開発開始
- WebアプリとPostgresを同じ定義から再現
- ローカル不具合をチーム全員が同じ手順で再現

## 30–60分ミニラボ
### 目標
Nginx + Redis の2サービス構成をComposeで起動し、ログとコンテナ操作を体験する。

### `compose.yaml`
```yaml
services:
  web:
    image: nginx:latest
    ports:
      - "8081:80"

  cache:
    image: redis:7-alpine
```

### 手順
1. 起動
```bash
docker compose up -d
```

2. 状態確認
```bash
docker compose ps
```

3. Webアクセス
- `http://localhost:8081`

4. Webログ確認
```bash
docker compose logs -f web
```

5. Redisコンテナで確認
```bash
docker compose exec cache redis-cli ping
```
期待結果:
```text
PONG
```

6. 停止と削除
```bash
docker compose down
```

### 余力があれば
volume付きDBサービスを追加し、「コンテナ再作成してもデータは残る」体験まで進める。

## コマンドチートシート
```bash
docker compose up -d
docker compose ps
docker compose logs -f SERVICE
docker compose exec SERVICE sh
docker compose down
```

## よくあるミスと安全な運用
- **ミス:** コンテナ削除とvolume削除を同じ感覚で扱う  
  → `down` と `down -v` は意味が違う
- **ミス:** パスワードを `compose.yaml` に直書きする  
  → `.env` 利用時も管理方法に注意し、機密ファイルをコミットしない
- **ミス:** サービス名解決を理解せず `localhost` で相互接続しようとする  
  → Composeネットワーク内では通常サービス名で接続する
- **安全策:** 開放ポートは最小化する
- **安全策:** volume削除前に本当に消してよいか確認する
- **警告:** 以下は破壊的です。実行前に影響範囲を確認してください。  
  - `docker system prune`
  - `docker image prune -a`
  - `docker rm -f ...`
  - `docker rmi ...`
  - `docker compose down -v`

## 面接っぽい質問
Docker Composeで、アプリコンテナからDBへ接続するときに `localhost` ではなくサービス名を使うべきなのはなぜですか？

## 次の一歩リソース
- Docker Compose overview  
  https://docs.docker.com/compose/
- Compose file reference  
  https://docs.docker.com/reference/compose-file/
- Multi-container applications  
  https://docs.docker.com/get-started/docker-concepts/running-containers/multi-container-applications/

---

# 実務メモ: 今日の学びの要点
- Beginnerでは「起動・確認・ログ・中に入る」を確実にする
- Middleでは「Dockerfileを雑に書かず、再利用しやすく組む」ことを意識する
- Advancedでは「複数サービスをコードで再現し、チーム開発に耐える環境」を作る
- 秘密情報はイメージにもcomposeにも安易に埋め込まない
- `prune` 系や `rm -f`、`rmi` は便利だが破壊的なので、実行前に対象確認を徹底する

# 明日の予告候補
- ボリュームと永続化
- ネットワークの基本
- 開発用Composeと本番用設計の分け方
