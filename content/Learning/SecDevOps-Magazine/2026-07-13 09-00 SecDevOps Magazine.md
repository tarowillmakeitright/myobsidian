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
links:
  - "[[Home]]"
---

# SecDevOps Magazine — 2026-07-13

#security #devops #docker #kubernetes #terraform #linux #cloudsecurity #observability #daily

[[Home]]

今日は **Learning Arc 1 / Middle**。
昨日の **Cloud Security (IAM & Permission Design)** の基礎を前提に、実務で事故が起きやすい **CI/CD Security と Secrets Management** に踏み込みます。

- 今日の位置づけ: **Middle**
- 今回のテーマ: **CI/CD Security: Deploy 権限分離と Secret Injection 設計**
- 前提知識:
  - IAM の principal / action / resource を説明できる
  - Least Privilege の意味がわかる
  - human / CI/CD / app runtime の権限を分ける必要性を理解している

---

## 1) Topic + Level

**CI/CD Security: Deploy 権限分離と Secret Injection 設計** — **Middle**

---

## 2) Why it matters in real projects

実務では、アプリ本体のコードよりも **CI/CD pipeline の権限や secret の扱い** が侵入口になることが珍しくありません。

たとえば:
- GitHub Actions や GitLab CI の token が強すぎて、本番環境まで自由に変更できる
- `docker login` 用 credential や cloud key を pipeline 変数にベタ置きしている
- build job と deploy job が同じ権限を持ち、PR から本番操作できてしまう
- ログに secret が出ていたのに誰も気づかない

CI/CD は「自動化された特権経路」です。
ここが弱いと、1つの repo compromise や 1つの workflow 改ざんで **そのまま supply chain incident** になります。

逆に、CI/CD の権限を分離し、secret 注入を短命化できれば、開発速度を落とさずにかなり堅くできます。

---

## 3) Core concepts

### 3-1. Build と Deploy は別物

まず大事なのは、**build** と **deploy** を分けて考えることです。

- **Build**
  - code checkout
  - test
  - artifact 作成
  - container image build
- **Deploy**
  - cluster / cloud への変更
  - rollout
  - migration 実行
  - secret / config の参照

この2つを同じ job・同じ credential で回すと危険です。
たとえば PR から走る build に deploy 権限があると、悪意ある commit や third-party action の compromise が即本番事故になります。

**原則:**
- PR 用 pipeline は read/build/test 中心
- main branch merge 後だけ deploy 権限
- prod deploy は staging よりさらに強いガードを置く

### 3-2. Secret は「保存方法」だけでなく「注入経路」で考える

secret 管理は「Vault を使ってるから安心」では終わりません。
重要なのは **どこで、誰に、何秒だけ見せるか** です。

見るべき点:
- secret は repo に入っていないか
- CI の環境変数として長く残っていないか
- job log に露出しないか
- deploy 先へ必要最小限だけ渡っているか
- artifact に secret が混ざっていないか

よい設計は、**実行時に短時間だけ取得** です。
例:
- OIDC で cloud role を一時取得
- secret manager から必要なキーだけ読む
- deploy job 内だけ使って job 終了後は残さない

### 3-3. OIDC / Workload Identity を使って static credential を減らす

Middle レベルで必ず押さえたいのがこれです。

悪い例:
- `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` を CI 変数に固定保存
- GCP service account key JSON を repo secret に長期保存

よい例:
- GitHub Actions OIDC → AWS AssumeRole
- GitHub Actions OIDC → GCP Workload Identity Federation
- GitLab CI → OpenID Connect / short-lived credential

これで何が良いか。
- key rotation の負担が減る
- 漏えい時の有効期限を短くできる
- どの workflow が role を取ったか監査しやすい

### 3-4. Environment ごとに権限と承認を分ける

理想的にはこうです。

- **dev**: 自動 deploy 可、広めでもよいが audit 必須
- **staging**: deploy 専用 role、secret は staging 限定
- **prod**: 専用 role、branch 制限、manual approval、必要なら change window

ここで大事なのは、**同じ pipeline 定義でも同じ権限にしない** ことです。
`prod` は常に別格です。

### 3-5. Secret Zero 問題

secret manager から secret を取るにも、最初に認証が必要です。これが **Secret Zero** 問題です。

解き方の定番:
- CI platform の identity を使う
- cloud 側で trust policy を絞る
- repo / branch / workflow 単位で role assumption 条件を付ける

つまり「最初の認証情報」を file や env に置かず、**identity federation** で置き換える発想です。

### 3-6. ログ・artifact・cache も漏えい面になる

開発者は secret store だけ見がちですが、実際には以下も危険です。

- CI log
- test report
- build artifact
- container layer cache
- `.npmrc`, `.docker/config.json`, `.terraform` 周辺ファイル

**守り方:**
- debug 出力を減らす
- マスキングを過信しない
- artifact に含める範囲を明示する
- build context を小さくする

---

## 4) Hands-on mini lab (30-60 min)

### 目標
「PR 用 build と main branch deploy を分離し、static secret 依存を減らす」設計を体験する。

### ラボ構成
手元の任意 repo、または練習用 repo で以下を実施します。
GitHub Actions を例に書くけれど、GitLab CI でも考え方は同じです。

### Part A: pipeline を 2 段に分ける (15分)

1. workflow を以下の 2 種類に分ける
   - `pull_request`: lint / test / image build only
   - `push on main`: deploy 可能

2. 確認すること
   - PR workflow に cloud credential が不要になっているか
   - deploy workflow が main branch 限定になっているか

**達成ライン:**
- 「PR から本番 deploy はできない」と説明できる

### Part B: static secret を棚卸しする (10-15分)

今の CI secrets を紙かメモに書き出して、次の 3 列で分類します。

- 本当に必要
- OIDC / federation に置き換えられる
- 不要 or 削除候補

例:
- `AWS_SECRET_ACCESS_KEY` → 置き換え候補
- `DOCKERHUB_TOKEN` → scope 縮小候補
- `SLACK_WEBHOOK_URL` → 本当に必要か再検討

### Part C: OIDC trust 条件を設計する (15分)

文章で OK。次を埋める。

- どの repo から
- どの branch から
- どの workflow 名だけ
- どの role を assume できるか
- その role は何をできるか

**例の考え方:**
- `repo:myorg/myapp`
- `ref:refs/heads/main`
- `workflow:deploy.yml`
- `role:staging-deployer`
- 権限: `ECR push`, `EKS deploy`, `Secrets read for staging only`

### Part D: secret 漏えいチェック (10分)

以下を確認する。

- workflow 内に `echo $SECRET` 的な記述がないか
- build artifact に `.env` や credential file が入っていないか
- Docker build context に不要ファイルが混ざっていないか
- Terraform plan / apply ログに sensitive 値が出ていないか

### 完了条件

- build と deploy の権限差を言語化できる
- 1つ以上の static secret を短命 credential へ置き換える案が出せる
- prod deploy の追加ガードを 2 つ以上挙げられる

---

## 5) Command cheatsheet

### Linux
```bash
env | sort
printenv | grep -iE 'token|secret|key'
history | tail -n 20
find . -maxdepth 3 \( -name '.env' -o -name '*.pem' -o -name '*.key' \)
rg -n 'AKIA|BEGIN PRIVATE KEY|SECRET|TOKEN' .
```

### Docker
```bash
docker build -t demo-app .
docker history demo-app
cat .dockerignore
docker inspect demo-app | jq '.[0].Config.Env'
```

### Kubernetes
```bash
kubectl get secrets -A
kubectl get serviceaccounts -A
kubectl auth can-i get secrets --as=system:serviceaccount:default:default -n default
kubectl describe deployment <name> -n <namespace>
kubectl rollout status deployment/<name> -n <namespace>
```

### Terraform
```bash
terraform fmt -check
terraform validate
terraform plan
terraform show
terraform output
```

### AWS
```bash
aws sts get-caller-identity
aws iam get-role --role-name <ROLE_NAME>
aws secretsmanager list-secrets
aws ecr get-login-password
```

### GCP
```bash
gcloud auth list
gcloud projects get-iam-policy <PROJECT_ID>
gcloud secrets list
gcloud iam workload-identity-pools list --location=global
```

### GitHub Actions / CI thinking points
```bash
cat .github/workflows/*.yml
rg -n 'secrets\.|id-token:|contents:|pull_request|workflow_dispatch|environment:' .github/workflows
```

---

## 6) Common mistakes and how to avoid them

### ミス1: PR workflow に deploy 権限を持たせる
**回避策:**
PR は build/test のみにする。deploy は main merge 後、または protected environment 経由に限定する。

### ミス2: static cloud key を長期保存する
**回避策:**
OIDC / Workload Identity Federation を使って短命 credential に置き換える。

### ミス3: staging と prod で同じ secret・同じ role を使う
**回避策:**
環境ごとに role / secret / approval を分ける。prod は専用 trust 条件にする。

### ミス4: secret manager を使っているだけで安心する
**回避策:**
取得条件、ログ露出、artifact 混入、job 後の残存まで見る。

### ミス5: third-party action を無警戒に使う
**回避策:**
version pinning する。できれば commit SHA 固定。必要最小限の権限だけ渡す。

### ミス6: `permissions:` を省略する
**回避策:**
GitHub Actions では job ごとに `permissions:` を最小化する。`id-token: write` も必要な job だけ。

### ミス7: debug ログで credential を漏らす
**回避策:**
`set -x` を安易に使わない。出力する変数を選ぶ。mask されても raw file 漏えいは別問題と理解する。

---

## 7) One interview-style question

**質問:**
「GitHub Actions で staging / prod deploy を安全に分離するなら、workflow・OIDC trust・secret 管理をどう設計しますか？」

**考える観点:**
- PR と main merge の分離
- OIDC での一時 credential 化
- environment protection rules
- role の scope
- audit trail の残し方

---

## 8) Next-step reading links

- OWASP CI/CD Security Cheat Sheet  
  <https://cheatsheetseries.owasp.org/cheatsheets/CI_CD_Security_Cheat_Sheet.html>
- OWASP Secrets Management Cheat Sheet  
  <https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html>
- GitHub Actions: Security hardening for GitHub Actions  
  <https://docs.github.com/en/actions/security-for-github-actions/security-guides/security-hardening-for-github-actions>
- AWS: Configuring OpenID Connect in CI/CD  
  <https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html>
- Google Cloud: Workload Identity Federation  
  <https://cloud.google.com/iam/docs/workload-identity-federation>
- Kubernetes Secrets  
  <https://kubernetes.io/docs/concepts/configuration/secret/>
- OpenTelemetry Overview  
  <https://opentelemetry.io/docs/>

---

## 次号予告

次は **Advanced** レベルとして、今日の CI/CD と権限分離の延長で **Kubernetes incident drill: failure / rollback / recovery** を扱うとかなり実務的です。

### Advanced に進む前提
- CI/CD の build と deploy を分離する意味がわかる
- OIDC / short-lived credential の利点を説明できる
- staging / prod で別 role・別 secret・別承認が必要な理由がわかる
- `kubectl rollout` と deployment の基本がわかる
