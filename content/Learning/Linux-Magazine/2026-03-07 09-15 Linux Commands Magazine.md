---
tags: [linux, commands, learning, devops, daily]
---

# Daily Linux Commands Magazine — 2026-03-07 09:15
[[Home]]

## 学習アーク1: ログ調査と運用トラブルシュート（Beginner → Middle → Advanced）

---

## 1) Topic + Level

### Beginner
**Topic:** `ls` / `cat` / `less` / `tail` でログを安全に読む

### Middle（前提: Beginnerの内容を理解していること）
**Topic:** `grep` / `awk` / `sort` / `uniq -c` でログから異常傾向を抽出

### Advanced（前提: Middleの内容 + パイプ処理に慣れていること）
**Topic:** `journalctl` と複合ワンライナーで「原因候補」を短時間で絞る

---

## 2) Why it matters in real projects

- 本番障害対応では「まずログを正しく読む力」が復旧速度を左右する。
- SRE/DevOps業務では、監視アラート後にCLIで即調査する場面が多い。
- GUIなし（サーバー直SSH）でも再現可能な手順を持つと、チームで共有・自動化しやすい。

---

## 3) Core command explanations

### Beginner Core
- `ls -lah /var/log`
  - ログディレクトリのサイズ感・更新日時を確認。
- `less /var/log/messages`
  - 長いファイルを安全に閲覧（編集しない）。
- `tail -n 50 /var/log/messages`
  - 直近50行だけを見る。
- `tail -f /var/log/messages`
  - 追記をリアルタイム監視（`Ctrl+C`で終了）。

### Middle Core
- `grep -i "error" app.log`
  - 大文字小文字を無視して `error` を検索。
- `awk '{print $1, $2, $3}' app.log`
  - 必要な列だけ抽出。
- `sort | uniq -c | sort -nr`
  - 件数集計→多い順に並べる定番パターン。
- 例:
  ```bash
  grep -i "timeout" app.log | awk '{print $5}' | sort | uniq -c | sort -nr | head
  ```
  - timeout関連の第5列（例: API名）を集計して上位表示。

### Advanced Core
- `journalctl -u nginx --since "1 hour ago"`
  - nginxサービスの直近1時間ログを取得。
- `journalctl -p err -S today`
  - 今日のエラーレベルログを抽出。
- 時刻付きで追跡:
  ```bash
  journalctl -u myapp -f -o short-iso
  ```
- 複合分析例:
  ```bash
  journalctl -u myapp --since "2 hours ago" \
    | grep -Ei "error|failed|timeout" \
    | awk '{print $1" "$2" "$3" | "$0}' \
    | head -n 30
  ```

---

## 4) 30-60 minute hands-on mini lab

**テーマ:** 「Webアプリ遅延の初動調査」

### 所要時間
40分

### 手順
1. **準備（5分）**
   - テスト用ログを作成:
     ```bash
     mkdir -p ~/linux-mag-lab && cd ~/linux-mag-lab
     cat > app.log <<'EOF'
     2026-03-07T08:40:01Z INFO api=/login status=200 latency=120ms
     2026-03-07T08:40:11Z WARN api=/search status=200 latency=920ms
     2026-03-07T08:40:21Z ERROR api=/checkout status=500 latency=2100ms
     2026-03-07T08:40:31Z ERROR api=/checkout status=500 latency=2200ms
     2026-03-07T08:40:41Z WARN api=/search status=200 latency=980ms
     EOF
     ```

2. **Beginner演習（10分）**
   - `less app.log`
   - `tail -n 3 app.log`
   - `tail -f app.log` を実行し、別ターミナルで1行追記して変化を確認。

3. **Middle演習（15分）**
   - ERRORだけ抽出:
     ```bash
     grep "ERROR" app.log
     ```
   - API別件数:
     ```bash
     awk '{print $3}' app.log | sort | uniq -c | sort -nr
     ```
   - 高遅延（900ms以上）抽出（簡易）:
     ```bash
     grep -E "latency=([9][0-9]{2}|[0-9]{4,})ms" app.log
     ```

4. **Advanced演習（10分）**
   - 自分なりの1行レポートを作る（例）:
     ```bash
     echo "Top error API:" && grep "ERROR" app.log | awk '{print $3}' | sort | uniq -c | sort -nr | head -n 1
     ```
   - 何がボトルネック候補かを2行で記述（`notes.txt`作成）。

### ゴール
- 「どのAPIで」「どんな異常が」「どれくらい起きたか」をCLIだけで説明できる。

---

## 5) Command cheatsheet

```bash
# 閲覧
less file.log
tail -n 100 file.log
tail -f file.log

# 検索・抽出
grep -i "error" file.log
grep -E "error|failed|timeout" file.log
awk '{print $1, $3, $5}' file.log

# 集計
awk '{print $3}' file.log | sort | uniq -c | sort -nr | head

# systemdログ
journalctl -u <service>
journalctl -u <service> --since "30 min ago"
journalctl -p err -S today
journalctl -u <service> -f
```

---

## 6) Common mistakes and safe practices

### よくあるミス
- `sudo` を常用して不要に強権で操作する。
- ログ確認中に誤って編集コマンド（`vi`等）を開いて保存してしまう。
- `grep` の条件が広すぎてノイズだらけになる。

### 安全プラクティス（重要）
- **破壊的コマンド注意:** `rm -rf` は対象パスを `pwd` / `ls` で再確認してから。ワイルドカード `*` は特に危険。
- **権限変更注意:** `chmod -R` / `chown -R` はシステム全体を壊しやすい。対象を限定し、実行前に `echo` で確認。
- **sudo注意:** 必要最小限で使用。まず一般権限で読める情報を集める。
- **運用の基本:** 変更前にバックアップ（例: `cp config config.bak`）を作る。
- **防御的学習を優先:** 調査・保守・復旧手順の習熟を主目的にし、攻撃的/悪用目的の手法は扱わない。

---

## 7) One interview-style question

**Q.** 本番APIで「遅い」という報告だけ来たとき、最初の10分でどんなコマンドをどんな順で実行し、何を切り分けますか？

（期待ポイント: 対象範囲の確認、直近ログ確認、エラー頻度、遅延傾向、サービス単位の絞り込み、再現可能な報告）

---

## 8) Next-step resources

- `man grep`, `man awk`, `man journalctl`
- The Linux Command Line (William Shotts)
- DigitalOcean Community: Linux logging / journalctl practical guides
- `tldr` コマンド（要インストール）で使用例を素早く確認

---

### 明日の予告（次アーク）
「ファイル権限と所有権の実務（`chmod`/`chown`/`umask`）」を Beginner → Middle → Advanced で扱います。
