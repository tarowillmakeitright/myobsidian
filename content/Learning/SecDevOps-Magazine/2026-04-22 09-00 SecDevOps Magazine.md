---
tags: [security, devops, docker, kubernetes, terraform, linux, cloudsecurity, observability, daily]
---

# SecDevOps Magazine — 2026-04-22 (09:00)
[[Home]]

#security #devops #docker #kubernetes #terraform #linux #cloudsecurity #observability #daily

前号の Beginner（IAM 基礎）から進み、
**今号は Middle** の実装寄りトレーニングです。  
学習アークは **Beginner → Middle → Advanced** を継続します。

---

## 1) Topic + Level
**Docker Hardening 実践：最小権限コンテナとサプライチェーン防御（Middle）**

> トラック: DevOps core（Docker hardening / CI/CD security / secrets management）+ Application Security（安全な実行境界）

**Prerequisites（前提知識）**
- Linux 基本コマンド（`chmod`, `chown`, `ps`, `ss`）
- Docker 基本（Image / Container / Layer / Volume）
- 前号の IAM 最小権限の考え方（Least Privilege）

---

## 2) Why it matters in real projects
実案件では「動くコンテナ」を作るだけでは不十分で、
**侵害されても被害を小さくする設計**が必須です。

Docker hardening をやる価値:
- 脆弱な依存ライブラリ混入時の被害範囲を縮小できる
- 誤って secret を image に埋め込む事故を防げる
- CI/CD で再現可能なセキュア build を標準化できる
- 監査・インシデント対応時に説明責任を果たしやすい

---

## 3) Core concepts（clear explanations）
1. **Non-root 実行**
   `USER root` のまま本番実行しない。侵害時の権限上限を下げる。

2. **最小ベースイメージ（distroless / slim）**
   不要な shell や package を減らすと攻撃面積が縮小。

3. **Immutable + Read-only filesystem**
   コンテナ内の書き込み可能領域を絞ることで改ざん耐性を上げる。

4. **Secrets は環境分離して注入**
   `Dockerfile` や Git に secret を置かない。Runtime inject を使う。

5. **Image スキャンと署名検証**
   CVE 検出（Trivy 等）+ provenance（SBOM/署名）でサプライチェーン対策。

---

## 4) Hands-on mini lab（30-60 min）
**ラボ名: 「危険な Dockerfile を hardened 化する」**

### 目標
- root 実行を廃止
- 不要 package 削減
- read-only 実行 + capability drop を適用
- スキャン結果を確認して修正サイクルを体験

### 手順
1. まず「悪い例」Dockerfile で build/run
2. `docker inspect` で root 実行を確認
3. `USER 10001`、`--read-only`、`--cap-drop ALL` を適用
4. Trivy で image scan（High/Critical を確認）
5. ベースイメージ更新後に再スキャンし差分比較

### 悪い例（before）
```dockerfile
FROM ubuntu:22.04
RUN apt-get update && apt-get install -y curl vim
WORKDIR /app
COPY . .
RUN npm install
CMD ["npm", "start"]
```

### 改善例（after）
```dockerfile
FROM node:20-bookworm-slim
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev && npm cache clean --force
COPY . .
RUN useradd -u 10001 -r -s /usr/sbin/nologin appuser && chown -R 10001:10001 /app
USER 10001
CMD ["node", "server.js"]
```

実行時オプション例:
```bash
docker run --read-only --cap-drop ALL --security-opt no-new-privileges -p 3000:3000 myapp:secure
```

---

## 5) Command cheatsheet
### Linux
```bash
id
ps aux
ss -lntp
chmod 600 .env
grep -R "API_KEY\|SECRET\|PASSWORD" -n .
```

### Docker
```bash
docker build -t myapp:secure .
docker run --rm -it --read-only --cap-drop ALL --security-opt no-new-privileges myapp:secure
docker inspect myapp:secure | jq '.[0].Config.User'
docker history myapp:secure
```

### CI/CD security（例）
```bash
trivy image --severity HIGH,CRITICAL myapp:secure
syft myapp:secure -o table
```

### Terraform（コンテナ実行ポリシーの考え方）
```hcl
# 例: タスク定義で readonlyRootFilesystem を有効化する方針
# (利用サービスごとに設定項目は異なる)
```

---

## 6) Common mistakes and how to avoid them
- **ミス:** `latest` タグ固定で再現性なし  
  **回避:** digest pin + 定期更新ジョブ

- **ミス:** image に `.env` を COPY してしまう  
  **回避:** `.dockerignore` 整備 + secret manager 利用

- **ミス:** root 実行のまま本番投入  
  **回避:** Dockerfile lint + CI で `USER` 必須チェック

- **ミス:** スキャンを一回だけ実施  
  **回避:** PR 時 + nightly の二段スキャン

- **ミス:** capability をデフォルトのまま  
  **回避:** まず `--cap-drop ALL`、必要最小だけ追加

---

## 7) One interview-style question
「`USER non-root` を設定していても、なぜ `--cap-drop ALL` や `no-new-privileges` が追加で重要なのですか？ 具体的な侵害シナリオで説明してください。」

---

## 8) Next-step reading links
- OWASP Docker Security Cheat Sheet: <https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html>
- Dockerfile Best Practices: <https://docs.docker.com/develop/develop-images/dockerfile_best-practices/>
- Trivy: <https://aquasecurity.github.io/trivy/>
- CNCF Software Supply Chain Best Practices: <https://tag-security.cncf.io/supply-chain-security/>
- NIST SSDF: <https://csrc.nist.gov/Projects/ssdf>

---

## 学習アーク進行メモ
- 2026-04-21: Beginner（Cloud Security: IAM）
- 2026-04-22: **Middle（Docker Hardening）** ← 今ここ
- 2026-04-23（予定）: Advanced（Kubernetes incident drill: failure / rollback / recovery）

次号は必須追加トピックの **Kubernetes incident drills** を Advanced で扱い、
その次に Beginner へ戻して **Observability（Prometheus/Grafana/OpenTelemetry）** を入れます。