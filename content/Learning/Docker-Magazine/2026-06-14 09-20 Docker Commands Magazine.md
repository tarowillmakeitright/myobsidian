---
tags:
  - docker
  - containers
  - devops
  - learning
  - daily
---

[[Home]]

# Daily Docker Commands Magazine

**日付:** 2026-06-14 09:20
**テーマ:** Dockerコマンドで学ぶ、アプリ開発の基本から実践運用まで

---

# Issue 1 — Beginner

## 1) Topic + Level
**Topic:** `docker run` / `docker ps` / `docker logs` の基本
**Level:** Beginner

## 2) Why it matters for real app development
アプリ開発では「自分のPCでは動くのに、他の環境では動かない」が頻発します。Dockerを使うと、実行環境をイメージとして固定し、チーム全員がほぼ同じ条件でアプリを動かせます。

特に初心者が最初に覚えるべきなのは、**コンテナを起動し、状態を見て、ログを読む**ことです。これは開発中の検証、デバッグ、簡易なローカル実行で毎日のように使います。

## 3) Core Docker command explanations

### `docker run`
イメージからコンテナを作成して起動します。

```bash
docker run hello-world
```

- イメージがローカルにない場合は取得してから実行
- 「作成」と「起動」をまとめて行う基本コマンド

Webアプリ確認でよくある例:

```bash
docker run --name webtest -d -p 8080:80 nginx
```

- `--name webtest`: コンテナ名を付ける
- `-d`: バックグラウンド起動
- `-p 8080:80`: ホストの8080番をコンテナの80番へ転送

### `docker ps`
動いているコンテナを確認します。

```bash
docker ps
```

停止済みも含めるなら:

```bash
docker ps -a
```

### `docker logs`
コンテナの標準出力・標準エラーを確認します。

```bash
docker logs webtest
```

追尾するなら:

```bash
docker logs -f webtest
```

## 4) How Docker is used while building apps
Docker公式のベストプラクティスに沿うと、開発中は次の流れが実践的です。

- まずは**公式イメージ**を使って検証する
- アプリを入れる前に、**コンテナの起動・停止・ログ確認**に慣れる
- コンテナは**使い捨て可能**である前提で扱う
- ログはコンテナ内に閉じ込めず、まずは標準出力へ出す
- 不要に `latest` へ依存せず、学習でもタグを意識する

例: Nginxの挙動確認を通じて、「ポート公開」「ログ確認」「停止」を短く回せるようになると、今後のNode.js/Python/Goアプリにもそのまま応用できます。

## 5) 30-60 minute hands-on mini lab
**目標:** Nginxコンテナを起動し、アクセスし、ログを確認して、停止・削除まで体験する

### 手順
1. コンテナ起動

```bash
docker run --name webtest -d -p 8080:80 nginx:stable
```

2. 状態確認

```bash
docker ps
```

3. ブラウザで確認
- `http://localhost:8080` にアクセス

4. ログ確認

```bash
docker logs webtest
```

5. 停止

```bash
docker stop webtest
```

6. 停止後の確認

```bash
docker ps -a
```

7. 削除

```bash
docker rm webtest
```

### できたら追加
- `-d` を外して前面起動してみる
- `docker logs -f` で追尾してみる
- `nginx:stable` を `nginx:alpine` に変えて差を観察する

## 6) Command cheatsheet

```bash
docker run hello-world
docker run --name webtest -d -p 8080:80 nginx:stable
docker ps
docker ps -a
docker logs webtest
docker logs -f webtest
docker stop webtest
docker rm webtest
```

## 7) Common mistakes and safe practices

### よくあるミス
- `-p` を付け忘れてブラウザから見えない
- `docker ps` だけ見て停止済みコンテナを見落とす
- ログ確認せず「動かない」と判断する
- `latest` 前提で再現性を落とす

### 安全な使い方
- 学習でも**明示的タグ**を付ける (`nginx:stable` など)
- まず `docker ps -a` と `docker logs` で状況把握する
- 本番に近い用途ほど、どのイメージを使ったか記録する

## 8) One interview-style question
`docker run -d -p 8080:80 nginx` を実行したあと、ブラウザで表示されない場合、最初に何を確認しますか？理由も説明してください。

## 9) Next-step resources
- Docker Get Started: https://docs.docker.com/get-started/
- Running containers: https://docs.docker.com/get-started/docker-concepts/running-containers/
- Docker CLI reference (`docker run`): https://docs.docker.com/reference/cli/docker/container/run/
- Docker CLI reference (`docker logs`): https://docs.docker.com/reference/cli/docker/container/logs/

---

# Issue 2 — Middle

## 1) Topic + Level
**Topic:** `docker build` / `docker exec` / `docker compose up` を使った開発環境構築
**Level:** Middle
**Prerequisites:**
- `docker run`, `docker ps`, `docker logs` の基本が分かる
- ポート公開の意味が分かる
- コンテナは「プロセスを実行する箱」というイメージを持っている

## 2) Why it matters for real app development
実アプリ開発では、単に公式イメージを起動するだけでは足りません。自分のアプリコードを入れたイメージを作り、アプリとDBをまとめて立ち上げ、必要に応じてコンテナへ入って確認する必要があります。

この段階で重要なのは、**再現可能な開発環境**をコード化することです。手でセットアップ手順を書くより、DockerfileとComposeで定義したほうがチーム開発・CI・引き継ぎに強くなります。

## 3) Core Docker command explanations

### `docker build`
Dockerfileからイメージを作成します。

```bash
docker build -t my-node-app:dev .
```

- `-t`: イメージ名とタグ
- `.`: ビルドコンテキスト

### `docker exec`
起動中コンテナ内でコマンドを実行します。

```bash
docker exec -it myapp sh
```

- `-i`: 標準入力を開く
- `-t`: 疑似TTYを付ける
- デバッグに便利だが、**恒久的変更を手作業で入れない**のが原則

### `docker compose up`
複数サービスをまとめて起動します。

```bash
docker compose up -d
```

- Webアプリ、DB、Redisなどを一括起動できる
- 開発環境の標準化に向いている

## 4) How Docker is used while building apps
Docker公式ベストプラクティスと整合する実務的な考え方:

- **Dockerfileで環境を定義**し、手作業セットアップを減らす
- `.dockerignore` を使って不要ファイルをビルドへ含めない
- **小さいイメージ**を意識する
- 依存関係のインストールとアプリコードのコピー順を工夫し、**ビルドキャッシュ**を活かす
- アプリ設定値や秘密情報をイメージへ焼き込まない
- ローカル開発ではComposeでアプリと周辺サービスをまとめる

### 例: Node.jsアプリの最小Dockerfile

```dockerfile
FROM node:22-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
```

これはシンプルですが、
- 依存関係を先にコピーしてキャッシュを効かせる
- ベースイメージを比較的軽量にする
という良い型になっています。

## 5) 30-60 minute hands-on mini lab
**目標:** シンプルなNode.jsアプリをコンテナ化し、Composeで起動する

### 例の `Dockerfile`

```dockerfile
FROM node:22-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
```

### 例の `compose.yaml`

```yaml
services:
  app:
    build: .
    ports:
      - "3000:3000"
```

### 手順
1. Dockerfileを用意
2. イメージ作成

```bash
docker build -t my-node-app:dev .
```

3. 単体起動

```bash
docker run --name myapp -d -p 3000:3000 my-node-app:dev
```

4. ログ確認

```bash
docker logs myapp
```

5. コンテナ内確認

```bash
docker exec -it myapp sh
```

6. 停止・削除

```bash
docker stop myapp
docker rm myapp
```

7. Compose起動

```bash
docker compose up -d
```

8. Compose停止

```bash
docker compose down
```

### 学習ポイント
- Dockerfileを変えるとどこまで再ビルドされるか
- `docker exec` は調査用であって、修正はDockerfileへ戻すべきこと
- Composeにすると起動コマンドの共有が楽になること

## 6) Command cheatsheet

```bash
docker build -t my-node-app:dev .
docker run --name myapp -d -p 3000:3000 my-node-app:dev
docker exec -it myapp sh
docker compose up -d
docker compose down
docker compose logs -f
```

## 7) Common mistakes and safe practices

### よくあるミス
- `.dockerignore` を作らず `node_modules` や `.git` を送ってしまう
- `docker exec` で直した内容が永続化されると思い込む
- 秘密情報を `ENV` やDockerfileへ直書きする
- Composeに本番用と開発用の設定を混在させる

### 安全な使い方
- `.env` やシークレット管理を分離し、**イメージに秘密を入れない**
- 開発用Composeと本番運用定義を安易に同一視しない
- イメージは定期的に再ビルドし、ベースイメージ更新を取り込む
- `docker exec` は調査用。修正はソースやDockerfileへ反映する

## 8) One interview-style question
Dockerfileで `COPY . .` より前に `COPY package*.json ./` と `RUN npm ci` を置くと、なぜビルド効率が良くなるのでしょうか？

## 9) Next-step resources
- Building images: https://docs.docker.com/get-started/docker-concepts/building-images/
- Best practices for writing Dockerfiles: https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Docker Compose overview: https://docs.docker.com/compose/
- Compose file reference: https://docs.docker.com/reference/compose-file/

---

# Issue 3 — Advanced

## 1) Topic + Level
**Topic:** `docker image ls` / `docker inspect` / `docker compose logs` / 安全なクリーンアップ運用
**Level:** Advanced
**Prerequisites:**
- DockerfileとComposeの基本が分かる
- コンテナ・イメージ・ネットワーク・ボリュームの違いをざっくり説明できる
- 開発中のデバッグで `logs` や `exec` を使ったことがある

## 2) Why it matters for real app development
実務では「起動できる」だけでなく、**なぜその状態なのかを観測し、安全に保守する**ことが重要です。イメージ肥大化、意図しない設定、ログ確認不足、雑なクリーンアップは、開発速度だけでなく事故にも直結します。

Advancedでは、状態観察・メタデータ確認・安全な片付けを身につけると、チームのDocker運用がかなり安定します。

## 3) Core Docker command explanations

### `docker image ls`
ローカルイメージ一覧を確認します。

```bash
docker image ls
```

不要な巨大イメージや古いタグの把握に役立ちます。

### `docker inspect`
コンテナやイメージの詳細情報をJSONで確認します。

```bash
docker inspect myapp
```

確認しやすい例:

```bash
docker inspect -f '{{.Config.Image}}' myapp
docker inspect -f '{{json .NetworkSettings.Ports}}' myapp
```

### `docker compose logs`
Compose管理下の複数サービスのログをまとめて見ます。

```bash
docker compose logs -f
```

特定サービスだけなら:

```bash
docker compose logs -f app
```

### クリーンアップ系コマンド
**注意: 破壊的です。対象確認後に実行してください。**

```bash
docker rm
docker rmi
docker system prune
```

とくに以下は要注意です。

```bash
docker system prune -a
docker image rm -f IMAGE_ID
```

- 停止中コンテナや未使用イメージを削除する
- キャッシュ削除で次回ビルドが重くなる
- 誤って必要な資産を消すと復旧コストが高い

## 4) How Docker is used while building apps
Docker公式の実践に寄せるなら、Advancedでは次を意識します。

- **1コンテナ1責務**を基本に保つ
- イメージは必要最小限にし、不要パッケージを減らす
- マルチステージビルドでビルド依存と実行依存を分離する
- ログ・設定・ポート・マウントを `inspect` で確認できるようになる
- クリーンアップは「空き容量確保」より**影響範囲の把握**を優先する
- SecretはBuild Contextやイメージレイヤへ残さない

### 実務でありがちな活用
- 「なぜこのコンテナは想定外ポートを開いているのか」を `inspect` で確認
- 「どのサービスが落ちているのか」を `docker compose logs -f` で切り分け
- 「CIのイメージが肥大化した」原因をレイヤやベースイメージ選択から見直す

## 5) 30-60 minute hands-on mini lab
**目標:** Composeで動かしたアプリの状態を観測し、安全に不要物を整理する

### 手順
1. 既存のCompose環境を起動

```bash
docker compose up -d
```

2. サービス一覧とログ確認

```bash
docker compose ps
docker compose logs -f
```

3. 任意のサービス詳細確認

```bash
docker inspect app
```

4. 公開ポート確認

```bash
docker inspect -f '{{json .NetworkSettings.Ports}}' app
```

5. ローカルイメージ確認

```bash
docker image ls
```

6. 停止

```bash
docker compose down
```

7. クリーンアップ前の確認

```bash
docker ps -a
docker image ls
docker system df
```

8. 必要なら限定的に削除

```bash
docker rm CONTAINER_ID
docker rmi IMAGE_ID
```

### 追加課題
- `docker system df` で容量を見る
- どのイメージが古いかをメモしてから整理する
- 削除前に「次のビルド・起動へ影響するか」を説明してみる

## 6) Command cheatsheet

```bash
docker image ls
docker inspect myapp
docker inspect -f '{{.Config.Image}}' myapp
docker inspect -f '{{json .NetworkSettings.Ports}}' myapp
docker compose ps
docker compose logs -f
docker system df
```

**破壊的コマンド（実行前に要確認）**

```bash
docker rm CONTAINER_ID
docker rmi IMAGE_ID
docker system prune
```

## 7) Common mistakes and safe practices

### よくあるミス
- `docker system prune -a` を意味を理解せず実行する
- `-f` を付けて強制削除し、依存関係や再利用予定を壊す
- `inspect` を使わず、推測で設定を判断する
- Secretをイメージ内やComposeファイルへ直書きする

### 安全な使い方
- 削除系コマンド前に `docker ps -a`, `docker image ls`, `docker system df` を確認する
- `prune`, `rmi`, `rm -f` は**影響範囲を理解してから**実行する
- Secretは安全な注入方法を使い、Gitやイメージレイヤに残さない
- Composeログと `inspect` を組み合わせ、推測ではなく観測で判断する

## 8) One interview-style question
`docker system prune -a` を開発マシンで実行する前に、どんな確認をして、どんなリスクを説明しますか？

## 9) Next-step resources
- Dockerfile best practices: https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Multi-stage builds: https://docs.docker.com/build/building/multi-stage/
- Compose logs reference: https://docs.docker.com/reference/cli/docker/compose/logs/
- Docker inspect reference: https://docs.docker.com/reference/cli/docker/inspect/
- Prune reference: https://docs.docker.com/reference/cli/docker/system/prune/

---

# まとめ

今日の学習アークは、

1. **Beginner:** コンテナを起動して観察する
2. **Middle:** DockerfileとComposeで開発環境を再現可能にする
3. **Advanced:** 状態を観測し、安全に保守する

という流れです。

Dockerは「コマンドを覚えること」自体より、**再現性・観測性・安全性をどう高めるか**が本質です。アプリ開発の現場では、単発の `run` よりも、Dockerfile・Compose・ログ・安全な運用判断が効いてきます。

明日以降は、次の流れで積み上げるとかなり強いです。

- ボリュームと永続化
- ネットワークとサービス間通信
- マルチステージビルド
- 開発用Composeと本番デプロイ設計の違い
