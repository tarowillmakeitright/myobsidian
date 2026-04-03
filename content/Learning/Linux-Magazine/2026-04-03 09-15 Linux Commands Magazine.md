---
tags: [linux, commands, learning, devops, daily]
---

# 2026-04-03 Linux Commands Magazine
[[Home]]

#linux #commands #learning #devops #daily

## 学習アークA（Beginner）
### 1) Topic + Level
**テーマ:** ログ調査の第一歩（`ls`, `cat`, `less`, `tail`）  
**レベル:** Beginner

### 2) Why it matters in real projects
本番障害の初動では、まず「どこに何のログがあるか」「直近で何が起きたか」を安全に確認できることが重要です。開発でも運用でも、ログ読解の速さが復旧時間に直結します。

### 3) Core command explanations
- `ls -lah` : ファイル一覧を人間に読みやすい形式で表示。
- `cat file.log` : ファイル全体を表示（巨大ファイルには不向き）。
- `less file.log` : ページャで安全に閲覧（`/キーワード` で検索、`q`で終了）。
- `tail -n 50 file.log` : 末尾50行を確認。
- `tail -f file.log` : 追記をリアルタイム監視。

> 安全メモ: 読み取りコマンド中心。まずは「読むだけ」で状況把握する習慣をつける。

### 4) 30-60 minute hands-on mini lab
**目標:** 疑似アプリログからエラーを発見する（40分）
1. 作業ディレクトリ作成:
   ```bash
   mkdir -p ~/lab/logs && cd ~/lab/logs
   ```
2. サンプルログ作成:
   ```bash
   cat > app.log <<'EOF'
   2026-04-03 09:00:01 INFO server started
   2026-04-03 09:03:11 INFO health check ok
   2026-04-03 09:07:44 WARN db response slow
   2026-04-03 09:10:02 ERROR failed to connect redis
   2026-04-03 09:11:20 INFO retry succeeded
   EOF
   ```
3. `ls -lah` で存在確認。
4. `less app.log` で全文を確認し、`/ERROR` で検索。
5. `tail -n 3 app.log` で直近イベント確認。
6. 追加ログを別ターミナルから追記し、`tail -f app.log` で監視:
   ```bash
   echo "2026-04-03 09:14:59 ERROR timeout on /api/items" >> app.log
   ```

### 5) Command cheatsheet
```bash
ls -lah
less app.log
tail -n 100 app.log
tail -f app.log
```

### 6) Common mistakes and safe practices
- ミス: `cat` で巨大ログを開いてターミナルが流れる。  
  対策: `less` / `tail -n` を優先。
- ミス: root権限前提で作業開始。  
  対策: まず一般ユーザーで読める範囲を調査。
- 安全: 変更コマンド（削除・権限変更）に進む前に読み取りで根拠を集める。

### 7) One interview-style question
「`tail -f` と `less +F` の違いを説明し、障害対応時にどちらを使うか理由付きで答えてください。」

### 8) Next-step resources
- manページ: `man less`, `man tail`
- The Linux Command Line（William Shotts）
- 実務演習: `/var/log` 配下を読み取り専用で探索（環境ルールに従う）

---

## 学習アークA（Middle）
### 1) Topic + Level
**テーマ:** テキスト抽出と集計（`grep`, `cut`, `sort`, `uniq`, `wc`）  
**レベル:** Middle  
**前提:** Beginnerの「ログ閲覧（less/tail）」を理解していること。

### 2) Why it matters in real projects
SRE/運用では「エラー件数」「特定APIの失敗頻度」「どのホストで多発しているか」を短時間で集計する必要があります。ワンライナーで一次分析できると調査速度が大きく向上します。

### 3) Core command explanations
- `grep "ERROR" app.log` : エラー行抽出。
- `cut -d' ' -f1-2` : 区切り文字で特定列を取り出し。
- `sort` : 並び替え（集計前の定番）。
- `uniq -c` : 重複行の件数集計（通常 `sort | uniq -c` の形）。
- `wc -l` : 行数カウント。

### 4) 30-60 minute hands-on mini lab
**目標:** 失敗エンドポイント上位を集計する（45分）
1. サンプルアクセスログ作成:
   ```bash
   cd ~/lab/logs
   cat > access.log <<'EOF'
   10.0.0.1 GET /api/users 200
   10.0.0.2 GET /api/items 500
   10.0.0.3 GET /api/items 500
   10.0.0.4 POST /api/orders 201
   10.0.0.5 GET /api/items 500
   10.0.0.6 GET /api/users 200
   10.0.0.7 GET /api/orders 503
   EOF
   ```
2. 5xxのみ抽出:
   ```bash
   grep -E ' 5[0-9][0-9]$' access.log
   ```
3. 失敗パスの件数ランキング:
   ```bash
   grep -E ' 5[0-9][0-9]$' access.log | cut -d' ' -f3 | sort | uniq -c | sort -nr
   ```
4. 総失敗件数:
   ```bash
   grep -E ' 5[0-9][0-9]$' access.log | wc -l
   ```

### 5) Command cheatsheet
```bash
grep "ERROR" app.log
grep -E ' 5[0-9][0-9]$' access.log
cut -d' ' -f3 access.log
sort access.log | uniq -c
wc -l access.log
```

### 6) Common mistakes and safe practices
- ミス: 正規表現が広すぎて誤検知。  
  対策: まず `grep` 単体でヒット行を目視確認。
- ミス: 区切り文字前提が壊れて `cut` 結果がズレる。  
  対策: ログ形式を先に確認（スペース数、タブ等）。
- 安全: 本番ログを直接編集しない。解析用コピーで試す。

### 7) One interview-style question
「`sort | uniq -c | sort -nr` の処理意図を各段階で説明してください。なぜ最初の `sort` が必要ですか？」

### 8) Next-step resources
- manページ: `man grep`, `man cut`, `man sort`, `man uniq`
- 正規表現練習サイト（ERE/PCREの違いも確認）
- 次の実務課題: 日次エラーレポートをシェルで自動生成

---

## 学習アークA（Advanced）
### 1) Topic + Level
**テーマ:** 安全な権限管理と変更前チェック（`chmod`, `chown`, `find`, `xargs`）  
**レベル:** Advanced  
**前提:** Middleの「抽出・集計」と、Linuxパーミッション（rwx, 所有者/グループ）基礎理解。

### 2) Why it matters in real projects
権限ミスはインシデントの温床です。`chmod -R` や `chown -R` を誤ると、アプリ停止・情報漏えい・復旧遅延につながります。安全な変更手順（確認→限定→実行→検証）が必須です。

### 3) Core command explanations
- `find /path -type f -name "*.sh"` : 対象を正確に絞る。
- `find ... -print0 | xargs -0 ...` : 空白入りファイル名にも安全。
- `chmod 640 file` / `chmod 750 dir` : 最小権限で設定。
- `chown user:group file` : 所有者/グループ変更。
- `sudo` : 管理者権限実行。必要最小限で使用。

> ⚠️ 破壊的リスク警告
> - `chmod -R` / `chown -R` は広範囲に影響。**必ず事前に対象一覧を確認**。
> - `rm -rf` は復元困難。今回ラボでは使用しない。
> - `sudo` 付き一括変更は、コマンドを声に出して確認してから実行。

### 4) 30-60 minute hands-on mini lab
**目標:** 安全に権限是正を実施し、差分を検証する（55分）
1. 検証用ディレクトリ作成:
   ```bash
   mkdir -p ~/lab/permtest/{bin,data,logs}
   touch ~/lab/permtest/bin/deploy.sh ~/lab/permtest/data/app.db ~/lab/permtest/logs/app.log
   chmod 777 ~/lab/permtest/bin/deploy.sh
   chmod 666 ~/lab/permtest/data/app.db
   ```
2. 現状確認（変更前記録）:
   ```bash
   ls -l ~/lab/permtest/bin/deploy.sh ~/lab/permtest/data/app.db
   ```
3. 対象を絞って確認（ドライラン的手順）:
   ```bash
   find ~/lab/permtest -type f -name "*.sh"
   ```
4. 最小権限へ修正:
   ```bash
   chmod 750 ~/lab/permtest/bin/deploy.sh
   chmod 640 ~/lab/permtest/data/app.db
   ```
5. 再確認:
   ```bash
   ls -l ~/lab/permtest/bin/deploy.sh ~/lab/permtest/data/app.db
   ```
6. （任意）複数対象に適用する前に、まず `echo` で確認:
   ```bash
   find ~/lab/permtest -type f -name "*.sh" -print0 | xargs -0 -I{} echo chmod 750 "{}"
   ```

### 5) Command cheatsheet
```bash
find /path -type f -name "*.sh"
find /path -type f -print0 | xargs -0 -I{} echo "{}"
chmod 640 file
chmod 750 dir_or_script
chown user:group file
sudo -l
```

### 6) Common mistakes and safe practices
- ミス: `chmod -R 777` で全開放。  
  対策: 原則禁止。最小権限を個別設定。
- ミス: `chown -R` の対象パス誤り。  
  対策: 先に `find` で対象を一覧化、必要ならバックアップ。
- ミス: `sudo` 乱用で監査性低下。  
  対策: 必要時のみ使用し、実行履歴を残す。
- 安全: 変更前後を `ls -l` で比較し、意図通りか必ず検証。

### 7) One interview-style question
「本番で誤って `chmod -R 777 /var/www` を実行した場合、あなたはどう切り分け・復旧計画を立てますか？（初動、影響範囲、再発防止まで）」

### 8) Next-step resources
- manページ: `man chmod`, `man chown`, `man find`, `man xargs`, `man sudo`
- CIS Benchmarks（Linux権限/運用ガイド）
- 次の課題: `find` + `stat` で権限監査レポートを自動生成

---

## 今日のまとめ
- Beginner: まず読む（`less`/`tail`）
- Middle: 根拠を数える（`grep`/`sort`/`uniq`）
- Advanced: 安全に直す（`find`で絞る→`chmod/chown`最小変更→検証）

**原則:** 速さより安全。破壊的コマンドは「対象確認」「最小権限」「変更後検証」をセットで実施する。
