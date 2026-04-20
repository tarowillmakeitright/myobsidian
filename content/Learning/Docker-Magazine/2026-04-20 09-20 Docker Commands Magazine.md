# Docker Commands Magazine — 2026-04-20 (09:20)

Tags: #docker #containers #devops #learning #daily  
Links: [[Home]]

---

## 今号のテーマ
**「コンテナのライフサイクルを理解して、開発〜デバッグ〜運用確認までを一気通貫で回す」**

学習アーク（段階的難易度）:
1. **Beginner**: まずは `run / ps / logs / exec / stop / rm` を安全に扱う
2. **Middle**: `build / image / volume / network` を使って開発に近い構成へ
3. **Advanced**: マルチステージビルド、最小権限、ヘルスチェック、クリーンアップ戦略

---

## 1) Topic + Level

### 🟢 Beginner
**Topic:** コンテナ操作の基本コマンドで「動かす・見る・入る・止める」

### 🟡 Middle（前提条件あり）
**Topic:** イメージ作成と開発用データ永続化（Volume）
**前提条件:**
- Beginnerレベルの `docker run`, `docker ps`, `docker logs`, `docker exec` が使える
- Dockerfile の基本構文（`FROM`, `WORKDIR`, `COPY`, `RUN`, `CMD`）を知っている

### 🔴 Advanced（前提条件あり）
**Topic:** 本番を意識したビルド最適化とセキュア運用
**前提条件:**
- Middleレベルの `docker build`, `docker image`, `docker volume` が使える
- レイヤーキャッシュ、`.dockerignore` の意義を理解している
- アプリ設定値と秘密情報の違い（環境変数に秘密情報を直書きしない）を理解している

---

## 2) なぜ実アプリ開発で重要か

- **再現性**: 開発者ごとの差異（OS/ライブラリ差）を減らせる
- **オンボーディング高速化**: 新メンバーでも同じ環境を短時間で立ち上げられる
- **デバッグ容易化**: `logs`/`exec` で実行中コンテナを直接観察できる
- **CI/CD連携**: build/test/release の流れを同じコンテナ前提で統一しやすい
- **安全性向上**: 最小イメージ・不要権限削減・秘密情報分離で事故を減らせる

---

## 3) コアDockerコマンド解説

### Beginnerコマンド
- `docker run -d --name web -p 8080:80 nginx:alpine`
  - イメージからコンテナを作成して起動（`-d` はバックグラウンド）
- `docker ps` / `docker ps -a`
  - 稼働中 / 全コンテナの確認
- `docker logs -f web`
  - ログを追跡（`-f` でフォロー）
- `docker exec -it web sh`
  - 実行中コンテナに入って確認
- `docker stop web` → `docker rm web`
  - 停止して削除（安全な順番）

### Middleコマンド
- `docker build -t myapp:dev .`
  - Dockerfileからイメージ作成
- `docker images`
  - ローカルイメージ一覧
- `docker run -d --name myapp -p 3000:3000 myapp:dev`
  - 作成したイメージでアプリ起動
- `docker volume create myapp-data`
  - 永続ボリューム作成
- `docker run -d --name db -e POSTGRES_PASSWORD=example -v myapp-data:/var/lib/postgresql/data postgres:16-alpine`
  - DBデータをボリュームで永続化

### Advancedコマンド
- `docker build --target runtime -t myapp:prod .`
  - マルチステージの最終ターゲットのみビルド
- `docker inspect myapp`
  - 設定/ネットワーク/マウント/ヘルス状態の詳細確認
- `docker stats`
  - CPU/メモリ監視
- `docker network ls` / `docker network inspect <network>`
  - 通信範囲を可視化し、不要公開を避ける

---

## 4) 実アプリ構築での使い方（docs.docker.comベストプラクティス準拠）

- **小さいベースイメージを使う**（例: `alpine`, `slim`）
- **マルチステージビルド**でビルドツールを最終イメージから除外
- **`.dockerignore` を必ず整備**（`node_modules`, `.git`, 一時ファイルなど）
- **1コンテナ1責務**を意識（Web, DB, Queueを分離）
- **機密情報をイメージに埋め込まない**
  - ❌ `ENV API_KEY=...` をDockerfileに直書き
  - ✅ 実行時注入（secret管理、環境側注入、必要最小限）
- **不要なポート公開をしない**（ローカル検証でも最小化）
- **root以外ユーザー実行**を検討（可能なら `USER` 指定）

---

## 5) 30〜60分ミニラボ

**目標:** Web + DB の2コンテナ構成を立ち上げ、ログ確認・再起動・データ永続化を体験

### 手順（45分目安）
1. **準備 (5分)**
   - 作業ディレクトリ作成
   - 簡易アプリ（例: Node/Python）とDockerfile準備
2. **ビルド＆起動 (10分)**
   - `docker build -t demo-web:dev .`
   - `docker run -d --name demo-web -p 3000:3000 demo-web:dev`
3. **ログ/内部確認 (10分)**
   - `docker logs -f demo-web`
   - `docker exec -it demo-web sh`
4. **DB永続化 (10分)**
   - `docker volume create demo-db-data`
   - PostgreSQLをボリューム付きで起動
5. **障害想定テスト (10分)**
   - DBコンテナを停止→再起動
   - データが残ることを確認

**完了条件**
- Webがブラウザで応答
- ログ追跡できる
- DB再起動後もデータが保持される

---

## 6) コマンドチートシート

```bash
# 起動・確認
docker run -d --name <name> -p <host>:<container> <image>
docker ps
docker logs -f <name>
docker exec -it <name> sh

# 停止・削除
docker stop <name>
docker rm <name>

# ビルド・イメージ
docker build -t <repo>:<tag> .
docker images

# ボリューム・ネットワーク
docker volume ls
docker volume inspect <volume>
docker network ls

# 使用状況
docker stats
```

---

## 7) よくあるミス & 安全な運用

### よくあるミス
- `latest` タグ固定で再現性が崩れる
- `.dockerignore` 未設定で巨大ビルドコンテキストになる
- コンテナに秘密情報を焼き込む
- なんでも `-p 0.0.0.0:...` で公開してしまう
- `docker rm -f` を常用して状態確認せず消す

### 安全プラクティス
- イメージは **明示タグ**（例: `myapp:1.4.2`）
- 破壊的コマンド前に `ps`, `images`, `volume ls` で対象確認
- 最小権限・最小公開・最小イメージを徹底
- cleanupは段階的に実施

⚠️ **破壊的コマンド注意**
- `docker system prune`, `docker image prune -a`, `docker rmi`, `docker rm -f` は削除影響が大きいです。  
  実行前に必ず対象を確認し、業務中は安易に使わないこと。

---

## 8) 面接っぽい質問（1問）

**Q.** `docker run` と `docker exec` の違いを説明し、実務での使い分け例を挙げてください。  
**期待ポイント:** 新規コンテナ作成/起動か、既存実行中コンテナへのコマンド投入かを明確に説明できること。

---

## 9) 次の一歩（公式ドキュメント中心）

- Docker Docs Home: https://docs.docker.com/
- Get Started: https://docs.docker.com/get-started/
- Dockerfile best practices: https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Multi-stage builds: https://docs.docker.com/build/building/multi-stage/
- Volumes: https://docs.docker.com/storage/volumes/
- Networking overview: https://docs.docker.com/network/
- Compose overview: https://docs.docker.com/compose/
- Engine security: https://docs.docker.com/engine/security/

---

## 明日の予告（学習アーク継続）
次号は **Middle寄り** にして、Composeで「アプリ + DB + Adminツール」をまとめて管理する実践に進みます。