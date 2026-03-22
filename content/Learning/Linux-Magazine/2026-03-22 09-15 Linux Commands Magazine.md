---
tags:
  - linux
  - commands
  - learning
  - devops
  - daily
---

# Linux Commands Magazine — 2026-03-22 (09:15)
[[Home]]

## 学習アーク 1

## 1) Topic + Level
**テーマ:** ログ調査とテキスト処理の基本〜実践（`tail` / `grep` / `awk` / `sed` / `journalctl`）  
**レベル:** 
- **Beginner:** ログを読む・絞る（`tail`, `grep`）
- **Middle:** 複数条件で集計・整形（`awk`, `sed`, パイプライン）
- **Advanced:** systemd ジャーナル分析と再現可能な調査コマンド化（`journalctl`, `xargs`, `tee`）

**前提条件:**
- **Middle の前提:** 基本的なファイル操作（`ls`, `cat`, `less`）とパイプ（`|`）を理解していること
- **Advanced の前提:** Beginner/Middle の内容、標準出力・標準エラー、`sudo` の最小利用原則を理解していること

---

## 2) Why it matters in real projects
実プロジェクトでは、障害時に「まずログを見る」が最短ルートです。  
- API遅延、500エラー、バッチ失敗、ディスク逼迫などはログに兆候が出ます。
- 監視ツールがあっても、最終的にはコマンドラインで一次切り分けする場面が多いです。
- テキスト処理コマンドを使えると、**原因の特定速度**と**報告の質**が上がります。

---

## 3) Core command explanations

### Beginner
- `tail -n 50 app.log`
  - 末尾50行を表示。直近エラー確認に使う。
- `tail -f app.log`
  - 追記をリアルタイム表示。デプロイ直後の監視に便利。
- `grep "ERROR" app.log`
  - ERROR行だけ抽出。
- `grep -i "timeout" app.log`
  - 大文字小文字を無視して検索。

### Middle
- `grep -E "ERROR|WARN" app.log`
  - OR条件で複数パターン抽出。
- `awk '{print $1, $2, $5}' app.log`
  - 特定列を抜き出して読む。
- `awk '/ERROR/ {count++} END {print count}' app.log`
  - 条件一致の件数を集計。
- `sed -n '1,120p' app.log`
  - 1〜120行のみ表示（範囲指定）。

### Advanced
- `journalctl -u nginx --since "1 hour ago"`
  - nginxサービスの1時間分ログを見る。
- `journalctl -p err -S today`
  - 今日のエラーレベルログのみ確認。
- `journalctl -u myapp -S "2026-03-22 08:00" -U "2026-03-22 09:00" | tee investigation.log`
  - 期間指定で調査ログを保存しつつ表示。
- `grep "ERROR" app.log | awk '{print $NF}' | sort | uniq -c | sort -nr | head`
  - 頻出エラー（末尾フィールド）をランキング化。

---

## 4) 30-60 minute hands-on mini lab
**目的:** 「Webアプリで断続的な 500 エラーが出る」想定で、ログから原因候補を絞る。

### 準備（5分）
```bash
mkdir -p ~/linux-mag-lab && cd ~/linux-mag-lab
cat > app.log <<'EOF'
2026-03-22T08:40:01 INFO request_id=1001 status=200 path=/health latency=12ms
2026-03-22T08:41:12 WARN request_id=1002 status=200 path=/api/users latency=890ms
2026-03-22T08:42:03 ERROR request_id=1003 status=500 path=/api/orders error=DBTimeout
2026-03-22T08:42:40 INFO request_id=1004 status=200 path=/api/users latency=52ms
2026-03-22T08:43:15 ERROR request_id=1005 status=500 path=/api/orders error=DBTimeout
2026-03-22T08:43:55 ERROR request_id=1006 status=500 path=/api/payments error=RedisConnRefused
2026-03-22T08:44:20 WARN request_id=1007 status=429 path=/api/orders latency=1200ms
EOF
```

### Beginner タスク（10-15分）
1. `tail -n 5 app.log` で直近事象を確認  
2. `grep "ERROR" app.log` でエラー行のみ抽出  
3. `grep "status=500" app.log` で500系を抽出

### Middle タスク（10-20分）
1. `grep -E "ERROR|WARN" app.log` で警告含めて把握  
2. `awk '/status=500/ {print $4, $5, $6}' app.log` で path/error を確認  
3. `grep "status=500" app.log | awk '{print $NF}' | sort | uniq -c` で原因候補集計

### Advanced タスク（10-20分）
1. 調査結果を保存:  
   `grep "status=500" app.log | tee errors-500.log`
2. 再利用可能なワンライナーを作る:  
   `grep "status=500" app.log | awk '{print $6}' | sort | uniq -c | sort -nr`
3. （systemd環境なら）同等調査を `journalctl` で実施し、期間指定で確認

### 仕上げ（5分）
- 「最頻出エラー」「影響エンドポイント」「次アクション（DB接続監視確認など）」を3行でまとめる

---

## 5) Command cheatsheet
```bash
# 末尾を見る
 tail -n 50 app.log
 tail -f app.log

# 検索
 grep "ERROR" app.log
 grep -i "timeout" app.log
 grep -E "ERROR|WARN" app.log

# 集計・整形
 awk '/ERROR/ {count++} END {print count}' app.log
 grep "status=500" app.log | awk '{print $NF}' | sort | uniq -c | sort -nr
 sed -n '1,120p' app.log

# systemdログ
 journalctl -u nginx --since "1 hour ago"
 journalctl -p err -S today
```

---

## 6) Common mistakes and safe practices

### よくあるミス
- `tail -f` を開きっぱなしで必要情報を見失う
- `grep` 条件が緩すぎてノイズ過多になる
- root権限が不要なのに `sudo` を常用する
- ログ調査中に不用意に削除・権限変更する

### 安全運用（重要）
- **破壊的操作前は必ず確認**（対象・パス・権限）
- `rm -rf` は原則最後の手段。実行前に `pwd` と `ls` で対象再確認
- `chmod -R` / `chown -R` は広範囲事故の原因。対象を限定し、まずテストディレクトリで検証
- `sudo` は必要なコマンドだけに付与（最小権限）
- 調査ログは `tee` で保存し、手順を再現可能にする

> Defensive 視点: まず「観測（読む・絞る・記録）」を優先し、設定変更や削除は影響範囲を明確化してから行う。

---

## 7) One interview-style question
本番で API の 500 エラーが増加したとき、`tail` / `grep` / `awk` / `journalctl` を使って**5分で一次切り分け**する手順を説明してください。  
（見る順番、切り分け観点、記録方法、次に誰へ何をエスカレーションするかまで）

---

## 8) Next-step resources
- `man tail`, `man grep`, `man awk`, `man sed`, `man journalctl`
- The Linux Command Line (William Shotts)
- systemd 公式ドキュメント（journalctl セクション）
- 次回おすすめテーマ:  
  1. **Beginner:** `find` と `locate` の安全な使い分け  
  2. **Middle:** `find` + `xargs` で一括処理（`-print0` を含む安全設計）  
  3. **Advanced:** 権限監査（`stat`, `getfacl`, `namei`）
