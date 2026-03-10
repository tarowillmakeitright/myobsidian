---
tags: [docker, containers, devops, learning, daily]
created: 2026-03-10 09:30
---

# Daily Docker Commands Magazine — 2026-03-10
[[Home]]

#docker #containers #devops #learning #daily

## 今日の学習アーク（Beginner → Middle → Advanced）

---

## 1) Topic + Level

### Beginner
**トピック:** `docker run` / `docker ps` / `docker logs` で「コンテナを安全に起動・観察する」

### Middle（前提あり）
**トピック:** `docker build` + `.dockerignore` + マルチステージビルドで「軽量・再現性の高いイメージを作る」
**Prerequisites:**
- Beginner内容（コンテナ起動・停止・ログ確認）ができる
- Linux基本コマンド（`cd`, `cat`, `ls`）
- Dockerfileの基本構文を見たことがある

### Advanced（前提あり）
**トピック:** `docker compose` で「アプリ + DB の開発環境を分離し、ヘルスチェックと依存管理を行う」
**Prerequisites:**
- Middle内容（Dockerfileビルド最適化）
- ネットワーク/ポートの基礎（localhost, 127.0.0.1）
- 環境変数の扱い（`.env` の基本）

---

## 2) Why it matters（実アプリ開発で重要な理由）

- **ローカル差異の削減:** 「自分のPCでは動くのに…」問題を減らす
- **再現性:** 同じイメージから同じ挙動を作れる
- **開発速度:** オンボーディング短縮、依存関係管理が簡潔になる
- **品質・セキュリティ:** 小さいイメージ、最小権限、秘密情報の分離がしやすい
- **CI/CD連携:** ビルド手順がそのままパイプラインに載せやすい

---

## 3) Core Docker command explanations

### Beginnerコマンド
- `docker run -d --name web -p 8080:80 nginx:alpine`
  - `-d`: バックグラウンド実行
  - `--name`: コンテナ名付与
  - `-p 8080:80`: ホスト8080 → コンテナ80
- `docker ps` / `docker ps -a`
  - 実行中 / 全コンテナ確認
- `docker logs -f web`
  - コンテナログを追跡
- `docker stop web && docker rm web`
  - 停止→削除（明示的で安全）

### Middleコマンド
- `docker build -t myapp:dev .`
  - カレントディレクトリをビルドコンテキストとしてイメージ作成
- `docker image ls`
  - イメージ確認
- `docker history myapp:dev`
  - レイヤ履歴確認（肥大化原因の分析に有効）

### Advancedコマンド
- `docker compose up -d --build`
  - サービス群をビルドして起動
- `docker compose ps`
  - 各サービス状態確認
- `docker compose logs -f app`
  - 特定サービスのログ追跡
- `docker compose down`
  - 構成停止・ネットワーク整理（ボリューム削除はオプション）

---

## 4) 実アプリ構築での使い方（docs.docker.com ベストプラクティス準拠）

- **小さいベースイメージを選ぶ**（例: `alpine`, distroless系の検討）
- **マルチステージビルド**でビルド依存物を最終イメージに残さない
- **`.dockerignore`**で不要ファイル（`.git`, `node_modules`, secrets）を送らない
- **レイヤキャッシュ最適化**
  - 依存解決（`package*.json`等）を先にコピー
  - 変更頻度の低い手順を上位レイヤに
- **秘密情報をイメージに焼かない**
  - `ARG`/`ENV`へ機密直書きしない
  - Composeの`secrets`や実行時注入を使う
- **最小権限**
  - 可能ならroot以外ユーザーで実行
- **ヘルスチェック/依存管理**
  - Composeの`healthcheck`で起動順依存を緩和

---

## 5) 30–60分ハンズオン・ミニラボ

### ゴール
Nginx + API(ダミー) + Redis を Compose で起動し、ログとヘルスを確認する。

### 手順（目安45分）

1. **準備（10分）**
   - 作業ディレクトリ作成
   - `Dockerfile`（API用）と `.dockerignore` 作成

2. **ビルド（10分）**
   ```bash
   docker build -t demo-api:dev .
   docker image ls
   ```

3. **Compose起動（15分）**
   ```bash
   docker compose up -d --build
   docker compose ps
   ```

4. **検証（10分）**
   ```bash
   docker compose logs -f app
   docker compose logs -f redis
   ```
   - `app` が `redis` に接続できるログを確認
   - ヘルスチェック結果を確認

5. **終了処理（安全）（5分）**
   ```bash
   docker compose down
   ```

> ⚠️ 注意: `docker compose down -v` はボリュームを削除し、DBデータが消える可能性があります。必要性を確認してから実行してください。

---

## 6) Command cheatsheet

```bash
# コンテナ操作
docker run -d --name web -p 8080:80 nginx:alpine
docker ps
docker logs -f web
docker stop web && docker rm web

# イメージ操作
docker build -t myapp:dev .
docker image ls
docker history myapp:dev

# Compose
docker compose up -d --build
docker compose ps
docker compose logs -f app
docker compose down

# クリーンアップ（要注意）
# ⚠️ 破壊的: 未使用リソースを削除
# docker system prune
# ⚠️ 破壊的: イメージを強制削除
# docker rmi -f <image>
# ⚠️ 破壊的: コンテナ強制削除
# docker rm -f <container>
```

---

## 7) Common mistakes and safe practices

### よくあるミス
- `COPY . .` で不要ファイルや秘密情報まで入れてしまう
- 開発用ツールを本番イメージに同梱し肥大化
- `latest` タグ固定で再現性を失う
- `prune` / `rm -f` / `rmi -f` を意味理解せず実行

### 安全運用のコツ
- `.dockerignore` を必ず整備
- イメージタグはバージョン明示（例: `myapp:1.4.2`）
- 機密は **イメージ内に保存しない**（Compose secrets / 実行時注入）
- 削除系コマンド前に `docker ps -a`, `docker image ls`, `docker volume ls` で確認
- 本番用と開発用のCompose設定を分ける

---

## 8) Interview-style question

**Q.** `docker run` と `docker compose up` の違いを、実務のチーム開発観点で説明してください。さらに、なぜ `docker compose` が複数サービス開発で有利なのかを、ネットワーク・環境変数・依存関係の観点で答えてください。

---

## 9) Next-step resources（公式優先）

- Docker Docs Home: https://docs.docker.com/
- Get Started: https://docs.docker.com/get-started/
- Dockerfile reference: https://docs.docker.com/reference/dockerfile/
- Build best practices: https://docs.docker.com/build/building/best-practices/
- Multi-stage builds: https://docs.docker.com/build/building/multi-stage/
- Docker Compose overview: https://docs.docker.com/compose/
- Compose file reference: https://docs.docker.com/reference/compose-file/
- Docker Engine security: https://docs.docker.com/engine/security/
- Manage secrets (Compose): https://docs.docker.com/compose/how-tos/use-secrets/

---

次回予告（明日）: Beginnerは`docker exec`/`docker cp`、Middleはボリューム設計、AdvancedはCompose overrideとプロファイル運用。