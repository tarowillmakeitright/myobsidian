---
tags:
  - docker
  - containers
  - devops
  - learning
  - daily
---

[[Home]]

# 2026-06-18 09-20 Docker Commands Magazine

## 今日のテーマ
**Docker Compose で複数コンテナ開発を回す実践アーク**
- **Beginner:** `docker compose up` / `docker compose ps` / `docker compose logs`
- **Middle:** Web + DB 構成でのネットワーク・ボリューム・環境変数設計
- **Advanced:** 開発向け Compose 設計、ヘルスチェック、override、イメージ/シークレットの安全運用

---

# 1) Topic + Level

## Beginner
**テーマ:** `docker compose up` で複数サービスをまとめて起動する

## Middle
**テーマ:** アプリ開発でよくある「Web + DB」構成を Compose で扱う

**前提条件:**
- `docker run` で単一コンテナを起動したことがある
- `docker ps` と `docker logs` の意味がわかる
- イメージとコンテナの違いを説明できる

## Advanced
**テーマ:** 本番を意識して Compose を安全・保守的に使う

**前提条件:**
- Compose ファイルを1回以上書いたことがある
- ボリューム、ポート公開、環境変数の基本を理解している
- Dockerfile と Compose の役割分担をざっくり理解している

---

# 2) Why it matters for real app development

実アプリは、単一コンテナだけで完結しないことが多いです。たとえば:

- Web アプリ
- PostgreSQL / MySQL などの DB
- Redis などのキャッシュ
- ワーカー
- リバースプロキシ

これを毎回 `docker run ...` で手作業起動すると、引数ミス・起動順ミス・設定のズレが起きやすくなります。`docker compose` を使うと、**複数サービスの構成をコードとして残せる**ので、次の価値があります。

- **新規参加者の立ち上がりが速い**
- **ローカル開発環境を再現しやすい**
- **依存サービス込みで検証できる**
- **設定差分をレビューしやすい**
- **CI や将来の本番構成との接続点になる**

要するに Compose は、単なる起動ショートカットではなく、**開発環境の設計図**です。

---

# 3) Core Docker command explanations

## Beginner: `docker compose up`
Compose ファイルを読み、定義された複数サービスをまとめて起動します。

```bash
docker compose up
```

よく使う形:

```bash
docker compose up -d
```

- `-d`: バックグラウンド起動

初回はイメージ作成が必要なこともあるので、明示的にこう使うこともあります。

```bash
docker compose up --build -d
```

- `--build`: 起動前にイメージを再ビルド

## Beginner: `docker compose ps`
Compose で管理しているサービスの状態を確認します。

```bash
docker compose ps
```

見るポイント:
- どのサービスが起動中か
- ポート公開が意図どおりか
- `Exited` になっていないか

## Beginner: `docker compose logs`
複数サービスのログをまとめて確認します。

```bash
docker compose logs
```

特定サービスだけ見る:

```bash
docker compose logs web
docker compose logs db
```

追従表示:

```bash
docker compose logs -f web
```

## Middle: `docker compose exec`
起動中コンテナの中でコマンドを実行します。

```bash
docker compose exec web sh
```

よくある用途:
- アプリコンテナに入って確認
- migration 実行
- DB クライアント起動

## Middle: `docker compose down`
Compose で起動したリソースを停止・削除します。

```bash
docker compose down
```

**注意:** ボリュームまで消す場合は影響が大きくなります。

```bash
docker compose down -v
```

`-v` は DB データなど永続化データを削除する可能性があるため、**本当に消してよいか確認してから**使ってください。

## Advanced: `docker compose config`
Compose の設定がどう解釈されるかを確認できます。

```bash
docker compose config
```

利点:
- YAML ミスの発見
- 環境変数展開後の確認
- override の合成結果確認

Compose を「書いて終わり」にせず、**実際にどう解釈されるか**まで見るのが安全です。

---

# 4) How Docker is used while building apps

Docker 公式ドキュメントのベストプラクティスに沿うと、Compose は「全部を1ファイルに雑に詰める」道具ではありません。**アプリ構築の役割分担を明確にする**のが大事です。

## 基本の役割分担

- **Dockerfile**: 1サービスのイメージをどう作るか
- **compose.yaml**: 複数サービスをどう組み合わせるか

## 実務でよくある流れ

1. アプリの Dockerfile を作る
2. DB や Redis を Compose に追加する
3. アプリと依存サービスを同じネットワークで接続する
4. 開発用ボリュームをマウントする
5. `docker compose up` で全体起動
6. `docker compose logs`, `exec`, `ps` でデバッグする

## docs.docker.com に沿って意識したいポイント

- **Compose ファイルに責務を持たせすぎない**
  - ビルド手順は Dockerfile へ、構成は Compose へ
- **環境ごとの差分は override や env で管理する**
  - 開発・テスト・本番で役割を分ける
- **秘密情報を image や compose に直書きしない**
  - `environment:` に API キーをベタ書きしない
- **永続データはボリュームで管理する**
  - DB データをコンテナ内部だけに依存しない
- **サービス名による名前解決を活用する**
  - 例: `db` というサービス名で接続する
- **ヘルスチェックや readiness を意識する**
  - 起動順だけでなく「使える状態か」を見る
- **ローカル開発用と本番用を混同しない**
  - ソースコード bind mount は便利だが、本番向けには別設計

## 避けたい秘密情報の扱い

悪い例:

```yaml
services:
  web:
    environment:
      DB_PASSWORD: super-secret-password
      API_TOKEN: hardcoded-token
```

避ける理由:
- Git に載りやすい
- 画面共有・ログ・レビューで漏れやすい
- 開発用設定がそのまま本番へ流れ込みやすい

代替案:
- `.env` を使う場合も管理を厳密にする
- `.env` をイメージへ `COPY` しない
- 本番では Secret 管理機構やデプロイ基盤側の安全な注入を使う

---

# 5) 30-60 minute hands-on mini lab

## ラボ名
**Node.js Web + PostgreSQL を Compose で立ち上げる**

**所要時間:** 45〜60分

## 目標
- `docker compose up` で複数サービスを起動する
- `docker compose ps` / `logs` / `exec` を使えるようになる
- ボリュームとサービス間通信の意味を体感する
- 危険な削除オプションを理解する

## 構成
- `web`: Node.js コンテナ
- `db`: PostgreSQL コンテナ

## 手順

### Step 1. 作業ディレクトリ作成

```bash
mkdir docker-compose-magazine-lab
cd docker-compose-magazine-lab
```

### Step 2. `compose.yaml` を作成

```bash
cat > compose.yaml <<'EOF'
services:
  web:
    image: node:22-alpine
    working_dir: /app
    command: sh -c "node server.js"
    volumes:
      - ./app:/app
    ports:
      - "8080:3000"
    environment:
      DB_HOST: db
      DB_PORT: 5432
      DB_NAME: appdb
      DB_USER: appuser
      DB_PASSWORD: apppass
    depends_on:
      - db

  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: appdb
      POSTGRES_USER: appuser
      POSTGRES_PASSWORD: apppass
    volumes:
      - pgdata:/var/lib/postgresql/data
    ports:
      - "5432:5432"

volumes:
  pgdata:
EOF
```

**補足:** このラボでは学習のため平文パスワードを使っています。実務ではこのまま Git 管理しないこと。特に本番相当環境では Secret 管理を使うこと。

### Step 3. アプリファイルを作成

```bash
mkdir -p app
cat > app/server.js <<'EOF'
const http = require('http');

const config = {
  DB_HOST: process.env.DB_HOST,
  DB_PORT: process.env.DB_PORT,
  DB_NAME: process.env.DB_NAME,
  DB_USER: process.env.DB_USER,
};

const server = http.createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
  res.end(JSON.stringify({
    message: 'Docker Compose lab is running',
    db: config,
    now: new Date().toISOString()
  }, null, 2));
});

server.listen(3000, () => {
  console.log('web service listening on port 3000');
});
EOF
```

### Step 4. 起動

```bash
docker compose up -d
```

### Step 5. 状態確認

```bash
docker compose ps
```

### Step 6. ログ確認

```bash
docker compose logs web
docker compose logs db
```

追従確認:

```bash
docker compose logs -f web
```

### Step 7. 動作確認

```bash
curl http://localhost:8080
```

期待すること:
- Web コンテナが起動している
- `db` というサービス名がアプリ設定に入っている
- Compose が同一ネットワークを自動で作るイメージが掴める

### Step 8. コンテナ内に入る

```bash
docker compose exec web sh
```

コンテナ内で確認:

```bash
ls -la
cat server.js
exit
```

### Step 9. 設定の解釈を見る

```bash
docker compose config
```

### Step 10. 片付け
まず通常停止:

```bash
docker compose down
```

**注意:** 次は DB データも削除する可能性があります。必要なデータがないと確信できる場合だけ使ってください。

```bash
docker compose down -v
```

さらに `docker system prune` や `docker volume prune` は他の開発環境にも影響することがあります。**何が消えるか確認してから**実行してください。

---

# 6) Command cheatsheet

## 基本

```bash
docker compose up
docker compose up -d
docker compose up --build -d
docker compose ps
docker compose logs
docker compose logs -f web
docker compose exec web sh
docker compose down
```

## 確認系

```bash
docker compose config
docker compose images
docker compose top
docker compose ls
```

## 注意が必要な停止・削除系

```bash
docker compose down -v
docker image prune
docker volume prune
docker system prune
```

**警告:** これらは不要データだけでなく、今後使う予定のキャッシュ・ボリューム・停止中コンテナまで消すことがあります。特に `prune` 系は実行前に影響範囲を確認してください。

---

# 7) Common mistakes and safe practices

## よくあるミス

### 1. Compose と Dockerfile の役割を混ぜる
結果:
- 設定が散らかる
- どこを直すべきかわかりにくい

安全策:
- イメージの作り方は Dockerfile
- 複数サービス構成は Compose

### 2. `depends_on` だけで「DB 準備完了」と思い込む
結果:
- アプリが先に接続して失敗する

安全策:
- ヘルスチェックを使う
- アプリ側で再試行ロジックを持つ
- 起動順と readiness を分けて考える

### 3. パスワードや API キーを compose.yaml に直書きする
結果:
- Git 経由で漏えいしやすい
- 開発設定がそのまま共有される

安全策:
- 本番では Secret 管理を使う
- 開発でも取り扱いを分ける
- `.env` を安易に image へ含めない

### 4. DB データを消すつもりなく `down -v` を実行する
結果:
- 開発データ消失
- 検証状態が再現できない

安全策:
- まず `docker compose down` だけで止める
- `-v` はデータ削除の意味を理解した上で使う

### 5. 不要にホストへポートを公開する
結果:
- ローカルでも露出が増える
- 競合や誤接続の原因になる

安全策:
- 必要なサービスだけ公開する
- DB は原則アプリから内部接続で十分か考える

### 6. 開発便利設定を本番想定に持ち込む
例:
- bind mount 前提
- root 実行前提
- デバッグオプション常時有効

安全策:
- 開発用 override を分ける
- 本番相当の Compose は最小権限・最小公開を意識する

---

# 8) One interview-style question

**質問:**
`docker compose` を使う利点を、単に「複数コンテナをまとめて起動できる」以外の観点から説明してください。開発体験、再現性、チーム運用、安全性の4観点を入れて答えてみてください。

---

# 9) Next-step resources

公式ドキュメント優先で読むと変な癖がつきにくいです。

- Docker Compose overview  
  <https://docs.docker.com/compose/>
- Compose file reference  
  <https://docs.docker.com/reference/compose-file/>
- Compose CLI reference  
  <https://docs.docker.com/reference/cli/docker/compose/>
- Environment variables in Compose  
  <https://docs.docker.com/compose/how-tos/environment-variables/set-environment-variables/>
- Use secrets with Compose  
  <https://docs.docker.com/compose/how-tos/use-secrets/>
- Volumes  
  <https://docs.docker.com/engine/storage/volumes/>
- Networking in Compose  
  <https://docs.docker.com/compose/how-tos/networking/>
- Best practices for writing Dockerfiles  
  <https://docs.docker.com/develop/develop-images/dockerfile_best-practices/>

次の自然なステップ:
- `docker compose watch`
- 開発用 `compose.override.yaml`
- PostgreSQL へ実際に接続するアプリ化
- `healthcheck` と migration コンテナの導入

---

## ひとことまとめ
今日は `docker compose` を軸に、**単一コンテナから複数サービス開発へ進む一歩**を整理しました。実務で強いのは、起動コマンドを覚えることよりも、**構成をコード化しつつ、データ削除や秘密情報の扱いを雑にしないこと**です.
