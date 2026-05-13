---
tags: [linux, commands, learning, devops, daily]
---

# 今日の1コマンド: `journalctl`

**一言まとめ:** systemd環境のログを時系列・条件付きで高速に確認できる標準ログ閲覧コマンド。

## 1) 今日の1コマンド（command name + one-line summary）
`journalctl` — OS/サービスの障害調査で、必要なログだけを素早く絞り込んで読むための基本コマンド。

## 2) 実務で使う場面（2-4 concrete scenarios）
- **サービス障害対応:** `nginx` や `sshd` が落ちた/起動失敗した原因調査。
- **夜間アラート確認:** 「5分前からエラー増加」など、時間範囲でのログ追跡。
- **再起動後トラブル:** 前回ブート時のログを確認して、起動時エラーを特定。
- **本番監視補助:** 障害復旧中にリアルタイムで新規ログを追う。

## 3) よく使うオプション（at least 3 options with explanation）
- `-u <unit>`: 指定systemdユニット（例: `nginx.service`）のログだけ表示。
- `-S "YYYY-MM-DD HH:MM:SS"`: この時刻以降のログに限定（`--since`）。
- `-U "YYYY-MM-DD HH:MM:SS"`: この時刻以前のログに限定（`--until`）。
- `-p <priority>`: 重要度で絞り込み（例: `err`, `warning`）。
- `-f`: `tail -f` のように新規ログを追従。
- `-b [N]`: ブート単位で表示（`-b -1` は1つ前の起動）。

## 4) 実例コマンド（at least 5 examples, copy-paste ready）
```bash
# 1) 直近の重要ログ（warning以上）を見る
journalctl -p warning -n 100 --no-pager

# 2) nginxサービスの今日のログだけ確認
journalctl -u nginx.service -S today --no-pager

# 3) 直近30分のssh失敗ログを確認
journalctl -u sshd.service -S "30 min ago" -p err --no-pager

# 4) 前回ブート時のカーネルログを確認
journalctl -k -b -1 --no-pager

# 5) サービス再起動しながらリアルタイム監視
journalctl -u myapp.service -f

# 6) 特定時間帯だけ切り出して調査用に保存
journalctl -u docker.service -S "2026-05-13 08:00:00" -U "2026-05-13 09:00:00" > docker_0800_0900.log
```

## 5) よくあるミスと安全ポイント
- **ミス:** `--since` だけ指定して終端がなく、ログ量が多すぎて見づらい。  
  **対策:** `-n` や `-U` を併用して範囲を絞る。
- **ミス:** 権限不足で一部ログが見えない。  
  **対策:** 必要に応じて `sudo journalctl ...` を使う。
- **ミス:** ページャで詰まって「止まった」と誤解。  
  **対策:** 自動処理や一次確認では `--no-pager` を付ける。
- **安全:** ログ共有時はIP・トークン・個人情報を必ずマスクする。

## 6) 追加学習（manページの読みどころ or related command）
- まず `man journalctl` の **`FILTERING OPTIONS`** と **`OUTPUT OPTIONS`** を重点的に読むと実務で効く。
- 関連コマンド: `systemctl status <unit>`（状態確認）→ 詳細調査で `journalctl -u <unit>` の流れが定番。

---
[[Home]]
