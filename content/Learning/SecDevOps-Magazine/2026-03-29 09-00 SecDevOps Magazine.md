---
tags: [security, devops, docker, kubernetes, terraform, linux, cloudsecurity, observability, daily]
---

# 2026-03-29 09:00 SecDevOps Magazine
[[Home]]

#security #devops #docker #kubernetes #terraform #linux #cloudsecurity #observability #daily

> **学習方針:** このマガジンは **倫理的・防御的・合法的** なセキュリティ学習のみを扱います。攻撃手法の悪用は扱いません。

## 1) Topic + Level
**Cloud IAM × Observability × Kubernetes Incident Drill 入門**  
**Level: Beginner**

## 2) Why it matters in real projects
実務では、障害やインシデントの原因は「1つのミス」ではなく、
- IAM権限の設計不備（広すぎる許可）
- 監視不足（異常に気づけない）
- 復旧手順不足（戻せない）

が連鎖して大きくなります。  
今日のテーマは、この3点を最小構成でつなげて理解すること。**「止めない運用」** の基礎になります。

## 3) Core concepts
- **Least Privilege (最小権限):** AWS/GCP IAMで「必要最小限」だけ許可する原則。
- **Role/Service Account 分離:** 人間ユーザーとアプリ実行主体の権限を分ける。
- **Observability:** メトリクス（Prometheus）、可視化（Grafana）、トレース（OpenTelemetry）で状態把握する。
- **Kubernetes Incident Drill:** 意図的に小さな障害を起こし、検知→切り戻し→復旧を練習する。
- **Defense in Depth:** IAM・監視・運用手順を重ねて守る考え方。

## 4) Hands-on mini lab (30-60 min)
### 目的
ローカルKubernetes（kind/minikube）で「障害検知→rollback→復旧」を1回体験する。

### 手順
1. **準備（10分）**
   - kind または minikube を起動
   - `kubectl` で接続確認

2. **アプリデプロイ（10分）**
   - nginx Deployment を 2 replicas で作成
   - Service を作成

3. **観測ポイント確認（10分）**
   - `kubectl get pods -w` で状態監視
   - `kubectl describe pod` / `kubectl logs` を確認

4. **軽い障害注入（10分）**
   - イメージタグを存在しないものに変更（例: `nginx:does-not-exist`）
   - `ImagePullBackOff` を観測

5. **復旧ドリル（10-15分）**
   - `kubectl rollout undo deployment/nginx` で切り戻し
   - Podが `Running` に戻ることを確認
   - 何分で復旧したかメモ

### 完了条件
- 障害状態を確認できた
- rollbackでサービス復旧できた
- 原因・検知・対応を3行で記録できた

## 5) Command cheatsheet
```bash
# Linux
uname -a
journalctl -xe --no-pager | tail -n 30
ss -lntp

# Docker
docker ps
docker images
docker inspect <container_or_image>

# Kubernetes
kubectl get nodes
kubectl get pods -A
kubectl get deploy
kubectl logs deploy/nginx --tail=50
kubectl describe deploy nginx
kubectl rollout history deploy/nginx
kubectl rollout undo deploy/nginx

# Terraform (IAMの原則確認用)
terraform fmt
terraform validate
terraform plan
```

## 6) Common mistakes and how to avoid them
- **ミス1: IAMに `*` を多用する**  
  → 役割ごとにポリシー分離。まずReadOnlyから始める。

- **ミス2: 監視を「入れただけ」で見ない**  
  → 最低1つのSLO/アラートを決め、通知先を確認。

- **ミス3: 復旧を本番で初実施する**  
  → 週次で小さなIncident Drillを実施し、Runbook更新。

- **ミス4: 失敗の記録を残さない**  
  → 「原因・検知・対応・再発防止」を毎回4行で記録。

## 7) One interview-style question
「Kubernetesで障害が起きた際、`kubectl rollout undo` だけに頼る運用のリスクは何ですか？ IAM設計・監視設計の観点も含めて説明してください。」

## 8) Next-step reading links
- OWASP Top 10: https://owasp.org/www-project-top-ten/
- CNCF Kubernetes Basics: https://kubernetes.io/docs/tutorials/kubernetes-basics/
- Kubernetes Rollout/Rollback: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Terraform Best Practices (HashiCorp): https://developer.hashicorp.com/terraform
- AWS IAM Best Practices: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- Google Cloud IAM Overview: https://cloud.google.com/iam/docs/overview
- Prometheus Docs: https://prometheus.io/docs/introduction/overview/
- Grafana Docs: https://grafana.com/docs/
- OpenTelemetry Docs: https://opentelemetry.io/docs/

---

## 学習アーク（ローテーション計画）
- **Day 1 (Beginner):** Cloud IAM + Observability + K8s復旧入門（今日）
- **Day 2 (Middle):** Docker hardening + CI/CD security + secrets management  
  - 前提: Linux基本コマンド、Dockerfile基礎
- **Day 3 (Advanced):** Threat modeling + OWASP対応設計 + Incident response演習  
  - 前提: Webアプリ構成理解、認証/セッションの基礎、Kubernetes基本操作

この3日アークを繰り返しつつ、以下トラックを毎週循環します：
- Application Security（secure coding / OWASP / threat modeling / auth-session / incident response）
- DevOps Core（Docker hardening / Kubernetes security / Terraform IaC / Linux mastery / CI/CD security / secrets management）
- Added Topics（Cloud Security IAM / Observability / Kubernetes incident drills）
