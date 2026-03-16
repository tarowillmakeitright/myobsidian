---
tags: [linux, commands, learning, devops, daily]
---
# 2026-03-16 Linux Commands Magazine
[[Home]]

## 学習アークA（Beginner）
### 1) Topic + Level
**テーマ:** ログ調査の第一歩（`ls`, `cat`, `less`, `tail`, `grep`）  
**レベル:** **Beginner**

### 2) Why it matters in real projects
本番障害の初動で最初にやるのは「状況確認」です。アプリが落ちた時、まずログを安全に読む力があると、復旧時間を大きく短縮できます。

### 3) Core command explanations
- `ls -lah` : ファイル一覧を人間が読みやすい形式で表示
- `cat file` : ファイル全体を表示（巨大ファイルには不向き）
- `less file` : ページャで安全に閲覧（`q`で終了）
- `tail -n 100 app.log` : 末尾100行を確認
- `tail -f app.log` : 追記をリアルタイム監視
- `grep "ERROR" app.log` : 特定文字列を検索
- `grep -n "timeout" app.log` : 行番号付き検索

### 4) 30-60 minute hands-on mini lab
1. 作業用ディレクトリを作成: `mkdir -p ~/lab/logs && cd ~/lab/logs`
2. サンプルログ作成:
   ```bash
   cat > app.log <<'EOF'
   2026-03-16 09:00:01 INFO server started
   2026-03-16 09:01:10 WARN retrying connection
   2026-03-16 09:02:45 ERROR database timeout
   2026-03-16 09:03:02 INFO health check ok
   EOF
   ```
3. `less app.log` で閲覧
4. `grep -n "ERROR\|WARN" app.log` で問題行抽出
5. 別ターミナルで `tail -f app.log` を実行し、追記して変化を確認:
   ```bash
   echo "2026-03-16 09:05:12 ERROR disk full" >> app.log
   ```

### 5) Command cheatsheet
```bash
ls -lah
less app.log
tail -n 50 app.log
tail -f app.log
grep -n "ERROR" app.log
grep -E "ERROR|WARN" app.log
```

### 6) Common mistakes and safe practices
- ❌ `cat` で巨大ログを開いてターミナルを埋める  
  ✅ まず `less` / `tail -n` を使う
- ❌ root権限でむやみに閲覧  
  ✅ 必要時のみ `sudo` を使い、目的を明確化
- ✅ ログ改変コマンド（`sed -i` など）は検証環境でのみ実施

### 7) One interview-style question
「`tail -f` と `less +F` の違いは？ 運用現場でどちらをどう使い分けますか？」

### 8) Next-step resources
- `man grep`, `man less`, `man tail`
- The Linux Command Line (William Shotts)

---

## 学習アークB（Middle）
### 1) Topic + Level
**テーマ:** プロセス監視と安全な停止（`ps`, `pgrep`, `top`, `kill`, `pkill`）  
**レベル:** **Middle**  
**前提:** Beginnerのログ確認（`grep`, `tail`, `less`）に慣れていること

### 2) Why it matters in real projects
CPU高騰・メモリリーク・ハング時、正しいプロセス特定と安全な停止ができないと、サービス停止やデータ不整合につながります。

### 3) Core command explanations
- `ps aux | grep <name>` : プロセス確認
- `pgrep -af <name>` : PIDを安全に検索
- `top` : リアルタイム監視
- `kill -15 <PID>` : **SIGTERM**（まずこれ。正常終了を促す）
- `kill -9 <PID>` : **SIGKILL**（最終手段）
- `pkill -15 -f <pattern>` : パターン一致でTERM送信

### 4) 30-60 minute hands-on mini lab
1. ダミープロセス起動:
   ```bash
   sleep 10000 &
   sleep 10000 &
   ```
2. `pgrep -af sleep` でPID確認
3. 1つ目に `kill -15 <PID>` を送る
4. `pgrep -af sleep` で終了確認
5. 残りを `kill -9 <PID>` で停止し、違いを理解
6. `top` でCPU/メモリ列を観察

### 5) Command cheatsheet
```bash
pgrep -af python
ps aux --sort=-%cpu | head
kill -15 12345
kill -9 12345   # 最終手段
pkill -15 -f "node server.js"
```

### 6) Common mistakes and safe practices
- ⚠️ `kill -9` の常用はNG（クリーンアップ処理が走らない）
- ⚠️ `pkill -f` はマッチ範囲が広く誤爆しやすい  
  → 先に `pgrep -af` で対象確認
- ⚠️ `sudo kill` は影響範囲が大きい  
  → サービス名・PID・親子関係を再確認してから実行

### 7) One interview-style question
「本番でCPU 100%のプロセスが見つかった時、`kill -9` を即実行しない理由と代替手順を説明してください。」

### 8) Next-step resources
- `man kill`, `man pkill`, `man pgrep`
- `htop`（導入できる環境なら）

---

## 学習アークC（Advanced）
### 1) Topic + Level
**テーマ:** 権限管理と安全な運用（`chmod`, `chown`, `umask`, `sudo`, `find`）  
**レベル:** **Advanced**  
**前提:** Middleのプロセス管理、および基本的なファイル操作（`ls`, `cp`, `mv`）

### 2) Why it matters in real projects
権限設定ミスは情報漏えい・改ざん・サービス停止の原因になります。DevOpsでは「最小権限」と「変更前確認」が必須です。

### 3) Core command explanations
- `chmod 640 file` : 読み書き権限を明示設定
- `chown user:group file` : 所有者変更
- `umask 027` : 新規ファイル既定権限を制限
- `sudo -l` : 実行可能なsudo権限を確認
- `find . -type f -perm /o+w` : 危険なworld-writableを検出

### 4) 30-60 minute hands-on mini lab
1. 検証ディレクトリ作成: `mkdir -p ~/lab/perms && cd ~/lab/perms`
2. ファイル作成: `touch secret.txt shared.txt`
3. `ls -l` で初期権限確認
4. `chmod 600 secret.txt`, `chmod 664 shared.txt`
5. `umask` 現在値確認後、`umask 027` を設定して新規ファイル作成
6. `find . -type f -perm /o+w -ls` で危険権限検出
7. （可能なら）`sudo -l` を実行し、権限境界を把握

### 5) Command cheatsheet
```bash
chmod 600 secret.txt
chmod 640 config.yml
chown appuser:appgroup config.yml
umask
umask 027
find /var/www -type f -perm /o+w
sudo -l
```

### 6) Common mistakes and safe practices
- 🚨 **危険:** `chmod -R 777` を安易に使わない
- 🚨 **危険:** `chown -R` の対象パス誤りは大事故につながる  
  → 実行前に `pwd` と対象を再確認
- 🚨 **危険:** `rm -rf` は破壊的。削除前に `ls` / `find` で対象確認し、可能ならバックアップ
- ✅ 本番変更は「確認コマンド → 変更 → 再確認」の3段階
- ✅ `sudo` は必要最小限・短時間で利用

### 7) One interview-style question
「`chmod 777` を避けるべき理由と、代わりにどう設計すべきか（ユーザー・グループ・umask観点）を説明してください。」

### 8) Next-step resources
- `man chmod`, `man chown`, `man umask`, `man sudoers`
- CIS Benchmarks（Linux権限ハードニングの観点）
- Linux Foundation training materials

---

## 今日のまとめ
- Beginner: **読む・探す**（ログ調査）
- Middle: **見つける・止める**（プロセス制御）
- Advanced: **守る**（権限管理）

次号はこの流れを引き継ぎ、
**Beginner: アーカイブ基礎（tar/gzip）→ Middle: ディスク調査（du/df/lsof）→ Advanced: 自動化（cron/systemd timer）** を扱います。