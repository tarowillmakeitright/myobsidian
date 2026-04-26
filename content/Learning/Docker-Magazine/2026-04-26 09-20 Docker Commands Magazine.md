---
tags: [docker, containers, devops, learning, daily]
---

# Docker Commands Magazine — 2026-04-26 09:20
[[Home]]

> 今日のテーマは「実務で使うDockerコマンド」を、**Beginner → Middle → Advanced** の順で段階的に学ぶ構成です。  
> 目標: ただコマンドを覚えるだけでなく、**安全に・再現性高く・チームで運用できる**使い方を身につける。

---

## 1) Topic + Level

### 🟢 Beginner
**Topic:** `docker run` / `docker ps` / `docker logs` で「コンテナを起動して観察する」

### 🟡 Middle
**Topic:** `docker build` / `docker exec` / `docker compose up` で「開発環境をチーム共有する」

**前提知識（Prerequisites）**
- Beginner編の内容（起動・一覧・ログ確認）
- Linuxの基本コマンド（`cd`, `ls`, `cat` など）
- アプリの起動コマンドを1つ説明できる（例: `npm start`, `python app.py`）

### 🔴 Advanced
**Topic:** `multi-stage build` / `build cache` / `healthcheck` / `least privilege` で「本番品質に近づける」

**前提知識（Prerequisites）**
- Middle編の内容（Dockerfile作成、Compose運用）
- イメージレイヤー概念の基本理解
- CI/CDでコンテナを使うイメージがあること

---

## 2) Why it matters for real app development

- **環境差分の削減:** 「自分のPCでは動く」を減らし、レビュー/検証/本番まで同じ基盤で動かせる。
- **オンボーディング高速化:** 新メンバーが `docker compose up` で早く開発開始できる。
- **障害解析がしやすい:** `logs`, `exec`, `inspect` で稼働中の実態を追える。
- **セキュリティと再現性:** 軽量イメージ、非root実行、秘密情報の分離などが設計段階で扱える。

---

## 3) Core Docker command explanations

### Beginnerコア
- `docker run -d --name web -p 8080:80 nginx:alpine`
  - `-d`: バックグラウンド実行
  - `--name`: コンテナ名を固定
  - `-p 8080:80`: ホスト8080 → コンテナ80
- `docker ps` / `docker ps -a`
  - 稼働中 / 全コンテナを確認
- `docker logs -f web`
  - `-f` でログを追尾
- `docker stop web && docker rm web`
  - 停止後に削除（安全な順序）

### Middleコア
- `docker build -t myapp:dev .`
  - Dockerfileからイメージ作成
- `docker exec -it myapp sh`
  - 稼働中コンテナに入って調査
- `docker compose up -d`
  - 複数サービスを一括起動
- `docker compose logs -f app`
  - サービス単位でログ確認
- `docker compose down`
  - Composeスタックを停止/削除

### Advancedコア
- `docker build --target runtime -t myapp:prod .`
  - multi-stageの最終ターゲットのみを生成
- `docker image inspect myapp:prod`
  - イメージ情報（サイズ、設定）確認
- `docker container inspect app`
  - ヘルス状態、ネットワーク、マウントを詳細確認
- `docker stats`
  - CPU/メモリ監視

---

## 4) How Docker is used while building apps (docs.docker.comベストプラクティス準拠)

- **小さなベースイメージを選ぶ**（例: `alpine`, `slim`）
- **マルチステージビルド**でビルド依存物を最終イメージに含めない
- **`.dockerignore` を適切に設定**して不要ファイルを送らない
- **レイヤーキャッシュ最適化**
  - 依存関係インストールを先に分離（`package*.json` → `npm ci` → ソースcopy）
- **コンテナを非rootで実行**（`USER` 指定）
- **秘密情報をイメージに焼き込まない**
  - `ENV API_KEY=...` をDockerfileに書かない
  - Composeの`environment`に平文直書きしない（`.env` + シークレット管理を使う）
- **1コンテナ1責務を基本にComposeで統合**

---

## 5) 30-60 minute hands-on mini lab

### Lab: 「Node API + Redis」をComposeで起動し、ログとヘルスを確認

**所要時間:** 45分目安

1. 作業ディレクトリ作成
```bash
mkdir docker-mag-lab && cd docker-mag-lab
```

2. `docker-compose.yml` 作成
```yaml
services:
  app:
    image: node:20-alpine
    working_dir: /app
    command: sh -c "npm init -y && npm i express redis && node server.js"
    volumes:
      - ./:/app
    ports:
      - "3000:3000"
    depends_on:
      - redis

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
```

3. `server.js` 作成
```js
const express = require('express');
const redis = require('redis');

const app = express();
const client = redis.createClient({ url: 'redis://redis:6379' });

(async () => {
  await client.connect();
})();

app.get('/', async (_req, res) => {
  const n = await client.incr('hits');
  res.send(`hello docker! hits=${n}`);
});

app.listen(3000, () => console.log('listening on 3000'));
```

4. 起動と確認
```bash
docker compose up -d
docker compose ps
docker compose logs -f app
```

5. 動作確認
```bash
curl http://localhost:3000
curl http://localhost:3000
```

6. 後片付け
```bash
docker compose down
```

**発展課題（Advanced）**
- `Dockerfile` を作って `app` を自前ビルドに変更
- `USER node` を使って非root実行化
- `HEALTHCHECK` を追加

---

## 6) Command cheatsheet

```bash
# コンテナ起動/停止/削除
docker run -d --name web -p 8080:80 nginx:alpine
docker ps
docker logs -f web
docker stop web
docker rm web

# イメージ操作
docker build -t myapp:dev .
docker images
docker image inspect myapp:dev

# コンテナ内デバッグ
docker exec -it <container> sh
docker inspect <container>
docker stats

# Compose
docker compose up -d
docker compose ps
docker compose logs -f
docker compose down
```

---

## 7) Common mistakes and safe practices

### よくあるミス
- `latest` タグ固定で再現性を失う
- Dockerfileに秘密情報を直書き
- root実行のまま本番運用
- `COPY . .` を先にしてキャッシュ効率を落とす
- 無差別なクリーンアップで必要なイメージ/ボリュームを消す

### 安全運用ポイント
- タグは明示（例: `node:20.12-alpine`）
- `.dockerignore` と最小権限を徹底
- シークレットは外部管理（環境変数注入やsecret機構）
- 破壊的コマンド前に `docker ps -a`, `docker images`, `docker volume ls` で確認

⚠️ **破壊的コマンド注意**
- `docker system prune -a`
- `docker image rm ...`
- `docker rm -f ...`

これらは復元不能な削除につながる。実行前に対象を必ず確認し、共有環境では合意を取る。

---

## 8) Interview-style question

**Q.** 開発環境でComposeを使うとき、`depends_on` だけでは不十分なケースがあるのはなぜ？どう補う？

**A.（考えるポイント）**
- `depends_on` は「起動順」を保証するが「アプリが利用可能な状態」を保証しない。
- DB/Redisの準備完了を待つには、ヘルスチェック・リトライ実装・waitスクリプトなどを組み合わせる。

---

## 9) Next-step resources (公式優先)

- Docker Docs Home: https://docs.docker.com/
- Get Started: https://docs.docker.com/get-started/
- Dockerfile best practices: https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Multi-stage builds: https://docs.docker.com/build/building/multi-stage/
- Compose overview: https://docs.docker.com/compose/
- Compose file reference: https://docs.docker.com/compose/compose-file/
- Docker Engine security: https://docs.docker.com/engine/security/
- Build cache: https://docs.docker.com/build/cache/

---

次号予告: **「ネットワークとボリュームを実務視点で理解する（Beginner→Advanced）」**