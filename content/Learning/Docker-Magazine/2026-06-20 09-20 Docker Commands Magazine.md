---
tags:
  - docker
  - containers
  - devops
  - learning
  - daily
---

[[Home]]

# Docker Commands Magazine — 2026-06-20

## 今回のテーマ
**Topic:** Docker コンテナのライフサイクル管理と実務的な使い分け  
**Level:** Beginner

---

## 1) なぜ大事か（実アプリ開発での意味）
アプリ開発では、**「同じアプリを、開発環境・CI・本番に近い検証環境で、できるだけ同じ条件で動かす」**ことが重要です。Docker の基本コマンドを理解していないと、次のような問題が起きやすくなります。

- 開発者ごとに動作が違う
- ローカルだけ動くが CI で壊れる
- 使い捨てにすべきコンテナと、残すべきイメージやボリュームの区別がつかない
- デバッグ時にログ確認・停止・再起動が雑になり、調査が遅くなる

実務では、Docker は単なる「起動コマンド」ではなく、**アプリを安全かつ再現可能に扱うための土台**です。

---

## 2) コア Docker コマンド解説
今日は「ライフサイクル管理」の基本に絞ります。

### `docker pull`
イメージをレジストリから取得します。

```bash
docker pull nginx:stable
```

- `nginx:stable` のように**タグを明示**するのが実務では安全
- `latest` 依存は再現性が下がるので避けることが多い

### `docker images`
ローカルにあるイメージ一覧を表示します。

```bash
docker images
```

確認ポイント:
- どのタグを持っているか
- 不要に巨大なイメージが増えていないか

### `docker run`
新しいコンテナを作成して起動します。

```bash
docker run --name web-test -d -p 8080:80 nginx:stable
```

主な意味:
- `--name web-test` : コンテナ名を付ける
- `-d` : バックグラウンド起動
- `-p 8080:80` : ホスト 8080 → コンテナ 80 を公開

### `docker ps`
起動中のコンテナを確認します。

```bash
docker ps
```

停止済みも含めたい場合:

```bash
docker ps -a
```

### `docker logs`
コンテナの標準出力・標準エラーを確認します。

```bash
docker logs web-test
```

追尾する場合:

```bash
docker logs -f web-test
```

### `docker stop`
コンテナを**安全に停止**します。

```bash
docker stop web-test
```

いきなり強制削除する前に、まず `stop` を使うのが基本です。

### `docker start`
停止済みコンテナを再起動します。

```bash
docker start web-test
```

### `docker rm`
停止済みコンテナを削除します。

```bash
docker rm web-test
```

> 注意: 実行中コンテナに `rm` は通常できません。`rm -f` は強制停止＋削除になるため、影響を理解してから使ってください。

### `docker exec`
起動中コンテナの中でコマンドを実行します。

```bash
docker exec -it web-test sh
```

- Alpine 系なら `sh`
- Debian/Ubuntu 系なら `bash` が使えることもあります

### `docker inspect`
詳細なメタデータを確認します。

```bash
docker inspect web-test
```

実務では以下の確認に便利です。
- 公開ポート
- マウント
- 環境変数
- ネットワーク設定

---

## 3) アプリ開発でどう使うか（Docker docs のベストプラクティス寄り）
Docker 公式ドキュメントの考え方に沿うと、基本は次の整理が大事です。

### 1. イメージは再現可能に作る
- ベースイメージを固定タグで指定する
- 開発者の手作業で状態が変わる運用を避ける
- Dockerfile にビルド手順を明示する

### 2. コンテナは使い捨て前提で考える
- コンテナの中に大事なデータを置きっぱなしにしない
- 永続化が必要なら volume を使う
- 設定は環境変数や Compose で管理する

### 3. ログ・状態確認をコマンドで再現する
- 「なんとなく動いてる」ではなく `docker ps`, `logs`, `inspect` で確認
- トラブル時の再現手順を README に残す

### 4. secrets をイメージに焼き込まない
- API キーや秘密情報を `Dockerfile` に書かない
- `.env` を使う場合も Git に入れない
- Compose や実行環境の secret 管理機能を優先する

### 5. 掃除コマンドは慎重に使う
- `docker system prune`, `docker image prune`, `docker container prune` は便利
- ただし**消える対象を理解せずに叩くと、検証環境やキャッシュを壊す**
- チーム開発では「今消してよいものか」を意識する

---

## 4) 30〜60分ハンズオン mini lab
**目標:** Nginx コンテナを起動し、状態確認・ログ確認・中に入る・停止・削除まで一通り行う。

### 前提
- Docker Engine / Docker Desktop が利用可能
- 8080 ポートが空いている

### 手順

#### Step 1: イメージ取得
```bash
docker pull nginx:stable
```

#### Step 2: イメージ確認
```bash
docker images
```

`nginx` が見えることを確認します。

#### Step 3: コンテナ起動
```bash
docker run --name web-test -d -p 8080:80 nginx:stable
```

#### Step 4: 起動確認
```bash
docker ps
```

`STATUS` が `Up ...` になっていればOKです。

#### Step 5: ブラウザ確認
ブラウザで以下を開きます。

- <http://localhost:8080>

Nginx の初期ページが見えれば成功です。

#### Step 6: ログ確認
```bash
docker logs web-test
```

アクセス後に再度見ると、リクエストログが増えることがあります。

#### Step 7: コンテナ内で確認
```bash
docker exec -it web-test sh
```

中で以下を試します。

```sh
pwd
ls /usr/share/nginx/html
exit
```

#### Step 8: 詳細情報確認
```bash
docker inspect web-test
```

特に以下を探してみてください。
- 公開ポート
- IP アドレス
- 起動イメージ名

#### Step 9: 停止
```bash
docker stop web-test
```

#### Step 10: 停止済みを含めて確認
```bash
docker ps -a
```

#### Step 11: 削除
```bash
docker rm web-test
```

### 発展課題（余裕があれば）
- `-p 8081:80` でもう一度起動して違いを見る
- `docker logs -f` でログ追尾しながらアクセスする
- `docker ps -a` で状態遷移を観察する

所要時間目安: **30〜45分**

---

## 5) Command Cheatsheet
```bash
# イメージ取得
docker pull nginx:stable

# イメージ一覧
docker images

# コンテナ起動
docker run --name web-test -d -p 8080:80 nginx:stable

# 起動中コンテナ確認
docker ps

# 停止済み含む確認
docker ps -a

# ログ確認
docker logs web-test

# ログ追尾
docker logs -f web-test

# コンテナ内に入る
docker exec -it web-test sh

# 詳細確認
docker inspect web-test

# 停止
docker stop web-test

# 削除
docker rm web-test
```

---

## 6) よくあるミスと安全な運用

### ミス1: `latest` を何も考えず使う
- 問題: いつの間にか挙動が変わる
- 安全策: 学習時も実務時も、できるだけタグを明示する

### ミス2: コンテナの中だけ直して満足する
- 問題: 再作成で消える
- 安全策: 永続化が必要なら volume、設定変更なら Dockerfile / Compose に戻す

### ミス3: `docker rm -f` を雑に使う
- 問題: 調査中のコンテナや必要な状態を一気に消す
- 安全策: まず `docker ps -a` で対象を確認し、通常は `stop` → `rm`

### ミス4: 危険な掃除コマンドを勢いで使う
以下は**削除系コマンド**です。実行前に対象を必ず確認してください。

```bash
docker system prune
docker image prune -a
docker container prune
docker volume prune
```

**警告:**
- 不要と思っていたコンテナ・イメージ・ネットワーク・volume を消すことがあります
- `volume prune` はデータ消失に直結する場合があります
- 実務マシンや共同環境では特に慎重に扱ってください

### ミス5: secrets をイメージや Compose に直書きする
- 問題: イメージ履歴や Git に残る
- 安全策:
  - `Dockerfile` に秘密情報を埋め込まない
  - `compose.yaml` に平文 secrets を直書きしない
  - `.env` を使う場合も Git 管理対象から外す
  - 本番では専用の secret 管理を使う

---

## 7) Interview-style Question
**質問:**  
`docker run` で起動したコンテナと、`docker pull` で取得したイメージの違いを説明してください。また、アプリのデータをコンテナの中だけに置く運用がなぜ危険なのかも説明してください。

**考えるポイント:**
- イメージ = テンプレート
- コンテナ = 実行インスタンス
- コンテナは再作成されうる
- 永続データは volume などで分離すべき

---

## 8) Next-step Resources
まずは公式を優先すると、理解がブレにくいです。

- Docker Get Started  
  <https://docs.docker.com/get-started/>

- Docker Engine command line reference  
  <https://docs.docker.com/engine/reference/commandline/>

- `docker run` reference  
  <https://docs.docker.com/engine/reference/run/>

- Best practices for writing Dockerfiles  
  <https://docs.docker.com/develop/develop-images/dockerfile_best-practices/>

- Persisting container data / volumes  
  <https://docs.docker.com/storage/volumes/>

- Build best practices  
  <https://docs.docker.com/build/building/best-practices/>

---

# 次回予告（学習アーク）
次回は **Middle** として、以下に進むのがおすすめです。

**予定テーマ:** Dockerfile の書き方と Node.js アプリのコンテナ化  
**Level:** Middle  
**Prerequisites:**
- `docker run`, `ps`, `logs`, `stop`, `rm` が使える
- イメージとコンテナの違いを説明できる
- ポート公開の基本を理解している

その次の **Advanced** では、以下につなげられます。

**予定テーマ:** Multi-stage build・軽量化・セキュアな build/runtime 分離  
**Level:** Advanced  
**Prerequisites:**
- Dockerfile の基本命令 (`FROM`, `WORKDIR`, `COPY`, `RUN`, `CMD`) を理解
- build context と `.dockerignore` の意味を説明できる
- 開発用設定と本番用設定の違いを意識できる

---

今日の結論はシンプルです。  
**Docker は「起動できること」より、「状態を把握し、安全に作って壊せること」が実務で効きます。**