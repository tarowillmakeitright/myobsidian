---
tags:
  - linux
  - commands
  - learning
  - devops
  - daily
---

[[Home]]

# Linux Commands Magazine — 2026-06-23

1) 今日の1コマンド
`journalctl` — systemd環境のログを時系列・サービス単位・起動単位で安全に追える、障害調査の基本コマンド。

2) 実務で使う場面
- `nginx` や `docker` などのサービスが起動失敗したとき、直近ログを確認するとき
- サーバ再起動後に「前回ブートで何が起きたか」を追いたいとき
- 本番で特定時間帯だけエラーが出たとき、期間を絞って調査するとき
- デプロイ後にアプリユニットの warning / error を素早く確認するとき

3) よく使うオプション
- `-u <unit>` : 特定の systemd ユニットだけ表示する
- `-b` : 現在のブート分のログだけ見る。`-b -1` で1回前の起動分
- `-f` : ログを追尾する。`tail -f` 的に使える
- `--since` / `--until` : 時間範囲を絞る
- `-p <priority>` : 優先度で絞る。例: `err`, `warning`
- `-n <lines>` : 末尾の指定行数だけ表示する

4) 実例コマンド
```bash
# 1. nginx サービスの直近100行を見る
journalctl -u nginx -n 100

# 2. docker サービスのログをリアルタイム監視する
journalctl -u docker -f

# 3. 今回の起動分だけでエラー以上を確認する
journalctl -b -p err

# 4. 1回前の起動で sshd に何が起きたか調べる
journalctl -b -1 -u sshd

# 5. 今日の09:00以降に app.service で出たログを確認する
journalctl -u app.service --since "2026-06-23 09:00:00"

# 6. 10:00〜10:30 の間の warning 以上だけ絞る
journalctl --since "2026-06-23 10:00:00" --until "2026-06-23 10:30:00" -p warning
```

5) よくあるミスと安全ポイント
- 権限不足で一部ログが見えないことがある。必要なら `sudo journalctl ...` を使う
- `-f` は流れ続けるので、共有端末や長時間監視では終了忘れに注意
- 時間指定はローカル時刻基準。サーバのタイムゾーン差で見たい範囲を外しやすい
- ログ量が多い環境では、まず `-u` `-b` `-p` `--since` で絞ると調査が速い
- 機密情報が出ることがあるので、そのまま貼らず必要箇所だけ共有する

6) 追加学習
- `man journalctl` の「FILTERING OPTIONS」「OUTPUT OPTIONS」「BOOT OPTIONS」を読むと実務で強い
- 関連コマンド: `systemctl status`（状態確認）, `dmesg`（カーネルログ）, `tail`（通常ログファイル追尾）
