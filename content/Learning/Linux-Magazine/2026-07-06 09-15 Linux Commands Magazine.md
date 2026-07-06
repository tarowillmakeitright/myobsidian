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

# Linux Commands Magazine — 2026-07-06 09:15

#linux #commands #learning #devops #daily
[[Home]]

1) 今日の1コマンド
`journalctl` — systemd環境で、サービスログや起動ログを時系列で追える標準ログ調査コマンド。

2) 実務で使う場面
- `nginx` や `docker` などの systemd サービスが落ちた原因を確認するとき。
- デプロイ直後に、直近10分のエラーや再起動履歴を追いたいとき。
- サーバー再起動後に、前回ブート時の失敗メッセージを見たいとき。
- 障害対応で「今まさに増えているログ」をリアルタイム監視したいとき。

3) よく使うオプション
- `-u <unit>` — 指定した systemd サービスのログだけを見る。運用では最重要。
- `-n <件数>` — 末尾から指定件数だけ表示する。大量ログを一気に開かずに済む。
- `-f` — ログを追尾する。`tail -f` 的に使える。
- `-b` — 現在のブート分だけ表示する。再起動をまたぐ調査で便利。
- `--since` / `--until` — 時間範囲で絞り込む。障害時間帯だけ見たいときに有効。
- `-p <priority>` — 優先度で絞る。`err` 以上だけ見る、などができる。

4) 実例コマンド
```bash
journalctl -u nginx -n 100
journalctl -u docker --since '30 minutes ago'
journalctl -b -p err
journalctl -u sshd -f
journalctl --since '2026-07-06 09:00:00' --until '2026-07-06 09:15:00'
journalctl -u postgresql -b -n 50 --no-pager
```

5) よくあるミスと安全ポイント
- ログが多い環境で素の `journalctl` を打つと情報量が多すぎる。まず `-u`、`-n`、`--since` で絞る。
- root権限がないと見えないログがある。必要なら `sudo journalctl ...` を使う。
- `-f` で追っているだけでは過去の原因を見落としやすい。直前ログは `-n` とセットで確認すると安全。
- 再起動前の障害を見たいのに `-b` だけ使うと今のブート分しか出ない。必要なら `journalctl -b -1` も使う。

6) 追加学習
- `man journalctl` の `-u`, `-b`, `-p`, `--since` 周りを先に読むと、実務で困らない使い方が早く身につく。
- 関連コマンド: `systemctl status`, `dmesg`, `tail`。
