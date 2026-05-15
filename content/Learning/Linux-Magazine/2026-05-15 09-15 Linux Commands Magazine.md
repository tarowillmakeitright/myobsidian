# Linux Commands Magazine — 2026-05-15 09:15
Tags: #linux #commands #learning #devops #daily
Links: [[Home]]

## 1) 今日の1コマンド（command name + one-line summary）
**`ss`** — TCP/UDPソケットの状態・待受ポート・接続先を高速に確認できる、障害対応の基本コマンド。

## 2) 実務で使う場面（2-4 concrete scenarios）
- アプリが起動しているのに疎通できない時、正しいポートでLISTENしているか確認する。
- 本番サーバでコネクション数急増時に、どの宛先/状態（ESTAB, TIME-WAIT）が増えているか切り分ける。
- デプロイ後に、想定外ポートが外部公開されていないか監査する。
- DB接続障害時に、アプリ→DBのTCP接続が張れているか即確認する。

## 3) よく使うオプション（at least 3 options with explanation）
- `-t` : TCPのみ表示。
- `-u` : UDPのみ表示。
- `-l` : LISTEN中ソケットのみ表示（待受確認に最重要）。
- `-n` : 名前解決せず数値で表示（高速・誤解が少ない）。
- `-p` : ソケットを使うプロセス情報を表示（要権限）。
- `-s` : ソケット統計サマリを表示（全体傾向の把握向け）。

## 4) 実例コマンド（at least 5 examples, copy-paste ready）
```bash
# 1) 待受中のTCPポートを確認（サービス起動確認）
ss -tln

# 2) プロセス名付きで待受ポート確認（要sudo推奨）
sudo ss -tlnp

# 3) 443番ポート関連だけ絞り込み
ss -tln '( sport = :443 )'

# 4) 現在の確立済みTCP接続を確認
ss -tn state established

# 5) 特定宛先DB(10.0.2.15:5432)への接続状態を確認
ss -tn '( dport = :5432 and dst = 10.0.2.15 )'

# 6) TCP/UDPの全体サマリを見る
ss -s
```

## 5) よくあるミスと安全ポイント
- **`-n` なしで遅い/見づらい:** DNS逆引きで遅延することがある。調査初手は `-n` を付ける。
- **`-p` で情報が出ない:** 権限不足が原因になりやすい。必要時は `sudo` を使う。
- **`netstat` 前提で読む癖:** `ss` は表示列が異なる。`State` と `Recv-Q/Send-Q` を先に見ると切り分けしやすい。
- **公開ポート確認の見落とし:** `0.0.0.0` / `::` 待受は外部公開の可能性。FW設定（`nftables`/`firewalld`）とセットで確認する。

## 6) 追加学習（manページの読みどころ or related command）
- `man ss` の **`FILTER`** セクション（`sport` / `dport` / `state` 条件式）が実務で特に有用。
- 関連コマンド: `lsof -i`（FD視点の確認）、`nft list ruleset`（通信許可ルール確認）。
