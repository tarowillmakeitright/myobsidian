---
tags:
  - docker
  - containers
  - devops
  - learning
  - daily
---

[[Home]]

# Docker Commands Magazine — 2026-06-21

## 今号のテーマ
**Topic:** Docker で開発環境を「再現可能」にする基本操作から、現実的な運用改善まで  
**Learning Arc:** Beginner → Middle → Advanced

---

# 1. Beginner — `docker run`, `docker ps`, `docker logs` でアプリを安全に動かす

## 1) Topic + Level
**Topic:** コンテナを起動・確認・観察する基本コマンド  
**Level:** Beginner

## 2) Why it matters for real app development
実アプリ開発では、まず「自分のマシンでは動く」を「誰のマシンでも同じように動く」に変える必要があります。Docker の基本操作を理解すると、以下が安定します。

- ローカル環境差分を減らせる
- バージョン違いの Node.js / Python / DB を隔離できる
- 不具合切り分け時に、ログ確認や再起動を素早く行える
- オンボーディング時に「まずこのコマンドを実行」で始められる

## 3) Core Docker command explanations
### `docker run`
イメージから新しいコンテナを作成して起動します。

```bash
docker run -d --name web -p 8080:80 nginx:stable
```

- `-d`: バックグラウンド実行
- `--name web`: コンテナ名を付ける
- `-p 8080:80`: ホスト 8080 → コンテナ 80 を公開
- `nginx:stable`: 使用イメージ

### `docker ps`
起動中のコンテナ一覧を表示します。

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
docker logs web
```

追尾するなら:

```bash
docker logs -f web
```

### よく一緒に使う補助コマンド
```bash
docker stop web
docker start web
docker rm web
```

## 4) How Docker is used while building apps
Docker 公式ドキュメントのベストプラクティスに沿うと、開発初期は「アプリ本体を作る前に、まず依存ミドルウェアをコンテナ化」する使い方が実用的です。

例:
- API 開発時に PostgreSQL / Redis を Docker で起動
- フロントエンド開発時に Nginx で静的配信確認
- チーム内で同じベースイメージを使い、環境差分を削減

重要なのは、**コンテナは使い捨て前提で扱い、重要データはボリュームや外部管理に分離する**ことです。

## 5) 30-60 minute hands-on mini lab
### ミニラボ: Nginx を起動して挙動を観察する
所要時間: 30〜40分

#### 手順
1. Nginx コンテナを起動
```bash
docker run -d --name docker-mag-nginx -p 8080:80 nginx:stable
```

2. 起動確認
```bash
docker ps
```

3. ログ確認
```bash
docker logs docker-mag-nginx
```

4. ブラウザで確認  
`http://localhost:8080`

5. 停止
```bash
docker stop docker-mag-nginx
```

6. 再起動
```bash
docker start docker-mag-nginx
```

7. 後片付け
```bash
docker stop docker-mag-nginx
docker rm docker-mag-nginx
```

#### 学べること
- イメージとコンテナの違い
- ポート公開の意味
- ログの見方
- 停止と削除の違い

## 6) Command cheatsheet
```bash
# イメージから起動
docker run -d --name web -p 8080:80 nginx:stable

# 起動中コンテナ確認
docker ps

# 全コンテナ確認
docker ps -a

# ログ確認
docker logs web
docker logs -f web

# 停止・起動・削除
docker stop web
docker start web
docker rm web
```

## 7) Common mistakes and safe practices
### よくあるミス
- `-p` を付け忘れてブラウザから見えない
- コンテナ名重複で再作成に失敗する
- 停止済みコンテナが残り続けて混乱する
- 「コンテナ削除 = イメージ削除」と勘違いする

### 安全な実践
- コンテナ名を明示する
- 不要な公開ポートを増やさない
- ログ確認を習慣化する
- 本番データをコンテナ内部だけに保存しない

## 8) One interview-style question
**質問:** `docker run` と `docker start` の違いを説明してください。  
**考え方のヒント:** 新規作成を伴うか、既存コンテナを再開するか。

## 9) Next-step resources
- Docker Get Started: https://docs.docker.com/get-started/
- Running containers: https://docs.docker.com/get-started/docker-concepts/running-containers/
- `docker run` reference: https://docs.docker.com/reference/cli/docker/container/run/
- `docker logs` reference: https://docs.docker.com/reference/cli/docker/container/logs/

---

# 2. Middle — `docker exec`, `docker compose up`, ボリュームで開発効率を上げる

## Prerequisites
- `docker run`, `docker ps`, `docker logs` の基本が分かる
- ポート公開の意味を理解している
- コンテナとイメージの違いを説明できる

## 1) Topic + Level
**Topic:** アプリ開発時の複数サービス連携とコンテナ内調査  
**Level:** Middle

## 2) Why it matters for real app development
実際のアプリは単体では完結しません。Web アプリ、DB、キャッシュ、ジョブワーカーなど複数サービスが連携します。`docker compose` を使うと、チーム全員が同じ構成を一発で再現できます。

さらに `docker exec` を使えると、トラブル時にコンテナ内部を確認しやすくなり、依存ライブラリ・環境変数・ファイル配置のズレをすぐ検証できます。

## 3) Core Docker command explanations
### `docker exec`
起動中コンテナの中でコマンドを実行します。

```bash
docker exec -it app sh
```

- `-i`: 標準入力を開く
- `-t`: 疑似 TTY を付与
- `sh`: シェルを起動

例:
```bash
docker exec app env
docker exec app ls -la /app
```

### `docker compose up`
Compose ファイルの定義に従って複数サービスを起動します。

```bash
docker compose up -d
```

- `-d`: バックグラウンド起動
- `docker-compose.yml` または `compose.yaml` を参照

### `docker compose logs`
Compose 配下のサービスログをまとめて確認します。

```bash
docker compose logs -f
```

### ボリュームの基本
ホストのソースコードをコンテナへマウントして、保存と同時に反映させることができます。

例:
```yaml
volumes:
  - ./:/app
```

## 4) How Docker is used while building apps
Docker 公式の実務寄りベストプラクティスでは、開発用 Compose で以下を揃えるのが定番です。

- アプリ本体と DB を分離
- 依存サービスは Compose で定義
- 設定値は環境変数で注入
- ソースコードは bind mount、永続データは volume で分ける
- 本番イメージには不要な開発ツールを含めない

特に重要なのは、**秘密情報を Dockerfile や compose ファイルへ直書きしない**ことです。`.env` やシークレット管理基盤を使い、Git に含めない運用を徹底します。

## 5) 30-60 minute hands-on mini lab
### ミニラボ: Web + Redis を Compose で起動する
所要時間: 40〜60分

#### 1. 作業ディレクトリ作成
```bash
mkdir docker-compose-lab
cd docker-compose-lab
```

#### 2. `compose.yaml` を作成
```yaml
services:
  web:
    image: nginx:stable
    ports:
      - "8080:80"
    volumes:
      - ./html:/usr/share/nginx/html:ro
  redis:
    image: redis:7-alpine
```

#### 3. HTML 作成
```bash
mkdir -p html
echo '<h1>Hello Docker Compose</h1>' > html/index.html
```

#### 4. 起動
```bash
docker compose up -d
```

#### 5. 状態確認
```bash
docker compose ps
docker compose logs -f
```

#### 6. ブラウザ確認  
`http://localhost:8080`

#### 7. Web コンテナ内部確認
```bash
docker compose exec web sh
ls -la /usr/share/nginx/html
exit
```

#### 8. 終了
```bash
docker compose down
```

#### 学べること
- Compose による複数サービス定義
- bind mount の効果
- `exec` を使った内部調査
- アプリと依存サービスの分離

## 6) Command cheatsheet
```bash
# 起動中コンテナへ入る
docker exec -it app sh

# Compose 起動
docker compose up -d

# Compose 状態確認
docker compose ps

# Compose ログ
docker compose logs -f

# Compose 内でコマンド実行
docker compose exec web sh

# 停止と削除
docker compose down
```

## 7) Common mistakes and safe practices
### よくあるミス
- `docker exec` を停止済みコンテナに対して実行する
- bind mount と named volume を混同する
- 開発用 Compose をそのまま本番へ流用する
- `.env` を Git へコミットする

### 安全な実践
- 開発用と本番用で設定を分離する
- secrets を Dockerfile に埋め込まない
- 読み取り専用でよいマウントは `:ro` を使う
- Compose サービス名を分かりやすく付ける

## 8) One interview-style question
**質問:** bind mount と named volume は何が違い、どの場面で使い分けますか？

## 9) Next-step resources
- Docker Compose overview: https://docs.docker.com/compose/
- Compose getting started: https://docs.docker.com/compose/gettingstarted/
- Volumes: https://docs.docker.com/engine/storage/volumes/
- Bind mounts: https://docs.docker.com/engine/storage/bind-mounts/

---

# 3. Advanced — `docker build`, multi-stage build, image hygiene で本番品質へ近づける

## Prerequisites
- Compose を使って複数サービスを起動できる
- `docker exec` でコンテナ内確認ができる
- ボリュームと bind mount の違いを理解している
- Dockerfile の基本構文 (`FROM`, `COPY`, `RUN`) を見たことがある

## 1) Topic + Level
**Topic:** 軽量・安全・再現性の高いイメージを作る  
**Level:** Advanced

## 2) Why it matters for real app development
本番運用では「動く」だけでは不十分です。イメージサイズ、ビルド時間、脆弱性露出、秘密情報混入、キャッシュ効率が、そのまま開発速度と運用コストに響きます。

良い Dockerfile を書けると:
- CI が速くなる
- 本番デプロイが軽くなる
- 脆弱性スキャン対象を減らせる
- チームのビルド再現性が上がる

## 3) Core Docker command explanations
### `docker build`
Dockerfile からイメージを作成します。

```bash
docker build -t myapp:dev .
```

- `-t`: イメージ名とタグ
- `.`: ビルドコンテキスト

### `docker image ls`
ローカルイメージ一覧を確認します。

```bash
docker image ls
```

### `docker history`
イメージレイヤー履歴を確認します。

```bash
docker history myapp:dev
```

### multi-stage build
ビルド用ステージと実行用ステージを分け、最終イメージを小さく安全に保ちます。

```dockerfile
FROM node:22-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM nginx:stable-alpine
COPY --from=build /app/dist /usr/share/nginx/html
```

## 4) How Docker is used while building apps
Docker 公式ベストプラクティスで特に重要なのは次の点です。

- 小さく信頼できるベースイメージを選ぶ
- ビルドキャッシュが効くように Dockerfile を並べる
- `.dockerignore` を使って不要ファイルを送らない
- multi-stage build で本番イメージを絞る
- 秘密情報を build context や image layer に含めない
- 可能なら非 root ユーザーで実行する

「とりあえず全部 COPY」は楽ですが、依存が巨大化し、ビルドも遅くなり、秘密情報混入の事故も起こしやすくなります。

## 5) 30-60 minute hands-on mini lab
### ミニラボ: 軽量な静的サイト用イメージを作る
所要時間: 45〜60分

#### 1. ディレクトリ作成
```bash
mkdir docker-build-lab
cd docker-build-lab
mkdir site
printf '<h1>Docker Build Lab</h1>' > site/index.html
```

#### 2. `Dockerfile` 作成
```dockerfile
FROM nginx:stable-alpine
COPY site/ /usr/share/nginx/html/
```

#### 3. `.dockerignore` 作成
```gitignore
.git
node_modules
.env
*.log
```

#### 4. ビルド
```bash
docker build -t docker-build-lab:1 .
```

#### 5. 実行
```bash
docker run -d --name docker-build-lab -p 8081:80 docker-build-lab:1
```

#### 6. 確認
- ブラウザ: `http://localhost:8081`
- ログ: `docker logs docker-build-lab`
- レイヤー確認: `docker history docker-build-lab:1`

#### 7. 終了
```bash
docker stop docker-build-lab
docker rm docker-build-lab
```

#### 発展課題
- ベースイメージを変えたときの差を比較する
- `.dockerignore` あり/なしでビルドコンテキストを比較する
- multi-stage build 版 Dockerfile を自作する

## 6) Command cheatsheet
```bash
# イメージビルド
docker build -t myapp:dev .

# イメージ一覧
docker image ls

# レイヤー確認
docker history myapp:dev

# イメージから起動
docker run -d --name myapp -p 8081:80 myapp:dev

# 停止・削除
docker stop myapp
docker rm myapp
```

## 7) Common mistakes and safe practices
### よくあるミス
- `.env` や秘密鍵を build context に含める
- 開発用キャッシュや `node_modules` を丸ごと送る
- root 前提のまま本番運用する
- イメージサイズを確認しない
- 不要なイメージ削除を勢いで実行する

### 安全な実践
- `.dockerignore` を必ず整備する
- 秘密情報は image layer に残さない
- multi-stage build を積極利用する
- ベースイメージの信頼性と更新頻度を確認する
- cleanup 系コマンドは対象を確認してから実行する

### 破壊的 cleanup コマンドの注意
以下は便利ですが、**本当に不要なものだけを削除するか確認してから**使ってください。

```bash
# 未使用リソースをまとめて削除（要注意）
docker system prune

# 未使用イメージ削除（要注意）
docker image prune

# 特定イメージ削除（依存確認）
docker rmi IMAGE_ID

# 強制削除は最後の手段
docker rm -f CONTAINER_NAME
docker rmi -f IMAGE_ID
```

特に共有開発環境や作業途中のローカルでは、`prune` や `-f` を反射的に使わないこと。

## 8) One interview-style question
**質問:** なぜ multi-stage build は本番向け Dockerfile で重要なのですか？サイズ以外の観点も含めて説明してください。

## 9) Next-step resources
- Building best practices: https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Multi-stage builds: https://docs.docker.com/build/building/multi-stage/
- `.dockerignore`: https://docs.docker.com/build/concepts/context/#dockerignore-files
- Image best practices / hardened guidance entry: https://docs.docker.com/dhi/core-concepts/best-practices/

---

# 今日のまとめ
- Beginner では「起動・確認・観察」の基本を固める
- Middle では Compose と `exec` で現実的な開発フローへ進む
- Advanced では Dockerfile 品質とイメージ衛生を意識する

Docker はコマンド暗記より、**再現性・分離・安全性をどう開発に効かせるか**が本質です。今日は `run → compose → build` の流れを通して、その土台を作る回です。
