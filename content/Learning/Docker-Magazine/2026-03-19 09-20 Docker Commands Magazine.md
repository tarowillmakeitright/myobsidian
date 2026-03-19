# Docker Commands Magazine — 2026-03-19 (09:20)
#docker #containers #devops #learning #daily
[[Home]]

---

## 今号のテーマ
**「開発で毎日使う Docker コマンドを、実装現場の流れで学ぶ」**  
学習アーク: **Beginner → Middle → Advanced**

---

## 1) Topic + Level

### 🟢 Beginner: コンテナの基本操作と観察
- 対象トピック: `docker run`, `docker ps`, `docker logs`, `docker exec`, `docker stop`, `docker rm`

### 🟡 Middle: イメージ作成と再現可能な開発環境
- 対象トピック: `docker build`, `docker images`, `docker tag`, `docker compose up/down`
- **前提知識 (Prerequisites)**
  - Beginner レベルのコマンド操作ができる
  - Dockerfile の基本命令（`FROM`, `WORKDIR`, `COPY`, `RUN`, `CMD`）を見たことがある

### 🔴 Advanced: 本番を意識した最適化と安全運用
- 対象トピック: multi-stage build, `.dockerignore`, volume/network 設計, 安全なクリーンアップ
- **前提知識 (Prerequisites)**
  - Middle レベルの build/compose 操作ができる
  - 開発中アプリ（Node/Python/Go など）を1つ以上触った経験

---

## 2) Why it matters for real app development
- **環境差異の削減**: 「自分のPCでは動く」を減らし、チーム開発で再現性を高める
- **オンボーディング高速化**: 新メンバーが Docker + Compose で短時間で起動可能
- **CI/CD と接続しやすい**: `docker build` がそのままパイプラインに乗る
- **運用事故を減らす**: ログ確認、ヘルスチェック、不要リソース整理を安全に実施できる

---

## 3) Core Docker command explanations

### Beginner コア
- `docker run --name web -d -p 8080:80 nginx`
  - Nginx コンテナをバックグラウンド起動し、ホスト8080→コンテナ80を公開
- `docker ps` / `docker ps -a`
  - 稼働中 / 全コンテナの状態確認
- `docker logs -f web`
  - コンテナログを追尾（障害調査の基本）
- `docker exec -it web sh`
  - 稼働中コンテナに入って調査
- `docker stop web && docker rm web`
  - 停止して削除（開発後の整理）

### Middle コア
- `docker build -t myapp:dev .`
  - Dockerfile からイメージ作成
- `docker images`
  - ローカルのイメージ一覧
- `docker tag myapp:dev myapp:latest`
  - タグ付けでバージョン運用
- `docker compose up -d`
  - 複数サービス（app/db等）をまとめて起動
- `docker compose down`
  - compose 管理リソースを停止

### Advanced コア
- `docker build --target runtime -t myapp:prod .`
  - multi-stage で最終ステージのみ出力し、軽量化
- `docker compose logs -f app`
  - サービス単位で障害追跡
- `docker system df`
  - ディスク使用量確認（削除前に必須）
- `docker volume ls` / `docker network ls`
  - 永続化データとネットワーク可視化

---

## 4) App build での Docker 活用（docs.docker.com ベストプラクティス準拠）
- **小さいベースイメージを選ぶ**（必要十分なもの）
- **`.dockerignore` を必ず用意**し、`node_modules`, `.git`, ログ等を除外
- **レイヤーキャッシュを活用**: 依存関係インストールを先に分離
- **1コンテナ1責務を基本に**: app と db は Compose で分離
- **秘密情報をイメージに焼き込まない**
  - `ENV PASSWORD=...` を Dockerfile/compose に直書きしない
  - シークレットは環境変数注入や secret 管理機能で扱う
- **不要な root 実行を避ける**（可能なら非rootユーザー）

---

## 5) 30–60分ハンズオン mini lab

### 目標
シンプルな Web アプリ + Redis を Compose で起動し、ログ確認と安全な後片付けを行う

### 手順（45分想定）
1. **プロジェクト作成 (5分)**
   - `Dockerfile`, `.dockerignore`, `compose.yaml` を作成
2. **イメージ作成 (10分)**
   - `docker build -t sample-web:dev .`
3. **複数サービス起動 (10分)**
   - `docker compose up -d`
4. **動作確認と調査 (10分)**
   - `docker ps`
   - `docker compose logs -f web`
   - `docker exec -it <webコンテナ名> sh`
5. **安全に終了 (10分)**
   - `docker compose down`
   - 必要に応じて `docker image ls` で確認

### 追加チャレンジ（+15分）
- multi-stage build に変更してイメージサイズを比較
- `docker history sample-web:dev` でレイヤー確認

---

## 6) Command cheatsheet

```bash
# コンテナ操作
docker run --name <name> -d -p <hostPort>:<containerPort> <image>
docker ps
docker logs -f <container>
docker exec -it <container> sh
docker stop <container>
docker rm <container>

# イメージ操作
docker build -t <image>:<tag> .
docker images
docker tag <image>:<tag> <image>:latest

# Compose
docker compose up -d
docker compose ps
docker compose logs -f <service>
docker compose down

# 状態確認
docker system df
docker volume ls
docker network ls
```

---

## 7) Common mistakes and safe practices

### よくあるミス
- `Dockerfile` に秘密情報を直書きする
- `COPY . .` の前に不要ファイル除外をせず、巨大イメージ化
- 開発中に `latest` タグだけ使い、どの版か分からなくなる
- いきなり強制削除コマンドを打つ

### 安全運用のポイント
- 削除前に必ず `docker ps -a`, `docker images`, `docker volume ls`, `docker system df` で確認
- **注意（破壊的コマンド）**
  - `docker system prune`
  - `docker image prune -a`
  - `docker rmi -f ...`
  - `docker rm -f ...`
  これらは停止中/未使用リソースや依存関係を広く消す可能性あり。実行前に対象を明確化すること。
- compose では `.env` の扱いを統制し、機密値を Git 管理しない

---

## 8) Interview-style question
**質問:**  
「`docker compose up` を使う開発環境で、再現性とセキュリティを両立するために、Dockerfile と compose.yaml に最低限どんな設計ルールを入れますか？」

（観点例: イメージ固定タグ、.dockerignore、シークレット管理、非root、volume設計、ヘルスチェック）

---

## 9) Next-step resources（公式ドキュメント優先）
- Docker Get Started  
  https://docs.docker.com/get-started/
- Dockerfile best practices  
  https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Compose documentation  
  https://docs.docker.com/compose/
- Multi-stage builds  
  https://docs.docker.com/build/building/multi-stage/
- Docker Engine storage/volumes  
  https://docs.docker.com/engine/storage/volumes/
- Use secrets (build/runtimeの安全管理の入口)  
  https://docs.docker.com/build/building/secrets/

---

次号予告（学習アーク継続）:  
**Beginner:** ネットワーク基礎（bridge, port公開）  
**Middle:** Compose で app + db + migration の実践  
**Advanced:** CI での build cache 最適化と脆弱性スキャン導入
