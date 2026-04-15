---
tags: [linux, commands, learning, devops, daily]
---

# 2026-04-15 09:15 Linux Commands Magazine
[[Home]]

#linux #commands #learning #devops #daily

## 1) 今日の1コマンド（command name + one-line summary）
**`lsof`** — 「どのプロセスが、どのファイル/ポートを掴んでいるか」を特定する調査コマンド。

## 2) 実務で使う場面（2-4 concrete scenarios）
- デプロイ時に「ポート 3000/8080 が既に使用中」で起動失敗した原因プロセスを特定するとき
- ログローテート後もディスク使用量が減らない（削除済みファイルをプロセスが掴み続ける）問題を調べるとき
- アプリ停止前に、特定ディレクトリ配下のファイルをどのプロセスが使っているか確認するとき
- 障害対応で「この接続を張っているPIDは何か」を短時間で確認したいとき

## 3) よく使うオプション（at least 3 options with explanation）
- `-i` : ネットワーク関連（ソケット）を表示。`-i :443` のようにポート指定も可能
- `-p <PID>` : 指定PIDが開いているファイル/ソケットだけ表示
- `-u <user>` : 指定ユーザーのプロセスに絞る（例: `-u nginx`）
- `+D <dir>` : 指定ディレクトリ配下を再帰的に調査（重いので範囲は狭く）
- `-n -P` : ホスト名/サービス名の名前解決を無効化（高速・誤解減）

## 4) 実例コマンド（at least 5 examples, copy-paste ready）
```bash
# 1) 443番ポートを使っているプロセスを確認（初動で便利）
sudo lsof -nP -i :443

# 2) LISTEN中のTCPポート一覧を確認
sudo lsof -nP -iTCP -sTCP:LISTEN

# 3) 特定PID（例: 1234）が掴んでいるものを確認
lsof -p 1234

# 4) /var/log 配下を掴んでいるプロセスを調査（ログローテート問題向け）
sudo lsof +D /var/log

# 5) 削除済みなのに開かれたままのファイルを確認（容量逼迫調査）
sudo lsof -nP | grep '(deleted)'

# 6) nginxユーザーのネットワーク接続だけ確認
sudo lsof -nP -u nginx -i
```

## 5) よくあるミスと安全ポイント
- **ミス:** `lsof +D /` のように広すぎる範囲で実行して重くする
  - **安全:** `+D` は対象を絞る（例: `/var/log` やアプリの作業ディレクトリ）
- **ミス:** 名前解決ありで遅く、調査が進まない
  - **安全:** 初動は `-n -P` を付ける
- **ミス:** `(deleted)` を見つけてもすぐ kill してしまう
  - **安全:** まずサービス影響を確認し、可能なら計画的に再起動して解放する

## 6) 追加学習（manページの読みどころ or related command）
- `man lsof` の **OUTPUT FOR OTHER PROGRAMS** と **EXAMPLES** を読むと、調査スクリプト化の精度が上がる
- 関連コマンド: `ss`（接続状態確認）、`fuser`（ファイル/ポート利用プロセス特定）
