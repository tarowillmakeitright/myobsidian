---
tags: [linux, commands, learning, devops, daily]
---
# 2026-03-05 Linux Commands Magazine
#linux #commands #learning #devops #daily
[[Home]]

## 1) Topic + Level
**テーマ:** ログ調査と安全なテキスト処理（運用トラブルシュート基礎）

### Beginner（初級）
**レベル:** Beginner  
**到達目標:** `ls`, `cat`, `less`, `tail`, `grep` でログの場所確認とエラー文字列抽出ができる

### Middle（中級）
**レベル:** Middle  
**前提知識:** Beginner の内容（標準出力/標準エラー、パイプ `|`、基本的な正規表現）  
**到達目標:** `awk`, `sort`, `uniq`, `cut`, `wc` で「頻出エラーの傾向」を集計できる

### Advanced（上級）
**レベル:** Advanced  
**前提知識:** Middle の内容（フィールド処理、集計、シェル変数、リダイレクト）  
**到達目標:** 安全に再利用できる調査ワンライナー/簡易スクリプトを作り、誤操作を防止できる

---

## 2) Why it matters in real projects
- 障害対応では「まずログ確認」が最短ルート。調査速度が MTTR（復旧時間）を左右します。  
- 開発/運用では、再発防止のために「感覚」ではなく「件数と傾向」で判断する必要があります。  
- 安全なコマンド運用（破壊的操作の回避、`sudo` の最小化）は、サービス停止やデータ損失の予防に直結します。

---

## 3) Core command explanations
### Beginner Core
- `less /var/log/syslog` : 大きいログを安全に閲覧（編集せず読める）
- `tail -n 50 app.log` : 末尾 50 行だけ確認
- `tail -f app.log` : 追記をリアルタイム監視（Ctrl+C で終了）
- `grep -i "error" app.log` : 大文字小文字を無視して検索
- `grep -n "timeout" app.log` : 行番号つき検索

### Middle Core
- `awk '{print $5}' app.log` : 5列目だけ取り出し
- `cut -d' ' -f1-3 app.log` : 区切り文字を指定して列抽出
- `sort | uniq -c | sort -nr` : 件数集計→降順ソート
- `wc -l app.log` : 行数カウント（件数の目安）

例: 頻出エラーを上位表示
```bash
grep -i "error" app.log | awk -F'error: ' '{print $2}' | sort | uniq -c | sort -nr | head
```

### Advanced Core
- `set -euo pipefail` : スクリプトの安全性向上（未定義変数・途中失敗を検知）
- `xargs -r` : 入力が空なら実行しない（事故防止）
- `grep -R --line-number --binary-files=without-match "ERROR" ./logs` : ディレクトリ横断検索
- `tee report.txt` : 画面表示しながらファイル保存

安全寄りテンプレート:
```bash
#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="${1:-app.log}"
[[ -f "$LOG_FILE" ]] || { echo "ログが見つかりません: $LOG_FILE"; exit 1; }

echo "[INFO] analyzing: $LOG_FILE"
grep -i "error" "$LOG_FILE" \
  | awk -F'error: ' 'NF>1{print $2}' \
  | sort | uniq -c | sort -nr | head \
  | tee error_top10.txt
```

---

## 4) 30-60 minute hands-on mini lab
**所要時間:** 45 分（Beginner 15分 → Middle 15分 → Advanced 15分）

### Step A (Beginner)
1. 練習用ログを作成
```bash
mkdir -p ~/linux-mag-lab && cd ~/linux-mag-lab
cat > app.log <<'EOF'
2026-03-05T09:00:01Z INFO start service
2026-03-05T09:01:10Z ERROR error: db timeout
2026-03-05T09:01:20Z WARN retry
2026-03-05T09:02:10Z ERROR error: auth failed
2026-03-05T09:03:11Z ERROR error: db timeout
2026-03-05T09:03:50Z INFO health ok
EOF
```
2. `less app.log` で閲覧
3. `grep -in "error" app.log` でエラー行抽出

### Step B (Middle)
1. エラー理由を集計
```bash
grep -i "error" app.log | awk -F'error: ' '{print $2}' | sort | uniq -c | sort -nr
```
2. 件数を確認
```bash
grep -ic "error" app.log
```
3. 結果を `report.txt` に保存
```bash
grep -i "error" app.log | awk -F'error: ' '{print $2}' | sort | uniq -c | sort -nr | tee report.txt
```

### Step C (Advanced)
1. `analyze.sh` を作成して引数でログを渡せるようにする
2. 存在チェック (`[[ -f ... ]]`) を入れる
3. `set -euo pipefail` を有効化
4. 実行して `error_top10.txt` を生成

ゴール: **手作業1回**→**再利用可能な安全スクリプト1本**に昇華する。

---

## 5) Command cheatsheet
```bash
# 閲覧
less file.log
tail -n 100 file.log
tail -f file.log

# 検索
grep -i "error" file.log
grep -n "timeout" file.log
grep -R "ERROR" ./logs

# 集計
grep -i "error" file.log | awk -F'error: ' '{print $2}' | sort | uniq -c | sort -nr
wc -l file.log

# 安全化
set -euo pipefail
xargs -r
tee report.txt
```

---

## 6) Common mistakes and safe practices
### よくあるミス
- `sudo` を常用してしまい、不要な高権限操作をする
- `>` で既存ファイルを上書きしてしまう
- ログ解析中に対象ファイルを誤って編集/削除する
- 区切り文字の想定違いで `awk`/`cut` が誤集計する

### 安全プラクティス
- **原則:** まず読み取り系コマンド（`less`, `grep`, `cat`）から始める
- 重要ファイル編集前はバックアップ: `cp config.yaml config.yaml.bak`
- 上書き回避: `set -o noclobber`（必要時のみ解除）
- `sudo` は必要最小限、コマンド単位で使う
- 実行前に対象確認: `pwd`, `ls`, `echo "$VAR"`

### 危険コマンド警告（必読）
- `rm -rf` : **取り消し不可**。特に `sudo rm -rf /` 系は致命的。`--preserve-root` でも過信しない
- `chmod -R` / `chown -R` : 範囲指定ミスでシステム全体を壊す可能性
- `sudo` + ワイルドカード (`*`) : 想定外の大量操作が起きやすい

> 破壊的操作は「対象確認 → dry-run相当の確認 → 実行」の3段階で。

---

## 7) One interview-style question
**質問:**  
本番障害で「レスポンス遅延」が発生しています。`app.log` から timeout 系エラーの件数推移を素早く把握し、再発防止のためにどんな追加ログを仕込むべきか、使うコマンドと理由を説明してください。

---

## 8) Next-step resources
- `man grep`, `man awk`, `man sed`, `man bash`
- The Linux Command Line (William Shotts)
- Google SRE Book（監視・運用の考え方）
- 正規表現学習: regex101（検証用途）
- 次回学習案: `journalctl` と `systemctl` で systemd ログ運用

---

### 明日の予告（Learning Arc 継続）
- Beginner: `find` で安全にファイル探索
- Middle: `find` + `xargs` で一括点検（非破壊）
- Advanced: `find` + `-exec` の安全設計と監査ログ化
