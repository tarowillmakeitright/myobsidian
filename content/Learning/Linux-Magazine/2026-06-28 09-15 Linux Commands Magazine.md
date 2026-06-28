---
tags:
  - linux
  - commands
  - learning
  - devops
  - daily
---

[[Home]]

# Linux Commands Magazine — 2026-06-28 09:15

## 1) 今日の1コマンド（command name + one-line summary）
`ps` — 実行中プロセスの状態・親子関係・CPU/メモリ使用量を確認する基本コマンド。

## 2) 実務で使う場面（2-4 concrete scenarios）
- アプリが重いときに、どのプロセスが CPU やメモリを食っているか確認する
- デプロイ後に、想定したプロセスが起動しているか・多重起動していないか確認する
- `systemd` やシェルスクリプトから起動した子プロセスの親子関係を追う
- 障害調査で PID を特定し、`kill` / `strace` / `lsof` など次の調査につなげる

## 3) よく使うオプション（at least 3 options with explanation）
- `-e` — 全プロセスを表示する
- `-f` — 親 PID や起動コマンドを含む詳細形式で表示する
- `-o` — 表示列を指定する。必要な情報だけ見たいときに便利
- `--sort=-%cpu` — CPU 使用率の高い順に並べる
- `--sort=-rss` — メモリ使用量の多い順に並べる

## 4) 実例コマンド（at least 5 examples, copy-paste ready）
```bash
ps -ef
ps -ef | grep nginx
ps -eo pid,ppid,cmd,%cpu,%mem --sort=-%cpu | head
ps -eo pid,ppid,cmd,rss --sort=-rss | head
ps -fp 1234
ps -C sshd -o pid,ppid,user,%cpu,%mem,cmd
```

## 5) よくあるミスと安全ポイント
- `ps | grep app` は `grep` 自身も拾うことがある。必要なら `ps -C` や `grep '[a]pp'` を使う
- BSD 系と GNU 系でオプション流儀が少し違う。Linux ではまず `ps -ef` / `ps -eo ...` を基準にすると安定
- `ps` は状態確認だけで何も止めないが、表示した PID をそのまま `kill` する前に親子関係とコマンド名を再確認する
- メモリ列の `RSS` は「実メモリ使用量」で、仮想メモリ `VSZ` と意味が違う

## 6) 追加学習（manページの読みどころ or related command）
- `man ps` では `STANDARD FORMAT SPECIFIERS` を読むと、`-o` で出せる列が一気に増える
- 関連コマンド: `top`, `pgrep`, `pstree`, `kill`, `lsof`

#linux #commands #learning #devops #daily
