---
tags: [security, devops, docker, kubernetes, terraform, linux, cloudsecurity, observability, daily]
---

[[Home]]

# SecDevOps Magazine — 2026-04-17

#security #devops #docker #kubernetes #terraform #linux #cloudsecurity #observability #daily

## 号情報
- **Issue:** #2
- **Topic + Level:** **Observability (Prometheus/Grafana/OpenTelemetry) — Middle**
- **学習アーク:** Beginner → Middle → Advanced（3日サイクル反復）
- **Prerequisites（Middle向け前提）:**
  - Beginner相当のCloud Security基礎（IAM・最小権限）
  - Linux基本コマンド（`grep`, `curl`, `journalctl`, `ss`）
  - Docker/Kubernetesの基本用語（Pod, Service, Container）

---

## 1) Topic + Level
**Observability (Prometheus/Grafana/OpenTelemetry) — Middle**

「監視」から一歩進んで、**Metrics / Logs / Traces** をつなぎ、障害原因を短時間で特定する実践力を育てる。

---

## 2) Why it matters in real projects
実プロジェクトでは「落ちたかどうか」だけ分かっても遅いです。必要なのは、
- どこで遅延が始まったか
- どの依存先でエラーが増えたか
- リリース変更と障害発生が相関しているか

を即座に見抜くこと。

Observabilityが整っているチームは、MTTR（平均復旧時間）を短縮し、夜間障害対応の消耗を大幅に減らせます。

---

## 3) Core concepts（要点）
1. **Metrics（数値時系列）**
   - 例: `http_requests_total`, `latency_p95`
   - 異常検知・SLO評価の基盤
2. **Logs（事実の記録）**
   - エラー本文、スタックトレース、業務ID
   - 「何が起きたか」を追う
3. **Traces（処理の道筋）**
   - 1リクエストが複数サービスをどう通過したか
   - 遅延ポイント特定に強い
4. **Golden Signals**
   - Latency / Traffic / Errors / Saturation
5. **OpenTelemetry（OTel）**
   - テレメトリ収集の共通規格
   - ベンダーロックを避けながら統一計測が可能

---

## 4) Hands-on mini lab（30–60分）
**目的:** ミニWeb APIを計測し、Grafanaで異常を見える化する。

### 手順
1. Docker Composeで `app + Prometheus + Grafana` を起動
2. アプリにOTel SDKを入れ、HTTPレイテンシとエラー率をエクスポート
3. Grafanaでダッシュボード作成（RPS, p95 latency, error rate）
4. `hey` または `ab` で負荷をかけ、意図的にエラーを発生
5. Alert rule（例: 5分間のerror rate > 2%）を追加

### 完了条件
- 3つ以上の可視化パネルがある
- アラートが1回発火し、原因を1段落で説明できる
- 「次に改善する観測ポイント」を1つ提案できる

---

## 5) Command cheatsheet
### Linux
```bash
ss -lntp
journalctl -u docker --since "30 min ago"
curl -s http://localhost:9090/-/healthy
curl -s http://localhost:3000/api/health
```

### Docker
```bash
docker compose up -d
docker compose ps
docker compose logs -f prometheus
docker compose logs -f grafana
docker stats
```

### Kubernetes（任意で拡張）
```bash
kubectl get pods -A
kubectl top pods -A
kubectl logs -n observability deploy/prometheus
kubectl port-forward svc/grafana 3000:3000 -n observability
```

### Terraform（監視基盤IaC化の入口）
```bash
terraform fmt
terraform validate
terraform plan -out tfplan
terraform apply tfplan
```

---

## 6) Common mistakes and how to avoid them
1. **メトリクス名・ラベル設計が雑**
   - 回避: 命名規約を先に定義（`service`, `env`, `region` など）
2. **高カーディナリティ地獄（`user_id`等をラベル化）**
   - 回避: 個別IDはログ/トレースへ。メトリクスは集計軸中心
3. **アラートが多すぎて誰も見ない**
   - 回避: まずはSLO直結アラートのみ運用開始
4. **ダッシュボードはあるがRunbookがない**
   - 回避: 各アラートに「最初の3手」を紐づける

---

## 7) One interview-style question
本番で「レスポンス遅延のみ増加、エラー率は低い」状況が発生しました。  
あなたなら **Metrics / Logs / Traces** をどの順番で確認し、どの仮説から潰しますか？理由も説明してください。

---

## 8) Next-step reading links
- OpenTelemetry Docs: https://opentelemetry.io/docs/
- Prometheus Getting Started: https://prometheus.io/docs/introduction/first_steps/
- Grafana Docs: https://grafana.com/docs/
- Google SRE Workbook (Alerting/Monitoring): https://sre.google/workbook/table-of-contents/
- Kubernetes Monitoring: https://kubernetes.io/docs/tasks/debug/debug-cluster/resource-metrics-pipeline/
- OWASP Logging Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html

---

## ローテーション計画（更新）
- Day 1 (Beginner): Cloud Security (IAM) ✅
- Day 2 (Middle): Observability ✅（本日）
- Day 3 (Advanced): Kubernetes incident drills（failure/rollback/recovery）
- Day 4 (Beginner): Secure Coding + OWASPリスク
- Day 5 (Middle): CI/CD Security + Secrets Management
- Day 6 (Advanced): Threat Modeling + Incident Response演習
- Day 7 (Beginner): Docker Hardening + Linux command mastery
- Day 8 (Middle): Terraform/IaC Best Practices
- Day 9 (Advanced): Auth/Session Security deep dive

次号はAdvancedとして、Kubernetes障害訓練（failure injection→rollback→postmortem）に進む。
