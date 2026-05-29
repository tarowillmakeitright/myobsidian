---
tags: [docker, containers, devops, learning, daily]
---

# 2026-05-29 09:20 Docker Commands Magazine
[[Home]]

#docker #containers #devops #learning #daily

## 今号のテーマ
**Dockerコマンド実践アーク：Beginner → Middle → Advanced**  
アプリ開発の現場で「作る・動かす・直す・安全に運用する」までを段階的に学ぶ号です。

---

## 1) Topic + Level

### 🟢 Beginner
**Topic:** `docker run` / `docker ps` / `docker logs` で「まずはコンテナを触る」

### 🟡 Middle
**Topic:** `Dockerfile` + `docker build` + `docker compose up` で開発環境を組む  
**前提知識:**
- `docker run` で単一コンテナを起動できる
- `docker ps`, `docker logs`, `docker stop` の基本操作ができる
- Linuxの基本コマンド（`cd`, `ls`, `cat`）が分かる

### 🔴 Advanced
**Topic:** マルチステージビルド + キャッシュ最適化 + セキュアなイメージ運用  
**前提知識:**
- Dockerfileの基本命令（`FROM`, `WORKDIR`, `COPY`, `RUN`, `CMD`）を理解
- Composeで複数サービスを起動した経験がある
- 依存関係とビルドキャッシュの概念が分かる

---

## 2) なぜ実アプリ開発で重要か
- **環境差分の削減**: 「自分のPCでは動く」問題を減らす
- **オンボーディング高速化**: 新メンバーが`compose up`で素早く参加可能
- **CI/CDと親和性**: ローカルと同じ手順をCIに載せやすい
- **セキュリティ品質向上**: 最小イメージ・不要ツール排除・秘密情報分離でリスク低減

---

## 3) Core Docker command explanations

### `docker run`
- イメージからコンテナを起動
- 例: `docker run --name web -p 8080:80 -d nginx`
- 主要オプション:
  - `--name`: 名前を付ける
  - `-p host:container`: ポート公開
  - `-d`: バックグラウンド実行

### `docker ps` / `docker ps -a`
- 起動中（`-a`で停止済み含む）コンテナ一覧

### `docker logs -f <container>`
- ログ確認（`-f`は追従）

### `docker exec -it <container> sh`
- 実行中コンテナに入って調査

### `docker build -t <name:tag> .`
- Dockerfileからイメージ作成

### `docker compose up -d` / `down`
- 複数サービスをまとめて起動・停止

### `docker image ls`, `docker container ls`, `docker volume ls`
- リソースの可視化（肥大化や孤児リソース検知に有効）

---

## 4) アプリ開発での使い方（docs.docker.com準拠の実践）
- **小さく保つ**: ベースイメージは必要最小限（例: slim/alpine系を検討）
- **レイヤー効率化**: 変更頻度の低いファイルを先に`COPY`してビルドキャッシュ活用
- **1コンテナ1責務を意識**: Web/API/DBをComposeで分離
- **設定は外出し**: 環境変数や`.env`で注入（ただし秘密情報は平文コミットしない）
- **秘密情報をイメージに焼き込まない**: `COPY . .`前に`.dockerignore`設定、シークレットを含めない
- **再現可能な開発環境**: `compose.yaml`をチーム標準として管理

---

## 5) 30-60分ハンズオン mini lab

### 目的
Node.js API + RedisをComposeで起動し、ログ確認と再ビルドを体験する

### 所要時間
45分目安

### 手順
1. 作業ディレクトリ作成
```bash
mkdir docker-mag-lab && cd docker-mag-lab
```

2. `app.js` を作成
```js
const express = require('express');
const redis = require('redis');

const app = express();
const client = redis.createClient({ url: 'redis://redis:6379' });
client.connect();

app.get('/', async (_, res) => {
  const count = await client.incr('hits');
  res.send(`Hello Docker! hits=${count}`);
});

app.listen(3000, () => console.log('app listening on 3000'));
```

3. `package.json` 作成
```json
{
  "name": "docker-mag-lab",
  "version": "1.0.0",
  "main": "app.js",
  "scripts": { "start": "node app.js" },
  "dependencies": {
    "express": "^4.19.2",
    "redis": "^4.6.15"
  }
}
```

4. `Dockerfile`
```dockerfile
FROM node:22-slim
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
```

5. `compose.yaml`
```yaml
services:
  app:
    build: .
    ports:
      - "3000:3000"
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
curl http://localhost:3000
```

8. ログ確認
```bash
docker compose logs -f app
```

9. 終了
```bash
docker compose down
```

### チャレンジ（余力があれば）
- `healthcheck` を `app` に追加
- `volumes` で開発時ホットリロード構成を検討

---

## 6) Command cheatsheet
```bash
# コンテナ起動
docker run --name web -p 8080:80 -d nginx

# 一覧確認
docker ps
docker ps -a

# ログ追跡
docker logs -f web

# コンテナ内に入る
docker exec -it web sh

# イメージビルド
docker build -t myapp:dev .

# Compose起動/停止
docker compose up -d
docker compose down

# リソース確認
docker image ls
docker volume ls
docker network ls
```

---

## 7) よくあるミス & 安全な運用

### よくあるミス
- `latest`タグ固定で、いつのイメージか追えない
- `COPY . .`で不要ファイル（`.env`, `.git`など）まで入れる
- コンテナをroot前提で動かす
- ローカル秘密情報をそのままComposeに直書きする

### 安全策
- イメージタグは明示（例: `myapp:2026-05-29`）
- `.dockerignore`を必ず設定
- 必要なら非rootユーザーで実行
- secretsはイメージ/リポジトリに含めない（環境注入・シークレット管理を利用）

### ⚠️ 破壊的コマンド注意
以下は削除系で影響が大きいです。実行前に対象確認を徹底してください。
- `docker system prune`
- `docker image prune -a`
- `docker rmi ...`
- `docker rm -f ...`

実行前チェック例:
```bash
docker ps -a
docker image ls
docker volume ls
```

---

## 8) Interview-style question
**Q.** 開発チームでDockerビルドが遅いです。Dockerfileのどこを見直し、なぜそれで速くなるか説明してください。  
（ヒント: レイヤーキャッシュ、`COPY`順序、依存関係インストールの分離）

---

## 9) Next-step resources（公式優先）
- Docker Docs Home: https://docs.docker.com/
- Get Started: https://docs.docker.com/get-started/
- Dockerfile best practices: https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Compose overview: https://docs.docker.com/compose/
- Multi-stage builds: https://docs.docker.com/build/building/multi-stage/
- Build cache: https://docs.docker.com/build/cache/
- Docker Engine security: https://docs.docker.com/engine/security/

---

次号予告（学習アーク継続）:  
**Beginner:** ボリューム基礎  
**Middle:** 開発用Compose最適化（profiles/override）  
**Advanced:** BuildKitとSBOM/イメージ署名の実務導入
