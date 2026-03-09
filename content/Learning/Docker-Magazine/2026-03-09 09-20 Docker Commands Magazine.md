---
tags:
  - docker
  - containers
  - devops
  - learning
  - daily
---

# Docker Commands Magazine（2026-03-09）
[[Home]]

今日のテーマは、**Beginner → Middle → Advanced** の学習アークで、実務で使える Docker コマンド力を段階的に伸ばす構成です。

---

## 1) Topic + Level

### Beginner: `docker run` / `docker exec` / `docker logs` で開発コンテナを操作する

### Middle: `docker compose up` / `docker compose ps` / `docker compose logs` で複数サービスを開発運用する
**前提知識:**
- Beginner の内容（単体コンテナの起動・確認・ログ閲覧）
- イメージとコンテナの違い

### Advanced: `docker buildx build` とキャッシュ最適化で高速・再現性の高いビルドを行う
**前提知識:**
- Middle の内容（Compose でのサービス連携）
- Dockerfile の基本命令（FROM, COPY, RUN）

---

## 2) なぜ実アプリ開発で重要か

- **環境差分の削減:** チーム全員が同じコンテナ環境で動かせるため、「自分のPCでは動く」問題を減らせる。
- **デバッグ速度の向上:** `logs` / `exec` により、アプリ内部の状態確認が速い。
- **マルチサービス開発の現実対応:** API + DB + Redis など、実務の構成を `compose` で再現しやすい。
- **CI/CD 連携の基礎:** ビルド最適化やレイヤーキャッシュ理解は、デプロイ時間とコスト削減に直結。
- **セキュリティと運用性:** イメージ肥大化や秘密情報混入を防ぐ設計習慣が、後工程の事故を減らす。

---

## 3) Core Docker command explanations

### Beginner コマンド

- `docker run -d --name web -p 8080:80 nginx:alpine`
  - イメージからコンテナを起動。
  - `-d`: バックグラウンド実行
  - `--name`: コンテナ名固定（運用で扱いやすい）
  - `-p 8080:80`: ホスト8080をコンテナ80へ公開

- `docker ps`
  - 稼働中コンテナ一覧。ポートや名前、状態を確認。

- `docker logs -f web`
  - コンテナログ追跡。`-f` でリアルタイム監視。

- `docker exec -it web sh`
  - 稼働中コンテナ内でシェル操作。
  - デバッグ時に便利だが、本番運用での恒常運用手段にはしない（再現性のため）。

### Middle コマンド

- `docker compose up -d`
  - compose.yaml 定義の複数サービスをまとめて起動。

- `docker compose ps`
  - サービス単位で状態確認。

- `docker compose logs -f api`
  - 特定サービスのログを追跡。

- `docker compose down`
  - 停止＋ネットワーク等のクリーンアップ。

### Advanced コマンド

- `docker buildx build -t sample-api:dev --load .`
  - BuildKit ベースでビルド。高速化・拡張機能を利用。
  - `--load` でローカル Docker イメージストアに取り込む。

- `docker buildx build --platform linux/amd64,linux/arm64 -t yourrepo/sample-api:1.0 --push .`
  - マルチアーキテクチャイメージ作成＆レジストリへ push。

- `docker image ls`
  - イメージサイズ確認（肥大化の早期発見）。

---

## 4) アプリ開発時の Docker 利用（docs.docker.com ベストプラクティス準拠）

- **小さいベースイメージを選ぶ**（例: alpine/slim 系、ただし互換性は検証）。
- **マルチステージビルド**で、ビルドツールを最終イメージに残さない。
- **レイヤーキャッシュを意識した Dockerfile 順序**
  - 依存定義ファイル（package-lock.json, requirements.txt 等）を先に COPY。
- **`.dockerignore` を整備**し、不要ファイルをビルドコンテキストから除外。
- **機密情報をイメージに埋め込まない**
  - `ENV PASSWORD=...` や Dockerfile 直書きは避ける。
  - 開発時も secrets / env ファイル管理ルールを明確化。
- **コンテナは“使い捨て可能”を前提**に設計し、設定変更はイメージや compose 定義で再現。

---

## 5) 30-60分ミニラボ

### 目標
Nginx + 簡易API（任意言語）を Compose で起動し、ログ確認と再ビルドまで実施する。

### 手順（約45分）

1. 作業ディレクトリ作成
   ```bash
   mkdir -p docker-mag-lab && cd docker-mag-lab
   ```

2. `compose.yaml` 作成（最小構成）
   ```yaml
   services:
     web:
       image: nginx:alpine
       ports:
         - "8080:80"
   ```

3. 起動と確認
   ```bash
   docker compose up -d
   docker compose ps
   curl -I http://localhost:8080
   ```

4. ログ監視
   ```bash
   docker compose logs -f web
   ```

5. 停止・片付け
   ```bash
   docker compose down
   ```

6. （発展）独自 Dockerfile を作り `build:` 指定に変更し、`docker compose up --build -d` を試す。

### 到達チェック
- `up -d` から `ps` / `logs` / `down` まで一連操作できた
- ポート公開とサービス状態を説明できる
- 再ビルドの必要タイミング（Dockerfile変更時など）を説明できる

---

## 6) Command cheatsheet

```bash
# コンテナ操作
docker run -d --name web -p 8080:80 nginx:alpine
docker ps
docker logs -f web
docker exec -it web sh
docker stop web && docker rm web

# Compose 操作
docker compose up -d
docker compose ps
docker compose logs -f
docker compose down

# ビルド
docker build -t myapp:dev .
docker buildx build -t myapp:dev --load .

# 調査
docker image ls
docker system df
```

---

## 7) よくあるミスと安全な運用

- **ミス:** `latest` タグ前提で動作差分が出る
  - **対策:** バージョンタグ固定（例: `nginx:1.27-alpine`）

- **ミス:** `.env` や秘密鍵をイメージに COPY
  - **対策:** `.dockerignore`、Secrets 管理、Git 追跡除外を徹底

- **ミス:** いきなり破壊的クリーンアップを実行
  - **対策:** 実行前に対象確認（`docker ps -a`, `docker image ls`, `docker volume ls`）
  - **警告:** `docker system prune`, `docker image prune -a`, `docker rm -f`, `docker rmi` はデータ損失リスクあり。必要性と対象を確認してから実行。

- **ミス:** コンテナ内手作業で設定を変え、本番手順に反映されない
  - **対策:** 変更は Dockerfile / compose / スクリプトに戻して再現可能にする

---

## 8) 面接風クエスチョン（1問）

**Q.** `docker compose up --build -d` と `docker compose up -d` の違いは？実務でどのタイミングで使い分けますか？

**期待したい観点:**
- Dockerfile やビルドコンテキスト変更時は `--build` が必要
- イメージが既に最新なら `up -d` で十分
- CI では再現性重視で明示ビルドを組み込むことが多い

---

## 9) 次の学習リソース（公式優先）

- Docker Docs（総合）
  - https://docs.docker.com/
- Get Started
  - https://docs.docker.com/get-started/
- Dockerfile best practices
  - https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Multi-stage builds
  - https://docs.docker.com/build/building/multi-stage/
- BuildKit / Buildx
  - https://docs.docker.com/build/
- Docker Compose overview
  - https://docs.docker.com/compose/
- Compose file reference
  - https://docs.docker.com/reference/compose-file/
- Docker secrets（機密情報管理の基本）
  - https://docs.docker.com/engine/swarm/secrets/

---

次号予告（学習アーク継続）:
- Beginner: ボリューム基礎（データ永続化）
- Middle: 開発用ホットリロード構成
- Advanced: セキュアな本番向けイメージ最適化（ユーザー権限・SBOM・スキャン導入）
