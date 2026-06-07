# Linux Commands Magazine — 2026-06-02 09:15
Tags: #linux #commands #learning #devops #daily
Links: [[Home]]

## 1) 今日の1コマンド（command name + one-line summary）
**`ip`** — ネットワーク設定・状態確認（IP/ルート/リンク）を1本で扱える、実務必須コマンド。

## 2) 実務で使う場面（2-4 concrete scenarios）
- **障害一次対応**: サーバが疎通しない時に、IPアドレス/IF状態/ルーティングを即確認。
- **クラウド運用**: 新規VM起動後、想定NICに正しいアドレスが付与されているか検証。
- **VPN・踏み台経由の不達調査**: どの経路へ出ていくか（default route）を確認。
- **コンテナ/名前空間調査**: ホスト側IFやルートの差分確認の基礎として使用。

## 3) よく使うオプション（at least 3 options with explanation）
- `-br` : brief表示。要点だけ短く見られる（監視・確認向き）。
- `-c` : 出力を色付きにして視認性向上。
- `-4` : IPv4だけ表示（IPv6混在時のノイズ削減）。
- `-6` : IPv6だけ表示。
- `-s` : 統計情報も表示（ドロップ/エラー確認に有効）。

## 4) 実例コマンド（at least 5 examples, copy-paste ready）
```bash
# 1) インターフェース状態を簡潔に確認
ip -br link

# 2) IPv4アドレス一覧を確認
ip -4 -br addr

# 3) ルーティングテーブル確認（default route含む）
ip route

# 4) 8.8.8.8 への実際の送信経路を確認
ip route get 8.8.8.8

# 5) ens3 の詳細統計（エラー/ドロップ）を確認
ip -s link show dev ens3

# 6) ens3 を一時的に down/up（作業時のみ）
sudo ip link set dev ens3 down
sudo ip link set dev ens3 up
```

## 5) よくあるミスと安全ポイント
- `ip link set ... down` をリモート環境で実行すると、自分のSSHが切断される可能性あり。**作業前に復旧手段（コンソール）を確保**する。
- 変更は即時反映されるが、通常は**永続化されない**。恒久対応は NetworkManager/netplan/systemd-networkd 側も更新する。
- IF名（`ens3` など）を打ち間違えると意図しない影響。`ip -br link` で事前確認。

## 6) 追加学習（manページの読みどころ or related command）
- `man ip` の **OBJECT**（`link`, `addr`, `route`）と **EXAMPLES** を先に読むと実務で使いやすい。
- 関連: `ss`（通信状態）, `ping`（到達性）, `traceroute`（経路可視化）。
