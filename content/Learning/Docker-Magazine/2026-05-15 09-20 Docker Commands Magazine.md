---
tags: [docker, containers, devops, learning, daily]
---

# Docker Commands Magazine — 2026-05-15 09:20
[[Home]]

今日のテーマは **「イメージ作成〜実行〜安全な運用の基礎を、実務フローでつなぐ」** です。  
難易度は **Beginner → Middle → Advanced** の学習アークで進みます。

---

## 1) Topic + Level

### Beginner
**トピック:** `docker run` / `docker ps` / `docker logs` で「コンテナを動かして観察する」

### Middle
**トピック:** `docker build` / `.dockerignore` / タグ運用で「再現可能な開発イメージを作る」
**前提知識:**
- `docker run`, `docker ps`, `docker stop` の基本操作
- Linuxコマンドの基本（`pwd`, `ls`, `cat`）

### Advanced
**トピック:** `docker compose` + ヘルスチェック + セキュアな設定分離
**前提知識:**
- Dockerfileの基本（`FROM`, `COPY`, `RUN`, `CMD`）
- イメージタグの概念（`name:tag`）
- 1コンテナ1プロセスの考え方

---

## 2) Why it matters for real app development

- **環境差分の削減:** 「自分のPCでは動く」を減らし、チーム全員で同じ実行環境を持てる。
- **オンボーディング高速化:** 新メンバーが Docker で即開発開始できる。
- **CI/CD連携:** ローカルで使う Dockerfile をそのままCIで再利用しやすい。
- **障害対応の可視性:** `logs`, `inspect`, `compose ps` で原因切り分けが速くなる。
- **セキュリティ向上:** シークレットをイメージへ焼き込まない運用を標準化できる。

---

## 3) Core Docker command explanations

- `docker run [OPTIONS] IMAGE [COMMAND]`
  - イメージからコンテナを起動。
  - 例: `-d`(バックグラウンド), `-p`(ポート公開), `--name`(名前指定), `--rm`(終了時自動削除)

- `docker ps` / `docker ps -a`
  - 稼働中 / 全コンテナ一覧を表示。状態確認の起点。

- `docker logs -f <container>`
  - ログ追跡。アプリ起動失敗や接続エラー確認で必須。

- `docker exec -it <container> sh`
  - 動作中コンテナへ入って調査（Alpine系は `sh` が多い）。

- `docker build -t app:dev .`
  - Dockerfileからイメージ作成。`-t`でタグ付け。

- `docker images`
  - ローカルイメージ一覧。タグ重複や容量肥大の把握。

- `docker compose up -d` / `docker compose down`
  - 複数サービスをまとめて起動/停止。アプリ+DBのローカル環境に有効。

---

## 4) How Docker is used while building apps (docs.docker.com 準拠の実務感)

実務では次の流れが一般的です。

1. **Dockerfile作成（最小・明確）**
   - 公式推奨の軽量ベースイメージを利用。
   - 不要ファイルは `.dockerignore` で除外。

2. **ローカルビルド&実行**
   - `docker build` → `docker run` で最速検証。

3. **Composeで依存サービスを統合**
   - API + DB + Cache を `compose.yaml` で構成。

4. **設定と秘密情報を分離**
   - 環境変数や secrets を使い、**Dockerfileに秘密情報を書かない**。
   - `.env` はGit管理対象から外す（`.gitignore`）。

5. **本番に近い検証**
   - ヘルスチェック、再起動ポリシー、read-only化や非root実行を段階導入。

---

## 5) 30-60 minute hands-on mini lab

### ゴール
Node.jsの簡易APIをコンテナ化し、Composeで起動、ログ確認とヘルスチェックまで行う。

### 手順（約45分）

#### A. プロジェクト作成（10分）
```bash
mkdir docker-mag-lab && cd docker-mag-lab
cat > app.js <<'EOF'
const http = require('http');
const port = process.env.PORT || 3000;
http.createServer((req, res) => {
  if (req.url === '/health') {
    res.writeHead(200, {'Content-Type':'application/json'});
    return res.end(JSON.stringify({status:'ok'}));
  }
  res.end('Hello Docker Magazine!');
}).listen(port, () => console.log(`listening on ${port}`));
EOF
```

#### B. Dockerfile + .dockerignore（10分）
```bash
cat > Dockerfile <<'EOF'
FROM node:20-alpine
WORKDIR /app
COPY app.js .
USER node
EXPOSE 3000
CMD ["node", "app.js"]
EOF

cat > .dockerignore <<'EOF'
.git
node_modules
npm-debug.log
.env
EOF
```

#### C. build/run（10分）
```bash
docker build -t mag-node:dev .
docker run -d --name mag-node -p 3000:3000 mag-node:dev
docker ps
docker logs -f mag-node
```
別ターミナルで:
```bash
curl http://localhost:3000
curl http://localhost:3000/health
```

#### D. compose化 + healthcheck（15分）
```bash
cat > compose.yaml <<'EOF'
services:
  app:
    image: mag-node:dev
    container_name: mag-node-compose
    ports:
      - "3000:3000"
    healthcheck:
      test: ["CMD", "wget", "-qO-", "http://localhost:3000/health"]
      interval: 10s
      timeout: 3s
      retries: 3
    restart: unless-stopped
EOF

docker rm -f mag-node
docker compose up -d
docker compose ps
```

### 完了条件
- `curl /health` が200を返す
- `docker compose ps` で `healthy` が確認できる

---

## 6) Command cheatsheet

```bash
# 実行・停止
docker run -d --name app -p 3000:3000 image:tag
docker stop app && docker rm app

# 観察
docker ps
docker logs -f app
docker exec -it app sh

# ビルド
docker build -t app:dev .
docker images

# Compose
docker compose up -d
docker compose ps
docker compose logs -f
docker compose down
```

---

## 7) Common mistakes and safe practices

### よくあるミス
- **ミス1:** DockerfileにAPIキーや秘密情報を直書き
  - 対策: `secrets` / 環境変数を使い、Gitに入れない。

- **ミス2:** `latest` タグ固定で再現性が崩れる
  - 対策: バージョンタグを明示（例: `node:20-alpine`）。

- **ミス3:** 不要なファイルをビルドコンテキストへ含める
  - 対策: `.dockerignore` を必ず整備。

- **ミス4:** rootユーザーで実行し続ける
  - 対策: 可能な限り非rootユーザー（`USER node` など）を使う。

### 破壊的コマンドの注意（必読）
以下はデータ/イメージを失う可能性があります。**実行前に対象を必ず確認**してください。

- `docker system prune`
- `docker image prune -a`
- `docker container rm -f <name>`
- `docker rmi <image>`

安全策:
1. まず `docker ps -a` / `docker images` で対象確認
2. `--volumes` 付き prune は特に慎重に
3. 本番/共有環境では即実行しない（レビューを挟む）

---

## 8) Interview-style question

**質問:**  
「開発中に `docker compose up` したらアプリが起動しません。最初の5分で、どの順で何を確認しますか？」

**期待される観点（例）:**
1. `docker compose ps` で状態確認（Exited/Restarting/Unhealthy）
2. `docker compose logs -f app` でエラー確認
3. ポート競合（`-p`設定, 既存プロセス）
4. 環境変数不足（`.env`, compose定義）
5. ヘルスチェック定義ミスや依存サービス未起動

---

## 9) Next-step resources (公式優先)

- Docker Docs Home  
  https://docs.docker.com/
- Get Started (公式チュートリアル)  
  https://docs.docker.com/get-started/
- Dockerfile Best Practices  
  https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Compose file reference  
  https://docs.docker.com/reference/compose-file/
- Docker Engine security  
  https://docs.docker.com/engine/security/
- Build cache / BuildKit  
  https://docs.docker.com/build/

---

次号予告（学習アーク継続）:  
**Beginner:** ボリューム基礎（永続化）  
**Middle:** 開発向けホットリロード構成  
**Advanced:** マルチステージビルド + SBOM/イメージスキャン
