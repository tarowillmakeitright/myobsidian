---
tags: [linux, commands, learning, devops, daily]
---

# Daily Linux Commands Magazine - 2026-05-08
[[Home]]

## 1) 今日の1コマンド（command name + one-line summary）
**`ss`** — TCP/UDPソケットの状態を高速に可視化し、通信トラブルの切り分けを行う標準コマンド。

## 2) 実務で使う場面（2-4 concrete scenarios）
- Webサーバ障害時に、`LISTEN` 状態で想定ポート（例: 80/443）が開いているか確認する。
- API遅延時に、`ESTAB`（確立済み接続）数や接続先を確認して過負荷を疑う。
- デプロイ後に「アプリがどのアドレスで待受しているか（127.0.0.1のみ/0.0.0.0）」を確認する。
- セキュリティ点検で、不要な待受ポートとプロセスを特定する。

## 3) よく使うオプション（at least 3 options with explanation）
- `-l` : 待受中（LISTEN）のソケットだけ表示。
- `-t` : TCPのみ表示。
- `-u` : UDPのみ表示。
- `-n` : 名前解決を無効化（IP/ポートを数値表示）して高速・正確に確認。
- `-p` : ソケットを使っているプロセス情報（PID/コマンド）を表示。
- `-s` : ソケット統計サマリを表示（全体傾向を素早く把握）。

## 4) 実例コマンド（at least 5 examples, copy-paste ready）
```bash
# 1) 待受ポートをTCP限定で確認（名前解決なし）
ss -ltn

# 2) 待受ポート + プロセスを確認（要権限）
sudo ss -ltnp

# 3) 443番ポートの待受有無を確認
ss -ltn '( sport = :443 )'

# 4) 確立済みTCP接続のみ確認（外向き通信の把握）
ss -tn state established

# 5) 特定宛先への接続状況を確認（例: DBサーバ 10.0.0.20:5432）
ss -tn '( dst 10.0.0.20 and dport = :5432 )'

# 6) 全体統計を確認（大量接続の兆候チェック）
ss -s
```

## 5) よくあるミスと安全ポイント
- `-p` でプロセス情報が見えない場合は権限不足が多い。`sudo` で再確認する。
- 名前解決あり（`-n`なし）だと表示が遅くなり、調査テンポが落ちる。
- `LISTEN` と `ESTAB` を混同しない。待受確認は `-l`、通信量確認は `state established` を使い分ける。
- まず `ss -ltnp` で「開いているか」を確定してからFW/ACL調査へ進むと切り分けが速い。

## 6) 追加学習（manページの読みどころ or related command）
- `man ss` の **FILTER** セクション（`sport`/`dport`/`dst`/`state` 条件式）が実務で最重要。
- 関連コマンド: `ip`（経路/IF確認）、`lsof -i`（ファイル視点での通信確認）、`nft`/`iptables`（フィルタ確認）。
