---
tags:
  - docker
  - containers
  - devops
  - learning
  - daily
---

[[Home]]

# 2026-06-08 09:20 Docker Commands Magazine

**Topic:** Dockerコマンドで学ぶ、開発用コンテナの作成・実行・保守

この号は、**Beginner → Middle → Advanced** の流れで、アプリ開発で実際によく使う Docker コマンドを段階的に学ぶ構成です。今日は「イメージを作る」「コンテナを動かす」「安全に片付ける」を軸に進めます。

---

# 1. Beginner

## Topic + Level
**レベル:** Beginner  
**テーマ:** `docker build` / `docker run` / `docker ps` / `docker logs` の基本

## Why it matters for real app development
ローカル開発で「自分のPCでは動くのに他人の環境では動かない」という問題はとても多いです。Docker を使うと、アプリの実行環境をイメージとして固めて共有できるため、チーム開発・検証・CI で再現性が高まります。

特に実務では以下が重要です。

- Node.js / Python / Go などの実行環境を統一できる
- 新メンバーのセットアップ時間を短縮できる
- 本番に近い構成をローカルで試しやすい
- 依存関係の汚染をホストOSに残しにくい

## Core Docker command explanations

### `docker build`
Dockerfile からイメージを作成します。

```bash
docker build -t demo-web:1.0 .
```

- `-t` はタグ付け
- `.` はビルドコンテキスト
- 実務では **不要ファイルを `.dockerignore` で除外** するのが大事

### `docker run`
イメージからコンテナを起動します。

```bash
docker run --name demo-web -p 8080:8080 demo-web:1.0
```

- `--name` でコンテナ名を固定
- `-p 8080:8080` でホストとコンテナのポートを接続
- まずは明示的な名前付けが管理しやすい

### `docker ps`
起動中のコンテナ一覧を確認します。

```bash
docker ps
```

停止済みも含めて見るなら:

```bash
docker ps -a
```

### `docker logs`
コンテナの標準出力・標準エラーを確認します。

```bash
docker logs demo-web
```

追尾するなら:

```bash
docker logs -f demo-web
```

## How Docker is used while building apps
Docker公式ドキュメントのベストプラクティスに沿うと、開発中は以下を意識すると良いです。

- **小さく分かりやすい Dockerfile を保つ**
- **ベースイメージは信頼できる公式イメージを使う**
- **不要なファイルを build context に入れない**
- **コンテナは使い捨て前提で設計する**
- **設定値や秘密情報をイメージに焼き込まない**

たとえば API サーバー開発では、ソースコードをコンテナで動かし、ログ確認やポート公開を通じて挙動を検証します。アプリ本体は Dockerfile、実行時設定は環境変数や Compose 側で分離するのが基本です。

## 30-60 minute hands-on mini lab
**目標:** シンプルな HTTP サーバーを Docker で動かす

### 手順
1. 作業ディレクトリを作成
2. `index.html` を用意
3. `Dockerfile` を作る
4. イメージをビルド
5. コンテナ起動
6. ブラウザで確認
7. ログ確認
8. 停止と削除

### サンプルファイル

**index.html**
```html
<h1>Hello Docker</h1>
<p>Daily Docker Magazine Lab</p>
```

**Dockerfile**
```Dockerfile
FROM nginx:stable-alpine
COPY index.html /usr/share/nginx/html/index.html
EXPOSE 80
```

### コマンド
```bash
mkdir docker-lab-hello
cd docker-lab-hello

cat > index.html <<'EOF'
<h1>Hello Docker</h1>
<p>Daily Docker Magazine Lab</p>
EOF

cat > Dockerfile <<'EOF'
FROM nginx:stable-alpine
COPY index.html /usr/share/nginx/html/index.html
EXPOSE 80
EOF

docker build -t docker-lab-hello:1.0 .
docker run --name docker-lab-hello -p 8080:80 -d docker-lab-hello:1.0
docker ps
docker logs docker-lab-hello
```

確認:
- ブラウザで `http://localhost:8080`

片付け:
```bash
docker stop docker-lab-hello
docker rm docker-lab-hello
```

## Command cheatsheet
```bash
docker build -t NAME:TAG .
docker run --name NAME -p HOST_PORT:CONTAINER_PORT IMAGE:TAG
docker run -d --name NAME IMAGE:TAG
docker ps
docker ps -a
docker logs NAME
docker logs -f NAME
docker stop NAME
docker rm NAME
```

## Common mistakes and safe practices
**よくあるミス**
- `docker build` のコンテキストに `.git` や `node_modules` を含めてしまう
- アプリが待ち受けるポートと `-p` のポートを混同する
- `docker logs` を見ずに「起動していない」と決めつける
- コンテナ名を毎回ランダム任せにして管理しづらくする

**安全な実践**
- `.dockerignore` を必ず使う
- 公式または信頼できるベースイメージを使う
- 秘密情報を `Dockerfile` に `ENV` や `COPY` で埋め込まない
- 不要になったコンテナだけを個別に止めて削除する

## Interview-style question
「`docker build` と `docker run` の役割の違いを説明してください。また、開発現場で両者をどう使い分けますか？」

## Next-step resources
- Docker overview: https://docs.docker.com/get-started/docker-overview/
- Build an image: https://docs.docker.com/get-started/docker-concepts/building-images/
- Run a container: https://docs.docker.com/get-started/docker-concepts/running-containers/
- Dockerfile best practices: https://docs.docker.com/develop/develop-images/dockerfile_best-practices/

---

# 2. Middle

## Topic + Level
**レベル:** Middle  
**テーマ:** `docker exec` / `docker inspect` / `docker cp` / `docker compose up`

**前提知識:**
- `docker build` と `docker run` の基本が分かる
- コンテナとイメージの違いを説明できる
- ポート公開の概念を知っている

## Why it matters for real app development
実務で必要なのは「起動できた」で終わらず、**中に入って調査する・設定を確認する・複数サービスをまとめて扱う**ことです。API サーバー、DB、Redis などが絡むと、単一コンテナだけでは足りません。

Middle レベルのコマンドは、障害調査とチーム開発に直結します。

- `docker exec`: 動作中コンテナの内部確認
- `docker inspect`: 設定・ネットワーク・マウント情報の確認
- `docker cp`: ファイルの持ち出し・投入
- `docker compose up`: 複数サービスのまとめ起動

## Core Docker command explanations

### `docker exec`
起動中コンテナ内でコマンドを実行します。

```bash
docker exec -it myapp sh
```

- Alpine 系なら `sh`、Debian/Ubuntu 系なら `bash` があることが多い
- 調査用には便利だが、**手作業で内部を変更しても再現性がない** ので常用しない

### `docker inspect`
コンテナやイメージの詳細情報を JSON で確認します。

```bash
docker inspect myapp
```

例: IP アドレスだけ見たいとき

```bash
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' myapp
```

### `docker cp`
ホストとコンテナ間でファイルコピーします。

```bash
docker cp myapp:/app/log.txt ./log.txt
```

### `docker compose up`
複数コンテナをまとめて起動します。

```bash
docker compose up -d
```

- 開発アプリ + DB のような構成で非常によく使う
- 実務では `compose.yaml` でサービス定義をコード管理する

## How Docker is used while building apps
Docker 公式の実践に合わせると、アプリ構築時は次の流れが自然です。

- アプリコンテナとDBを Compose で定義する
- ソースコード変更時は必要に応じて再ビルドする
- 調査は `docker logs` を優先し、必要時のみ `docker exec`
- 設定の確認は `docker inspect` を使う
- 開発の再現性は Dockerfile / Compose に寄せる

つまり、**「手で直す」より「定義に戻す」** のが正解です。これが CI/CD や本番運用にそのままつながります。

## 30-60 minute hands-on mini lab
**目標:** Web + Redis の 2 サービス構成を Compose で起動し、コンテナ調査を行う

### `compose.yaml`
```yaml
services:
  web:
    image: nginx:stable-alpine
    ports:
      - "8081:80"
  redis:
    image: redis:7-alpine
```

### 手順
```bash
mkdir docker-lab-compose
cd docker-lab-compose

cat > compose.yaml <<'EOF'
services:
  web:
    image: nginx:stable-alpine
    ports:
      - "8081:80"
  redis:
    image: redis:7-alpine
EOF

docker compose up -d
docker compose ps
docker ps
docker inspect docker-lab-compose-web-1
docker exec -it docker-lab-compose-redis-1 redis-cli ping
```

期待する結果:
- `web` が 8081 で応答
- Redis に `PONG` が返る

追加調査:
```bash
docker logs docker-lab-compose-web-1
docker inspect -f '{{json .Mounts}}' docker-lab-compose-web-1
```

片付け:
```bash
docker compose down
```

## Command cheatsheet
```bash
docker exec -it CONTAINER sh
docker inspect CONTAINER
docker inspect -f '{{.Name}}' CONTAINER
docker cp CONTAINER:/path/in/container ./local-path
docker compose up -d
docker compose ps
docker compose logs
docker compose down
```

## Common mistakes and safe practices
**よくあるミス**
- `docker exec` で修正した内容が永続化されると思い込む
- Compose のサービス名とコンテナ名の違いで混乱する
- `docker inspect` の出力が大きすぎて必要項目を見失う
- DB や Redis を外部公開しなくてよいのに `ports` を開けてしまう

**安全な実践**
- まず `docker logs` と `docker compose logs` で状況確認
- 本当に必要なサービスだけ `ports` 公開する
- 内部サービスは Compose のデフォルトネットワークで閉じる
- 秘密情報を `compose.yaml` に直書きしない
- `.env` を使う場合も、機密値を Git 管理しない

## Interview-style question
「`docker exec` で設定を直す方法と、Dockerfile / Compose を更新して再作成する方法では、なぜ後者が実務向きなのでしょうか？」

## Next-step resources
- Docker Compose overview: https://docs.docker.com/compose/
- Compose getting started: https://docs.docker.com/compose/gettingstarted/
- Networking in Compose: https://docs.docker.com/compose/how-tos/networking/
- `docker inspect` reference: https://docs.docker.com/reference/cli/docker/inspect/

---

# 3. Advanced

## Topic + Level
**レベル:** Advanced  
**テーマ:** `docker image ls` / `docker history` / `docker stats` / 安全なクリーンアップ運用

**前提知識:**
- Dockerfile と Compose の基本が使える
- コンテナの調査 (`logs`, `exec`, `inspect`) を経験済み
- イメージとレイヤーの概念をある程度理解している

## Why it matters for real app development
Advanced で重要なのは、**サイズ・性能・セキュリティ・保守性** です。開発が進むほど、イメージ肥大化・不要リソース蓄積・秘密情報混入・調査しづらい Dockerfile が問題になります。

実務でよくある課題:
- CI が遅い
- イメージサイズが大きい
- 不要レイヤーが多い
- コンテナがメモリを食いすぎる
- 雑なクリーンアップで必要なものまで消す

## Core Docker command explanations

### `docker image ls`
ローカルイメージ一覧を確認します。

```bash
docker image ls
```

サイズやタグの重複を見るのに便利です。

### `docker history`
イメージのレイヤー履歴を確認します。

```bash
docker history demo-web:1.0
```

- どの命令でサイズが増えたか見える
- 不要な `RUN` や大きいコピーを見直すヒントになる

### `docker stats`
コンテナのリソース使用状況を確認します。

```bash
docker stats
```

- CPU / Memory / Net I/O をざっくり監視できる
- 開発中のメモリ食いすぎ調査に有効

### クリーンアップ系コマンド
たとえば以下があります。

```bash
docker image prune
docker container prune
docker system prune
```

**注意:** これらは削除系です。特に `prune` は範囲を理解せずに使うと、必要なキャッシュや停止中コンテナを消してしまいます。実行前に必ず影響範囲を確認してください。

さらに危険度が上がる例:

```bash
docker system prune -a
docker rmi IMAGE_ID
docker rm -f CONTAINER
```

- `-a` は未使用イメージまで広く削除
- `rmi` は参照関係次第で影響大
- `rm -f` は強制停止を伴うため調査前に使わない

## How Docker is used while building apps
Docker 公式ベストプラクティスと実務感覚を合わせると、Advanced では次を強く意識します。

- **小さいベースイメージ** を検討する
- **マルチステージビルド** でビルド依存を最終イメージに残さない
- **不要ファイルを送らない** (`.dockerignore`)
- **1コンテナ1責務** を基本にする
- **シークレットをイメージや Compose に直書きしない**
- **定期クリーンアップは手当たり次第にやらず、影響確認してから実施**

例として、アプリのビルド成果物だけを最終イメージへコピーし、開発ツールやキャッシュを含めない設計は本番運用で非常に効果的です。

## 30-60 minute hands-on mini lab
**目標:** イメージの重さとレイヤーを観察し、安全な削除判断を練習する

### 手順
1. 既存の学習用イメージ一覧を見る
2. 1つ選んで `history` を確認
3. `stats` でリソースを見る
4. すぐ削除せず、まず未使用かどうか確認する

### コマンド例
```bash
docker image ls
docker history docker-lab-hello:1.0
docker ps
docker stats --no-stream
```

未使用確認の考え方:
- 今動いているコンテナがそのイメージを使っていないか
- 別プロジェクトの Compose が参照していないか
- 再ビルドに時間がかかるキャッシュではないか

安全寄りの片付け例:
```bash
docker container ls -a
docker image ls
docker image prune
```

**警告:** `docker image prune` は未使用イメージ削除です。実行前に一覧を確認してください。学習環境以外や仕事中のマシンでは、他プロジェクトへの影響を考えてから実行すること。

より広範囲な削除コマンドは、内容を理解してから:
```bash
docker system prune
```

**強い警告:** `docker system prune`, `docker system prune -a`, `docker rmi`, `docker rm -f` は便利ですが破壊的です。勢いで打たず、対象確認 → 停止確認 → 必要ならバックアップ、の順で進めること。

## Command cheatsheet
```bash
docker image ls
docker history IMAGE:TAG
docker stats
docker stats --no-stream
docker image prune
docker container prune
docker system prune
```

## Common mistakes and safe practices
**よくあるミス**
- イメージサイズを見ずに放置する
- `docker system prune -a` を意味を理解せず実行する
- Build 時に `.env` や秘密鍵をコンテキストへ含める
- 調査のために `latest` だけ使い続けて履歴管理しない

**安全な実践**
- イメージはタグ付けを明示する
- 破壊系コマンドは `ls` / `ps` / `inspect` で事前確認する
- 本番や共有環境では削除作業の影響範囲を必ず把握する
- シークレットは Dockerfile に埋め込まない
- Compose にも API キーやパスワードを直書きしない
- マルチステージビルドと `.dockerignore` を活用する

## Interview-style question
「Docker イメージを小さく安全に保つために、あなたなら Dockerfile・build context・運用コマンドの3つの観点から何を改善しますか？」

## Next-step resources
- Image best practices: https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Multi-stage builds: https://docs.docker.com/build/building/multi-stage/
- CLI reference: https://docs.docker.com/reference/cli/docker/
- `docker image prune` reference: https://docs.docker.com/reference/cli/docker/image/prune/
- `docker system prune` reference: https://docs.docker.com/reference/cli/docker/system/prune/

---

# 今日のまとめ

今日は Docker コマンドを、単なる丸暗記ではなく**アプリ開発の流れに沿って**整理しました。

- **Beginner:** build / run / ps / logs
- **Middle:** exec / inspect / cp / compose up
- **Advanced:** image ls / history / stats / 安全な cleanup

大事なのは、Docker を「便利な実行ツール」としてだけでなく、**再現性・保守性・セキュリティを支える開発基盤**として扱うことです。

明日以降は次の学習アークにつなげやすいです。

- Beginner → ボリュームとデータ永続化
- Middle → Compose でアプリ + DB + 環境変数管理
- Advanced → マルチステージビルドと CI/CD 連携
