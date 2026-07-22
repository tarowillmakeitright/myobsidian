---
type: weekly-magazine
series: docker
difficulty: Intermediate
focus: "本番コンテナのCPU・メモリ・PID制限とOOM診断"
week: 2026-W30
prerequisites:
  - Docker EngineまたはDocker Desktop
  - Docker Compose v2
  - Dockerfile・compose up・logs・inspectの基礎
  - Linuxプロセスとメモリの基本
estimated_minutes: 150
---

# Weekly Docker Magazine — CPU・メモリ・PID制限とOOM診断

#docker #containers #weekly #deep-dive

[[Home]]

> [!warning] 削除とSecrets
> `docker system prune` / `docker image prune` / `docker rmi` / `docker rm -f` は資産や稼働中コンテナを削除し得る。共有ホストでは実行せず、cleanup前に必ず対象を確認する。本ラボに秘密情報は不要。APIキー等をDockerfile、イメージ、`compose.yaml`、Git管理下の`.env`へ絶対に書かない。本番では実行時secret管理を使う。

## 1. Focus、難易度、前提、到達点

**本番基準：1コンテナの暴走がホストや同居サービスを巻き込まないよう、CPU・メモリ・PIDを測定して制限し、OOMとCPU throttlingを証拠から診断できること。**

- Difficulty signal: **Intermediate**（目安であり参加条件ではない）
- 必要な知識：プロセス、RAM/swap、HTTP、終了コードの基本
- 先行概念：イメージとコンテナ、Dockerfile、Composeサービス、ログ、`inspect`
- ツール：現行Docker Engine/Desktop、Compose v2、`curl`、エディタ
- 環境：Linuxコンテナ。推奨2 CPU、空きRAM 2 GiB。DesktopではLinux VM内に制限される

150分後に、次を実測して説明できることを合格条件とする。

1. 128 MiB、0.5 CPU、64 PIDの制限をComposeへ設定し、`inspect`で反映を確認する。
2. `docker stats`でCPU%、メモリ使用量/上限、PID数を記録する。
3. OOMを再現し、exit 137と`OOMKilled=true`を区別して確認する。
4. CPU上限を負荷試験し、「遅い」と「落ちた」を切り分ける。
5. 平常・ピーク計測、余裕幅、同時実行数から本番候補値を提案する。

## 2. 実アプリのシナリオと制約

画像メタデータAPIが、2 vCPU / 2 GiBのVM上でWeb、ワーカー、監視エージェントと共存する。普段は40–60 MiBだが、大入力や不具合でメモリが増え、CPU集約処理もある。

- API 1個の予算：CPU 0.5 core、RAM 128 MiB、PID 64
- `/healthz`の通常p95目標：200 ms未満
- 障害時は問題コンテナだけを止め、ホストを守る
- root以外、最小権限、loopback公開、秘密の埋め込み禁止
- 128 MiBは教材値。本番へコピーせず、測定から決める

## 3. Container/runtime mental model

コンテナは軽量VMではなくホスト上のプロセスである。namespaceが「見える範囲」を分離し、cgroupsが「使える資源と使用量」を管理する。

- **memory hard limit**：超過時、Linux OOM killerがコンテナ内プロセスを終了させ得る。
- **memory reservation**：競合時に効くsoft target。hard ceilingではない。
- **CPU quota (`cpus`)**：一定期間のCPU時間を制限。超過時は通常killでなくthrottle＝遅延になる。
- **CPU shares**：競合時の相対weight。上限でも予約でもない。
- **PID limit**：fork bombやプロセス/スレッドリークによるホスト枯渇を抑える。
- **swap**：OOMまでの緩衝になり得るが遅い。`memory-swap`は`memory`との組合せで意味が変わる。

つまり、**メモリ不足はkill、CPU不足は主に待ち時間増大**として現れる。healthcheckは観察であり、Docker Engine単体で`unhealthy`を必ず再起動する仕組みではない。

```mermaid
flowchart LR
  L[curl負荷] --> P[127.0.0.1:8080]
  P --> A[非root Python API]
  subgraph Docker Host / Linux VM
    subgraph Container cgroup
      A --> H[/healthz]
      A --> M[/allocate]
      A --> C[/cpu]
    end
    CG[cgroup v2\nmemory.max / cpu.max / pids.max] --> A
    M -->|128 MiB超過| OOM[OOM killer]
    OOM -->|SIGKILL / exit 137| A
    A --> OBS[docker stats / inspect / events]
  end
```

## 4. 設計代替案とtrade-off

| 設計 | 長所 | 短所・判断 |
|---|---|---|
| 制限なし | バースト性能 | noisy neighborとhost OOM。本番不可 |
| hard memoryのみ | host保護が明確 | 低すぎると急なOOM。安全網として実測後に設定 |
| reservation + limit | 通常目標と絶対上限を分離 | 監視と意味の理解が必要 |
| `cpus` quota | CPU ceiling | tail latency増。バッチ暴走隔離向き |
| CPU shares | 余剰CPUを活用 | 非競合時の上限にならない |
| swap禁止 | 遅延が読みやすい | burstでOOMしやすい。低遅延用途向き |
| swap許可 | 一時ピークの緩衝 | latencyとI/O悪化。負荷検証が必須 |
| Compose直下の制限 | ローカルで明快 | orchestrator移行時に再設計 |
| `deploy.resources` | limits/reservationsを仕様化 | 実行基盤の対応を確認する |

本番では「物理容量 − OS/daemon/監視の余白」を先に確保する。全limit合計を物理RAMぎりぎりにしない。

## 5–7. Guided lab（150分）

### 時間配分

- 0–20分：環境とbaseline
- 20–55分：sample作成/build
- 55–85分：制限の検証と測定
- 85–120分：failure injection
- 120–140分：security/size/performance review
- 140–150分：成果物とcleanup

### Step 0 — 環境確認

```bash
mkdir -p docker-resource-lab
cd docker-resource-lab
docker version
docker compose version
docker info --format '{{json .Warnings}}'
docker info --format 'Cgroup={{.CgroupVersion}} Driver={{.CgroupDriver}} CPUs={{.NCPU}} Memory={{.MemTotal}}'
```

1–2行目は専用build contextを作る。3–4行目は互換性確認。5行目はkernel警告、6行目はcgroup版とhost容量の記録。`Cgroup=2`が一般的だが環境差を即異常としない。

**Checkpoint A:** daemonへ接続でき、hostのCPU/RAMと警告を記録した。

### Step 1 — 完全なsample files

`app.py`:

```python
import hashlib, json, os, time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlparse

ALLOCATIONS = []
class Handler(BaseHTTPRequestHandler):
    def send_json(self, status, payload):
        body = json.dumps(payload).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers(); self.wfile.write(body)
    def do_GET(self):
        u = urlparse(self.path); q = parse_qs(u.query)
        if u.path == "/healthz":
            return self.send_json(200, {"status":"ok", "pid":os.getpid()})
        if u.path == "/allocate":
            mib = min(int(q.get("mib", ["1"])[0]), 1024)
            ALLOCATIONS.append(bytearray(mib * 1024 * 1024))
            return self.send_json(200, {"allocated_mib":mib, "chunks":len(ALLOCATIONS)})
        if u.path == "/cpu":
            seconds = min(float(q.get("seconds", ["1"])[0]), 30)
            end = time.monotonic() + seconds; rounds = 0
            while time.monotonic() < end:
                hashlib.sha256(str(rounds).encode()).digest(); rounds += 1
            return self.send_json(200, {"busy_seconds":seconds, "rounds":rounds})
        self.send_json(404, {"error":"not found"})
    def log_message(self, fmt, *args):
        print(json.dumps({"client":self.client_address[0], "message":fmt % args}), flush=True)

ThreadingHTTPServer(("0.0.0.0", 8080), Handler).serve_forever()
```

`ALLOCATIONS`は参照を保持してGC解放を防ぐ。`bytearray`でMiB単位に確保する。`min`はラボ誤操作を抑える。`monotonic`は時計変更に影響されない。スレッド型serverはPID/タスク観察にも使える。負荷endpointは本番公開禁止。

`Dockerfile`:

```dockerfile
# syntax=docker/dockerfile:1
FROM python:3.13-slim
WORKDIR /app
COPY --chown=10001:10001 app.py /app/app.py
USER 10001:10001
EXPOSE 8080
HEALTHCHECK --interval=5s --timeout=2s --start-period=3s --retries=3 \
  CMD ["python", "-c", "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8080/healthz', timeout=1)"]
CMD ["python", "/app/app.py"]
```

- `FROM`は小さめのruntime。本番はdigest固定と更新手順を併用。
- `WORKDIR`は基準directory、`COPY --chown`は専用UID所有でコピー。
- `USER`でrootを避ける。`EXPOSE`はmetadataであり公開ではない。
- `HEALTHCHECK`は5秒間隔、2秒timeout、起動猶予3秒、3連続失敗でunhealthy。
- exec形式`CMD`はshellを挟まずsignalを予測しやすくする。

`compose.yaml`:

```yaml
services:
  api:
    build:
      context: .
    image: local/resource-lab:2026-07-22
    ports:
      - "127.0.0.1:8080:8080"
    mem_limit: 128m
    mem_reservation: 64m
    memswap_limit: 128m
    cpus: 0.50
    pids_limit: 64
    read_only: true
    tmpfs:
      - /tmp:size=16m,mode=1777
    cap_drop:
      - ALL
    security_opt:
      - no-new-privileges:true
    init: true
    restart: "no"
```

- loopback bindは外部NICへの不用意な公開を防ぐ。
- `mem_limit`はhard 128 MiB、`mem_reservation`はsoft 64 MiB。
- `memswap_limit`をRAM limitと同値にして追加swapを禁止。
- `cpus`は0.5 CPU相当、`pids_limit`は64 task。
- read-only root filesystemにし、`/tmp`だけ16 MiB tmpfs。
- capabilityを全dropし、権限昇格を禁止。
- `init`でsignal転送/zombie回収を改善。
- OOM証拠を観察するため自動restartしない。本番方針はSLOに合わせる。

`.dockerignore`:

```text
.git
.env
__pycache__/
*.pyc
notes/
```

contextを縮小し偶発混入を防ぐが、secret managerの代わりではない。

### Step 2 — 検証、build、起動

```bash
docker compose config
/usr/bin/time -f 'build=%e sec' docker compose build --pull
docker image inspect local/resource-lab:2026-07-22 --format '{{.Size}} bytes'
docker compose up -d
docker compose ps
curl -sS http://127.0.0.1:8080/healthz
```

`config`は補間後の構成を検証（secret入り環境で出力を共有しない）。`--pull`はbase更新を確認。サイズとbuild時間をbaseline化し、`ps`でhealthyを待ってHTTP 200も別確認する。

期待例：

```text
NAME                      STATUS             PORTS
docker-resource-lab-api-1 Up ... (healthy)   127.0.0.1:8080->8080/tcp
{"status": "ok", "pid": 7}
```

**Checkpoint B:** healthyかつHTTP 200。`init: true`ならapp PIDが1でなくても正常。

### Step 3 — 宣言でなくruntimeを確認

```bash
CID=$(docker compose ps -q api)
docker inspect "$CID" --format 'Memory={{.HostConfig.Memory}} Reservation={{.HostConfig.MemoryReservation}} MemorySwap={{.HostConfig.MemorySwap}} NanoCPUs={{.HostConfig.NanoCpus}} Pids={{.HostConfig.PidsLimit}}'
docker stats --no-stream "$CID"
docker compose exec api sh -c 'id; cat /sys/fs/cgroup/memory.max; cat /sys/fs/cgroup/cpu.max; cat /sys/fs/cgroup/pids.max'
```

`CID`は正確な対象ID。`inspect`でdaemonの実値を読む。期待は`Memory=134217728`、`Reservation=67108864`、`MemorySwap=134217728`、`NanoCPUs=500000000`、`Pids=64`。cgroup v2ならおおむね次になる。

```text
134217728
50000 100000
64
```

`cpu.max`は100ms期間に50ms＝0.5 CPU。cgroup v1/Desktopではpathや表示が異なるので、`inspect`を共通確認点にする。

**Checkpoint C:** Compose、`inspect`、cgroupの3層が一致する。

### Step 4 — CPU測定

```bash
/usr/bin/time -f 'elapsed=%e sec' curl -sS 'http://127.0.0.1:8080/cpu?seconds=5'
docker stats --no-stream --format 'CPU={{.CPUPerc}} MEM={{.MemUsage}} PIDS={{.PIDs}}' "$CID"
```

負荷中は別terminalで連続観察する。

```bash
docker stats --format 'CPU={{.CPUPerc}} MEM={{.MemUsage}} PIDS={{.PIDs}}' "$CID"
```

1 CPU換算でCPU%は概ね50%付近が上限。ただしDesktop、CPU数、sampling windowで揺れる。同条件を3回測り中央値を比較する。

## 8. Failure injectionとsystematic debugging

### A — OOM

```bash
docker stats --no-stream "$CID"
curl -sS 'http://127.0.0.1:8080/allocate?mib=32'
docker stats --no-stream "$CID"
curl -v 'http://127.0.0.1:8080/allocate?mib=160' || true
docker compose ps -a
docker inspect "$CID" --format 'Status={{.State.Status}} Exit={{.State.ExitCode}} OOMKilled={{.State.OOMKilled}} Error={{json .State.Error}}'
docker compose logs --no-color --timestamps --tail=50 api
```

期待：接続が切れ、containerはexited、多くのLinux環境で`Exit=137 OOMKilled=true`。137は手動SIGKILLでも出るためOOM確定材料ではない。

診断順序は固定する。

1. **現象**：timeout/reset/遅延/restartを区別。
2. **状態**：`ps -a`と`.State`でexit、code、OOM flag。
3. **制約**：`inspect`で実際のMemory/NanoCPUs/PidsLimit。YAMLを見ただけで終えない。
4. **時系列**：timestamps付きlogs、events、metricsを同じ時計へ並べる。
5. **仮説検証**：同入力で再現。limitを上げる前にleak、入力上限、並列度を調べる。

```bash
docker events --since 10m --until 1m --filter container="$CID"
docker compose up -d
CID=$(docker compose ps -q api)
curl -sS http://127.0.0.1:8080/healthz
```

`events`は1分で終了。後半3行は復旧して新CIDを取り直す。

### B — CPU throttlingをcrashと誤認しない

terminal A:

```bash
curl -sS 'http://127.0.0.1:8080/cpu?seconds=20'
```

terminal B:

```bash
for i in 1 2 3 4 5; do
  curl -sS -o /dev/null -w 'code=%{http_code} time=%{time_total}\n' http://127.0.0.1:8080/healthz
done
docker inspect "$CID" --format 'Running={{.State.Running}} OOM={{.State.OOMKilled}} Health={{.State.Health.Status}}'
```

期待：計算量は抑制されるがrunning。thread競合でhealth latencyは増え得る。「遅い＝停止」ではない。

### C — PID上限（optional）

```bash
docker compose exec api python -c 'import subprocess,time; p=[subprocess.Popen(["sleep","10"]) for _ in range(80)]; print(len(p)); time.sleep(1)'
docker stats --no-stream "$CID"
```

期待：途中で`BlockingIOError: Resource temporarily unavailable`等になり、host全体でなくcgroup内で生成が拒否される。PIDSにはthreadも含まれる。

**Checkpoint D:** OOM、CPU throttling、PID枯渇を別々の証拠で説明できる。

## 9. Security、size/performance、本番checklist

### Security review

- 非root、read-only、全cap drop、no-new-privilegesを採用。
- loopbackだけに公開。`/allocate`と`/cpu`は本番では削除。
- resource limitはDoSのblast radiusを狭めるが、認証/rate limit/request size上限の代替ではない。
- base imageの脆弱性、digest、更新頻度をCI管理。
- secretはbuild args/ENV/Dockerfile/Composeへ入れない。BuildKit secretまたはruntime secret storeを使う。
- Docker socketをcontainerへmountしない。

### Image sizeとperformance測定

```bash
docker image inspect local/resource-lab:2026-07-22 --format 'bytes={{.Size}}'
docker history --no-trunc local/resource-lab:2026-07-22
for i in 1 2 3; do curl -sS -o /dev/null -w '%{time_total}\n' http://127.0.0.1:8080/healthz; done
docker stats --no-stream --format '{{.Name}},{{.CPUPerc}},{{.MemUsage}},{{.PIDs}}' "$CID"
```

記録：image `______ bytes`、最大layer `______`、build初回/再build `____/____ sec`、health p50/p95 `____/____ sec`。最低3回、可能なら30回測り、idle/通常/peak/障害直前を分ける。サイズだけを削って証明書やdebug可能性を失わない。

### Production-readiness checklist

- [ ] idle/通常/peak/異常入力のmemory working setを測定
- [ ] GC/runtime、child process、page cache込みの余裕幅
- [ ] CPU limit下でp95/p99とthroughputがSLO内
- [ ] PID上限は正常最大並列より高く、暴走を抑える
- [ ] OOMKilled、restart count、CPU throttling、memory pressureをalert化
- [ ] restart/backoffがretry stormを起こさない
- [ ] healthcheckは軽量で、依存障害時の意味が明確
- [ ] hostにOS/daemon/monitoring用CPU/RAM余白
- [ ] 非root、cap drop、read-only、no-new-privilegesを検証
- [ ] secretsがimage/Composeにない
- [ ] load test入力、結果、Docker/host versionを保存
- [ ] rollback手順と制限変更のreviewerが明確

## 10–11. Deliverablesとcleanup

### 成果物

1. `app.py`、`Dockerfile`、`compose.yaml`、`.dockerignore`
2. `docker compose config`成功記録
3. Memory/Reservation/Swap/NanoCPUs/PidsLimitの`inspect`結果
4. idle/CPU/memory負荷の`stats` snapshot
5. OOM時のexit code、OOMKilled、logをまとめたincident note
6. image bytes、build時間、health latency表
7. 本番候補値と根拠（観測値・余裕幅・同時実行数）

```text
発生時刻:
ユーザー影響:
証拠: Exit=___ / OOMKilled=___ / usage=___ / limit=___
直接原因と寄与要因:
恒久対策と検証方法:
```

cleanup前に対象確認：

```bash
docker compose ps -a
docker image ls local/resource-lab:2026-07-22
docker compose down
```

`down`はこのprojectのcontainer/networkを削除する。named volumeはない。

> [!danger] 任意のイメージ削除
> 本当に必要な場合だけ正確なtagを再確認し、`docker rmi local/resource-lab:2026-07-22`を実行する。`docker rm -f`やpruneは不要。特に`docker system prune -a --volumes`を掃除目的で実行しない。

## 12. Assessment

### Q1. `mem_limit`と`mem_reservation`の違いは？
<details><summary>回答</summary>`mem_limit`はhard ceiling。reservationは競合時のsoft targetで、常時超過を禁止しない。</details>

### Q2. exit 137だけでOOMと断定できない理由は？
<details><summary>回答</summary>137は通常128+SIGKILL(9)。手動killでも出るため、`OOMKilled`、memory event、log、時刻を合わせる。</details>

### Q3. `cpus: 0.50`とCPU sharesの違いは？
<details><summary>回答</summary>`cpus`はquota ceiling。sharesは競合時の相対weightで、余剰時の上限ではない。</details>

### Q4. `mem_limit: 128m`と`memswap_limit: 128m`の意味は？
<details><summary>回答</summary>RAM上限とmemory+swap合計が同じため追加swapを許さない。環境対応を`inspect`と試験で確認する。</details>

### Q5. unhealthyならEngineが必ず再起動する？
<details><summary>回答</summary>しない。health statusと再起動/置換は別機能で、実行基盤ごとに設計する。</details>

### Interview/design question

2 GiB VMで、平常60 MiB、p99 110 MiB、まれに160 MiBのAPIを8個動かしたい。OS/daemon/監視に512 MiB必要。limit、replica数、swap、alert、負荷試験をどう設計するか。容量計算、SLO、障害半径、restart stormまで述べる。

### Follow-up challenge（Optional advanced / Specialized）

cgroup v2の`memory.events`、`memory.current`、`cpu.stat`を10秒ごとに採取し、`oom_kill`と`nr_throttled`増分をCSV化するread-only scriptを作る。「0.25 CPU/96 MiB」と「1 CPU/256 MiB」を各3回比較し、throughput、p95、OOM有無から容量提案を書く。監視containerへDocker socketや過剰capabilityを与えない。

## 13. 現行Docker公式資料（2026-07-22確認）

- [Resource constraints](https://docs.docker.com/engine/containers/resource_constraints/)
- [Runtime metrics](https://docs.docker.com/engine/containers/runmetrics/)
- [docker container stats](https://docs.docker.com/reference/cli/docker/container/stats/)
- [Compose services reference](https://docs.docker.com/reference/compose-file/services/)
- [Compose Deploy Specification](https://docs.docker.com/reference/compose-file/deploy/)
- [Running containers](https://docs.docker.com/engine/containers/run/)
- [Dockerfile HEALTHCHECK](https://docs.docker.com/reference/dockerfile/#healthcheck)
- [Docker Engine security](https://docs.docker.com/engine/security/)

**今週の一文：制限値はYAMLに書いた瞬間ではなく、負荷時のSLOと障害時の証拠を確認した瞬間に設計になる。**
