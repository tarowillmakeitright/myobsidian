---
tags: [linux, commands, learning, devops, daily]
---

[[Home]]

# 2026-04-28 09:15 Linux Commands Magazine

## 1) 今日の1コマンド（command name + one-line summary）
**`tar`** — 複数ファイルを一括アーカイブ/展開して、バックアップや配布を効率化する定番コマンド。

## 2) 実務で使う場面（2-4 concrete scenarios）
- リリース前に設定ファイルや成果物を1つのアーカイブにまとめて保管/転送する
- 障害調査時に `/var/log/myapp` を固めてチームへ共有する
- 定期バックアップで「日付付きの圧縮アーカイブ」を作成して世代管理する
- CI/CDでビルド成果物を `tar.gz` にしてアーティファクト保存する

## 3) よく使うオプション（at least 3 options with explanation）
- `-c` : 新しいアーカイブを作成（create）
- `-x` : アーカイブを展開（extract）
- `-f <file>` : アーカイブファイル名を指定（ほぼ必須）
- `-z` : gzip圧縮を使用（`.tar.gz`）
- `-t` : 展開せずに中身一覧を確認（事故防止に有効）
- `-C <dir>` : 展開/収集時の作業ディレクトリを指定

## 4) 実例コマンド（at least 5 examples, copy-paste ready）
```bash
# 1) 設定ディレクトリを日付付きでtar.gz化
sudo tar -czf /backup/etc-$(date +%F).tar.gz /etc

# 2) ログディレクトリを固めて共有用アーカイブ作成
sudo tar -czf /tmp/myapp-logs-$(date +%F).tar.gz /var/log/myapp

# 3) 展開前に中身を確認（安全チェック）
tar -tf release-2026-04-28.tar.gz

# 4) /opt/app 配下に展開（展開先を明示）
sudo tar -xzf release-2026-04-28.tar.gz -C /opt/app

# 5) build/ の中身だけをアーカイブ化（親ディレクトリ名を含めない）
tar -czf build-artifacts.tar.gz -C build .
```

## 5) よくあるミスと安全ポイント
- **展開先を間違える**: `-C` を付けて展開先を明示する。`pwd` 確認してから実行。
- **上書き事故**: 本番環境で展開前に `tar -tf` で内容確認し、必要なら一度検証環境で展開する。
- **絶対パス混入**: アーカイブ作成時に不用意なパスを入れない（`-C` を使って相対パスで固める）。
- **容量逼迫**: 大きいアーカイブ作成時は保存先の空き容量を `df -h` で先に確認する。

## 6) 追加学習（manページの読みどころ or related command）
- `man tar` の **"OPERATION MODE"**（`-c/-x/-t`）と **"OPTIONS"**（`-C`, `--exclude`, `--strip-components`）を読むと実務で役立つ。
- 関連コマンド: `gzip`/`zstd`（圧縮方式）, `rsync`（差分同期）, `sha256sum`（配布物の整合性確認）。
