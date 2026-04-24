---
title: SecDevOps Magazine
date: 2026-04-24 09:00
tags: [security, devops, docker, kubernetes, terraform, linux, cloudsecurity, observability, daily]
---

# SecDevOps Magazine — 2026-04-24
[[Home]]

#security #devops #docker #kubernetes #terraform #linux #cloudsecurity #observability #daily

---

## 今日のテーマ（Learning Arc 1 / Day 1）

### 1) Topic + Level
**「最小権限IAM + 監視の土台 + Kubernetes障害復旧の入口」 / Beginner**

> これは Beginner 号です。次の Middle/Advanced に進むための前提も最後に明記します。

---

### 2) Why it matters in real projects
本番障害や情報漏えいの多くは、次の3つが弱いと起きやすくなります。

- **権限が広すぎる**（Cloud IAMの設計不足）
- **異常に気づけない**（Observability不足）
- **壊れたとき戻せない**（Kubernetes復旧手順の未整備）

この3点を早い段階で押さえると、開発速度を落とさずに「事故の確率」と「事故時の損失」を下げられます。

---

### 3) Core concepts（やさしく要点）

#### A. Cloud Security（AWS/GCP IAM）
- **Principal（誰が）**、**Action（何を）**、**Resource（どこに）**、**Condition（どの条件で）** を明示する。
- 原則は **Least Privilege（最小権限）**。
- 「最初は広く許可」ではなく、**必要な操作を観測して許可を足す** 方が安全。

#### B. Observability（Prometheus/Grafana/OpenTelemetry）
- **Metrics**: CPU, latency, error率など数値で監視。
- **Logs**: 何が起きたかの時系列記録。
- **Traces**: リクエストがどこで遅い/失敗したかの経路。
- 3つを関連づけると、原因調査の時間が一気に短くなる。

#### C. Kubernetes incident drill（障害訓練）
- 障害対応は「知識」より**手順の反復**が効く。
- 重要なのは以下の順番：
  1. 影響範囲を確認
  2. 暫定復旧（Rollback/Scale）
  3. 根本原因分析（RCA）
  4. 再発防止（Runbook更新）

---

### 4) Hands-on mini lab（30〜60分）

**目標:** 「壊して、気づいて、戻す」を1サイクル体験する。

#### Step 0（準備: 10分）
- `kind` または `minikube` のローカルK8sを用意
- `kubectl` と `docker` が使える状態

#### Step 1（デプロイ: 10分）
- Nginx Deploymentを作成（replicas=2）
- Serviceで公開

#### Step 2（障害注入: 10分）
- わざと不正イメージタグに更新して `ImagePullBackOff` を発生させる

#### Step 3（観測: 10分）
- `kubectl get/describe/logs/events` で原因確認
- 可能なら Prometheus/Grafana で Pod再起動やエラーを確認

#### Step 4（復旧: 10分）
- `kubectl rollout undo` で前バージョンに戻す
- 復旧時間（MTTR）をメモ

#### Step 5（IAMミニ演習: 5〜10分）
- 「S3読み取りだけ可能」などの最小権限ポリシーを JSON で作る
- 不要な `*` 権限がないかチェック

---

### 5) Command cheatsheet

#### Linux
```bash
# 直近エラーを追う
journalctl -p err -n 50

# プロセス/ポート確認
ss -lntp
ps aux --sort=-%cpu | head
```

#### Docker
```bash
docker ps
docker images
docker inspect <container_or_image>
# できるだけ root 実行を避ける（Dockerfileで USER 指定）
```

#### Kubernetes
```bash
kubectl get pods -A
kubectl describe pod <pod>
kubectl logs <pod> --previous
kubectl get events --sort-by=.lastTimestamp
kubectl rollout history deploy/<name>
kubectl rollout undo deploy/<name>
```

#### Terraform（IaCの安全運用）
```bash
terraform fmt -recursive
terraform validate
terraform plan
# apply 前に plan をレビュー（権限変更は特に厳密に）
```

#### IAM設計チェック観点（AWS/GCP共通の考え方）
```text
- Action が * になっていないか
- Resource が * になっていないか
- 管理者権限ロールの常用をしていないか
- 一時クレデンシャル/ロール引受を使っているか
```

---

### 6) Common mistakes and how to avoid them

1. **「とりあえずAdmin権限」**
   - 回避: まずReadOnly + 必要操作ごとに追加。
2. **メトリクスだけ見てログを見ない**
   - 回避: アラート時に Logs/Traces へ飛べる導線を作る。
3. **Rollback手順を本番まで未検証**
   - 回避: 週1回の軽い障害訓練を実施（5〜15分でも効果大）。
4. **Terraformをapply直実行**
   - 回避: `fmt` → `validate` → `plan` → レビュー → `apply` の固定化。

---

### 7) Interview-style question

**Q.** Kubernetes で新しいリリース後に 5xx が急増しました。あなたが最初の10分で行う確認・復旧アクションを、優先順で説明してください。

（期待される観点：影響範囲、直近変更、メトリクス/ログ、ロールバック判断、関係者連携）

---

### 8) Next-step reading links

- OWASP Top 10: https://owasp.org/www-project-top-ten/
- Kubernetes Security Checklist (CIS): https://www.cisecurity.org/benchmark/kubernetes
- Kubernetes Rollback: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#rolling-back-a-deployment
- Terraform Best Practices: https://developer.hashicorp.com/terraform/language/style
- AWS IAM Best Practices: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- GCP IAM Best Practices: https://cloud.google.com/iam/docs/using-iam-securely
- OpenTelemetry Docs: https://opentelemetry.io/docs/
- Prometheus Docs: https://prometheus.io/docs/introduction/overview/
- Grafana Docs: https://grafana.com/docs/

---

## 次号予告（ローテーション）
- **Middle:** Docker hardening + CI/CD security + Secrets管理（前提: Linux基本操作、Dockerfile読解）
- **Advanced:** Threat modeling + Kubernetes incident drill実戦（前提: Middle内容、基本的なネットワーク知識、RBAC理解）

学習アークは **Beginner → Middle → Advanced** を繰り返し、各トラック（AppSec / DevOps / Cloud Security / Observability / K8s Drills）を順番に回します。
