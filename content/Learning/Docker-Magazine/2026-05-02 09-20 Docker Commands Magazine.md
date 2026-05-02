# 2026-05-02 Docker Commands Magazine

Tags: #docker #containers #devops #learning #daily  
Links: [[Home]]

---

## 今日のテーマ
**Dockerコマンド実践アーク：開発コンテナ運用の基礎 → 改善 → 最適化**

この号は、**Beginner → Middle → Advanced** の3段階で進みます。  
狙いは「コマンドを覚える」だけでなく、**実アプリ開発で安全に使いこなす**ことです。

---

## 1) Topic + Level

### [Beginner] コンテナのライフサイクルを確実に扱う
- 対象: Dockerを使い始めた人
- ゴール: `run / ps / logs / exec / stop / rm` を安全に使える

### [Middle] 開発効率を上げるイメージ管理とCompose運用
- 前提知識:
  - Beginner内容を理解している
  - Dockerfileの基本命令（`FROM`, `WORKDIR`, `COPY`, `RUN`, `CMD`）を見たことがある
- ゴール: `build`, タグ戦略、`docker compose up/down` を実務目線で使える

### [Advanced] セキュアで再現性の高いビルド運用
- 前提知識:
  - Middle内容を理解している
  - レイヤーキャッシュ・マルチステージビルドの概念を知っている
- ゴール: BuildKit, キャッシュ最適化, secret取り扱い, クリーンアップ方針を設計できる

---

## 2) なぜ実アプリ開発で重要か
- **再現性**: 開発者ごとの差分を減らし「自分のPCでは動く問題」を減らす
- **速度**: ビルド/起動の待ち時間を短縮して開発サイクルを速める
- **安全性**: 不要な権限・秘密情報漏えい・雑な削除操作による事故を防ぐ
- **移植性**: ローカル→CI→本番で同じアーティファクトを扱える

---

## 3) Core Docker command explanations

### Beginnerで必須
- `docker run --name app -p 8080:8080 IMAGE`
  - コンテナ起動。`--name`で識別しやすく、`-p`でポート公開
- `docker ps` / `docker ps -a`
  - 実行中/停止済みコンテナ確認
- `docker logs -f app`
  - ログ追跡。障害切り分けの第一歩
- `docker exec -it app sh`
  - 稼働中コンテナに入って調査
- `docker stop app` → `docker rm app`
  - 停止後に削除（順序を守る）

### Middleで強化
- `docker build -t myapp:dev .`
  - イメージ作成。タグに環境・用途を明示
- `docker images`
  - イメージ一覧・サイズ確認
- `docker compose up -d`
  - 複数サービスをまとめて起動
- `docker compose logs -f`
  - サービス横断でログ追跡
- `docker compose down`
  - 構成単位で停止・削除

### Advancedで最適化
- `DOCKER_BUILDKIT=1 docker build -t myapp:dev .`
  - BuildKit有効化で高速化・高度機能利用
- `docker buildx build --progress=plain .`
  - 詳細ビルドログで詰まり箇所可視化
- `docker system df`
  - Docker利用容量確認（削除前の事実確認）

> ⚠️ 破壊的コマンド注意:  
> `docker system prune`, `docker image prune -a`, `docker rm -f`, `docker rmi` は不要資産を消せますが、**必要なコンテナ/イメージも消える可能性**があります。実行前に `docker ps -a` / `docker images` / `docker system df` で対象確認してください。

---

## 4) 実アプリ開発での使い方（docs.docker.com準拠の実践）
- **小さく安全なベースイメージを使う**（攻撃面積とサイズを減らす）
- **マルチステージビルド**でランタイムに不要なビルドツールを含めない
- **`.dockerignore`を整備**して不要ファイル送信を防ぐ（速度・秘匿性向上）
- **イミュータブルなイメージ運用**（同じタグで中身が変わらないよう管理）
- **Composeで依存サービスを定義**し、ローカル再現性を上げる
- **シークレットをイメージ/compose直書きしない**
  - NG: Dockerfileにトークンを`ENV`で埋め込み
  - 推奨: 実行時注入（環境変数、secret管理機構、CI secret）

---

## 5) 30-60分ミニラボ
**題材: Node.js API + Redis をComposeで起動し、ログ確認と安全な片付けまで実施**

### 手順（目安45分）
1. プロジェクト雛形準備（5分）
2. Dockerfile作成（10分）
3. `docker-compose.yml`作成（10分）
4. 起動・疎通確認（10分）
5. ログ/中身確認（5分）
6. 停止・後片付け（5分）

### 最小コマンドフロー
```bash
# ビルド
DOCKER_BUILDKIT=1 docker compose build

# 起動
docker compose up -d

# 状態確認
docker compose ps

# ログ確認
docker compose logs -f api

# コンテナ内確認
docker compose exec api sh

# 停止
docker compose down
```

### チャレンジ（余力があれば）
- `.dockerignore`追加前後でビルド時間比較
- Dockerfileをマルチステージ化してイメージサイズ比較

---

## 6) Command cheatsheet
```bash
# コンテナ
docker run --name app -p 8080:8080 myapp:dev
docker ps
docker logs -f app
docker exec -it app sh
docker stop app && docker rm app

# イメージ
docker build -t myapp:dev .
docker images
docker image inspect myapp:dev

# Compose
docker compose up -d
docker compose ps
docker compose logs -f
docker compose down

# 容量確認（削除前）
docker system df
```

---

## 7) よくあるミスと安全策
- ミス: `latest`タグ前提で動作差分発生
  - 安全策: バージョンタグ固定（例: `node:22-alpine`）
- ミス: `COPY . .`で秘密情報まで送る
  - 安全策: `.dockerignore`に `.env`, `.git`, `node_modules` 等を追加
- ミス: root実行前提のコンテナ
  - 安全策: 可能なら非rootユーザーで実行
- ミス: 不要になったからと即`prune -a`
  - 安全策: まず `docker system df` と一覧確認、削除対象を明示
- ミス: Composeファイルにパスワード直書き
  - 安全策: secret管理・環境注入、リポジトリへ平文コミットしない

---

## 8) 面接風クエスチョン（1問）
**質問:**  
「開発環境でDockerイメージのビルドが遅いです。原因調査と改善を、コマンドとDockerfile観点でどう進めますか？」

**答える際のポイント:**
- `buildx --progress=plain` でボトルネック特定
- キャッシュ効く順序（依存定義→インストール→アプリコード）
- `.dockerignore`最適化
- マルチステージ導入
- 不要な再ビルドを避けるCompose運用

---

## 9) 次の一歩（公式中心）
- Docker Docs Home: https://docs.docker.com/
- Get Started: https://docs.docker.com/get-started/
- Dockerfile best practices: https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Multi-stage builds: https://docs.docker.com/build/building/multi-stage/
- BuildKit overview: https://docs.docker.com/build/buildkit/
- Compose getting started: https://docs.docker.com/compose/gettingstarted/
- Docker Engine security: https://docs.docker.com/engine/security/

---

### 明日の予告
次号は **[Beginner] ボリュームと永続化** → **[Middle] バックアップ/復元** → **[Advanced] 本番データ運用の設計** を扱います。
