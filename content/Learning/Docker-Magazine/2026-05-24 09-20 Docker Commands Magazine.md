---
tags: [docker, containers, devops, learning, daily]
---

# 2026-05-24 09:20 Docker Commands Magazine

[[Home]]

#docker #containers #devops #learning #daily

---

## 今号のテーマ
**「Dockerイメージ管理とコンテナ運用の実践」**

学習アーク（段階式）:
- **Beginner**: イメージとコンテナの基本操作を安全に理解
- **Middle**: マルチステージビルドとComposeで開発体験を改善
- **Advanced**: キャッシュ最適化・セキュアなビルド・運用向け整理

---

## [Beginner] イメージ/コンテナの基本コマンド

### 1) Topic + Level
**トピック:** `docker pull / run / ps / logs / exec / stop / rm`
**レベル:** Beginner

### 2) なぜ実務で重要か
ローカルで「本番に近い実行環境」を再現できると、
- 「自分のPCでは動く問題」を減らせる
- チームのオンボーディングが速くなる
- デバッグ時に再現性が上がる

### 3) コアコマンド解説
- `docker pull nginx:1.27` : イメージ取得
- `docker run -d --name web -p 8080:80 nginx:1.27` : バックグラウンド起動
- `docker ps` : 起動中コンテナ一覧
- `docker logs -f web` : ログ追跡
- `docker exec -it web sh` : コンテナ内シェル
- `docker stop web` : 停止
- `docker rm web` : 削除

### 4) アプリ開発での使い方（Docker推奨に沿って）
- 依存サービス（DB/Redisなど）をコンテナ化してローカル標準化
- 固定タグ利用（例: `nginx:1.27`）で再現性を高める
- ログを標準出力へ流し、`docker logs`で観測しやすくする

### 5) 30-60分ミニラボ
1. nginxをpull/runし、`http://localhost:8080` を確認
2. `logs -f` でアクセスログ確認
3. `exec`でコンテナ内に入り、`nginx -v` を実行
4. stop/rmで終了

### 6) Cheatsheet
```bash
docker pull <image:tag>
docker run -d --name <name> -p <host>:<container> <image:tag>
docker ps
docker logs -f <container>
docker exec -it <container> sh
docker stop <container>
docker rm <container>
```

### 7) よくあるミス & 安全策
- ミス: `latest`タグ依存 → 環境差分が発生
  - 安全策: バージョンタグ固定
- ミス: コンテナ名重複で起動失敗
  - 安全策: 命名規則（`app-api-dev` など）

### 8) 面接風質問
「`docker run` と `docker start` の違いを説明してください。」

### 9) 次の一歩（公式）
- https://docs.docker.com/get-started/
- https://docs.docker.com/engine/containers/run/

---

## [Middle] マルチステージビルド + Compose

### 前提条件
- Beginnerの内容を理解していること
- Dockerfileの基本（`FROM`, `COPY`, `RUN`）を触ったこと

### 1) Topic + Level
**トピック:** `docker build`, マルチステージ, `docker compose up`
**レベル:** Middle

### 2) なぜ実務で重要か
- イメージサイズ削減で配布/デプロイが速くなる
- 開発・テスト・本番の構成差をComposeで減らせる

### 3) コアコマンド解説
- `docker build -t myapp:dev .` : イメージ作成
- `docker image ls` : イメージ確認
- `docker compose up -d` : 複数サービス起動
- `docker compose logs -f` : サービス横断ログ確認
- `docker compose down` : 停止/ネットワーク削除

### 4) アプリ開発での使い方（Docker推奨に沿って）
- マルチステージでビルド依存を最終イメージから除外
- `.dockerignore` で不要ファイルをコンテキストから除外
- Composeでapp + db + cacheを1コマンドで再現
- **シークレットをイメージに焼かない**（ENV直書き・COPY禁止）

### 5) 30-60分ミニラボ
1. 簡単なNode/Go/PythonアプリのDockerfileをマルチステージ化
2. `.dockerignore`に`.git`, `node_modules`, `.env`を追加
3. `compose.yml`でapp+db起動
4. `compose logs -f`で接続確認

### 6) Cheatsheet
```bash
docker build -t myapp:dev .
docker image ls
docker compose up -d
docker compose ps
docker compose logs -f
docker compose down
```

### 7) よくあるミス & 安全策
- ミス: `.env` を `COPY . .` で取り込んでしまう
  - 安全策: `.dockerignore`徹底、Secretは実行時注入
- ミス: 1ステージでビルドし続けて肥大化
  - 安全策: マルチステージ化

### 8) 面接風質問
「マルチステージビルドがセキュリティと配布性能に効く理由は？」

### 9) 次の一歩（公式）
- https://docs.docker.com/build/building/multi-stage/
- https://docs.docker.com/compose/
- https://docs.docker.com/build/cache/optimize/

---

## [Advanced] 安全なクリーンアップとビルド最適化運用

### 前提条件
- Middleまで完了
- Compose運用とDockerfile改善経験がある

### 1) Topic + Level
**トピック:** `docker system df`, `builder prune`, 安全なクリーンアップ設計
**レベル:** Advanced

### 2) なぜ実務で重要か
- 開発マシン/CIのディスク枯渇を防ぐ
- 事故削除を避けつつ、速度と容量のバランスを保てる

### 3) コアコマンド解説
- `docker system df` : 使用量可視化
- `docker builder prune` : ビルドキャッシュ削除
- `docker image prune` : 未使用イメージ削除
- `docker container prune` : 停止コンテナ削除

> ⚠️ **破壊的コマンド注意**
> `docker system prune -a`, `docker rmi`, `docker rm -f` は必要資産を消す可能性あり。
> 実行前に対象確認（`docker ps -a`, `docker image ls`）し、チーム環境では合意を取ること。

### 4) アプリ開発での使い方（Docker推奨に沿って）
- 定期的に`system df`で容量監視
- CIではキャッシュキー設計で再ビルド最小化
- rootユーザー常用を避け、最小権限で実行
- 機密情報はBuildKit Secretや外部Secret管理を利用

### 5) 30-60分ミニラボ
1. `docker system df` で現状把握
2. サンプルビルドを2回実行しキャッシュ効果を観察
3. `docker builder prune` を `--filter until=24h` 付きで試す
4. prune前後の容量差を記録

### 6) Cheatsheet
```bash
docker system df
docker builder prune
docker builder prune --filter until=24h
docker image prune
docker container prune
# 危険: docker system prune -a / docker rmi / docker rm -f
```

### 7) よくあるミス & 安全策
- ミス: 何も確認せず`system prune -a`
  - 安全策: 先に一覧確認＋対象限定prune
- ミス: DockerfileにAPIキーを直書き
  - 安全策: Secret管理（環境注入/secret mount）
- ミス: 不要な`ADD`/`COPY`でキャッシュ破壊
  - 安全策: 変更頻度の低い層を上に配置

### 8) 面接風質問
「`docker builder prune` と `docker system prune` の使い分けを、事故防止観点で説明してください。」

### 9) 次の一歩（公式）
- https://docs.docker.com/build/cache/
- https://docs.docker.com/build/buildkit/
- https://docs.docker.com/engine/manage-resources/pruning/
- https://docs.docker.com/develop/security-best-practices/

---

## 今日のまとめ
- Beginnerで“動かす・見る・止める”を確実化
- Middleで“軽く・再現可能に”構成改善
- Advancedで“安全に運用し続ける”習慣化

次号はこの流れを継続し、別テーマ（ネットワーク、ボリューム、ヘルスチェック、CI連携）で難易度を1段ずつ上げます。