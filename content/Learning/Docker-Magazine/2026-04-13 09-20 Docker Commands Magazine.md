# 2026-04-13 Docker Commands Magazine

#docker #containers #devops #learning #daily
[[Home]]

---

## 今日の学習アーク（Beginner → Middle → Advanced）

> テーマ: **開発効率と安全性を両立する Docker コマンド運用**

---

## 1) Topic + Level

### 🟢 Beginner
**トピック:** `docker run` / `docker ps` / `docker logs` で「まず動かして観察する」

### 🟡 Middle（前提あり）
**トピック:** `Dockerfile` + `docker build` + `docker compose up` でローカル開発環境を再現する

**前提（Prerequisites）:**
- Beginner内容を理解している
- Linuxコマンドの基本（`cd`, `ls`, `cat`）
- アプリの環境変数の概念を知っている

### 🔴 Advanced（前提あり）
**トピック:** BuildKit・マルチステージビルド・最小権限コンテナで本番に近い運用へ

**前提（Prerequisites）:**
- Middle内容を実際に1回は実施済み
- Dockerイメージ層（layer）とキャッシュの基本理解
- CI/CDの基本概念

---

## 2) なぜ実アプリ開発で重要か

- **再現性:** 「自分のPCでは動く」を減らし、チーム全員が同じ環境で動かせる
- **オンボーディング高速化:** 新メンバーが `docker compose up` で短時間セットアップ可能
- **障害切り分け:** コンテナ単位でログ確認・再起動でき、原因特定が速い
- **セキュリティ:** 実行ユーザーやイメージ内容を制御し、攻撃面を減らせる

---

## 3) コア Docker コマンド解説

### Beginnerコマンド
- `docker run --name web -d -p 8080:80 nginx:alpine`
  - コンテナ起動（バックグラウンド）
  - `-p 8080:80` は **ホスト8080 → コンテナ80**
- `docker ps`
  - 稼働中コンテナ一覧
- `docker logs -f web`
  - コンテナログ追跡（`Ctrl+C`で抜ける）
- `docker stop web && docker rm web`
  - 停止して削除（クリーンに片付け）

### Middleコマンド
- `docker build -t myapp:dev .`
  - Dockerfileからイメージ作成
- `docker compose up --build`
  - 複数サービス（例: app + db）をビルドして起動
- `docker compose logs -f app`
  - appサービスのログ監視
- `docker compose down`
  - 停止・ネットワーク解放

### Advancedコマンド
- `docker buildx build --platform linux/arm64,linux/amd64 -t myorg/myapp:1.0 --push .`
  - マルチアーキ向けビルド（CIで有用）
- `docker image inspect myapp:dev`
  - イメージメタデータ確認
- `docker scout quickview myapp:dev`（利用環境で有効な場合）
  - 依存パッケージの脆弱性把握を支援

---

## 4) 実アプリ構築での使い方（docs.docker.com ベストプラクティス準拠）

- **小さいベースイメージを選ぶ**（例: `alpine` か用途に合う公式最小イメージ）
- **マルチステージビルド**でビルドツールを最終イメージに残さない
- **`.dockerignore` を整備**して不要ファイル混入を防ぐ
- **1コンテナ1責務**を基本に、連携は Compose で管理
- **機密情報をイメージに埋め込まない**
  - NG: Dockerfileにトークン直書き
  - 推奨: 実行時環境変数・シークレット管理を利用
- **root以外で実行**して被害範囲を縮小

---

## 5) 30〜60分ミニラボ

### ラボ: Node.js API + Redis を Compose で起動して観察

**目標時間:** 約45分

1. プロジェクト作成（10分）
   - `Dockerfile`, `docker-compose.yml`, `.dockerignore` を用意
2. 起動（10分）
   - `docker compose up --build -d`
3. 動作確認（10分）
   - `docker ps`
   - `docker compose logs -f app`
   - APIにアクセスしてレスポンス確認
4. 変更反映と再ビルド（10分）
   - アプリコードを1行変更
   - `docker compose up --build -d`
5. 後片付け（5分）
   - `docker compose down`

**発展課題（任意）**
- Dockerfileをマルチステージ化
- `USER node` 等で非root実行化

---

## 6) コマンドチートシート

```bash
# 稼働中コンテナ
docker ps

# 全コンテナ（停止中含む）
docker ps -a

# イメージ一覧
docker images

# コンテナ起動
docker run -d --name sample -p 8080:80 nginx:alpine

# ログ追跡
docker logs -f sample

# コンテナ内シェル
docker exec -it sample sh

# Compose起動（再ビルド込み）
docker compose up --build -d

# Compose停止
docker compose down
```

---

## 7) よくあるミス & 安全運用

### よくあるミス
- `latest` タグ固定で意図せず挙動変化
- `.env` や秘密鍵をイメージにCOPYしてしまう
- `docker compose down -v` でDBボリュームを誤削除
- ログ未確認で「動かない」と判断する

### 安全運用の注意
- **破壊的コマンドは実行前に必ず確認**
  - `docker system prune`
  - `docker image prune -a`
  - `docker rm -f ...`
  - `docker rmi ...`
- 本番/開発で Docker context を分離し、誤操作を防ぐ
- Secretはイメージ・Composeファイルへ直書きしない
- 削除系は `--dry-run` 相当がないため、対象を先に `docker ps -a` / `docker images` で確認

---

## 8) 面接っぽい一問

**質問:**
「`docker run` と `docker compose up` の使い分けを、チーム開発の観点で説明してください。」

**回答のポイント（自己採点用）:**
- 単体検証は `docker run` が素早い
- 複数サービス連携（DB/Cache/App）は Compose が管理しやすい
- 再現性・共有性・運用性で Compose が優位

---

## 9) 次の一歩（公式ドキュメント優先）

- Docker Get Started:
  https://docs.docker.com/get-started/
- Dockerfile best practices:
  https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Multi-stage builds:
  https://docs.docker.com/build/building/multi-stage/
- Docker Compose overview:
  https://docs.docker.com/compose/
- Build cache:
  https://docs.docker.com/build/cache/
- Image security best practices:
  https://docs.docker.com/develop/security-best-practices/

---

次号予告（学習アーク継続）:
**Beginner:** ボリューム基礎 → **Middle:** 開発用ホットリロード構成 → **Advanced:** CIでのキャッシュ最適化と脆弱性スキャン自動化
