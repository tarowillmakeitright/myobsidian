---
tags: [security, devops, docker, kubernetes, terraform, linux, cloudsecurity, observability, daily]
---

[[Home]]

# SecDevOps Magazine — 2026-05-31

今日のテーマは **Application Security + DevOps 実践力**。  
このシリーズは Beginner → Middle → Advanced の学習アークを回しながら、現場で使える守りの技術を積み上げます。

---

## 1) Topic + Level
**Cloud IAM設計と最小権限 + Kubernetes障害復旧ドリル + Observability導入基礎**  
**Level: Beginner（学習アーク 1/3）**

---

## 2) Why it matters in real projects
- IAMの設計ミスは、侵害時の被害範囲を一気に拡大します（例: `*` 権限）。
- Kubernetesは「壊れた時に戻せるか」が品質。デプロイ成功より復旧速度が重要です。
- Observability（Prometheus/Grafana/OpenTelemetry）がないと、障害原因が追えずMTTRが悪化します。
- AppSec観点でも、監査ログ・権限境界・セッション監視はインシデントレスポンスの初動を左右します。

---

## 3) Core concepts（clear explanations）
### A. Cloud Security（AWS/GCP IAM）
- **Least Privilege**: 必要最小限の Action / Resource / Condition だけ許可。
- **Role分離**: 人間操作用ロールとCI/CDロールを分ける。
- **Denyの活用**: 事故が多い操作（例: 本番削除）を明示Denyで防ぐ。
- **Permission Boundary / Org Policy**: チーム運用での上限ガード。

### B. Kubernetes incident drill
- **Failure注入**: わざと bad image / env mismatch を出して検知訓練。
- **Rollback**: `kubectl rollout undo` を即実行できる状態を作る。
- **Recovery確認**: Ready復帰、ログ、メトリクス、影響範囲をチェック。

### C. Observability
- **Metrics**: 量的変化（CPU, RPS, latency, error rate）
- **Logs**: 事象の詳細（誰が・何を・いつ）
- **Traces**: リクエスト経路（どこで遅延したか）
- OpenTelemetryで統一計測し、Prometheus/Grafanaで可視化すると、調査コストが下がる。

### D. AppSec接続ポイント
- OWASP Top 10の多くは、認可ミス・入力検証不足・監視不足と結びつく。
- Threat Modelingで「誰がどの権限で何を壊せるか」を先に洗い出す。

---

## 4) Hands-on mini lab（30-60 min）
**目的**: 「壊す→検知→戻す」を1サイクル回す

### 手順
1. kind/minikubeでローカルK8sを起動。
2. 正常な nginx Deployment を apply。
3. `set image` で存在しないタグに変更し、意図的に障害化。
4. `rollout status` と `describe` で失敗を確認。
5. `rollout undo` で復旧。
6. 監視観点として、確認すべきメトリクス・ログ項目をメモ化。
7. IAM演習: サンプルポリシーで `s3:*` / `storage.*` を絞り、最小権限版を作成。

**完了条件**
- 失敗状態と復旧状態を再現できる。
- 「このロールに不要な権限」を3つ以上説明できる。

---

## 5) Command cheatsheet
```bash
# Linux
journalctl -u kubelet --since "30 min ago"
grep -R "error\|denied" ./logs

# Docker
docker scout quickview nginx:latest
docker run --read-only --cap-drop=ALL nginx:stable

# Kubernetes
kubectl get pods -A
kubectl set image deploy/web web=nginx:does-not-exist
kubectl rollout status deploy/web
kubectl describe pod <pod-name>
kubectl rollout undo deploy/web
kubectl get events --sort-by=.metadata.creationTimestamp

# Terraform (IAM設計レビュー向け)
terraform fmt -recursive
terraform validate
terraform plan
```

---

## 6) Common mistakes and how to avoid them
- **ミス1: `*` 権限の放置**  
  → サービス単位で Action を分解し、期限付き例外運用にする。
- **ミス2: ロール共有（人間とCIが同一）**  
  → principalを分離。監査ログで主体が追える設計に。
- **ミス3: ロールバック手順がドキュメントだけ**  
  → 月次で drill 実施。実行時間と詰まりポイントを記録。
- **ミス4: メトリクスだけ見てログ/トレース未整備**  
  → 3本柱（metrics/logs/traces）を最小構成で揃える。
- **ミス5: AppSecとDevOpsが分断**  
  → PRテンプレに脅威観点（認可/入力/秘密情報/監視）を固定項目化。

---

## 7) One interview-style question
「本番Kubernetesで障害が発生し、5xxが急増しています。あなたなら **最初の10分** で何を確認し、どの条件で rollback を判断しますか？ IAMや監査ログの観点も含めて説明してください。」

---

## 8) Next-step reading links
- OWASP Top 10: https://owasp.org/www-project-top-ten/
- OWASP ASVS: https://owasp.org/www-project-application-security-verification-standard/
- AWS IAM Best Practices: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- Google Cloud IAM Overview: https://cloud.google.com/iam/docs/overview
- Kubernetes Security Checklist: https://kubernetes.io/docs/concepts/security/
- Kubernetes Rollout/Rollback: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Prometheus Docs: https://prometheus.io/docs/introduction/overview/
- Grafana Docs: https://grafana.com/docs/
- OpenTelemetry Docs: https://opentelemetry.io/docs/
- Terraform Security Guidance: https://developer.hashicorp.com/terraform/tutorials/security

---

### 次号予告（Middle）
**Prerequisites（Middle進級条件）**
- `kubectl rollout` と `describe/events/logs` の基本操作ができる
- IAM最小権限の考え方（Action/Resource/Condition）を説明できる
- metrics/logs/traces の役割を区別できる

次号では、CI/CD security（署名・SBOM・Policy as Code）と、Threat Modelingを実装ワークフローへ接続します。
