# Docker Commands Magazine — 2026-03-18
#docker #containers #devops #learning #daily
[[Home]]

---

## 今号のテーマ
**実践アプリ開発で押さえる Docker コマンド学習アーク**  
Beginner → Middle → Advanced の順で、同じ「アプリを安全にコンテナ運用する」流れを段階的に深めます。

---

## Level 1: Beginner
### 1) Topic + Level
**トピック:** 「`docker run` / `docker ps` / `docker logs` でアプリを動かして観察する」  
**レベル:** Beginner

### 2) なぜ実務で重要か
- ローカル環境差分（OS/ライブラリ違い）を減らし、再現性のある開発ができる
- 「起動したけど動かない」をログで切り分ける基本動作を身につけられる
- まずは**実行・確認・停止**の基本ループが最重要

### 3) コアコマンド解説
- `docker run -d --name web -p 8080:80 nginx:alpine`
  - `-d`: バックグラウンド起動
  - `--name`: コンテナ名を付ける
  - `-p 8080:80`: ホスト8080 → コンテナ80を公開
- `docker ps`
  - 起動中コンテナ確認
- `docker logs -f web`
  - `-f` でログを追従
- `docker stop web && docker rm web`
  - 停止して削除（`rm -f` は強制なので通常は避ける）

### 4) アプリ開発時の使い方（Docker公式ベストプラクティス寄り）
- 依存ミドルウェア（DB、Redis、Nginx）をコンテナで起動して開発再現性を上げる
- 「1コンテナ1責務」を意識（公式の設計思想）
- 一時検証は disposable（捨てやすい）に保つ

### 5) 30〜60分ミニラボ
1. `nginx:alpine` を `docker run` で起動
2. ブラウザで `http://localhost:8080` を表示
3. `docker logs -f web` でアクセスログを確認
4. 別ポート（8081）でもう1つ起動し、ポート競合を体験
5. 停止・削除まで実施

### 6) Cheatsheet
```bash
docker run -d --name web -p 8080:80 nginx:alpine
docker ps
docker logs -f web
docker stop web
docker rm web
```

### 7) よくあるミス & 安全策
- ミス: `-p` 指定忘れでアクセス不能
- ミス: コンテナ名重複で起動失敗
- 安全策: まず `docker ps -a` で状態確認してから削除
- 注意: `docker rm -f` は強制終了を伴うため、原因調査前に使わない

### 8) 面接風質問
「`docker run -p 8080:80` の左右の数字は何を意味し、逆にすると何が変わる？」

### 9) 次の一歩（公式中心）
- Docker Get Started: https://docs.docker.com/get-started/
- `docker run` リファレンス: https://docs.docker.com/engine/reference/commandline/run/

---

## Level 2: Middle
### 1) Topic + Level
**トピック:** 「`docker build` / `docker exec` / `docker compose up` で開発環境を整える」  
**レベル:** Middle  
**前提知識:** Beginner の内容（run/ps/logs/stop/rm、ポート公開の理解）

### 2) なぜ実務で重要か
- チーム開発では「同じ Dockerfile / compose」で環境差分を最小化できる
- アプリ＋DBの複数サービス連携をローカルで再現できる
- CI/CD の前段として「ビルドできる状態」を作る基礎になる

### 3) コアコマンド解説
- `docker build -t myapp:dev .`
  - Dockerfile からイメージ作成
- `docker exec -it myapp sh`
  - 起動中コンテナに入って診断
- `docker compose up -d`
  - 複数サービスを一括起動
- `docker compose logs -f app`
  - サービス単位でログ追跡
- `docker compose down`
  - 構成を停止

### 4) アプリ開発時の使い方（Docker公式ベストプラクティス寄り）
- `.dockerignore` を整備してビルドコンテキストを最小化
- `Dockerfile` レイヤーキャッシュを活用（依存インストールは先に）
- Compose で app/db を分離し、設定は環境変数で注入
- **秘密情報をイメージに焼き込まない**（`ENV PASSWORD=...` 直書き禁止）

### 5) 30〜60分ミニラボ
1. 簡単なWebアプリ（Node/Pythonどちらでも）用 Dockerfile 作成
2. `docker build -t myapp:dev .`
3. `docker compose.yml` で app + postgres を定義
4. `docker compose up -d` で起動
5. `docker compose logs -f` で接続エラーを確認・修正
6. `docker exec -it` で app コンテナに入り環境変数確認

### 6) Cheatsheet
```bash
docker build -t myapp:dev .
docker images
docker exec -it myapp sh
docker compose up -d
docker compose ps
docker compose logs -f app
docker compose down
```

### 7) よくあるミス & 安全策
- ミス: `COPY . .` で不要ファイルまで含みイメージ肥大化
- ミス: `latest` タグ依存で再現性低下
- ミス: 秘密情報を Dockerfile/compose に平文記載
- 安全策: `.env` + Secret 管理、最小ベースイメージ、固定タグ運用
- 注意: `docker rmi` は他プロジェクト影響の可能性があるため依存確認してから

### 8) 面接風質問
「Dockerfile の命令順がビルド時間に影響する理由を、レイヤーキャッシュの観点で説明してください。」

### 9) 次の一歩（公式中心）
- Dockerfile best practices: https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Compose overview: https://docs.docker.com/compose/
- Compose file reference: https://docs.docker.com/compose/compose-file/

---

## Level 3: Advanced
### 1) Topic + Level
**トピック:** 「イメージ最適化・脆弱性低減・安全なクリーンアップ運用」  
**レベル:** Advanced  
**前提知識:** Middle の内容（Dockerfile/Compose/ログ調査、複数サービス運用）

### 2) なぜ実務で重要か
- 本番運用ではサイズ、起動速度、セキュリティ、保守性がコストに直結
- 脆弱なベースイメージや不要パッケージは攻撃面を広げる
- クリーンアップコマンド誤用は障害やデータ喪失の原因になる

### 3) コアコマンド解説
- `docker buildx build --platform linux/amd64,linux/arm64 -t myorg/myapp:1.0 --push .`
  - マルチアーキ対応ビルド
- `docker image ls` / `docker system df`
  - 容量・不要物の可視化
- `docker scout quickview myorg/myapp:1.0`（利用可能環境なら）
  - イメージのセキュリティ確認
- `docker compose down --remove-orphans`
  - 迷子コンテナ整理

### 4) アプリ開発時の使い方（Docker公式ベストプラクティス寄り）
- マルチステージビルドでランタイムを最小化
- 非rootユーザー実行（`USER`）を標準化
- ヘルスチェック導入で障害検知しやすくする
- SBOM/脆弱性確認を CI に組み込む
- Secret は Docker secrets / 外部Secret Manager 側で扱う

### 5) 30〜60分ミニラボ
1. 既存 Dockerfile をマルチステージ化（builder/runtime 分離）
2. runtime 側を軽量イメージ化し、非rootユーザー化
3. ビルド前後で `docker image ls` サイズ比較
4. `docker system df` でディスク利用確認
5. （可能なら）Scoutで脆弱性差分を確認

### 6) Cheatsheet
```bash
docker buildx build --platform linux/amd64,linux/arm64 -t myorg/myapp:1.0 .
docker image ls
docker system df
docker compose down --remove-orphans
# 破壊的操作: 実行前に必ず確認
# docker system prune
# docker image prune -a
```

### 7) よくあるミス & 安全策
- ミス: `docker system prune -a` を何も確認せず実行
- ミス: 本番で root 実行のまま
- ミス: build context に `.env` や鍵を含める
- 安全策:
  - **破壊的クリーンアップ前に必ず警告:** 削除対象を `docker system df` / `docker image ls` で確認
  - `prune/rmi/rm -f` は「対象を明示」してから実行
  - 秘密情報はイメージ・composeへ直書きしない

### 8) 面接風質問
「マルチステージビルドは、セキュリティと配布サイズの両面でなぜ有効ですか？」

### 9) 次の一歩（公式中心）
- Multi-stage builds: https://docs.docker.com/build/building/multi-stage/
- Buildx: https://docs.docker.com/build/buildx/
- Docker Scout: https://docs.docker.com/scout/
- Engine security: https://docs.docker.com/engine/security/

---

## 今日のまとめ
- Beginner: まずは run/ps/logs で観察力をつける
- Middle: build/compose でチーム開発の再現性を確保
- Advanced: 最適化とセキュリティを運用に組み込む

明日はこの流れを引き継ぎ、**ネットワークとボリューム運用（データ永続化と分離）**を段階的に扱うと効果的です。
