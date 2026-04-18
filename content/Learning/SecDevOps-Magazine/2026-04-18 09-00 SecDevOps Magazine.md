---
tags: [security, devops, docker, kubernetes, terraform, linux, cloudsecurity, observability, daily]
---

[[Home]]

# SecDevOps Magazine — 2026-04-18

#security #devops #docker #kubernetes #terraform #linux #cloudsecurity #observability #daily

## 号情報
- **Issue:** #3
- **Topic + Level:** **Kubernetes incident drills (failure/rollback/recovery) — Advanced**
- **学習アーク:** Beginner → Middle → Advanced（3日サイクル反復）
- **Prerequisites（Advanced向け前提）:**
  - Middle相当のObservability運用（Prometheus/Grafana/OpenTelemetry）
  - `kubectl` 基本操作（`get`, `describe`, `logs`, `rollout`）
  - Deployment/Service/ConfigMap/Secretの基本理解
  - Linuxトラブルシュート基礎（`top`, `ss`, `journalctl`, `dmesg`）

---

## 1) Topic + Level
**Kubernetes incident drills (failure/rollback/recovery) — Advanced**

本番で本当に効くのは「知識」だけではなく、**障害時に迷わず動ける手順**です。今日は、意図的に壊して復旧する“守りの筋トレ”をやります。

---

## 2) Why it matters in real projects
実運用では、次のような事故が普通に起きます。
- 誤ったイメージタグをデプロイして 5xx が急増
- HPA/Resource設定ミスでPodが再起動ループ
- Config変更で依存先接続が失敗

このとき重要なのは「誰が悪いか」ではなく、
1) 検知、2) 影響範囲の把握、3) 安全なロールバック、4) 再発防止
を短時間で回すこと。Incident drillをやるチームほど、MTTRが短くなります。

---

## 3) Core concepts（要点）
1. **Failure Injection（制御された障害注入）**
   - わざと失敗を作り、Runbookの有効性を検証する
2. **Rollback Strategy**
   - `kubectl rollout undo` の即応
   - 直前リビジョンが安全かを事前に担保
3. **Recovery Validation**
   - 復旧後に「メトリクス正常化」「エラーレート低下」「依存先疎通」を確認
4. **Blast Radius Control**
   - canary / progressive delivery / PodDisruptionBudgetで被害局所化
5. **Postmortem（責めない振り返り）**
   - タイムライン、根本原因、検知遅延、改善アクションを記録

---

## 4) Hands-on mini lab（30–60分）
**目的:** 意図的なデプロイ障害を発生させ、5〜15分以内に安全復旧する。

### シナリオ
- `webapp` Deployment を `:stable` から `:broken` に更新
- readiness probeを通らず失敗、または5xx増加
- 監視で異常確認後、ロールバックして復旧検証

### 手順
1. 現状確認（正常時メトリクスをスクリーンショット）
2. 障害注入（誤タグ/誤設定を適用）
3. `kubectl rollout status` とアプリログで異常確認
4. `kubectl rollout undo` で1つ前に戻す
5. 復旧後にSLI（latency/error rate）を比較
6. 5行Postmortemを書く（原因・検知・復旧・改善）

### 完了条件
- 障害検知から復旧完了まで15分以内
- 影響範囲（ユーザー影響/対象Pod）を説明できる
- 再発防止アクションを2つ提示できる

---

## 5) Command cheatsheet
### Linux
```bash
date
ss -lntp
journalctl -u kubelet --since "20 min ago"
curl -sS http://localhost:8080/healthz
```

### Docker（ローカル再現用）
```bash
docker images | grep webapp
docker run --rm -p 8080:8080 webapp:stable
docker run --rm -p 8081:8080 webapp:broken
```

### Kubernetes（メイン）
```bash
kubectl config current-context
kubectl get deploy,po,svc -n prod
kubectl rollout history deploy/webapp -n prod
kubectl set image deploy/webapp app=registry.local/webapp:broken -n prod
kubectl rollout status deploy/webapp -n prod --timeout=120s
kubectl logs -n prod deploy/webapp --tail=200
kubectl describe pod -n prod <pod-name>
kubectl rollout undo deploy/webapp -n prod
kubectl get events -n prod --sort-by=.metadata.creationTimestamp | tail -n 30
```

### Terraform（K8s設定をIaC管理している場合）
```bash
terraform fmt
terraform validate
terraform plan -out=tfplan
terraform show -json tfplan | jq '.resource_changes[]?.change.actions'
```

---

## 6) Common mistakes and how to avoid them
1. **復旧より先に原因究明を始めてしまう**
   - 回避: まずサービス復旧（Rollback）→その後に深掘り
2. **`latest` タグ運用でロールバック不能**
   - 回避: immutable tag（例: git SHA）を強制
3. **Probe/Resource上限を未検証で本番投入**
   - 回避: stagingでfailure testを定例化
4. **監視はあるが閾値が鈍く検知が遅い**
   - 回避: SLOベースのalertに寄せる
5. **Postmortemが“犯人探し”になる**
   - 回避: 個人ではなく仕組み改善にフォーカス

---

## 7) One interview-style question
本番で新バージョン展開直後に **error rate 8%**、**p95 latency 2倍** を検知。あなたがIncident Commanderなら、最初の10分で何をどの順序で実行しますか？
（検知 → 連絡 → 切り戻し判断 → 検証まで、具体的コマンドを交えて説明してください）

---

## 8) Next-step reading links
- Kubernetes: Deployment Rollback: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#rolling-back-a-deployment
- Kubernetes Pod Disruptions: https://kubernetes.io/docs/concepts/workloads/pods/disruptions/
- Google SRE Workbook (Incident Response): https://sre.google/workbook/incident-response/
- CNCF TAG App Delivery (Progressive Delivery): https://tag-app-delivery.cncf.io/
- OWASP Incident Response Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/Incident_Response_Cheat_Sheet.html
- OpenTelemetry Docs: https://opentelemetry.io/docs/

---

## ローテーション計画（更新）
- Day 1 (Beginner): Cloud Security (IAM) ✅
- Day 2 (Middle): Observability ✅
- Day 3 (Advanced): Kubernetes incident drills ✅（本日）
- Day 4 (Beginner): Secure Coding + OWASPリスク
- Day 5 (Middle): CI/CD Security + Secrets Management
- Day 6 (Advanced): Threat Modeling + Incident Response演習
- Day 7 (Beginner): Docker Hardening + Linux command mastery
- Day 8 (Middle): Terraform/IaC Best Practices
- Day 9 (Advanced): Auth/Session Security deep dive

次号はBeginnerに戻し、Secure Coding + OWASP Top 10 の基礎を実装寄りで進める。