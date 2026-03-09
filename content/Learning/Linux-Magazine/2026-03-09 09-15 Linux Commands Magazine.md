---
tags: [linux, commands, learning, devops, daily]
---

# 2026-03-09 Linux Commands Magazine

#linux #commands #learning #devops #daily  
[[Home]]

---

## 学習アーク 1

### 1) Topic + Level
**トピック:** ログ調査と障害の初動対応（`journalctl` / `tail` / `grep`）  
**Level:** Beginner（初級）

### 2) Why it matters in real projects
本番障害の最初の一歩は「状況把握」です。  
アプリ・OS・サービスのログを素早く読めると、復旧時間（MTTR）を短縮でき、チームへの報告精度も上がります。

### 3) Core command explanations
- `journalctl -u nginx --since "-30min"`
  - systemdサービス（例: nginx）の直近30分ログを確認
- `tail -f /var/log/messages`
  - ログ末尾を追尾（リアルタイム監視）
- `grep -i "error" app.log`
  - 大文字小文字を無視して`error`を検索
- `grep -E "timeout|refused" app.log`
  - 複数パターンをOR検索

### 4) 30-60 minute hands-on mini lab
**目標:** 疑似障害をログから特定する（40分）

1. テストログ作成
   ```bash
   mkdir -p ~/linux-mag-lab && cd ~/linux-mag-lab
   cat > app.log <<'EOF'
   2026-03-09T09:00:01 INFO server start
   2026-03-09T09:05:10 WARN slow query 1200ms
   2026-03-09T09:06:31 ERROR db timeout
   2026-03-09T09:07:12 INFO retry success
   EOF
   ```
2. `grep`でERROR行抽出
   ```bash
   grep -n "ERROR" app.log
   ```
3. 直近イベントを時系列把握
   ```bash
   tail -n 3 app.log
   ```
4. （systemd環境なら）任意サービスの直近ログ確認
   ```bash
   journalctl -u sshd --since "-15min"
   ```
5. 発見事項をメモ（障害時刻、エラー種別、再発有無）

### 5) Command cheatsheet
```bash
journalctl -xe                      # 重要度高めの最近ログ
journalctl -u <service> -f          # サービスログを追尾
tail -n 100 <file>                  # 末尾100行
grep -n -i "error" <file>          # 行番号付き検索
grep -E "warn|error|fatal" <file>  # OR条件検索
```

### 6) Common mistakes and safe practices
- いきなりログ削除しない（証跡消失）
- `sudo`は必要最小限にする（誤操作影響が大きい）
- 本番で`-f`追尾中に別作業を混ぜて混乱しない（ターミナルを分ける）
- 解析前に**コピーを取る**（`cp app.log app.log.bak`）

### 7) One interview-style question
「`tail -f`と`journalctl -f`の使い分けを、systemd運用の現場目線で説明してください。」

### 8) Next-step resources
- `man journalctl`
- `man grep`
- systemd公式ドキュメント（journal）

---

## 学習アーク 2

### 1) Topic + Level
**トピック:** 権限管理の基本運用（`chmod` / `chown` / `umask`）  
**Level:** Middle（中級）  
**前提（Prerequisites）:**
- 初級のログ調査コマンドが使える
- Linuxのユーザー/グループ概念を理解している
- `ls -l`の表示（rwx）が読める

### 2) Why it matters in real projects
権限設定ミスは「動かない」「漏れる」「壊れる」の原因になります。  
DevOpsでは最小権限が基本で、権限の設計品質がセキュリティと運用品質を左右します。

### 3) Core command explanations
- `chmod 640 secret.txt`
  - 所有者: rw、グループ: r、その他: なし
- `chown appuser:appgroup app.log`
  - 所有者/グループを変更
- `umask 027`
  - 新規作成時のデフォルト権限制御（厳しめ）
- `find . -type f -perm -o+w`
  - world-writableファイル検出

### 4) 30-60 minute hands-on mini lab
**目標:** 安全な権限モデルを作る（45分）

1. 検証ディレクトリ準備
   ```bash
   mkdir -p ~/linux-mag-perm && cd ~/linux-mag-perm
   touch public.txt secret.txt run.sh
   ```
2. 権限を設定
   ```bash
   chmod 644 public.txt
   chmod 640 secret.txt
   chmod 750 run.sh
   ls -l
   ```
3. 危険権限を作って検出
   ```bash
   chmod 666 public.txt
   find . -type f -perm -o+w
   ```
4. 適切権限に戻す
   ```bash
   chmod 644 public.txt
   ```
5. `umask`確認
   ```bash
   umask
   umask 027
   touch newfile.txt && ls -l newfile.txt
   ```

### 5) Command cheatsheet
```bash
ls -l                               # 権限確認
chmod 640 file                      # 数値モード
chmod u+x script.sh                 # 記号モード
chown user:group file               # 所有者変更
umask 027                           # デフォルト権限制御
find /path -type f -perm -o+w       # 危険権限検出
```

### 6) Common mistakes and safe practices
- **危険:** `chmod -R 777` を安易に使わない（重大なセキュリティリスク）
- **危険:** `chown -R` の対象ミス（システム全体に誤適用）
- `sudo`で権限変更する前に対象を`pwd`/`ls`で再確認
- 本番適用前に検証環境で再現し、変更履歴を残す

### 7) One interview-style question
「`chmod 755` と `chmod 750` の違いを、Webアプリ配置時のリスク観点で説明してください。」

### 8) Next-step resources
- `man chmod`
- `man chown`
- CIS Benchmarks（Linux権限設計の参考）

---

## 学習アーク 3

### 1) Topic + Level
**トピック:** 安全なファイル運用とバックアップ自動化（`rsync` / `tar` / `cron`）  
**Level:** Advanced（上級）  
**前提（Prerequisites）:**
- 中級の権限管理を実務レベルで使える
- パス/所有者/実行ユーザーの影響を説明できる
- シェルスクリプトの基礎（変数・終了コード）を理解している

### 2) Why it matters in real projects
障害対応では「復旧できること」が最重要です。  
`rsync`と`tar`、定期実行を組み合わせると、シンプルでも信頼性の高いバックアップ運用を作れます。

### 3) Core command explanations
- `rsync -av --delete src/ dst/`
  - 差分同期。`--delete`は宛先の不要ファイルを削除（**要注意**）
- `tar -czf backup-$(date +%F).tar.gz /data`
  - 圧縮アーカイブ作成
- `crontab -e`
  - 定期実行設定
- `crontab -l`
  - 現在の設定確認

### 4) 30-60 minute hands-on mini lab
**目標:** ローカル安全バックアップを自動化（60分）

1. データ作成
   ```bash
   mkdir -p ~/linux-mag-adv/src ~/linux-mag-adv/backup
   echo "v1" > ~/linux-mag-adv/src/app.conf
   ```
2. ドライランで同期確認（最重要）
   ```bash
   rsync -av --delete --dry-run ~/linux-mag-adv/src/ ~/linux-mag-adv/backup/
   ```
3. 問題なければ本実行
   ```bash
   rsync -av --delete ~/linux-mag-adv/src/ ~/linux-mag-adv/backup/
   ```
4. アーカイブ作成
   ```bash
   tar -czf ~/linux-mag-adv/backup-$(date +%F).tar.gz -C ~/linux-mag-adv backup
   ```
5. cron想定のスクリプト化
   ```bash
   cat > ~/linux-mag-adv/backup.sh <<'EOF'
   #!/usr/bin/env bash
   set -euo pipefail
   rsync -av --delete --dry-run "$HOME/linux-mag-adv/src/" "$HOME/linux-mag-adv/backup/"
   rsync -av --delete "$HOME/linux-mag-adv/src/" "$HOME/linux-mag-adv/backup/"
   tar -czf "$HOME/linux-mag-adv/backup-$(date +%F).tar.gz" -C "$HOME/linux-mag-adv" backup
   EOF
   chmod 750 ~/linux-mag-adv/backup.sh
   ```

### 5) Command cheatsheet
```bash
rsync -av --dry-run src/ dst/      # 事前確認（安全）
rsync -av --delete src/ dst/       # 差分同期（削除あり）
tar -czf out.tar.gz /path          # 圧縮バックアップ
crontab -e                         # 定期実行編集
crontab -l                         # 定期実行確認
```

### 6) Common mistakes and safe practices
- **最重要警告:** `rsync --delete` は宛先を削除する。必ず `--dry-run` を先に実施
- **危険:** `rm -rf` をバックアップスクリプトに安易に入れない（パス変数空文字事故）
- **危険:** `sudo`実行cronは影響範囲が大きい。可能なら専用ユーザーで実行
- ログ出力を残す（`>> backup.log 2>&1`）
- 復元テストまで行って初めて「バックアップできている」と言える

### 7) One interview-style question
「`rsync --delete` を本番運用に採用する場合、どの安全策（手順・監視・ロールバック）を設計しますか？」

### 8) Next-step resources
- `man rsync`
- `man tar`
- `man 5 crontab`
- Site Reliability Engineering（運用設計の考え方）

---

### 今日のまとめ
- 初級: ログ調査で原因特定スピードを上げる
- 中級: 最小権限で安全に運用する
- 上級: バックアップを自動化し、復旧可能性を高める

**安全第一:** 破壊的コマンド（`rm -rf` / `chmod -R` / `chown -R` / `sudo`）は、対象パス・実行ユーザー・影響範囲を必ず事前確認してから実行すること。
