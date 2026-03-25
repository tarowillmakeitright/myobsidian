---
tags: [linux, commands, learning, devops, daily]
---

# Daily Linux Commands Magazine — 2026-03-25
[[Home]]

## 1) Topic + Level
**今号テーマ:** ログ調査とシステム健全性チェックの実践（段階学習アーク）

- **Beginner（初級）:** `ls` / `cat` / `less` / `tail` でログを安全に読む
- **Middle（中級）:** `grep` / `find` / `journalctl` で障害切り分けを高速化
  - **前提知識:** ファイルパスの基本、標準出力/標準エラーの概念、初級コマンドの利用経験
- **Advanced（上級）:** `awk` / `xargs` / `ss` / `du` でボトルネック分析と運用自動化
  - **前提知識:** 正規表現、パイプ処理、プロセス・権限の基礎、`sudo`の安全運用

---

## 2) Why it matters in real projects
本番運用では「何が起きたかを短時間で把握する力」が重要です。  
障害時にログ確認が遅れると、MTTR（復旧時間）が長引き、ユーザー影響・売上損失・信頼低下につながります。

このテーマを身につけると:
- リリース後の不具合調査が速くなる
- インフラ監視アラートへの一次対応が安定する
- 「危険な操作を避けながら」調査できるようになる

---

## 3) Core command explanations

### Beginner（初級）
- `ls -lah`
  - ディレクトリ内容を人間に読みやすい単位で表示
- `cat file.log`
  - 小さいファイルを一気に表示（大きいログには非推奨）
- `less file.log`
  - ページャで安全に閲覧（`/keyword`検索、`q`終了）
- `tail -n 100 file.log`
  - 末尾100行を確認
- `tail -f file.log`
  - ログ追跡（リアルタイム）

### Middle（中級）
- `grep -n "ERROR" app.log`
  - ERROR行を行番号付きで抽出
- `grep -E "ERROR|WARN" app.log`
  - 複数パターン検索
- `find /var/log -type f -name "*.log"`
  - 対象ログの探索
- `journalctl -u nginx --since "1 hour ago"`
  - systemdサービスの直近ログ確認
- `journalctl -p err -S today`
  - 当日のエラーレベルログに絞る

### Advanced（上級）
- `awk '{print $1, $2, $NF}' access.log | head`
  - 必要列のみ抽出して俯瞰
- `grep " 500 " access.log | awk '{print $1}' | sort | uniq -c | sort -nr | head`
  - 500エラー発生元IPの上位集計
- `ss -tulpn`
  - 待受ポート・プロセス対応確認
- `du -xh /var | sort -h | tail -n 20`
  - 容量圧迫箇所の特定
- `find /tmp -type f -mtime +7 -print`
  - 7日超の古い一時ファイルを「まず表示だけ」

---

## 4) 30-60 minute hands-on mini lab
**ラボ名:** 「疑似障害ログから原因を特定せよ」

### 所要時間
40分（初級15分 + 中級15分 + 上級10分）

### 手順
1. 作業ディレクトリ作成
```bash
mkdir -p ~/lab/linux-mag-2026-03-25 && cd ~/lab/linux-mag-2026-03-25
```

2. 疑似ログ生成
```bash
cat > app.log <<'EOF'
2026-03-25T09:00:01 INFO  api request_id=1 status=200 path=/health
2026-03-25T09:01:11 WARN  db  request_id=2 retry=1
2026-03-25T09:02:20 ERROR api request_id=3 status=500 path=/checkout
2026-03-25T09:02:21 ERROR api request_id=4 status=500 path=/checkout
2026-03-25T09:03:00 INFO  api request_id=5 status=200 path=/home
EOF
```

3. 初級タスク
- `less app.log` で全体確認
- `tail -n 3 app.log` で直近確認

4. 中級タスク
- `grep -n "ERROR" app.log`
- `grep -E "WARN|ERROR" app.log`

5. 上級タスク
- ステータス500件数を確認
```bash
grep "status=500" app.log | wc -l
```
- エラー時刻とpathを抽出
```bash
grep "ERROR" app.log | awk '{print $1, $NF}'
```

6. ふりかえり
- 何分で「異常検知→対象絞り込み→原因候補提示」できたか記録

### 合格ライン
- ERROR行を30秒以内に抽出できる
- 500エラーの件数を即答できる
- 危険コマンドを実行せず調査完了できる

---

## 5) Command cheatsheet
```bash
# 閲覧
ls -lah
less app.log
tail -n 100 app.log
tail -f app.log

# 抽出
grep -n "ERROR" app.log
grep -E "ERROR|WARN" app.log

# 探索
find /var/log -type f -name "*.log"
journalctl -u nginx --since "1 hour ago"

# 集計
grep "status=500" app.log | wc -l
grep "ERROR" app.log | awk '{print $1, $NF}'

# システム確認
ss -tulpn
du -xh /var | sort -h | tail -n 20
```

---

## 6) Common mistakes and safe practices

### よくあるミス
- `cat`で巨大ログを開いて端末が固まる
- `grep`対象を広げすぎてノイズだらけになる
- `sudo`を常用して、不要に権限を上げる
- `chmod -R` / `chown -R` を誤ったパスで実行

### 安全運用（重要）
- **破壊的コマンド前は必ず確認:**
  - `rm -rf` は極めて危険。実行前に `pwd` / `ls` / 対象パス再確認
  - 可能なら `rm`ではなくバックアップ・移動（例: `mv target ~/backup/`）を優先
- **権限変更は最小範囲で:**
  - `chmod/chown` は単体ファイルから試し、`-R`は最後の手段
- **sudoは必要な1コマンドだけ:**
  - `sudo -i`で長時間作業を避ける
- **まず読む、消さない:**
  - 調査フェーズでは `-print` / 一覧表示を先に実施して影響確認

---

## 7) One interview-style question
本番環境で「アプリが遅い」という報告を受けました。  
`top`以外に、どのコマンドをどういう順序で使って一次切り分けしますか？  
（CPU・メモリ・ディスク・ネットワーク・ログの観点を含めて説明してください）

---

## 8) Next-step resources
- manページ（最優先）
  - `man grep`, `man journalctl`, `man awk`, `man ss`
- The Linux Command Line（基礎固め）
- Linux Foundationの無料教材（運用寄り）
- 次号予告:
  - 「権限管理アーク: `id` / `umask` / `chmod` / `setfacl` の実務」
  - ※破壊的変更を避ける検証手順つき
