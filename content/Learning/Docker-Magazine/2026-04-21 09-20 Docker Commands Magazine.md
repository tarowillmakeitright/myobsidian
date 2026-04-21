# 2026-04-21 09:20 Docker Commands Magazine

Tags: #docker #containers #devops #learning #daily  
Links: [[Home]]

---

## 今回の学習アーク
1. **Beginner:** `docker run` と `docker ps` で「まず動かす」
2. **Middle:** `Dockerfile` + `docker build` + `docker compose up` で「開発環境を組む」
3. **Advanced:** マルチステージビルド + ヘルスチェック + セキュア運用で「本番品質に寄せる」

---

## 1) Topic + Level

### 🟢 Beginner
**Topic:** コンテナの起動・確認・停止の基本

### 🟡 Middle（前提あり）
**Topic:** Node.js API を Docker で開発実行（Dockerfile + Compose）  
**Prerequisites:**
- `docker run` / `docker ps` / `docker stop` の基本がわかる
- Node.js アプリの最小構成（`package.json`）が読める
- 基本的なポート概念（例: 3000 番）

### 🔴 Advanced（前提あり）
**Topic:** 本番向けに近づける（マルチステージ、最小権限、ヘルスチェック、ログ確認）  
**Prerequisites:**
- Dockerfile と Compose の基本記法
- イメージレイヤーとキャッシュの概念
- Linux 権限（root / non-root）の基本

---

## 2) なぜ実アプリ開発で重要か
- **環境差分を減らせる**: 「自分のPCでは動く」問題を減らす。
- **オンボーディングが速い**: 新メンバーは Docker で同じ開発環境を即再現。
- **CI/CD と相性が良い**: ローカルと同じコンテナをテスト・デプロイに流せる。
- **セキュリティ運用しやすい**: 依存を閉じ込め、最小権限・最小イメージへ寄せられる。

---

## 3) コア Docker コマンド解説
- `docker run IMAGE`  
  イメージからコンテナを作って起動。`-d` でバックグラウンド、`-p` でポート公開。

- `docker ps` / `docker ps -a`  
  実行中 / 全コンテナの状態確認。トラブル時の第一歩。

- `docker logs -f CONTAINER`  
  コンテナログ追跡。アプリ起動失敗や接続エラー確認に必須。

- `docker exec -it CONTAINER sh`  
  実行中コンテナ内部へ入って確認。設定ファイル・環境変数の点検に使う。

- `docker build -t NAME:TAG .`  
  Dockerfile からイメージ生成。`-t` で名前/タグ付け。

- `docker compose up -d` / `docker compose down`  
  複数コンテナ（API + DB など）をまとめて起動/停止。

- `docker image ls` / `docker images`  
  ローカルイメージ一覧確認。容量管理にも有効。

---

## 4) アプリ開発での使い方（docs.docker.com ベストプラクティス寄せ）
- **小さく保つ**: 不要ファイルを `.dockerignore` で除外。
- **キャッシュを活かす**: 依存インストール層を先に置く（`package*.json` 先コピー）。
- **1コンテナ1責務を意識**: API と DB を分離し、Compose で連携。
- **設定は外出し**: 秘密情報はイメージに焼き込まない（`.env` / シークレット管理）。
- **最小権限**: 可能なら non-root ユーザーで実行。
- **固定タグを使う**: `latest` 依存を避け、再現性を確保。

---

## 5) 30〜60分ミニラボ（実践）

### 目標
Node.js API をコンテナ化し、`/health` を返すまで。

### 手順（約45分）
1. **最小API作成（10分）**
   - `server.js` で `GET /health` → `{"ok":true}` を返す。
2. **Dockerfile作成（10分）**
   - `node:20-alpine` ベース、`WORKDIR /app`、`npm ci`、`CMD ["node","server.js"]`。
3. **イメージビルド（5分）**
   - `docker build -t health-api:1.0 .`
4. **単体起動して確認（5分）**
   - `docker run -d --name health-api -p 3000:3000 health-api:1.0`
   - `curl http://localhost:3000/health`
5. **Compose化（10分）**
   - `compose.yaml` を作り `docker compose up -d`。
6. **検証とログ確認（5分）**
   - `docker compose ps`
   - `docker compose logs -f`

### 完了条件
- ブラウザ/`curl` で `{"ok":true}` が返る
- `docker compose up -d` だけで再現可能

---

## 6) Command Cheatsheet
```bash
# 起動中コンテナ確認
docker ps

# 全コンテナ確認
docker ps -a

# イメージ一覧
docker image ls

# ビルド
docker build -t myapp:1.0 .

# 実行
docker run -d --name myapp -p 3000:3000 myapp:1.0

# ログ追跡
docker logs -f myapp

# コンテナ内シェル
docker exec -it myapp sh

# Compose 起動/停止
docker compose up -d
docker compose down
```

---

## 7) よくあるミス & 安全プラクティス

### よくあるミス
- `COPY . .` で秘密情報（`.env`, 鍵ファイル）までイメージに入れてしまう
- `latest` タグ固定で、昨日と今日で動作がズレる
- root 実行のまま本番投入
- ローカル開発で `:ro`（read-only）にすべきボリュームを無制限でマウント

### 安全プラクティス
- `.dockerignore` を必ず整備
- Secrets は **環境変数直書き/イメージ焼き込み禁止**（Compose secrets や外部Secret Managerを検討）
- 依存ベースイメージを定期更新、脆弱性スキャンを実施
- `HEALTHCHECK` を設定し、死活監視しやすくする

### ⚠️ 破壊的コマンドの注意
以下はディスク解放に有効だが、**不要データを削除**する可能性があるため実行前に確認:
- `docker system prune`
- `docker image prune -a`
- `docker rmi ...`
- `docker rm -f ...`

> 実行前に「本当に消してよいコンテナ/イメージか」を `docker ps -a` と `docker image ls` で確認すること。

---

## 8) 面接っぽい質問（1問）
**Q.** `docker compose up --build` を毎回使うチームと、通常は `docker compose up -d` で必要時のみビルドするチーム、どちらが現実的？理由は？

**狙い:** ビルドコスト、再現性、CI との役割分担、開発体験のトレードオフを説明できるか。

---

## 9) 次の一歩リソース（公式優先）
- Docker Get Started  
  https://docs.docker.com/get-started/
- Dockerfile best practices  
  https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Compose overview  
  https://docs.docker.com/compose/
- Multi-stage builds  
  https://docs.docker.com/build/building/multi-stage/
- Build cache  
  https://docs.docker.com/build/cache/
- Docker Scout（脆弱性・サプライチェーン観点）  
  https://docs.docker.com/scout/

---

明日の予告: **「Beginner→Middle→Advanced: ボリューム/バインドマウント設計と開発効率」**