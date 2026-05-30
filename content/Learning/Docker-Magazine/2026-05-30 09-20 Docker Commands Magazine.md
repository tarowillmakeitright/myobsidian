---
tags: [docker, containers, devops, learning, daily]
---

# 2026-05-30 09:20 Docker Commands Magazine

[[Home]]

#docker #containers #devops #learning #daily

---

## 今号の学習アーク
- **Beginner → Middle → Advanced** の順で、同じ「コンテナ化されたアプリ開発」を段階的に深掘りします。
- テーマは一貫して **「開発中のコンテナ運用を安全・実践的に回す」** です。

---

## 1) Topic + Level

### 🟢 Beginner
**Topic:** はじめての `docker run` / `docker ps` / `docker logs`

### 🟡 Middle
**Topic:** `Dockerfile` と `docker build` で再現可能な開発環境を作る

**前提知識（Prerequisites）**
- Beginner のコマンドを使ってコンテナを起動・停止できる
- 基本的な Linux コマンド（`cd`, `ls`, `cat`）
- 1つ以上のアプリ言語（Node/Python/Go いずれか）の hello-world 経験

### 🔴 Advanced
**Topic:** マルチステージビルド + 最小権限実行 + 安全なクリーンアップ運用

**前提知識（Prerequisites）**
- Middle の内容（Dockerfile と build キャッシュ）を理解
- `.dockerignore` の目的を説明できる
- `docker compose` で複数サービスを起動した経験（初歩でOK）

---

## 2) なぜ実アプリ開発で重要か
- **環境差分バグを減らす**: 「自分のPCでは動くのに本番で動かない」を減らす。
- **オンボーディング高速化**: 新メンバーが同じコマンドで即開発開始できる。
- **CI/CD と一致**: ローカルとパイプラインの実行形態を揃えやすい。
- **セキュリティ改善**: 最小権限・不要ファイル除外・秘密情報の分離を徹底しやすい。

---

## 3) Core Docker command explanations

### Beginner 主要コマンド
- `docker run --name web -d -p 8080:80 nginx:alpine`
  - `run`: イメージからコンテナを作って起動
  - `--name`: 管理しやすい名前
  - `-d`: バックグラウンド実行
  - `-p 8080:80`: ホスト8080 → コンテナ80 を公開
- `docker ps` / `docker ps -a`
  - 稼働中 / 全コンテナ一覧を確認
- `docker logs -f web`
  - `-f` でログ追従（トラブル時の一次調査）
- `docker stop web` / `docker rm web`
  - 停止 / 削除（削除は停止後が基本）

### Middle 主要コマンド
- `docker build -t myapp:dev .`
  - Dockerfile からイメージ生成
- `docker image ls`
  - ローカルイメージ確認
- `docker exec -it <container> sh`
  - 稼働コンテナ内部で調査
- `docker compose up -d` / `docker compose down`
  - 複数サービス起動/停止

### Advanced 主要コマンド
- `docker build --target runtime -t myapp:prod .`
  - マルチステージの特定ステージを選択
- `docker inspect <container>`
  - 設定・ネットワーク・マウントの詳細確認
- `docker system df`
  - ディスク使用量把握（削除前の判断材料）

⚠️ **破壊的コマンド注意**
- `docker system prune`, `docker image prune -a`, `docker rm -f`, `docker rmi`
- これらは復旧が難しい削除を含みます。**実行前に対象確認**（`docker ps -a`, `docker image ls`, `docker system df`）し、共有環境では必ず合意してから。

---

## 4) 実アプリ構築での使い方（docs.docker.com ベストプラクティス準拠）
- **小さいベースイメージ**を選ぶ（例: `alpine`, distroless系の検討）
- **マルチステージビルド**でビルド依存物を最終イメージへ残さない
- **`.dockerignore` を整備**し、不要ファイル/秘密情報の混入を防ぐ
- **非rootユーザー実行**（`USER`）で被害範囲を縮小
- **イメージに秘密情報を埋め込まない**
  - NG: `ENV API_KEY=...` をDockerfileへ直書き
  - 推奨: 実行時環境変数・シークレット管理を利用
- **1コンテナ1責務**を意識し、連携は Compose/ネットワークで扱う

---

## 5) 30–60分ミニラボ

### ゴール
Node.js の簡単な Web API を Docker 化し、安全設定を1つ入れる。

### 手順（約45分）
1. 作業ディレクトリ作成
   - `mkdir docker-lab && cd docker-lab`
2. 最小アプリ作成（`server.js`）
   - 3000番で `Hello Docker` を返す
3. `Dockerfile` 作成
   - `node:20-alpine`
   - 依存インストール → ソースコピー
   - `USER node`
   - `EXPOSE 3000`
4. ビルド
   - `docker build -t hello-docker:lab .`
5. 実行
   - `docker run --name hello-lab -d -p 3000:3000 hello-docker:lab`
6. 動作確認
   - `curl http://localhost:3000`
   - `docker logs -f hello-lab`
7. 後片付け
   - `docker stop hello-lab && docker rm hello-lab`

### 追加チャレンジ（+15分）
- `.dockerignore` に `node_modules`, `.git`, `.env` を追加し、再ビルド時間やサイズ差を確認

---

## 6) Command cheatsheet
```bash
# 実行・確認
docker run --name app -d -p 8080:80 nginx:alpine
docker ps
docker logs -f app

# 停止・削除
docker stop app
docker rm app

# ビルド
docker build -t myapp:dev .
docker image ls

# Compose
docker compose up -d
docker compose down

# 状態確認
docker inspect app
docker system df

# ⚠️ 破壊的（要注意）
# docker system prune
# docker image prune -a
# docker rm -f <container>
# docker rmi <image>
```

---

## 7) よくあるミス & 安全策
- ミス: `.env` をイメージに含める
  - 安全策: `.dockerignore` で除外、秘密は実行時注入
- ミス: root 実行のまま本番運用
  - 安全策: `USER` 指定、必要最小権限
- ミス: `latest` タグ固定で再現性低下
  - 安全策: バージョンタグを明示（例 `node:20.11-alpine`）
- ミス: `prune` を無確認実行
  - 安全策: 事前に `docker system df` と対象一覧を確認
- ミス: 1コンテナにDB/アプリ/ジョブを詰め込む
  - 安全策: サービス分離し Compose で連携

---

## 8) Interview-style Question
**Q.** Dockerfile で `COPY . .` を早い段階に置くと、なぜビルドが遅くなることがある？どう改善する？

**A（要点）:** レイヤーキャッシュが無効化されやすく、依存インストール層まで毎回再実行されるため。`package*.json` など依存定義を先にCOPYして install、その後にアプリコードをCOPYする構成へ分離して改善する。

---

## 9) Next-step resources（公式優先）
- Docker 公式ドキュメント（入口）
  - https://docs.docker.com/
- Dockerfile ベストプラクティス
  - https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Multi-stage builds
  - https://docs.docker.com/build/building/multi-stage/
- Docker Compose 概要
  - https://docs.docker.com/compose/
- イメージビルド（Build 概要）
  - https://docs.docker.com/build/
- Docker Engine セキュリティ
  - https://docs.docker.com/engine/security/

---

次号予告: **Middle→Advanced の橋渡しとして「Compose で開発/本番差分を安全に管理（override, profiles, env分離）」** を扱います。