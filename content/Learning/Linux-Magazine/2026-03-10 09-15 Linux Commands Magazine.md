---
tags: [linux, commands, learning, devops, daily]
---

# Daily Linux Commands Magazine — 2026-03-10
[[Home]]

## 1) Topic + Level

### Beginner（初級）
**トピック:** `ls` / `find` / `grep` で「必要なファイルを安全に見つける」

### Middle（中級）
**トピック:** `grep` / `awk` / `sort` / `uniq` で「ログを集計して異常傾向を読む」

**前提知識（Prerequisites）:**
- 初級の内容（パス指定、ワイルドカード、基本的な `grep`）
- 標準入力/標準出力、パイプ `|` の基本

### Advanced（上級）
**トピック:** `journalctl` / `xargs` / `tee` / `watch` で「運用向けの安全な調査パイプラインを作る」

**前提知識（Prerequisites）:**
- 中級の内容（テキスト処理パイプライン）
- systemd ジャーナルの基本
- `sudo` の影響範囲を理解していること

---

## 2) Why it matters in real projects

実プロジェクトでは、障害対応や性能劣化の初動で「素早く・安全に・再現可能な調査」を行えるかが重要です。

- **開発（Dev）:** テスト失敗ログの原因箇所を即座に抽出
- **運用（Ops）:** 本番障害時にエラーパターンを定量化
- **SRE/DevOps:** 手作業調査をコマンド化し、手順の再利用性を高める

攻撃的な使い方ではなく、**防御的・保守的なシステム管理**として、観測と分析の精度を上げる練習をします。

---

## 3) Core command explanations

### 初級コア
- `ls -lah` : ファイルを人間が読みやすい単位で表示（隠しファイル含む）
- `find . -type f -name "*.log"` : カレント配下の `.log` を列挙
- `grep -n "ERROR" app.log` : 行番号付きで一致行を表示
- `grep -R --include="*.log" "timeout" .` : 再帰検索（対象拡張子を限定）

### 中級コア
- `awk '{print $1}' access.log` : フィールド抽出
- `sort | uniq -c | sort -nr` : 件数集計して多い順に並べる
- `grep -E "(ERROR|WARN)"` : 拡張正規表現で複数条件検索
- `cut -d' ' -f1,9` : 区切り文字ベースで列抽出

### 上級コア
- `journalctl -u nginx --since "1 hour ago"` : サービス単位の直近ログ
- `xargs -r` : 入力が空なら実行しない（安全性アップ）
- `tee report.txt` : 画面表示しながらファイル保存
- `watch -n 5 'command'` : 5秒ごとに観測（継続監視）

> ⚠️ **安全メモ:** `sudo` を付ける前に「読み取りだけか」「書き込みが発生しないか」を必ず確認。

---

## 4) 30-60 minute hands-on mini lab

**ラボ目標:** 疑似ログからエラー傾向を安全に調査し、レポートを作る。

### Step 0（5分）準備
```bash
mkdir -p ~/linux-lab/{input,output}
cd ~/linux-lab
cat > input/app.log <<'EOF'
2026-03-10T08:55:01Z INFO user=alice action=login status=200
2026-03-10T08:56:10Z WARN user=bob action=upload status=429
2026-03-10T08:57:45Z ERROR user=alice action=payment status=500
2026-03-10T08:58:20Z INFO user=carol action=view status=200
2026-03-10T08:59:02Z ERROR user=dave action=payment status=500
2026-03-10T09:00:33Z WARN user=alice action=api status=429
EOF
```

### Beginner Arc（10-15分）
1. ログ件数確認
```bash
wc -l input/app.log
```
2. ERROR行の抽出
```bash
grep -n "ERROR" input/app.log
```
3. WARN/ERROR をまとめて確認
```bash
grep -En "WARN|ERROR" input/app.log
```

### Middle Arc（15-20分）
1. ステータスコード別件数
```bash
grep -Eo 'status=[0-9]+' input/app.log | cut -d= -f2 | sort | uniq -c | sort -nr
```
2. ユーザー別エラー件数（簡易）
```bash
grep "ERROR" input/app.log | grep -Eo 'user=[a-z]+' | cut -d= -f2 | sort | uniq -c | sort -nr
```
3. 結果を保存
```bash
{
  echo "# Error Summary"
  date
  echo
  echo "## status counts"
  grep -Eo 'status=[0-9]+' input/app.log | cut -d= -f2 | sort | uniq -c | sort -nr
} | tee output/report.txt
```

### Advanced Arc（15-20分）
1. 「対象が空でも暴発しない」 `xargs -r` を体験
```bash
find input -name "*.log" -print0 | xargs -0 -r grep -Hn "ERROR"
```
2. 調査コマンドを関数化（再利用）
```bash
analyze_log() {
  local f="$1"
  echo "Analyzing: $f"
  grep -En "WARN|ERROR" "$f" | tee "output/$(basename "$f").issues.txt"
}
analyze_log input/app.log
```
3. 監視風に確認（Ctrl+Cで終了）
```bash
watch -n 5 'tail -n 5 ~/linux-lab/input/app.log'
```

---

## 5) Command cheatsheet

```bash
# ファイル探索
find . -type f -name "*.log"

# キーワード検索（行番号）
grep -n "ERROR" file.log

# 複数条件検索
grep -En "WARN|ERROR" file.log

# 集計パターン
... | sort | uniq -c | sort -nr

# serviceログ確認（systemd）
journalctl -u <service> --since "30 min ago"

# 安全な xargs（入力なし時は実行しない）
... | xargs -r <command>

# 画面表示 + 保存
command | tee output.txt
```

---

## 6) Common mistakes and safe practices

### よくあるミス
- `grep -R` をルート配下で実行して重くする
- 正規表現の引用ミスで意図しない一致を拾う
- `sudo` を無意識に付ける
- `chmod -R` / `chown -R` を広範囲に実行して権限破壊

### 安全プラクティス
- 対象範囲を絞る（`--include`, ディレクトリ限定）
- まずは読み取り専用コマンドから始める
- 破壊的操作の前に `echo` / `ls` / ドライランで確認
- 出力を `tee` で記録し、作業を再現可能にする

> ⚠️ **危険コマンド警告**
> - `rm -rf <path>`: パス誤りで致命的削除。実行前に `pwd` と `ls <path>` で確認。
> - `chmod/chown -R`: 想定外の範囲へ適用されるとサービス停止原因に。
> - `sudo`: 一時的に強力権限を得るため、コマンドの意味を理解してから使用。

---

## 7) One interview-style question

**質問:**
本番サーバーで「APIが遅い」という報告が来ました。`/var/log/app.log` から過去1時間の `ERROR` と `WARN` の件数を素早く集計し、再現可能な形でチーム共有するには、どのコマンドパイプラインを使いますか？また、安全面での注意点を2つ挙げてください。

---

## 8) Next-step resources

- `man grep`, `man find`, `man awk`, `man journalctl`
- The Linux Command Line (William Shotts)
- ExplainShell（コマンド分解の学習に便利）
- systemd公式ドキュメント（journalctl運用）

**次回予告:**
「権限管理の実践（`chmod`/`chown`/`umask`）を安全に学ぶ」— 誤設定を防ぐ運用視点付き。
