---
tags: [linux, commands, learning, devops, daily]
---

# Daily Linux Commands Magazine — 2026-03-26 09:15

[[Home]]

> 今日のテーマは **「ログ調査とディスク容量トラブル対応」**。  
> 実務で頻出する運用シナリオを、Beginner → Middle → Advanced の学習アークで段階的に学びます。  
> **安全第一**で、破壊的操作（`rm -rf` / `chmod` / `chown` / `sudo`）の注意点を毎セクションで確認します。

---

## 1) Topic + Level

### Beginner（初級）
**Topic:** ログの基本確認（`ls`, `cat`, `less`, `tail`, `grep`）

### Middle（中級）
**Topic:** 容量逼迫の原因特定（`df`, `du`, `sort`, `head`, `find`）

**Prerequisites（前提知識）:**
- ファイル/ディレクトリ操作（`cd`, `ls`, パス概念）
- 標準出力とパイプ（`|`）の基礎
- 初級編の `less`, `grep`, `tail` が使えること

### Advanced（上級）
**Topic:** ログのローテーション/権限/安全運用（`logrotate` 読解, `chmod`, `chown`, `journalctl`）

**Prerequisites（前提知識）:**
- 中級編の容量調査コマンドを扱えること
- Linux 権限モデル（owner/group/other）を理解していること
- `sudo` の意味とリスクを理解していること

---

## 2) Why it matters in real projects

- 本番障害の初動で最も多いのが「**ディスクフル**」「**ログ肥大化**」「**権限ミスでサービス停止**」。
- 開発/運用の現場では、まず「壊さずに状況把握」する能力が重要。
- 監視アラート（Disk usage > 90%）発報時に、
  1. どこが増えたか  
  2. 何が原因か  
  3. 安全にどう対処するか  
  を短時間で判断できると信頼される。

---

## 3) Core command explanations

### Beginner
- `ls -lah /var/log`  
  ログディレクトリの一覧を人間向けサイズで表示。
- `less /var/log/messages`（環境によっては `/var/log/syslog`）  
  大きいログを安全に閲覧（編集しない）。
- `tail -n 100 /var/log/syslog`  
  最新100行を確認。
- `tail -f /var/log/syslog`  
  追記をリアルタイム監視（Ctrl+C で終了）。
- `grep -i error /var/log/syslog`  
  エラー行を抽出（`-i` は大文字小文字無視）。

### Middle
- `df -h`  
  マウントポイントごとの使用率確認。
- `du -sh /var/log/* 2>/dev/null | sort -h`  
  どのログファイル/ディレクトリが大きいか可視化。
- `find /var/log -type f -size +100M -print`  
  100MB超のファイル探索。
- `du -xhd1 / | sort -h`  
  同一ファイルシステム内で肥大箇所を1階層で調査。

### Advanced
- `journalctl -p err -b`  
  今回起動（`-b`）中のエラーレベルログを確認。
- `sudo logrotate -d /etc/logrotate.conf`  
  **dry-run（デバッグ）** でローテーション動作を事前確認。
- `namei -l /var/log/app/app.log`  
  パス途中を含む権限の追跡確認。
- `stat /var/log/app/app.log`  
  所有者・権限・更新時刻を精査。

> ⚠️ 注意: `chmod -R` / `chown -R` は誤対象で大事故になりやすい。  
> 必ず対象パスを `pwd`, `ls`, `readlink -f` で確認してから最小範囲で実行する。

---

## 4) 30-60 minute hands-on mini lab

### Goal
「ディスク使用率アラートが来た」という想定で、**調査→原因特定→安全な暫定対応案**まで実施する。

### 手順（約45分）

1. **現状把握（5分）**
   ```bash
   df -h
   ```
   - 使用率が高いパーティションをメモ（例: `/var` 92%）。

2. **犯人候補探索（10分）**
   ```bash
   sudo du -sh /var/* 2>/dev/null | sort -h
   sudo du -sh /var/log/* 2>/dev/null | sort -h
   ```
   - どのディレクトリが急増しているか特定。

3. **巨大ファイル特定（10分）**
   ```bash
   sudo find /var/log -type f -size +200M -print
   ```
   - ファイル名・サイズ・更新時刻を確認。

4. **ログ内容確認（10分）**
   ```bash
   sudo tail -n 200 /var/log/<suspect.log>
   sudo grep -iE "error|warn|fail" /var/log/<suspect.log> | tail -n 50
   ```
   - 何のエラーでログが増えているか仮説を立てる。

5. **安全な対応案を作成（10分）**
   - いきなり削除しない。
   - 提案例:
     - `logrotate` 設定見直し
     - アプリのログレベル調整（debug→info）
     - 原因エラー修正
   - 必要なら圧縮/退避を優先し、完全削除は承認後。

### Labの提出物
- 使用率の高いマウントポイント
- 肥大ディレクトリ上位3つ
- 最大ログファイル1つと原因仮説
- 破壊的操作なしでの暫定対処案

---

## 5) Command cheatsheet

```bash
# ログ閲覧
less /var/log/syslog
tail -n 100 /var/log/syslog
tail -f /var/log/syslog
grep -i error /var/log/syslog

# 容量調査
df -h
du -sh /var/log/* 2>/dev/null | sort -h
find /var/log -type f -size +100M -print

# systemd環境ログ
journalctl -p err -b
journalctl -u nginx --since "1 hour ago"

# 事前確認（安全）
logrotate -d /etc/logrotate.conf
```

---

## 6) Common mistakes and safe practices

### よくあるミス
1. `sudo rm -rf /var/log/*` を即実行する  
   - 監査証跡消失、サービス影響、原因追跡不能化。
2. `chmod -R 777` で権限問題を“力技”解決  
   - セキュリティ重大リスク。
3. `chown -R` の対象を誤る  
   - システム全体の所有権破壊につながる。
4. 本番で検証なしに `logrotate` 反映  
   - ログ欠落や再起動誘発の可能性。

### 安全プラクティス
- 破壊的変更前に **バックアップ/退避**。
- まず `-d`（dry-run）, `--test` があるなら必ず使う。
- `sudo` 実行前に「対象・目的・ロールバック手段」を言語化。
- 削除より先に「圧縮」「ローテーション」「出力抑制」を検討。
- 変更履歴をチケット/ノートに記録（再現性確保）。

---

## 7) One interview-style question

**Q.** 本番サーバーで `/var` 使用率が 95% になりました。サービス停止を避けつつ、最初の15分でどの順番で調査し、どの操作を避けますか？理由も説明してください。

（期待される観点：`df`→`du/find`→ログ確認→原因仮説→安全な暫定対処。安易な `rm -rf` 回避、監査ログ保全、変更前確認。）

---

## 8) Next-step resources

- manページ（一次情報）
  - `man du`
  - `man df`
  - `man find`
  - `man journalctl`
  - `man logrotate`
- The Linux Documentation Project: https://tldp.org/
- Red Hat系運用ドキュメント（journal/logrotate）
- 学習提案（次号予告）
  - 「プロセス調査（`ps`, `top`, `ss`, `lsof`）で高負荷原因を特定する」

---

**Daily note:** 今日の学習アークは「読む（Beginner）→測る（Middle）→壊さず運用設計（Advanced）」です。安全第一で、破壊的コマンドは最後の手段として扱いましょう。
