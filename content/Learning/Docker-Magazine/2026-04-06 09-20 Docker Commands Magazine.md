---
tags: [docker, containers, devops, learning, daily]
---

# Docker Commands Magazine — 2026-04-06 09:20
#docker #containers #devops #learning #daily
[[Home]]

今日は**実務で使うDockerコマンド**を、
**Beginner → Middle → Advanced**の順で段階的に学びます。

---

## Learning Arc 1

## 1) トピック + レベル

### Beginner（初級）
**トピック:** コンテナの起動・確認・停止の基本

### Middle（中級）
**トピック:** Dockerfileで再現可能な開発環境を作る

**前提知識（Prerequisites）:**
- `docker run / ps / stop / logs` が使える
- Linux基本コマンド（`cd`, `ls`, `cat`）
- アプリの依存関係（例: Node.jsの`package.json`）の概念

### Advanced（上級）
**トピック:** Composeで複数サービスを安全に運用（Web + DB）

**前提知識（Prerequisites）:**
- Dockerfileのレイヤー/キャッシュを理解している
- ボリュームとネットワークの基本を説明できる
- `.env` と secrets の違いを理解している

---

## 2) なぜ実アプリ開発で重要か

- **環境差分バグを減らせる**（「私のPCでは動く」を減らす）
- **オンボーディングが速い**（`docker compose up`で開始しやすい）
- **CI/CDに直結**（ローカルと本番の実行条件を揃えやすい）
- **依存関係を隔離**し、ホスト汚染を防げる

---

## 3) コアDockerコマンド解説

### 初級コマンド
- `docker pull nginx:stable`  
  イメージを取得
- `docker run -d --name web -p 8080:80 nginx:stable`  
  バックグラウンド起動。`ホスト8080 -> コンテナ80`
- `docker ps` / `docker ps -a`  
  稼働中/全コンテナ確認
- `docker logs -f web`  
  ログ追跡
- `docker stop web && docker rm web`  
  停止して削除

### 中級コマンド
- `docker build -t myapp:dev .`  
  Dockerfileからイメージ作成
- `docker image ls`  
  イメージ一覧
- `docker exec -it <container> sh`  
  稼働中コンテナに入る（デバッグ）
- `docker inspect <container>`  
  設定詳細（ポート、マウント、ネットワーク）確認

### 上級コマンド（Compose中心）
- `docker compose up -d --build`  
  複数サービス起動 + 再ビルド
- `docker compose ps` / `docker compose logs -f`  
  サービス状態・ログ確認
- `docker compose exec app sh`  
  appサービスでコマンド実行
- `docker compose down`  
  停止・ネットワーク削除（ボリュームは残る）
- `docker compose down -v`  
  **警告: データボリューム削除**（DBデータ喪失の可能性）

---

## 4) 実アプリ開発での使い方（docs.docker.com準拠の実践）

- **小さいベースイメージを選ぶ**（例: `node:20-alpine`）
- **マルチステージビルド**で実行イメージを軽量化
- **`.dockerignore`**で不要ファイルを送らない（速度・秘匿性向上）
- **レイヤーキャッシュ最適化**（依存インストールを先に）
- **1コンテナ1責務**を意識（Web/DB/Workerを分離）
- **機密情報をイメージに焼き込まない**
  - NG: `ENV API_KEY=...` をDockerfileに直書き
  - 推奨: 実行時注入、Compose secrets、環境変数管理
- **非rootユーザー実行**を検討（権限最小化）

---

## 5) 30〜60分ハンズオン・ミニラボ

### Lab（約45分）: Node.js API + PostgreSQL をComposeで起動

#### 目標
ローカル開発環境を「1コマンドで再現可能」にする。

#### 手順
1. プロジェクト雛形作成（10分）
   - `app/` に簡易Node API（`/health`）
   - `Dockerfile` 作成
2. Compose定義（15分）
   - `app` と `db` の2サービス
   - `db` は named volume を使用
3. 起動と検証（10分）
   - `docker compose up -d --build`
   - `docker compose ps`
   - `curl http://localhost:3000/health`
4. ログとデバッグ（5分）
   - `docker compose logs -f app`
   - `docker compose exec app sh`
5. 後片付け（5分）
   - `docker compose down`

#### できたら追加
- `healthcheck` をComposeに追加
- `.env` と `.env.example` を分離

---

## 6) コマンド・チートシート

```bash
# 基本
docker ps
docker logs -f <container>
docker exec -it <container> sh

# ビルド/実行
docker build -t <name>:<tag> .
docker run -d --name <name> -p 8080:80 <image>:<tag>

# Compose
docker compose up -d --build
docker compose ps
docker compose logs -f
docker compose exec <service> sh
docker compose down

# クリーンアップ（要注意）
# WARNING: 未使用リソースを削除。必要データまで消える可能性あり。
docker system prune
# WARNING: イメージを強制削除。依存コンテナに影響する可能性あり。
docker rmi -f <image>
# WARNING: 稼働中でも強制削除。調査中コンテナを消す危険あり。
docker rm -f <container>
```

---

## 7) よくあるミス & 安全プラクティス

### よくあるミス
- `latest` タグ固定で再現性が崩れる
- SecretsをDockerfile/compose.ymlに直書き
- `docker system prune -a` を意味理解せず実行
- DBを匿名ボリュームに置いてデータ管理不能

### 安全プラクティス
- イメージタグは明示（例: `postgres:16.3-alpine`）
- 機密情報は secrets / 実行時注入で管理
- 削除系コマンド前に対象確認
  - `docker ps -a`
  - `docker image ls`
  - `docker volume ls`
- 本番想定なら read-only root filesystem や non-root 実行を検討

---

## 8) 面接っぽい質問（1問）

**質問:**  
「`docker run` と `docker compose up` の使い分けを、実務の開発チーム観点で説明してください。再現性・可読性・運用コストに触れて答えてください。」

---

## 9) 次の一歩（公式ドキュメント中心）

- Docker Docs Home  
  https://docs.docker.com/
- Get Started  
  https://docs.docker.com/get-started/
- Dockerfile Best Practices  
  https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Multi-stage Builds  
  https://docs.docker.com/build/building/multi-stage/
- Compose Overview  
  https://docs.docker.com/compose/
- Compose file reference  
  https://docs.docker.com/reference/compose-file/
- Docker Engine security  
  https://docs.docker.com/engine/security/
- Build secrets  
  https://docs.docker.com/build/building/secrets/

---

次号予告（Arc 2）:  
**Beginner:** ボリューム基礎 → **Middle:** 開発速度を上げるキャッシュ戦略 → **Advanced:** BuildKit + CI連携の最適化
