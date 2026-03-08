---
tags:
  - docker
  - containers
  - devops
  - learning
  - daily
---

# 2026-03-05 Docker Commands Magazine（09:20）
[[Home]]

本日のテーマは **「Docker コマンド実践アーク：Beginner → Middle → Advanced」** です。  
実務でのアプリ開発に直結する形で、段階的に進めます。

---

## 1) Topic + Level

### Beginner
**トピック:** コンテナの基本操作（`docker run`, `docker ps`, `docker logs`, `docker exec`, `docker stop`）

### Middle
**トピック:** イメージ作成と開発フロー（`docker build`, `docker compose up`, `docker compose logs`）

**前提知識（Prerequisites）:**
- Beginner の内容を理解している
- Linux の基本コマンド（`cd`, `ls`, `cat`）
- アプリの実行コマンド（例: Node.js/ Python）を1つ知っている

### Advanced
**トピック:** 安全で効率的な運用（マルチステージビルド、キャッシュ最適化、クリーンアップ運用）

**前提知識（Prerequisites）:**
- Middle の内容を理解している
- Dockerfile の基本命令（`FROM`, `COPY`, `RUN`, `CMD`）
- CI/CD やデプロイの流れを概念的に理解している

---

## 2) なぜ実アプリ開発で重要か

- **環境差分の削減:** 「自分のPCでは動く」を減らし、開発/CI/本番の再現性を高める。
- **オンボーディング高速化:** 新メンバーが Docker だけで同じ実行環境を再現可能。
- **依存関係の分離:** ホスト環境を汚さず、複数プロジェクトを安全に共存。
- **デプロイの一貫性:** 同じイメージをテストから本番まで使える。

---

## 3) Core Docker command explanations

### `docker run`
イメージからコンテナを起動する。  
例: `docker run -d --name web -p 8080:80 nginx:alpine`
- `-d`: バックグラウンド実行
- `--name`: コンテナ名
- `-p 8080:80`: ホスト8080 → コンテナ80

### `docker ps`
起動中コンテナの一覧確認。`-a`で停止済みも表示。

### `docker logs -f <container>`
コンテナログを追跡表示。アプリ不調時の初手。

### `docker exec -it <container> sh`
起動中コンテナに入って調査。`bash` がないイメージもあるため `sh` が無難。

### `docker build -t <name>:<tag> .`
Dockerfile からイメージ作成。

### `docker compose up -d`
複数サービス（app/db/redis等）をまとめて起動。

### `docker compose logs -f`
構成全体のログ確認。

### `docker compose down`
Compose で起動したリソースを停止・削除（ネットワーク等）。

---

## 4) docs.docker.com ベストプラクティスに沿った使い方

- **最小ベースイメージを選ぶ**（例: `alpine`, `slim`）
- **マルチステージビルド**で実行イメージを軽量化
- **`.dockerignore` を必ず用意**（`node_modules`, `.git`, 秘密情報を除外）
- **レイヤーキャッシュを意識した Dockerfile 順序**（依存定義を先にCOPY）
- **コンテナは1プロセス原則を意識**（監視・スケールしやすく）
- **秘密情報をイメージに焼き込まない**
  - NG: `ENV API_KEY=...` をDockerfileに直書き
  - 推奨: 実行時注入（環境変数/シークレット管理）
- **`latest` 固定を避ける**（再現性のためタグ固定）

---

## 5) 30-60分ミニラボ（実践）

### ゴール
簡単なWebアプリをコンテナ化し、Composeで起動、ログ確認、停止まで行う。

### 手順（約45分）
1. 作業フォルダ作成
```bash
mkdir docker-mini-lab && cd docker-mini-lab
```

2. サンプルアプリ準備（例: Node.js）
```bash
cat > app.js <<'EOF'
const http = require('http');
const server = http.createServer((req, res) => {
  res.end('Hello from Docker Mini Lab!');
});
server.listen(3000, () => console.log('Server running on 3000'));
EOF
```

3. Dockerfile 作成
```Dockerfile
FROM node:22-alpine
WORKDIR /app
COPY app.js .
EXPOSE 3000
CMD ["node", "app.js"]
```

4. イメージビルド
```bash
docker build -t mini-lab-web:1.0 .
```

5. コンテナ起動
```bash
docker run -d --name mini-lab -p 3000:3000 mini-lab-web:1.0
```

6. 動作確認
```bash
curl http://localhost:3000
```

7. ログ確認・コンテナ内確認
```bash
docker logs mini-lab
docker exec -it mini-lab sh
```

8. Compose化（任意で+15分）
`compose.yaml` を作って `docker compose up -d` / `docker compose logs -f` を体験。

9. 停止・後片付け
```bash
docker stop mini-lab
docker rm mini-lab
```

> ⚠️ 注意: `docker system prune` や `docker image prune -a` は未使用リソースを削除します。必要なキャッシュ/イメージまで消える可能性があるため、内容を確認してから実行してください。

---

## 6) Command Cheatsheet

```bash
# コンテナ起動
docker run -d --name app -p 8080:80 nginx:alpine

# 一覧確認
docker ps
docker ps -a

# ログ
docker logs -f app

# コンテナ内へ
docker exec -it app sh

# イメージ作成
docker build -t myapp:1.0 .

# Compose 起動/停止
docker compose up -d
docker compose logs -f
docker compose down

# 危険系（実行前に確認）
# docker system prune
# docker image rm -f <image>
# docker rm -f <container>
```

---

## 7) よくあるミス & 安全運用

- **ミス:** ポート競合（既に使用中ポートへバインド）  
  **対策:** `lsof -i :PORT` 等で使用状況確認、別ポートを使う。

- **ミス:** ログを見ずに再ビルド連打  
  **対策:** まず `docker logs` / `docker compose logs` で原因特定。

- **ミス:** Secret をDockerfile/composeに平文記載  
  **対策:** `.env` 管理 + Git除外 + シークレット管理基盤の利用。

- **ミス:** いきなり `prune` 実行  
  **対策:** `docker system df` で確認し、削除対象を把握してから実行。

- **ミス:** root 権限前提のコンテナ設計  
  **対策:** 可能なら非rootユーザーで実行する設計にする。

---

## 8) Interview-style Question

**質問:**  
「開発環境では動くのに本番で動かない問題を、Dockerでどう減らせますか？ 具体的に使うコマンドと運用ルールを挙げて説明してください。」

---

## 9) Next-step Resources（公式優先）

- Docker Docs Home: https://docs.docker.com/
- Get Started: https://docs.docker.com/get-started/
- Dockerfile best practices: https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Multi-stage builds: https://docs.docker.com/build/building/multi-stage/
- Compose overview: https://docs.docker.com/compose/
- Compose file reference: https://docs.docker.com/reference/compose-file/
- Docker Engine security: https://docs.docker.com/engine/security/
- Build cache: https://docs.docker.com/build/cache/

---

次号予告（学習アーク継続）:  
**Beginner:** ボリューム基礎  
**Middle:** 開発用Compose（hot reload）  
**Advanced:** CIでのBuildx + キャッシュ戦略
