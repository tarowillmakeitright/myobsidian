# 2026-04-22 09:20 Docker Commands Magazine

Tags: #docker #containers #devops #learning #daily

[[Home]]

---

# Daily Docker Commands Magazine（実践版）

今号テーマは **「開発サイクルを速くする Docker 実践コマンド」**。
難易度を **Beginner → Middle → Advanced** の学習アークで進めます。

---

## 1) Topic + Level

### Beginner
**トピック:** コンテナの基本操作（起動・確認・停止・削除）

### Middle
**トピック:** Dockerfile で開発用イメージを作る（キャッシュ活用）
**前提知識:**
- `docker run`, `docker ps`, `docker stop`, `docker rm` の基本
- Linux ファイルパスと作業ディレクトリの概念

### Advanced
**トピック:** BuildKit / マルチステージビルドで安全かつ軽量にする
**前提知識:**
- Dockerfile の命令（`FROM`, `WORKDIR`, `COPY`, `RUN`, `CMD`）
- イメージレイヤーとキャッシュの基本
- `.dockerignore` の目的

---

## 2) なぜ実アプリ開発で重要か

- **再現性:** 「自分のPCでは動く」を減らし、チーム開発で同じ環境を共有できる。
- **開発速度:** 適切な Dockerfile 構成でビルド時間を短縮し、試行回数を増やせる。
- **安全性:** 秘密情報をイメージに埋め込まない、不要な権限を避ける、最小構成にすることでリスクを減らせる。
- **運用接続:** ローカル開発から CI/CD、本番配備へ流れをつなげやすい。

---

## 3) コア Docker コマンド解説

- `docker run -d --name app -p 8080:80 nginx:alpine`
  - コンテナをバックグラウンド起動。`-p` でホスト:コンテナのポート公開。
- `docker ps` / `docker ps -a`
  - 実行中 / 全コンテナを確認。
- `docker logs -f app`
  - ログを追跡して起動失敗を早期発見。
- `docker exec -it app sh`
  - 稼働中コンテナ内部で調査。
- `docker build -t myapp:dev .`
  - Dockerfile からイメージ作成。
- `docker images`
  - ローカルイメージ一覧。
- `docker stop app && docker rm app`
  - コンテナ停止と削除。

---

## 4) アプリ開発での使い方（Docker公式ベストプラクティス準拠）

- **小さいベースイメージを選ぶ**（例: `alpine`, `slim` 系）
- **マルチステージビルド**でビルド成果物だけを最終イメージへ
- **`.dockerignore` を必ず作る**（`node_modules`, `.git`, ログ, 秘密ファイルを除外）
- **レイヤーキャッシュを活かす順序**
  - 依存定義ファイル（`package*.json` 等）を先に `COPY`
  - 依存インストール後にアプリ本体を `COPY`
- **秘密情報を入れない**
  - `ENV API_KEY=...` や Dockerfile 直書きを避ける
  - BuildKit secret や実行時環境変数管理を使う
- **不要な root 実行を避ける**（可能なら非rootユーザーへ）

---

## 5) 30〜60分ミニラボ

### ゴール
Node.js の簡単な API を Docker 化し、改善版 Dockerfile（キャッシュ最適化）を作る。

### 手順（目安45分）

1. **サンプル作成（10分）**
   - `app.js` と `package.json` を用意（Hello API でOK）

2. **初版 Dockerfile（10分）**
   - 単純に `COPY . .` → `npm install` → `npm start`
   - `docker build -t hello-api:v1 .` / `docker run --rm -p 3000:3000 hello-api:v1`

3. **改善版 Dockerfile（15分）**
   - `COPY package*.json ./` を先
   - `RUN npm ci --only=production`（要件に応じ調整）
   - 後から `COPY . .`
   - 再ビルドでキャッシュ効果を確認

4. **安全チェック（10分）**
   - `.dockerignore` 作成
   - APIキー等がイメージ履歴に含まれていないか確認（`docker history`）

### 検証コマンド
- `curl http://localhost:3000`
- `docker logs -f <container_name>`

---

## 6) Command Cheatsheet

```bash
# 実行中コンテナ
docker ps

# 全コンテナ（停止済み含む）
docker ps -a

# イメージビルド
docker build -t myapp:dev .

# コンテナ起動
docker run -d --name myapp -p 3000:3000 myapp:dev

# ログ確認
docker logs -f myapp

# コンテナ内シェル
docker exec -it myapp sh

# 停止/削除
docker stop myapp
docker rm myapp

# 未使用データの掃除（要注意）
# ⚠️ 破壊的: 未使用リソースを削除します
# docker system prune
# docker image prune -a
```

---

## 7) よくあるミスと安全運用

- **ミス:** `COPY . .` で `.env` や鍵ファイルまで入れる
  - **対策:** `.dockerignore` を整備し、秘密情報は実行時注入

- **ミス:** 開発と本番を同じ巨大イメージで運用
  - **対策:** マルチステージで本番最小化

- **ミス:** いきなり `docker system prune -a` を実行
  - **対策:** 先に `docker ps -a`, `docker images` で確認。共有環境では特に事前合意。

- **ミス:** `docker rm -f` / `docker rmi -f` を習慣的に使う
  - **対策:** `-f` は最終手段。影響範囲を確認してから。

---

## 8) 面接風質問（1問）

**質問:**
「Dockerfile で `COPY package.json` を先に行ってから `npm ci` を実行し、その後にアプリ全体を `COPY` するのはなぜですか？」

**答えるポイント（自己チェック）:**
- レイヤーキャッシュの再利用
- 依存変更がない限りインストール層が再利用される
- ビルド時間短縮と開発効率向上

---

## 9) 次の一歩（公式ドキュメント中心）

- Docker Docs Home  
  https://docs.docker.com/
- Get Started（公式チュートリアル）  
  https://docs.docker.com/get-started/
- Dockerfile best practices  
  https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Multi-stage builds  
  https://docs.docker.com/build/building/multi-stage/
- Build secrets（秘密情報の安全な扱い）  
  https://docs.docker.com/build/building/secrets/
- Docker Compose overview  
  https://docs.docker.com/compose/

---

次号予告（学習アーク継続）:
- Beginner: `docker compose up` の基本
- Middle: 開発用ボリューム戦略とホットリロード
- Advanced: CI でのキャッシュ最適化と SBOM/脆弱性確認
