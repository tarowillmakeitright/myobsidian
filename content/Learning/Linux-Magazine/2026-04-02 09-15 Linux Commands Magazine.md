---
tags: [linux, commands, learning, devops, daily]
---
[[Home]]

# Daily Linux Commands Magazine — 2026-04-02

## 学習アークA（Beginner → Middle → Advanced）

---

## 1) Topic + Level

### 今日のテーマ
**「ログ調査とプロセス管理の基本」**

- **Beginner:** `ps`, `top`, `grep`, `tail` で「今なにが起きているか」を見る
- **Middle:** `journalctl`, `ss`, `awk`, `xargs` で障害の切り分けを高速化
  - **前提知識:** Beginnerのコマンドで出力を読めること、パイプ `|` が使えること
- **Advanced:** `systemctl`, `nice/renice`, 安全な一括操作（dry-run前提）で運用対応力を上げる
  - **前提知識:** Middleのログ調査ができること、プロセスID（PID）とサービス概念を理解していること

---

## 2) Why it matters in real projects

実案件では「アプリが遅い」「突然落ちた」「ポートが使えない」が日常的に起きます。  
そのときに必要なのは、

- 感覚ではなく**観測（ログ・プロセス・ソケット）**で判断すること
- いきなり再起動せず、**原因の証跡**を残すこと
- 影響範囲を見ながら、**安全に最小操作**で復旧すること

このテーマを身につけると、オンコールや障害一次対応で強くなれます。

---

## 3) Core command explanations

### Beginner

#### `ps aux`
全プロセスの一覧を表示。

```bash
ps aux | head
```

- `USER`: 実行ユーザー
- `PID`: プロセスID
- `%CPU`, `%MEM`: リソース利用率
- `COMMAND`: 実行コマンド

#### `top`（または `htop`）
リアルタイムでCPU/メモリ使用率を監視。

```bash
top
```

- `P` キー: CPU使用率順
- `M` キー: メモリ使用率順

#### `tail -f`
ログ末尾を追跡。障害時の「今出たエラー」確認に有効。

```bash
tail -f /var/log/messages
```

> ディストリビューションによりログ場所は異なります。`journalctl`主体の環境も多いです。

#### `grep`
必要な行だけ抽出。

```bash
grep -i "error" app.log
```

- `-i`: 大文字小文字を無視

### Middle

#### `journalctl`
systemd環境のログ閲覧。

```bash
journalctl -u nginx --since "1 hour ago"
```

- `-u`: サービス単位
- `--since`: 時間範囲指定

追跡モード:

```bash
journalctl -u nginx -f
```

#### `ss -lntp`
待受ポートとプロセス確認。

```bash
ss -lntp
```

- `-l`: listen中
- `-n`: 名前解決しない（高速）
- `-t`: TCP
- `-p`: プロセス表示

#### `awk`
列ベースで整形・集計。

```bash
ps aux | awk '{print $1, $2, $3, $11}' | head
```

#### `xargs`
標準入力を引数に変換して別コマンドへ。

```bash
cat pids.txt | xargs -r -n1 echo PID:
```

- `-r`: 入力空なら実行しない（安全）

### Advanced

#### `systemctl`
サービス状態の確認と制御。

```bash
systemctl status nginx
systemctl restart nginx
```

> `restart`は影響が大きいので、先に`status`とログ確認を行う。

#### `nice` / `renice`
CPU優先度を調整。

```bash
nice -n 10 ./batch_job.sh
renice +5 -p 12345
```

- 数値が大きいほど優先度が下がる（他業務への影響を抑える）

#### 安全な一括操作（確認→実行）

```bash
# まず対象確認（dry-run）
ps aux | grep myworker | grep -v grep | awk '{print $2}'

# 実行前に echo で確認
ps aux | grep myworker | grep -v grep | awk '{print $2}' | xargs -r -n1 echo kill -TERM

# 問題なければ実行
ps aux | grep myworker | grep -v grep | awk '{print $2}' | xargs -r -n1 kill -TERM
```

---

## 4) 30-60 minute hands-on mini lab

**所要時間:** 約45分  
**ゴール:** 「高CPUなプロセスを特定し、ログを確認し、安全に停止/再起動判断する」

### 手順

1. **疑似負荷プロセスを起動（5分）**

```bash
yes > /dev/null &
echo $! > /tmp/cpuhog.pid
```

2. **プロセス観測（10分）**

```bash
ps aux | grep yes | grep -v grep
top
```

3. **ログ観測（10分）**
   - 自分のアプリログがあれば `tail -f` / `grep` で確認
   - systemdサービスがあれば `journalctl -u <service> --since "30 min ago"`

4. **ポート競合確認（10分）**

```bash
ss -lntp | head -n 20
```

5. **安全停止（10分）**

```bash
cat /tmp/cpuhog.pid
kill -TERM $(cat /tmp/cpuhog.pid)
ps -p $(cat /tmp/cpuhog.pid) || echo "stopped"
```

### 検証ポイント

- PIDを誤っていないか
- `kill -9`を安易に使っていないか
- 停止前後でログ差分を見たか

---

## 5) Command cheatsheet

```bash
# プロセス一覧
ps aux | head

# 高負荷確認
top

# ログ追跡
tail -f /path/to/app.log
journalctl -u <service> -f

# エラー抽出
grep -i "error|failed" app.log

# ポート確認
ss -lntp

# サービス状態
systemctl status <service>

# 安全停止（通常シグナル）
kill -TERM <pid>

# 優先度調整
renice +5 -p <pid>
```

---

## 6) Common mistakes and safe practices

### よくあるミス

1. **いきなり再起動する**
   - 原因が消えて再発防止できない
2. **`kill -9`を常用する**
   - 後処理が走らずデータ不整合のリスク
3. **`sudo`を無意識に多用する**
   - 誤操作の影響が大きくなる
4. **`chmod -R 777`で雑に解決する**
   - セキュリティ事故の温床
5. **`chown -R`対象を誤る**
   - システムファイル破壊に直結
6. **`rm -rf`を補完任せで実行する**
   - 取り返しがつかない

### 安全プラクティス

- 破壊的操作の前に **`echo` でdry-run**
- まずは **読み取り系コマンドで現状把握**（`ps`, `ss`, `journalctl`）
- root操作は最小限・手順化
- 変更前にバックアップ（設定ファイルはコピーしてから編集）
- `rm -rf` が必要なら対象パスを2回確認し、可能なら `trash` を使う

---

## 7) One interview-style question

**質問:**  
本番サーバーでCPU使用率が急上昇したと報告がありました。あなたなら最初の10分でどのコマンドをどの順で実行し、何を根拠に次のアクション（監視継続・優先度調整・プロセス停止・サービス再起動）を決めますか？

---

## 8) Next-step resources

- `man ps`, `man top`, `man journalctl`, `man systemctl`, `man ss`
- Linux Foundation (LFS201系) の運用基礎
- 「UNIX and Linux System Administration Handbook」
- 練習: `systemd` サービスを自作し、障害注入→ログ解析→復旧を1サイクル実施

---

次号予告（学習アーク継続）:  
**「ファイル権限と所有者管理（事故らない chmod/chown 実践）」**  
Beginner→Middle→Advancedで、権限設計と安全運用を深掘りします。
