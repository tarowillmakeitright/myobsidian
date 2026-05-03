---
tags: [docker, containers, devops, learning, daily]
---

# 2026-05-03 Docker Commands Magazine
[[Home]]

#docker #containers #devops #learning #daily

## Issue 1 — Beginner
### 1) Topic + Level
**Topic:** コンテナの基本ライフサイクル（`pull` / `run` / `ps` / `logs` / `stop` / `rm`）  
**Level:** Beginner

### 2) Why it matters for real app development
ローカル開発で「自分の環境では動くのに他人の環境では壊れる」を減らす第一歩。  
DBやキャッシュなど依存サービスを素早く立ち上げ、再現性のある開発環境を作れる。

### 3) Core Docker command explanations
- `docker pull nginx:alpine` : イメージを取得
- `docker run -d --name web -p 8080:80 nginx:alpine` : コンテナ起動（バックグラウンド、ポート公開）
- `docker ps` : 起動中コンテナ一覧
- `docker logs -f web` : ログ追跡
- `docker stop web` : 停止
- `docker rm web` : コンテナ削除

### 4) How Docker is used while building apps (docsベストプラクティス準拠)
- 依存ミドルウェア（Postgres/Redisなど）をコンテナ化してチームで統一
- 使い捨て可能な環境として扱い、永続データはボリュームへ分離
- 1コンテナ1責務を意識し、アプリ本体とDBを分離

### 5) 30-60 minute hands-on mini lab
1. `nginx:alpine` を起動し、`http://localhost:8080` へアクセス
2. `docker logs -f web` でアクセスログ確認
3. 停止→削除→再起動を実施し、同じ手順で再現できることを確認
4. 学びをメモ: 「どのコマンドで何が変わるか」

### 6) Command cheatsheet
```bash
docker pull nginx:alpine
docker run -d --name web -p 8080:80 nginx:alpine
docker ps
docker logs -f web
docker stop web
docker rm web
```

### 7) Common mistakes and safe practices
- ミス: `-p` を忘れて外部アクセスできない
- ミス: コンテナ削除とイメージ削除を混同
- 安全策: 開発中は `--name` を必ず付ける（管理しやすい）
- 安全策: 削除前に `docker ps -a` で対象確認

### 8) Interview-style question
「`docker run -d -p 8080:80 nginx` の `8080:80` は何を意味し、なぜ必要ですか？」

### 9) Next-step resources
- Docker Get Started: https://docs.docker.com/get-started/
- Containers overview: https://docs.docker.com/get-started/docker-overview/

---

## Issue 2 — Middle
### Prerequisites
- Beginner内容を完了
- Dockerfileの基本構文（`FROM`, `COPY`, `RUN`, `CMD`）を見たことがある

### 1) Topic + Level
**Topic:** DockerfileでNode.jsアプリをイメージ化（キャッシュ効率と最小権限）  
**Level:** Middle

### 2) Why it matters for real app development
CI/CDで毎回同じ方法でビルド・実行できる。依存関係と実行環境が固定され、デプロイ事故を減らせる。

### 3) Core Docker command explanations
- `docker build -t myapp:dev .` : Dockerfileからイメージ作成
- `docker run --rm -p 3000:3000 myapp:dev` : 一時コンテナで実行（終了時自動削除）
- `docker image ls` : イメージ確認
- `docker exec -it <container> sh` : 稼働中コンテナ内確認

### 4) How Docker is used while building apps (docsベストプラクティス準拠)
- `package*.json` を先に `COPY` → `npm ci` でレイヤーキャッシュ最適化
- `.dockerignore` で不要ファイル除外（`node_modules`, `.git`）
- `USER node` など非root実行で安全性向上
- 可能なら軽量ベースイメージを利用

### 5) 30-60 minute hands-on mini lab
1. `Dockerfile` を作成（例: Node 20-alpine）
2. `.dockerignore` を設定
3. `docker build -t myapp:dev .`
4. `docker run --rm -p 3000:3000 myapp:dev`
5. `docker exec` で実行ユーザーとファイル配置を確認

### 6) Command cheatsheet
```bash
docker build -t myapp:dev .
docker run --rm -p 3000:3000 myapp:dev
docker image ls
docker ps
docker exec -it <container_id> sh
```

### 7) Common mistakes and safe practices
- ミス: `COPY . .` を早い段階で実行しキャッシュが効かない
- ミス: 秘密情報を `ENV` やファイルでイメージに焼き込む
- 安全策: シークレットはビルド引数やイメージに含めず、実行時注入（環境変数/シークレット管理）
- 安全策: 不要ポートを公開しない

### 8) Interview-style question
「Dockerレイヤーキャッシュを効かせるDockerfileの並び順を、Node.jsアプリ例で説明してください。」

### 9) Next-step resources
- Building best practices: https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- .dockerignore: https://docs.docker.com/build/building/context/#dockerignore-files

---

## Issue 3 — Advanced
### Prerequisites
- Middle内容を完了
- Docker Composeの基本（`services`, `volumes`, `networks`）を理解
- 開発/本番の設定差分を意識できる

### 1) Topic + Level
**Topic:** Composeで複数サービス運用 + 安全なクリーンアップ運用  
**Level:** Advanced

### 2) Why it matters for real app development
Web/API/DB/Redisなどを一括起動・停止でき、オンボーディングと検証速度が大幅向上。環境差分を構成ファイルで管理できる。

### 3) Core Docker command explanations
- `docker compose up -d` : 複数サービス起動
- `docker compose ps` : サービス状態確認
- `docker compose logs -f api` : 特定サービスログ追跡
- `docker compose down` : 停止とネットワーク削除
- `docker volume ls` : ボリューム確認

### 4) How Docker is used while building apps (docsベストプラクティス準拠)
- アプリ/DB/キャッシュをサービス分離し、依存関係を明示
- 永続化が必要なデータのみ named volume に保存
- `env_file` や実行時環境変数を使い、秘密情報をGit追跡ファイルに置かない
- 本番向けは最小権限・最小公開ポートを徹底

### 5) 30-60 minute hands-on mini lab
1. `compose.yaml` を作成（例: `api`, `db`）
2. `docker compose up -d`
3. `docker compose ps` と `logs -f` で疎通確認
4. API再ビルドが必要なら `docker compose up -d --build`
5. `docker compose down` で停止

### 6) Command cheatsheet
```bash
docker compose up -d
docker compose ps
docker compose logs -f api
docker compose up -d --build
docker compose down
docker volume ls
```

### 7) Common mistakes and safe practices
- ミス: `depends_on` だけでDB接続準備完了だと思い込む（ヘルスチェック設計不足）
- ミス: `.env` をそのままコミット
- 安全策: シークレットは専用管理（少なくとも `.env` はGit除外）
- **警告（破壊的）:** `docker system prune`, `docker image prune -a`, `docker rm -f`, `docker rmi` は削除対象を事前確認してから実行。共有環境では特に禁止/要レビュー。

### 8) Interview-style question
「`docker compose down` と `docker compose down -v` の違いは？ 開発環境で使い分ける基準を説明してください。」

### 9) Next-step resources
- Docker Compose docs: https://docs.docker.com/compose/
- Compose file reference: https://docs.docker.com/reference/compose-file/
- Multi-stage builds: https://docs.docker.com/build/building/multi-stage/

---

## Tomorrow preview (learning arc)
次回は Beginner→Middle→Advanced を繰り返しつつ、テーマを「イメージ最適化（サイズ・ビルド速度・セキュリティ）」へ進める。