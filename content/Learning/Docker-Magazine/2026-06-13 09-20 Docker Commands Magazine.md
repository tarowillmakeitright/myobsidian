---
tags:
  - docker
  - containers
  - devops
  - learning
  - daily
---

[[Home]]

# Docker Commands Magazine — 2026-06-13

今日のテーマは、**Docker でアプリ開発環境を素早く・安全に立ち上げる基本コマンド**です。  
学習アークは **Beginner → Middle → Advanced**。実務での使いどころを意識しつつ、docs.docker.com のベストプラクティスに沿って進めます。

---

## 1) Topic + Level

### Beginner
**テーマ:** `docker run`, `docker ps`, `docker logs`, `docker exec` でコンテナを動かして観察する

### Middle
**テーマ:** `docker build`, `docker compose up`, `docker compose logs` で開発用アプリ環境を組む

**前提知識:**
- Beginner の内容を理解している
- イメージとコンテナの違いがわかる
- ポート公開 (`-p`) の基本がわかる

### Advanced
**テーマ:** 開発効率と安全性を意識した Dockerfile / Compose 運用

**前提知識:**
- Middle の内容を一通り実行できる
- Dockerfile の基本命令 (`FROM`, `WORKDIR`, `COPY`, `RUN`, `CMD`) を見たことがある
- ログ確認・停止・再起動などの日常操作に慣れている

---

## 2) Why it matters for real app development

Docker は「本番に近い環境を、開発者全員が同じ形で再現する」ための土台です。

実務では特に次の点が重要です。

- **環境差分を減らせる**  
  「自分の PC では動くのに他の人の PC では動かない」を減らせます。

- **依存関係を隔離できる**  
  Node.js / Python / PostgreSQL / Redis などのバージョンをプロジェクト単位で固定しやすくなります。

- **オンボーディングが速い**  
  新しいメンバーが `docker compose up` で開発を始めやすくなります。

- **CI/CD や本番運用につながる**  
  ローカル開発だけでなく、テスト・ビルド・デプロイでも同じ考え方を使えます。

- **安全な実験がしやすい**  
  ローカル OS を汚しにくく、不要になればコンテナ単位で掃除できます。

---

## 3) Core Docker command explanations

### `docker run`
コンテナを起動します。

```bash
docker run --name web-test -d -p 8080:80 nginx:alpine
```

- `--name web-test` : コンテナ名を付ける
- `-d` : バックグラウンド実行
- `-p 8080:80` : ホストの 8080 番をコンテナの 80 番へ接続
- `nginx:alpine` : 使用イメージ

### `docker ps`
起動中のコンテナ一覧を確認します。

```bash
docker ps
```

停止済みも含めるなら:

```bash
docker ps -a
```

### `docker logs`
コンテナの標準出力・標準エラーを見ます。

```bash
docker logs web-test
```

追尾するなら:

```bash
docker logs -f web-test
```

### `docker exec`
起動中コンテナの中でコマンドを実行します。

```bash
docker exec -it web-test sh
```

- `-i` : 標準入力を開く
- `-t` : 疑似 TTY を付ける

### `docker build`
Dockerfile からイメージを作ります。

```bash
docker build -t myapp:dev .
```

- `-t myapp:dev` : イメージ名:タグ
- `.` : ビルドコンテキスト

### `docker compose up`
複数サービスをまとめて起動します。

```bash
docker compose up -d
```

### `docker compose logs`
Compose 管理下のサービスログを確認します。

```bash
docker compose logs -f
```

### `docker stop` / `docker rm`
停止・削除の基本です。

```bash
docker stop web-test
docker rm web-test
```

### `docker images`
ローカルにあるイメージ一覧を確認します。

```bash
docker images
```

---

## 4) How Docker is used while building apps

Docker のベストプラクティスに沿うと、アプリ開発中は次のような使い方になります。

### 4-1. 開発環境をコードとして定義する
`Dockerfile` と `compose.yaml` をリポジトリに置き、チーム全員が同じ手順で起動できるようにします。

- アプリ本体: Dockerfile
- 複数サービス連携: Compose
- 環境変数: `.env` や秘密管理の仕組みを使う

### 4-2. 1 コンテナ 1 主要責務を意識する
たとえば:

- `app` : Web アプリ
- `db` : PostgreSQL
- `redis` : キャッシュ

全部を 1 コンテナに詰め込むより、役割を分けた方が保守しやすいです。

### 4-3. 小さくて明確なイメージを作る
実務では軽量なベースイメージやマルチステージビルドが有効です。

- 必要なものだけ入れる
- 不要なビルド成果物を最終イメージへ持ち込まない
- `.dockerignore` を使って無駄なファイル送信を避ける

### 4-4. 秘密情報をイメージへ焼き込まない
**重要:**

- `ENV API_KEY=...` を Dockerfile に直書きしない
- `COPY . .` で `.env` や秘密鍵を巻き込まない
- Compose に秘密情報を平文で固定しない

開発でも本番でも、**シークレットはイメージ外で扱う**のが基本です。

### 4-5. コンテナの中身より、再現可能な定義を信頼する
手で `docker exec` してその場で直すより、Dockerfile や Compose に反映して再現可能にする方が安全です。

### 4-6. 破壊的な掃除コマンドは慎重に使う
以下は便利ですが危険です。

```bash
# 危険: 未使用リソースをまとめて削除する
# 実行前に本当に消していいか確認すること
docker system prune

docker image prune -a

docker container rm -f <container>

docker rmi <image>
```

**警告:** 共有中の開発イメージ・停止中の検証コンテナ・キャッシュが消えると、再構築に時間がかかったり、作業状態を失うことがあります。

---

## 5) 30-60 minute hands-on mini lab

### ミニラボ: Nginx コンテナを動かし、Compose 化し、設定変更を反映する

所要時間: **約 40 分**

### Step 1: 単体コンテナで Nginx を起動

```bash
docker run --name docker-mag-nginx -d -p 8080:80 nginx:alpine
```

確認:

```bash
docker ps
docker logs docker-mag-nginx
```

ブラウザで `http://localhost:8080` を開く。

### Step 2: コンテナ内部を確認

```bash
docker exec -it docker-mag-nginx sh
```

中で確認:

```sh
ls /usr/share/nginx/html
cat /etc/nginx/conf.d/default.conf
exit
```

### Step 3: ローカル作業ディレクトリを作る

```bash
mkdir -p docker-magazine-lab
cd docker-magazine-lab
mkdir -p html
printf '<h1>Hello Docker Magazine</h1>\n' > html/index.html
```

### Step 4: Compose ファイルを作る

`compose.yaml`

```yaml
services:
  web:
    image: nginx:alpine
    ports:
      - "8081:80"
    volumes:
      - ./html:/usr/share/nginx/html:ro
```

起動:

```bash
docker compose up -d
```

確認:

```bash
docker compose ps
docker compose logs -f
```

ブラウザで `http://localhost:8081` を開く。

### Step 5: ホットに近い感覚でコンテンツ変更

```bash
printf '<h1>Updated from local volume</h1>\n' > html/index.html
```

ブラウザを再読み込みして、ローカル変更がコンテナに反映されることを確認します。

### Step 6: 安全に停止・片付け

```bash
docker compose down
docker stop docker-mag-nginx
docker rm docker-mag-nginx
```

### 追加課題（Middle 向け）
- `Dockerfile` を作って独自の静的サイトイメージをビルドする
- `EXPOSE 80` の意味を調べる
- `.dockerignore` を追加して、不要ファイルをビルド対象から外す

### 追加課題（Advanced 向け）
- `nginx:alpine` をベースに独自イメージを作る
- `COPY html/ /usr/share/nginx/html/` 方式と bind mount の違いを整理する
- Compose で `read_only` や `tmpfs` の利用可否を調べる

---

## 6) Command cheatsheet

```bash
# イメージ取得
docker pull nginx:alpine

# コンテナ起動
docker run --name sample -d -p 8080:80 nginx:alpine

# 起動中コンテナ確認
docker ps

# 全コンテナ確認
docker ps -a

# ログ確認
docker logs sample
docker logs -f sample

# コンテナ内部でシェル
docker exec -it sample sh

# 停止
docker stop sample

# 削除
docker rm sample

# イメージ一覧
docker images

# ビルド
docker build -t myapp:dev .

# Compose 起動
docker compose up -d

# Compose 停止・削除
docker compose down

# Compose ログ
docker compose logs -f
```

---

## 7) Common mistakes and safe practices

### よくあるミス

- **`latest` タグを当然のように使う**  
  意図しない更新で挙動が変わることがあります。

- **`COPY . .` を雑に使う**  
  `.git`, `node_modules`, `.env`, 秘密鍵まで入る事故が起きやすいです。

- **開発用と本番用の設定を混同する**  
  bind mount は便利ですが、本番でそのまま使う設計とは限りません。

- **ログを見ずに再起動を繰り返す**  
  まず `docker logs` / `docker compose logs` を確認する方が早いです。

- **破壊的コマンドを勢いで打つ**  
  `prune`, `rmi`, `rm -f` は要注意です。

### 安全な実践

- イメージタグを明示する（例: `nginx:1.27-alpine`）
- `.dockerignore` を必ず整える
- 秘密情報を Dockerfile やイメージへ埋め込まない
- 開発では bind mount、本番では再現可能なイメージを重視する
- 削除系コマンドの前に `docker ps -a`, `docker images`, `docker volume ls` を確認する
- まず停止し、必要性を確認してから削除する

---

## 8) One interview-style question

**質問:**  
`docker run -p 8080:80 nginx:alpine` の `8080:80` は何を意味しますか？ また、アプリ開発でこのポートマッピングを誤るとどんな問題が起こりますか？

**考えるポイント:**
- ホスト側ポートとコンテナ側ポートの違い
- ブラウザや API クライアントがどこへ接続するか
- 複数サービスのポート競合

---

## 9) Next-step resources

まずは公式ドキュメント優先で進めるのが堅実です。

- Docker Get Started  
  https://docs.docker.com/get-started/

- Dockerfile overview  
  https://docs.docker.com/build/concepts/dockerfile/

- Image build best practices  
  https://docs.docker.com/build/building/best-practices/

- Docker Compose overview  
  https://docs.docker.com/compose/

- Compose file reference  
  https://docs.docker.com/reference/compose-file/

- Bind mounts  
  https://docs.docker.com/engine/storage/bind-mounts/

- Multi-stage builds  
  https://docs.docker.com/build/building/multi-stage/

- Docker Engine security  
  https://docs.docker.com/engine/security/

---

## まとめ

今日は **Docker の基本コマンドを、実務のアプリ開発につながる形で整理**しました。  
Beginner では「動かす・見る」、Middle では「Compose でまとめる」、Advanced では「安全性・再現性・保守性を高める」という流れです。

特に大事なのは次の 4 点です。

1. `docker run`, `ps`, `logs`, `exec` をまず確実に使えるようにする  
2. 開発環境は Dockerfile / Compose で再現可能にする  
3. 秘密情報をイメージへ入れない  
4. `prune`, `rmi`, `rm -f` などの破壊的コマンドは必ず確認してから使う

明日は、**Dockerfile の書き方をもう一段実務寄りにして、レイヤー・キャッシュ・`.dockerignore` の設計**まで深掘りすると伸びます。
