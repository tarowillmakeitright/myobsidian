---
tags:
  - linux
  - commands
  - learning
  - devops
  - daily
---

[[Home]]

# Daily Linux Commands Magazine — 2026-03-19

## 1) Topic + Level

### 今回のテーマ
**安全なログ調査とディスク圧迫トラブルの初動対応**

---

### Beginner（初級）
**レベル:** Beginner  
**トピック:** `ls` / `du` / `df` / `tail` / `less` で「どこが容量を食っているか」を安全に把握する

---

### Middle（中級）
**レベル:** Middle  
**トピック:** `find` + `xargs` + `grep` で「最近更新された巨大ログ」を絞り込む

**前提（Prerequisites）:**
- Beginner の内容（`du` と `df` の違い、`less`/`tail` の閲覧）
- パイプ（`|`）と標準出力の基礎

---

### Advanced（上級）
**レベル:** Advanced  
**トピック:** `journalctl` / `logrotate` / 権限確認（`sudo -l`）を使った継続運用と安全対策

**前提（Prerequisites）:**
- Middle の内容（`find` 条件式、`xargs` の扱い）
- systemd ジャーナルとログローテーションの基本概念

---

## 2) Why it matters in real projects

本番運用では「突然ディスクがいっぱいでアプリが落ちる」事故が頻発します。  
このとき重要なのは、**削除を急がず、まず観測して原因を特定すること**です。

- CI/CD が失敗する（ビルド成果物を保存できない）
- DB/アプリが書き込みエラーを起こす
- 監視エージェントが停止し、障害検知が遅れる

実務では、
1. 現状把握（`df`, `du`）
2. 原因特定（巨大・新規ログの特定）
3. 再発防止（`logrotate`, 監視, 運用ルール）
の順が王道です。

---

## 3) Core command explanations

### Beginnerコマンド

- `df -h`  
  ファイルシステム単位で空き容量を確認（`-h` は見やすい単位）。

- `du -sh /var/log/*`  
  ディレクトリ/ファイルごとの使用量を確認。`df` と違って「どこが重いか」がわかる。

- `tail -n 100 /var/log/messages`  
  末尾100行を見る。ログの最新状況を把握。

- `less /var/log/messages`  
  安全な閲覧。検索は `/keyword`、終了は `q`。

> 安全メモ: まずは **読むだけのコマンド** を使う。いきなり削除しない。

---

### Middleコマンド

- `find /var/log -type f -mtime -1 -size +100M`  
  24時間以内に更新され、100MB超のファイルを探索。

- `find ... -print0 | xargs -0 ls -lh`  
  スペース入りファイル名でも安全に処理。

- `grep -E "error|fatal|oom" /var/log/app.log | tail -n 50`  
  重要キーワードを抽出して直近傾向を確認。

> 安全メモ: `xargs` は対象が大量のとき強力。まず `echo` で dry-run する癖をつける。

---

### Advancedコマンド

- `journalctl -p err -S today`  
  今日のエラーレベルログを抽出（systemd環境）。

- `sudo -l`  
  自分に許可された `sudo` 範囲を確認。不要な昇格を避ける。

- `logrotate -d /etc/logrotate.conf`  
  実際には変更せずにデバッグ実行（安全に動作確認）。

- `logrotate -f /etc/logrotate.conf`  
  強制ローテーション。**本番では影響確認後のみ**。

> 安全メモ: `sudo` は最小権限で。`-d`（dry-run/diagnostic）を先に使う。

---

## 4) 30-60 minute hands-on mini lab

**ラボ名:** ディスク逼迫インシデント初動（安全版）  
**目安:** 45分

### 目的
- 容量逼迫時に「観測→特定→対策案」までを安全に実施する

### 手順

1. **現状確認（10分）**
   - `df -h`
   - `du -sh /var/log/* 2>/dev/null | sort -h | tail`
   - 最も重いログ領域をメモ

2. **犯人候補の特定（15分）**
   - `find /var/log -type f -size +100M -print0 | xargs -0 ls -lh`
   - `find /var/log -type f -mtime -1 -print | head`
   - 直近で肥大化した候補を3つ選ぶ

3. **内容確認（10分）**
   - `tail -n 200 <対象ログ>`
   - `grep -Ei "error|fatal|exception|oom" <対象ログ> | tail -n 50`
   - エラーパターンを記録

4. **再発防止プラン作成（10分）**
   - ローテーション設定の確認: `cat /etc/logrotate.conf`
   - 個別設定確認: `ls /etc/logrotate.d`
   - 提案を3点まとめる（例: 保持日数調整、アプリログレベル見直し、アラート閾値設定）

### 成果物
- 「原因候補」「根拠コマンド」「再発防止案」を3行ずつで記録

> 禁止（このラボでは実施しない）:
> - `rm -rf` による即削除
> - `truncate -s 0` の無計画実行
> - 本番での `logrotate -f` 即実行

---

## 5) Command cheatsheet

```bash
# 容量の全体像
 df -h

# どこが重いか（上位確認）
 du -sh /var/log/* 2>/dev/null | sort -h | tail

# 巨大ファイル探索
 find /var/log -type f -size +100M

# 最近更新されたログ
 find /var/log -type f -mtime -1

# 末尾チェック
 tail -n 100 /var/log/messages

# キーワード抽出
 grep -Ei "error|fatal|oom" /var/log/app.log | tail -n 50

# systemdログ（今日のエラー）
 journalctl -p err -S today

# sudo権限確認
 sudo -l

# logrotateの安全確認（変更なし）
 logrotate -d /etc/logrotate.conf
```

---

## 6) Common mistakes and safe practices

### よくあるミス
- `df` だけ見て「どのファイルが原因か」を特定した気になる
- いきなり `sudo rm -rf` でログを消す
- `chmod -R 777` や雑な `chown -R` で権限事故を起こす
- `sudo` を常用して操作ログ・責任境界が曖昧になる

### 安全プラクティス
- まずは読み取りコマンドで調査（`df`, `du`, `less`, `tail`）
- 破壊的操作前にバックアップ/スナップショット/同意を取る
- `find` + `xargs` は `-print0` / `-0` を使って安全に
- 権限変更は対象を絞る（最小権限の原則）
- 本番での強制操作（`-f`）は必ず影響確認後

> ⚠ 危険コマンド注意:
> - `rm -rf` : パス誤りで壊滅的削除
> - `chmod/chown -R` : サービス停止や情報漏えいの原因
> - `sudo` : 影響範囲が広い。必要最小限で使用

---

## 7) One interview-style question

**質問:**  
「本番サーバの `/var` が 95% に達しました。あなたが最初の15分で実行するコマンドと、絶対に避ける操作を説明してください。」

**評価ポイント（自習用）:**
- 観測優先（`df`→`du`→`find`）の順序
- 根拠に基づく切り分け
- 破壊的操作の抑制と安全性配慮

---

## 8) Next-step resources

- manページ
  - `man df`, `man du`, `man find`, `man journalctl`, `man logrotate`
- 公式ドキュメント
  - systemd journal: https://www.freedesktop.org/software/systemd/man/journalctl.html
  - logrotate: https://linux.die.net/man/8/logrotate
- 実務演習アイデア
  - ステージングで意図的にログ肥大化シナリオを作り、対応手順をRunbook化
  - 監視に「ディスク使用率 + inode使用率 + ログ増加速度」を追加

---

次号予告（学習アーク継続）:  
Beginner→Middle→Advanced の流れで、次回は **「プロセス監視と異常プロセス切り分け（ps/top/ss/lsof）」** を扱います。