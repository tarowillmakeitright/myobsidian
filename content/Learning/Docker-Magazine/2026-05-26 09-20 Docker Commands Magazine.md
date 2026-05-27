---
tags: [docker, containers, devops, learning, daily]
---

# 2026-05-26 Docker Commands Magazine
[[Home]]

## 今号のテーマ + レベル
**テーマ:** コンテナ化されたWeb API開発の基本フロー（ビルド→実行→確認→停止）
**レベル:** **Beginner（初級）**

> 学習アーク: Beginner → Middle → Advanced を日次で循環

---

## 1) なぜ実アプリ開発で重要か
ローカル環境で「自分のPCでは動くのに本番で動かない」を減らせます。Dockerを使うと、アプリと依存関係をまとめて同じ実行環境で動かせるため、
- 開発者間の環境差分を吸収
- CI/CDに同じコンテナを流用しやすい
- バージョン固定（再現性）を確保
が実現しやすくなります。

---

## 2) コアDockerコマンド解説（初級）

### `docker build`
イメージを作成します。
```bash
docker build -t my-api:dev .
```
- `-t`: イメージ名:タグ
- `.`: Dockerfileのビルドコンテキスト

### `docker run`
コンテナを起動します。
```bash
docker run --name my-api-dev -p 8080:8080 my-api:dev
```
- `--name`: コンテナ名
- `-p 8080:8080`: ホスト:コンテナのポート公開

### `docker ps`
起動中コンテナを確認します。
```bash
docker ps
```

### `docker logs`
コンテナログを確認します。
```bash
docker logs -f my-api-dev
```
- `-f`: ログ追従（tail -f相当）

### `docker exec`
起動中コンテナ内でコマンド実行。
```bash
docker exec -it my-api-dev sh
```

### `docker stop` / `docker rm`
停止と削除。
```bash
docker stop my-api-dev
docker rm my-api-dev
```

---

## 3) アプリ開発での使い方（Docker公式ベストプラクティス準拠）
- **1コンテナ1責務**を基本にする（Web/API、DB、workerを分離）
- Dockerfileは**レイヤーキャッシュ**を活かす順序にする（依存インストールを先に）
- `.dockerignore` を使って不要ファイルをビルドコンテキストから除外する
- イメージは **immutable（不変）** として扱い、設定は環境変数で注入
- 開発時は `docker compose` で複数サービスをまとめて管理

> セキュリティ注意: シークレット（APIキー、秘密鍵、.env本体）をイメージに `COPY` しない。BuildKit secrets / runtime env / secret managerを使用する。

---

## 4) 30〜60分ミニラボ（初級）
**ゴール:** `nginx` コンテナで静的ページを公開し、運用で使う基本コマンドを一巡する

### 所要時間
30〜45分

### 手順
1. 作業フォルダ作成
```bash
mkdir -p docker-lab-01 && cd docker-lab-01
```

2. `index.html` 作成
```html
<h1>Hello Docker Magazine</h1>
<p>2026-05-26 Beginner Lab</p>
```

3. `Dockerfile` 作成
```Dockerfile
FROM nginx:1.27-alpine
COPY index.html /usr/share/nginx/html/index.html
EXPOSE 80
```

4. ビルド
```bash
docker build -t docker-mag-nginx:lab01 .
```

5. 起動
```bash
docker run --name docker-mag-web -d -p 8080:80 docker-mag-nginx:lab01
```

6. 動作確認
```bash
curl http://localhost:8080
```
ブラウザでも `http://localhost:8080` を確認。

7. ログ確認
```bash
docker logs docker-mag-web
```

8. 後片付け
```bash
docker stop docker-mag-web
docker rm docker-mag-web
```

---

## 5) コマンド・チートシート
```bash
# イメージ作成
docker build -t <image>:<tag> .

# 起動（フォアグラウンド）
docker run --name <container> -p <host_port>:<container_port> <image>:<tag>

# 起動（バックグラウンド）
docker run -d --name <container> -p <host_port>:<container_port> <image>:<tag>

# 稼働中コンテナ
docker ps

# 全コンテナ（停止含む）
docker ps -a

# ログ
docker logs -f <container>

# コンテナに入る
docker exec -it <container> sh

# 停止 / 削除
docker stop <container>
docker rm <container>
```

---

## 6) よくあるミス & 安全運用

### よくあるミス
- `-p` 指定ミスでアクセスできない
- コンテナ名重複で `Conflict` エラー
- `.dockerignore` 不備でビルドが遅い / 秘密情報混入
- `latest` タグ依存で再現性低下

### 安全運用
- 破壊的コマンドの前に必ず対象確認
  - `docker ps -a`
  - `docker images`
- **警告:** `docker system prune`, `docker image prune -a`, `docker rm -f`, `docker rmi` は削除影響が大きい。実行前に「何が消えるか」を確認する。
- 本番用途に近づくほど、非root実行・最小ベースイメージ・脆弱性スキャンを導入

---

## 7) 面接っぽい確認質問（1問）
**Q.** `docker run -p 8080:80 nginx` の `8080:80` は何を意味しますか？また、なぜこの指定が必要ですか？

---

## 8) 次の学習ステップ（公式ドキュメント中心）
- Docker Get Started: https://docs.docker.com/get-started/
- Dockerfile best practices: https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Multi-stage builds: https://docs.docker.com/build/building/multi-stage/
- Docker Compose overview: https://docs.docker.com/compose/
- Build cache optimization: https://docs.docker.com/build/cache/
- Secrets (Build/Runtime): https://docs.docker.com/build/building/secrets/

---

## 次号予告（Middle）
**前提知識（Prerequisites）:**
- `docker build/run/ps/logs/exec/stop/rm` を1回以上実行したこと
- ポート公開（`-p`）を理解していること

**次号テーマ候補:**
- Docker ComposeでAPI + DBを連携
- ボリュームで開発データを永続化
- ヘルスチェックと依存サービス起動順の設計
