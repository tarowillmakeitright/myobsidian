---
tags:
  - linux
  - commands
  - learning
  - devops
  - daily
---

# Daily Linux Commands Magazine — 2026-04-05
[[Home]]

## 1) Topic + Level
**テーマ:** ログ調査と安全なテキスト解析（`tail` / `grep` / `less` / `awk` 基礎）  
**学習アーク:** Beginner → Middle → Advanced

- **Beginner（初級）:** `tail -f` と `grep` でログを「見る・絞る」
- **Middle（中級）:** `awk` とパイプでログを集計する
  - **前提条件:** パイプ（`|`）、リダイレクト（`>`/`>>`）、`grep` の基本が分かること
- **Advanced（上級）:** 複数ログの横断分析と安全な自動化（読み取り専用運用）
  - **前提条件:** `awk` の基本、正規表現の初歩、cron やシェルスクリプトの基本読解

---

## 2) Why it matters in real projects
本番運用では「障害が起きてから最初に触る」のがログです。  
アプリ障害、デプロイ失敗、権限エラー、ネットワーク遅延など、**原因特定の初動速度**で復旧時間（MTTR）が大きく変わります。

- 監視アラート受信後に、まず現状を把握できる
- 開発者・SRE・インフラ担当の会話が具体化する
- 「勘」ではなく、証拠ベースで切り分けできる

---

## 3) Core command explanations

### `tail`
- `tail -n 50 app.log` : 末尾50行を表示
- `tail -f app.log` : 追記をリアルタイム監視
- `tail -F app.log` : ログローテーション後も追跡（運用で便利）

### `grep`
- `grep "ERROR" app.log` : ERROR を含む行
- `grep -n "timeout" app.log` : 行番号付き
- `grep -E "ERROR|WARN" app.log` : OR 条件（拡張正規表現）
- `grep -i "failed" app.log` : 大文字小文字を無視

### `less`
- `less app.log` : 大きいファイルを安全に閲覧
- `less +F app.log` : `tail -f` 的に追従（`Ctrl+C`で追従解除）
- 検索: `/ERROR`、次へ: `n`

### `awk`（集計の入口）
- `awk '{print $1, $2}' app.log` : 1列目・2列目を出力
- `awk '/ERROR/ {count++} END {print count}' app.log` : ERROR 件数
- `awk '{a[$3]++} END {for (k in a) print k, a[k]}' app.log` : 3列目をキーに集計

> **安全原則:** 今日の演習はすべて「読み取り中心」。本番ログを直接編集・削除しない。

---

## 4) 30-60 minute hands-on mini lab
**目標:** ダミーログからエラー傾向を特定し、短いレポートを作る

### 0. 準備（5分）
```bash
mkdir -p ~/linux-lab/logs
cat > ~/linux-lab/logs/app.log <<'EOF'
2026-04-05T08:58:01 INFO api /health 200 12ms
2026-04-05T08:58:05 WARN api /v1/orders 429 31ms
2026-04-05T08:58:12 ERROR db connection_timeout 504 1200ms
2026-04-05T08:58:20 INFO worker job_sync 200 220ms
2026-04-05T08:58:34 ERROR api /v1/login 500 340ms
2026-04-05T08:58:51 WARN cache miss_user_profile 404 5ms
2026-04-05T08:59:10 ERROR api /v1/orders 502 870ms
2026-04-05T08:59:33 INFO api /v1/orders 200 45ms
EOF
```

### 1. Beginner（10-15分）
1. 末尾確認
```bash
tail -n 5 ~/linux-lab/logs/app.log
```
2. ERROR 抽出
```bash
grep "ERROR" ~/linux-lab/logs/app.log
```
3. WARN/ERROR のみ表示
```bash
grep -E "WARN|ERROR" ~/linux-lab/logs/app.log
```

### 2. Middle（15-20分）
1. ERROR 件数
```bash
awk '/ERROR/ {c++} END {print "ERROR count:", c+0}' ~/linux-lab/logs/app.log
```
2. ステータスコード別の件数（6列目）
```bash
awk '{code[$6]++} END {for (k in code) print k, code[k]}' ~/linux-lab/logs/app.log | sort
```
3. コンポーネント別の ERROR 件数（2列目）
```bash
awk '/ERROR/ {comp[$2]++} END {for (k in comp) print k, comp[k]}' ~/linux-lab/logs/app.log
```

### 3. Advanced（15-20分）
1. 500系のエラーだけ抽出して保存（**元ログは変更しない**）
```bash
awk '$6 ~ /^5/ {print}' ~/linux-lab/logs/app.log > ~/linux-lab/logs/5xx.log
```
2. レイテンシ（7列目）上位3件
```bash
awk '{gsub("ms","",$7); print $7, $0}' ~/linux-lab/logs/app.log | sort -nr | head -n 3
```
3. 日次レポート生成（読み取り専用）
```bash
{
  echo "# log report $(date '+%F %T')"
  awk '/ERROR/ {e++} /WARN/ {w++} END {print "ERROR:", e+0, "WARN:", w+0}' ~/linux-lab/logs/app.log
  echo "## 5xx"
  awk '$6 ~ /^5/ {print}' ~/linux-lab/logs/app.log
} > ~/linux-lab/logs/report.txt
```

**完了条件:** `report.txt` に ERROR/WARN 件数と 5xx 行が出力されていること。

---

## 5) Command cheatsheet
```bash
# 末尾確認
tail -n 100 app.log

# 追従監視（ローテーション対応）
tail -F app.log

# 重要語句の抽出
grep -E "ERROR|WARN|FATAL" app.log

# 大きいログを安全閲覧
less app.log

# ERROR件数
awk '/ERROR/ {c++} END {print c+0}' app.log

# ステータスコード集計（例: 6列目）
awk '{a[$6]++} END {for(k in a) print k,a[k]}' app.log | sort
```

---

## 6) Common mistakes and safe practices

### よくあるミス
- `sudo` を常用してしまい、不要に高権限で操作する
- `grep "error"` だけで大文字 `ERROR` を見落とす（`-i` 未使用）
- パイプ先で意図せず上書き（`>`）して元データを失う
- 本番ログに対して編集系コマンド（`sed -i` など）を直接使う

### 安全プラクティス
- **原則読み取り専用**: まず `cat/less/grep/awk` で調査
- 出力先は別ファイルに保存し、元ログは不変に保つ
- 破壊的コマンドの前に確認:
  - `rm -rf` は対象を `pwd` と `ls` で再確認
  - `chmod/chown` は `-R` を使う前に単体で検証
  - `sudo` は必要最小限、コマンドを声に出して確認
- 可能なら `cp` でバックアップしてから加工

> ⚠️ 注意: `rm -rf`, `chmod -R`, `chown -R`, 無闇な `sudo` は事故の定番。ラボ環境でのみ練習し、本番はレビュー付きで実行。

---

## 7) One interview-style question
**質問:**  
本番で「API が遅い」というアラートが来ました。`app.log` しか手元にない状況で、最初の10分でどのコマンドをどう組み合わせて原因の仮説を立てますか？

**評価ポイント（セルフチェック）:**
- 時系列確認（直近の異常）
- エラー種別の切り分け（4xx/5xx/timeout）
- 遅延の偏り（特定エンドポイント/コンポーネント）
- 読み取り専用で調査しているか

---

## 8) Next-step resources
- `man tail`, `man grep`, `man awk`, `man less`
- The Linux Command Line（William Shotts）
- Brendan Gregg の observability / performance 関連資料
- 次回おすすめテーマ:
  1. `find` + `xargs` の安全運用（`-print0`, `-0`）
  2. `journalctl` で systemd ログ解析
  3. `ss` / `lsof` でポート・プロセス調査

---

**今日のひとこと:** 速く直せる人は、速く打つ人ではなく、まず安全に「正しく見る」人。