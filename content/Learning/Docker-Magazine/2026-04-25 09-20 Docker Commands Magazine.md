# 2026-04-25 09:20 Docker Commands Magazine

Tags: #docker #containers #devops #learning #daily
Links: [[Home]]

---

## 今日のテーマ
**Dockerコマンド実践: 開発フローを支える基本〜応用（Beginner → Middle → Advanced）**

---

## 1) Topic + Level

### Beginner（初級）
**トピック:** `docker run`, `docker ps`, `docker logs`, `docker exec` で「動いているコンテナ」を理解する

### Middle（中級）
**トピック:** `Dockerfile` + `docker build` + `docker compose up` でローカル開発環境を再現する
**前提知識（Prerequisites）:**
- Beginnerレベルのコマンドが使える
- Linuxコマンドの基本（`cd`, `ls`, `cat`）
- アプリに環境変数が必要な理由を知っている

### Advanced（上級）
**トピック:** BuildKitキャッシュ・マルチステージビルド・セキュアなイメージ運用
**前提知識（Prerequisites）:**
- MiddleレベルのDockerfile/Compose運用
- レイヤーキャッシュの概念
- CI/CDでイメージを扱う基礎知識

---

## 2) Why it matters for real app development

実アプリ開発では、**「手元では動くのに本番で壊れる」** を減らすことが最重要です。Dockerを使うと:

- 開発者ごとの環境差分（OS, ライブラリ差）を吸収
- チームで同じ実行環境を共有
- テスト・CI・本番に同一イメージを展開しやすい
- 障害調査時に再現性が高い

つまりDockerは、単なる便利ツールではなく、**品質とスピードを同時に上げる土台**です。

---

## 3) Core Docker command explanations

- `docker run --name app -p 8080:80 nginx`
  - イメージからコンテナを起動。`-p` はホスト:コンテナのポート公開。
- `docker ps` / `docker ps -a`
  - 実行中 / 停止済み含むコンテナ一覧。
- `docker logs <container>`
  - 標準出力・標準エラーを確認。障害調査の第一歩。
- `docker exec -it <container> sh`
  - 稼働中コンテナに入って確認（本番では最小限に）。
- `docker build -t myapp:dev .`
  - Dockerfileからイメージ作成。
- `docker compose up -d`
  - 複数サービス（app, db, cache）をまとめて起動。
- `docker compose logs -f`
  - サービス横断でログ追跡。
- `docker image ls`, `docker volume ls`, `docker network ls`
  - リソースの可視化。

---

## 4) Building apps with Docker (docs.docker.com aligned)

Docker公式ベストプラクティスに沿うと、次が重要です。

1. **小さいベースイメージを選ぶ**（必要最小限）
2. **マルチステージビルド**でビルド依存を最終イメージから除外
3. **`.dockerignore`**で不要ファイルをビルドコンテキストから除外
4. **1コンテナ1責務**を意識（アプリとDBを分離）
5. **機密情報をイメージに焼き込まない**（`ENV SECRET=...`を避ける）
6. **非rootユーザー**で実行可能ならそうする
7. **タグ戦略**（`latest`固定に依存しない。`1.4.2`等の固定タグ併用）

開発中はComposeで依存サービスをまとめ、本番へは最終イメージを昇格させる流れが実践的です。

---

## 5) 30-60 minute hands-on mini lab

### 目標
Node.js API + Redis を Docker Compose で起動し、ログ確認と再ビルドまで体験。

### 所要時間
約45分

### 手順

1. 任意フォルダ作成
```bash
mkdir docker-mini-lab && cd docker-mini-lab
```

2. `app.js` を作成
```js
const http = require('http');
const port = process.env.PORT || 3000;
http.createServer((req, res) => {
  res.end('Docker mini lab OK\n');
}).listen(port, () => console.log(`listening on ${port}`));
```

3. `package.json` を作成
```json
{
  "name": "docker-mini-lab",
  "version": "1.0.0",
  "main": "app.js",
  "scripts": {
    "start": "node app.js"
  }
}
```

4. `Dockerfile` を作成
```dockerfile
FROM node:22-alpine
WORKDIR /app
COPY package.json ./
RUN npm install --omit=dev
COPY app.js ./
USER node
EXPOSE 3000
CMD ["npm", "start"]
```

5. `compose.yaml` を作成
```yaml
services:
  app:
    build: .
    ports:
      - "3000:3000"
    environment:
      - PORT=3000
    depends_on:
      - redis
  redis:
    image: redis:7-alpine
```

6. 起動
```bash
docker compose up -d --build
```

7. 動作確認
```bash
curl http://localhost:3000
```

8. ログ確認
```bash
docker compose logs -f app
```

9. 停止
```bash
docker compose down
```

### できたら追加挑戦（+15分）
- `.dockerignore` を追加して再ビルド速度を比較
- `docker image ls` でサイズ差を確認

---

## 6) Command cheatsheet

```bash
# コンテナ確認
docker ps
docker ps -a

# ログ
docker logs <container>
docker compose logs -f

# コンテナ内シェル
docker exec -it <container> sh

# ビルド・起動
docker build -t myapp:dev .
docker compose up -d --build

# 停止・削除（通常）
docker compose down

# リソース一覧
docker image ls
docker volume ls
docker network ls
```

---

## 7) Common mistakes and safe practices

### よくあるミス
- `COPY . .` で不要ファイル（`.git`, `node_modules`, 秘密情報）を含める
- `latest` タグだけ使って追跡不能になる
- 機密値をDockerfileやComposeに直書きする
- root前提でコンテナを動かす

### 安全運用のポイント
- `.dockerignore` を必ず整備
- シークレットは環境変数管理基盤 or secret機構で注入
- 本番イメージは軽量・最小権限・固定タグ
- 不要削除コマンドは影響を把握してから実行

⚠️ **破壊的コマンド注意（実行前に対象確認）**
- `docker system prune -a`
- `docker image rm ...` / `docker rmi ...`
- `docker rm -f ...`

これらは必要なリソースも削除し得ます。`docker ps -a`, `docker image ls`, `docker volume ls` で事前確認を徹底してください。

---

## 8) Interview-style question

**質問:**
「開発環境では動くのに本番で動かない問題を、Dockerfile設計と運用でどう予防しますか？」

**回答の観点（自己チェック用）:**
- ベースイメージ固定
- マルチステージビルド
- `.dockerignore`
- 非root実行
- シークレット管理
- CIでイメージ検証

---

## 9) Next-step resources (official docs preferred)

- Docker Docs Home: https://docs.docker.com/
- Get Started: https://docs.docker.com/get-started/
- Dockerfile Best Practices: https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Multi-stage Builds: https://docs.docker.com/build/building/multi-stage/
- BuildKit Overview: https://docs.docker.com/build/
- Compose Overview: https://docs.docker.com/compose/
- Compose File Reference: https://docs.docker.com/reference/compose-file/
- Docker Engine Security: https://docs.docker.com/engine/security/

---

次号予告: **「ボリューム・ネットワーク・ヘルスチェックを使った実運用寄りCompose設計」**（Beginner→Advancedで反復）
