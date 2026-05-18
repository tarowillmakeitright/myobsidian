---
tags: [docker, containers, devops, learning, daily]
---

# Docker Commands Magazine — 2026-05-18 (09:20)
[[Home]]

本日の学習アークは **Beginner → Middle → Advanced**。
実務で「安全に使う」ことを最優先に、段階的にレベルアップします。

---

## 1) Topic + Level

### Beginner
**トピック:** `docker run` / `docker ps` / `docker logs` でローカルAPIを素早く起動・観察する

### Middle（前提あり）
**トピック:** `docker compose up` / `docker compose logs` / `docker compose exec` で複数サービス開発
**前提:**
- `docker run` の基本操作ができる
- ポート公開（`-p`）とボリューム（`-v`）の概念を理解している

### Advanced（前提あり）
**トピック:** BuildKit + マルチステージビルド + キャッシュ最適化（`docker buildx build`）
**前提:**
- Dockerfile が読める
- Composeでアプリ+DB構成を起動した経験がある
- イメージサイズ・ビルド時間の課題を体感したことがある

---

## 2) Why it matters for real app development

- 開発速度: コンテナ化で「自分の環境だけ動かない」を減らせる
- 再現性: CI/CD と同じ実行条件をローカルでも再現しやすい
- 安全性: 実行権限・イメージ由来・秘密情報の扱いを標準化しやすい
- 運用接続: 開発時点でログ確認・ヘルスチェック・依存関係起動を習慣化できる

---

## 3) Core Docker command explanations

- `docker run IMAGE`:
  単一コンテナを起動。`--rm` で終了後に自動削除。
- `docker ps` / `docker ps -a`:
  実行中 / 全コンテナ確認。
- `docker logs CONTAINER` / `-f`:
  ログ確認。`-f` で追従。
- `docker exec -it CONTAINER sh`:
  コンテナ内シェルで調査。
- `docker compose up -d`:
  複数サービスをバックグラウンド起動。
- `docker compose logs -f SERVICE`:
  サービス別ログ追跡。
- `docker compose exec SERVICE CMD`:
  サービスコンテナでコマンド実行。
- `docker buildx build ...`:
  BuildKit前提の高機能ビルド（キャッシュ/マルチアーキ等）。

---

## 4) App開発での使い方（docs.docker.com ベストプラクティス準拠）

- **最小ベースイメージ**を使う（攻撃面・サイズ削減）
- **マルチステージビルド**でビルド成果物だけ最終イメージへ
- **レイヤーキャッシュを意識**して Dockerfile を並べる（依存インストールを先に固定）
- **`.dockerignore` を整備**して不要ファイルを送らない
- **root以外ユーザーで実行**（可能なら）
- **秘密情報をイメージに埋め込まない**
  - NG: Dockerfile に `ENV API_KEY=...`
  - 推奨: runtime環境変数や secrets 機構を利用
- **Composeで開発依存（DB, Redis）を明示**し、起動手順を標準化

---

## 5) 30–60分ミニラボ

### 目標
Node.js API + Redis を Compose で起動し、ログ観察と簡易デバッグを実施。最後に BuildKit で軽量イメージ化。

### 手順（45分想定）
1. **雛形作成（10分）**
   - `app.js`（Hello API）
   - `package.json`
   - `Dockerfile`
   - `compose.yaml`（app + redis）
2. **起動（10分）**
   - `docker compose up -d --build`
   - `docker compose ps`
3. **観察（10分）**
   - `docker compose logs -f app`
   - `curl http://localhost:3000`
4. **デバッグ（5分）**
   - `docker compose exec app sh`
   - プロセス/環境変数確認
5. **最適化（10分）**
   - Dockerfileをマルチステージ化
   - `docker buildx build --load -t demo-api:optimized .`
   - `docker images | grep demo-api`

完了条件:
- APIレスポンスが返る
- redis と app の依存起動を確認
- optimized イメージが従来より小さい（目視でOK）

---

## 6) Command cheatsheet

```bash
# 単体コンテナ
docker run --rm -p 3000:3000 myapp:dev
docker ps
docker logs -f <container>
docker exec -it <container> sh

# Compose
docker compose up -d --build
docker compose ps
docker compose logs -f app
docker compose exec app sh
docker compose down

# BuildKit / buildx
docker buildx ls
docker buildx build --load -t myapp:latest .

# イメージ確認
docker images
```

---

## 7) Common mistakes and safe practices

### よくあるミス
- `latest` タグ固定で意図せず更新される
- `.dockerignore` 未設定で巨大ビルドコンテキスト
- `COPY . .` 前に依存解決を置いてキャッシュ効率悪化
- シークレットを Dockerfile/compose に直書き

### 安全運用ポイント
- タグは明示（例: `node:22-alpine`）
- 非root実行を検討
- 定期的にイメージ脆弱性スキャン（Docker Scout等）
- 本番相当の環境変数は `.env` / secrets で分離管理

⚠️ **破壊的コマンド注意**（実行前に対象を必ず確認）
- `docker system prune`
- `docker image prune -a`
- `docker rmi ...`
- `docker rm -f ...`

これらは不要データだけでなく、必要な停止中コンテナやキャッシュを消す可能性があります。

---

## 8) Interview-style question

「`docker compose up` と `docker compose run` の違いを、開発時ユースケース（Webアプリ + DB）に沿って説明してください。さらに、どちらをCIのテスト実行で使うべきか理由付きで答えてください。」

---

## 9) Next-step resources（公式優先）

- Docker Docs Home: https://docs.docker.com/
- Get Started: https://docs.docker.com/get-started/
- Dockerfile best practices: https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Multi-stage builds: https://docs.docker.com/build/building/multi-stage/
- Compose overview: https://docs.docker.com/compose/
- BuildKit / buildx: https://docs.docker.com/build/
- Docker Scout: https://docs.docker.com/scout/

---

次号予告（学習アーク継続）:
- Beginner: コンテナの永続化（volume）
- Middle: 開発/本番で compose ファイルを分割
- Advanced: マルチアーキテクチャビルドとCIキャッシュ戦略
