---
tags:
  - linux
  - commands
  - learning
  - devops
  - daily
---

# 2026-04-07 09:15 Linux Commands Magazine
[[Home]]

今日のテーマは、実務で毎日使う「**ログ調査と安全な運用コマンド**」です。  
学習アークは **Beginner → Middle → Advanced** の順で進めます。

---

## Arc 1) Topic + Level
**Topic:** ログ確認の基本（`ls`, `cat`, `less`, `tail`, `grep`）  
**Level:** Beginner

## Arc 1) Why it matters in real projects
本番障害の初動では、まず「何が起きたか」をログで事実確認します。  
アプリ開発・SRE・運用保守のどの職種でも、ログを早く安全に読めることは必須です。

## Arc 1) Core command explanations
- `ls -lah` : ファイル一覧を人間向けサイズで表示
- `less /var/log/syslog` : 大きいログをページ送りで安全に閲覧
- `tail -n 100 app.log` : 末尾100行だけ確認
- `tail -f app.log` : ログ追尾（Ctrl+C で停止）
- `grep "ERROR" app.log` : エラー行を抽出
- `grep -n "timeout" app.log` : 行番号付き検索

## Arc 1) 30-60 minute hands-on mini lab
1. 作業ディレクトリ作成: `mkdir -p ~/lab/logs && cd ~/lab/logs`
2. サンプルログ作成:
   - `printf "INFO start\nERROR db timeout\nINFO retry\n" > app.log`
3. `less app.log` で閲覧
4. `grep "ERROR" app.log` で抽出
5. 別ターミナルで `tail -f app.log` 実行
6. 元ターミナルで `echo "ERROR cache miss" >> app.log` を追加し、追尾で確認

## Arc 1) Command cheatsheet
- 閲覧: `less file.log`
- 末尾確認: `tail -n 50 file.log`
- 追尾: `tail -f file.log`
- 検索: `grep "keyword" file.log`
- 件数: `grep -c "ERROR" file.log`

## Arc 1) Common mistakes and safe practices
- `cat` で巨大ログ全表示 → 端末が見づらくなる。**`less` を優先**。
- root権限でむやみに閲覧しない。**必要最小限で `sudo` 使用**。
- ログ改変禁止。調査時は原本維持（コピーして検証）。

## Arc 1) One interview-style question
「`tail -f` と `less +F` の使い分けを、運用現場の例で説明してください。」

## Arc 1) Next-step resources
- `man tail`
- `man grep`
- `man less`

---

## Arc 2) Topic + Level
**Topic:** プロセスとリソース調査（`ps`, `top`, `htop`, `pgrep`, `kill`）  
**Level:** Middle  
**Prerequisites:** Arc 1 のログ閲覧・検索ができること

## Arc 2) Why it matters in real projects
「重い」「落ちる」「応答しない」問題では、プロセス状態とCPU/メモリ利用確認が最短ルートです。

## Arc 2) Core command explanations
- `ps aux | grep nginx` : 対象プロセスの確認
- `pgrep -af python` : コマンドライン付きでPID検索
- `top` / `htop` : リソース高負荷プロセスの可視化
- `kill -15 <PID>` : 正常終了依頼（SIGTERM）
- `kill -9 <PID>` : 最終手段（SIGKILL）

## Arc 2) 30-60 minute hands-on mini lab
1. 疑似ワークロード起動: `yes > /dev/null &`
2. PID確認: `pgrep -af yes`
3. `top` でCPU使用率確認
4. 安全停止: `kill -15 <PID>`
5. 止まらない場合のみ `kill -9 <PID>`（実験環境限定）
6. 停止確認: `pgrep yes` が空になること

## Arc 2) Command cheatsheet
- 全体確認: `top`
- 絞り込み: `ps aux | grep <name>`
- PID検索: `pgrep -af <name>`
- 正常停止: `kill -15 <PID>`
- 強制停止: `kill -9 <PID>`

## Arc 2) Common mistakes and safe practices
- いきなり `kill -9` はNG。**まず `-15`**。
- PID取り違えは重大事故。`pgrep -af` で実コマンドを再確認。
- `sudo kill` は影響範囲大。対象プロセスを二重確認。

## Arc 2) One interview-style question
「本番でCPU 100%のプロセスを見つけたとき、`kill -9` 以外に先に取るべき対応は？」

## Arc 2) Next-step resources
- `man ps`
- `man kill`
- `man top`

---

## Arc 3) Topic + Level
**Topic:** 権限・所有者・安全なファイル操作（`chmod`, `chown`, `find`, `xargs`）  
**Level:** Advanced  
**Prerequisites:** Arc 1-2 完了、Linux 権限（rwx）とユーザー/グループの基本理解

## Arc 3) Why it matters in real projects
権限ミスは「動かない」「漏れる」「消える」の原因です。デプロイ失敗やセキュリティ事故を防ぐ要です。

## Arc 3) Core command explanations
- `ls -l` : パーミッションと所有者確認
- `chmod 640 file` : 最小権限に調整
- `chown user:group file` : 所有者変更
- `find . -type f -name "*.log"` : 条件一致ファイル探索
- `find ... -print0 | xargs -0 ...` : 空白入りファイル名を安全処理

## Arc 3) 30-60 minute hands-on mini lab
1. 検証用ディレクトリ: `mkdir -p ~/lab/perm && cd ~/lab/perm`
2. ファイル作成: `touch app.log secret.txt`
3. 権限確認: `ls -l`
4. `chmod 600 secret.txt` で秘匿ファイル化
5. `find . -type f -print0 | xargs -0 ls -l` で安全列挙
6. （任意）`stat secret.txt` で詳細確認

## Arc 3) Command cheatsheet
- 権限確認: `ls -l`
- 変更: `chmod 644 file`
- 所有者: `chown user:group file`
- 安全検索: `find . -type f -print0`
- 安全連携: `xargs -0`

## Arc 3) Common mistakes and safe practices
- **危険:** `chmod -R 777` は原則禁止（過剰権限）。
- **危険:** `chown -R` は対象パス誤りで広範囲破壊。実行前に `pwd` と対象を再確認。
- **危険:** `rm -rf` は破壊的。削除前に `ls` / `find` で対象確認、可能ならバックアップ。
- `sudo` は最後の手段。必要なコマンドだけ限定して使う。

## Arc 3) One interview-style question
「`chmod 755` と `chmod 644` の違いを、実行ファイルと設定ファイルの運用例で説明してください。」

## Arc 3) Next-step resources
- `man chmod`
- `man chown`
- `man find`
- Linux Foundation: File Permissions 基礎教材

---

### 今日の一言
実務で強い人は、「速く打てる人」ではなく **安全に再現できる手順を持つ人** です。まず確認、次に実行、最後に検証。