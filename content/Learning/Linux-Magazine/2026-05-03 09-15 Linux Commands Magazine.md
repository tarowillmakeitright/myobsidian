---
tags: [linux, commands, learning, devops, daily]
---

# Daily Linux Commands Magazine - 2026-05-03
[[Home]]

## 1) 今日の1コマンド（command name + one-line summary）
**`ss`** — TCP/UDPソケット（待受/接続中）を高速に可視化し、通信トラブルを切り分ける標準コマンド。

## 2) 実務で使う場面（2-4 concrete scenarios）
- アプリが「ポート使用中」で起動失敗したとき、どのプロセスが占有しているか確認する。
- 本番障害で「接続タイムアウト」が出たとき、サーバー側でLISTEN状態を確認する。
- DBやAPIへの大量接続で詰まりが疑われるとき、接続数をざっくり把握する。
- ファイアウォール変更後に、期待ポートで待受しているか即確認する。

## 3) よく使うオプション（at least 3 options with explanation）
- `-t` : TCPのみ表示。
- `-u` : UDPのみ表示。
- `-l` : LISTEN（待受中）ソケットのみ表示。
- `-n` : 名前解決しない（高速・誤解減）。
- `-p` : ソケットを掴んでいるプロセス情報を表示（要権限）。
- `-a` : LISTEN以外も含む全状態を表示。

## 4) 実例コマンド（at least 5 examples, copy-paste ready）
```bash
# 1) 待受中のTCPポートを確認（運用で最頻出）
ss -tln

# 2) プロセス名込みで待受確認（sudo推奨）
sudo ss -tlnp

# 3) 443番ポートを掴んでいるプロセスを特定
sudo ss -tlnp | grep ':443 '

# 4) 全TCP接続を状態つきで確認（ESTAB/WAIT系の把握）
ss -tan

# 5) nginx関連の接続だけを見る
sudo ss -tanp | grep nginx

# 6) UDP待受ポートを確認（DNS/監視エージェント調査など）
ss -uln
```

## 5) よくあるミスと安全ポイント
- `-p` は権限不足だとプロセス情報が欠ける。調査時は `sudo` 前提で確認。
- `-n` なしだと名前解決で遅くなり、障害初動に不利。
- `grep 80` のような曖昧検索は誤検知しやすい。`':80 '` のように区切って検索する。
- `ss` は参照系で安全だが、結果を根拠にkillする前に `systemctl status` 等で二重確認する。

## 6) 追加学習（manページの読みどころ or related command）
- `man ss` の **"STATE-FILTER"** と **"FILTER"** セクションを読むと、条件指定調査が一気に速くなる。
- 関連コマンド: `ip`（経路/IF確認）、`lsof -i`（ソケットとファイルの対応確認）。
