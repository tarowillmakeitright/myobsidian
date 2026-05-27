---
tags: [docker, containers, devops, learning, daily]
---

# Daily Docker Commands Magazine — 2026-05-25
[[Home]]

## 今日のテーマ
**「Dockerで開発環境を再現し、ビルドから運用準備まで安全に回す」**

---

## 🟢 Beginner：`docker run` / `docker ps` / `docker logs` でアプリを動かす

### 1) Topic + Level
**Topic:** コンテナ起動・確認・ログ確認の基本
**Level:** Beginner

### 2) なぜ実務で重要か
ローカルで「同じ手順で同じ結果」を出せることは、実アプリ開発の土台です。環境差分バグ（動く/動かない問題）を減らし、レビューやオンボーディングを高速化できます。

### 3) コアコマンド解説
- `docker run -d --name web -p 8080:80 nginx:alpine`
  - イメージからコンテナを起動
  - `-d`: バックグラウンド実行
  - `--name`: 管理しやすい名前
  - `-p 8080:80`: ホスト8080 → コンテナ80
- `docker ps`
  - 稼働中コンテナ一覧
- `docker logs -f web`
  - コンテナログ追跡（`-f` は follow）
- `docker stop web && docker rm web`
  - 停止して削除（開発後の片付け）

### 4) アプリ開発での使い方（Docker公式ベストプラクティス準拠）
- 依存サービス（DB/Redis/Nginx）を素早く起動して動作確認
- コンテナ名・ポートを明示して、チームで手順を標準化
- ログで「動いているつもり」を可視化

### 5) 30-60分ミニラボ
1. Nginxを起動し、`http://localhost:8080` にアクセス
2. `docker ps` で状態確認
3. `docker logs -f web` を確認
4. 停止・削除して再起動
5. ポートを `-p 9090:80` に変えて差分確認

### 6) Cheatsheet
```bash
docker run -d --name web -p 8080:80 nginx:alpine
docker ps
docker logs -f web
docker stop web
docker rm web
```

### 7) よくあるミス & 安全策
- ミス: `-p` 指定忘れでブラウザ接続不可
- ミス: 同名コンテナが残っていて再作成失敗
- 安全策: `docker ps -a` で残骸確認してから整理

### 8) 面接っぽい質問
`docker run -p 8080:80` の「左と右」は何を意味し、実務でどう使い分けますか？

### 9) 次の一歩（公式）
- https://docs.docker.com/get-started/docker-concepts/running-containers/
- https://docs.docker.com/reference/cli/docker/container/run/

---

## 🟡 Middle：DockerfileでNode.jsアプリをビルド（前提あり）

### 前提知識（Prerequisites）
- Beginnerの内容（run/ps/logs/stop/rm）
- Node.jsアプリの最小構成（`package.json`）

### 1) Topic + Level
**Topic:** 再現可能なアプリイメージの作成
**Level:** Middle

### 2) なぜ実務で重要か
Dockerfileは「環境の設計書」です。CI/CDや本番で同じビルドを再現でき、デプロイ事故を減らします。

### 3) コアコマンド解説
- `docker build -t my-node-app:dev .`
  - Dockerfileからイメージ作成
- `docker images`
  - 作成済みイメージ確認
- `docker run --rm -p 3000:3000 my-node-app:dev`
  - アプリ起動（`--rm` で終了時に自動削除）

### 4) アプリ開発での使い方（ベストプラクティス）
- **小さいベースイメージ**（例: `node:20-alpine`）を検討
- `COPY package*.json` → `RUN npm ci` → `COPY . .` の順でレイヤキャッシュ活用
- `.dockerignore` を必ず作り、`node_modules` や `.git` を除外
- **秘密情報をイメージに焼き込まない**（`ENV API_KEY=...` を避ける）

### 5) 30-60分ミニラボ
1. 以下Dockerfileを作成
2. `.dockerignore` を作成
3. `docker build` 実行
4. `docker run` で起動し疎通確認
5. ソース変更後に再ビルドし、キャッシュ挙動を確認

**サンプル Dockerfile（開発向け最小）**
```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
```

### 6) Cheatsheet
```bash
docker build -t my-node-app:dev .
docker images
docker run --rm -p 3000:3000 my-node-app:dev
```

### 7) よくあるミス & 安全策
- ミス: `.dockerignore` 未設定でビルド遅延
- ミス: `latest` タグ固定でバージョン管理が曖昧
- 安全策: タグに `:dev-YYYYMMDD` など識別子を付与
- 安全策: シークレットは実行時注入（環境変数/シークレット管理）

### 8) 面接っぽい質問
Dockerfileで `COPY package*.json` を先に行うと、なぜビルドが速くなることがありますか？

### 9) 次の一歩（公式）
- https://docs.docker.com/build/building/best-practices/
- https://docs.docker.com/reference/dockerfile/
- https://docs.docker.com/build/cache/

---

## 🔴 Advanced：Compose + ヘルスチェック + 安全なクリーンアップ（前提あり）

### 前提知識（Prerequisites）
- Beginner + Middle
- Docker network / volume の基礎概念

### 1) Topic + Level
**Topic:** 複数サービス構成の運用に近い開発フロー
**Level:** Advanced

### 2) なぜ実務で重要か
実アプリは単体より「Web + DB + Cache」が普通。Composeで依存関係を管理し、起動順やヘルス確認を組み込むことで、ローカルでも本番に近い検証ができます。

### 3) コアコマンド解説
- `docker compose up -d`
  - 複数サービスをバックグラウンド起動
- `docker compose ps`
  - サービス状態確認
- `docker compose logs -f`
  - 全体ログ追跡
- `docker compose down`
  - 停止・ネットワーク削除
- `docker compose down -v`
  - **⚠️ volumeも削除（データ消失）**

### 4) アプリ開発での使い方（ベストプラクティス）
- サービス間通信はComposeネットワーク名を利用
- DB readiness は healthcheck で判断
- 永続化が必要なデータは volume 分離
- **秘密情報をcompose直書きしない**（envファイル運用でもGit管理に注意）

### 5) 30-60分ミニラボ
1. `compose.yaml` で `web` + `redis` を定義
2. `docker compose up -d`
3. `docker compose ps` / `logs -f` で状態確認
4. `docker compose down` して再起動
5. `down -v` の前後でデータ有無を比較（学習用）

### 6) Cheatsheet
```bash
docker compose up -d
docker compose ps
docker compose logs -f
docker compose down
# 危険: volume削除でデータ消失
docker compose down -v
```

### 7) よくあるミス & 安全策
- ミス: `down -v` を日常的に使い、検証データを消す
- ミス: `docker system prune -a` を意味理解なしで実行
- 安全策: 破壊的コマンド前に対象確認
  - `docker ps -a`
  - `docker images`
  - `docker volume ls`
- **警告:**
  - `docker system prune`, `docker image prune -a`, `docker rm -f`, `docker rmi` は削除系。
  - 実行前に「何が消えるか」を必ず確認し、必要ならバックアップ。

### 8) 面接っぽい質問
`docker compose down` と `docker compose down -v` の違いを、開発データ保全の観点で説明してください。

### 9) 次の一歩（公式）
- https://docs.docker.com/compose/
- https://docs.docker.com/compose/gettingstarted/
- https://docs.docker.com/reference/cli/docker/compose/down/
- https://docs.docker.com/engine/manage-resources/pruning/

---

## まとめ
今日は「単一コンテナ実行 → Dockerfile再現ビルド → Compose複数サービス運用」という実務に直結する学習アークを回しました。

明日はこの続きとして、**マルチステージビルド**と**脆弱性スキャン（Docker Scoutの入口）**に進むと、開発品質とセキュリティの両輪が強くなります。