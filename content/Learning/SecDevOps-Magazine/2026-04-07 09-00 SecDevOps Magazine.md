# SecDevOps Magazine — 2026-04-07
[[Home]]

#security #devops #docker #kubernetes #terraform #linux #cloudsecurity #observability #daily

---

## 1) Topic + Level
**Kubernetes Incident Drill（failure / rollback / recovery）+ Observability（Prometheus/Grafana/OpenTelemetry）+ Incident Response 実践**  
**Level: Middle**

> 学習アーク: Beginner → Middle → Advanced（3日ループ）  
> 昨日のBeginner（IAM最小権限）を踏まえ、今日はMiddleとして「障害を観測して安全に戻す」実戦。次回Advancedで「攻撃混在インシデント（権限悪用＋サプライチェーン）」へ進みます。

**Prerequisites（前提）**
- `kubectl get/describe/logs` を使って状態確認できる
- `terraform plan` の差分を読める
- IAM最小権限の基本（CIロールと運用ロールの分離）を理解している

---

## 2) なぜ実務で重要か
実際のプロジェクトでは、障害は「起きる前提」で運用します。問題は**起きないこと**ではなく、**早く検知して安全に戻せるか**です。

- 可用性: rollbackが遅いとSLA違反に直結
- セキュリティ: 事故対応時に権限を広げすぎると二次被害が発生
- 法務/監査: いつ・誰が・何を変更したか追えないと説明責任を果たせない

---

## 3) Core concepts（要点）
- **Golden Signals**: latency / traffic / errors / saturation をまず見る
- **SLO / Error Budget**: どこまで失敗を許容し、どこで止めるか
- **Rollback戦略**: `kubectl rollout undo` か、GitOps/Terraformで前バージョンへ戻す
- **Blast Radius最小化**: Namespace、RBAC、NetworkPolicyで影響範囲を絞る
- **IRの基本フロー**: 検知 → トリアージ → 封じ込め → 復旧 → 振り返り
- **OWASP対応**: 監視不備は Security Logging and Monitoring Failures（A09）に直結
- **Cloud Security接続**: AWS/GCP IAMは「緊急対応ロールを短時間だけ昇格」する設計が重要

---

## 4) Hands-on mini lab（30–60分）
**目標:** 故意にKubernetes障害を起こし、Observabilityで検知して、最小権限でrollback/recoveryする

### Step A（10分）環境準備
```bash
mkdir -p ~/labs/k8s-incident-drill && cd ~/labs/k8s-incident-drill
kubectl create ns drill
kubectl config set-context --current --namespace=drill
```

### Step B（10分）正常系デプロイ
```bash
kubectl create deployment web --image=nginx:1.27
kubectl expose deployment web --port=80 --type=ClusterIP
kubectl rollout status deployment/web
```

### Step C（10分）障害注入（failure）
```bash
kubectl set image deployment/web nginx=nginx:badtag
kubectl rollout status deployment/web --timeout=60s || true
kubectl get pods -o wide
kubectl describe deploy web | sed -n '1,120p'
```

### Step D（10–15分）観測（Observability）
- Prometheusで `kube_pod_container_status_waiting_reason` を確認
- Grafanaでエラー率と再起動回数を確認
- OpenTelemetryを入れている場合はトレースで失敗スパンを追跡

### Step E（10分）rollback / recovery
```bash
kubectl rollout undo deployment/web
kubectl rollout status deployment/web
kubectl get events --sort-by=.lastTimestamp | tail -n 20
```

### Step F（5分）再発防止
- CIで「存在しないイメージタグ」を弾く
- 本番反映前に canary or staged rollout を必須化
- 緊急時ロール昇格は15分TTLに制限

**完了条件**
- 障害検知から復旧までの時刻を記録できた
- 影響範囲（Blast Radius）を説明できた
- 次回防止策を3つ挙げられた

---

## 5) Command cheatsheet
```bash
# Linux
journalctl -u kubelet --since "30 min ago"
ss -lntp

# Kubernetes
kubectl get pods -A
kubectl logs deploy/web --tail=100
kubectl describe pod <POD_NAME>
kubectl rollout history deployment/web
kubectl rollout undo deployment/web
kubectl top pod -n drill

# Docker（ローカル再現）
docker pull nginx:badtag || true
docker image ls | grep nginx

# Terraform（復旧後の定義差分確認）
terraform fmt -check
terraform validate
terraform plan

# IAM確認（例）
aws sts get-caller-identity
gcloud auth list
```

---

## 6) Common mistakes と回避策
1. **障害時にいきなり全部再起動**  
   → まずメトリクス・イベント・ログで原因仮説を作る。

2. **緊急対応でAdmin権限を配りっぱなし**  
   → Break-glassロールにTTLを付け、終了後すぐ剥奪。

3. **rollback手順が人依存**  
   → Runbook化し、月1回ドリルで検証する。

4. **監視ダッシュボードがあるだけで使われない**  
   → しきい値アラートと当番通知（on-call）を運用に組み込む。

---

## 7) One interview-style question
「本番で5xx急増。直前にデプロイがあり、同時に外部API遅延も発生。あなたはどの指標・ログ・トレースをどの順で見て、rollback判断を何分以内に下しますか？」

---

## 8) Next-step reading links
- Kubernetes: Debug Running Pods  
  https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/
- Kubernetes: Rollback a Deployment  
  https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#rolling-back-a-deployment
- Prometheus Querying Basics  
  https://prometheus.io/docs/prometheus/latest/querying/basics/
- Grafana Alerting  
  https://grafana.com/docs/grafana/latest/alerting/
- OpenTelemetry Documentation  
  https://opentelemetry.io/docs/
- OWASP Top 10 A09  
  https://owasp.org/Top10/A09_2021-Security_Logging_and_Monitoring_Failures/
- AWS IAM Best Practices  
  https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- Google Cloud IAM Overview  
  https://cloud.google.com/iam/docs/overview

---

### 次号予告（Advanced）
**予定テーマ:** CI/CD Security + Supply Chain Defense（署名検証、SBOM、秘密情報漏えい時の封じ込め）  
**Prerequisite**
- 今日のK8s障害ドリルを30分以内で再現・復旧できる
- 主要メトリクス（error rate, latency）でrollbackトリガーを説明できる
- 緊急昇格権限のTTL運用を理解している
