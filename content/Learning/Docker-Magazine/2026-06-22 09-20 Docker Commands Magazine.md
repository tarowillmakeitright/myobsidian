---
tags:
  - docker
  - containers
  - devops
  - learning
  - daily
---

[[Home]]

# Daily Docker Commands Magazine — 2026-06-22

#docker #containers #devops #learning #daily

Docker を「コマンド暗記」で終わらせず、実際のアプリ開発で安全に使えるようにするための実践号です。今日は **Beginner → Middle → Advanced** の 3 段階で、コンテナの基本操作から、開発での実用、そして安全な運用判断までをつなげます。

---

## 1) Topic + Level

### Beginner
**テーマ:** `docker run`, `docker ps`, `docker logs`, `docker exec` でコンテナを理解する

### Middle
**テーマ:** `docker build`, `docker image`, `docker compose up` で開発環境を組み立てる  
**前提知識:** `docker run` でコンテナ起動経験があること / イメージとコンテナの違いがわかること

### Advanced
**テーマ:** キャッシュ・レイヤー・ボリューム・安全なクリーンアップを理解して、開発フローを改善する  
**前提知識:** Dockerfile を一度書いたことがあること / Compose で複数サービスを立ち上げたことがあること

---

## 2) Why it matters for real app development

Docker は「自分の PC では動くのに、他の人の環境では動かない」を減らします。

実アプリ開発で重要なのは次の点です。

- **環境差分を減らせる**: Node.js, Python, PostgreSQL などのバージョン差異を吸収しやすい
- **オンボーディングが速い**: 新メンバーが `docker compose up` で開発開始しやすい
- **CI/CD とそろえやすい**: ローカル・CI・本番の差を減らしやすい
- **依存関係を分離できる**: ホスト OS を汚しにくい
- **再現性が高い**: バグ調査やレビューがしやすい

Docker の価値は「コンテナを動かせること」ではなく、**チーム開発の再現性・安全性・速度を上げること**にあります。

---

## 3) Core Docker command explanations

### Beginner コマンド

#### `docker run`
イメージから新しいコンテナを作って起動します。

```bash
docker run --name webtest -d -p 8080:80 nginx
```

ポイント:
- `--name`: コンテナ名を付ける
- `-d`: バックグラウンド起動
- `-p 8080:80`: ホスト 8080 → コンテナ 80 を公開

#### `docker ps`
起動中のコンテナ一覧を見ます。

```bash
docker ps
```

停止済みも含めるなら:

```bash
docker ps -a
```

#### `docker logs`
コンテナの標準出力・標準エラーを見る基本コマンドです。

```bash
docker logs webtest
```

追従するなら:

```bash
docker logs -f webtest
```

#### `docker exec`
起動中コンテナの中でコマンドを実行します。

```bash
docker exec -it webtest sh
```

用途:
- 設定ファイル確認
- アプリ内部のファイル確認
- 一時的なデバッグ

注意:
- コンテナ内で手作業修正しても、再作成で消えることが多い
- 恒久修正は Dockerfile や設定ファイル側で行う

---

### Middle コマンド

#### `docker build`
Dockerfile からイメージを作成します。

```bash
docker build -t myapp:dev .
```

ポイント:
- `-t`: イメージ名:タグ
- `.`: ビルドコンテキスト

#### `docker image ls`
ローカルのイメージ一覧を表示します。

```bash
docker image ls
```

#### `docker compose up`
複数サービスをまとめて起動します。

```bash
docker compose up -d
```

代表例:
- app
- db
- redis

ログ確認:

```bash
docker compose logs -f
```

停止:

```bash
docker compose down
```

---

### Advanced コマンド

#### `docker volume ls`
永続化ボリュームの一覧を確認します。

```bash
docker volume ls
```

#### `docker inspect`
コンテナやイメージの詳細情報を JSON で確認できます。

```bash
docker inspect webtest
```

用途:
- マウント確認
- IP/ネットワーク確認
- 環境変数確認

#### `docker system df`
Docker が使っているディスク容量を確認します。

```bash
docker system df
```

#### `docker builder prune`
ビルドキャッシュの掃除です。

```bash
docker builder prune
```

**警告:** 削除系コマンドです。キャッシュ再利用が減って次回ビルドが遅くなることがあります。実行前に影響を理解してください。

---

## 4) How Docker is used while building apps (docs.docker.com best practices aligned)

Docker 公式のベストプラクティスに沿うと、開発中は次の考え方が重要です。

### 1. 小さく明確な Dockerfile を保つ
- 不要なパッケージを入れすぎない
- 1 コンテナ 1 主責務を意識する
- 目的のはっきりしたベースイメージを使う

### 2. レイヤーキャッシュを意識する
依存関係のインストールを、ソースコード全体コピーより前に置くと再ビルドが速くなります。

例:

```dockerfile
FROM node:22-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
CMD ["npm", "start"]
```

こうすると、アプリコード変更だけなら `npm ci` を毎回やり直しにくくなります。

### 3. `.dockerignore` を必ず使う
不要ファイルをビルドコンテキストに含めないのが大事です。

例:

```gitignore
node_modules
.git
.env
coverage
.dist
```

特に `.env` や秘密情報をコンテキストに入れないこと。

### 4. 秘密情報をイメージに焼き込まない
やってはいけない例:
- Dockerfile に API キー直書き
- `COPY . .` で `.env` を巻き込む
- Compose ファイルに本番秘密情報を平文で残す

安全寄りの考え方:
- 開発用でも秘密情報をイメージに含めない
- 実行時の環境変数や安全なシークレット管理機構を使う
- サンプルは `.env.example` を使う

### 5. イミュータブルな前提で扱う
コンテナ内を手で直すより、
- Dockerfile
- compose.yaml
- アプリコード
に変更を戻すほうが再現性が高いです。

### 6. 開発では Compose、本番では責務を分ける
ローカル開発で:
- app
- db
- cache
を Compose でつなぐのは非常に実用的です。

ただし本番では、
- 永続化
- ログ
- シークレット
- ネットワーク
- ヘルスチェック
をもっと厳密に扱う必要があります。

---

## 5) 30-60 minute hands-on mini lab

### ラボ名
**Node.js アプリを Docker で動かし、Compose で再現性ある開発環境を作る**

### 目標
- 単体コンテナを起動する
- Dockerfile を作る
- Compose で app を起動する
- ログ確認と安全な停止を覚える

### 所要時間
約 45 分

### 手順

#### Step 1: 作業フォルダ作成

```bash
mkdir docker-mini-lab
cd docker-mini-lab
```

#### Step 2: アプリ作成

`server.js`

```javascript
const http = require('http');
const port = 3000;

const server = http.createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'text/plain' });
  res.end('Hello from Docker lab!\n');
});

server.listen(port, () => {
  console.log(`Server running on port ${port}`);
});
```

`package.json`

```json
{
  "name": "docker-mini-lab",
  "version": "1.0.0",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  }
}
```

#### Step 3: Dockerfile 作成

```dockerfile
FROM node:22-alpine
WORKDIR /app
COPY package.json ./
RUN npm install --omit=dev
COPY server.js ./
EXPOSE 3000
CMD ["npm", "start"]
```

#### Step 4: `.dockerignore` 作成

```gitignore
node_modules
.git
.env
npm-debug.log
```

#### Step 5: イメージをビルド

```bash
docker build -t docker-mini-lab:dev .
```

#### Step 6: コンテナ起動

```bash
docker run --name docker-mini-lab -d -p 3000:3000 docker-mini-lab:dev
```

#### Step 7: 動作確認

```bash
curl http://localhost:3000
```

期待結果:

```text
Hello from Docker lab!
```

#### Step 8: ログ確認

```bash
docker logs docker-mini-lab
```

#### Step 9: Compose 化

`compose.yaml`

```yaml
services:
  app:
    build:
      context: .
    ports:
      - "3000:3000"
```

起動:

```bash
docker compose up -d --build
```

ログ:

```bash
docker compose logs -f
```

停止:

```bash
docker compose down
```

#### Step 10: 振り返り

確認したいこと:
- `docker run` と `docker compose up` の役割の違い
- なぜ `.dockerignore` が必要か
- なぜコンテナ内手修正より Dockerfile 修正が良いか

---

## 6) Command cheatsheet

```bash
# イメージをビルド
docker build -t myapp:dev .

# コンテナ起動
docker run --name myapp -d -p 3000:3000 myapp:dev

# 起動中コンテナ確認
docker ps

# 全コンテナ確認
docker ps -a

# ログ確認
docker logs -f myapp

# コンテナ内に入る
docker exec -it myapp sh

# イメージ一覧
docker image ls

# Compose 起動
docker compose up -d

# Compose ログ
docker compose logs -f

# Compose 停止
docker compose down

# ボリューム一覧
docker volume ls

# 詳細確認
docker inspect myapp

# 使用容量確認
docker system df
```

削除系コマンドは特に注意:

```bash
# 危険: 停止コンテナ削除
docker rm <container>

# 危険: イメージ削除
docker rmi <image>

# 危険: 未使用リソース一括削除
docker system prune
```

**実行前に必ず対象を確認**してください。`-f` を安易に付けないこと。

---

## 7) Common mistakes and safe practices

### よくあるミス

#### 1. `COPY . .` で秘密情報まで入れる
- `.env`
- SSH キー
- API キー入り設定

これはかなり危険です。`.dockerignore` で除外し、秘密情報は実行時に渡す前提にします。

#### 2. コンテナの中を直して満足する
再作成で消えるので、根本修正になりません。Dockerfile・Compose・アプリコードを直すべきです。

#### 3. ベースイメージを何となく選ぶ
重すぎるイメージや不要パッケージ入りイメージは、ビルド時間・セキュリティ面で不利です。

#### 4. `latest` に依存しすぎる
意図しない更新が入って再現性が崩れることがあります。必要に応じてタグを明示します。

#### 5. 削除コマンドを雑に使う
- `docker system prune`
- `docker image prune -a`
- `docker rm -f`
- `docker rmi -f`

これらは便利ですが、学習中ほど事故りやすいです。

### 安全な実践

- 削除前に `docker ps -a` / `docker image ls` / `docker volume ls` で対象確認
- まずは `inspect`, `logs`, `system df` で観察してから削除判断
- 開発用の秘密情報でもイメージに焼き込まない
- Compose ファイルに本番シークレットを平文で置かない
- 不要なポート公開を避ける
- 最小権限・最小構成を意識する

---

## 8) One interview-style question

**質問:**  
`docker run` と `docker exec` の違いを説明してください。また、開発中にコンテナ内部を直接変更する運用がなぜ推奨されにくいのかも答えてください。

**考えるポイント:**
- 新規コンテナ作成 vs 既存コンテナへのコマンド実行
- 再現性
- Infrastructure as Code 的な考え方

---

## 9) Next-step resources

まずは公式を優先。

- Docker Get Started  
  https://docs.docker.com/get-started/

- Dockerfile best practices  
  https://docs.docker.com/develop/develop-images/dockerfile_best-practices/

- Building best practices  
  https://docs.docker.com/build/building/best-practices/

- Compose overview  
  https://docs.docker.com/compose/

- Persisting container data / volumes  
  https://docs.docker.com/get-started/docker-concepts/running-containers/persisting-container-data/

- Multi-container applications  
  https://docs.docker.com/get-started/docker-concepts/running-containers/multi-container-applications/

- Image tag and publish basics  
  https://docs.docker.com/get-started/docker-concepts/building-images/build-tag-and-publish-an-image/

---

## 今日のひとこと

Docker は「とりあえず動かす」段階から、**安全に再現できる開発環境を作る**段階に進むと一気に価値が出ます。  
今日のゴールは、コマンドを覚えることではなく、**なぜそのコマンドをその順で使うのか**を理解することです。
