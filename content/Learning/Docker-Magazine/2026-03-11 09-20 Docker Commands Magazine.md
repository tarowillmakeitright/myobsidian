---
tags: [docker, containers, devops, learning, daily]
---
[[Home]]

# Docker Commands Magazine — 2026-03-11 (09:20)

今日のテーマは、**Beginner → Middle → Advanced** の順で「イメージ作成から実運用に近い実行・デバッグ・クリーンアップ」までを一気通貫で学ぶ構成です。  
実務での再現性・安全性・保守性を重視しています。

---

## 1) Topic + Level

### 🟢 Beginner
**トピック:** `docker run` / `docker ps` / `docker logs` でコンテナ実行の基本を掴む

### 🟡 Middle
**トピック:** `docker build` / `.dockerignore` / タグ運用で開発用イメージを整える

**前提条件（Prerequisites）:**
- Beginner の内容（run / ps / logs）が使える
- Dockerfile の基本構文（`FROM`, `COPY`, `RUN`, `CMD`）を見たことがある

### 🔴 Advanced
**トピック:** `docker compose` + ヘルスチェック + 安全なクリーンアップ戦略（本番事故を防ぐ）

**前提条件（Prerequisites）:**
- Middle の内容（build とタグ、.dockerignore）を理解している
- 複数コンテナ（アプリ + DB）の構成イメージがある

---

## 2) なぜ重要か（実アプリ開発での意味）

- **再現可能な開発環境**を全員で共有できる（「自分のPCでは動く」問題を削減）
- **CI/CD との接続**が容易になる（build/test/deploy が同じイメージ基準）
- ログ・状態・ヘルスチェックを通じて、**障害時の初動が速くなる**
- 安全なクリーンアップ手順を持つことで、**誤削除・容量逼迫・停止事故**を防げる

---

## 3) コア Docker コマンド解説

### Beginner で使う
- `docker run --name web -p 8080:80 nginx:alpine`
  - イメージからコンテナを作成・起動
  - `--name`: 識別しやすい名前
  - `-p ホスト:コンテナ`: ポート公開
- `docker ps` / `docker ps -a`
  - 起動中 / 全コンテナの確認
- `docker logs -f web`
  - ログ追跡（`-f` は follow）
- `docker exec -it web sh`
  - 稼働中コンテナに入って調査

### Middle で使う
- `docker build -t myapp:dev .`
  - カレントディレクトリをビルドコンテキストにしてイメージ作成
- `docker images`
  - ローカルイメージ一覧
- `docker tag myapp:dev myapp:2026-03-11`
  - バージョン管理しやすいタグ付け
- `docker history myapp:dev`
  - レイヤ履歴確認（肥大化調査に有効）

### Advanced で使う
- `docker compose up -d`
  - 複数サービスをバックグラウンド起動
- `docker compose ps`
  - Compose 管理下の状態確認
- `docker compose logs -f app`
  - サービス単位でログ追跡
- `docker compose down`
  - 停止・ネットワーク削除（ボリューム削除有無はオプションで制御）

> ⚠️ 破壊的コマンド注意: `docker system prune`, `docker image prune`, `docker container rm -f`, `docker rmi` は削除対象を必ず確認してから実行。

---

## 4) アプリ開発時の使い方（docs.docker.com のベストプラクティス準拠）

- **最小ベースイメージ**を選ぶ（例: alpine/slim。ただし互換性とトレードオフを検証）
- **.dockerignore を必ず用意**し、不要ファイルをビルドコンテキストに入れない
- **レイヤキャッシュを意識**した Dockerfile 順序にする（依存解決→アプリコード）
- **1コンテナ1責務**を基本に、複数は Compose で連携
- **機密情報をイメージに焼かない**（`ENV` 直書き・`COPY .env` は避ける）
  - Secrets/環境変数注入は実行時に管理
- **非root実行**を検討し、不要権限を避ける
- **ヘルスチェック**を付けてオーケストレーション時の健全性判定を可能にする

---

## 5) 30〜60分ハンズオン・ミニラボ

**目標:** シンプルなWebアプリをビルドし、Compose で app + db を起動、ログ確認、最後に安全に片付ける。

### Step 0 (5分): 事前確認
```bash
docker version
docker compose version
```

### Step 1 (10分): サンプルアプリ作成
```bash
mkdir docker-mag-lab && cd docker-mag-lab
cat > app.py <<'PY'
from flask import Flask
app = Flask(__name__)

@app.get("/")
def home():
    return {"status": "ok", "message": "Hello Docker Magazine"}
PY

cat > requirements.txt <<'REQ'
flask==3.0.3
REQ
```

### Step 2 (10分): Dockerfile + .dockerignore
```bash
cat > Dockerfile <<'DOCKERFILE'
FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app.py .
EXPOSE 5000
CMD ["python", "-m", "flask", "--app", "app", "run", "--host=0.0.0.0", "--port=5000"]
DOCKERFILE

cat > .dockerignore <<'IGNORE'
.git
__pycache__
*.pyc
.env
IGNORE
```

### Step 3 (10分): ビルドと単体実行
```bash
docker build -t docker-mag-app:dev .
docker run --rm -d --name docker-mag-app -p 5000:5000 docker-mag-app:dev
curl http://localhost:5000
docker logs --tail=50 docker-mag-app
```

### Step 4 (10〜15分): Compose で app + db
```bash
cat > compose.yaml <<'YAML'
services:
  app:
    image: docker-mag-app:dev
    ports:
      - "5000:5000"
    healthcheck:
      test: ["CMD", "python", "-c", "import urllib.request; urllib.request.urlopen('http://localhost:5000')"]
      interval: 10s
      timeout: 3s
      retries: 3
    depends_on:
      db:
        condition: service_started

  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: appdb
      POSTGRES_USER: appuser
      POSTGRES_PASSWORD: change_me_in_real_env
    volumes:
      - pgdata:/var/lib/postgresql/data

volumes:
  pgdata:
YAML

docker compose up -d
docker compose ps
docker compose logs -f app
```

### Step 5 (5分): 安全な終了手順
```bash
docker compose down
# ボリューム削除は本当に不要な時のみ:
# docker compose down -v
```

---

## 6) コマンド・チートシート

```bash
# 実行・確認
docker run -d --name <name> -p 8080:80 <image>:<tag>
docker ps
docker logs -f <container>
docker exec -it <container> sh

# ビルド・イメージ
docker build -t <image>:<tag> .
docker images
docker tag <image>:<tag> <image>:<newtag>
docker history <image>:<tag>

# Compose
docker compose up -d
docker compose ps
docker compose logs -f <service>
docker compose down

# クリーンアップ（要注意）
docker image prune          # 未使用イメージ削除
# docker system prune -a    # 超注意: 未使用リソースを広範囲削除
```

---

## 7) よくあるミス & 安全運用

- **ミス:** `COPY . .` で `.env` や秘密鍵を混入  
  **対策:** `.dockerignore` に機密系を明示、Secrets は実行時注入

- **ミス:** `latest` タグ固定で挙動が日によって変わる  
  **対策:** 明示タグ（例: `1.2.3`, `2026-03-11`）で固定

- **ミス:** 不要に `--privileged` や root 実行  
  **対策:** 最小権限、必要時のみ権限追加

- **ミス:** `prune` を無確認で実行  
  **対策:** `docker ps -a`, `docker images`, `docker volume ls` で事前確認

- **ミス:** DB 永続化を考慮せず `down -v` でデータ消失  
  **対策:** ボリューム削除は「破棄合意後」に限定

---

## 8) 面接風質問（1問）

**Q.** 開発チームで Docker イメージのビルド時間が急増しました。`docs.docker.com` の推奨に沿って、まず何を確認し、どう改善しますか？

**期待したい回答の方向性:**
- ビルドコンテキスト肥大化（`.dockerignore`）
- Dockerfile のレイヤ順序最適化（キャッシュ活用）
- 依存とアプリコードのコピー分離
- ベースイメージ見直し（サイズ/互換性バランス）
- BuildKit の活用

---

## 9) 次の一歩（公式中心）

- Docker Docs Home  
  https://docs.docker.com/
- Get Started  
  https://docs.docker.com/get-started/
- Dockerfile Best Practices  
  https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Multi-stage Builds  
  https://docs.docker.com/build/building/multi-stage/
- Compose Overview  
  https://docs.docker.com/compose/
- Compose File Reference  
  https://docs.docker.com/compose/compose-file/
- Image Build (BuildKit)  
  https://docs.docker.com/build/
- Docker Engine Security  
  https://docs.docker.com/engine/security/

---

明日の予告（学習アーク継続）:  
**Beginner:** ボリューム基礎 / **Middle:** 開発時ホットリロード構成 / **Advanced:** マルチステージ + SBOM/脆弱性スキャン導線
