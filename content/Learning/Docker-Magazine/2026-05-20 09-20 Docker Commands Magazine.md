---
tags: [docker, containers, devops, learning, daily]
---

# 2026-05-20 09:20 Docker Commands Magazine

[[Home]]

#docker #containers #devops #learning #daily

今日のテーマは **「Docker コマンドを使った開発ワークフローの基礎→実運用」**。  
学習アークは **Beginner → Middle → Advanced** の順で進めます。

---

## 1) Topic + Level

### Beginner（初級）
**トピック:** コンテナ実行の基本（`docker run`, `docker ps`, `docker logs`, `docker exec`）

### Middle（中級）
**トピック:** イメージ作成とマルチステージビルド（`docker build`, `docker image ls`, `docker history`）

**前提知識（Prerequisites）:**
- Beginnerの内容を理解している
- Linux基本コマンド（`cd`, `ls`, `cat`）
- アプリの依存関係（例: Node.jsの`package.json`）の概念

### Advanced（上級）
**トピック:** Composeで開発環境を構成し、セキュアに運用（`docker compose up/down`, `docker compose logs`, `docker compose exec`）

**前提知識（Prerequisites）:**
- Middleまで完了
- ネットワーク/ボリュームの基本
- 環境変数と設定分離の考え方

---

## 2) Why it matters for real app development

- **ローカル環境差分を最小化**: 「自分のPCでは動く」を減らし、チームの再現性を上げる。  
- **オンボーディング高速化**: 新メンバーが`docker compose up`だけで開発開始しやすい。  
- **CI/CDとの接続が容易**: ローカルと同じDockerfileをCIでも使える。  
- **運用事故を減らす**: 不要な権限・肥大化イメージ・秘密情報混入を防ぐ設計ができる。

---

## 3) Core Docker command explanations

### Beginnerコマンド
- `docker run --name app -p 8080:80 nginx:alpine`  
  イメージからコンテナを起動。`-p`でホスト:コンテナのポート公開。
- `docker ps` / `docker ps -a`  
  実行中 / 全コンテナを確認。
- `docker logs -f app`  
  ログを追跡（`-f`はfollow）。
- `docker exec -it app sh`  
  稼働中コンテナへ対話シェル接続。

### Middleコマンド
- `docker build -t myapp:dev .`  
  Dockerfileからイメージ作成。
- `docker image ls`  
  ローカルのイメージ一覧。
- `docker history myapp:dev`  
  レイヤー履歴を確認し、サイズ肥大ポイントを把握。

### Advancedコマンド
- `docker compose up -d`  
  複数サービスをバックグラウンド起動。
- `docker compose logs -f web`  
  特定サービスのログを追跡。
- `docker compose exec web sh`  
  サービスコンテナ内で操作。
- `docker compose down`  
  停止・削除（必要なら`-v`でボリューム削除）。

---

## 4) How Docker is used while building apps（docs.docker.com準拠の実践）

- **小さいベースイメージを選ぶ**（例: `alpine`系、ただし互換性検証は必須）
- **マルチステージビルド**でビルド依存と実行環境を分離
- **`.dockerignore`整備**で不要ファイル（`node_modules`, `.git`等）を送らない
- **非rootユーザーで実行**（可能な限り）
- **イメージに秘密情報を埋め込まない**
  - NG: `ENV API_KEY=...`をDockerfileに書く
  - 推奨: 実行時注入（環境変数、シークレット管理）
- **Composeでdev/prod差分を管理**し、設定をコード化

---

## 5) 30-60 minute hands-on mini lab

### ゴール
Node.jsの簡易APIをDocker化し、Composeで起動、ログ確認、コンテナ内実行まで行う。

### 手順（目安45分）

1. **プロジェクト作成（10分）**
   - `app.js`（`/health`で`ok`を返す）
   - `package.json`

2. **Dockerfile作成（10分）**
   - マルチステージ構成
   - 最終ステージは軽量ランタイムのみ

3. **Compose作成（10分）**
   - `web`サービスを定義
   - ポート`3000:3000`公開

4. **起動と検証（10分）**
   - `docker compose up -d --build`
   - `curl http://localhost:3000/health`
   - `docker compose logs -f web`

5. **振り返り（5分）**
   - `docker image ls`でサイズ確認
   - `docker history`で不要レイヤー有無を確認

### 追加チャレンジ（+15分）
- `USER node`等で非root実行に変更
- `.dockerignore`最適化前後でビルド速度比較

---

## 6) Command cheatsheet

```bash
# 実行・確認
docker run --name app -p 8080:80 nginx:alpine
docker ps
docker logs -f app
docker exec -it app sh

# ビルド
docker build -t myapp:dev .
docker image ls
docker history myapp:dev

# Compose
docker compose up -d --build
docker compose logs -f web
docker compose exec web sh
docker compose down
```

---

## 7) Common mistakes and safe practices

### よくあるミス
1. **`latest`タグ固定**で再現性が崩れる
2. **秘密情報をDockerfile/compose直書き**する
3. **巨大ビルドコンテキスト**でビルド遅延
4. **root実行のまま本番投入**

### 安全運用のポイント
- タグは明示（例: `node:20-alpine`）
- シークレットは外部注入（Vault/CI Secrets/環境変数管理）
- `.dockerignore`で不要物除外
- 定期的に脆弱性スキャン（Docker Scout等）

### ⚠ 破壊的コマンドの注意喚起
以下は**データやキャッシュを消す可能性**があります。実行前に対象を必ず確認。
- `docker system prune`
- `docker image prune -a`
- `docker rmi ...`
- `docker rm -f ...`
- `docker compose down -v`

実行前チェック例:
```bash
docker ps -a
docker image ls
docker volume ls
docker system df
```

---

## 8) Interview-style question

**質問:**  
「開発用Dockerfileと本番用Dockerfile（またはステージ）を分けるべき理由を、セキュリティ・性能・運用性の観点で説明してください。」

**考えるポイント:**
- ビルドツール混入リスク
- イメージサイズとデプロイ速度
- デバッグ容易性と本番最小化のトレードオフ

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
  https://docs.docker.com/compose/compose-file/
- Docker Engine security  
  https://docs.docker.com/engine/security/
- Build secrets（機密情報の安全な扱い）  
  https://docs.docker.com/build/building/secrets/

---

次号予告（学習アーク継続）:  
**Beginner:** ボリューム基礎 → **Middle:** キャッシュ最適化 → **Advanced:** CIでのBuildKit高速化と署名検証
