---
tags:
  - docker
  - containers
  - devops
  - learning
  - daily
---

[[Home]]

# 2026-07-14 09-20 Docker Commands Magazine

## 今日のテーマ
**BuildKit・multi-stage build・キャッシュ最適化で作る実務向け Docker build パイプライン**

**Level: Advanced**

### 前提知識（Advanced レベル）
- `docker build` と Dockerfile の基本がわかる
- `docker run`, `docker ps`, `docker logs` を使って動作確認できる
- `.dockerignore` の役割を理解している
- イメージとコンテナの違いを説明できる

---

## 1) Topic + Level
### Topic
`docker buildx build`、multi-stage build、BuildKit のキャッシュ機能を使って、**小さく・速く・安全で・CI/CD に載せやすい Docker イメージ作成フロー**を学ぶ。

### Level
**Advanced**

> 学習アーク: Beginner → Middle → Advanced
>
> - Beginner: コンテナ観察・基本操作
> - Middle: `docker build` と Dockerfile 設計
> - **Advanced: BuildKit / multi-stage build / cache 最適化 / セキュア build ← 今日**
> - 次の Beginner 周回候補: `docker exec` / `docker cp` / `docker logs` を使ったデバッグ基礎

---

## 2) Why it matters for real app development
実務の Docker は「とりあえず build できる」だけでは足りません。開発チームや CI/CD では、次の 4 点が非常に重要です。

- **build 時間を短くすること**
  - CI が遅いとレビューやデプロイ全体が遅くなる
- **本番イメージを小さく保つこと**
  - pull が速くなり、脆弱性スキャン対象も減らしやすい
- **不要な build ツールを本番に持ち込まないこと**
  - コンパイラや dev 依存を runtime に残さない
- **secret を安全に扱うこと**
  - API キーや private registry 認証情報をイメージに焼き込まない

Docker 公式ドキュメントでも、multi-stage build、最小構成の runtime image、適切な cache 利用、secret の安全な注入がベストプラクティスとして強く推奨されています。

---

## 3) Core Docker command explanations

## `docker buildx build`
BuildKit ベースで build を行うコマンド。高速化・高度なキャッシュ・マルチプラットフォーム build などに対応します。

```bash
docker buildx build -t my-app:dev .
```

### 実務でよく使う形
```bash
docker buildx build --load -t my-app:dev .
```

- `--load`
  - build 結果をローカルの Docker image として読み込む
  - ローカル確認用に便利
- `-t`
  - イメージ名とタグを付ける

### いつ使うか
- CI/CD の build 高速化
- BuildKit 機能を使いたいとき
- multi-platform build を将来的に見据えるとき

---

## `docker buildx build --no-cache`
キャッシュを無効化して build する。

```bash
docker buildx build --no-cache -t my-app:fresh .
```

用途:
- キャッシュ依存の不具合切り分け
- 本当に再現可能か確認

注意:
- 通常運用で毎回使うと遅い
- 「遅い build を力技で受け入れる」方向に行きやすいので常用しない

---

## `docker buildx build --progress=plain`
build ログを詳細表示する。

```bash
docker buildx build --progress=plain -t my-app:dev .
```

用途:
- CI ログで何がキャッシュされたか確認
- どこで失敗したかを追いやすい

---

## `docker image ls`
ローカルイメージ一覧を確認する。

```bash
docker image ls
```

見るポイント:
- tag が意図通りか
- 同じ名前の肥大化した古い image が溜まっていないか

---

## `docker history`
イメージのレイヤ履歴を確認する。

```bash
docker history my-app:prod
```

用途:
- 不要に大きい layer を見つける
- build tool や秘密情報が runtime image 側に残っていないかを見直すヒントにする

---

## `docker run`
build したイメージを起動して runtime を確認する。

```bash
docker run --rm -p 3000:3000 my-app:prod
```

確認ポイント:
- 本番相当 image で本当に起動するか
- build stage にしかないファイルへ依存していないか

---

## 4) How Docker is used while building apps
実アプリ開発では、Docker は単なる梱包ツールではなく、**開発・テスト・CI・本番デプロイをつなぐ再現性の基盤**として使います。

### 4-1. multi-stage build で build 用と runtime 用を分離する
たとえば Node.js/Go/Java などでは、依存解決やコンパイルに必要なものと、本番実行に必要なものは違います。

考え方:
- build stage: 依存インストール、ビルド、テスト
- runtime stage: 実行に必要な成果物だけコピー

これで:
- イメージが小さくなる
- attack surface を減らせる
- dev dependency 混入を防ぎやすい

### 4-2. cache を設計する
Docker build の速さは「運」ではなく「設計」です。

良い例:
- 依存ファイルを先に `COPY`
- 変更の少ない処理を上段へ
- アプリ本体は後段へ

これにより:
- アプリコード変更だけなら依存インストールを再利用できる
- CI 実行時間を削減しやすい

### 4-3. runtime image を最小化する
Docker docs の考え方に沿うと、runtime image にはできるだけ以下を残さない方がよいです。

- compiler
- package manager の一時ファイル
- テスト用ツール
- 不要な shell utilities
- credentials や secret ファイル

### 4-4. secret は build 引数や Dockerfile 直書きで雑に渡さない
危険な例:

```Dockerfile
ARG API_TOKEN
ENV API_TOKEN=$API_TOKEN
```

これらは履歴や設定に残る恐れがあります。

安全な考え方:
- secret は build 時に安全な仕組みで渡す
- runtime secret は実行時注入にする
- `.env` や認証ファイルを `COPY` しない
- Compose や CI の secret 管理機能を使う

### 4-5. non-root 実行を検討する
本番コンテナでは、可能なら root 前提を避けた方が安全です。

- 侵害時の影響範囲を減らす
- 最小権限の考え方に合う

### 4-6. タグを「追跡可能な単位」にする
- `latest` だけに依存しない
- `app:1.4.2`
- `app:2026-07-14`
- `app:git-<sha>`

これにより、障害時の切り戻しや原因追跡がしやすくなります。

---

## 5) 30-60 minute hands-on mini lab
### ミニラボ: multi-stage build と BuildKit cache を体験する

所要時間: **45〜60分**

### ゴール
- multi-stage build の意味を体感する
- runtime image を小さく保つ考え方を理解する
- cache の効き方を build ログで確認する
- secret を image に入れない理由を理解する

### 想定アプリ
Node.js のシンプルな Web アプリ

### 1. 作業フォルダを作る
```bash
mkdir docker-advanced-lab
cd docker-advanced-lab
```

### 2. `package.json` を作る
```json
{
  "name": "docker-advanced-lab",
  "version": "1.0.0",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.21.0"
  }
}
```

### 3. `server.js` を作る
```js
const express = require('express');
const app = express();
const port = 3000;

app.get('/', (req, res) => {
  res.send('Hello from advanced Docker lab!');
});

app.listen(port, () => {
  console.log(`Listening on ${port}`);
});
```

### 4. `.dockerignore` を作る
```gitignore
node_modules
.git
.gitignore
.env
npm-debug.log
Dockerfile.bad
*.md
```

### 5. multi-stage な Dockerfile を作る
`Dockerfile`

```Dockerfile
# syntax=docker/dockerfile:1

FROM node:22-bookworm-slim AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev

FROM node:22-bookworm-slim AS runtime
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY server.js ./
EXPOSE 3000
USER node
CMD ["node", "server.js"]
```

### 6. BuildKit で build する
```bash
docker buildx build --load --progress=plain -t docker-advanced-lab:prod .
```

見るポイント:
- `npm ci` の layer がどこで走るか
- build ログで cache 状態がどう見えるか

### 7. 起動して確認する
```bash
docker run --rm -p 3000:3000 docker-advanced-lab:prod
```

ブラウザまたは `curl`:
```bash
curl http://localhost:3000
```

### 8. layer を確認する
```bash
docker history docker-advanced-lab:prod
```

観察ポイント:
- runtime image 側に build 用の処理が少ないか
- 不要なファイルが残っていなさそうか

### 9. cache 効果を確認する
`server.js` の返答文字列だけ変更して再 build:

```bash
docker buildx build --load --progress=plain -t docker-advanced-lab:prod .
```

期待する挙動:
- `npm ci` は cache されやすい
- アプリ本体側だけが再評価される

### 10. 悪い例と比較する
`Dockerfile.bad`

```Dockerfile
FROM node:22-bookworm-slim
WORKDIR /app
COPY . .
RUN npm ci --omit=dev
EXPOSE 3000
CMD ["node", "server.js"]
```

これで build:
```bash
docker buildx build --load --progress=plain -f Dockerfile.bad -t docker-advanced-lab:bad .
```

比較ポイント:
- ちょっとしたコード変更で `npm ci` が再実行されやすい
- context が雑だと安全性も速度も落ちる

### 11. secret の安全確認メモ
このラボでは **secret を Dockerfile に書かない**。もし private package 取得などが必要でも、トークンを `ENV` や `COPY .env` で焼き込まないこと。

---

## 6) Command cheatsheet

```bash
# BuildKit で build
docker buildx build --load -t my-app:dev .

# 詳細ログつき build
docker buildx build --load --progress=plain -t my-app:dev .

# キャッシュ無効で build
docker buildx build --no-cache --load -t my-app:fresh .

# イメージ一覧
docker image ls

# イメージの履歴確認
docker history my-app:prod

# コンテナ起動
docker run --rm -p 3000:3000 my-app:prod

# コンテナ一覧
docker ps

docker ps -a
```

### 慎重に扱うコマンド
以下は便利ですが、**削除対象を確認してから**実行すること。

```bash
# 未使用リソースの一括削除
# 注意: 想定外に学習中/検証中のデータを消すことがある
docker system prune

# image の掃除
# 注意: 他のプロジェクトで再利用中の image を消す可能性あり
docker image prune

# 特定 image 削除
docker rmi IMAGE_ID

# 強制削除は特に要注意
docker rmi -f IMAGE_ID

# コンテナ削除
docker rm CONTAINER_ID
docker rm -f CONTAINER_ID
```

> `prune` / `rmi` / `rm -f` は破壊的です。共有開発環境や作業継続中のマシンでは、対象確認なしで流さないこと。

---

## 7) Common mistakes and safe practices

### よくあるミス 1: build 用の依存を本番 image に残す
問題:
- image が大きくなる
- 脆弱性対象が増える
- 不要ツールが runtime に残る

安全策:
- multi-stage build を使う
- runtime には必要な成果物だけコピーする

### よくあるミス 2: cache を壊す Dockerfile 順序にする
問題:
- 毎回 `npm ci` や package install が走って遅い
- CI コストが増える

安全策:
- 依存定義ファイルを先に `COPY`
- 変更頻度の低い処理を先に置く

### よくあるミス 3: secret を image に焼き込む
問題:
- image 配布時に漏えいしやすい
- inspect/history/設定から露出する危険がある

安全策:
- `ENV` や `ARG` を雑に secret 用途で使わない
- `.env` を `COPY` しない
- secret は専用の安全な仕組みで注入する

### よくあるミス 4: runtime で root のまま動かす
問題:
- 侵害時の影響が大きい

安全策:
- 可能なら non-root user を使う
- 必要権限だけに絞る

### よくあるミス 5: `latest` しか使わない
問題:
- どの image で動いているか追跡しづらい
- ロールバックしづらい

安全策:
- バージョン、日付、git sha など追跡可能なタグを使う

### よくあるミス 6: cleanup コマンドを雑に打つ
問題:
- 学習中の image や別プロジェクトの container まで消しやすい

安全策:
- `docker ps -a` や `docker image ls` で先に確認
- `prune` / `rmi -f` / `rm -f` は警戒して使う

---

## 8) One interview-style question
**質問:**
なぜ実務の Dockerfile では multi-stage build を使うことが多いのでしょうか。`FROM ... AS build` と runtime stage を分ける利点を、**セキュリティ・性能・保守性**の観点から説明してください。

**考えるポイント:**
- image サイズ
- attack surface
- CI/CD の再現性
- build tool と runtime の分離

---

## 9) Next-step resources
- Docker docs: Build overview  
  <https://docs.docker.com/build/>

- Docker docs: Multi-stage builds  
  <https://docs.docker.com/build/building/multi-stage/>

- Docker docs: Best practices for writing Dockerfiles  
  <https://docs.docker.com/develop/develop-images/dockerfile_best-practices/>

- Docker docs: Build cache  
  <https://docs.docker.com/build/cache/>

- Docker docs: .dockerignore files  
  <https://docs.docker.com/build/concepts/context/#dockerignore-files>

- Docker docs: Dockerfile reference  
  <https://docs.docker.com/reference/dockerfile/>

- Docker docs: Build secrets  
  <https://docs.docker.com/build/building/secrets/>

---

## まとめ
今日の要点は 4 つです。

1. Advanced な Docker 実務では、**BuildKit と multi-stage build が基礎体力**になる
2. 良い Dockerfile は、**速い・小さい・安全**を同時に目指す
3. cache は偶然ではなく、**Dockerfile の順序設計**で作る
4. secret を image に焼き込まないことが、セキュリティの最低ライン

次回は学習アークを Beginner に戻して、`docker logs` / `docker exec` / `docker cp` など、**運用・デバッグ寄りの基本コマンド**に戻るとバランスが良いです。
