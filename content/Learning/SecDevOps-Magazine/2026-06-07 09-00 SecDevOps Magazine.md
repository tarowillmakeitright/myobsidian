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

# SecDevOps Magazine — 2026-06-07

**学習アーク:** Arc 1（Beginner → Middle → Advanced の3日サイクル継続）  
**本日のレベル:** **Middle**  
**今日のテーマ:** **CI/CD Security + Secrets Management（実務向け中級）**

**前提知識:**
- IAM / 最小権限の基本
- Docker build の流れをざっくり理解している
- GitHub Actions / GitLab CI の YAML を読める

---

## 1) Topic + Level
**CI/CD Security + Secrets Management（Middle）**

---

## 2) なぜ実務で重要か
CI/CD は「開発速度を上げる仕組み」ですが、同時に**攻撃者が最も狙いたい自動化経路**でもあります。

実務ではこんな事故が本当に起きます。
- CI の Secret が pull request や build log から漏れる
- deploy 用トークンに権限を盛りすぎて、本番全体が改ざんされる
- `latest` イメージを無条件で使い、意図しないバージョンが本番へ出る
- pipeline 内で検証不足の shell script を実行し、Supply Chain リスクを広げる

CI/CD を安全に設計できると、
**「速く出す」**と**「事故らず出す」**を両立できます。ここは DevOps の実力差がそのまま出る場所です。

---

## 3) Core concepts（実務で使う考え方）

### A. Secret を「置かない」発想が最優先
理想は、CI に長期 Secret を保存しないことです。
- AWS: OIDC 連携で Role Assume
- GCP: Workload Identity Federation
- Kubernetes: 外部 Secret Manager と連携

つまり、**固定鍵を埋め込むより、短期資格情報を都度払い出す**方が安全です。

### B. Pipeline にも最小権限
CI ジョブは「何でもできる bot」になりがちです。
でも本当は、ジョブごとに役割を分けるべきです。
- test job: 読み取り中心
- build job: artifact 作成のみ
- deploy job: 特定環境への更新のみ

1本の万能トークンで全部やる設計は危険です。

### C. 信頼境界（Trust Boundary）を分ける
特に重要なのは次の境界です。
- fork から来た PR
- main branch への merge 後
- staging deploy
- production deploy

外部コントリビュータの PR と、本番 deploy ジョブを同じ権限で動かすのは危険です。
**「誰のコードが、どの権限で、どこまで実行されるか」**を分けましょう。

### D. Build Artifact を信じすぎない
安全なのは「ソースがある」ことではなく、
**どの commit から、どの依存関係で、どの設定で build されたか追跡できること**です。
ここで効くのが以下です。
- Image digest 固定
- SBOM（Software Bill of Materials）
- 署名（cosign など）
- provenance / attestation

### E. Secret は「見えないこと」より「漏れても被害限定」が大事
Secret を完全に漏らさないのが理想ですが、現実には漏えい前提の設計が必要です。
- 短命トークンにする
- 環境ごとに分離する
- ローテーション可能にする
- 利用ログを取る

---

## 4) Hands-on mini lab（30–60分）
**目的:** 危険な CI 設計を見直し、より安全な pipeline に改善する

### シナリオ
あなたはコンテナアプリを GitHub Actions で build / push / deploy しているとします。
現状は以下の問題を抱えています。
- `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` を長期保存している
- `docker build && docker push` を main でも PR でも同じ権限で実行している
- 本番 deploy が branch 制御だけで、人手確認なし
- イメージ参照が `:latest`

### やること
1. 現状の危険点を 5 個書き出す
2. 長期 Secret を OIDC 前提の構成に置き換える設計を書く
3. pipeline を `test` / `build` / `deploy-staging` / `deploy-prod` に分割する
4. `latest` をやめて digest pinning の方針を書く
5. Secret を以下の3カテゴリに分類する
   - なくせる Secret
   - 短期化できる Secret
   - どうしても必要な Secret
6. 本番 deploy 前に必要な control を 2 つ追加する
   - 例: manual approval
   - 例: image scan pass 必須

### 仕上げ条件
以下を満たせば OK です。
- PR 由来のコードは本番権限に触れない
- deploy 用認証は短期化されている
- Artifact の追跡性がある
- rollback しやすいタグ戦略になっている

---

## 5) Command cheatsheet

### Linux
```bash
# 環境変数から Secret 混入をざっと確認
env | grep -Ei 'token|secret|key|password'

# リポジトリ内に秘密情報っぽい文字列がないか軽く確認
grep -RInE '(AKIA|SECRET|TOKEN|PASSWORD|-----BEGIN)' .

# 直近で変更されたCI設定を見る
find . -type f \( -name '*.yml' -o -name '*.yaml' \) | grep -E 'github|gitlab|ci'
```

### Docker
```bash
# イメージのレイヤと履歴確認
docker history myapp:latest

# Digest を確認
docker image inspect myapp:latest --format '{{index .RepoDigests 0}}'

# コンテナイメージをスキャン（trivy がある場合）
trivy image myapp:latest
```

### Kubernetes
```bash
# 現在のデプロイ状態を確認
kubectl get deploy,po -n production

# イメージタグ/ダイジェスト確認
kubectl get deploy myapp -n production -o jsonpath='{.spec.template.spec.containers[*].image}'

# ロールバック履歴
kubectl rollout history deployment/myapp -n production

# ロールバック実行
kubectl rollout undo deployment/myapp -n production
```

### Terraform
```bash
# IaC の基本チェック
terraform fmt -recursive
terraform validate
terraform plan

# 変更差分をレビューしやすく保存
terraform plan -out=tfplan
```

### CI/CD 設計メモ
```bash
# GitHub Actions OIDC の典型イメージ
permissions:
  id-token: write
  contents: read

# image を latest ではなく commit SHA で管理する発想
IMAGE_TAG=${GIT_COMMIT_SHA}
```

---

## 6) Common mistakes と回避策

### 1. PR でも本番 deploy と同じ Secret を見せる
**問題:** 悪意あるコードや事故で Secret が抜かれる  
**回避:** PR 用ジョブは read-only / no-secret / no-deploy に分離する

### 2. `latest` タグ依存
**問題:** 何が本番に出たか追跡しづらい  
**回避:** commit SHA, semver, digest を使う

### 3. CI 用ロールが広すぎる
**問題:** build システム侵害 = クラウド侵害になる  
**回避:** build / deploy / infra-change を別権限に分割

### 4. Secret をログに出してしまう
**問題:** 思った以上に長く残る  
**回避:** `set -x` を乱用しない、マスク設定を確認、エラー出力を設計する

### 5. スキャン結果を無視する
**問題:** 「チェックした気分」だけで止まる  
**回避:** 高重大度の脆弱性や policy violation で pipeline を fail させる

### 6. rollback を考えず deploy する
**問題:** 障害時の復旧が遅れる  
**回避:** 直前 digest を記録し、`kubectl rollout undo` や再deploy手順を事前に用意する

---

## 7) One interview-style question
「GitHub Actions で pull request のテスト、main branch への merge 後の image build、本番 deploy を運用しています。Secret 漏えいと権限過剰を避けるために、job 分離・認証方式・承認フローをどう設計しますか？」

---

## 8) Next-step reading links
- OWASP CI/CD Security Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/CI_CD_Security_Cheat_Sheet.html
- GitHub Actions OIDC: https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect
- AWS IAM Best Practices: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- Google Cloud Workload Identity Federation: https://cloud.google.com/iam/docs/workload-identity-federation
- Kubernetes Secrets good practices: https://kubernetes.io/docs/concepts/configuration/secret/
- Sigstore Cosign: https://docs.sigstore.dev/cosign/overview/
- OpenTelemetry overview: https://opentelemetry.io/docs/concepts/

---

## 次号予告（Advanced / 前提つき）
**予定テーマ:** Kubernetes Incident Drill（障害・rollback・recovery 演習） + Observability 連携  
**前提知識:**
- Kubernetes Deployment / Pod / Service の基本
- `kubectl get/describe/logs` が使える
- CI/CD と image tag / digest の意味を理解している

速く作れる人は多いです。  
でも、**安全に継続運用できる pipeline を組める人**は一気に希少になります。今日はそこに一歩進めた日です。