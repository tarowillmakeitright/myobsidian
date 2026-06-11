---
tags: [linux, commands, learning, devops, daily]
---

[[Home]]

# 2026-06-11 09:15 Linux Commands Magazine

#linux #commands #learning #devops #daily

## 1) 今日の1コマンド（command name + one-line summary）
**`journalctl`** — systemd環境のログを、時刻・サービス単位・ブート単位で安全に追える標準ログ調査コマンド。

## 2) 実務で使う場面（2-4 concrete scenarios）
- **サービス障害の一次調査**: `nginx` や `docker`、自作systemdサービスが落ちた原因を確認する。
- **再起動後の原因追跡**: 前回ブートで何が起きていたかを見て、起動失敗やカーネル周りを追う。
- **デプロイ後の確認**: `systemctl restart` の直後に対象サービスの最新ログだけを追って異常有無を見る。
- **cron代替や定期ジョブの確認**: systemd timer / service の実行結果や失敗理由を確認する。

## 3) よく使うオプション（at least 3 options with explanation）
- `-u <unit>` : 特定サービスのログだけに絞る。例: `-u nginx`, `-u sshd`。
- `-b` : 現在のブート分だけ表示する。`-b -1` で前回ブートも見られる。
- `-f` : ログを追尾する。`tail -f` 的にリアルタイム確認したい時に使う。
- `--since` / `--until` : 期間で絞る。障害発生時刻が分かっている時に便利。
- `-p <priority>` : 重要度で絞る。例: `-p err` でエラー以上だけ表示。
- `-n <件数>` : 最新N件だけ表示。長いログを全部読まずに済む。

## 4) 実例コマンド（at least 5 examples, copy-paste ready）
```bash
journalctl -u nginx -n 50 --no-pager

journalctl -u docker --since "2026-06-11 08:30" --until "2026-06-11 09:15" --no-pager

journalctl -b -p err --no-pager

journalctl -b -1 -u sshd --no-pager

journalctl -fu myapp.service

journalctl --since "1 hour ago" -p warning --no-pager
```

## 5) よくあるミスと安全ポイント
- サービス名とunit名が微妙に違うことがある。まず `systemctl list-units --type=service` で正式名を確認すると速い。
- 期間指定なしで全件を見ると量が多すぎる。**`-u` / `--since` / `-n` を先に付ける**のが実務向き。
- root権限が必要なログもある。見えない時は `sudo journalctl ...` を試す。
- `-f` は便利だが終わらせ忘れやすい。障害確認だけなら `-n 100` で十分なことも多い。
- ログ共有時はAPIキーやトークンが混ざっていないか確認してから貼る。

## 6) 追加学習（manページの読みどころ or related command）
- `man journalctl` では **FILTERING OPTIONS** と **OUTPUT OPTIONS** を先に読むと実務で使いやすい。
- 関連コマンド: `systemctl status`（今の状態確認）, `dmesg`（カーネルログ）, `logger`（テスト用に任意メッセージを書き込む）。
