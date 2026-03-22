---
tags: [docker, containers, devops, learning, daily]
---
# 2026-03-22 09:20 Docker Commands Magazine
[[Home]]

#docker #containers #devops #learning #daily

今日のテーマは **「コンテナ開発の基本操作から運用準備まで」**。  
難易度を **Beginner → Middle → Advanced** で段階的に進めます。

---

## 1) Topic + Level

### Beginner
**トピック:** イメージとコンテナの基本操作（`docker pull` / `docker run` / `docker ps` / `docker logs` / `docker exec`）

### Middle
**トピック:** Dockerfileでアプリをビルドして実行（`docker build` / `docker buildx` / `.dockerignore` / 非root実行）

**前提知識（Prerequisites）:**
- Beginnerのコマンドを理解している
- Linuxコマンドの基本（`cd`, `ls`, `cat`）
- 1つ以上のアプリ言語（Node/Python/Go等）を少し触ったことがある

### Advanced
**トピック:** Composeで開発環境を安全に組み立てる（`docker compose up/down/logs/exec`、ヘルスチェック、シークレット管理方針）

**前提知識（Prerequisites）:**
- Middleまでの内容を実践済み
- Dockerfileのレイヤー概念を理解している
- 環境変数と設定ファイルの役割を説明できる

---

## 2) Why it matters for real app development

- **環境差分を減らす:** 「自分のPCでは動く」を防ぎ、チーム開発で再現性を確保できる。
- **オンボーディングが速い:** 新メンバーが`docker compose up`で同じ環境を即再現できる。
- **CI/CDに直結:** Dockerイメージを使うことで、ローカル・CI・本番で同じ成果物を扱える。
- **運用の安全性向上:** 非root実行、最小ベースイメージ、不要ポート非公開などの原則でリスクを下げられる。

---

## 3) Core Docker command explanations

### `docker pull <image>`
レジストリ（Docker Hub等）からイメージを取得。まずは公式イメージを優先。

### `docker run [options] <image>`
イメージからコンテナを起動。
- `-d`: バックグラウンド実行
- `--name`: コンテナ名を指定
- `-p host:container`: ポート公開
- `--rm`: 停止後にコンテナ自動削除（開発時に便利）

### `docker ps` / `docker ps -a`
起動中 / 全コンテナの確認。

### `docker logs <container>`
ログ確認。障害切り分けの第一歩。

### `docker exec -it <container> sh`
起動中コンテナへ入って調査。`bash`がないイメージもあるため`sh`が無難。

### `docker build -t <name:tag> .`
Dockerfileからイメージを作成。

### `docker compose up -d`
複数サービス（アプリDB等）を一括起動。

### `docker compose down`
Composeで起動したリソースを停止・削除。

---

## 4) Building apps with Docker (docs.docker.com best practices aligned)

実務では以下を徹底すると品質が上がります。

1. **小さいベースイメージを選ぶ**（例: `alpine`やslim系、ただし互換性要確認）
2. **`.dockerignore`を適切に設定**（`node_modules`, `.git`, ローカル秘密情報を除外）
3. **レイヤーキャッシュを活かす**（依存関係コピー→インストール→アプリ本体コピー）
4. **非rootユーザーで実行**（`USER`命令で権限を下げる）
5. **イメージに秘密情報を焼き込まない**
   - NG: `ENV API_KEY=...` をDockerfileに直書き
   - 推奨: 実行時に環境注入、またはCompose secrets / 外部Secret Manager
6. **不要ポートを公開しない**（必要最小限）
7. **ヘルスチェックを入れる**（Composeやオーケストレータで自己回復しやすくする）

---

## 5) 30-60 minute hands-on mini lab

**ラボ名:** Node.js APIをDocker + Composeで起動して観察する（所要45分目安）

### Step A (10-15分): 最小API準備
1. 任意ディレクトリ作成
2. `server.js`（`/health`で200返却）を作成
3. `package.json`を作成

### Step B (15分): Dockerfile作成してビルド
例:
```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
USER node
EXPOSE 3000
CMD ["node", "server.js"]
```

ビルド・実行:
```bash
docker build -t myapi:dev .
docker run --rm -d --name myapi -p 3000:3000 myapi:dev
curl http://localhost:3000/health
docker logs myapi
```

### Step C (15分): Compose化
`compose.yaml`を作ってアプリを起動:
```yaml
services:
  app:
    image: myapi:dev
    ports:
      - "3000:3000"
    healthcheck:
      test: ["CMD", "wget", "-qO-", "http://localhost:3000/health"]
      interval: 10s
      timeout: 3s
      retries: 3
```

```bash
docker compose up -d
docker compose ps
docker compose logs -f app
```

### Step D (5分): 後片付け（安全確認つき）
```bash
docker compose down
```

> ⚠️ **注意（破壊的コマンド）**  
> `docker system prune`, `docker image prune -a`, `docker rm -f`, `docker rmi` は削除対象を必ず確認してから実行。  
> 共有環境や作業中コンテナがある状態での実行は避ける。

---

## 6) Command cheatsheet

```bash
# イメージ取得
docker pull nginx:latest

# コンテナ起動
docker run -d --name web -p 8080:80 nginx:latest

# 状態確認
docker ps
docker ps -a

# ログ確認
docker logs -f web

# コンテナに入る
docker exec -it web sh

# イメージビルド
docker build -t myapp:1.0 .

# Compose起動/停止
docker compose up -d
docker compose down

# 未使用リソース確認（削除前に一覧確認）
docker system df
```

---

## 7) Common mistakes and safe practices

### よくあるミス
- Dockerfileへ秘密情報を直書き
- `latest`タグ固定で再現性が崩れる
- 巨大なビルドコンテキスト（`.dockerignore`不足）
- rootユーザー実行のまま本番運用
- いきなり`prune -a`で必要イメージまで削除

### 安全プラクティス
- タグは明示（例: `myapp:2026-03-22`）
- 最小権限（非root、必要最小ポート）
- 削除前に確認（`docker ps -a`, `docker images`, `docker system df`）
- Secretsはイメージ外で管理（環境注入/secret管理機構）
- 公式ドキュメントに沿って定期的に設定見直し

---

## 8) One interview-style question

**質問:**  
「Dockerfileで`COPY . .`を先に実行するとビルド時間が伸びることがあります。なぜですか？ どのようにDockerレイヤーキャッシュを活用して改善しますか？」

---

## 9) Next-step resources (official Docker docs preferred)

- Docker Get Started  
  https://docs.docker.com/get-started/
- Dockerfile best practices  
  https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Building best practices  
  https://docs.docker.com/build/building/best-practices/
- Compose overview  
  https://docs.docker.com/compose/
- Compose file reference  
  https://docs.docker.com/reference/compose-file/
- Docker Engine security  
  https://docs.docker.com/engine/security/
- Manage sensitive data with Docker secrets  
  https://docs.docker.com/engine/swarm/secrets/

---

次回予告（学習アーク継続）:  
**Beginner:** ボリュームと永続化基礎 → **Middle:** マルチステージビルド → **Advanced:** CIでのキャッシュ戦略とイメージ署名検証
