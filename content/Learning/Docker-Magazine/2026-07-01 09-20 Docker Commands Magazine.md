---
tags:
  - docker
  - containers
  - devops
  - learning
  - daily
---

[[Home]]

# Docker Commands Magazine — 2026-07-01

## 今日のテーマ
**Arc 1 / Beginner — `docker run`・`docker ps`・`docker logs` でアプリ実行の最小ループを理解する**

> 次号以降の流れ: Beginner → Middle → Advanced の順で段階的に進める予定です。今回は土台作りとして、コンテナを「起動して、確認して、ログを見る」までを確実にします。

---

## 1) Topic + Level
**Topic:** Docker の基本実行ループ
**Level:** Beginner

扱う主コマンド:
- `docker run`
- `docker ps`
- `docker logs`
- `docker exec`
- `docker stop`
- `docker rm`
- `docker images`

---

## 2) Why it matters for real app development
実アプリ開発では、Docker は単なる学習用ツールではなく、次のような現場課題を減らすために使われます。

- **ローカル環境差分を減らす**  
  「自分のPCでは動くのに、他の人のPCでは動かない」を減らせます。
- **依存関係を隔離できる**  
  Node.js、Python、Postgres、Redis などをホストに直接汚さず試せます。
- **起動確認が早い**  
  アプリ、DB、ジョブワーカーなどを同じ流れで確認できます。
- **CI/CD や本番運用への接続が自然**  
  ローカルで Docker を理解しておくと、Build、Test、Deploy の一貫性が上がります。

特にアプリ開発では、**「コンテナを起動 → 状態確認 → ログ確認 → 中に入って調査 → 停止」** のループが基本動作になります。

---

## 3) Core Docker command explanations

### `docker run`
コンテナを新規作成して起動します。

```bash
docker run hello-world
```

よく使うオプション:
- `--name <name>`: コンテナ名を付ける
- `-d`: バックグラウンド起動
- `-p hostPort:containerPort`: ポート公開
- `-e KEY=value`: 環境変数を渡す
- `--rm`: 終了時に自動削除

例:
```bash
docker run --name webtest -d -p 8080:80 nginx
```

これは:
- `nginx` イメージから
- `webtest` という名前のコンテナを
- バックグラウンドで起動し
- ホストの `8080` をコンテナの `80` に転送します

---

### `docker ps`
起動中のコンテナ一覧を表示します。

```bash
docker ps
```

停止済みも含めるなら:
```bash
docker ps -a
```

確認ポイント:
- `STATUS`
- `PORTS`
- `NAMES`
- どのイメージから作られたか

---

### `docker logs`
コンテナ標準出力・標準エラー出力を確認します。

```bash
docker logs webtest
```

追従表示:
```bash
docker logs -f webtest
```

アプリ開発では、まずログを見る癖が重要です。落ちた理由、起動失敗、設定不備の最初の手がかりになります。

---

### `docker exec`
起動中コンテナ内でコマンドを実行します。

```bash
docker exec -it webtest sh
```

用途:
- ファイル確認
- 環境変数確認
- アプリプロセス調査
- 疎通確認

`bash` が入っていない軽量イメージもあるので、まず `sh` を試すと安全です。

---

### `docker stop`
コンテナを停止します。

```bash
docker stop webtest
```

強制停止より先に、まず通常停止を試すのが基本です。

---

### `docker rm`
停止済みコンテナを削除します。

```bash
docker rm webtest
```

> 注意: `docker rm -f` は強制削除です。開発中の調査対象や必要なログ確認前に消すと、原因追跡が難しくなります。

---

### `docker images`
ローカルにあるイメージを一覧表示します。

```bash
docker images
```

どのイメージを使っているか、サイズはどれくらいかをざっくり把握できます。

---

## 4) How Docker is used while building apps
Docker の公式ドキュメントのベストプラクティスに沿うと、アプリ開発では次の使い方が実践的です。

### 4-1. 開発環境を再現可能にする
- アプリ実行に必要なランタイムや依存関係を Dockerfile で定義する
- 新メンバーでも同じ手順で起動できるようにする

### 4-2. 1コンテナ1責務を意識する
- Web アプリ
- DB
- キャッシュ
- バッチ

を役割ごとに分けると観察しやすくなります。

### 4-3. ログは標準出力へ出す
Docker ではログ収集の基本が標準出力です。ファイルの中だけに閉じ込めると、`docker logs` で追えず運用しづらくなります。

### 4-4. イメージに秘密情報を焼き込まない
**APIキー、DBパスワード、トークンを Dockerfile やイメージに直接含めない**こと。開発時でも危険です。

避けるべき例:
```dockerfile
ENV SECRET_KEY=super-secret-value
```

より安全な考え方:
- 実行時に環境変数で注入する
- ただし `.env` や Compose ファイルに秘密をベタ書きしない
- 本番では専用の secret 管理機構を使う

### 4-5. 破壊的クリーンアップは確認してから
以下は便利ですが、影響範囲を理解せず実行しないこと:
- `docker system prune`
- `docker image prune`
- `docker container prune`
- `docker rmi`
- `docker rm -f`

特に共有開発環境や作業途中では、必要なイメージや停止中コンテナまで消える可能性があります。

---

## 5) 30–60 minute hands-on mini lab
**ラボ名:** Nginx コンテナを起動し、状態確認・ログ確認・内部調査までやる

### ゴール
- コンテナを起動できる
- ポート公開を理解する
- ログ確認ができる
- `exec` で中を見られる
- 安全に停止・削除できる

### 前提
- Docker Engine または Docker Desktop が使える
- ローカルで `docker` コマンドが動く

### 手順

#### Step 1. 動作確認
```bash
docker run hello-world
```

確認ポイント:
- イメージが pull される
- コンテナが実行される
- 正常終了メッセージが表示される

#### Step 2. Web サーバーをバックグラウンド起動
```bash
docker run --name webtest -d -p 8080:80 nginx
```

#### Step 3. コンテナ状態を確認
```bash
docker ps
```

期待する見え方:
- `webtest` が `Up` になっている
- `0.0.0.0:8080->80/tcp` のようなポート対応が見える

#### Step 4. ブラウザまたは curl で疎通確認
```bash
curl http://localhost:8080
```

HTML が返れば OK です。

#### Step 5. ログを見る
```bash
docker logs webtest
```

アクセス後にもう一度見ると、リクエストログの変化が確認できます。

追従したい場合:
```bash
docker logs -f webtest
```

#### Step 6. コンテナ内部を確認
```bash
docker exec -it webtest sh
```

中で試す:
```sh
nginx -v
ls /usr/share/nginx/html
cat /etc/nginx/conf.d/default.conf
exit
```

#### Step 7. 停止
```bash
docker stop webtest
```

#### Step 8. 削除
```bash
docker rm webtest
```

#### Step 9. 後片付けの確認
```bash
docker ps -a
```

`webtest` が消えていれば完了です。

### 余力があれば
`--rm` 付きの一時実行も試す:
```bash
docker run --rm alpine echo "temporary container"
```

これは終了後にコンテナが自動削除されるため、単発コマンド検証に便利です。

---

## 6) Command cheatsheet

```bash
# 単発実行
docker run hello-world

# バックグラウンドで起動
docker run --name webtest -d -p 8080:80 nginx

# 起動中コンテナ確認
docker ps

# 停止済みも含めて確認
docker ps -a

# ログ確認
docker logs webtest

# ログ追従
docker logs -f webtest

# コンテナ内部でシェル起動
docker exec -it webtest sh

# 停止
docker stop webtest

# 削除（停止済みのみ）
docker rm webtest

# ローカルイメージ確認
docker images
```

---

## 7) Common mistakes and safe practices

### よくあるミス 1: `docker ps` に出ないので「消えた」と思う
`docker ps` は起動中だけ表示します。停止済みも確認したいなら `docker ps -a`。

### よくあるミス 2: ポート指定を逆にする
```bash
-p 8080:80
```
は **ホスト8080 → コンテナ80**。逆ではありません。

### よくあるミス 3: コンテナ名を付けず管理しづらくなる
名前なしでも動きますが、学習段階では `--name` を付けたほうが追跡しやすいです。

### よくあるミス 4: 落ちたらすぐ削除する
先にやるべきは:
1. `docker ps -a`
2. `docker logs <container>`
3. 必要なら `docker inspect <container>`

原因を見ずに消すと再現しづらくなります。

### よくあるミス 5: 秘密情報をイメージに埋め込む
- Dockerfile に秘密を書かない
- Compose に本番秘密を直書きしない
- Git に秘密ファイルを入れない

### Safe practices
- 開発中は `--name` を活用する
- まず `logs`、次に `exec` で調べる
- 強制削除・一括削除の前に対象を確認する
- チーム運用では不要な `latest` 依存を避け、バージョンを意識する

> 警告: `docker system prune` や `docker rmi` は便利ですが、不要だと思っていたイメージやキャッシュ、停止済みコンテナまで消えることがあります。実行前に影響範囲を確認してください。

---

## 8) One interview-style question
**質問:**
`docker run -d -p 8080:80 --name web nginx` を実行したあと、ブラウザで `localhost:8080` にアクセスしても繋がりません。どんな順序で切り分けますか？

**考えるポイント:**
- `docker ps` で本当に起動しているか
- `PORTS` が期待通りか
- `docker logs web` にエラーがないか
- ホスト側で 8080 が競合していないか
- コンテナ内サービスが 80 番で待ち受けているか

---

## 9) Next-step resources
公式ドキュメント優先です。

- Docker Get Started  
  https://docs.docker.com/get-started/
- Docker run reference  
  https://docs.docker.com/reference/cli/docker/container/run/
- Docker ps reference  
  https://docs.docker.com/reference/cli/docker/container/ls/
- Docker logs reference  
  https://docs.docker.com/reference/cli/docker/container/logs/
- Docker exec reference  
  https://docs.docker.com/reference/cli/docker/container/exec/
- Best practices for writing Dockerfiles  
  https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Build best practices  
  https://docs.docker.com/build/building/best-practices/

---

## 次回予告
**Arc 1 / Middle — `docker build`・Dockerfile・軽量で安全なイメージ作成の基本**

### 次回の前提知識
- `docker run` でコンテナを起動できる
- `docker ps` と `docker logs` で状態確認ができる
- コンテナ停止・削除の流れを理解している
