---
tags: [linux, commands, learning, devops, daily]
---

[[Home]]

# 2026-06-12 09:15 Linux Commands Magazine

#linux #commands #learning #devops #daily

## 1) 今日の1コマンド（command name + one-line summary）
**`tar`** — 複数ファイルやディレクトリを、バックアップ・受け渡し・ログ採取用にまとめて圧縮/展開できる定番コマンド。

## 2) 実務で使う場面（2-4 concrete scenarios）
- **障害調査のログ回収**: `/var/log/myapp` や設定ファイルをひとまとめにして共有する。
- **デプロイ前バックアップ**: 変更前の設定ディレクトリを退避して、即ロールバックできるようにする。
- **成果物の受け渡し**: ビルド結果や静的配信物を1つのアーカイブにして配布する。
- **古いログの保管**: 日次・週次でログやレポートをまとめて保存する。

## 3) よく使うオプション（at least 3 options with explanation）
- `-c` : 新しいアーカイブを作る（create）。
- `-x` : アーカイブを展開する（extract）。
- `-f <file>` : アーカイブファイル名を指定する。`tar` はこれを付けることが多い。
- `-z` : gzip圧縮を使う。`.tar.gz` を作る時の定番。
- `-C <dir>` : 指定ディレクトリに移動してから処理する。展開先や相対パス整理に便利。
- `-t` : 中身一覧だけを見る。展開前の確認に使う。
- `-v` : 処理対象を表示する。確認向きだが、普段はログが多くなるので必要時だけでOK。

## 4) 実例コマンド（at least 5 examples, copy-paste ready）
```bash
tar -czf nginx-config-backup-$(date +%F).tar.gz /etc/nginx

tar -czf incident-logs-$(date +%F).tar.gz /var/log/nginx /var/log/messages /etc/nginx/nginx.conf

tar -tf incident-logs-2026-06-12.tar.gz

tar -xzf release-assets.tar.gz -C /srv/www/releases

tar -czf build-output.tar.gz dist/ public/ README.md

tar -czf app-backup.tar.gz -C /opt/myapp config logs uploads
```

## 5) よくあるミスと安全ポイント
- `-f` の直後は**アーカイブ名**。順番を崩すと意図しない名前で作ることがある。
- 展開前に `tar -tf ...` で中身確認すると安全。特に他人から受け取ったアーカイブは先に見る。
- 絶対パスのまま固めると、展開時に扱いづらいことがある。配布・保管用途では `-C` を使って相対パス化すると扱いやすい。
- 上書き事故を避けるため、展開先は空ディレクトリか専用ディレクトリを切るのが無難。
- 機密ファイルをまとめる時は、アーカイブ作成前に含めるパスを見直す。`.env` や秘密鍵の混入はありがち。

## 6) 追加学習（manページの読みどころ or related command）
- `man tar` では **Operation mode** と **file selection** 周りを先に読むと、日常運用で迷いにくい。
- 関連コマンド: `gzip` / `gunzip`（圧縮方式の理解）, `zip` / `unzip`（他OS共有向け）, `rsync`（アーカイブではなく同期したい時）。
