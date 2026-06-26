# Docker Commands Magazine
#docker #containers #devops #learning #daily
[[Home]]

作成日時: 2026-06-26 09:20 JST  
学習アーク: Docker Commands Magazine / Beginner → Middle → Advanced の反復学習アーク  
今回の号: **Beginner**

---

## 1) Topic + Level

**トピック:** `docker run` / `docker ps` / `docker logs` を使って、ローカル開発用コンテナを安全に立ち上げて観察する  
**レベル:** **Beginner**

> 次回の Middle では `docker exec`・`docker inspect`・ボリューム・ネットワークに進む予定。  
> Advanced では Dockerfile 最適化、BuildKit、マルチステージ、セキュアなビルド運用まで扱う。

---

## 2) Why it matters for real app development

実アプリ開発では、まず「動く環境をすぐ再現できる」ことが重要です。Docker の最初の価値はここにあります。

たとえば以下の場面で効きます。

- 新メンバーが同じ実行環境を数分で再現できる
- Node.js / Python / Go などの実行環境差分でハマりにくくなる
- DB や Redis をローカル PC に直接汚さず試せる
- CI とローカルの差を減らしやすい
- ログ確認やプロセス観察がしやすく、原因切り分けが速くなる

特に `docker run` を雑に使うと、

- 不要に公開ポートを増やす
- 使い捨てのつもりがコンテナを散らかす
- コンテナの中にデータを閉じ込める
- シークレットをイメージに焼き込む

といった事故の入口になります。なので最初から「安全で再現性のある使い方」を身につけるのが大事です。

---

## 3) Core Docker command explanations

### `docker run`
イメージから新しいコンテナを作って起動するコマンドです。

```bash
docker run --name webtest -d -p 8080:80 nginx:stable
```

意味:

- `--name webtest`: コンテナに名前を付ける
- `-d`: バックグラウンド起動
- `-p 8080:80`: ホスト 8080 → コンテナ 80 を公開
- `nginx:stable`: 使用するイメージ

ポイント:

- まずは `--name` を付けると管理しやすい
- `-p` は本当に必要なポートだけ公開する
- 開発用途では `--rm` が便利なことが多い

### `docker ps`
起動中のコンテナ一覧を見るコマンドです。

```bash
docker ps
```

停止済みも含めて見たいなら:

```bash
docker ps -a
```

見るべき列:

- `CONTAINER ID`
- `IMAGE`
- `STATUS`
- `PORTS`
- `NAMES`

### `docker logs`
コンテナの標準出力・標準エラーを確認します。

```bash
docker logs webtest
```

追いかけるなら:

```bash
docker logs -f webtest
```

直近 50 行だけ見るなら:

```bash
docker logs --tail 50 webtest
```

### `docker stop`
安全に停止シグナルを送ります。

```bash
docker stop webtest
```

### `docker rm`
停止済みコンテナを削除します。

```bash
docker rm webtest
```

**注意:** `docker rm -f` は強制停止付きです。開発中の確認用には便利でも、状態確認前に使うと原因調査の証拠を消しやすいです。

---

## 4) How Docker is used while building apps

Docker 公式ドキュメントのベストプラクティスに沿うと、開発中の Docker の使い方は「便利さ」より「再現性・最小権限・保守性」を優先するのが筋です。

### 開発時の典型フロー

1. ベースイメージを選ぶ
   - 例: `node:22-alpine` や `python:3.12-slim`
   - 小さければ正義、ではなく **必要な依存が安定して入るか** も見る

2. アプリをコンテナで動かす
   - `docker run` でローカル起動
   - まずはログとポート公開を理解する

3. データはコンテナ外に持つ
   - ソースコードは bind mount
   - 永続データは volume
   - 「コンテナの中にあるから大丈夫」は危険

4. ビルドは Dockerfile で明文化する
   - 手作業の `docker exec` セットアップに頼らない
   - 誰がやっても同じビルドになる状態を作る

5. シークレットをイメージに入れない
   - `.env` をそのまま COPY しない
   - API キーや秘密情報を Dockerfile に直書きしない
   - Compose や実行時環境変数を使う場合も、漏えいしない管理方法を選ぶ

### Docker docs 的に意識したいこと

- 1 コンテナ 1 つの主要責務を意識する
- 不要なパッケージを入れすぎない
- 公式イメージや信頼できるベースを使う
- Dockerfile は読みやすく、キャッシュを活かして書く
- イメージを immutable な成果物として扱う
- コンテナの中で秘密情報を固定化しない

---

## 5) 30-60 minute hands-on mini lab

### ミニラボ: Nginx コンテナを立てて、状態確認・ログ確認・停止・削除までやる

**所要時間:** 30〜45 分  
**目的:** `docker run` / `ps` / `logs` / `stop` / `rm` を「ただ打つ」ではなく、開発フローの中で理解する

### 事前準備

- Docker Engine または Docker Desktop が動いている
- 8080 ポートが空いている

### Step 1: イメージ取得を兼ねて起動

```bash
docker run --name webtest -d -p 8080:80 nginx:stable
```

確認ポイント:

- イメージが未取得なら pull が走る
- コンテナ名を固定すると再操作しやすい

### Step 2: 状態を見る

```bash
docker ps
```

チェックすること:

- `STATUS` が `Up`
- `PORTS` が `0.0.0.0:8080->80/tcp` などになっている

### Step 3: ブラウザまたは curl でアクセス

```bash
curl http://localhost:8080
```

Nginx の HTML が返れば成功。

### Step 4: ログを見る

```bash
docker logs webtest
```

さらに別ターミナルでアクセスしてから:

```bash
docker logs -f webtest
```

ログがどう増えるか観察する。

### Step 5: 停止する

```bash
docker stop webtest
```

その後:

```bash
docker ps
docker ps -a
```

停止済みが `ps -a` に残ることを確認する。

### Step 6: 削除する

```bash
docker rm webtest
```

### Step 7: 使い捨て起動も試す

```bash
docker run --rm -it alpine:3.22 sh
```

中で:

```sh
echo hello from alpine
exit
```

終了後、`docker ps -a` で自動削除されていることを確認。

### ラボの学び

- バックグラウンド起動と使い捨て起動は用途が違う
- ログ確認はデバッグの基本
- 停止済みコンテナは自動では消えないことがある
- `--rm` を使うと検証用コンテナの散らかりを減らせる

---

## 6) Command cheatsheet

```bash
# イメージから新しいコンテナを起動
docker run --name webtest -d -p 8080:80 nginx:stable

# フォアグラウンドで起動して挙動を見る
docker run --name webtest nginx:stable

# 終了時に自動削除される使い捨てコンテナ
docker run --rm -it alpine:3.22 sh

# 起動中コンテナ一覧
docker ps

# 停止済みも含めた一覧
docker ps -a

# ログ確認
docker logs webtest

# ログ追従
docker logs -f webtest

# 直近ログのみ
docker logs --tail 50 webtest

# 停止
docker stop webtest

# 削除（停止済み）
docker rm webtest
```

---

## 7) Common mistakes and safe practices

### よくあるミス

#### 1. なんでも `-p` で公開する
不要なポート公開は攻撃面を広げます。

**安全策:**

- 必要なポートだけ公開
- ローカル確認だけなら `127.0.0.1:8080:80` のように bind 先を絞るのも有効

例:

```bash
docker run --name webtest -d -p 127.0.0.1:8080:80 nginx:stable
```

#### 2. ログを見ずにすぐ消す
コンテナが落ちた原因を見ないまま削除すると再現調査が面倒になります。

**安全策:**

- まず `docker ps -a`
- 次に `docker logs <container>`
- その後で削除

#### 3. シークレットをイメージに入れる
Dockerfile の `COPY . .` で `.env` や秘密鍵を巻き込む事故は本当に多いです。

**安全策:**

- `.dockerignore` を使う
- シークレットをイメージに焼かない
- Compose やランタイム環境変数も、秘匿管理を前提に使う

#### 4. 破壊的な掃除コマンドを雑に使う
以下は便利ですが、影響範囲を理解せず打つと危険です。

```bash
docker system prune
docker image prune -a
docker container rm -f <id>
docker rmi <image>
```

**警告:**

- 未使用リソースをまとめて消す
- 他の作業中コンテナやキャッシュに影響する
- 調査用の停止済みコンテナまで消えることがある

**安全策:**

- 先に `docker ps -a` / `docker images` / `docker volume ls` で確認
- `-f` や `-a` は意味を理解してから使う
- チーム開発マシンや共有環境では特に慎重に扱う

#### 5. コンテナ内データを永続化したつもりになる
コンテナを消したらデータも消えることがあります。

**安全策:**

- DB データや重要ファイルは volume や bind mount に置く
- 「再作成前提」で設計する

---

## 8) One interview-style question

**質問:**  
`docker run -d -p 8080:80 nginx:stable` を実行したあと、ブラウザでアクセスできません。あなたならどの順番で切り分けますか？

**考える観点の例:**

- `docker ps` で本当に起動しているか
- `docker logs` にエラーはないか
- `PORTS` が期待通りか
- 8080 が別プロセスと競合していないか
- `curl http://localhost:8080` でローカルから届くか
- ファイアウォールや bind 先の問題はないか

---

## 9) Next-step resources

まずは公式ドキュメント優先で進めるのがいちばん堅いです。

- Docker Get Started  
  https://docs.docker.com/get-started/

- Docker Engine reference: `docker run`  
  https://docs.docker.com/engine/containers/run/

- Docker CLI reference  
  https://docs.docker.com/reference/cli/docker/

- View container logs  
  https://docs.docker.com/reference/cli/docker/container/logs/

- Best practices for writing Dockerfiles  
  https://docs.docker.com/develop/develop-images/dockerfile_best-practices/

- Build best practices  
  https://docs.docker.com/build/building/best-practices/

- Use bind mounts  
  https://docs.docker.com/engine/storage/bind-mounts/

- Use volumes  
  https://docs.docker.com/engine/storage/volumes/

- Multi-stage builds（予告編として）  
  https://docs.docker.com/build/building/multi-stage/

---

## 次号予告

**Middle 予定テーマ:**  
`docker exec` / `docker inspect` / ボリューム / ネットワークで「動いているコンテナの中身と接続」を理解する

**Middle の前提条件:**

- `docker run` でコンテナを起動できる
- `docker ps` と `docker logs` で状態確認できる
- ポート公開の基本を理解している

この土台ができると、ただ動かす段階から「開発環境を扱う」段階に進める。