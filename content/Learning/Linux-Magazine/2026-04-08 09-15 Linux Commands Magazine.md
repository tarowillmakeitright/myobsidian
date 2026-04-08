---
tags: [linux, commands, learning, devops, daily]
---

# Daily Linux Commands Magazine — 2026-04-08 (09:15)
[[Home]]

## 学習アークA: ログ調査と安全なテキスト処理

### 1) Topic + Level
- **Beginner:** `cat` / `less` / `head` / `tail` でログを読む
- **Middle:** `grep` / `wc` / `sort` / `uniq` で傾向を集計
  - **前提知識:** ファイル閲覧コマンド、標準出力/標準エラーの基本
- **Advanced:** `journalctl` + パイプで障害切り分けを高速化
  - **前提知識:** `grep` とパイプ、systemd サービス概念

### 2) Why it matters in real projects
本番障害の初動は「まずログを見る」です。Docker・VM・物理サーバーどれでも、ログ調査の速さが復旧時間を左右します。特に DevOps では、原因仮説を短時間で絞る力が重要です。

### 3) Core command explanations
- `less /var/log/syslog`（環境により `/var/log/messages`）
  - 長いログを安全にページングして閲覧。`q` で終了。
- `tail -n 100 app.log`
  - 直近100行だけ確認。ノイズを減らせる。
- `tail -f app.log`
  - 追記をリアルタイム監視（確認後は `Ctrl+C` で停止）。
- `grep -i "error" app.log`
  - 大文字小文字を無視して error を抽出。
- `grep -E "timeout|refused|denied" app.log`
  - 複数キーワードを1回で検索。
- `awk '{print $1}' access.log | sort | uniq -c | sort -nr | head`
  - 先頭カラム（例: IP）を件数順に上位表示。
- `journalctl -u nginx --since "1 hour ago"`
  - nginx サービスの直近1時間ログを抽出。

### 4) 30-60 minute hands-on mini lab
**目標:** 「5xx が増えた」想定で原因候補を3つ挙げる

1. テスト用ログ作成
   ```bash
   mkdir -p ~/linux-lab && cd ~/linux-lab
   cat > app.log <<'EOF'
   2026-04-08T08:10:01Z INFO startup complete
   2026-04-08T08:11:12Z WARN db latency high
   2026-04-08T08:12:20Z ERROR timeout while calling payment-api
   2026-04-08T08:12:45Z ERROR connection refused to redis
   2026-04-08T08:13:01Z INFO retry success
   2026-04-08T08:14:33Z ERROR timeout while calling payment-api
   EOF
   ```
2. ERROR 行だけ抽出
   ```bash
   grep "ERROR" app.log
   ```
3. エラー種別を集計
   ```bash
   grep "ERROR" app.log | awk -F'ERROR ' '{print $2}' | sort | uniq -c | sort -nr
   ```
4. 時系列で直近を確認
   ```bash
   tail -n 3 app.log
   ```
5. 振り返り
   - 最多エラーは何か
   - 再現性があるか（複数回発生しているか）
   - 依存先（DB/Redis/API）のどこが怪しいか

### 5) Command cheatsheet
- 閲覧: `less file`, `head -n 20 file`, `tail -n 50 file`
- 監視: `tail -f file`
- 検索: `grep -i "keyword" file`, `grep -E "a|b|c" file`
- 集計: `sort | uniq -c | sort -nr`
- systemdログ: `journalctl -u <service> --since "30 min ago"`

### 6) Common mistakes and safe practices
- **危険:** `rm -rf` をログディレクトリで安易に実行しない（復旧困難）。
- **危険:** `sudo` 付きで編集/削除する前に `pwd` と対象パスを再確認。
- `tail -f` を放置しない（端末占有・見落としの原因）。
- `chmod -R 777` は原則禁止（情報漏えい・改ざんリスク）。
- `chown -R` は対象を限定して実行（誤るとサービス停止の原因）。
- 本番では「読むコマンド」を優先し、破壊的変更は手順レビュー後に実施。

### 7) One interview-style question
「`grep "ERROR" app.log | sort | uniq -c | sort -nr` が何をしているか、各パイプの役割を説明してください。さらに、ログが巨大（数GB）な場合の改善案は？」

### 8) Next-step resources
- `man grep`, `man journalctl`, `man awk`
- systemd公式ドキュメント（journalctl）
- The Linux Command Line（William Shotts）
- SRE本の障害対応章（ログ起点のトラブルシュート）

---

## 次回予告（次アーク）
- Beginner: `find` で安全にファイル探索
- Middle: `xargs` と組み合わせた一括処理（前提: `find`）
- Advanced: `tar`/`rsync` でバックアップ運用（前提: 権限とパス設計）
