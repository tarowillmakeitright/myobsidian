---
tags:
  - docker
  - containers
  - devops
  - learning
  - daily
---

[[Home]]

# 2026-06-29 09-20 Docker Commands Magazine

**Topic:** Dockerコンテナの基本操作を身につける — `docker pull` / `docker run` / `docker ps` / `docker logs` / `docker exec` / `docker stop`
**Level:** Beginner

> 次回以降の学習アーク予定: Beginner → Middle → Advanced の順で進める。今日は土台づくり。

---

## 1) Topic + Level

### 今日のテーマ
**「まずは安全にコンテナを起動・観察・停止できるようになる」**

Docker学習の最初の壁は、イメージ・コンテナ・実行中プロセスの違いが曖昧なままコマンドを叩いてしまうことです。今日は以下の基本操作だけに集中します。

- イメージを取得する: `docker pull`
- コンテナを起動する: `docker run`
- 動いているか確認する: `docker ps`
- 出力を確認する: `docker logs`
- 中に入って調べる: `docker exec`
- 止める: `docker stop`

### このレベルで目指す状態
- イメージとコンテナの違いを説明できる
- Webアプリ用コンテナをローカルで起動できる
- ログを見てトラブルの入り口を掴める
- 危険な削除系コマンドを雑に打たない

---

## 2) Why it matters for real app development

実アプリ開発でDockerが重要なのは、**開発者ごとの差分を減らし、環境を再現可能にする**からです。

たとえばWebアプリ開発では次のような場面で効きます。

- 新メンバーが参加しても、同じイメージから同じ環境を起動できる
- アプリ本体、DB、Redisなどを分離して扱える
- ローカルで「本番に近い動かし方」を試せる
- CIでも同じコンテナイメージを使い回しやすい

Dockerを雑に使うと「動くけど仕組みが分からない箱」になりがちです。逆に基本コマンドを丁寧に押さえると、Compose、Build、CI/CD、Kubernetesに進んでも理解がつながります。

---

## 3) Core Docker command explanations

### `docker pull`
リモートレジストリ（主に Docker Hub）からイメージを取得します。

```bash
docker pull nginx:1.27-alpine
```

ポイント:
- `nginx` がイメージ名
- `1.27-alpine` がタグ
- `latest` に頼りすぎず、**なるべく明示タグを使う**のが実務向き

---

### `docker run`
コンテナを新規作成して起動します。

```bash
docker run --name my-nginx -d -p 8080:80 nginx:1.27-alpine
```

主要オプション:
- `--name my-nginx`: コンテナ名を付ける
- `-d`: バックグラウンド実行
- `-p 8080:80`: ホストの8080番をコンテナの80番へ転送

考え方:
- **イメージは設計図**
- **コンテナは起動した実体**

---

### `docker ps`
動いているコンテナを確認します。

```bash
docker ps
```

停止済みも含めて見たいとき:

```bash
docker ps -a
```

確認したい観点:
- STATUS
- PORTS
- NAMES
- 起動しっぱなしになっていないか

---

### `docker logs`
コンテナ標準出力/標準エラー出力を確認します。

```bash
docker logs my-nginx
```

追いかけるとき:

```bash
docker logs -f my-nginx
```

実務ではまずログを見る癖が大事です。アプリが起動しない、ポートが違う、設定ファイル読めていない、といった問題の最初の手がかりになります。

---

### `docker exec`
起動中コンテナの中でコマンドを実行します。

```bash
docker exec -it my-nginx sh
```

注意:
- Alpine系は `bash` ではなく `sh` のことが多い
- 本番運用では「execでその場しのぎ修正」は避ける
- 原因調査には便利だが、修正は **Dockerfileや設定ファイルに戻す**のが原則

---

### `docker stop`
コンテナを安全に停止します。

```bash
docker stop my-nginx
```

いきなり強制終了するより、まずは `stop` を使うのが基本です。

---

## 4) How Docker is used while building apps

Docker公式ドキュメントのベストプラクティスに沿うと、開発中の使い方は次の流れが基本です。

### 1. 依存環境をコンテナで揃える
- たとえばアプリ本体は手元のNode.jsで動かしつつ
- PostgreSQLやRedisはコンテナで立てる
- あるいはアプリ本体も含めて全部コンテナ化する

### 2. イメージは再現可能に作る
- ベースイメージは軽量かつ信頼できるものを使う
- タグを固定する
- Dockerfileの命令順を工夫してキャッシュを活かす
- 不要ファイルは `.dockerignore` で送らない

### 3. 1コンテナ1責務を意識する
- Webアプリ、DB、ジョブワーカーを分ける
- ログはコンテナ外で集約・観察する前提にする

### 4. 秘密情報をイメージに焼き込まない
**重要:**
- `ENV API_KEY=...` のように秘密をDockerfileへ直書きしない
- `docker compose.yml` に本物の秘密をコミットしない
- `.env` を使う場合も Git 管理に注意する
- 本番では専用の secret 管理を使う

### 5. コンテナを「手で直す箱」にしない
- `docker exec` で中に入りっぱなしにしない
- 変更は Dockerfile / Compose / 設定ファイルに戻す
- 再ビルドして同じ結果になる状態を保つ

これは docs.docker.com の考え方とかなり一致しています。つまり、**再現性・最小性・秘密管理・責務分離**が軸です。

---

## 5) 30-60 minute hands-on mini lab

### ミニラボ: Nginxコンテナを起動して観察する（所要 35〜45分）

### ゴール
- コンテナ起動
- ブラウザ確認
- ログ確認
- コンテナ内部確認
- 安全に停止

### 前提
- Docker Engine / Docker Desktop が使える
- ローカルの 8080 番ポートが空いている

### 手順 1: イメージ取得

```bash
docker pull nginx:1.27-alpine
```

確認ポイント:
- どのタグを引いたかメモする
- `latest` ではなく固定タグを使った理由を考える

### 手順 2: コンテナ起動

```bash
docker run --name my-nginx -d -p 8080:80 nginx:1.27-alpine
```

### 手順 3: 起動確認

```bash
docker ps
```

見るところ:
- `STATUS` が `Up`
- `PORTS` に `0.0.0.0:8080->80/tcp` 系の表示

### 手順 4: ブラウザまたは curl で確認

```bash
curl http://localhost:8080
```

期待:
- NginxのWelcomeページHTMLが返る

### 手順 5: ログを見る

```bash
docker logs my-nginx
```

次に別ターミナルでアクセスし、追尾してみる:

```bash
docker logs -f my-nginx
```

学ぶこと:
- アクセスログが標準出力に出る設計
- コンテナは「ログをファイルに溜め込む」より標準出力に出すのが扱いやすい

### 手順 6: コンテナ内部を確認

```bash
docker exec -it my-nginx sh
```

中で試す:

```sh
pwd
ls -la /usr/share/nginx/html
cat /etc/nginx/nginx.conf | head
exit
```

学ぶこと:
- コンテナ内FSはホストと別物
- ただし永続化しない変更も多い
- 調査はしてよいが、恒久変更はDockerfile側へ戻す

### 手順 7: 停止

```bash
docker stop my-nginx
```

### 手順 8: 停止後確認

```bash
docker ps -a
```

余力があれば:
- 同じ名前で再起動するには何が必要か調べる
- `docker start my-nginx` も試す

---

## 6) Command cheatsheet

```bash
# イメージ取得
docker pull nginx:1.27-alpine

# コンテナ起動
docker run --name my-nginx -d -p 8080:80 nginx:1.27-alpine

# 稼働中コンテナ確認
docker ps

# 停止済み含めて確認
docker ps -a

# ログ確認
docker logs my-nginx

# ログ追尾
docker logs -f my-nginx

# コンテナ内でシェル起動
docker exec -it my-nginx sh

# コンテナ停止
docker stop my-nginx

# 停止済みコンテナを再開
docker start my-nginx
```

---

## 7) Common mistakes and safe practices

### よくあるミス 1: `latest` タグに依存する
問題:
- 日によって中身が変わりうる
- チーム内やCIで再現性が落ちる

安全策:
- バージョンタグを固定する
- できれば digest 固定も検討する

### よくあるミス 2: コンテナの中を手で直して満足する
問題:
- 再起動で消える
- 他メンバーやCIで再現できない

安全策:
- Dockerfile / compose / 設定ファイルに戻して修正する

### よくあるミス 3: 秘密情報をイメージやComposeへ直書きする
問題:
- 履歴・Git・イメージレイヤーに残る
- 漏えい時の回収が難しい

安全策:
- 本物の秘密を Dockerfile に書かない
- Composeファイルに秘密を直接コミットしない
- 開発用 `.env` でもGit除外を確認する

### よくあるミス 4: 不要な公開ポートを開ける
問題:
- 意図せずローカル外から到達可能になる場合がある
- 開発中の管理画面やDBを露出しやすい

安全策:
- 必要なポートだけ公開する
- 何を `-p` しているか毎回意識する

### よくあるミス 5: 削除系コマンドを雑に使う
特に危険:

```bash
docker system prune
docker image prune -a
docker rm -f <container>
docker rmi <image>
```

警告:
- 不要と思っていたイメージ・停止済みコンテナ・ビルドキャッシュ・未使用ネットワークを消す
- 作業中の別プロジェクトへ影響することがある
- `-f` は確認なしで進みやすい

安全策:
- まず `docker ps -a`、`docker images` で確認する
- prune系は**何が消えるか理解してから**使う
- 共有開発環境や学習中は特に慎重に

---

## 8) One interview-style question

**質問:**
`docker run -d -p 8080:80 nginx:1.27-alpine` は何をしていて、`8080:80` は何を意味しますか？ また、トラブル時に最初に確認したいコマンドを2つ挙げてください。

**考えるポイント:**
- イメージとコンテナの違い
- バックグラウンド実行
- ポートフォワーディング
- `docker ps` と `docker logs` を挙げられるか

---

## 9) Next-step resources

まずは公式ドキュメント優先で進むのが一番強いです。

- Docker Get Started  
  https://docs.docker.com/get-started/

- Docker Engine overview  
  https://docs.docker.com/engine/

- Running containers  
  https://docs.docker.com/engine/containers/run/

- Dockerfile best practices  
  https://docs.docker.com/develop/develop-images/dockerfile_best-practices/

- Build best practices / cache / context の考え方  
  https://docs.docker.com/build/

- Compose overview  
  https://docs.docker.com/compose/

---

## 次回予告

### Middle 予告
**テーマ候補:** `docker build` / `Dockerfile` / `.dockerignore` / レイヤーキャッシュ

**Prerequisites:**
- `docker pull` / `run` / `ps` / `logs` / `exec` / `stop` が使える
- イメージとコンテナの違いが分かる

### Advanced 予告
**テーマ候補:** マルチステージビルド、非root実行、ヘルスチェック、Composeでの開発環境設計

**Prerequisites:**
- Dockerfileを書いてイメージをビルドできる
- キャッシュとレイヤーの基本を説明できる
- 秘密情報をイメージへ埋め込まない理由を理解している

---

## ひとこと

Dockerは「コマンド暗記」より、**再現性のある開発環境をどう作るか**で学ぶと強いです。今日はまず、起動して、観察して、止める。この地味な土台がかなり大事。