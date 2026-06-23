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

# SecDevOps Magazine — 2026-06-23

## 1) Topic + Level
**Cloud Security / IAM Permission Design と権限境界の実践**  
**Level: Middle**

**前提知識（Prerequisites）**
- IAM の基本要素を説明できること（User / Group / Role / Policy）
- Least Privilege の考え方を理解していること
- AWS IAM Policy JSON または GCP IAM Role Binding を見て、何となく意味が読めること
- CLI で現在の identity を確認した経験があること

---

## 2) Why it matters in real projects
本番で事故を起こす権限設計は、だいたい「便利だから admin を付けた」から始まります。

現実のプロジェクトでは、こんな場面が頻繁にあります。

- CI/CD が本番環境まで触れる
- Terraform 用の service account が広すぎる
- 開発者が検証用に付けた権限がそのまま残る
- 監査ログはあるのに、誰が何をできるのか整理されていない

IAM はただの設定ではなく、**被害半径（blast radius）を小さくする設計そのもの**です。攻撃者にとっては「侵入後にどこまで横移動できるか」を決める鍵であり、防御側にとっては「1つのミスを全社事故にしない」ための最後の壁でもあります。

Middle レベルでは、単に権限を減らすだけでなく、**役割分離・権限境界・一時権限・監査性**まで考える段階に入ります。

---

## 3) Core concepts

### 3-1. Role ベース設計は“人”ではなく“仕事”に付ける
悪い例:
- `alice-admin`
- `bob-terraform`

良い例:
- `ci-deploy-role`
- `readonly-audit-role`
- `break-glass-admin-role`
- `terraform-plan-role`
- `terraform-apply-prod-role`

ポイントは、権限を人間にベタ付けせず、**職務やユースケースに結び付ける**ことです。人の異動や退職より、役割のほうが管理しやすいです。

### 3-2. Permission Design は “許可” と “境界” の2層で考える
IAM では「何を許可するか」だけ見がちですが、実務ではそれに加えて**どこまで広がれないか**が大事です。

- **Allow Policy**: 何をしてよいか
- **Boundary / Condition / Organization Policy**: どこで止めるか

AWS なら:
- IAM Policy
- Permission Boundary
- SCP (Service Control Policy)
- Condition (`aws:RequestedRegion`, `aws:PrincipalTag`, など)

GCP なら:
- Project / Folder / Organization 階層
- Predefined role / Custom role
- IAM Conditions
- Organization Policy

つまり、権限設計は「足し算」ではなく、**足し算 + 柵づくり**です。

### 3-3. Terraform や CI/CD には専用ロールを分ける
IaC やパイプラインは便利ですが、強い権限を集約しやすい危険ポイントでもあります。

たとえば Terraform 用の権限を以下で分けます。

- `plan` 用: read が中心
- `apply` 用: 書き込み権限あり
- `prod apply` 用: さらに制限、承認付き

CI/CD も同じです。

- build 用ロール
- artifact publish 用ロール
- staging deploy 用ロール
- production deploy 用ロール

**1本の万能ロールにまとめない**のが基本です。

### 3-4. 一時権限（temporary credentials）を基本にする
固定キーは漏れます。ログにも残りにくく、失効忘れも起こります。

優先順位はこうです。

1. Workload Identity / OIDC / AssumeRole などの短期認証
2. ローテーションされた短期クレデンシャル
3. やむを得ない固定キー（最終手段）

特に GitHub Actions, GitLab CI, Kubernetes workload から cloud に触るときは、**長期 Access Key を置かない**方向が今の標準です。

### 3-5. Break-glass は必要。でも平時の運用に使わない
本当に緊急時だけ使う強権限ロールは必要です。ただし条件があります。

- MFA 必須
- 利用理由の記録
- 使用時に通知
- 使用後レビュー
- 常用禁止

「困ったらその admin ロールを使う」は、break-glass ではなく通常運用の崩壊です。

### 3-6. 監査できない権限設計は、良い設計ではない
次の問いにすぐ答えられないなら、再設計の余地があります。

- 本番 DB を読めるのは誰か？
- `iam:PassRole` を使えるのは誰か？
- CI が AssumeRole できる対象は何か？
- 監査用 read-only role は全環境で共通か？

セキュリティは「設定した」で終わりません。**説明できること**が重要です。

---

## 4) Hands-on mini lab (30-60 min)
**テーマ: “広すぎる deploy 権限” を分解して、より安全な構成にする**

### ゴール
- broad admin 的な deploy 権限を発見する
- `deploy-staging` と `deploy-prod` を役割分離する
- prod 側に追加制約を入れる
- 現在の identity と有効権限の確認癖をつける

### パターンA: AWS を想定した机上ラボ
1. 既存の deploy policy を読む
2. 危険アクションを洗い出す
   - `iam:*`
   - `sts:AssumeRole` on `*`
   - `s3:*`
   - `ecs:*` / `eks:*` / `lambda:*` 全許可
3. staging 用 policy を作る
   - 対象 resource を staging に限定
4. prod 用 policy を作る
   - 対象 resource を prod に限定
   - 必要最小限 action のみ許可
   - 可能なら MFA / tag / region condition を追加
5. `break-glass-admin-role` は別ロールに退避
6. 最後に「誰が AssumeRole できるか」を trust policy まで確認

### パターンB: GCP を想定した机上ラボ
1. 現在の project role binding を確認
2. `Editor` / `Owner` が付いた principal を見つける
3. deploy 用 service account を分離
4. staging と prod で service account を分ける
5. Custom Role で deploy に必要な permission だけを整理
6. IAM Conditions で対象や時間条件を検討する

### 仕上げ課題
次の2つを書き出してください。
- **この設計で一番危ない横移動ルートは何か？**
- **その横移動を止める 1 つの制約は何か？**

30〜60分で十分です。大事なのは完璧な policy を作ることではなく、**広すぎる権限を見たときに分解して考える筋力**をつけることです。

---

## 5) Command cheatsheet

### Linux / general
```bash
# JSON を読みやすく整形
cat policy.json | jq

# 文字列検索
grep -R "AssumeRole\|iam:\*\|admin" .

# 差分確認
diff -u old-policy.json new-policy.json
```

### AWS IAM
```bash
# 現在の caller identity
aws sts get-caller-identity

# ロール一覧
aws iam list-roles

# 特定ロールの情報
aws iam get-role --role-name deploy-prod-role

# アタッチ済みポリシー一覧
aws iam list-attached-role-policies --role-name deploy-prod-role

# インラインポリシー一覧
aws iam list-role-policies --role-name deploy-prod-role

# ポリシードキュメントの確認（managed policy version）
aws iam get-policy --policy-arn arn:aws:iam::123456789012:policy/deploy-prod
aws iam get-policy-version --policy-arn arn:aws:iam::123456789012:policy/deploy-prod --version-id v1
```

### GCP IAM
```bash
# 現在のアカウント確認
gcloud auth list

# 現在の project 確認
gcloud config get-value project

# IAM policy 取得
gcloud projects get-iam-policy PROJECT_ID

# service account 一覧
gcloud iam service-accounts list

# role 一覧（project レベル）
gcloud iam roles list --project=PROJECT_ID
```

### Terraform
```bash
# フォーマット
terraform fmt

# 構文確認
terraform validate

# 実行計画
terraform plan

# state 内の resource 確認
terraform state list
```

### Kubernetes / CI 周辺の確認視点
```bash
# K8s 側の service account 確認
kubectl get sa -A

# 現在の context 確認
kubectl config current-context

# Secret を直接作り込んでいないか確認
grep -R "AWS_ACCESS_KEY_ID\|GOOGLE_APPLICATION_CREDENTIALS" .
```

---

## 6) Common mistakes and how to avoid them

### ミス1: “とりあえず AdministratorAccess”
**問題:** 早いけど、事故の被害範囲が最大化します。  
**回避:** まず job function を書き出し、必要 action だけに絞る。

### ミス2: 人間ユーザーと CI/CD に同じ権限を持たせる
**問題:** 監査性も責任分界も崩れます。  
**回避:** Human role と machine role を分ける。

### ミス3: Trust policy / AssumeRole 経路を見ていない
**問題:** 権限そのものより、誰がその権限を“取れるか”のほうが危険なことがあります。  
**回避:** Allow policy だけでなく trust relationship を毎回確認する。

### ミス4: staging と prod の deploy 権限が同一
**問題:** 検証環境侵害から本番へ横移動しやすくなります。  
**回避:** 環境ごとに role を分離し、prod だけ追加制約を入れる。

### ミス5: 長期 access key を CI に保存する
**問題:** 漏えい・棚卸し忘れ・ローテーション漏れの温床。  
**回避:** OIDC / Workload Identity / short-lived credential に寄せる。

### ミス6: 読み取り権限を軽視する
**問題:** 読めるだけでも architecture 情報や secret metadata が漏れ、次の攻撃につながります。  
**回避:** read-only でも scope を絞り、監査専用 role を明示する。

---

## 7) One interview-style question
**質問:**  
「あなたが設計した CI/CD 用 deploy role が広すぎると言われました。どの観点で権限を分解し、どうやって本番への被害半径を減らしますか？」

**考えるポイント:**
- 環境分離（staging / prod）
- job function 分離（build / deploy / infra apply）
- trust policy の制御
- short-lived credential 化
- condition / boundary / org policy の追加
- break-glass の分離

---

## 8) Next-step reading links
- AWS IAM Best Practices  
  https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- AWS Policy evaluation logic  
  https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_evaluation-logic.html
- Google Cloud IAM overview  
  https://cloud.google.com/iam/docs/overview
- Google Cloud IAM Conditions  
  https://cloud.google.com/iam/docs/conditions-overview
- Terraform Security Best Practices (HashiCorp Learn / docs entry points)  
  https://developer.hashicorp.com/terraform
- OWASP Cheat Sheet Series  
  https://cheatsheetseries.owasp.org/

---

## ひとこと
IAM 設計は地味です。でも、現場の事故を本気で減らす力があります。  
派手な exploit を追う前に、**「その権限、本当に必要？」を言える人**になると一気に強くなります。
