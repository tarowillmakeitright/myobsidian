---
tags: [docker, containers, devops, learning, daily]
---

# Daily Docker Commands Magazine — 2026-05-14 09:20

[[Home]]

## 今号のテーマ
**Dockerで開発環境を再現可能にする実践コマンド術（Beginner → Middle → Advanced）**

---

## 1) Topic + Level

### 🟢 Beginner
**Topic:** `docker run` / `docker ps` / `docker logs` で「動かして観察する」

### 🟡 Middle
**Topic:** `Dockerfile` + `docker build` + `docker compose up` で「アプリ開発環境をコード化する」
**Prerequisites:**
- Beginnerレベルの実行・確認コマンドを理解している
- 基本的なLinuxコマンド（cd, ls, cat）が使える
- 任意のWebアプリ（Node/Pythonなど）の最小構成を知っている

### 🔴 Advanced
**Topic:** BuildKitキャッシュ・マルチステージビルド・セキュアなCompose運用
**Prerequisites:**
- MiddleレベルのDockerfile/Compose運用経験
- イメージレイヤー構造の基礎理解
- CI/CDまたはチーム開発での再現性課題を経験している

---

## 2) なぜ実アプリ開発で重要か

- **環境差分の消滅**: 「自分のPCでは動く」を減らし、チーム全員が同じ環境で開発可能。
- **オンボーディング高速化**: 新メンバーも`docker compose up`で早期に開発参加できる。
- **品質向上**: 本番に近い構成（DB、Redis、API）をローカル再現しやすい。
- **セキュリティ改善**: 依存関係・実行ユーザー・ネットワーク境界を定義し、リスクを可視化できる。

---

## 3) Core Docker command explanations

### Beginnerコマンド
- `docker run -d --name web -p 8080:80 nginx:alpine`
  - コンテナ起動（バックグラウンド）
  - `--name` で識別しやすくする
  - `-p 8080:80` でホスト8080→コンテナ80へ公開
- `docker ps`
  - 稼働中コンテナ一覧を表示
- `docker logs -f web`
  - `web`コンテナのログを追跡表示
- `docker exec -it web sh`
  - 稼働中コンテナに対話シェル接続

### Middleコマンド
- `docker build -t myapp:dev .`
  - Dockerfileからイメージ作成
- `docker compose up -d`
  - 複数サービス（app/db等）をまとめて起動
- `docker compose logs -f app`
  - appサービスログを追跡
- `docker compose down`
  - Composeで作ったリソースを停止・削除（通常はデータボリュームは維持）

### Advancedコマンド
- `DOCKER_BUILDKIT=1 docker build --target runtime -t myapp:runtime .`
  - BuildKit有効化 + マルチステージの特定ターゲット出力
- `docker buildx build --platform linux/amd64,linux/arm64 -t myorg/myapp:latest .`
  - マルチアーキ対応イメージ作成（環境によりpush指定が必要）
- `docker image inspect myapp:runtime`
  - イメージ情報・設定確認（ユーザー、環境変数、レイヤーなど）

---

## 4) 実アプリ構築での使い方（docs.docker.comベストプラクティス準拠）

- **小さいベースイメージを選ぶ**（例: `alpine`や公式slim系）
- **マルチステージビルドを使う**（ビルド依存を最終イメージに残さない）
- **`.dockerignore`を適切に設定**（`node_modules`、`.git`、秘密情報を除外）
- **非rootユーザーで実行**（`USER`命令）
- **イメージはタグ固定を検討**（`latest`依存を避ける）
- **秘密情報をイメージに焼き込まない**
  - `ENV PASSWORD=...` のような書き方は避ける
  - Composeの`environment`直書きやGit管理された`.env`に機密を置かない
  - 必要ならランタイム注入・シークレット管理を使う

---

## 5) 30–60分ハンズオン・ミニラボ

**目標:** Nginx + シンプルAPI（任意）構成をComposeで起動し、ログ確認と安全運用まで体験

### 手順（約45分）
1. 作業ディレクトリ作成
```bash
mkdir -p docker-mag-lab && cd docker-mag-lab
```

2. `docker-compose.yml`作成（最小例）
```yaml
services:
  web:
    image: nginx:alpine
    ports:
      - "8080:80"
    read_only: true
    tmpfs:
      - /var/cache/nginx
      - /var/run
```

3. 起動して確認
```bash
docker compose up -d
docker compose ps
curl -I http://localhost:8080
```

4. ログ確認
```bash
docker compose logs -f web
```

5. 安全な停止
```bash
docker compose down
```

### 追加チャレンジ（余裕があれば）
- `Dockerfile`を作り、`USER`を設定した非root実行コンテナを作成
- `.dockerignore`を追加してビルドコンテキスト縮小
- `docker history <image>` でサイズ差比較

---

## 6) Command cheatsheet

```bash
# 実行・確認
docker run -d --name web -p 8080:80 nginx:alpine
docker ps
docker logs -f web
docker exec -it web sh

# ビルド
docker build -t myapp:dev .
DOCKER_BUILDKIT=1 docker build -t myapp:dev .

# Compose
docker compose up -d
docker compose ps
docker compose logs -f
docker compose down

# 調査
docker image ls
docker image inspect myapp:dev
docker system df
```

---

## 7) よくあるミスと安全運用

### よくあるミス
- `latest`タグ前提で再現性が崩れる
- `.dockerignore`未設定で不要ファイル混入
- コンテナをrootで動かし続ける
- 機密情報（APIキー等）をDockerfile/Composeへ直書き

### 安全運用
- 公式イメージ + バージョンタグを基本にする
- 最小権限（non-root、必要最小ポート公開）
- 不要なクリーンアップコマンドを常用しない

⚠️ **破壊的コマンド注意**
- `docker system prune -a`
- `docker rmi ...`
- `docker rm -f ...`

これらは**未使用イメージ/停止コンテナ/ネットワーク/キャッシュを削除**し、復元困難な場合があります。実行前に対象確認（`docker ps -a`, `docker image ls`, `docker system df`）を必ず行ってください。

---

## 8) 面接っぽい質問（Interview-style）

**Q.** Dockerfileでレイヤーキャッシュを効率化して、Node.jsアプリのビルド時間を短縮するにはどう設計しますか？

**期待される観点（要点）:**
- 依存インストール層とアプリコード層を分離（`package*.json`先コピー）
- `.dockerignore`で不要ファイル除外
- マルチステージでランタイムを軽量化
- CIでBuildKitキャッシュを再利用

---

## 9) 次の一歩（公式ドキュメント優先）

- Docker Docs Home: https://docs.docker.com/
- Get Started: https://docs.docker.com/get-started/
- Dockerfile best practices: https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Multi-stage builds: https://docs.docker.com/build/building/multi-stage/
- Compose file reference: https://docs.docker.com/compose/compose-file/
- BuildKit overview: https://docs.docker.com/build/buildkit/
- Docker Engine security: https://docs.docker.com/engine/security/

---

**次号予告（学習アーク継続）:**
Beginner→Middle→Advancedの流れで、次回は「ボリューム・ネットワーク・開発効率（ホットリロード）」を実践します。
