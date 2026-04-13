---
tags: [linux, commands, learning, devops, daily]
---

# 2026-04-13 09:15 Linux Commands Magazine
[[Home]]

今日のテーマは **「ログ調査と安全なトラブルシュート」**。  
学習アークは **Beginner → Middle → Advanced** の順で進みます（毎号この流れで反復）。

---

## 1) Topic + Level

### Beginner（初級）
**トピック:** `ls` / `cat` / `less` / `tail` でログを「読む」

### Middle（中級）
**トピック:** `grep` / `awk` / `sort` / `uniq` でログを「絞る・集計する」  
**前提知識:** Beginnerの内容（ファイル閲覧・`less`操作・`tail -f`）

### Advanced（上級）
**トピック:** `journalctl` とパイプラインで「障害の原因候補を特定する」  
**前提知識:** Beginner + Middle（標準入出力、パイプ `|`、基本正規表現）

---

## 2) Why it matters in real projects

- 本番障害の初動は「まず状況把握」。ログを早く安全に読める人は復旧が速い。
- 開発環境でも、CI失敗・デプロイ失敗・権限エラーの原因はログに出る。
- 監視ツールがあっても、最終的な一次情報はログ。CLIで扱えると環境依存が少ない。

---

## 3) Core command explanations

### Beginner
- `ls -lah /var/log`
  - ログディレクトリの全体像とサイズ感を確認。
- `less /var/log/syslog`（環境により `/var/log/messages`）
  - ページングして安全に閲覧（編集はしない）。
- `tail -n 50 /var/log/syslog`
  - 末尾50行を確認。
- `tail -f /var/log/syslog`
  - リアルタイム監視（Ctrl+Cで終了）。

### Middle
- `grep -i "error" app.log`
  - 大文字小文字無視で error 検索。
- `grep -E "timeout|failed|denied" app.log`
  - 複数キーワード検索。
- `awk '{print $1, $2, $5}' app.log`
  - 必要列だけ抽出（ログ形式が固定の場合に有効）。
- `sort | uniq -c | sort -nr`
  - 出現回数を集計して多い順に並べる。

### Advanced
- `journalctl -u nginx --since "1 hour ago"`
  - systemdサービス単位で直近ログ確認。
- `journalctl -p err..alert --since today`
  - エラーレベル以上を抽出。
- `journalctl -u your-service --since "30 min ago" | grep -Ei "error|panic|oom|denied"`
  - 重要語だけ再フィルタ。

> ⚠️ 安全注意: `sudo` は必要最小限。ログ閲覧のためだけに不要な root シェルを開かない。

---

## 4) 30-60 minute hands-on mini lab（45分想定）

### ゴール
「サービス障害が起きた」という想定で、原因候補を3つ挙げる。

### 手順
1. **準備（5分）**
   - `mkdir -p ~/lab/logs`
   - サンプルログを作成:
     - `cp /var/log/syslog ~/lab/logs/syslog.sample 2>/dev/null || cp /var/log/messages ~/lab/logs/messages.sample`

2. **初級パート（10分）**
   - `ls -lah ~/lab/logs`
   - `less ~/lab/logs/*.sample`
   - `tail -n 100 ~/lab/logs/*.sample`

3. **中級パート（15分）**
   - `grep -Ei "error|failed|timeout|denied" ~/lab/logs/*.sample | less`
   - `grep -Ei "error|failed|timeout|denied" ~/lab/logs/*.sample | awk '{print $NF}' | sort | uniq -c | sort -nr | head`
   - 目立つエラー語をメモ。

4. **上級パート（15分）**（systemd環境）
   - `journalctl --since "2 hours ago" -p warning..alert | less`
   - 任意のサービスを1つ選ぶ: `journalctl -u sshd --since "2 hours ago" | tail -n 100`
   - 「時刻」「サービス名」「エラーパターン」の3軸で原因候補を整理。

### 完了条件
- 原因候補を3つ（例: 権限拒否、接続タイムアウト、メモリ不足）書けたら完了。

---

## 5) Command cheatsheet

```bash
# 閲覧
ls -lah /var/log
tail -n 100 /var/log/syslog
less /var/log/syslog

# 監視
tail -f /var/log/syslog

# 検索・集計
grep -Ei "error|failed|timeout|denied" app.log
grep -Ei "error|failed|timeout|denied" app.log | sort | uniq -c | sort -nr

# systemdログ
journalctl -u nginx --since "1 hour ago"
journalctl -p err..alert --since today
```

---

## 6) Common mistakes and safe practices

### よくあるミス
- `cat 巨大ログ` で端末が流れて読めなくなる（`less`を使う）。
- 時刻範囲を絞らずにノイズだらけになる（`--since`活用）。
- `sudo`を常用して事故を招く。

### 安全運用のポイント
- 破壊的操作の前に「対象確認」: `pwd` / `ls` / `echo`。
- **危険コマンド注意:**
  - `rm -rf`：削除対象を必ず絶対パスで再確認。
  - `chmod -R` / `chown -R`：範囲を誤るとサービス停止の原因。
  - `sudo`：必要な1コマンドだけ付ける（常時rootは避ける）。
- 調査はまず「読む」→「絞る」→「仮説化」。いきなり設定変更しない。

---

## 7) One interview-style question

**質問:**  
「Webサービスが断続的に 502 を返しています。あなたなら最初の10分でどのログを、どの順番で、どんなコマンドで確認しますか？」

（意図: ログ調査の優先順位、時系列整理、再現性ある手順を説明できるか）

---

## 8) Next-step resources

- `man journalctl`, `man grep`, `man awk`
- The Linux Documentation Project: https://tldp.org/
- DigitalOcean Community Linux tutorials: https://www.digitalocean.com/community/tutorials
- Learn Linux TV (YouTube): 実運用寄りの学習素材

---

次号予告（学習アーク継続）:  
**ファイル権限と所有権の実務（chmod/chown/umask + ACL入門）**
