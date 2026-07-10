---
tags:
  - docker
  - containers
  - devops
  - learning
  - daily
---

[[Home]]

# Docker Commands Magazine — 2026-07-10

今日のテーマは **Docker イメージ最適化と安全なコンテナ実行**。  
学習アークとして **Beginner → Middle → Advanced** の順で、同じ「実アプリ開発でそのまま使う」流れに寄せて進めます。

---

## 1) Beginner — `docker run` / `docker ps` / `docker logs` の基本

### 1) Topic + Level
**Topic:** コンテナを起動・確認・観察する基本コマンド  
**Level:** Beginner

### 2) Why it matters for real app development
アプリ開発では、まず「ローカルで同じ実行環境をすぐ再現できる」ことが重要です。`docker run` で依存環境を素早く立ち上げ、`docker ps` で状態確認、`docker logs` でトラブルシュートできると、開発初期の検証速度がかなり上がります。

たとえば:
- API サーバーの動作確認
- PostgreSQL / Redis などの依存サービス起動
- チーム内での環境差分の吸収

### 3) Core Docker command explanations
#### `docker run`
イメージから新しいコンテナを作成して起動します。

```bash
docker run --name hello-nginx -d -p 8080:80 nginx:stable
```

- `--name hello-nginx`: コンテナ名を付ける
- `-d`: バックグラウンド起動
- `-p 8080:80`: ホストの 8080 をコンテナの 80 に転送
- `nginx:stable`: 使用するイメージ

#### `docker ps`
起動中コンテナを一覧表示します。

```bash
docker ps
```

停止済みも含めたい場合:

```bash
docker ps -a
```

#### `docker logs`
コンテナ標準出力・標準エラー出力を確認します。

```bash
docker logs hello-nginx
```

追尾する場合:

```bash
docker logs -f hello-nginx
```

### 4) How Docker is used while building apps
Docker 公式のベストプラクティスに沿うと、開発中は次の考え方が実用的です。

- 1コンテナ1責務を意識する
- コンテナは「使い捨て可能」に設計する
- ログはファイルではなく標準出力へ出す
- コンテナ内部を手でいじって維持するのではなく、設定は Dockerfile や Compose でコード化する

つまり、**手作業で直すより、再現可能な定義に落とす**のが大事です。

### 5) 30-60 minute hands-on mini lab
**目標:** Nginx コンテナを起動し、状態確認とログ確認まで行う

1. Nginx を起動

```bash
docker run --name hello-nginx -d -p 8080:80 nginx:stable
```

2. コンテナ一覧確認

```bash
docker ps
```

3. ブラウザで確認  
`http://localhost:8080`

4. ログ確認

```bash
docker logs hello-nginx
```

5. 停止

```bash
docker stop hello-nginx
```

6. 停止後の状態確認

```bash
docker ps -a
```

### 6) Command cheatsheet
```bash
docker run --name app -d -p 8080:80 nginx:stable
docker ps
docker ps -a
docker logs app
docker logs -f app
docker stop app
docker start app
```

### 7) Common mistakes and safe practices
**よくあるミス**
- `-p` を付け忘れて外からアクセスできない
- コンテナ名未指定で管理しづらくなる
- ログの見方が分からず、原因調査が止まる

**安全な運用**
- 検証用でも公開ポートは最小限にする
- 不要に root 前提で運用しない
- 本番相当データを雑にコンテナへ入れない

### 8) One interview-style question
`docker run` と `docker start` の違いを説明してください。

### 9) Next-step resources
- Docker Get Started  
  https://docs.docker.com/get-started/
- Running containers  
  https://docs.docker.com/get-started/docker-concepts/running-containers/
- Viewing container logs  
  https://docs.docker.com/reference/cli/docker/container/logs/

---

## 2) Middle — Dockerfile と `docker build` でアプリをイメージ化する

### Prerequisites
- `docker run`, `docker ps`, `docker logs` を使える
- ポート公開の意味を理解している
- Node.js または Python の簡単なアプリ構造を見たことがある

### 1) Topic + Level
**Topic:** Dockerfile を使ってアプリ実行イメージを作る  
**Level:** Middle

### 2) Why it matters for real app development
チーム開発では「誰のマシンでも同じ手順・同じ依存関係で動く」ことが重要です。Dockerfile があると、ローカル開発・CI・検証環境で同一のビルド手順を共有できます。

さらに、Dockerfile の質はそのまま以下に効きます。
- ビルド時間
- セキュリティ
- イメージサイズ
- デプロイの安定性

### 3) Core Docker command explanations
#### `docker build`
Dockerfile からイメージを作成します。

```bash
docker build -t demo-node-app:1.0 .
```

- `-t`: イメージに名前とタグを付与
- `.`: ビルドコンテキスト

#### `docker images`
ローカルにあるイメージを確認します。

```bash
docker images
```

#### `docker exec`
起動中コンテナの中でコマンドを実行します。

```bash
docker exec -it demo-node sh
```

### 4) How Docker is used while building apps
Docker 公式ベストプラクティスでは、Dockerfile で特に次が重要です。

- 軽量なベースイメージを選ぶ
- `.dockerignore` を使って不要ファイルを送らない
- ビルドキャッシュを活かす順序で `COPY` / `RUN` を並べる
- イメージに秘密情報を埋め込まない
- 必要ならマルチステージビルドを使う

典型例は、依存ファイルだけ先に `COPY` して `npm install` し、その後ソースコードをコピーする構成です。これで変更時の再ビルドが速くなります。

### 5) 30-60 minute hands-on mini lab
**目標:** 小さな Node.js アプリを Dockerfile からビルドして起動する

#### `app.js`
```js
const http = require('http');
const server = http.createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'text/plain' });
  res.end('Hello from Docker!\n');
});
server.listen(3000, () => console.log('Server running on 3000'));
```

#### `package.json`
```json
{
  "name": "demo-node-app",
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
RUN npm install --omit=dev
COPY app.js ./
EXPOSE 3000
CMD ["npm", "start"]
```

#### 実行手順
1. イメージをビルド

```bash
docker build -t demo-node-app:1.0 .
```

2. コンテナ起動

```bash
docker run --name demo-node -d -p 3000:3000 demo-node-app:1.0
```

3. 動作確認

```bash
curl http://localhost:3000
```

4. コンテナ内部確認

```bash
docker exec -it demo-node sh
```

### 6) Command cheatsheet
```bash
docker build -t demo-node-app:1.0 .
docker images
docker run --name demo-node -d -p 3000:3000 demo-node-app:1.0
docker exec -it demo-node sh
docker logs demo-node
docker stop demo-node
```

### 7) Common mistakes and safe practices
**よくあるミス**
- `COPY . .` を早い段階で置き、キャッシュが効かずビルドが遅い
- `.env` や秘密鍵をビルドコンテキストに含める
- `latest` タグ頼みで再現性が落ちる

**安全な運用**
- `.dockerignore` を必ず用意する
- シークレットはイメージに焼き込まない
- 依存ベースイメージは定期的に更新する
- 可能なら固定タグを使う

### 8) One interview-style question
なぜ `COPY package.json ./` を先に行い、その後でアプリ本体を `COPY` する設計が多いのでしょうか。

### 9) Next-step resources
- Dockerfile best practices  
  https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Build concepts  
  https://docs.docker.com/build/concepts/overview/
- Dockerfile reference  
  https://docs.docker.com/reference/dockerfile/

---

## 3) Advanced — マルチステージビルドと安全なクリーンアップ

### Prerequisites
- Dockerfile と `docker build` を使ったことがある
- イメージサイズやビルド時間の課題を感じたことがある
- 開発用依存と本番用依存の違いを理解している

### 1) Topic + Level
**Topic:** マルチステージビルドで本番向けイメージを最適化し、不要リソースを安全に整理する  
**Level:** Advanced

### 2) Why it matters for real app development
本番運用では、イメージサイズが大きいと:
- デプロイが遅い
- 脆弱性スキャン対象が増える
- 攻撃面が広がる
- CI/CD の転送コストが上がる

マルチステージビルドは、ビルド用ツールと実行用成果物を分離できるため、**小さく・安全で・配布しやすいイメージ**に直結します。

### 3) Core Docker command explanations
#### `docker build --target`
マルチステージの途中段階までビルドして確認できます。

```bash
docker build --target builder -t demo-app-builder .
```

#### `docker image ls`
イメージ一覧を確認します。

```bash
docker image ls
```

#### `docker system df`
Docker が使っているディスク量を確認します。

```bash
docker system df
```

#### `docker image prune`
未使用イメージを削除します。  
**注意:** 削除系コマンドは本当に不要なものか確認してから使ってください。

```bash
docker image prune
```

**破壊的注意**
- `docker system prune`
- `docker image prune -a`
- `docker rm -f ...`
- `docker rmi ...`

これらは未使用資産や停止コンテナ、ネットワーク、イメージを消す可能性があります。共有環境や作業途中のローカル環境では、対象確認なしに実行しないでください。

### 4) How Docker is used while building apps
Docker 公式ベストプラクティスと整合する実務ポイント:

- ビルド用ステージと本番実行ステージを分ける
- 本番イメージにコンパイラや不要ツールを残さない
- シークレットを `ENV` や `COPY` で埋め込まない
- イメージを immutable artifact として扱う
- クリーンアップ前に `docker ps -a` / `docker image ls` / `docker system df` で現状確認する

### 5) 30-60 minute hands-on mini lab
**目標:** マルチステージビルドを試し、ビルド用イメージと本番用イメージの違いを観察する

#### `Dockerfile`
```Dockerfile
FROM node:22-alpine AS builder
WORKDIR /app
COPY package.json ./
RUN npm install
COPY app.js ./

FROM node:22-alpine AS runtime
WORKDIR /app
COPY --from=builder /app /app
EXPOSE 3000
CMD ["node", "app.js"]
```

#### 実行手順
1. 本番向けイメージをビルド

```bash
docker build -t demo-node-app:multi .
```

2. builder ステージ単体も確認

```bash
docker build --target builder -t demo-node-app:builder .
```

3. サイズ比較

```bash
docker image ls | grep demo-node-app
```

4. ディスク使用量確認

```bash
docker system df
```

5. 不要なイメージ整理前に一覧確認

```bash
docker image ls
docker ps -a
```

6. 必要なら慎重にクリーンアップ

```bash
docker image prune
```

### 6) Command cheatsheet
```bash
docker build -t demo-node-app:multi .
docker build --target builder -t demo-node-app:builder .
docker image ls
docker system df
docker ps -a
docker image prune
```

### 7) Common mistakes and safe practices
**よくあるミス**
- 本番イメージにビルドツール一式を残す
- 開発用依存をそのまま本番へ持ち込む
- `docker system prune -a` を意味を理解せず実行する
- Compose や Dockerfile に秘密情報を直書きする

**安全な運用**
- クリーンアップ前に対象確認
- 共有マシンでは削除コマンドを特に慎重に扱う
- 秘密情報は secret manager / 環境注入方式を検討する
- 本番イメージは最小権限・最小構成を意識する

### 8) One interview-style question
マルチステージビルドは、セキュリティとパフォーマンスの両面でどんな利点がありますか。

### 9) Next-step resources
- Multi-stage builds  
  https://docs.docker.com/build/building/multi-stage/
- Image best practices  
  https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Docker CLI reference  
  https://docs.docker.com/reference/cli/docker/
- Prune reference  
  https://docs.docker.com/reference/cli/docker/system/prune/

---

## Quick Recap
- Beginner では **起動・確認・ログ観察** を固める
- Middle では **Dockerfile で再現可能なビルド** を作る
- Advanced では **マルチステージビルドと安全な整理** を身につける

今日の実務メッセージはシンプルです。  
**Docker は「動かす」だけでなく、「再現可能に定義し、安全に小さく保つ」と価値が出る。**
