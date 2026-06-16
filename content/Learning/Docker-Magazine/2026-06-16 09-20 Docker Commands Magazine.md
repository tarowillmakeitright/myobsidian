---
tags:
  - docker
  - containers
  - devops
  - learning
  - daily
---

# Docker Commands Magazine — 2026-06-16 09:20
[[Home]]

# Docker Commands Magazine

今日のテーマは **`docker run` / `docker ps` / `docker logs` / `docker exec` を軸にした「コンテナ実行とデバッグの基本」** です。昨日の `docker build` の続きとして、**作ったイメージを安全に動かし、状態を観察し、原因を切り分ける** ところまでを扱います。

---

## 1) Topic + Level

### Beginner
**トピック:** `docker run` でアプリを起動し、`docker ps` と `docker logs` で状態確認する

### Middle
**トピック:** `docker exec` と環境変数・ポート指定を使って、実行中コンテナの中身を確認する
**前提知識:**
- `docker build -t <image>:<tag> .` を使ってイメージを作れる
- `docker run -p ホスト:コンテナ` の意味が分かる
- Linux の基本コマンド（`ls`, `cat`, `env`）を少し読める

### Advanced
**トピック:** 再現性と安全性を意識して、開発用コンテナの起動オプションを設計する
**前提知識:**
- `docker run`, `docker ps`, `docker logs`, `docker exec` を一通り触ったことがある
- コンテナとイメージの違いを説明できる
- Dockerfile の基本（`FROM`, `WORKDIR`, `COPY`, `CMD`）を知っている

---

## 2) Why it matters for real app development

実アプリ開発では、Docker は単に「動けばよい箱」ではありません。次のような場面で毎日使います。

- **ローカル開発環境の統一**
  - 「自分のPCでは動く」を減らし、チームで同じ実行条件をそろえる
- **依存関係の隔離**
  - Node.js, Python, DB, Redis などのバージョン差分を吸収する
- **障害調査の高速化**
  - 起動失敗、ポート競合、設定ミス、環境変数不足をログから素早く切り分ける
- **本番に近い実行確認**
  - docs.docker.com のベストプラクティスにもある通り、イメージはできるだけ一貫した方法でビルド・実行し、不要な差分を減らすことが重要

Docker を学ぶ意味は、**コンテナを作ること** ではなく、**安全に再現可能な開発・検証フローを作ること** にあります。

---

## 3) Core Docker command explanations

### `docker run`
イメージから新しいコンテナを作成し、起動します。

```bash
docker run --name hello-nginx -d -p 8080:80 nginx:alpine
```

よく使うオプション:
- `--name` : コンテナ名を付ける
- `-d` : バックグラウンド実行
- `-p 8080:80` : ホストの 8080 をコンテナの 80 に転送
- `-e KEY=value` : 環境変数を渡す
- `--rm` : 停止後にコンテナを自動削除（検証向き）

### `docker ps`
起動中のコンテナ一覧を表示します。

```bash
docker ps
```

停止済みも含めて見るなら:

```bash
docker ps -a
```

確認ポイント:
- STATUS が `Up` か
- PORTS が期待通りか
- NAMES が管理しやすい名前か

### `docker logs`
コンテナ標準出力・標準エラー出力を確認します。

```bash
docker logs hello-nginx
```

追いかけるなら:

```bash
docker logs -f hello-nginx
```

ログは障害調査の第一歩です。**起動しないときは、まず logs** が基本です。

### `docker exec`
実行中コンテナの中でコマンドを実行します。

```bash
docker exec -it hello-nginx sh
```

よくある使い方:
- 設定ファイル確認
- 環境変数確認
- アプリ生成物の確認
- 動作中プロセスの確認

注意:
- `exec` は調査に便利ですが、**手で直した変更は再現性がありません**
- 恒久対応は Dockerfile や Compose 設定に戻して反映するのが原則です

### `docker stop`
コンテナを安全に停止します。

```bash
docker stop hello-nginx
```

### `docker rm`
停止済みコンテナを削除します。

```bash
docker rm hello-nginx
```

> 注意: `docker rm -f` は強制停止を伴うことがあります。開発中でも、まず `docker stop` → `docker rm` の順を優先してください。

---

## 4) How Docker is used while building apps

Docker公式ドキュメントのベストプラクティスに沿うと、アプリ開発では次の流れが実践的です。

### A. イメージは「再現可能な成果物」として作る
- 依存関係を Dockerfile に明示する
- ローカルだけの差分を入れない
- `.dockerignore` で不要ファイルをビルド文脈から除外する

### B. コンテナは「一時的な実行環境」として扱う
- コンテナ内を手作業で修正し続けない
- 問題があれば Dockerfile / Compose / 起動オプションを直して再作成する
- つまり **pets ではなく cattle 的に扱う**

### C. 設定はイメージではなく実行時に注入する
- 環境差分は `-e` や Compose の environment で渡す
- **シークレットをイメージに bake しない**
- `Dockerfile` や `compose.yaml` に秘密情報を直書きしない

### D. 小さく、観察しやすく、壊しやすく作る
- 単一責務のコンテナを意識する
- ログを標準出力に出す
- ヘルスチェックや明確な起動コマンドで状態把握しやすくする

### E. 掃除コマンドは慎重に使う
以下は便利ですが、削除範囲を理解してから実行してください。

```bash
docker container prune
docker image prune -a
docker system prune
```

> 警告: `prune` 系は未使用コンテナ・ネットワーク・イメージ・キャッシュを削除します。学習環境や他プロジェクトも巻き込む可能性があります。**対象を確認してから実行** し、共有環境では特に慎重に扱ってください。

---

## 5) 30-60 minute hands-on mini lab

**テーマ:** 小さなWebアプリを Docker で起動し、ログ確認と中身の調査までやる

所要時間: 40〜50分

### ゴール
- `docker build` でイメージ作成
- `docker run` で起動
- `docker ps` / `docker logs` / `docker exec` で確認
- 起動設定を変えて再実行

### 手順 1: 作業フォルダ作成

```bash
mkdir -p ~/docker-magazine-lab-2026-06-16
cd ~/docker-magazine-lab-2026-06-16
```

### 手順 2: アプリ作成

`index.html`

```html
<!doctype html>
<html lang="ja">
<head>
  <meta charset="utf-8">
  <title>Docker Lab</title>
</head>
<body>
  <h1>Hello Docker Lab</h1>
  <p>コンテナ実行確認用ページです。</p>
</body>
</html>
```

`Dockerfile`

```dockerfile
FROM nginx:alpine
COPY index.html /usr/share/nginx/html/index.html
EXPOSE 80
```

### 手順 3: イメージをビルド

```bash
docker build -t docker-lab:web-001 .
```

### 手順 4: コンテナ起動

```bash
docker run --name docker-lab-web -d -p 8081:80 docker-lab:web-001
```

ブラウザで `http://localhost:8081` を開き、ページが見えるか確認します。

### 手順 5: 状態確認

```bash
docker ps
docker logs docker-lab-web
```

チェックポイント:
- コンテナが `Up` になっているか
- ポートが `0.0.0.0:8081->80/tcp` のように見えるか
- ログに異常がないか

### 手順 6: コンテナ内部を確認

```bash
docker exec -it docker-lab-web sh
```

コンテナ内で実行:

```sh
ls /usr/share/nginx/html
cat /usr/share/nginx/html/index.html
nginx -T | head -n 40
exit
```

### 手順 7: 起動条件を変えて再実行
まず停止・削除:

```bash
docker stop docker-lab-web
docker rm docker-lab-web
```

再起動:

```bash
docker run --name docker-lab-web -d -p 8082:80 docker-lab:web-001
```

ポート変更後に `http://localhost:8082` を確認します。

### 手順 8: 発展課題
- `--rm` を付けた一時実行を試す
- `docker ps -a` で停止済みも確認する
- `docker logs -f` でアクセスログを眺める
- `compose.yaml` に置き換えるならどう書くか考える

---

## 6) Command cheatsheet

```bash
# イメージをビルド
docker build -t myapp:dev .

# コンテナをバックグラウンド起動
docker run --name myapp -d -p 8080:80 myapp:dev

# 環境変数を渡して起動
docker run --name myapp -d -p 8080:80 -e APP_ENV=dev myapp:dev

# 起動中コンテナ確認
docker ps

# 停止済み含めて確認
docker ps -a

# ログ確認
docker logs myapp

# ログ追跡
docker logs -f myapp

# コンテナに入る
docker exec -it myapp sh

# 安全に停止
docker stop myapp

# 停止済みを削除
docker rm myapp
```

慎重に使うコマンド:

```bash
# 警告: 未使用リソースを削除
docker container prune

# 警告: 未使用イメージを広く削除
docker image prune -a

# 警告: 幅広く掃除するため影響範囲を要確認
docker system prune
```

---

## 7) Common mistakes and safe practices

### よくあるミス 1: コンテナ内を手で直して満足する
- 問題: 再起動・再作成で消える
- 安全策: Dockerfile や `compose.yaml` に戻して修正する

### よくあるミス 2: ポート公開範囲を意識しない
- 問題: ローカル確認のつもりが外部アクセス可能になることがある
- 安全策: 必要最小限のポートだけ公開する。用途によっては `127.0.0.1:8080:80` のようにバインド先を限定する

### よくあるミス 3: シークレットをイメージに埋め込む
- 問題: イメージ共有時に漏えいする
- 安全策: APIキー・DBパスワードを Dockerfile や Git 管理下の Compose に直書きしない。実行時注入や秘密情報管理の仕組みを使う

### よくあるミス 4: `latest` タグを当然視する
- 問題: 再現性が落ちる
- 安全策: ベースイメージや自作イメージに意味のあるタグを付ける

### よくあるミス 5: `prune` / `rmi` / `rm -f` を雑に使う
- 問題: 他の学習成果物や必要イメージまで消える
- 安全策: 実行前に `docker ps -a`, `docker images` を確認する。共有環境・作業中環境では特に慎重に

### よくあるミス 6: root 前提で考える
- 問題: 権限やセキュリティ面で事故の元になる
- 安全策: Dockerfile では可能なら non-root 実行を検討し、最小権限を意識する

---

## 8) One interview-style question

**質問:**
`docker run` で起動したアプリがブラウザから見えません。あなたならどの順番で切り分けますか？

**答えるときの観点例:**
- コンテナが起動しているか (`docker ps`)
- ポート公開が正しいか (`-p host:container`)
- アプリがコンテナ内でそのポートを listen しているか
- ログにエラーがないか (`docker logs`)
- ホスト側でポート競合がないか
- `127.0.0.1` bind と `0.0.0.0` bind の違いを理解しているか

---

## 9) Next-step resources

まずは公式ドキュメント中心で進めるのがおすすめです。

- Docker Get Started
  - https://docs.docker.com/get-started/
- Dockerfile reference
  - https://docs.docker.com/reference/dockerfile/
- `docker run` reference
  - https://docs.docker.com/reference/cli/docker/container/run/
- `docker logs` reference
  - https://docs.docker.com/reference/cli/docker/container/logs/
- `docker exec` reference
  - https://docs.docker.com/reference/cli/docker/container/exec/
- Build best practices
  - https://docs.docker.com/build/building/best-practices/
- Develop with containers
  - https://docs.docker.com/guides/
- Compose file reference
  - https://docs.docker.com/reference/compose-file/
- Docker security overview
  - https://docs.docker.com/engine/security/

---

## 今日のひとこと

`docker build` で終わる人と、`docker run` 後に **観察・切り分け・再現性ある修正** までできる人では、実務の強さがかなり違います。今日は「起動する」より一歩進めて、**安全に調べられる人** になる回です。
