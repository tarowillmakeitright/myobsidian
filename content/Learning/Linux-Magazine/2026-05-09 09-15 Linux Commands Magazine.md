---
tags: [linux, commands, learning, devops, daily]
---

# Daily Linux Commands Magazine - 2026-05-09
[[Home]]

## 1) 今日の1コマンド（command name + one-line summary）
**`journalctl`** — systemd環境のログを時刻・サービス単位で即座に絞り込み、障害調査を速くするコマンド。

## 2) 実務で使う場面（2-4 concrete scenarios）
- デプロイ直後に `nginx` や `docker` サービスが落ちた原因を確認する。
- サーバ再起動後に「起動中に何が失敗したか」を時系列で追う。
- 深夜障害で、直近30分のエラーログだけ抽出して一次切り分けする。
- 特定サービスのログをリアルタイム監視して復旧確認する。

## 3) よく使うオプション（at least 3 options with explanation）
- `-u <unit>` : 指定サービス（例: `nginx.service`）のログだけ表示。
- `-b` : 現在のブート以降のログに限定（再起動前後の切り分けに有効）。
- `--since "..."` / `--until "..."` : 時間範囲で絞り込み。
- `-p <level>` : 優先度で絞る（例: `err` 以上）。
- `-f` : `tail -f` のようにログを追従表示。
- `-n <行数>` : 最新N行だけ表示して素早く確認。

## 4) 実例コマンド（at least 5 examples, copy-paste ready）
```bash
# 1) 現在ブートの全体ログを新しい順で確認
journalctl -b -r

# 2) nginxサービスの最新100行を確認
journalctl -u nginx -n 100

# 3) 直近1時間のエラー以上を抽出
journalctl --since "1 hour ago" -p err

# 4) dockerサービスをリアルタイム監視
journalctl -u docker -f

# 5) 今日の 09:00〜09:30 の kubelet ログを確認
journalctl -u kubelet --since "2026-05-09 09:00:00" --until "2026-05-09 09:30:00"

# 6) 前回ブート（1つ前）の重大ログを確認
journalctl -b -1 -p warning
```

## 5) よくあるミスと安全ポイント
- `sudo` なしだと読めないログがある。権限不足時は `sudo journalctl ...` で再実行。
- 時刻指定が曖昧だと取りこぼす。障害調査は `--since`/`--until` を明示する。
- ログ量が多い環境で無絞り実行すると見落としやすい。まず `-u` と `-p` で絞る。
- ログ確認だけで設定変更はしない（調査フェーズと復旧作業を分離する）。

## 6) 追加学習（manページの読みどころ or related command）
- `man journalctl` の **FILTERING OPTIONS** と **OUTPUT OPTIONS** を重点的に読むと実務で効く。
- 関連コマンド: `systemctl status`, `dmesg`, `logger`（テストログ投入）。
