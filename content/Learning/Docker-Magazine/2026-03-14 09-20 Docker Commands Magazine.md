---
tags: [docker, containers, devops, learning, daily]
---
# Docker Commands Magazine (2026-03-14 09:20)
[[Home]]

#docker #containers #devops #learning #daily

## 今号のテーマ
**マルチステージビルドと実行最適化（Beginner → Middle → Advanced）**

---

## 1) Topic + Level

### 🟢 Beginner
**トピック:** `docker build` / `docker run` / `docker logs` で「動くコンテナ」を確実に作る

### 🟡 Middle（前提あり）
**トピック:** マルチステージビルドでイメージを小さく・安全にする
**前提:**
- `Dockerfile` の基本命令（`FROM`, `RUN`, `COPY`, `CMD`）
- `docker build -t ...` と `docker run ...` を実行できる
- `.dockerignore` の役割を理解している

### 🔴 Advanced（前提あり）
**トピック:** BuildKit キャッシュ最適化 + 非root実行 + ヘルスチェックまで含めた本番寄り運用
**前提:**
- マルチステージビルドを1回以上書いたことがある
- Linuxユーザー/権限の基本（UID/GID, root/non-root）
- CIで `docker build` を回した経験（個人開発でも可）

---

## 2) なぜ実アプリ開発で重要か

- **ビルド時間短縮**: 開発ループが速くなり、修正→検証回数が増える。
- **イメージ軽量化**: Pull/Pull時間、デプロイ時間、レジストリコストを削減。
- **攻撃面の縮小**: 不要なツール・依存を実行イメージに残さない。
- **再現性**: ローカル/CI/本番で同じ手順・同じ成果物を使える。

Docker公式の推奨（小さいベース、不要ファイル除外、最小権限、マルチステージ）に沿うと、開発速度と安全性を両立しやすい。

---

## 3) Core Docker command explanations

- `docker build -t myapp:dev .`
  - 現在ディレクトリをビルドコンテキストとしてイメージ作成。
  - `-t` で名前:タグを付与。

- `docker run --rm -p 8080:8080 myapp:dev`
  - コンテナ起動。`--rm` は終了後にコンテナを自動削除。
  - `-p` は `ホスト:コンテナ` のポート公開。

- `docker logs -f <container>`
  - 標準出力ログを追跡。動作確認・障害調査の基本。

- `docker exec -it <container> sh`
  - 実行中コンテナに入る。最小限に使い、恒久対策はDockerfileへ反映。

- `docker image ls` / `docker container ls -a`
  - イメージ・コンテナの在庫確認。

- `docker buildx build ...`
  - BuildKitベースの高度ビルド（キャッシュ、マルチアーキなど）。

---

## 4) アプリ構築時の使い方（docs.docker.com ベストプラクティス準拠）

1. **コンテキストを絞る**
   - `.dockerignore` で `node_modules`, `.git`, `.env`, テスト成果物を除外。
2. **依存解決レイヤーを先に固定**
   - `package*.json` だけ先に `COPY` → `npm ci` でキャッシュ効率化。
3. **マルチステージ化**
   - buildステージでコンパイル、runtimeステージは成果物のみ `COPY --from=build`。
4. **最小権限**
   - `USER nonroot`（または専用ユーザー作成）で実行。
5. **シークレットを焼き込まない**
   - `ENV SECRET=...` や `COPY .env` は避ける。実行時注入（環境変数/Secret機構）を使う。
6. **ヘルスチェックと終了シグナルを考慮**
   - `HEALTHCHECK` と適切な `CMD` で運用安定性を上げる。

---

## 5) 30〜60分ミニラボ

### ゴール
Node.jsサンプルAPIを**マルチステージ + 非root**で起動し、サイズ差と動作を確認する。

### 手順（目安45分）

#### Step 1: 雛形作成（10分）
```bash
mkdir docker-mag-lab && cd docker-mag-lab
npm init -y
npm i express
cat > server.js <<'EOF'
const express = require('express');
const app = express();
app.get('/health', (_, res) => res.send('ok'));
app.listen(8080, () => console.log('listening on 8080'));
EOF
```

#### Step 2: 非最適Dockerfile（比較用）を作る（5分）
```dockerfile
FROM node:22
WORKDIR /app
COPY . .
RUN npm install
EXPOSE 8080
CMD ["node", "server.js"]
```

```bash
docker build -t lab:naive .
docker image ls | grep 'lab\s\+naive'
```

#### Step 3: 最適化Dockerfileへ置換（20分）
```dockerfile
# syntax=docker/dockerfile:1
FROM node:22-alpine AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev

FROM node:22-alpine AS runtime
WORKDIR /app
RUN addgroup -S app && adduser -S app -G app
COPY --from=deps /app/node_modules ./node_modules
COPY server.js ./
USER app
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s CMD wget -qO- http://127.0.0.1:8080/health || exit 1
CMD ["node", "server.js"]
```

`.dockerignore`:
```gitignore
node_modules
npm-debug.log
.git
.env
```

```bash
docker build -t lab:optimized .
docker image ls | grep 'lab\s\+optimized'
```

#### Step 4: 実行確認（10分）
```bash
docker run --rm -p 8080:8080 --name labapp lab:optimized
# 別ターミナル
curl http://localhost:8080/health
docker logs -f labapp
```

### チェックポイント
- `lab:optimized` のサイズが `lab:naive` より小さい
- `/health` が `ok` を返す
- コンテナ内が非rootで動作

---

## 6) Command cheatsheet

```bash
# build
docker build -t myapp:dev .
docker build --no-cache -t myapp:clean .

# run / inspect
docker run --rm -p 8080:8080 myapp:dev
docker ps
docker ps -a
docker logs -f <container>
docker exec -it <container> sh

# image/container inventory
docker image ls
docker container ls -a

# cleanup（⚠注意して実行）
docker container rm <id>
docker image rm <image>
# 破壊的: 未使用リソースを広く削除
# docker system prune -a
```

---

## 7) よくあるミス & 安全な実践

### よくあるミス
- `COPY . .` を先に置いて毎回依存再インストールになる
- `.env` や秘密鍵をイメージに含める
- root実行のまま本番投入
- `latest` 固定運用で再現性が落ちる

### 安全な実践
- **秘密情報はイメージに保存しない**（Dockerfile/Composeに直書きしない）
- 可能な限り**タグ固定**（必要なら digest 固定）
- 最小ベース + 不要パッケージ削減
- 非rootユーザー実行
- Cleanupコマンドは対象確認してから実行

> ⚠ **破壊的コマンド注意**
> `docker system prune`, `docker image rm`, `docker rm -f` はデータ/リソースを消す可能性があります。実行前に `docker ps -a` / `docker image ls` で対象を確認し、必要ならバックアップしてください。

---

## 8) 面接風質問（1問）

**Q.** 「マルチステージビルドを使うと、なぜセキュリティとパフォーマンスの両方に効くのですか？」

**期待される要点:**
- ビルド専用ツールをランタイムから除外して攻撃面を減らせる
- イメージサイズが減り配布/起動が速くなる
- 不要ファイル排除で脆弱性スキャン対象が減る

---

## 9) 次の一歩（公式ドキュメント中心）

- Docker Docs Home
  - https://docs.docker.com/
- Build best practices
  - https://docs.docker.com/build/building/best-practices/
- Multi-stage builds
  - https://docs.docker.com/build/building/multi-stage/
- Build cache
  - https://docs.docker.com/build/cache/
- Dockerfile reference
  - https://docs.docker.com/reference/dockerfile/
- Compose file reference
  - https://docs.docker.com/reference/compose-file/
- Docker Scout（イメージセキュリティ）
  - https://docs.docker.com/scout/

---

### 明日の予告
次号は **「docker compose でローカル開発環境をチーム共通化する」**（依存サービス、ヘルスチェック連携、開発体験改善）を扱います。