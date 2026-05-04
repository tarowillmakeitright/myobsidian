---
tags: [docker, containers, devops, learning, daily]
---

# 2026-05-04 09:20 Docker Commands Magazine
[[Home]]

#docker #containers #devops #learning #daily

今日のテーマは、**Beginner → Middle → Advanced** の学習アークで「Dockerコマンドを実務開発で使える形にする」ことです。

---

## 1) Topic + Level

### Beginner
**Topic:** コンテナの基本操作（`docker run` / `docker ps` / `docker logs` / `docker exec`）

### Middle（前提あり）
**Topic:** Dockerfileで再現可能な開発環境を作る（`docker build` / `.dockerignore` / 複数ステージ）
**Prerequisites:**
- Beginnerの基本コマンドが使える
- Linuxコマンドの初歩（`cd`, `ls`, `cat`）
- Gitリポジトリ構成の理解（アプリコードと設定ファイルの分離）

### Advanced（前提あり）
**Topic:** Composeでアプリ + DBを安全に運用する（`docker compose up/down/logs`、ヘルスチェック、シークレット管理）
**Prerequisites:**
- MiddleのDockerfile作成経験
- WebアプリとDB接続の基礎知識
- 環境変数と`.env`運用の理解

---

## 2) Why it matters for real app development

- **環境差分バグを減らす**: 「自分のPCでは動く」を減らし、チーム開発で再現性を確保。
- **オンボーディングを高速化**: 新メンバーが`docker compose up`ですぐ開発開始可能。
- **CI/CDと整合**: ローカルで使うコンテナ定義をCIにも流用しやすい。
- **本番運用の品質向上**: 小さく安全なイメージ、ヘルスチェック、明示的設定で障害耐性を上げる。

---

## 3) Core Docker command explanations

- `docker run IMAGE`
  - イメージからコンテナを起動。
  - よく使うオプション: `-d`（バックグラウンド）、`-p host:container`（ポート公開）、`--name`。

- `docker ps` / `docker ps -a`
  - 稼働中 / 全コンテナ一覧を確認。

- `docker logs CONTAINER`
  - 実行ログ確認。`-f`で追従（tail）。

- `docker exec -it CONTAINER sh`
  - コンテナ内に入って調査。
  - Alpine系は`sh`、Debian/Ubuntu系は`bash`が使えることが多い。

- `docker build -t name:tag .`
  - Dockerfileからイメージをビルド。

- `docker images`
  - ローカルのイメージ一覧。

- `docker compose up -d`
  - 複数サービスを一括起動。

- `docker compose logs -f`
  - サービス横断のログ確認。

- `docker compose down`
  - サービス停止 + ネットワーク削除（ボリューム削除は`-v`を付けた場合）。

---

## 4) How Docker is used while building apps (docs.docker.com aligned)

実務での典型フロー（Docker公式の推奨に沿った形）:

1. **開発用Dockerfileを作る**
   - 依存解決手順を先に置き、レイヤーキャッシュを効かせる。
   - `.dockerignore`で不要ファイル（`node_modules`, `.git`, ログ）を除外。

2. **マルチステージビルドを使う**
   - ビルド環境と実行環境を分離し、最終イメージを小さく安全に。

3. **Composeで依存サービスを定義**
   - `app`, `db`, `redis` などを1ファイルで管理。
   - `depends_on`だけに頼らず、**healthcheck**で起動順と可用性を担保。

4. **設定はイメージではなく環境へ分離**
   - 秘密情報をDockerfileに埋め込まない。
   - `.env`やシークレット管理機構を利用し、リポジトリに平文秘密情報を置かない。

5. **最小権限を意識**
   - 可能なら非rootユーザーで実行。
   - 不要なポート公開や過剰な権限付与を避ける。

---

## 5) 30–60 minute hands-on mini lab

**Goal:** `app + db` の最小構成をComposeで起動し、ログ確認と疎通確認を行う。

### Step A (10–15分): サンプル構成作成
1. 新規ディレクトリ作成
2. `Dockerfile`（アプリ）作成
3. `docker-compose.yml`（app, postgres）作成
4. `.dockerignore`作成

### Step B (10–15分): 起動と確認
```bash
docker compose up -d --build
docker compose ps
docker compose logs -f app
```
- アプリが起動しているか
- DB接続エラーがないかを確認

### Step C (10–15分): コンテナ内デバッグ
```bash
docker compose exec app sh
# 例: 環境変数・接続先確認
```
- 接続先ホスト名（`db`）が解決されるか確認

### Step D (5–10分): 安全な停止
```bash
docker compose down
```
- ※DBデータを保持したい場合はボリューム設計を確認してから停止/削除

---

## 6) Command cheatsheet

```bash
# 稼働確認
docker ps

# 全コンテナ確認（停止済み含む）
docker ps -a

# イメージ一覧
docker images

# 単体起動
docker run -d -p 8080:80 --name web nginx:alpine

# ログ追跡
docker logs -f web

# コンテナ内シェル
docker exec -it web sh

# ビルド
docker build -t myapp:dev .

# Compose起動
docker compose up -d --build

# Composeログ
docker compose logs -f

# Compose停止
docker compose down
```

---

## 7) Common mistakes and safe practices

### よくあるミス
- `latest`タグ固定で再現性を失う
- `.dockerignore`未設定でビルド遅延・不要ファイル混入
- Dockerfileにシークレットを直書き
- コンテナをrootで実行し続ける
- DB永続化を考えず`down -v`してデータ喪失

### Safe practices
- イメージタグを固定（例: `postgres:16.3`）
- 最終イメージを小さく保つ（マルチステージ）
- 秘密情報は環境変数/シークレット管理へ分離
- 必要最小限のポートだけ公開
- ヘルスチェックとログ監視を標準化

### ⚠ 危険コマンドの注意
以下は**削除系**なので実行前に対象を必ず確認:
- `docker system prune`
- `docker image prune -a`
- `docker rmi ...`
- `docker rm -f ...`

推奨手順:
1. `docker ps -a` / `docker images`で対象確認
2. 影響範囲（他プロジェクト含む）を確認
3. 本当に不要なものだけ削除

---

## 8) One interview-style question

**Q.** `docker run` と `docker compose up` の使い分けを、チーム開発・再現性・依存サービス管理の観点で説明してください。さらに、なぜ本番に近い検証がComposeでやりやすいのかを述べてください。

---

## 9) Next-step resources (official docs first)

- Docker Docs Home  
  https://docs.docker.com/

- Get Started (公式チュートリアル)  
  https://docs.docker.com/get-started/

- Dockerfile best practices  
  https://docs.docker.com/develop/develop-images/dockerfile_best-practices/

- Multi-stage builds  
  https://docs.docker.com/build/building/multi-stage/

- Compose documentation  
  https://docs.docker.com/compose/

- Compose file reference  
  https://docs.docker.com/compose/compose-file/

- Image security best practices（セキュリティ関連）  
  https://docs.docker.com/develop/security-best-practices/

---

次号予告: **Middle → Advanced ブリッジ編**（BuildKitキャッシュ最適化、開発/本番Dockerfile分離、Compose profiles）
