---
tags: [docker, containers, devops, learning, daily]
---

# 2026-04-23 09:20 Docker Commands Magazine
[[Home]]

#docker #containers #devops #learning #daily

## 今日のテーマ
**実践で身につける Docker コマンド学習アーク（Beginner → Middle → Advanced）**

---

## 1) Topic + Level

### Beginner
**トピック:** イメージ取得〜コンテナ起動の基本（`docker pull` / `docker run` / `docker ps` / `docker logs`）

### Middle
**トピック:** 開発効率を上げるボリュームと Compose（`docker volume` / `docker compose up`）
**前提知識:** Beginner の内容、Linux の基本的なファイルパス理解、HTTP の基礎

### Advanced
**トピック:** マルチステージビルドとセキュア運用（`docker build` / `docker exec` / `docker inspect` / `docker compose` 運用）
**前提知識:** Middle の内容、Dockerfile の基本命令（`FROM`, `RUN`, `COPY`, `CMD`）

---

## 2) なぜ実アプリ開発で重要か
- **環境差分の削減:** 「自分のPCでは動く」を減らし、チーム開発の再現性を高める。
- **オンボーディング高速化:** 新メンバーが `docker compose up` で素早く開発開始できる。
- **CI/CD 連携:** 本番に近いイメージをCIで検証し、デプロイ事故を減らす。
- **セキュリティ:** 最小イメージ・非root実行・秘密情報管理でリスク低減。

---

## 3) コア Docker コマンド解説

### Beginner コマンド
- `docker pull nginx:stable`
  - レジストリからイメージ取得。タグ固定で再現性向上。
- `docker run --name web1 -d -p 8080:80 nginx:stable`
  - コンテナ起動。`-d` バックグラウンド、`-p` ポート公開。
- `docker ps` / `docker ps -a`
  - 実行中 / 全コンテナ確認。
- `docker logs -f web1`
  - アプリログ追跡。障害初動で最重要。

### Middle コマンド
- `docker volume create app_data`
  - 永続データ保存先を作成。
- `docker run -v app_data:/data ...`
  - コンテナ削除後もデータを保持。
- `docker compose up -d`
  - 複数サービス（API/DB/Redisなど）を一括起動。
- `docker compose logs -f api`
  - サービス単位でログ確認。

### Advanced コマンド
- `docker build -t myapp:1.0 .`
  - Dockerfileからイメージ作成。
- `docker inspect myapp:1.0`
  - メタデータや設定を確認（ポート、環境変数、レイヤなど）。
- `docker exec -it <container> sh`
  - 実行中コンテナへ入り調査。
- `docker compose config`
  - Composeの最終解決結果を確認し、設定ミスを早期発見。

---

## 4) アプリ構築時の Docker 利用（docs.docker.com ベストプラクティス準拠）
- **小さく安全なベースイメージ**を使う（例: `alpine` 系、または公式イメージ）。
- **マルチステージビルド**で不要なビルドツールを最終イメージから排除。
- **`.dockerignore` を適切に設定**して不要ファイル流入を防止。
- **タグ固定（可能なら digest）**で再現性確保。
- **秘密情報をイメージに埋め込まない。**
  - `ENV PASSWORD=...` や Dockerfile への直書きは避ける。
  - Compose でも `.env` の扱いに注意し、機密値をGit管理しない。
- **コンテナは不変前提**（設定は環境変数や外部設定で注入）。

---

## 5) 30〜60分ハンズオン Mini Lab

### ゴール
Nginx コンテナを立て、ローカルHTMLを反映し、Compose化して再起動まで行う。

### 手順（約45分）
1. 作業フォルダ作成
   - `mkdir -p docker-lab/site && cd docker-lab`
2. HTML作成
   - `echo '<h1>Hello Docker Magazine</h1>' > site/index.html`
3. 単体起動で確認
   - `docker run --name lab-nginx -d -p 8088:80 -v $(pwd)/site:/usr/share/nginx/html:ro nginx:stable`
   - ブラウザで `http://localhost:8088`
4. ログ確認
   - `docker logs -f lab-nginx`
5. Compose化（`compose.yaml` 作成）
   - サービス `web` に `nginx:stable`、`8088:80`、ボリュームマウント設定
6. 単体停止→Compose起動
   - `docker stop lab-nginx && docker rm lab-nginx`
   - `docker compose up -d`
7. 変更反映テスト
   - `site/index.html` を編集してリロード
8. 後片付け（安全に）
   - `docker compose down`

---

## 6) Command Cheatsheet
- 起動: `docker run --name <name> -d -p <host>:<container> <image>:<tag>`
- 一覧: `docker ps` / `docker ps -a`
- ログ: `docker logs -f <container>`
- 停止/削除: `docker stop <container>` / `docker rm <container>`
- ビルド: `docker build -t <name>:<tag> .`
- Compose起動/停止: `docker compose up -d` / `docker compose down`
- 設定確認: `docker compose config`
- 詳細確認: `docker inspect <target>`

---

## 7) よくあるミスと安全プラクティス
- **ミス:** `latest` 任せで環境差分発生
  - **対策:** 明示タグを使う（例: `nginx:1.27-alpine`）
- **ミス:** 機密情報を Dockerfile や compose.yaml に直書き
  - **対策:** 秘密情報は安全な注入方法を使い、Gitに含めない
- **ミス:** root 前提で運用
  - **対策:** 可能なら非rootユーザー実行
- **ミス:** 不用意なクリーンアップで必要データ消失
  - **注意喚起（破壊的コマンド）:**
    - `docker system prune`
    - `docker image prune -a`
    - `docker rmi`
    - `docker rm -f`
  これらは**削除対象を必ず確認してから**実行すること。特に `-a`, `-f` は要注意。

---

## 8) 面接風質問（1問）
「`docker run` と `docker compose up` の使い分けを、チーム開発・再現性・運用保守の観点で説明してください。」

---

## 9) 次の一歩（公式ドキュメント中心）
- Docker 公式ドキュメント入口: https://docs.docker.com/
- Get Started: https://docs.docker.com/get-started/
- Dockerfile ベストプラクティス: https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Multi-stage builds: https://docs.docker.com/build/building/multi-stage/
- Compose 公式ガイド: https://docs.docker.com/compose/
- Compose file reference: https://docs.docker.com/reference/compose-file/
- Volumes: https://docs.docker.com/storage/volumes/
- Docker Scout（イメージの脆弱性把握）: https://docs.docker.com/scout/

---

明日の予告: **Middle寄りアーク**として「Node.js API + Postgres の Compose 開発環境」を実践します（healthcheck付き）。
