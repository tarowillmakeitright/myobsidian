---
tags: [docker, containers, devops, learning, daily]
---

# 2026-03-06 09:20 Docker Commands Magazine
[[Home]]

#docker #containers #devops #learning #daily

## 今日のテーマ
**実践で身につける Docker コマンド学習アーク（Beginner → Middle → Advanced）**  
題材: **Node.js API をコンテナで開発・検証・配布する流れ**

---

## 1) Topic + Level

### 🟢 Beginner: `docker run` / `docker ps` / `docker logs` の基本運用

**到達目標**
- イメージからコンテナを起動・停止・確認できる
- ログ確認でアプリ状態を把握できる

---

### 🟡 Middle: `docker build` / `docker exec` / `docker compose up` で開発効率化

**前提知識（Prerequisites）**
- Beginner内容（run/ps/logs）の理解
- Dockerfile の基本構文（`FROM`, `WORKDIR`, `COPY`, `RUN`, `CMD`）

**到達目標**
- アプリを自作イメージ化できる
- 稼働中コンテナに入り、状態確認できる
- Compose で複数サービスをまとめて起動できる

---

### 🔴 Advanced: `multi-stage build` / `healthcheck` / セキュア運用

**前提知識（Prerequisites）**
- Middle内容（build/exec/compose）の理解
- Linux権限・環境変数の基礎

**到達目標**
- 軽量で安全な本番向けイメージを作る
- ヘルスチェックと再現可能ビルドを取り入れる
- 破壊的コマンドを安全に扱う

---

## 2) なぜ実アプリ開発で重要か

- **環境差分の削減**: 「自分のPCでは動く」問題を抑制
- **オンボーディング高速化**: 新メンバーが `docker compose up` で即開発開始
- **CI/CD親和性**: ローカルとCIで同じビルド手順を再利用
- **運用の安定性**: ヘルスチェック・最小イメージで障害対応がしやすい

---

## 3) コア Docker コマンド解説

- `docker run -d -p 3000:3000 --name app myapp:dev`  
  コンテナ起動（バックグラウンド、ポート公開、名前付け）

- `docker ps` / `docker ps -a`  
  起動中 / 全コンテナ一覧

- `docker logs -f app`  
  リアルタイムログ追跡（`Ctrl+C` で抜ける）

- `docker build -t myapp:dev .`  
  Dockerfile からイメージ作成

- `docker exec -it app sh`  
  コンテナ内シェルで診断（`bash` がない場合は `sh`）

- `docker compose up -d` / `docker compose down`  
  複数サービス一括起動/停止

- `docker inspect app`  
  ネットワーク・環境変数・設定の詳細確認

---

## 4) 実アプリ構築での使い方（docs.docker.com ベストプラクティス準拠）

1. **.dockerignore を整備**  
   `node_modules`, `.git`, ログ等を除外しビルド効率改善

2. **レイヤーキャッシュを活用**  
   `package*.json` を先に `COPY` して `npm ci`、その後ソースを `COPY`

3. **最小ベースイメージの検討**  
   例: `node:20-alpine`（互換性確認は必須）

4. **マルチステージビルド**  
   ビルド用と実行用を分離してサイズ・攻撃面を縮小

5. **秘密情報をイメージに埋め込まない**  
   `ENV API_KEY=...` の直書き禁止。runtime注入（Compose env/secrets等）

6. **非rootユーザー実行**  
   可能なら `USER node` 等で権限最小化

---

## 5) 30–60分ハンズオン mini lab（目安45分）

### ゴール
Node.js API + Redis を Compose で起動し、ログ確認とヘルスチェックまで実施

### 手順
1. **雛形作成（10分）**
   - `Dockerfile` と `docker-compose.yml` を用意
2. **ビルド（10分）**
   - `docker build -t myapi:lab .`
3. **起動（10分）**
   - `docker compose up -d`
4. **観測（10分）**
   - `docker ps`
   - `docker logs -f <apiコンテナ名>`
   - `curl http://localhost:3000/health`
5. **診断（5分）**
   - `docker exec -it <apiコンテナ名> sh`
   - 環境変数/プロセス確認

### 追加チャレンジ（任意）
- Dockerfile を multi-stage 化してイメージサイズ比較  
  `docker images | grep myapi`

---

## 6) コマンドチートシート

```bash
# 起動・停止
docker run -d --name app -p 3000:3000 myapp:dev
docker stop app && docker start app

# 状態確認
docker ps
docker logs -f app
docker inspect app

# ビルド
docker build -t myapp:dev .

# コンテナ内確認
docker exec -it app sh

# Compose
docker compose up -d
docker compose ps
docker compose logs -f
docker compose down
```

---

## 7) よくあるミスと安全運用

### よくあるミス
- `latest` タグ固定で再現性が崩れる
- `.dockerignore` 未設定でビルドが遅い
- `COPY . .` を早く置いてキャッシュが効かない
- シークレットを Dockerfile / compose に平文記載

### 安全運用
- タグは `myapp:1.4.2` のように明示
- 不要権限を避ける（非root、read-only検討）
- 脆弱性スキャン/ベース更新を定期化

### ⚠️ 破壊的コマンドの注意
以下は**削除を伴う**ため、実行前に対象確認必須:
- `docker system prune`
- `docker image prune -a`
- `docker rm -f <container>`
- `docker rmi <image>`

実行前チェック例:
```bash
docker ps -a
docker images
docker volume ls
```

---

## 8) 面接ふう質問（1問）

**Q. `docker run` と `docker compose up` の使い分けを、チーム開発の観点で説明してください。**  
（期待ポイント: 単体検証 vs 複数サービス構成管理、再現性、共有しやすさ）

---

## 9) 次の一歩（公式ドキュメント中心）

- Docker Get Started  
  https://docs.docker.com/get-started/
- Dockerfile best practices  
  https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Multi-stage builds  
  https://docs.docker.com/build/building/multi-stage/
- Compose overview  
  https://docs.docker.com/compose/
- Compose file reference  
  https://docs.docker.com/reference/compose-file/
- Volumes  
  https://docs.docker.com/storage/volumes/
- Docker Engine security  
  https://docs.docker.com/engine/security/

---

次号予告: **Docker Networking 実践（bridge / host / internal）で API + DB の疎通設計**