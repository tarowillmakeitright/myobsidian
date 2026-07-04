---
tags:
  - docker
  - containers
  - devops
  - learning
  - daily
---

[[Home]]

# Docker Commands Magazine — 2026-07-04

今日のテーマは、**Dockerコンテナのライフサイクルを安全に扱う基本コマンド**です。  
学習アークとして、**Beginner → Middle → Advanced** の順で段階的に理解を深めます。

---

# 1) Topic + Level

## Beginner
**トピック:** `docker run`, `docker ps`, `docker stop`, `docker logs` でコンテナを動かして観察する

## Middle
**トピック:** `docker exec`, `docker inspect`, `docker cp`, `docker rm` を使って開発中コンテナを調査・保守する

**前提知識:**
- `docker run` でコンテナを起動できる
- `docker ps` / `docker stop` の基本が分かる
- イメージとコンテナの違いをざっくり説明できる

## Advanced
**トピック:** `docker compose up`, `docker compose logs`, `docker compose exec`, `docker compose down` で複数サービスの開発環境を運用する

**前提知識:**
- 単体コンテナの起動・停止・ログ確認ができる
- ポート公開 (`-p`) とボリュームマウント (`-v` または bind mount) の意味が分かる
- 開発用アプリで「アプリ本体 + DB」のように複数サービスが必要になる理由を理解している

---

# 2) Why it matters for real app development

実アプリ開発では、Dockerは「動けばOK」の道具ではなく、**開発環境を再現可能にする基盤**です。

なぜ重要か:
- **環境差分を減らせる**: 自分のPC、チームメンバー、CIで同じ条件を再現しやすい
- **オンボーディングが速い**: README通りに `docker compose up` すればすぐ動く構成を作りやすい
- **トラブル調査がしやすい**: ログ、環境変数、ネットワーク、ファイルの状態をコマンドで確認できる
- **本番に近い検証ができる**: アプリ、DB、キャッシュなどをまとめて検証できる
- **依存関係の固定に向く**: 言語ランタイムやOSパッケージ差異による事故を減らせる

Docker公式ドキュメントでも、開発・テスト・本番の一貫性、最小イメージ、安全な設定、Secretsの適切な扱いが重視されています。

---

# 3) Core Docker command explanations

## Beginner Commands

### `docker run`
イメージから新しいコンテナを作成して起動します。

例:
```bash
docker run --name webtest -d -p 8080:80 nginx:alpine
```

ポイント:
- `--name webtest`: コンテナ名を付ける
- `-d`: バックグラウンド実行
- `-p 8080:80`: ホストの8080番をコンテナの80番へ転送
- `nginx:alpine`: 使用するイメージ

### `docker ps`
現在動いているコンテナを一覧表示します。

```bash
docker ps
```

停止済みも含めるなら:
```bash
docker ps -a
```

### `docker logs`
コンテナの標準出力・標準エラーを確認します。

```bash
docker logs webtest
```

追跡表示:
```bash
docker logs -f webtest
```

### `docker stop`
コンテナを安全に停止します。

```bash
docker stop webtest
```

---

## Middle Commands

### `docker exec`
起動中コンテナの中でコマンドを実行します。

```bash
docker exec -it webtest sh
```

用途:
- 設定ファイル確認
- 疎通確認
- 一時的なデバッグ

注意:
- `exec` で加えた変更は、**再作成で消える**ことがあります
- 恒久的な変更は Dockerfile や compose 設定へ戻すのが原則です

### `docker inspect`
コンテナやイメージの詳細情報をJSONで確認します。

```bash
docker inspect webtest
```

よく見る項目:
- IPアドレス
- マウント先
- 環境変数
- 起動コマンド

### `docker cp`
ホストとコンテナの間でファイルをコピーします。

```bash
docker cp webtest:/etc/nginx/nginx.conf ./nginx.conf
```

### `docker rm`
停止済みコンテナを削除します。

```bash
docker rm webtest
```

注意:
- 起動中コンテナに `-f` を付けると強制停止＋削除です
- **`docker rm -f` は便利ですが、調査中の状態を失いやすい**ため慎重に使う

---

## Advanced Commands

### `docker compose up`
複数サービスをまとめて起動します。

```bash
docker compose up -d
```

オプション:
```bash
docker compose up --build
```
変更を反映してビルドし直したいときに使います。

### `docker compose logs`
複数サービスのログをまとめて確認します。

```bash
docker compose logs -f
```

特定サービスだけ見る:
```bash
docker compose logs -f app
```

### `docker compose exec`
Compose管理下のサービスに入って確認します。

```bash
docker compose exec app sh
```

### `docker compose down`
Composeで起動したリソースを停止・削除します。

```bash
docker compose down
```

注意:
- ボリュームまで消す場合の `-v` は**破壊的**です
- DBデータを消す可能性があるため、実行前に必ず確認する

```bash
docker compose down -v
```

---

# 4) How Docker is used while building apps

Docker公式のベストプラクティスに沿うと、アプリ開発では次の使い方が実践的です。

## 1. 開発環境の標準化
- Node.js, Python, Go などのランタイムをイメージ化
- チーム全員が同じ依存関係で作業
- 「自分の環境では動く」を減らす

## 2. Composeで依存サービスをまとめる
例:
- `app`
- `db` (Postgres)
- `redis`

アプリ単体ではなく、**アプリが依存する周辺サービス込みで起動**するのが現実的です。

## 3. Dockerfileに変更を戻す
コンテナ内で手修正して終わりにせず、再現可能な形に戻します。

良い流れ:
1. `docker exec` で原因を調査
2. 修正方針を決める
3. Dockerfile / compose.yml / アプリコードへ反映
4. 再ビルドして検証

## 4. 小さく安全なイメージを意識する
Docker docsでも推奨される考え方:
- できるだけ小さいベースイメージを使う
- 不要なパッケージを入れない
- レイヤキャッシュを意識してDockerfileを書く
- `.dockerignore` を使って不要ファイルを送らない

## 5. Secretsをイメージに埋め込まない
やってはいけない例:
- DockerfileにAPIキーを直書き
- `ENV SECRET=...` をイメージへ焼き込む
- `compose.yml` に本番用秘密情報を平文で置く

安全な方針:
- 開発用でも秘密情報の扱いを軽視しない
- `.env` の管理範囲を明確にする
- 本番ではDocker secretsやクラウドの秘密情報管理を使う
- Gitに機密情報を入れない

---

# 5) 30-60 minute hands-on mini lab

**テーマ:** 単体コンテナからCompose運用まで一通り体験する

想定時間: 45分

## ゴール
- Nginxコンテナを起動できる
- ログ確認・コンテナ内調査ができる
- ComposeでWeb + DB構成の雰囲気をつかめる

## Step 1: Nginxを起動する（10分）

```bash
docker run --name webtest -d -p 8080:80 nginx:alpine
```

確認:
```bash
docker ps
docker logs webtest
```

ブラウザ確認:
- `http://localhost:8080`

学び:
- コンテナ起動
- ポート公開
- ログ確認

## Step 2: コンテナの中を調べる（10分）

```bash
docker exec -it webtest sh
```

中で実行:
```sh
ls /etc/nginx
cat /etc/nginx/nginx.conf
exit
```

追加確認:
```bash
docker inspect webtest
```

学び:
- コンテナ内部の実体確認
- 「中身を見る」と「定義を直す」は別だと理解する

## Step 3: ファイルを取り出す（5分）

```bash
docker cp webtest:/etc/nginx/nginx.conf ./nginx.conf
```

学び:
- 調査用に設定ファイルをホスト側へ退避できる

## Step 4: Composeファイルを作る（10-15分）

作業用フォルダを作成し、`compose.yaml` を作成:

```yaml
services:
  app:
    image: nginx:alpine
    ports:
      - "8081:80"

  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_PASSWORD: example-change-me
      POSTGRES_DB: sample
      POSTGRES_USER: sample
```

起動:
```bash
docker compose up -d
```

確認:
```bash
docker compose logs
docker compose ps
```

学び:
- 複数サービスをまとめて扱う感覚
- 実アプリ開発の基本構造

## Step 5: 安全に片付ける（5分）

```bash
docker stop webtest
docker rm webtest
docker compose down
```

**注意:**
- `docker compose down -v` はDBデータも消える可能性あり
- 何を消すか分からないまま `prune` を使わない

発展:
- `app` に bind mount を追加して静的HTML差し替え
- `docker compose exec db sh` でDBコンテナの中を確認

---

# 6) Command cheatsheet

## 基本
```bash
docker run --name NAME -d -p HOST_PORT:CONTAINER_PORT IMAGE
docker ps
docker ps -a
docker logs CONTAINER
docker logs -f CONTAINER
docker stop CONTAINER
docker start CONTAINER
docker rm CONTAINER
```

## 調査・保守
```bash
docker exec -it CONTAINER sh
docker inspect CONTAINER
docker cp CONTAINER:/path/in/container ./local-path
```

## Compose
```bash
docker compose up -d
docker compose up --build
docker compose ps
docker compose logs -f
docker compose exec SERVICE sh
docker compose down
```

## 破壊的なので要注意
```bash
docker rm -f CONTAINER
docker rmi IMAGE
docker system prune
docker image prune -a
docker volume prune
docker compose down -v
```

**警告:** 上の削除系コマンドは、停止中コンテナ・未使用イメージ・未使用ボリューム・キャッシュを消します。どこまで消えるか理解してから実行してください。

---

# 7) Common mistakes and safe practices

## よくあるミス

### 1. コンテナ内の手修正を「完成版」だと思う
問題:
- 再起動や再作成で消える

安全策:
- Dockerfile / compose.yaml / アプリコードへ戻して再現可能にする

### 2. `latest` タグを当然のように使う
問題:
- いつの内容か分からず再現性が下がる

安全策:
- `postgres:16-alpine` のように、ある程度明示的なタグを使う

### 3. Secretsを雑に入れる
問題:
- イメージ履歴やGitに漏れる

安全策:
- 秘密情報をDockerfileへ直書きしない
- 本番資格情報をcomposeに平文で置かない
- `.env` の扱いとGit除外を明確にする

### 4. 不用意に `prune` する
問題:
- 他プロジェクトの未使用リソースまで消すことがある

安全策:
- 実行前に対象を確認する
- 共有開発マシンでは特に慎重に扱う

### 5. root前提で考える
問題:
- 権限まわりやセキュリティが荒くなる

安全策:
- 可能なら非rootユーザー実行を検討する
- 本番向けDockerfileでは最小権限を意識する

### 6. 不要ファイルまでビルドコンテキストに送る
問題:
- ビルドが遅い
- 機密ファイル混入リスクがある

安全策:
- `.dockerignore` を用意する
- `.git`, `node_modules`, `.env`, キャッシュ類を見直す

---

# 8) Interview-style question

**質問:**  
`docker exec` でコンテナ内を修正して問題が直ったとしても、そのまま運用に乗せるべきではないのはなぜですか？ また、正しい修正の戻し先はどこですか？

**考えるポイント:**
- 再現性
- 再デプロイ時の消失
- インフラのコード化
- チーム開発での共有

---

# 9) Next-step resources

まずは公式を優先して読むのがおすすめです。

- Docker Get Started  
  https://docs.docker.com/get-started/

- Docker Engine command line reference  
  https://docs.docker.com/engine/reference/commandline/cli/

- `docker run` リファレンス  
  https://docs.docker.com/engine/reference/run/

- Docker Compose overview  
  https://docs.docker.com/compose/

- Compose file reference  
  https://docs.docker.com/reference/compose-file/

- Building best practices  
  https://docs.docker.com/build/building/best-practices/

- Multi-stage builds  
  https://docs.docker.com/build/building/multi-stage/

- Dockerfile reference  
  https://docs.docker.com/reference/dockerfile/

- Manage sensitive data and secrets  
  https://docs.docker.com/engine/swarm/secrets/

---

# 今日のひとこと

Dockerコマンドは「覚える」より、**コンテナの状態を安全に観察して、再現可能な定義に戻す**のが本質です。  
開発で強い人ほど、`exec` で直して終わりではなく、**Dockerfile / Compose / アプリ設定に反映して再現性を守る**ところまでやります。
