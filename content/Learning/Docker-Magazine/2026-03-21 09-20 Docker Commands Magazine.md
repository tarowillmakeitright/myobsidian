# Docker Commands Magazine — 2026-03-21
Tags: #docker #containers #devops #learning #daily  
Links: [[Home]]

---

# 今日の特集
**テーマ:** Dockerで開発環境を再現し、デバッグし、最終的に運用に近い形へつなげる  
**学習アーク:** Beginner → Middle → Advanced

この号は、同じ題材（シンプルなWeb API）を段階的に育てる構成です。実務で「まず動かす → 調査する → 安全に最適化する」という流れを意識しています。

---

## 1) Topic + Level

### Beginner（入門）
**トピック:** `docker run` / `docker ps` / `docker logs` で「まず1コンテナを動かす」

### Middle（中級）
**トピック:** `Dockerfile` + `docker build` + `docker compose up` で「開発環境をチームで再現する」

**前提知識（Prerequisites）:**
- Beginner内容を理解している
- Linux基本コマンド（`cd`, `ls`, `cat`）
- アプリの依存関係という概念（例: Node.jsの`package.json`）

### Advanced（上級）
**トピック:** マルチステージビルド・最小権限・ヘルスチェックで「本番を意識した安全なイメージ運用」

**前提知識（Prerequisites）:**
- Middle内容を実際に試した
- レイヤーキャッシュの概念
- `.env` とシークレットの違いを理解している

---

## 2) なぜ実アプリ開発で重要か

- **環境差分の削減:** 「自分のPCでは動く」を減らし、レビュー・CI・本番に近い形で再現できる。
- **オンボーディング高速化:** 新メンバーがDocker + Composeで短時間に開発開始できる。
- **デバッグ効率:** ログ・環境変数・ポート・依存サービスの状態を切り分けやすい。
- **セキュリティと保守性:** 小さいイメージ、最小権限、明示的な設定で事故を減らせる。

---

## 3) Core Docker command 解説

### 入門コマンド
- `docker run -d -p 8080:80 --name web nginx:alpine`
  - `-d`: バックグラウンド実行
  - `-p`: ホスト:コンテナのポート公開
  - `--name`: 管理しやすいコンテナ名
- `docker ps` / `docker ps -a`
  - 稼働中 / 全コンテナ一覧
- `docker logs -f web`
  - `-f` で追尾。障害調査の基本
- `docker exec -it web sh`
  - コンテナ内確認（パッケージ、設定、ファイル）

### 中級コマンド
- `docker build -t myapp:dev .`
  - Dockerfileからイメージ作成
- `docker compose up -d`
  - 複数サービス（app + db等）をまとめて起動
- `docker compose logs -f app`
  - サービス単位でログ追跡
- `docker compose down`
  - 構成停止（必要に応じて`-v`）

### 上級コマンド
- `docker build --target runtime -t myapp:prod .`
  - マルチステージの最終ステージのみ利用
- `docker image ls`, `docker history myapp:prod`
  - 画像サイズ・レイヤー確認
- `docker inspect <container>`
  - 実行設定・ネットワーク・ヘルス状態の詳細把握

---

## 4) docs.docker.com ベストプラクティスに沿った実装観点

- **小さいベースイメージを選ぶ**（必要十分な内容に絞る）
- **マルチステージビルド**でビルド依存物をランタイムに持ち込まない
- **不要ファイルを送らない**（`.dockerignore`）
- **1コンテナ1責務**（app / db / cacheを分離）
- **イメージに秘密情報を埋め込まない**
  - `ENV` や `ARG` にAPIキーを直書きしない
  - Composeファイルへ平文で機密情報を書かない
- **非rootユーザーで実行**（可能な限り）
- **ヘルスチェック**で死活監視を明示

---

## 5) 30–60分ハンズオン mini lab

### ゴール
Node.jsの簡易APIをDocker化し、Composeで起動、ログ確認、ヘルス確認まで行う。

### 手順（目安45分）

1. **プロジェクト作成（10分）**
   - `server.js` を作成（`/health` で `ok` を返す）
   - `package.json` を作成

2. **Dockerfile作成（10分）**
   - `node:20-alpine` をベース
   - 依存を先にコピーしてキャッシュ効率を上げる
   - `USER node` で非root実行

3. **Compose作成（10分）**
   - `app` サービスで `3000:3000` を公開
   - `restart: unless-stopped`

4. **起動と確認（10分）**
   - `docker compose up -d --build`
   - `curl http://localhost:3000/health`
   - `docker compose logs -f app`

5. **改善（5分）**
   - `HEALTHCHECK` をDockerfileへ追加
   - `.dockerignore` に `node_modules` などを追加

### 追加チャレンジ（余裕があれば）
- マルチステージ化し、最終イメージサイズを比較
- `docker history` で差分を確認

---

## 6) Command Cheatsheet

```bash
# 基本操作
docker run -d -p 8080:80 --name web nginx:alpine
docker ps
docker logs -f web
docker exec -it web sh

docker build -t myapp:dev .
docker compose up -d
docker compose logs -f app
docker compose down

docker image ls
docker inspect web
docker history myapp:dev

# ⚠ 破壊的操作（実行前に対象確認）
# docker container rm -f <id>
# docker image rm <id>
# docker system prune -a
```

---

## 7) よくあるミス & 安全な運用

### よくあるミス
- **`latest` タグ固定**で再現性が崩れる
- **ポート競合**（既に同ポート使用中）
- **ログを見ずに再起動連打**して原因を見失う
- **機密情報をDockerfile/Composeに直書き**
- **`prune` を無確認で実行**して必要データを消す

### 安全な運用
- イメージタグは明示（例: `myapp:1.4.2`）
- 先に `docker ps`, `docker image ls`, `docker volume ls` で現状確認
- 破壊系コマンド前に「何が消えるか」を明確化
- 機密情報はシークレット管理（少なくともイメージ内に焼き込まない）
- 本番想定では非root + 最小権限 + 最小イメージを徹底

---

## 8) Interview-style Question

**Q.** 開発用Dockerfileを本番にそのまま使うと、どんな問題が起こりやすいですか？また、どう改善しますか？

**期待される観点:**
- デバッグツール混入によるイメージ肥大化
- セキュリティリスク（root実行・不要パッケージ）
- ビルド成果物とランタイム分離不足
- マルチステージ化、非root化、依存最小化、タグ固定で改善

---

## 9) Next-step resources（公式優先）

- Docker Get Started  
  https://docs.docker.com/get-started/
- Dockerfile best practices  
  https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Multi-stage builds  
  https://docs.docker.com/build/building/multi-stage/
- Compose overview  
  https://docs.docker.com/compose/
- Compose file reference  
  https://docs.docker.com/reference/compose-file/
- Docker Engine security  
  https://docs.docker.com/engine/security/
- Build secrets（機密情報の安全な扱い）  
  https://docs.docker.com/build/building/secrets/

---

## 明日の予告（Learning Arc 継続）
次号は「Dockerネットワークと依存サービス接続（app + db + cache）」を Beginner → Middle → Advanced で継続します。
