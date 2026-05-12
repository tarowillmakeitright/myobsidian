# Linux Commands Magazine — 2026-05-12 09:15
Tags: #linux #commands #learning #devops #daily
Links: [[Home]]

## 1) 今日の1コマンド（command name + one-line summary）
**`ss`** — サーバの待受ポート・接続状況を高速に確認し、通信トラブルを切り分けるコマンド。

## 2) 実務で使う場面（2-4 concrete scenarios）
- 新規デプロイ後、アプリが正しいポートで待受しているか確認する。
- 「接続できない」障害で、LISTEN状態や接続数を即時確認する。
- 本番で不審な外向き接続や大量接続（輻輳）の有無を調べる。
- どのプロセスがポートを掴んでいるか特定し、ポート競合を解消する。

## 3) よく使うオプション（at least 3 options with explanation）
- `-l` : LISTEN中のソケットのみ表示。
- `-t` / `-u` : TCP / UDP に絞って表示。
- `-n` : 名前解決せず数値のまま表示（高速・誤解防止）。
- `-p` : ソケットを使っているプロセス情報を表示。
- `-s` : プロトコルごとの統計サマリーを表示。

## 4) 実例コマンド（at least 5 examples, copy-paste ready）
```bash
# 1) 待受中のTCPポートを数値表示で確認
ss -ltn

# 2) 待受中ポートとプロセス名を確認（要sudo）
sudo ss -ltnp

# 3) 443番ポートを使う接続だけ確認
ss -tn '( sport = :443 or dport = :443 )'

# 4) ESTABLISHED接続だけ抽出して負荷状況を見る
ss -tn state established

# 5) UDPの待受状況を確認
ss -lun

# 6) プロトコル統計をざっくり確認
ss -s
```

## 5) よくあるミスと安全ポイント
- **`netstat`前提の古い手順をそのまま使う**: 現行Linuxでは `ss` を優先すると高速で情報量も多い。
- **名前解決ありで遅くなる/見間違える**: 調査時はまず `-n` を付ける。
- **プロセス情報が見えない**: `-p` は権限制限があるため必要に応じて `sudo` を使う。
- **確認だけで済ませる**: 異常を見つけたら、`journalctl` やFW設定確認に必ずつなげる。

## 6) 追加学習（manページの読みどころ or related command）
- `man ss` の **STATE FILTER** と **EXPRESSION**（`sport`/`dport` 条件）を読むと、障害対応の速度が上がる。
- 関連コマンド: `ip`, `lsof -i`, `journalctl`。
