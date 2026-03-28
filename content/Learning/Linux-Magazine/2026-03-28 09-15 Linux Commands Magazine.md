---
tags: [linux, commands, learning, devops, daily]
---

# Linux Commands Magazine — 2026-03-28
#linux #commands #learning #devops #daily
[[Home]]

## 1) Topic + Level

**今号テーマ:** ログ調査と障害一次対応（CLIでの実践）

### Beginner（初級）
**レベル:** 初級  
**トピック:** `ls`, `cat`, `less`, `tail`, `grep` で「今何が起きているか」を把握する

### Middle（中級）
**レベル:** 中級  
**前提条件:** 初級内容（標準入出力、`grep`、`tail -f`）を理解していること  
**トピック:** `awk`, `sort`, `uniq`, `cut`, `xargs` でログを集計して異常傾向を見つける

### Advanced（上級）
**レベル:** 上級  
**前提条件:** 中級内容（パイプ処理、集計コマンド、基本的な権限概念）を理解していること  
**トピック:** `journalctl`, `find`, `stat`, `tee`, `sudo` の安全運用で再現性ある調査フローを作る

---

## 2) Why it matters in real projects

- 本番障害では「原因特定までの初動速度」がサービス影響を大きく左右します。  
- 監視アラートを受けた直後に、ログの場所特定→時系列確認→異常行抽出→件数把握ができると、開発・運用双方の意思決定が速くなります。  
- 口頭報告ではなく、**再現可能なコマンド列**として残せると、引き継ぎ・ポストモーテム・面接実務でも強いです。

---

## 3) Core command explanations

### 初級コマンド
- `less /var/log/nginx/access.log`  
  大きいファイルを安全に閲覧。編集はしない。
- `tail -n 100 /var/log/nginx/error.log`  
  直近100行を確認して最新エラーを掴む。
- `tail -f /var/log/nginx/error.log`  
  リアルタイム追跡（監視）。`Ctrl+C`で終了。
- `grep "500" access.log`  
  ステータス500の行を抽出。
- `grep -E "timeout|refused|denied" error.log`  
  複数キーワードのOR検索。

### 中級コマンド
- `awk '{print $9}' access.log`  
  例: nginxアクセスログの9列目（ステータス）を抜く。
- `awk '{print $1}' access.log | sort | uniq -c | sort -nr | head`  
  アクセス元IPを件数順に上位表示。
- `cut -d' ' -f7 access.log | sort | uniq -c | sort -nr | head`  
  よく叩かれるパス上位を抽出。
- `xargs`（安全に使う）  
  `... | xargs -r echo` で空入力時の誤実行を防ぐ（`-r`推奨）。

### 上級コマンド
- `journalctl -u nginx --since "30 min ago"`  
  systemdサービス単位で最近ログを取得。
- `journalctl -p err..alert --since today`  
  優先度エラー以上を抽出。
- `find /var/log -type f -name "*.log" -mtime -1`  
  24時間以内に更新されたログファイル探索。
- `stat /var/log/nginx/error.log`  
  更新時刻・権限・所有者の確認。
- `command | tee investigation.txt`  
  画面表示しつつ調査記録に保存。

---

## 4) 30-60 minute hands-on mini lab

**目標:** 「502/500増加アラート」を想定し、原因候補を3つ挙げる

### 0-10分: 状況確認（初級）
1. `tail -n 200 /var/log/nginx/error.log`
2. `tail -n 200 /var/log/nginx/access.log`
3. `grep -E " 5[0-9][0-9] " /var/log/nginx/access.log | tail -n 50`

### 10-25分: 傾向集計（中級）
1. ステータス分布:
   ```bash
   awk '{print $9}' /var/log/nginx/access.log | sort | uniq -c | sort -nr
   ```
2. 5xx多発IP上位:
   ```bash
   grep -E " 5[0-9][0-9] " /var/log/nginx/access.log | awk '{print $1}' | sort | uniq -c | sort -nr | head
   ```
3. 5xx多発パス上位:
   ```bash
   grep -E " 5[0-9][0-9] " /var/log/nginx/access.log | awk '{print $7}' | sort | uniq -c | sort -nr | head
   ```

### 25-45分: systemdログ確認（上級）
1. `journalctl -u nginx --since "1 hour ago" | tail -n 200`
2. `journalctl -u php-fpm --since "1 hour ago" | grep -Ei "error|warning|timeout"`
3. `journalctl -p err..alert --since "1 hour ago"`

### 45-60分: 報告メモ作成
- `tee`で記録しながら、以下を1ファイルにまとめる：
  - いつから増えたか
  - どのエンドポイントで増えたか
  - どのサービスログに異常があるか
  - 暫定対応案（例: upstream timeout値確認、DB接続数確認）

---

## 5) Command cheatsheet

```bash
# 直近確認

tail -n 100 /var/log/nginx/error.log

# リアルタイム監視

tail -f /var/log/nginx/error.log

# 5xx抽出

grep -E " 5[0-9][0-9] " /var/log/nginx/access.log

# ステータス件数

awk '{print $9}' /var/log/nginx/access.log | sort | uniq -c | sort -nr

# IP上位

grep -E " 5[0-9][0-9] " /var/log/nginx/access.log | awk '{print $1}' | sort | uniq -c | sort -nr | head

# サービスログ（1時間）

journalctl -u nginx --since "1 hour ago"

# エラー優先度のみ

journalctl -p err..alert --since today

# 調査ログ保存

journalctl -u nginx --since "30 min ago" | tee nginx_investigation.txt
```

---

## 6) Common mistakes and safe practices

### よくあるミス
- `sudo`を常用し、不要に管理者権限で閲覧・操作してしまう
- `grep`条件が曖昧で誤検知だらけになる
- タイムゾーンや対象期間を揃えず、誤った相関を作る
- 出力を保存せず再現不能になる

### 安全プラクティス（重要）
- **破壊的コマンド注意:** `rm -rf` は原則調査フェーズで不要。実行前に必ず対象パスを `pwd` と `ls` で再確認。  
- **権限変更注意:** `chmod -R` / `chown -R` は広範囲事故の原因。対象を `find ... -maxdepth` などで限定し、まず dry-run 相当の確認を行う。  
- **`sudo`注意:** 必要なコマンドだけに限定し、`sudo su` 常駐は避ける。監査可能な履歴を残す。  
- **防御的運用:** まず「読む」コマンド（`less`, `tail`, `grep`, `journalctl`）を優先し、設定変更は根拠が揃ってから行う。  
- **バックアップ:** 編集前に `cp file file.bak` で退避。

---

## 7) One interview-style question

**質問:**  
本番で 5xx アラートが発火しました。あなたが最初の15分で実行するコマンドと、その順序の理由を説明してください。

**評価ポイント（自己採点用）:**
- 影響範囲（期間・件数・対象エンドポイント）を定量化できるか
- アプリ/ミドルウェア/OSログを切り分けられるか
- 破壊的操作をせず、再現可能な形で記録できるか

---

## 8) Next-step resources

- `man grep`, `man awk`, `man journalctl`
- Nginxログフォーマットの理解（`log_format` 設定）
- systemd/journald 運用設計（ログ保持期間、永続化設定）
- SRE基礎: インシデント初動、タイムライン作成、ポストモーテム

---

次号予告（学習アーク継続）:  
「プロセス・CPU・メモリ調査（`ps`, `top`, `htop`, `vmstat`, `free`, `pidstat`）」を初級→中級→上級で扱います。
