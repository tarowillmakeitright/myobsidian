---
tags: [docker, containers, devops, learning, daily]
---

# Docker Commands Magazine — 2026-03-26
[[Home]]

#docker #containers #devops #learning #daily

> 今日の学習アーク: **コンテナのライフサイクル管理（作る→動かす→運用する）**  
> 難易度: **Beginner → Middle → Advanced**

---

## 1) Topic + Level

### Beginner
**トピック:** `docker run / ps / logs / exec / stop / rm` で単一コンテナを安全に扱う

### Middle
**トピック:** `Dockerfile` と `docker build`、`docker compose up` で開発環境を再現可能にする  
**前提知識:** Beginner内容（コンテナ基本操作、ログ確認、停止と削除）

### Advanced
**トピック:** マルチステージビルド、最小権限、ヘルスチェック、イメージ最適化とクリーンアップ戦略  
**前提知識:** Middle内容（Dockerfile作成、Composeで複数サービス起動、基本的なネットワーク理解）

---

## 2) Why it matters for real app development

- 開発者ごとの差異（OS/依存関係）を減らし、**「自分のPCでは動く問題」**を減らせる
- CI/CDで同じイメージを使うことで、テスト環境と本番環境の差異を縮小できる
- ログ・ヘルスチェック・再起動ポリシーにより、障害時の原因特定と復旧が速くなる
- セキュアなDockerfile運用（root回避・シークレット管理）で、事故や情報漏えいリスクを下げられる

---

## 3) Core Docker command explanations

### Beginner Core
- `docker run -d --name web -p 8080:80 nginx:alpine`  
  Nginxコンテナをバックグラウンド起動。`-p` は `ホスト:コンテナ`。
- `docker ps` / `docker ps -a`  
  実行中 / すべてのコンテナ一覧。
- `docker logs -f web`  
  コンテナログを追跡（`-f` = follow）。
- `docker exec -it web sh`  
  稼働中コンテナ内部へ入って確認。
- `docker stop web` → `docker rm web`  
  停止してから削除する基本手順。

### Middle Core
- `docker build -t myapp:dev .`  
  Dockerfileからイメージ作成。
- `docker compose up -d`  
  複数サービス（例: app + db）をまとめて起動。
- `docker compose logs -f app`  
  特定サービスログを追跡。
- `docker compose down`  
  サービス停止とネットワーク解放（ボリューム削除は `-v` 指定時のみ）。

### Advanced Core
- `docker build --target runtime -t myapp:prod .`  
  マルチステージビルドの特定ターゲットを利用。
- `docker inspect <container>`  
  設定・ネットワーク・ヘルス状態を詳細確認。
- `docker stats`  
  CPU/メモリ利用をリアルタイム監視。
- `docker image ls` / `docker image prune`  
  イメージ管理。**pruneは削除対象を必ず確認してから**。

---

## 4) How Docker is used while building apps（docs.docker.comベストプラクティス準拠）

1. **開発時**
   - `compose.yaml` で app/db/redis 等を定義してチーム全員の環境を統一
   - 依存のインストールはDockerfileで明示し、手動セットアップを減らす

2. **ビルド時**
   - `.dockerignore` を整備して不要ファイルを除外（ビルド高速化・漏えい防止）
   - マルチステージビルドで最終イメージを小さく、攻撃面を縮小
   - 可能な限り固定バージョン（例: `node:22-alpine`）を使い再現性を高める

3. **運用前チェック**
   - `HEALTHCHECK` を使ってサービス健全性を確認
   - rootユーザー常用を避ける（`USER` 指定）
   - 秘密情報はイメージに焼き込まない（環境変数/secret管理を利用）

---

## 5) 30-60 minute hands-on mini lab

**ラボ名:** Flask + Redis をComposeで立ち上げ、ログ確認と安全な停止を実施する（45分目安）

### ゴール
- 単一コンテナ操作（Beginner）
- Composeで複数サービス起動（Middle）
- ヘルス/ログ/安全なクリーンアップ（Advanced導入）

### 手順
1. **準備（10分）**
   - ディレクトリ作成
   - `app.py`, `requirements.txt`, `Dockerfile`, `compose.yaml` を用意

2. **ビルドと起動（10分）**
   - `docker compose up -d --build`

3. **確認（10分）**
   - `docker compose ps`
   - `docker compose logs -f app`
   - ブラウザで `http://localhost:5000` を開く

4. **コンテナ内確認（5分）**
   - `docker compose exec app sh`
   - 必要なら `env` やファイル配置を確認

5. **停止と片付け（10分）**
   - `docker compose down`
   - 不要リソースだけ手動確認して削除

### 最小サンプル `compose.yaml`
```yaml
services:
  app:
    build: .
    ports:
      - "5000:5000"
    environment:
      - REDIS_HOST=redis
    depends_on:
      - redis
  redis:
    image: redis:7-alpine
```

---

## 6) Command cheatsheet

```bash
# 起動
docker run -d --name web -p 8080:80 nginx:alpine

# 状態確認
docker ps
docker ps -a

# ログ
docker logs -f web
docker compose logs -f app

# コンテナ内に入る
docker exec -it web sh
docker compose exec app sh

# ビルド/起動/停止
docker build -t myapp:dev .
docker compose up -d --build
docker compose down

# リソース確認
docker image ls
docker volume ls
docker network ls
```

---

## 7) Common mistakes and safe practices

### よくあるミス
1. `latest` タグ依存で、環境差異が突然発生する
2. `.env` や秘密鍵をイメージに COPY してしまう
3. `docker system prune -a` を意味を理解せず実行して必要データを消す
4. rootユーザー前提でコンテナを実行する

### 安全運用のポイント
- **破壊的コマンドは事前確認必須**  
  - `docker system prune`, `docker image prune -a`, `docker rm -f`, `docker rmi`, `docker volume prune` 実行前に削除対象を確認
- 本番・重要データのある環境では、先にバックアップ方針を確認
- シークレットは Dockerfile/compose.yaml に平文で固定しない
- 最小権限ユーザーで実行し、不要ポート公開を避ける

---

## 8) One interview-style question

**質問:**  
`docker compose down -v` と `docker compose down` の違いは何ですか？開発環境と本番相当環境で使い分ける理由も説明してください。

---

## 9) Next-step resources（公式優先）

- Docker Docs Home: https://docs.docker.com/
- Get Started: https://docs.docker.com/get-started/
- Dockerfile best practices: https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Multi-stage builds: https://docs.docker.com/build/building/multi-stage/
- Compose overview: https://docs.docker.com/compose/
- Compose file reference: https://docs.docker.com/compose/compose-file/
- Engine security: https://docs.docker.com/engine/security/
- Prune reference（削除系コマンド注意）: https://docs.docker.com/config/pruning/

---

次号予告: **Beginner: ボリューム基礎 → Middle: DB永続化設計 → Advanced: バックアップ/リストア運用**