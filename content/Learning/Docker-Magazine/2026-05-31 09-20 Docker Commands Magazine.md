---
tags: [docker, containers, devops, learning, daily]
---

# 2026-05-31 09:20 Docker Commands Magazine
[[Home]]

#docker #containers #devops #learning #daily

本日のテーマは、実務で必ず使う「**コンテナのライフサイクル管理**」です。難易度は **Beginner → Middle → Advanced** の順で進みます。

---

## 1) Topic + Level

### Beginner
**Topic:** `docker run` / `docker ps` / `docker stop` / `docker logs` でアプリを安全に動かす

### Middle
**Topic:** `Dockerfile` の改善（レイヤー最適化、キャッシュ活用、`.dockerignore`）
**Prerequisites:**
- Beginnerの内容を一通り実行できる
- Linuxコマンド（`cd`, `ls`, `cat`）が使える
- 最低1つはWebアプリ（Node/Python/Go等）を触ったことがある

### Advanced
**Topic:** BuildKit/マルチステージビルド + セキュアなイメージ運用（最小権限・秘密情報の扱い）
**Prerequisites:**
- Middleで Dockerfile を編集してビルドした経験
- ベースイメージ、レイヤー、タグの概念理解
- CI/CDでコンテナを使うイメージがある

---

## 2) Why it matters for real app development

- 開発環境差異（「自分のPCでは動く問題」）を減らせる
- 本番に近い形でローカル検証でき、バグの再現性が上がる
- ビルド時間・イメージサイズ最適化はCI時間とコストを直接削減
- セキュアな運用（非root・秘密情報分離）はインシデント予防に直結

---

## 3) Core Docker command explanations

- `docker run IMAGE`:
  新規コンテナを作成して起動（create + start）。`-d` でバックグラウンド、`-p` でポート公開。
- `docker ps` / `docker ps -a`:
  稼働中 / 全コンテナの確認。
- `docker logs CONTAINER`:
  標準出力/標準エラーを確認。`-f` で追尾。
- `docker exec -it CONTAINER sh`:
  実行中コンテナに入って調査。
- `docker build -t name:tag .`:
  Dockerfileからイメージ作成。
- `docker images`:
  ローカルイメージ一覧。
- `docker stop CONTAINER` / `docker rm CONTAINER`:
  停止 / 削除。
- `docker rmi IMAGE`:
  イメージ削除。

⚠️ **注意（破壊的コマンド）**
- `docker system prune` / `docker image prune -a` / `docker rm -f` / `docker rmi` は不要リソースや実行中資産を失う可能性があります。実行前に `docker ps -a` と `docker images` を必ず確認してください。

---

## 4) How Docker is used while building apps (docs.docker.com aligned)

実務フロー例（Docker公式ベストプラクティス準拠）:

1. **開発初期**: 軽量ベースイメージ（例: `node:20-alpine`）で試作
2. **依存解決最適化**: `COPY package*.json` → `RUN npm ci` → `COPY . .` の順でキャッシュ効率化
3. **不要ファイル除外**: `.dockerignore`（`.git`, `node_modules`, `.env` など）
4. **本番向け最適化**: マルチステージでビルド成果物だけを最終イメージへ
5. **セキュリティ**:
   - 可能な限り非rootユーザーで実行
   - 秘密情報を `Dockerfile` に埋め込まない
   - `.env` をイメージにCOPYしない
6. **運用**: タグ戦略（`app:1.4.2`, `app:stable`）と脆弱性スキャンをCIに統合

---

## 5) 30-60 minute hands-on mini lab

**Lab: Node APIをDocker化し、サイズとセキュリティを改善する（45分目安）**

### Step A (10分): 最小API作成
1. `app.js` を作成（Hello API）
2. `package.json` 作成
3. ローカルで動作確認

### Step B (15分): Docker化（Beginner→Middle）
1. Dockerfile v1 を作成
2. `docker build -t hello-api:v1 .`
3. `docker run --name hello-api -p 3000:3000 hello-api:v1`
4. `docker logs -f hello-api`

### Step C (10分): 最適化（Middle）
1. `.dockerignore` 追加
2. 依存ファイル先コピーに修正
3. 再ビルドして時間差・サイズ差を確認

### Step D (10分): セキュア化（Advanced）
1. マルチステージに変更
2. 非rootユーザーで起動
3. 秘密情報を環境変数/シークレットとして外部注入（イメージ埋め込み禁止）

成功条件:
- `curl http://localhost:3000` が返る
- v1より改善版イメージのサイズが縮小
- コンテナが非rootで動いている

---

## 6) Command cheatsheet

```bash
# 起動
docker run -d --name web -p 3000:3000 myapp:dev

# 状態確認
docker ps
docker ps -a
docker images

# ログ/デバッグ
docker logs -f web
docker exec -it web sh

# ビルド
docker build -t myapp:dev .

# 停止/削除
docker stop web
docker rm web

# 危険: 削除系（実行前に確認）
# docker rm -f <container>
# docker rmi <image>
# docker system prune
```

---

## 7) Common mistakes and safe practices

よくあるミス:
- `latest` タグ固定で再現性が落ちる
- `.env` や秘密鍵をイメージに含める
- `COPY . .` を先にしてキャッシュが毎回無効化
- root実行のまま本番投入

安全な実践:
- バージョンタグを固定（例: `node:20.11-alpine`）
- シークレットは Docker secrets / CI secret / 実行時環境変数で注入
- `.dockerignore` を必ず整備
- 最終イメージは必要最小限（マルチステージ）
- cleanup系コマンド前に「対象確認 → バックアップ/復元手段確認」

---

## 8) Interview-style question

**Q.** `docker run` と `docker start` の違いを説明し、再現性ある開発フローでどう使い分けるべきですか？

（期待ポイント: `run=create+start`, `start=既存再起動`, 設定差分管理、Dockerfile/Composeで宣言的に管理）

---

## 9) Next-step resources (official-first)

- Docker 公式 Get Started: https://docs.docker.com/get-started/
- Dockerfile best practices: https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Multi-stage builds: https://docs.docker.com/build/building/multi-stage/
- Build cache: https://docs.docker.com/build/cache/
- Docker Engine security: https://docs.docker.com/engine/security/
- Compose overview: https://docs.docker.com/compose/

---

次号予告: **Middle → Advanced の橋渡しとして「Composeでローカル開発をチーム共通化」**
