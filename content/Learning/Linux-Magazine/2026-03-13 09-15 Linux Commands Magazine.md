---
tags:
  - linux
  - commands
  - learning
  - devops
  - daily
---

# Daily Linux Commands Magazine - 2026-03-13
[[Home]]

## 1) Topic + Level
**テーマ:** `find` / `grep` / `xargs` で作る安全なログ調査パイプライン  
**レベル:** 初級 → 中級 → 上級（段階的ラーニングアーク）

- **初級 (Beginner):** `find` と `grep` で「必要なファイルを安全に探す」
- **中級 (Middle):** `xargs` と組み合わせて「複数ファイルを効率処理する」
  - **前提知識:** パス指定、標準入力/標準出力、`grep` の基本オプション
- **上級 (Advanced):** NUL区切り・安全設計・運用向けワンライナー化
  - **前提知識:** 中級内容、シェルクォート、権限（`sudo`）の基本理解

---

## 2) Why it matters in real projects
本番運用や開発現場では、以下が日常的に発生します。

- 障害調査で「いつ・どこで・何が起きたか」を短時間で特定する
- 巨大なログ/設定ファイル群から、関連箇所だけ抽出する
- 手作業ミスを減らし、再現可能な調査手順を残す

`find` + `grep` + `xargs` は、**監視アラート調査・デプロイ後確認・監査対応** などで即戦力です。

---

## 3) Core command explanations

### A. `find`（対象ファイルを絞る）
```bash
find /var/log -type f -name "*.log"
```
- `-type f`: 通常ファイルのみ
- `-name "*.log"`: 拡張子 `.log` を対象

### B. `grep`（内容を検索する）
```bash
grep -n "ERROR" app.log
```
- `-n`: 行番号を表示（調査時に重要）

```bash
grep -R --include="*.log" -n "timeout" /var/log/myapp
```
- `-R`: 再帰検索
- `--include`: 対象拡張子を制限

### C. `xargs`（複数入力をコマンド引数に渡す）
```bash
find . -type f -name "*.log" | xargs grep -n "ERROR"
```
- 複数ファイルへ `grep` を適用
- ただし空白や改行を含むファイル名で壊れる可能性あり（後述）

### D. 安全版（推奨）NUL区切り
```bash
find . -type f -name "*.log" -print0 | xargs -0 grep -n "ERROR"
```
- `-print0` + `-0` で、特殊文字を含むファイル名でも安全

### E. 権限が必要な領域
```bash
sudo grep -R -n "Failed password" /var/log
```
- `sudo` は最小範囲で使用し、必要な時だけ実行

---

## 4) 30-60 minute hands-on mini lab
**目標:** 疑似ログ環境でエラー調査フローを作る（安全第一）

### 0) 準備（5分）
```bash
mkdir -p ~/linux-mag-lab/logs/{app,nginx,db}
```

### 1) テストログ作成（10分）
```bash
cat > ~/linux-mag-lab/logs/app/app.log <<'EOF'
2026-03-13 09:00:01 INFO Start worker
2026-03-13 09:02:18 ERROR timeout while calling payment API
2026-03-13 09:04:44 WARN retrying request
EOF

cat > ~/linux-mag-lab/logs/nginx/access.log <<'EOF'
127.0.0.1 - - [13/Mar/2026:09:00:01 +0900] "GET /health HTTP/1.1" 200 2
127.0.0.1 - - [13/Mar/2026:09:02:19 +0900] "POST /checkout HTTP/1.1" 504 0
EOF

cat > ~/linux-mag-lab/logs/db/db.log <<'EOF'
2026-03-13 09:02:18 connection timeout from app-server-01
EOF
```

### 2) 初級タスク（10分）
- `find` で `.log` 一覧を出す
- `grep -n` で `ERROR` を探す

例:
```bash
find ~/linux-mag-lab/logs -type f -name "*.log"
grep -n "ERROR" ~/linux-mag-lab/logs/app/app.log
```

### 3) 中級タスク（10-15分）
- 全ログから `timeout` を横断検索

```bash
grep -R --include="*.log" -n "timeout" ~/linux-mag-lab/logs
```

- `find` + `xargs` で同等処理

```bash
find ~/linux-mag-lab/logs -type f -name "*.log" -print0 | xargs -0 grep -n "timeout"
```

### 4) 上級タスク（10-20分）
- 「再利用可能な安全スクリプト」を作る

```bash
cat > ~/linux-mag-lab/search_logs.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="${1:-$HOME/linux-mag-lab/logs}"
KEYWORD="${2:-ERROR}"

find "$BASE_DIR" -type f -name "*.log" -print0 \
  | xargs -0 grep -n -- "$KEYWORD" || true
EOF

chmod 700 ~/linux-mag-lab/search_logs.sh
~/linux-mag-lab/search_logs.sh ~/linux-mag-lab/logs timeout
```

- `set -euo pipefail` の意味を確認し、失敗時挙動を観察する

---

## 5) Command cheatsheet
```bash
# ファイル検索
find /path -type f -name "*.log"

# 再帰grep
grep -R --include="*.log" -n "PATTERN" /path

# 安全な find + xargs
find /path -type f -name "*.log" -print0 | xargs -0 grep -n "PATTERN"

# 大文字小文字を無視
grep -R -i -n "error" /path

# 行番号付きで複数キーワード（拡張正規表現）
grep -R -nE "ERROR|WARN|timeout" /path
```

---

## 6) Common mistakes and safe practices

### よくあるミス
1. **`xargs` を素のまま使う**（空白入りファイル名で事故）
2. **検索範囲が広すぎる**（`/` 全体など）→ 遅い・ノイズ過多
3. **`sudo` を常用する**（不要な権限昇格）
4. **結果ゼロを異常扱いする**（`grep` は未ヒット時終了コード1）

### 安全プラクティス
- まずは対象を限定（例: `/var/log/myapp`）
- `-print0` / `-0` を優先して使う
- `sudo` は「必要な1コマンドだけ」に絞る
- スクリプト化時は `set -euo pipefail` を基本にする
- 破壊的操作の前に `echo` で対象確認する

### ⚠ 破壊的コマンドへの警告
- `rm -rf`, `chmod -R`, `chown -R` は誤対象で重大事故になります。
- 本番で実行前に、**対象パスを二重確認**し、可能なら `ls` / `find` で事前確認。
- `sudo rm -rf ...` は最終手段。レビューやバックアップなしで実行しない。

---

## 7) Interview-style question
「`find ... -print0 | xargs -0 ...` の組み合わせは、なぜ運用現場で推奨されるのですか？通常のパイプと比較して、どんな障害やバグを防げるか説明してください。」

---

## 8) Next-step resources
- `man find`, `man grep`, `man xargs`
- GNU Findutils / Grep 公式ドキュメント
- The Linux Command Line（William Shotts）
- 次の学習アーク案:
  - 初級: `cut`, `sort`, `uniq`
  - 中級: `awk` でログ集計
  - 上級: `journalctl` と `systemd` 障害解析

---

明日の予告: `awk` で「抽出→集計→可視化（CLI）」を実践し、運用報告に直結するワークフローを作ります。
