---
tags: [security, devops, docker, kubernetes, terraform, linux, cloudsecurity, observability, daily]
---

[[Home]]

# SecDevOps Magazine — 2026-05-28

## 今日の学習アーク
- **Arc:** AppSec × DevOps 基礎強化サイクル（Beginner → Middle → Advanced を反復）
- **本日の位置づけ:** **Beginner**（次回 Middle へ進行予定）
- **次回の前提条件（Middle に進むため）:**
  - Linux 基本コマンド（`grep`, `find`, `chmod`, `journalctl`）を使ってログ確認できる
  - Dockerfile の基本構文を理解している
  - Kubernetes の `Pod`, `Deployment`, `Service` の違いを説明できる

---

## 1) Topic + Level
**Topic:** Kubernetes Incident Drills 入門（failure / rollback / recovery） + Observability 連携の第一歩  
**Level:** **Beginner**

## 2) Why it matters in real projects
本番障害は「起きるかどうか」ではなく「いつ起きるか」の問題です。  
Kubernetes 運用では、デプロイ失敗・誤設定・依存先障害が高頻度で発生します。  
このとき重要なのは、
- 早く異常を検知する（Observability）
- 安全に切り戻す（rollback）
- 影響を最小化して復旧する（recovery）

という一連の筋力です。面接でも実務でも、**「障害時に何をどう見るか」**を話せる人は強いです。

## 3) Core concepts（clear explanations）
- **Failure（障害）:** 期待どおり動かない状態。例：新しいイメージが起動しない。
- **Rollback（切り戻し）:** 直前の安定版に戻す操作。`kubectl rollout undo` が基本。
- **Recovery（復旧）:** サービスを安定状態に戻す全体プロセス（原因確認、修正、再デプロイ含む）。
- **Observability（可観測性）:** システム内部状態を外から理解する能力。
  - **Metrics:** 数値（CPU, メモリ, エラーレート）
  - **Logs:** 文字ログ（例外、警告、業務エラー）
  - **Traces:** リクエスト経路（どこで遅延/失敗したか）
- **OpenTelemetry:** Logs/Metrics/Traces を標準化して収集する仕組み。
- **SLO/SLI の入口:** 「何を守るか（例: 99.9%可用性）」を決めると、障害判断と優先順位が明確になる。

## 4) Hands-on mini lab（30–60 min）
**目標:** 意図的に失敗を起こし、観測して、切り戻して復旧する。

### 準備（5–10分）
- ローカル Kubernetes（`minikube` or `kind`）
- `kubectl` が使えること

### 手順（25–40分）
1. 正常な Deployment を作成（`nginx:1.25` など）
2. `kubectl get pods -w` で状態監視
3. 故意に壊れたイメージへ更新（例: 存在しないタグ）
4. `kubectl describe pod` / `kubectl logs` で失敗理由を確認
5. `kubectl rollout undo deployment/<name>` で切り戻し
6. 復旧後、再度 `kubectl get pods` で正常化確認
7. 振り返りメモ：
   - 検知まで何分かかったか
   - 根拠になったシグナル（Events/Logs/Metrics）は何か
   - 次回短縮できるポイント

### 発展（余裕があれば）
- Prometheus/Grafana を導入済みなら、失敗中の `restart count` と `pod status` を可視化してスクショ保存。

## 5) Command cheatsheet
```bash
# 状態確認
kubectl get pods -A
kubectl get deploy
kubectl get events --sort-by=.metadata.creationTimestamp

# ログ・詳細
kubectl logs <pod-name>
kubectl describe pod <pod-name>
kubectl describe deploy <deploy-name>

# ロールアウト管理
kubectl rollout status deploy/<deploy-name>
kubectl rollout history deploy/<deploy-name>
kubectl rollout undo deploy/<deploy-name>

# 変更適用
kubectl apply -f deployment.yaml
kubectl set image deploy/<deploy-name> <container-name>=nginx:DOES-NOT-EXIST

# Linux補助
watch -n 2 'kubectl get pods'
grep -i "error\|fail" app.log

# Docker補助（イメージ確認）
docker images | head
```

## 6) Common mistakes and how to avoid them
- **ミス1:** いきなり再デプロイして証拠を失う  
  → 先に `describe`, `logs`, `events` を保存。
- **ミス2:** Rollback 前提を作っていない（履歴がない）  
  → `Deployment` を使い、`rollout history` を日常的に確認。
- **ミス3:** 「動いた/動かない」だけで判断  
  → Metrics・Logs・Events を3点セットで見る。
- **ミス4:** 監視項目が多すぎて運用不能  
  → まずは `Pod restart`, `5xx`, `Latency` の3つに絞る。

## 7) One interview-style question
「本番で新しいリリース後に 5xx が急増しました。あなたが最初の10分で行う確認・判断・アクションを、Kubernetes コマンドと観測データを使って具体的に説明してください。」

## 8) Next-step reading links
- OWASP Top 10: https://owasp.org/www-project-top-ten/
- Kubernetes Deployment / Rollout: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Kubernetes Debugging: https://kubernetes.io/docs/tasks/debug/
- OpenTelemetry Docs: https://opentelemetry.io/docs/
- Prometheus Docs: https://prometheus.io/docs/
- Grafana Docs: https://grafana.com/docs/
- AWS IAM Best Practices: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- Google Cloud IAM Overview: https://cloud.google.com/iam/docs/overview

---

## トラック進行メモ（ローテーション管理）
次号以降で以下を順番に回し、難易度を段階的に上げる：
1. Application Security（OWASP/Threat Modeling/Auth/Incident Response）
2. DevOps Core（Docker/K8s/Terraform/Linux/CI-CD/Secrets）
3. Cloud Security（AWS/GCP IAM permission design）
4. Observability（Prometheus/Grafana/OpenTelemetry）
5. Kubernetes Incident Drills（failure/rollback/recovery）

> 学習方針: **守れる設計 → 見える運用 → すぐ戻せる復旧力** を毎日積み上げる。
