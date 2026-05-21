---
tags: [docker, containers, devops, learning, daily]
---

# 2026-05-21 09:20 Docker Commands Magazine
[[Home]]

#docker #containers #devops #learning #daily

## 今号のテーマ
**Docker ネットワークと Compose で作る「安全な3層Webアプリ開発」学習アーク**

- **Beginner:** コンテナ間通信の基本（bridge network / port公開）
- **Middle:** Docker Composeで複数サービス連携（Web + DB）
- **Advanced:** セキュアな運用（ネットワーク分離、read-only、least privilege、secret管理方針）

---

## 1) Topic + Level

### 🟢 Beginner
**Topic:** `docker run` と `docker network` の基本

### 🟡 Middle
**Topic:** `docker compose up` でアプリ+DBを連携

**前提知識（Prerequisites）**
- Beginnerの内容（ポート公開、基本的なrun/exec/logs）
- Dockerfileの基本構造（`FROM`, `COPY`, `RUN`, `CMD`）

### 🔴 Advanced
**Topic:** 本番を意識した安全設定（権限最小化・ネットワーク設計・secret非埋め込み）

**前提知識（Prerequisites）**
- Middleの内容（Composeで複数サービス運用）
- Linux権限の基礎（UID/GID, 読み取り専用の概念）

---

## 2) なぜ重要か（実アプリ開発での意味）

- ローカル開発で「手元では動くのに本番で動かない」を減らせる。
- Composeで依存サービスを揃えると、チーム全員が同じ環境で再現できる。
- セキュリティ設定（不要なポート閉鎖、root回避、secretをイメージに含めない）は、事故・漏えいリスクを直接下げる。

---

## 3) コアDockerコマンド解説

- `docker run -d --name app -p 8080:80 nginx:alpine`
  - コンテナ起動（バックグラウンド）
  - `-p ホスト:コンテナ` でポート公開

- `docker ps` / `docker ps -a`
  - 稼働中 / 全コンテナ確認

- `docker logs -f app`
  - ログ追跡（不具合調査の基本）

- `docker exec -it app sh`
  - 稼働中コンテナへ入る（状態確認）

- `docker network ls` / `docker network inspect <network>`
  - ネットワーク可視化

- `docker compose up -d` / `docker compose down`
  - 複数サービス起動/停止

- `docker compose logs -f`
  - サービス全体ログ監視

---

## 4) 実アプリ構築での使い方（docs.docker.com ベストプラクティス準拠）

- **1プロセス/1コンテナを基本にする**（責務分離）
- **イメージは小さく**（例: `alpine`, multi-stage build）
- **秘密情報をイメージに埋め込まない**
  - ❌ `ENV DB_PASSWORD=...` をDockerfileに直書き
  - ✅ 実行時注入（環境変数、Secret機構）
- **不要なポートを公開しない**
  - DBは内部ネットワークのみ、外部公開しない
- **実行ユーザーを非rootにする**（可能な範囲で）
- **ヘルスチェック・ログ確認を運用に組み込む**

---

## 5) 30〜60分ミニラボ

### ゴール
Composeで `web` (nginx) + `db` (postgres) を起動し、ネットワーク分離と安全設定を確認する。

### 手順

1. 作業フォルダ作成
```bash
mkdir -p docker-mag-lab && cd docker-mag-lab
```

2. `compose.yaml` を作成
```yaml
services:
  web:
    image: nginx:alpine
    ports:
      - "8080:80"
    read_only: true
    tmpfs:
      - /var/cache/nginx
      - /var/run
    depends_on:
      - db
    networks:
      - front
      - back

  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: app
      POSTGRES_PASSWORD: change_me_in_real_env
      POSTGRES_DB: appdb
    volumes:
      - db_data:/var/lib/postgresql/data
    networks:
      - back

volumes:
  db_data:

networks:
  front:
  back:
```

3. 起動
```bash
docker compose up -d
```

4. 確認
```bash
docker compose ps
docker compose logs -f --tail=50
```

5. ネットワーク確認
```bash
docker network ls
docker network inspect docker-mag-lab_back
```
- `db` が `back` のみにいることを確認

6. 後片付け（注意して実行）
```bash
docker compose down
```

**発展（任意）**
- `web` コンテナに `user: "101:101"` を追加し、root以外で動くか確認
- `.env` を使ってDBパスワードを外出し（ただし `.env` の取り扱いに注意）

---

## 6) コマンドチートシート

```bash
# 起動/停止
docker compose up -d
docker compose down

# 状態/ログ
docker compose ps
docker compose logs -f

docker ps
docker logs -f <container>

# コンテナ内調査
docker exec -it <container> sh

# ネットワーク
docker network ls
docker network inspect <network>
```

---

## 7) よくあるミス + 安全運用

### よくあるミス
- DBポート（5432）を不用意に外部公開する
- Dockerfileやcomposeに秘密情報を直書きする
- `latest` タグ固定で再現性を失う
- ログを見ずに再起動だけ繰り返す

### 安全運用
- イメージタグは明示（例: `postgres:16-alpine`）
- 公開ポートは最小限
- secretは実行時注入（CI/CD secret、Docker secret等）
- コンテナ権限は最小化（non-root, read-only FS）

### ⚠️ 破壊的コマンドの警告
以下は不要資産を削除します。実行前に対象確認必須。

- `docker system prune`
- `docker image prune -a`
- `docker rm -f <container>`
- `docker rmi <image>`

本番/共有環境では、いきなり実行しないこと。必ず影響範囲を確認してから。

---

## 8) 面接風質問（1問）

**質問:** あるチームが `docker-compose.yml` にDBパスワードを直書きしてGit管理しています。どんなリスクがあり、どう改善しますか？

**考えるポイント:**
- 漏えい経路（リポジトリ複製・ログ・スクリーンショット）
- ローテーションの難しさ
- Secret管理の移行案（環境変数注入、secret manager、権限分離）

---

## 9) 次の一歩（公式ドキュメント中心）

- Docker 公式ドキュメント Top
  - https://docs.docker.com/
- Get Started
  - https://docs.docker.com/get-started/
- Docker Compose Overview
  - https://docs.docker.com/compose/
- Compose file reference
  - https://docs.docker.com/reference/compose-file/
- Dockerfile best practices
  - https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Build secrets / secretの扱い
  - https://docs.docker.com/build/building/secrets/
- Docker Engine security
  - https://docs.docker.com/engine/security/

---

次号予告：**Beginner→Middle→Advanced 学習アーク継続（テーマ: イメージ最適化とビルド高速化）**