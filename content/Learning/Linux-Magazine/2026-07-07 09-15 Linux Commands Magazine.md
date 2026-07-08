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

# Linux Commands Magazine — 2026-07-07 09:15

#linux #commands #learning #devops #daily

[[Home]]

1) 今日の1コマンド
`pgrep` — プロセス名や条件で対象プロセスを安全に絞って探すコマンド。

2) 実務で使う場面
- アプリが起動済みかをデプロイ前後で確認するとき
- バッチやワーカーが多重起動していないか調べるとき
- 特定ユーザー配下のプロセスだけ確認したいとき
- `kill` や `pkill` を打つ前に、対象PIDを安全に確認したいとき

3) よく使うオプション
- `-a` : PIDだけでなく実行コマンド全体も表示する
- `-f` : プロセス名だけでなくコマンドライン全体で検索する
- `-u <user>` : 特定ユーザーのプロセスに限定する
- `-l` : PIDに加えてプロセス名も表示する
- `-n` : 条件に合う中で最新のプロセスだけ選ぶ

4) 実例コマンド
```bash
pgrep nginx
pgrep -a ssh
pgrep -u www-data python
pgrep -f 'gunicorn.*myapp'
pgrep -n -f 'backup.sh'
```

5) よくあるミスと安全ポイント
- `pgrep foo` は「完全一致」ではなく部分一致になることがある。似た名前のプロセスが混ざらないか確認する
- systemd 管理下のサービスは、実プロセス名がサービス名と違う場合がある。見つからないときは `-f` で確認する
- `pkill` の前にまず `pgrep -a` で対象確認。誤爆防止になる
- コンテナ環境では、ホスト側とコンテナ内で見えるプロセスが違う点に注意する

6) 追加学習
- `man pgrep` の `-f`, `-u`, `-n`, `-o` あたりは実務で特に使いやすい
- 関連コマンド: `ps`, `pidof`, `pkill`, `kill`
