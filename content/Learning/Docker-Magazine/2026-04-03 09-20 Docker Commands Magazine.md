---
tags: [docker, containers, devops, learning, daily]
---

# 2026-04-03 09:20 Docker Commands Magazine
[[Home]]

#docker #containers #devops #learning #daily

今日のテーマは、**Beginner → Middle → Advanced** の3段階で「実務で使うDockerコマンド」をつなげて学ぶ構成です。

---

## 1) Topic + Level

### Beginner
**Topic:** コンテナの基本ライフサイクル（起動・確認・停止・削除）

### Middle
**Topic:** Dockerfileを使った開発用イメージ作成と再現可能な実行
**Prerequisites:**
- Beginnerの内容を理解していること
- Linuxコマンドの基本（`cd`, `ls`, `cat`）
- アプリの最小構成（例: Node/PythonのHello World）を把握していること

### Advanced
**Topic:** マルチステージビルド + Composeでの開発環境運用 + 安全なクリーンアップ
**Prerequisites:**
- Middleの内容を完了していること
- Dockerfileレイヤー/キャッシュの概念を理解していること
- `.env` と環境変数の扱いを理解していること

---

## 2) Why it matters for real app development

- **環境差分の削減:** ローカル・CI・本番で同じイメージを使い、"自分のPCでは動く"問題を減らす。
- **オンボーディング高速化:** 新メンバーが `docker compose up` で開発環境を再現可能。
- **デプロイ信頼性向上:** Dockerfileで依存と手順をコード化し、変更履歴を追える。
- **セキュリティ/保守:** 不要なツールや秘密情報をイメージに残さない設計ができる。

---

## 3) Core Docker command explanations

### Beginner core
- `docker run -d --name web -p 8080:80 nginx:alpine`
  - イメージからコンテナ起動。`-d` バックグラウンド、`--name` 命名、`-p` ポート公開。
- `docker ps` / `docker ps -a`
  - 稼働中 / 全コンテナを確認。
- `docker logs -f web`
  - ログ追跡（`-f` フォロー）。
- `docker exec -it web sh`
  - 実行中コンテナへ対話シェル接続。
- `docker stop web` / `docker rm web`
  - 停止・削除。

### Middle core
- `docker build -t sample-app:dev .`
  - Dockerfileからイメージ作成。
- `docker images`
  - ローカルイメージ一覧。
- `docker run --rm -p 3000:3000 sample-app:dev`
  - 実行後に自動削除（`--rm`）。
- `docker inspect <container_or_image>`
  - 詳細メタ情報確認（設定・ネットワーク等）。

### Advanced core
- `docker compose up -d --build`
  - Composeサービスをビルド込みで起動。
- `docker compose logs -f app`
  - 特定サービスのログ確認。
- `docker compose exec app sh`
  - Compose管理下コンテナに入る。
- `docker compose down`
  - サービス停止・ネットワーク削除。
- `docker builder prune` / `docker image prune`
  - ビルドキャッシュ/未使用イメージ削除（後述の注意必読）。

---

## 4) How Docker is used while building apps (docs.docker.com aligned)

実務フロー（推奨）:
1. **Dockerfileを最小・明確に保つ**
   - 公式/信頼できるベースイメージを使う。
   - 不要ファイルを `.dockerignore` で除外。
2. **マルチステージビルドで本番イメージを軽量化**
   - build用依存とruntime用依存を分離。
3. **Composeで依存サービスを束ねる**
   - app + db + cache を1コマンドで起動。
4. **秘密情報をイメージに焼き込まない**
   - `ENV PASSWORD=...` のような固定埋め込みは禁止。
   - 開発では `.env` / 実行時環境変数 / シークレット管理を使う。
5. **不要リソースを定期整理（ただし慎重に）**
   - `prune` 系は影響範囲を確認してから実行。

---

## 5) 30-60 minute hands-on mini lab

**Lab: 「Hello API + Redis」をComposeで起動し、ログと再ビルドを体験する（45分目安）**

### Step 0: 事前準備（5分）
```bash
mkdir docker-mag-lab && cd docker-mag-lab
```

### Step 1: アプリ作成（10分）
`app.py`（例）を作り、簡単なHTTPレスポンスを返す。

### Step 2: Dockerfile作成（10分）
- `python:3.12-alpine` ベース
- 作業ディレクトリ設定
- 依存インストール
- アプリコピー
- `CMD ["python", "app.py"]`

### Step 3: compose.yaml作成（10分）
- `app` と `redis` サービスを定義
- `ports`, `depends_on`, `environment` を設定

### Step 4: 実行・確認（10分）
```bash
docker compose up -d --build
docker compose ps
docker compose logs -f app
curl http://localhost:8000
```

### Step 5: 変更反映（5-10分）
- アプリ応答文を変更
- 再ビルドして差分確認
```bash
docker compose up -d --build
```

**達成条件:**
- コンテナ起動/停止ができる
- ログで起動確認できる
- コード変更を再ビルドで反映できる

---

## 6) Command cheatsheet

```bash
# 起動
docker run -d --name web -p 8080:80 nginx:alpine

# 状態確認
docker ps
docker ps -a
docker images

# ログ・接続
docker logs -f web
docker exec -it web sh

# ビルド・実行
docker build -t myapp:dev .
docker run --rm -p 3000:3000 myapp:dev

# Compose
docker compose up -d --build
docker compose ps
docker compose logs -f app
docker compose down
```

---

## 7) Common mistakes and safe practices

### よくあるミス
- `latest` タグ固定で再現性が崩れる
- `COPY . .` で不要ファイルや秘密情報まで含める
- 開発用ツールを本番イメージに残す
- `docker system prune -a` を影響確認なしで実行

### 安全運用のコツ
- イメージタグは明示（例: `node:22-alpine`）。
- `.dockerignore` を必ず整備。
- シークレットは**イメージ/Compose直書きしない**。
- `prune` / `rmi` / `rm -f` 実行前に対象確認:
  - `docker ps -a`
  - `docker images`
  - `docker volume ls`

⚠️ **破壊的コマンド注意:**
- `docker system prune -a --volumes`
- `docker image rm -f <image>`
- `docker rm -f <container>`

これらは復旧困難なデータ損失につながる可能性があります。実行前に必ず対象と影響範囲を確認してください。

---

## 8) Interview-style question

**Q.** 開発では便利な `docker compose up --build` を毎回使うべきでしょうか？CI/CDや本番運用を踏まえて、使い分け方を説明してください。

（期待ポイント: キャッシュ活用、ビルド時間、再現性、イメージのプロモーション戦略、環境ごとの責務分離）

---

## 9) Next-step resources (official docs prioritized)

- Docker Documentation Home  
  https://docs.docker.com/
- Get started (Docker)  
  https://docs.docker.com/get-started/
- Dockerfile reference  
  https://docs.docker.com/reference/dockerfile/
- Build best practices  
  https://docs.docker.com/build/building/best-practices/
- Multi-stage builds  
  https://docs.docker.com/build/building/multi-stage/
- Docker Compose docs  
  https://docs.docker.com/compose/
- Compose file reference  
  https://docs.docker.com/reference/compose-file/
- Docker Engine prune reference  
  https://docs.docker.com/engine/manage-resources/pruning/

---

明日の予告: **ネットワークとボリュームを実務目線で深掘り**（データ永続化・サービス間通信・トラブルシュート）。
