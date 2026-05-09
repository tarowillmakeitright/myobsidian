---
tags: [docker, containers, devops, learning, daily]
---

[[Home]]

# Docker Commands Magazine — 2026-05-09

## 今号のテーマ + レベル
**テーマ:** `docker run` / `docker exec` / `docker logs` で「動かす・入る・観察する」
**レベル:** **Beginner（学習アーク 1/3）**

> このシリーズは **Beginner → Middle → Advanced** を繰り返し、段階的に実務力を上げます。

---

## 1) なぜ実アプリ開発で重要か
実務では「まず動かす」だけでなく、**動作確認・原因調査・再現性** が重要です。
- `docker run` でローカルに実行環境を即用意
- `docker logs` でエラー原因を迅速に把握
- `docker exec` でコンテナ内を確認し、設定ミスや依存不足を特定

これらは、開発スピードと障害対応速度に直結します。

---

## 2) コア Docker コマンド解説

### `docker run`
イメージからコンテナを起動。
```bash
docker run --name web-nginx -d -p 8080:80 nginx:stable
```
- `--name`: コンテナ名を付与
- `-d`: バックグラウンド実行
- `-p 8080:80`: ホスト8080 → コンテナ80へポート公開

### `docker ps`
起動中コンテナ一覧。
```bash
docker ps
```

### `docker logs`
コンテナの標準出力・標準エラーを確認。
```bash
docker logs web-nginx
docker logs -f --tail 100 web-nginx
```
- `-f`: 追従表示
- `--tail 100`: 末尾100行

### `docker exec`
起動中コンテナ内でコマンド実行。
```bash
docker exec -it web-nginx sh
```
- `-it`: 対話モード

### `docker stop` / `docker rm`
停止・削除。
```bash
docker stop web-nginx
docker rm web-nginx
```

---

## 3) アプリ構築時の使い方（docs.docker.com ベストプラクティス準拠）
- **再現可能な環境**を作るため、まずは公式イメージ（例: `nginx:stable`, `node:lts`）を使う
- ローカル開発では、`run` + `logs` + `exec` で最小の検証ループを作る
- コンテナは**使い捨て前提（immutable）**で扱い、手作業変更に依存しない
- 設定値や機密情報はイメージに焼き込まず、環境変数や secrets 機構で管理
- 不要な root 実行や過剰な公開ポートを避ける

---

## 4) 30〜60分ハンズオン・ミニラボ
**目標:** Nginxコンテナを起動し、ログ観察と内部確認を行う

### 手順（約40分）
1. **起動**
   ```bash
   docker run --name web-nginx -d -p 8080:80 nginx:stable
   ```
2. **状態確認**
   ```bash
   docker ps
   ```
3. **ブラウザ確認**（`http://localhost:8080`）
4. **ログ確認**
   ```bash
   docker logs -f --tail 50 web-nginx
   ```
5. **別ターミナルからアクセス**
   ```bash
   curl -I http://localhost:8080
   ```
   → 先ほどのログにアクセス記録が出ることを確認
6. **コンテナ内確認**
   ```bash
   docker exec -it web-nginx sh
   ls /usr/share/nginx/html
   exit
   ```
7. **停止・削除**
   ```bash
   docker stop web-nginx
   docker rm web-nginx
   ```

### ゴール判定
- `run` で起動できた
- `logs` でアクセスログを追えた
- `exec` でコンテナ内ファイルを確認できた

---

## 5) コマンド・チートシート
```bash
# 起動（バックグラウンド + ポート公開）
docker run --name <name> -d -p <host_port>:<container_port> <image>:<tag>

# 一覧
docker ps
docker ps -a

# ログ
docker logs <name>
docker logs -f --tail 100 <name>

# コンテナ内コマンド
docker exec -it <name> sh

# 停止・削除
docker stop <name>
docker rm <name>
```

---

## 6) よくあるミス & 安全運用

### よくあるミス
- ポート競合（例: 8080が既に使用中）
- コンテナ名重複（同名コンテナが残っている）
- `-d` 付け忘れで端末を専有
- 「コンテナ内で手修正」して再現不能になる

### 安全運用
- 削除系コマンド実行前に対象を確認（`docker ps -a`, `docker images`）
- 機密情報（APIキー等）をDockerfileやCompose直書きしない
- 公開ポートは必要最小限
- 公式/信頼済みイメージを優先し、タグ固定を意識

### ⚠ 破壊的コマンドの注意
以下は強い削除を伴います。**実行前に影響範囲を必ず確認**してください。
- `docker system prune`
- `docker image prune -a`
- `docker rmi ...`
- `docker rm -f ...`

---

## 7) 面接っぽい一問
**Q. `docker run -p 8080:80 nginx` の `8080:80` は何を意味し、なぜ必要ですか？**

**A（要点）:** ホスト側8080番ポートへの通信をコンテナ側80番へ転送する指定。コンテナ内サービスをホスト（ブラウザやcurl）から利用するために必要。

---

## 8) 次のステップ（公式ドキュメント中心）
- Docker Get Started: https://docs.docker.com/get-started/
- Docker CLI reference (`docker run`): https://docs.docker.com/engine/reference/commandline/run/
- Docker CLI reference (`docker logs`): https://docs.docker.com/engine/reference/commandline/logs/
- Docker CLI reference (`docker exec`): https://docs.docker.com/engine/reference/commandline/exec/
- Image best practices: https://docs.docker.com/develop/develop-images/dockerfile_best-practices/

---

## 次号予告（Middle）
**予定テーマ:** DockerfileでNode.jsアプリをビルドし、レイヤーキャッシュと`.dockerignore`を使ってビルド最適化

**Middleの前提知識:**
- `docker run / ps / logs / exec / stop / rm` が使えること
- ポート公開（`-p`）の意味を説明できること

**Advancedの前提知識（先取り）:**
- Dockerfile（複数ステージ）
- ボリューム/ネットワーク基礎
- セキュリティ（non-root実行、secretsの外出し）
