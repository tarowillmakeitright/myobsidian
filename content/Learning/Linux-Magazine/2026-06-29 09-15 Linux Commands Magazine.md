---
tags:
  - linux
  - commands
  - learning
  - devops
  - daily
---

[[Home]]

# Linux Commands Magazine — 2026-06-29 09:15

## 1) 今日の1コマンド（command name + one-line summary）
`ip` — Linuxのネットワーク設定・経路・アドレス状態を確認する現場向け標準コマンド。

## 2) 実務で使う場面（2-4 concrete scenarios）
- サーバーにIPが正しく付与されているか確認するとき
- 通信できない原因が、経路・NICダウン・アドレス設定ミスのどれか切り分けるとき
- VPNやコンテナ追加後にルーティングがどう変わったか確認するとき
- 監視アラート後に、対象ホストのネットワーク状態をSSHで即確認するとき

## 3) よく使うオプション（at least 3 options with explanation）
- `-br` — brief形式。一覧を短く見やすく表示
- `-c` — 状態に色を付ける。対話確認向き
- `-4` — IPv4だけ表示する
- `addr` — IPアドレス情報を表示するサブコマンド
- `route` — ルーティングテーブルを表示するサブコマンド

## 4) 実例コマンド（at least 5 examples, copy-paste ready）
```bash
ip -br addr
ip -4 -br addr
ip -br link
ip route
ip route get 8.8.8.8
ip -s link show eth0
```

## 5) よくあるミスと安全ポイント
- `ifconfig` 前提で考えると情報が足りない。今はまず `ip addr` / `ip route` を基準にすると安定
- `ip link` はNICのUP/DOWN確認、`ip addr` はアドレス確認、`ip route` は経路確認。役割を分けて見ると切り分けが速い
- `ip addr add` や `ip link set down` は変更系。今日は確認系だけを使う意識だと安全
- NIC名は `eth0` 固定とは限らない。まず `ip -br link` で正式名を確認する

## 6) 追加学習（manページの読みどころ or related command）
- `man ip` は長いので、まず `ADDRESS`, `LINK`, `ROUTE` 周辺を読むと実務で効く
- 関連コマンド: `ss`, `ping`, `traceroute`, `nmcli`

#linux #commands #learning #devops #daily
