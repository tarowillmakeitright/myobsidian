---
tags: [linux, commands, learning, devops, daily]
---

# Daily Linux Commands Magazine — 2026-03-23 09:15
[[Home]]

## 学習アークA-1
### 1) Topic + Level
**テーマ:** ファイル探索と内容確認の基本（`ls` / `cd` / `pwd` / `cat` / `less` / `head` / `tail`）  
**Level:** Beginner

### 2) Why it matters in real projects
本番障害対応やCIログ調査では、まず「どこに何があるか」を速く正確に把握する力が必要です。基礎コマンドを安全に使えると、誤操作を減らし、調査速度が上がります。

### 3) Core command explanations
- `pwd`: 現在位置を確認。迷子防止。
- `ls -lah`: ファイル一覧を詳細表示（権限・サイズ・更新時刻）。
- `cd <dir>`: ディレクトリ移動。`cd -` で直前に戻る。
- `cat <file>`: 小さなファイルを一気に表示。
- `less <file>`: 長いファイルを安全に閲覧（`q` で終了）。
- `head -n 20 <file>` / `tail -n 20 <file>`: 先頭/末尾だけ確認。
- `tail -f <log>`: ログ監視（Ctrl+C で停止）。

### 4) 30-60 minute hands-on mini lab
**目標:** ログ調査の基礎動作を身につける（約40分）
1. 練習用ディレクトリを作成  
   `mkdir -p ~/linux-mag-lab/a1 && cd ~/linux-mag-lab/a1`
2. サンプルログ作成  
   `seq 1 200 | sed 's/^/INFO line /' > app.log`
3. 全体把握  
   `pwd` → `ls -lah`
4. 中身確認  
   `head -n 5 app.log` / `tail -n 5 app.log`
5. ページャで閲覧  
   `less app.log`（検索: `/INFO line 150`）
6. 追記監視  
   別ターミナルで `echo "ERROR db timeout" >> app.log` を数回実行し、元ターミナルで `tail -f app.log` で確認。

### 5) Command cheatsheet
- 位置確認: `pwd`
- 一覧詳細: `ls -lah`
- 移動: `cd <path>` / `cd -`
- 閲覧: `cat`, `less`
- 部分表示: `head -n`, `tail -n`
- 監視: `tail -f`

### 6) Common mistakes and safe practices
- **ミス:** `cat` で巨大ログを開いてターミナルが読みにくくなる。  
  **安全策:** まず `less` / `head` / `tail` を使う。
- **ミス:** 相対パス誤認で別場所を操作。  
  **安全策:** 実行前に `pwd` と `ls` で確認。
- **注意:** `sudo` は必要最小限。閲覧作業は通常ユーザーで十分。

### 7) One interview-style question
`tail -f` と `less +F` はどちらもログ追跡できます。運用現場での使い分けを説明してください。

### 8) Next-step resources
- manページ: `man ls`, `man less`, `man tail`
- TLDP (The Linux Documentation Project)
- `explainshell.com`（オプションの意味確認に便利）

---

## 学習アークA-2
### 1) Topic + Level
**テーマ:** テキスト検索とパイプ処理（`grep` / `wc` / `sort` / `uniq` / `cut`）  
**Level:** Middle  
**前提:** Beginnerレベルの「ファイル閲覧・ログ確認」ができること

### 2) Why it matters in real projects
障害一次切り分けでは、ログから「頻発エラー」「特定ユーザー影響」「時間帯偏り」を短時間で抽出する必要があります。パイプ処理ができると、簡易分析を即実施できます。

### 3) Core command explanations
- `grep "ERROR" app.log`: 文字列一致行を抽出。
- `grep -E "WARN|ERROR" app.log`: 正規表現（拡張）検索。
- `wc -l`: 行数カウント。
- `cut -d' ' -f1,2`: 区切りで列抽出。
- `sort` / `uniq -c`: 並び替えと重複集計。
- パイプ `|`: 前コマンド出力を次コマンド入力へ接続。

### 4) 30-60 minute hands-on mini lab
**目標:** ログのエラー集計レポートを作る（約45分）
1. テストデータ作成  
   ```bash
   mkdir -p ~/linux-mag-lab/a2 && cd ~/linux-mag-lab/a2
   cat > app.log <<'EOF'
   2026-03-23T09:00:01 INFO auth success user=alice
   2026-03-23T09:00:12 ERROR db timeout user=alice
   2026-03-23T09:01:10 WARN api slow user=bob
   2026-03-23T09:02:11 ERROR db timeout user=carol
   2026-03-23T09:02:45 ERROR cache miss user=bob
   EOF
   ```
2. ERROR行抽出  
   `grep "ERROR" app.log > error.log`
3. 件数確認  
   `wc -l error.log`
4. エラー種別集計（3列目=ERROR, 4列目=種別想定）  
   `cut -d' ' -f4-5 error.log | sort | uniq -c | sort -nr`
5. ユーザー別影響集計  
   `grep "ERROR" app.log | grep -o 'user=[^ ]*' | sort | uniq -c | sort -nr`

### 5) Command cheatsheet
- 検索: `grep`, `grep -E`
- 件数: `wc -l`
- 列抽出: `cut -d -f`
- 集計: `sort | uniq -c | sort -nr`

### 6) Common mistakes and safe practices
- **ミス:** 正規表現の解釈違い（`.` や `*` の誤用）。  
  **安全策:** まずサンプル数行で検証してから本番ログへ。
- **ミス:** `sudo grep` を常用。  
  **安全策:** 権限が必要な時だけ `sudo`。`sudo` でのリダイレクトには注意（`>` はシェル側で実行）。
- **注意:** 本番ログを直接書き換えない。解析はコピーや読み取り専用で行う。

### 7) One interview-style question
`grep "ERROR" app.log | wc -l` と `grep -c "ERROR" app.log` の違いと、どちらを選ぶか説明してください。

### 8) Next-step resources
- manページ: `man grep`, `man cut`, `man uniq`
- 正規表現チートシート（POSIX ERE）
- SRE本のログ分析章

---

## 学習アークA-3
### 1) Topic + Level
**テーマ:** 権限・所有者と安全運用（`chmod` / `chown` / `find` / `xargs` 基礎）  
**Level:** Advanced  
**前提:** Middleレベルの「検索・抽出・パイプ処理」ができること

### 2) Why it matters in real projects
権限ミスは情報漏えい・サービス停止の主要原因です。特にCI/CDや運用自動化では、最小権限を守りつつ一括変更を安全に行う設計が必須です。

### 3) Core command explanations
- `ls -l`: 権限/所有者確認。
- `chmod 640 file`: 権限変更（所有者rw, グループr, その他なし）。
- `chown user:group file`: 所有者変更。
- `find <dir> -type f -name "*.log"`: 条件検索。
- `find ... -print0 | xargs -0 ...`: 空白入りファイル名に安全対応。

### 4) 30-60 minute hands-on mini lab
**目標:** 安全な一括権限是正を実施（約60分）
1. 練習環境作成  
   ```bash
   mkdir -p ~/linux-mag-lab/a3/{logs,bin,conf}
   touch ~/linux-mag-lab/a3/logs/app.log ~/linux-mag-lab/a3/conf/app.conf
   echo -e '#!/usr/bin/env bash\necho ok' > ~/linux-mag-lab/a3/bin/run.sh
   chmod 777 ~/linux-mag-lab/a3/logs/app.log
   chmod 777 ~/linux-mag-lab/a3/conf/app.conf
   chmod 777 ~/linux-mag-lab/a3/bin/run.sh
   ```
2. 現状確認  
   `find ~/linux-mag-lab/a3 -maxdepth 2 -printf '%M %u:%g %p\n'`
3. 方針設定  
   - `bin/*.sh` は `750`
   - `conf/*.conf` は `640`
   - `logs/*.log` は `640`
4. **ドライラン（まず表示のみ）**  
   `find ~/linux-mag-lab/a3 -type f -name '*.conf' -print`
5. 変更実施  
   ```bash
   chmod 750 ~/linux-mag-lab/a3/bin/run.sh
   chmod 640 ~/linux-mag-lab/a3/conf/app.conf ~/linux-mag-lab/a3/logs/app.log
   ```
6. 変更後検証  
   `find ~/linux-mag-lab/a3 -maxdepth 2 -printf '%M %u:%g %p\n'`

### 5) Command cheatsheet
- 権限確認: `ls -l`, `find -printf '%M %p\n'`
- 権限変更: `chmod 640 file`, `chmod 750 script.sh`
- 所有者変更: `chown user:group file`
- 安全一括: `find ... -print0 | xargs -0`

### 6) Common mistakes and safe practices
- **重大注意:** `chmod -R 777` は原則禁止（過剰権限で重大事故）。
- **重大注意:** `chown -R` は対象パスを誤ると広範囲破壊。必ず `pwd` と対象確認後に実施。
- **重大注意:** `rm -rf` は今回の演習では不要。使う場合は **対象を `echo` で先に確認** し、可能なら `trash` を優先。
- **sudo リスク:** `sudo` は最終手段。実行前に「本当に root が必要か」を確認。
- **安全策:** 本番前に同構成の検証ディレクトリで手順をリハーサル。

### 7) One interview-style question
Webアプリ配備ディレクトリで「実行可能にすべきもの」と「読み取り専用にすべきもの」をどう分類し、なぜその権限設計にするか説明してください。

### 8) Next-step resources
- manページ: `man chmod`, `man chown`, `man find`, `man xargs`
- CIS Benchmarks（Linux権限の考え方）
- Linux Foundation の運用系トレーニング

---

## 今日の一言
基礎コマンドは「速さ」より「事故らない正確さ」。  
**確認（pwd/ls）→ ドライラン → 実行 → 検証** の順を習慣化しましょう。