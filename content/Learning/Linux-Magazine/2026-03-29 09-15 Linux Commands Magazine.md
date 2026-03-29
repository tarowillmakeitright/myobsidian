# Linux Commands Magazine — 2026-03-29 09:15
#linux #commands #learning #devops #daily
[[Home]]

---

## Learning Arc 1
### 1) トピック + レベル
**トピック:** ログ確認と基本調査（`ls`, `cat`, `less`, `tail`, `grep`）  
**レベル:** Beginner

### 2) 実プロジェクトで重要な理由
障害対応や問い合わせ対応では、まず「何が起きたか」をログから素早く把握する力が必要です。基本コマンドだけで初動速度が大きく変わります。

### 3) コアコマンド解説
- `ls -lah` : ファイル一覧を人間に読みやすい形式で表示
- `less /path/to/file` : 大きいファイルを安全にページ閲覧（編集しない）
- `tail -n 50 app.log` : 末尾50行を確認
- `tail -f app.log` : リアルタイム監視（Ctrl+Cで終了）
- `grep -n "ERROR" app.log` : エラー行を行番号付きで検索

### 4) 30-60分ミニラボ
1. 作業用ディレクトリ作成: `mkdir -p ~/lab/logs && cd ~/lab/logs`
2. サンプルログ作成:
   ```bash
   cat > app.log <<'EOF'
   2026-03-29 09:00:01 INFO start app
   2026-03-29 09:01:22 WARN high memory usage
   2026-03-29 09:02:10 ERROR failed to connect db
   2026-03-29 09:03:40 INFO retry success
   EOF
   ```
3. `less app.log` で閲覧、`/ERROR` で検索
4. `grep -n "ERROR\|WARN" app.log` で問題行抽出
5. 追記しながら監視:
   - ターミナルA: `tail -f app.log`
   - ターミナルB: `echo "2026-03-29 09:05:00 ERROR timeout" >> app.log`

### 5) コマンドチートシート
```bash
ls -lah
less FILE
tail -n 100 FILE
tail -f FILE
grep -n "PATTERN" FILE
grep -E "ERROR|WARN" FILE
```

### 6) よくあるミス & 安全プラクティス
- ミス: `cat` で巨大ログを開いて端末が見づらくなる
  - 対策: 大きいファイルは `less` を優先
- ミス: 正規表現の誤りで検索漏れ
  - 対策: まず単語検索→徐々にパターンを広げる
- 安全: 本番ログの権限変更（`chmod/chown`）は原則しない。必要時は影響範囲を確認し、バックアップと承認を取る。

### 7) 面接風質問
「`tail -f` と `less +F` の使い分けを、運用時の観点で説明してください。」

### 8) 次の一歩リソース
- `man tail`, `man grep`, `man less`
- The Linux Command Line（基礎章）

---

## Learning Arc 2
### 1) トピック + レベル
**トピック:** プロセス監視と安全な停止（`ps`, `top`, `pgrep`, `kill`, `systemctl`）  
**レベル:** Middle  
**前提知識:** Beginnerのログ確認（`grep`, `tail`, `less`）ができること

### 2) 実プロジェクトで重要な理由
CPU高騰・メモリ逼迫・ハング時に、原因プロセスを特定し安全に制御できることはSRE/運用の基本です。

### 3) コアコマンド解説
- `ps aux --sort=-%cpu | head` : CPU使用率上位プロセス確認
- `top` / `htop` : リアルタイム監視
- `pgrep -af nginx` : プロセス検索（PIDとコマンド表示）
- `kill -15 PID` : **まず**SIGTERMで正常終了要求
- `kill -9 PID` : 最終手段（強制終了）
- `systemctl status SERVICE` : サービス状態確認

### 4) 30-60分ミニラボ
1. 疑似負荷プロセス起動:
   ```bash
   yes > /dev/null &
   echo $! > /tmp/yes.pid
   ```
2. `ps aux --sort=-%cpu | head` で該当PID確認
3. `kill -15 $(cat /tmp/yes.pid)` を実行して停止確認
4. 停止しないケースを再現し、数秒待ってから `kill -9` を試す
5. `systemctl status sshd`（環境により `sshd`/`ssh`）を確認

### 5) コマンドチートシート
```bash
ps aux --sort=-%mem | head
pgrep -af NAME
kill -15 PID
kill -9 PID   # 最終手段
systemctl status SERVICE
journalctl -u SERVICE -n 100 --no-pager
```

### 6) よくあるミス & 安全プラクティス
- ミス: いきなり `kill -9`
  - 対策: `-15` → 待機 → ログ確認 → 最後に `-9`
- ミス: 誤PID停止
  - 対策: `pgrep -af` と `ps -fp PID` で二重確認
- **sudo注意:** `sudo kill` や `sudo systemctl` は影響が大きい。対象サービス名・環境（本番/検証）を必ず確認。

### 7) 面接風質問
「アプリが応答しないとき、`kill -9` をすぐ使わない理由と、使う判断基準を説明してください。」

### 8) 次の一歩リソース
- `man ps`, `man kill`, `man systemctl`
- Linux Performance の入門記事（CPU/メモリ観測）

---

## Learning Arc 3
### 1) トピック + レベル
**トピック:** 権限・所有者・再帰操作の安全運用（`chmod`, `chown`, `find`, `xargs`）  
**レベル:** Advanced  
**前提知識:** Middleのプロセス管理、Linuxのユーザー/グループ/パーミッション基礎

### 2) 実プロジェクトで重要な理由
権限設定ミスは「動かない」「情報漏えい」「復旧遅延」を招きます。安全な一括変更手順は本番運用で必須です。

### 3) コアコマンド解説
- `ls -l` : 現在の権限・所有者確認
- `find DIR -type f -name "*.sh"` : 対象を厳密抽出
- `chmod 750 FILE` : 実行権限を最小限で付与
- `chown user:group FILE` : 所有者変更
- `find ... -print0 | xargs -0 ...` : 空白入りファイル名でも安全に処理

### 4) 30-60分ミニラボ
1. 検証用作成:
   ```bash
   mkdir -p ~/lab/perm/bin ~/lab/perm/data
   touch ~/lab/perm/bin/run.sh ~/lab/perm/data/sample.txt
   ```
2. 現状確認: `ls -lR ~/lab/perm`
3. ドライラン発想で対象確認:
   ```bash
   find ~/lab/perm -type f -name "*.sh"
   ```
4. 安全に権限変更:
   ```bash
   chmod 750 ~/lab/perm/bin/run.sh
   ```
5. 再帰変更は限定条件でのみ実施（例）:
   ```bash
   find ~/lab/perm -type f -name "*.txt" -print0 | xargs -0 chmod 640
   ```
6. 変更後差分確認: `ls -lR ~/lab/perm`

### 5) コマンドチートシート
```bash
ls -l PATH
stat FILE
chmod 640 FILE
chmod 750 SCRIPT.sh
chown user:group FILE
find DIR -type f -name "*.log" -print0 | xargs -0 chmod 640
```

### 6) よくあるミス & 安全プラクティス
- **危険:** `chmod -R 777` は原則禁止（過剰権限）
- **危険:** `chown -R` を誤パスで実行すると広範囲に影響
- 対策:
  1. まず `find` で対象を表示（ドライラン）
  2. 小範囲で試す
  3. 変更前後を `ls -l`/`stat` で確認
  4. 本番ではメンテ時間帯・ロールバック手順を用意
- **破壊系警告:** `rm -rf` は最終手段。使う前に `pwd` / `ls` / 対象パス復唱、可能なら `trash` やバックアップを優先。

### 7) 面接風質問
「`chmod -R` を本番で実行する前に、あなたが行う確認手順を具体的に説明してください。」

### 8) 次の一歩リソース
- `man chmod`, `man chown`, `man find`, `man xargs`
- Linux File Permissions deep dive（ACL含む）

---

### 今日の一言
安全な運用は「速さ」より「再現性と確認手順」。まず観測、次に小さく変更、最後に検証。