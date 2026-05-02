---
tags: [linux, commands, learning, devops, daily]
---

# Daily Linux Commands Magazine - 2026-05-02
[[Home]]

## 1) 今日の1コマンド（command name + one-line summary）
**`journalctl`** — systemd環境のログを時刻・サービス単位で素早く絞り込み、障害調査を効率化するコマンド。

## 2) 実務で使う場面（2-4 concrete scenarios）
- サービスが再起動を繰り返す時に、直近エラー原因を特定する。
- デプロイ後の障害で、特定時間帯だけのログを抜き出して確認する。
- 深夜障害の翌朝に、`sshd` や `nginx` の異常ログを優先調査する。
- インシデント報告用に、重要ログを時系列で再現する。

## 3) よく使うオプション（at least 3 options with explanation）
- `-u <unit>` : 指定サービス（例: `nginx.service`）のログだけ表示。
- `-b` : 現在のブート分だけ表示（再起動前後の切り分けに便利）。
- `-p <priority>` : 重要度で絞り込み（例: `err`, `warning`）。
- `-n <行数>` : 末尾から指定行数だけ確認（初動確認が速い）。
- `-f` : ログを追尾表示（`tail -f` 的な使い方）。
- `--since` / `--until` : 期間指定で調査範囲を限定。

## 4) 実例コマンド（at least 5 examples, copy-paste ready）
```bash
# 1) 直近100行を確認
journalctl -n 100

# 2) nginxサービスの当日ログを確認
journalctl -u nginx --since today

# 3) 前回起動分のログを確認（再起動絡みの調査）
journalctl -b -1

# 4) エラー以上のみを直近2時間で確認
journalctl -p err --since "2 hours ago"

# 5) sshdログをリアルタイム監視
journalctl -u sshd -f

# 6) 障害時間帯だけを絞って保存
journalctl --since "2026-05-02 08:40:00" --until "2026-05-02 09:10:00" > incident-log.txt
```

## 5) よくあるミスと安全ポイント
- `sudo` なしだと一部ログが見えないことがある（権限不足）。
- 時刻指定はサーバーTZ依存。調査時は `timedatectl` でTZ確認。
- `-f` で追尾し続けると見落としやすいので、まず `-n` で直近状況を把握してから追尾する。
- ログ共有時はIP・トークン等の機微情報をマスキングしてから提出する。

## 6) 追加学習（manページの読みどころ or related command）
- `man journalctl` の **"FILTERING OPTIONS"** と **"OUTPUT OPTIONS"** を読むと、調査速度がかなり上がる。
- 関連コマンド: `systemctl status <unit>`（状態確認）→ `journalctl -u <unit>`（詳細ログ確認）の流れが定番。
