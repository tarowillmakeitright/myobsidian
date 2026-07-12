---
tags:
  - docker
  - containers
  - devops
  - learning
  - daily
---

[[Home]]

# Docker Commands Magazine — 2026-07-12 09:20

## 今日のテーマ
**`docker exec` と `docker logs` で「動いているコンテナの中」を安全に観察する**

---

# 1) Topic + Level

## Beginner
**テーマ:** `docker logs` と `docker exec` の基本

## Middle
**テーマ:** アプリ調査のための `docker inspect` / `docker ps` / `docker compose logs` の連携

**前提条件:**
- `docker run` でコンテナを起動したことがある
- `docker logs` と `docker exec` の基本を知っている
- ポート公開 (`-p`) の意味を理解している

## Advanced
**テーマ:** 本番に近い調査フローとしての「ログ確認 → 状態確認 → 一時的なデバッグ」の設計

**前提条件:**
- Compose を使った複数サービス構成を触ったことがある
- イメージとコンテナの違いを説明できる
- 環境変数・ボリューム・ネットワークの基本を理解している

---

# 2) Why it matters for real app development

アプリ開発では、コンテナは「起動すること」よりも**問題を安全に切り分けること**のほうが重要です。

実務ではこんな場面が頻繁にあります。

- Web アプリが起動したのに 500 エラーになる
- コンテナは `Up` なのにアプリが応答しない
- DB 接続先や環境変数の設定が怪しい
- ローカルでは動くのに Compose にすると失敗する
- デプロイ直後だけ落ちる、または readiness が遅い

このとき、いきなりイメージを作り直したり、`docker rm -f` や `docker system prune` を叩くのは雑です。まずは:

1. **ログを見る**
2. **コンテナの状態を確認する**
3. **必要なら中に入って最小限の確認をする**

この流れができると、開発速度も安全性もかなり上がります。

Docker の公式ドキュメントでも、再現性のあるイメージ構築・適切な設定分離・秘密情報をイメージへ埋め込まないこと・最小権限と明示的な観察性が重要です。つまり、**「まず観察、次に修正」** が基本です。

---

# 3) Core Docker command explanations

## `docker ps`
起動中のコンテナ一覧を表示します。

```bash
docker ps
```

よく見る列:
- `CONTAINER ID`: コンテナ識別子
- `IMAGE`: どのイメージから作られたか
- `STATUS`: 起動中か、何秒前に落ちたか
- `PORTS`: 公開ポート
- `NAMES`: コンテナ名

停止済みも見たい場合:

```bash
docker ps -a
```

---

## `docker logs`
コンテナ標準出力・標準エラー出力を確認します。

```bash
docker logs <container>
```

よく使う形:

```bash
docker logs --tail 100 <container>
docker logs -f <container>
docker logs --since 10m <container>
```

ポイント:
- `--tail 100`: 直近 100 行だけ見る
- `-f`: ログを追いかける
- `--since 10m`: 直近 10 分だけ見る

**実務ではまず `--tail` を付ける**のが安全です。大量ログで見失いにくくなります。

---

## `docker exec`
起動中コンテナの中でコマンドを実行します。

```bash
docker exec <container> <command>
```

対話シェルの例:

```bash
docker exec -it <container> sh
```

bash がある場合:

```bash
docker exec -it <container> bash
```

よくある用途:
- 設定ファイル確認
- 環境変数確認
- アプリのプロセス確認
- 一時的なネットワーク疎通確認

ただし重要なのは、**`docker exec` での修正は永続化されないことが多い**という点です。中で手修正しても、再作成すると消えます。調査には使う、恒久対応は Dockerfile / Compose / アプリ設定へ戻す、が原則です。

---

## `docker inspect`
コンテナやイメージの詳細 JSON を見ます。

```bash
docker inspect <container>
```

特に見る場所:
- IP / ネットワーク
- マウントされたボリューム
- 環境変数
- 起動コマンド
- ヘルスチェック状態

ヘルス状態だけ絞る例:

```bash
docker inspect --format '{{json .State.Health}}' <container>
```

---

## `docker compose logs`
Compose 管理の複数サービスのログをまとめて見ます。

```bash
docker compose logs
```

特定サービスだけ:

```bash
docker compose logs web
docker compose logs -f api db
```

マルチサービス構成では、`docker logs` より `docker compose logs` のほうが文脈を追いやすいです。

---

# 4) How Docker is used while building apps

実際のアプリ開発では、Docker は「配布用箱」ではなく、**開発・テスト・依存関係分離・再現性の担保**に使います。

Docker 公式のベストプラクティスに沿うと、次の考え方が重要です。

## 4-1. アプリはログを stdout/stderr に出す
`docker logs` で見えるように、アプリログはファイル固定ではなく標準出力へ出す設計が扱いやすいです。

## 4-2. 設定はイメージに焼かず外から注入する
- 環境別設定は environment / env file / secret 管理で分ける
- API キーやパスワードを Dockerfile に書かない
- `.env` をそのままイメージへ `COPY` しない

## 4-3. デバッグのために本番イメージを汚しすぎない
本番用イメージへ不要なツールを大量に入れると、サイズも攻撃面も増えます。必要最小限を基本にし、開発時だけ別の方法で観察します。

## 4-4. 手作業の修正ではなく、定義を直す
`docker exec` で直して「動いた」で終わると再現不能になります。

正しい流れ:
- コンテナ内で原因確認
- Dockerfile / Compose / アプリ設定を修正
- 再ビルド / 再起動で再現確認

## 4-5. healthcheck や起動順の考慮
Compose で複数サービスを組むときは、単に `depends_on` を書くだけでは不十分なことがあります。アプリ側のリトライや healthcheck 設計も重要です。

---

# 5) 30-60 minute hands-on mini lab

## ラボ名
**Nginx コンテナを使って「起動確認・ログ確認・コンテナ内調査」を一通りやる**

## 目標
- `docker ps` で状態確認
- `docker logs` でアクセスログ確認
- `docker exec` でコンテナ内のファイル確認
- `docker inspect` で設定情報確認
- 変更はコンテナ内に閉じず、ホスト側ファイルで管理する感覚をつかむ

## 所要時間
30〜45 分

## 手順

### Step 1. 作業ディレクトリを作る

```bash
mkdir -p ~/docker-labs/nginx-observe
cd ~/docker-labs/nginx-observe
```

### Step 2. 簡単な HTML を用意する

```bash
cat > index.html <<'EOF'
<!doctype html>
<html lang="ja">
  <head>
    <meta charset="utf-8">
    <title>Docker Observe Lab</title>
  </head>
  <body>
    <h1>Hello from Docker Lab</h1>
    <p>logs と exec の練習用ページです。</p>
  </body>
</html>
EOF
```

### Step 3. Nginx コンテナを起動する

```bash
docker run -d \
  --name nginx-observe-lab \
  -p 8080:80 \
  -v "$PWD/index.html:/usr/share/nginx/html/index.html:ro" \
  nginx:stable
```

ポイント:
- `-d`: バックグラウンド起動
- `--name`: 名前を付ける
- `-p 8080:80`: ホスト 8080 → コンテナ 80
- `-v ...:ro`: 読み取り専用でファイルをマウント

### Step 4. 状態確認

```bash
docker ps
```

ブラウザまたは curl でアクセス:

```bash
curl http://localhost:8080
```

### Step 5. ログを見る

```bash
docker logs --tail 50 nginx-observe-lab
```

その後、別ターミナルで追跡:

```bash
docker logs -f nginx-observe-lab
```

アクセスを数回発生させる:

```bash
curl http://localhost:8080
curl http://localhost:8080 >/dev/null
```

アクセスログが増えるのを確認します。

### Step 6. コンテナ内を確認する

```bash
docker exec -it nginx-observe-lab sh
```

中で実行:

```sh
pwd
ls -l /usr/share/nginx/html
cat /usr/share/nginx/html/index.html
ps aux
exit
```

### Step 7. 設定情報を確認する

```bash
docker inspect nginx-observe-lab
```

見たいところを絞る例:

```bash
docker inspect --format '{{json .Mounts}}' nginx-observe-lab
docker inspect --format '{{json .Config.ExposedPorts}}' nginx-observe-lab
docker inspect --format '{{.State.Status}}' nginx-observe-lab
```

### Step 8. ホスト側ファイルを編集して反映を確認する

`index.html` をホストで編集し、内容を変更します。

例:

```bash
sed -i 's/Hello from Docker Lab/Hello again from host file/' index.html
```

再アクセス:

```bash
curl http://localhost:8080
```

**学び:** コンテナ内で直すより、ホスト側・定義側を直したほうが再現性が高い。

### Step 9. 後片付け

```bash
docker stop nginx-observe-lab
docker rm nginx-observe-lab
```

**注意:** `docker rm -f nginx-observe-lab` は強制削除です。通常は `stop` → `rm` の順で安全に実施してください。

---

# 6) Command cheatsheet

```bash
# 起動中コンテナ一覧
docker ps

# 停止済みも含む
docker ps -a

# ログ確認
docker logs <container>
docker logs --tail 100 <container>
docker logs -f <container>
docker logs --since 10m <container>

# コンテナ内でコマンド実行
docker exec <container> <command>
docker exec -it <container> sh
docker exec -it <container> bash

# 詳細情報
docker inspect <container>
docker inspect --format '{{.State.Status}}' <container>

# Compose ログ
docker compose logs
docker compose logs -f
docker compose logs web db

# 安全な停止と削除
docker stop <container>
docker rm <container>
```

---

# 7) Common mistakes and safe practices

## よくあるミス 1: いきなり `exec` で手修正する
**問題:** 再作成で消える、手順が残らない。

**安全策:**
- 調査だけ `exec`
- 恒久対応は Dockerfile / Compose / ソース修正

## よくあるミス 2: ログではなく「勘」で再起動する
**問題:** 原因を見失う。

**安全策:**
- まず `docker logs --tail 100`
- 直近変更と時刻を突き合わせる

## よくあるミス 3: 秘密情報をイメージに埋め込む
**問題:** 履歴やレジストリ経由で漏えいしやすい。

**安全策:**
- Dockerfile に秘密を書かない
- `ENV SUPER_SECRET=...` のような固定記述を避ける
- Compose や secret 管理、環境注入を使う
- `.env` を無造作に `COPY` しない

## よくあるミス 4: 破壊的クリーンアップを雑に使う
以下は便利ですが、影響範囲を理解せずに使うと事故りやすいです。

```bash
docker system prune
docker image prune -a
docker rm -f <container>
docker rmi <image>
```

**警告:**
- 未使用ネットワーク・停止済みコンテナ・ビルドキャッシュ・未使用イメージを消すことがある
- 他の開発作業に必要なキャッシュやイメージまで消すことがある

**安全策:**
- まず `docker ps -a` と `docker images` を確認
- 何を消すか個別に把握してから実行
- チーム環境・共有ホストでは特に慎重に

## よくあるミス 5: root 前提で触る
**問題:** 権限や所有者のズレ、不要なリスクが増える。

**安全策:**
- 可能なら非 root ユーザー設計を検討
- ボリューム権限と UID/GID を意識する

---

# 8) One interview-style question

**質問:**
`docker exec` でコンテナ内の設定を書き換えて問題が解決しました。なぜそのまま本番対応完了にしてはいけないのでしょうか？ また、正しい修正先はどこですか？

**考えるポイント:**
- 再現性
- イメージ再作成時の消失
- Infrastructure as Code
- Dockerfile / Compose / アプリ設定への反映

---

# 9) Next-step resources

まずは公式ドキュメント優先で進めるのが堅いです。

- Docker Get Started  
  https://docs.docker.com/get-started/

- `docker exec` リファレンス  
  https://docs.docker.com/reference/cli/docker/container/exec/

- `docker logs` リファレンス  
  https://docs.docker.com/reference/cli/docker/container/logs/

- `docker inspect` リファレンス  
  https://docs.docker.com/reference/cli/docker/inspect/

- Docker Compose overview  
  https://docs.docker.com/compose/

- Dockerfile best practices  
  https://docs.docker.com/develop/develop-images/dockerfile_best-practices/

- Build best practices / image construction guidance  
  https://docs.docker.com/build/building/best-practices/

- Secrets の考え方  
  https://docs.docker.com/engine/swarm/secrets/

---

# まとめ

今日の要点はシンプルです。

- **まず `docker ps` で状態を見る**
- **次に `docker logs` で事実を見る**
- **必要なら `docker exec` で最小限の調査をする**
- **直す場所はコンテナ内ではなく定義側**

この流れが身につくと、Docker は「なんとなく動かすもの」から、**安全に観察して確実に直せる開発基盤**になります。
