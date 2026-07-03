---
tags:
  - linux
  - commands
  - learning
  - devops
  - daily
links:
  - "[[Home]]"
---

# Linux Commands Magazine

#linux #commands #learning #devops #daily
[[Home]]

1) 今日の1コマンド
`ss` — ソケット・待受ポート・接続状態を高速に確認するネットワーク調査コマンド。

2) 実務で使う場面
- Webサーバーが本当に `:80` / `:443` で待ち受けているか確認するとき
- 「このポート誰が掴んでる？」を調べて競合原因を切り分けるとき
- 障害調査で ESTAB / TIME-WAIT / LISTEN の状況をざっと見たいとき
- コンテナ・VM・本番サーバーで `netstat` の代わりに素早く接続状況を見たいとき

3) よく使うオプション
- `-t` — TCPだけ表示
- `-u` — UDPだけ表示
- `-l` — LISTEN中のソケットだけ表示
- `-n` — 名前解決せず数値のまま表示。調査時はほぼ必須
- `-p` — プロセス名/PIDも表示
- `-a` — LISTENだけでなく全状態を表示

4) 実例コマンド
```bash
ss -tuln
ss -tlpn
ss -tunp
ss -ltn 'sport = :443'
ss -tp state established '( dport = :443 or sport = :443 )'
ss -ltnp | grep ':3000'
```

5) よくあるミスと安全ポイント
- `-n` なしで実行すると名前解決で見づらくなり、調査が遅くなりがち
- `-p` は権限不足だとPID/プロセス名が見えないことがある。必要なら `sudo` を使う
- `LISTEN` だけ見たいのに `-l` を付け忘れると出力が多すぎて判断しづらい
- `grep 443` だけだと意図しない行も拾う。必要なら `sport = :443` の条件式を使う

6) 追加学習
- まず `man ss` の **FILTER** セクションを見ると、`sport` / `dport` / `state` の絞り込みが一気に使いやすくなる
- 関連コマンド: `ip`（経路・NIC確認）、`lsof -i`（ポートを掴むプロセス確認）
