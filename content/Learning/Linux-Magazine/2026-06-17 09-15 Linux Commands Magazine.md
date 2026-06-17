---
tags:
  - linux
  - commands
  - learning
  - devops
  - daily
---

[[Home]]

# 2026-06-17 09:15 Linux Commands Magazine

#linux #commands #learning #devops #daily

## 1) 今日の1コマンド（command name + one-line summary）
**`rsync`** — ファイルやディレクトリを、差分だけ安全・高速に同期する実務定番コマンド。

## 2) 実務で使う場面（2-4 concrete scenarios）
- **デプロイ前バックアップ**: 設定や成果物を別ディレクトリ・別サーバーへ退避するとき。
- **ログ/成果物の回収**: リモートサーバーから調査用ログやビルド成果物だけを持ってくるとき。
- **静的ファイル配布**: Web配信ディレクトリへ差分だけ反映したいとき。
- **日次同期**: ローカル作業フォルダを NAS や外部ディスクへ増分バックアップするとき。

## 3) よく使うオプション（at least 3 options with explanation）
- **`-a`**: アーカイブモード。再帰・タイムスタンプ・権限などをまとめて保持する基本形。
- **`-v`**: 詳細表示。何が同期されたか確認しやすい。
- **`-h`**: サイズを人間向けに見やすく表示する。
- **`--progress`**: 転送の進捗を表示。大きいファイルのコピーで便利。
- **`--delete`**: 転送先にだけある不要ファイルを削除して、完全ミラーに近づける。
- **`-n` / `--dry-run`**: 実行せず、何が起きるかだけ確認する。事故防止の最重要オプション。
- **`-z`**: 通信中に圧縮する。低速回線のリモート同期で有効。

## 4) 実例コマンド（at least 5 examples, copy-paste ready）
```bash
rsync -avh ./app/ ./backup/app/

rsync -avhn --delete ./public/ /var/www/html/

rsync -avh --progress /var/log/nginx/ ./logs/nginx/

rsync -avhz ./dist/ deploy@web01:/srv/www/app/

rsync -avh deploy@web01:/etc/nginx/nginx.conf ./nginx.conf

rsync -avh --delete --exclude='.git' --exclude='node_modules' ./project/ /mnt/backup/project/
```

## 5) よくあるミスと安全ポイント
- **末尾スラッシュの違いに注意**: `src/` は中身を同期、`src` はディレクトリごと同期。意図がズレやすい。
- **`--delete` は必ず `-n` で先に確認**: 削除対象を見ずに本番実行すると事故りやすい。
- **権限不足や所有者保持に注意**: システム領域では `sudo` が必要なことがある。
- **まず小さい範囲で試す**: いきなり本番全体ではなく、1ディレクトリで挙動確認がおすすめ。

## 6) 追加学習（manページの読みどころ or related command）
- `man rsync` の **"USAGE"**, **"COPYING TO A DIFFERENT NAME"**, **"--delete" 周辺** を読むと事故が減る。
- 関連コマンド: `scp`（単純コピー）, `tar`（固めて運ぶ）, `cp -a`（ローカル保存属性つきコピー）
