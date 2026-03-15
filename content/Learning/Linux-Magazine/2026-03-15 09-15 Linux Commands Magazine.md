---
tags: [linux, commands, learning, devops, daily]
---

# Daily Linux Commands Magazine — 2026-03-15 09:15
[[Home]]

## 1) Topic + Level

### 初級（Beginner）
**テーマ:** `find` と `grep` で「ログから必要情報を素早く見つける」

### 中級（Middle）
**テーマ:** `find` + `xargs` + `tar` で「安全なバックアップ対象の収集と圧縮」
**前提条件:**
- 初級の `find` / `grep` の基本がわかる
- 標準入力・標準出力の概念を理解している

### 上級（Advanced）
**テーマ:** `journalctl` + `awk` + `sort` で「障害調査向けログ要約パイプラインを作る」
**前提条件:**
- 中級のパイプ処理を理解している
- テキスト処理（`awk`, `sort`, `uniq`）の初歩に慣れている

---

## 2) Why it matters in real projects

- **初級:** 本番・検証環境のログ確認で「必要な行だけ」を即抽出できると、調査時間を大幅短縮できる。
- **中級:** デプロイ前後の設定バックアップを安全に自動化できると、事故時の復旧速度が上がる。
- **上級:** 大量ログを要約して「異常の傾向」を可視化できると、原因切り分けが早くなる。

実務では「全部読む」より「必要箇所を絞る」スキルが重要。今回の3段階はその基礎→応用→運用の流れ。

---

## 3) Core command explanations

### 初級コマンド

#### `find`
- 目的: ファイルを条件で検索
- 例:
```bash
find /var/log -type f -name "*.log"
```
- 意味:
  - `/var/log`: 検索開始ディレクトリ
  - `-type f`: ファイルのみ
  - `-name "*.log"`: .log に一致

#### `grep`
- 目的: 文字列/パターンを含む行を抽出
- 例:
```bash
grep -i "error" /var/log/syslog
```
- 意味:
  - `-i`: 大文字小文字無視

#### 組み合わせ
```bash
find /var/log -type f -name "*.log" -print0 | xargs -0 grep -Hi "timeout"
```
- `-print0` + `xargs -0` は、**空白を含むファイル名でも安全**に扱える。

---

### 中級コマンド

#### `xargs`
- 目的: 標準入力を引数としてコマンドに渡す
- 安全版例:
```bash
find ./config -type f -name "*.conf" -print0 | xargs -0 -I{} cp -v "{}" ./backup/
```
- `-I{}` で明示的にプレースホルダを使うと可読性が上がる。

#### `tar`
- 目的: まとめてアーカイブ
- 例:
```bash
tar -czf backup-$(date +%F).tar.gz ./backup
```
- 意味:
  - `-c`: 作成
  - `-z`: gzip圧縮
  - `-f`: ファイル名指定

---

### 上級コマンド

#### `journalctl`
- 目的: systemdジャーナル参照
- 例:
```bash
journalctl -u nginx --since "today" --no-pager
```

#### `awk` + `sort` + `uniq`
- 目的: ログ行の特定フィールドを集計
- 例:
```bash
journalctl -u nginx --since "24 hours ago" --no-pager \
  | grep -i "error" \
  | awk '{print $5}' \
  | sort \
  | uniq -c \
  | sort -nr \
  | head
```
- エラー頻出要素のランキングを作る基本形。

> 注: ログ形式により `awk '{print $5}'` は調整が必要。

---

## 4) 30-60 minute hands-on mini lab

### ゴール
「疑似ログ生成 → 検索 → バックアップ → 要約」を一連で体験する。

### 所要時間
45分目安

### 手順

1. 作業用ディレクトリ作成（5分）
```bash
mkdir -p ~/linux-mag-lab/{logs,config,backup}
cd ~/linux-mag-lab
```

2. 疑似ログ作成（10分）
```bash
cat > logs/app.log <<'EOF'
2026-03-15 09:00:01 INFO start api
2026-03-15 09:03:10 ERROR db timeout
2026-03-15 09:03:30 WARN retry db
2026-03-15 09:05:44 ERROR auth failed
2026-03-15 09:07:55 ERROR db timeout
EOF
```

3. 初級演習: エラー抽出（10分）
```bash
grep -n -i "error" logs/app.log
```
```bash
find ./logs -type f -name "*.log" -print0 | xargs -0 grep -Hi "timeout"
```

4. 中級演習: 設定ファイルの安全バックアップ（10分）
```bash
echo "PORT=8080" > config/app.conf
echo "DB_HOST=localhost" > config/db.conf
find ./config -type f -name "*.conf" -print0 | xargs -0 -I{} cp -v "{}" ./backup/
tar -czf backup-$(date +%F).tar.gz ./backup
```

5. 上級演習: エラー語の集計（10分）
```bash
grep -i "error" logs/app.log | awk '{print $4,$5}' | sort | uniq -c | sort -nr
```

### 完了条件
- `grep`でERROR行を抽出できる
- `backup-YYYY-MM-DD.tar.gz` が作成される
- エラー種別の件数が表示される

---

## 5) Command cheatsheet

```bash
# 検索
find <path> -type f -name "*.log"

# 文字列抽出
grep -i "error" file.log
grep -Rin "timeout" ./logs

# 安全なfind→xargs
find . -type f -print0 | xargs -0 <command>

# バックアップ
tar -czf backup-$(date +%F).tar.gz <dir>

# ジャーナル
journalctl -u <service> --since "today" --no-pager

# 簡易集計
... | awk '{print $N}' | sort | uniq -c | sort -nr
```

---

## 6) Common mistakes and safe practices

### よくあるミス
1. **`xargs` を `-0` なしで使う**
   - 空白入りファイル名で誤動作しやすい。
2. **`grep -R` の対象を広げすぎる**
   - `/` 全体検索は重く、権限エラーも多発。
3. **`sudo` 常用**
   - 不要な権限昇格は事故リスクを増やす。

### 安全プラクティス
- 破壊的コマンド前に `echo` で対象確認。
- まず `ls` / `find` で対象を目視確認。
- 重要ファイルは先に `tar` でバックアップ。
- `cp -i`, `mv -i`, `rm -i` を検討（上書き/削除確認）。

### 危険コマンド警告
- `rm -rf` は**対象パスを二重確認**（特に変数展開時）。
- `chmod -R` / `chown -R` は範囲ミスで大規模障害を起こす。
- `sudo` 付きワンライナーは内容を理解してから実行。

> 本誌は防御・運用の学習を目的とし、攻撃・悪用手法は扱いません。

---

## 7) One interview-style question

**質問:**
`find` と `locate` の違いを説明し、障害調査時に `find` を選ぶ理由を述べてください。

**期待される観点:**
- `locate` はデータベース依存で即時性が弱い
- `find` はリアルタイムなファイル状態を検索できる
- 権限や検索コスト、正確性のトレードオフ

---

## 8) Next-step resources

- `man find`, `man grep`, `man xargs`, `man tar`, `man journalctl`
- The Linux Command Line (William Shotts)
- Linux Foundation の無料入門資料
- 実践課題: 
  1. 1週間分ログを日付単位で抽出
  2. エラー件数をCSV化
  3. cronで日次バックアップ自動化（実行前にテスト環境で検証）

---

次号予告: **権限管理アーク（chmod/chown/umask）** — 安全な権限設計を初級→上級で掘り下げます。
