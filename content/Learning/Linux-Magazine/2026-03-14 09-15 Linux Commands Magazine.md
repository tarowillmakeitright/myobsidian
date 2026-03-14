# 2026-03-14 Linux Commands Magazine

Tags: #linux #commands #learning #devops #daily
Links: [[Home]]

---

## 学習アーク 1（初級 → 中級 → 上級）
テーマは「ログ調査と安全な運用」です。実務で最も頻出かつ事故を防ぎやすい流れにしています。

---

## 1) Topic + Level

### 初級（Beginner）
**トピック:** `ls` / `cat` / `less` / `tail` でログを読む基礎

### 中級（Middle）
**トピック:** `grep` / `awk` / `sort` / `uniq` / `wc` でログを絞り込んで集計
**前提条件:** 初級の内容（パス移動、ファイル閲覧、`tail -f`の意味）を理解していること

### 上級（Advanced）
**トピック:** `journalctl` + パイプライン + 安全な権限確認で障害切り分け
**前提条件:** 中級の内容（正規表現での抽出、集計パイプ）を扱えること

---

## 2) Why it matters in real projects

- 障害対応の最初の一歩は「正しくログを読む」こと。
- 開発でも運用でも、**再現性のある調査コマンド**を持つ人は強い。
- 誤った権限変更（`chmod` / `chown`）や危険削除（`rm -rf`）を避けることで、復旧工数を大幅に減らせる。

---

## 3) Core command explanations

### 初級コマンド
- `ls -lah` : 隠しファイル含め詳細表示。サイズ・権限確認に必須。
- `less /path/to/log` : 長いログを安全に閲覧（編集しない）。
- `tail -n 100 app.log` : 末尾100行を確認。
- `tail -f app.log` : 追記をリアルタイム監視（Ctrl+Cで終了）。

### 中級コマンド
- `grep -E "ERROR|WARN" app.log` : エラー・警告の抽出。
- `awk '{print $1, $2, $5}' app.log` : 列抽出（フォーマット依存）。
- `sort | uniq -c | sort -nr` : 件数集計の定番。
- `wc -l app.log` : 行数確認（規模感の把握）。

### 上級コマンド
- `journalctl -u nginx --since "1 hour ago"` : systemdサービスログ確認。
- `journalctl -p err -S today` : エラーレベルのみ抽出。
- `sudo -l` : sudo可能範囲の確認（先に把握してから使う）。
- `namei -l /path/to/file` : パス各階層の権限確認（Permission denied調査で有効）。

---

## 4) 30-60 minute hands-on mini lab

**目標:** 「接続エラーが増えた」想定でログ調査し、原因仮説を1つ作る。

### 所要時間目安
- 初級 15分
- 中級 20分
- 上級 20分

### 手順
1. テスト用ログ作成
   ```bash
   mkdir -p ~/linux-mag-lab && cd ~/linux-mag-lab
   cat > app.log <<'EOF'
   2026-03-14T08:50:01 INFO auth login_success user=alice
   2026-03-14T08:51:12 WARN api timeout endpoint=/orders
   2026-03-14T08:51:45 ERROR db connection_failed code=ECONNRESET
   2026-03-14T08:52:10 INFO auth login_success user=bob
   2026-03-14T08:52:41 ERROR db connection_failed code=ECONNRESET
   2026-03-14T08:53:01 WARN api timeout endpoint=/checkout
   EOF
   ```
2. 初級: `less`, `tail -n 5` で現象を目視。
3. 中級: `grep -E "ERROR|WARN" app.log | sort | uniq -c | sort -nr` で頻出事象を特定。
4. 上級: （systemd環境なら）
   ```bash
   journalctl -p err -S "today" | tail -n 30
   ```
   アプリログとの時刻相関を確認。
5. 結果を `report.md` に記録（現象 / 根拠ログ / 仮説 / 次アクション）。

**提出物（自分用）:**
- `report.md` に最低4項目
  - 現象
  - 主要エラー
  - 仮説
  - 次に確認するコマンド

---

## 5) Command cheatsheet

```bash
# 閲覧
ls -lah
less app.log
tail -n 100 app.log
tail -f app.log

# 抽出・集計
grep -E "ERROR|WARN" app.log
grep "connection_failed" app.log | wc -l
grep "ERROR" app.log | awk '{print $5}' | sort | uniq -c | sort -nr

# systemdログ
journalctl -u nginx --since "1 hour ago"
journalctl -p err -S today

# 権限・実行可能範囲確認
id
sudo -l
namei -l /path/to/file
```

---

## 6) Common mistakes and safe practices

### よくあるミス
- `rm -rf` を補完任せで実行し、意図しない場所を削除する。
- `chmod -R 777` を安易に使う（セキュリティ事故の原因）。
- `chown -R` の対象を誤る（サービス停止や権限崩壊）。
- `sudo` を「とりあえず」で使う（監査性と安全性が落ちる）。

### 安全プラクティス
- **破壊的コマンド前に `pwd` と `ls` を確認。**
- **削除前は `echo rm ...` でドライラン相当確認。**
- 権限変更は最小範囲・最小権限（Principle of Least Privilege）。
- 重要操作前にバックアップ（`cp -a` やスナップショット）。
- `sudo` は必要最小限、実行前に目的と影響範囲を言語化。

---

## 7) One interview-style question

**質問:**
本番で「APIが断続的に500を返す」と報告されました。あなたなら最初の10分でどのコマンドをどういう順序で打ち、何を根拠に次アクションを決めますか？

（期待される観点: 時刻同期、エラーログ抽出、頻度集計、依存サービスの状態確認、破壊的操作をしない安全性）

---

## 8) Next-step resources

- manページ
  - `man tail`
  - `man grep`
  - `man journalctl`
  - `man sudo`
- The Linux Command Line (William Shotts)
- Linux Foundation training materials (運用・管理系)
- 実環境での安全演習: 読み取り中心の障害調査手順書を自作し、毎週1回リハーサル

---

次号予告（学習アーク 2）:
「プロセス管理とリソース監視（`ps`, `top`, `htop`, `ss`, `lsof`）」
初級→中級→上級の同形式で進行。