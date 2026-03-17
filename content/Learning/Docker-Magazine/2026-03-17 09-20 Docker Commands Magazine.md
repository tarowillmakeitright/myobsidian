---
tags: [docker, containers, devops, learning, daily]
---

# Daily Docker Commands Magazine - 2026-03-17
[[Home]]

#docker #containers #devops #learning #daily

## 今日の学習アーク（Beginner → Middle → Advanced）
テーマは**「Docker イメージ作成と実行を、開発現場の安全運用までつなげる」**です。  
同じ流れ（基礎→中級→上級）を毎日繰り返して、段階的に実務力を積み上げます。

---

## 1) Topic + Level

### Beginner（基礎）
**Topic:** `docker build` / `docker run` / `docker logs` でローカル開発アプリを動かす

### Middle（中級）
**Topic:** `docker compose up` / `docker compose logs` / `docker compose exec` で複数サービスを連携する  
**前提条件:**
- Beginner のコマンドを迷わず使える
- Dockerfile の基本命令（`FROM`, `WORKDIR`, `COPY`, `RUN`, `CMD`）を理解している

### Advanced（上級）
**Topic:** BuildKit + マルチステージ + 非root実行で、軽量・安全な本番向けイメージを設計する  
**前提条件:**
- Compose で API + DB などを起動した経験がある
- `.dockerignore` とイメージレイヤの考え方を説明できる

---

## 2) なぜ実アプリ開発で重要か

- **再現性:** 「自分のPCでは動く」を減らし、同じ実行環境をチームで共有できる
- **速度:** 依存関係セットアップの時間を短縮し、オンボーディングを速くする
- **品質:** CI でも同じコンテナを使えるため、ローカルとの差異が減る
- **運用安全性:** 最小権限・不要ファイル排除で、脆弱性面積を小さくできる

---

## 3) Core Docker command 解説

- `docker build -t myapp:dev .`
  - Dockerfile からイメージを作る
  - `-t` はタグ（名前:バージョン）

- `docker run --rm -p 3000:3000 myapp:dev`
  - コンテナ起動、`-p` でポート公開
  - `--rm` は停止後コンテナ自動削除（開発時に便利）

- `docker logs -f <container>`
  - 実行ログを追跡（障害調査の基本）

- `docker compose up -d`
  - compose.yaml の複数サービスをバックグラウンド起動

- `docker compose exec app sh`
  - 稼働中コンテナ内でコマンド実行（デバッグ・マイグレーション）

- `docker image ls` / `docker ps` / `docker inspect <id>`
  - 状態把握・設定確認に必須

---

## 4) アプリ構築時の Docker 活用（docs.docker.com ベストプラクティス準拠）

- **小さいベースイメージ**を選ぶ（必要最小限）
- **マルチステージビルド**でビルド依存物を最終イメージへ持ち込まない
- **`.dockerignore` を必ず整備**（`node_modules`, `.git`, secrets を除外）
- **機密情報をイメージへ焼き込まない**
  - NG: `ENV API_KEY=...` を Dockerfile に直書き
  - 推奨: 実行時環境変数、Docker secrets、CI secret 管理
- **1コンテナ1責務**を意識（アプリとDBを分離）
- **非rootユーザーで実行**し、権限を最小化

参考（公式）:
- https://docs.docker.com/build/building/best-practices/
- https://docs.docker.com/compose/
- https://docs.docker.com/engine/security/

---

## 5) 30-60分ハンズオン・ミニラボ

### ゴール
Node/Express の簡易APIを Docker 化し、Compose で app + redis を起動。  
最後にログ確認とヘルスチェックまで実施。

### 手順（約45分）
1. プロジェクト雛形作成（10分）
   - `Dockerfile`, `compose.yaml`, `.dockerignore` を用意
2. イメージビルド（10分）
   - `docker build -t demo-api:dev .`
3. 単体起動テスト（5分）
   - `docker run --rm -p 3000:3000 demo-api:dev`
4. Compose で複数サービス起動（10分）
   - `docker compose up -d --build`
5. 観測とデバッグ（10分）
   - `docker compose ps`
   - `docker compose logs -f app`
   - `curl http://localhost:3000/health`

### 完了条件
- `curl` が `{"status":"ok"}` を返す
- app コンテナが redis へ接続できる
- 再起動しても同じ手順で再現できる

---

## 6) Command Cheatsheet

```bash
# build & run
docker build -t myapp:dev .
docker run --rm -p 3000:3000 myapp:dev

# observe
docker ps
docker logs -f <container>
docker inspect <container>

# compose
docker compose up -d --build
docker compose ps
docker compose logs -f
docker compose exec app sh
docker compose down

# cleanup（注意して実行）
docker rm <container>
docker rmi <image>
# 破壊的: 未使用リソースを広く削除
# 実行前に対象確認必須
docker system prune
```

---

## 7) よくあるミス & 安全運用

- ミス: `COPY . .` で秘密情報まで同梱
  - 対策: `.dockerignore` に `.env`, `*.pem`, `.git` を追加

- ミス: 本番イメージを root で実行
  - 対策: `USER appuser` を設定

- ミス: `latest` タグ固定で追跡不能
  - 対策: `app:1.4.2` のようにバージョン固定

- ミス: いきなりクリーンアップで環境破壊
  - 対策: `prune`, `rmi`, `rm -f` の前に必ず対象確認
  - 例: `docker ps -a`, `docker image ls`, `docker volume ls`

- ミス: Compose ファイルに平文シークレットを直書き
  - 対策: `.env` の管理を厳格化し、可能なら secrets 機構を使う

---

## 8) 面接っぽい質問（1問）

**質問:** 「開発用 Dockerfile と本番用 Dockerfile を分けるべきケースを説明してください。マルチステージビルドでどう整理しますか？」

---

## 9) Next-step resources（公式中心）

- Docker Get Started: https://docs.docker.com/get-started/
- Dockerfile reference: https://docs.docker.com/reference/dockerfile/
- Build best practices: https://docs.docker.com/build/building/best-practices/
- Multi-stage builds: https://docs.docker.com/build/building/multi-stage/
- Compose file reference: https://docs.docker.com/reference/compose-file/
- Docker Engine security: https://docs.docker.com/engine/security/

---

次号予告（同アーク反復）:  
Beginner「ボリューム基礎」→ Middle「開発効率化（bind mount / watch）」→ Advanced「CI キャッシュ最適化と SBOM/脆弱性スキャン」
