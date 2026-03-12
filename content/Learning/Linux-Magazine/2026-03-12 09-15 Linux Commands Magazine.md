---
tags: [linux, commands, learning, devops, daily]
---

# Daily Linux Commands Magazine — 2026-03-12
[[Home]]

## 1) Topic + Level

### Beginner（初級）: `grep` と `less` でログを読む
**トピック:** テキストログから必要な情報を安全に探す

### Middle（中級）: `journalctl` + `grep` + `tail -f` で障害の兆候を追う
**前提知識:** Beginnerの内容（`grep` 基本、`less` で閲覧、標準出力の理解）

### Advanced（上級）: `awk`/`sort`/`uniq` でログを集計し、原因候補を絞る
**前提知識:** Middleの内容（systemdログ確認、リアルタイム監視、パイプ処理）

---

## 2) Why it matters in real projects

- 本番障害の初動は「まずログを読む」が基本。
- 監視アラートが鳴ったとき、**5分以内に状況把握**できるかが復旧速度を左右する。
- `grep`/`journalctl`/`awk` の組み合わせは、クラウド・オンプレ問わず使える。
- 破壊的変更をせずに現状調査できるため、**安全な運用スキル**として重要。

---

## 3) Core command explanations

### Beginner
- `less /var/log/syslog`  
  ログをページ単位で読む。編集・削除しないので安全。
- `grep -i "error" /var/log/syslog`  
  `-i` は大文字小文字を無視して検索。
- `grep -n "failed" app.log`  
  `-n` で行番号表示。報告時に参照しやすい。

### Middle
- `journalctl -u nginx --since "1 hour ago"`  
  nginxサービスの直近1時間ログを表示。
- `journalctl -f -u nginx`  
  `tail -f` 相当の追跡。リアルタイム監視。
- `tail -f /var/log/nginx/error.log | grep --line-buffered -i "timeout"`  
  ストリーム中の特定語を即時検知。

### Advanced
- `awk '{print $9}' access.log | sort | uniq -c | sort -nr | head`  
  HTTPステータスコード（例）を頻度順に集計。
- `awk '/ERROR|FATAL/ {print $1, $2, $0}' app.log`  
  重要ログだけ抽出して時系列確認。
- `grep "POST /api" access.log | awk '{print $1}' | sort | uniq -c | sort -nr | head`  
  エンドポイント別にアクセス元IPの偏りを確認。

> 注意: ログ形式は環境で異なる。`awk` の列番号は最初に `head -n 3` で確認してから使う。

---

## 4) 30-60 minute hands-on mini lab

### 目的
「レスポンス遅延アラートが出た」という想定で、原因候補を3つ挙げる。

### 手順（45分想定）
1. **5分**: ログの場所確認
   - `ls -lh /var/log`
   - `journalctl --since "30 min ago" | head`

2. **10分**: エラーログ把握
   - `grep -iE "error|failed|timeout" /var/log/syslog | tail -n 50`
   - `journalctl -u nginx --since "30 min ago" | grep -iE "error|timeout"`

3. **15分**: リクエスト傾向の集計
   - `awk '{print $9}' /var/log/nginx/access.log | sort | uniq -c | sort -nr | head`
   - 4xx/5xx が急増していないか確認

4. **10分**: リアルタイム監視
   - `journalctl -f -u nginx`
   - 別ターミナルでテストアクセスし、ログ変化を観察

5. **5分**: 結果まとめ
   - 例: 「502増加」「特定IPの過剰アクセス」「timeoutの頻発」など

---

## 5) Command cheatsheet

- 閲覧: `less file.log`
- 末尾確認: `tail -n 100 file.log`
- 追跡: `tail -f file.log`
- 検索: `grep -i "keyword" file.log`
- 複数語: `grep -iE "error|failed|timeout" file.log`
- systemdログ: `journalctl -u <service> --since "1 hour ago"`
- 集計: `... | sort | uniq -c | sort -nr`

---

## 6) Common mistakes and safe practices

### よくあるミス
- `sudo` を何となく付ける（不要な権限昇格）
- 本番でいきなり `chmod -R` / `chown -R` を実行する
- ログ掃除で `rm -rf` を雑に使う
- パイプの前段が空でも「問題なし」と誤認する

### 安全運用の実践
- まずは**読み取り専用コマンド**（`less`, `grep`, `journalctl`）から始める
- 破壊的コマンドの前に `pwd` と `ls` で対象確認
- `rm -rf` は原則回避。必要時は対象を `echo` で展開確認してから実行
- `chmod/chown` は単体ファイルでテスト → 範囲拡大
- `sudo` は最小限。理由を説明できない `sudo` は使わない

> 警告: `rm -rf /` のような破壊的パターン、無差別 `chown -R`、不用意な `sudo` はシステム停止や権限事故につながる。

---

## 7) One interview-style question

**質問:**  
「本番で nginx の 502 が増えたとき、あなたが最初の10分で実行するコマンドと、確認観点を順番に説明してください。」

**評価ポイント（自己チェック）:**
- 読み取り中心で安全に調査しているか
- 時間範囲を切ってログ確認できているか
- 仮説（アプリ遅延/上流障害/過負荷）をログで検証しているか

---

## 8) Next-step resources

- `man grep`, `man journalctl`, `man awk`
- DigitalOcean Community: Linux log analysis tutorials
- Red Hat docs: systemd journal運用
- 次回学習候補:
  - `xargs` と安全な一括処理
  - `find` + `-mtime` でログローテーション補助
  - `ss` / `lsof` で接続とプロセスの可視化
