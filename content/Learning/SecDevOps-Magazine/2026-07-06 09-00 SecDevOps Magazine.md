---
tags:
  - security
  - devops
  - docker
  - kubernetes
  - terraform
  - linux
  - cloudsecurity
  - observability
  - daily
---

[[Home]]

# SecDevOps Magazine — 2026-07-06

**Issue:** 2  
**Topic:** Docker Hardening  
**Level:** Middle  
**Prerequisites:** Dockerの基本操作（build / run / exec / logs）、Linuxの権限モデル（user / group / chmod）、コンテナとイメージの違いを理解していること

## 1) Topic + Level
**Docker Hardening / Middle**

Dockerは便利ですが、雑に使うと「とりあえず動く」代わりに、権限過多・秘密情報の混入・脆弱なベースイメージ・危険なruntime設定がそのまま本番に流れます。今日は**“コンテナを安全に動かすための現実的な防御ライン”**に集中します。

## 2) Why it matters in real projects
実務では、アプリの脆弱性そのものより先に、**コンテナの設定ミス**が事故の入口になることが珍しくありません。

たとえば:
- `root` で動くコンテナから予期しない権限利用が起きる
- イメージに `.env` や秘密鍵を焼き込んでしまう
- `latest` タグ依存で再現性が崩れ、CI/CDやロールバックが不安定になる
- 不要なpackageを入れすぎて攻撃面が広がる
- `--privileged` や広すぎるvolume mountで、ホスト側まで危険になる

つまりDocker hardeningは、**セキュリティだけでなく、運用安定性・再現性・監査性**にも直結します。

## 3) Core concepts

### A. rootで動かさない
コンテナ内の `root` はホストの `root` と完全一致ではないものの、危険な設定やkernel脆弱性と組み合わさると被害が大きくなります。基本方針は:
- `USER appuser` を使う
- 書き込み先を限定する
- 必要最小限のcapabilityだけにする

### B. 最小ベースイメージを使う
`ubuntu:latest` に何でも入れるより、用途に合った軽量イメージを使う方が安全です。
例:
- `nginx:alpine`
- `python:3.12-slim`
- distroless系（より上級）

パッケージ数が少ないほど、**脆弱性の混入余地**も減ります。

### C. build contextを絞る
`COPY . .` は便利ですが危険です。`.git/`、`.env`、秘密鍵、テストデータ、不要なscriptまで入ることがあります。`.dockerignore` で明示的に除外しましょう。

### D. イメージの再現性を上げる
- `latest` を避ける
- versionを固定する
- lock fileを使う
- build手順を単純化する

これで「昨日は動いたのに今日は壊れた」を減らせます。

### E. runtime権限を減らす
代表例:
- `--read-only`
- `--cap-drop ALL`
- `--security-opt no-new-privileges`
- 必要なportだけ公開
- 必要なdirectoryだけmount

**動く最小権限**を探るのがhardeningの基本です。

### F. secretをイメージに埋め込まない
`ENV API_KEY=...` や `COPY .env /app/.env` は避けるべきです。secretは:
- runtimeで注入する
- secret managerを使う
- CI側のsecret storeで管理する

### G. スキャンは“最後にやるもの”ではない
イメージスキャンは大事ですが、**Dockerfile設計が悪いと毎回大量アラート**になります。まずは設計を整え、そのうえでTrivy等のスキャンを回す方が効果的です。

## 4) Hands-on mini lab (30-60 min)
**目標:** 危ないDockerfileを、より安全な形へ改善する

### Step 1: 作業ディレクトリ作成
```bash
mkdir -p ~/lab/docker-hardening && cd ~/lab/docker-hardening
```

### Step 2: 危ないサンプルを作る
`app.py`
```python
from flask import Flask
app = Flask(__name__)

@app.route('/')
def hello():
    return 'hello from hardened docker lab\n'

app.run(host='0.0.0.0', port=5000)
```

`requirements.txt`
```txt
flask==3.0.3
```

`Dockerfile.insecure`
```Dockerfile
FROM python:3.12
WORKDIR /app
COPY . .
RUN pip install -r requirements.txt
ENV APP_ENV=prod
EXPOSE 5000
CMD ["python", "app.py"]
```

### Step 3: 改善版を作る
`Dockerfile`
```Dockerfile
FROM python:3.12-slim

WORKDIR /app

RUN groupadd -r appgroup && useradd -r -g appgroup appuser

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

RUN chown -R appuser:appgroup /app
USER appuser

EXPOSE 5000
CMD ["python", "app.py"]
```

`.dockerignore`
```gitignore
.git
.env
*.pem
*.key
__pycache__/
```

### Step 4: buildして確認
```bash
docker build -t flask-hardening-demo .
```

### Step 5: 実行時オプションを絞る
```bash
docker run --rm -p 5000:5000 \
  --read-only \
  --tmpfs /tmp \
  --security-opt no-new-privileges \
  --cap-drop ALL \
  flask-hardening-demo
```

### Step 6: ユーザー確認
別ターミナルで:
```bash
docker ps
docker exec -it <container_id> id
```
`uid=0(root)` ではなく、`appuser` で動いていればOKです。

### Step 7: 振り返り
以下を自分の言葉で説明できれば今日のlabは成功です。
- なぜ `COPY . .` を減らしたのか
- なぜ `USER` を追加したのか
- なぜ `--cap-drop ALL` が有効なのか
- なぜ `.dockerignore` が重要なのか

## 5) Command cheatsheet

### Docker build / inspect
```bash
docker build -t myapp:1.0 .
docker images
docker history myapp:1.0
docker inspect myapp:1.0
```

### Container run hardening
```bash
docker run --rm myapp:1.0
docker run --read-only --tmpfs /tmp myapp:1.0
docker run --cap-drop ALL --security-opt no-new-privileges myapp:1.0
docker run -u 10001:10001 myapp:1.0
```

### Runtime observation
```bash
docker ps
docker logs <container_id>
docker exec -it <container_id> sh
docker exec -it <container_id> id
```

### Linux permission check
```bash
id
whoami
ls -l
chmod 600 secret.txt
chown appuser:appgroup /app
```

### Vulnerability scanning (if installed)
```bash
trivy image myapp:1.0
```

## 6) Common mistakes and how to avoid them

### ミス1: `COPY . .` を何も考えず使う
**回避:** 先に `requirements.txt` など必要ファイルだけcopy。`.dockerignore` を必ず置く。

### ミス2: `root` のまま本番投入
**回避:** Dockerfileで専用userを作る。`USER` を最後に設定する。

### ミス3: `latest` タグ依存
**回避:** `python:3.12-slim` のようにversionを固定。CIでも同じtagを使う。

### ミス4: secretをbuildに混ぜる
**回避:** `.env` や鍵ファイルはimageに入れない。runtime注入に分離する。

### ミス5: `--privileged` を安易に使う
**回避:** 本当に必要なcapabilityだけを追加。基本は `cap-drop ALL` から考える。

### ミス6: “scanしてるから安全”と思う
**回避:** scannerは補助輪。まずDockerfileとruntime設定を正す。

## 7) One interview-style question
**質問:** もし本番コンテナが `root` で動いていて、さらにhost directoryを広くmountしていたら、どんなリスクがありますか？ また、そのリスクを減らすためにDockerfileとruntime設定をどう見直しますか？

## 8) Next-step reading links
- Docker docs — Engine security: https://docs.docker.com/engine/security/
- Docker docs — Build best practices: https://docs.docker.com/build/building/best-practices/
- OWASP Docker Security Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html
- Trivy: https://trivy.dev/latest/
- CIS Docker Benchmark overview: https://www.cisecurity.org/benchmark/docker

---

## 学習アークメモ
- 前回: **Secure Coding / Beginner**
- 今回: **Docker Hardening / Middle**
- 次回候補: **Cloud Security (IAM & permission design) / Advanced**

Middleに入ると、単なるコマンド暗記では足りません。**「どの設定がどの攻撃面を減らすのか」** を説明できるようになると、実務で一気に強くなります。今日は“安全に動かす設計感覚”を1つ持ち帰れば十分です。