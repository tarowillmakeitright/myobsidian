---
tags: [linux, commands, learning, devops, daily]
---

# Daily Linux Commands Magazine — 2026-03-31
#linux #commands #learning #devops #daily
[[Home]]

実務で効く Linux コマンド学習を、**初級 → 中級 → 上級**の学習アークで進めます。

---

## 1) Topic + Level

### 初級（Beginner）
**トピック:** ログ確認の基本（`ls` / `cat` / `less` / `tail` / `grep`）

### 中級（Middle）
**トピック:** ログ解析の効率化（`awk` / `sort` / `uniq` / `cut` / `xargs`）

**前提条件（Prerequisites）:**
- 初級の内容（標準出力・標準入力・パイプ `|`）を理解している
- `grep` と `tail` を使ってログを追える

### 上級（Advanced）
**トピック:** 安全な障害調査フロー（`journalctl` / `find` / `du` / `df` / `tee` / `sudo`の適切運用）

**前提条件（Prerequisites）:**
- 中級のパイプ処理を組み立てられる
- 権限（所有者・グループ・パーミッション）の基本を理解している
- 変更系コマンド実行前に検証（dry-run相当）を行える

---

## 2) Why it matters in real projects

- 本番障害の一次対応では、まず「**何が起きたかを安全に観測**」する力が重要です。
- 開発・運用現場では、ログ調査が遅いと復旧が遅れ、影響範囲が拡大します。
- 強いエンジニアは、破壊的変更を避けつつ、事実を最短で抽出できます。

---

## 3) Core command explanations

### 初級コマンド
- `ls -lah` : ファイルサイズ・権限を含めて一覧表示
- `less file.log` : 長いログを安全に閲覧（編集しない）
- `tail -n 50 file.log` : 末尾50行を見る
- `tail -f file.log` : 追記監視（Ctrl+Cで終了）
- `grep "ERROR" file.log` : エラー行抽出

### 中級コマンド
- `cut -d' ' -f1-3` : 区切り文字で列抽出
- `awk '{print $1, $2, $NF}'` : 柔軟な列操作
- `sort | uniq -c | sort -nr` : 出現頻度集計
- `xargs -r` : 前段の出力を引数化（`-r`で空入力時実行しない）

### 上級コマンド
- `journalctl -u nginx --since "1 hour ago"` : サービス単位で直近ログ確認
- `df -h` : ディスク使用率確認
- `du -sh /var/log/* | sort -h` : 容量の大きいログ特定
- `find /var/log -type f -name "*.log" -mtime -1` : 1日以内更新ログ探索
- `cmd | tee output.txt` : 画面表示しつつ記録

---

## 4) 30-60 minute hands-on mini lab

**目標:** 「CPU高騰＋アプリ応答遅延」の想定で、ログから原因候補を絞る

### 0. 準備（5分）
```bash
mkdir -p ~/lab/linux-mag && cd ~/lab/linux-mag
cat > app.log <<'EOF'
2026-03-31T08:40:01 INFO api request_id=1 path=/health status=200 ms=12
2026-03-31T08:41:10 ERROR api request_id=2 path=/login status=500 ms=980
2026-03-31T08:41:11 ERROR api request_id=3 path=/login status=500 ms=1020
2026-03-31T08:41:12 WARN api request_id=4 path=/search status=200 ms=420
2026-03-31T08:42:01 ERROR db request_id=5 query=users timeout_ms=3000
2026-03-31T08:42:10 INFO api request_id=6 path=/health status=200 ms=9
EOF
```

### 1. 初級（10-15分）
```bash
ls -lah
less app.log
tail -n 3 app.log
grep "ERROR" app.log
```
- ERROR行だけ抽出できることを確認。

### 2. 中級（15-20分）
```bash
grep "ERROR" app.log | awk '{print $3}' | sort | uniq -c | sort -nr
grep "status=500" app.log | awk '{print $5}'
```
- どのコンポーネント（api/db）由来か、500発生箇所を特定。

### 3. 上級（15-20分）
```bash
# 監査用に結果保存（破壊なし）
grep "ERROR" app.log | tee error-lines.txt

# 遅いリクエスト候補（ms=400以上）
awk -F'ms=' '/ms=/{ if ($2+0 >= 400) print $0 }' app.log | tee slow-lines.txt
```
- `error-lines.txt` と `slow-lines.txt` を比較し、関連性を文章で3行まとめる。

---

## 5) Command cheatsheet

```bash
# 観測
ls -lah
less file.log
tail -n 100 file.log
tail -f file.log

# 抽出・集計
grep "ERROR" file.log
awk '{print $1,$2,$NF}' file.log
cut -d' ' -f1-3 file.log
grep "ERROR" file.log | sort | uniq -c | sort -nr

# システム確認
df -h
du -sh /var/log/* | sort -h
journalctl -u <service> --since "30 min ago"

# 記録
command | tee result.txt
```

---

## 6) Common mistakes and safe practices

### よくあるミス
1. `sudo`を習慣で付ける（不要な権限昇格）
2. `rm -rf`を補完任せで実行する
3. `chmod -R 777` で権限を雑に開放する
4. `chown -R` の対象パスを誤る
5. 本番で直接編集して差分記録を残さない

### 安全運用の原則
- **破壊的操作の前に確認:** `pwd`, `ls`, `echo` で対象確認
- **先に観測、後で変更:** まず `cat/less/grep/journalctl`
- **バックアップを取る:** `cp file file.bak`
- **`sudo`は最小限:** 必要コマンドだけに限定
- **危険コマンドは声に出して確認:**
  - `rm -rf` は削除先を2回確認
  - `chmod/chown -R` は対象ディレクトリを絶対パスで確認

> ⚠️ 警告: `rm -rf`, `chmod -R`, `chown -R`, 無制限な `sudo` はシステム破壊・情報漏洩のリスクがあります。学習ではまず検証用ディレクトリで実行し、本番環境での無検証実行を避けてください。

---

## 7) One interview-style question

**質問:**
本番APIで 5xx が増加したとき、あなたが最初の10分で実行するコマンドと確認順序を説明してください。なお、サービス停止を避けるため、破壊的変更は禁止です。

---

## 8) Next-step resources

- `man grep`, `man awk`, `man journalctl`
- The Linux Command Line（書籍）
- Google SRE Workbook（障害対応フロー）
- `tldr` コマンド（要点の早見）

**次回予告（学習アーク継続）:**
- 初級: `ps`, `top`, `htop` でプロセス観測
- 中級: `ss`, `lsof` で接続・ポート調査
- 上級: systemd ユニット障害の切り分け手順
