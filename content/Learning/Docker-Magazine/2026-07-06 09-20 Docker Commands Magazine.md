---
tags:
  - docker
  - containers
  - devops
  - learning
  - daily
---

[[Home]]

# 2026-07-06 Docker Commands Magazine

> 今日のテーマは **Docker の基本実行フロー** を軸に、Beginner → Middle → Advanced の学習アークで段階的に理解を深める構成です。実務で「イメージを作る・動かす・調べる・安全に片付ける」までを一連で扱います。

---

## 1) Topic + Level

### Beginner
**トピック:** `docker run`, `docker ps`, `docker logs`, `docker exec` でコンテナを使い始める

### Middle
**トピック:** `docker build`, `Dockerfile`, `.dockerignore`, ボリュームとポート公開の実践
**前提条件:**
- Beginner の内容を理解している
- Linux の基本コマンド（`cd`, `ls`, `cat`）を少し使える
- Web アプリが「ソースコード + 依存関係 + 実行環境」で動くことを知っている

### Advanced
**トピック:** マルチステージビルド、イメージ最適化、非 root 実行、秘密情報をイメージに入れない運用
**前提条件:**
- Middle の内容を理解している
- Dockerfile を読んで簡単な修正ができる
- 開発環境と本番環境で要件が違うことを理解している

---

## 2) Why it matters for real app development

Docker は「自分のPCでは動くのに、他の環境では動かない」を減らすための実務道具です。

実アプリ開発で特に重要なのは次の点です。

- **再現性**: 開発者ごとの差異を減らせる
- **依存関係の固定**: Node / Python / Java などのバージョン差異事故を防ぎやすい
- **オンボーディング短縮**: 新メンバーがすぐ動かせる
- **CI/CDとの相性**: ビルド成果物をイメージとして同じ形で流せる
- **本番寄り検証**: ローカルで本番に近い実行条件を再現しやすい

Docker をただ「コンテナを起動するもの」としてではなく、**アプリの配布単位と実行環境を一緒に管理する仕組み**として理解すると実務で強いです。

---

## 3) Core Docker command explanations

### `docker run`
コンテナを新規作成して起動します。

```bash
docker run hello-world
```

よく使うオプション:

- `--name` : コンテナ名を付ける
- `-d` : バックグラウンド実行
- `-p HOST:CONTAINER` : ポート公開
- `-v HOST:CONTAINER` : ボリュームマウント
- `--rm` : 停止後にコンテナを自動削除
- `-it` : 対話シェルを開く
- `--env` / `--env-file` : 環境変数を渡す

例:

```bash
docker run --name webtest -d -p 8080:80 nginx:alpine
```

### `docker ps`
起動中コンテナを確認します。

```bash
docker ps
```

停止済みも含めるなら:

```bash
docker ps -a
```

### `docker logs`
コンテナの標準出力・標準エラー出力を確認します。

```bash
docker logs webtest
```

追尾表示:

```bash
docker logs -f webtest
```

### `docker exec`
起動中コンテナの中でコマンドを実行します。

```bash
docker exec -it webtest sh
```

### `docker build`
Dockerfile からイメージを作成します。

```bash
docker build -t myapp:dev .
```

### `docker images`
ローカルにあるイメージ一覧を確認します。

```bash
docker images
```

### `docker inspect`
コンテナやイメージの詳細情報を JSON で確認します。

```bash
docker inspect webtest
```

### `docker stop` / `docker rm`
コンテナを止める・削除する基本操作です。

```bash
docker stop webtest
docker rm webtest
```

> 注意: `docker rm -f` は強制停止＋削除です。調査中のコンテナや未保存の状態を消す可能性があるので、対象を確認してから使うこと。

### `docker rmi`
イメージを削除します。

```bash
docker rmi myapp:dev
```

> 注意: タグ違い・依存中のイメージを巻き込むと再ビルドが必要になります。消してよいものか確認してから実行。

### `docker system prune`
未使用リソースを一括削除します。

```bash
docker system prune
```

> **警告:** 便利ですが破壊的です。未使用コンテナ・ネットワーク・ビルドキャッシュなどを削除します。`-a` や `--volumes` を付ける前に、何が消えるか必ず理解してから使うこと。

---

## 4) How Docker is used while building apps

Docker の公式ドキュメントに沿った実務的な使い方の要点は次の通りです。

### 4-1. 小さく、明確な Dockerfile を書く
- ベースイメージは必要最小限にする
- 何をコピーして何を実行するかを明示する
- 不要なファイルを `.dockerignore` で除外する

例:

```dockerfile
FROM node:22-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
```

### 4-2. キャッシュを活かす順番で書く
依存関係ファイルを先にコピーして `npm ci` し、その後ソースコードをコピーするのが定番です。

理由:
- コード変更だけなら依存関係レイヤーを再利用できる
- ビルド時間が短くなりやすい

### 4-3. `.dockerignore` を必ず使う
例:

```gitignore
node_modules
.git
.env
coverage
dist
```

これにより:
- ビルドコンテキストが小さくなる
- 機密ファイルの混入リスクを下げる
- ビルドが速くなる

### 4-4. 秘密情報をイメージに焼き込まない
**やってはいけない例:**
- Dockerfile に API キーを `ENV` で直書き
- `.env` をそのまま `COPY` する
- Compose ファイルに本番秘密情報をベタ書きする

安全な考え方:
- 実行時に環境変数や秘密情報管理基盤から注入する
- リポジトリに秘密情報を置かない
- イメージは配布可能な成果物、秘密は外から渡す

### 4-5. 非 root 実行を優先する
可能ならアプリは root ではなく専用ユーザーで動かします。

理由:
- コンテナ侵害時の被害範囲を減らしやすい
- セキュリティレビューで説明しやすい

### 4-6. 開発と本番の目的を分ける
- 開発: ホットリロード、デバッグしやすさ
- 本番: 小さい、速い、攻撃面が少ない

この差を吸収するのに、**マルチステージビルド**や環境ごとの設定分離が有効です。

---

## 5) 30-60 minute hands-on mini lab

### ゴール
Node.js の簡単な Web アプリを Docker でビルド・起動し、ログ確認、コンテナ内確認、安全な停止まで一通り実施する。

### 所要時間
30〜60分

### 準備
以下の 3 ファイルを作ります。

#### `app.js`
```js
const http = require('http');
const port = process.env.PORT || 3000;

const server = http.createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'text/plain; charset=utf-8' });
  res.end('Docker mini lab is running\n');
});

server.listen(port, () => {
  console.log(`server listening on ${port}`);
});
```

#### `package.json`
```json
{
  "name": "docker-mini-lab",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "start": "node app.js"
  }
}
```

#### `Dockerfile`
```dockerfile
FROM node:22-alpine
WORKDIR /app
COPY package.json ./
COPY app.js ./
EXPOSE 3000
CMD ["npm", "start"]
```

#### `.dockerignore`
```gitignore
node_modules
.git
.env
npm-debug.log
```

### 手順

#### Step 1. イメージをビルド
```bash
docker build -t docker-mini-lab:1 .
```

確認:
```bash
docker images
```

#### Step 2. コンテナを起動
```bash
docker run --name docker-mini-lab -d -p 3000:3000 docker-mini-lab:1
```

確認:
```bash
docker ps
```

#### Step 3. ブラウザまたは curl で疎通確認
```bash
curl http://localhost:3000
```

期待結果:
```text
Docker mini lab is running
```

#### Step 4. ログを見る
```bash
docker logs docker-mini-lab
```

#### Step 5. コンテナ内を確認
```bash
docker exec -it docker-mini-lab sh
```

中で確認:
```sh
pwd
ls -la
exit
```

#### Step 6. 環境変数でポートを変えてみる（追加課題）
別コンテナとして:

```bash
docker run --name docker-mini-lab-2 -d -e PORT=3001 -p 3001:3001 docker-mini-lab:1
```

確認:
```bash
curl http://localhost:3001
```

#### Step 7. 安全に停止・削除
```bash
docker stop docker-mini-lab docker-mini-lab-2
docker rm docker-mini-lab docker-mini-lab-2
```

必要ならイメージ削除:

```bash
docker rmi docker-mini-lab:1
```

> 注意: `docker rmi` は後で再ビルドが必要になるので、学習途中なら残しておいてもよいです。

### 発展課題
- `COPY . .` に変えた場合の違いを考える
- `.dockerignore` を外したときのリスクを確認する
- `USER node` を追加できるか試す
- マルチステージビルド版 Dockerfile を書いてみる

---

## 6) Command cheatsheet

```bash
# イメージをビルド
docker build -t myapp:dev .

# コンテナ起動
docker run --name myapp -d -p 3000:3000 myapp:dev

# 起動中コンテナ確認
docker ps

# 停止済みも含めて確認
docker ps -a

# ログ確認
docker logs myapp
docker logs -f myapp

# コンテナ内でシェル実行
docker exec -it myapp sh

# 環境変数付き起動
docker run --name myapp2 -e PORT=3001 -p 3001:3001 myapp:dev

# コンテナ停止
docker stop myapp

# コンテナ削除
docker rm myapp

# イメージ一覧
docker images

# イメージ削除（要注意）
docker rmi myapp:dev

# 未使用リソース掃除（要注意）
docker system prune
```

---

## 7) Common mistakes and safe practices

### よくあるミス

1. **`.env` や秘密情報をイメージに入れてしまう**
   - Dockerfile の `COPY . .` で事故が起きやすい

2. **`latest` タグ前提で運用する**
   - 再現性が下がる
   - 明示的なタグ利用が安全

3. **コンテナとイメージの違いを混同する**
   - イメージはテンプレート
   - コンテナは実行インスタンス

4. **`docker exec` で手作業修正して満足する**
   - その変更はコンテナ削除で消える
   - 永続化すべき変更は Dockerfile やマウント元へ反映する

5. **不要な root 実行**
   - セキュリティ上のリスクが上がる

6. **破壊的クリーンアップを雑に実行する**
   - `docker system prune -a --volumes`
   - `docker rm -f ...`
   - `docker rmi ...`
   これらは学習環境でも被害が出やすい

### 安全な実践

- まず `docker ps -a` と `docker images` で対象確認
- 削除前に「今使っていないか」を確認
- 秘密情報はイメージに含めず、実行時注入にする
- Dockerfile は小さく保ち、不要ファイルを送らない
- 可能なら非 root ユーザーで実行する
- ベースイメージは信頼できるものを選び、更新状況も気にする
- 本番向けでは healthcheck、最小権限、依存更新を意識する

---

## 8) One interview-style question

**質問:**
`docker run -p 8080:3000 myapp:dev` の `8080:3000` は何を意味し、アプリがコンテナ内で `3000` 番ポートを listen しているのにブラウザでは `http://localhost:8080` でアクセスできるのはなぜですか？

**考えるポイント:**
- ホストポートとコンテナポートの違い
- コンテナネットワークの基本
- ポート公開が必要な理由

---

## 9) Next-step resources

まずは公式を軸に進めるのが堅いです。

- Docker Get Started
  - https://docs.docker.com/get-started/
- Dockerfile リファレンス
  - https://docs.docker.com/reference/dockerfile/
- イメージ作成のベストプラクティス
  - https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- ボリューム
  - https://docs.docker.com/engine/storage/volumes/
- コンテナの実行
  - https://docs.docker.com/engine/containers/run/
- Docker CLI リファレンス
  - https://docs.docker.com/reference/cli/docker/
- Compose の概要
  - https://docs.docker.com/compose/
- Build cache / build 改善
  - https://docs.docker.com/build/cache/
- マルチステージビルド
  - https://docs.docker.com/build/building/multi-stage/
- シークレットの扱い（Build secrets 含む）
  - https://docs.docker.com/build/building/secrets/

---

## まとめ

今日の焦点は、Docker を「ただ起動するコマンド集」ではなく、**実務の開発・検証・配布を支える土台**として掴むことです。

- Beginner: まずは `run / ps / logs / exec`
- Middle: `build`, `Dockerfile`, `.dockerignore`, ポート/ボリューム
- Advanced: マルチステージ、最適化、非 root、秘密情報の分離

この順で積むと、ローカル開発から CI/CD・本番運用まで自然につながります。