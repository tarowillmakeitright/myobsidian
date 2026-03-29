---
tags: [docker, containers, devops, learning, daily]
---

# Docker Commands Magazine — 2026-03-29
#docker #containers #devops #learning #daily
[[Home]]

今日のテーマは、**Beginner → Middle → Advanced** の学習アークで「Dockerコマンドを実アプリ開発でどう使うか」を段階的に身につける構成です。

---

## 1) Topic + Level

### Beginner
**Topic:** `docker run` / `docker ps` / `docker logs` で「コンテナを動かして観察する」

### Middle（前提あり）
**Topic:** `docker build` / `docker compose up` で「開発環境を再現する」
**前提:** `docker run` の基本、イメージとコンテナの違い、ポート公開（`-p`）

### Advanced（前提あり）
**Topic:** BuildKit・マルチステージ・キャッシュ最適化で「安全かつ高速なビルド運用」
**前提:** Dockerfile基礎、Compose基礎、レイヤーキャッシュの概念

---

## 2) Why it matters for real app development

- **環境差分の削減:** 「自分のPCでは動く」を減らせる
- **オンボーディング高速化:** 新メンバーが `docker compose up` ですぐ開始
- **CI/CDとの整合:** ローカルとCIで同じイメージ作成フローを共有
- **セキュリティ強化:** 最小イメージ・非root実行・秘密情報の分離
- **再現性:** 同じDockerfileから同じ成果物を得やすい

---

## 3) Core Docker command explanations

### Beginnerコマンド
- `docker run -d -p 8080:80 --name web nginx:alpine`
  - `-d`: バックグラウンド実行
  - `-p 8080:80`: ホスト8080 → コンテナ80
  - `--name`: 管理しやすい名前を付与
- `docker ps` / `docker ps -a`
  - 稼働中 / 全コンテナ一覧
- `docker logs -f web`
  - ログ追跡（トラブルシュートの基本）
- `docker exec -it web sh`
  - コンテナ内部確認（本番では最小限に）

### Middleコマンド
- `docker build -t myapp:dev .`
  - Dockerfileからイメージ作成
- `docker compose up -d`
  - 複数サービス（app/db等）を一括起動
- `docker compose logs -f app`
  - サービス単位のログ確認
- `docker compose down`
  - 構成停止（必要時のみ `-v` を使う）

### Advancedコマンド
- `DOCKER_BUILDKIT=1 docker build --progress=plain -t myapp:buildkit .`
  - BuildKit有効化でビルド効率・機能向上
- `docker buildx build --platform linux/amd64,linux/arm64 -t myorg/myapp:latest .`
  - マルチアーキ向けビルド
- `docker image inspect myapp:dev`
  - イメージ設定・レイヤー確認

---

## 4) How Docker is used while building apps (docs.docker.com best practices aligned)

実務フロー例:
1. **開発中:** Composeで app + db + cache を起動
2. **Dockerfile最適化:** 依存関係の先コピー、レイヤーキャッシュ活用
3. **マルチステージ:** build用とruntime用を分離し、最終イメージを小さく
4. **非rootユーザー:** `USER` 指定で権限最小化
5. **秘密情報を埋め込まない:**
   - ❌ `ENV API_KEY=...` をDockerfileに直書き
   - ✅ `.env` / CI secrets / runtime注入を利用
6. **不要なファイル除外:** `.dockerignore` で `node_modules`, `.git`, 秘密ファイル等を除外
7. **脆弱性対応:** ベースイメージ更新、定期再ビルド、最小構成維持

---

## 5) 30-60 minute hands-on mini lab

### ゴール
Node.js APIをDocker化し、Composeで起動、ログ確認まで行う。

### 手順（約45分）
1. **プロジェクト準備（10分）**
   - 最小API（`/health`）を作成
2. **Dockerfile作成（10分）**
   - `node:20-alpine` ベース
   - `npm ci` → `COPY . .` → `npm start`
3. **Compose作成（10分）**
   - `app` サービスで `ports: ["3000:3000"]`
4. **起動・確認（10分）**
   - `docker compose up -d --build`
   - `curl http://localhost:3000/health`
   - `docker compose logs -f app`
5. **改善（5分）**
   - `.dockerignore` を追加
   - `USER node` の利用検討

### 追加課題（時間があれば）
- マルチステージ化してイメージサイズ比較
- `docker history` でレイヤー確認

---

## 6) Command cheatsheet

```bash
# 実行・確認
docker run -d -p 8080:80 --name web nginx:alpine
docker ps
docker logs -f web
docker exec -it web sh

# ビルド
docker build -t myapp:dev .
docker image ls
docker image inspect myapp:dev

# Compose
docker compose up -d --build
docker compose ps
docker compose logs -f app
docker compose down

# クリーンアップ（注意して使用）
docker rm <container>
docker rmi <image>
```

---

## 7) Common mistakes and safe practices

### よくあるミス
- Dockerfileに秘密情報（APIキー等）を埋め込む
- `latest` タグ前提で再現不能になる
- 不要に巨大なベースイメージを使う
- `docker compose down -v` を意味を理解せず実行してデータ消失
- ローカル開発で `--privileged` を安易に使う

### 安全運用の実践
- **秘密情報はイメージに入れない**（runtime注入）
- タグ固定（例: `node:20-alpine`）で再現性確保
- 非root実行・最小権限
- 不要ポートを公開しない
- 本番前にログ・ヘルスチェック・リソース制限を確認

### 破壊的コマンドの警告
以下は削除系です。実行前に対象確認を必ず行ってください。
- `docker system prune`
- `docker image prune -a`
- `docker rmi ...`
- `docker rm -f ...`

推奨: まず `docker ps -a` / `docker image ls` で対象確認 → 必要最小限で削除。

---

## 8) Interview-style question

**質問:**
「`docker run` と `docker compose up` はどう使い分けますか？実務のチーム開発を想定して説明してください。」

**回答の観点（自己チェック）:**
- 単体検証 vs 複数サービス構成
- 再現性（設定のコード化）
- チームオンボーディングとCI連携

---

## 9) Next-step resources (official Docker docs preferred)

- Docker Docs Home: https://docs.docker.com/
- Get Started: https://docs.docker.com/get-started/
- Dockerfile reference: https://docs.docker.com/reference/dockerfile/
- Compose file reference: https://docs.docker.com/reference/compose-file/
- Build best practices: https://docs.docker.com/build/building/best-practices/
- Multi-stage builds: https://docs.docker.com/build/building/multi-stage/
- Docker Engine security: https://docs.docker.com/engine/security/

---

次号予告（学習アーク継続）:
- Beginner: ボリューム基礎（永続化）
- Middle: 開発用ホットリロード構成
- Advanced: 本番向けイメージ最適化と脆弱性対応フロー
