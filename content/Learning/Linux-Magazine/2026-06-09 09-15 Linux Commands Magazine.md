# Linux Commands Magazine — 2026-06-09 09:15
Tags: #linux #commands #learning #devops #daily
Links: [[Home]]

## 1) 今日の1コマンド（command name + one-line summary）
**`journalctl`** — systemd環境のログを一元的に検索・追跡できる、障害調査の基本コマンド。

## 2) 実務で使う場面（2-4 concrete scenarios）
- **サービス障害の切り分け**: `nginx`, `docker`, 自作API などの起動失敗や再起動ループを調べる。
- **デプロイ後の異常確認**: 直近10分〜1時間のエラーや警告だけを追う。
- **サーバ再起動原因の確認**: 前回ブート時のログやカーネルメッセージを確認する。
- **定期ジョブ/バッチ失敗の調査**: 対象サービスや時間帯で絞って原因を探す。

## 3) よく使うオプション（at least 3 options with explanation）
- `-u <unit>` : 対象のsystemdユニットだけに絞る。サービス調査の基本。
- `-f` : 追尾表示。`tail -f` 感覚でリアルタイム監視できる。
- `-n <件数>` : 末尾から指定件数だけ表示。直近確認に便利。
- `--since` : 指定時刻以降に絞る。デプロイ後や障害発生後の調査で有効。
- `-p <priority>` : 優先度で絞る。`err` や `warning` の抽出に便利。
- `-b` : 現在のブート分だけ表示。再起動またぎの混線を防げる。

## 4) 実例コマンド（at least 5 examples, copy-paste ready）
```bash
# 1) nginxサービスの最新100行を見る
sudo journalctl -u nginx -n 100

# 2) APIサービスのログをリアルタイム追尾する
sudo journalctl -u myapp-api -f

# 3) 今日の0時以降のエラーログだけ確認する
sudo journalctl --since today -p err

# 4) 直近30分の docker ログを確認する
sudo journalctl -u docker --since "30 minutes ago"

# 5) 現在のブート中に出た警告以上を確認する
sudo journalctl -b -p warning

# 6) ひとつ前のブートの末尾50行を見る
sudo journalctl -b -1 -n 50
```

## 5) よくあるミスと安全ポイント
- ログ量が多い環境では、**まず `-u`・`--since`・`-p` で絞る**と調査が速い。
- 古いログが見えない場合は、journald の**永続保存設定**が無効なことがある。
- `-f` で追っても対象サービスを絞らないとノイズが多い。なるべく `-u` 併用。
- 権限不足で一部ログが見えないことがあるため、システム調査では `sudo` 前提で考える。

## 6) 追加学習（manページの読みどころ or related command）
- `man journalctl` は **FILTERING OPTIONS**, **-b**, **--since/--until**, **-p** 周辺を先に読むと実務向き。
- 関連: `systemctl status`（サービスの要約確認）, `dmesg`（カーネルリングバッファ）, `less`（長いログ閲覧）。
