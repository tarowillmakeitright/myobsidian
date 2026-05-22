---
tags:
  - docker
  - containers
  - devops
  - learning
  - daily
---

# 2026-05-22 09:20 Docker Commands Magazine
[[Home]]

今日の学習アークは **Beginner → Middle → Advanced** の3段構成です。実務での安全運用（特に秘密情報と破壊的コマンド）を前提に進めます。

---

## 1) Topic + Level

### Beginner
**テーマ:** コンテナの基本操作（`docker run`, `docker ps`, `docker logs`, `docker exec`）

### Middle
**テーマ:** Dockerfile設計と再現可能なビルド（`docker build`, `.dockerignore`, レイヤ最適化）

**前提条件:**
- Beginnerのコマンド操作ができる
- Linuxコマンド（`cd`, `cat`, `ls`）の基礎理解
- アプリ依存関係（例: Node.js / Python）の概念を知っている

### Advanced
**テーマ:** Composeによる複数サービス連携 + セキュア運用（`docker compose up`, ヘルスチェック, secrets運用指針）

**前提条件:**
- Middleまでの内容
- Webアプリ + DB構成の基本理解
- ネットワーク/ポート公開の意味を説明できる

---

## 2) Why it matters for real app development

- **環境差異を減らす:** 開発者ごとの差分（OS/ライブラリ）で壊れにくくなる
- **オンボーディング高速化:** `docker compose up` で初日から実行可能
- **CI/CD整合性:** ローカルとCIで同じイメージを使いやすい
- **運用事故予防:** 不要公開ポートや機密情報混入を防ぐ設計ができる

---

## 3) Core Docker command explanations

- `docker run --name app -p 8080:80 nginx:alpine`
  - 新規コンテナ起動。`-p` は **ホスト:コンテナ** ポートマッピング
- `docker ps` / `docker ps -a`
  - 稼働中 / 全コンテナ確認
- `docker logs -f <container>`
  - ログ追跡（障害切り分けの第一歩）
- `docker exec -it <container> sh`
  - コンテナ内部に入って調査
- `docker build -t myapp:dev .`
  - Dockerfileからイメージ作成
- `docker compose up -d`
  - 複数サービスをまとめて起動
- `docker compose down`
  - サービス停止・ネットワーク削除

> ⚠️ 注意（破壊的操作）
> - `docker system prune`, `docker image prune -a`, `docker rmi`, `docker rm -f` は削除を伴います。実行前に対象確認（`docker ps -a`, `docker images`）を必ず行ってください。

---

## 4) App building でのDocker活用（docs.docker.com準拠の実践）

- **小さいベースイメージを使う**（例: `alpine` 系、または公式軽量タグ）
- **マルチステージビルド**でビルドツールを最終イメージに残さない
- **`.dockerignore`** を整備して不要ファイルを送らない（`node_modules`, `.git`, `.env` など）
- **レイヤキャッシュを活かす順序**にする（依存ファイル→インストール→アプリ本体）
- **非rootユーザー実行**を基本にする
- **機密情報をイメージに焼き込まない**
  - `ENV API_KEY=...` をDockerfileに直書きしない
  - Composeでも平文をGit管理しない（`.env`の扱い、secret管理を分離）

---

## 5) 30-60分ミニラボ（実践）

**ゴール:** シンプルなWebアプリ（例: nginx静的配信）をDockerfile + Composeで動かし、ログ確認まで行う

### 手順（目安45分）

1. 作業ディレクトリ作成（5分）
   - `mkdir docker-mini-lab && cd docker-mini-lab`
2. `index.html` 作成（5分）
3. `Dockerfile` 作成（10分）
   - `nginx:alpine` ベース
   - `COPY index.html /usr/share/nginx/html/index.html`
4. ビルドと単体起動（10分）
   - `docker build -t mini-nginx:lab .`
   - `docker run --rm -d --name mini-web -p 8080:80 mini-nginx:lab`
5. 確認とトラブルシュート（5-10分）
   - `curl http://localhost:8080`
   - `docker logs mini-web`
6. Compose化（10分）
   - `compose.yaml` を作成し `docker compose up -d`
   - `docker compose ps` / `docker compose logs -f`

**できたら追加課題:**
- コンテナ実行ユーザーを非root化したDockerfileに改修
- `.dockerignore` 追加前後でビルド文脈サイズ差を確認

---

## 6) Command cheatsheet

- 起動: `docker run -d --name <name> -p <host>:<container> <image>`
- 一覧: `docker ps` / `docker ps -a`
- ログ: `docker logs -f <name>`
- 内部シェル: `docker exec -it <name> sh`
- ビルド: `docker build -t <image>:<tag> .`
- Compose起動: `docker compose up -d`
- Compose停止: `docker compose down`
- 使用量確認: `docker system df`

⚠️ 削除系（要確認）
- `docker rm -f <container>`
- `docker rmi <image>`
- `docker system prune`（未使用リソースを一括削除）

---

## 7) Common mistakes and safe practices

**よくあるミス**
- `latest` タグ固定で再現性が落ちる
- `.env` や秘密鍵をイメージに含める
- 不要な `COPY . .` で機密や巨大ファイル混入
- root実行のまま本番投入
- prune系を確認なしで実行

**安全プラクティス**
- イメージタグを固定（例: `nginx:1.27-alpine`）
- `.dockerignore` を必ずメンテ
- secretsは環境分離し、Gitに平文を置かない
- 削除前に対象確認コマンドを実行
- Composeで公開ポートを最小化（必要なものだけ）

---

## 8) Interview-style question

**質問:**
「`COPY package*.json ./` → `RUN npm ci` → `COPY . .` の順にDockerfileを書く理由を、ビルドキャッシュと再現性の観点で説明してください。」

---

## 9) Next-step resources（公式中心）

- Docker Get Started
  - https://docs.docker.com/get-started/
- Dockerfile best practices
  - https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Multi-stage builds
  - https://docs.docker.com/build/building/multi-stage/
- Compose overview
  - https://docs.docker.com/compose/
- Docker Engine security
  - https://docs.docker.com/engine/security/
- Build cache / optimization
  - https://docs.docker.com/build/cache/

---

次号予告（学習アーク継続）:
- Beginner: ボリューム基礎
- Middle: 開発用ホットリロード構成
- Advanced: CIでのBuildKitキャッシュ活用
