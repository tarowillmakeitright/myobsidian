---
tags:
  - linux
  - commands
  - learning
  - devops
  - daily
---

[[Home]]

# Linux Commands Magazine — 2026-07-02 09:15

## 1) 今日の1コマンド（command name + one-line summary）
`journalctl` — systemd ジャーナルから、サービス障害や起動ログを時系列で追うためのログ確認コマンド。

## 2) 実務で使う場面（2-4 concrete scenarios）
- `nginx` や `docker` が起動失敗したときに、unit 単位で直近エラーを確認するとき
- 本番サーバーで「夜中に何が起きたか」を時刻指定で調べるとき
- 再起動後に、前回ブートで出ていた警告や失敗ログを確認するとき
- 障害一次対応で、カーネルメッセージや認証ログを横断して流れを追うとき

## 3) よく使うオプション（at least 3 options with explanation）
- `-u <unit>` : 特定サービスのログだけに絞る
- `-b` : 現在のブート分だけ表示する。`-b -1` で前回起動分も見られる
- `-n <件数>` : 末尾から指定件数だけ表示する
- `-f` : 新しいログを追尾表示する（`tail -f` 的に使う）
- `--since` / `--until` : 時刻範囲を指定して調査対象を絞る
- `-p <priority>` : 重要度で絞る（例: `err`, `warning`）

## 4) 実例コマンド（at least 5 examples, copy-paste ready）
```bash
journalctl -u nginx -n 100
journalctl -u docker -f
journalctl -b -p err
journalctl --since "2026-07-02 00:00" --until "2026-07-02 06:00"
journalctl -b -1 -u sshd
journalctl -k -n 50
journalctl -u openclaw --since "1 hour ago"
```

## 5) よくあるミスと安全ポイント
- ログが多すぎるときは、いきなり全件を見るより `-u` `-n` `--since` で絞る方が速い
- `-f` のまま放置すると抜け忘れやすい。確認後は `Ctrl+C` で止める
- サービス名は unit 名で指定する。`ssh` と `sshd` のように環境差があるので `systemctl list-units --type=service` で確認すると安全
- 古いブートの障害を見たいのに `-b` だけで済ませると、現在ブート分しか出ない。前回分は `-b -1`
- 一般ユーザーで読める範囲が制限されることがある。権限不足時は `sudo` を使う

## 6) 追加学習（manページの読みどころ or related command）
- `man journalctl` の `FILTERING OPTIONS` と `OUTPUT OPTIONS` を読むと、調査時の絞り込みがかなり速くなる
- 関連コマンド: `systemctl`（サービス状態確認）, `dmesg`（カーネルリングバッファ確認）
