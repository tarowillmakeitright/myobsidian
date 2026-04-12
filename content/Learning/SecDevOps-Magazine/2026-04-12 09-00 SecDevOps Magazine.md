# SecDevOps Magazine — 2026-04-12
[[Home]]

#security #devops #docker #kubernetes #terraform #linux #cloudsecurity #observability #daily

---

## 1) Topic + Level
**Cloud Security入門（AWS/GCP IAM Permission Design）+ 観測の第一歩**  
**Level: Beginner**

> 学習アーク: Beginner → Middle → Advanced（反復）  
> 前号のAdvanced（CI/CD supply chain防御）から、今日はBeginnerに戻って「土台」を再構築します。

**Prerequisites（前提）**
- Beginnerのため必須前提なし
- あると良い: Linux基本コマンド（`ls`, `cat`, `grep`）

---

## 2) なぜ実務で重要か
クラウド事故の多くは、ゼロデイより先に**権限ミス（IAM過剰付与）**で起きます。

- 開発速度を優先して `*` 権限を付ける
- CI/CD用の資格情報を長期間使い回す
- 監査ログはあるが、異常検知ルールがない

この状態だと、アプリが安全でも運用で破られます。  
だからApplication SecurityとDevOpsに加えて、**Cloud Security（IAM）+ Observability（検知）+ K8s incident drill（復旧）**をセットで学ぶのが実務的です。

---

## 3) Core concepts（要点）
- **Least Privilege（最小権限）**: その作業に必要な操作だけ許可
- **Role Separation（役割分離）**:
  - Human admin role
  - CI build role
  - Deploy role（対象namespace限定）
- **Temporary Credentials**: 長期キーより短命認証（OIDC/STS）
- **Permission Boundary / Policy Review**: 「許可しすぎ」を継続監査
- **Observabilityの最小構成**:
  - Metrics: 失敗率、認証エラー
  - Logs: 誰がいつ何を変更したか
  - Traces: 遅延や失敗の経路
- **Kubernetes incident drill基礎**:
  - failure（障害注入）
  - rollback（安全に戻す）
  - recovery（正常化確認）
- **倫理・法務**: 学習は許可された環境でのみ。防御目的のみ。無断テスト禁止。

---

## 4) Hands-on mini lab（30–60分）
**目標:** IAM最小権限の考え方を確認し、Kubernetesで軽い障害→rollbackを体験、観測ポイントを記録する

### Step A（10分）Linuxで資格情報の扱い確認
```bash
mkdir -p ~/labs/iam-basics && cd ~/labs/iam-basics
printf "service=demo\nowner=devops\n" > meta.txt
ls -l
grep -n "owner" meta.txt
```

### Step B（10分）クラウド認証コンテキスト確認（読み取りのみ）
```bash
# AWS
aws sts get-caller-identity

# GCP
gcloud auth list
```
チェック観点:
- どのアカウントで実行しているか
- 本当に必要な権限のアカウントか

### Step C（15分）Kubernetesで軽いincident drill
```bash
kubectl create ns drill-iam --dry-run=client -o yaml | kubectl apply -f -
kubectl -n drill-iam create deployment web --image=nginx:1.27
kubectl -n drill-iam rollout status deployment/web

# わざと失敗タグへ
kubectl -n drill-iam set image deployment/web nginx=nginx:badtag
kubectl -n drill-iam rollout status deployment/web --timeout=60s || true
kubectl -n drill-iam get pods

# rollback
kubectl -n drill-iam rollout undo deployment/web
kubectl -n drill-iam rollout status deployment/web
```

### Step D（10分）観測メモを残す
```bash
kubectl -n drill-iam get events --sort-by=.lastTimestamp | tail -n 20
kubectl -n drill-iam describe deployment web | sed -n '1,140p'
```
記録すること:
- 失敗を検知した時刻
- rollback完了時刻
- 原因（bad tag）
- 再発防止案（例: digest固定、CIでタグ検証）

### Step E（任意5–10分）IaCの静的チェック
```bash
terraform fmt -check
terraform validate
```

**完了条件**
- 自分のクラウド実行主体（AWS/GCP）を説明できる
- K8sで failure→rollback→recovery を1回実施
- 「最小権限にするなら何を削るか」を2つ言える

---

## 5) Command cheatsheet
```bash
# Linux
whoami
id
grep -R "AKIA\|SECRET\|token" .

# Docker
docker images
docker inspect nginx:1.27 --format '{{.RepoDigests}}'

# Kubernetes
kubectl get ns
kubectl -n drill-iam get deploy,rs,pods
kubectl -n drill-iam rollout history deployment/web
kubectl -n drill-iam rollout undo deployment/web
kubectl -n drill-iam get events --sort-by=.lastTimestamp | tail -n 20

# Terraform / IaC
terraform fmt -check
terraform validate
terraform plan

# Cloud Security
aws sts get-caller-identity
gcloud auth list

# Observability（最小）
kubectl top pod -n drill-iam
kubectl logs -n drill-iam deploy/web --tail=50
```

---

## 6) Common mistakes と回避策
1. **とりあえずAdmin権限を付ける**  
   → 作業単位でRoleを分離し、不要アクションを削る。

2. **CIシークレットを長期固定**  
   → 短命認証（OIDC/STS）へ移行し、ローテーションを自動化。

3. **Kubernetes障害対応を本番で初実施**  
   → 事前にdrill環境で failure/rollback/recovery を反復。

4. **ログは取るが見ない**  
   → 「何を異常とするか」閾値を決める（例: CrashLoop増加）。

5. **法的境界を曖昧にする**  
   → 許可済み環境のみ、攻撃的行為は行わない。

---

## 7) One interview-style question
「あなたが新規プロジェクトの最初のDevOps担当です。AWS/GCP上でCI/CDを動かすとき、`最小権限` をどう設計し、どのログ/メトリクスを最低限監視対象にしますか？」

---

## 8) Next-step reading links
- OWASP Top 10  
  https://owasp.org/Top10/
- AWS IAM Best Practices  
  https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- Google Cloud IAM Overview  
  https://cloud.google.com/iam/docs/overview
- Kubernetes Rollback  
  https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#rolling-back-a-deployment
- Terraform Best Practices (HashiCorp Learn)  
  https://developer.hashicorp.com/terraform/tutorials/configuration-language
- Prometheus Docs  
  https://prometheus.io/docs/introduction/overview/
- Grafana Docs  
  https://grafana.com/docs/
- OpenTelemetry Docs  
  https://opentelemetry.io/docs/

---

### 次号予告（Middle）
**予定テーマ:** Docker hardening + secrets management + CI/CD security gate（実装寄り）
