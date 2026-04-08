---
tags:
  - docker
  - containers
  - devops
  - learning
  - daily
---

# 2026-04-07 09:20 Docker Commands Magazine
[[Home]]

## 今日の学習テーマ
**テーマ:** Dockerコマンドで「開発→検証→運用前チェック」まで一気通貫する
**学習アーク:** Beginner → Middle → Advanced

---

## Arc 1 — Beginner（基礎）
### 1) Topic + Level
**Level:** Beginner  
**Topic:** `docker run` / `docker ps` / `docker logs` でアプリを“まず動かす・観察する”

### 2) なぜ実務で重要か
ローカル開発では「動くけど原因不明」の時間が最もコスト高です。  
コンテナの起動・状態確認・ログ確認の3点セットを素早く回せると、実装スピードとデバッグ効率が大きく上がります。

### 3) コアコマンド解説
- `docker run -d --name web -p 8080:80 nginx:alpine`
  - イメージからコンテナ作成＋起動（`-d`でバックグラウンド）
  - `--name`で識別しやすく
  - `-p ホスト:コンテナ`でポート公開
- `docker ps` / `docker ps -a`
  - 実行中 / 全コンテナ確認
- `docker logs -f web`
  - コンテナログ追跡（`-f`でfollow）
- `docker stop web && docker rm web`
  - 停止して削除（作業後の基本クリーンアップ）

### 4) アプリ開発での使い方（Docker公式ベストプラクティス寄り）
- 使い捨て可能なコンテナで検証し、環境差分を減らす
- コンテナにSSHせず、**ログと設定で観測可能性**を確保する
- まずは公式イメージ（例: `nginx`, `node`, `postgres`）を使い、不要な独自化を避ける

### 5) 30-60分ミニラボ
**目標:** 静的サイトをNginxコンテナで配信し、ログを確認する

1. 作業フォルダを作る
```bash
mkdir -p docker-lab-1/site && cd docker-lab-1
cat > site/index.html <<'HTML'
<h1>Hello Docker Lab</h1>
<p>Beginner arc</p>
HTML
```
2. コンテナ起動
```bash
docker run -d --name web -p 8080:80 -v "$PWD/site:/usr/share/nginx/html:ro" nginx:alpine
```
3. 動作確認
```bash
curl -s http://localhost:8080
```
4. ログ確認
```bash
docker logs -f web
```
5. 終了
```bash
docker stop web && docker rm web
```

### 6) Cheatsheet
- 起動: `docker run ...`
- 一覧: `docker ps -a`
- ログ: `docker logs -f <name>`
- 停止: `docker stop <name>`
- 削除: `docker rm <name>`

### 7) よくあるミス & セーフプラクティス
- ミス: `-p 80:80`でローカル80番を奪って既存アプリと衝突
  - 対策: 開発は `8080:80` など衝突しにくいポートを使う
- ミス: `-v`で書き込み可能マウントし、意図せずファイル改変
  - 対策: 参照専用なら `:ro`

### 8) 面接風質問
「`docker run` と `docker start` の違いを説明してください。既存コンテナ再利用の場面でどう使い分けますか？」

### 9) 次の学習リソース
- Docker Get Started: https://docs.docker.com/get-started/
- `docker run` リファレンス: https://docs.docker.com/engine/reference/commandline/run/
- コンテナログ: https://docs.docker.com/engine/logging/

---

## Arc 2 — Middle（実践）
### Prerequisites
- Beginner内容を実施済み
- Dockerfileの基本構文（`FROM`, `COPY`, `RUN`, `CMD`）を読んだことがある

### 1) Topic + Level
**Level:** Middle  
**Topic:** 開発向けDockerfile最適化（レイヤーキャッシュ・`.dockerignore`・マルチステージ導入）

### 2) なぜ実務で重要か
ビルドが遅いとCI/CDと開発体験が壊れます。  
イメージサイズが大きいと配布遅延・セキュリティ面のリスク増につながります。

### 3) コアコマンド解説
- `docker build -t myapp:dev .`
  - Dockerfileからイメージ作成
- `docker image ls`
  - イメージサイズ確認
- `docker history myapp:dev`
  - レイヤーごとの肥大化ポイント確認
- `docker exec -it <container> sh`
  - 実行中コンテナ内部を最小限調査（常用しすぎない）

### 4) アプリ開発での使い方（ベストプラクティス）
- 依存定義ファイルを先に`COPY`してインストール層をキャッシュ
- `.dockerignore`で不要ファイル（`.git`, `node_modules`, secrets）を送らない
- マルチステージビルドで実行イメージを最小化
- **秘密情報をDockerfileに埋め込まない**（`ENV PASSWORD=...`禁止）

### 5) 30-60分ミニラボ
**目標:** Nodeアプリをマルチステージでビルドし、サイズと速度を比較

1. サンプル作成
```bash
mkdir -p docker-lab-2 && cd docker-lab-2
cat > package.json <<'JSON'
{
  "name": "docker-lab-2",
  "version": "1.0.0",
  "scripts": {"start": "node server.js"},
  "dependencies": {"express": "^4.19.2"}
}
JSON
cat > server.js <<'JS'
const express = require('express');
const app = express();
app.get('/', (_, res) => res.send('hello from middle arc'));
app.listen(3000);
JS
cat > .dockerignore <<'EOF'
node_modules
.git
.env
EOF
```
2. Dockerfile（マルチステージ）
```Dockerfile
FROM node:22-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm install --omit=dev

FROM node:22-alpine AS runtime
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY server.js package.json ./
EXPOSE 3000
CMD ["npm", "start"]
```
3. ビルド・実行・確認
```bash
docker build -t myapp:dev .
docker run -d --name myapp -p 3000:3000 myapp:dev
curl -s http://localhost:3000
```
4. サイズ調査
```bash
docker image ls myapp:dev
docker history myapp:dev
```
5. 終了
```bash
docker stop myapp && docker rm myapp
```

### 6) Cheatsheet
- ビルド: `docker build -t <name>:<tag> .`
- サイズ確認: `docker image ls`
- 履歴確認: `docker history <image>`
- コンテナ内シェル: `docker exec -it <name> sh`

### 7) よくあるミス & セーフプラクティス
- ミス: `COPY . .`を早い段階で実行→毎回キャッシュ無効
  - 対策: 依存ファイル先コピー → インストール → ソースコピー
- ミス: `.env`をイメージに同梱
  - 対策: シークレットは環境変数注入/シークレット管理で扱う（イメージに焼かない）

### 8) 面接風質問
「Dockerレイヤーキャッシュを最大化するDockerfileの並び順を、Node.jsアプリを例に説明してください。」

### 9) 次の学習リソース
- Dockerfile best practices: https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Multi-stage builds: https://docs.docker.com/build/building/multi-stage/
- `.dockerignore`: https://docs.docker.com/build/building/context/#dockerignore-files

---

## Arc 3 — Advanced（運用前提）
### Prerequisites
- Middle内容を実施済み
- Docker Compose基本（サービス、ネットワーク、ボリューム）を理解
- セキュリティの基本（最小権限、秘密情報管理）を理解

### 1) Topic + Level
**Level:** Advanced  
**Topic:** Composeでアプリ+DBを安全に統合し、ヘルスチェックと運用前チェックを組み込む

### 2) なぜ実務で重要か
本番に近い複数コンテナ構成をローカルで再現できると、統合不具合を早期検出できます。  
さらにヘルスチェック・依存制御があるとデプロイ時の不安定性を減らせます。

### 3) コアコマンド解説
- `docker compose up -d`
  - 複数サービス起動
- `docker compose ps`
  - サービス状態確認
- `docker compose logs -f app`
  - サービス単位のログ追跡
- `docker compose down`
  - 停止・ネットワーク削除（ボリュームは残る）
- `docker compose down -v`
  - **注意:** ボリュームも削除（データ消失リスク）

### 4) アプリ開発での使い方（ベストプラクティス）
- `depends_on` + healthcheck で起動順依存を緩和
- 永続データはnamed volumeに分離
- `.env`やComposeファイルへ秘密情報を直書きしない
- イメージは軽量・非root実行を検討し攻撃面を縮小

### 5) 30-60分ミニラボ
**目標:** app + postgres構成をComposeで立ち上げ、ヘルス確認まで行う

1. `compose.yaml`作成
```yaml
services:
  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: appdb
      POSTGRES_USER: appuser
      POSTGRES_PASSWORD: change-me-local-only
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U appuser -d appdb"]
      interval: 5s
      timeout: 3s
      retries: 10
    volumes:
      - pgdata:/var/lib/postgresql/data

  app:
    image: node:22-alpine
    working_dir: /app
    command: ["sh", "-c", "node -e \"console.log('app started')\" && sleep 3600"]
    depends_on:
      db:
        condition: service_healthy

volumes:
  pgdata:
```
2. 起動
```bash
docker compose up -d
```
3. 状態確認
```bash
docker compose ps
docker compose logs -f db
```
4. 終了
```bash
docker compose down
```

> 実運用では `POSTGRES_PASSWORD` 直書き禁止。シークレット管理機構を使うこと。

### 6) Cheatsheet
- 起動: `docker compose up -d`
- 状態: `docker compose ps`
- ログ: `docker compose logs -f <service>`
- 停止/片付け: `docker compose down`

### 7) よくあるミス & セーフプラクティス
- ミス: `depends_on`だけで「準備完了」と誤解
  - 対策: healthcheckでready判定
- ミス: 破壊的クリーンアップを無警戒で実行
  - **警告:** `docker system prune`, `docker image prune -a`, `docker rm -f`, `docker rmi`, `docker compose down -v` は削除対象を必ず確認してから
- ミス: SecretsをGit管理
  - 対策: `.env`を除外し、CI/CDのSecret Storeを利用

### 8) 面接風質問
「Compose環境でDB依存のアプリが起動時に失敗する問題に対し、healthcheckと再試行戦略をどう設計しますか？」

### 9) 次の学習リソース
- Docker Compose overview: https://docs.docker.com/compose/
- Compose file reference: https://docs.docker.com/reference/compose-file/
- Docker secrets（概念理解）: https://docs.docker.com/engine/swarm/secrets/
- イメージセキュリティ: https://docs.docker.com/engine/security/

---

## 破壊的コマンドの安全メモ（毎日確認）
次のコマンドは**削除系**です。実行前に対象確認を徹底してください。

- `docker system prune`
- `docker image prune -a`
- `docker container prune`
- `docker volume prune`
- `docker rm -f <container>`
- `docker rmi <image>`

推奨手順:
1. `docker ps -a` / `docker image ls` / `docker volume ls` で対象確認  
2. 本当に不要か判断  
3. 可能ならバックアップ  
4. 破壊的コマンドを実行

---

今日のゴール: **「動かす」だけでなく「安全に運用を意識して動かす」** まで到達する。
