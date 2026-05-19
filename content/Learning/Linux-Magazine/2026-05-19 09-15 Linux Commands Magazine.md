# Linux Commands Magazine — 2026-05-19 09:15
Tags: #linux #commands #learning #devops #daily
Links: [[Home]]

## 1) 今日の1コマンド（command name + one-line summary）
**`ss`** — TCP/UDPソケット状態を高速に可視化し、通信トラブルを即切り分けできるコマンド。

## 2) 実務で使う場面（2-4 concrete scenarios）
- APIサーバで「ポートは開いているのに接続できない」時に、LISTEN状態と待受プロセスを確認する。
- 障害時に特定ポート（例: 443）への接続数急増を確認し、過負荷や攻撃兆候を切り分ける。
- デプロイ後に新プロセスが正しいアドレス/ポートで待受しているかを検証する。
- DB接続問題で、アプリ側のESTAB/TIME-WAIT過多を観察して接続枯渇の兆候を掴む。

## 3) よく使うオプション（at least 3 options with explanation）
- `-t` : TCPソケットだけ表示。
- `-u` : UDPソケットだけ表示。
- `-l` : LISTEN（待受中）ソケットに限定。
- `-n` : 名前解決せず数値表示（高速・誤解防止）。
- `-p` : ソケットを使っているプロセス情報を表示（要権限の場合あり）。
- `-s` : ソケット統計サマリを表示（全体傾向の把握に有効）。

## 4) 実例コマンド（at least 5 examples, copy-paste ready）
```bash
# 1) 待受中のTCPポートを数値表示で確認
ss -tln

# 2) 待受ポート + プロセス名/ PID を確認
sudo ss -tlnp

# 3) 443番ポート関連の接続を抽出
ss -tn '( sport = :443 or dport = :443 )'

# 4) ESTABLISHED接続だけを確認（現行接続の把握）
ss -tn state established

# 5) UDP待受ポートを確認（DNS/監視エージェント等）
ss -uln

# 6) ソケット統計を確認（再送や接続状態の全体感）
ss -s
```

## 5) よくあるミスと安全ポイント
- **`netstat`前提の読み方をする**：`ss`は表示項目が異なる。まず`-n`で素直に数値確認。
- **`-p`で情報が出ない**：権限不足が原因になりやすい。必要時は`sudo`で再実行。
- **フィルタ式のクォート漏れ**：`'( sport = :443 )'` のように引用してシェル解釈を回避。
- **一時的な状態を断定する**：瞬間値なので、障害中は複数回確認して傾向で判断する。

## 6) 追加学習（manページの読みどころ or related command）
- `man ss` の **"FILTER"** 節（state/port条件式）を重点的に読むと実戦力が上がる。
- 関連コマンド：`lsof -i`（ファイル/ソケット起点の確認）、`ip`（NIC/ルーティング確認）。
