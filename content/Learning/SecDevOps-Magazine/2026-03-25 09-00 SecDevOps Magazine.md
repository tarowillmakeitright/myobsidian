---
title: SecDevOps Magazine
date: 2026-03-25 09:00
tags: [security, devops, docker, kubernetes, terraform, linux, cloudsecurity, observability, daily]
---

#security #devops #docker #kubernetes #terraform #linux #cloudsecurity #observability #daily  
[[Home]]

# SecDevOps Magazine — 2026-03-25

今日のテーマは、**“検知して、守って、素早く戻す”**。  
倫理的・防御的・合法的な範囲で、実務に直結する力を積み上げます。

---

## 0) 学習アーク（Beginner → Middle → Advanced の反復）
- Arc 2 / Day 1: Beginner（Cloud IAM最小権限）
- **Arc 2 / Day 2: Middle（今日）** ← Observability + Kubernetes Incident Drill
- Arc 2 / Day 3: Advanced（次号予告）

> 中級は「概念理解」から「運用で再現できる」に進む段階です。

---

## 1) Topic + Level
**Topic:** Observability（Prometheus/Grafana/OpenTelemetry）× Kubernetes Incident Drill（failure / rollback / recovery）× App Incident Response連携  
**Level:** **Middle**

**Prerequisites（Middle向け前提）**
- Linux基本コマンド（`grep`, `curl`, `journalctl`, `ss`）
- Kubernetes基礎（Pod/Deployment/Service, `kubectl get/describe/logs`）
- Docker基礎（イメージ・コンテナ・ヘルスチェック）
- Cloud IAM最小権限の基本（監視閲覧権限と運用権限を分離する考え方）

---

## 2) Why it matters in real projects
本番障害で重要なのは、**「止めないこと」より「早く安全に戻すこと」**です。  
Observabilityが弱いと、障害時に「何が壊れたか」が見えず、復旧が遅れます。

実務では次の3点が成果を分けます：
- **Detection:** しきい値/異常検知で早く気づく
- **Rollback:** 影響を最小化して速やかに切り戻す
- **Recovery + Learning:** 復旧後にRCA（根本原因分析）で再発を防ぐ

---

## 3) Core concepts（clear explanations）
### A. Three Pillars + Trace Context
- **Metrics（Prometheus）**: CPU、latency、error rate などの時系列
- **Logs（Loki/ELKなど）**: 事象の詳細記録
- **Traces（OpenTelemetry）**: リクエストがどこで遅延/失敗したか

3つを関連づけると、"アラートが鳴った理由"を素早く説明できます。

### B. SLI / SLO / Error Budget
- **SLI:** 例）成功率、p95 latency
- **SLO:** 例）99.9%成功率
- **Error Budget:** 失敗を許容できる余地

Error Budgetを使うと、「新機能を急ぐか」「安定化を優先するか」を感覚でなく数字で判断できます。

### C. Kubernetes障害対応の型
1. **Failure Injection（安全な障害注入）**
2. **Detection（アラート確認）**
3. **Mitigation（緩和）**
4. **Rollback（切り戻し）**
5. **Recovery Verification（復旧確認）**
6. **Postmortem（学習）**

### D. AppSec Incident Responseとの接続
インフラ障害とセキュリティイベントは分離しがちですが、実際は連動します。  
例：認証サービスの5xx急増 → 侵入試行/設定ミスの両方を疑う。  
**運用Runbookに「セキュリティ確認項目」を最初から入れる**のが実務的です。

---

## 4) Hands-on mini lab（30–60 min）
**ラボ名:** 「Kubernetes障害ドリル：遅延悪化を検知し、Rollbackして回復を確認する」  
**所要:** 45〜60分

### 目標
- p95 latency悪化をPrometheus/Grafanaで検知
- Deploymentを前バージョンへrollback
- 復旧後に簡易RCAを残す

### 手順（ローカル環境: kind / minikube推奨）
1. サンプルWebアプリをデプロイ（v1）
2. v2として意図的に遅いエンドポイントを混ぜる（安全な学習用）
3. 負荷を軽くかけ、latency/errorを観測
4. アラート条件（例: p95 > 500ms 5分）を確認
5. `kubectl rollout undo` でrollback
6. 正常化（error率・latency）を確認
7. `postmortem.md` に「何が起きたか」「次の予防策」を3項目で記録

### 完了条件
- アラート発火 → rollback → 指標正常化を再現できる
- 10分以内に「検知から切り戻し開始」できる
- RCAメモに**再発防止アクション**が1つ以上ある

---

## 5) Command cheatsheet
### Linux
```bash
# ポート確認
ss -lntp

# 直近ログ（環境に応じてサービス名変更）
journalctl -u kubelet --since "30 min ago" --no-pager

# APIの簡易疎通確認
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8080/health
```

### Docker
```bash
# 稼働コンテナ確認
docker ps

# コンテナログ確認
docker logs --tail 100 <container_name>
```

### Kubernetes
```bash
# 全体状況
kubectl get pods -A -o wide
kubectl get events -A --sort-by=.metadata.creationTimestamp | tail -n 30

# 障害箇所の深掘り
kubectl describe deploy <app> -n <ns>
kubectl logs deploy/<app> -n <ns> --tail=200

# Rollout確認と切り戻し
kubectl rollout history deploy/<app> -n <ns>
kubectl rollout undo deploy/<app> -n <ns>
kubectl rollout status deploy/<app> -n <ns>
```

### Prometheus / Grafana / OpenTelemetry（概念確認）
```bash
# Prometheusターゲット疎通（例）
curl -s http://localhost:9090/-/healthy

# OpenTelemetry Collector稼働確認（例）
kubectl get pods -n observability
kubectl logs deploy/otel-collector -n observability --tail=100
```

### Terraform（運用設定をコードで管理）
```bash
terraform fmt
terraform validate
terraform plan
```

---

## 6) Common mistakes and how to avoid them
1. **メトリクスだけ見てログ/トレースを見ない**  
   - 回避: アラート時のRunbookに「metrics → logs → traces」の順序を固定

2. **閾値が厳しすぎてアラート疲れ**  
   - 回避: SLOベースに再設計し、warning/criticalを分離

3. **rollback手順が未検証**  
   - 回避: 月1回のKubernetes incident drillを定例化

4. **監視権限と変更権限を同一ロールにする**  
   - 回避: IAMでviewer / operatorを分離し、操作は監査ログ必須

5. **復旧後に記録を残さない**  
   - 回避: 5分で書けるpostmortemテンプレを用意

---

## 7) One interview-style question
**Q.** 「Kubernetesでレイテンシ障害が発生したとき、Prometheus/Grafana/OpenTelemetryを使って“原因特定→rollback判断→再発防止”までを、10分でどう進めますか？」

---

## 8) Next-step reading links
- OWASP Incident Response Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/Incident_Response_Cheat_Sheet.html
- Google SRE Workbook (Alerting/On-call): https://sre.google/workbook/table-of-contents/
- Prometheus Docs: https://prometheus.io/docs/
- Grafana Docs: https://grafana.com/docs/
- OpenTelemetry Docs: https://opentelemetry.io/docs/
- Kubernetes Debug Running Pods: https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/
- Kubernetes Rollback (Deployment): https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#rolling-back-a-deployment
- AWS IAM Best Practices: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- Google Cloud IAM: https://cloud.google.com/iam/docs/overview

---

## 次号予告（Advanced）
**Advanced:** Cloud IAM Permission Boundary設計 × Kubernetes Security（RBAC/NetworkPolicy）× インシデント統合演習（攻撃兆候を含む復旧訓練）

**Prerequisites（Advanced向け）**
- 今日のドリル（検知→rollback→RCA）を1回再現済み
- RBACの`can-i`確認を実施した経験
- Terraformで最小1つのIAMロールを管理した経験

継続は最強です。今日の1時間は、将来の大きな障害を確実に短縮します。