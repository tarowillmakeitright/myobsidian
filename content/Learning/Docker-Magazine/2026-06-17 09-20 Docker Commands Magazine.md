---
tags:
  - docker
  - containers
  - devops
  - learning
  - daily
---

[[Home]]

# 2026-06-17 09-20 Docker Commands Magazine

## 今日のテーマ
**Docker イメージ作成と実行の基本アーク**
- **Beginner:** `docker build` と `docker images`
- **Middle:** `docker run` + ポート公開 + 環境変数 + ボリューム
- **Advanced:** マルチステージビルド + BuildKit + `.dockerignore` + セキュアなビルド運用

---

# 1) Topic + Level

## Beginner
**テーマ:** `docker build` と `docker images` で「アプリを動かす箱」を作る

## Middle
**テーマ:** 作ったイメージを `docker run` で現実的に使う

**前提条件:**
- `docker build` の流れがわかる
- Dockerfile を1回以上書いたことがある
- `docker ps` / `docker logs` を軽く触ったことがある

## Advanced
**テーマ:** 本番を意識した軽量・安全・再現性の高いイメージ設計

**前提条件:**
- `docker run` でWebアプリを起動した経験がある
- ボリュームとポート公開の基本を理解している
- Dockerfile の各命令 (`FROM`, `COPY`, `RUN`, `CMD`) を読める

---

# 2) Why it matters for real app development

Docker は「自分のPCでは動くのに、CIや本番では動かない」を減らすための土台です。実アプリ開発では特に以下が重要です。

- **開発環境の再現性**: 新メンバーでも同じ環境をすぐ立てられる
- **CI/CD との相性**: テスト・ビルド・デプロイの実行環境を揃えやすい
- **依存関係の隔離**: Node, Python, Go, Java など複数プロジェクトが衝突しにくい
- **本番運用の一貫性**: ローカル→ステージング→本番の差分を減らせる
- **セキュリティと保守性**: 軽量イメージ、不要ファイル除外、秘密情報を埋め込まない設計がしやすい

Docker をただの「便利な実行コマンド」として使うより、**ビルド品質・デバッグしやすさ・安全性**まで含めて使えると、現場でかなり強いです。

---

# 3) Core Docker command explanations

## Beginner: `docker build`
Dockerfile をもとにイメージを作るコマンドです。

```bash
docker build -t hello-docker:1.0 .
```

- `-t hello-docker:1.0`
  - イメージに名前とタグを付ける
- `.`
  - ビルドコンテキスト。今いるディレクトリ配下のファイルが Docker デーモンに渡る

ポイント:
- コンテキストが大きいとビルドが遅くなる
- 不要ファイルを送らないために `.dockerignore` が重要

## Beginner: `docker images`
ローカルにあるイメージ一覧を確認します。

```bash
docker images
```

確認したい観点:
- どのタグがあるか
- サイズが不自然に大きくないか
- 古い/使っていないイメージが溜まりすぎていないか

## Middle: `docker run`
イメージからコンテナを起動します。

```bash
docker run --name myapp -p 8080:3000 hello-docker:1.0
```

- `--name myapp`: コンテナ名
- `-p 8080:3000`: ホスト 8080 → コンテナ 3000

よく使う実践オプション:

```bash
docker run --name myapp \
  -p 8080:3000 \
  --env-file .env.local \
  -v $(pwd):/app \
  hello-docker:1.0
```

- `--env-file`: 環境変数をファイルから読み込む
- `-v`: ボリュームマウント。開発時のホットリロードや設定注入に便利

## Advanced: BuildKit + マルチステージビルド
BuildKit は高速化・キャッシュ改善・高度なビルド機能に役立ちます。

```bash
DOCKER_BUILDKIT=1 docker build -t myapp:prod .
```

マルチステージビルドでは、ビルド用ツールを最終イメージに残さず軽量化できます。

```Dockerfile
FROM node:22-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html
```

利点:
- 最終イメージが小さい
- 攻撃対象領域が減る
- ビルド依存を本番に持ち込まない

---

# 4) How Docker is used while building apps

docs.docker.com のベストプラクティスに沿うと、Docker は「とりあえず動かす」道具ではなく、開発パイプラインの品質装置になります。

## よくある実務フロー

1. **アプリコードを書く**
2. **Dockerfile で実行環境を定義**
3. **`.dockerignore` で不要物を除外**
4. **`docker build` で再現可能なイメージを作る**
5. **`docker run` / Compose でローカル検証**
6. **CI で同じ手順を再実行**
7. **レジストリへ push してデプロイ**

## 実務で意識したいベストプラクティス

- **1コンテナ1責務を基本に考える**
  - Web、worker、DB を無理に1つへ詰め込まない
- **軽量なベースイメージを検討する**
  - ただし小ささだけで決めず、保守性や互換性も見る
- **レイヤーキャッシュを活かす順序で Dockerfile を書く**
  - 依存ファイルを先に `COPY` → `npm ci` → ソースを `COPY`
- **不要ファイルをコンテキストへ入れない**
  - `node_modules`, `.git`, ログ, `.env` など
- **秘密情報をイメージに焼き込まない**
  - `ENV PASSWORD=...` や `COPY .env` は避ける
- **タグ戦略を雑にしない**
  - `latest` だけに頼らず、バージョンやコミットSHAも使う
- **コンテナを使い捨て前提で設計する**
  - 状態はボリュームや外部DBへ
- **本番イメージでは開発ツールを減らす**
  - curl, vim, compilers などを安易に残さない

## 秘密情報の安全な扱い

避けるべき例:

```Dockerfile
ENV API_KEY=super-secret-value
COPY .env /app/.env
```

理由:
- イメージ履歴や配布物に秘密が残る
- 誤 push / 誤共有時の被害が大きい

代わりに:
- 実行時に環境変数注入
- シークレット管理機構を利用
- 開発でも `.env` を直接 image に入れない

---

# 5) 30-60 minute hands-on mini lab

## ラボ名
**静的Webアプリを安全にコンテナ化して配信する**

**所要時間:** 40〜50分

## 目標
- `docker build` でイメージ作成
- `docker run` で公開
- `.dockerignore` の効果を理解
- マルチステージビルドで軽量配信

## 手順

### Step 1. 作業ディレクトリを作る

```bash
mkdir docker-magazine-lab
cd docker-magazine-lab
```

### Step 2. シンプルなHTMLを作る

```bash
mkdir -p src
cat > src/index.html <<'EOF'
<!doctype html>
<html lang="ja">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Docker Magazine Lab</title>
</head>
<body>
  <h1>Docker Magazine Lab</h1>
  <p>このページは Docker コンテナから配信されています。</p>
</body>
</html>
EOF
```

### Step 3. `.dockerignore` を作る

```bash
cat > .dockerignore <<'EOF'
.git
node_modules
.env
*.log
EOF
```

### Step 4. マルチステージ Dockerfile を作る

```bash
cat > Dockerfile <<'EOF'
FROM alpine:3.20 AS prepare
WORKDIR /work
COPY src ./src

FROM nginx:1.27-alpine
COPY --from=prepare /work/src /usr/share/nginx/html
EXPOSE 80
EOF
```

### Step 5. イメージをビルド

```bash
DOCKER_BUILDKIT=1 docker build -t docker-magazine-lab:2026-06-17 .
```

### Step 6. イメージ一覧を確認

```bash
docker images | grep docker-magazine-lab
```

### Step 7. コンテナを起動

```bash
docker run --name docker-magazine-web -d -p 8080:80 docker-magazine-lab:2026-06-17
```

### Step 8. 動作確認
ブラウザで以下を開く:

- <http://localhost:8080>

または CLI で確認:

```bash
curl http://localhost:8080
```

### Step 9. ログと状態確認

```bash
docker ps
docker logs docker-magazine-web
```

### Step 10. 改善課題（余力があれば）
- `LABEL` を Dockerfile に追加する
- `HEALTHCHECK` を追加してみる
- Nginx の設定ファイルを別途コピーしてキャッシュ制御を試す
- タグを `:latest` ではなく日付やバージョンにする

## 片付け
以下は削除を伴います。**必要なコンテナやイメージがないことを確認してから**実行してください。

```bash
docker stop docker-magazine-web
docker rm docker-magazine-web
```

イメージ削除は必要な場合のみ:

```bash
docker rmi docker-magazine-lab:2026-06-17
```

`docker rm -f`, `docker rmi -f`, `docker system prune` などの**強制・一括削除系は影響範囲を確認してから**使ってください。

---

# 6) Command cheatsheet

## 基本

```bash
docker build -t myapp:1.0 .
docker images
docker run --name myapp -p 8080:3000 myapp:1.0
docker ps
docker logs myapp
docker stop myapp
docker rm myapp
```

## 実務寄り

```bash
DOCKER_BUILDKIT=1 docker build -t myapp:prod .
docker run -d --name myapp -p 8080:3000 --env-file .env.local myapp:prod
docker exec -it myapp sh
docker inspect myapp
```

## 注意付き削除コマンド

```bash
docker rmi myapp:1.0
docker image prune
```

**警告:** 以下は破壊的になりやすいです。

```bash
docker rm -f <container>
docker rmi -f <image>
docker system prune
docker system prune -a
```

使う前に:
- 何が消えるか確認する
- 開発中コンテナやキャッシュが消えて困らないか確認する
- 共有環境では特に慎重に扱う

---

# 7) Common mistakes and safe practices

## よくあるミス

### 1. `.dockerignore` を置かない
結果:
- ビルドが遅い
- `.git` や `.env` がコンテキストに入る
- 不要に巨大なイメージになりやすい

### 2. 秘密情報を Dockerfile に書く
結果:
- イメージや履歴に秘密が残る
- レジストリ共有時に事故りやすい

安全策:
- 実行時注入
- Secret 管理を使う
- `.env` を `COPY` しない

### 3. `latest` タグだけで運用する
結果:
- 何が動いているか追いづらい
- ロールバックしにくい

安全策:
- バージョンタグ
- 日付タグ
- コミットSHAタグ

### 4. 何でも root 前提で動かす
結果:
- 権限過多
- 侵害時の影響が大きい

安全策:
- 可能なら非 root ユーザー利用を検討
- 最小権限を意識する

### 5. 開発用ツールを本番イメージへ残す
結果:
- サイズ増大
- 攻撃対象増加

安全策:
- マルチステージビルド
- 本番用の最終ステージを小さく保つ

### 6. 強制削除や prune を雑に実行する
結果:
- 必要なコンテナやキャッシュ消失
- 検証環境が壊れる

安全策:
- まず一覧確認: `docker ps -a`, `docker images`
- 削除対象を明示する
- `-f` は最後の手段

---

# 8) One interview-style question

**質問:**
なぜ本番向け Docker イメージではマルチステージビルドと `.dockerignore` が重要なのですか？サイズ削減以外の観点も含めて説明してください。

**考えるポイント:**
- セキュリティ
- ビルド速度
- キャッシュ効率
- 再現性
- 不要ファイル混入防止

---

# 9) Next-step resources

まずは公式ドキュメント優先で読むのが堅いです。

- Docker Build overview  
  <https://docs.docker.com/build/>
- Dockerfile reference  
  <https://docs.docker.com/reference/dockerfile/>
- Best practices for writing Dockerfiles  
  <https://docs.docker.com/develop/develop-images/dockerfile_best-practices/>
- Multi-stage builds  
  <https://docs.docker.com/build/building/multi-stage/>
- `.dockerignore` file  
  <https://docs.docker.com/build/concepts/context/#dockerignore-files>
- Image tagging best practices (conceptual reference via image management docs)  
  <https://docs.docker.com/reference/cli/docker/image/tag/>
- Volumes  
  <https://docs.docker.com/engine/storage/volumes/>
- Environment variables and secrets guidance  
  <https://docs.docker.com/compose/how-tos/environment-variables/set-environment-variables/>
  
補足:
- Compose を使う場合でも、**秘密を image や compose ファイルへ直書きしない**意識は同じです
- 次回は `docker compose up`, `docker compose logs`, `docker compose down` を題材にすると、複数サービス開発へ自然につながります

---

## ひとことまとめ
今日は `docker build` を軸に、**作る → 動かす → 軽く安全にする**流れを整理しました。実務で効くのは、コマンド暗記よりも「何をイメージに含めないか」「どう安全に再現するか」を理解することです。