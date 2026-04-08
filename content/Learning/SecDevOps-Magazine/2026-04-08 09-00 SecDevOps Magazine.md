# SecDevOps Magazine — 2026-04-08
[[Home]]

#security #devops #docker #kubernetes #terraform #linux #cloudsecurity #observability #daily

---

## 1) Topic + Level
**CI/CD Security + Supply Chain Defense（署名検証 / SBOM / Secrets管理）**  
**Level: Advanced**

> 学習アーク: Beginner → Middle → Advanced（3日ループ）  
> 昨日のMiddle（Kubernetes incident drill + observability）を踏まえ、今日はAdvancedとして「**攻撃混在**（不正イメージ混入 + 権限悪用 + 復旧判断）」に対応します。次回はBeginnerに戻り、基礎を再強化します。

**Prerequisites（前提）**
- `kubectl rollout undo` / `kubectl logs` / `kubectl get events` で復旧の基本操作ができる
- Dockerイメージのタグ/digestの違いを説明できる
- Terraformの `plan` 差分を読める
- AWS/GCP IAMで最小権限の考え方（role分離）を理解している
- Prometheus/Grafana/OpenTelemetryで「異常の兆候」を最低1つ追える

---

## 2) なぜ実務で重要か
実務では「アプリ脆弱性」だけでなく、**ビルド～配布～実行までの供給網（supply chain）**が狙われます。

- 署名なしイメージを本番に入れると、改ざん検知が困難
- CIトークン漏えいは、そのままクラウド権限侵害に直結
- 障害時に復旧を急ぎすぎると、証拠保全や法務対応を壊す

つまり、Application Security（OWASP）、DevOps、Cloud Security、Incident Responseを**1本の運用線**として扱えるチームが強いです。

---

## 3) Core concepts（要点）
- **Artifact Trust Chain**: build provenance（誰が何から作ったか）を追跡
- **Image Signing/Verification**: digest固定 + 署名検証（例: cosign）
- **SBOM**: 依存関係を可視化し、CVE影響範囲を即時判定
- **CI/CD Secret Hygiene**: 長期キー禁止、OIDC短命認証、ローテーション自動化
- **Cloud IAM Permission Design**: 
  - CI role（build/push限定）
  - deploy role（namespace限定）
  - break-glass role（時間制限 + 監査必須）
- **Observability連携**: メトリクス（error rate）+ ログ（auth失敗）+ トレース（遅延経路）で誤検知を減らす
- **Kubernetes Incident Drill**: failure注入→rollback→recoveryを事前反復し、本番判断時間を短縮
- **法務・倫理**: 学習は防御目的のみ。許可された環境で再現し、無断テスト禁止

---

## 4) Hands-on mini lab（30–60分）
**目標:** 「怪しいデプロイ」を検知し、署名/権限/可観測性を使って安全にrollbackする

### Step A（10分）疑似パイプライン準備
```bash
mkdir -p ~/labs/advanced-cicd-drill && cd ~/labs/advanced-cicd-drill
cat > deployment.yaml <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
  namespace: drill
spec:
  replicas: 2
  selector:
    matchLabels: { app: web }
  template:
    metadata:
      labels: { app: web }
    spec:
      containers:
      - name: web
        image: nginx:1.27
        ports:
        - containerPort: 80
YAML
kubectl apply -f deployment.yaml
kubectl rollout status deploy/web -n drill
```

### Step B（10分）failure注入（不正タグ想定）
```bash
kubectl set image deploy/web web=nginx:badtag -n drill
kubectl rollout status deploy/web -n drill --timeout=60s || true
kubectl get pods -n drill
kubectl describe deploy web -n drill | sed -n '1,160p'
```

### Step C（10–15分）観測で根拠収集
```bash
kubectl get events -n drill --sort-by=.lastTimestamp | tail -n 30
kubectl logs deploy/web -n drill --tail=80 || true
```
- Prometheus: 再起動回数・エラー率の急増確認
- Grafana: デプロイ時刻とエラー時刻の相関確認
- OpenTelemetry: 失敗スパンが新リリースに偏っているか確認

### Step D（10分）rollback + recovery
```bash
kubectl rollout undo deploy/web -n drill
kubectl rollout status deploy/web -n drill
kubectl get rs -n drill
```

### Step E（5–10分）再発防止（IaC/CI設定）
```bash
# Terraform (例) 変更前チェック
terraform fmt -check
terraform validate
terraform plan
```
- CIで「署名未検証イメージを拒否」ルール追加
- IAMでCI roleの権限をpush先限定に縮小
- Incident runbookに「証拠保全 → rollback → postmortem」順序を明記

**完了条件**
- 検知からrollbackまでの所要時間を記録できた
- 「なぜrollbackしたか」をメトリクス/ログ/トレースで説明できた
- IAM/CIルール改善を最低2点提案できた

---

## 5) Command cheatsheet
```bash
# Linux
date -Iseconds
grep -R "token\|secret" .

# Docker
docker pull nginx:1.27
docker inspect nginx:1.27 --format '{{.RepoDigests}}'

# Kubernetes
kubectl get deploy,rs,pods -n drill
kubectl rollout history deploy/web -n drill
kubectl rollout undo deploy/web -n drill
kubectl describe pod -n drill <POD_NAME>

# Terraform / IaC
terraform fmt -check
terraform validate
terraform plan

# Cloud Security (IAM確認)
aws sts get-caller-identity
gcloud auth list

# Observability（環境に応じて）
kubectl top pod -n drill
kubectl get events -n drill --sort-by=.lastTimestamp | tail -n 20
```

---

## 6) Common mistakes と回避策
1. **タグだけ見て安全と判断する**  
   → digest固定 + 署名検証を必須化。

2. **障害時に監査ログを取らずに即修正**  
   → まず証拠保全（ログ/イベント/変更履歴）を確保。

3. **CIに広すぎるクラウド権限を付与**  
   → CI roleと運用roleを分離し、短命認証へ移行。

4. **Observabilityをダッシュボード閲覧だけで終える**  
   → rollback判断に使う閾値（例: 5xx率）を事前定義。

5. **Kubernetesドリルを一度だけ実施**  
   → 月次で failure/rollback/recovery を反復訓練。

---

## 7) One interview-style question
「新しい本番デプロイ後にエラー率が上昇。署名検証は通過したが、OpenTelemetryで外部依存の遅延も同時に増えている。あなたは“アプリ起因”と“外部要因”をどう切り分け、rollbackを実行する閾値をどう定義しますか？」

---

## 8) Next-step reading links
- OWASP Top 10（A01/A05/A09など）  
  https://owasp.org/Top10/
- SLSA Supply-chain Levels  
  https://slsa.dev/
- Sigstore Cosign  
  https://docs.sigstore.dev/cosign/overview/
- Kubernetes: Deployment Rollback  
  https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#rolling-back-a-deployment
- Prometheus Querying Basics  
  https://prometheus.io/docs/prometheus/latest/querying/basics/
- Grafana Alerting  
  https://grafana.com/docs/grafana/latest/alerting/
- OpenTelemetry Docs  
  https://opentelemetry.io/docs/
- AWS IAM Best Practices  
  https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- Google Cloud IAM Overview  
  https://cloud.google.com/iam/docs/overview

---

### 次号予告（Beginner）
**予定テーマ:** Secure Coding Basics + OWASP Input Validation + Session Securityの基礎固め
