# Daily Linux Commands Magazine — 2026-03-27 09:15
#linux #commands #learning #devops #daily
[[Home]]

---

## Learning Arc 1

### 1) Topic + Level
**Topic:** ファイル探索と安全な閲覧の基本  
**Level:** Beginner（初級）

### 2) Why it matters in real projects
実務では「設定ファイルがどこにあるか」「ログの中にエラーがあるか」を素早く見つける能力が重要です。初動調査が早いほど、障害対応や開発スピードが上がります。

### 3) Core command explanations
- `pwd` : 現在の作業ディレクトリを表示
- `ls -la` : 隠しファイル含め一覧表示（権限・所有者も確認可）
- `cd` : ディレクトリ移動
- `find . -name "*.log"` : ファイル名で探索
- `grep -n "ERROR" app.log` : 文字列検索（行番号付き）
- `less app.log` : 大きなファイルを安全に閲覧（編集しない）

### 4) 30-60 minute hands-on mini lab
**目安: 35分**
1. `~/linux-lab/day1` を作成し、`app.log`, `server.log`, `README.md` を用意
2. `echo` でログっぽい内容（INFO/WARN/ERROR）を10-20行追加
3. `find` で `.log` ファイルを列挙
4. `grep -n` で ERROR 行を抽出
5. `less` で全体を確認し、`/ERROR` 検索を体験
6. 最後に調査メモを `README.md` にまとめる

### 5) Command cheatsheet
```bash
pwd
ls -la
cd /path/to/dir
find . -name "*.log"
grep -n "ERROR" app.log
less app.log
```

### 6) Common mistakes and safe practices
- `grep "*" file` のような誤ったクォートで意図しない展開が起きる → 文字列は基本ダブルクォート
- `cat 巨大ログ` でターミナルが埋まる → `less` を優先
- **安全策:** まず「見るだけ」のコマンド（`ls`, `find`, `grep`, `less`）から始める

### 7) One interview-style question
「1GBのログファイルから `timeout` エラーだけを素早く確認したい場合、どのコマンドをどう組み合わせますか？」

### 8) Next-step resources
- `man find`, `man grep`, `man less`
- The Linux Command Line (書籍)
- explain shell（コマンド分解の学習サイト）

---

## Learning Arc 2

### 1) Topic + Level
**Topic:** プロセス監視とサービス状態確認  
**Level:** Middle（中級）

**Prerequisites（前提知識）:**
- 初級のファイル探索・ログ閲覧ができること
- 標準入出力とパイプ（`|`）の基本を理解していること

### 2) Why it matters in real projects
本番障害では「CPUを食っているプロセスは何か」「サービスが落ちた原因は何か」を短時間で特定する必要があります。ここが遅いと復旧が遅れ、影響範囲が拡大します。

### 3) Core command explanations
- `ps aux --sort=-%cpu | head` : CPU使用率の高いプロセス確認
- `top` / `htop` : リアルタイム監視
- `pgrep -a nginx` : プロセス名で検索（引数も表示）
- `systemctl status nginx` : systemdサービスの状態確認
- `journalctl -u nginx --since "1 hour ago"` : サービスログ確認

### 4) 30-60 minute hands-on mini lab
**目安: 45分**
1. 適当なサービス（例: `sshd`）の `systemctl status` を確認
2. `journalctl -u <service> --since "2 hours ago"` で直近ログを閲覧
3. CPUを使うダミープロセスを起動（例: `yes > /dev/null`）
4. `ps aux --sort=-%cpu | head` で上位プロセスを確認
5. `pgrep -a yes` でPID特定
6. `kill <PID>` で停止し、終了を確認

### 5) Command cheatsheet
```bash
ps aux --sort=-%cpu | head
top
pgrep -a <name>
systemctl status <service>
journalctl -u <service> --since "1 hour ago"
kill <PID>
```

### 6) Common mistakes and safe practices
- `kill -9` を常用するのは危険（後処理が走らない）→ まず `kill`（SIGTERM）
- **`sudo` の多用はリスク**（誤操作時の被害拡大）→ 必要最小限で実行
- 本番で不用意にサービス再起動しない → 先に `status` とログ確認
- `chmod/chown` の誤用でサービス起動不可になることがある → 変更前に現状記録（`ls -l`）

### 7) One interview-style question
「アプリが遅いと報告されたとき、`top`・`ps`・`journalctl` を使って原因を切り分ける手順を説明してください。」

### 8) Next-step resources
- `man systemctl`, `man journalctl`, `man kill`
- Linux Performance（Brendan Gregg の資料）
- 実機またはVMでの障害対応演習

---

## Learning Arc 3

### 1) Topic + Level
**Topic:** 権限・所有権・バックアップを伴う安全運用  
**Level:** Advanced（上級）

**Prerequisites（前提知識）:**
- 中級のプロセス/サービス診断を実施できること
- Linuxのユーザー・グループ・パーミッション（rwx）を理解していること
- `tar` / `cp` の基本操作を知っていること

### 2) Why it matters in real projects
設定変更や権限修正は、正しく行えば障害予防になりますが、誤ると重大インシデントに直結します。上級者は「変更そのもの」より「安全に変更する手順」を設計します。

### 3) Core command explanations
- `id`, `groups` : 現在ユーザーと所属グループ確認
- `stat file` : 詳細メタ情報確認
- `chmod` : パーミッション変更（最小権限原則）
- `chown user:group file` : 所有者変更
- `tar -czf backup-$(date +%F).tar.gz dir/` : 変更前バックアップ
- `sudo -l` : 実行可能なsudo権限確認

### 4) 30-60 minute hands-on mini lab
**目安: 60分**
1. 検証用ディレクトリ `~/linux-lab/perm-test` を作成
2. 現状を `ls -la` と `stat` で記録
3. `tar -czf` でバックアップ作成
4. テストファイルに対し `chmod 640` / `chmod 600` を比較
5. 読み書き可否を別ユーザー観点でシミュレーション（可能な範囲で）
6. `chown` は**本番ファイルではなく検証ファイルのみ**で試す
7. 変更差分を記録し、ロールバック（元権限に戻す）手順を作成

### 5) Command cheatsheet
```bash
id
groups
stat <file>
tar -czf backup-$(date +%F).tar.gz <dir>
chmod 640 <file>
chown <user>:<group> <file>
sudo -l
```

### 6) Common mistakes and safe practices
- ⚠️ **`rm -rf` は破壊的**: 実行前に `pwd` と対象パスを2回確認。可能なら `trash` を使う
- ⚠️ **`chmod -R` / `chown -R` の誤爆**: 対象を限定し、まずテストディレクトリで検証
- ⚠️ **`sudo` 実行時のワイルドカード**: 想定外ファイルまで対象になる危険
- 変更前バックアップ + 変更後検証 + ロールバック手順を必ず用意
- 本番はメンテ時間帯・レビュー付きで実施

### 7) One interview-style question
「本番で `Permission denied` が発生した際、`chmod/chown/sudo` をどう安全に使い分け、どの順で調査・復旧しますか？」

### 8) Next-step resources
- `man chmod`, `man chown`, `man sudoers`, `man tar`
- CIS Benchmarks（Linux）
- 「最小権限原則」「変更管理（Change Management）」の実務資料

---

## 今日のまとめ
- 初級: まず安全に“読む”力（探索・検索・閲覧）
- 中級: プロセスとサービスを根拠ベースで診断
- 上級: 権限変更を安全設計込みで実施

**合言葉:** 「いきなり壊す操作をしない。観察→記録→最小変更→検証→必要ならロールバック。」
