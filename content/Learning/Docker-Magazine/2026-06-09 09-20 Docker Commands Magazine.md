---
tags:
  - docker
  - containers
  - devops
  - learning
  - daily
---

[[Home]]

# 2026-06-09 09:20 Docker Commands Magazine

## 今日のテーマ
**Dockerコマンド実践誌: `docker run` / `docker exec` / `docker logs` / `docker build` を軸に、開発から運用前確認までを段階的に学ぶ**

---

# Beginner — `docker run` で開発用コンテナを正しく起動する

## 1) Topic + Level
**Topic:** `docker run` の基本と、安全な開発コンテナ起動
**Level:** Beginner

## 2) Why it matters for real app development
アプリ開発では「自分のPCでは動くのに、他の環境では動かない」を減らすことが重要です。`docker run` を理解すると、Node.js、Python、PostgreSQL、Redis などの依存環境を素早く再現でき、ローカル開発・検証・チーム共有が安定します。

## 3) Core Docker command explanations
### `docker run`
イメージから新しいコンテナを作成して起動します。

よく使う例:
```bash
docker run --name hello-nginx -d -p 8080:80 nginx:latest
```

主要オプション:
- `--name`: コンテナ名を付ける
- `-d`: バックグラウンド実行
- `-p 8080:80`: ホストの8080番をコンテナの80番へ公開
- `nginx:latest`: 使用するイメージ

補助コマンド:
```bash
docker ps
docker stop hello-nginx
docker start hello-nginx
docker rm hello-nginx
```

## 4) How Docker is used while building apps
Docker公式のベストプラクティスに沿うと、開発中は以下の使い方が実践的です。
- ローカルに直接ミドルウェアを大量インストールせず、コンテナで依存関係を分離する
- 明示的なバージョンタグを使う（例: `nginx:1.27`, `node:22-alpine`）
- 一時確認用コンテナと、継続利用する開発用コンテナを分けて考える
- ポート公開は必要最小限にする
- コンテナ内に秘密情報を焼き込まない

## 5) 30-60 minute hands-on mini lab
### ミニラボ: Nginx を立てて動作確認する
所要時間: 30分前後

1. Nginxコンテナを起動
```bash
docker run --name hello-nginx -d -p 8080:80 nginx:1.27
```

2. 起動確認
```bash
docker ps
```

3. ブラウザで確認
- `http://localhost:8080`

4. ログ確認
```bash
docker logs hello-nginx
```

5. 停止と削除
```bash
docker stop hello-nginx
docker rm hello-nginx
```

発展:
- `-p 127.0.0.1:8080:80` に変えて、ローカルホストだけへ公開する
- `nginx:latest` と固定タグ運用の違いを確認する

## 6) Command cheatsheet
```bash
docker run --name app -d -p 8080:80 nginx:1.27
docker ps
docker ps -a
docker stop app
docker start app
docker rm app
docker logs app
```

## 7) Common mistakes and safe practices
### よくあるミス
- `latest` を当然の前提として使う
- 不要に `0.0.0.0` へポート公開する
- 停止せずに同名コンテナを再作成しようとする
- コンテナ削除前に必要なデータを確認しない

### 安全策
- できるだけ固定タグを使う
- 公開ポートは最小限にする
- 学習用でも `--name` を付けて管理しやすくする
- 削除前に `docker ps -a` で対象確認

## 8) One interview-style question
`docker run -p 8080:80 nginx` の `8080:80` は何を意味しますか？ また、なぜ開発環境でポート公開範囲を最小化すべきですか？

## 9) Next-step resources
- Docker docs: <https://docs.docker.com/get-started/docker-concepts/running-containers/>
- Port publishing: <https://docs.docker.com/get-started/docker-concepts/running-containers/publishing-ports/>
- Docker CLI reference (`docker run`): <https://docs.docker.com/reference/cli/docker/container/run/>

---

# Middle — `docker exec` / `docker logs` で開発中のトラブルを調べる

## 1) Topic + Level
**Topic:** コンテナ内調査とログ確認
**Level:** Middle

**Prerequisites:**
- `docker run` でコンテナ起動できる
- `docker ps`, `docker stop`, `docker rm` を使える

## 2) Why it matters for real app development
アプリ開発では「コンテナは起動したがアプリが落ちる」「依存パッケージは入っているのか」「環境変数は読まれているのか」といった確認が頻繁に発生します。`docker exec` と `docker logs` を使えると、ローカル開発やCI前の自己診断が速くなります。

## 3) Core Docker command explanations
### `docker logs`
コンテナ標準出力・標準エラー出力を確認します。
```bash
docker logs myapp
docker logs -f myapp
docker logs --tail 100 myapp
```

### `docker exec`
起動中コンテナ内でコマンドを実行します。
```bash
docker exec myapp ls /app
docker exec -it myapp sh
```

主要ポイント:
- `-it`: 対話的シェル
- `sh` または `bash`: イメージ次第で使える方が違う
- 実行中の状態確認に便利だが、恒久修正は Dockerfile 側で行うべき

## 4) How Docker is used while building apps
実務では、`docker exec` は原因調査には便利ですが、手作業でコンテナ内を変更して終わる運用は再現性を壊します。Docker公式の考え方に沿うなら:
- 変更は Dockerfile や compose 設定に戻す
- ログは標準出力へ出す設計を優先する
- デバッグで得た知見をイメージ定義へ反映する
- `exec` は診断用、構成管理はコードで行う

## 5) 30-60 minute hands-on mini lab
### ミニラボ: Node.jsコンテナの中身を調べる
所要時間: 45分前後

1. 作業ディレクトリ作成
```bash
mkdir -p ~/tmp/docker-node-lab
cd ~/tmp/docker-node-lab
```

2. `server.js` を作成
```javascript
const http = require('http');
const port = 3000;
http.createServer((req, res) => {
  console.log(`request: ${req.method} ${req.url}`);
  res.end('hello from docker');
}).listen(port, () => {
  console.log(`server listening on ${port}`);
});
```

3. すぐ試すために bind mount で起動
```bash
docker run --name node-lab -d -p 3000:3000 -v "$PWD":/app -w /app node:22-alpine node server.js
```

4. ログ確認
```bash
docker logs node-lab
docker logs -f node-lab
```

5. 別ターミナルでアクセス
```bash
curl http://localhost:3000
```

6. コンテナ内を確認
```bash
docker exec node-lab ls -la /app
docker exec node-lab ps
```

7. シェルで入る
```bash
docker exec -it node-lab sh
```

8. 終了後クリーンアップ
```bash
docker stop node-lab
docker rm node-lab
```

## 6) Command cheatsheet
```bash
docker logs myapp
docker logs -f myapp
docker logs --tail 50 myapp
docker exec myapp env
docker exec myapp ls /app
docker exec -it myapp sh
```

## 7) Common mistakes and safe practices
### よくあるミス
- `docker exec` で入って手修正し、そのまま解決した気になる
- ログを見ずに再起動を繰り返す
- シークレットを環境変数一覧で雑に露出させる
- 開発用mountのつもりが本番相当で同じ設定を使ってしまう

### 安全策
- 再現した修正は必ず Dockerfile や compose に戻す
- ログは `--tail` や `-f` で必要範囲を確認する
- `docker exec myapp env` の出力共有に注意する
- 秘密情報はイメージへCOPYしない、composeファイルへ直書きしない

## 8) One interview-style question
`docker exec` は便利ですが、なぜ本番問題の恒久対応としては不十分なのでしょうか？ 再現性の観点から説明してください。

## 9) Next-step resources
- Docker logs reference: <https://docs.docker.com/reference/cli/docker/container/logs/>
- Docker exec reference: <https://docs.docker.com/reference/cli/docker/container/exec/>
- Bind mounts: <https://docs.docker.com/engine/storage/bind-mounts/>

---

# Advanced — `docker build` で再現性の高い開発イメージを作る

## 1) Topic + Level
**Topic:** Dockerfile と `docker build` の実践
**Level:** Advanced

**Prerequisites:**
- `docker run`, `docker logs`, `docker exec` を使える
- コンテナとイメージの違いを理解している
- 基本的なアプリ実行フローを説明できる

## 2) Why it matters for real app development
本格的なアプリ開発では、手動で `docker run` するだけでは足りません。CI/CD、チーム開発、レビュー環境、セキュリティスキャンまで考えると、Dockerfileで再現可能なイメージを作ることが重要です。`docker build` を理解すると、「誰がどこで作っても同じ成果物」を作りやすくなります。

## 3) Core Docker command explanations
### `docker build`
Dockerfileからイメージを作成します。
```bash
docker build -t my-node-app:0.1.0 .
```

よく使うオプション:
- `-t`: イメージ名とタグ
- `-f`: Dockerfileの場所を指定
- `.`: ビルドコンテキスト

確認コマンド:
```bash
docker images
docker history my-node-app:0.1.0
```

## 4) How Docker is used while building apps
Docker公式ベストプラクティスに沿うと、開発用イメージ作成では以下が重要です。
- 小さく保つ: 不要ファイルを `.dockerignore` で除外
- レイヤーを意識: 依存インストールとアプリコピー順を工夫してキャッシュ活用
- 1コンテナ1責務を基本に考える
- 秘密情報を `ARG` や `COPY` で焼き込まない
- ベースイメージは信頼できるものを選び、固定タグやdigestも検討する

## 5) 30-60 minute hands-on mini lab
### ミニラボ: 小さなNode.jsアプリのイメージを作る
所要時間: 45〜60分

1. 作業ディレクトリ作成
```bash
mkdir -p ~/tmp/docker-build-lab
cd ~/tmp/docker-build-lab
```

2. `server.js` を作成
```javascript
const http = require('http');
const port = 3000;
http.createServer((req, res) => {
  res.end('built with docker');
}).listen(port, () => {
  console.log(`server listening on ${port}`);
});
```

3. `package.json` を作成
```json
{
  "name": "docker-build-lab",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "start": "node server.js"
  }
}
```

4. `.dockerignore` を作成
```gitignore
node_modules
npm-debug.log
.git
.env
```

5. `Dockerfile` を作成
```dockerfile
FROM node:22-alpine
WORKDIR /app
COPY package.json ./
COPY server.js ./
EXPOSE 3000
CMD ["npm", "start"]
```

6. イメージをビルド
```bash
docker build -t docker-build-lab:0.1.0 .
```

7. コンテナ起動
```bash
docker run --name docker-build-lab -d -p 3000:3000 docker-build-lab:0.1.0
```

8. 動作確認
```bash
curl http://localhost:3000
docker logs docker-build-lab
```

9. 片付け
```bash
docker stop docker-build-lab
docker rm docker-build-lab
```

追加課題:
- `COPY . .` を安易に使わず、必要ファイルのみコピーする違いを考える
- `.env` を `.dockerignore` に入れる理由を説明する
- イメージサイズや `docker history` を確認する

## 6) Command cheatsheet
```bash
docker build -t myapp:0.1.0 .
docker images
docker history myapp:0.1.0
docker run --name myapp -d -p 3000:3000 myapp:0.1.0
docker logs myapp
docker stop myapp
docker rm myapp
```

## 7) Common mistakes and safe practices
### よくあるミス
- `.dockerignore` を作らず、不要ファイルや秘密情報をビルドコンテキストへ含める
- `COPY . .` を無条件で使う
- イメージの中へ `.env` や認証鍵を入れてしまう
- キャッシュ効率を考えず、毎回フルビルドになるDockerfileを書く

### 安全策
- `.dockerignore` を必ず用意する
- シークレットは build context やイメージへ入れない
- ベースイメージの出所とタグを確認する
- ビルド後に `docker history` やファイル構成を見直す

## 8) One interview-style question
Dockerfileで `COPY package.json ./` を先に行い、その後にアプリ本体をコピーする構成がよく使われるのはなぜですか？ キャッシュ効率の観点から説明してください。

## 9) Next-step resources
- Docker build overview: <https://docs.docker.com/build/>
- Dockerfile best practices: <https://docs.docker.com/develop/develop-images/dockerfile_best-practices/>
- Dockerfile reference: <https://docs.docker.com/reference/dockerfile/>
- .dockerignore: <https://docs.docker.com/build/concepts/context/#dockerignore-files>

---

# 破壊的コマンドへの注意
以下は便利ですが、学習中に雑に使うと事故りやすいです。

## 要注意コマンド
```bash
docker container prune
docker image prune -a
docker system prune -a
docker rm -f <container>
docker rmi <image>
```

### 注意点
- 未使用と思っていたコンテナ・イメージ・ネットワーク・ビルドキャッシュを消すことがある
- 他の開発中プロジェクトへ影響することがある
- `-a` や `-f` は特に危険

### 安全な進め方
- まず `docker ps -a` と `docker images` で対象確認
- 消す理由を明確にする
- 共有環境や継続開発環境では即実行しない
- prune系は出力内容を読んでから実行する

---

# 今日のひとこと
Dockerは「動かす」だけでなく、「再現する」「調べる」「安全に片付ける」までが実務です。`run → logs/exec → build` の流れを体で覚えると、一気に開発が安定します。
