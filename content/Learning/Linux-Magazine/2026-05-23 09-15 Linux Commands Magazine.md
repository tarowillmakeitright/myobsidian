# Linux Commands Magazine — 2026-05-23 09:15
Tags: #linux #commands #learning #devops #daily
Links: [[Home]]

## 1) 今日の1コマンド（command name + one-line summary）
**`ss`** — Linuxのソケット/通信状態を高速に確認できる、`netstat`の実務向け後継コマンド。

## 2) 実務で使う場面（2-4 concrete scenarios）
- **ポート競合の調査**: 「なぜ 8080 が使えない？」をPID付きで即確認する。
- **障害一次対応**: `ESTAB`/`TIME-WAIT` の増加を見て接続枯渇の兆候をつかむ。
- **公開ポート監査**: サーバーが外部待受しているポートを定期確認する。
- **アプリ単位の通信確認**: 特定プロセスがどの宛先へ接続しているかを追う。

## 3) よく使うオプション（at least 3 options with explanation）
- `-t` : TCPソケットのみ表示。
- `-u` : UDPソケットのみ表示。
- `-l` : LISTEN中（待受中）のみ表示。
- `-n` : 名前解決せず数値で表示（高速・誤解防止）。
- `-p` : プロセス情報（PID/コマンド名）を表示。
- `-s` : プロトコル統計サマリを表示。

## 4) 実例コマンド（at least 5 examples, copy-paste ready）
```bash
# 1) 待受中のTCPポートをPID付きで確認
ss -tlnp

# 2) 443番ポート関連の接続だけ確認（待受/確立含む）
ss -tnp '( sport = :443 or dport = :443 )'

# 3) 特定プロセス（nginx）の接続を確認
ss -tnp | grep nginx

# 4) ESTABLISHED接続だけを一覧（名前解決なし）
ss -tn state established

# 5) UDP待受ポートを確認
ss -ulnp

# 6) ソケット統計サマリを確認（障害切り分けの初手）
ss -s
```

## 5) よくあるミスと安全ポイント
- **`-p` で情報が出ない**: 一般ユーザーだと一部見えない。必要に応じて `sudo` で実行。
- **名前解決で遅い/見づらい**: 調査時は基本 `-n` を付ける。
- **フィルタ式の記法ミス**: 括弧と空白を含むため、`'( ... )'` のようにクォートする。
- **誤解しやすい状態**: `TIME-WAIT` 多発は即障害とは限らない。再現手順・負荷状況と合わせて判断する。

## 6) 追加学習（manページの読みどころ or related command）
- `man ss` の **“FILTER”** セクションを読むと、ポート/状態/アドレス条件の絞り込み精度が一気に上がる。
- 関連コマンド: `lsof -i`（プロセス起点で通信を見る）, `ip`（インターフェース/ルーティング確認）。
