---
tags:
  - security
  - devops
  - docker
  - kubernetes
  - terraform
  - linux
  - cloudsecurity
  - observability
  - daily
---

[[Home]]

# SecDevOps Magazine — 2026-03-05 (09:00)

## 今日の学習アーク
- **Arc: Cloud Security & IAM基礎 → Observability実装 → Kubernetes障害対応**
- **Day 3/3: Advanced**（次アークは Beginner に戻して再スタート）
- ローテーション対象トラック:
  - Application Security（脅威モデリング / 認証・セッション / インシデントレスポンス）
  - DevOps Core（Docker hardening / Kubernetes / Terraform / Linux / CI/CD security / Secrets management）
  - 追加必須（Cloud Security, Observability, Kubernetes incident drills）

## 1) Topic + Level
**Topic:** Kubernetes Incident Drill 実戦編: **Failure Injection → Rollback → Recovery を90分運用に落とす**  
**Level:** **Advanced**

**Prerequisites（Advanced向け）:**
- Middle回の Observability（Prometheus/Grafana/OpenTelemetry）を使って異常検知できる
- `kubectl rollout status/history/undo` を使える
- IAM/RBAC の最小権限設計（誰が rollback できるか）を説明できる
- 基本的な脅威モデリング（何が壊れたらどう悪用されるか）を言語化できる

## 2) なぜ実案件で重要か
本番は「壊れない」より「壊れた時に早く安全に戻せる」ことが価値です。特に以下が同時に起きます。
- 新リリースで 5xx 増加
- 一部Podだけ異常で再現しにくい
- 緊急対応で権限過多オペレーションが発生しやすい

このドリルを回すことで、**MTTR短縮**だけでなく、
- インシデント時の**権限逸脱防止**
- セッション/認証系障害時の**被害封じ込め**
- 監査ログ付きの**法務・監査説明可能な運用**
を同時に鍛えられます。

## 3) Core concepts（clear explanations）
- **Failure Injection（意図的障害注入）**
  - 例: 誤ったイメージタグ、CPU制限ミス、Secret参照ミス
  - 目的: 「運が悪い障害」を「練習できる障害」に変える
- **Rollback Strategy**
  - Deploymentのリビジョン管理、`rollout undo`、段階的復旧
  - 重要: 「戻す判断基準」を事前定義（Error Rate, p95 Latency, Auth失敗率）
- **Recovery + Hardening**
  - 戻した後に再発防止（CI/CD policy、Admission制御、Secret rotation）
- **Security連携ポイント**
  - Auth/Session異常（例: JWT検証失敗急増）を障害として扱う
  - RBAC最小権限（SREはrollback可、開発者は閲覧中心など）
  - Cloud IAMとK8s RBACの責任境界を分離
- **Legal/Defensive only**
  - 本演習は防御・復旧のための手順のみ。攻撃実行手法や不正侵入は扱わない。

## 4) Hands-on mini lab（30-60 min）
**目標:** 「検知 → 判断 → Rollback → 復旧確認 → ポストモーテム」を1サイクル完了する。

### シナリオ
- `myapp:v2` をデプロイした直後、5xx と p95 latency が上昇
- さらに認証エラー率（401/403）が急増

### 手順
1. `kubectl set image` で意図的に不安定バージョンへ更新（演習用環境のみ）。
2. Grafanaで `Error Rate / p95 / Auth failures` を確認。
3. しきい値超過で「rollback実施」判断を宣言（runbookに時刻記録）。
4. `kubectl rollout undo` で直前安定版へ戻す。
5. 復旧確認（HTTP 200比率、ログ上の認証失敗率低下、trace正常化）。
6. 事後対応:
   - Secretをローテーション
   - CIに `kubectl diff` + policy check を追加
   - インシデントメモ作成（原因・検知・復旧・再発防止）

### 成果物
- `runbook-k8s-incident.md`
- `rollback-evidence.md`（時系列・メトリクス・スクショ）
- `postmortem-template.md`

## 5) Command cheatsheet
```bash
# Linux
date -Iseconds
grep -R "ERROR\|401\|403\|500" ./logs -n | tail -n 50

# Kubernetes rollout / recovery
kubectl get deploy -n prod
kubectl rollout status deploy/myapp -n prod
kubectl rollout history deploy/myapp -n prod
kubectl rollout undo deploy/myapp --to-revision=3 -n prod
kubectl get events -n prod --sort-by=.lastTimestamp | tail -n 30
kubectl logs deploy/myapp -n prod --tail=200

# Auth / RBAC確認
kubectl auth can-i patch deployment/myapp -n prod --as=sre-oncall
kubectl auth can-i get secrets -n prod --as=dev-user

# Docker（イメージ検証）
docker image ls | head
docker scout quickview myapp:v2

# Terraform / IaC（変更点確認）
terraform fmt
terraform validate
terraform plan
```

## 6) Common mistakes and how to avoid them
- **ミス1: メトリクスを見ずに“勘”でrollback**
  - 回避: しきい値ベース（例: 5分平均Error Rate > 2%）で機械的に判断
- **ミス2: rollback権限を全員に付与**
  - 回避: 緊急権限はJIT（Just-In-Time）で期限付き付与
- **ミス3: 戻して終わり、根本対策なし**
  - 回避: postmortemで「検知・判断・実行・改善」を必ず記録
- **ミス4: 認証/セッション異常をアプリ不具合と切り分けない**
  - 回避: Auth失敗率を独立メトリクスとして常設監視
- **ミス5: 秘密情報の扱いを演習で省略**
  - 回避: 演習でもSecret rotationと監査ログ確認をセットで実施

## 7) One interview-style question
「本番障害で 5xx が急増し、同時に 401/403 も増えています。あなたがOn-callなら、どの順番で “安全性を保ちながら” rollback と原因切り分けを進めますか？」

## 8) Next-step reading links
- Kubernetes: Debug Running Pods: https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/
- Kubernetes: Rollback a Deployment: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#rolling-back-a-deployment
- OWASP Incident Response Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/Incident_Response_Cheat_Sheet.html
- NIST Computer Security Incident Handling Guide (SP 800-61r2): https://csrc.nist.gov/publications/detail/sp/800-61/rev-2/final
- OpenTelemetry Docs: https://opentelemetry.io/docs/
- Prometheus Alerting: https://prometheus.io/docs/alerting/latest/overview/
- AWS IAM Best Practices: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- Google Cloud IAM Best Practices: https://cloud.google.com/iam/docs/best-practices

---

## 次アーク予告（明日: Beginner）
- **テーマ候補:** Docker Hardening基礎 + CI/CD Security 入門
- **リセット意図:** 難易度を Beginner に戻し、別テーマで再び Beginner → Middle → Advanced を回す
