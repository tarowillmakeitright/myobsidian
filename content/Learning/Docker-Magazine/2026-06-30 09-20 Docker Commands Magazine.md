---
tags:
  - docker
  - containers
  - devops
  - learning
  - daily
---

[[Home]]

# Docker Commands Magazine — 2026-06-30

**テーマ:** Dockerコマンドを使って、開発環境を安全かつ実践的に組み立てる

この号は、**Beginner → Middle → Advanced** の順に進む学習アークです。実際のアプリ開発で「ローカル実行」「再現可能な開発環境」「安全なイメージ運用」にどうつながるかを意識して構成しています。

---

# 1. Beginner — `docker run` / `docker ps` / `docker logs` の基本

## 1) Topic + Level
**Topic:** コンテナを起動して、状態確認とログ確認をする
**Level:** Beginner

## 2) Why it matters for real app development
アプリ開発では、まず「同じ環境で確実に動く」ことが重要です。Dockerを使うと、Node.js、Python、Postgres、Redis などをローカルPCに直接ベタ入れせず、**隔離された実行環境**として扱えます。

特に `docker run`、`docker ps`、`docker logs` は、
- 開発用サービスの起動
- バックエンドAPIの動作確認
- 起動失敗時の原因調査

に直結する最重要コマンドです。

## 3) Core Docker command explanations
### `docker run`
コンテナを新規作成して起動します。

```bash
docker run -d --name webtest -p 8080:80 nginx
```

- `-d`: バックグラウンド起動
- `--name webtest`: コンテナ名を付ける
- `-p 8080:80`: ホストの8080番をコンテナの80番へ転送
- `nginx`: 使用するイメージ名

### `docker ps`
起動中のコンテナ一覧を表示します。

```bash
docker ps
```

停止中も含めるなら:

```bash
docker ps -a
```

### `docker logs`
コンテナの標準出力・標準エラーを確認します。

```bash
docker logs webtest
```

追尾表示:

```bash
docker logs -f webtest
```

## 4) How Docker is used while building apps
Docker公式のベストプラクティスに沿うと、開発中は次のように使います。

- ローカルに大量の依存物を直インストールしない
- サービスごとに責務を分離する
- アプリの挙動確認はログベースで行う
- コンテナ名・ポート・環境変数を明示する
- 一時検証と継続運用を区別する

たとえば、フロントエンド開発者でも、バックエンドAPIやDBを `docker run` ですぐ立ち上げられると、環境差分で詰まりにくくなります。

## 5) 30-60 minute hands-on mini lab
### ミニラボ: Nginxを起動して状態確認
所要時間: 30分

1. Nginxコンテナを起動
```bash
docker run -d --name webtest -p 8080:80 nginx
```

2. 起動確認
```bash
docker ps
```

3. ログ確認
```bash
docker logs webtest
```

4. ブラウザで `http://localhost:8080` にアクセス

5. 停止
```bash
docker stop webtest
```

6. 停止後の状態確認
```bash
docker ps -a
```

7. 不要なら削除
```bash
docker rm webtest
```

## 6) Command cheatsheet
```bash
docker run -d --name webtest -p 8080:80 nginx
docker ps
docker ps -a
docker logs webtest
docker logs -f webtest
docker stop webtest
docker rm webtest
```

## 7) Common mistakes and safe practices
### よくあるミス
- `-p` を付け忘れてブラウザから見えない
- コンテナ名の重複で起動失敗
- 停止済みコンテナを放置して一覧が散らかる
- ログを見ずに「Dockerが壊れた」と判断する

### 安全な運用
- 公開不要なサービスは `0.0.0.0` でむやみに開けない
- 開発用途でも不要なポート公開を減らす
- コンテナ削除前に必要データの有無を確認する
- `docker rm -f` は強制削除なので、何を消すか確認してから実行する

## 8) One interview-style question
**Q.** `docker run -d -p 8080:80 nginx` の `8080:80` は何を意味しますか？ また、アプリ開発でこのポートマッピングが必要になる理由を説明してください。

## 9) Next-step resources
- Docker Get Started: https://docs.docker.com/get-started/
- Running containers: https://docs.docker.com/get-started/docker-concepts/running-containers/
- `docker run` reference: https://docs.docker.com/engine/containers/run/

---

# 2. Middle — `docker exec` / `docker cp` / `docker inspect`

## Prerequisites
- Beginnerレベルの内容
- コンテナの起動・停止・ログ確認ができること

## 1) Topic + Level
**Topic:** 実行中コンテナを調査して、開発時の問題切り分けを行う
**Level:** Middle

## 2) Why it matters for real app development
本番に近い開発環境では、「起動したけど期待通りに動かない」が日常です。そんなときに重要なのが、**コンテナ内部の確認**と**設定の見える化**です。

- `docker exec`: コンテナ内に入って調査
- `docker cp`: ファイルの出し入れ
- `docker inspect`: 設定やネットワーク情報の確認

これらは、APIサーバーが環境変数を読めているか、生成ファイルがどこにあるか、ポートやマウントが正しいかを確認するのに役立ちます。

## 3) Core Docker command explanations
### `docker exec`
起動中コンテナ内でコマンドを実行します。

```bash
docker exec -it webtest sh
```

- `-i`: 標準入力を開く
- `-t`: 擬似TTYを割り当てる
- `sh`: シェルを起動

### `docker cp`
ホストとコンテナの間でファイルをコピーします。

```bash
docker cp webtest:/etc/nginx/nginx.conf ./nginx.conf
```

### `docker inspect`
コンテナやイメージの詳細情報をJSONで表示します。

```bash
docker inspect webtest
```

よく見る項目:
- `NetworkSettings`
- `Mounts`
- `Config.Env`
- `State`

## 4) How Docker is used while building apps
Docker公式の考え方では、**トラブル時に手元で再現・観察できること**が重要です。

実際のアプリ開発では:
- コンテナ内の生成物を確認する
- 設定ファイルの場所を調べる
- 環境変数やマウント状態を確認する
- ただし、手作業の変更をコンテナ内に直接入れ続けない

重要なのは、`docker exec` は**調査用**、恒久対応は **Dockerfile / Compose / 設定ファイル側に戻す**ことです。これは再現性を守るうえで非常に大事です。

## 5) 30-60 minute hands-on mini lab
### ミニラボ: Nginx設定を読んで、inspectで構造を理解する
所要時間: 45分

1. コンテナ起動
```bash
docker run -d --name webtest -p 8080:80 nginx
```

2. シェルで入る
```bash
docker exec -it webtest sh
```

3. コンテナ内で設定確認
```sh
cat /etc/nginx/nginx.conf
exit
```

4. 設定ファイルをホストへコピー
```bash
docker cp webtest:/etc/nginx/nginx.conf ./nginx.conf
```

5. inspectでポートや状態を見る
```bash
docker inspect webtest
```

6. 可能なら次を絞り込み表示
```bash
docker inspect --format='{{json .NetworkSettings.Ports}}' webtest
```

7. 片付け
```bash
docker stop webtest
docker rm webtest
```

## 6) Command cheatsheet
```bash
docker exec -it webtest sh
docker cp webtest:/etc/nginx/nginx.conf ./nginx.conf
docker inspect webtest
docker inspect --format='{{json .Config.Env}}' webtest
docker inspect --format='{{json .Mounts}}' webtest
```

## 7) Common mistakes and safe practices
### よくあるミス
- `exec` で直した内容が永続化されると思い込む
- 本来Dockerfileに書くべき変更を手作業で済ませる
- `inspect` のJSONを見て圧倒される
- `docker cp` でパスの向きを逆にする

### 安全な運用
- コンテナ内で秘密情報を直接書き込まない
- `.env` やシークレットをイメージへ焼き込まない
- 調査した結果は Dockerfile / Compose / README に反映する
- 本番コンテナへ安易にシェルログインして手修正しない

## 8) One interview-style question
**Q.** `docker exec` で行った変更をそのまま運用に頼るべきでない理由は何ですか？ 再現性の観点から説明してください。

## 9) Next-step resources
- Container logs and debugging concepts: https://docs.docker.com/get-started/docker-concepts/running-containers/multi-container-applications/
- `docker exec` reference: https://docs.docker.com/reference/cli/docker/container/exec/
- `docker inspect` reference: https://docs.docker.com/reference/cli/docker/inspect/

---

# 3. Advanced — `docker build` / `docker image ls` / `docker history` / 安全なクリーンアップ

## Prerequisites
- Beginner / Middle の内容
- Dockerfileの基本概念
- イメージとコンテナの違いを説明できること

## 1) Topic + Level
**Topic:** 開発用イメージを安全にビルドし、イメージ品質とサイズを意識して運用する
**Level:** Advanced

## 2) Why it matters for real app development
現実のアプリ開発では、「動く」だけでは不十分です。重要なのは:
- ビルドが再現可能
- イメージが軽量
- シークレットが混入しない
- キャッシュが効率的
- 不要なアーティファクトを残さない

`docker build` を理解すると、開発環境・CI・本番デプロイの品質が一段上がります。

## 3) Core Docker command explanations
### `docker build`
Dockerfileを使ってイメージを作成します。

```bash
docker build -t demo-node:1.0 .
```

- `-t demo-node:1.0`: イメージ名とタグ
- `.`: ビルドコンテキスト

### `docker image ls`
ローカルのイメージ一覧を確認します。

```bash
docker image ls
```

### `docker history`
イメージのレイヤー履歴を確認します。

```bash
docker history demo-node:1.0
```

どの層で大きくなったか、不要ファイルが入り込んでいないかのヒントになります。

### 安全なクリーンアップ関連
```bash
docker image prune
```
未使用イメージの整理です。

**注意:** `prune` 系は削除コマンドです。何が消えるか確認してから実行してください。

## 4) How Docker is used while building apps
Docker公式ベストプラクティスに沿うと、ビルド時は特に次を意識します。

- 公式または信頼できるベースイメージを使う
- `.dockerignore` を整備して不要ファイルを送らない
- レイヤーキャッシュを意識して Dockerfile を組む
- シークレットを `COPY` や `ENV` で焼き込まない
- 可能ならマルチステージビルドを使う
- イメージを定期的に見直し、不要レイヤーや脆弱な古いベースを避ける

アプリ開発では、`Dockerfile` は単なる起動スクリプトではなく、**再現可能なビルド仕様書**です。

## 5) 30-60 minute hands-on mini lab
### ミニラボ: 小さなNode.jsアプリをビルドして観察する
所要時間: 60分

1. 作業ディレクトリ作成
```bash
mkdir -p docker-magazine-lab
cd docker-magazine-lab
```

2. `app.js` を作成
```js
const http = require('http');
const server = http.createServer((req, res) => {
  res.writeHead(200, {'Content-Type': 'text/plain'});
  res.end('hello from docker lab\n');
});
server.listen(3000, () => console.log('server listening on 3000'));
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
.git
node_modules
.env
*.log
```

5. ビルド
```bash
docker build -t demo-node:1.0 .
```

6. イメージ確認
```bash
docker image ls
```

7. 起動
```bash
docker run --rm -p 3000:3000 demo-node:1.0
```

8. 別ターミナルでアクセス
```bash
curl http://localhost:3000
```

9. 履歴確認
```bash
docker history demo-node:1.0
```

10. 片付け前に確認
```bash
docker ps -a
docker image ls
```

11. 必要なら整理
```bash
# 削除対象を理解してから実行
docker image prune
```

## 6) Command cheatsheet
```bash
docker build -t demo-node:1.0 .
docker image ls
docker history demo-node:1.0
docker run --rm -p 3000:3000 demo-node:1.0
docker image prune
```

## 7) Common mistakes and safe practices
### よくあるミス
- `.env` や秘密鍵をビルドコンテキストへ含める
- `COPY . .` を無造作に使う
- 巨大なベースイメージを選ぶ
- イメージタグを雑に管理して追跡不能になる
- `prune` や `rmi` を状況確認せず実行する

### 安全な運用
- **秘密情報をイメージに入れない**
- Composeでも平文シークレットを安易に直書きしない
- `.dockerignore` を必ず整備する
- 破壊的クリーンアップ前に `docker ps -a` と `docker image ls` を確認する
- `docker rmi`, `docker rm -f`, `docker system prune` は削除影響を理解してから使う
- 本番向けには最小権限・最小構成を意識する

## 8) One interview-style question
**Q.** Dockerイメージを小さく・安全に保つために、Dockerfile とビルド運用で取るべき具体策を3つ以上説明してください。

## 9) Next-step resources
- Building images: https://docs.docker.com/get-started/docker-concepts/building-images/
- Dockerfile best practices: https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Multi-stage builds: https://docs.docker.com/build/building/multi-stage/
- `.dockerignore` reference: https://docs.docker.com/build/concepts/context/#dockerignore-files
- CLI image reference: https://docs.docker.com/reference/cli/docker/image/

---

# Quick Review

- Beginnerでは、**起動・一覧・ログ確認**を押さえる
- Middleでは、**調査・設定確認・内部観察**を覚える
- Advancedでは、**ビルド品質・サイズ・安全性**を意識する

Dockerは「コマンドを覚える」だけでは足りません。実際の開発では、**再現性・安全性・調査しやすさ**まで含めて使えるかが差になります。今日は、まず `run / ps / logs` を確実に使いこなし、その次に `exec / inspect`、最後に `build / history` へつなげる流れが実践的です。
