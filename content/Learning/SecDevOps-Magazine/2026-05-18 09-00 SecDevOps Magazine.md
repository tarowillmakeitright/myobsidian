---
tags: [security, devops, docker, kubernetes, terraform, linux, cloudsecurity, observability, daily]
---

[[Home]]

# SecDevOps Magazine — 2026-05-18

今日の学習テーマは、**Cloud Security（AWS/GCP IAM & permission design）× Kubernetes incident drills（基礎）**です。  
学習アークは **Beginner → Middle → Advanced** で循環します。今回はその1本目として **Beginner** 号です。

## 1) Topic + Level
**Topic:** Cloud Security 入門: IAM最小権限設計 + K8s障害対応の入口  
**Level:** **Beginner**

---

## 2) Why it matters in real projects
本番事故の多くは「攻撃が強かった」よりも、**権限が広すぎた**ことが被害拡大の原因になります。  
- IAMが雑だと、1つの漏えいキーで環境全体にアクセスされる
- K8s運用で障害復旧手順がないと、復旧が人依存になって長期停止する
- CI/CDやTerraformが高権限で動くと、設定ミスが即インフラ全体に波及する

つまり、**最小権限 + 復旧ドリル**は「守り」と「復旧力」を同時に上げる最短ルートです。

---

## 3) Core concepts (clear explanations)
### A. IAMの基本（AWS/GCP共通）
- **Principal（主体）**: User / Role / Service Account
- **Action（操作）**: 何を実行できるか（例: `s3:GetObject`, `container.clusters.get`）
- **Resource（対象）**: どこに対して実行できるか
- **Condition（条件）**: どの状況で許可するか（IP, 時刻, タグなど）

### B. 最小権限（Least Privilege）
- 最初は「必要最小限のAllow」だけ
- ワイルドカード `*` を減らす
- 人間ユーザーより **Role/Service Account中心**に設計
- 期限付き・用途限定の権限を使う

### C. K8s incident drill の入口
- 障害対応は「起きてから考える」と遅い
- 最低限の流れを固定する:  
  1. 検知（アラート）  
  2. 切り分け（Pod/Node/Network/Config）  
  3. 一時復旧（rollback / scale / restart）  
  4. 恒久対策（再発防止）

### D. Observabilityの役割
- **Metrics（Prometheus）**: CPU/Memory/latencyの数値
- **Logs**: エラー文脈
- **Traces（OpenTelemetry）**: リクエスト経路
- Grafanaで可視化し、復旧判断を早くする

---

## 4) Hands-on mini lab (30-60 min)
**目的:** 「広すぎる権限」を見つけて、最小権限に寄せる感覚を掴む

### Lab A (Cloud IAM擬似演習, 20-30分)
1. 手元に `policy.json` を作る（わざと広い権限）
2. 使っている操作を3つだけ列挙（例: read logs, read bucket, deploy image）
3. 不要Actionを削る
4. Resourceを `*` から具体名へ
5. Conditionを1つ追加（例: 特定タグ付きresourceのみ）

### Lab B (K8s復旧ドリル基礎, 20-30分)
1. `kubectl get pods -A` で状態確認
2. テスト用Deploymentのimage tagをわざと誤設定して `ImagePullBackOff` を発生
3. `kubectl rollout undo deployment/<name>` でロールバック
4. 復旧時間（検知〜復旧完了）を記録

**完了条件:**
- IAMポリシーの `Action` と `Resource` が具体化されている
- K8sで1回ロールバック成功している

---

## 5) Command cheatsheet
### Linux
```bash
# 直近ログ確認
journalctl -xe --no-pager | tail -n 50

# 設定ファイル差分確認
git diff
```

### Kubernetes
```bash
kubectl get pods -A
kubectl describe pod <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace> --tail=100
kubectl rollout history deployment/<deploy> -n <namespace>
kubectl rollout undo deployment/<deploy> -n <namespace>
```

### Docker
```bash
docker ps
docker images
docker inspect <container_or_image>
```

### Terraform
```bash
terraform fmt -recursive
terraform validate
terraform plan
```

---

## 6) Common mistakes and how to avoid them
1. **`Action: *` の放置**  
   → まずRead系とWrite系を分離。必要Actionを明文化してから追加。

2. **CI/CDに管理者権限を渡す**  
   → パイプライン専用Roleを作る。環境ごとにRole分割。

3. **K8s障害時に“勘”で再起動連打**  
   → `describe` / `logs` / `events` を見て根拠を取る。

4. **Observabilityを後回し**  
   → 最低限のメトリクスとダッシュボードを先に用意。

---

## 7) One interview-style question
「本番で使うCI/CD用IAM Roleを設計するとき、**最小権限**をどう定義し、どの順番で検証しますか？  
また、誤権限によるインシデントを想定した**検知とロールバック手順**を簡潔に説明してください。」

---

## 8) Next-step reading links
- OWASP Top 10: https://owasp.org/www-project-top-ten/
- AWS IAM Best Practices: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- Google Cloud IAM Overview: https://cloud.google.com/iam/docs/overview
- Kubernetes RBAC: https://kubernetes.io/docs/reference/access-authn-authz/rbac/
- Kubernetes Incident Response (guide): https://kubernetes.io/docs/tasks/debug/debug-cluster/
- Prometheus Docs: https://prometheus.io/docs/introduction/overview/
- Grafana Docs: https://grafana.com/docs/
- OpenTelemetry Docs: https://opentelemetry.io/docs/
- Terraform Security Best Practices (HashiCorp): https://developer.hashicorp.com/terraform/language/state/sensitive-data

---

### 次号予告（学習アーク）
- **Middle（次回）**: Docker hardening + CI/CD security + Secrets management（前提: Linux基本コマンド、コンテナ基礎）
- **Advanced（次々回）**: Threat modeling + K8s incident drill実戦 + Observability深掘り（前提: Middle内容の実施経験）

一歩ずつでOK。重要なのは「安全に作る力」と「壊れても戻せる力」をセットで伸ばすことです。