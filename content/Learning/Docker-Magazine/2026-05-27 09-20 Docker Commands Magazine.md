---
tags: [docker, containers, devops, learning, daily]
---

# 2026-05-27 Docker Commands Magazine
[[Home]]

#docker #containers #devops #learning #daily

今日のテーマは**「イメージ作成から安全な運用までの基本アーク」**です。  
難易度を **Beginner → Middle → Advanced** で段階的に進めます。

---

## 1) Topic + Level

### Beginner（初級）
**Topic:** Dockerfileの基本と`docker build` / `docker run`

### Middle（中級）
**Topic:** 開発効率を上げる`docker compose`とボリューム運用
**前提条件:**
- Beginnerの内容（Dockerfile、build/run）が理解できる
- Linux基本コマンド（`ls`, `cd`, `cat`）が使える

### Advanced（上級）
**Topic:** マルチステージビルド + セキュアなイメージ最適化
**前提条件:**
- Middleの内容（compose、volume、ネットワークの基礎）を実践済み
- アプリ依存管理（npm/pip/go mod等）の基本理解

---

## 2) Why it matters for real app development

- **再現性:** 開発者全員が同じ環境で動かせる（「自分のPCだけ動く」を減らす）
- **移植性:** ローカル→CI→本番で同じイメージを使える
- **速度:** Composeで依存サービス（DB/Redis等）を一括起動できる
- **安全性:** 最小イメージ、非root実行、秘密情報の分離でリスク低減

---

## 3) Core Docker command explanations

### Beginnerコアコマンド
- `docker build -t myapp:dev .`
  - Dockerfileからイメージを作成
  - `-t`で`名前:タグ`を付与
- `docker run --rm -p 8080:8080 myapp:dev`
  - コンテナ起動。`--rm`で停止時に自動削除（開発向け）
  - `-p ホスト:コンテナ`でポート公開
- `docker ps` / `docker ps -a`
  - 起動中 / 全コンテナを確認
- `docker logs <container>`
  - アプリログ確認

### Middleコアコマンド
- `docker compose up -d`
  - 複数サービスをバックグラウンド起動
- `docker compose logs -f`
  - 全サービスのログを追跡
- `docker compose exec app sh`
  - 稼働中コンテナ内でシェル操作
- `docker volume ls`
  - 永続ボリューム一覧

### Advancedコアコマンド
- `docker build --target runtime -t myapp:prod .`
  - マルチステージビルドで指定ステージを生成
- `docker image inspect myapp:prod`
  - メタデータ確認（ユーザー、環境変数など）
- `docker history myapp:prod`
  - レイヤー履歴（無駄・秘密混入の有無を確認）
- `docker scout quickview myapp:prod`（利用可能環境なら）
  - 脆弱性・ベースイメージ状態を確認

---

## 4) App開発での使い方（docs.docker.comベストプラクティス準拠）

- **小さいベースイメージを選ぶ**（例: `alpine`やdistroless系、ただし互換性検証必須）
- **マルチステージビルドを使う**（ビルドツールを本番イメージに残さない）
- **`.dockerignore`を整備**（`node_modules`, `.git`, `*.log`等を除外）
- **レイヤーキャッシュを意識**（依存インストールを先、ソースCOPYを後）
- **コンテナを非rootで動かす**（`USER`指定）
- **秘密情報をイメージに焼き込まない**
  - NG: `ENV API_KEY=...` をDockerfileに直書き
  - OK: 実行時環境変数、Secrets管理、CIシークレット注入
- **Composeで開発と本番設定を分離**（overrideファイルやprofilesを活用）

---

## 5) 30-60分ハンズオンミニラボ

### ゴール
Node系Webアプリ（簡易）をDocker化し、Composeで起動。最後に軽量化まで実施。

### 手順（約45分）
1. **0-10分: 最小アプリ準備**
   - `app.js`（Hello返却）
   - `package.json`
2. **10-20分: Beginner実践**
   - Dockerfile作成
   - `docker build -t hello-node:dev .`
   - `docker run --rm -p 3000:3000 hello-node:dev`
3. **20-35分: Middle実践**
   - `compose.yaml`に`app` + `redis`追加
   - `docker compose up -d`
   - `docker compose logs -f`
4. **35-45分: Advanced実践**
   - マルチステージ化（builder/runtime分離）
   - 非rootユーザー化
   - `docker image inspect`と`docker history`で確認
5. **余裕があれば+10分**
   - `.dockerignore`調整→再build時間比較

---

## 6) Command cheatsheet

```bash
# Build & Run
docker build -t myapp:dev .
docker run --rm -p 8080:8080 myapp:dev

# Inspect
docker ps
docker logs <container>
docker image ls
docker image inspect myapp:dev
docker history myapp:dev

# Compose
docker compose up -d
docker compose down
docker compose logs -f
docker compose exec app sh

# Cleanup (要注意: 破壊的)
# WARNING: 不要データ削除の可能性あり。対象確認してから実行。
docker rm -f <container>
docker rmi <image>
docker system prune
```

---

## 7) Common mistakes and safe practices

### よくあるミス
- `COPY . .`で不要ファイルや秘密情報まで混入
- `latest`タグ固定運用で再現性が崩れる
- root実行のまま本番投入
- `docker system prune`を確認なしで実行

### 安全プラクティス
- `.dockerignore`を必ず用意
- イメージは`myapp:1.2.0`のように明示タグ
- 本番は`USER appuser`で非root実行
- **破壊的コマンド前に確認**
  - `docker ps -a`
  - `docker image ls`
  - `docker volume ls`
- Secretsは以下を徹底
  - Gitにコミットしない
  - Dockerfileに埋め込まない
  - Composeでも平文直書き回避（`.env`管理 + 秘密管理基盤）

---

## 8) Interview-style question

**質問:**  
「Dockerfileで依存インストールのレイヤーを先に置くと、なぜビルドが速くなるのか？また、どんな変更でキャッシュが無効化されるか説明してください。」

---

## 9) Next-step resources（公式優先）

- Docker Docs Home  
  https://docs.docker.com/
- Dockerfile best practices  
  https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Multi-stage builds  
  https://docs.docker.com/build/building/multi-stage/
- Compose overview  
  https://docs.docker.com/compose/
- Compose file reference  
  https://docs.docker.com/reference/compose-file/
- Docker Engine security  
  https://docs.docker.com/engine/security/
- Build cache optimization  
  https://docs.docker.com/build/cache/

---

次号予告（学習アーク継続）:  
**Beginner:** コンテナのデバッグ基本  
**Middle:** ヘルスチェックと依存起動順  
**Advanced:** BuildKit + CIキャッシュ最適化
