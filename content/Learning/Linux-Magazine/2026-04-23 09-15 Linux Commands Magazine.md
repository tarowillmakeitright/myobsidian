---
tags: [linux, commands, learning, devops, daily]
---

# 2026-04-23 09:15 Linux Commands Magazine
[[Home]]

#linux #commands #learning #devops #daily

## 1) 今日の1コマンド（command name + one-line summary）
**`timeout`** — コマンド実行時間に上限をつけ、ハングや長時間処理を自動で打ち切る。

## 2) 実務で使う場面（2-4 concrete scenarios）
- CIジョブで外部API待ちやテストが固まる事故を防ぐ
- 運用スクリプト内の `curl` / `ssh` / バックアップ処理に最大実行時間を設ける
- 障害調査時の重いコマンド（`find`/`du`/`tcpdump` など）を安全に短時間実行する
- cronタスクの暴走を防ぎ、次ジョブへの影響を減らす

## 3) よく使うオプション（at least 3 options with explanation）
- `-s, --signal=<SIG>` : タイムアウト時に送るシグナルを指定（例: `TERM`, `INT`, `KILL`）
- `-k, --kill-after=<期間>` : まず穏当に停止を試し、一定時間後に `KILL` で強制終了
- `--preserve-status` : タイムアウトしなかった場合、元コマンドの終了コードをそのまま返す
- `-v, --verbose` : タイムアウトでシグナル送信したことを表示し、原因追跡しやすくする

## 4) 実例コマンド（at least 5 examples, copy-paste ready）
```bash
# 1) APIヘルスチェックを最大10秒で打ち切る
timeout 10s curl -fsS https://api.example.com/health

# 2) SSH疎通確認を15秒で終了（ハング防止）
timeout 15s ssh -o BatchMode=yes -o ConnectTimeout=5 ops@example-host 'echo ok'

# 3) テストを20分までに制限（CI向け）
timeout --preserve-status 20m pytest -q

# 4) TERMで停止を試し、5秒後にKILL
timeout -s TERM -k 5s 60s ./long_running_job.sh

# 5) 大きいディレクトリの容量調査を30秒だけ実行
timeout 30s du -ah /var/log | sort -hr | head -n 50

# 6) タイムアウト発生ログを見たい時（verbose）
timeout -v 8s bash -c 'sleep 20'
```

## 5) よくあるミスと安全ポイント
- `timeout` の終了コードを見ずに成功扱いしてしまう
  - タイムアウト時は通常 `124`（シグナル異常終了は別コード）なので、CIでは終了コード判定を入れる
- `-k` なしで子プロセスが残るケースを見落とす
  - 停止しにくい処理には `-k` を併用して確実に終了させる
- 制限時間を短くしすぎて正常処理まで落とす
  - 本番前に実測し、通常実行時間の余裕を見て設定する

## 6) 追加学習（manページの読みどころ or related command）
- `man timeout` の **EXIT STATUS**（特に `124/125/126/127`）を先に確認すると運用が安定する
- 関連コマンド: `nohup`, `watch`, `systemd-run --scope`（実行制御の使い分け）
