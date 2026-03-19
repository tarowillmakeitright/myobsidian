---
tags: [security, devops, docker, kubernetes, terraform, linux, cloudsecurity, observability, daily]
---
[[Home]]

# SecDevOps Magazine — 2026-03-19 09:00

> 今日から「Beginner → Middle → Advanced」を1アークとして、実務で使えるApplication Security + DevOpsを毎日積み上げます。今回は **Beginner** 回です。

## 今週の学習アーク（進行管理）
- Day 1（今日）: **Beginner** — Kubernetes Incident Drill 入門 + Observability 基礎
- Day 2: **Middle** — Docker/K8s セキュリティ設定と検知（※Prereq: Day 1）
- Day 3: **Advanced** — 侵害を想定した復旧演習 + IAM 最小権限設計（※Prereq: Day 1-2）
- Day 4 以降: 新テーマで再び Beginner から開始（OWASP / Terraform / CI/CD Security / Secrets Management などをローテーション）

---

## 1) Topic + Level
**Topic:** Kubernetes incident drills（failure / rollback / recovery）を題材に、Observability（Prometheus/Grafana/OpenTelemetry）とCloud Security（IAM最小権限）の接続を理解する  
**Level:** **Beginner**

---

## 2) Why it matters in real projects
本番障害は「起きる前提」で設計するのが現実的です。特にKubernetes運用では、
- 誤デプロイ
- 設定ミス（ConfigMap / Secret）
- 権限過剰（IAM / RBAC）
が連鎖すると、復旧が遅れてサービス停止が長引きます。

**Incident Drill（事前演習）**をしておくと、
1. 兆候を観測（Observability）
2. 原因を切り分け
3. 安全に rollback/recovery
をチームで再現でき、MTTR（平均復旧時間）を現実的に短縮できます。

---

## 3) Core concepts（やさしく要点）
- **Failure**: 何が壊れたか（例: 新イメージ投入後にPod CrashLoopBackOff）
- **Rollback**: 直前の安定版へ戻す（`kubectl rollout undo`）
- **Recovery**: 元に戻すだけでなく、再発防止を反映（監視・権限・手順更新）

- **Observability 3本柱**
  - Metrics（Prometheus）: CPU/メモリ/エラー率
  - Logs（Loki/ELK等）: 何が起きたかの記録
  - Traces（OpenTelemetry）: リクエスト遅延のボトルネック

- **Cloud Security (IAM)**
  - 「動く権限」ではなく「必要最小権限」を設計
  - 例: CIロールはECR Pushだけ、運用ロールはRead中心 + break-glassを分離

- **AppSecとの接続**
  - OWASP観点でいう Security Misconfiguration / Broken Access Control は、運用設定と権限設計で悪化/予防される

---

## 4) Hands-on mini lab（30–60分）
**目的:** 故障注入→検知→rollback→振り返りを最小構成で1周する

### 手順
1. ローカルクラスタ準備（kind または minikube）
2. サンプルアプリを v1 でデプロイ
3. 意図的に壊れた v2（不正な環境変数）へ更新
4. `kubectl rollout status` とログで異常確認
5. `kubectl rollout undo` で復旧
6. 再発防止として「ヘルスチェック」「アラート条件」「権限見直し」メモを作成

### 成功条件
- 失敗状態を再現できた
- 5分以内にrollbackできた
- 「なぜ壊れたか」「次回どう防ぐか」を3行で言語化できた

---

## 5) Command cheatsheet
```bash
# Kubernetes 基本
kubectl get pods -A
kubectl get deploy
kubectl describe pod <pod-name>
kubectl logs deploy/<deploy-name> --tail=100
kubectl rollout status deploy/<deploy-name>
kubectl rollout history deploy/<deploy-name>
kubectl rollout undo deploy/<deploy-name>

# Linux 調査
watch -n 2 "kubectl get pods"
grep -R "error\|exception" .

# Docker（イメージ確認）
docker images
docker history <image:tag>

# Terraform（IaCの安全確認）
terraform fmt -recursive
terraform validate
terraform plan
```

---

## 6) Common mistakes and how to avoid them
1. **「監視は入れてるから大丈夫」思考**  
   → ダッシュボードだけでは不十分。**アラート条件**と**対応Runbook**まで用意する。

2. **rollback手順を本番で初実行**  
   → 事前にステージングで drill。役割分担（指揮/実行/記録）を決める。

3. **IAM/RBACが広すぎる**  
   → 読み取り中心に開始し、必要操作をログで確認して段階的に付与。

4. **原因分析せず復旧で終える**  
   → Postmortem で「技術原因 + プロセス原因」を分けて記録する。

---

## 7) One interview-style question
**Q.** Kubernetesで障害時に `rollback` だけで終わらせる運用が危険なのはなぜですか？Observability と IAM の観点も含めて説明してください。  

---

## 8) Next-step reading links
- OWASP Top 10: https://owasp.org/www-project-top-ten/
- Kubernetes: Debug Applications: https://kubernetes.io/docs/tasks/debug/debug-application/
- Kubernetes Rollout: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Prometheus Docs: https://prometheus.io/docs/introduction/overview/
- Grafana Docs: https://grafana.com/docs/
- OpenTelemetry Docs: https://opentelemetry.io/docs/
- AWS IAM Best Practices: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- Google Cloud IAM Best Practices: https://cloud.google.com/iam/docs/using-iam-securely
- Terraform Recommended Practices: https://developer.hashicorp.com/terraform

---

### 明日の予告（Middle）
**テーマ:** Docker hardening + CI/CD security + Secret管理の実践  
**Prerequisites:**
- 今日の「rollbackコマンド」「監視3本柱」「最小権限」の意味を説明できること
- `kubectl logs/describe/rollout` を自力で実行できること
