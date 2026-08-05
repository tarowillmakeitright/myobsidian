---
type: weekly-magazine
series: docker
difficulty: Intermediate
focus: "Compose実行時Secretsの最小権限注入と漏えい検証"
week: 2026-W32
prerequisites:
  - Docker EngineまたはDocker Desktop
  - Docker Compose v2
  - Dockerfile・Compose・HTTPの基礎
  - Linuxのファイル権限と環境変数の初歩
estimated_minutes: 150
---

# Weekly Docker Magazine — Compose Secretsを「見える範囲」で設計する

#docker #containers #weekly #deep-dive

[[Home]]

> [!warning] 削除操作と秘密情報
> `docker system prune` / `docker image prune` / `docker rmi` / `docker rm -f` は、別プロジェクトや稼働中サービスの資産を失わせる可能性がある。実行前に必ず対象を一覧・確認し、共有ホストでは安易に使わない。本ラボのcleanupはプロジェクト限定の `docker compose down --remove-orphans` を使う。
>
> APIキー、パスワード、秘密鍵をDockerfile、イメージ、`compose.yaml`、ソース、Git管理下の`.env`へ絶対に埋め込まない。以下の値はローカル教材専用のダミー値であり、実運用のcredentialを使わない。

## 1. Focus、難易度、前提、測定可能な到達点

**本番基準：各サービスへ必要なsecretだけをファイルとして実行時注入し、イメージ・Compose定義・環境変数・ログ・API応答へ値を残さず、欠落・誤権限・ローテーション失敗を証拠から診断できること。**

- Difficulty signal: **Intermediate**（学習の目安であり参加条件ではない）
- 必要知識：イメージとコンテナ、Compose service、HTTP、LinuxのUID/GIDとmode
- 先行概念：`docker compose up/logs/exec/config`、Dockerfile、read-only filesystem、最小権限
- ツール：現行Docker EngineまたはDocker Desktop、Compose v2、`curl`、`grep`、`time`、エディタ
- 環境：Linuxコンテナ、空きRAM 1 GiB程度、`127.0.0.1:8080`が空いていること
- 前号との接続：ネットワーク分離が「誰と通信できるか」を絞るのに対し、今回は「どのプロセスがcredentialを読めるか」を絞る

150分後の合格条件：

1. `api`だけが`/run/secrets/api_key`を読め、`worker`にはsecretが存在しないことを検証する。
2. `docker inspect`、`docker compose config`、`docker history`、ログ、API応答からsecret値が検出されないことをテストする。
3. secret欠落をfail-closedで起動失敗させ、ログとmount情報から原因を切り分ける。
4. 新しいsecretへローテーションし、コンテナ再作成後に旧値が使えないことを確認する。
5. イメージサイズ、起動時間、実行UID、capability、read-only root filesystemを測定して判定表を残す。

## 2. 実アプリのシナリオと制約

社内の配送見積APIは、上流サービスへ接続するAPIキーを必要とする。1台のDockerホスト上で`api`と、credential不要の`worker`が同居する。

- APIキーを必要とするのは`api`のみ。`worker`へは付与しない
- secretはイメージbuild時には不要で、実行時だけ使う
- `/healthz`に値、長さ、先頭文字、ファイルパスを露出させない
- secret欠落時は黙って匿名動作せず、起動を失敗させる
- root filesystemはread-only。一時書込みはsize制限付きtmpfsのみ
- コンテナは非root、全Linux capabilityをdrop、権限昇格を禁止
- 教材ではローカルファイルがsecret source。これは**暗号化されたsecret managerではない**。本番ではホスト上のsource file保護、配布、監査、ローテーションを別途設計する

## 3. コンテナ／runtime mental model

イメージlayerはimmutableな配布物で、`COPY`、`ARG`、`ENV`に入れた値は、後のlayerで削除しても履歴や下位layerに残り得る。一方、Compose runtime secretは対象serviceに明示的にgrantされ、コンテナ内の`/run/secrets/<name>`へファイルとしてmountされる。

重要なのは「secretを使う」ではなく、次の境界を別々に考えること。

1. **source境界**：ホスト上で誰がsource fileを読めるか
2. **grant境界**：どのCompose serviceへsecretを割り当てるか
3. **process境界**：コンテナ内のどのUID/GIDがmount fileを読めるか
4. **lifetime境界**：値の変更がいつ稼働processへ反映されるか
5. **egress境界**：ログ、例外、HTTP応答、telemetryへ値が出ないか

環境変数はprocess環境を継承する子process、debug dump、誤ったログ出力などから露出しやすい。file mountならアプリが必要時にだけ開け、service単位のgrantを明示できる。ただし、侵害された同一コンテナ内の読取可能processから守る万能金庫ではない。

```mermaid
flowchart LR
  O[Operator / Secret manager] -->|0600 source file| S[Host: secrets/api_key.txt]
  S -->|Compose grant| M[/run/secrets/api_key]
  subgraph API container
    M -->|open + read once| A[non-root API process]
    A -->|valueを出さない| H[/healthz]
    A -->|認証判定| Q[/quote]
    T[tmpfs /tmp] --> A
  end
  S -.grantなし.-> W[worker container]
  D[Dockerfile / image layers] -.secretなし.-> A
  C[compose.yaml] -.値なし、source pathのみ.-> S
  A -.再作成が反映境界.-> R[rotation]
```

## 4. 設計代替案と明示的trade-off

| 方法 | 長所 | リスク／採用判断 |
|---|---|---|
| Dockerfile `ENV` / `ARG` | 簡単 | image metadata/layer/build logへ残り得る。secret用途は禁止 |
| Compose `environment` / `.env` | 導入容易 | inspect、process環境、ログへ漏れやすい。非secret設定用 |
| bind mount `:ro` | pathや複数fileを柔軟に扱う | service grantの意図が弱く、host path依存。証明書bundle等には候補 |
| Compose secrets | serviceごとのgrant、`/run/secrets`規約、値をYAMLに書かない | local Composeではsource fileの保護と配布は利用者責任。本ラボの採用案 |
| 外部secret manager + sidecar/agent | 動的credential、監査、集中rotation | 運用複雑性、可用性、bootstrap credentialが増える。本番規模で検討 |
| BuildKit secret mount | build中だけprivate registry等へ認証可能 | runtime secretとは別物。成果物へ値を書き出す処理は禁止 |

rotationは「source fileを上書きすれば全processが即更新」と仮定しない。アプリが起動時に一度読む設計なら、値の更新後に明示的な再作成と旧credentialの失効が必要。zero-downtimeには新旧併用期間、rolling replace、監査が要る。

## 5. Guided lab（約150分）

### 5.1 時間配分

- Foundationと設計：20分
- sample作成・build：35分
- grant/leakage tests：30分
- failure injection・debug：30分
- rotation・計測・review：25分
- optional challenge：10分

### 5.2 作業directoryと完全なsample files

```bash
mkdir -p docker-secret-lab/app docker-secret-lab/secrets
cd docker-secret-lab
umask 077
printf '%s\n' 'lab-key-v1-8f62c1' > secrets/api_key.txt
chmod 600 secrets/api_key.txt
```

`umask 077`は以降の新規fileを所有者以外へ原則非公開にする。`printf`は教材用ダミー値を末尾改行付きで作る。shell historyへ**本物の値を直書きしてはいけない**。本番値はsecret manager等の安全な経路から配置する。

`app/app.py`：

```python
import hashlib
import hmac
import os
import sys
from flask import Flask, jsonify, request

SECRET_PATH = os.environ.get("API_KEY_FILE", "/run/secrets/api_key")

def load_secret(path: str) -> bytes:
    try:
        with open(path, "rb") as handle:
            value = handle.read().strip()
    except OSError as exc:
        print(f"startup_error=secret_unavailable type={type(exc).__name__}", file=sys.stderr)
        raise SystemExit(78) from exc
    if len(value) < 12:
        print("startup_error=secret_invalid reason=too_short", file=sys.stderr)
        raise SystemExit(78)
    return value

API_KEY = load_secret(SECRET_PATH)
KEY_ID = hashlib.sha256(API_KEY).hexdigest()[:8]
app = Flask(__name__)

@app.get("/healthz")
def healthz():
    return jsonify(status="ok", credential="loaded", key_id=KEY_ID)

@app.get("/quote")
def quote():
    supplied = request.headers.get("X-API-Key", "").encode()
    if not hmac.compare_digest(supplied, API_KEY):
        return jsonify(error="unauthorized"), 401
    return jsonify(currency="JPY", amount=1280)
```

`KEY_ID`は生値ではなくrotation確認用の短いSHA-256 fingerprint。それでもcredentialとの相関情報なので、公開APIへ安易に出さず、教材ではlocalhost限定にする。`hmac.compare_digest`は単純な`==`よりtiming差を抑える。例外ログにはpathや値を含めず、欠落の種類だけを出す。exit code 78は設定不備を表す教材上の選択。

`app/worker.py`：

```python
import os
import time

path = "/run/secrets/api_key"
print(f"worker_started secret_visible={os.path.exists(path)}", flush=True)
while True:
    time.sleep(30)
```

`requirements.txt`：

```text
Flask==3.1.1
gunicorn==23.0.0
```

`Dockerfile`：

```dockerfile
# syntax=docker/dockerfile:1
FROM python:3.13-alpine AS runtime

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir --requirement requirements.txt
COPY --chown=10001:10001 app/ ./

USER 10001:10001
EXPOSE 8080
CMD ["gunicorn", "--bind=0.0.0.0:8080", "--workers=1", "--access-logfile=-", "--error-logfile=-", "app:app"]
```

行ごとの意味：

- `# syntax=...`：現行Dockerfile frontendを選ぶ。将来BuildKit mountへ拡張可能
- `FROM`：Python runtimeをbaseにする。実運用は検証済みdigest固定と定期更新も検討
- `WORKDIR`：以降のcopy/runと起動場所を`/app`へ固定
- `COPY requirements.txt`→`RUN pip install`：依存layerをsource変更から分離してcacheを活用
- `--no-cache-dir`：pip download cacheをruntime imageへ残さない
- `COPY --chown=10001:10001`：application fileを実行UIDへ帰属
- `USER 10001:10001`：rootで起動しない。名前ではなく数値UIDでbase image差を避ける
- `EXPOSE`：container portのmetadataでありhost公開やfirewallではない
- exec形式`CMD`：GunicornをPID 1として起動しsignal処理を明確にする

`.dockerignore`：

```text
.git
.env
secrets
**/__pycache__
*.pyc
```

`secrets`をbuild contextから除外することが重要。Compose runtime mountを使っても、contextへ秘密を送る設計では防御が不十分。

`compose.yaml`：

```yaml
name: docker-secret-lab

services:
  api:
    build:
      context: .
    image: docker-secret-lab:local
    ports:
      - "127.0.0.1:8080:8080"
    environment:
      API_KEY_FILE: /run/secrets/api_key
    secrets:
      - api_key
    read_only: true
    tmpfs:
      - /tmp:size=16m,mode=1777
    cap_drop:
      - ALL
    security_opt:
      - no-new-privileges:true
    init: true
    restart: "no"

  worker:
    image: docker-secret-lab:local
    command: ["python", "worker.py"]
    read_only: true
    tmpfs:
      - /tmp:size=8m,mode=1777
    cap_drop:
      - ALL
    security_opt:
      - no-new-privileges:true
    init: true
    restart: "no"

secrets:
  api_key:
    file: ./secrets/api_key.txt
```

行ごとの設計意図：

- `name`：project名を固定し、検査・cleanup対象を判別しやすくする
- `ports`：host全interfaceでなくloopbackだけへ公開
- `environment`：秘密**値ではなくpath**のみを渡す
- service側`secrets`：`api`だけへgrant。`worker`には書かない
- top-level`secrets`：host sourceを定義。値そのものはYAMLに書かない
- `read_only`：container writable layerへの書込みを拒否
- `tmpfs`：一時fileだけをmemory-backed mountへ許可し、sizeを制限
- `cap_drop: ALL`：Linux capabilityを全て落とす。本アプリは追加不要
- `no-new-privileges`：setuid等による権限昇格を禁止
- `init`：signal転送とzombie回収を行う小さなinitをPID 1の前に置く
- `restart: "no"`：設定不備を再起動loopで隠さない。production方針は可用性設計と合わせる

### 5.3 Checkpoint A — 静的検証とbuild（25分）

```bash
docker compose config --quiet
docker compose config > rendered-compose.yaml
grep -R --line-number 'lab-key-v1-8f62c1' Dockerfile compose.yaml app requirements.txt .dockerignore rendered-compose.yaml && echo 'FAIL: leaked' || echo 'PASS: no literal secret'
/usr/bin/time -f 'build_elapsed=%e sec' docker compose build --pull
docker image inspect docker-secret-lab:local --format 'bytes={{.Size}} user={{.Config.User}}'
docker history --no-trunc docker-secret-lab:local | grep 'lab-key-v1-8f62c1' && echo 'FAIL: image leak' || echo 'PASS: image clean'
```

期待出力の要点：

```text
PASS: no literal secret
build_elapsed=<環境依存> sec
bytes=<正の整数> user=10001:10001
PASS: image clean
```

`config --quiet`はCompose modelを検証する。`config`のrender結果にもsecret値はなくsource pathだけであるべき。`--pull`はbase image更新を確認してbuildするが、再現性のため本番releaseでは検証済みdigestも使う。`history --no-trunc`はlayer作成commandにダミー値がないか調べる。

> [!note] 誤検知を理解する
> 上の`grep` command自体をshell scriptとして保存すると、そこに検索対象のダミー値が現れる。検査対象と検査codeを分離すること。本物のsecretをcommand line引数へ載せない。

### 5.4 Checkpoint B — grantとleakageの動的test（30分）

```bash
/usr/bin/time -f 'startup_elapsed=%e sec' docker compose up -d
docker compose ps
curl --fail --silent http://127.0.0.1:8080/healthz
curl --silent --output /dev/null --write-out '%{http_code}\n' http://127.0.0.1:8080/quote
curl --fail --silent -H 'X-API-Key: lab-key-v1-8f62c1' http://127.0.0.1:8080/quote
docker compose exec api sh -c 'id; stat -c "mode=%a uid=%u gid=%g" /run/secrets/api_key; test -r /run/secrets/api_key'
docker compose exec worker sh -c 'test ! -e /run/secrets/api_key && echo PASS:no-secret-grant'
docker inspect docker-secret-lab-api-1 | grep 'lab-key-v1-8f62c1' && echo 'FAIL: inspect leak' || echo 'PASS: inspect clean'
docker compose logs --no-color | grep 'lab-key-v1-8f62c1' && echo 'FAIL: log leak' || echo 'PASS: logs clean'
docker compose exec api sh -c 'touch /should-fail' && echo 'FAIL: rootfs writable' || echo 'PASS: rootfs read-only'
```

期待出力例：

```text
{"credential":"loaded","key_id":"<8桁>","status":"ok"}
401
{"amount":1280,"currency":"JPY"}
uid=10001 gid=10001 groups=10001
PASS:no-secret-grant
PASS: inspect clean
PASS: logs clean
touch: /should-fail: Read-only file system
PASS: rootfs read-only
```

`curl --fail`は4xx/5xxを失敗扱いにする。未認証testではstatus codeだけを記録し、credentialを出さない。認証成功例の`-H`は教材ダミー値限定で、本物ならshell historyやprocess listへ漏らさない安全なtest harnessを使う。`exec worker`はgrantなしを積極的に証明する。

### 5.5 Checkpoint C — rotation（20分）

```bash
OLD_ID=$(curl --fail --silent http://127.0.0.1:8080/healthz | sed -n 's/.*"key_id":"\([0-9a-f]*\)".*/\1/p')
printf '%s\n' 'lab-key-v2-41d9aa' > secrets/api_key.txt
chmod 600 secrets/api_key.txt
docker compose up -d --force-recreate api
NEW_ID=$(curl --fail --silent http://127.0.0.1:8080/healthz | sed -n 's/.*"key_id":"\([0-9a-f]*\)".*/\1/p')
test "$OLD_ID" != "$NEW_ID" && echo 'PASS: key id changed'
curl --silent --output /dev/null --write-out 'old=%{http_code}\n' -H 'X-API-Key: lab-key-v1-8f62c1' http://127.0.0.1:8080/quote
curl --silent --output /dev/null --write-out 'new=%{http_code}\n' -H 'X-API-Key: lab-key-v2-41d9aa' http://127.0.0.1:8080/quote
```

期待値は`PASS: key id changed`、`old=401`、`new=200`。`--force-recreate api`はimageを作り直すのではなくcontainerを置換してmountとprocessを更新する。本番では新credentialを先に有効化し、全instance更新を確認してから旧credentialを失効させる。

## 6. Failure injectionと体系的debugging（30分）

### 障害：secret source欠落

```bash
mv secrets/api_key.txt secrets/api_key.txt.disabled
docker compose up -d --force-recreate api
docker compose ps -a
docker compose logs --no-color api
docker compose config
ls -ld secrets secrets/api_key.txt*
```

Composeがcontainer作成前にsource file欠落を報告する場合と、実装・環境差によりcontainer側で失敗する場合がある。期待する最終状態は「credentialなしでAPIが正常稼働しない」こと。

体系的な切り分け順：

1. **定義**：`docker compose config`でtop-level secretとservice grantがあるか
2. **source**：hostのpath、file type、owner、modeを`ls/stat`で確認
3. **creation**：`docker compose ps -a`でcontainerが作られたか、exit codeは何か
4. **mount**：作成済みなら`docker inspect ... --format '{{json .Mounts}}'`でtargetを確認
5. **process access**：実行UIDとfile modeを確認。ただし値を`cat`してterminal/logへ出さない
6. **application**：`startup_error=secret_unavailable`か`secret_invalid`かを値なしログで確認

よくある誤診断：

- `environment: API_KEY=...`を足して「直す」：fail-closedとleak防止を壊す
- Dockerfileへ`COPY secrets/...`：imageへ永久に混入させる
- `chmod 777`：読取主体を不必要に増やす
- `docker system prune`：原因を消し、他のassetも巻き込む

復旧：

```bash
mv secrets/api_key.txt.disabled secrets/api_key.txt
chmod 600 secrets/api_key.txt
docker compose up -d --force-recreate api
curl --fail --silent http://127.0.0.1:8080/healthz
```

追加failure injectionとして、12文字未満のダミー値を入れるとexit 78と`secret_invalid`を観察できる。実施後はv2値へ戻して再作成する。

## 7. Security review、size/performance計測、本番readiness

### Security review

- [ ] secret値がDockerfile、build args、image layer、Compose YAML、Git、`.env`にない
- [ ] `.dockerignore`が`secrets/`をbuild contextから除外
- [ ] serviceごとに必要なsecretだけをgrant
- [ ] applicationがfile pathから読み、値・長さ・prefixをlog/responseへ出さない
- [ ] 欠落・空・短すぎる値でfail-closed
- [ ] source fileのowner/mode、backup、配送経路、監査を定義
- [ ] non-root、`cap_drop: ALL`、`no-new-privileges`、read-only rootfs
- [ ] localhost以外への公開要否を確認し、productionではTLS/auth/network policyを設計
- [ ] rotation runbookに新値有効化、rolling replace、検証、旧値失効、rollbackを含める
- [ ] compromise時のrevoke、audit、incident responseを演習

### Size/performance measurement sheet

```bash
docker image inspect docker-secret-lab:local --format '{{.Size}}' | awk '{printf "image_mib=%.2f\n", $1/1024/1024}'
docker history docker-secret-lab:local
docker stats --no-stream docker-secret-lab-api-1 docker-secret-lab-worker-1
docker compose exec api sh -c 'grep -E "^(Uid|Gid|CapEff|NoNewPrivs):" /proc/1/status'
for i in 1 2 3 4 5; do curl --silent --output /dev/null --write-out '%{time_total}\n' http://127.0.0.1:8080/healthz; done
```

記録表：

| 指標 | 実測 | 本番候補基準 |
|---|---:|---:|
| image size | ___ MiB | baselineを記録し、releaseごとの急増を検知 |
| cold start | ___ sec | readiness timeout以内 |
| health latency 5回最大 | ___ sec | local baselineの2倍以内を目安に原因調査 |
| idle memory | ___ MiB | resource budgetに余裕を確保 |
| `CapEff` | ___ | `0000000000000000`を期待 |
| `NoNewPrivs` | ___ | `1`を期待 |

Alpineが常に最適とは限らない。musl互換性、debuggability、脆弱性対応、native wheel有無を含めてslim系と比較する。小型化だけを目的に運用性を落とさない。

### Production-readiness checklist

- [ ] deploy artifactはtagだけでなく検証済みdigestで追跡可能
- [ ] image vulnerability scan、SBOM、provenance方針がある
- [ ] health/readinessとgraceful shutdownを実環境で確認
- [ ] secret sourceは暗号化・RBAC・auditを備えた管理基盤から供給
- [ ] log/trace/error reporterのredaction testがCIにある
- [ ] backupやsupport bundleにもsecretを含めない
- [ ] resource limits、log rotation、restart policyを実測から設定
- [ ] host、daemon socket、registry credentialへの不要なaccessがない
- [ ] rotationとrevokeのSLO、owner、連絡経路が明文化済み

## 8. Cleanup

まず対象を確認する：

```bash
docker compose ps -a
docker image ls docker-secret-lab
```

プロジェクトのcontainer/networkだけを停止・削除する：

```bash
docker compose down --remove-orphans
```

教材imageも不要なら、対象名を再確認したうえでのみ次を実行する：

```bash
docker image rm docker-secret-lab:local
```

これは`rmi`相当の削除操作である。別containerが使用中なら無理に`-f`を付けない。`docker system prune`、`docker image prune`、`docker rm -f`は本ラボでは不要。最後に教材ダミーsecret fileとdirectoryを通常のfile管理手順で削除する。本物のcredentialなら、file削除だけでなく発行元でrevokeする。

## 9. Concrete deliverables

1. `Dockerfile`、`.dockerignore`、`compose.yaml`、application files
2. grant matrix（service × secret）と、`worker`非到達のtest結果
3. image/history/inspect/log/APIのleakage test結果
4. failure injectionのtimeline：症状、仮説、command、証拠、復旧
5. rotation記録：旧/new key ID、旧401、新200、再作成時間
6. image size、cold start、health latency、idle resource表
7. 上記production-readiness checklistと未解決riskのowner

## 10. Assessment

### Q1. なぜDockerfileのあるlayerでsecretを作り、次のlayerで削除しても安全ではないか？

<details><summary>回答</summary>
各命令が作るimage layerやbuild metadataに値が残り、後のlayerの削除は下位layerからの回収を意味しないため。最初からbuild contextやlayerへ入れず、build時ならBuildKit secret mount、runtimeならruntime secretを使う。
</details>

### Q2. Compose secretは、環境変数よりどの境界を明示しやすいか？

<details><summary>回答</summary>
serviceごとのgrantとcontainer内のfile accessである。必要serviceだけに`secrets:`を列挙でき、applicationは特定pathを必要時に読む。ただし同一container内で読取権限を得た侵害processやhost管理者から守る万能策ではない。
</details>

### Q3. `worker`にsecretがないことを「設定を見た」以上にどう証明するか？

<details><summary>回答</summary>
render済みCompose modelでgrantがないことを確認し、稼働container内で`test ! -e /run/secrets/api_key`、必要に応じて`docker inspect`のmount一覧も確認する。定義とruntimeの両方を証拠にする。
</details>

### Q4. source fileを更新したのにアプリが旧値を使い続ける場合、何を調べるか？

<details><summary>回答</summary>
mountの更新semantics、アプリが起動時に値をmemoryへcacheするか、containerが再作成されたか、全replicaが置換されたかを調べる。rotationの反映境界を明文化し、新旧併用と失効順序を設計する。
</details>

### Q5. `docker compose config`にsecret値が見えなければ漏えい対策は完了か？

<details><summary>回答</summary>
いいえ。build context、image history/layers、inspect、process環境、log、HTTP response、trace、crash dump、backup、host source fileも検査対象である。さらにgrant、file権限、rotation、revoke、auditも必要。
</details>

### Interview / design question

「20個のservice、3環境、日次rotation、無停止要件がある。Compose file-based secretsから外部secret managerへ移行する設計を、bootstrap認証、cache、障害時挙動、監査、新旧credentialの重複期間、rollbackまで説明せよ。」

評価pointは、単なる製品名ではなく、secret lifetime、identity、最小権限、manager停止時のfail-open/closed、rotation state machine、観測可能性をtrade-offとして説明できること。

### Optional advanced challenge（Specialized相当・10〜30分）

private package repositoryを模したbuildを追加し、BuildKitの`RUN --mount=type=secret,id=repo_token,required=true`でbuild時だけtokenを読ませる。次を自動testする。

1. `--secret`なしではbuildが失敗する
2. `--secret`ありでは成功する
3. `docker history --no-trunc`、final filesystem、`docker save`展開結果にtokenがない
4. cache hit時にもtoken値がoutputやcache artifactへ書かれない

runtime Compose secretとBuildKit build secretは目的・lifetime・consumerが異なることを比較表へ追記する。実在credentialは使わない。

## 11. 公式Docker Docs（2026-08-05確認）

- [Manage secrets securely in Docker Compose](https://docs.docker.com/compose/how-tos/use-secrets/)
- [Compose file reference: Secrets top-level element](https://docs.docker.com/reference/compose-file/secrets/)
- [Compose file reference: Services（secrets / read_only / cap_drop / security_opt / tmpfs）](https://docs.docker.com/reference/compose-file/services/)
- [Build secrets](https://docs.docker.com/build/building/secrets/)
- [Dockerfile reference: RUN --mount=type=secret](https://docs.docker.com/reference/dockerfile/#run---mounttypesecret)
- [Build context and .dockerignore](https://docs.docker.com/build/concepts/context/)
- [tmpfs mounts](https://docs.docker.com/engine/storage/tmpfs/)
- [Docker build best practices](https://docs.docker.com/build/building/best-practices/)

公式Docsの要点：Compose secretsはtop-levelでsourceを定義し、service側で明示的にgrantすると`/run/secrets/<name>`へfileとしてmountされる。build secretには`ARG`/`ENV`ではなく`--secret`と`RUN --mount=type=secret`を使い、runtime secretと混同しない。
