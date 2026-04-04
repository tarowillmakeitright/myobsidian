---
tags:
  - linux
  - commands
  - learning
  - devops
  - daily
---

[[Home]]

# Daily Linux Commands Magazine — 2026-04-04 09:15

> 学習アーク: **Beginner → Middle → Advanced**
> 
> 今号テーマは「**ログ調査と安全な運用トラブルシュート**」。

---

## 1) Topic + Level

### Topic: ログ調査で障害の初動対応を速くする

- **Beginner:** `ls`, `cat`, `less`, `tail` でログを読む
- **Middle:** `grep`, `awk`, `cut`, `sort`, `uniq` でログを絞り込む
  - **前提条件:** Beginner の内容（ファイル閲覧・基本パイプ）
- **Advanced:** `journalctl`, `xargs`, `find`, 安全なワンライナー設計
  - **前提条件:** Middle の内容（テキスト処理・パイプ）

---

## 2) Why it matters in real projects

本番運用では「エラーが出た」に対して、まず事実確認が必要です。  
ログ調査スキルがあると、以下ができるようになります。

- 障害切り分け時間の短縮（アプリ問題か、OS/ネットワーク問題か）
- 再現手順の特定（いつ・誰が・何をしたか）
- 変更影響の検証（デプロイ後に異常が増えたか）
- 上長・顧客への説明の質向上（推測ではなく根拠で話せる）

---

## 3) Core command explanations

### Beginner

- `less /var/log/syslog`  
  長いログを安全に閲覧（編集しない）。`/keyword` で検索、`q` で終了。
- `tail -n 100 /var/log/syslog`  
  最新100行を確認。
- `tail -f /var/log/syslog`  
  追記をリアルタイム監視（Ctrl+C で停止）。

### Middle

- `grep -i "error" app.log`  
  大文字小文字を無視して `error` を検索。
- `grep -E "timeout|refused|denied" app.log`  
  複数パターンを1回で検出。
- `awk '{print $1, $2, $5}' app.log`  
  列ベースで必要情報だけ抽出。
- `cut -d' ' -f1-3 app.log`  
  区切り文字指定で列抽出。
- `sort | uniq -c | sort -nr`  
  出現頻度を集計して多い順に並べる。

### Advanced

- `journalctl -u nginx --since "1 hour ago"`  
  systemdサービス単位で直近ログ確認。
- `find /var/log -type f -name "*.log" -mtime -1`  
  24時間以内に更新されたログを列挙。
- `grep -R "FATAL" /var/log/myapp/`  
  ディレクトリ再帰検索。
- `xargs` 利用時の注意: スペース・改行を含むファイル名で事故るため、`-print0` と `xargs -0` を基本にする。

---

## 4) 30-60 minute hands-on mini lab

### 目標
「最近増えたエラーの原因候補を3つ挙げる」

### 手順（45分想定）

1. **準備 (5分)**
   - 練習用ディレクトリ作成: `mkdir -p ~/lab/logs && cd ~/lab/logs`
   - 疑似ログ生成（安全なローカルファイルのみ）

2. **Beginner操作 (10分)**
   - `less sample.log`
   - `tail -n 50 sample.log`
   - `tail -f sample.log`（別ターミナルで追記して挙動確認）

3. **Middle操作 (15分)**
   - `grep -i "error" sample.log | wc -l`
   - `grep -E "timeout|denied|refused" sample.log`
   - `awk '{print $5}' sample.log | sort | uniq -c | sort -nr | head`

4. **Advanced操作 (15分)**
   - `journalctl --since "30 min ago" | grep -i "error" | head -n 30`
   - `find ~/lab/logs -type f -name "*.log" -print0 | xargs -0 grep -H "ERROR"`

### 成果物
- エラー上位3種
- 発生時刻帯
- 次に確認すべき対象（例: DB接続、認証、外部API）

---

## 5) Command cheatsheet

- 閲覧: `less file.log`, `tail -n 100 file.log`, `tail -f file.log`
- 検索: `grep -i "error" file.log`, `grep -E "a|b|c" file.log`
- 集計: `... | sort | uniq -c | sort -nr`
- 列抽出: `awk '{print $1,$2,$5}'`, `cut -d' ' -f1-3`
- systemdログ: `journalctl -u <service> --since "1 hour ago"`
- 安全な一括処理: `find ... -print0 | xargs -0 ...`

---

## 6) Common mistakes and safe practices

### よくあるミス

- `sudo` を何となく付ける（不要な権限昇格）
- `grep -R` をルートディレクトリに対して実行し、重くする
- ログ確認中に誤って編集系コマンドを実行する
- `xargs` を `-0` なしで使い、意図しない対象を処理する

### 安全プラクティス（重要）

- **破壊的コマンド注意:** `rm -rf` は対象パスを `pwd` と `ls` で二重確認してから。可能なら `trash` を使う。
- **権限変更注意:** `chmod -R` / `chown -R` は誤爆時の影響大。必ず対象を絞り、まず `echo` でドライラン相当を確認。
- **sudo注意:** 必要最小限で使用。コマンド意味を理解してから実行。
- 本番相当の調査は「読み取り中心」で開始し、変更は最後に最小限。

---

## 7) One interview-style question

「`tail -f` と `journalctl -f -u <service>` の使い分けを、本番障害対応の観点で説明してください。  
また、証跡保全（後から検証可能）を意識するなら、どのようなコマンド実行ログを残しますか？」

---

## 8) Next-step resources

- manページ: `man grep`, `man awk`, `man journalctl`, `man find`, `man xargs`
- The Linux Command Line (William Shotts)
- 高品質チートシート: tldr (`tldr grep`, `tldr awk`)
- 次号予告: 「プロセス監視と性能調査（`ps`, `top`, `htop`, `vmstat`, `iostat`）」

---

### 今日のひとこと
ログは「読む技術」が9割。  
焦って直すより、先に事実を集めると復旧が速く、安全です。
