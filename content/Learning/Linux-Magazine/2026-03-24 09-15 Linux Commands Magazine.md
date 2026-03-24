---
tags: [linux, commands, learning, devops, daily]
---

# Daily Linux Commands Magazine — 2026-03-24 09:15
[[Home]]

> 今日の学習アークは **Beginner → Middle → Advanced** の3段階です。  
> Middle/Advanced には前提条件を明記しています。  
> **安全第一**で進め、破壊的コマンドは必ず検証用環境でのみ実行してください。

---

## 1) Topic + Level

### Beginner: ファイル探索と内容確認の基本（`pwd`, `ls`, `cd`, `cat`, `less`, `head`, `tail`）

### Middle: ログ調査とフィルタリング（`grep`, `find`, `xargs`, `wc`, `sort`, `uniq`）
**前提条件:**
- Beginner レベルのコマンドでディレクトリ移動・ファイル閲覧ができる
- 標準入力/標準出力の概念をざっくり理解している

### Advanced: 安全な権限管理と運用時の防御的オペレーション（`chmod`, `chown`, `sudo`, `stat`, `id`, `umask`）
**前提条件:**
- Middle レベルの検索・抽出・パイプ処理ができる
- Linux のユーザー/グループの基本概念を理解している

---

## 2) Why it matters in real projects

- **Beginner**: サーバー上で「今どこにいるか」「何があるか」「どんな中身か」を素早く把握できると、障害対応やデプロイ確認の初動が速くなります。
- **Middle**: 本番障害では「大量ログから必要情報だけを抜く」能力が重要です。調査時間短縮が復旧時間短縮に直結します。
- **Advanced**: 権限設定ミスはインシデントの温床です。最小権限・誤操作防止を実践できると、運用事故を減らせます。

---

## 3) Core command explanations

### Beginner Core
- `pwd`: 現在の作業ディレクトリを表示
- `ls -la`: 隠しファイル含め詳細表示（権限・所有者・更新時刻）
- `cd <dir>`: ディレクトリ移動
- `cat <file>`: ファイル内容を一気に表示（巨大ファイルには不向き）
- `less <file>`: ページング表示（`/keyword` で検索）
- `head -n 20 <file>` / `tail -n 20 <file>`: 先頭/末尾行を確認

### Middle Core
- `grep "ERROR" app.log`: 特定文字列を抽出
- `grep -R "timeout" ./logs`: ディレクトリ配下を再帰検索
- `find ./logs -type f -name "*.log"`: 条件に合うファイル探索
- `wc -l app.log`: 行数カウント
- `sort | uniq -c | sort -nr`: 重複件数を多い順で可視化
- `xargs`: 標準入力を引数として次コマンドへ渡す（空白含むパスは `-print0` + `xargs -0` を推奨）

### Advanced Core
- `stat <file>`: 詳細メタ情報（権限・UID/GID・時刻）確認
- `id`: 現在ユーザーの UID/GID と所属グループ確認
- `chmod 640 file`: 所有者 rw、グループ r、その他なし
- `chown user:group file`: 所有者/グループ変更
- `umask 027`: 新規作成ファイルのデフォルト権限を制御
- `sudo -l`: 実行可能な sudo 権限を確認

⚠️ **重要警告（破壊的パターン）**
- `rm -rf` は取り消し困難。実行前に `pwd` と `ls` で対象確認。
- `chmod -R` / `chown -R` は影響範囲が広い。必ずテストディレクトリで検証後に実施。
- `sudo` は最小限利用。コマンド意味を理解せずに実行しない。

---

## 4) 30-60 minute hands-on mini lab

### 目標
疑似ログ環境を作り、調査〜権限保護までを一連で体験する。

### 所要時間
約45分

### 手順

1. **検証用ディレクトリ作成（安全な練習場）**
```bash
mkdir -p ~/linux-mag-lab/{logs,archive}
cd ~/linux-mag-lab
pwd
```

2. **サンプルログを作成**
```bash
cat > logs/app.log <<'EOF'
2026-03-24T09:00:01 INFO  Service started
2026-03-24T09:01:12 WARN  Slow query detected
2026-03-24T09:02:33 ERROR DB timeout
2026-03-24T09:03:10 INFO  Retry success
2026-03-24T09:04:21 ERROR API timeout
EOF
```

3. **Beginner操作で確認**
```bash
ls -la logs
head -n 3 logs/app.log
tail -n 2 logs/app.log
less logs/app.log
```

4. **Middle操作で調査**
```bash
grep "ERROR" logs/app.log
grep "timeout" logs/app.log | wc -l
grep -E "ERROR|WARN" logs/app.log | sort
```

5. **集計を作る**
```bash
awk '{print $3}' logs/app.log | sort | uniq -c | sort -nr
```

6. **Advanced操作で権限を安全化**
```bash
stat logs/app.log
chmod 640 logs/app.log
ls -l logs/app.log
umask
```

7. **振り返り**
- ERROR件数は何件か？
- timeout はどのレイヤーで発生しているか？
- 権限は最小化できているか？

> 注意: このラボでは **`rm -rf` は使用しない**。削除する場合は対象を `ls` で確認してから通常 `rm` を使う。

---

## 5) Command cheatsheet

```bash
# 現在地・一覧
pwd
ls -la

# 内容確認
head -n 20 file
tail -n 20 file
less file

# 検索
find . -type f -name "*.log"
grep -R "ERROR" ./logs

# 集計
grep "ERROR" app.log | wc -l
awk '{print $3}' app.log | sort | uniq -c | sort -nr

# 権限
id
stat file
chmod 640 file
chown user:group file
umask 027

# sudo確認
sudo -l
```

---

## 6) Common mistakes and safe practices

**よくあるミス**
- `cd` 後に場所確認せず操作して別ディレクトリを変更
- `grep -R` をルート近くで実行し、不要に時間を浪費
- `chmod 777` を安易に使う
- `sudo` を常用し、誤操作時の被害を拡大

**安全プラクティス**
- 破壊前チェック: `pwd` → `ls` → 実行
- まず読み取り専用調査（`ls`, `cat`, `less`, `grep`）から始める
- 権限は最小限（例: 640/750 を基準に検討）
- 本番前に検証環境で手順を再現
- 履歴を残す（実行コマンドをメモ）

---

## 7) One interview-style question

**質問:**  
本番サーバーで API 遅延が報告され、`/var/log/app/` 配下に多数のログがあります。  
あなたは最初の10分でどのコマンドをどの順に実行し、どんな根拠で原因候補を絞りますか？  
（安全性と再現性も説明してください）

---

## 8) Next-step resources

- `man bash`, `man grep`, `man find`, `man chmod`, `man chown`
- The Linux Command Line (William Shotts)
- Linux Foundation Training (LFCS 系の学習パス)
- 実環境に近い練習: Docker コンテナでログ調査演習を自動化

---

**明日の予告（次の学習アーク）**  
プロセス監視（Beginner: `ps/top` → Middle: `ss/lsof` → Advanced: `systemctl/journalctl`）を扱います。