# Docker Commands Magazine — 2026-03-12

#docker #containers #devops #learning #daily
[[Home]]

---

## 今号のテーマ
**「Docker イメージ/コンテナ運用の基礎から実践まで：`build` → `run` → `logs/exec` → `compose`」**

学習アーク（段階的難易度）:
1. **Beginner**: 単一コンテナを安全に動かす
2. **Middle**: 複数サービスを `docker compose` で連携
3. **Advanced**: 本番を意識したビルド最適化とセキュア運用

---

## 1) Topic + Level

### Beginner
**トピック:** `docker build`, `docker run`, `docker ps`, `docker logs`, `docker exec`

### Middle
**トピック:** `docker compose up/down`, ボリューム、環境変数の扱い
**前提知識:**
- Beginner のコマンドが使える
- ポート公開（`-p`）の意味を説明できる
- コンテナとイメージの違いを理解している

### Advanced
**トピック:** マルチステージビルド、キャッシュ活用、最小権限・秘密情報保護
**前提知識:**
- Middle の Compose 運用ができる
- Dockerfile を読める
- CI/CD でイメージを配布する流れをイメージできる

---

## 2) なぜ実アプリ開発で重要か

- **再現性**: 開発者ごとの差分（OS/ライブラリ差）を減らせる
- **オンボーディング高速化**: 新メンバーが短時間で同じ実行環境を再現できる
- **デバッグ効率**: `logs`/`exec` で問題箇所に素早く到達
- **本番移行の一貫性**: 開発環境に近い構成をそのまま検証・配備しやすい
- **セキュリティ/運用性**: イメージ最小化・秘密情報分離でリスクを下げる

---

## 3) コア Docker コマンド解説

- `docker build -t app:dev .`
  - カレントディレクトリの Dockerfile からイメージ作成
  - `-t` でタグ付け（管理しやすくなる）

- `docker run --name app -p 8080:8080 app:dev`
  - イメージからコンテナ起動
  - `--name` で識別しやすく、`-p` でホストに公開

- `docker ps` / `docker ps -a`
  - 起動中 / 全コンテナ確認

- `docker logs -f app`
  - ログ追跡（障害調査の第一歩）

- `docker exec -it app sh`
  - 稼働中コンテナ内で調査

- `docker compose up -d`
  - 複数サービスをバックグラウンド起動

- `docker compose down`
  - Compose 構成を停止・削除（ネットワーク等）

---

## 4) アプリ開発中の Docker 活用（docs.docker.com ベストプラクティス準拠）

- **小さく保つ**: 軽量ベースイメージ + 不要ファイル除外（`.dockerignore`）
- **責務分離**: 1コンテナ1責務を基本に、DB/APP を Compose で分離
- **設定の外部化**: 環境差分は環境変数や Compose で注入
- **秘密情報を焼き込まない**:
  - ❌ `Dockerfile` に API キーを `ENV` 直書き
  - ✅ 実行時注入（シークレット管理、環境側設定）
- **非 root / 最小権限**を意識
- **タグ運用**: `latest` 依存を減らし、バージョン明示

---

## 5) 30–60分ミニラボ（目安45分）

### ゴール
Node.js API + Redis の2サービス構成を Compose で起動し、ログ確認と簡易デバッグを行う。

### 手順
1. **準備 (10分)**
   - 簡単な Node.js API（`/health`）を用意
   - `Dockerfile` 作成（開発向け）

2. **単体確認 (10分)**
   - `docker build -t node-api:dev .`
   - `docker run --rm -p 3000:3000 --name node-api node-api:dev`
   - `curl http://localhost:3000/health`

3. **Compose化 (15分)**
   - `compose.yaml` に `api` と `redis` を定義
   - `docker compose up -d`
   - `docker compose ps` で状態確認
   - `docker compose logs -f api`

4. **デバッグ演習 (10分)**
   - `docker compose exec api sh` で内部確認
   - 環境変数ミスを意図的に起こし、ログから原因特定

### 完了条件
- API が 200 を返す
- Redis コンテナが起動している
- ログから設定ミスを特定できる

---

## 6) コマンドチートシート

```bash
# Build / Run
docker build -t myapp:dev .
docker run --name myapp -p 8080:8080 myapp:dev

# Inspect
docker ps
docker logs -f myapp
docker exec -it myapp sh

# Compose
docker compose up -d
docker compose ps
docker compose logs -f
docker compose exec api sh
docker compose down

# Cleanup（要注意）
# ⚠ 削除対象を必ず確認してから実行
# docker rm -f <container>
# docker rmi <image>
# docker system prune
```

---

## 7) よくあるミスと安全策

- **ミス:** `Dockerfile` に秘密情報を埋め込む
  - **安全策:** 実行時注入・シークレット機構を利用

- **ミス:** `latest` 固定で予期せぬ差分混入
  - **安全策:** 明示タグ（例: `node:22-alpine`）

- **ミス:** 不要な `COPY . .` で機密や巨大ファイル混入
  - **安全策:** `.dockerignore` を整備

- **ミス:** 破壊的クリーンアップを無確認で実行
  - **安全策:**
    - `docker ps -a`, `docker images`, `docker volume ls` で事前確認
    - `prune`/`rmi`/`rm -f` は影響範囲を確認してから

- **ミス:** root 実行のまま運用
  - **安全策:** 非 root ユーザーを利用、必要最小権限で実行

---

## 8) 面接風質問（1問）

**質問:**
「`docker run` と `docker compose up` の使い分けを、開発チーム運用の観点で説明してください。さらに、環境変数と秘密情報をどう分離するかも述べてください。」

---

## 9) 次の一歩（公式ドキュメント中心）

- Docker Docs Home: https://docs.docker.com/
- Get Started: https://docs.docker.com/get-started/
- Dockerfile Best Practices: https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Multi-stage builds: https://docs.docker.com/build/building/multi-stage/
- Compose overview: https://docs.docker.com/compose/
- Compose file reference: https://docs.docker.com/reference/compose-file/
- Engine security: https://docs.docker.com/engine/security/
- Build cache: https://docs.docker.com/build/cache/

---

### 明日の予告
次号は「**Beginner→Middle→Advanced で学ぶ Docker ネットワーク（bridge / compose network / service discovery）**」を扱います。