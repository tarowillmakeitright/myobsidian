---
tags: [linux, commands, learning, devops, daily]
---

# 2026-04-17 09:15 Linux Commands Magazine
[[Home]]

#linux #commands #learning #devops #daily

## 1) 今日の1コマンド（command name + one-line summary）
**`journalctl`** — systemd環境のログを時刻・サービス単位で高速に追跡できる障害調査コマンド。

## 2) 実務で使う場面（2-4 concrete scenarios）
- 本番APIが5xxを返し始めたときに、`nginx`/`app`サービスの直近エラーを確認する
- デプロイ後にサービス再起動が失敗した原因（設定ミス・権限不足）を特定する
- 深夜障害で「何時何分から異常が始まったか」を時刻範囲で切って調べる
- サーバ再起動後の起動ログを確認して、依存サービスの立ち上がり順問題を追う

## 3) よく使うオプション（at least 3 options with explanation）
- `-u <unit>` : 対象サービスを絞る（例: `-u nginx`, `-u docker`）
- `-f` : ログを追尾表示（`tail -f`相当、障害再現中に便利）
- `-n <N>` : 直近N行だけ表示（初動確認が速い）
- `--since` / `--until` : 時刻範囲を指定して調査（例: `--since "2026-04-17 08:00"`）
- `-p <priority>` : 重大度で絞る（`err`, `warning` など）
- `-b` : 現在ブート分のみ表示（再起動後の切り分けに有効）

## 4) 実例コマンド（at least 5 examples, copy-paste ready）
```bash
# 1) 直近100行のシステムログを確認
journalctl -n 100 --no-pager

# 2) nginxサービスのログを追尾（障害再現中）
sudo journalctl -u nginx -f

# 3) 今日の9時以降のエラーログだけ確認
sudo journalctl --since "2026-04-17 09:00" -p err --no-pager

# 4) dockerサービスの直近200行を確認
sudo journalctl -u docker -n 200 --no-pager

# 5) 現在ブート分のみで warning以上を確認
sudo journalctl -b -p warning --no-pager

# 6) 2時間前から現在までのアプリログを確認
sudo journalctl -u myapp --since "2 hours ago" --until "now" --no-pager
```

## 5) よくあるミスと安全ポイント
- **ミス:** ログ全件を流してしまい、必要情報を見失う
  - **安全:** まず `-u` と `--since` を付けて範囲を絞る
- **ミス:** ページャで止まって「固まった」と勘違いする
  - **安全:** 非対話用途は `--no-pager` を付ける
- **ミス:** 時刻の解釈ミスで調査範囲を誤る
  - **安全:** サーバTZを確認し、`--since` は具体時刻で指定する

## 6) 追加学習（manページの読みどころ or related command）
- `man journalctl` の **FILTERING OPTIONS** と **OUTPUT OPTIONS** を先に読むと、実務での調査速度が上がる
- 関連コマンド: `systemctl status <unit>`（サービス状態確認）, `dmesg`（カーネルログ確認）
