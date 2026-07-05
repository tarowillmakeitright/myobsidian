---
tags:
  - linux
  - commands
  - learning
  - devops
  - daily
links:
  - "[[Home]]"
---

# Linux Commands Magazine — 2026-07-05 09:15

#linux #commands #learning #devops #daily
[[Home]]

1) 今日の1コマンド
`timeout` — コマンドの実行時間に上限を付けて、ハングや長時間実行を防ぐコマンド。

2) 実務で使う場面
- 外部API確認や疎通テストが返ってこないとき、CIや運用スクリプトを止めないために使う。
- `tail -f` や監視コマンドを一定時間だけ動かして、証跡だけ取りたいときに使う。
- 障害調査で、重いコマンドや応答不安定なSSH先コマンドを安全に打ち切りたいときに使う。
- バッチ内で「最悪でも30秒で次へ進む」という上限を付けたいときに使う。

3) よく使うオプション
- `-s <signal>` — 終了時に送るシグナルを指定する。穏やかに止めたいなら `TERM`、強制なら `KILL`。
- `-k <時間>` — 最初のシグナルで止まらない場合、追加で強制終了するまでの猶予を指定する。
- `--preserve-status` — タイムアウトしなかった場合、元コマンドの終了コードをそのまま返す。
- `--foreground` — 対話的コマンドを前面で扱いやすくする。TTY絡みで使うことがある。

4) 実例コマンド
```bash
timeout 10s curl -I https://example.com
timeout 30s ssh app-server 'systemctl status nginx'
timeout 20s tail -f /var/log/nginx/access.log
timeout -s TERM -k 5s 60s python manage.py migrate
timeout --preserve-status 15s bash -c 'until nc -z 127.0.0.1 5432; do sleep 1; done'
timeout 5m rsync -av /src/ /backup/
```

5) よくあるミスと安全ポイント
- `timeout` は子プロセスの止まり方まで完全保証するわけではない。止まらない処理には `-k` を付けておくと安全。
- 単位なしだと秒扱い。`5` と `5m` は意味が違うので、スクリプトでは `s` `m` を明示する。
- DBマイグレーションや同期処理に短すぎる上限を付けると、中途半端な状態を招くことがある。業務影響を見て時間を決める。
- タイムアウト終了時の終了コード判定を忘れると、失敗原因の切り分けが雑になる。CIでは終了コード確認までセットで考える。

6) 追加学習
- `man timeout` の `Exit status` を読むと、通常失敗とタイムアウト失敗の扱いを整理しやすい。
- 関連コマンド: `watch`（定期実行）, `nohup`（切断耐性）, `xargs -P`（並列実行時の制御）。
