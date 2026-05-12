# 2026-05-12 Docker Commands Magazine

Tags: #docker #containers #devops #learning #daily  
Links: [[Home]]

---

## 今号の学習アーク（Beginner → Middle → Advanced）

---

## 1) Topic + Level

### **Beginner｜`docker run` / `docker ps` / `docker logs` で「動かして観察する」**

### **Middle｜`docker exec` / `docker compose up` で「開発中コンテナを扱う」**
**前提知識（Prerequisites）**
- Beginnerレベルのコマンドを使って、コンテナ起動とログ確認ができる
- イメージとコンテナの違いを説明できる

### **Advanced｜`docker buildx build`（マルチステージ）+ セキュアなビルド運用**
**前提知識（Prerequisites）**
- Middleレベルの compose 実行と exec デバッグができる
- Dockerfileの基本命令（FROM, COPY, RUN, CMD）を理解している

---

## 2) Why it matters for real app development

- **ローカル環境差分を減らす**: 「自分のPCでは動く問題」を減らせる
- **オンボーディング高速化**: 新メンバーが `docker compose up` で即開発開始
- **デバッグ効率向上**: `logs` / `exec` で挙動確認が速い
- **本番に近い運用**: イメージ化・タグ運用・最小化でCI/CDに直結
- **セキュリティ向上**: 不要なツールや秘密情報を含めないビルド習慣が作れる

---

## 3) Core Docker command explanations

### Beginner
- `docker run --name web -p 8080:80 nginx:alpine`
  - イメージからコンテナを作成し起動
  - `-p ホスト:コンテナ` でポート公開
- `docker ps` / `docker ps -a`
  - 稼働中 / 全コンテナ一覧
- `docker logs -f web`
  - ログを追尾表示（障害調査の基本）

### Middle
- `docker exec -it web sh`
  - 実行中コンテナに入って調査
- `docker compose up -d`
  - 複数サービスを定義ファイルから起動
- `docker compose logs -f`
  - サービス単位のログ観察

### Advanced
- `docker buildx build -t myapp:dev .`
  - BuildKit/Buildxで高機能ビルド
- `docker image inspect myapp:dev`
  - イメージメタデータ確認（サイズ・履歴確認に有用）
- `docker scout quickview myapp:dev`（利用可能環境なら）
  - 脆弱性やベースイメージ状況のクイック確認

---

## 4) How Docker is used while building apps（docs.docker.com準拠の実践）

- **開発**: `compose` で app/db/cache をまとめて起動
- **ビルド**: マルチステージビルドで最終イメージを小さく保つ
- **依存固定**: ベースイメージタグを明示（必要に応じてdigest pinning）
- **秘密情報管理**:
  - `.env` やシークレット管理機構を使う
  - **NG**: パスワード/APIキーを Dockerfile に直書き、`COPY` で混入
- **最小権限**:
  - 可能な限り non-root ユーザーで実行
  - 不要ポートを開けない

---

## 5) 30-60 minute hands-on mini lab

### 目標
Nginx + App(ダミー) の2サービスを compose で起動し、ログ確認・exec調査・安全な後片付けまで行う

### 手順（約45分）
1. 作業フォルダ作成
   - `mkdir docker-mag-lab && cd docker-mag-lab`
2. `compose.yml` を作成
   - `web: nginx:alpine`（`8080:80`）
   - `app: alpine`（`command: ["sh", "-c", "while true; do echo app-running; sleep 5; done"]`）
3. 起動
   - `docker compose up -d`
4. 状態確認
   - `docker compose ps`
   - `docker compose logs -f --tail=20`
5. コンテナ内確認
   - `docker compose exec web sh`
   - `nginx -v` など確認して exit
6. 停止
   - `docker compose down`
7. 振り返り
   - どのコマンドが「調査」に効いたかメモ

---

## 6) Command cheatsheet

```bash
# 起動・一覧・停止
docker run --name web -p 8080:80 -d nginx:alpine
docker ps
docker stop web

# ログ・内部調査
docker logs -f web
docker exec -it web sh

# Compose
docker compose up -d
docker compose ps
docker compose logs -f
docker compose down

# ビルド
docker buildx build -t myapp:dev .
docker image ls
docker image inspect myapp:dev
```

---

## 7) Common mistakes and safe practices

### よくあるミス
- `latest` タグ前提で再現不能になる
- コンテナ内変更を「永続化される」と勘違い
- ログを見ずに再起動を繰り返す
- Dockerfileに秘密情報を埋め込む

### 安全運用
- まず `logs` と `inspect` で事実確認
- 本番系はタグ戦略を固定（例: semver + digest）
- `.dockerignore` を適切に設定して不要ファイル混入防止
- **破壊的コマンドに注意**:
  - `docker system prune`
  - `docker image rm`
  - `docker rm -f`
  - 実行前に必ず対象を確認し、必要データ消失リスクを理解すること

---

## 8) Interview-style question

**質問:**  
`docker run` と `docker compose up` の使い分けを、チーム開発（複数サービス）と再現性の観点で説明してください。加えて、デバッグ時に最初に確認するコマンドを2つ挙げ、その理由を述べてください。

---

## 9) Next-step resources（公式優先）

- Docker Get Started  
  https://docs.docker.com/get-started/
- Dockerfile best practices  
  https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Compose documentation  
  https://docs.docker.com/compose/
- Multi-stage builds  
  https://docs.docker.com/build/building/multi-stage/
- BuildKit / Buildx  
  https://docs.docker.com/build/
- Docker Engine security  
  https://docs.docker.com/engine/security/

---

### 明日の予告
次号は「Beginner: volume基礎 → Middle: bind mount設計 → Advanced: 開発/本番でのマウント戦略と権限設計」を扱います。