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

# SecDevOps Magazine — 2026-07-03

## 今日のテーマ
**Linux command mastery + CI/CD security の土台を作る**  
**Level: Beginner**

これは今後の学習アークの出発点です。今回で「安全に作業する Linux 基礎」と「CI/CD を攻撃面として見る視点」を固め、次回以降の Middle / Advanced 回で Docker hardening、Terraform/IaC、Kubernetes、Cloud Security、Observability、Kubernetes incident drills へ段階的につなげていきます。

---

## 1) Topic + Level
**Topic:** Linux command mastery for secure DevOps + CI/CD security の入口  
**Level:** **Beginner**

**この回で身につけること**
- Linux 上で「何が起きているか」を安全に観察する基本コマンド
- CI/CD パイプラインを「便利な自動化」ではなく「重要な攻撃対象」として捉える視点
- 後続トピック（Docker, Kubernetes, Terraform, Cloud IAM, Observability）の前提になる最小限の操作力

---

## 2) Why it matters in real projects
現実の開発現場では、脆弱性はアプリコードだけでなく**実行環境・自動化基盤・権限設計**からも入ってきます。

たとえば:
- 本番障害時に `ps`, `ss`, `journalctl`, `grep`, `tail` を使えないと、原因調査が遅れる
- CI/CD に secrets をベタ書きしていると、ログや artifact 経由で漏えいする
- 危険な shell script をレビューせず流すと、build agent 上で任意コード実行の踏み台になる
- 誰でも main branch に push できると、サプライチェーンリスクが一気に上がる

**強い AppSec / DevOps の人**は、難しいツールを知っている人ではなく、まず**基本操作で状況を正確に見て、安全な自動化の原則を守れる人**です。

---

## 3) Core concepts

### A. Linux command mastery は「破壊せず観察する力」
最初に重要なのは、派手なコマンドではなく**安全な観察系コマンド**です。

- `pwd`, `ls`, `find`: どこに何があるか確認する
- `cat`, `less`, `tail`, `grep`: 設定やログを読む
- `ps`, `top`, `ss`: プロセスや待受ポートを確認する
- `id`, `whoami`, `groups`: 自分の権限を知る
- `chmod`, `chown`: 権限の意味を理解する

セキュリティの基本は、**見えていないものを無理に触らない**ことです。まず観察、次に仮説、最後に変更。この順番が大事です。

### B. CI/CD security は「自動化された本番権限」を守ること
CI/CD はコードをビルドし、テストし、デプロイします。つまり多くの場合、**人間以上に強い権限**を持っています。

守るべきポイント:
- パイプラインで使う secrets を最小化する
- branch protection や approval を設定する
- 外部 action / plugin / container image を安易に信用しない
- build log に secrets が出ないようにする
- artifact や cache に機密が混ざらないようにする

CI/CD の事故は、単なる「ビルド失敗」ではなく、**ソースコード改ざん・秘密情報漏えい・本番侵害**につながります。

### C. 最小権限 (Least Privilege)
この原則は今後の全トピックに共通します。

- Linux: 必要以上に root を使わない
- CI/CD: deploy job にだけ deploy 権限を与える
- Cloud Security: IAM role を細かく分ける
- Kubernetes: service account を使い回さない
- Terraform: 実行用資格情報を絞る

「とりあえず admin」は短期的には楽ですが、長期的には事故の種です。

### D. ログは証拠であり、Observability への入口
Observability の前に、まずログを見る習慣が必要です。

- エラーはいつ始まったか
- 誰の変更後に起きたか
- 同時に別の process / port 変化はないか

今日の基礎は、将来の **Prometheus / Grafana / OpenTelemetry** の理解にも直結します。

---

## 4) Hands-on mini lab (30–60 min)
**ラボ名:** ローカル Linux 環境で「安全な調査」と「危ない CI 設定の発見」をやってみる

### ゴール
- Linux の観察系コマンドを使って環境を把握する
- わざと危ない CI 設定例を読み、問題点を見つける
- secrets をログに出さない意識を持つ

### 手順

#### Part 1: 観察系コマンドに慣れる (15–20分)
ターミナルで実行:

```bash
whoami
id
pwd
ls -la
ps aux | head
ss -tulpn | head
journalctl -n 20 --no-pager
```

**確認ポイント**
- 自分は誰の権限で動いているか？
- どの process が動いているか？
- どのポートが LISTEN しているか？
- 最近の system log に何が出ているか？

#### Part 2: 危ない CI 設定を読む (15–20分)
次の内容を `insecure-pipeline.yml` として保存:

```yaml
name: insecure-demo
on: [push]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Debug secrets
        run: |
          echo "TOKEN=$PROD_TOKEN"
      - name: Run remote installer
        run: curl -fsSL https://example.com/install.sh | bash
        env:
          PROD_TOKEN: ${{ secrets.PROD_TOKEN }}
      - name: Deploy
        run: ./deploy.sh
```

**見つけるべき問題**
- secret を `echo` している
- 外部スクリプトを pipe でそのまま実行している
- deploy job の権限境界が見えない
- pin されていない外部依存を信用している

#### Part 3: 少しだけ改善する (15–20分)
以下の観点で「どう直すか」をメモする:
- secrets をログ出力しない
- 外部スクリプトは hash 検証または vendor 化を検討
- deploy を approval 付き environment に分ける
- branch protection / signed commits / required review を導入

可能なら `secure-notes.md` を作って改善案を書く。

---

## 5) Command cheatsheet

### Linux 基本観察
```bash
whoami                  # 現在ユーザー
id                      # UID/GID と所属 group
pwd                     # 現在ディレクトリ
ls -la                  # 隠しファイル込み一覧
find . -maxdepth 2 -type f
cat /etc/os-release     # OS 情報
```

### ログ・テキスト確認
```bash
less file.txt
grep -R "password" .
tail -f /var/log/messages
journalctl -n 50 --no-pager
journalctl -u sshd --since today
```

### プロセス・ネットワーク
```bash
ps aux
ps aux | grep nginx
ss -tulpn
ss -tunap
lsof -i -P -n | head
```

### 権限の理解
```bash
ls -l
chmod 600 secret.txt
chmod 755 script.sh
chown user:user file.txt
```

### CI/CD security 観点で覚えたい shell 基本
```bash
env | sort
printenv
set -u                  # 未定義変数で失敗
set -e                  # エラーで停止
set -o pipefail         # pipe 中の失敗を拾う
```

---

## 6) Common mistakes and how to avoid them

### ミス1: root で何でも実行する
**問題:** 誤操作の影響が大きく、監査性も悪くなる。  
**回避:** まず通常権限で観察し、必要時のみ `sudo` を使う。

### ミス2: ログに secrets を出す
**問題:** build log, terminal history, artifact に残る。  
**回避:** `echo $TOKEN` をしない。CI の masking 機能を過信しない。

### ミス3: `curl ... | bash` を無警戒に使う
**問題:** 供給元が改ざんされるとそのまま侵害される。  
**回避:** ダウンロード後に中身確認、署名や hash 検証、固定 version 利用。

### ミス4: branch protection がない
**問題:** 誤 push や悪意ある変更がそのまま main に入る。  
**回避:** required review, status checks, protected branches を設定。

### ミス5: コマンドを意味もわからずコピペする
**問題:** 破壊的操作や情報漏えいにつながる。  
**回避:** 1行ずつ意味を確認し、特に `sudo`, redirection, pipe は慎重に読む。

---

## 7) One interview-style question
**質問:**  
CI/CD パイプラインがアプリケーション本体と同じくらい、あるいはそれ以上に重要なセキュリティ対象になるのはなぜですか？ 3つ理由を挙げて説明してください。

**考えるヒント:**
- secrets
- deployment authority
- supply chain
- audit trail

---

## 8) Next-step reading links
- OWASP Top 10: https://owasp.org/www-project-top-ten/
- OWASP CI/CD Security Guidance: https://owasp.org/
- GitHub Actions security hardening: https://docs.github.com/en/actions/security-for-github-actions/security-guides/security-hardening-for-github-actions
- Linux permissions overview (Red Hat): https://www.redhat.com/en/blog/linux-file-permissions-explained
- Kubernetes basics: https://kubernetes.io/docs/tutorials/kubernetes-basics/
- Docker security: https://docs.docker.com/engine/security/
- Terraform best practices: https://developer.hashicorp.com/terraform
- OpenTelemetry docs: https://opentelemetry.io/docs/
- Prometheus docs: https://prometheus.io/docs/
- Grafana docs: https://grafana.com/docs/
- AWS IAM best practices: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- Google Cloud IAM overview: https://cloud.google.com/iam/docs/overview

---

## 次回予告
**次回候補 (Middle)**  
**Docker hardening + secrets management**

**Prerequisites for Middle issue:**
- Linux の基本コマンドでファイル・権限・process・port を確認できる
- CI/CD の secrets 漏えいリスクを説明できる
- `chmod`, `ps`, `ss`, `grep`, `tail` の役割を理解している

この前提ができると、次は「コンテナをどう安全に作り、どう secrets を入れずに運ぶか」に進めます。

---

## 学習アークメモ
この雑誌では以下のように **Beginner → Middle → Advanced** を繰り返していきます。

- Arc 1: Linux / CI/CD security 基礎 → Docker hardening → パイプライン侵害シナリオ分析
- Arc 2: OWASP / secure coding → threat modeling → incident response drill
- Arc 3: Terraform/IaC 基礎 → Cloud IAM 設計 → 権限昇格リスク分析
- Arc 4: Kubernetes 基礎 → Kubernetes security → Kubernetes incident drills
- Arc 5: Logging 基礎 → Observability (Prometheus/Grafana/OpenTelemetry) → 障害検知・復旧演習

毎回、倫理的・防御的・合法的な学習に限定して進めます。
