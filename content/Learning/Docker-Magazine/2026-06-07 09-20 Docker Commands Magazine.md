---
tags:
  - docker
  - containers
  - devops
  - learning
  - daily
---

[[Home]]

# Docker Commands Magazine — 2026-06-07

日々のアプリ開発でそのまま使えるように、**初級 → 中級 → 上級**の順で段階的に学ぶDocker特集です。今日は「**コンテナの基本操作から、実務的なイメージ管理・運用確認まで**」をテーマにまとめます。

---

## 1. 初級 — `docker run` / `docker ps` / `docker logs` で開発用コンテナを扱う

### なぜ大事？
アプリ開発では、まず「**ローカル環境で同じ条件をすぐ再現できること**」が強いです。Dockerを使うと、DB・Redis・APIの依存環境をホストOSに直接汚さず起動できます。チーム開発でも「自分のPCだけ動かない」を減らせます。

### コアコマンド解説

#### `docker run`
イメージから新しいコンテナを作成して起動します。

```bash
docker run --name hello-nginx -d -p 8080:80 nginx:stable
```

- `--name hello-nginx`: コンテナ名を付ける
- `-d`: バックグラウンド実行
- `-p 8080:80`: ホストの8080番をコンテナの80番へ公開
- `nginx:stable`: 使用するイメージ:タグ

#### `docker ps`
起動中コンテナの一覧を表示します。

```bash
docker ps
```

停止済みも含めるなら:

```bash
docker ps -a
```

#### `docker logs`
コンテナ標準出力・標準エラーを確認します。

```bash
docker logs hello-nginx
```

追いかけるなら:

```bash
docker logs -f hello-nginx
```

### 実務ではどう使う？
Docker公式ベストプラクティスに沿うと、開発時は「**使い捨て可能なコンテナ**」として扱う意識が重要です。アプリ本体の状態はイメージ、永続データはvolume、設定は環境変数やComposeへ分離します。

- 開発用WebサーバやDBをすぐ起動
- ログ確認で起動失敗を早く切り分け
- コンテナを壊れても作り直せる前提で扱う

### 30〜60分ミニラボ
**目標:** Nginxコンテナを起動して状態確認まで行う

1. Nginxを起動

```bash
docker run --name hello-nginx -d -p 8080:80 nginx:stable
```

2. 起動確認

```bash
docker ps
```

3. ブラウザで `http://localhost:8080` を開く
4. ログ確認

```bash
docker logs hello-nginx
```

5. 停止

```bash
docker stop hello-nginx
```

6. 再開

```bash
docker start hello-nginx
```

### チートシート

```bash
docker run --name NAME -d -p HOST:CONTAINER IMAGE:TAG
docker ps
docker ps -a
docker logs NAME
docker logs -f NAME
docker stop NAME
docker start NAME
```

### よくあるミスと安全策
- `-p` の向きを逆にする (`80:8080` と `8080:80` を混同)
- `docker ps` だけ見て「存在しない」と誤解する（停止済みは `docker ps -a`）
- ローカル検証用でも不要なポート公開をしない
- 本番っぽいデータを雑に入れない

### 面接っぽい一問
**Q.** `docker run` と `docker start` の違いは？

**考え方:** `docker run` は「新しいコンテナを作って起動」、`docker start` は「既存コンテナを再起動」です。

### 次の一歩
- Docker Get Started: https://docs.docker.com/get-started/
- Running containers: https://docs.docker.com/get-started/docker-concepts/running-containers/

---

## 2. 中級 — `docker exec` / `docker inspect` / `docker cp` でトラブルシュートする

**前提条件:**
- `docker run` と `docker ps` の基本が分かる
- コンテナ内とホストOSが別空間だと理解している

### なぜ大事？
アプリ開発では「起動したけど想定通り動かない」が日常です。そんなとき、コンテナ内部に入る・設定を確認する・ファイルを持ち出す、という流れが非常に実務的です。

### コアコマンド解説

#### `docker exec`
起動中コンテナ内でコマンドを実行します。

```bash
docker exec -it hello-nginx sh
```

- `-i`: 標準入力を開く
- `-t`: 疑似TTYを割り当てる
- `sh`: 実行するシェル

#### `docker inspect`
コンテナやイメージの詳細なメタデータをJSONで確認します。

```bash
docker inspect hello-nginx
```

IPやマウント先なども確認できます。

#### `docker cp`
ホストとコンテナ間でファイルをコピーします。

```bash
docker cp hello-nginx:/etc/nginx/nginx.conf ./nginx.conf
```

### 実務ではどう使う？
Docker公式の考え方では、**調査のために一時的に中に入るのはOK**ですが、修正をその場で手作業固定するのではなく、最終的には **Dockerfile / Compose / 設定ファイルに反映** するのが正道です。

良い使い方:
- `docker exec` で稼働確認
- `docker inspect` でポート/volume/ネットワーク確認
- `docker cp` で設定やログを退避

避けたい使い方:
- 本番運用の修正を `exec` 後に手作業だけで終える
- コンテナ内に秘密情報をベタ置きする

### 30〜60分ミニラボ
**目標:** コンテナ内部を確認し、設定ファイルをホストへコピーする

1. Nginxを起動（未起動なら）

```bash
docker run --name hello-nginx -d -p 8080:80 nginx:stable
```

2. コンテナに入る

```bash
docker exec -it hello-nginx sh
```

3. コンテナ内で確認

```sh
ls /etc/nginx
cat /etc/nginx/nginx.conf | head
exit
```

4. 詳細情報を見る

```bash
docker inspect hello-nginx
```

5. 設定をホストへコピー

```bash
docker cp hello-nginx:/etc/nginx/nginx.conf ./nginx.conf
```

6. コピーされたファイルを確認

```bash
ls -l ./nginx.conf
```

### チートシート

```bash
docker exec -it NAME sh
docker exec NAME env
docker inspect NAME
docker inspect --format '{{.NetworkSettings.IPAddress}}' NAME
docker cp NAME:/path/in/container ./local-path
docker cp ./local-file NAME:/tmp/local-file
```

### よくあるミスと安全策
- `exec` は**起動中コンテナにしか使えない**
- Alpine系は `bash` がなく `sh` のことが多い
- `inspect` 出力には環境変数等が見える場合があるので共有時は注意
- 機密情報を `.env` のままイメージへ `COPY` しない
- secrets はDockerfileに埋め込まず、実行時注入やsecret管理を使う

### 面接っぽい一問
**Q.** なぜ `docker exec` での手修正だけに頼るのは危険？

**考え方:** コンテナ再作成で消えやすく、再現性がなく、IaC/構成管理の原則に反するためです。

### 次の一歩
- Container networking / storage / env basics: https://docs.docker.com/get-started/docker-concepts/
- `docker exec` reference: https://docs.docker.com/reference/cli/docker/container/exec/
- `docker inspect` reference: https://docs.docker.com/reference/cli/docker/inspect/

---

## 3. 上級 — `docker build` / `docker image ls` / `docker history` で安全なイメージ運用を理解する

**前提条件:**
- コンテナ起動・停止・ログ確認ができる
- `docker exec` で調査した経験がある
- Dockerfileが「イメージを定義するファイル」だと理解している

### なぜ大事？
実務では「コンテナを使う」だけでなく、**自分たちのアプリ用イメージをどう安全かつ軽量に作るか** が重要です。ビルドの質は、CI速度・デプロイサイズ・脆弱性面積・秘密情報漏えいリスクに直結します。

### コアコマンド解説

#### `docker build`
Dockerfileを使ってイメージをビルドします。

```bash
docker build -t my-node-app:dev .
```

- `-t`: イメージ名:タグを付与
- `.`: ビルドコンテキスト

#### `docker image ls`
ローカルのイメージ一覧を表示します。

```bash
docker image ls
```

#### `docker history`
イメージのレイヤ履歴を確認します。

```bash
docker history my-node-app:dev
```

### 実務ではどう使う？
Docker公式ベストプラクティスでは、以下が特に重要です。

- **小さいベースイメージを選ぶ**
- **マルチステージビルドを使う**
- **`.dockerignore` を適切に使う**
- **不要ファイルや秘密情報をビルドコンテキストに含めない**
- **コンテナは1責務を意識する**
- **タグ固定や更新戦略を考える**

特に重要なのは、**秘密情報をイメージへ焼き込まないこと**です。`ARG` や `ENV` の使い方を誤ると履歴やイメージ内容に残る可能性があります。

### 30〜60分ミニラボ
**目標:** シンプルなNode.jsアプリのイメージをビルドし、イメージ履歴を確認する

1. 作業ディレクトリ作成

```bash
mkdir -p docker-magazine-lab && cd docker-magazine-lab
```

2. `app.js` を作成

```javascript
const http = require('http');
const server = http.createServer((req, res) => {
  res.end('hello from docker lab\n');
});
server.listen(3000, () => console.log('listening on 3000'));
```

3. `Dockerfile` を作成

```Dockerfile
FROM node:22-alpine
WORKDIR /app
COPY app.js .
EXPOSE 3000
CMD ["node", "app.js"]
```

4. `.dockerignore` を作成

```gitignore
node_modules
.git
.env
*.log
```

5. ビルド

```bash
docker build -t my-node-app:dev .
```

6. 実行

```bash
docker run --name my-node-app -d -p 3000:3000 my-node-app:dev
```

7. 動作確認

```bash
curl http://localhost:3000
```

8. イメージ確認

```bash
docker image ls
```

9. レイヤ履歴確認

```bash
docker history my-node-app:dev
```

### チートシート

```bash
docker build -t NAME:TAG .
docker image ls
docker history NAME:TAG
docker tag NAME:TAG NAME:OTHER_TAG
docker run --rm -p 3000:3000 NAME:TAG
```

### よくあるミスと安全策
- `.env` や秘密鍵をビルドコンテキストに入れる
- `latest` だけに依存して再現性を失う
- 不要に巨大なベースイメージを使う
- 開発用ツールを本番イメージに残す
- **破壊的コマンド注意:**
  - `docker system prune`
  - `docker image prune -a`
  - `docker rmi`
  - `docker rm -f`

これらは未使用イメージ・停止コンテナ・キャッシュ削除などに有効ですが、**必要な開発資産まで消す可能性があります。実行前に対象確認**を徹底してください。

### 面接っぽい一問
**Q.** `.dockerignore` はなぜ重要？

**考え方:** ビルドコンテキストの肥大化を防ぎ、ビルド高速化・キャッシュ効率向上・秘密情報混入防止に効くからです。

### 次の一歩
- Building best practices: https://docs.docker.com/build/building/best-practices/
- Dockerfile reference: https://docs.docker.com/reference/dockerfile/
- Multi-stage builds: https://docs.docker.com/build/building/multi-stage/

---

## 今日のまとめ

今日の学習アークはこうです。

1. **初級:** まずはコンテナを起動し、見て、止める
2. **中級:** 中に入って調べ、設定やファイルを確認する
3. **上級:** 自分のアプリ用イメージを安全に作り、品質を見る

Dockerは単なるコマンド暗記ではなく、**再現性・隔離・運用のしやすさ・安全性**を支える実務ツールです。特にアプリ開発では、

- コンテナは使い捨て前提
- 設定はコード化
- secretsは焼き込まない
- 削除系コマンドは慎重に

この4つを意識するだけで事故がかなり減ります。
