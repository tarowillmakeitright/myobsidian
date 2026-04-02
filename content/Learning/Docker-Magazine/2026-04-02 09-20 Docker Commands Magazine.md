---
tags: [docker, containers, devops, learning, daily]
---

# Docker Commands Magazine — 2026-04-02 09:20
[[Home]]

#docker #containers #devops #learning #daily

## 今号のテーマ
**開発の基本フローを固める Docker コマンド実践**  
学習アーク: **Beginner → Middle → Advanced**

---

## 1) Topic + Level

### Beginner（初級）
**トピック:** `docker run` / `docker ps` / `docker logs` で「コンテナを起動・観察・停止」する

### Middle（中級）
**トピック:** `Dockerfile` + `docker build` + `docker compose up` でローカル開発環境を再現する  
**前提知識:** 初級内容（コンテナの起動/停止/ログ確認）ができること

### Advanced（上級）
**トピック:** マルチステージビルドと実行時最小化、ヘルスチェック、クリーンアップ運用  
**前提知識:** 中級内容（Dockerfile と Compose の基本運用）ができること

---

## 2) なぜ実アプリ開発で重要か
- **環境差分を減らせる:** 「自分のPCでは動く」問題を減らし、チーム開発の再現性を上げる
- **オンボーディングを短縮:** 新メンバーは `docker compose up` で同じ構成をすぐ起動可能
- **CI/CDに接続しやすい:** ローカルと同じ Docker イメージをビルド・検証・デプロイに流せる
- **安全性と保守性:** 最小イメージ・非root実行・Secrets分離で運用リスクを下げる

---

## 3) コア Docker コマンド解説

### 初級コマンド
- `docker run --name web -d -p 8080:80 nginx:alpine`
  - イメージからコンテナ起動（`-d` バックグラウンド、`-p` ポート公開）
- `docker ps` / `docker ps -a`
  - 稼働中 / 全コンテナ確認
- `docker logs -f web`
  - ログ追跡（トラブルの最初の入口）
- `docker stop web && docker rm web`
  - 停止と削除（明示的にライフサイクル管理）

### 中級コマンド
- `docker build -t myapp:dev .`
  - Dockerfileからイメージ作成
- `docker compose up --build`
  - 複数サービスをまとめて起動（必要時に再ビルド）
- `docker compose ps` / `docker compose logs -f app`
  - サービス状態とログ監視
- `docker compose down`
  - ネットワーク含め後片付け（volume削除は必要時のみ）

### 上級コマンド
- `docker image ls` / `docker history myapp:dev`
  - イメージサイズとレイヤー確認
- `docker inspect <container_or_image>`
  - 設定・マウント・ネットワーク詳細確認
- `docker exec -it app sh`
  - 実行中コンテナの調査（最小限で実施）
- `docker builder prune`
  - ビルドキャッシュ整理（⚠ 後述の注意を必ず確認）

---

## 4) アプリ開発での使い方（docs.docker.com ベストプラクティス準拠）
- **1プロセス/1責務を基本に分割**（例: app, db, redis）
- **軽量ベースイメージを選択**（例: `alpine` 系。ただし互換性検証必須）
- **マルチステージビルド**でビルド依存を最終イメージへ持ち込まない
- **`.dockerignore` を整備**して不要ファイル流入を防ぐ
- **Secretsをイメージへ焼き込まない**
  - NG: `ENV API_KEY=...` を Dockerfile に直書き
  - OK: 実行時環境変数/Secrets機構（Composeの`secrets`等）
- **コンテナはなるべく非rootで実行**
- **Composeで設定をコード化**し、READMEに起動手順を固定

---

## 5) 30–60分ハンズオンミニラボ
**ゴール:** Node.js API + Redis を Compose で起動し、ログ確認・再ビルド・安全停止まで実施

### 手順（45分目安）
1. プロジェクト作成（5分）
   - `app/` に簡単な API（`GET /health`）を用意
2. Dockerfile作成（10分）
   - 依存インストール → アプリコピー → 非rootユーザーで起動
3. compose.yaml作成（10分）
   - `app` と `redis` サービス定義、`depends_on`、ポート公開
4. 起動と検証（10分）
   - `docker compose up --build -d`
   - `curl http://localhost:3000/health`
   - `docker compose logs -f app`
5. 変更反映と後片付け（10分）
   - コード1行修正 → `docker compose up --build -d`
   - `docker compose down`

**追加チャレンジ（任意）**
- マルチステージ化してイメージサイズ比較（`docker image ls`）
- `HEALTHCHECK` を追加して `docker ps` で状態確認

---

## 6) コマンドチートシート
```bash
# 起動・確認
docker run --name web -d -p 8080:80 nginx:alpine
docker ps
docker logs -f web

# ビルド・Compose
docker build -t myapp:dev .
docker compose up --build -d
docker compose ps
docker compose logs -f app

# 停止・削除
docker stop web && docker rm web
docker compose down

# 調査
docker exec -it app sh
docker inspect app

# クリーンアップ（注意して実行）
docker image prune
# docker system prune -a  # ⚠未使用イメージ/ネットワーク等を広く削除
```

---

## 7) よくあるミス & 安全運用
- **ミス:** Dockerfile/composeにシークレット直書き  
  **対策:** `.env` + Secrets機構を使い、Git管理から除外

- **ミス:** 開発中に `latest` タグ依存  
  **対策:** バージョン固定タグを使い再現性を確保

- **ミス:** 不要に `--privileged` や root 実行  
  **対策:** 最小権限、必要機能だけ付与

- **ミス:** 破壊的クリーンアップを無確認で実行  
  **対策:** 実行前に対象確認
  - `docker system df` で使用状況を見る
  - `docker image ls` / `docker volume ls` で対象を確認
  - **警告:** `docker system prune`, `docker image rm`, `docker rm -f` は復元困難な削除を招く可能性あり

---

## 8) 面接っぽい質問（1問）
**質問:** 開発環境で `docker compose up --build` を毎回実行すると遅いです。再現性を保ちつつ高速化するには、Dockerfile/Composeをどう改善しますか？  
**見るポイント:** レイヤーキャッシュ、依存ファイル先コピー、`.dockerignore`、マルチステージ、不要再ビルド回避

---

## 9) 次の一歩（公式中心）
- Docker Docs Home: https://docs.docker.com/
- Get Started: https://docs.docker.com/get-started/
- Dockerfile best practices: https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Multi-stage builds: https://docs.docker.com/build/building/multi-stage/
- Compose overview: https://docs.docker.com/compose/
- Compose file reference: https://docs.docker.com/compose/compose-file/
- Engine security: https://docs.docker.com/engine/security/
- Manage sensitive data with Docker secrets: https://docs.docker.com/engine/swarm/secrets/

---

### 明日の予告
次号は **「Docker ボリュームとデータ永続化（バックアップ/復元含む）」** を Beginner→Advanced で扱います。