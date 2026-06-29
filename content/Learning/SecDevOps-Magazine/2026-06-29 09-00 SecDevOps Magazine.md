# 2026-06-29 SecDevOps Magazine
[[Home]]

#security #devops #docker #kubernetes #terraform #linux #cloudsecurity #observability #daily

---

## 今日の学習アーク
- **Arc 1 / Beginner**
- 今週の流れ: **Linux command mastery → Docker hardening → CI/CD security**
- 今日は土台づくりとして、DevOps と Application Security の両方で効く **Linux 権限・プロセス・ログ確認の基礎** を固めます。
- 次回以降の Middle / Advanced で、Docker hardening、Kubernetes incident drills、Cloud IAM 設計、Observability まで段階的につなげていきます。

---

## 1) Topic + Level
**Linux command mastery for Security Baseline + Log Triage / Beginner**

---

## 2) Why it matters in real projects
実案件では、インシデントや障害の最初の数分で「どのユーザーが何をしたか」「どのプロセスが怪しいか」「設定や権限が危険ではないか」を素早く見抜けるかが重要です。

Linux の基本コマンドに強いと、次のような場面で効きます。
- Docker コンテナのベースイメージやホストの権限確認
- Kubernetes Node / Pod 障害時の一次切り分け
- CI/CD ランナー上の秘密情報漏えいリスク調査
- 侵害後の簡易トリアージと初動確認
- Terraform や Cloud IAM を扱う前提としての OS 理解

つまり、Linux の基礎は DevOps の土台であり、同時に Security の初動力そのものです。

---

## 3) Core concepts
### A. 権限 (permission)
Linux では「誰が」「何に」「どこまでアクセスできるか」を権限で制御します。
- `r` = read
- `w` = write
- `x` = execute

確認の基本:
- `ls -l` でファイル権限を見る
- 所有者は `user:group` の考え方で管理される
- 危険なのは **過剰権限**。たとえば `chmod 777` は雑に全部開ける典型例です

### B. プロセス (process)
アプリ、エージェント、CI ジョブ、Web サーバーはすべてプロセスとして動きます。
- `ps`, `top`, `pgrep` で観察
- 重要なのは「誰の権限で動いているか」「親子関係はどうか」「CPU / メモリを食っていないか」

Security 的には:
- 不自然な常駐プロセス
- root で動く不要サービス
- 怪しい引数付きプロセス
を早く見つける視点が大事です。

### C. ログ (logs)
ログは障害対応とインシデント対応の入口です。
- `journalctl` で systemd 系ログを見る
- `/var/log/` 配下を読む
- `tail -f` でリアルタイム監視
- `grep` で必要な行だけ絞る

### D. 最小権限 (least privilege)
Application Security でも Cloud Security でも共通原則です。
- 必要最小限の権限だけ付与する
- root を常用しない
- 秘密情報を誰でも読める場所に置かない

この考え方は後続の AWS/GCP IAM、Kubernetes RBAC、Terraform 設計にもそのままつながります。

---

## 4) Hands-on mini lab (30-60 min)
### ゴール
Linux 上で「権限」「プロセス」「ログ」を観察し、危険な設定を 3 つ見つける。

### 前提
- ローカル Linux シェル
- root 不要（`sudo` が使えるなら一部確認が広がる）

### 手順
#### Step 1: 権限を見る
```bash
pwd
ls -la
find . -maxdepth 2 -type f | head
```
次に、権限の強すぎるファイルがないか確認します。
```bash
find . -type f -perm /o+w 2>/dev/null | head -20
```
見るポイント:
- world-writable なファイルがないか
- `.env` や鍵ファイルが広く読めないか

#### Step 2: 実行中プロセスを見る
```bash
ps aux --sort=-%mem | head
ps aux --sort=-%cpu | head
pgrep -a ssh
```
見るポイント:
- 想定外の高負荷プロセス
- root 実行の不要プロセス
- 不明なバイナリや不自然な引数

#### Step 3: ログを読む
```bash
tail -n 50 /var/log/messages 2>/dev/null || true
journalctl -n 50 --no-pager 2>/dev/null || true
journalctl -p warning -n 30 --no-pager 2>/dev/null || true
```
見るポイント:
- 認証失敗
- サービス再起動の繰り返し
- 権限エラー

#### Step 4: SUID / SGID を観察する
```bash
find /usr/bin /bin /usr/sbin /sbin -perm /4000 2>/dev/null | head -30
```
学び:
- SUID は便利ですが、攻撃面でも注目されやすい
- 「あること」自体が悪ではなく、「不要なものが増えていないか」を見る

#### Step 5: 学習メモを残す
次を 3 行でまとめる:
1. 今日見つけた危険 or 気になる点
2. それがなぜ危険か
3. 明日直すなら何をするか

---

## 5) Command cheatsheet
### ファイル・権限
```bash
ls -la
stat <file>
chmod 640 <file>
chown user:group <file>
find . -type f -perm /o+w
```

### プロセス
```bash
ps aux
ps aux --sort=-%cpu | head
ps aux --sort=-%mem | head
pgrep -a <name>
kill -15 <pid>
```

### ログ
```bash
tail -n 100 <logfile>
tail -f <logfile>
grep -i "error" <logfile>
journalctl -u <service> --no-pager
journalctl -p err -n 50 --no-pager
```

### 監査の足がかり
```bash
whoami
id
uname -a
ss -tulpn
sudo -l
```

---

## 6) Common mistakes and how to avoid them
### ミス1: `chmod 777` で全部解決しようとする
**問題:** 早いけど危険。書き込み可能範囲が広がり、改ざんや漏えいの入口になる。
**回避:** 必要な user/group だけに必要な権限を付ける。

### ミス2: root で常用する
**問題:** 誤操作の被害が大きくなる。監査もしづらい。
**回避:** 普段は一般ユーザー、必要時だけ `sudo`。

### ミス3: ログを「全部読む」前提で動く
**問題:** 時間が溶ける。重要情報を見逃す。
**回避:** `journalctl -p warning`, `grep`, `tail` で先に絞る。

### ミス4: プロセス名だけ見て安心する
**問題:** 正規プロセスっぽく偽装されることがある。
**回避:** 実行ユーザー、パス、引数、親プロセスまで見る。

### ミス5: 秘密情報を平文ファイルに置きっぱなしにする
**問題:** CI/CD、Docker、Cloud IAM 事故の定番。
**回避:** Secret Manager / Vault / 環境変数管理 / 権限制御を組み合わせる。

---

## 7) One interview-style question
**質問:**
本番 Linux サーバーでアプリ障害と情報漏えいの疑いが同時に出ています。最初の 10 分で、あなたはどの順番で確認しますか？

**考える観点:**
- 稼働中プロセス
- 異常なログ
- 外部公開ポート
- 権限の広すぎる秘密情報ファイル
- root 実行の不要サービス

---

## 8) Next-step reading links
- OWASP Top 10: https://owasp.org/www-project-top-ten/
- OWASP Cheat Sheet Series: https://cheatsheetseries.owasp.org/
- Linux file permissions overview (Red Hat): https://www.redhat.com/en/blog/linux-file-permissions-explained
- systemd / journalctl docs: https://www.freedesktop.org/software/systemd/man/journalctl.html
- Docker security best practices: https://docs.docker.com/engine/security/
- Kubernetes security checklist: https://kubernetes.io/docs/concepts/security/overview/
- Terraform security best practices (HashiCorp): https://developer.hashicorp.com/terraform/tutorials/configuration-language/sensitive-variables
- OpenTelemetry docs: https://opentelemetry.io/docs/
- AWS IAM best practices: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- Google Cloud IAM overview: https://cloud.google.com/iam/docs/overview

---

## 次号予告
**Middle 予告:** Docker hardening と secrets management の基礎。

### Middle の前提知識
- `ls`, `ps`, `grep`, `tail` を使って基本調査ができる
- Linux の user/group/permission の意味がわかる
- `.env` や鍵ファイルの扱いが危険になりうると理解している

次号では、今回の Linux 基礎を踏まえて、コンテナに入った瞬間に権限や秘密情報がどう事故るのかを扱います。
