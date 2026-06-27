---
tags:
  - docker
  - containers
  - devops
  - learning
  - daily
---

[[Home]]

# Docker Commands Magazine — 2026-06-27 09:20

## 今日のテーマ + Level
**Topic:** `docker build` / `docker compose up` / `docker exec` でローカル開発環境を組み立てる
**Level:** Middle

### 前提知識
- Beginner レベルの内容として、`docker run` / `docker ps` / `docker logs` の基本がわかる
- イメージとコンテナの違いをざっくり説明できる
- `-p` でポート公開し、ブラウザや `curl` で確認したことがある

---

## 1) なぜ実アプリ開発で重要なのか
アプリ開発では、コードそのものよりも**「動作環境の差」**でハマることが多いです。

たとえば:
- 自分のPCでは動くのに、他の開発者の環境では動かない
- Node/Python/Postgres のバージョン差で不具合が出る
- 開発サーバー、DB、キャッシュを毎回手動で立ち上げるのが面倒

ここで Docker を使うと、
- **Dockerfile** でアプリ実行環境をコード化できる
- **Compose** で複数サービス（app/db など）をまとめて起動できる
- **exec** で動いているコンテナの中を確認しながらデバッグできる

つまり今日のコマンド群は、**「アプリを再現可能な形で作り、動かし、調べる」**ための中心です。

---

## 2) コア Docker コマンド解説

### A. `docker build`
Dockerfile からイメージを作るコマンドです。

```bash
docker build -t hello-web:dev .
```

#### 何をしているか
- `.` : 現在ディレクトリを build context として使う
- `-t hello-web:dev` : イメージ名とタグを付ける

#### 実務ポイント
- イメージを毎回同じ手順で作れる
- CI でも同じ build 手順を再利用できる
- Dockerfile の書き方次第で build が速くも遅くもなる

#### 注意
- build context に不要ファイルを含めると遅くなる
- `.env` や秘密鍵を context に入れるのは危険
- `COPY . .` を雑に使うと secrets や巨大ファイルを巻き込みやすい

---

### B. `docker compose up`
複数コンテナをまとめて起動します。

```bash
docker compose up -d
```

#### 何をしているか
- `compose.yaml` の定義を読む
- app, db など必要なサービスをまとめて起動する
- `-d` はバックグラウンド実行

#### 実務ポイント
- 開発チーム全員が同じサービス構成を使える
- `app + db + redis` のような構成が簡単に再現できる
- ローカル検証、統合テスト、レビュー環境の土台になりやすい

#### 注意
- secrets を compose ファイルに直書きしない
- 本番向けの設定をそのままローカルに持ち込まない
- bind mount のしすぎで権限やパフォーマンス問題が出ることがある

---

### C. `docker exec`
起動中コンテナの中でコマンドを実行します。

```bash
docker exec -it hello-app sh
```

#### 何をしているか
- `hello-app` コンテナの中でシェルを開く
- ログだけでは見えない内部状態を確認できる

#### 実務ポイント
- 設定ファイル確認
- 環境変数の確認
- アプリ内で `ls`, `cat`, `ps`, `env` などを実行して原因切り分け

#### 注意
- コンテナの中で手作業変更しても再作成で消える
- 直した気になる「その場しのぎ」になりやすい
- 恒久対応は Dockerfile や compose 設定に戻して反映する

---

## 3) アプリ開発での Docker の使い方
Docker の公式ドキュメントの考え方に沿うと、開発中は次の流れがかなり実務的です。

### 1. Dockerfile でアプリの実行環境を定義する
例:
- ベースイメージを明示する
- 作業ディレクトリを決める
- 依存関係をインストールする
- アプリ起動コマンドを定義する

### 2. 依存ファイルを先にコピーしてキャッシュを活用する
たとえば Node なら、ソース全部を先に `COPY` するより、
- `package*.json` を先にコピー
- `npm install`
- その後にアプリ本体をコピー

という順番が build 高速化に効きます。

### 3. `.dockerignore` を必ず使う
除外候補:
- `node_modules`
- `.git`
- `.env`
- `dist`
- 一時ファイル

不要ファイルを context に入れないのが、速さと安全性の両方に効きます。

### 4. 1コンテナ1責務を意識する
- app コンテナ
- db コンテナ
- redis コンテナ

のように分けるほうが、管理・再利用・障害切り分けがしやすいです。

### 5. secrets をイメージに焼き込まない
やってはいけない例:
- Dockerfile に API キーを `ENV` で直書き
- `.env` をそのまま `COPY`
- compose に本番パスワードをベタ書き

安全寄りの考え方:
- 開発用はローカル環境変数や安全な env ファイル管理を使う
- 本番 secrets は専用の secret 管理機構を使う
- 「イメージを見られたら秘密も見える」前提で考える

---

## 4) 30〜60分ミニラボ
**ラボ名:** Python の小さな Web アプリを Dockerfile + Compose で起動して中を調べる

### ゴール
- `docker build` を使ってイメージ作成
- `docker compose up` でアプリ起動
- `docker exec` でコンテナ内部確認
- Dockerfile のキャッシュしやすい書き方を体験

### 所要時間
約40〜50分

### 作業用フォルダを作る
```bash
mkdir -p ~/tmp/docker-middle-lab
cd ~/tmp/docker-middle-lab
```

### 1. `app.py` を作る
```python
from flask import Flask
app = Flask(__name__)

@app.route("/")
def home():
    return "hello from docker middle lab\n"
```

### 2. `requirements.txt` を作る
```txt
flask==3.0.3
```

### 3. `Dockerfile` を作る
```Dockerfile
FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

EXPOSE 5000
CMD ["flask", "--app", "app", "run", "--host=0.0.0.0", "--port=5000"]
```

### 4. `.dockerignore` を作る
```gitignore
.git
__pycache__
.env
*.pyc
```

### 5. `compose.yaml` を作る
```yaml
services:
  web:
    build: .
    container_name: hello-app
    ports:
      - "5000:5000"
```

### 6. build する
```bash
docker build -t hello-web:dev .
```

確認ポイント:
- `COPY requirements.txt .` のあとに `RUN pip install ...` がある
- `app.py` だけ変えた場合、依存インストール層が再利用されやすい

### 7. Compose で起動する
```bash
docker compose up -d
```

確認:
```bash
docker ps
curl http://localhost:5000
```

期待結果:
```text
hello from docker middle lab
```

### 8. コンテナ内部に入る
```bash
docker exec -it hello-app sh
```

中で実行:
```sh
pwd
ls -la
env | sort | head
cat /app/app.py
exit
```

### 9. アプリを少し変えて再 build する
`app.py` の返り値を変更:
```python
return "hello again from rebuilt container\n"
```

再 build / 再起動:
```bash
docker compose up -d --build
curl http://localhost:5000
```

### 10. 後片付け
まず停止:
```bash
docker compose down
```

**注意:** 以下は削除を伴います。必要なコンテナやイメージがないことを確認してから実行してください。

イメージ削除まで行う場合:
```bash
docker rmi hello-web:dev
```

---

## 5) コマンド cheatsheet
```bash
# Dockerfile からイメージ作成
docker build -t hello-web:dev .

# Compose で起動
docker compose up -d

# build し直して起動
docker compose up -d --build

# 起動中コンテナ確認
docker ps

# ログ確認
docker compose logs -f

# コンテナ内でシェル起動
docker exec -it hello-app sh

# Compose 停止と削除
docker compose down

# イメージ一覧
docker images

# 注意して使う: イメージ削除
docker rmi hello-web:dev
```

---

## 6) よくあるミスと安全策

### ミス1: `COPY . .` で全部入れてしまう
**問題:** `.env` や不要ファイル、巨大ディレクトリまでイメージや build context に入りやすい。

**安全策:**
- `.dockerignore` を置く
- 先に依存ファイルだけコピーする
- 必要最小限のファイルだけ `COPY` する

### ミス2: secrets を Dockerfile / Compose に直書きする
**問題:** イメージ履歴や設定ファイルから漏れる。

**安全策:**
- API キーやパスワードをイメージに焼き込まない
- チーム共有ファイルに本番 secrets を置かない
- 開発用でも取り扱いを雑にしない

### ミス3: `exec` で手修正して満足する
**問題:** コンテナ再作成で消えるので再現性がない。

**安全策:**
- 原因調査には `exec`
- 修正は Dockerfile / compose / アプリコードに戻す

### ミス4: コンテナ名やポートを曖昧にする
**問題:** どのサービスを見ているか分からなくなる。

**安全策:**
- サービス名を意味のあるものにする
- `docker ps` と `docker compose logs` をセットで見る

### ミス5: 削除系コマンドを勢いで打つ
**問題:** 開発中の資産まで消える。

**特に注意が必要なコマンド:**
- `docker system prune`
- `docker image prune -a`
- `docker container rm -f ...`
- `docker rmi ...`

**安全策:**
- まず `docker ps -a` / `docker images` で対象確認
- 削除前に「本当に今消してよいか」を確認
- 共用環境では特に慎重に扱う

---

## 7) 面接っぽい質問
**質問:**
`docker build` でキャッシュを効かせるために、`COPY requirements.txt .` を先に行ってから `RUN pip install ...` するのはなぜですか？

**考えるポイント:**
- 変更頻度の低い層を先に作る意味
- アプリコード更新時の再 build 時間
- Docker layer cache の仕組み

---

## 8) 次の一歩リソース
公式中心で、今日の内容からつなげやすいものを並べます。

- Docker Docs — Get started  
  https://docs.docker.com/get-started/

- Docker Docs — Writing a Dockerfile  
  https://docs.docker.com/get-started/docker-concepts/building-images/writing-a-dockerfile/

- Docker Docs — Building images best practices  
  https://docs.docker.com/develop/develop-images/dockerfile_best-practices/

- Docker Docs — Docker Compose overview  
  https://docs.docker.com/compose/

- Docker Docs — Multi-container applications  
  https://docs.docker.com/get-started/docker-concepts/running-containers/multi-container-applications/

- Docker Docs — Bind mounts  
  https://docs.docker.com/engine/storage/bind-mounts/

- Docker Docs — Secrets  
  https://docs.docker.com/engine/swarm/secrets/

---

## 9) 明日の予告
次は **Advanced** として、
**`docker network` / `docker volume` / healthcheck / multi-stage build の実務設計**
に進むと流れがきれいです。

「動かす」から一歩進んで、**壊れにくく・速く・安全に使う Docker** に入っていきます。
