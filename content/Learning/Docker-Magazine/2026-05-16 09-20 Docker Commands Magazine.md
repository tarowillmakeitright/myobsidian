---
tags: [docker, containers, devops, learning, daily]
---

# 2026-05-16 09:20 Docker Commands Magazine

[[Home]]

日次テーマ: **Dockerコマンド実践誌（Beginner → Middle → Advanced）**

---

## Issue 1 — Beginner
### 1) Topic + Level
**トピック:** Dockerの基本ライフサイクル（`pull` / `run` / `ps` / `logs` / `stop` / `rm`）  
**レベル:** Beginner

### 2) なぜ実務で重要か
ローカル開発で「同じ環境を全員が再現」できることが、バグ再現・オンボーディング・CIの安定化に直結します。まずはコンテナの起動〜停止〜確認を正しく行えることが、全Docker運用の土台になります。

### 3) コアコマンド解説
- `docker pull nginx:stable`  
  イメージをレジストリから取得。
- `docker run -d --name web -p 8080:80 nginx:stable`  
  コンテナ起動（バックグラウンド、名前付け、ポート公開）。
- `docker ps` / `docker ps -a`  
  稼働中 / 全コンテナ確認。
- `docker logs -f web`  
  ログ追跡。
- `docker stop web`  
  正常停止。
- `docker rm web`  
  停止済みコンテナ削除。

### 4) アプリ開発での使い方（docs.docker.com準拠）
- 開発初期は、DBやキャッシュなど依存サービスをコンテナ化して再現性を上げる。  
- コンテナ名・ポートを明示し、`docker ps`と`logs`で状態観測を習慣化。  
- 「動く」だけでなく「観測可能（logs/health）」をセットで設計する。

### 5) 30-60分ミニラボ
1. `nginx:stable` を起動して `http://localhost:8080` を確認。  
2. `docker logs -f web` でアクセスログを確認。  
3. `docker exec -it web sh` でコンテナ内確認（`nginx -v`）。  
4. 停止・削除して、`docker ps -a` で消えたことを確認。

### 6) Cheatsheet
```bash
docker pull nginx:stable
docker run -d --name web -p 8080:80 nginx:stable
docker ps
docker logs -f web
docker exec -it web sh
docker stop web
docker rm web
```

### 7) よくあるミス & 安全策
- ミス: `-p` 指定忘れでアクセス不能。  
  対策: 起動テンプレート化（Makefileやscript）。
- ミス: `docker rm -f` を安易に使用。  
  対策: まず `stop`、必要時のみ `-f`。
- ミス: 何が動いているか不明。  
  対策: 命名規則（`app-web-dev` 等）を統一。

### 8) 面接っぽい質問
`docker run -d -p 8080:80 nginx` と `docker run -d -P nginx` の違いを説明してください。

### 9) 次の一歩（公式中心）
- Docker Get Started: https://docs.docker.com/get-started/  
- `docker run` リファレンス: https://docs.docker.com/engine/reference/commandline/run/

---

## Issue 2 — Middle
### 1) Topic + Level
**トピック:** Dockerfile最適化（レイヤー、キャッシュ、.dockerignore、マルチステージ）  
**レベル:** Middle  
**前提:** `docker run`/`docker ps`/`docker logs` を扱えること

### 2) なぜ実務で重要か
ビルド時間とイメージサイズは、開発速度・CIコスト・配布速度・セキュリティ面（攻撃面積）に直結します。Dockerfileの質がそのままチーム生産性になります。

### 3) コアコマンド解説
- `docker build -t myapp:dev .`  
  Dockerfileからイメージ作成。
- `docker image ls`  
  サイズ含めイメージ一覧確認。
- `docker history myapp:dev`  
  レイヤー構成確認。
- `docker build --no-cache -t myapp:clean .`  
  キャッシュ無効ビルド（再現検証）。

### 4) アプリ開発での使い方（docs.docker.com準拠）
- 依存定義ファイル（`package-lock.json`, `requirements.txt` 等）を先にCOPYしてキャッシュ活用。  
- `.dockerignore` で不要ファイル（`.git`, `node_modules`, secrets）を送らない。  
- マルチステージでビルド用ツールチェーンを最終イメージから排除。  
- `latest` 固定依存を避け、必要に応じてタグを明示。

### 5) 30-60分ミニラボ
1. シンプルなNode/Pythonアプリ用Dockerfileを作成。  
2. `.dockerignore` なしでビルド時間・サイズを記録。  
3. `.dockerignore` とレイヤー順最適化後に再計測。  
4. マルチステージへ変更し、最終サイズ差分を比較。  
5. 結果を「時間/サイズ/学び」で3行まとめる。

### 6) Cheatsheet
```bash
docker build -t myapp:dev .
docker image ls
docker history myapp:dev
docker build --no-cache -t myapp:clean .
```

### 7) よくあるミス & 安全策
- ミス: シークレット（`.env`, 鍵）を `COPY . .` で混入。  
  対策: `.dockerignore` 徹底、秘密はランタイム注入。
- ミス: 巨大ベースイメージを無批判に使用。  
  対策: 公式イメージ選定、必要最小限化。
- ミス: 再現不能なビルド。  
  対策: バージョン固定、ロックファイル利用。

### 8) 面接っぽい質問
Dockerfileで「キャッシュが効く並び順」を、依存インストールを例に説明してください。

### 9) 次の一歩（公式中心）
- Dockerfile best practices: https://docs.docker.com/develop/develop-images/dockerfile_best-practices/  
- Multi-stage builds: https://docs.docker.com/build/building/multi-stage/

---

## Issue 3 — Advanced
### 1) Topic + Level
**トピック:** Composeでの開発スタック運用（依存関係・ヘルスチェック・永続化・安全なクリーンアップ）  
**レベル:** Advanced  
**前提:** Dockerfile作成と基本ビルド最適化を理解していること

### 2) なぜ実務で重要か
実アプリは単体コンテナではなく、API・DB・キャッシュ・ワーカーの組み合わせで動きます。Compose運用を正しく行えると、ローカル/CI/検証環境の差異が減り、障害切り分けが速くなります。

### 3) コアコマンド解説
- `docker compose up -d --build`  
  サービス群をビルドして起動。
- `docker compose ps`  
  全サービス状態確認。
- `docker compose logs -f api`  
  特定サービスのログ追跡。
- `docker compose exec api sh`  
  稼働コンテナ内で診断。
- `docker compose down`  
  停止とネットワーク削除（通常クリーン）。
- `docker compose down -v`  
  **警告:** ボリューム削除（DBデータ消失の可能性）。

### 4) アプリ開発での使い方（docs.docker.com準拠）
- `depends_on` だけに頼らず、healthcheckで実利用可能状態を判定。  
- 永続データはnamed volumeへ。bind mountの責務を分ける。  
- secretsはイメージに焼かず、環境変数/secret管理で注入。  
- 破壊的クリーンアップは開発環境限定で明示実行。

### 5) 30-60分ミニラボ
1. `api + db` の `compose.yaml` を作成。  
2. `db` にhealthcheckを追加、`api` の待機戦略を確認。  
3. named volumeでDBデータを保持し、再起動後の永続性を確認。  
4. `down` と `down -v` の違いを検証（テストデータで実施）。  
5. ログと障害時の確認手順をREADMEに追記。

### 6) Cheatsheet
```bash
docker compose up -d --build
docker compose ps
docker compose logs -f api
docker compose exec api sh
docker compose down
# destructive: data volumes may be removed
docker compose down -v
```

### 7) よくあるミス & 安全策
- ミス: `docker system prune -a` を無警告で実行。  
  対策: **必ず影響確認**（未使用イメージ/停止コンテナ/ネットワーク削除）。
- ミス: `docker rmi` / `docker rm -f` の乱用。  
  対策: 対象を `ps`/`images` で確認してから実行。
- ミス: `compose.yaml` に平文シークレット直書き。  
  対策: `.env` 管理＋配布制御、可能ならsecret機構を利用。

### 8) 面接っぽい質問
`docker compose down` と `docker compose down -v` の違いを、障害調査時の運用観点で説明してください。

### 9) 次の一歩（公式中心）
- Docker Compose overview: https://docs.docker.com/compose/  
- Compose file reference: https://docs.docker.com/reference/compose-file/  
- Docker Engine prune reference: https://docs.docker.com/engine/manage-resources/pruning/

---

## 安全メモ（全レベル共通）
- `prune`, `rmi`, `rm -f`, `down -v` は破壊的になり得ます。**実行前に対象と影響を必ず確認**。  
- シークレットはイメージやGit管理下のComposeに埋め込まない。  
- 「速さ」より「再現性・可観測性・安全性」を優先する。
