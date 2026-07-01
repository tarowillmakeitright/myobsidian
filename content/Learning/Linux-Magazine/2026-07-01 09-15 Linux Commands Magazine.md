---
tags:
  - linux
  - commands
  - learning
  - devops
  - daily
---

[[Home]]

# Linux Commands Magazine — 2026-07-01 09:15

## 1) 今日の1コマンド（command name + one-line summary）
`systemctl` — systemd 管理下のサービス状態確認・起動停止・自動起動設定を行う標準コマンド。

## 2) 実務で使う場面（2-4 concrete scenarios）
- デプロイ後に `nginx` や `docker` などのサービスが正常起動しているか確認するとき
- 障害対応で、落ちたサービスを再起動して状態と直近ログを確認するとき
- サーバー初期設定で、必要なサービスを自動起動にし不要なものを無効化するとき
- バッチやエージェントが「動いているはずなのに動かない」ときに unit 状態を確認するとき

## 3) よく使うオプション（at least 3 options with explanation）
- `--now` : 有効化/無効化と同時に、今すぐ起動/停止も行う
- `--type=service` : `list-units` などで service ユニットだけに絞る
- `--failed` : 失敗状態のユニットだけ一覧表示する
- `-l` : 長い行を省略せず表示する
- `-n <件数>` : `status` で表示するログ行数を制限する

## 4) 実例コマンド（at least 5 examples, copy-paste ready）
```bash
systemctl status nginx
systemctl restart nginx
systemctl enable --now docker
systemctl disable --now apache2
systemctl list-units --type=service --failed
systemctl status sshd -n 50 -l
systemctl is-active cron
```

## 5) よくあるミスと安全ポイント
- `restart` を本番でいきなり打つ前に、まず `status` で失敗理由と依存関係を確認する
- `disable` は「次回起動しない」だけで、今動いているプロセスは止まらない。今止めたいなら `--now` を付ける
- サービス名はディストリごとに違うことがある (`ssh` / `sshd` など)。補完や `list-units` で確認する
- root 権限が必要な操作が多い。変更系は `sudo` 前提で、影響範囲を確認してから実行する
- `mask` は強めの無効化。通常はまず `disable` で十分なことが多い

## 6) 追加学習（manページの読みどころ or related command）
- `man systemctl` の `COMMANDS` と `UNIT COMMANDS` を先に読むと、日常運用で必要な操作を押さえやすい
- 関連コマンド: `journalctl`（サービスの詳細ログ確認）, `systemd-analyze`（起動時間や依存関係の分析）
