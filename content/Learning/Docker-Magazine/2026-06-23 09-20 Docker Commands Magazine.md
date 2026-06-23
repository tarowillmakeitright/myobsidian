---
tags:
  - docker
  - containers
  - devops
  - learning
  - daily
---

[[Home]]

# Docker Commands Magazine — 2026-06-23

今日のテーマは、**Dockerイメージとコンテナの基本操作から、安全なビルド・実行・クリーンアップまでを段階的に学ぶ**ことです。実務でよく使うコマンドを中心に、Beginner → Middle → Advanced の順で進めます。

---

## 1) Beginner — `docker run` / `docker ps` / `docker logs` の基本

### なぜ重要か
アプリ開発では「まず動かす」「動いたものを確認する」「エラーを追う」が最初の基本です。Dockerではこの流れが `docker run` → `docker ps` → `docker logs` に集約されています。ローカル環境差分を減らし、チーム全員が同じ実行条件でアプリを確認しやすくなります。

### コアコマンド解説

#### `docker run`
イメージからコンテナを作成して起動します。

```bash
docker run --name hello-nginx -d -p 8080:80 nginx:stable
```

- `--name hello-nginx`: コンテナ名を付ける
- `-d`: バックグラウンド起動
- `-p 8080:80`: ホスト8080番をコンテナ80番へ公開
- `nginx:stable`: 起動するイメージ

#### `docker ps`
起動中のコンテナ一覧を表示します。

```bash
docker ps
```

停止済みも含めるなら:

```bash
docker ps -a
```

#### `docker logs`
コンテナの標準出力・標準エラーを確認します。

```bash
docker logs hello-nginx
```

追尾表示:

```bash
docker logs -f hello-nginx
```

### アプリ開発での使い方
- Webアプリを仮コンテナで起動して動作確認する
- 開発サーバーの起動エラーをログで追う
- READMEに実行コマンドを固定し、オンボーディングを簡単にする

**Dockerのベストプラクティス寄りの考え方:**
- 使うイメージタグを曖昧にしすぎない（例: `latest` 依存を減らす）
- 起動確認はログとヘルスの両方を意識する
- 必要なポートだけ公開する

### 30〜60分ミニラボ
**目標:** Nginxコンテナを起動し、状態確認とログ確認まで行う。

1. Nginxを起動
   ```bash
   docker run --name hello-nginx -d -p 8080:80 nginx:stable
   ```
2. コンテナ一覧を確認
   ```bash
   docker ps
   ```
3. ブラウザまたは curl で確認
   ```bash
   curl http://localhost:8080
   ```
4. ログ確認
   ```bash
   docker logs hello-nginx
   ```
5. 停止
   ```bash
   docker stop hello-nginx
   ```
6. 停止後も一覧に見えることを確認
   ```bash
   docker ps -a
   ```
7. 後片付け
   ```bash
   docker rm hello-nginx
   ```

### Cheatsheet
```bash
docker run --name app -d -p 8080:80 nginx:stable
docker ps
docker ps -a
docker logs app
docker logs -f app
docker stop app
docker rm app
```

### よくあるミスと安全策
- **ポート競合**: 8080が既に使われていると起動失敗。別ポートを試す
- **停止せず削除しようとする**: `docker rm` 前に `docker stop` を意識
- **ログだけで全部わかると思う**: アプリ側の設定ミスは `docker inspect` やアプリ内部ログも必要なことがある
- **不要な全公開**: `-p 0.0.0.0:...` を安易に使わず、必要最小限にする

### 面接風質問
`docker run -d -p 8080:80 nginx` を実行したあと、ブラウザで確認できない場合、まずどのコマンドをどんな順で確認しますか？

### 次の一歩リソース
- Docker docs: <https://docs.docker.com/get-started/docker-concepts/running-containers/>
- Docker CLI reference (`docker run`): <https://docs.docker.com/reference/cli/docker/container/run/>
- Docker CLI reference (`docker logs`): <https://docs.docker.com/reference/cli/docker/container/logs/>

---

## 2) Middle — `docker build` と Dockerfile の基本

**前提知識:** `docker run`, `docker ps`, `docker logs` が使えること

### なぜ重要か
実務では既製イメージを使うだけでは足りず、自分たちのアプリをイメージ化します。`docker build` と Dockerfile を理解すると、開発環境・CI・本番デプロイで同じ成果物を扱えるようになります。

### コアコマンド解説

#### `docker build`
Dockerfileを使ってイメージを作成します。

```bash
docker build -t my-node-app:dev .
```

- `-t my-node-app:dev`: イメージ名とタグ
- `.`: ビルドコンテキスト

#### `docker images`
ローカルにあるイメージ一覧を表示します。

```bash
docker images
```

#### `docker exec`
起動中コンテナ内でコマンドを実行します。

```bash
docker exec -it my-node-app sh
```

### アプリ開発での使い方
Docker公式のベストプラクティスに沿うなら、次を強く意識します。

- **小さく保つ**: 不要なファイルをビルドコンテキストに入れない
- **`.dockerignore` を使う**: `node_modules`, `.git`, ローカル秘密情報などを送らない
- **レイヤーを意識する**: 依存関係インストールとアプリコードコピーを分けてキャッシュを活かす
- **秘密情報をイメージに埋め込まない**: APIキーや `.env` を `COPY` しない
- **1コンテナ1責務を基本に考える**

### 30〜60分ミニラボ
**目標:** 小さなNode.jsアプリをDockerfileでビルド・起動する。

#### 1. 作業フォルダ準備

`app.js`
```js
const http = require('http');
const port = 3000;
http.createServer((req, res) => {
  res.end('Hello from Docker magazine!\n');
}).listen(port, () => {
  console.log(`Server listening on ${port}`);
});
```

`package.json`
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

`Dockerfile`
```dockerfile
FROM node:22-alpine
WORKDIR /app
COPY package.json ./
RUN npm install --omit=dev
COPY app.js ./
EXPOSE 3000
CMD ["npm", "start"]
```

`.dockerignore`
```gitignore
node_modules
npm-debug.log
.git
.env
```

#### 2. ビルド
```bash
docker build -t docker-magazine-node:dev .
```

#### 3. 起動
```bash
docker run --name docker-magazine-node -d -p 3000:3000 docker-magazine-node:dev
```

#### 4. 動作確認
```bash
curl http://localhost:3000
```

#### 5. ログ確認
```bash
docker logs docker-magazine-node
```

#### 6. コンテナ内確認
```bash
docker exec -it docker-magazine-node sh
```

### Cheatsheet
```bash
docker build -t my-app:dev .
docker images
docker run --name my-app -d -p 3000:3000 my-app:dev
docker exec -it my-app sh
docker logs my-app
```

### よくあるミスと安全策
- **`.env` をCOPYしてしまう**: 機密情報漏えいの原因。秘密情報はイメージに入れない
- **`COPY . .` の乱用**: 不要ファイル混入・キャッシュ効率悪化。まず必要ファイルだけコピー
- **巨大ベースイメージ**: 開発速度とセキュリティの両面で不利。必要最小限の公式イメージを選ぶ
- **root前提の実装**: 本番寄りでは非rootユーザー実行を検討する

### 面接風質問
Dockerfileで `COPY package.json ./` → `RUN npm install` → `COPY app.js ./` の順にする理由を説明してください。

### 次の一歩リソース
- Building best practices: <https://docs.docker.com/build/building/best-practices/>
- Dockerfile reference: <https://docs.docker.com/reference/dockerfile/>
- `.dockerignore` docs: <https://docs.docker.com/build/concepts/context/#dockerignore-files>

---

## 3) Advanced — 安全で実務的なイメージ運用とクリーンアップ

**前提知識:** `docker build`, Dockerfile, `docker exec` の基本を理解していること

### なぜ重要か
長く開発していると、古いイメージ・停止済みコンテナ・未使用ボリューム・キャッシュが溜まります。一方で、雑な掃除は作業中データや再利用できるキャッシュを失う原因になります。上級者ほど「消す前に確認」「秘密を埋め込まない」「再現可能に保つ」が重要です。

### コアコマンド解説

#### `docker image ls`
イメージ一覧を表示します。

```bash
docker image ls
```

#### `docker container ls -a`
全コンテナを確認します。

```bash
docker container ls -a
```

#### `docker system df`
Dockerが使っているディスク容量を確認します。

```bash
docker system df
```

#### `docker rm` / `docker rmi`
コンテナやイメージを削除します。

```bash
docker rm old-container
docker rmi old-image:tag
```

#### `docker system prune`
未使用リソースをまとめて掃除します。

```bash
docker system prune
```

> **警告:** `prune`, `rmi`, `rm -f` 系は破壊的です。何が消えるか必ず確認してから実行してください。特に `-a` や `--volumes` 付きは影響範囲が大きいです。

### アプリ開発での使い方
実務で大事なのは「速さ」と「安全性」の両立です。

- ディスク圧迫時に `docker system df` で現状把握してから掃除する
- CI/CDではタグ運用を明確にし、どのイメージがデプロイ済みか追跡できるようにする
- 本番用イメージにはビルド専用ツールや秘密情報を残さない
- 可能ならマルチステージビルドで実行環境を細くする
- ComposeやDockerfileに平文シークレットを書かない

### 30〜60分ミニラボ
**目標:** 使用状況を確認し、安全に不要リソースを整理する判断を学ぶ。

1. 現状確認
   ```bash
   docker system df
   docker image ls
   docker container ls -a
   ```
2. テスト用コンテナを作成
   ```bash
   docker run --name temp-nginx -d nginx:stable
   docker stop temp-nginx
   ```
3. 停止済みコンテナだけ削除
   ```bash
   docker rm temp-nginx
   ```
4. どのイメージが残っているか確認
   ```bash
   docker image ls
   ```
5. `prune` はまず説明だけ読む
   ```bash
   docker system prune --help
   ```
6. 実行する場合は、**何が消えるか理解してから** 対話付きで行う
   ```bash
   docker system prune
   ```

**発展課題:**
- 自分のNodeアプリDockerfileをマルチステージ化できるか考える
- 開発用タグとリリース用タグの付け方を整理する

### Cheatsheet
```bash
docker system df
docker image ls
docker container ls -a
docker rm <container>
docker rmi <image>
docker system prune
```

### よくあるミスと安全策
- **`docker system prune -a --volumes` を勢いで打つ**: 本当に必要なキャッシュやボリュームまで消える可能性
- **`rm -f` を常用する**: 何が起きたか把握しにくい。通常は段階的に停止→確認→削除
- **シークレットをDockerfileやcomposeに直書き**: イメージ履歴やリポジトリに残る危険
- **タグ運用が雑**: `latest` だけだと追跡困難。環境別・バージョン別の命名を考える

### 面接風質問
`docker system prune` を本番運用中のホストで安易に実行してはいけない理由を説明してください。

### 次の一歩リソース
- Image best practices: <https://docs.docker.com/build/building/best-practices/>
- Multi-stage builds: <https://docs.docker.com/build/building/multi-stage/>
- Docker CLI reference (`system prune`): <https://docs.docker.com/reference/cli/docker/system/prune/>
- Docker security: <https://docs.docker.com/engine/security/>

---

## 今日のまとめ
- **Beginner:** まずは `run`, `ps`, `logs` で「起動・確認・調査」の基本を固める
- **Middle:** `build` と Dockerfile でアプリを再現可能な形にする
- **Advanced:** クリーンアップとイメージ運用は、安全確認と再現性を優先する

明日はこの流れを踏まえて、**ボリューム・バインドマウント・開発効率改善**に進むと実務感がさらに出ます.
