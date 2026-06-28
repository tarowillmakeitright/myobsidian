---
tags:
  - docker
  - containers
  - devops
  - learning
  - daily
---

[[Home]]

# Docker Commands Magazine — 2026-06-28

## 今日のテーマ
**Docker イメージの作成・実行・改善の基本フロー**

今回は、Docker を使ったアプリ開発で最も頻出の流れである **build → run → inspect → iterate** を、難易度を上げながら学ぶ。

---

# Beginner — `docker build` / `docker run` / `docker ps`

## 1) Topic + Level
**Topic:** コンテナ化されたアプリを自分で作って起動する
**Level:** Beginner

## 2) Why it matters for real app development
ローカル開発で「自分の環境では動くのに、他人のPCやCIでは動かない」という問題はよく起きる。Docker を使うと、アプリ実行環境をイメージとして固定できるため、開発・レビュー・CI/CD・本番の差分を減らしやすい。

特に以下で重要:
- 新メンバーの開発環境セットアップ
- CIでの再現性あるビルド
- バージョン違いによる不具合の回避
- 軽量な検証環境の使い捨て

## 3) Core Docker command explanations
### `docker build -t myapp:dev .`
- カレントディレクトリの `Dockerfile` を使ってイメージを作る
- `-t` はタグ付け
- `myapp:dev` は `名前:タグ`

### `docker run --rm -p 8080:3000 myapp:dev`
- イメージからコンテナを起動する
- `--rm` は終了後にコンテナを自動削除
- `-p 8080:3000` はホストの8080番をコンテナの3000番へ転送

### `docker ps`
- 起動中のコンテナ一覧を確認

### `docker logs <container>`
- コンテナの標準出力/標準エラーを見る

## 4) How Docker is used while building apps
Docker公式のベストプラクティスに沿うと、アプリ開発では次が基本になる:
- **1コンテナ1責務**を意識する
- **軽量なベースイメージ**を選ぶ
- **不要なファイルを `.dockerignore` で除外**する
- **イメージは不変**、設定は環境変数や実行時注入で扱う
- **シークレットを Dockerfile やイメージに埋め込まない**

たとえば Node.js アプリなら、`node_modules` や `.git` を build context に含めないだけでもビルド速度と安全性が改善する。

## 5) 30-60 minute hands-on mini lab
### 目標
最小の Web アプリを Docker 化して起動する。

### 手順
1. 作業フォルダを作る
2. `server.js` を作る
3. `Dockerfile` を作る
4. イメージをビルドする
5. コンテナを起動する
6. ログと起動状況を確認する

### 例: `server.js`
```js
const http = require('http');
const port = 3000;

http.createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'text/plain' });
  res.end('Hello from Docker!\n');
}).listen(port, () => {
  console.log(`Server listening on ${port}`);
});
```

### 例: `Dockerfile`
```dockerfile
FROM node:22-alpine
WORKDIR /app
COPY server.js .
EXPOSE 3000
CMD ["node", "server.js"]
```

### 実行コマンド
```bash
docker build -t myapp:dev .
docker run --rm -p 8080:3000 myapp:dev
docker ps
docker logs <container_id>
```

### 確認
- ブラウザで `http://localhost:8080`
- `Hello from Docker!` が表示されれば成功

## 6) Command cheatsheet
```bash
docker build -t myapp:dev .
docker run --rm -p 8080:3000 myapp:dev
docker ps
docker logs <container_id>
docker stop <container_id>
```

## 7) Common mistakes and safe practices
### よくあるミス
- `-p` の左右を逆にする
- アプリが `0.0.0.0` ではなく `localhost` に bind していて外から見えない
- ビルドコンテキストに巨大ファイルを含める
- `latest` タグ前提で挙動を固定してしまう

### 安全な運用
- ベースイメージはなるべく明示タグで固定する
- `--rm` を使って使い捨て検証をきれいに保つ
- 本番向けに root 実行を避ける設計を検討する
- 秘密情報は Dockerfile に書かない

## 8) Interview-style question
`docker run -p 8080:3000 myapp:dev` の `8080` と `3000` はそれぞれ何を意味し、どちらがホスト側か説明してください。

## 9) Next-step resources
- Docker build overview: https://docs.docker.com/build/
- Dockerfile reference: https://docs.docker.com/reference/dockerfile/
- Running containers: https://docs.docker.com/engine/containers/run/

---

# Middle — `docker exec` / `docker inspect` / `docker cp`

## Prerequisites
- `docker build` と `docker run` を使ってコンテナを起動できる
- ポート公開とログ確認の基本を理解している

## 1) Topic + Level
**Topic:** 起動中コンテナの調査とデバッグ
**Level:** Middle

## 2) Why it matters for real app development
実アプリ開発では「起動したけど動かない」「環境変数が違う」「ファイルが入っていない」「アプリは起動しているのに応答しない」といった調査が頻繁に起きる。そこで重要なのが、コンテナの中身・設定・実行状態を安全に観察する力。

## 3) Core Docker command explanations
### `docker exec -it <container> sh`
- 起動中コンテナの中でシェルを開く
- Alpine 系では `sh`、Debian/Ubuntu 系では `bash` が使えることが多い

### `docker inspect <container>`
- コンテナ設定、IP、マウント、環境変数、起動コマンドなどをJSONで確認

### `docker cp <container>:/app/file.txt ./file.txt`
- コンテナとホストの間でファイルをコピーする

### `docker stats`
- CPU・メモリ使用量をざっくり確認

## 4) How Docker is used while building apps
開発中は、コンテナを単に起動するだけでなく、**観測可能性を持たせる**ことが大事。

Docker公式の考え方と相性が良い実践:
- ログは標準出力へ出す
- 設定はイメージに焼かず、実行時に与える
- コンテナ内部の変更を前提にせず、変更は Dockerfile に戻す
- 一時デバッグ後は「なぜ必要だったか」をコードや設定に反映する

つまり、`docker exec` は便利だが、恒久対応は `Dockerfile` やアプリ設定へ戻すのが筋。

## 5) 30-60 minute hands-on mini lab
### 目標
起動中コンテナを調査し、設定やファイルの状態を確認する。

### 手順
1. Beginner のコンテナを起動する
2. `docker inspect` でポート設定を見る
3. `docker exec` で中に入る
4. `/app` 配下を確認する
5. 必要ならコンテナ内ファイルを `docker cp` で取得する

### 実行例
```bash
docker ps
docker inspect <container_id>
docker exec -it <container_id> sh
ls -la /app
cat /app/server.js
exit
docker cp <container_id>:/app/server.js ./server-from-container.js
docker stats
```

### 追加課題
- `docker inspect` の出力からコンテナIPを見つける
- マウント設定がある場合、どのディレクトリが結びついているか読む

## 6) Command cheatsheet
```bash
docker exec -it <container_id> sh
docker inspect <container_id>
docker cp <container_id>:/path/in/container ./local-path
docker stats
docker logs <container_id>
```

## 7) Common mistakes and safe practices
### よくあるミス
- `docker exec` で直した内容を永続化したつもりになる
- `inspect` の情報量に圧倒されて必要箇所を見失う
- コンテナ名とイメージ名を混同する

### 安全な運用
- 調査結果は Dockerfile や Compose 設定に戻して再現可能にする
- 本番環境ではむやみにシェル侵入を前提にしない
- `docker cp` で設定ファイルやログを回収するとき、機密情報の持ち出しに注意する
- 環境変数に秘密情報がある場合、出力共有先を慎重に扱う

## 8) Interview-style question
`docker exec` でコンテナ内のファイルを直接修正した場合、なぜそれを本質的な修正と呼べないのでしょうか。

## 9) Next-step resources
- `docker exec` docs: https://docs.docker.com/reference/cli/docker/container/exec/
- `docker inspect` docs: https://docs.docker.com/reference/cli/docker/inspect/
- Container logs and debugging: https://docs.docker.com/engine/containers/logging/

---

# Advanced — `docker build` 最適化 / レイヤー設計 / 安全なクリーンアップ

## Prerequisites
- Dockerfile を書いてアプリを build/run できる
- 起動中コンテナの調査 (`exec`, `inspect`, `logs`) ができる
- アプリ開発で依存関係やビルド成果物の扱いを理解している

## 1) Topic + Level
**Topic:** Dockerfile の改善、ビルド最適化、安全な後片付け
**Level:** Advanced

## 2) Why it matters for real app development
チーム開発やCIでは、Dockerのビルド時間・イメージサイズ・セキュリティ品質がそのまま開発速度と運用コストに効く。遅いビルド、大きいイメージ、秘密情報混入、雑なクリーンアップは、現場でじわじわ痛い。

## 3) Core Docker command explanations
### `docker build --no-cache -t myapp:clean .`
- キャッシュを使わずに再ビルド
- キャッシュ由来の不整合切り分けに便利

### `docker image ls`
- ローカルのイメージ一覧を確認

### `docker history myapp:dev`
- イメージレイヤーの履歴を見る
- どの命令がサイズに効いているか観察できる

### `docker system df`
- Docker関連ディスク使用量の確認

### 破壊的コマンドへの注意
以下は便利だが、**消してよい対象を確認してから**使うこと。
```bash
docker image prune
docker system prune
docker rm -f <container>
docker rmi <image>
```
- `prune` 系は未使用リソースを広く削除する
- `rm -f` は強制停止＋削除
- `rmi` は参照中イメージ削除に失敗したり、意図しない再取得を招くことがある

## 4) How Docker is used while building apps
Docker公式ベストプラクティスに沿う実践ポイント:
- **レイヤーキャッシュを活かす順序で Dockerfile を書く**
- **マルチステージビルド**で不要な開発ツールを最終イメージへ持ち込まない
- **`.dockerignore` を整える**
- **最終イメージに秘密情報を残さない**
- **コンテナ内変更ではなく宣言的なビルドに寄せる**

### 改善前の例
```dockerfile
FROM node:22
WORKDIR /app
COPY . .
RUN npm install
CMD ["npm", "start"]
```

問題点:
- `COPY . .` が早すぎてキャッシュ効率が悪い
- 開発不要ファイルまで入る可能性がある
- `npm install` が再利用しにくい

### 改善後の例
```dockerfile
FROM node:22-alpine AS base
WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .
CMD ["npm", "start"]
```

さらに本格運用では、ビルド用と実行用を分けるマルチステージ化が有効。

## 5) 30-60 minute hands-on mini lab
### 目標
Dockerfile を改善し、キャッシュ・サイズ・安全性の違いを観察する。

### 手順
1. あえて素朴な Dockerfile を書く
2. 初回ビルド時間を確認する
3. Dockerfile を改善する
4. `.dockerignore` を追加する
5. 再ビルドして差を観察する
6. `docker history` と `docker system df` を確認する

### 例: `.dockerignore`
```gitignore
node_modules
.git
.env
npm-debug.log
Dockerfile*
README.md
```

### 実行コマンド
```bash
docker build -t myapp:v1 .
docker history myapp:v1
docker system df

# Dockerfile / .dockerignore 改善後
docker build -t myapp:v2 .
docker history myapp:v2
docker image ls
```

### 安全なクリーンアップ演習
まず確認してから削除する:
```bash
docker ps -a
docker image ls
docker system df
```
必要なものがないと確認できたら実行:
```bash
# 注意: 未使用リソースを削除する
docker image prune
```
より強い削除は影響範囲を理解してから:
```bash
# 注意: 停止中コンテナ・未使用ネットワーク・未使用イメージ等を削除
docker system prune
```

## 6) Command cheatsheet
```bash
docker build --no-cache -t myapp:clean .
docker image ls
docker history myapp:dev
docker system df
docker image prune   # 注意して実行
docker system prune  # 影響範囲を確認してから
```

## 7) Common mistakes and safe practices
### よくあるミス
- `.env` をイメージに含める
- Dockerfile 内で秘密情報を `ENV` や `COPY` で埋め込む
- 依存ファイル変更がないのに毎回フルビルドになる書き方をする
- `system prune` を軽い気持ちで叩く

### 安全な運用
- シークレットはイメージに焼かず、実行時注入や専用シークレット管理を使う
- `prune` 前に `docker ps -a`, `docker image ls`, `docker volume ls` を確認する
- 本番ビルドは再現可能性のため固定バージョンや `npm ci` を優先する
- 開発イメージと本番イメージの責務を分ける

## 8) Interview-style question
Dockerfile で `COPY package*.json ./` を先に行ってから `RUN npm ci` し、その後で `COPY . .` する構成は、なぜビルド効率改善につながるのでしょうか。

## 9) Next-step resources
- Docker build best practices: https://docs.docker.com/build/building/best-practices/
- Multi-stage builds: https://docs.docker.com/build/building/multi-stage/
- `.dockerignore` reference: https://docs.docker.com/build/concepts/context/#dockerignore-files
- Image layers: https://docs.docker.com/get-started/docker-concepts/building-images/understanding-image-layers/

---

# まとめ
今日の学習弧は以下:
1. **Beginner:** build/run してコンテナ化の基本をつかむ
2. **Middle:** inspect/exec で調査力をつける
3. **Advanced:** Dockerfile 改善と安全なクリーンアップを学ぶ

開発現場で大事なのは、Dockerコマンドを暗記することよりも、**再現性・安全性・保守性のある使い方**を身につけること。特に、
- 秘密情報をイメージに入れない
- コンテナ内の手修正で終わらせない
- 削除系コマンドは影響確認後に実行する

この3つは、早い段階から癖にするとかなり強い。
