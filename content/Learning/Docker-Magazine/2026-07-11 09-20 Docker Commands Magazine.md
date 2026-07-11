---
tags:
  - docker
  - containers
  - devops
  - learning
  - daily
---

[[Home]]

# 2026-07-11 09:20 Docker Commands Magazine

#docker #containers #devops #learning #daily

## 今日のテーマ
**実践Docker学習アーク：`docker run` → `docker exec` → `docker compose up`**

コンテナを「単発で動かす」だけで終わらせず、**開発環境として起動し、内部を観察し、複数サービスをまとめて扱う**ところまで進む回です。

---

## Beginner — `docker run` で開発用コンテナを安全に起動する

### 1) Topic + Level
**Topic:** `docker run` の基本と、開発でよく使う `-it`, `--rm`, `-p`, `-v`, `-e`
**Level:** Beginner

### 2) なぜ実務で重要か
アプリ開発では、ローカルPCに直接ミドルウェアを大量インストールするより、**Dockerで隔離された実行環境**を使うほうが再現性が高くなります。

たとえば：
- 新規参加メンバーが同じ開発環境をすぐ再現できる
- Node/Python/Postgres のバージョン差異で壊れにくい
- 検証用の使い捨て環境をすぐ作れる

Docker公式ドキュメントのベストプラクティスとも相性がよく、**「アプリ本体」「依存サービス」「設定」を分離しながら再現可能にする」**のが強みです。

### 3) コアコマンド解説
#### `docker run`
イメージから新しいコンテナを作成し、そのまま起動します。

よく使うオプション：
- `-it` : 対話モード。シェルに入って操作しやすい
- `--rm` : 終了時にコンテナを自動削除。検証用に便利
- `-p 8080:80` : ホストの8080番をコンテナの80番に転送
- `-v $(pwd):/app` : 現在ディレクトリをコンテナへマウント
- `-e KEY=value` : 環境変数を渡す
- `--name web-dev` : コンテナに名前を付ける

例：
```bash
docker run --rm -it --name ubuntu-lab ubuntu:24.04 bash
```

Nginxの例：
```bash
docker run --rm -d --name mynginx -p 8080:80 nginx:alpine
```

### 4) アプリ開発での使われ方
実務では `docker run` は次の用途でよく使います。
- 依存関係の切り分け検証
- CIで一時的なテスト環境を作る
- DBやRedisをローカルに安全に立てる
- ビルド済みイメージの起動確認

Docker公式ベストプラクティスに沿うなら、次を意識すると良いです。
- **1コンテナ1責務**を基本にする
- イメージは軽量なベースを選ぶ
- 開発時と本番時の設定差分を明示する
- 永続化が必要なデータはボリュームへ分離する

### 5) 30–60分ミニラボ
**目標:** 静的HTMLをNginxコンテナで配信する

1. 作業フォルダを作る
```bash
mkdir -p docker-run-lab/site
cd docker-run-lab
```

2. HTMLを作る
```bash
cat > site/index.html <<'EOF'
<!doctype html>
<html>
  <head><meta charset="utf-8"><title>Docker Lab</title></head>
  <body>
    <h1>Hello from Docker</h1>
    <p>Beginner mini lab is running.</p>
  </body>
</html>
EOF
```

3. Nginxコンテナを起動する
```bash
docker run --rm -d \
  --name docker-site \
  -p 8080:80 \
  -v "$(pwd)/site:/usr/share/nginx/html:ro" \
  nginx:alpine
```

4. 動作確認
```bash
docker ps
curl http://localhost:8080
```

5. 終了
```bash
docker stop docker-site
```

### 6) Command Cheatsheet
```bash
docker run --rm -it ubuntu:24.04 bash
docker run -d -p 8080:80 nginx:alpine
docker run --name app -e APP_ENV=dev image:tag
docker run -v "$(pwd):/app" image:tag
docker ps
docker stop <container>
```

### 7) よくあるミスと安全策
**よくあるミス**
- `-p` を付け忘れてブラウザから見えない
- `-v` のパスを間違えてファイルが反映されない
- `--rm` を付けず検証コンテナが大量に残る
- 機密情報を `Dockerfile` に書いてしまう

**安全策**
- シークレットは**イメージに焼き込まない**
- `.env` やSecrets管理を使い、Gitへコミットしない
- 読み取り専用で十分なら `:ro` マウントを使う
- 公開ポートは必要最小限だけにする

### 8) 面接っぽい質問
**Q. `docker run` と `docker start` の違いは？**

**考え方のポイント:**
- `docker run` は「新しいコンテナを作成して起動」
- `docker start` は「既存コンテナを再起動」

### 9) 次の一歩リソース
- Docker Get Started: <https://docs.docker.com/get-started/>
- `docker run` リファレンス: <https://docs.docker.com/engine/containers/run/>
- Bind mounts: <https://docs.docker.com/engine/storage/bind-mounts/>

---

## Middle — `docker exec` と `docker logs` で稼働中コンテナを調査する

### Prerequisites
- `docker run` でコンテナを起動できる
- コンテナとイメージの違いが分かる
- `docker ps` の基本が分かる

### 1) Topic + Level
**Topic:** `docker exec`, `docker logs`, `docker inspect` を使ったデバッグ基礎
**Level:** Middle

### 2) なぜ実務で重要か
アプリが「起動したのに動かない」とき、まず必要なのは**中で何が起きているかを見る力**です。

実務では：
- Webサーバーは動いているか
- 環境変数は正しく渡っているか
- ボリュームの中身は期待通りか
- ログにエラーが出ていないか

この調査を素早くできると、開発速度と障害対応の質がかなり上がります。

### 3) コアコマンド解説
#### `docker exec`
動いているコンテナの中で追加コマンドを実行します。

```bash
docker exec -it mynginx sh
```

#### `docker logs`
コンテナの標準出力・標準エラーを確認します。

```bash
docker logs mynginx
docker logs -f mynginx
```

#### `docker inspect`
コンテナの詳細設定をJSONで見ます。

```bash
docker inspect mynginx
```

### 4) アプリ開発での使われ方
Docker公式の考え方に沿うと、**観測可能性**は重要です。アプリをコンテナで動かすなら、次を意識します。
- ログはファイル閉じ込めより**stdout/stderr**へ出す
- 設定は環境変数やComposeで外部化する
- デバッグのために、コンテナ内部状態を確認できる運用にする

`docker exec` は便利ですが、**本番障害の恒久対応を手作業でコンテナ内修正して済ませない**のも大事です。修正はイメージや構成へ戻すのが原則です。

### 5) 30–60分ミニラボ
**目標:** Nodeコンテナの中身・ログ・環境変数を調査する

1. 作業ディレクトリを作る
```bash
mkdir -p ~/docker-debug-lab
cd ~/docker-debug-lab
```

2. 簡単なNodeアプリを用意
```bash
cat > server.js <<'EOF'
const http = require('http');
const port = process.env.PORT || 3000;
const msg = process.env.APP_MESSAGE || 'default message';

const server = http.createServer((req, res) => {
  console.log(`request: ${req.method} ${req.url}`);
  res.end(`Message: ${msg}\n`);
});

server.listen(port, () => {
  console.log(`server listening on ${port}`);
});
EOF
```

3. 公式Nodeイメージで起動
```bash
docker run --rm -d \
  --name node-debug \
  -p 3000:3000 \
  -e PORT=3000 \
  -e APP_MESSAGE='hello debug lab' \
  -v "$(pwd):/app" \
  -w /app \
  node:22-alpine \
  node server.js
```

4. ログ確認
```bash
docker logs node-debug
curl http://localhost:3000
docker logs node-debug
```

5. コンテナ内部を確認
```bash
docker exec -it node-debug sh
printenv | grep APP_
ls -la /app
exit
```

6. 詳細確認
```bash
docker inspect node-debug | less
```

### 6) Command Cheatsheet
```bash
docker logs <container>
docker logs -f <container>
docker exec -it <container> sh
docker exec <container> printenv
docker inspect <container>
docker top <container>
docker stats
```

### 7) よくあるミスと安全策
**よくあるミス**
- `docker exec` で手修正し、その内容が再作成で消える
- ログをコンテナ内ファイルだけに書いて追跡しづらい
- 環境変数に秘密情報をベタ書きし、履歴や設定から漏れる

**安全策**
- 問題修正は `Dockerfile` や Compose 定義へ戻す
- ログは標準出力へ出す
- APIキー・DBパスワードはイメージやソースに埋め込まない
- コンテナ内部を見たら、**再現可能な設定に戻して終える**

### 8) 面接っぽい質問
**Q. なぜ本番コンテナの中で直接ファイル修正する運用は危険なのですか？**

**考え方のポイント:**
- 再作成で消える
- 変更履歴が残りにくい
- 環境差分が増え、再現性が壊れる

### 9) 次の一歩リソース
- Logsの見方: <https://docs.docker.com/engine/logging/>
- `docker exec` 参考: <https://docs.docker.com/reference/cli/docker/container/exec/>
- `docker inspect` 参考: <https://docs.docker.com/reference/cli/docker/inspect/>

---

## Advanced — `docker compose up` でアプリ + DB の開発環境を組む

### Prerequisites
- `docker run`, `docker exec`, `docker logs` を使える
- ポート公開とボリュームマウントを理解している
- アプリとDBが別プロセス/別サービスで動くイメージを持っている

### 1) Topic + Level
**Topic:** `docker compose up` で複数サービス開発環境を構築する
**Level:** Advanced

### 2) なぜ実務で重要か
実アプリは単体コンテナでは終わりません。典型的には：
- APIサーバー
- DB
- キャッシュ
- ワーカー

これらを**チーム全員が同じ構成で起動できる**ことが重要です。`docker compose` はローカル開発・検証・簡易CIで非常に実用的です。

Docker公式ベストプラクティスに沿うと、Composeは次を整理しやすくします。
- サービスごとの責務分離
- 環境変数の管理
- ネットワークと永続ボリュームの定義
- 開発用オーバーライドの明確化

### 3) コアコマンド解説
#### `docker compose up`
Composeファイルに定義された複数サービスを作成・起動します。

```bash
docker compose up
```

よく使う形：
- `docker compose up -d` : バックグラウンド起動
- `docker compose ps` : 状態確認
- `docker compose logs -f` : ログ追跡
- `docker compose down` : 停止・削除

### 4) アプリ開発での使われ方
実務ではComposeで次をよくやります。
- API + Postgres のローカル開発環境
- 本番に近い依存サービス構成の再現
- テスト実行時の一時DB起動
- 新メンバー向けオンボーディング環境の標準化

ベストプラクティス：
- Composeに**秘密情報を直書きしない**
- 永続データはnamed volumeで分離
- `depends_on` だけで「アプリがDB接続可能」とは限らないので、ヘルスチェックやリトライ設計も考える
- 開発用マウントと本番イメージの責務を混ぜすぎない

### 5) 30–60分ミニラボ
**目標:** Nginx + Postgres の複数サービスをComposeで起動し、ネットワークとボリュームの概念に触れる

1. フォルダ作成
```bash
mkdir -p ~/docker-compose-lab/web
cd ~/docker-compose-lab
```

2. HTML作成
```bash
cat > web/index.html <<'EOF'
<!doctype html>
<html>
  <head><meta charset="utf-8"><title>Compose Lab</title></head>
  <body>
    <h1>Compose is running</h1>
    <p>Nginx + Postgres lab</p>
  </body>
</html>
EOF
```

3. `compose.yaml` を作る
```yaml
services:
  web:
    image: nginx:alpine
    ports:
      - "8081:80"
    volumes:
      - ./web:/usr/share/nginx/html:ro
    depends_on:
      - db

  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: appdb
      POSTGRES_USER: appuser
      POSTGRES_PASSWORD: change-me-for-local-dev
    volumes:
      - pgdata:/var/lib/postgresql/data

volumes:
  pgdata:
```

4. 起動
```bash
docker compose up -d
```

5. 確認
```bash
docker compose ps
docker compose logs -f
curl http://localhost:8081
```

6. DBコンテナに入って確認
```bash
docker compose exec db psql -U appuser -d appdb -c '\l'
```

7. 終了
```bash
docker compose down
```

**補足:** ボリュームまで削除したい場合は `docker compose down -v` ですが、**データが消える**ため意味を理解してから使ってください。

### 6) Command Cheatsheet
```bash
docker compose up
docker compose up -d
docker compose ps
docker compose logs -f
docker compose exec db sh
docker compose down
docker compose down -v
```

### 7) よくあるミスと安全策
**よくあるミス**
- Composeファイルに本物のパスワードを書く
- `depends_on` だけで起動順問題が解決したと思い込む
- ボリューム削除の影響を理解せず `down -v` を打つ
- 開発用のbind mount前提を本番運用へ持ち込む

**安全策**
- 本番秘密情報はSecrets管理や安全な注入方法を使う
- 開発用パスワードでも公開リポジトリに置かない
- データ削除系コマンドは対象を確認してから実行する
- 本番では最小権限・最小公開ポートを徹底する

**破壊的コマンドへの注意**
以下は便利ですが、誤ると不要でないデータまで消します。
- `docker system prune`
- `docker image prune -a`
- `docker rmi`
- `docker rm -f`

実行前に必ず：
- 何が消えるか確認する
- 開発中コンテナ/イメージ/ボリュームか確認する
- 共有環境や重要データでないことを確認する

### 8) 面接っぽい質問
**Q. `docker compose` を使う利点は、単に `docker run` を複数回打つのと比べて何ですか？**

**考え方のポイント:**
- 構成がコード化される
- 再現性が上がる
- チーム共有しやすい
- ネットワーク/ボリューム/環境変数を一元管理できる

### 9) 次の一歩リソース
- Docker Compose overview: <https://docs.docker.com/compose/>
- Compose file reference: <https://docs.docker.com/reference/compose-file/>
- Docker volumes: <https://docs.docker.com/engine/storage/volumes/>
- Docker build best practices: <https://docs.docker.com/build/building/best-practices/>
- Multi-container applications: <https://docs.docker.com/get-started/docker-concepts/running-containers/multi-container-applications/>

---

## まとめ
今日の学習アークは次の流れです。

1. **Beginner:** `docker run` で安全に単体コンテナを扱う
2. **Middle:** `docker exec` / `docker logs` で中を調べる
3. **Advanced:** `docker compose up` で実務寄りの複数サービス構成へ進む

この順に慣れると、Dockerを「なんとなく起動する道具」ではなく、**再現性の高い開発基盤**として使えるようになります。

明日は、必要なら次のアークに進めます。
- `docker build` と `Dockerfile` 設計
- レイヤキャッシュ最適化
- 開発用Composeと本番用イメージの分離
