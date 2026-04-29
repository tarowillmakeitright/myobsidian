# Docker Commands Magazine — 2026-04-29

Tags: #docker #containers #devops #learning #daily
Link: [[Home]]

---

## Issueテーマ
**「コンテナのライフサイクルを安全に回す」**

- **Beginner:** `docker run / ps / logs / stop / rm`
- **Middle:** `docker exec / inspect / cp / stats`（前提あり）
- **Advanced:** `docker compose up/down + build最適化 + クリーンアップ戦略`（前提あり）

---

## 1) Topic + Level

### Beginner（初級）
**Topic:** 単一コンテナの起動〜停止〜削除を正しく扱う

### Middle（中級）
**Topic:** 実行中コンテナの調査・デバッグ・リソース観測

**Prerequisites:**
- `docker run`, `docker ps`, `docker logs`, `docker stop`, `docker rm` を使える
- Linux基本コマンド（`sh`, `cat`, `ls`）

### Advanced（上級）
**Topic:** Composeで開発環境を再現し、イメージ/不要物を安全に管理する

**Prerequisites:**
- Middleの内容（`exec`, `inspect`）
- Dockerfile基礎（`FROM`, `COPY`, `RUN`, `CMD`）
- Compose YAMLの基本構文

---

## 2) なぜ実アプリ開発で重要か

- **ローカル再現性**: 新メンバーが同じ環境を数分で起動できる
- **デバッグ効率**: ログ・プロセス・環境変数を即確認できる
- **本番事故の予防**: 「動くけど危ない」設定（秘密情報の埋め込み、強制削除乱用）を避けられる
- **CI/CD整合**: ローカルで回る手順をそのままパイプラインへ載せやすい

---

## 3) Core Docker command explanations

### Beginnerコア
- `docker run --name app -p 8080:80 nginx:alpine`
  - イメージから新規コンテナ作成+起動
  - `--name`: 管理しやすい識別名
  - `-p host:container`: ポート公開
- `docker ps` / `docker ps -a`
  - 実行中 / 全コンテナ確認
- `docker logs -f app`
  - ログ追跡（`-f`でtail）
- `docker stop app`
  - SIGTERMで安全停止
- `docker rm app`
  - 停止済みコンテナ削除

### Middleコア
- `docker exec -it app sh`
  - 実行中コンテナ内で対話シェル
- `docker inspect app`
  - 設定/ネットワーク/マウントをJSONで可視化
- `docker cp app:/etc/nginx/nginx.conf ./nginx.conf`
  - コンテナ↔ホストのファイルコピー
- `docker stats`
  - CPU/メモリ/IOのリアルタイム監視

### Advancedコア
- `docker compose up -d --build`
  - 複数サービス起動、必要ならビルド
- `docker compose logs -f`
  - サービス横断ログ追跡
- `docker compose down`
  - サービス停止・ネットワーク整理
- `docker image ls` / `docker system df`
  - イメージ容量と使用量確認

---

## 4) アプリ開発での使い方（docs.docker.comベストプラクティス準拠）

- **小さく安全なベースイメージ**を選ぶ（例: `alpine`系、必要十分なランタイム）
- **マルチステージビルド**でビルド依存を最終イメージに残さない
- **`.dockerignore`を整備**し、不要ファイルや秘密情報をビルド文脈へ入れない
- **1コンテナ1責務**を基本に、連携はComposeで管理
- **秘密情報をイメージやcompose直書きしない**
  - NG: `ENV API_KEY=...` をDockerfileに固定
  - 推奨: 実行時注入（envファイル管理ポリシー、シークレット管理機構）
- **タグ戦略**: `latest`固定を避け、バージョン/コミットSHAで追跡可能に

---

## 5) 30-60分ハンズオン・ミニラボ

### ゴール
Nginxコンテナを起動し、設定確認・ログ追跡・Compose化まで実施する。

### 手順（約45分）
1. **起動（10分）**
   ```bash
   docker run -d --name web1 -p 8080:80 nginx:alpine
   docker ps
   ```
2. **観察（10分）**
   ```bash
   docker logs -f web1
   docker inspect web1 --format '{{.Config.Image}} {{.State.Status}}'
   ```
3. **内部確認（10分）**
   ```bash
   docker exec -it web1 sh
   # コンテナ内で
   nginx -v
   exit
   ```
4. **Compose化（10-15分）**
   `compose.yaml` を作成:
   ```yaml
   services:
     web:
       image: nginx:alpine
       ports:
         - "8081:80"
   ```
   実行:
   ```bash
   docker compose up -d
   docker compose logs -f
   docker compose down
   ```
5. **片付け（安全版）（5分）**
   ```bash
   docker stop web1
   docker rm web1
   ```

---

## 6) Command Cheatsheet

```bash
# 起動/確認
docker run -d --name myapp -p 3000:3000 myimage:1.0
docker ps
docker ps -a

# ログ/中に入る
docker logs -f myapp
docker exec -it myapp sh

# 停止/削除
docker stop myapp
docker rm myapp

# Compose
docker compose up -d --build
docker compose logs -f
docker compose down

# 使用量確認
docker system df
docker image ls
```

---

## 7) よくあるミス & Safe Practices

- **ミス:** `docker rm -f` を常用して graceful shutdown を飛ばす  
  **対策:** まず `docker stop` → `docker rm`

- **ミス:** `docker system prune -a` を意味を理解せず実行  
  **警告:** 未使用イメージ/ネットワーク/キャッシュを広く削除。復旧に再pull/再buildが必要。  
  **対策:** 事前に `docker system df` で対象規模を確認し、チーム環境では合意後に実施。

- **ミス:** Dockerfile/composeへ秘密情報を直書き  
  **対策:** 秘密は実行時注入、管理対象外ファイルやシークレット機構を利用。

- **ミス:** `latest` 前提で挙動が日替わり  
  **対策:** 明示タグ固定、更新時のみ計画的に上げる。

---

## 8) 面接風質問（1問）

**Q.** `docker run` と `docker compose up` の使い分けを、ローカル開発チームの再現性という観点で説明してください。  
（補足: 単体検証と複数サービス連携の違い、設定のコード化、オンボーディング速度まで触れられると強い）

---

## 9) Next-step resources（公式優先）

- Docker Docs Home: https://docs.docker.com/
- Get Started: https://docs.docker.com/get-started/
- Dockerfile Best Practices: https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Multi-stage Builds: https://docs.docker.com/build/building/multi-stage/
- Compose Overview: https://docs.docker.com/compose/
- Compose File Reference: https://docs.docker.com/reference/compose-file/
- Docker Engine `docker system prune` reference: https://docs.docker.com/reference/cli/docker/system/prune/

---

次号予告（学習アーク継続）:  
**Beginner:** ボリューム基礎  
**Middle:** 開発用バインドマウントとホットリロード  
**Advanced:** BuildKitキャッシュ最適化とCI高速化
