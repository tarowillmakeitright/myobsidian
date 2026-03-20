# Docker Commands Magazine — 2026-03-20

#docker #containers #devops #learning #daily  
[[Home]]

---

## 今号のテーマ（学習アーク）
**「開発用コンテナを安全に作って運用する基本」**  
進行: **Beginner → Middle → Advanced**

---

## 1) Beginner レベル

### 1) Topic + Level
**Topic:** コンテナの起動・確認・停止の基本 (`docker run`, `docker ps`, `docker logs`, `docker stop`)  
**Level:** Beginner

### 2) なぜ実アプリ開発で重要か
- ローカル環境差分（OS/バージョン違い）を減らせる
- 「自分のPCでは動くのに…」を減らし、再現性の高い検証ができる
- バグ調査時にログ確認・再起動をすばやく行える

### 3) コアコマンド解説
- `docker run -d --name web -p 8080:80 nginx:alpine`
  - `-d`: バックグラウンド実行
  - `--name`: コンテナ名を固定
  - `-p host:container`: ポート公開
- `docker ps` / `docker ps -a`
  - 稼働中のみ / 停止済み含む一覧
- `docker logs -f web`
  - ログ追跡（`-f`でfollow）
- `docker stop web`
  - SIGTERMで安全停止

### 4) アプリ開発での使い方（Docker公式ベストプラクティス準拠）
- まずは**公式イメージ**（例: `nginx`, `postgres`）を使う
- コンテナは**使い捨て可能**に（状態を前提にしない）
- 設定はイメージに焼き込まず、必要に応じて環境変数/マウントで外出し

### 5) 30–60分ミニラボ
**目標:** Nginxコンテナを立ち上げ、ログ確認し、安全に終了する（約30分）

1. 起動
```bash
docker run -d --name web -p 8080:80 nginx:alpine
```
2. 稼働確認
```bash
docker ps
```
3. ブラウザで `http://localhost:8080` を確認
4. ログ確認
```bash
docker logs -f web
```
5. 停止・削除
```bash
docker stop web
docker rm web
```

### 6) コマンドチートシート
```bash
docker run -d --name <name> -p <host>:<container> <image>
docker ps
docker logs -f <name>
docker stop <name>
docker rm <name>
```

### 7) よくあるミスと安全策
- ミス: `-p`を忘れてアクセスできない
  - 安全策: `docker ps` の `PORTS` 列を確認
- ミス: コンテナ名重複で起動失敗
  - 安全策: 既存を `docker ps -a` で確認
- ミス: ログを見ずに再起動を繰り返す
  - 安全策: まず `docker logs` で原因確認

### 8) 面接風質問
「`docker run -d -p 8080:80 nginx` の `-d` と `-p` はそれぞれ何を解決しているか説明してください。」

### 9) 次の一歩（公式中心）
- Docker Get Started: https://docs.docker.com/get-started/
- `docker run` reference: https://docs.docker.com/engine/reference/commandline/run/
- `docker logs` reference: https://docs.docker.com/engine/reference/commandline/logs/

---

## 2) Middle レベル

### 前提条件（Prerequisites）
- Beginner内容（`run/ps/logs/stop/rm`）を一通り実行できる
- 基本的なDockerfileの読み書きに抵抗がない

### 1) Topic + Level
**Topic:** 開発向けイメージ作成とマルチサービス起動 (`docker build`, `docker compose up`)  
**Level:** Middle

### 2) なぜ実アプリ開発で重要か
- チーム全員が同じ依存関係で開発可能
- DB/アプリをまとめて起動し、オンボーディングを短縮
- CIに近い形でローカル検証できる

### 3) コアコマンド解説
- `docker build -t myapp:dev .`
  - Dockerfileからイメージ作成
- `docker compose up -d`
  - 複数サービスを定義どおり起動
- `docker compose logs -f app`
  - サービス別ログ追跡
- `docker compose down`
  - 構成一式停止・ネットワーク削除

### 4) アプリ開発での使い方（ベストプラクティス）
- 小さいベースイメージ（例: `node:alpine` など）を検討
- `.dockerignore` で不要ファイルを除外しビルド高速化
- レイヤーキャッシュを意識（依存インストールとアプリコピー順）
- 秘密情報（APIキー等）をDockerfile/Composeに直書きしない
  - `.env`の扱いに注意し、Git管理から除外

### 5) 30–60分ミニラボ
**目標:** Node.jsアプリ + Redis をComposeで起動（約45分）

1. `Dockerfile` 作成（Nodeアプリ）
2. `compose.yaml` に `app` と `redis` を定義
3. 起動
```bash
docker compose up -d --build
```
4. ログ確認
```bash
docker compose logs -f app
```
5. 停止
```bash
docker compose down
```

### 6) コマンドチートシート
```bash
docker build -t myapp:dev .
docker compose up -d --build
docker compose ps
docker compose logs -f <service>
docker compose down
```

### 7) よくあるミスと安全策
- ミス: build contextが大きすぎて遅い
  - 安全策: `.dockerignore` を整備
- ミス: シークレットをDockerfileに埋め込む
  - 安全策: BuildKit secrets / 環境注入を利用し、イメージへ残さない
- ミス: `latest`タグ固定で再現性低下
  - 安全策: ベースイメージをバージョン固定

### 8) 面接風質問
「Dockerfileで依存関係を先にコピーしてインストールするのはなぜですか？キャッシュの観点で説明してください。」

### 9) 次の一歩（公式中心）
- Build best practices: https://docs.docker.com/build/building/best-practices/
- Dockerfile overview: https://docs.docker.com/build/concepts/dockerfile/
- Compose overview: https://docs.docker.com/compose/

---

## 3) Advanced レベル

### 前提条件（Prerequisites）
- Middle内容（Dockerfile最適化、Compose運用）を実施済み
- Linux権限・ネットワーク・CI/CDの基本理解

### 1) Topic + Level
**Topic:** セキュアで軽量な本番向けイメージ運用（マルチステージ・最小権限・クリーンアップ戦略）  
**Level:** Advanced

### 2) なぜ実アプリ開発で重要か
- 攻撃対象領域を減らし、脆弱性対応を容易にする
- デプロイ時間と転送サイズを削減
- 運用時の事故（誤削除・停止）を防ぎ、復旧性を高める

### 3) コアコマンド解説
- `docker build --target runtime -t myapp:prod .`
  - マルチステージの最終段を指定
- `docker image ls` / `docker image inspect`
  - イメージサイズ・メタ情報確認
- `docker exec -it <container> sh`
  - 稼働中の調査（最小限に）
- `docker system df`
  - ディスク使用量の可視化

### 4) アプリ開発での使い方（ベストプラクティス）
- マルチステージビルドでビルドツールを最終イメージに含めない
- 非rootユーザーで実行（`USER`）
- ヘルスチェックや明示的なバージョン固定で運用安定化
- 定期的に不要リソースを整理するが、削除系は必ず影響確認してから

### 5) 30–60分ミニラボ
**目標:** マルチステージ + 非root化した本番向けイメージを作る（約60分）

1. マルチステージDockerfile作成（builder/runtime）
2. runtimeステージをビルド
```bash
docker build --target runtime -t myapp:prod .
```
3. 実行ユーザーを確認
```bash
docker run --rm myapp:prod id
```
4. サイズ比較（dev版 vs prod版）
```bash
docker image ls | grep myapp
```
5. 後片付け（必要なものだけ残す）

### 6) コマンドチートシート
```bash
docker build --target runtime -t myapp:prod .
docker image inspect myapp:prod
docker system df
docker exec -it <container> sh
```

### 7) よくあるミスと安全策
- ミス: root実行のまま本番投入
  - 安全策: Dockerfileで `USER` を設定
- ミス: 何でも `docker system prune -a` で削除
  - **警告:** 重要イメージ/停止中コンテナ/キャッシュを消す可能性あり
  - 安全策: 先に `docker system df` と一覧確認、必要なら対象限定で削除
- ミス: `docker rm -f` / `docker rmi -f` を無計画に実行
  - **警告:** 強制削除は依存中リソースや調査用コンテナを失う危険
  - 安全策: 依存関係確認後に実行、可能なら通常削除を優先
- ミス: シークレットをイメージ層に残す
  - 安全策: Build secrets・ランタイム注入を使い、履歴に残さない

### 8) 面接風質問
「本番用Dockerイメージで“マルチステージ + 非root実行 + タグ固定”を組み合わせると、セキュリティと運用面にどんな効果がありますか？」

### 9) 次の一歩（公式中心）
- Multi-stage builds: https://docs.docker.com/build/building/multi-stage/
- Dockerfile best practices: https://docs.docker.com/build/building/best-practices/
- Compose production considerations: https://docs.docker.com/compose/production/
- Engine security: https://docs.docker.com/engine/security/

---

## 付録: 破壊的コマンドの安全メモ
以下は便利ですが**破壊的**です。実行前に対象確認を必須にしてください。

```bash
# 何が消えるか先に確認

docker ps -a
docker image ls
docker volume ls
docker system df

# 注意して実行（必要最小限）
# docker system prune
# docker system prune -a
# docker container rm -f <id>
# docker rmi -f <image>
```

