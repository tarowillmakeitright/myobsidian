---
tags: [docker, containers, devops, learning, daily]
---

# 2026-05-05 09:20 Docker Commands Magazine
[[Home]]

## 今号のテーマ
**「`docker run` から始める、開発環境の再現性を高める基本運用」**

---

## 🟢 Beginner
### 1) Topic + Level
**Topic:** コンテナ実行の基本 (`docker pull` / `docker run` / `docker ps` / `docker logs` / `docker stop`)  
**Level:** Beginner

### 2) なぜ実アプリ開発で重要か
ローカル開発で「自分の環境だけ動く」を防ぐための第一歩です。  
同じイメージから同じ実行環境を起動できるため、オンボーディングや検証の速度が上がります。

### 3) コアコマンド解説
- `docker pull nginx:stable`
  - レジストリからイメージを取得。
- `docker run -d --name web1 -p 8080:80 nginx:stable`
  - バックグラウンド起動。`8080(host) -> 80(container)` を公開。
- `docker ps`
  - 起動中コンテナ確認。
- `docker logs web1`
  - ログ確認（不調時の最初の入口）。
- `docker stop web1`
  - 正常停止。

### 4) 実アプリ構築での使い方（Docker公式ベストプラクティス準拠）
- **イメージはタグ固定**（例: `nginx:stable`）で再現性を確保。
- まずは**ログ確認→状態確認**の運用を習慣化。
- いきなり巨大composeに行く前に、単体コンテナのライフサイクルを把握。

### 5) 30-60分ミニラボ
1. `nginx:stable` をpull。
2. `-p 8080:80` で起動し、ブラウザで `http://localhost:8080` を確認。
3. `docker logs` でアクセスログを確認。
4. 別名で2台目起動し、ポート競合を体験（例: 8081:80）。
5. 両方停止して差分を確認。

### 6) コマンドチートシート
```bash
docker pull nginx:stable
docker run -d --name web1 -p 8080:80 nginx:stable
docker ps
docker logs web1
docker stop web1
docker rm web1
```

### 7) よくあるミスと安全策
- ミス: `latest` 依存で挙動が日によって変わる。  
  安全策: 明示タグ運用。
- ミス: 不要な `--privileged` 利用。  
  安全策: 最小権限原則。

### 8) 面接風質問
「`docker run -p 8080:80` の `8080` と `80` はそれぞれどこを指し、なぜ必要ですか？」

### 9) 次の一歩（公式）
- https://docs.docker.com/get-started/docker-overview/
- https://docs.docker.com/get-started/

---

## 🟡 Middle
### 1) Topic + Level
**Topic:** DockerfileでNode.jsアプリをコンテナ化（マルチステージ基礎）  
**Level:** Middle  
**Prerequisites:** Beginnerの内容、Node.jsアプリの基本構成理解

### 2) なぜ実アプリ開発で重要か
本番配布可能なアーティファクトを標準化できます。  
「ビルド環境」と「実行環境」を分けることで軽量・高速・安全な配布が可能です。

### 3) コアコマンド解説
- `docker build -t sample-node:1.0 .`
  - Dockerfileからイメージ作成。
- `docker run --rm -p 3000:3000 sample-node:1.0`
  - 実行して動作確認。`--rm`で終了時に自動削除。
- `docker image ls`
  - イメージ確認。
- `docker exec -it <container> sh`
  - 起動中コンテナ内部確認。

### 4) 実アプリ構築での使い方（Docker公式ベストプラクティス準拠）
- **マルチステージビルド**で最終イメージを最小化。
- `COPY package*.json` → `npm ci` → ソースコピーの順で**レイヤーキャッシュ最適化**。
- `.dockerignore` を用意して不要ファイルを除外（`node_modules`, `.git` など）。

### 5) 30-60分ミニラボ
1. 最小Node API（`/health`）を用意。
2. Dockerfile（build/runtime分離）を作成。
3. `.dockerignore` 追加。
4. build→run→`curl localhost:3000/health` 確認。
5. `docker history sample-node:1.0` で層を観察。

### 6) コマンドチートシート
```bash
docker build -t sample-node:1.0 .
docker run --rm -p 3000:3000 sample-node:1.0
docker image ls
docker ps
docker exec -it <container_id> sh
docker history sample-node:1.0
```

### 7) よくあるミスと安全策
- ミス: 秘密情報（APIキー等）を `ENV` やイメージに焼き込む。  
  安全策: **秘密情報はイメージ/composeへ直書きしない**。実行時注入（シークレット管理）を使う。
- ミス: build contextが巨大。  
  安全策: `.dockerignore` を整備。

### 8) 面接風質問
「マルチステージビルドは、どのようにセキュリティとパフォーマンスを改善しますか？」

### 9) 次の一歩（公式）
- https://docs.docker.com/build/building/multi-stage/
- https://docs.docker.com/build/cache/optimize/
- https://docs.docker.com/develop/develop-images/dockerfile_best-practices/

---

## 🔴 Advanced
### 1) Topic + Level
**Topic:** Docker ComposeでWeb+DBの安全なローカル統合環境を作る  
**Level:** Advanced  
**Prerequisites:** Middleの内容、ネットワーク/永続化ボリュームの基礎

### 2) なぜ実アプリ開発で重要か
複数サービス（API, DB, Cache）の連携を本番に近い形で検証できます。  
CI前に依存関係・起動順・ヘルスチェック課題を潰せるため、障害予防に直結します。

### 3) コアコマンド解説
- `docker compose up -d`
  - 複数サービスを定義どおり起動。
- `docker compose ps`
  - サービス状態確認。
- `docker compose logs -f api`
  - サービス単位でログ追跡。
- `docker compose down`
  - 停止・ネットワーク削除（volume削除は別）。

### 4) 実アプリ構築での使い方（Docker公式ベストプラクティス準拠）
- **ヘルスチェック**と `depends_on` 条件で起動依存を明示。
- DBデータはnamed volumeに分離。
- 機密情報は`.env`直書きで済ませず、チームルールに沿ったシークレット管理へ移行。
- 不要なポート公開を避け、内部通信はcompose networkを優先。

### 5) 30-60分ミニラボ
1. `api`(Node) + `db`(Postgres) の `compose.yaml` 作成。
2. `healthcheck` を `db` に設定。
3. `docker compose up -d` 実行。
4. `api` から `db` 接続確認（簡易クエリ）。
5. `docker compose logs -f` で起動順・再試行を観察。
6. `down` して再起動、volume永続化を確認。

### 6) コマンドチートシート
```bash
docker compose up -d
docker compose ps
docker compose logs -f api
docker compose exec db psql -U postgres
docker compose down
```

### 7) よくあるミスと安全策
- ミス: `docker compose down -v` を何も考えず実行。  
  ⚠️ **警告:** volume削除でDBデータが消えます。バックアップ不要か確認してから実行。
- ミス: `docker system prune -a` / `docker image rm -f` / `docker rm -f` を常用。  
  ⚠️ **警告:** 破壊的クリーンアップです。対象確認（`docker ps -a`, `docker images`）後に限定実行。
- ミス: DBパスワードをcomposeに平文固定。  
  安全策: シークレット管理と環境分離（dev/stg/prod）を徹底。

### 8) 面接風質問
「Compose環境で、`depends_on` だけでは不十分なケースがあるのはなぜですか？ヘルスチェックと合わせて説明してください。」

### 9) 次の一歩（公式）
- https://docs.docker.com/compose/
- https://docs.docker.com/compose/compose-file/
- https://docs.docker.com/engine/security/
- https://docs.docker.com/reference/cli/docker/system/prune/

---

## 今日の学習アーク（Beginner → Middle → Advanced）
1. 単体コンテナ運用の基本を体に入れる
2. Dockerfile最適化で配布品質を上げる
3. Composeで実運用に近い統合検証へ進む

明日はこの続きとして、**イメージ脆弱性スキャン（Docker Scout含む）**と**CI組み込み**に進むと効果的です。