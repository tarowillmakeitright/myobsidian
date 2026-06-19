---
tags:
  - docker
  - containers
  - devops
  - learning
  - daily
---

[[Home]]

# Docker Commands Magazine — 2026-06-19

今日のテーマは **Dockerコマンドを、実際のアプリ開発の流れの中でどう使うか**。  
難易度は **Beginner → Middle → Advanced** の順で上げていきます。

---

## 1) Topic + Level

### Beginner
**テーマ:** `docker run`, `docker ps`, `docker logs`, `docker exec` でコンテナを動かして観察する

### Middle
**テーマ:** `docker build`, `docker images`, `docker tag` でアプリ用イメージを作る

**前提知識:**
- Beginnerレベルのコマンドが分かる
- Dockerfile を1回は見たことがある
- Linuxの基本的なファイル/ディレクトリ操作が分かる

### Advanced
**テーマ:** `docker compose up`, `docker compose logs`, `docker compose exec`, `docker compose down` で複数サービスを扱う

**前提知識:**
- Middleレベルのイメージ作成が分かる
- Webアプリがアプリ本体 + DB など複数要素で動くことを理解している
- 環境変数の基本を知っている

---

## 2) Why it matters for real app development

実務のアプリ開発でDockerが重要なのは、**「自分のPCでは動くのに、他人の環境では動かない」問題を減らせる**からです。

特に次の場面で効きます。

- 開発メンバー全員で同じ実行環境を使う
- Node.js / Python / Go / Java などのランタイム差分を減らす
- ローカルでDBやRedisなどの依存サービスを簡単に立ち上げる
- CI/CDで本番に近い形のビルド・テストを回す
- 本番用イメージを再現性高く作る

Dockerは単なる「コマンド暗記」ではなく、**開発・テスト・デプロイの共通土台**として使うのが本筋です。

---

## 3) Core Docker command explanations

### Beginner: 実行と観察

#### `docker run`
イメージから新しいコンテナを作成し、起動します。

例:
```bash
docker run --name webtest -d -p 8080:80 nginx
```

ポイント:
- `--name webtest`: コンテナ名を付ける
- `-d`: バックグラウンド実行
- `-p 8080:80`: ホスト8080番をコンテナ80番に接続
- `nginx`: 使用するイメージ

#### `docker ps`
起動中のコンテナ一覧を確認します。

```bash
docker ps
```

停止中も含めるなら:
```bash
docker ps -a
```

#### `docker logs`
コンテナの標準出力・標準エラー出力を見ます。

```bash
docker logs webtest
```

追尾表示:
```bash
docker logs -f webtest
```

#### `docker exec`
起動中コンテナ内でコマンドを実行します。

```bash
docker exec -it webtest sh
```

`-it` は対話操作向け。デバッグ時によく使います。

---

### Middle: イメージを作る

#### `docker build`
Dockerfileからイメージを作成します。

```bash
docker build -t myapp:dev .
```

ポイント:
- `-t myapp:dev`: 名前とタグを付ける
- `.`: ビルドコンテキスト（現在ディレクトリ）

#### `docker images`
ローカルのイメージ一覧を見ます。

```bash
docker images
```

#### `docker tag`
既存イメージに別タグを付けます。

```bash
docker tag myapp:dev myapp:2026-06-19
```

タグは「バージョン」や「用途」の管理に重要です。

---

### Advanced: 複数サービスを扱う

#### `docker compose up`
複数コンテナをまとめて起動します。

```bash
docker compose up -d
```

#### `docker compose logs`
Compose管理下のサービス群のログを見ます。

```bash
docker compose logs
```

特定サービスだけ見る:
```bash
docker compose logs app
```

#### `docker compose exec`
特定サービスのコンテナ内でコマンドを実行します。

```bash
docker compose exec app sh
```

#### `docker compose down`
Composeで作ったネットワークやコンテナを停止・削除します。

```bash
docker compose down
```

`-v` を付けるとボリュームも削除されるため注意:
```bash
docker compose down -v
```

**警告:** `-v` はDBデータなどを消す場合があります。何が消えるか分かっているときだけ使ってください。

---

## 4) How Docker is used while building apps (docs.docker.com best practices aligned)

Docker公式ドキュメントのベストプラクティスに沿うなら、開発中は次を意識すると強いです。

### 1. 小さく、目的が明確なイメージを作る
- 1コンテナ1責務を基本にする
- 不要なツールを入れすぎない
- 軽量ベースイメージを検討する

### 2. `.dockerignore` をちゃんと使う
ビルドコンテキストに不要ファイルを含めると:
- ビルドが遅くなる
- キャッシュが効きにくくなる
- 秘密情報を誤って送る危険が増える

例:
```gitignore
node_modules
.git
.env
coverage
*.log
```

### 3. レイヤーキャッシュを意識する
依存関係のインストールを、ソースコード全体コピーより前に置くとキャッシュしやすいです。

Node.js例:
```dockerfile
FROM node:22-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
CMD ["npm", "start"]
```

### 4. 本番ではマルチステージビルドを検討する
ビルド用ツールと実行用環境を分けると、
- イメージが小さくなる
- 攻撃面が減る
- 配布しやすくなる

### 5. シークレットをイメージに焼き込まない
**やってはいけない例:**
- Dockerfile にAPIキー直書き
- `COPY . .` で `.env` を丸ごと入れる
- composeファイルに秘密値を固定記述してそのまま共有

代わりに:
- 実行時環境変数を使う
- 必要ならDockerのsecret機構や安全なシークレット管理を使う
- `.env` を配布・コミットしない

### 6. root前提を減らす
可能なら非rootユーザーで動かす設計を検討します。実務ではセキュリティ上かなり重要です。

---

## 5) 30-60 minute hands-on mini lab

### ゴール
Nginxコンテナを起動し、次に自作HTMLを含むカスタムイメージを作り、最後にComposeでWeb + DB構成の雰囲気を体験する。

所要時間: **45分前後**

---

### Part A — Beginner (10-15分)

#### 1. Nginxを起動
```bash
docker run --name webtest -d -p 8080:80 nginx
```

#### 2. 状態確認
```bash
docker ps
docker logs webtest
```

#### 3. ブラウザ確認
`http://localhost:8080`

#### 4. コンテナ内部を見る
```bash
docker exec -it webtest sh
```

中で:
```sh
ls /usr/share/nginx/html
exit
```

学びどころ:
- イメージからコンテナが起動する流れ
- ポート公開の意味
- logs/exec の基本

---

### Part B — Middle (15-20分)

#### 1. 作業用ディレクトリ作成
```bash
mkdir docker-magazine-lab
cd docker-magazine-lab
```

#### 2. `index.html` を作る
```html
<h1>Hello Docker Magazine</h1>
<p>Custom image test</p>
```

#### 3. `Dockerfile` を作る
```dockerfile
FROM nginx:stable-alpine
COPY index.html /usr/share/nginx/html/index.html
```

#### 4. イメージをビルド
```bash
docker build -t docker-magazine:web1 .
```

#### 5. 起動
```bash
docker run --name webcustom -d -p 8081:80 docker-magazine:web1
```

#### 6. 確認
ブラウザで `http://localhost:8081`

#### 7. イメージ一覧
```bash
docker images
```

学びどころ:
- Dockerfileから再現可能な環境を作る感覚
- `docker build` と `docker run` の役割の違い

---

### Part C — Advanced (15-25分)

#### 1. `compose.yaml` を作る
```yaml
services:
  app:
    image: nginx:stable-alpine
    ports:
      - "8082:80"
  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: appuser
      POSTGRES_PASSWORD: change-me-for-local-only
      POSTGRES_DB: appdb
```

#### 2. 起動
```bash
docker compose up -d
```

#### 3. 状態とログ確認
```bash
docker compose ps
docker compose logs
```

#### 4. appコンテナに入る
```bash
docker compose exec app sh
```

#### 5. 停止
```bash
docker compose down
```

学びどころ:
- 複数サービスを1ファイルで管理する基本
- 単体コンテナ運用からチーム開発向け構成へ進む入口

**セキュリティ注意:**
このラボの `POSTGRES_PASSWORD` は学習用です。実案件では、秘密情報をcomposeファイルへ固定で書いたまま共有しないでください。

---

## 6) Command cheatsheet

### 基本
```bash
docker run --name sample -d -p 8080:80 nginx
docker ps
docker ps -a
docker logs sample
docker logs -f sample
docker exec -it sample sh
docker stop sample
docker start sample
```

### イメージ
```bash
docker build -t myapp:dev .
docker images
docker tag myapp:dev myapp:v1
```

### Compose
```bash
docker compose up -d
docker compose ps
docker compose logs
docker compose logs app
docker compose exec app sh
docker compose down
```

### 片付け系（要注意）
```bash
docker rm container_name
docker rmi image_name
docker system prune
```

**警告:**
- `docker rm -f ...` は強制停止・削除です
- `docker rmi ...` は参照中イメージや再利用したいイメージを消すことがあります
- `docker system prune` は未使用リソースをまとめて削除します

削除系は、**何が消えるか `docker ps -a`, `docker images`, `docker volume ls` で確認してから**実行するのが安全です。

---

## 7) Common mistakes and safe practices

### よくあるミス

#### 1. `latest` タグを当然のように使う
- 再現性が落ちる
- チームで挙動がズレやすい

**安全策:**
- バージョンタグを明示する
- 例: `node:22-alpine`, `postgres:16-alpine`

#### 2. `COPY . .` で余計なものを入れる
- `.env`
- `.git`
- ローカル秘密ファイル
- 巨大キャッシュ

**安全策:**
- `.dockerignore` を必ず整備する

#### 3. 開発用と本番用を同じ雑な設定で回す
- デバッグ設定が本番に残る
- 不要ポートが開く

**安全策:**
- 開発用composeと本番用構成を分ける
- 環境ごとの差分を意識する

#### 4. コンテナ内に入って手作業修正して満足する
- 再起動で消える
- 再現できない

**安全策:**
- 変更はDockerfileやcompose.yaml、ソースコードに戻して反映する

#### 5. 秘密情報をイメージに埋め込む
- 漏えい時の影響が大きい
- イメージ配布先まで拡散する

**安全策:**
- シークレットは実行時注入
- Git管理対象にしない
- サンプル値と本番値を分離する

#### 6. prune系を勢いで打つ
- 不要と思っていたボリュームにDBデータが入っていた、はよくある事故です

**安全策:**
- まず確認
- 可能なら削除対象を個別に消す
- 本番/重要環境ではバックアップ前提

---

## 8) One interview-style question

**質問:**  
`docker run` と `docker build` の違いを説明してください。また、実務で両者をどう使い分けるべきですか？

**答えるときの観点:**
- `build` はイメージ作成
- `run` はイメージからコンテナ起動
- 再現性、CI/CD、チーム開発での位置づけ

---

## 9) Next-step resources

まずは公式ドキュメント優先で進むのがおすすめです。

- Docker Get Started  
  https://docs.docker.com/get-started/

- Dockerfile reference  
  https://docs.docker.com/reference/dockerfile/

- Building best practices  
  https://docs.docker.com/build/building/best-practices/

- Docker Compose overview  
  https://docs.docker.com/compose/

- Publishing and exposing ports  
  https://docs.docker.com/get-started/docker-concepts/running-containers/publishing-ports/

- Multi-stage builds  
  https://docs.docker.com/build/building/multi-stage/

- Compose file reference  
  https://docs.docker.com/reference/compose-file/

---

## 今日のひとこと

Dockerは「コンテナを動かす道具」で終わらせると弱いです。  
**開発環境を揃え、ビルドを再現可能にし、複数サービスを安全に扱うための基盤**として見ると、一気に実務で効いてきます。

明日はこの流れの続きとして、`docker cp`, `docker inspect`, `docker stats`, `docker volume` あたりに進むとかなり実践的です。
