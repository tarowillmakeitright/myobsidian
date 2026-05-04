---
tags: [security, devops, docker, kubernetes, terraform, linux, cloudsecurity, observability, daily]
---

# SecDevOps Magazine — 2026-05-04 09:00
[[Home]]

## 学習アーク（3日サイクル）
- Day 1: Beginner（基礎）
- **Day 2: Middle（設計・運用） ← 今日**
- Day 3: Advanced（実戦・復旧）

---

## 1) Topic + Level
**Observability（Prometheus / Grafana / OpenTelemetry）× CI/CD Security — Middle**

**Prerequisites（前提条件）**
- Linux 基本操作（`grep`, `curl`, `journalctl`, `jq`）
- Docker/Kubernetes の基本（Pod, Service, logs）
- Beginner レベルの IAM 最小権限の理解

---

## 2) Why it matters in real projects
本番障害やセキュリティインシデントで一番時間を失うのは「何が起きたか分からない時間」です。  
Observability を整えると、**検知（detect）→ 切り分け（triage）→ 復旧（recover）** が速くなります。さらに CI/CD セキュリティと接続すると、危険な変更を早期に止め、事故の拡大を防げます。

---

## 3) Core concepts（clear explanations）
### A. 3本柱: Metrics / Logs / Traces
- **Metrics（Prometheus）**: CPU, error rate, latency などの時系列
- **Logs**: 事象の詳細証拠
- **Traces（OpenTelemetry）**: リクエストがどこで遅延・失敗したか

### B. SLI / SLO / Error Budget
- **SLI**: 可用性や遅延の測定値
- **SLO**: 目標値（例: 月間 99.9%）
- **Error Budget**: 使ってよい失敗余地。超えそうならリリース速度を落とす

### C. CI/CD Security 連携
- パイプラインで SAST / IaC スキャン / image scan を実施
- 高リスク結果が出たら `deploy` を止める
- 監査可能な形で「誰が・いつ・何をデプロイしたか」を残す

### D. Alert の設計原則
- 人を起こす Alert は「即アクション可能」な条件に限定
- しきい値だけでなく、**継続時間**（5分継続など）も使う
- ノイズ削減（同一原因の重複通知抑制）

---

## 4) Hands-on mini lab（30-60 min）
**目的:** 小さなサービスで「検知→判断→安全停止」を体験する。

1. サンプル API を起動（Docker でも K8s でも可）
2. Prometheus で `request_total`, `error_total`, `latency` を取得
3. Grafana で 1枚ダッシュボード作成（RPS, エラー率, p95 latency）
4. OpenTelemetry を有効化し、失敗リクエストの trace を確認
5. 疑似障害（負荷 or 例外）を入れて Alert 発火を確認
6. CI で `trivy` または `tfsec/checkov` を実行し、Critical 検出時は fail させる

**完了条件**
- 「障害発生から原因候補特定まで」を 10 分以内で説明できる
- CI が高リスク検出時にデプロイをブロックできる

---

## 5) Command cheatsheet
### Linux
```bash
# サービスログを直近100行確認
journalctl -u myapp -n 100 --no-pager

# API の簡易ヘルスチェック
curl -sS http://localhost:8080/health | jq .
```

### Docker
```bash
# コンテナログを追跡
docker logs -f myapp

# イメージ脆弱性スキャン（例: Trivy）
trivy image myapp:latest
```

### Kubernetes
```bash
# Pod 状態・再起動回数確認
kubectl get pods -n app -o wide

# エラーログ確認
kubectl logs deploy/myapp -n app --since=10m

# ロールアウト履歴と戻し
kubectl rollout history deploy/myapp -n app
kubectl rollout undo deploy/myapp -n app
```

### Terraform / IaC
```bash
terraform fmt -recursive
terraform validate
terraform plan

# IaC セキュリティスキャン例
tfsec .
```

---

## 6) Common mistakes and how to avoid them
1. **メトリクスだけ見てログ/トレースを見ない**  
   → 3本柱をセットで扱う。

2. **Alert が多すぎて誰も見ない**  
   → P1条件を絞る。まずは少数精鋭の Alert から。

3. **CI スキャンを warning 扱いで放置**  
   → Critical/High は fail にして例外承認フローを設ける。

4. **ダッシュボードが“きれい”だが意思決定に使えない**  
   → 「次に何をするか」が判断できる指標だけ残す。

5. **復旧手順が人依存**  
   → rollback 手順を runbook 化し、演習で検証する。

---

## 7) One interview-style question
「本番で 5xx が急増したとき、Metrics・Logs・Traces のどれから確認しますか？  
あなたの優先順と、その順番にする理由を説明してください。」

---

## 8) Next-step reading links
- OpenTelemetry Docs: https://opentelemetry.io/docs/
- Prometheus Docs: https://prometheus.io/docs/introduction/overview/
- Grafana Docs: https://grafana.com/docs/
- Google SRE Workbook (Alerting / SLO): https://sre.google/workbook/alerting-on-slos/
- OWASP CI/CD Security Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/CI_CD_Security_Cheat_Sheet.html
- Trivy: https://trivy.dev/latest/
- tfsec: https://aquasecurity.github.io/tfsec/

---

## 次号予告（Advanced）
**Kubernetes incident drills（failure / rollback / recovery）× Incident Response**
- 障害注入（意図的 failure）
- 安全な rollback 判断
- 復旧後の再発防止（postmortem テンプレ）
