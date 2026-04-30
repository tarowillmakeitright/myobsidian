---
tags: [docker, containers, devops, learning, daily]
---

# 2026-04-30 Docker Commands Magazine

[[Home]]

#docker #containers #devops #learning #daily

## 今号のテーマ
**Dockerコマンド実践アーク：Beginner → Middle → Advanced**

---

## 1) Topic + Level

### 🟢 Beginner
**トピック:** `docker run` / `docker ps` / `docker logs` で「まず動かして観察する」

### 🟡 Middle（前提あり）
**トピック:** `Dockerfile` + `docker build` + `docker compose up` でローカル開発環境を組む

**前提（Prerequisites）**
- Beginnerの内容（コンテナ起動・停止・ログ確認）ができる
- Linux基本コマンド（`cd`, `ls`, `cat`）
- アプリの環境変数の基礎知識

### 🔴 Advanced（前提あり）
**トピック:** BuildKit活用・マルチステージビルド・キャッシュ最適化・セキュア運用

**前提（Prerequisites）**
- Middleの内容（Dockerfile/Compose）を1回以上触ったことがある
- CI/CDの基本概念（ビルド→テスト→デプロイ）
- イメージレイヤー構造の概念を理解している

---

## 2) Why it matters for real app development
- **環境差分の削減:** 「自分のPCでは動く」を減らし、チーム開発の再現性を高める。
- **オンボーディング高速化:** 新メンバーが `docker compose up` で開発開始できる。
- **品質とセキュリティ向上:** 小さく安全なイメージ、依存固定、不要権限の回避が実運用で効く。
- **CIとの接続が容易:** ローカルとCIの実行環境を揃えやすく、デバッグが速くなる。

---

## 3) Core Docker command explanations

### Beginner向け必須
- `docker run --name web -d -p 8080:80 nginx:alpine`
  - イメージからコンテナを起動。
  - `-d`: バックグラウンド実行
  - `-p`: ホスト:コンテナ のポート公開
- `docker ps` / `docker ps -a`
  - 稼働中 / 全コンテナ一覧
- `docker logs -f web`
  - ログ追跡（`Ctrl+C` で抜ける）
- `docker stop web && docker rm web`
  - 停止して削除

### Middle向け
- `docker build -t myapp:dev .`
  - カレントディレクトリのDockerfileでイメージ作成
- `docker compose up --build`
  - 複数サービス起動（必要ならビルド）
- `docker compose logs -f`
  - 全サービスのログを追跡
- `docker compose down`
  - Composeで作ったリソースを停止・削除

### Advanced向け
- `docker buildx build --platform linux/amd64,linux/arm64 -t myapp:multi .`
  - マルチアーキ向けビルド
- `docker image inspect myapp:dev`
  - イメージ詳細（レイヤ、設定）を確認
- `docker history myapp:dev`
  - レイヤサイズ分析で肥大化ポイントを把握

---

## 4) App開発での使い方（docs.docker.comベストプラクティス整合）

- **小さなベースイメージを選ぶ**（例: `alpine` / `slim`）
- **マルチステージビルドを使う**（ビルド成果物だけ最終イメージへ）
- **`.dockerignore` を整備**（不要ファイル送信を防ぐ）
- **依存は固定バージョン寄り**（再現性を確保）
- **コンテナは原則1プロセス/責務**
- **Secretsをイメージに埋め込まない**
  - NG: `ENV API_KEY=...` をDockerfileへ直書き
  - OK: 実行時注入（環境変数/シークレット管理）
- **最小権限で実行**（必要なら非rootユーザー）

---

## 5) 30-60分ハンズオン・ミニラボ

### 目的
「シンプルなWebアプリをDocker化し、Composeで起動、ログ確認、停止まで」

### 手順（約45分）
1. サンプルアプリ用フォルダを作る
   - `mkdir docker-lab && cd docker-lab`
2. `app.py` と `requirements.txt` を作る（Flask最小構成）
3. Dockerfile作成（例）
   ```Dockerfile
   FROM python:3.12-slim
   WORKDIR /app
   COPY requirements.txt .
   RUN pip install --no-cache-dir -r requirements.txt
   COPY . .
   EXPOSE 5000
   CMD ["python", "app.py"]
   ```
4. ビルド
   - `docker build -t flask-lab:dev .`
5. 起動
   - `docker run --name flask-lab -d -p 5000:5000 flask-lab:dev`
6. 動作確認
   - ブラウザで `http://localhost:5000`
   - `docker logs -f flask-lab`
7. 停止/削除
   - `docker stop flask-lab && docker rm flask-lab`
8. 余力があれば `compose.yaml` を作って `docker compose up --build` へ置換

**達成条件**
- 自力でビルド→起動→ログ確認→終了ができる
- Dockerfileの各行の役割を説明できる

---

## 6) Command cheatsheet

```bash
# 基本
docker pull nginx:alpine
docker run --name web -d -p 8080:80 nginx:alpine
docker ps
docker logs -f web
docker exec -it web sh
docker stop web
docker rm web

# イメージ
docker build -t myapp:dev .
docker images
docker image inspect myapp:dev
docker history myapp:dev

# Compose
docker compose up --build
docker compose ps
docker compose logs -f
docker compose down
```

---

## 7) Common mistakes and safe practices

### よくあるミス
- Dockerfileに秘密情報（APIキー、DBパスワード）を直接書く
- `latest` タグに依存し、再現性を壊す
- 不要なファイルをビルドコンテキストへ含めてビルド遅延
- コンテナ内部の変更を永続化できると誤解する

### Safe practices
- `.env` やシークレット管理で実行時注入（ただし`.env`のGit管理に注意）
- `.dockerignore` を必ず用意
- イメージサイズを定期点検（`docker history`）
- 不要リソース削除は影響確認してから実施

⚠️ **破壊的コマンド注意（要確認）**
- `docker system prune`
- `docker image prune -a`
- `docker rm -f <container>`
- `docker rmi <image>`

これらは他プロジェクトに影響する可能性があります。実行前に対象確認・チーム共有を推奨。

---

## 8) Interview-style question

**質問:**
「開発環境でDockerイメージのビルド時間が長くなってきました。あなたならDockerfileとワークフローをどう改善しますか？」

**期待される観点（例）:**
- 変更頻度の低いレイヤ（依存インストール）を先に置く
- `.dockerignore` 整備
- マルチステージビルド
- キャッシュ活用（BuildKit/CIキャッシュ）
- ベースイメージの見直し

---

## 9) Next-step resources（公式優先）

- Docker Get Started  
  https://docs.docker.com/get-started/
- Dockerfile best practices  
  https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Multi-stage builds  
  https://docs.docker.com/build/building/multi-stage/
- Build cache  
  https://docs.docker.com/build/cache/
- Docker Compose overview  
  https://docs.docker.com/compose/
- Docker Engine security  
  https://docs.docker.com/engine/security/

---

次号予告：
**「Middle強化回：ComposeでDB(PostgreSQL)とアプリを連携し、ヘルスチェックと永続ボリュームを実装する」**