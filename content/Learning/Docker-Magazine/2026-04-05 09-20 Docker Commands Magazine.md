---
tags:
  - docker
  - containers
  - devops
  - learning
  - daily
---

# Docker Commands Magazine — 2026-04-05 09:20
[[Home]]

今日のテーマは、**開発フローに沿って Docker コマンドを段階的に使いこなす**ことです。  
学習アーク: **Beginner → Middle → Advanced**

---

## 1) Topic + Level

### Beginner（初級）
**Topic:** `docker run` / `docker ps` / `docker logs` で「動かして観察する」

### Middle（中級）
**Topic:** `docker build` / `docker compose up` で「アプリを再現可能にする」  
**前提知識:**
- Beginner のコマンド（run/ps/logs）
- Dockerfile の基本（FROM, COPY, RUN, CMD）

### Advanced（上級）
**Topic:** BuildKit キャッシュ + マルチステージ + セキュア運用で「速く・安全に届ける」  
**前提知識:**
- Middle の内容（build/compose）
- レイヤーキャッシュの概念
- `.dockerignore` と環境変数運用の基礎

---

## 2) なぜ実アプリ開発で重要か

- ローカル環境差分（OS/ライブラリ差）で壊れにくくなる
- チーム開発・CI で「同じ手順で同じ結果」を出せる
- トラブルシュートがしやすくなる（ログ・コンテナ状態を標準化）
- セキュリティ/供給網対策（最小イメージ・秘密情報の分離）を実装しやすい

---

## 3) Core Docker command explanations

### Beginner 核心コマンド
- `docker run -d --name web -p 8080:80 nginx:alpine`  
  イメージからコンテナを作成して起動。`-d` はバックグラウンド、`-p` でポート公開。
- `docker ps` / `docker ps -a`  
  稼働中 / 全コンテナを確認。
- `docker logs -f web`  
  コンテナログを追跡（`-f` = follow）。
- `docker exec -it web sh`  
  稼働中コンテナへ入って確認。

### Middle 核心コマンド
- `docker build -t myapp:dev .`  
  Dockerfile からイメージ作成。
- `docker compose up -d`  
  複数サービス（app/db等）をまとめて起動。
- `docker compose logs -f app`  
  特定サービスのログ追跡。
- `docker compose down`  
  構成を停止・削除（ボリューム削除は `-v` が必要）。

### Advanced 核心コマンド
- `docker buildx build --progress=plain -t myapp:prod .`  
  BuildKit/Buildx を使った高機能ビルド。
- `docker image inspect myapp:prod`  
  メタデータ確認（設定ミスやサイズ調査）。
- `docker history myapp:prod`  
  レイヤー構造確認（無駄な層・機密混入の手掛かり）。
- `docker compose config`  
  compose 設定の最終解決結果を検証。

---

## 4) 実アプリ構築での使い方（docs.docker.com ベストプラクティス準拠）

- **小さく保つ:** 軽量ベースイメージ + 不要ファイル除外（`.dockerignore`）
- **マルチステージビルド:** ビルド成果物だけを実行イメージへコピー
- **依存の固定:** ベースタグや依存バージョンを明示し再現性確保
- **1コンテナ1責務を意識:** app / db / cache を compose で分離
- **秘密情報を焼き込まない:**
  - Dockerfile に API キー直書き禁止
  - `ARG/ENV` に機密を埋め込んでコミットしない
  - 実運用は secret 管理機構（Compose secrets/外部 secret manager）を利用
- **不要な権限を減らす:** 可能なら non-root ユーザー実行

---

## 5) 30-60分ミニラボ（実践）

### ゴール
Node.js API を Docker 化し、Compose で app + redis を起動。ログ確認まで。

### 手順（約45分）
1. **サンプルAPI準備（10分）**
   - `app.js` で簡単な `/health` エンドポイントを作成
2. **Dockerfile 作成（10分）**
   - `node:20-alpine` ベース
   - `package*.json` 先コピーでキャッシュ効率化
   - `npm ci --omit=dev`
3. **Compose 作成（10分）**
   - `app` と `redis` サービス定義
   - `depends_on` を設定
4. **起動と検証（10分）**
   - `docker compose up -d --build`
   - `curl http://localhost:3000/health`
   - `docker compose logs -f app`
5. **後片付け（5分）**
   - `docker compose down`

### 追加チャレンジ（+10分）
- Dockerfile をマルチステージ化し、最終イメージサイズ比較（`docker images`）

---

## 6) Command cheatsheet

```bash
# コンテナ起動/確認
docker run -d --name web -p 8080:80 nginx:alpine
docker ps
docker logs -f web
docker exec -it web sh

# イメージ作成/確認
docker build -t myapp:dev .
docker images
docker history myapp:dev

# Compose
docker compose up -d --build
docker compose logs -f app
docker compose config
docker compose down

# クリーンアップ（注意して実行）
docker rm <container>
docker rmi <image>
```

---

## 7) よくあるミス & 安全運用

- **ミス:** Dockerfile に `.env` や秘密鍵を COPY してしまう  
  **対策:** `.dockerignore` に `.env`, `*.pem`, `.git` などを追加。

- **ミス:** `latest` タグ依存で挙動が日によって変わる  
  **対策:** バージョンタグを固定。

- **ミス:** 破壊的クリーンアップを無自覚に実行  
  **注意喚起（重要）:**
  - `docker system prune -a`
  - `docker image prune -a`
  - `docker rmi -f ...`
  - `docker rm -f ...`
  は未使用資産や実行中リソースに影響し得ます。**対象確認後に実行**し、共有環境では事前合意を取る。

- **ミス:** コンテナを root 前提で運用  
  **対策:** 可能な限り non-root ユーザーへ。

---

## 8) 面接風クエスチョン（1問）

> 「Dockerfile で `COPY . .` を早い段階で書くと、ビルド時間やセキュリティにどんな影響がありますか？改善案も説明してください。」

---

## 9) 次の学習リソース（公式優先）

- Docker Docs Home  
  https://docs.docker.com/
- Get Started  
  https://docs.docker.com/get-started/
- Dockerfile best practices  
  https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Multi-stage builds  
  https://docs.docker.com/build/building/multi-stage/
- Compose overview  
  https://docs.docker.com/compose/
- Build cache  
  https://docs.docker.com/build/cache/
- Docker Scout（イメージ脆弱性や推奨修正）  
  https://docs.docker.com/scout/

---

次号予告: **「デバッグ効率を上げるコンテナ観測（logs/exec/stats/inspect）」**