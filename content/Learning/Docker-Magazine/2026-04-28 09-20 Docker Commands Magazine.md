# 2026-04-28 09:20 Docker Commands Magazine

#docker #containers #devops #learning #daily  
[[Home]]

---

## 今日のテーマ
**Dockerコマンドで学ぶ開発フロー実践：ローカル起動 → デバッグ → 安全なクリーンアップ**

学習アーク（段階式）:
1. **Beginner**: `docker run` / `docker ps` / `docker logs`
2. **Middle**: `docker exec` / `docker compose up` / `docker compose logs`
3. **Advanced**: `docker buildx build` / マルチステージビルド / 安全なクリーンアップ運用

---

## 1) Topic + Level

### 🟢 Beginner
**トピック:** コンテナを起動・確認・停止する基本運用

### 🟡 Middle
**トピック:** Composeで複数サービスをまとめて動かし、調査する
**前提条件:**
- Beginnerの内容（コンテナ起動・停止・ログ確認）ができる
- Docker Engine / Docker Desktop が導入済み

### 🔴 Advanced
**トピック:** Build最適化と本番を意識したセキュア運用
**前提条件:**
- Middleの内容（Compose運用とログ調査）ができる
- Dockerfileの基本構文（`FROM`, `RUN`, `COPY`）を理解している

---

## 2) なぜ実アプリ開発で重要か

- 開発現場では「**同じ環境を全員で再現**」できることが品質と速度を左右する。
- 問題の切り分け（アプリ問題か、環境問題か）を速くするには、コンテナの状態・ログ・プロセス操作が必須。
- 本番運用では、イメージサイズ・ビルド速度・秘密情報の扱いがそのままコストと事故率に影響する。

---

## 3) Core Docker command explanations

### Beginnerコマンド
- `docker run -d --name web -p 8080:80 nginx:alpine`
  - `-d`: バックグラウンド実行
  - `--name`: コンテナに名前を付ける
  - `-p 8080:80`: ホスト8080 → コンテナ80を公開
- `docker ps` / `docker ps -a`
  - 稼働中 / 全コンテナの確認
- `docker logs -f web`
  - `-f` でログ追尾
- `docker stop web && docker rm web`
  - 停止して削除（安全な基本手順）

### Middleコマンド
- `docker compose up -d`
  - `compose.yml` のサービス群を一括起動
- `docker compose ps`
  - サービス状態を確認
- `docker compose logs -f app`
  - 特定サービスのログを追う
- `docker exec -it <container> sh`
  - 実行中コンテナへ入って調査

### Advancedコマンド
- `docker buildx build --platform linux/arm64 -t myapp:dev .`
  - BuildKit/Buildxで拡張ビルド
- `docker image ls` / `docker history <image>`
  - イメージサイズやレイヤを確認
- `docker system df`
  - ディスク使用量の可視化

⚠️ **破壊的コマンド注意**
- `docker system prune`, `docker image prune -a`, `docker rm -f`, `docker rmi`
  - 未使用リソースやコンテナ/イメージを削除するため、事前確認必須。
  - 実行前に `docker ps -a`, `docker image ls`, `docker volume ls` を確認すること。

---

## 4) アプリ開発時のDocker活用（docs.docker.comベストプラクティス準拠）

- **1プロセス/1コンテナを基本に設計**し、複数サービスはComposeで分離。
- **軽量ベースイメージ**（例: alpine系）や**マルチステージビルド**で配布物を小さくする。
- **`.dockerignore` を整備**して不要ファイルをビルドコンテキストに含めない。
- **秘密情報をイメージに焼き込まない**（`ENV`固定値や`COPY .env`を避ける）。
  - Secretsは実行時注入（環境変数、シークレット管理）を使う。
- **最小権限**（不要なroot実行を避ける）を意識する。

---

## 5) 30-60分ハンズオンミニラボ

**目標:** Nginxコンテナを起動し、Compose化して、ログ調査と安全な後片付けまで体験する。

### Step A（10-15分）Beginner
1. 起動:
   ```bash
   docker run -d --name lab-web -p 8080:80 nginx:alpine
   ```
2. 確認:
   ```bash
   docker ps
   curl -I http://localhost:8080
   docker logs lab-web
   ```
3. 停止:
   ```bash
   docker stop lab-web
   docker rm lab-web
   ```

### Step B（15-20分）Middle
1. `compose.yml` を作成（`web`サービスのみでOK）
2. 起動:
   ```bash
   docker compose up -d
   docker compose ps
   ```
3. ログ確認:
   ```bash
   docker compose logs -f web
   ```
4. コンテナ内確認:
   ```bash
   docker exec -it <webコンテナIDまたは名前> sh
   ```

### Step C（15-25分）Advanced
1. 簡単なDockerfileを作り、Buildxでビルド:
   ```bash
   docker buildx build -t lab-nginx:custom .
   ```
2. レイヤと容量確認:
   ```bash
   docker history lab-nginx:custom
   docker system df
   ```
3. **安全な掃除（確認してから）**:
   ```bash
   docker compose down
   # 注意して対象を確認
   docker image ls
   # 必要なものだけ削除
   docker rmi lab-nginx:custom
   ```

---

## 6) Command Cheatsheet

```bash
# 起動/確認
docker run -d --name app -p 8080:80 nginx:alpine
docker ps
docker logs -f app

# 停止/削除
docker stop app
docker rm app

# Compose
docker compose up -d
docker compose ps
docker compose logs -f
docker compose down

# ビルド/調査
docker buildx build -t myapp:dev .
docker image ls
docker history myapp:dev
docker system df
```

---

## 7) よくあるミス & 安全運用

- ミス: `latest`タグ固定で再現不能になる  
  → 対策: バージョンタグを明示（例: `nginx:1.27-alpine`）
- ミス: `.env` や秘密鍵を `COPY` してしまう  
  → 対策: `.dockerignore` とシークレット注入を徹底
- ミス: `docker system prune -a` を勢いで実行  
  → 対策: 事前確認 + 影響範囲を把握してから実行
- ミス: root前提で開発して権限事故  
  → 対策: 非rootユーザー実行を検討（Dockerfileで`USER`）

---

## 8) 面接っぽい質問（1問）

**Q.** Dockerfileでレイヤキャッシュを効かせてビルドを高速化するには、`COPY` と `RUN` の順序をどう設計しますか？理由も説明してください。

---

## 9) 次の一歩（公式優先）

- Docker Docs Home: https://docs.docker.com/
- Get Started: https://docs.docker.com/get-started/
- Dockerfile best practices: https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Compose overview: https://docs.docker.com/compose/
- Buildx / BuildKit: https://docs.docker.com/build/
- Multi-stage builds: https://docs.docker.com/build/building/multi-stage/
- Docker Engine security: https://docs.docker.com/engine/security/

---

明日の予告: **ボリューム/ネットワークを使った「開発データ永続化 + サービス間通信」実践編**
