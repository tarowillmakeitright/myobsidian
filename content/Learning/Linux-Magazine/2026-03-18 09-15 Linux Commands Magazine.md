# Daily Linux Commands Magazine — 2026-03-18 09:15
#linux #commands #learning #devops #daily
[[Home]]

---

## 学習アーク 1

### 1) Topic + Level
**トピック:** ログ調査の基本（`ls` / `cat` / `less` / `grep` / `tail`）  
**レベル:** **Beginner（初級）**

### 2) Why it matters in real projects
本番・開発環境で不具合が起きたとき、最初に頼るのはログです。  
ログを素早く読めると、原因切り分け（アプリか、設定か、ネットワークか）が早くなり、復旧時間を短縮できます。

### 3) Core command explanations
- `ls -lah /var/log` : ログディレクトリの一覧を人間に読みやすい形式で表示
- `less /var/log/messages` : 大きいログをページ送りで安全に閲覧（`q` で終了）
- `grep -i "error" app.log` : 大文字小文字を無視して "error" を検索
- `tail -n 50 app.log` : 末尾50行を確認
- `tail -f app.log` : リアルタイム監視（Ctrl+Cで停止）

### 4) 30-60 minute hands-on mini lab
**目標:** 疑似障害ログからエラー原因を特定する（30〜45分）

1. 作業ディレクトリ作成
   ```bash
   mkdir -p ~/linux-magazine/lab1 && cd ~/linux-magazine/lab1
   ```
2. テストログ作成
   ```bash
   cat > app.log <<'EOF'
   INFO Start service
   INFO DB connected
   WARN retrying request
   ERROR timeout on api.example.local
   INFO healthcheck ok
   EOF
   ```
3. エラー抽出
   ```bash
   grep -n -i "error\|warn" app.log
   ```
4. 末尾監視の体験
   ```bash
   tail -f app.log
   ```
   別ターミナルで:
   ```bash
   echo "ERROR disk threshold exceeded" >> app.log
   ```
5. `less` で全体を確認し、発生順序をメモ

### 5) Command cheatsheet
```bash
ls -lah
less <file>
grep -n -i "keyword" <file>
tail -n 100 <file>
tail -f <file>
```

### 6) Common mistakes and safe practices
- `cat` で巨大ファイルを開いてターミナルが埋まる → **`less` を優先**
- `/var/log` 配下の権限不足で無理に `sudo` 連打 → **必要最小限の `sudo` のみ**
- ログ改変（`>` で上書き）事故 → **本番ログは基本読み取り専用で扱う**

### 7) One interview-style question
「`tail -f` と `less +F` の使い分けを、障害対応の現場目線で説明してください。」

### 8) Next-step resources
- `man grep`
- `man less`
- `man tail`
- systemd環境なら: `journalctl --help`

---

## 学習アーク 2

### 1) Topic + Level
**トピック:** プロセス監視とジョブ管理（`ps` / `top` / `pgrep` / `kill` / `nice`）  
**レベル:** **Middle（中級）**  
**前提（Prerequisites）:**
- 初級アークのログ読解ができる
- PID（プロセスID）とシグナルの基本概念を理解している

### 2) Why it matters in real projects
CPU高騰、メモリ逼迫、ハングなどの運用トラブルでは、どのプロセスが原因かを即時に掴む必要があります。安全な停止手順を知っていると、サービス断を最小化できます。

### 3) Core command explanations
- `ps aux --sort=-%cpu | head` : CPU使用率上位プロセスを確認
- `pgrep -af nginx` : コマンドライン付きで対象プロセス検索
- `top` : リアルタイムで負荷観測
- `kill -15 <PID>` : 丁寧な終了要求（SIGTERM）
- `kill -9 <PID>` : 最終手段（SIGKILL）
- `nice -n 10 <command>` : 優先度を下げて実行

### 4) 30-60 minute hands-on mini lab
**目標:** 高負荷プロセスを特定し、安全に停止する（40〜60分）

1. 擬似高負荷プロセス起動
   ```bash
   yes > /dev/null &
   yes > /dev/null &
   ```
2. PID確認
   ```bash
   pgrep -af "yes"
   ps aux --sort=-%cpu | head
   ```
3. `top` で負荷観察（1〜2分）
4. 安全停止（まずSIGTERM）
   ```bash
   kill -15 <PID1> <PID2>
   ```
5. 残存していれば最終手段
   ```bash
   kill -9 <PID>
   ```
6. 再発防止メモ（監視・閾値設定案）を3点書く

### 5) Command cheatsheet
```bash
ps aux --sort=-%cpu | head
pgrep -af <name>
top
kill -15 <PID>
kill -9 <PID>   # 最終手段
nice -n 10 <command>
```

### 6) Common mistakes and safe practices
- **誤PID kill** → `pgrep -af` と `ps -fp <PID>` で二重確認
- いきなり `kill -9` → **まず `-15`（graceful shutdown）**
- root権限で雑に停止 → **影響範囲（本番/検証）を先に確認**
- `sudo` 常用 → **必要なコマンドだけ限定して使う**

### 7) One interview-style question
「本番APIサーバーが高CPU時、`kill -9` を避ける理由と、段階的な対処フローを説明してください。」

### 8) Next-step resources
- `man ps`
- `man top`
- `man kill`
- `man nice`

---

## 学習アーク 3

### 1) Topic + Level
**トピック:** ファイル権限・所有権を安全に扱う（`chmod` / `chown` / `umask` / `find`）  
**レベル:** **Advanced（上級）**  
**前提（Prerequisites）:**
- 中級アークのプロセス・権限意識がある
- rwx（読み/書き/実行）とユーザー/グループ/その他を説明できる

### 2) Why it matters in real projects
権限設定ミスは、情報漏えい・サービス停止・デプロイ失敗の直接原因になります。特にCI/CDや共有サーバーでは、最小権限原則が必須です。

### 3) Core command explanations
- `ls -l` : 現在の権限と所有者を確認
- `chmod 640 file` : 例）所有者rw, グループr, その他なし
- `chmod -R` : 再帰変更（**危険**、対象を厳密確認）
- `chown user:group file` : 所有者・グループ変更
- `umask 027` : 新規作成時のデフォルト権限を制御
- `find . -type f -perm -o+w` : world-writableファイル検出

### 4) 30-60 minute hands-on mini lab
**目標:** 「安全な権限モデル」を作り、危険設定を検知・是正する（45〜60分）

1. 検証環境作成
   ```bash
   mkdir -p ~/linux-magazine/lab3/project && cd ~/linux-magazine/lab3/project
   touch app.conf deploy.sh notes.txt
   chmod 777 notes.txt
   ```
2. 現状確認
   ```bash
   ls -l
   find . -type f -perm -o+w
   ```
3. 是正
   ```bash
   chmod 640 app.conf notes.txt
   chmod 750 deploy.sh
   ```
4. 新規ファイル方針確認
   ```bash
   umask
   umask 027
   touch newfile && ls -l newfile
   ```
5. レポート作成（5行でOK）
   - 何が危険だったか
   - どう是正したか
   - 本番での再発防止策

### 5) Command cheatsheet
```bash
ls -l
chmod 640 <file>
chmod 750 <script>
chown <user>:<group> <file>
umask 027
find <path> -type f -perm -o+w
```

### 6) Common mistakes and safe practices
- **`chmod -R 777` は原則禁止**（過剰権限）
- **`chown -R` は対象ディレクトリを誤ると大事故**
- `rm -rf` と組み合わせた自動化は特に危険（変数展開ミスで破壊）
- 実行前に以下を徹底:
  1. `pwd` と `ls` で現在地確認
  2. 対象を `echo` でドライラン表示
  3. 可能なら検証環境で先に実行
- `sudo` は最小限。レビュー可能なコマンド履歴を残す

### 7) One interview-style question
「`chmod 777` を避けるべき理由を、セキュリティと運用の両面から説明し、代替案を提示してください。」

### 8) Next-step resources
- `man chmod`
- `man chown`
- `man umask`
- Linux Foundation: file permissions best practices

---

## 今日のまとめ
- 初級: ログを**読む力**
- 中級: プロセスを**安全に制御する力**
- 上級: 権限を**壊さず守る力**

> 実務では「速さ」より「安全で再現可能な手順」が価値になります。特に `rm -rf`、`chmod/chown -R`、`sudo` は毎回“本当に必要か”を確認してから実行しましょう。
