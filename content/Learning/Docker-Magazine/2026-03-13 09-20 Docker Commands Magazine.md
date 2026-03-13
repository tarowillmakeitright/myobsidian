---
tags: [docker, containers, devops, learning, daily]
---

# 2026-03-13 Docker Commands Magazine
#docker #containers #devops #learning #daily
[[Home]]

## 今号のテーマ
**「開発ループを速くする Docker 基本運用」**

---

## Arc 1 — Beginner（初級）
### 1) Topic + Level
**Topic:** コンテナの起動・停止・確認の基本  
**Level:** Beginner

### 2) なぜ実務で重要か
ローカル環境差分（OS・言語バージョン）でハマる時間を減らし、チーム全体で同じ実行環境を再現できます。

### 3) コアコマンド解説
- `docker pull nginx:stable` : イメージ取得
- `docker run -d --name web -p 8080:80 nginx:stable` : バックグラウンド起動＋ポート公開
- `docker ps` / `docker ps -a` : 実行中/全コンテナ一覧
- `docker logs -f web` : ログ追跡
- `docker stop web` / `docker start web` : 停止/再開
- `docker rm web` : コンテナ削除（停止済みのみ）

### 4) アプリ開発での使い方（Docker公式ベストプラクティス準拠）
- 依存サービス（DB, Redis, MQ）をコンテナで固定化
- コンテナは**使い捨て前提**で、状態は volume に分離
- `latest` 固定を避け、タグを明示して再現性を担保

### 5) 30-60分ミニラボ（40分目安）
1. `nginx` コンテナを起動し `http://localhost:8080` を確認
2. `docker logs -f web` でアクセスログ確認
3. `docker stop/start` で再起動検証
4. `docker rm` で片付け

### 6) Cheatsheet
```bash
docker pull <image:tag>
docker run -d --name <name> -p <host>:<container> <image:tag>
docker ps
docker logs -f <container>
docker stop <container>
docker start <container>
docker rm <container>
```

### 7) よくあるミス & 安全策
- ミス: `:latest` 依存 → 再現不能
- 安全策: タグ固定（例 `nginx:1.27`）
- ミス: コンテナにデータ保存 → 消失
- 安全策: volume 利用

### 8) 面接風質問
「`docker run -d -p 8080:80` の `-d` と `-p` はそれぞれ何をし、開発時にどんな利点がありますか？」

### 9) 次の一歩（公式）
- https://docs.docker.com/get-started/
- https://docs.docker.com/engine/containers/run/

---

## Arc 2 — Middle（中級）
### Prerequisites
- `docker run/ps/logs/stop/rm` を迷わず使える
- ポート公開の意味を説明できる

### 1) Topic + Level
**Topic:** Dockerfile で Node.js API をコンテナ化  
**Level:** Middle

### 2) なぜ実務で重要か
「誰のPCでも同じビルド」を実現し、CI/CDへそのまま載せられます。

### 3) コアコマンド解説
- `docker build -t myapi:0.1 .` : イメージビルド
- `docker run --rm -p 3000:3000 myapi:0.1` : 一時起動
- `docker exec -it <container> sh` : コンテナ内調査
- `docker inspect <container>` : 詳細メタ確認

### 4) 開発での使い方（ベストプラクティス）
- `.dockerignore` を必ず使い、不要ファイルをビルドコンテキストから除外
- レイヤーキャッシュを意識し、依存インストールを先に分離
- 1コンテナ1責務を意識
- **秘密情報はイメージや compose に直書きしない**（envファイル/シークレット管理を使用）

### 5) 30-60分ミニラボ（50分目安）
1. シンプルな Node API を作る（`/health`）
2. Dockerfile 作成（軽量ベース、作業ディレクトリ、依存、起動）
3. `docker build` 実行
4. `docker run` で動作確認
5. `docker exec` でコンテナ内確認

### 6) Cheatsheet
```bash
docker build -t myapi:0.1 .
docker run --rm -p 3000:3000 myapi:0.1
docker exec -it <container> sh
docker inspect <container>
```

### 7) よくあるミス & 安全策
- ミス: `COPY . .` を早い段階で実行しキャッシュ効率悪化
- 安全策: `package*.json` 先コピー→`npm ci`→アプリコピー
- ミス: `.env` をイメージに含める
- 安全策: 実行時注入（`--env-file` / Secret管理）

### 8) 面接風質問
「Dockerfileでビルド時間を短縮するため、レイヤー順序をどう設計しますか？」

### 9) 次の一歩（公式）
- https://docs.docker.com/build/
- https://docs.docker.com/build/cache/
- https://docs.docker.com/develop/develop-images/dockerfile_best-practices/

---

## Arc 3 — Advanced（上級）
### Prerequisites
- Dockerfile最適化、基本デバッグ、ログ確認ができる
- ネットワーク/ボリューム/環境変数の基礎理解がある

### 1) Topic + Level
**Topic:** Composeで複数サービス（API + DB）を安全運用  
**Level:** Advanced

### 2) なぜ実務で重要か
本番に近い構成をローカルで再現し、結合不具合を早期に検知できます。

### 3) コアコマンド解説
- `docker compose up -d` : 複数サービス起動
- `docker compose ps` : サービス状態確認
- `docker compose logs -f api` : 特定サービスログ
- `docker compose exec api sh` : サービス内デバッグ
- `docker compose down` : 停止・ネットワーク削除

### 4) 開発での使い方（ベストプラクティス）
- `depends_on` だけに頼らずヘルスチェックを使う
- DBデータは volume で永続化
- 環境別設定（dev/prod）を override ファイルで分離
- 機密は compose ファイルに平文で置かない

### 5) 30-60分ミニラボ（60分目安）
1. `api` と `postgres` の `compose.yaml` を作成
2. ヘルスチェックを追加
3. `docker compose up -d` で起動
4. API からDB接続確認
5. ログと `exec` で障害切り分け
6. `docker compose down` で終了

### 6) Cheatsheet
```bash
docker compose up -d
docker compose ps
docker compose logs -f <service>
docker compose exec <service> sh
docker compose down
```

### 7) よくあるミス & 安全策
- ミス: サービス起動順だけで安定稼働を期待
- 安全策: readiness/healthcheck で待ち合わせ
- ミス: `docker system prune -a` を無警戒で実行
- 安全策: **破壊的クリーンアップ前に必ず確認**
  - ⚠️ `docker system prune`, `docker image prune`, `docker rmi`, `docker rm -f` は削除対象を事前確認
  - 可能なら `docker ps -a` / `docker images` / `docker volume ls` を先に確認

### 8) 面接風質問
「Compose環境でAPIがDB起動前に失敗する問題を、どの機能でどう改善しますか？」

### 9) 次の一歩（公式）
- https://docs.docker.com/compose/
- https://docs.docker.com/compose/compose-file/
- https://docs.docker.com/reference/cli/docker/system/prune/
- https://docs.docker.com/security/

---

## まとめ
今日は「単体コンテナ運用 → Dockerfile最適化 → Compose複数サービス運用」の流れで、実務でそのまま使えるコマンドと安全運用を学ぶ構成です。次号はこの流れを引き継ぎ、BuildKit・マルチステージビルド・脆弱性スキャンへ進みます。
