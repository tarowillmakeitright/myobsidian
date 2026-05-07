---
tags: [linux, commands, learning, devops, daily]
---

# Daily Linux Commands Magazine - 2026-05-07
[[Home]]

## 1) 今日の1コマンド（command name + one-line summary）
**`tar`** — 複数ファイルを1つに固めて圧縮/展開し、バックアップ・配布・移行を安定運用する基本コマンド。

## 2) 実務で使う場面（2-4 concrete scenarios）
- リリース成果物（設定・バイナリ・スクリプト）を1アーカイブにまとめて配布する。
- 障害調査で、ログ一式を圧縮してチームへ共有する。
- サーバ移行時に、対象ディレクトリを固めて安全に持ち運ぶ。
- 定期バックアップで日付付きアーカイブを作り、保管ローテーションする。

## 3) よく使うオプション（at least 3 options with explanation）
- `-c` : 新しいアーカイブを作成する（create）。
- `-x` : アーカイブを展開する（extract）。
- `-f <file>` : アーカイブファイル名を指定する（必須級）。
- `-z` : gzip圧縮を使う（`.tar.gz`）。
- `-t` : 展開せず中身一覧を確認する（安全確認に有効）。
- `-C <dir>` : 作業ディレクトリを切り替えて、不要な親パス混入を防ぐ。

## 4) 実例コマンド（at least 5 examples, copy-paste ready）
```bash
# 1) ディレクトリを gzip 圧縮して保存
sudo tar -czf /backup/app-$(date +%F).tar.gz /opt/myapp

# 2) アーカイブ内容を展開前に確認
tar -tzf /backup/app-2026-05-07.tar.gz

# 3) /tmp/restore に展開（事前に展開先を明示）
mkdir -p /tmp/restore && tar -xzf /backup/app-2026-05-07.tar.gz -C /tmp/restore

# 4) 特定ディレクトリへ移動して相対パスで固める（親パス事故防止）
tar -czf logs-$(date +%F).tar.gz -C /var/log myapp nginx

# 5) 除外パターンを使って不要ファイルを省く
tar -czf src-$(date +%F).tar.gz --exclude="node_modules" --exclude=".git" /srv/project

# 6) xz 圧縮（高圧縮率）
tar -cJf archive-$(date +%F).tar.xz /data/reports
```

## 5) よくあるミスと安全ポイント
- 展開前に `tar -t` で中身確認。**いきなり本番ディレクトリへ展開しない**。
- `-C` を使わず絶対パスで固めると、展開時に意図しない階層ができやすい。
- 圧縮方式ミスマッチに注意（`-z` は gzip、`-J` は xz）。拡張子とオプションを揃える。
- バックアップ用途では作成後に `tar -tzf` で読み取り確認し、破損検知を習慣化する。

## 6) 追加学習（manページの読みどころ or related command）
- `man tar` の **OPERATIONS**（`-c/-x/-t`）と **OPTIONS**（`-C`, `--exclude`）を重点確認。
- 関連コマンド: `gzip`/`xz`（圧縮方式の使い分け）、`rsync`（継続同期が必要な場面）。
