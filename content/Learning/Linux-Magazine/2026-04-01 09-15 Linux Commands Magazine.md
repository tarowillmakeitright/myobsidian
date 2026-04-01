---
tags:
  - linux
  - commands
  - learning
  - devops
  - daily
---

[[Home]]

# Daily Linux Commands Magazine — 2026-04-01

## 今回の学習アーク
- **Beginner → Middle → Advanced** の順で、実務でそのまま使える運用系スキルを積み上げます。  
- **安全第一**: 破壊的コマンド（`rm -rf` など）は必ず影響範囲を確認してから実行。

---

## 1) Topic + Level

### Beginner（初級）
**トピック:** ファイル調査の基本（`ls`, `pwd`, `cd`, `cat`, `less`, `head`, `tail`, `wc`）

### Middle（中級）
**トピック:** ログ解析の基本パイプライン（`grep`, `sort`, `uniq`, `cut`, `awk`, `xargs`）  
**前提知識:** Beginnerレベルのファイル操作、標準入力/標準出力の概念

### Advanced（上級）
**トピック:** 安全な一括運用（`find` + 条件指定 + 実行前確認 + バックアップ）  
**前提知識:** Middleレベルのパイプ操作、`find`/正規表現の基礎、権限（`chmod`/`chown`）の基本

---

## 2) Why it matters in real projects
- 障害対応では「まず状況を読む」能力が重要。初級コマンドが最速の観測手段になります。  
- 中級のテキスト処理は、アプリログ・アクセスログ・監査ログの分析で日常的に必要です。  
- 上級の一括処理は、設定ファイルの棚卸し・不要ファイル整理・権限監査などの保守運用で強力。  
- ただし強力な分、**誤実行で被害が大きい**ため、常に「Dry-run → 確認 → 実行」の順を徹底します。

---

## 3) Core command explanations

### Beginner コア
- `pwd`: 現在地を確認（迷子防止）
- `ls -lah`: サイズ・権限・隠しファイルを含めて一覧
- `cat file`: 短いファイルの中身確認
- `less file`: 長いファイルを安全に閲覧（`q`で終了）
- `head -n 20 file` / `tail -n 50 file`: 先頭・末尾を確認
- `wc -l file`: 行数カウント

### Middle コア
- `grep "ERROR" app.log`: 文字列検索
- `grep -E "WARN|ERROR" app.log`: 複数パターン
- `cut -d' ' -f1,4`: 区切り文字で列抽出
- `awk '{print $1, $5}'`: 柔軟な列処理
- `sort | uniq -c | sort -nr`: 集計の定番
- `xargs`: 標準入力を引数化（**`-0` と組み合わせるのが安全**）

### Advanced コア
- `find . -type f -name "*.log"`: 条件検索
- `find . -type f -mtime +30`: 30日より古いファイル
- `find . -type f -print0 | xargs -0 ...`: 空白入りファイル名に安全対応
- `find ... -exec ... {} \;`: 1件ずつ安全実行
- `cp -a target target.bak.$(date +%F)`: 事前バックアップ

> ⚠️ 注意: `find ... -exec rm -rf {} \;` のような破壊的パターンは危険です。まず `-print` で対象確認し、削除は最後に。

---

## 4) 30-60 minute hands-on mini lab

### ゴール
「ログを調べ、古いログ候補を抽出し、安全にアーカイブする」

### 手順（約45分）
1. **作業ディレクトリ準備（5分）**
   ```bash
   mkdir -p ~/linux-mag-lab/{logs,archive}
   cd ~/linux-mag-lab
   ```

2. **サンプルログ作成（10分）**
   ```bash
   for i in {1..5}; do
     echo "2026-04-01 INFO service=api message=ok" >> logs/app.log
   done
   echo "2026-04-01 WARN service=api message=retry" >> logs/app.log
   echo "2026-04-01 ERROR service=db message=timeout" >> logs/app.log
   ```

3. **中級解析（15分）**
   ```bash
   grep -E "WARN|ERROR" logs/app.log
   awk '{print $3}' logs/app.log | sort | uniq -c | sort -nr
   grep "ERROR" logs/app.log | wc -l
   ```

4. **上級: 安全な一括対象確認（10分）**
   ```bash
   # まず候補表示（削除しない）
   find logs -type f -name "*.log" -print

   # アーカイブ（安全側: moveの前にコピー）
   cp -a logs logs.bak.$(date +%F-%H%M)
   tar -czf archive/logs-$(date +%F).tar.gz logs/*.log
   ```

5. **検証（5分）**
   ```bash
   tar -tzf archive/logs-$(date +%F).tar.gz
   ls -lah archive
   ```

### 完了条件
- WARN/ERROR 行を抽出できた
- ERROR 件数を数えられた
- ログを安全にバックアップ・アーカイブできた

---

## 5) Command cheatsheet

```bash
# 位置・一覧
pwd
ls -lah

# 閲覧
less file
head -n 20 file
tail -n 50 file
wc -l file

# 検索・集計
grep -E "WARN|ERROR" app.log
awk '{print $3}' app.log | sort | uniq -c | sort -nr

# 安全な一括処理
find . -type f -name "*.log" -print
find . -type f -name "*.log" -print0 | xargs -0 -I{} echo {}

# 事前バックアップ
cp -a dir dir.bak.$(date +%F-%H%M)
```

---

## 6) Common mistakes and safe practices

### よくあるミス
1. `rm -rf` を補完ミスで誤爆する  
2. `chmod -R 777` を安易に使う  
3. `chown -R` の対象を誤り、サービスが起動不能になる  
4. `sudo` 付きで未確認コマンドを実行する

### 安全プラクティス
- **原則Dry-run**: まず `echo` / `-print` で対象確認
- **バックアップ先行**: 変更前に `cp -a` や `tar` を取る
- **最小権限**: `sudo` は必要時のみ、必要範囲だけ
- **段階実行**: 1件テスト → 少量実行 → 全体実行
- **危険コマンドの前に指差し確認**: パス・ワイルドカード・カレントディレクトリ

---

## 7) One interview-style question

**質問:**  
本番サーバーで `/var/log/myapp/` 配下の `.log` が急増しディスク逼迫しています。  
サービス影響を最小化しつつ、原因調査と容量対策をどう進めますか？

**評価ポイント（セルフチェック）:**
- まず観測（`du`, `find`, `tail`, `grep`）して事実確認しているか
- 破壊操作の前にバックアップやローテーション方針を示せるか
- 一時対応（圧縮・退避）と恒久対応（logrotate, アプリログレベル見直し）を分けて説明できるか

---

## 8) Next-step resources
- `man` の習慣化: `man find`, `man grep`, `man awk`, `man xargs`
- The Linux Command Line（William Shotts）
- logrotate公式ドキュメント
- systemd-journald / journalctl の運用ガイド
- 次回の学習候補: `journalctl` と `systemctl` で障害初動を標準化

---

### 明日へのブリッジ
明日は「`journalctl` で時系列に障害を追う（Beginner）→ フィルタ条件最適化（Middle）→ 永続化と保持戦略（Advanced）」を扱うと、今回のログ解析スキルが実務レベルでつながります。
