---
tags:
  - docker
  - containers
  - devops
  - learning
  - daily
---

[[Home]]

# Docker Commands Magazine — 2026-07-09

今日のテーマは **「docker run / exec / logs / ps を使って、アプリ開発中のコンテナを安全に観察・操作する」** です。  
難易度は **Beginner → Middle → Advanced** の順で進み、同じ題材を少しずつ深くしていきます。

---

## 1) Topic + Level

### Beginner
**Topic:** `docker ps` / `docker run` / `docker logs` / `docker exec` の基本

### Middle
**Topic:** 開発用コンテナの運用確認とデバッグ

**Prerequisites:**
- `docker ps` でコンテナ一覧を見られる
- `docker run` でコンテナを起動したことがある
- `docker logs` の基本を知っている

### Advanced
**Topic:** 実アプリ開発での安全なコンテナ操作と再現性の高いワークフロー

**Prerequisites:**
- `docker exec` でコンテナ内に入れる
- ポート公開 (`-p`) の意味を理解している
- イメージとコンテナの違いを説明できる

---

## 2) Why it matters for real app development

実アプリ開発では、Dockerは「ただ起動するだけ」の道具ではありません。  
特に以下の場面で、今回のコマンド群は毎日のように使います。

- **ローカル開発環境を揃える**
  - Node.js, Python, PostgreSQL, Redis などを同じ手順で再現できる
- **不具合調査を速くする**
  - ログ確認、プロセス確認、環境差分の調査がしやすい
- **チーム開発のズレを減らす**
  - 「自分のPCでは動く」を減らせる
- **本番に近い形で検証する**
  - コンテナ前提のCI/CDやクラウド配備とつながる

Docker公式のベストプラクティスでも、**再現性・最小権限・イメージの小型化・秘密情報をイメージに埋め込まないこと** が重視されています。  
今日の内容は、その土台になる「普段使いの操作」を安全に身につける回です。

---

## 3) Core Docker command explanations

### `docker ps`
起動中のコンテナ一覧を表示します。

```bash
docker ps
```

よく使う派生:

```bash
docker ps -a
```
- 停止済みも含めて表示

見るポイント:
- `CONTAINER ID`
- `IMAGE`
- `STATUS`
- `PORTS`
- `NAMES`

---

### `docker run`
イメージから新しいコンテナを作成し、起動します。

```bash
docker run -d --name web -p 8080:80 nginx:latest
```

主なオプション:
- `-d`: バックグラウンド起動
- `--name`: コンテナ名を付ける
- `-p 8080:80`: ホスト8080番 → コンテナ80番へ公開

注意:
- `latest` タグは手軽ですが、**再現性の観点では固定バージョン推奨**
- 例: `nginx:1.27-alpine`

---

### `docker logs`
コンテナの標準出力・標準エラー出力を確認します。

```bash
docker logs web
```

便利な使い方:

```bash
docker logs -f web
```
- ログを追尾する (`tail -f` のような感覚)

```bash
docker logs --tail 100 web
```
- 直近100行だけ見る

---

### `docker exec`
起動中コンテナ内でコマンドを実行します。

```bash
docker exec web ls /usr/share/nginx/html
```

シェルに入る場合:

```bash
docker exec -it web sh
```

補足:
- Alpine系は `bash` ではなく `sh` のことが多い
- 本番運用では「コンテナに入って手で直す」より、**Dockerfileや設定を修正して作り直す** 方が安全です

---

## 4) How Docker is used while building apps

Docker公式の考え方に沿うと、アプリ開発中のDocker利用は次のようになります。

### 4-1. 開発環境の標準化
たとえばWebアプリでは、以下をコンテナで揃えます。

- アプリ本体
- DB (PostgreSQL/MySQL)
- キャッシュ (Redis)
- ジョブワーカー

これにより、新メンバーも同じコマンドで環境構築できます。

### 4-2. 依存関係をホストから切り離す
ローカルPCに大量の依存を直入れせず、コンテナに閉じ込めることで、環境汚染を減らせます。

### 4-3. ログ中心で状態把握する
Dockerでは、アプリの挙動をまず `docker logs` で確認する運用が基本です。  
「中に入ってなんとなく見る」より、**ログが読める構造にしておく** 方が保守性が上がります。

### 4-4. 使い捨て前提で作る
コンテナはVMより軽く、**壊れたら作り直す** 発想が重要です。  
そのために:
- イメージは再ビルド可能にする
- 手作業変更に依存しない
- 設定はコード化する

### 4-5. 秘密情報を埋め込まない
安全面で重要です。

**やってはいけない例:**
- DockerfileにAPIキーを書く
- `ENV PASSWORD=...` をイメージに含める
- `compose.yaml` に本番秘密情報をベタ書きする

**安全な方向:**
- 環境変数は安全な注入方法を使う
- Secret管理機構を使う
- `.env` を雑にコミットしない

---

## 5) 30-60 minute hands-on mini lab

## ミニラボ: Nginxコンテナを起動して観察する

**目標:**
- コンテナを起動する
- 起動状態とポートを確認する
- ログを見る
- コンテナ内のファイルを確認する
- 安全に停止・削除する

**所要時間:** 30〜45分

### Step 1: イメージを取得して起動

```bash
docker run -d --name docker-mag-web -p 8080:80 nginx:1.27-alpine
```

確認:

```bash
docker ps
```

見るポイント:
- `docker-mag-web` が起動しているか
- `0.0.0.0:8080->80/tcp` のように表示されるか

### Step 2: ブラウザまたはcurlで確認

```bash
curl http://localhost:8080
```

期待結果:
- Nginxの初期HTMLが返る

### Step 3: ログを確認

```bash
docker logs docker-mag-web
```

アクセス後に追尾してみる:

```bash
docker logs -f docker-mag-web
```

別ターミナルで:

```bash
curl http://localhost:8080
```

ログにアクセス記録が出ることを確認します。

### Step 4: コンテナ内を確認

```bash
docker exec docker-mag-web ls /usr/share/nginx/html
```

さらに中に入る:

```bash
docker exec -it docker-mag-web sh
```

中で実行:

```sh
cat /etc/nginx/nginx.conf
exit
```

### Step 5: 停止

```bash
docker stop docker-mag-web
```

### Step 6: 削除

```bash
docker rm docker-mag-web
```

#### 追加チャレンジ（Middle向け）
1. `--name` を変えて2つ目のNginxを起動してみる
2. 同じホストポート `8080` を使うと衝突することを確認する
3. 別ポート `8081:80` で起動し直す

```bash
docker run -d --name docker-mag-web-2 -p 8081:80 nginx:1.27-alpine
```

#### 追加チャレンジ（Advanced向け）
- `docker inspect docker-mag-web-2` で設定情報を読む
- `docker exec` で一時変更しても、作り直すと消えることを確認する
- 「なぜ設定はDockerfileやcomposeで管理すべきか」を言語化する

---

## 6) Command cheatsheet

```bash
# 起動中コンテナ一覧
docker ps

# 停止済みも含める
docker ps -a

# コンテナ起動
docker run -d --name app -p 8080:80 nginx:1.27-alpine

# ログ確認
docker logs app

# ログ追尾
docker logs -f app

# 直近50行
docker logs --tail 50 app

# コンテナ内でコマンド実行
docker exec app ls /

# コンテナ内シェル
docker exec -it app sh

# 停止
docker stop app

# 削除
docker rm app

# 設定確認
docker inspect app
```

---

## 7) Common mistakes and safe practices

### よくあるミス

#### 1. `latest` を何となく使う
- 再現性が落ちる
- チームで結果が変わりやすい

**安全策:**
- バージョンタグを固定する
- 可能なら軽量イメージを選ぶ

#### 2. コンテナ内の手作業変更に頼る
- 再作成で消える
- 手順が属人化する

**安全策:**
- 変更はDockerfileや設定ファイルに戻す

#### 3. ログを見ずに原因調査を始める
- 調査が遠回りになる

**安全策:**
- まず `docker ps` → `docker logs` → 必要なら `docker exec`

#### 4. 秘密情報をイメージやcomposeに直書きする
- 流出リスクが高い
- 履歴に残る

**安全策:**
- Secret管理を使う
- `.env` の扱いを厳格にする
- Gitへ不用意にコミットしない

#### 5. 破壊的なクリーンアップを雑に実行する
特に以下は要注意です。

```bash
docker system prune
docker image prune -a
docker rm -f <container>
docker rmi <image>
```

**警告:**
- 不要と思っていたコンテナ・ネットワーク・イメージ・ビルドキャッシュを消すことがあります
- 開発中のデータや再利用したかったイメージを失う場合があります

**安全策:**
- まず一覧確認する
  - `docker ps -a`
  - `docker images`
  - `docker volume ls`
- `-f` を付ける前に対象を明示する
- prune系は何が消えるか理解してから使う

#### 6. 不要に root 前提で使う
- セキュリティリスクが上がる

**安全策:**
- 最小権限を意識する
- アプリ側も non-root 実行を検討する

---

## 8) One interview-style question

**質問:**  
`docker run` と `docker exec` の違いを説明してください。また、アプリの不具合調査で両者をどう使い分けますか？

**考えるポイント:**
- 新規コンテナ作成か、既存コンテナへの操作か
- 再現性のある調査か、その場しのぎの確認か
- どこまでをDockerfile/composeへ反映すべきか

---

## 9) Next-step resources

まずは公式ドキュメント中心で進むのが堅いです。

- Docker Get Started  
  https://docs.docker.com/get-started/

- Docker CLI reference  
  https://docs.docker.com/reference/cli/docker/

- `docker run` reference  
  https://docs.docker.com/reference/cli/docker/container/run/

- `docker exec` reference  
  https://docs.docker.com/reference/cli/docker/container/exec/

- `docker logs` reference  
  https://docs.docker.com/reference/cli/docker/container/logs/

- Best practices for writing Dockerfiles  
  https://docs.docker.com/build/building/best-practices/

- Multi-stage builds  
  https://docs.docker.com/build/building/multi-stage/

- Manage sensitive data with Docker secrets  
  https://docs.docker.com/engine/swarm/secrets/

---

## 今日のひとこと

Dockerは「難しいオーケストレーション」より前に、  
**コンテナを観察し、状態を読み、壊したら作り直せる** ことが強いです。  
まずは `ps` / `run` / `logs` / `exec` を、速く・安全に・迷わず使えるようにするのが実務の第一歩です。
