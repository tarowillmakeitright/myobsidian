# Docker Commands Magazine — 2026-04-04

[[Home]]

タグ: #docker #containers #devops #learning #daily

---

## 今号の学習アーク
Beginner → Middle → Advanced の順で、実務でよく使う Docker コマンドを段階的に強化します。

---

## 1) Topic + Level

### Beginner
**Topic:** コンテナの基本操作（`docker run`, `docker ps`, `docker logs`, `docker exec`）

### Middle
**Topic:** イメージ作成と再現可能な開発環境（`docker build`, `docker compose up`, `docker compose logs`）
**Prerequisites:**
- Beginner のコマンドを使ってコンテナを起動・停止できる
- Dockerfile の基本（`FROM`, `COPY`, `RUN`, `CMD`）を読める

### Advanced
**Topic:** マルチステージビルド + キャッシュ最適化 + セキュア運用（BuildKit, non-root, secrets）
**Prerequisites:**
- Middle の compose 運用を理解している
- レイヤーキャッシュの概念（Docker build cache）を説明できる
- `.env` と環境変数の扱いを理解している

---

## 2) Why it matters for real app development

- ローカル・CI・本番で同じ実行環境を再現しやすくなる
- 「自分のPCでは動く」問題を減らし、チーム開発の速度と品質を上げる
- compose を使って API / DB / cache をまとめて起動でき、開発開始までの時間を短縮できる
- BuildKit とマルチステージでイメージを小さくし、ビルド時間と脆弱性面積を削減できる

---

## 3) Core Docker command explanations

- `docker run IMAGE` : 新しいコンテナを作成して実行
- `docker ps` / `docker ps -a` : 実行中 / 全コンテナ確認
- `docker logs CONTAINER` : 標準出力・エラー確認（`-f` で追尾）
- `docker exec -it CONTAINER sh` : コンテナ内に入って調査
- `docker build -t name:tag .` : Dockerfile からイメージ作成
- `docker compose up -d` : 複数サービスをバックグラウンド起動
- `docker compose down` : compose リソース停止・削除（ネットワーク等）
- `docker image ls` / `docker container ls` / `docker volume ls` : 資産確認

---

## 4) How Docker is used while building apps (docs.docker.com aligned)

実務フローの例（Docker公式の推奨に沿った形）:

1. **開発用 Dockerfile を作る**
   - 軽量ベースイメージを選ぶ（例: `node:20-alpine` など）
   - 依存関係を先にコピーしてキャッシュ効率を上げる
2. **`.dockerignore` を整備する**
   - `node_modules`, `.git`, ビルド成果物を除外
3. **compose で依存サービスを束ねる**
   - app + db + redis を一括起動
4. **環境差分は環境変数で管理**
   - シークレットはイメージに焼き込まない（`ENV PASSWORD=...` を避ける）
5. **本番は最小イメージ + non-root**
   - マルチステージビルドで build tool を最終イメージから除外
   - `USER` で root 実行を避ける

参考（公式）:
- https://docs.docker.com/build/
- https://docs.docker.com/build/cache/
- https://docs.docker.com/compose/
- https://docs.docker.com/develop/
- https://docs.docker.com/security/

---

## 5) 30-60 minute hands-on mini lab

### ゴール
シンプルな Web アプリ（Nginx で静的ページ配信）を build & compose で動かし、ログ確認まで行う。

### 手順（約45分）

1. 作業フォルダ作成
```bash
mkdir -p docker-mag-lab && cd docker-mag-lab
```

2. `index.html` 作成
```html
<h1>Hello Docker Magazine</h1>
<p>2026-04-04 issue</p>
```

3. `Dockerfile` 作成
```dockerfile
FROM nginx:alpine
COPY index.html /usr/share/nginx/html/index.html
EXPOSE 80
```

4. ビルド
```bash
docker build -t mag-nginx:0.1 .
```

5. 単体起動して確認
```bash
docker run --name mag-web -d -p 8080:80 mag-nginx:0.1
docker ps
docker logs mag-web
```
ブラウザで `http://localhost:8080` を確認。

6. compose 化（`compose.yaml`）
```yaml
services:
  web:
    build: .
    ports:
      - "8080:80"
```

7. compose 起動
```bash
docker compose up -d
docker compose logs -f web
```

8. 終了
```bash
docker compose down
```

任意発展（Advanced寄り）:
- `.dockerignore` を追加してビルド時間の差を比較
- `USER` を指定した別Dockerfileを試す

---

## 6) Command cheatsheet

```bash
# 基本確認
docker --version
docker info

# コンテナ
docker ps
docker ps -a
docker logs -f <container>
docker exec -it <container> sh
docker stop <container>
docker rm <container>

# イメージ
docker build -t <name>:<tag> .
docker image ls
docker rmi <image>

# Compose
docker compose up -d
docker compose ps
docker compose logs -f
docker compose down
```

---

## 7) Common mistakes and safe practices

よくあるミス:
- `latest` タグ固定で再現性が崩れる
- `COPY . .` を早い段階で実行してキャッシュ効率を落とす
- `.env` や秘密情報をイメージに含める
- root ユーザーのまま本番運用する

安全運用のポイント:
- イメージタグは明示（例: `1.2.3`）
- シークレットは Docker secrets / 外部 secret manager / CI secrets を使用
- 不要なポート公開を避ける（`0.0.0.0` 公開は最小限）
- 定期的にベースイメージ更新 + 脆弱性スキャン

⚠️ 破壊的コマンドの注意:
- `docker system prune -a`
- `docker image prune -a`
- `docker rmi -f ...`
- `docker rm -f ...`

これらは**未使用リソースや稼働中コンテナに影響**する可能性があります。実行前に `docker ps -a`, `docker image ls`, `docker volume ls` で対象確認し、共有環境では必ず合意を取ること。

---

## 8) One interview-style question

「あなたのチームで Docker build が遅く、CI コストが高いです。Dockerfile とパイプラインをどう改善して、再現性・セキュリティを落とさず高速化しますか？」

（期待される観点: レイヤー順序、依存キャッシュ、.dockerignore、マルチステージ、ベースイメージ選定、secret の安全な注入）

---

## 9) Next-step resources (official first)

- Docker Get Started: https://docs.docker.com/get-started/
- Dockerfile reference: https://docs.docker.com/reference/dockerfile/
- Build best practices: https://docs.docker.com/build/building/best-practices/
- Docker Compose manual: https://docs.docker.com/compose/
- Docker Engine security: https://docs.docker.com/engine/security/
- Compose production best practices: https://docs.docker.com/compose/production/

---

次号予告（学習アーク継続）:
- Beginner: ボリュームと永続化
- Middle: ヘルスチェックと依存起動制御
- Advanced: Buildx / マルチアーキ / SBOM 入門
