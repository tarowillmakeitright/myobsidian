---
tags: [linux, commands, learning, devops, daily]
---

# Daily Linux Commands Magazine — 2026-03-04
[[Home]]

## Learning Arc 1 — Beginner

### 1) Topic + Level
**Topic:** ファイル探索と安全な閲覧（`pwd`, `ls`, `cd`, `find`, `less`, `cat`）  
**Level:** Beginner

### 2) Why it matters in real projects
本番障害やログ調査では、まず「どこにいるか」「何があるか」「どのファイルを安全に読むか」を正確に把握する力が必要です。ここでミスすると、調査遅延や誤操作に直結します。

### 3) Core command explanations
- `pwd` : 現在の作業ディレクトリを表示
- `ls -lah` : 権限・サイズ・隠しファイルを含めて一覧表示
- `cd /path` : ディレクトリ移動（`cd -` で直前に戻る）
- `find . -name "*.log"` : 条件に合うファイルを再帰検索
- `less file.log` : 大きなファイルを安全にページ表示（編集しない）
- `cat file.txt` : 小さなファイルを表示（巨大ファイルには非推奨）

### 4) 30-60 minute hands-on mini lab
**所要時間:** 35分
1. `mkdir -p ~/lab/linux-mag/{logs,docs}`
2. `touch ~/lab/linux-mag/logs/app.log ~/lab/linux-mag/docs/readme.txt`
3. `echo "INFO startup" >> ~/lab/linux-mag/logs/app.log`
4. `pwd` と `ls -lah ~/lab/linux-mag/logs` で状態確認
5. `find ~/lab/linux-mag -name "*.log"` を実行
6. `less ~/lab/linux-mag/logs/app.log` で閲覧
7. 最後に `history | tail -n 20` で実行コマンドを振り返る

### 5) Command cheatsheet
- 位置確認: `pwd`
- 一覧確認: `ls -lah`
- 移動: `cd`, `cd -`, `cd ~`
- 検索: `find <dir> -name "<pattern>"`
- 閲覧: `less <file>`（推奨）, `cat <small_file>`

### 6) Common mistakes and safe practices
- **ミス:** `cat` で巨大ログを開いて端末が流れる  
  **対策:** `less` を使う
- **ミス:** 相対パスで迷子になる  
  **対策:** 実行前に必ず `pwd`
- **安全:** 読み取り中心の調査時は、編集系コマンド（`sed -i`, `mv`, `rm`）を避ける

### 7) One interview-style question
「`less` と `cat` を使い分ける基準を、運用ログ調査の観点で説明してください。」

### 8) Next-step resources
- `man ls`, `man find`, `man less`
- The Linux Command Line (William Shotts)
- `tldr find`, `tldr less`

---

## Learning Arc 2 — Middle

### 1) Topic + Level
**Topic:** テキスト処理パイプライン（`grep`, `sort`, `uniq`, `cut`, `wc`, `xargs`）  
**Level:** Middle  
**Prerequisites:** Beginnerの内容（パス操作・ファイル閲覧・基本的な標準入出力）

### 2) Why it matters in real projects
アプリログや監視データから「異常の傾向」を素早く抽出するには、複数コマンドをパイプでつなぐ力が必須です。SIEMや可観測性基盤がなくても一次解析が可能になります。

### 3) Core command explanations
- `grep "ERROR" app.log` : パターン抽出
- `grep -E "WARN|ERROR" app.log` : 拡張正規表現
- `cut -d' ' -f1` : 区切り文字で列抽出
- `sort` / `uniq -c` : ソート＋重複集計
- `wc -l` : 行数カウント
- `xargs` : 標準入力を引数に変換して別コマンド実行

### 4) 30-60 minute hands-on mini lab
**所要時間:** 45分
1. サンプルログ作成
   ```bash
   cat > ~/lab/linux-mag/logs/service.log <<'EOF'
   INFO api started
   WARN retry request_id=1
   ERROR db timeout request_id=2
   INFO api healthcheck
   ERROR db timeout request_id=3
   WARN retry request_id=4
   EOF
   ```
2. エラー行抽出: `grep "ERROR" ~/lab/linux-mag/logs/service.log`
3. WARN/ERROR集計:
   ```bash
   grep -E "WARN|ERROR" ~/lab/linux-mag/logs/service.log | cut -d' ' -f1 | sort | uniq -c
   ```
4. 総行数確認: `wc -l ~/lab/linux-mag/logs/service.log`
5. 複数ファイル対象（将来拡張）:
   ```bash
   find ~/lab/linux-mag/logs -name "*.log" | xargs grep -H "ERROR"
   ```

### 5) Command cheatsheet
- 抽出: `grep`, `grep -E`, `grep -H`
- 列処理: `cut -d -f`
- 集計: `sort | uniq -c`
- 件数: `wc -l`
- 一括処理: `xargs`

### 6) Common mistakes and safe practices
- **ミス:** 空白区切り前提で `cut` し、ログ形式変更で壊れる  
  **対策:** フォーマットを先に確認し、必要なら `awk` を使用
- **ミス:** `xargs` で意図せぬ大量実行  
  **対策:** 先に `echo` でドライラン（例: `... | xargs -I{} echo grep ERROR {}`）
- **安全:** `sudo` 付き解析は最小化。読み取り用途なら通常権限で実行

### 7) One interview-style question
「`grep | sort | uniq -c` パイプラインで障害分析するとき、順序を変えると何が変わりますか？」

### 8) Next-step resources
- `man grep`, `man cut`, `man xargs`
- GNU Coreutils docs
- `tldr grep`, `tldr xargs`

---

## Learning Arc 3 — Advanced

### 1) Topic + Level
**Topic:** 権限・所有者・安全なメンテナンス（`chmod`, `chown`, `sudo`, `rsync`, `tar`）  
**Level:** Advanced  
**Prerequisites:** Middleの内容（パイプ処理、ログ分析、基本ファイル操作）

### 2) Why it matters in real projects
権限ミスは情報漏えい・サービス停止・復旧遅延の主要因です。安全なバックアップ・デプロイ・復元手順を持つことは、SRE/DevOps業務の基礎体力です。

### 3) Core command explanations
- `chmod 640 file` : 権限設定（最小権限）
- `chown user:group file` : 所有者変更
- `sudo -l` : 実行可能な特権コマンド確認
- `rsync -av --dry-run src/ dst/` : 差分同期の事前確認
- `tar -czf backup.tgz dir/` : 圧縮バックアップ作成
- `tar -tzf backup.tgz` : 展開前に内容確認

### 4) 30-60 minute hands-on mini lab
**所要時間:** 50分
1. テストディレクトリ作成: `mkdir -p ~/lab/linux-mag/secure-data`
2. テストファイル作成: `echo "secret" > ~/lab/linux-mag/secure-data/secret.txt`
3. 権限確認: `ls -l ~/lab/linux-mag/secure-data/secret.txt`
4. 最小権限へ変更: `chmod 600 ~/lab/linux-mag/secure-data/secret.txt`
5. バックアップ作成:
   ```bash
   tar -czf ~/lab/linux-mag/secure-data.tgz -C ~/lab/linux-mag secure-data
   tar -tzf ~/lab/linux-mag/secure-data.tgz
   ```
6. 同期ドライラン:
   ```bash
   mkdir -p ~/lab/linux-mag/backup-target
   rsync -av --dry-run ~/lab/linux-mag/secure-data/ ~/lab/linux-mag/backup-target/
   ```
7. 変更前後を `ls -lah` で比較記録

### 5) Command cheatsheet
- 権限: `chmod 600`, `chmod 640`, `chmod 755`
- 所有者: `chown user:group file`
- 特権確認: `sudo -l`
- 同期: `rsync -av --dry-run src/ dst/`
- バックアップ: `tar -czf`, `tar -tzf`

### 6) Common mistakes and safe practices
- **危険:** `chmod -R 777` は原則禁止（過剰権限）
- **危険:** `chown -R` の誤対象指定でサービス破壊の可能性
- **危険:** `sudo` 常用は事故率を上げる。必要コマンドだけ最小利用
- **危険:** `rm -rf` は最終手段。実行前に `pwd` と対象を2回確認
- **安全策:**
  1. まず `--dry-run`（`rsync` など）
  2. バックアップ取得後に変更
  3. 変更対象を絶対パスで明示
  4. 重要操作はコマンド履歴を残す

### 7) One interview-style question
「本番サーバで権限修正が必要なとき、`chmod/chown` を安全に実施する手順を時系列で説明してください。」

### 8) Next-step resources
- `man chmod`, `man chown`, `man sudoers`, `man rsync`, `man tar`
- Linux Foundation: Essential System Administration
- 実環境での復旧訓練（ステージングで手順書化）

---

## 今日のまとめ
- Beginner: まずは“迷わず安全に読む”
- Middle: パイプで“傾向を抽出する”
- Advanced: 権限とバックアップで“安全に変更する”

次回はこの流れを維持しつつ、`systemd` 運用（サービス状態確認→ログ追跡→ユニット安全編集）へ進むと実務接続がさらに強くなります。