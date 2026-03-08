---
tags: [docker, containers, devops, learning, daily]
created: 2026-03-04
---

# 2026-03-04 09:20 Docker Commands Magazine
[[Home]]

今日のテーマは、**Beginner → Middle → Advanced**の順で段階的に学ぶ「Dockerコマンド実践アーク」です。  
実務での使い方・安全性・面接対策までを1本にまとめています。

---

## 1) Topic + Level

### Beginner
**トピック:** `docker run` / `docker ps` / `docker logs` で「まず動かして観察する」

### Middle
**トピック:** `docker build` / `docker exec` / `docker compose up` で開発環境を再現する

**前提知識（Prerequisites）**
- Beginnerレベルのコマンドを説明できる
- イメージとコンテナの違いを理解している
- ポート公開（`-p`）の意味を知っている

### Advanced
**トピック:** マルチステージビルド + ヘルスチェック + ボリューム運用 + 安全なクリーンアップ

**前提知識（Prerequisites）**
- Dockerfileでアプリイメージを作成できる
- Docker Composeの基本（service, ports, volumes）がわかる
- アプリのログ/プロセス確認ができる

---

## 2) Why it matters for real app development

実アプリ開発では、Dockerコマンドの理解が次の価値に直結します。

- **再現性**: 「自分のPCでは動く」を減らし、チーム全員で同じ環境を使える
- **オンボーディング高速化**: 新メンバーが数コマンドで起動可能
- **CI/CDとの接続**: ローカルと本番の差分を縮小し、デプロイ事故を減らす
- **障害対応力向上**: `logs` / `exec` / `inspect`で問題切り分けが速くなる
- **セキュリティ向上**: イメージ最小化・秘密情報分離・不要リソース削減を習慣化できる

---

## 3) Core Docker command explanations

### Beginnerコマンド
- `docker run -d -p 8080:80 --name web nginx:alpine`
  - `-d`: バックグラウンド実行
  - `-p 8080:80`: ホスト8080 → コンテナ80
  - `--name`: 識別しやすい名前付け
- `docker ps` / `docker ps -a`
  - 稼働中 / 全コンテナ一覧を確認
- `docker logs -f web`
  - ログ追跡で挙動確認

### Middleコマンド
- `docker build -t myapp:dev .`
  - Dockerfileからイメージ作成
- `docker exec -it myapp sh`
  - 稼働中コンテナへ入って調査
- `docker compose up -d`
  - 複数サービス（app/dbなど）をまとめて起動
- `docker compose logs -f app`
  - サービス単位でログ監視

### Advancedコマンド
- `docker build --target runtime -t myapp:prod .`
  - マルチステージの最終ステージのみをビルドし軽量化
- `docker inspect <container>`
  - 詳細状態（ネットワーク/マウント/環境変数）確認
- `docker stats`
  - CPU/メモリ使用量のリアルタイム監視
- `docker volume ls` / `docker volume inspect`
  - データ永続化の安全確認

---

## 4) How Docker is used while building apps（docs.docker.com準拠の実務パターン）

docs.docker.comのベストプラクティスに沿った流れ:

1. **軽量ベースイメージを選ぶ**（例: alpine系、distroless検討）
2. **マルチステージビルド**でビルド依存を分離
3. **`.dockerignore`整備**で不要ファイルを送らない（速度/漏えい対策）
4. **秘密情報をイメージに含めない**
   - NG: Dockerfile/composeに平文シークレット直書き
   - OK: 環境変数管理、シークレット機能、CI側注入
5. **1コンテナ1責務を意識**（アプリ・DB・キューを分離）
6. **Composeでローカル統合環境を定義**し、チーム共有
7. **ヘルスチェック導入**で依存サービス起動順問題を緩和

---

## 5) 30-60 minute hands-on mini lab

### 目標
Node.js API + Redis を Composeで起動し、ログ確認・ヘルス確認・安全な停止まで実施。

### 所要時間
約45分

### 手順
1. **準備（5分）**
   - 任意の作業ディレクトリ作成
   - `Dockerfile` と `docker-compose.yml` を用意

2. **ビルド＆起動（10分）**
   - `docker compose up -d --build`
   - `docker compose ps` で状態確認

3. **動作確認（10分）**
   - `curl http://localhost:3000/health`
   - `docker compose logs -f app` でアクセスログ確認

4. **コンテナ内調査（10分）**
   - `docker compose exec app sh`
   - 環境変数・プロセス・ファイル確認

5. **リソース確認（5分）**
   - `docker stats`

6. **安全なクリーンアップ（5分）**
   - `docker compose down`
   - 必要なら未使用リソース確認後に削除

> ⚠️ 注意: `docker system prune -a` や `docker image rm -f` は、**本当に不要なリソースか確認してから**実行。開発中イメージやボリュームを誤削除すると復旧コストが高いです。

---

## 6) Command cheatsheet

```bash
# 起動・確認
docker run -d -p 8080:80 --name web nginx:alpine
docker ps
docker logs -f web

# ビルド・実行
docker build -t myapp:dev .
docker run --rm -p 3000:3000 myapp:dev

# Compose
docker compose up -d --build
docker compose ps
docker compose logs -f app
docker compose exec app sh
docker compose down

# 調査
docker inspect <container_or_image>
docker stats

# クリーンアップ（要注意）
docker image ls
docker container ls -a
docker volume ls
# 破壊的: 実行前に必ず確認
# docker system prune -a
# docker image rm -f <image>
# docker rm -f <container>
```

---

## 7) Common mistakes and safe practices

### よくあるミス
- Dockerfileに`.env`や秘密鍵をCOPYしてしまう
- `latest`タグ固定で再現不能になる
- `docker compose down -v` を深く考えず実行し、DBデータ消失
- 不要な`--privileged`やroot実行
- ログ/監視なしで「動いてるはず」運用

### 安全策
- `.dockerignore`とシークレット管理を最優先
- イメージタグはバージョン/コミットSHAで明示
- 破壊的コマンド前に `ls` / `ps -a` / `volume ls` で確認
- 非rootユーザー実行を検討
- 定期的に脆弱性スキャン（Docker Scout等）

---

## 8) One interview-style question

**質問:**  
「`docker compose up --build` と `docker compose up` の違いは？ 実務で使い分ける基準を説明してください。」

**回答の方向性（要点）:**
- `--build` はイメージ再ビルドを伴う（Dockerfile変更時に必要）
- 変更がコードのbind mountのみなら再ビルド不要な場合がある
- CIや本番前検証では再ビルドして差分混入を防ぐ

---

## 9) Next-step resources（公式優先）

- Docker Docs Home: https://docs.docker.com/
- Get Started: https://docs.docker.com/get-started/
- Dockerfile best practices: https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Multi-stage builds: https://docs.docker.com/build/building/multi-stage/
- Compose docs: https://docs.docker.com/compose/
- Compose file reference: https://docs.docker.com/compose/compose-file/
- Volumes: https://docs.docker.com/storage/volumes/
- Engine security: https://docs.docker.com/engine/security/
- Docker Scout: https://docs.docker.com/scout/

---

明日の予告: **ネットワーク編（bridge/host/compose network）**で、サービス間通信とセキュアな公開範囲を実践します。
