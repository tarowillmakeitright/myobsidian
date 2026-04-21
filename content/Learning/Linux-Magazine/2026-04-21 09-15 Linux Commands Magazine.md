---
tags: [linux, commands, learning, devops, daily]
---

# 2026-04-21 09:15 Linux Commands Magazine
[[Home]]

#linux #commands #learning #devops #daily

## 1) 今日の1コマンド（command name + one-line summary）
**`ss`** — ソケット/ポートの状態を高速に確認し、通信トラブルを切り分けるための定番コマンド。

## 2) 実務で使う場面（2-4 concrete scenarios）
- アプリが「起動したのに接続できない」とき、想定ポートでLISTENしているか確認する
- 本番障害で、どのクライアントIPから大量接続が来ているかを即時確認する
- デプロイ後に、特定プロセスがどのポートを掴んでいるかを検証する
- FW/NAT変更後に、TCPセッションが確立済みかをざっと把握する

## 3) よく使うオプション（at least 3 options with explanation）
- `-l` : LISTEN中ソケットのみ表示（待受確認に最適）
- `-t` : TCPのみ表示
- `-u` : UDPのみ表示
- `-n` : 名前解決せず数値表示（高速・誤解防止）
- `-p` : ソケットを使うプロセス情報も表示（要権限）
- `-a` : LISTEN以外も含め全状態を表示

## 4) 実例コマンド（at least 5 examples, copy-paste ready）
```bash
# 1) 待受中のTCPポートを確認（運用で最頻出）
ss -ltn

# 2) Nginx想定の443番を掴んでいるプロセス確認
sudo ss -ltnp '( sport = :443 )'

# 3) 5432(PostgreSQL)への接続状態を確認
ss -tn '( dport = :5432 )'

# 4) UDP待受（DNSなど）を確認
ss -lun

# 5) 特定ホストとのHTTPS通信だけ抽出
ss -tn '( dst 203.0.113.10 and dport = :443 )'

# 6) 全ソケットを要約表示（件数確認向け）
ss -s
```

## 5) よくあるミスと安全ポイント
- `netstat`前提で遅い/情報不足になる
  - 現場では `ss` を優先（iproute2系で高速）
- 名前解決ありで表示が遅くなる
  - 障害時はまず `-n` を付ける
- `-p` でプロセスが見えない
  - 権限不足の可能性。必要時のみ `sudo` を使う
- フィルタ条件の括弧をシェルに解釈される
  - `'( ... )'` のようにクォートして実行する

## 6) 追加学習（manページの読みどころ or related command）
- `man ss` の **FILTER** セクションを読むと、`sport/dport/src/dst/state` 条件を実戦投入しやすい
- 関連コマンド: `ip`（経路/IF確認）, `lsof -i`（ファイル視点での通信確認）
