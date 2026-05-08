---
tags: [docker, containers, devops, learning, daily]
---

# 2026-05-08 Docker Commands Magazine
[[Home]]

#docker #containers #devops #learning #daily

## 今号テーマ
**実践で身につける Docker コンテナ運用の基本コマンド学習アーク（Beginner → Middle → Advanced）**

---

## 1) Topic + Level

### Beginner
**トピック:** `docker run / ps / logs / exec` で「動かす・見る・入る」

### Middle
**トピック:** `docker build / image ls / tag / push` でイメージ管理と配布
**前提条件:**
- Beginner の内容を理解している
- Dockerfile の基本構文（`FROM`, `COPY`, `RUN`, `CMD`）を読める
- Docker Hub などのレジストリにログインできる

### Advanced
**トピック:** `docker compose`, ヘルスチェック、ネットワーク分離、不要リソースの安全なクリーンアップ
**前提条件:**
- Middle の内容を理解している
- 複数コンテナ（Web + DB）の構成を想像できる
- `.env` やシークレット管理の重要性を理解している

---

## 2) なぜ実アプリ開発で重要か

- **開発環境の再現性**: 「自分のPCだけ動く」を防げる
- **チーム開発の速度向上**: 同じコンテナ定義を共有しオンボーディングを短縮
- **デプロイ品質の向上**: ビルド成果物（イメージ）を固定でき、本番差分を減らせる
- **障害調査の効率化**: `logs`, `exec`, `inspect` で原因切り分けが速くなる
- **セキュリティと運用性**: 最小権限・最小イメージ・安全なクリーンアップが運用事故を減らす

---

## 3) Core Docker command explanations

### Beginner Core
- `docker run -d --name app -p 8080:80 nginx:alpine`
  - コンテナ起動。`-d` バックグラウンド、`--name` 命名、`-p` ポート公開
- `docker ps` / `docker ps -a`
  - 稼働中 / 全コンテナ一覧
- `docker logs -f app`
  - ログ追跡（`-f` で follow）
- `docker exec -it app sh`
  - コンテナ内部に入って確認（Alpine は `sh`）

### Middle Core
- `docker build -t myapp:dev .`
  - Dockerfile からイメージ作成
- `docker image ls`
  - ローカルイメージ確認
- `docker tag myapp:dev <your-account>/myapp:2026-05-08`
  - レジストリ向けタグ付け
- `docker push <your-account>/myapp:2026-05-08`
  - レジストリへ配布

### Advanced Core
- `docker compose up -d`
  - 複数サービスを一括起動
- `docker compose ps` / `docker compose logs -f`
  - 構成全体の状態とログ確認
- `docker network ls`
  - ネットワーク分離の可視化
- `docker system df`
  - ディスク使用状況の確認（削除前の安全確認）

---

## 4) 実アプリ構築での使い方（docs.docker.com ベストプラクティス準拠）

- **小さく安全なベースイメージを使う**（例: `alpine`, `distroless` を検討）
- **マルチステージビルド**で最終イメージを最小化
- **`.dockerignore` を整備**し不要ファイル流入を防ぐ
- **タグ戦略を明確化**（`latest` だけに依存しない。`1.4.2`, `2026-05-08` など）
- **1コンテナ1責務**を基本に Compose で連携
- **シークレットをイメージに焼き込まない**
  - NG: Dockerfile に API キー直書き
  - 推奨: 実行時注入（環境変数、シークレット機構）
- **ヘルスチェック**で自己診断可能にする
- **不要削除前に必ず確認**（`docker ps -a`, `docker images`, `docker volume ls`）

参考（公式）:
- https://docs.docker.com/build/building/best-practices/
- https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- https://docs.docker.com/compose/

---

## 5) 30〜60分ミニラボ

### ゴール
Nginx + 簡易アプリ（静的ページ）を Docker で起動し、Compose で管理、ログ確認まで実施。

### 手順（45分想定）
1. **プロジェクト作成（5分）**
   - `mkdir docker-mag-lab && cd docker-mag-lab`
   - `mkdir site && echo '<h1>Hello Docker Magazine</h1>' > site/index.html`

2. **Dockerfile 作成（10分）**
   - `Dockerfile`:
```dockerfile
FROM nginx:alpine
COPY site/index.html /usr/share/nginx/html/index.html
EXPOSE 80
```

3. **ビルド＆単体起動（10分）**
   - `docker build -t docker-mag:lab .`
   - `docker run -d --name docker-mag-web -p 8088:80 docker-mag:lab`
   - `curl http://localhost:8088`
   - `docker logs docker-mag-web`

4. **Compose 化（10分）**
   - `compose.yaml`:
```yaml
services:
  web:
    build: .
    ports:
      - "8088:80"
    restart: unless-stopped
```
   - 既存コンテナ停止: `docker stop docker-mag-web && docker rm docker-mag-web`
   - `docker compose up -d`
   - `docker compose ps`

5. **検証と後片付け（10分）**
   - `docker compose logs -f --tail=50`
   - 終了: `docker compose down`

> ⚠️ 注意: `docker system prune`, `docker image prune -a`, `docker rm -f`, `docker rmi` は破壊的です。実行前に対象確認し、必要なイメージ/コンテナ/ボリュームを誤削除しないこと。

---

## 6) Command cheatsheet

```bash
# 実行・確認
docker run -d --name app -p 8080:80 nginx:alpine
docker ps
docker logs -f app
docker exec -it app sh

# ビルド・配布
docker build -t myapp:dev .
docker image ls
docker tag myapp:dev <account>/myapp:1.0.0
docker push <account>/myapp:1.0.0

# Compose
docker compose up -d
docker compose ps
docker compose logs -f
docker compose down

# 状況確認（削除前）
docker system df
docker volume ls
docker network ls
```

---

## 7) よくあるミスと安全策

- **ミス:** `latest` 固定で再現不能
  - **安全策:** 明示タグ（SemVer/日付）を使用

- **ミス:** 秘密情報を Dockerfile / compose.yaml に直書き
  - **安全策:** `.env` / シークレット管理を利用し、Git 追跡除外

- **ミス:** 不用意な prune で開発資産消失
  - **安全策:** 削除前に `ls/ps/df` で対象確認、必要ならバックアップ

- **ミス:** コンテナを root 前提で運用
  - **安全策:** 非 root ユーザー実行を検討、最小権限を徹底

- **ミス:** ログを見ずに再起動連打
  - **安全策:** `docker logs`, `docker inspect` で原因特定してから対処

---

## 8) 面接風質問（1問）

**質問:**
「開発環境で動いている Docker コンテナを本番に近づけるために、あなたなら Dockerfile と Compose のどこを改善しますか？（セキュリティ・再現性・運用性の観点で3点以上）」

---

## 9) 次の一歩（公式ドキュメント優先）

- Docker Get Started
  - https://docs.docker.com/get-started/
- Dockerfile ベストプラクティス
  - https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Build best practices
  - https://docs.docker.com/build/building/best-practices/
- Docker Compose ガイド
  - https://docs.docker.com/compose/gettingstarted/
- Docker Engine セキュリティ
  - https://docs.docker.com/engine/security/

---

### 明日の予告
次号は **Middle → Advanced 寄り**で、`buildx` によるマルチアーキテクチャビルドと、CI でのキャッシュ戦略を扱います。
