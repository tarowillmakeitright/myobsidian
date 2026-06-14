---
tags:
  - docker
  - containers
  - devops
  - learning
  - daily
---

[[Home]]

# Docker Commands Magazine — 2026-06-12

#docker #containers #devops #learning #daily

今日は **Beginner → Middle → Advanced** の流れで、実アプリ開発に直結する Docker コマンド学習を進める。
テーマは **「イメージを作る・動かす・安全に育てる」**。

---

## 1) Topic + Level

### Topic
**Docker イメージのビルドとコンテナ実行を、開発現場の流れに沿って理解する**

### Level Arc
- **Beginner:** `docker run` / `docker ps` / `docker logs` でコンテナを扱う
- **Middle:** `docker build` / `docker exec` / `docker compose` の基礎で開発環境を作る
- **Advanced:** 安全で再現性の高い Dockerfile 設計、レイヤー最適化、非 root 実行、Secrets を意識した実践

### Prerequisites
- **Middle の前提:**
  - `docker run` でコンテナを起動・停止できる
  - イメージとコンテナの違いを説明できる
- **Advanced の前提:**
  - Dockerfile を読める
  - `docker build` と `docker compose up` を最低 1 回は使ったことがある
  - ポート公開、ボリューム、環境変数の役割を理解している

---

## 2) Why it matters for real app development

実アプリ開発で Docker が重要なのは、**「自分のマシンでは動くのに、他人の環境や本番では動かない」問題を減らせる**から。

特に現場では以下に効く。

- **開発環境の再現性**
  - Node.js、Python、PostgreSQL、Redis などの依存をチームで揃えやすい
- **オンボーディング高速化**
  - 新メンバーがローカル環境構築で詰まりにくい
- **CI/CD と相性が良い**
  - ローカルと CI でほぼ同じ実行環境を使える
- **本番運用への接続が自然**
  - コンテナ化されたアプリは ECS / Kubernetes / Cloud Run などへ載せやすい
- **依存の分離**
  - 複数プロジェクトで異なるバージョンのランタイムを安全に共存させやすい

ただし、Docker を使えば何でも安全になるわけではない。**イメージに秘密情報を焼き込まない・不要に root で動かさない・不要な破壊コマンドを雑に打たない**のが基本。

---

## 3) Core Docker command explanations

### Beginner

#### `docker run`
イメージからコンテナを作成して起動する。

```bash
docker run --name hello-nginx -p 8080:80 nginx:stable
```

ポイント:
- `--name`: コンテナ名をつける
- `-p 8080:80`: ホストの 8080 番をコンテナの 80 番へ接続
- `nginx:stable`: 使用するイメージ:タグ

#### `docker ps`
起動中のコンテナ一覧を表示する。

```bash
docker ps
```

停止済みも見たいなら:

```bash
docker ps -a
```

#### `docker logs`
コンテナの標準出力・標準エラーを見る。

```bash
docker logs hello-nginx
```

追従するなら:

```bash
docker logs -f hello-nginx
```

#### `docker stop`
コンテナを停止する。

```bash
docker stop hello-nginx
```

#### `docker rm`
停止済みコンテナを削除する。

```bash
docker rm hello-nginx
```

> 注意: `docker rm -f` は実行中コンテナを強制停止して削除する。開発中の未保存データや検証状態を失うことがあるので、まず通常の `docker stop` → `docker rm` を優先する。

---

### Middle

#### `docker build`
Dockerfile から独自イメージを作る。

```bash
docker build -t demo-web:1.0 .
```

ポイント:
- `-t demo-web:1.0`: 名前とタグを付ける
- `.`: ビルドコンテキスト。**このディレクトリ以下がビルド対象として送られる**

#### `docker exec`
起動中コンテナの中でコマンドを実行する。

```bash
docker exec -it hello-nginx sh
```

- `-i`: 標準入力を開く
- `-t`: 擬似 TTY をつける
- `sh`: コンテナ内シェル

#### `docker compose up`
複数コンテナをまとめて起動する。

```bash
docker compose up -d
```

- Web アプリ + DB + Cache のような構成でよく使う
- `-d` はバックグラウンド起動

#### `docker compose logs`
compose 管理下のサービスログを見る。

```bash
docker compose logs -f
```

#### `docker compose down`
compose で起動したサービス群を停止・削除する。

```bash
docker compose down
```

> 注意: `docker compose down -v` はボリュームも削除する。DB データも消えることがあるので、何が消えるか理解してから使う。

---

### Advanced

#### `docker image ls`
ローカルイメージを確認する。

```bash
docker image ls
```

#### `docker inspect`
コンテナやイメージの詳細情報を見る。

```bash
docker inspect hello-nginx
```

ポート、環境変数、マウント、ネットワーク設定の確認に便利。

#### `docker history`
イメージレイヤー履歴を見る。

```bash
docker history demo-web:1.0
```

大きなレイヤーや不要ファイル混入の気づきに役立つ。

#### `docker stats`
コンテナのリソース使用量を監視する。

```bash
docker stats
```

#### `docker builder prune`
不要ビルドキャッシュを削除する。

```bash
docker builder prune
```

> 注意: キャッシュを消すと次回ビルドが遅くなる。空き容量確保が必要なときだけ使う。

#### `docker image prune`
未使用イメージを削除する。

```bash
docker image prune
```

> 注意: `docker system prune` や `docker image prune -a` は影響範囲が広い。どのイメージ・ネットワーク・キャッシュ・停止済みコンテナが消えるかを確認してから実行すること。

---

## 4) How Docker is used while building apps

Docker 公式ドキュメントのベストプラクティスに沿うと、開発中は次の流れがかなり実践的。

### 開発フローの定番
1. **アプリコードを書く**
2. **Dockerfile を作る**
3. **必要最小限のファイルだけを build context に含める**
   - `.dockerignore` を必ず使う
4. **`docker build` でイメージ作成**
5. **`docker run` または `docker compose up` で動作確認**
6. **ログ・exec・inspect で問題調査**
7. **本番向けに小さく安全なイメージへ改善**

### 公式ベストプラクティス寄りの考え方

- **小さいベースイメージを選ぶ**
  - ただし「小さい」だけでなく、メンテされている公式イメージを優先
- **マルチステージビルドを使う**
  - ビルド用ツールを最終イメージに残さない
- **不要ファイルを送らない**
  - `.git`, `node_modules`, ローカル秘密情報, テスト成果物などは `.dockerignore` へ
- **レイヤーキャッシュを意識する**
  - 依存インストールとアプリコードコピー順を工夫する
- **1 コンテナ 1 主要責務を基本にする**
  - Web と DB を 1 コンテナに詰め込みすぎない
- **コンテナを不変な成果物として扱う**
  - 手で中をいじって運用しない
- **Secrets をイメージに含めない**
  - `ENV PASSWORD=...` や `COPY .env /app/.env` は避ける
- **可能なら非 root ユーザーで実行する**
  - 万一侵害されたときの影響を減らす

### 例: よくない Dockerfile

```Dockerfile
FROM node:22
WORKDIR /app
COPY . .
RUN npm install
ENV API_KEY=super-secret-value
CMD ["npm", "start"]
```

問題点:
- `COPY . .` が早すぎてキャッシュ効率が悪い
- 秘密情報をイメージに埋め込んでいる
- `npm install` より `npm ci` が向く場面が多い
- 非 root 実行の配慮がない

### 改善例

```Dockerfile
FROM node:22-alpine AS base
WORKDIR /app

COPY package*.json ./
RUN npm ci --omit=dev

COPY . .

USER node
EXPOSE 3000
CMD ["node", "server.js"]
```

さらに本格運用では:
- 開発依存が必要なら build stage を分ける
- 本番では runtime stage に必要成果物だけを入れる
- Secrets は実行時注入にする

---

## 5) 30-60 minute hands-on mini lab

### ラボテーマ
**シンプルな静的 Web を Docker で動かし、Compose 化し、ログ確認までやる**

### 所要時間
約 40 分

### ゴール
- `docker build` で自作イメージを作る
- `docker run` で公開する
- `docker exec` と `docker logs` で中身を確認する
- `docker compose` で再現可能な開発環境にする

### 手順

#### 1. 作業ディレクトリを作る

```bash
mkdir -p docker-magazine-lab
cd docker-magazine-lab
```

#### 2. `index.html` を作る

```html
<!doctype html>
<html lang="ja">
  <head>
    <meta charset="UTF-8" />
    <title>Docker Lab</title>
  </head>
  <body>
    <h1>Hello Docker</h1>
    <p>このページは Docker コンテナから配信されています。</p>
  </body>
</html>
```

#### 3. `Dockerfile` を作る

```Dockerfile
FROM nginx:stable-alpine
COPY index.html /usr/share/nginx/html/index.html
EXPOSE 80
```

#### 4. イメージをビルド

```bash
docker build -t docker-lab-web:1.0 .
```

#### 5. コンテナ起動

```bash
docker run --name docker-lab-web -d -p 8080:80 docker-lab-web:1.0
```

#### 6. 動作確認
ブラウザで `http://localhost:8080` を開く。

CLI で確認するなら:

```bash
docker ps
docker logs docker-lab-web
```

#### 7. コンテナ内確認

```bash
docker exec -it docker-lab-web sh
```

中で:

```sh
ls /usr/share/nginx/html
cat /usr/share/nginx/html/index.html
exit
```

#### 8. Compose 化する
`compose.yaml` を作る。

```yaml
services:
  web:
    build: .
    container_name: docker-lab-web-compose
    ports:
      - "8081:80"
```

起動:

```bash
docker compose up -d
```

ログ確認:

```bash
docker compose logs -f
```

#### 9. 後片付け
まず停止:

```bash
docker compose down
docker stop docker-lab-web
```

次に削除:

```bash
docker rm docker-lab-web
```

> 破壊的な掃除コマンドはまだ使わなくていい。`prune` 系は「何を消すか把握してから」が基本。

### 余力があれば
- `index.html` を編集して再ビルド
- `docker history docker-lab-web:1.0` を見る
- `.dockerignore` を追加して build context を意識する

---

## 6) Command cheatsheet

### 基本操作

```bash
docker run --name myapp -p 8080:80 nginx:stable
docker ps
docker ps -a
docker logs myapp
docker logs -f myapp
docker stop myapp
docker rm myapp
```

### ビルドと調査

```bash
docker build -t myimage:1.0 .
docker exec -it myapp sh
docker inspect myapp
docker image ls
docker history myimage:1.0
docker stats
```

### Compose

```bash
docker compose up -d
docker compose ps
docker compose logs -f
docker compose down
```

### 掃除系（要注意）

```bash
docker image prune
docker builder prune
docker system prune
```

> 警告:
> - `docker system prune` は未使用リソースを広く消す
> - `docker image prune -a` は未使用イメージを広範囲に消す
> - `docker compose down -v` はボリューム削除を含むことがある
> 本当に消してよいものを確認してから実行すること。

---

## 7) Common mistakes and safe practices

### よくあるミス

#### 1. `.dockerignore` を使わない
結果:
- ビルドが遅い
- 不要ファイルがイメージに入る
- `.env` や秘密鍵が事故混入する

対策例:

```gitignore
node_modules
.git
.env
*.log
dist
coverage
```

#### 2. Secrets を Dockerfile や compose に直書きする
悪い例:

```Dockerfile
ENV DB_PASSWORD=my-password
```

```yaml
environment:
  - DB_PASSWORD=my-password
```

問題:
- イメージ履歴や設定から漏れる可能性
- 共有やコミット時に事故る

安全策:
- 開発でも秘密情報の扱いを分離する
- 実行時注入や専用 secret 管理を使う
- `.env` を使う場合も **コミットしない**、用途を限定する

#### 3. root 前提で何でも実行する
問題:
- 侵害時の影響が大きい

安全策:
- 可能なら `USER` を設定して非 root 実行

#### 4. `latest` に依存しすぎる
問題:
- いつの間にか挙動が変わる

安全策:
- できるだけバージョンタグを明示
  - 例: `nginx:stable-alpine`, `node:22-alpine`

#### 5. 使っているデータの中身を理解せず削除する
危険コマンド例:
- `docker system prune -a`
- `docker rm -f ...`
- `docker rmi ...`
- `docker compose down -v`

安全策:
- 先に `docker ps -a`, `docker image ls`, `docker volume ls` で確認
- 共有開発環境では破壊前に一呼吸置く
- DB ボリュームが消える影響を理解してから実行

#### 6. コンテナ内を手作業で直して満足する
問題:
- 再現できない
- 次回起動で消える

安全策:
- 修正は Dockerfile / compose / ソースコードへ戻す

---

## 8) One interview-style question

**質問:**
`docker run` と `docker build` の違いを説明しつつ、開発チームで再現性のあるローカル環境を配布したい場合に、なぜ Dockerfile と docker compose が役立つのかを話してください。

**考えるポイント:**
- イメージ作成とコンテナ起動の責務の違い
- アプリ + DB + Cache など複数サービス管理
- バージョン固定、設定共有、オンボーディング短縮
- 「コンテナ内で手修正」ではなく「定義ファイルに戻す」重要性

---

## 9) Next-step resources

公式ドキュメント中心で次へ進むならこの順がいい。

- Docker Get Started
  - https://docs.docker.com/get-started/
- Dockerfile のベストプラクティス
  - https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Dockerfile リファレンス
  - https://docs.docker.com/reference/dockerfile/
- Compose 概要
  - https://docs.docker.com/compose/
- Compose file reference
  - https://docs.docker.com/reference/compose-file/
- Image best practices / building best practices 周辺
  - https://docs.docker.com/build/
- Volumes
  - https://docs.docker.com/engine/storage/volumes/
- Secrets の考え方
  - https://docs.docker.com/engine/swarm/secrets/
- Docker Scout / イメージセキュリティ入口
  - https://docs.docker.com/scout/

---

## 今日のひとこと

Docker は「コマンド暗記ゲーム」ではなく、**再現可能で安全な開発環境を定義する習慣**が本体。
まずは `run` と `build` を雑に使えるようにして、次に **compose・Dockerfile・安全なイメージ設計**へ進むと強い。
