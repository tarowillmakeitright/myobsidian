---
tags:
  - docker
  - containers
  - devops
  - learning
  - daily
---

[[Home]]

# Docker Commands Magazine — 2026-07-03

## 今号の位置づけ
- **Learning Arc 1**
- **Level: Beginner**
- **テーマ:** `docker run` と `docker ps` で「コンテナを安全に起動して観察する」

> 次の流れ: Beginner → Middle → Advanced の順で進みます。Middle 以降は前号の理解を前提に、徐々にネットワーク・ボリューム・イメージ最適化・Compose・デバッグへ広げていきます。

---

## 1) Topic + Level
**Topic:** `docker run` / `docker ps` / `docker logs` / `docker stop` の基本
**Level:** Beginner
**対象:** Docker を触り始めた開発者、ローカル開発環境を整えたい人
**前提知識:**
- Beginner なので必須前提はなし
- あると楽: Linux/macOS ターミナルの基本操作、HTTP の超基礎

**Middle に進むための前提（予告）**
- `docker run` でポート公開できる
- 起動中コンテナを `docker ps` で確認できる
- `docker logs` と `docker exec` の役割が分かる

**Advanced に進むための前提（予告）**
- イメージとコンテナの違いを説明できる
- ボリューム、ネットワーク、Dockerfile、Compose の基本を触ったことがある

---

## 2) なぜ実アプリ開発で重要か
Docker は「自分のマシンでは動くのに、他人の環境では動かない」を減らすための土台です。実アプリ開発では特に次の場面で効きます。

- **開発環境の再現性**: Node.js、Python、Postgres、Redis などの依存を揃えやすい
- **オンボーディング短縮**: 新メンバーが環境構築に何時間も溶かしにくい
- **CI/CD と整合**: ローカルで使うコンテナの感覚が、そのままビルドやテスト自動化につながる
- **安全な分離**: ホストに直接いろいろ入れず、コンテナ内で試せる
- **マイクロサービス開発**: API、DB、キューを分けて扱いやすい

Docker を「ただの便利コマンド集」として覚えるより、**開発・検証・運用の再現性を上げる道具**として捉えると実務で強いです。

---

## 3) コア Docker コマンド解説

### `docker run`
イメージからコンテナを作って起動します。

```bash
docker run hello-world
```

これは最小の確認用。イメージがローカルに無ければ取得し、コンテナを起動してメッセージを表示します。

よく使うオプション:

```bash
docker run --name webtest -d -p 8080:80 nginx:alpine
```

- `--name webtest`: コンテナに覚えやすい名前を付ける
- `-d`: バックグラウンド実行
- `-p 8080:80`: ホストの 8080 番をコンテナの 80 番に転送
- `nginx:alpine`: 起動するイメージとタグ

### `docker ps`
起動中コンテナを一覧表示します。

```bash
docker ps
```

停止済みも含めて見たいなら:

```bash
docker ps -a
```

### `docker logs`
コンテナ標準出力・標準エラーを確認します。

```bash
docker logs webtest
```

追従表示:

```bash
docker logs -f webtest
```

### `docker stop`
コンテナを安全に停止します。

```bash
docker stop webtest
```

### `docker rm`
停止済みコンテナを削除します。

```bash
docker rm webtest
```

> **注意:** `docker rm -f` は強制停止を伴うため、作業中の検証や未保存データが失われる可能性があります。必要性を理解したうえで使ってください。

### `docker exec`
起動中コンテナの中でコマンドを実行します。

```bash
docker exec -it webtest sh
```

デバッグ時によく使います。`bash` が入っていない軽量イメージも多いので、`sh` の方が通りやすいです。

---

## 4) アプリ構築時に Docker をどう使うか
Docker 公式ドキュメントの考え方に沿うと、ローカル開発でも以下が重要です。

### 4-1. 1コンテナ1責務を意識する
Web アプリ、DB、キャッシュを無理に 1 つへ詰め込まず、役割ごとに分けるほうが保守しやすいです。

### 4-2. イメージは軽く、再現可能に
- 必要なものだけ入れる
- できるだけ公式イメージや信頼できるベースを使う
- タグを明示し、挙動のブレを減らす

例:
- `nginx:alpine`
- `node:22-alpine`

### 4-3. 秘密情報をイメージへ焼き込まない
- `Dockerfile` に API キーやパスワードを書かない
- `compose.yaml` や `.env` の扱いも慎重にする
- Git に秘密情報を入れない

**避けたい例:**
```Dockerfile
ENV DATABASE_PASSWORD=supersecret
```

これはイメージ履歴や設定から漏れる危険があります。

### 4-4. 永続化が必要なデータはボリュームで扱う
DB データなどをコンテナの中だけに置くと、削除時に消えます。永続化が必要なものはボリュームや bind mount を使います。これは Middle 以降で詳しく扱います。

### 4-5. 破壊的な掃除コマンドは理解してから
たとえば以下は便利ですが、消える範囲を理解してから。

```bash
docker system prune
```

> **警告:** 未使用コンテナ・ネットワークなどを削除します。`-a` を付けると未使用イメージまで対象になり影響が大きいです。

```bash
docker image prune
```

> **警告:** 未使用イメージを削除します。ビルドキャッシュや再取得コストも考えましょう。

---

## 5) 30–60分ハンズオン・ミニラボ
**ラボ名:** Nginx コンテナを起動して、観察して、停止して片付ける
**所要時間:** 30〜45分

### ゴール
- Nginx コンテナを起動できる
- ブラウザまたは curl で動作確認できる
- ログ確認、コンテナ内部確認、停止・削除まで一通りできる

### 手順

#### Step 1: 動作確認用イメージを起動
```bash
docker run --name webtest -d -p 8080:80 nginx:alpine
```

#### Step 2: 起動確認
```bash
docker ps
```

確認ポイント:
- `STATUS` が `Up` になっているか
- `PORTS` に `0.0.0.0:8080->80/tcp` のような表示があるか

#### Step 3: ブラウザまたは curl でアクセス
```bash
curl http://localhost:8080
```

Nginx の HTML が返れば OK。

#### Step 4: ログを見る
```bash
docker logs webtest
```

その後もう一度 `curl` してアクセスログが出るか見ます。

#### Step 5: コンテナ内部に入る
```bash
docker exec -it webtest sh
```

中で以下を試す:
```sh
ls /usr/share/nginx/html
cat /etc/nginx/nginx.conf | head
exit
```

#### Step 6: 停止する
```bash
docker stop webtest
```

#### Step 7: 削除する
```bash
docker rm webtest
```

### 発展課題
- `-p 8081:80` に変えて別ポートで起動してみる
- `docker ps -a` で停止済みの見え方を確認する
- `--name` を変えて複数起動し、ポート競合を体験する

### 学びどころ
- イメージは設計図、コンテナは実行中インスタンス
- ポート公開が無いと、ホストから簡単に触れない
- ログと `exec` は初期デバッグの基本動線

---

## 6) コマンド・チートシート

### まず覚えるセット
```bash
docker run hello-world
docker run --name webtest -d -p 8080:80 nginx:alpine
docker ps
docker ps -a
docker logs webtest
docker logs -f webtest
docker exec -it webtest sh
docker stop webtest
docker rm webtest
```

### 状況確認系
```bash
docker images
docker inspect webtest
```

### 注意して使う掃除系
```bash
docker system prune
docker image prune
docker container prune
```

> **警告:** `prune` 系は未使用リソースをまとめて消します。実行前に「何が消えるか」を把握してください。

---

## 7) よくあるミスと安全な実践

### ミス1: イメージとコンテナを混同する
- **誤解:** コンテナを消したらイメージも消える
- **実際:** 別物です。コンテナ削除後もイメージは残ることが多い

### ミス2: ポート公開を忘れる
- **症状:** `curl localhost:8080` でつながらない
- **確認:** `docker ps` の `PORTS` 列
- **対策:** `-p ホスト側:コンテナ側` を明示

### ミス3: 強制削除を雑に使う
- `docker rm -f`
- `docker rmi -f`
- `docker system prune -a`

これらは便利ですが、影響が大きいです。

**安全策:**
- まず `docker ps -a` や `docker images` で確認
- 開発中の DB データや再利用したいイメージが無いか考える
- 共有環境・作業中環境では特に慎重に

### ミス4: 秘密情報を Dockerfile や Compose へ直書きする
**危険:** イメージ履歴・Git 管理・ログから漏れる可能性

**安全策:**
- シークレット管理機構を使う
- ローカル `.env` を使う場合も Git へ入れない
- 本番運用では Docker/オーケストレータ側の secrets 機構を検討

### ミス5: root 前提で考える
コンテナ内で root のまま動かす例は多いですが、実務では最小権限が大事です。これは Advanced で深掘り予定。

---

## 8) 面接風クエスチョン
**質問:**
`docker run -d -p 8080:80 --name webtest nginx:alpine` というコマンドを、各オプションの意味まで含めて説明してください。また、アプリにアクセスできないとき最初に何を確認しますか？

**考えるポイント:**
- `-d`, `-p`, `--name`, イメージ名の意味
- `docker ps` の見方
- ポート公開、ログ、コンテナ状態の確認順

---

## 9) 次の一歩リソース
**公式 Docker Docs 優先**

- Docker Get Started
  - https://docs.docker.com/get-started/
- Docker CLI reference (`docker run`)
  - https://docs.docker.com/reference/cli/docker/container/run/
- Docker CLI reference (`docker ps`)
  - https://docs.docker.com/reference/cli/docker/container/ls/
- Docker CLI reference (`docker logs`)
  - https://docs.docker.com/reference/cli/docker/container/logs/
- Dockerfile best practices
  - https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Build best practices
  - https://docs.docker.com/build/building/best-practices/

### 次号予告
**Arc 1 / Middle:** `docker exec`・`docker cp`・ボリューム入門で「コンテナの中を安全に調べ、データを持続化する」

---

## まとめ
今日の焦点は「**起動する・見る・止める**」です。Docker 学習の最初の壁は、コマンド暗記ではなく、**イメージとコンテナの関係を実感すること**。まずは `docker run` → `docker ps` → `docker logs` → `docker stop` の流れを手で覚えると、その先の Compose や CI/CD もかなり入りやすくなります。
