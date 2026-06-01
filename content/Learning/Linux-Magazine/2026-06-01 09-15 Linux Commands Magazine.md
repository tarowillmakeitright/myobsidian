# Linux Commands Magazine — 2026-06-01 09:15
Tags: #linux #commands #learning #devops #daily
Links: [[Home]]

## 1) 今日の1コマンド（command name + one-line summary）
**`ss`** — Linuxのソケット状態（待受ポート・接続元・プロセス）を高速に確認できる、障害対応の基本コマンド。

## 2) 実務で使う場面（2-4 concrete scenarios）
- **サービス疎通確認**: Web/APIが本当にポート待受しているかを即確認。
- **障害切り分け**: 接続数急増や `TIME-WAIT` 偏りを見て、通信異常を特定。
- **セキュリティ点検**: 想定外ポートのLISTENを検出して設定漏れを発見。
- **デプロイ後確認**: 新プロセスが正しいポートで起動したかを検証。

## 3) よく使うオプション（at least 3 options with explanation）
- `-l` : LISTEN（待受）ソケットのみ表示。
- `-t` : TCPのみ対象。
- `-u` : UDPのみ対象。
- `-n` : 名前解決せず数値表示（高速・誤解減）。
- `-p` : ソケットを掴んでいるプロセス情報を表示。
- `-s` : ソケット統計の要約を表示（全体傾向把握）。

## 4) 実例コマンド（at least 5 examples, copy-paste ready）
```bash
# 1) いま待受中のTCPポート一覧（数値表示）
ss -ltn

# 2) 待受ポートとプロセス名を同時確認（要sudo）
sudo ss -ltnp

# 3) 443番ポートを使う接続だけ抽出
ss -tn '( sport = :443 or dport = :443 )'

# 4) ESTABLISHED接続のみ確認（アプリ疎通チェック）
ss -tn state established

# 5) TCP状態別のサマリを確認
ss -s

# 6) 特定プロセス（nginx）関連ソケットを絞る
sudo ss -ltnp | grep nginx
```

## 5) よくあるミスと安全ポイント
- `netstat` 前提の見方をそのまま持ち込むと読み違える。`ss` の列（State/Recv-Q/Send-Q）を確認。
- `-p` は権限不足だとプロセス名が欠ける。調査時は `sudo` を使う。
- DNS逆引きで遅く見える場合があるので、まず `-n` を付ける。
- `grep` だけに頼らず、可能なら `state` や式フィルタで絞ると誤検出が減る。

## 6) 追加学習（manページの読みどころ or related command）
- `man ss` の **FILTER** 構文（`state`, `sport`, `dport`）を先に覚えると実務で強い。
- 関連: `lsof -i`（プロセス起点で通信確認）, `ip`（経路/IF確認）, `tcpdump`（パケット深掘り）。
