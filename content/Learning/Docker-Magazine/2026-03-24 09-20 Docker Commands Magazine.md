---
tags: [docker, containers, devops, learning, daily]
created: 2026-03-24
---

# 2026-03-24 09:20 Docker Commands Magazine
[[Home]]

今日のテーマは **「開発フローで使う Docker コマンド実践」**。  
難易度を **Beginner → Middle → Advanced** の学習アークで段階的に進めます。

> 安全メモ: `docker system prune` / `docker image prune -a` / `docker rm -f` / `docker rmi` は削除系コマンドです。実行前に対象確認し、必要ならバックアップ・チーム合意を取ってください。

---

## 1) Topic + Level

### Beginner: 「コンテナの基本ライフサイクルを理解する」
対象コマンド: `docker run`, `docker ps`, `docker logs`, `docker exec`, `docker stop`, `docker rm`

### Middle: 「Dockerfile を使って再現可能な開発環境を作る」
**前提知識**: Beginner の内容（コンテナ起動・停止・ログ確認・削除）ができること。  
対象コマンド: `docker build`, `docker images`, `docker tag`, `docker history`

### Advanced: 「Compose で複数サービスを安全に運用する」
**前提知識**: Middle の内容（Dockerfile ビルド、イメージ管理）ができること。  
対象コマンド: `docker compose up`, `docker compose logs`, `docker compose exec`, `docker compose down`

---

## 2) Why it matters for real app development

- **ローカル開発の再現性**: 「自分のPCでは動く」を減らせる。  
- **オンボーディング高速化**: 新メンバーが同じ環境を短時間で再現可能。  
- **本番との差分縮小**: コンテナを軸に dev/stg/prod の差異を減らす。  
- **トラブルシュート効率**: `logs`, `exec`, `inspect` 系で原因を絞り込みやすい。  
- **セキュリティと保守性**: 最小イメージ・秘密情報の分離・不要削除の慎重運用が可能。

---

## 3) Core Docker command explanations

### Beginner Core
- `docker run --name app -p 8080:80 nginx:alpine`  
  イメージからコンテナを起動。`-p` はホスト:コンテナのポート公開。
- `docker ps` / `docker ps -a`  
  実行中 / 全コンテナを確認。
- `docker logs -f app`  
  ログ追跡。`-f` で tail。
- `docker exec -it app sh`  
  稼働中コンテナへ対話シェル接続。
- `docker stop app && docker rm app`  
  停止して削除（状態をクリーンに保つ）。

### Middle Core
- `docker build -t myapp:dev .`  
  カレントディレクトリの Dockerfile でイメージ作成。
- `docker images`  
  ローカルイメージ一覧。
- `docker tag myapp:dev myapp:2026-03-24`  
  タグ付けでバージョン管理。
- `docker history myapp:dev`  
  レイヤ構成確認（肥大化・秘匿情報混入の気づきに有効）。

### Advanced Core
- `docker compose up -d --build`  
  複数サービスをビルド＋起動。
- `docker compose logs -f api`  
  指定サービスのログ追跡。
- `docker compose exec api sh`  
  サービスコンテナへ接続。
- `docker compose down`  
  スタック停止・ネットワーク削除。  
  ※ `-v` はボリュームも消すため要注意（データ消失リスク）。

---

## 4) App building での Docker活用（docs.docker.com ベストプラクティス準拠）

- **小さいベースイメージを選ぶ**（例: `alpine`/distroless、ただし互換性は検証）。
- **マルチステージビルド**でビルド依存を最終イメージに残さない。
- **`.dockerignore` を整備**して不要ファイルをコンテキストに含めない。
- **依存レイヤのキャッシュ最適化**（`COPY package*.json` → install → `COPY . .`）。
- **コンテナは単一責務**を意識、複数プロセスを詰め込みすぎない。
- **秘密情報はイメージに埋め込まない**（`ENV PASSWORD=...` や `COPY .env` は避ける）。
- **Compose では環境変数や secrets を適切に分離**し、Gitに機密を置かない。
- **不要な root 実行を避ける**（可能なら non-root ユーザーで実行）。

---

## 5) 30–60分ハンズオン mini lab

### Lab Goal
Node.js API + Redis を Compose で起動し、ログ確認・再ビルド・安全なクリーンアップまで体験する。

### 所要時間
45分目安

### 手順
1. **プロジェクト作成（10分）**
   - `app.js` で簡単な HTTP エンドポイント作成
   - `Dockerfile` 作成（`node:20-alpine` など）
   - `.dockerignore` 作成（`node_modules`, `.git`, `.env` など）

2. **単体ビルド＆実行（10分）**
   - `docker build -t mini-api:dev .`
   - `docker run --name mini-api -p 3000:3000 mini-api:dev`
   - `docker logs -f mini-api`

3. **Compose 連携（15分）**
   - `compose.yaml` で `api` + `redis` 定義
   - `docker compose up -d --build`
   - `docker compose ps` と `docker compose logs -f api`

4. **変更反映と検証（5分）**
   - コード変更 → `docker compose up -d --build`
   - 応答確認

5. **安全クリーンアップ（5分）**
   - `docker compose down`
   - 不要コンテナ確認: `docker ps -a`
   - 必要なら明示削除: `docker rm <id>`

> 危険操作注意: `docker system prune -a` は未使用イメージ・ネットワーク等を広範囲削除します。共有環境・作業中環境では原則避け、対象を確認してから。

---

## 6) Command cheatsheet

```bash
# 状態確認
docker ps
docker ps -a
docker images
docker compose ps

# 実行・ログ・接続
docker run --name sample -p 8080:80 nginx:alpine
docker logs -f sample
docker exec -it sample sh
docker compose up -d --build
docker compose logs -f api
docker compose exec api sh

# 停止・削除（注意して実行）
docker stop sample
docker rm sample
docker compose down
# 注意: down -v はボリューム削除
# 注意: system/image/container prune は削除範囲が広い
```

---

## 7) Common mistakes and safe practices

### よくあるミス
- `latest` タグ固定で再現性が崩れる
- `COPY . .` を先に書いてキャッシュが効かずビルド遅延
- `.env` や秘密鍵をイメージに含める
- `docker compose down -v` でDBデータを消す
- `docker rm -f` を常用し、原因調査の機会を失う

### 安全運用
- イメージタグは明示（例: `myapp:1.4.2`）
- `docker history` とスキャンで不要/危険レイヤを確認
- シークレットは環境注入 or secret 管理機構へ分離
- 削除系は「一覧確認 → 対象指定」で最小範囲実行
- 本番相当データを扱うボリュームはバックアップ前提

---

## 8) One interview-style question

**Q.** `docker run` と `docker compose up` の使い分けを、開発チーム運用の観点で説明してください。さらに、Compose利用時に secrets を安全に扱うための基本方針を1つ挙げてください。

---

## 9) Next-step resources（公式優先）

- Docker Docs Home  
  https://docs.docker.com/
- Get started (公式チュートリアル)  
  https://docs.docker.com/get-started/
- Dockerfile best practices  
  https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Multi-stage builds  
  https://docs.docker.com/build/building/multi-stage/
- Compose documentation  
  https://docs.docker.com/compose/
- Docker Engine security  
  https://docs.docker.com/engine/security/

---

### 明日の予告
次号は「Docker ネットワーク実践（bridge / service discovery / ポート公開戦略）」を予定。Beginner→Advanced で、通信トラブルの切り分け手順まで扱います。