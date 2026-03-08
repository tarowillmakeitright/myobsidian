---
tags: [docker, containers, devops, learning, daily]
---

# Daily Docker Commands Magazine - 2026-03-07
[[Home]]

#docker #containers #devops #learning #daily

> テーマ: **Dockerコマンド実践アーク（Beginner → Middle → Advanced）**  
> 今日の狙い: 「動かす」だけでなく、**安全に・再現性高く・本番を意識して**Dockerを使えるようになる。

---

## 1) Topic + Level

### 🟢 Beginner: `docker run` / `docker ps` / `docker logs` の基本で「1コンテナを正しく扱う」

### 🟡 Middle: `docker build` / `docker compose up` で「開発環境を再現可能にする」
**前提条件（Prerequisites）**
- Beginnerレベル（コンテナ起動・停止・ログ確認）ができる
- Dockerfileを読める（`FROM`, `WORKDIR`, `COPY`, `RUN`, `CMD`）

### 🔴 Advanced: キャッシュ最適化・ヘルスチェック・安全なクリーンアップ運用
**前提条件（Prerequisites）**
- Middleレベル（Composeで複数サービス起動）ができる
- イメージレイヤーとボリュームの基本理解

---

## 2) Why it matters（なぜ実アプリ開発で重要か）

- **ローカル環境差分を減らす**: 「私のPCでは動く」を減らし、チーム開発の摩擦を小さくする
- **検証速度を上げる**: 依存関係をコンテナ化し、CI/CDと同じ土台で試せる
- **運用事故を防ぐ**: ログ確認、ヘルスチェック、削除コマンドの扱いを誤ると本番障害に直結する
- **セキュリティ確保**: シークレットをイメージに焼き込まない、不要な権限を避ける、最小限の公開ポートにする

---

## 3) Core Docker command explanations（コマンド解説）

### `docker run`
- 役割: イメージからコンテナを起動
- 例: `docker run --name web -p 8080:80 -d nginx:alpine`
- ポイント:
  - `--name`: コンテナ識別を簡単に
  - `-p host:container`: 必要なポートだけ公開
  - `-d`: バックグラウンド実行

### `docker ps` / `docker ps -a`
- 役割: 実行中（`-a`で全）コンテナ一覧確認
- 実運用での意味: 稼働確認・トラブル切り分けの第一歩

### `docker logs -f <container>`
- 役割: ログ確認（`-f`で追従）
- 実運用での意味: 失敗原因の初動把握

### `docker build -t <name:tag> .`
- 役割: Dockerfileからイメージ作成
- 実運用での意味: 再現可能なビルド基盤

### `docker compose up -d` / `docker compose down`
- 役割: 複数サービスの起動・停止
- 実運用での意味: app + db + cache を一括管理

### `docker exec -it <container> sh`
- 役割: 稼働中コンテナに入って調査
- 実運用での意味: デバッグ効率化（本番では最小限）

### `docker image ls` / `docker volume ls` / `docker network ls`
- 役割: 資産可視化（何が溜まっているか）

---

## 4) App開発での使い方（docs.docker.com ベストプラクティス準拠）

- **Dockerfileは小さく安全に**
  - 軽量ベースイメージ（例: `alpine`系）を検討
  - レイヤーキャッシュを意識して `COPY` 順序を設計
  - `.dockerignore` で不要ファイルを送らない
- **Composeで開発依存を定義**
  - DBやRedisをComposeで固定化し、オンボーディング時間を短縮
- **シークレットの扱い**
  - ❌ `ENV PASSWORD=...` をDockerfileに直書きしない
  - ✅ 実行時環境変数・シークレット管理機構を利用
- **権限と公開面を最小化**
  - 必要最小限のポート公開
  - 不要な`--privileged`回避

---

## 5) 30-60分ハンズオン・ミニラボ（約45分）

### ゴール
Nginx + 簡易アプリ（静的ページ）をDockerで起動し、Compose化、ログ確認、ヘルス確認まで行う。

### 手順
1. **準備（5分）**
   - 作業ディレクトリ作成
   - `index.html` を用意
2. **Beginner操作（10分）**
   - `docker run -d --name mynginx -p 8080:80 nginx:alpine`
   - `docker ps` / `docker logs mynginx`
   - ブラウザで `http://localhost:8080`
3. **Middle操作（15分）**
   - `Dockerfile` 作成（`COPY index.html /usr/share/nginx/html/index.html`）
   - `docker build -t mysite:dev .`
   - `docker run -d --name mysite -p 8081:80 mysite:dev`
   - `docker compose.yml` に置き換え、`docker compose up -d`
4. **Advanced操作（15分）**
   - `HEALTHCHECK` を追加したDockerfileを試す
   - `docker inspect --format='{{json .State.Health}}' mysite | jq`
   - ログとステータスで動作確認

### 完了チェック
- [ ] コンテナ起動/停止を安全にできた
- [ ] Dockerfileビルド→実行の流れを説明できる
- [ ] Composeで再現可能な開発環境を起動できた
- [ ] HEALTHCHECKの状態確認ができた

---

## 6) Command cheatsheet

```bash
# 起動・確認
docker run --name web -p 8080:80 -d nginx:alpine
docker ps
docker logs -f web

# コンテナ操作
docker stop web
docker start web
docker exec -it web sh

# ビルド
docker build -t myapp:dev .
docker image ls

# Compose
docker compose up -d
docker compose ps
docker compose logs -f
docker compose down

# 状態確認
docker inspect web
```

---

## 7) Common mistakes & safe practices

### よくあるミス
- `latest`タグ固定で意図せぬ更新
- `.dockerignore`未設定で巨大ビルドコンテキスト
- シークレットをDockerfile/composeに平文記載
- 不要ポートを開けっぱなし

### 安全運用の注意（重要）
- ⚠️ **破壊的コマンド注意**: `docker system prune`, `docker image prune -a`, `docker rm -f`, `docker rmi` は削除対象を必ず確認してから実行
- 本番/共有環境では、削除前に影響範囲（依存コンテナ・ボリューム）を確認
- データ永続化が必要なものは named volume を使う

---

## 8) Interview-style question

**Q.** `docker run` と `docker compose up` の使い分けを、開発チームの運用観点で説明してください。  
**期待される要点**: 単体検証 vs 複数サービス再現、構成のコード化、オンボーディング容易性、CI/CD整合性。

---

## 9) Next-step resources（公式優先）

- Docker Docs Home: https://docs.docker.com/
- Get Started: https://docs.docker.com/get-started/
- Dockerfile best practices: https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Compose overview: https://docs.docker.com/compose/
- Compose file reference: https://docs.docker.com/reference/compose-file/
- Image tagging best practices: https://docs.docker.com/reference/cli/docker/image/tag/
- Volumes: https://docs.docker.com/storage/volumes/
- Docker Engine security: https://docs.docker.com/engine/security/

---

次回予告: **「Beginner→Middle→Advanced: ネットワーク編（bridge/host/compose network）」**