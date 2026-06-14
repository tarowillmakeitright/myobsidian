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

# SecDevOps Magazine — 2026-06-12

**学習アーク:** Arc 1 / Day 1
**今日のレベル:** Beginner
**このアークの進み方:** Beginner → Middle → Advanced
**次回予告:** Day 2 では Docker hardening の Middle レベルに進み、Day 3 で CI/CD security の Advanced に接続します。

## 1) Topic + Level
**Linux Command Mastery for Secure Operations / Beginner**

今日のテーマは、**セキュリティを意識した Linux コマンド基礎**です。Application Security と DevOps の両方に共通する土台として、まずは「安全に状況を把握し、ログを読み、権限を見て、設定を確認する」力を固めます。

## 2) Why it matters in real projects
実務では、インシデント対応でも、CI/CD トラブルでも、Kubernetes ノード調査でも、最初に頼るのは Linux です。

たとえば以下のような場面で差が出ます。

- 本番障害時に「何が起きているか」を数分で把握できる
- 怪しい権限や world-writable file を早く見つけられる
- 誤った設定変更の痕跡をログから追える
- Docker/Kubernetes/Terraform の学習でも、土台の OS 理解があると吸収が速い

つまり Linux コマンドは、ただの操作スキルではなく、**防御・調査・改善の共通言語**です。

## 3) Core concepts

### 3-1. 観察 (observe) を先にする
安全な運用では、いきなり変更せず、まず現状確認します。

- `pwd` : 今どこにいるか
- `ls -la` : ファイル一覧と権限
- `id` : 自分のユーザーと所属グループ
- `whoami` : 現在の実行ユーザー
- `uname -a` : カーネル・OS の概要
- `df -h` : ディスク使用量
- `free -h` : メモリ使用量

「見てから触る」が基本です。

### 3-2. 権限 (permissions) を読む
Linux では、ファイル権限の理解がセキュリティの入口です。

例:
`-rw-r-----`

これは以下を意味します。

- owner: read/write
- group: read
- others: no access

重要な観点:

- `777` に安易にしない
- secrets を含むファイルは最小権限にする
- 実行権限 (`x`) は必要なものだけ付ける

### 3-3. パイプとフィルタ
ログや設定確認では、全部読むより絞り込みが重要です。

- `cat` : 内容表示
- `less` : スクロールして読む
- `grep` : 検索
- `sort`, `uniq` : 整理
- `wc -l` : 件数確認
- `tail -n 50` : 末尾確認
- `tail -f` : ログ監視

例:
`grep -i error app.log | tail -n 20`

これは「error を含む行を大文字小文字無視で探し、最後の20件を見る」意味です。

### 3-4. プロセスとポートの基礎
セキュリティでは「何が動いているか」が重要です。

- `ps aux` : 実行中プロセス
- `ss -tulpn` : 待受ポート確認
- `top` または `htop` : リソース監視

たとえば、想定外のサービスが `0.0.0.0` で待ち受けていたら、攻撃面 (attack surface) が広がっている可能性があります。

### 3-5. ログを読む姿勢
Linux のログは、障害対応・侵入調査・認証トラブルの入口です。

- `/var/log/` 配下を見る
- `journalctl` で systemd ログを確認する
- auth, sudo, service start/stop を重点的に見る

例:
- `journalctl -n 50`
- `journalctl -u sshd`
- `sudo grep -i failed /var/log/auth.log`

ディストリによってログ場所は異なるので、**まず存在確認**してから読むのが大事です。

## 4) Hands-on mini lab (30-60 min)
**ラボ名:** Secure Linux Recon Mini Lab

### ゴール
安全に情報収集し、怪しい設定を見つける練習をします。変更は最小限、基本は read-only です。

### 手順

1. 作業ディレクトリを作る
```bash
mkdir -p ~/secdevops-lab/day1
cd ~/secdevops-lab/day1
```

2. 調査メモを保存する
```bash
{
  echo '## host basics'
  date
  whoami
  id
  uname -a
  echo
  echo '## disk'
  df -h
  echo
  echo '## memory'
  free -h
} > recon.txt
```

3. 権限を観察する
```bash
ls -la ~
find ~ -maxdepth 2 -type f -perm /o+w 2>/dev/null | head -n 20
```

4. 待受ポートを確認する
```bash
ss -tulpn | head -n 30
```

5. 最近のログを読む
```bash
journalctl -n 50 --no-pager > recent-journal.txt
```

6. エラーっぽい行を探す
```bash
grep -Ei 'fail|error|denied|invalid' recent-journal.txt | tail -n 20
```

7. sudo 権限の確認（可能なら）
```bash
sudo -l
```

### できたら考えること
- world-writable file は本当に必要か？
- 想定外の LISTEN ポートはないか？
- ログに認証失敗や権限拒否は出ていないか？

## 5) Command cheatsheet

### Linux basics
```bash
pwd
ls -la
cd /path/to/dir
find . -type f
```

### 権限・所有者
```bash
stat file.txt
ls -l file.txt
chmod 640 secret.txt
chown user:group file.txt
```

### ログ確認
```bash
tail -n 100 /var/log/messages
journalctl -n 100 --no-pager
journalctl -u sshd --no-pager
```

### プロセス・ネットワーク
```bash
ps aux
ss -tulpn
lsof -i -P -n
```

### 絞り込み
```bash
grep -i error app.log
sort file.txt | uniq
wc -l app.log
```

## 6) Common mistakes and how to avoid them

### ミス1: いきなり `chmod 777`
**問題:** とりあえず動かすために権限を開けすぎると、重大なセキュリティ事故につながります。  
**回避:** まず owner/group を整え、必要最小限の `chmod` を使う。

### ミス2: 本番で確認前に変更する
**問題:** 原因調査のつもりが、証拠や状態を壊してしまう。  
**回避:** 先に `ls`, `stat`, `journalctl`, `ss` で観察。必要ならメモを保存する。

### ミス3: `sudo` を常用しすぎる
**問題:** 誤操作の影響範囲が大きくなる。  
**回避:** 普段は一般権限、必要な操作だけ `sudo`。

### ミス4: ログを全文読もうとして疲れる
**問題:** ノイズが多く、重要箇所を見落とす。  
**回避:** `tail`, `grep`, `journalctl -u` で対象を絞る。

### ミス5: LISTEN ポートを見ても意味を考えない
**問題:** 危険なのは「あること」ではなく「不要に外へ開いていること」。  
**回避:** そのポートは何のためか、誰から到達可能か、認証があるかを確認する。

## 7) One interview-style question
**質問:** ある Linux サーバーでアプリが外部公開されているはずなのに、期待しないポートも複数 LISTEN していました。あなたなら最初の10分で何を確認しますか？

**考えるポイント:**
- `ss -tulpn` でプロセスとポートの対応を見る
- `ps aux` や systemd unit を確認する
- firewall / security group / reverse proxy の位置づけを整理する
- 本当に必要なサービスだけかを棚卸しする

## 8) Next-step reading links
- OWASP Top 10: https://owasp.org/www-project-top-ten/
- Linux Permissions Basics (Red Hat): https://www.redhat.com/en/blog/linux-file-permissions-explained
- systemd journal / journalctl docs: https://www.freedesktop.org/software/systemd/man/journalctl.html
- CIS Benchmarks overview: https://www.cisecurity.org/cis-benchmarks
- Kubernetes Basics: https://kubernetes.io/docs/tutorials/kubernetes-basics/
- Docker Engine security: https://docs.docker.com/engine/security/

---

## Progression note
このマガジンは日替わりで、以下のトラックをローテーションしながら **Beginner → Middle → Advanced** の学習アークを回していきます。

- Application security: secure coding / OWASP risks / threat modeling / auth & session security / incident response
- DevOps core: Docker hardening / Kubernetes fundamentals & security / Terraform & IaC / Linux mastery / CI/CD security / secrets management
- Required added topics: Cloud Security / Observability / Kubernetes incident drills

### 次のレベルへ進む前提条件
**Middle に進む前提:**
- Linux 基本コマンドに抵抗がない
- 権限 (`rwx`) と owner/group の意味がわかる
- `grep`, `tail`, `journalctl`, `ss` を使って簡単な調査ができる

**Advanced に進む前提:**
- Docker/Kubernetes/CI/CD の基本用語がわかる
- 設定変更の影響範囲を説明できる
- ログ、権限、ネットワークの3観点で障害やリスクを整理できる
