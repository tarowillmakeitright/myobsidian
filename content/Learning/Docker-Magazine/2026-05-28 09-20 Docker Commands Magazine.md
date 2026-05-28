---
tags: [docker, containers, devops, learning, daily]
---

# 2026-05-28 Docker Commands Magazine
[[Home]]

#docker #containers #devops #learning #daily

## 今日のテーマ
**DockerネットワークとComposeで作る「安全なWeb + DB開発環境」**

---

## 1) Topic + Level

### Beginner（初級）
**トピック:** コンテナ起動の基本 (`docker run`, `docker ps`, `docker logs`, `docker exec`)

### Middle（中級）
**トピック:** ユーザー定義ネットワークとボリューム (`docker network`, `docker volume`)
**前提知識:** `docker run`/`ps`/`logs` が使えること、Linuxのポート概念（`host:container`）を理解していること

### Advanced（上級）
**トピック:** Docker ComposeでWeb+DBを安全に構成（環境変数・ヘルスチェック・最小権限）
**前提知識:** Dockerfileの基本、Middle内容（ネットワーク/ボリューム）、`.env` の使い方の基礎

---

## 2) なぜ実務で重要か
- ローカル開発環境の再現性を高め、**「自分のPCでは動く」問題**を減らせる。
- DB付きアプリの構築速度が上がり、オンボーディングが速くなる。
- ネットワーク分離・最小権限・secret管理を意識すると、**開発段階から本番に近い安全設計**になる。

---

## 3) Core Docker command explanations
- `docker run -d --name app -p 8080:80 nginx:alpine`  
  イメージからコンテナを起動。`-d`でバックグラウンド、`-p`でポート公開。

- `docker ps` / `docker ps -a`  
  実行中 / 全コンテナ一覧を確認。

- `docker logs -f <container>`  
  ログ追跡。アプリ起動失敗時の最初の確認ポイント。

- `docker exec -it <container> sh`  
  コンテナ内部で調査（設定・ファイル・疎通確認）。

- `docker network create app-net`  
  サービス間通信専用ネットワーク作成。

- `docker volume create pgdata`  
  DBデータを永続化し、コンテナ再作成でも保持。

- `docker compose up -d` / `docker compose down`  
  複数サービスを宣言的に起動/停止。

---

## 4) 実アプリ開発での使い方（docs.docker.comベストプラクティス寄せ）
- 依存関係（Web/DB/Cache）をComposeで管理し、`docker compose up`一発で開発開始。
- **1コンテナ1責務**を基本に、サービスを分離。
- イメージは軽量ベース（例: `alpine`系）を検討し、不要パッケージを減らす。
- 機密情報は**イメージに焼き込まない**（DockerfileにAPIキー直書き禁止、`compose.yml`に平文secret直書き回避）。
- `HEALTHCHECK` や `depends_on`（condition）で起動順・健全性を制御。
- 不要なポート公開を避け、DBは可能なら内部ネットワークのみで公開しない。

---

## 5) 30–60分ミニラボ
**ゴール:** Nginx + Postgresの開発環境をComposeで構築し、ネットワーク分離と永続化を確認

### 手順（約45分）
1. 作業ディレクトリ作成
```bash
mkdir -p docker-mag-lab && cd docker-mag-lab
```

2. `compose.yml` 作成
```yaml
services:
  web:
    image: nginx:alpine
    container_name: lab-web
    ports:
      - "8080:80"
    depends_on:
      db:
        condition: service_healthy
    networks:
      - app-net
    read_only: true
    tmpfs:
      - /var/cache/nginx
      - /var/run

  db:
    image: postgres:16-alpine
    container_name: lab-db
    environment:
      POSTGRES_DB: appdb
      POSTGRES_USER: appuser
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    volumes:
      - pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U appuser -d appdb"]
      interval: 5s
      timeout: 3s
      retries: 10
    networks:
      - app-net

networks:
  app-net:

volumes:
  pgdata:
```

3. `.env` 作成（機密をGit管理しない）
```bash
cat > .env <<'EOF'
POSTGRES_PASSWORD=change-this-strong-password
EOF
```

4. 起動と確認
```bash
docker compose up -d
docker compose ps
docker logs -f lab-db
```

5. 動作確認
- ブラウザで `http://localhost:8080` を開く
- `docker exec -it lab-db sh` でDBコンテナに入り、`pg_isready -U appuser -d appdb` を実行

6. 後片付け
```bash
docker compose down
```

> データも消す場合のみ（破壊的）:
```bash
# WARNING: ボリューム内データを削除します
# docker compose down -v
```

---

## 6) Command Cheatsheet
```bash
# 起動
docker compose up -d

# 状態確認
docker compose ps
docker ps -a

# ログ
docker compose logs -f web
docker logs -f lab-db

# コンテナ内シェル
docker exec -it lab-web sh
docker exec -it lab-db sh

# 停止/削除
docker compose down

# イメージ/不要資源確認
docker images
docker system df
```

---

## 7) よくあるミス & 安全運用
- **ミス:** `Dockerfile` や `compose.yml` に秘密情報を直書き  
  **対策:** `.env` / secrets管理を使い、リポジトリへ含めない。

- **ミス:** DBポートを外部公開しっぱなし  
  **対策:** 必要時のみ公開。基本は内部ネットワーク通信。

- **ミス:** 無差別クリーンアップ実行  
  **対策:** `prune` 系は対象確認後に実行。

⚠️ **破壊的コマンド注意**
- `docker system prune -a`
- `docker image rm ...` / `docker rmi ...`
- `docker rm -f ...`

実行前に必ず影響範囲を確認（消してよいコンテナ/イメージ/ボリュームか）。

---

## 8) 面接っぽい質問（1問）
**Q.** `docker compose down` と `docker compose down -v` の違いは？ 本番障害対応で誤って `-v` を使うと何が起きる？

---

## 9) 次の一歩（公式ドキュメント優先）
- Docker Get Started: https://docs.docker.com/get-started/
- Docker Compose overview: https://docs.docker.com/compose/
- Compose file reference: https://docs.docker.com/reference/compose-file/
- Dockerfile best practices: https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Build secrets / 機密情報: https://docs.docker.com/build/building/secrets/
- Docker network: https://docs.docker.com/network/
- Docker volumes: https://docs.docker.com/storage/volumes/

---

次回予告（学習アーク継続）: **イメージ最適化（multi-stage build）→ SBOM/脆弱性スキャン → CI/CD連携**