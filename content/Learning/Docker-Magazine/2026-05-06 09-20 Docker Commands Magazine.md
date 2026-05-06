# 2026-05-06 09-20 Docker Commands Magazine

Tags: #docker #containers #devops #learning #daily  
Links: [[Home]]

---

## 今号のテーマ
**Docker イメージ最適化とマルチステージビルド（Beginner → Middle → Advanced 学習アーク）**

---

## Beginner

### 1) Topic + Level
**Level: Beginner**  
**Topic:** `docker build` / `docker run` の基本と、開発向け Node.js コンテナを作る

### 2) なぜ実務で重要？
- 開発環境差分（OS/ライブラリ違い）で動かない問題を減らせる
- チーム全員が同じ実行環境を使える
- CI/CD のベースとなるため、最初に押さえる価値が高い

### 3) コア Docker コマンド解説
- `docker build -t myapp:dev .`  
  カレントディレクトリの Dockerfile からイメージ作成
- `docker run --rm -p 3000:3000 myapp:dev`  
  一時コンテナとして実行、終了時に自動削除
- `docker ps` / `docker ps -a`  
  稼働中 / 全コンテナ一覧
- `docker logs <container>`  
  アプリログ確認

### 4) アプリ開発での使い方（Docker公式ベストプラクティス準拠）
- **最小限のベースイメージ**を選ぶ（例: `node:20-alpine`）
- `.dockerignore` を必ず用意し、`node_modules` や `.git` を除外
- レイヤーキャッシュ活用のため `package*.json` を先にコピーして `npm ci`

### 5) 30-60分ミニラボ
1. 作業ディレクトリ作成
2. 以下 Dockerfile を作成

```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev
COPY . .
EXPOSE 3000
CMD ["node", "server.js"]
```

3. `.dockerignore` 作成

```gitignore
node_modules
.git
npm-debug.log
Dockerfile*
```

4. ビルド・起動

```bash
docker build -t myapp:dev .
docker run --rm -p 3000:3000 myapp:dev
```

5. ブラウザで `http://localhost:3000` 確認

### 6) Command Cheatsheet
```bash
docker build -t myapp:dev .
docker run --rm -p 3000:3000 myapp:dev
docker ps
docker logs <container>
docker stop <container>
```

### 7) よくあるミス & 安全策
- ミス: `COPY . .` を早く実行してキャッシュ効率が悪化
  - 安全策: 依存ファイルコピー → install → ソースコピーの順
- ミス: ローカル秘密情報（`.env`）をそのままイメージへコピー
  - 安全策: `.dockerignore` で除外、機密は実行時注入

### 8) 面接風質問
**Q:** `docker run --rm` を開発で使うメリットは？  
**A（要点）:** 不要な停止済みコンテナを残さず、作業環境をクリーンに保てる。

### 9) 次の一歩（公式）
- Dockerfile ベストプラクティス: https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Node.js 言語ガイド: https://docs.docker.com/language/nodejs/

---

## Middle

### 1) Topic + Level
**Level: Middle**  
**Prerequisites:** Beginner内容（build/run/logs/.dockerignore）を理解していること  
**Topic:** マルチステージビルドでサイズ削減・セキュリティ改善

### 2) なぜ実務で重要？
- 本番イメージを小さくし、デプロイ・スキャン時間を短縮
- ビルドツールや不要ファイルを本番イメージへ持ち込まない
- 攻撃面を減らす（不要バイナリ/パッケージ削減）

### 3) コア Docker コマンド解説
- `docker image ls`  
  イメージサイズ比較
- `docker history <image>`  
  レイヤー肥大化原因の可視化
- `docker build --target build -t myapp:build .`  
  中間ステージまでビルドして検証

### 4) アプリ開発での使い方（公式ベストプラクティス）
- ビルドステージとランタイムステージを分離
- 実行ユーザーを root 以外にする
- 必要最小限ファイルのみ最終ステージへ `COPY --from=`

### 5) 30-60分ミニラボ
1. 次の Dockerfile に変更

```dockerfile
# build stage
FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# runtime stage
FROM node:20-alpine
WORKDIR /app
ENV NODE_ENV=production
RUN addgroup -S app && adduser -S app -G app
COPY --from=build /app/dist ./dist
COPY --from=build /app/package*.json ./
RUN npm ci --omit=dev && npm cache clean --force
USER app
EXPOSE 3000
CMD ["node", "dist/server.js"]
```

2. ビルドと比較

```bash
docker build -t myapp:multi .
docker image ls | grep myapp
docker history myapp:multi
```

3. 中間ステージ検証

```bash
docker build --target build -t myapp:build-stage .
```

### 6) Command Cheatsheet
```bash
docker build -t myapp:multi .
docker build --target build -t myapp:build-stage .
docker image ls
docker history myapp:multi
docker run --rm -p 3000:3000 myapp:multi
```

### 7) よくあるミス & 安全策
- ミス: 本番イメージに `.env` や秘密鍵をコピー
  - 安全策: シークレットは Docker secrets / 環境変数 / 外部Secret Managerで管理
- ミス: root 実行のまま本番投入
  - 安全策: `USER` 指定で非root化

### 8) 面接風質問
**Q:** マルチステージビルドがセキュリティに効く理由は？  
**A（要点）:** 本番に不要なビルドツールやソース断片を含めず、攻撃面・脆弱性対象を減らせる。

### 9) 次の一歩（公式）
- Multi-stage builds: https://docs.docker.com/build/building/multi-stage/
- Build best practices: https://docs.docker.com/develop/develop-images/dockerfile_best-practices/

---

## Advanced

### 1) Topic + Level
**Level: Advanced**  
**Prerequisites:** Middle内容（multi-stage, image/histroy比較, non-root運用）を実践済み  
**Topic:** BuildKit キャッシュ・SBOM/スキャン・安全なクリーンアップ運用

### 2) なぜ実務で重要？
- CI時間短縮（キャッシュ最適化）
- サプライチェーン可視化（SBOM）
- 運用コスト削減と事故防止（安全な掃除手順）

### 3) コア Docker コマンド解説
- `docker buildx build ...`  
  BuildKit機能を使った高度ビルド
- `docker scout quickview <image>`（環境により利用可）  
  脆弱性/ベース更新状況の確認
- `docker system df`  
  ディスク使用量確認

### 4) アプリ開発での使い方（公式ベストプラクティス）
- BuildKit のキャッシュマウントを活用し依存インストール高速化
- イメージを定期的に再ビルドして脆弱性修正を取り込む
- 破壊的クリーンアップは「対象を確認 → 範囲限定」で実行

### 5) 30-60分ミニラボ
1. BuildKit有効化（シェル）

```bash
export DOCKER_BUILDKIT=1
```

2. Dockerfileの `RUN npm ci` をキャッシュ対応に変更（例）

```dockerfile
RUN --mount=type=cache,target=/root/.npm npm ci --omit=dev
```

3. ビルド時間比較（2回実行）

```bash
time docker build -t myapp:bk .
time docker build -t myapp:bk .
```

4. 使用量確認と安全なクリーンアップ計画

```bash
docker system df
docker image ls
docker container ls -a
```

5. 必要なら限定削除

```bash
docker image rm myapp:oldtag
```

### 6) Command Cheatsheet
```bash
export DOCKER_BUILDKIT=1
docker buildx ls
docker build -t myapp:bk .
docker system df
docker image rm <image:tag>
```

### 7) よくあるミス & 安全策
- ⚠️ `docker system prune -a` を無確認で実行
  - リスク: 停止中コンテナ/未使用イメージ/ネットワーク/ビルドキャッシュを広範囲削除
  - 安全策: 先に `docker system df` と `docker image ls` で対象確認、必要なら個別削除優先
- ⚠️ `docker rm -f` / `docker rmi -f` の乱用
  - リスク: 強制停止・依存崩壊・復旧工数増
  - 安全策: 依存関係を確認して通常停止・通常削除を優先
- 機密情報を Dockerfile `ARG` / `ENV` に直書き
  - 安全策: シークレットはイメージに焼き込まない（実行時注入）

### 8) 面接風質問
**Q:** `docker system prune -a` を本番系ホストで避けるべき理由と、代替手順は？  
**A（要点）:** 影響範囲が広く想定外削除を招くため。`docker system df` で可視化し、不要対象を `docker image rm` などで段階的に削除する。

### 9) 次の一歩（公式）
- Build cache: https://docs.docker.com/build/cache/
- BuildKit: https://docs.docker.com/build/buildkit/
- Image vulnerabilities / Docker Scout: https://docs.docker.com/scout/
- Prune reference: https://docs.docker.com/engine/manage-resources/pruning/

---

## 明日の予告
次号は「Docker Compose による開発環境の分離（DB/Redis/API の連携）」を予定。Beginner→Middle→Advanced で継続します。