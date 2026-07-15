---
tags:
  - docker
  - containers
  - devops
  - learning
  - daily
date: 2026-07-15 09:20
level: Beginner
---

# 2026-07-15 09-20 Docker Commands Magazine

[[Home]]

#docker #containers #devops #learning #daily

## 1) Topic + Level

**Level: Beginner**

**テーマ：`docker run` から始めるコンテナのライフサイクルと安全なポート公開**

今日は、Webアプリを「起動する → 状態を見る → ログを読む → 停止する → 削除する」という基本ループを身につける。特に `-p` の意味と、開発用サービスをローカルホストだけに公開する方法を扱う。

## 2) 実際のアプリ開発で重要な理由

Docker化されたアプリでは、コードが動かない原因を調べる最初の手掛かりがコンテナの状態とログになる。開発者がライフサイクル操作を理解していると、環境差分を減らし、同じイメージをチームやCIで再現できる。

また、ポート公開はブラウザからアプリへ接続するために必要だが、`-p 8080:80` のようにIPを省略すると、既定では全ネットワークインターフェースに公開される。ローカル開発では `127.0.0.1:8080:80` と書く習慣が安全。

## 3) コアDockerコマンド

### 起動

```bash
docker run --name web-demo -d -p 127.0.0.1:8080:80 nginx:alpine
```

- `docker run`: イメージから新しいコンテナを作成して起動
- `--name web-demo`: 人が読める固定名を付ける
- `-d`: バックグラウンドで実行
- `-p 127.0.0.1:8080:80`: ホストの8080番をコンテナの80番へ転送し、ローカルからだけ接続可能にする
- `nginx:alpine`: 利用するイメージとタグ。再現性を重視する場合は、検証済みの具体的なバージョンまたはdigestへ固定する

### 観察

```bash
docker ps
docker ps -a
docker logs web-demo
docker logs --tail 20 -f web-demo
docker inspect web-demo
docker port web-demo
```

- `ps`: 実行中、`ps -a`: 停止済みを含む一覧
- `logs`: 標準出力・標準エラーを確認。`-f` は追跡、`Ctrl+C` で追跡だけを終了
- `inspect`: 設定、ネットワーク、マウントなどの詳細をJSONで表示
- `port`: 実際のポート対応を確認

### 停止・再開・削除

```bash
docker stop web-demo
docker start web-demo
docker rm web-demo
```

`stop` はまず正常終了シグナルを送る。通常は `kill` や `rm -f` より `stop` を優先する。`rm` は停止済みコンテナを削除するが、元のイメージは残る。

## 4) アプリ構築中のDocker活用

典型的な開発ループは次の通り。

1. Dockerfileからアプリイメージをビルドする
2. 明示的な名前と必要最小限のポートで起動する
3. `docker ps`、`logs`、`inspect` で状態を観察する
4. コード変更後にイメージを再ビルドし、古いコンテナを置き換える
5. 動作確認済みイメージをCIやステージングでも使う

Docker Docsのベストプラクティスに沿い、ベースイメージは小さく信頼できるものを選び、不要なパッケージを入れず、タグを意識して定期的に再ビルドする。アプリは可能なら非rootユーザーで動かし、ポートやマウントは必要なものだけ許可する。

秘密情報をDockerfileの `ENV` や `ARG`、ソース、イメージへ焼き込まない。ビルド時の秘密はBuildKit secret、実行時は適切なsecret管理基盤を使う。`.env` はGitへコミットせず、Composeでも秘密値を平文で共有しない。

## 5) 30〜60分ハンズオン・ミニラボ

**目安：40分**

### A. 事前確認（5分）

```bash
docker version
docker info
```

Docker Engineへ接続できることを確認する。エラー時はDocker DesktopまたはDocker Engineの起動状態を確認。

### B. Webコンテナを安全に起動（10分）

```bash
docker pull nginx:alpine
docker run --name web-demo -d -p 127.0.0.1:8080:80 nginx:alpine
docker ps
docker port web-demo
```

ブラウザで `http://127.0.0.1:8080` を開く。ホスト8080番とコンテナ80番の違いを説明できるようにする。

### C. ログと設定を調査（10分）

ページを数回再読み込みしてから実行する。

```bash
docker logs --tail 10 web-demo
docker inspect --format '{{.State.Status}}' web-demo
docker inspect --format '{{json .NetworkSettings.Ports}}' web-demo
```

アクセスログと `running` 状態、ポート割り当てを確認する。`inspect --format` は巨大なJSONから必要な値だけを取り出す実務的な方法。

### D. ライフサイクルを体験（10分）

```bash
docker stop web-demo
docker ps
docker ps -a
docker start web-demo
docker ps
```

停止中は `docker ps` から消えても、`docker ps -a` には残ることを確認。再起動後にページへ再アクセスする。

### E. 後片付け（5分）

```bash
docker stop web-demo
docker rm web-demo
```

最後に `docker ps -a` で削除を確認する。学習用イメージも消したい場合だけ `docker image rm nginx:alpine` を使う。

## 6) コマンド・チートシート

```text
docker pull IMAGE                  イメージ取得
docker run --name NAME -d IMAGE    作成してバックグラウンド起動
docker run -p 127.0.0.1:H:C IMAGE  localhostのH番をコンテナC番へ公開
docker ps                          実行中一覧
docker ps -a                       全コンテナ一覧
docker logs --tail 50 NAME         最新50行のログ
docker logs -f NAME                ログ追跡（Ctrl+Cで終了）
docker inspect NAME                詳細情報
docker port NAME                   ポート対応
docker stop NAME                   正常停止を試みる
docker start NAME                  停止済みを再開
docker rm NAME                     停止済みを削除
docker image ls                    ローカルイメージ一覧
```

## 7) よくあるミスと安全策

- **ホスト側とコンテナ側のポートを逆にする**：`HOST:CONTAINER` の順。アプリがコンテナ内で待ち受ける番号を右に書く。
- **不要に外部公開する**：ローカル開発では `-p 127.0.0.1:8080:80` を優先。DBポートを安易に公開しない。
- **`EXPOSE`だけで接続できると思う**：`EXPOSE` はメタデータであり、ホスト公開には `-p` が必要。
- **ログ追跡をコンテナ停止と勘違いする**：`docker logs -f` の `Ctrl+C` は追跡を終えるだけ。
- **`latest` を無条件に使う**：内容が変わり得る。チームやCIでは検証済みタグまたはdigestを使う。
- **秘密をイメージへ入れる**：Dockerfile、ビルドコンテキスト、Composeファイル、Git管理下の `.env` に秘密を書かない。
- **強制削除を常用する**：`docker rm -f` は実行中プロセスを強制終了する。まず `docker stop`、次に通常の `docker rm`。

> [!danger] 破壊的クリーンアップに注意
> `docker system prune`、`docker image prune`、`docker rmi` / `docker image rm`、`docker rm -f` は、未使用と判断された資産、キャッシュ、イメージ、または実行中コンテナを削除し得る。共有ホストや重要データのある環境では実行前に `docker ps -a`、`docker image ls`、`docker volume ls` と対象を確認する。特に `--volumes` 付きpruneは永続データ喪失につながるため、バックアップと明示的な承認なしに実行しない。

## 8) 面接スタイルの質問

**質問：** `docker run -d -p 8080:80 nginx` を実行したとき、2つのポート番号は何を表し、セキュリティ面でどのように改善できますか？

**回答の要点：** 8080はホスト側、80はコンテナ内でサービスが待ち受ける側。IP省略時は既定で全インターフェースに公開されるため、ローカル開発なら `-p 127.0.0.1:8080:80` として到達範囲を限定する。さらに、不要なサービスやDBポートは公開しない。

## 9) 次のステップ（Docker公式）

- [Get started](https://docs.docker.com/get-started/)
- [Running containers](https://docs.docker.com/engine/containers/run/)
- [Publishing and exposing ports](https://docs.docker.com/get-started/docker-concepts/running-containers/publishing-ports/)
- [Port publishing and mapping](https://docs.docker.com/engine/network/port-publishing/)
- [Building best practices](https://docs.docker.com/build/building/best-practices/)
- [Docker CLI Cheat Sheet (PDF)](https://docs.docker.com/get-started/docker_cheatsheet.pdf)

### 次号への橋渡し

次は **Middle**。前提として今日の `run`、`ps`、`logs`、`stop`、`rm` とポート公開を理解したうえで、複数サービスをDocker Composeで起動し、ヘルスチェックと名前解決を扱う。
