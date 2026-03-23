---
tags: [docker, containers, devops, learning, daily]
created: 2026-03-23 09:20
---

# Docker Commands Magazine — 2026-03-23 (09:20)
#docker #containers #devops #learning #daily
[[Home]]

今日の学習アークは **Beginner → Middle → Advanced** の3段階です。実務での「安全に回る開発フロー」を意識して進めます。

---

## 1) Topic + Level

### Beginner（初級）
**テーマ:** コンテナの基本操作とログ確認（`docker run`, `docker ps`, `docker logs`, `docker exec`）

### Middle（中級）
**テーマ:** Dockerfileで再現可能な開発環境を作る（`docker build`, `docker tag`, `.dockerignore`）

**前提条件（Prerequisites）**
- Beginner内容を理解している
- Linux基本コマンド（`ls`, `cat`, `curl`）
- アプリ実行に必要な依存関係の概念（例: Node/Pythonのパッケージ）

### Advanced（上級）
**テーマ:** Composeで複数サービス運用 + 安全な設定（`docker compose up`, `docker compose logs`, ヘルスチェック、シークレット管理）

**前提条件（Prerequisites）**
- Middle内容を理解している
- Dockerfileのレイヤーとキャッシュの基本理解
- ネットワーク/環境変数/ボリュームの基礎

---

## 2) なぜ実アプリ開発で重要か

- **環境差異を潰せる**: 「自分のPCでは動く」問題を減らせる。
- **オンボーディングが速い**: 新メンバーが同じコンテナで即開発開始できる。
- **CI/CDと整合**: ローカルとCIで同じDockerfile/Composeを使うことで品質が安定。
- **障害調査が容易**: `logs` と `exec` で本番に近い形の再現・切り分けが可能。
- **セキュリティ/運用**: 最小イメージ、不要パッケージ削減、秘密情報の分離などがしやすい。

---

## 3) Core Docker command 解説

### `docker run`
コンテナを起動する。例:
```bash
docker run --name web -d -p 8080:80 nginx:alpine
```
- `--name`: コンテナ名
- `-d`: バックグラウンド実行
- `-p 8080:80`: ホスト8080 → コンテナ80

### `docker ps` / `docker ps -a`
実行中コンテナ/全コンテナを確認。

### `docker logs -f <container>`
ログを追跡。アプリの起動失敗や接続エラーの一次確認に必須。

### `docker exec -it <container> sh`
実行中コンテナへ入る。設定やファイルの状態確認に使う。

### `docker build -t <image:tag> .`
Dockerfileからイメージ作成。
- `-t` でタグ命名（例: `myapp:dev`）

### `docker compose up -d`
複数サービスをまとめて起動。

### `docker compose logs -f`
複数サービスログを横断確認。

---

## 4) 実装時のDocker活用（docs.docker.comベストプラクティス準拠）

1. **小さいベースイメージを選ぶ**（例: `alpine`系、用途に応じて公式イメージ）
2. **Dockerfileはレイヤーキャッシュを意識**
   - 依存インストールを先に、ソースコピーを後に
3. **`.dockerignore` を必ず使う**
   - `node_modules`, `.git`, ログ、秘密ファイルを除外
4. **1コンテナ1責務を基本**
   - アプリ、DB、キャッシュはComposeで分離
5. **設定は環境変数/シークレットで注入**
   - パスワードやAPIキーをDockerfileに直書きしない
6. **ヘルスチェックを定義**
   - 起動しただけでなく「利用可能」状態を確認
7. **最小権限原則**
   - 可能なら非rootユーザーで実行

---

## 5) 30〜60分ミニラボ（実践）

**ゴール:** Nginx + 簡易API（mock）をComposeで起動し、ログ確認とヘルスチェックまで実施

### 所要時間
- 45分目安

### 手順

1. 作業ディレクトリ作成（5分）
```bash
mkdir docker-mag-lab && cd docker-mag-lab
mkdir web api
```

2. Nginx用の静的ページ作成（5分）
```bash
echo '<h1>Hello Docker Magazine</h1>' > web/index.html
```

3. APIコンテナ（簡易）準備（10分）
`api/Dockerfile`:
```dockerfile
FROM python:3.12-alpine
WORKDIR /app
RUN pip install --no-cache-dir flask
COPY app.py .
CMD ["python", "app.py"]
```

`api/app.py`:
```python
from flask import Flask
app = Flask(__name__)

@app.get("/health")
def health():
    return {"status": "ok"}

@app.get("/")
def home():
    return {"message": "hello from api"}

app.run(host="0.0.0.0", port=5000)
```

4. `compose.yaml` 作成（10分）
```yaml
services:
  web:
    image: nginx:alpine
    ports:
      - "8080:80"
    volumes:
      - ./web/index.html:/usr/share/nginx/html/index.html:ro
    healthcheck:
      test: ["CMD-SHELL", "wget -q -O - http://localhost || exit 1"]
      interval: 10s
      timeout: 3s
      retries: 3

  api:
    build: ./api
    ports:
      - "5000:5000"
    healthcheck:
      test: ["CMD", "wget", "-q", "-O", "-", "http://localhost:5000/health"]
      interval: 10s
      timeout: 3s
      retries: 3
```

5. 起動・確認（10分）
```bash
docker compose up -d --build
docker compose ps
curl http://localhost:8080
curl http://localhost:5000/health
docker compose logs -f --tail=50
```

6. 後片付け（5分）
```bash
docker compose down
```

> 注意: `down` はコンテナ/ネットワークを停止・削除します。名前付きボリュームを消す場合は `-v` を付けますが、データ消失に注意。

---

## 6) Command Cheatsheet

```bash
# コンテナ起動
docker run --name sample -d -p 8080:80 nginx:alpine

# 状態確認
docker ps
docker ps -a

# ログ確認
docker logs -f sample

# コンテナ内に入る
docker exec -it sample sh

# イメージビルド
docker build -t myapp:dev .

# Compose起動/停止
docker compose up -d --build
docker compose ps
docker compose logs -f
docker compose down
```

---

## 7) よくあるミス & 安全運用

### よくあるミス
- Dockerfileに `.env` や秘密鍵を `COPY` してしまう
- `latest` タグ固定で再現性が落ちる
- 不要ファイルをビルドコンテキストに含め、ビルドが遅い
- コンテナをrootのまま運用

### 安全運用（重要）
- **秘密情報はイメージに焼き込まない**
  - Dockerfile/Composeに平文シークレットを書かない
  - シークレット管理機能や環境注入を使う
- **破壊的コマンドは必ず影響範囲確認**
  - `docker system prune`, `docker image prune -a`, `docker rm -f`, `docker rmi` は削除対象を要確認
  - 実行前に `docker ps -a`, `docker images`, `docker volume ls` で確認する
- **本番相当ではread-onlyマウントを優先**（必要箇所のみwrite）
- **公式イメージと公式ドキュメントを優先**

---

## 8) 面接風質問（Interview-style）

**質問:**
「開発環境で `docker compose up` は成功するのに、CIで同じ構成が失敗します。あなたならどの順序で原因を切り分けますか？」

**期待される観点（簡易）:**
- イメージタグ固定・依存バージョン差異
- `.env` やCI変数の注入差
- ヘルスチェック待ち不足（依存サービス起動順）
- キャッシュ差異（`--no-cache` で再ビルド）
- 権限/ファイルパス/改行コード差

---

## 9) 次の学習リソース（公式優先）

- Docker Docs Home: https://docs.docker.com/
- Get Started: https://docs.docker.com/get-started/
- Dockerfile Best Practices: https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Multi-stage Builds: https://docs.docker.com/build/building/multi-stage/
- Compose Overview: https://docs.docker.com/compose/
- Compose File Reference: https://docs.docker.com/reference/compose-file/
- Build cache / BuildKit: https://docs.docker.com/build/cache/
- Docker Scout (image security): https://docs.docker.com/scout/
- Secrets (Compose/Swarm関連): https://docs.docker.com/engine/swarm/secrets/

---

### 明日の予告（学習アーク継続）
次回は「イメージ最適化と脆弱性対応（Beginner→Advanced）」として、multi-stage build と scanワークフローに進みます。
