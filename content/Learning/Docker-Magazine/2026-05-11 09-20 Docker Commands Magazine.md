---
tags: [docker, containers, devops, learning, daily]
---

# 2026-05-11 Docker Commands Magazine
[[Home]]

## 今号のテーマ
**Topic:** Dockerイメージの作成・実行・保守を安全に回す基本フロー  
**Learning Arc:** Beginner → Middle → Advanced

---

## Beginner（初級）
### 1) Topic + Level
**Level:** Beginner  
**Topic:** `docker build` / `docker run` / `docker ps` で「まず動かす」

### 2) なぜ実務で重要？
ローカル開発で「自分の環境では動くのに他人の環境で壊れる」問題を減らせます。アプリをコンテナで統一すれば、オンボーディングと検証が速くなります。

### 3) コアコマンド解説
- `docker build -t myapp:dev .`  
  カレントディレクトリのDockerfileからイメージ作成。
- `docker run --name myapp-dev -p 8080:8080 myapp:dev`  
  コンテナを起動。`-p` でホストとコンテナのポートを接続。
- `docker ps` / `docker ps -a`  
  実行中 / 全コンテナを確認。
- `docker logs -f myapp-dev`  
  ログ追跡。障害調査の入口。

### 4) アプリ開発での使い方（Docker公式ベストプラクティス準拠）
- 1コンテナ1責務を意識（アプリとDBを分離）
- 明示タグ運用（`latest`固定依存を避ける）
- 最小ベースイメージを選ぶ（攻撃面とサイズ削減）

### 5) 30-60分ミニラボ
1. サンプルWebアプリ（Node/Python等）にDockerfileを作る。  
2. `docker build -t demo-web:dev .`  
3. `docker run --rm -p 8080:8080 demo-web:dev`  
4. ブラウザで疎通確認。  
5. コードを1行変えて再ビルドし、変更が反映されることを確認。

### 6) Cheatsheet
```bash
docker build -t <name>:<tag> .
docker run --name <cname> -p <host>:<container> <name>:<tag>
docker ps
docker logs -f <cname>
docker stop <cname>
```

### 7) よくあるミス & 安全策
- ミス: `Dockerfile`に秘密情報（APIキー）を直接書く  
  → 安全策: シークレットは環境変数/secret管理で注入し、イメージに焼き込まない。
- ミス: `:latest`前提で再現不能  
  → 安全策: バージョンタグ固定。

### 8) 面接風質問
「`docker run -p 8080:80` の `8080` と `80` はそれぞれ何を指し、どちらを変更すべきかをどう判断しますか？」

### 9) 次の一歩（公式）
- https://docs.docker.com/get-started/
- https://docs.docker.com/build/

---

## Middle（中級）
### 前提（Prerequisites）
- `docker build/run/ps/logs` を一通り使える
- Dockerfileの基本命令（`FROM`, `COPY`, `RUN`, `CMD`）を理解

### 1) Topic + Level
**Level:** Middle  
**Topic:** `docker compose` で複数サービスを開発運用

### 2) なぜ実務で重要？
実アプリはWeb単体で完結しません。DB・キャッシュ・ジョブワーカーを一括起動できると、開発環境の再現性とチーム速度が上がります。

### 3) コアコマンド解説
- `docker compose up -d`  
  サービス群をバックグラウンド起動。
- `docker compose ps`  
  サービス状態確認。
- `docker compose logs -f web`  
  特定サービスのログ追跡。
- `docker compose down`  
  ネットワーク/コンテナ停止。

### 4) アプリ開発での使い方（公式準拠）
- `.env` と `compose.yaml` を分離し、環境差分を管理
- `depends_on` だけでなくヘルスチェックで依存先の準備完了を待つ
- 秘密情報は`.env`直書き運用を最小化し、可能ならDocker secrets等へ

### 5) 30-60分ミニラボ
1. `web + db` の `compose.yaml` を作成。  
2. `docker compose up -d` で起動。  
3. `docker compose logs -f web` で接続エラー有無を確認。  
4. DB停止→再起動し、アプリの挙動確認。  
5. 不要になったら `docker compose down`。

### 6) Cheatsheet
```bash
docker compose up -d
docker compose ps
docker compose logs -f <service>
docker compose exec <service> sh
docker compose down
```

### 7) よくあるミス & 安全策
- ミス: `compose.yaml`へ秘密鍵を直書き  
  → 安全策: 環境注入＋アクセス制御。Gitに秘匿情報を置かない。
- ミス: ボリューム理解不足でデータ消失  
  → 安全策: named volume利用とバックアップ設計。

### 8) 面接風質問
「`docker compose down` と `docker compose down -v` の違いは？ 本番相当データがあるとき、どちらをどう使い分けますか？」

### 9) 次の一歩（公式）
- https://docs.docker.com/compose/
- https://docs.docker.com/compose/gettingstarted/
- https://docs.docker.com/compose/environment-variables/

---

## Advanced（上級）
### 前提（Prerequisites）
- Composeで複数サービスを起動・調査できる
- イメージレイヤーとキャッシュの基本を理解
- CI/CDの基本フローを知っている

### 1) Topic + Level
**Level:** Advanced  
**Topic:** マルチステージビルド + BuildKit最適化 + 安全なクリーンアップ運用

### 2) なぜ実務で重要？
ビルド時間短縮・配布サイズ削減・脆弱性面積縮小に直結。CIコストとデプロイ安定性に効きます。

### 3) コアコマンド解説
- `docker buildx build --target runtime -t myapp:prod .`  
  マルチステージの最終成果物のみ採用。
- `docker image ls` / `docker history myapp:prod`  
  サイズ・レイヤー内訳確認。
- `docker builder prune`  
  BuildKitキャッシュ削除（**要注意**）。

### 4) アプリ開発での使い方（公式準拠）
- ビルド用ステージと実行用ステージを分離（不要ツールを最終イメージへ持ち込まない）
- 非rootユーザーで実行
- `.dockerignore`で不要ファイル（`.git`, `node_modules`, 秘匿ファイル）を除外
- SBOM/スキャンをCIに組み込み、定期更新

### 5) 30-60分ミニラボ
1. 既存Dockerfileを2段階（build/runtime）へ分割。  
2. `docker buildx build -t app:ms .` を実行。  
3. 旧版と新版でイメージサイズ比較（`docker image ls`）。  
4. `docker history`で不要レイヤー削減を確認。  
5. `docker run --user` or Dockerfile `USER`設定で非root起動確認。

### 6) Cheatsheet
```bash
docker buildx build -t <name>:<tag> .
docker history <image>
docker image ls
docker builder prune   # 破壊的。削除対象を確認してから実行
```

### 7) よくあるミス & 安全策
- ミス: cleanup系コマンドを無確認で実行
  - `docker system prune -a`
  - `docker image rm -f <image>`
  - `docker rm -f <container>`
  
  **警告:** これらは復旧困難な削除を引き起こします。実行前に対象確認 (`docker ps -a`, `docker image ls`, `docker volume ls`) と影響範囲レビューを必ず実施。
- ミス: シークレットを`ARG`/`ENV`でビルド層に残す  
  → 安全策: Build secrets機構を利用し、履歴に残さない。

### 8) 面接風質問
「マルチステージビルドは“何を削る”ための仕組みですか？ セキュリティ・性能・運用の3観点で説明してください。」

### 9) 次の一歩（公式）
- https://docs.docker.com/build/building/multi-stage/
- https://docs.docker.com/build/cache/
- https://docs.docker.com/build/buildkit/
- https://docs.docker.com/engine/security/

---

## 付記（安全運用メモ）
- `prune`/`rmi`/`rm -f` は**必ず事前確認**してから。  
- イメージ/Composeへシークレットを埋め込まない。  
- 本番相当データはボリューム戦略＋バックアップをセットで運用。
