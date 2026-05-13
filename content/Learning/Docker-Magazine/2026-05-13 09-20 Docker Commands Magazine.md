# 2026-05-13 09-20 Docker Commands Magazine

#docker #containers #devops #learning #daily  
[[Home]]

---

## 今日のテーマ
**DockerネットワークとComposeでの安全なローカル開発フロー**

---

## 1) Topic + Level

### 🟢 Beginner
**トピック:** コンテナ起動・停止・ログ確認の基本（`docker run`, `docker ps`, `docker logs`, `docker stop`）

### 🟡 Middle
**トピック:** Composeで複数サービス（App + DB）をつなぐ（`docker compose up`, `docker compose exec`, `docker compose down`）  
**前提条件:**
- Beginnerのコマンドが使える
- イメージ・コンテナの違いを説明できる
- ポート公開（`-p`）の意味を理解している

### 🔴 Advanced
**トピック:** セキュアなビルドと運用（マルチステージ、非root、ヘルスチェック、不要データの安全なクリーンアップ）  
**前提条件:**
- MiddleのCompose運用ができる
- `Dockerfile`の基本命令（`FROM`, `RUN`, `COPY`, `CMD`）を理解
- ボリュームとネットワークの役割を説明できる

---

## 2) Why it matters for real app development
- 開発では「アプリ単体」ではなく、DB・キャッシュ・ワーカーなど**複数プロセス連携**が前提。
- Docker/Composeを使うと、チーム全員が同じ実行環境を再現でき、**環境差分バグ**を減らせる。
- セキュアな設定（非root・秘密情報の分離）を早期から習慣化すると、開発→本番移行時の事故を防げる。

---

## 3) Core Docker command explanations
- `docker run --name app -p 8080:8080 IMAGE`
  - 新しいコンテナを起動。`--name`で識別名、`-p`でホスト:コンテナのポート公開。
- `docker ps` / `docker ps -a`
  - 起動中 / 全コンテナ一覧を確認。
- `docker logs -f CONTAINER`
  - ログを追跡。`-f`でtail的に監視。
- `docker exec -it CONTAINER sh`
  - 起動中コンテナ内でシェル実行。
- `docker compose up -d`
  - `compose.yml`のサービス群をバックグラウンド起動。
- `docker compose exec SERVICE sh`
  - Compose管理下のサービスコンテナに入る。
- `docker compose down`
  - サービス停止とネットワーク削除（ボリューム削除は`-v`指定時のみ）。

---

## 4) How Docker is used while building apps (docs.docker.com aligned)
Docker公式のベストプラクティスに沿うと、次の流れが実務的です。

1. **開発環境をComposeで定義**
   - `app`, `db`などの依存関係を`compose.yml`に明示。
2. **Dockerfileは小さく安全に**
   - マルチステージビルドで最終イメージを軽量化。
   - 可能なら非rootユーザーで実行。
3. **秘密情報をイメージへ焼き込まない**
   - `ENV PASSWORD=...`のような固定値埋め込みは避ける。
   - `.env`やシークレット管理機構を使用。
4. **不要なキャッシュ・資源を定期整理**
   - ただし`prune`系は影響範囲確認後に実行。

---

## 5) 30-60 minute hands-on mini lab
**目標:** App + DBのローカル開発環境をComposeで立て、ログ・接続確認まで行う。

### Step A (10-15分)
`compose.yml`を作成（例: `app` + `postgres`）。

```yaml
services:
  app:
    image: node:22-alpine
    working_dir: /app
    volumes:
      - ./:/app
    command: sh -c "node -e 'console.log(\"app up\")' && sleep infinity"
    ports:
      - "3000:3000"
    depends_on:
      - db

  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: appuser
      POSTGRES_PASSWORD: change_me_local_only
      POSTGRES_DB: appdb
    volumes:
      - db_data:/var/lib/postgresql/data

volumes:
  db_data:
```

### Step B (10-15分)
起動・状態確認
```bash
docker compose up -d
docker compose ps
docker compose logs -f db
```

### Step C (10-15分)
Appコンテナに入って疎通確認
```bash
docker compose exec app sh
# コンテナ内で
echo "inside app container"
exit
```

### Step D (10-15分)
停止と後片付け
```bash
docker compose down
```
必要ならボリュームも削除:
```bash
# 注意: DBデータが消えます
docker compose down -v
```

---

## 6) Command cheatsheet
```bash
# 基本
docker ps
docker ps -a
docker logs -f <container>
docker exec -it <container> sh

# Compose
docker compose up -d
docker compose ps
docker compose logs -f <service>
docker compose exec <service> sh
docker compose down

# イメージ/資源確認
docker images
docker system df
```

---

## 7) Common mistakes and safe practices

### よくあるミス
- `latest`タグ前提で再現性が崩れる
- 秘密情報（APIキー・DBパスワード）をDockerfile/compose.ymlに直書きしてGit管理
- `docker system prune -a`を意味を理解せず実行
- `docker rm -f` / `docker rmi`で必要資源を誤削除

### 安全プラクティス
- イメージタグは固定（例: `postgres:16-alpine`）
- `.env`やシークレット管理を使い、秘密情報をイメージに含めない
- 削除系コマンド前に対象確認:
  - `docker ps -a`
  - `docker images`
  - `docker volume ls`
- **破壊的コマンドの注意喚起**
  - `docker system prune`, `docker image prune`, `docker container prune`, `docker volume prune`, `docker network prune`
  - `docker rm -f`, `docker rmi`
  - これらは復元困難な削除を伴うため、実行前に必ず影響範囲を確認。

---

## 8) Interview-style question
「`docker compose down` と `docker compose down -v` の違いは？ 開発環境でどんな場面で `-v` を使うべきか、データ永続化の観点で説明してください。」

---

## 9) Next-step resources (official docs preferred)
- Docker Docs Home: https://docs.docker.com/
- Get Started: https://docs.docker.com/get-started/
- Dockerfile best practices: https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Multi-stage builds: https://docs.docker.com/build/building/multi-stage/
- Compose overview: https://docs.docker.com/compose/
- Compose file reference: https://docs.docker.com/compose/compose-file/
- Engine security: https://docs.docker.com/engine/security/

---

**明日の予告（学習アーク継続）:**
Beginner→Middle→Advancedの流れで、次回は「ボリューム設計（bind mount vs named volume）と開発効率・安全性の最適化」を扱います。
