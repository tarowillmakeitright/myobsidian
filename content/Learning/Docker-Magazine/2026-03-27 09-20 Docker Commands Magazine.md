---
tags: [docker, containers, devops, learning, daily]
---
# Docker Commands Magazine — 2026-03-27
#docker #containers #devops #learning #daily
[[Home]]

今日のテーマは **「開発で毎日使う Docker コマンド実践」**。  
難易度を **Beginner → Middle → Advanced** で段階的に進めます。

---

## 1) Topic + Level

### Beginner
**トピック:** イメージ/コンテナの基本操作（`pull`, `run`, `ps`, `logs`, `stop`, `rm`）

### Middle
**トピック:** 開発向け Dockerfile と `build`, `exec`, `cp`, ボリューム活用
**前提条件:** Beginner のコマンドで「起動・停止・確認」ができること

### Advanced
**トピック:** Compose で複数サービス運用（アプリ + DB）と安全なクリーンアップ
**前提条件:** Middle の Dockerfile ビルドとコンテナ内デバッグができること

---

## 2) なぜ実アプリ開発で重要か

- ローカル環境差分（OS/バージョン違い）を減らし、**再現可能な開発環境**を作れる
- チーム全員が同じ手順で動かせるため、**オンボーディングが速い**
- CI/CD と同じ発想でローカル検証でき、**本番事故の予防**につながる
- Dockerfile/Compose を設計資産として残せる（インフラ知識の共有）

---

## 3) Core Docker command explanations

### Beginner 基本コマンド
- `docker pull nginx:1.27-alpine`  
  イメージを取得（タグ固定で再現性を高める）
- `docker run -d --name web -p 8080:80 nginx:1.27-alpine`  
  バックグラウンド起動、ポート公開、名前付きコンテナ
- `docker ps` / `docker ps -a`  
  稼働中 / 全コンテナ確認
- `docker logs -f web`  
  ログ追跡（原因調査の第一歩）
- `docker stop web && docker rm web`  
  停止して削除（順序を守る）

### Middle 実装寄りコマンド
- `docker build -t myapp:dev .`  
  Dockerfile からイメージ作成
- `docker exec -it myapp sh`  
  コンテナ内シェルで調査
- `docker cp myapp:/app/logs ./logs`  
  コンテナ内ファイルを取り出す
- `docker volume ls` / `docker volume inspect <name>`  
  永続データの確認

### Advanced 運用寄りコマンド
- `docker compose up -d --build`  
  複数サービスを一括起動
- `docker compose ps` / `docker compose logs -f`  
  サービス状態・統合ログ確認
- `docker compose down`  
  ネットワーク含め安全停止
- `docker compose down -v`  
  **注意:** DBボリュームも削除される可能性あり（要バックアップ確認）

---

## 4) アプリ構築時の Docker 利用（docs.docker.com ベストプラクティス準拠）

- **最小ベースイメージ**を選ぶ（例: `alpine`, `slim`）
- **マルチステージビルド**で不要なビルド成果物を最終イメージに含めない
- `Dockerfile` はレイヤーキャッシュを意識（依存関係を先にコピー）
- `latest` 固定を避け、**明示タグ/ダイジェスト**利用
- `.dockerignore` で不要ファイルをビルドコンテキストから除外
- **Secrets をイメージに埋め込まない**（`ENV`, `ARG` への直書き禁止）
  - 開発時: `.env` + Compose の `env_file` / 実行時注入
  - 本番時: Docker secrets や外部シークレットマネージャ推奨
- コンテナは基本 **1プロセス責務**、状態はボリューム/外部DBへ

---

## 5) 30–60分ハンズオン Mini Lab（約45分）

### ゴール
Node.js API + Redis を Compose で起動し、ログ確認と安全停止まで実施。

### 手順
1. **プロジェクト作成（5分）**
   - `mkdir docker-mag-lab && cd docker-mag-lab`
   - `app/server.js`, `package.json`, `Dockerfile`, `compose.yaml` を作成

2. **Dockerfile 作成（10分）**
   - `node:20-alpine` ベース
   - `WORKDIR /app`
   - `package*.json` を先にコピーして `npm ci`
   - `COPY . .`
   - `USER node`（可能なら非root実行）

3. **Compose 起動（10分）**
   - `app` と `redis` サービス定義
   - `docker compose up -d --build`
   - `docker compose ps` で状態確認

4. **動作確認/デバッグ（10分）**
   - `curl http://localhost:3000/health`
   - `docker compose logs -f app`
   - `docker exec -it <app_container> sh`

5. **停止と後片付け（10分）**
   - `docker compose down`
   - 必要時のみ `docker image ls` で不要確認
   - 破壊的クリーンアップは今日は実行しない

---

## 6) Command cheatsheet

```bash
# 取得・起動
docker pull <image:tag>
docker run -d --name <name> -p <host>:<container> <image:tag>

# 状態確認
docker ps
docker logs -f <container>
docker inspect <container>

# ビルド・実行
docker build -t <name:tag> .
docker exec -it <container> sh

# Compose
docker compose up -d --build
docker compose ps
docker compose logs -f
docker compose down

# クリーンアップ（⚠要注意）
# docker system prune -a
# docker image rm -f <image>
# docker rm -f <container>
```

---

## 7) よくあるミスと安全策

### よくあるミス
- `:latest` を使って環境差分が発生
- `.dockerignore` 不備で `.git` や秘密情報を含めてしまう
- `docker rm -f` / `rmi -f` / `system prune -a` を無確認で実行
- Compose で `down -v` 実行し、DBデータを消してしまう

### 安全策
- 事前に `docker ps -a`, `docker images`, `docker volume ls` を確認
- 破壊的コマンド前に「何が消えるか」を言語化して確認
- バックアップ可能な設計（named volume + dump運用）
- シークレットは環境注入し、イメージ・Gitに保存しない

> ⚠ **警告（破壊的コマンド）**  
> `docker system prune`, `docker image rm -f`, `docker rm -f`, `docker compose down -v` はデータ損失リスクがあります。対象確認・バックアップ確認後にのみ実行してください。

---

## 8) 面接風質問（1問）

**質問:**  
`docker run` と `docker compose up` の使い分けを、ローカル開発（単体サービス）と実アプリ開発（複数依存サービス）でどう判断しますか？  
また、再現性とチーム開発観点でのメリット/デメリットを説明してください。

---

## 9) 次の学習リソース（公式優先）

- Docker Docs Home: https://docs.docker.com/
- Get Started: https://docs.docker.com/get-started/
- Dockerfile best practices: https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Multi-stage builds: https://docs.docker.com/build/building/multi-stage/
- Compose overview: https://docs.docker.com/compose/
- Compose file reference: https://docs.docker.com/compose/compose-file/
- Docker Engine security: https://docs.docker.com/engine/security/
- Build secrets (BuildKit): https://docs.docker.com/build/building/secrets/

---

明日の予告（学習アーク継続）:  
**「Docker ネットワーク基礎→Composeネットワーク設計→本番を意識した分離戦略」**
