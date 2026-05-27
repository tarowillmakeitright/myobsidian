# Linux Commands Magazine — 2026-05-27 09:15
Tags: #linux #commands #learning #devops #daily
Links: [[Home]]

## 1) 今日の1コマンド（command name + one-line summary）
**`lsof`** — 「どのプロセスが、どのファイル/ソケットを掴んでいるか」を可視化するトラブルシュート必須コマンド。

## 2) 実務で使う場面（2-4 concrete scenarios）
- **ポート競合の調査**: 例) 3000番ポートが起動できない原因プロセスを特定。
- **アンマウント失敗対応**: `umount: target is busy` のとき、掴んでいるプロセスを確認。
- **ログローテーション後の容量逼迫**: 削除済みログをまだ開いているプロセスを検出。
- **本番障害対応**: 特定PIDがどの設定ファイル/ソケットを使っているか即確認。

## 3) よく使うオプション（at least 3 options with explanation）
- `-i` : ネットワーク関連（TCP/UDP）だけ表示。
- `-i :PORT` : 指定ポートを使っているプロセスを表示。
- `-p PID` : 指定PIDが開いているFDを確認。
- `-u USER` : 指定ユーザーのプロセスに絞る。
- `+D DIR` : ディレクトリ配下で開かれているファイルを再帰的に検索。
- `-nP` : DNS名/ポート名解決を無効化（高速・出力が明確）。

## 4) 実例コマンド（at least 5 examples, copy-paste ready）
```bash
# 1) 3000番ポートを使っているプロセスを特定
sudo lsof -nP -i :3000

# 2) LISTEN中のTCPソケットだけ確認
sudo lsof -nP -iTCP -sTCP:LISTEN

# 3) 特定プロセス(PID 1234)のオープンファイルを確認
lsof -p 1234

# 4) /var を掴んでいるプロセスを調査（umount失敗時など）
sudo lsof +D /var

# 5) ユーザー nginx のプロセスが開いているFDを確認
sudo lsof -u nginx

# 6) deleted なのに開きっぱなしのファイルを検出（容量逼迫調査）
sudo lsof -nP | grep '(deleted)'
```

## 5) よくあるミスと安全ポイント
- **`sudo`なしで情報不足**: システム領域は見えないことが多い。調査時は `sudo` 前提で考える。
- **名前解決で遅い/読みにくい**: まず `-nP` を付けると速くて判読しやすい。
- **`+D` の多用で重い**: 大規模ディレクトリでは高負荷。対象を狭めて使う。
- **確認せず kill**: 原因特定後も即 `kill -9` せず、サービス影響を確認してから停止。

## 6) 追加学習（manページの読みどころ or related command）
- `man lsof` は **「OUTPUT」「NETWORK FILES」「+|- options」** を優先して読むと実務で効く。
- 関連コマンド: `ss`（ソケット状態確認）, `fuser`（ファイル/ポートを使うPID表示）, `journalctl`（合わせて原因追跡）。
