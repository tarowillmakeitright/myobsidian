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

# Linux Commands Magazine — 2026-07-11 09:15

## 1) 今日の1コマンド
`rsync` — ファイルを差分同期しながら、安全にバックアップ・配布・移行できる実務定番コマンド。

## 2) 実務で使う場面
- デプロイ前に、成果物だけをサーバーへ差分反映する
- ローカルから外付けSSDへ、毎日のバックアップを取る
- 大きなログやデータを別マシンへ再送するとき、途中から効率よく再同期する
- 除外ルールを付けて、プロジェクトを別環境へ複製する

## 3) よく使うオプション
- `-a` — 再帰コピーしつつ、更新時刻・権限・シンボリックリンクなどをまとめて保持する
- `-v` — 何を同期したか見やすくする
- `-h` — サイズ表示を人間向けにする
- `--delete` — 転送元にないファイルを転送先から消して、完全ミラーに近づける
- `--progress` — 大きいファイル転送時の進捗を確認できる
- `--exclude='PATTERN'` — `node_modules` や `.git` など不要なものを除外する

## 4) 実例コマンド
```bash
rsync -avh ./project/ /backup/project/
rsync -avh --progress ./bigdata/ user@server:/srv/bigdata/
rsync -avh --exclude='.git' --exclude='node_modules' ./app/ /tmp/app-copy/
rsync -avh --delete ./public/ user@server:/var/www/public/
rsync -avh -e ssh /etc/nginx/ ops@192.168.1.20:/srv/config-backup/nginx/
```

## 5) よくあるミスと安全ポイント
- 末尾スラッシュの意味に注意。`src/` は中身を同期、`src` はディレクトリごと同期する
- `--delete` は便利だが危険。まずは削除なしで確認し、必要なら `--dry-run` を挟む
- 権限エラーが出る場所では、転送先の書き込み権限や実行ユーザーを先に確認する
- SSH越し同期では、最初に小さいディレクトリで接続確認しておくと事故が減る

## 6) 追加学習
`man rsync` の「FILTER RULES」と「EXCLUDE PATTERNS」を読むと実戦投入しやすい。関連コマンドは `scp`、`tar`、`cp`。
