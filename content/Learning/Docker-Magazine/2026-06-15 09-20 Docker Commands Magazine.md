[[Home]]

# 2026-06-15 09-20 Docker Commands Magazine

#docker #containers #devops #learning #daily

## 今日のテーマ
**Dockerfile と `docker build` を使って、安全に再現可能なアプリ開発環境を作る**

**Level:** Beginner → Middle → Advanced

---

## 1) Topic + Level

### Beginner
**テーマ:** `docker build` と Dockerfile の基本を理解する

### Middle
**テーマ:** レイヤーキャッシュ・`.dockerignore`・マルチステージビルドで開発効率と安全性を上げる

**前提知識:**
- `docker run` / `docker ps` / `docker logs` を使ったことがある
- イメージとコンテナの違いをざっくり理解している
- 基本的な Linux コマンド（`cd`, `ls`, `cat`）が分かる

### Advanced
**テーマ:** 実務向けに build context・タグ戦略・秘密情報の扱い・安全なイメージ運用を設計する

**前提知識:**
- Dockerfile を1回以上書いたことがある
- マルチステージビルドの目的を説明できる
- 開発用と本番用で設定を分ける必要性を理解している

---

## 2) Why it matters for real app development

アプリ開発では「自分のPCでは動くのに、CI や本番では動かない」が頻出する。Dockerfile を使うと、

- 依存関係をコードとして固定できる
- チーム全員で同じ開発環境を再現できる
- CI/CD で同じ手順をそのまま流せる
- 本番デプロイ前にコンテナ単位で検証できる
- 不要なツールを含まない小さいイメージを作りやすい

つまり Dockerfile は、**「動く環境を文章ではなく定義ファイルとして残す」** ための実務の土台。

---

## 3) Core Docker command explanations

### `docker build -t myapp:dev .`
現在のディレクトリを build context として Dockerfile を読み、`myapp:dev` というタグ名でイメージを作る。

- `-t` はタグ付け
- `.` は build context
- context には **そのディレクトリ以下のファイルが Docker デーモンに送られる**

**重要:** `.` を雑に使うと、不要ファイルや秘密情報まで build context に入る危険がある。`.dockerignore` はほぼ必須。

### `docker image ls`
ローカルにあるイメージ一覧を確認する。

### `docker run --rm -p 3000:3000 myapp:dev`
作ったイメージからコンテナを起動する。

- `--rm`: 停止後にコンテナを自動削除
- `-p 3000:3000`: ホスト3000番をコンテナ3000番へ公開

### `docker build --no-cache -t myapp:clean .`
キャッシュを使わずに最初からビルドする。依存解決や Dockerfile の変更確認に便利。

### `docker inspect <image-or-container>`
イメージやコンテナの詳細を JSON で確認する。設定確認やデバッグに強い。

### `docker history <image>`
イメージの各レイヤーを確認する。どの命令でサイズが増えたかを見やすい。

---

## 4) How Docker is used while building apps

docs.docker.com のベストプラクティスに沿うと、開発中の Docker 利用はだいたいこうなる。

### A. 依存を定義ファイルで固定する
例: Node.js なら `package.json` / `package-lock.json` を先にコピーし、依存インストールのキャッシュを効かせる。

```Dockerfile
FROM node:22-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
CMD ["npm", "start"]
```

これで、ソースコードだけ変わった場合は `npm ci` レイヤーを再利用しやすい。

### B. `.dockerignore` で不要物を送らない
例えば以下を除外する。

```gitignore
node_modules
.git
.env
coverage
*.log
```

これでビルドが速くなり、秘密情報や巨大ファイルの混入も減る。

### C. マルチステージビルドで本番イメージを軽くする
ビルドに必要なツールと、本番実行に必要なファイルを分離する。

```Dockerfile
FROM node:22-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:22-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev
COPY --from=build /app/dist ./dist
CMD ["node", "dist/server.js"]
```

### D. 秘密情報をイメージに焼き込まない
やってはいけない例:

```Dockerfile
ENV API_KEY=super-secret-key
```

これはイメージ履歴や設定に残る可能性がある。秘密情報は

- 実行時環境変数
- Docker Compose の安全な設定
- Secret 管理機構

で扱うべき。**`.env` をそのまま image に COPY しない。**

---

## 5) 30-60 minute hands-on mini lab

### 目的
シンプルな Web コンテナを Dockerfile から作り、`.dockerignore` とマルチステージの意味を体感する。

### 所要時間
40〜50分

### 手順

#### Step 1: 作業フォルダ作成
```bash
mkdir -p ~/tmp/docker-magazine-lab
cd ~/tmp/docker-magazine-lab
```

#### Step 2: `index.html` を作る
```bash
cat > index.html <<'EOF'
<!doctype html>
<html>
  <head>
    <meta charset="utf-8">
    <title>Docker Magazine Lab</title>
  </head>
  <body>
    <h1>Hello from Docker build lab</h1>
    <p>This page is served from a container.</p>
  </body>
</html>
EOF
```

#### Step 3: Dockerfile を作る
```bash
cat > Dockerfile <<'EOF'
FROM nginx:stable-alpine
WORKDIR /usr/share/nginx/html
COPY index.html ./index.html
EXPOSE 80
EOF
```

#### Step 4: `.dockerignore` を作る
```bash
cat > .dockerignore <<'EOF'
.git
.env
node_modules
*.log
EOF
```

#### Step 5: イメージをビルド
```bash
docker build -t docker-mag-lab:1 .
```

#### Step 6: コンテナ起動
```bash
docker run --rm -d --name docker-mag-lab -p 8080:80 docker-mag-lab:1
```

#### Step 7: 動作確認
```bash
curl http://localhost:8080
```
ブラウザで `http://localhost:8080` を開いてもいい。

#### Step 8: イメージの中身を観察
```bash
docker image ls
docker history docker-mag-lab:1
docker inspect docker-mag-lab:1
```

#### Step 9: 変更して再ビルド
`index.html` の文言を変えてから再度ビルド。
```bash
docker build -t docker-mag-lab:2 .
```

#### Step 10: 安全に停止
```bash
docker stop docker-mag-lab
```

### 発展課題
- `COPY . .` に変えて build context の意味を考える
- `.env` ファイルを置いて `.dockerignore` で除外されるか確認する
- `docker build --no-cache -t docker-mag-lab:nocache .` を試す

---

## 6) Command cheatsheet

```bash
# Dockerfile からイメージを作る
docker build -t myapp:dev .

# キャッシュなしで再ビルド
docker build --no-cache -t myapp:clean .

# イメージ一覧
docker image ls

# イメージ詳細
docker inspect myapp:dev

# レイヤー履歴
docker history myapp:dev

# コンテナ起動
docker run --rm -p 3000:3000 myapp:dev

# バックグラウンド起動
docker run -d --name myapp -p 3000:3000 myapp:dev

# ログ確認
docker logs myapp

# 停止
docker stop myapp
```

---

## 7) Common mistakes and safe practices

### よくあるミス 1: `COPY . .` を無邪気に使う
問題:
- `.git`
- `.env`
- ローカルの秘密ファイル
- 巨大な `node_modules`

まで image build context に含まれることがある。

**安全策:** 必ず `.dockerignore` を置く。

### よくあるミス 2: 秘密情報を Dockerfile に書く
問題:
- `ENV SECRET=...`
- `ARG TOKEN=...`
- `.env` を `COPY`

は漏えいリスクが高い。

**安全策:** シークレットは実行時注入。イメージに埋め込まない。

### よくあるミス 3: 1つのイメージに何でも入れる
問題:
- ビルドツール
- デバッグツール
- 本番に不要な依存

が混在すると image が肥大化し、攻撃面も増える。

**安全策:** マルチステージビルドで本番イメージを最小化。

### よくあるミス 4: タグを雑に運用する
問題:
`latest` だけ運用すると、いつのビルドか追いにくい。

**安全策:** `app:2026-06-15`, `app:1.2.3`, `app:gitsha` のように意味あるタグを付ける。

### よくあるミス 5: 破壊的なクリーンアップを軽く打つ
以下は便利だが危険。

```bash
docker system prune
docker image prune -a
docker rmi -f <image>
docker rm -f <container>
```

**警告:** 未使用だと思っていたイメージや停止中コンテナを消して、検証環境やキャッシュを壊すことがある。

**安全策:**
- まず `docker ps -a` と `docker image ls` を確認
- 何が消えるか理解してから実行
- 共有開発環境では特に慎重に

---

## 8) One interview-style question

**質問:**
`COPY package*.json ./` → `RUN npm ci` → `COPY . .` という順番が Dockerfile でよく使われるのはなぜですか？

**考えるポイント:**
- レイヤーキャッシュ
- ビルド時間短縮
- ソース変更時の再利用性
- 再現性の高い依存管理

---

## 9) Next-step resources

- Docker Build overview  
  https://docs.docker.com/build/

- Best practices for writing Dockerfiles  
  https://docs.docker.com/develop/develop-images/dockerfile_best-practices/

- Multi-stage builds  
  https://docs.docker.com/build/building/multi-stage/

- .dockerignore file  
  https://docs.docker.com/build/concepts/context/#dockerignore-files

- Image tagging best practices  
  https://docs.docker.com/reference/cli/docker/image/tag/

- Docker Compose overview  
  https://docs.docker.com/compose/

---

## まとめ
今日は **Dockerfile と `docker build` を実務目線で扱う基礎** がテーマ。

大事なのは以下の3つ。

1. `docker build` は単なるビルドコマンドではなく、**再現可能な開発環境を作る入口**
2. `.dockerignore` とマルチステージビルドは、**速度・安全性・軽量化** に直結する
3. 秘密情報や破壊的 cleanup コマンドは、**便利さより事故防止を優先** する

明日以降はこの流れで、Compose・ボリューム・ネットワーク・デバッグ・イメージ配布へ進むと実務感がぐっと増す。