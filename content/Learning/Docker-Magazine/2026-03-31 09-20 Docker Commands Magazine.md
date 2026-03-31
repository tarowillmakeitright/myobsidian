---
tags: [docker, containers, devops, learning, daily]
created: 2026-03-31
---

# Docker Commands Magazine — 2026-03-31 (09:20)
[[Home]]

> 今日のテーマは **「コンテナ開発の基本ループを作る」**。  
> 難易度は **Beginner → Middle → Advanced** の順で進みます。

---

## 1) Topic + Level

### Beginner
**Topic:** `docker run` / `docker ps` / `docker logs` で「動かして観察する」

### Middle
**Topic:** `Dockerfile` + `docker build` + `docker compose up` で開発環境を再現する  
**Prerequisites:**
- Beginnerの内容（コンテナ起動・停止・ログ確認）ができる
- Linuxコマンド基礎（`cd`, `ls`, `cat`）

### Advanced
**Topic:** BuildKit / マルチステージビルド / 最小権限実行で安全かつ高速なイメージ運用  
**Prerequisites:**
- Middleの内容（Dockerfile作成、Compose起動）
- アプリ依存管理（npm/pip等）の基本
- CI/CDの基礎理解（任意）

---

## 2) なぜ実アプリ開発で重要か

- **環境差分の削減**: 「自分のPCでは動く」を減らせる
- **オンボーディング高速化**: 新メンバーが同じ手順で起動できる
- **デバッグ効率化**: ログ・プロセス・ネットワークをコマンドで可視化
- **本番に近い検証**: 依存バージョンをイメージに固定できる
- **セキュリティ向上**: 最小ベースイメージ・非root実行などを標準化

---

## 3) Core Docker command explanations

- `docker run IMAGE`  
  イメージからコンテナを起動。`-d`でバックグラウンド、`-p 8080:80`でポート公開。

- `docker ps` / `docker ps -a`  
  起動中／全コンテナの確認。

- `docker logs CONTAINER` / `docker logs -f CONTAINER`  
  ログ確認。`-f`で追従。

- `docker exec -it CONTAINER sh`  
  稼働中コンテナ内で調査。デバッグ時に有効。

- `docker build -t app:dev .`  
  Dockerfileからイメージ作成。

- `docker compose up -d` / `docker compose down`  
  複数サービス（app/db等）を一括起動・停止。

- `docker image ls`, `docker container ls`, `docker volume ls`, `docker network ls`  
  リソースの棚卸し。

---

## 4) アプリ構築時の使い方（docs.docker.com ベストプラクティス準拠）

- **小さく保つ**: 不要ファイルを `.dockerignore` で除外
- **キャッシュを活かす**: 依存インストール層を先に配置
- **マルチステージビルド**: ビルド用ツールを最終イメージに持ち込まない
- **1コンテナ1責務**: app, db, cacheをComposeで分離
- **設定は外出し**: 環境変数やシークレット管理（イメージに焼き込まない）
- **非rootユーザーで実行**: 被害最小化
- **イミュータブル運用**: コンテナを手修正せず再ビルドで反映

> ⚠️ **Secret安全運用**  
> `ENV PASSWORD=...` や `COPY .env` を Dockerfile に書かない。  
> Composeの`secrets`や環境管理基盤（CI secret, vault等）を利用。

---

## 5) 30–60分ハンズオン mini lab

### ゴール
Node.js API + Redis を Compose で起動し、ログ確認と安全な再ビルドを体験。

### 手順（目安45分）
1. **プロジェクト作成（10分）**
   - `app/` に簡易API（`/health`）を作る
   - `package.json` を用意

2. **Dockerfile作成（10分）**
   - `node:20-alpine` をベース
   - 依存インストール層を分離
   - `USER node` に変更

3. **compose.yaml作成（10分）**
   - `app` + `redis` サービス
   - `depends_on`, `ports`, `environment` を設定

4. **起動・確認（10分）**
   - `docker compose up -d --build`
   - `docker compose ps`
   - `docker compose logs -f app`
   - `curl http://localhost:3000/health`

5. **改善（5分）**
   - `.dockerignore` を追加
   - 再ビルド速度の差を確認

### 期待成果
- チーム全員が同一手順で起動できる
- ローカル開発を短時間で再現可能

---

## 6) Command cheatsheet

```bash
# 起動/確認
docker run -d --name web -p 8080:80 nginx
docker ps
docker logs -f web

# コンテナ内調査
docker exec -it web sh

# イメージ作成
docker build -t myapp:dev .

# Compose
docker compose up -d --build
docker compose ps
docker compose logs -f
docker compose down

# リソース確認
docker image ls
docker volume ls
docker network ls
```

---

## 7) よくあるミスと安全策

1. **ミス:** `latest` タグ固定で再現性が崩れる  
   **安全策:** バージョンタグを明示（例: `node:20.12-alpine`）

2. **ミス:** `.env` をイメージにコピーして漏洩  
   **安全策:** `.dockerignore` で除外、シークレットは外部管理

3. **ミス:** root実行のまま運用  
   **安全策:** `USER` 指定で非root化

4. **ミス:** 不要なポート公開  
   **安全策:** 必要最小限のみ公開。内部通信用はComposeネットワーク活用

5. **ミス:** 破壊的クリーンアップを無確認実行  
   **安全策:** 対象確認後に実行。特に以下は注意。
   - `docker system prune -a`
   - `docker image rm ...`
   - `docker rm -f ...`

> ⚠️ これらは停止中コンテナ・未使用イメージ・キャッシュ等を削除し、復元困難な場合があります。実行前に `docker ps -a` / `docker image ls` で確認してください。

---

## 8) 面接風クエスチョン（1問）

**Q.** 「`docker compose up --build` と `docker compose up` の違いは？どんな場面で使い分けますか？」

**A.（要点）**
- `--build` は Dockerfile や依存変更を反映したい時に使う
- 変更がない通常起動は `up` のみで高速化
- CIやリリース前確認では `--build` を明示すると安全

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
- Compose file reference  
  https://docs.docker.com/reference/compose-file/
- Docker Build cache  
  https://docs.docker.com/build/cache/
- Secrets (Compose/Swarm関連の考え方)  
  https://docs.docker.com/engine/swarm/secrets/

---

### 明日の予告
**「Beginner→Middle→Advanced 学習アーク継続」**  
次回は「ネットワークと永続化（bridge/network/volume）」を実践中心で扱います。
