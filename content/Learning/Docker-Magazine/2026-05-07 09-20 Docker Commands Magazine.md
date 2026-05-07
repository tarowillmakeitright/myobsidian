---
tags: [docker, containers, devops, learning, daily]
---

# 2026-05-07 09:20 Docker Commands Magazine
[[Home]]

#docker #containers #devops #learning #daily

## 今号のテーマ
**「Docker イメージ運用を段階的に身につける：作る→検証する→最適化する」**

---

## Beginner（初級）
### 1) Topic + Level
**Topic:** `docker build` / `docker images` / `docker run` の基本ループ  
**Level:** Beginner

### 2) Why it matters（実務で重要な理由）
アプリ開発では「ローカルでは動くのに本番で動かない」を減らすのが重要です。  
Docker の基本ループ（ビルド→起動→確認）を確実に回せると、開発環境差分を小さくし、レビュー時の再現性が上がります。

### 3) Core commands（コマンド解説）
- `docker build -t myapp:dev .`  
  現在ディレクトリの Dockerfile からイメージを作成し、`myapp:dev` タグを付与。
- `docker images`  
  ローカルのイメージ一覧確認。
- `docker run --rm -p 8080:8080 myapp:dev`  
  コンテナ起動。`--rm` で停止後に自動削除、`-p` でポート公開。
- `docker ps` / `docker ps -a`  
  稼働中/全コンテナ確認。
- `docker logs <container>`  
  起動エラー・アプリログ調査。

### 4) App building best practices（docs.docker.com準拠の使い方）
- Dockerfile は**小さく、責務を明確に**（不要なツールを入れない）。
- `COPY package*.json` → `RUN npm ci` → `COPY . .` のように、キャッシュ効率を意識。  
- `.dockerignore` で `node_modules` や `.git` を除外し、ビルドコンテキストを最小化。

### 5) 30-60分ミニラボ
1. 最小 Web アプリ（Hello API など）を作る。  
2. Dockerfile を作成して `docker build -t myapp:dev .`。  
3. `docker run --rm -p 8080:8080 myapp:dev` で起動。  
4. `curl localhost:8080` で応答確認。  
5. ログ確認（`docker logs`）し、1箇所だけ Dockerfile 改善（例: `.dockerignore` 追加）。

### 6) Cheatsheet
- Build: `docker build -t <name>:<tag> .`
- Run: `docker run --rm -p <host>:<container> <image>`
- List images: `docker images`
- List containers: `docker ps -a`
- Logs: `docker logs <container>`

### 7) Common mistakes & safe practices
- ミス: `latest` だけに依存してバージョン曖昧化。  
  対策: `myapp:1.0.0` 等の明示タグを併用。
- ミス: 不要ファイルを全部 COPY。  
  対策: `.dockerignore` を必ず用意。
- セキュリティ: コンテナへ秘密情報を焼き込まない（ENV直書き・COPYしない）。

### 8) Interview-style question
「`docker run --rm` を使う場面と、使わない場面を説明してください。」

### 9) Next-step resources
- https://docs.docker.com/get-started/  
- https://docs.docker.com/build/building/best-practices/  
- https://docs.docker.com/engine/reference/commandline/build/

---

## Middle（中級）
### 前提条件（Prerequisites）
- Beginner の内容を一通り実行済み
- Dockerfile の基本命令（FROM, COPY, RUN, CMD）を理解

### 1) Topic + Level
**Topic:** レイヤー最適化とマルチステージビルド  
**Level:** Middle

### 2) Why it matters
実務では CI のビルド時間・イメージサイズ・脆弱性面積がコストに直結します。  
マルチステージ化でランタイムをスリム化すると、デプロイもスキャンも速くなります。

### 3) Core commands
- `docker build --target builder -t myapp:builder .`  
  中間ステージを検証用にビルド。
- `docker build -t myapp:prod .`  
  最終ステージまでビルド。
- `docker image inspect myapp:prod`  
  メタデータ確認。
- `docker history myapp:prod`  
  レイヤー構造を確認し、肥大化ポイントを発見。

### 4) App building best practices
- Build stage と Runtime stage を分離（コンパイラ・テスト依存を最終イメージに残さない）。
- ベースイメージは用途に合う最小構成を選ぶ（例: slim系）。
- 依存の固定化（lock file）で再現性を担保。
- Secret は BuildKit secret 等を利用し、Dockerfileへ平文埋め込みしない。

### 5) 30-60分ミニラボ
1. 既存 Dockerfile を 2 ステージ化（builder/runtime）。
2. `docker build -t myapp:single -f Dockerfile.single .` と比較用を作る。
3. `docker build -t myapp:multi -f Dockerfile.multi .` を作成。
4. `docker images | grep myapp` でサイズ比較。
5. `docker history myapp:multi` で不要レイヤー削減を確認。

### 6) Cheatsheet
- Build target: `docker build --target <stage> -t <img> .`
- Layer history: `docker history <img>`
- Inspect JSON: `docker image inspect <img>`

### 7) Common mistakes & safe practices
- ミス: builder の成果物以外を runtime に COPY。  
  対策: `COPY --from=builder <artifact> <dest>` を明示。
- ミス: root ユーザーで実行し続ける。  
  対策: 可能なら non-root ユーザー運用を検討。
- 注意（破壊的コマンド）:  
  `docker image prune` / `docker rmi` は未使用イメージ削除。必要イメージまで消す恐れがあるため、実行前に `docker images` で確認し、`-f` は最終手段。

### 8) Interview-style question
「マルチステージビルドがセキュリティとデプロイ速度に与える効果を説明してください。」

### 9) Next-step resources
- https://docs.docker.com/build/building/multi-stage/  
- https://docs.docker.com/build/cache/  
- https://docs.docker.com/build/building/best-practices/

---

## Advanced（上級）
### 前提条件（Prerequisites）
- Middle の内容を実践済み
- Compose で複数サービスを起動した経験
- CI/CD でイメージを扱う基礎知識

### 1) Topic + Level
**Topic:** Docker Compose 運用と安全なクリーンアップ戦略  
**Level:** Advanced

### 2) Why it matters
実アプリは API/DB/Cache など複数サービス連携が前提です。  
Compose を正しく使えると、開発・テスト環境をコード化でき、チーム全体の再現性が上がります。

### 3) Core commands
- `docker compose up -d`  
  サービス群をバックグラウンド起動。
- `docker compose ps`  
  サービス状態確認。
- `docker compose logs -f api`  
  サービス単位のログ追跡。
- `docker compose exec api sh`  
  稼働コンテナへ入って診断。
- `docker compose down`  
  停止とネットワーク片付け（ボリューム削除は明示オプション時）。

### 4) App building best practices
- `compose.yaml` に secrets を直書きしない（`.env` 運用＋機密管理基盤を併用）。
- 開発用 override と本番設定を分離。
- Healthcheck を設定し、依存サービス起動順に頼りすぎない設計。
- 永続データ（DB）は volume で管理し、ライフサイクルを明確化。

### 5) 30-60分ミニラボ
1. `api + db` の compose 構成を作る。
2. `docker compose up -d` → `docker compose ps` で状態確認。
3. API が DB 接続できることを確認。
4. `docker compose logs -f` で障害時の調査導線を確認。
5. `docker compose down` で終了し、再起動してデータ永続性を検証。

### 6) Cheatsheet
- Start: `docker compose up -d`
- Status: `docker compose ps`
- Logs: `docker compose logs -f <service>`
- Exec: `docker compose exec <service> sh`
- Stop/Cleanup: `docker compose down`

### 7) Common mistakes & safe practices
- ミス: `down -v` を常用して DB データを消す。  
  対策: volume 削除は意図が明確なときのみ。
- ミス: `docker system prune -a` を無確認で実行。  
  対策: **非常に破壊的**。未使用イメージ/ネットワーク/キャッシュを広範囲削除。事前に影響確認し、実行前にバックアップ。
- ミス: 認証情報を Dockerfile/Compose にハードコード。  
  対策: secret 管理機構を使い、リポジトリに残さない。

### 8) Interview-style question
「`docker compose down` と `docker compose down -v` の違いを、開発環境事故の観点で説明してください。」

### 9) Next-step resources
- https://docs.docker.com/compose/  
- https://docs.docker.com/compose/gettingstarted/  
- https://docs.docker.com/engine/security/  
- https://docs.docker.com/reference/cli/docker/system/prune/

---

## 学習アーク（次号予告）
次回はこの流れを継続：  
**Beginner:** ボリューム基礎 → **Middle:** ネットワーク分離 → **Advanced:** CI での buildx / キャッシュ最適化
