---
tags: [docker, containers, devops, learning, daily]
---

# 2026-05-19 09:20 Docker Commands Magazine
[[Home]]

#docker #containers #devops #learning #daily

## 今号テーマ
**Docker コマンドで学ぶ「開発〜運用の基本フロー」**

- **Beginner:** イメージ取得〜コンテナ起動
- **Middle:** Dockerfile でアプリをビルド
- **Advanced:** マルチステージビルド + セキュア運用

---

## 1) Topic + Level

### Level 1 — Beginner
**Topic:** `docker pull` / `docker run` / `docker ps` / `docker logs`

### Level 2 — Middle
**Topic:** `docker build` / `docker exec` / `docker stop` / `docker rm`
**Prerequisites:**
- Beginner のコマンドを理解している
- 1つ以上の簡単な Web アプリ（Node/Python/Go など）をローカルで動かした経験

### Level 3 — Advanced
**Topic:** マルチステージビルド、最小権限、キャッシュ最適化
**Prerequisites:**
- Dockerfile を書いて `docker build` できる
- ベースイメージ・レイヤー・コンテナライフサイクルの基礎理解

---

## 2) なぜ実アプリ開発で重要か

- **環境差異を消せる:** チーム全員が同じ実行環境で開発できる
- **再現可能なビルド:** CI/CD で「ローカルでは動くのに…」を減らせる
- **デプロイ速度向上:** イメージ化でリリース単位が明確になる
- **セキュリティ向上:** 最小イメージ・非 root 実行・秘密情報分離を徹底できる

---

## 3) Core Docker command explanations

- `docker pull <image>:<tag>`
  - レジストリからイメージを取得。タグ固定（例: `nginx:1.27`）で再現性を上げる。

- `docker run [options] <image>`
  - コンテナ起動。よく使うオプション:
  - `-d` バックグラウンド
  - `-p host:container` ポート公開
  - `--name` 名前付け
  - `--rm` 停止時に自動削除（検証向け）

- `docker ps` / `docker ps -a`
  - 起動中 / 全コンテナ確認。

- `docker logs -f <container>`
  - ログ追跡。アプリの起動失敗調査の第一歩。

- `docker build -t <name>:<tag> .`
  - Dockerfile からイメージ作成。

- `docker exec -it <container> sh`
  - コンテナ内で調査・デバッグ（本番での多用は避ける）。

- `docker stop <container>`
  - 正常停止（SIGTERM → 猶予後 SIGKILL）。

- `docker rm <container>`
  - 停止済みコンテナ削除。

---

## 4) 実アプリ構築での使い方（docs.docker.com ベストプラクティス準拠）

1. **ベースイメージを明示的に管理**
   - `latest` 依存を避ける
   - 可能なら slim / alpine 系を比較して選定

2. **Dockerfile をレイヤー最適化**
   - 依存ファイル（`package*.json` など）を先に `COPY` してキャッシュ活用
   - 変更頻度が低い処理ほど上段に配置

3. **マルチステージビルドを使う**
   - ビルドツールを最終イメージに含めない
   - 攻撃面とサイズを削減

4. **秘密情報をイメージに焼かない**
   - `ENV API_KEY=...` を Dockerfile に直書きしない
   - シークレットは実行時注入（環境変数・secret 管理）

5. **不要な公開をしない**
   - 必要ポートのみ `-p` で公開
   - ローカル検証では `127.0.0.1:8080:80` のようにバインド範囲を狭める

---

## 5) 30〜60分ミニラボ

### ゴール
Node.js の簡易 API を Docker 化し、軽量で安全寄りのイメージを作る。

### 手順（約45分）

1. プロジェクト作成（10分）
```bash
mkdir docker-mini-lab && cd docker-mini-lab
cat > server.js <<'EOF'
const http = require('http');
const port = process.env.PORT || 3000;
http.createServer((req,res)=>{
  res.writeHead(200, {'Content-Type':'application/json'});
  res.end(JSON.stringify({ok:true, ts: Date.now()}));
}).listen(port, ()=> console.log(`listening ${port}`));
EOF
```

2. Dockerfile 作成（10分）
```Dockerfile
# syntax=docker/dockerfile:1
FROM node:20-alpine AS base
WORKDIR /app
COPY server.js .

# 非rootユーザー（簡易）
USER node
EXPOSE 3000
CMD ["node", "server.js"]
```

3. ビルドと起動（10分）
```bash
docker build -t mini-api:2026-05-19 .
docker run -d --name mini-api -p 127.0.0.1:3000:3000 mini-api:2026-05-19
docker ps
docker logs -f mini-api
```

4. 動作確認（5分）
```bash
curl http://127.0.0.1:3000
```

5. 後片付け（安全版）（5分）
```bash
docker stop mini-api
docker rm mini-api
```

6. 発展（+10分）
- マルチステージ化
- `.dockerignore` 追加
- `HEALTHCHECK` 検討

---

## 6) Command cheatsheet

```bash
# イメージ取得
docker pull nginx:1.27

# 起動（ポート公開 + 名前）
docker run -d --name web -p 127.0.0.1:8080:80 nginx:1.27

# 稼働確認
docker ps

# ログ確認
docker logs -f web

# コンテナ内に入る
docker exec -it web sh

# ビルド
docker build -t myapp:1.0.0 .

# 停止・削除
docker stop web
docker rm web
```

---

## 7) よくあるミス & 安全な運用

### よくあるミス
- `latest` タグ固定なしで再現性が崩れる
- `.env` や秘密鍵を `COPY . .` でイメージ混入
- root 実行のまま本番運用
- コンテナ削除忘れでローカルが散らかる

### 安全プラクティス
- タグ固定、できれば digest pin 検討
- `.dockerignore` で秘密情報除外
- 非 root ユーザー実行
- 不要ポートは公開しない
- 定期的に `docker image ls` / `docker ps -a` を整理

### ⚠ 破壊的クリーンアップの注意
以下は**削除影響が大きい**ため、実行前に対象確認必須:
- `docker system prune`
- `docker image prune -a`
- `docker rmi ...`
- `docker rm -f ...`

実行前の推奨確認:
```bash
docker ps -a
docker image ls
docker volume ls
docker network ls
```

---

## 8) 面接っぽい質問（1問）

**Q.** `docker run` と `docker exec` の違いは？実運用で使い分けを説明してください。

---

## 9) 次の学習リソース（公式優先）

- Docker Get Started  
  https://docs.docker.com/get-started/
- Dockerfile best practices  
  https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Multi-stage builds  
  https://docs.docker.com/build/building/multi-stage/
- Image building overview  
  https://docs.docker.com/build/
- Docker Engine security  
  https://docs.docker.com/engine/security/

---

### 次号予告（Learning Arc）
- Beginner: ボリューム基礎
- Middle: Compose で複数サービス連携
- Advanced: BuildKit キャッシュ戦略 + SBOM/脆弱性スキャン入門
