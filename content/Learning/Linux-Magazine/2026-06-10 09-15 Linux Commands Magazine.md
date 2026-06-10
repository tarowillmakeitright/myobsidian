---
tags: [linux, commands, learning, devops, daily]
---

[[Home]]

# 2026-06-10 09:15 Linux Commands Magazine

#linux #commands #learning #devops #daily

## 1) 今日の1コマンド（command name + one-line summary）
**`timeout`** — ハングしがちな処理や長すぎるコマンドに実行時間の上限を付けて、運用事故を防ぐコマンド。

## 2) 実務で使う場面（2-4 concrete scenarios）
- **CI/CDの暴走防止**: テストや外部API待ちが固まってジョブ全体を詰まらせるのを防ぐ。
- **運用スクリプトの安全化**: `curl` / `ssh` / `rsync` などの待ち続け事故を防ぐ。
- **障害調査の時間制御**: 重い `find` や `tcpdump` を短時間だけ走らせて様子を見る。
- **cronの保険**: 前回ジョブが終わらず次回実行と重なる事故を減らす。

## 3) よく使うオプション（at least 3 options with explanation）
- `10s` / `5m` / `1h` : 制限時間の指定。秒・分・時間で書ける。
- `-k <時間>` : 通常終了シグナルで止まらない時、さらに指定時間後に強制終了する。
- `-s <SIG>` : タイムアウト時に送るシグナルを指定する（例: `TERM`, `INT`, `KILL`）。
- `--preserve-status` : タイムアウトしなかった場合、元コマンドの終了コードをそのまま返す。

## 4) 実例コマンド（at least 5 examples, copy-paste ready）
```bash
timeout 30s curl -fsS https://example.com/health

timeout 2m ssh deploy@web01 'systemctl restart myapp && systemctl status --no-pager myapp'

timeout -k 10s 1m rsync -avz ./build/ backup@192.168.1.50:/srv/backups/build/

timeout 20s bash -lc 'tail -f /var/log/nginx/error.log'

timeout 5m find /var/log -type f -name "*.log" -size +500M

timeout -s INT 15s tcpdump -ni any port 443
```

## 5) よくあるミスと安全ポイント
- `timeout` は**相手コマンドが安全に中断できるか**も大事。途中停止で中途半端な成果物が残る処理は注意。
- `rsync --delete` や更新系スクリプトに使う時は、**中断時の整合性**を先に考える。
- `tail -f` や `tcpdump` のような「止め忘れやすい監視系」と相性がいい。
- 終了コード `124` はタイムアウトの目印。監視やシェル分岐で拾えるようにしておくと実務向き。

## 6) 追加学習（manページの読みどころ or related command）
- `man timeout` では **EXIT STATUS** と **SIGNAL指定（`-s`, `-k`）** を先に読むと実践投入しやすい。
- 関連コマンド: `watch`（定期表示）, `nohup`（切断耐性）, `systemd-run --scope`（より運用寄りの実行制御）。
