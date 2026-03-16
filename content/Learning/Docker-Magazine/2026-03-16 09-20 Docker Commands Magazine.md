---
tags: [docker, containers, devops, learning, daily]
created: 2026-03-16 09:20
---

# Docker Commands Magazine — 2026-03-16
[[Home]]

## 今日のテーマ
**テーマ:** コンテナ起動から本番運用を見据えた実践コマンド
**学習アーク:** Beginner → Middle → Advanced

---

## 1) Topic + Level

### 🟢 Beginner: `docker run` / `docker ps` / `docker logs` で「動かして観察する」

### 🟡 Middle: `docker compose up` / `docker compose logs` / `docker exec` で「複数サービス開発」
**前提知識（Prerequisites）**
- Beginnerの内容（単一コンテナを起動・停止・ログ確認できる）
- Dockerfileの基本（`FROM`, `COPY`, `RUN` を見たことがある）

### 🔴 Advanced: `docker buildx build` / マルチステージビルド / 最小権限実行で「安全に配布する」
**前提知識（Prerequisites）**
- Middleの内容（Composeでアプリ＋DBを扱える）
- イメージレイヤーとキャッシュの概念
- CI/CDの基本（ビルド→テスト→配布の流れ）

---

## 2) なぜ実アプリ開発で重要か
- ローカル環境差異（OS・ライブラリ差）を減らし、**「自分のPCでは動く」問題を減らす**。
- 開発・テスト・本番で同じイメージを使えるため、**再現性が高い**。
- Composeで依存サービス（DB/Redis等）をコード化でき、**オンボーディングが速い**。
- Buildxとマルチステージにより、**軽量で安全なイメージ配布**ができる。

---

## 3) コアDockerコマンド解説

### Beginnerコマンド
- `docker run -d --name web -p 8080:80 nginx:alpine`
  - `-d`: バックグラウンド起動
  - `--name`: コンテナ名
  - `-p 8080:80`: ホスト8080→コンテナ80を公開
- `docker ps` / `docker ps -a`
  - 起動中 / 全コンテナ一覧
- `docker logs -f web`
  - ログ追跡（`Ctrl+C`で追跡停止）
- `docker stop web && docker rm web`
  - 停止と削除を分離して安全に実施

### Middleコマンド
- `docker compose up -d`
  - 複数サービスを定義に沿って起動
- `docker compose ps`
  - サービス状態確認
- `docker compose logs -f app`
  - 特定サービスのログ追跡
- `docker exec -it <container> sh`
  - 実行中コンテナへ入って調査

### Advancedコマンド
- `docker buildx build --platform linux/amd64,linux/arm64 -t yourorg/app:1.0 --push .`
  - マルチアーキテクチャビルド＆レジストリへpush
- `docker image inspect yourorg/app:1.0`
  - イメージ詳細（設定、レイヤー情報）
- `docker scout quickview yourorg/app:1.0`（環境導入済みの場合）
  - 脆弱性や改善の確認

---

## 4) 実アプリ構築での使い方（docs.docker.comベストプラクティス準拠）
- **小さく保つ:** マルチステージビルドで最終イメージを最小化。
- **1コンテナ1責務:** Web/API/Worker/DB をComposeで分離。
- **設定は外出し:** 環境変数・`.env`を活用（ただし秘密情報の取り扱いは後述）。
- **非root実行:** 可能な限り `USER` を設定して最小権限。
- **レイヤーキャッシュ最適化:** 依存関係インストールを先に分離してビルド高速化。
- **不要ファイル除外:** `.dockerignore` で `node_modules`, `.git`, ログ等を除外。

公式参照:
- https://docs.docker.com/build/building/best-practices/
- https://docs.docker.com/compose/
- https://docs.docker.com/develop/

---

## 5) 30〜60分ミニラボ

### 目標
Node.js API + Redis をComposeで起動し、ログ確認・コンテナ内調査まで行う。

### 手順（約45分）
1. プロジェクト作成
   - `mkdir docker-lab && cd docker-lab`
2. `app.js`（簡易API）と `package.json` を用意
3. `Dockerfile` 作成（`node:20-alpine` ベース）
4. `compose.yml` 作成（`app`, `redis` サービス）
5. 起動
   - `docker compose up -d --build`
6. 動作確認
   - `docker compose ps`
   - `curl http://localhost:3000`
7. ログ確認
   - `docker compose logs -f app`
8. コンテナ調査
   - `docker exec -it <app_container> sh`
9. 後片付け
   - `docker compose down`

### 追加チャレンジ（時間があれば）
- `healthcheck` を追加
- `depends_on` + ヘルス条件を検討
- マルチステージ化でサイズ比較

---

## 6) コマンドチートシート
- 起動: `docker run ...` / `docker compose up -d`
- 状態: `docker ps` / `docker compose ps`
- ログ: `docker logs -f <name>` / `docker compose logs -f <service>`
- 侵入: `docker exec -it <container> sh`
- 停止: `docker stop <container>` / `docker compose stop`
- 削除: `docker rm <container>` / `docker compose down`
- ビルド: `docker build -t app:dev .` / `docker buildx build ...`
- 画像一覧: `docker images`

---

## 7) よくあるミスと安全運用

### よくあるミス
- 秘密情報（APIキー/DBパスワード）をDockerfileに`ENV`で焼き込む。
- `latest`タグ固定で再現性を失う。
- すぐに `docker system prune -a` を実行して必要データまで消す。
- rootで実行し続ける。

### 安全運用のポイント
- **秘密情報はイメージに含めない。**
  - `.env`やシークレット管理を使い、Gitにコミットしない。
- **削除系コマンドは対象確認してから実行。**
  - `docker ps -a`, `docker images`, `docker volume ls` で確認。
- **破壊的コマンド注意（要確認）**
  - `docker system prune`, `docker image prune -a`, `docker rm -f`, `docker rmi`
  - 実行前に「本当に不要か」を必ず確認。
- **最小権限・最小イメージ**を意識して攻撃面を減らす。

---

## 8) 面接対策Q（1問）
**Q.** `docker run` と `docker compose up` の使い分けを、チーム開発の観点で説明してください。

**答えるポイント（例）**
- `docker run`: 単体コンテナの試験・検証に向く。
- `docker compose up`: 複数依存を定義化し再現性を上げ、チーム共有しやすい。
- IaC的に履歴管理できるため、長期運用はComposeが有利。

---

## 9) 次の一歩（公式ドキュメント中心）
- Docker Build best practices
  - https://docs.docker.com/build/building/best-practices/
- Dockerfile reference
  - https://docs.docker.com/reference/dockerfile/
- Docker Compose docs
  - https://docs.docker.com/compose/
- Compose file reference
  - https://docs.docker.com/reference/compose-file/
- Development workflows
  - https://docs.docker.com/develop/
- Engine security
  - https://docs.docker.com/engine/security/

---

## 明日の予告
次回は **「Dockerネットワーク基礎→Composeネットワーク設計→本番相当の分離戦略」** を扱います。
