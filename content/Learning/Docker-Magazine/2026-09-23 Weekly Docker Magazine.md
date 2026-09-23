---
type: weekly-magazine
series: docker
difficulty: Intermediate
focus: "Linux capabilities・read-only root filesystem・no-new-privileges・seccompによる実行時最小権限"
week: 2026-W39
prerequisites:
  - Docker EngineまたはDocker DesktopとDocker Compose v2
  - Dockerfile・Compose・Linuxプロセス・ファイル権限の基礎
  - コンテナがホストkernelを共有するという理解
  - curlと基本的なshellコマンド
estimated_minutes: 165
---

# Weekly Docker Magazine — 「動く権限」ではなく「必要な権限」だけを渡す

#docker #containers #weekly #deep-dive

[[Home]]

> [!warning] 削除操作と秘密情報
> `docker system prune` / `docker image prune` / `docker rmi` / `docker rm -f` は、別プロジェクトの資産や稼働サービスを消し得る。実行前に `docker ps -a`、`docker image ls`、対象名を確認する。本ラボのcleanupはプロジェクト名 `runtime-hardening-lab` に限定する。
>
> token、パスワード、秘密鍵をDockerfile、image layer、`ARG`、`ENV`、`compose.yaml`へ書かない。本ラボにsecretは不要。本番ではsecret managerまたはCompose secrets等で実行時に必要なserviceだけへ渡す。

## 1. Focus、難易度、前提、測定可能な到達点

### Focus — 今週の単一本番基準

> **通常のWeb APIが、非root・全capability削除・権限昇格禁止・read-only root filesystem・Docker既定seccompのまま機能し、例外は検証可能な最小単位でのみ許可されること。**

これは「設定項目を並べた」状態ではない。正常系testと攻撃的probeの両方をCIで実行し、必要機能は通る一方、root filesystem書込み、setuid権限昇格、不要なkernel操作が拒否されることを証明する。

### 難易度シグナル: Intermediate

学習量の目安であり参加資格ではない。Linux固有のkernel制御を扱うため、Docker DesktopではLinux VM内の挙動として観測する。

### 必要な知識・ツール・環境・既習概念

- **知識:** UID/GID、file permission、system call、process、HTTPの基礎
- **ツール:** 現行Docker EngineまたはDocker Desktop、Compose v2、`curl`、`awk`、`time`、任意で`jq`
- **環境:** Linux containerを実行できる開発機、空きRAM 1 GiB、空きdisk 1 GiB、`127.0.0.1:18080`が空いていること
- **earlier concepts:** imageとcontainer、multi-stage build、Compose service、healthcheck、resource limit、Rootless mode
- **区別:** Rootlessはdaemon/host側の境界。本号は各container processへ許す操作を狭める境界。両者は代替ではなく重ねられる

### 165分後の合格条件

1. hardened APIへ20回requestし、すべてHTTP 200になる。
2. `Config.User`、`ReadonlyRootfs`、`CapDrop`、`SecurityOpt`を`docker inspect`で証明する。
3. `/app`への書込み、setuid helperによるroot昇格、raw socket生成がすべて拒否される。
4. `/tmp`だけはsize制限付きtmpfsとして書込み可能で、再作成後に消える。
5. `seccomp=unconfined`を恒久回避に使わず、拒否された操作→必要性→最小例外→test→記録の順で判断できる。
6. image size、起動時間、平常時memoryを測り、本番readiness表を完成させる。

## 2. 実アプリのシナリオと制約

社内の「build情報API」を単一Docker hostで運用する。APIは`/healthz`と`/info`を返し、一時ファイルだけを`/tmp`へ書く。外部DBやhost filesystemは不要である。

- processはUID/GID `10001`で実行する
- root filesystemはimmutableにし、書込み先は64 MiB以下の`tmpfs`だけ
- Linux capabilitiesはゼロから開始する
- setuid/setgid binaryやfile capabilityによる昇格を禁止する
- Dockerの既定seccomp profileを外さない
- host公開は`127.0.0.1:18080`だけ
- host PID/network namespace、device、Docker socket、host bind mountを渡さない
- imageは80 MiB以下を教材目標とする（環境差があるため合否は測定値と理由で判断）
- 設定不足を`privileged: true`で解決しない

**脅威モデル:** appにremote code executionが起きても、攻撃者がcontainer内で任意processを動かせるだけで、直ちにhost rootにならないよう爆発半径を狭める。ただしcontainerはhost kernelを共有するため、kernel脆弱性、Docker socket、危険なbind mount、daemon管理権限は別の重要境界である。

## 3. Foundation — container/runtime mental model

「container内root」は万能ではない。実際にprocessができることは複数の独立した制御の積で決まる。

```text
実行できる操作
  = UID/GID と file mode
  ∩ Linux capabilities
  ∩ no-new-privileges
  ∩ seccomp system-call filter
  ∩ mountのread/write属性
  ∩ LSM（AppArmor/SELinux等）
  ∩ namespace / cgroup / device policy
```

- **non-root user:** 通常のUnix permissionで操作を制限する。これだけでは誤ってworld-writableな場所等を防げない
- **capabilities:** 従来のroot権限を小さな単位へ分割する。`CAP_NET_RAW`、`CAP_SYS_ADMIN`等。`SYS_ADMIN`は極めて広く、安易に追加しない
- **`no-new-privileges`:** `execve`後にsetuid/setgid bitやfile capabilities等から新しい権限を得ることを禁止する
- **seccomp:** processが呼べるsystem callをfilterする。Docker既定profileは互換性を保ちつつ危険なcall群を拒否する
- **read-only root filesystem:** image由来のmountを変更不能にする。書込みが必要なpathだけvolume/tmpfsとして明示する
- **tmpfs:** memory-backedでcontainer lifecycle後に残らない。size/modeを制限しないとmemory消費や情報露出の原因になる

`USER 10001`、`cap_drop: [ALL]`、`read_only: true`は別々の事故を防ぐ。どれか一つで全部を代替できない。

## 4. 設計候補と明示的なtrade-off

|設計|利点|代償・注意|本号の判断|
|---|---|---|---|
|既定設定のみ|互換性が高い|不要な書込み・capability・昇格余地を残す|baseline比較だけ|
|非rootのみ|導入しやすい|filesystemやsetuid等の境界が曖昧|不十分|
|`privileged: true`|多くの互換性問題を隠す|ほぼ全device/capabilityへ広がり、隔離を大幅に弱める|禁止|
|`cap_drop: ALL`後に個別追加|権限の根拠が明確|legacy appで調査が必要|採用。今回は追加ゼロ|
|read-only + 限定tmpfs|改ざんと野放図な書込みを抑える|必要なwrite pathの棚卸しが必要|採用|
|Docker既定seccomp|更新・互換性・防御のbalance|app固有の最小allowlistではない|採用|
|独自seccomp allowlist|system call面をさらに狭められる|architecture/runtime更新で壊れやすく保守コスト大|Optional challenge|
|`seccomp=unconfined`|切り分けが速い|防御層を丸ごと外す|一時診断でも共有/本番環境では避け、恒久設定にしない|

### Architecture / build flow

```mermaid
flowchart LR
  S[app.py / probe.c] --> B[BuildKit multi-stage build]
  B --> I[runtime image\nnon-root UID 10001]
  C[compose.yaml hardening policy] --> R[container create]
  I --> R
  R --> U[UID/GID boundary]
  R --> CAP[cap_drop ALL]
  R --> NNP[no-new-privileges]
  R --> SEC[Docker default seccomp]
  R --> RO[read-only rootfs]
  RO --> TMP[/tmp tmpfs 64 MiB]
  T[functional + negative tests] --> API[127.0.0.1:18080]
  T --> P[write / setuid / raw-socket probes]
  API --> R
  P --> R
  R --> E[inspect evidence + measurements]
```

## 5. Guided lab（目安165分）

### 5.1 時間配分と成果物

- 0–20分: preflightとmental model
- 20–50分: sample作成とbuild
- 50–80分: baseline観測
- 80–120分: hardened実装と自動test
- 120–145分: failure injectionとsystematic debugging
- 145–165分: size/performance/security reviewと判断記録

作業directoryを作る。

```bash
mkdir -p runtime-hardening-lab
cd runtime-hardening-lab
docker version
docker compose version
docker info --format '{{json .SecurityOptions}}'
```

**Checkpoint 0:** Engine/Compose versionと`SecurityOptions`が表示される。Linux以外では以降のcapability/seccomp挙動が異なるため、Linux container modeを確認する。

### 5.2 完全なsample files

#### `app.py`

```python
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
import os
import tempfile
import time

class Handler(BaseHTTPRequestHandler):
    def reply(self, code, payload):
        body = (json.dumps(payload, sort_keys=True) + "\n").encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        if self.path == "/healthz":
            return self.reply(200, {"status": "ok"})
        if self.path == "/info":
            with tempfile.NamedTemporaryFile(dir="/tmp", delete=True) as f:
                f.write(b"ephemeral\n")
                f.flush()
            return self.reply(200, {
                "uid": os.getuid(),
                "gid": os.getgid(),
                "tmp_write": "ok",
                "epoch": int(time.time()),
            })
        return self.reply(404, {"error": "not found"})

    def log_message(self, fmt, *args):
        print(json.dumps({"event": "http", "message": fmt % args}), flush=True)

ThreadingHTTPServer(("0.0.0.0", 8080), Handler).serve_forever()
```

#### `probe.c`

教材専用のsetuid probe。実アプリへsetuid binaryを入れる推奨ではない。`no-new-privileges`の効果を目で確認するためだけに使う。

```c
#include <stdio.h>
#include <unistd.h>

int main(void) {
  printf("uid=%d euid=%d\n", getuid(), geteuid());
  return 0;
}
```

#### `Dockerfile`

```dockerfile
# syntax=docker/dockerfile:1
FROM alpine:3.22 AS probe-build
RUN apk add --no-cache build-base
WORKDIR /src
COPY probe.c .
RUN cc -O2 -s -o privilege-probe probe.c

FROM python:3.13-alpine
RUN addgroup -g 10001 app && adduser -D -H -u 10001 -G app app
WORKDIR /app
COPY --chown=10001:10001 app.py .
COPY --from=probe-build /src/privilege-probe /usr/local/bin/privilege-probe
RUN chown root:root /usr/local/bin/privilege-probe \
    && chmod 4755 /usr/local/bin/privilege-probe
USER 10001:10001
EXPOSE 8080
CMD ["python", "app.py"]
```

#### `.dockerignore`

```gitignore
.git
.env
*.pem
*.key
__pycache__/
evidence/
```

`.env`やkeyを除外しても、秘密をbuild contextへ置いてよいわけではない。Build secretが必要ならBuildKit secret mountを使う。

#### `compose.baseline.yaml`

```yaml
services:
  api:
    build: .
    ports:
      - "127.0.0.1:18080:8080"
```

#### `compose.yaml`

```yaml
name: runtime-hardening-lab
services:
  api:
    build:
      context: .
    image: runtime-hardening-api:lab
    user: "10001:10001"
    read_only: true
    cap_drop:
      - ALL
    security_opt:
      - no-new-privileges:true
    tmpfs:
      - /tmp:size=64m,mode=1777,noexec,nosuid,nodev
    ports:
      - "127.0.0.1:18080:8080"
    healthcheck:
      test: ["CMD", "python", "-c", "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8080/healthz', timeout=2)"]
      interval: 5s
      timeout: 3s
      retries: 5
      start_period: 3s
    mem_limit: 128m
    pids_limit: 64
    cpus: 0.50
    restart: "no"
```

#### `test.sh`

```sh
#!/bin/sh
set -eu

base=http://127.0.0.1:18080
i=1
while [ "$i" -le 20 ]; do
  curl -fsS "$base/healthz" | grep -q '"status": "ok"'
  i=$((i + 1))
done

curl -fsS "$base/info" | tee /tmp/runtime-hardening-info.json
curl -fsS "$base/info" | grep -q '"uid": 10001'

cid=$(docker compose ps -q api)
test -n "$cid"
docker inspect "$cid" --format 'user={{.Config.User}} readonly={{.HostConfig.ReadonlyRootfs}} capdrop={{json .HostConfig.CapDrop}} security={{json .HostConfig.SecurityOpt}}'

if docker compose exec -T api sh -c 'echo bad > /app/should-not-exist'; then
  echo 'FAIL: root filesystem write unexpectedly succeeded' >&2
  exit 1
else
  echo 'PASS: root filesystem write blocked'
fi

docker compose exec -T api sh -c 'echo ok > /tmp/allowed && grep -q ok /tmp/allowed'

probe=$(docker compose exec -T api privilege-probe)
echo "$probe"
echo "$probe" | grep -q 'uid=10001 euid=10001'

if docker compose exec -T api python -c 'import socket; socket.socket(socket.AF_INET, socket.SOCK_RAW, socket.IPPROTO_ICMP)'; then
  echo 'FAIL: raw socket unexpectedly succeeded' >&2
  exit 1
else
  echo 'PASS: raw socket blocked'
fi

echo 'ALL HARDENING TESTS PASSED'
```

#### `deny-gethostname.json`

これはfailure injection専用の最小profileで、**default allowのため本番用profileではない**。

```json
{
  "defaultAction": "SCMP_ACT_ALLOW",
  "syscalls": [
    {
      "names": ["gethostname"],
      "action": "SCMP_ACT_ERRNO",
      "errnoRet": 1
    }
  ]
}
```

### 5.3 buildとbaseline（約30分）

```bash
export COMPOSE_PROJECT_NAME=runtime-hardening-lab
docker compose -f compose.baseline.yaml build --pull
docker compose -f compose.baseline.yaml up -d
curl -fsS http://127.0.0.1:18080/info
docker compose -f compose.baseline.yaml exec -T api privilege-probe
docker compose -f compose.baseline.yaml exec -T api sh -c 'echo mutable > /app/baseline-write && cat /app/baseline-write'
```

**期待出力（主要部）:**

```text
{"epoch": ..., "gid": 10001, "tmp_write": "ok", "uid": 10001}
uid=10001 euid=0
mutable
```

baselineではDockerfileの`USER`により通常processは非rootだが、setuid bitによりeffective UID 0へ上がり、root filesystemにも書ける。これが「non-rootだけでは不十分」の証拠である。

停止して同じportを空ける。

```bash
docker compose -f compose.baseline.yaml down --remove-orphans
```

### 5.4 hardened構成（約40分）

```bash
docker compose config
docker compose up -d --build
docker compose ps
chmod +x test.sh
./test.sh
```

**期待出力（順序や文言は環境差あり）:**

```text
user=10001:10001 readonly=true capdrop=["ALL"] security=["no-new-privileges:true"]
sh: can't create /app/should-not-exist: Read-only file system
PASS: root filesystem write blocked
uid=10001 euid=10001
PermissionError: [Errno 1] Operation not permitted
PASS: raw socket blocked
ALL HARDENING TESTS PASSED
```

**Checkpoint 1:** 正常HTTPは通り、3つのnegative testは拒否される。拒否を「lab失敗」と誤読しない。test script全体のexit codeが0であることを確認する。

### 5.5 tmpfs lifecycle test

```bash
docker compose exec -T api sh -c 'echo transient > /tmp/lifecycle && cat /tmp/lifecycle'
docker compose up -d --force-recreate
docker compose exec -T api sh -c 'test ! -e /tmp/lifecycle && echo "PASS: tmpfs was reset"'
```

**期待:** `PASS: tmpfs was reset`。永続化が必要なデータをtmpfsへ置いてはいけない。

## 6. コマンドと設定をline by lineで読む

### `compose.yaml`

- `name`: project名を固定し、container/networkをこのlabへscopingする
- `build.context: .`: current directoryだけをbuild contextにする。`.dockerignore`も適用される
- `image`: 測定・cleanup対象を明示名にする
- `user: "10001:10001"`: image設定に加えruntimeでもUID/GIDを明示する
- `read_only: true`: root filesystemをread-only mountにする
- `cap_drop: [ALL]`: Dockerの既定capability集合も含め、全て削除する。必要性をtestで証明できた時だけ個別追加する
- `security_opt: no-new-privileges:true`: setuid helperを実行してもeffective UIDが増えない
- `tmpfs`: `/tmp`だけ書込み可。`size`はmemory上限、`1777`は標準的な共有tmp permission、`noexec/nosuid/nodev`は用途を一時データへ限定する
- `ports`: host loopbackだけへ公開する。これはcontainer間network policyの代替ではない
- `healthcheck`: container内loopbackでapplication readinessを確認する。Docker Engine単体では`unhealthy`を必ず再起動するわけではない
- `mem_limit` / `pids_limit` / `cpus`: hardeningが別のresource exhaustionを解決するわけではないため併用する
- `restart: "no"`: labでfailureを見失わない設定。本番policyはorchestratorとSLOに合わせる

### 重要コマンド

```bash
docker compose config
```

mergeと変数展開後のCompose modelを検査する。**注意:** 実際のsecretをenvironment等へ置くと表示へ混入し得る。本ラボにはsecretを置かない。

```bash
docker inspect "$cid" --format '...'
```

希望ではなく、Engineへ渡ったruntime設定を確認する。ただしkernelで実効化されたかはnegative testでも証明する。

```bash
docker compose exec -T api ...
```

`-T`は疑似TTYを割り当てず、CIでも出力とexit codeを安定させる。productionで場当たり的な変更をする手段にはしない。

## 7. Failure injectionとsystematic debugging（約25分）

### Injection A — 必要write pathを忘れる

`app.py`の`dir="/tmp"`を`dir="/app"`へ一時変更し、再buildする。

```bash
docker compose up -d --build
curl -i http://127.0.0.1:18080/info
docker compose logs --tail=50 api
```

**期待:** `/healthz`は通るが`/info`は500、logに`Read-only file system`。修正候補は次の順で評価する。

1. 本当に書込みが必要か。不要ならcodeを直す
2. ephemeralか。そうなら専用tmpfsへ移す
3. persistentか。そうなら専用volumeを最小pathへmountし、backup/owner/quotaを設計する
4. `read_only: false`へ戻すのは最後で、理由・owner・監視を記録する

### Injection B — seccomp拒否を再現する

```bash
docker run --rm \
  --security-opt seccomp="$PWD/deny-gethostname.json" \
  python:3.13-alpine \
  python -c 'import socket; print(socket.gethostname())'
```

**期待:** `PermissionError: [Errno 1] Operation not permitted`等でnon-zero終了。

比較は隔離されたlabだけで行う。

```bash
docker run --rm python:3.13-alpine python -c 'import socket; print(socket.gethostname())'
```

### 切り分け順序

1. **症状:** exit code、HTTP status、timestampを固定する
2. **application:** `docker compose logs`でstack traceと失敗path/callを見る
3. **effective config:** `docker compose config`と`docker inspect`
4. **identity/capability:** `id`、`grep '^Cap' /proc/1/status`
5. **mount:** `grep ' /app\| /tmp ' /proc/self/mountinfo`
6. **security profile:** `grep '^NoNewPrivs\|^Seccomp' /proc/1/status`
7. **single-variable comparison:** local disposable labで一つだけ境界を変え、再現testを走らせる
8. **最小修正:** 全解除ではなく必要path/capability/system callだけを設計し直す
9. **regression:** 正常testとnegative testをCIへ残す

観測command:

```bash
docker compose exec -T api sh -c 'id; grep -E "^(Cap|NoNewPrivs|Seccomp)" /proc/1/status'
docker compose exec -T api sh -c 'grep -E " /app | /tmp " /proc/self/mountinfo || true'
```

**Checkpoint 2:** `NoNewPrivs: 1`、`Seccomp: 2`（filter mode）、capability maskゼロ相当を説明できる。kernel/runtime差があれば、数値を「期待に合わせて解釈」せず環境情報と一緒に記録する。

## 8. Security review

### 攻撃面のreview質問

- processは固定の非root UID/GIDか
- `cap_add`、`privileged`、host PID/network、device mountは本当にゼロか
- Docker socketやhost rootのbind mountがないか
- root filesystemはread-onlyか。write mountは最小path、正しいowner、quota/size、必要なmount flagsを持つか
- `no-new-privileges`がinspectとprocess statusの両方で確認できるか
- Docker既定seccompを外していないか。custom profileにはowner、version、architecture testがあるか
- healthcheckがsecretや個人情報をlogへ出さないか
- base imageはdigest固定、更新手順、SBOM、脆弱性scan、provenanceの対象か
- daemon/operator権限、Rootless/user namespace、LSM、host patchingは別layerとして管理されているか

### 誤解しやすい点

- `cap_drop: ALL`は「containerが何もできない」ではない。通常のfile/network/process操作の多くはcapability不要
- read-only rootfsでも、明示したvolume/tmpfsは書ける
- seccompはnetwork ACLでもfile ACLでもない
- non-rootとRootless modeは同じではない
- hardeningは脆弱性を消さず、侵害後の選択肢とblast radiusを狭める

## 9. Image size・performance測定

```bash
mkdir -p evidence
docker image inspect runtime-hardening-api:lab \
  --format 'bytes={{.Size}} id={{.Id}}' | tee evidence/image.txt
docker history --no-trunc runtime-hardening-api:lab | tee evidence/history.txt

/usr/bin/time -f 'elapsed=%e sec' \
  docker compose up -d --force-recreate 2>&1 | tee evidence/startup.txt

docker stats --no-stream --format \
  'name={{.Name}} cpu={{.CPUPerc}} memory={{.MemUsage}} pids={{.PIDs}}' \
  | grep runtime-hardening | tee evidence/stats.txt

for i in $(seq 1 100); do
  curl -fsS -o /dev/null http://127.0.0.1:18080/healthz
done
```

記録する値:

|指標|実測|目標/判断|
|---|---:|---|
|image size|____ MiB|教材目標80 MiB以下。超過ならlayerとbaseを説明|
|startup time|____ sec|healthcheck healthyまで別途観測|
|idle memory / limit|____ / 128 MiB|headroomを説明|
|100 requests成功数|____ / 100|100必須|
|hardened negative tests|____ / 3|3必須|

security option自体のmicrobenchmarkだけで優劣を断定しない。実appのlatency/throughput、kernel、architecture、load条件を固定して比較する。

## 10. Production-readiness checklist

- [ ] 正常系とnegative security testがCIで毎回動く
- [ ] image/Composeの両方で非root identityが明示される
- [ ] `cap_drop: ALL`で動き、追加capabilityがある場合は1個ずつ根拠・owner・expiryがある
- [ ] `no-new-privileges`が有効
- [ ] root filesystemがread-only
- [ ] write mountは用途別で、size/permission/mount flags/backup方針が明確
- [ ] Docker既定seccompを無効化していない
- [ ] custom seccompを使う場合、kernel/architecture/runtime更新testがある
- [ ] `privileged`、Docker socket、host namespace、不要device、広いhost bind mountがない
- [ ] resource limits、logging、health/readiness、shutdown、restart policyが別途設計済み
- [ ] base image、digest、SBOM/provenance、scan、patch cadenceが管理される
- [ ] host kernel/daemon/operator access/Rootlessまたはuser namespace/LSMもreview済み
- [ ] rollbackはhardening全解除でなく、検証済み前versionへ戻す
- [ ] 実測値と例外がrelease evidenceとして保存される

## 11. Cleanup

> [!danger] 実行前確認
> `docker system prune`、`docker image prune`、広い`docker rmi`、`docker rm -f`は使わない。まず下の一覧がこのlabだけか確認する。

```bash
docker compose ps -a
docker image ls runtime-hardening-api
docker compose down --remove-orphans
```

lab imageも削除したい場合だけ、表示されたrepository/tagを再確認してから実行する。

```bash
docker image rm runtime-hardening-api:lab
```

`evidence/`は学習成果物なので自動削除しない。不要なら内容を確認し、OSのtrash機能で回収可能に削除する。

## 12. Concrete deliverables

1. `app.py`、`probe.c`、`Dockerfile`、`.dockerignore`
2. `compose.baseline.yaml`とhardened `compose.yaml`
3. `test.sh`と全test成功log
4. `evidence/image.txt`、`history.txt`、`startup.txt`、`stats.txt`
5. baseline対hardenedの差分表
6. capability/seccomp/write mountの例外判断記録（例外ゼロでも記録）
7. 完成したproduction-readiness checklist

## 13. Assessment

### Q1. `USER 10001`だけで十分でない理由を2つ挙げよ。

<details><summary>答え</summary>

setuid/file capabilities等で`execve`後に権限が増える可能性と、root filesystemが依然read-writeでapplication fileを改ざんできる可能性がある。さらに不要capability、seccomp、mount、host resource等は別の制御層である。

</details>

### Q2. `cap_drop: ALL`後に`NET_BIND_SERVICE`を追加すべき典型条件は何か。

<details><summary>答え</summary>

非root processがLinux上で1024未満のportへ直接bindする必要があり、別portやproxyで代替できず、testでそのcapabilityだけが必要だと証明できた場合。通常はcontainer内8080等を使いhost側で443へpublish/proxyする方が単純。

</details>

### Q3. read-only rootfsでcacheが必要になった。最初の判断は何か。

<details><summary>答え</summary>

cacheが本当に必要か、ephemeralかpersistentかを分類する。ephemeralならsize制限付きtmpfs、persistentなら専用volumeとowner/backup/quotaを設計する。rootfs全体をread-writeへ戻さない。

</details>

### Q4. `Operation not permitted`を見て、すぐ`seccomp=unconfined`にしてはいけない理由は何か。

<details><summary>答え</summary>

EPERMはUID、capability、seccomp、LSM等の複数層から起こり得る。unconfinedは原因を証明せずsystem call防御を丸ごと外す。log/config/process statusを観測し、disposable環境で一変数比較し、最小修正とregression testを残す。

</details>

### Q5. `NoNewPrivs: 1`とsetuid probeの`euid=10001`はそれぞれ何を証明するか。

<details><summary>答え</summary>

前者はkernelがprocessにno-new-privilegesを設定した観測、後者はsetuid root binaryを`execve`しても実際にeffective UIDが増えなかった機能test。設定値と挙動の両方を確認することで証拠が強くなる。

</details>

### Interview / design question

画像処理serviceが`cap_drop: ALL`で壊れ、vendor文書は`privileged: true`を要求している。どのように安全な本番設計へ収束させるか。

回答には、再現可能な最小workload、必要device/system call/capabilityの観測、代替architecture（host側workerや専用nodeを含む）、一つずつの権限追加、negative test、host isolation、例外owner/期限、監視、rollbackを含める。vendorの要求をそのまま要件と見なさない。

### Follow-up challenge（Optional advanced）

本番workloadのsystem callをstagingで観測し、Docker既定profileを基点にapp固有seccomp profile候補を作る。ただし観測に現れなかったcallを単純削除しない。cold start、healthcheck、DNS、TLS、signal handling、architecture差、runtime/library upgradeをtest matrixへ入れ、profileをversion管理する。最後にDocker既定profileと比較し、追加防御が保守コストを上回るかADRへ記録する。

## 14. 現行Docker公式ドキュメント

- [Docker Engine security](https://docs.docker.com/engine/security/)
- [Seccomp security profiles for Docker](https://docs.docker.com/engine/security/seccomp/)
- [Compose services reference: `cap_drop`, `read_only`, `security_opt`, `tmpfs`](https://docs.docker.com/reference/compose-file/services/)
- [Compose trust model](https://docs.docker.com/compose/trust-model/)
- [`docker container create` reference: read-only / security options / capabilities](https://docs.docker.com/reference/cli/docker/container/create/)
- [Dockerfile best practices](https://docs.docker.com/build/building/best-practices/)
- [Docker build secrets](https://docs.docker.com/build/building/secrets/)
- [Rootless mode](https://docs.docker.com/engine/security/rootless/)

---

**今週の判断原則:** 権限不足は、全解除の理由ではない。必要な操作を特定し、最小の例外を設計し、正常系と拒否系の両方をtestして初めて本番権限になる。
