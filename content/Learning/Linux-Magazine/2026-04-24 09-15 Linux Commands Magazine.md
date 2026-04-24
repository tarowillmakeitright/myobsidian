---
tags: [linux, commands, learning, devops, daily]
---

# 2026-04-24 09:15 Linux Commands Magazine
[[Home]]

#linux #commands #learning #devops #daily

## 1) 今日の1コマンド（command name + one-line summary）
**`ip`** — Linuxのネットワーク設定・状態確認（IP/ルート/リンク）を一元管理する標準コマンド。

## 2) 実務で使う場面（2-4 concrete scenarios）
- サーバが「外に出られない」ときに、IPアドレス・デフォルトGW・ルートを即確認する
- 障害対応で、どのNICが `UP/DOWN` か、リンク断か設定ミスかを切り分ける
- コンテナ/VMホストで、インターフェースやポリシールーティングの反映状況を検証する
- デプロイ後の疎通確認で、送信元IPや経路（どのIFを通るか）を確認する

## 3) よく使うオプション（at least 3 options with explanation）
- `-br` : 省略表示（brief）。一覧を短く見やすく表示（運用で最速確認向け）
- `-4` : IPv4のみ表示（IPv6情報を除外してノイズ削減）
- `-6` : IPv6のみ表示（IPv6障害の切り分けで必須）
- `-c` : 色付き表示（端末上で状態を視認しやすい）
- `-j` : JSON出力（スクリプト処理・自動化向け）

## 4) 実例コマンド（at least 5 examples, copy-paste ready）
```bash
# 1) インターフェース状態をざっと確認
ip -br link

# 2) IPv4アドレス一覧を確認
ip -4 -br addr

# 3) デフォルトルートと経路テーブルを確認
ip route show

# 4) 8.8.8.8 への実際の経路・送信元IPを確認
ip route get 8.8.8.8

# 5) 特定NIC（例: eth0）の詳細確認
ip addr show dev eth0

# 6) JSONで取得して jq でUPなIFだけ抽出
ip -j link show | jq '.[] | select(.operstate=="UP") | {ifname, operstate, mtu}'
```

## 5) よくあるミスと安全ポイント
- `ifconfig` / `route` 前提で調べ続ける：現行Linuxでは `ip` を基準にする方が情報が揃う
- 一時設定と永続設定を混同する：`ip addr add` などは再起動で消える（恒久化は NetworkManager/systemd-networkd 側で実施）
- リモート接続中に設定変更する：SSH中に `ip link set ... down` やルート変更をすると自分を切断しやすい。事前に復旧手段（コンソール/KVM）を確保する

## 6) 追加学習（manページの読みどころ or related command）
- まず `man ip` の **OBJECT** セクション（`link` / `address` / `route` / `rule`）を読むと全体像を掴みやすい
- 関連コマンド: `ss`（ソケット確認）、`nmcli`（NetworkManager管理環境での永続設定）
