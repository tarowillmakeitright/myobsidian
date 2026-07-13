---
tags:
  - docker
  - containers
  - devops
  - learning
  - daily
---

[[Home]]

# 2026-07-13 09-20 Docker Commands Magazine

## 今日のテーマ
**`docker build` と Dockerfile 設計の基本〜実務的なイメージ作成フロー**

**Level: Middle**

### 前提知識（Middle レベル）
- `docker ps` / `docker logs` / `docker exec` の基本を触ったことがある
- コンテナとイメージの違いをざっくり説明できる
- Linux の基本コマンド（`cd`, `ls`, `cat`）を少し使える

---

## 1) Topic + Level
### Topic
`docker build` を中心に、**再現性が高く・小さく・安全に動くイメージを作る**ための Dockerfile の考え方を学ぶ。

### Level
**Middle**

> 学習アーク: Beginner → Middle → Advanced
>
> - Beginner: コンテナ観察・基本操作
> - **Middle: Dockerfile と build の実務設計 ← 今日**
> - Advanced: BuildKit / multi-stage build / cache 最適化 / supply chain 対策

---

## 2) Why it matters for real app development
実アプリ開発では、単に「ローカルで動いた」だけでは足りません。チーム開発や CI/CD では、**誰が・どこで・いつ build しても同じ結果になること**が重要です。

Docker イメージ作成が重要な理由:

- **開発環境の差分を減らせる**
  - 「自分のPCでは動く」を減らす
- **CI/CD に乗せやすい**
  - テスト、ビルド、デプロイを同じ手順で実行できる
- **本番運用の安定性が上がる**
  - 必要な依存関係をイメージに閉じ込められる
- **セキュリティと保守性に直結する**
  - 不要なパッケージや秘密情報を含めない設計ができる

特に Docker 公式ドキュメントでも、**小さく、明確で、再利用しやすいイメージ**を作ることがベストプラクティスとして重視されています。

---

## 3) Core Docker command explanations

## `docker build`
Dockerfile をもとにイメージを作成するコマンド。

```bash
docker build -t my-node-app:dev .
```

### よく使う要素
- `-t`
  - イメージに名前とタグを付ける
  - 例: `my-node-app:dev`, `my-node-app:1.0`
- `.`
  - build context
  - 現在ディレクトリのファイル群を Docker デーモンへ渡す

### 重要ポイント
**build context に入ったファイルは、Dockerfile 内の `COPY` で参照可能**です。つまり、不要ファイルや秘密情報まで context に含めると事故の元です。

そのため `.dockerignore` がかなり重要です。

---

## `docker image ls`
ローカルにあるイメージ一覧を確認。

```bash
docker image ls
```

用途:
- build 結果を確認する
- サイズをざっくり確認する
- タグ付けミスを見つける

---

## `docker run`
build したイメージを実際に起動して確認する。

```bash
docker run --rm -p 3000:3000 my-node-app:dev
```

### よく使うオプション
- `--rm`
  - 停止後にコンテナを自動削除
  - 学習や一時実行に便利
- `-p 3000:3000`
  - ホストの 3000 番をコンテナの 3000 番へ転送

---

## `docker history`
イメージがどのレイヤで構成されているか確認する。

```bash
docker history my-node-app:dev
```

用途:
- 無駄に大きいレイヤがないか確認する
- `COPY . .` の影響が大きすぎないか見る
- イメージ最適化のヒントを得る

---

## `docker inspect`
イメージやコンテナの詳細情報を見る。

```bash
docker inspect my-node-app:dev
```

用途:
- 環境変数、設定、エントリポイント確認
- 想定通りの設定になっているか検証

---

## 4) How Docker is used while building apps
Docker を実アプリ開発に使うときは、単にコンテナ化するだけでなく、**開発・テスト・デプロイの流れ全体を整える**意識が大切です。

Docker 公式のベストプラクティスに沿うと、次の考え方が重要です。

### 4-1. 小さいイメージを作る
- 不要なツールを入れすぎない
- できるだけ軽量なベースイメージを選ぶ
- 不要ファイルを `.dockerignore` で除外する

例:
- `node:22-alpine` のような軽量系を検討する
- ただし Alpine は互換性の検証が必要なこともあるため、**軽さだけで選ばない**

### 4-2. レイヤキャッシュを活かす
依存関係のインストールは時間がかかるので、変更頻度の低いファイルを先に `COPY` する。

悪い例:
```Dockerfile
COPY . .
RUN npm install
```

より良い例:
```Dockerfile
COPY package*.json ./
RUN npm ci
COPY . .
```

こうすると、アプリコードだけ変わった場合に依存関係の再インストールを避けやすいです。

### 4-3. タグ運用を雑にしない
- `latest` だけに頼らない
- `app:dev`, `app:1.2.3`, `app:2026-07-13` のように意味のあるタグを使う

### 4-4. 秘密情報をイメージに埋め込まない
**超重要**です。

やってはいけない例:
- Dockerfile に API キーを直接書く
- `ENV SECRET_KEY=...` を build 時点で固定する
- `.env` や秘密ファイルをそのまま `COPY` する

安全な考え方:
- 秘密情報は**実行時に注入**する
- イメージはできるだけ汎用に保つ
- Compose や CI の secret 管理機能を使う

### 4-5. コンテナは 1 つの責務を意識する
Web アプリ、DB、バッチなどを 1 コンテナに全部詰め込むより、役割を分けた方が運用しやすいです。

---

## 5) 30-60 minute hands-on mini lab
### ミニラボ: Node.js の最小アプリを Docker 化して build 最適化を体験する

所要時間: **40〜50分**

### ゴール
- `docker build` の基本を理解する
- `.dockerignore` の効果を体感する
- `COPY` 順序でキャッシュ効率が変わることを確認する

### 事前準備
作業フォルダを作る:

```bash
mkdir docker-build-lab
cd docker-build-lab
```

### 1. アプリを作る
`package.json`

```json
{
  "name": "docker-build-lab",
  "version": "1.0.0",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.19.2"
  }
}
```

`server.js`

```js
const express = require('express');
const app = express();
const port = 3000;

app.get('/', (req, res) => {
  res.send('Hello from Docker build lab!');
});

app.listen(port, () => {
  console.log(`App listening on port ${port}`);
});
```

### 2. Dockerfile を作る
`Dockerfile`

```Dockerfile
FROM node:22-bookworm-slim

WORKDIR /app

COPY package*.json ./
RUN npm ci --omit=dev

COPY . .

EXPOSE 3000
CMD ["npm", "start"]
```

### 3. `.dockerignore` を作る

```gitignore
node_modules
npm-debug.log
.git
.gitignore
.env
*.md
```

### 4. build する

```bash
docker build -t docker-build-lab:dev .
```

### 5. 実行する

```bash
docker run --rm -p 3000:3000 docker-build-lab:dev
```

ブラウザで確認:
- `http://localhost:3000`

### 6. レイヤを確認する
別ターミナルで:

```bash
docker history docker-build-lab:dev
```

### 7. キャッシュ挙動を試す
`server.js` のメッセージだけ変えて再 build:

```bash
docker build -t docker-build-lab:dev .
```

見るポイント:
- `npm ci` レイヤが再利用されるか
- コード変更だけでフル再インストールになっていないか

### 8. 悪い例も試す
Dockerfile を一時的にこう変える:

```Dockerfile
FROM node:22-bookworm-slim
WORKDIR /app
COPY . .
RUN npm ci --omit=dev
EXPOSE 3000
CMD ["npm", "start"]
```

再 build して、キャッシュ効率の差を観察する。

### 学び
- `COPY` 順序で build 時間が変わる
- `.dockerignore` は安全性と速度の両方に効く
- Dockerfile は「動けばよい」ではなく「継続開発に耐える形」が大事

---

## 6) Command cheatsheet

```bash
# イメージを build
docker build -t my-app:dev .

# イメージ一覧
docker image ls

# build したイメージを起動
docker run --rm -p 3000:3000 my-app:dev

# イメージのレイヤ確認
docker history my-app:dev

# 詳細情報確認
docker inspect my-app:dev

# コンテナ一覧確認
docker ps

# 停止中も含めて確認
docker ps -a
```

### 慎重に扱うコマンド
以下は便利ですが、**削除系なので実行前に対象を必ず確認**してください。

```bash
# 未使用イメージ・停止済みコンテナ等の掃除
# 注意: 想定外のデータ削除につながることがある
docker system prune

# 未使用イメージ削除
# 注意: 他の作業中イメージを消す可能性あり
docker image prune

# 特定イメージ削除
# 注意: 依存コンテナがあると困る場合がある
docker rmi IMAGE_ID

# 強制削除は特に注意
docker rmi -f IMAGE_ID

docker rm CONTAINER_ID
docker rm -f CONTAINER_ID
```

> `prune` / `rmi` / `rm -f` は破壊的になり得ます。共有開発環境や学習用以外のマシンでは、対象確認なしに流さないこと。

---

## 7) Common mistakes and safe practices

### よくあるミス 1: `COPY . .` を雑に使う
問題:
- 不要ファイルまで image に入る
- キャッシュが壊れやすい
- 秘密ファイル混入リスクがある

安全策:
- `.dockerignore` を必ず書く
- 依存ファイル → インストール → アプリ本体、の順に分ける

### よくあるミス 2: `latest` だけ使う
問題:
- どの版か追跡しにくい
- ロールバックしにくい

安全策:
- バージョン、環境、日付など意味のあるタグを使う

### よくあるミス 3: 秘密情報をイメージに焼き込む
問題:
- イメージ配布時に漏えいしやすい
- 履歴やレイヤにも残り得る

安全策:
- secrets は実行時注入
- `.env` を安易に `COPY` しない
- Compose/CI の secret 機構を使う

### よくあるミス 4: root 前提で何でも動かす
問題:
- 万一侵害されたときの影響が大きい

安全策:
- 可能なら非 root ユーザー実行を検討する
- 本番向けでは最小権限を意識する

### よくあるミス 5: build context が大きすぎる
問題:
- build が遅い
- 無駄な転送が増える

安全策:
- `.git`, `node_modules`, ローカル生成物を `.dockerignore` へ

---

## 8) One interview-style question
**質問:**
Dockerfile で次の順序にする理由を説明してください。

```Dockerfile
COPY package*.json ./
RUN npm ci
COPY . .
```

**考えるポイント:**
- build cache
- 変更頻度の違い
- CI/CD の実行時間
- 再現性

---

## 9) Next-step resources
公式ドキュメント中心に、次に読むと効果が高い順で並べます。

- Docker docs: Build の概要  
  <https://docs.docker.com/build/>

- Docker docs: Dockerfile リファレンス  
  <https://docs.docker.com/reference/dockerfile/>

- Docker docs: Best practices for writing Dockerfiles  
  <https://docs.docker.com/develop/develop-images/dockerfile_best-practices/>

- Docker docs: Multi-stage builds  
  <https://docs.docker.com/build/building/multi-stage/>

- Docker docs: .dockerignore  
  <https://docs.docker.com/build/concepts/context/#dockerignore-files>

- Docker docs: Image tagging  
  <https://docs.docker.com/reference/cli/docker/image/tag/>

---

## まとめ
今日の要点は 3 つです。

1. `docker build` は単なるイメージ作成コマンドではなく、**再現性ある開発フローの入り口**
2. 良い Dockerfile は、**小さい・速い・安全**を意識して設計する
3. `.dockerignore`、`COPY` 順序、秘密情報の扱いが、実務品質を大きく左右する

次の Advanced 回では、**multi-stage build / BuildKit / キャッシュ最適化 / セキュアな build パイプライン**へ進むと流れがきれいです。
