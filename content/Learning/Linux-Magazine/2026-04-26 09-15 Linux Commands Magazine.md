---
tags: [linux, commands, learning, devops, daily]
---

[[Home]]

# 2026-04-26 09:15 Linux Commands Magazine

## 1) 今日の1コマンド（command name + one-line summary）
**`journalctl`** — systemd環境のログを時刻・サービス単位で高速に検索/追跡できるコマンド。

## 2) 実務で使う場面（2-4 concrete scenarios）
- デプロイ後に `myapp.service` が落ちる原因を直近ログで特定する
- サーバ再起動後、起動時エラーだけを時系列で確認する
- 障害対応中に、特定時間帯の認証失敗やOOM発生を切り出す
- オンコール時に `-f` でログを追いながら復旧確認する

## 3) よく使うオプション（at least 3 options with explanation）
- `-u <unit>` : 指定サービス（例: `nginx.service`）のログだけ表示
- `-f` : 新しいログを追尾表示（`tail -f` 的に使う）
- `-n <行数>` : 末尾から指定行数だけ表示（まず状況把握したい時に便利）
- `--since/--until` : 期間を絞って調査（例: `--since "2026-04-26 08:00"`）
- `-p <priority>` : 重大度で絞る（`err`, `warning` など）

## 4) 実例コマンド（at least 5 examples, copy-paste ready）
```bash
# 1) 直近100行のシステムログを確認
journalctl -n 100

# 2) nginxサービスのログだけ確認
journalctl -u nginx.service -n 200

# 3) 今日の0時以降のエラーログを抽出
journalctl --since today -p err

# 4) デプロイ時間帯（9:00〜9:20）の myapp ログを確認
journalctl -u myapp.service --since "2026-04-26 09:00" --until "2026-04-26 09:20"

# 5) 復旧対応中に sshd のログをリアルタイム追尾
journalctl -u sshd.service -f
```

## 5) よくあるミスと安全ポイント
- **sudoなしで見えないログがある**: 権限不足の場合は `sudo journalctl ...` を使う。
- **時刻解釈ミス**: 調査時はサーバTZを先に確認（`timedatectl`）。
- **`-f` 放置に注意**: 監視後は `Ctrl+C` で確実に終了し、不要なターミナル占有を避ける。

## 6) 追加学習（manページの読みどころ or related command）
- `man journalctl` の **"FILTERING OPTIONS"** と **"OUTPUT OPTIONS"** は実務必須。
- 関連コマンド: `systemctl status`, `dmesg`, `grep`（絞り込み補助）。
