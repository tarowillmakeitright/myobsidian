---
tags:
  - docker
  - containers
  - devops
  - learning
  - daily
---

[[Home]]

# 2026-06-24 09-20 Docker Commands Magazine

## 今日のテーマ
**Docker ネットワークとポート公開を理解して、ローカル開発環境を安全に組み立てる**  
**Level: Beginner**

---

## 1) Topic + Level
### Topic
Docker の `run`, `ps`, `logs`, `exec`, `stop`, `rm`, `network ls`, `port` を中心に、**「コンテナを起動するだけ」で終わらず、アプリ開発で安全に接続確認・デバッグ・停止までできること**を目標にする。

### Level
**Beginner**

### 次の学習アーク
- **Middle:** Docker Compose で複数サービスを束ねる
  - **Prerequisites:** `docker run`, ポート公開 (`-p`), コンテナ停止/削除, ログ確認ができること
- **Advanced:** 開発用ネットワーク設計・非 root 実行・シークレット分離・BuildKit を使った安全なイメージビルド
  - **Prerequisites:** Compose の基本、ボリューム、環境変数の扱い、Dockerfile の基礎が分かること

---

## 2) なぜ実アプリ開発で重要か
実際のアプリ開発では、Web アプリ、API、DB、キャッシュ、ジョブワーカーなどを**手元で再現できること**が大きな強みになる。

Docker を理解していると、次のような実務メリットがある。

- 開発環境の「自分のPCでは動く/動かない」差を減らせる
- PostgreSQL や Redis などの依存サービスをすぐ立ち上げられる
- レビューや onboarding 時に環境構築を標準化できる
- テストや CI で本番に近い形を再現しやすい
- 不要なポート公開や雑な権限付与を避け、**安全なローカル開発**に近づける

特にネットワークやポート公開の理解が浅いと、
- DB を外部に不用意に公開する
- どのコンテナがどこにつながっているか分からない
- ログや疎通確認が雑になって原因調査が遅れる

という事故が起きやすい。Docker は「動かす」だけでなく、**どう隔離し、どう接続し、どう安全に観察するか**までが実務のコア。

---

## 3) Core Docker command explanations

### `docker run`
コンテナを起動する基本コマンド。

```bash
docker run -d --name web -p 8080:80 nginx:stable
```

ポイント:
- `-d`: バックグラウンド起動
- `--name web`: コンテナ名を付ける
- `-p 8080:80`: ホストの 8080 をコンテナの 80 に転送
- `nginx:stable`: 使用イメージ

### `docker ps`
起動中コンテナの確認。

```bash
docker ps
```

よく使う見方:
- STATUS: 起動中か
- PORTS: どのポートが公開されているか
- NAMES: 作業対象のコンテナ名

停止済みも含めたいなら:

```bash
docker ps -a
```

### `docker logs`
コンテナ標準出力の確認。

```bash
docker logs web
docker logs -f web
```

- `-f`: tail -f のように追従
- アプリの起動失敗や接続エラーの初動調査に便利

### `docker exec`
起動中コンテナの中に入って確認する。

```bash
docker exec -it web sh
```

用途:
- 設定ファイル確認
- `curl localhost` で疎通確認
- DNS 解決やプロセス確認

注意:
- デバッグ用。**恒久的な変更は Dockerfile や Compose に戻す**
- コンテナ内で手作業変更しても再作成で消える

### `docker port`
どのポートがどこに公開されているか確認。

```bash
docker port web
```

### `docker stop` / `docker rm`
停止と削除。

```bash
docker stop web
docker rm web
```

安全な順序:
1. `docker ps` で対象確認
2. `docker stop` で停止
3. `docker rm` で削除

### `docker network ls`
Docker ネットワーク一覧を確認。

```bash
docker network ls
```

将来 Compose を使うと、この理解がそのまま複数コンテナ構成に効いてくる。

---

## 4) アプリ開発で Docker をどう使うか
Docker 公式ドキュメントのベストプラクティスに沿うと、開発時の考え方はかなり整理できる。

### 基本方針
- **1 コンテナ 1 役割**を意識する
  - Web
  - API
  - DB
  - Cache
- アプリコードはイメージに焼き込みすぎず、開発では bind mount / Compose を適切に使う
- **ログは標準出力に出す**
- 設定はコードに埋めず、環境変数や安全な設定管理へ分離
- イメージは小さく、不要なパッケージを入れすぎない
- `latest` 依存を避け、タグをある程度明示する
- 機密情報を Dockerfile や image layer に書き込まない

### 実務でよくある流れ
1. 開発用の DB をコンテナで起動
2. API コンテナをその DB と同じネットワークで動かす
3. `docker logs` でアプリ起動確認
4. `docker exec` で中から接続確認
5. 問題があれば Compose / Dockerfile を直して再作成

### セキュリティ寄りの実践ポイント
- DB のポートは本当にホストへ公開が必要か見直す
- ローカルだけでよいなら `127.0.0.1:5432:5432` のように loopback に限定する
- 秘密情報を `.env` に置く場合も Git 管理に入れない
- 本番 secrets をイメージに COPY しない
- `docker exec` での応急処置を常態化しない

---

## 5) 30-60 分ハンズオン mini lab
### ゴール
Nginx コンテナを起動し、ポート公開・ログ確認・コンテナ内確認・停止削除まで一連で体験する。

### 所要時間
**約 30〜45 分**

### 手順

#### Step 1: Nginx を起動
```bash
docker run -d --name docker-mag-web -p 8080:80 nginx:stable
```

確認:
```bash
docker ps
```

期待:
- `docker-mag-web` が起動している
- `0.0.0.0:8080->80/tcp` あるいは `:::8080->80/tcp` などが見える

#### Step 2: 公開ポート確認
```bash
docker port docker-mag-web
```

#### Step 3: ブラウザまたは curl で確認
```bash
curl http://localhost:8080
```

期待:
- Nginx の welcome HTML が返る

#### Step 4: ログ確認
```bash
docker logs docker-mag-web
```

次に別ターミナル、または先に curl を数回打ってから:
```bash
docker logs -f docker-mag-web
```

期待:
- アクセスログが見える

#### Step 5: コンテナ内に入る
```bash
docker exec -it docker-mag-web sh
```

コンテナ内で:
```sh
ls /usr/share/nginx/html
cat /usr/share/nginx/html/index.html
exit
```

学びどころ:
- コンテナの filesystem は見えるが、そこでの手作業変更は永続設計ではない

#### Step 6: ネットワークを見る
```bash
docker network ls
```

余裕があれば詳細:
```bash
docker inspect docker-mag-web
```

`NetworkSettings` や `Ports` を眺めて、Docker がどう接続しているかを確認する。

#### Step 7: 安全に停止・削除
```bash
docker stop docker-mag-web
docker rm docker-mag-web
```

最後に確認:
```bash
docker ps -a
```

### 発展課題
- `-p 127.0.0.1:8081:80` で loopback 限定公開して違いを確認する
- `docker run --rm hello-world` を試して、「一度きりコンテナ」の感覚を掴む
- 次回に向けて Compose 化を想像する

---

## 6) Command cheatsheet
```bash
# 起動
docker run -d --name web -p 8080:80 nginx:stable

# 起動中一覧
docker ps

# 停止済み含む一覧
docker ps -a

# ログ確認
docker logs web
docker logs -f web

# コンテナ内に入る
docker exec -it web sh

# 公開ポート確認
docker port web

# ネットワーク一覧
docker network ls

# 停止
docker stop web

# 削除
docker rm web

# 一時実行後に自動削除
docker run --rm hello-world
```

---

## 7) Common mistakes and safe practices

### よくあるミス 1: とりあえず全部 `-p` で公開する
問題:
- DB や管理 UI を不用意に外へ開く原因になる

安全策:
- 本当に必要なポートだけ公開する
- ローカル限定なら `127.0.0.1:PORT:PORT` を使う

### よくあるミス 2: コンテナ内で直した内容を本修正だと思い込む
問題:
- 再作成で消える
- チームに共有されない

安全策:
- 変更は Dockerfile / Compose / アプリコードに戻す

### よくあるミス 3: `latest` を無意識に使う
問題:
- ある日急に挙動が変わる

安全策:
- `nginx:stable` やバージョンタグを検討する

### よくあるミス 4: シークレットをイメージに埋め込む
問題:
- image history / layer から漏れる
- レジストリ配布時に危険

安全策:
- Dockerfile に API キーや秘密情報を直接書かない
- Compose の env でも Git 管理やログ露出に注意する
- 本番では secret 管理機構を使う

### よくあるミス 5: 破壊的クリーンアップを雑に実行する
以下は便利だが**破壊的**。

```bash
docker system prune
docker image prune -a
docker rm -f <container>
docker rmi <image>
```

警告:
- 未使用コンテナ、ネットワーク、イメージ、build cache を消す可能性がある
- 学習中や別プロジェクトの資産まで消すことがある

安全策:
- 実行前に `docker ps -a`, `docker images`, `docker volume ls` で確認
- 何が消えるか分からないなら `--volumes` は付けない
- 特に `rm -f`, `rmi`, `prune` 系は対象を目視してから使う

---

## 8) Interview-style question
**質問:**  
`docker run -p 8080:80 nginx` の `8080:80` は何を意味しますか？ また、ローカルマシン以外からアクセスさせたくない場合はどう工夫しますか？

**考えるポイント:**
- ホスト側ポートとコンテナ側ポートの対応
- `127.0.0.1:8080:80` のような bind の制限
- 不要なポート公開を避ける設計

---

## 9) Next-step resources
公式ドキュメント中心に次へ進むならこの順が実践的。

- Docker Get Started  
  https://docs.docker.com/get-started/

- Docker Engine: `docker run` reference  
  https://docs.docker.com/engine/containers/run/

- Publishing and exposing ports  
  https://docs.docker.com/get-started/docker-concepts/running-containers/publishing-ports/

- Multi-container applications / Compose の導入  
  https://docs.docker.com/get-started/docker-concepts/running-containers/multi-container-applications/

- Dockerfile best practices  
  https://docs.docker.com/develop/develop-images/dockerfile_best-practices/

- Build secrets / secure build considerations  
  https://docs.docker.com/build/building/secrets/

- Compose file reference  
  https://docs.docker.com/reference/compose-file/

---

## まとめ
今日は **Docker のポート公開と観察の基本** を押さえた。  
アプリ開発では、コンテナを「起動できる」だけでは不十分で、**どこに公開され、どう確認し、どう安全に止めるか** が重要。  
次の Middle では Compose を使って Web + DB の複数サービス構成へ進むと、実務にかなり近づく。