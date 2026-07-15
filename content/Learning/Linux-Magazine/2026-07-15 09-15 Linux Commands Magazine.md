---
date: 2026-07-15 09:15
tags:
  - linux
  - commands
  - learning
  - devops
  - daily
---

# Linux Commands Magazine — 2026-07-15 09:15

#linux #commands #learning #devops #daily

[[Home]]

## 1) 今日の1コマンド

**`namei`** — パスを構成する各階層の種類・権限・所有者を表示し、「なぜアクセスできないか」を切り分けるコマンド。

## 2) 実務で使う場面

- Webサーバーやアプリが設定・証明書・ソケットを読めない原因を調べる。
- `Permission denied` 発生時、親ディレクトリの実行権限（`x`）不足を特定する。
- シンボリックリンクがどこへ解決されるか、途中で循環していないか確認する。
- デプロイ先のパスについて、所有者・グループ・権限を階層ごとに監査する。

## 3) よく使うオプション

- `-l`：各階層のパーミッション、所有者、グループを一覧表示する。
- `-m`：各階層を `ls -l` 風のモード文字列付きで表示する。
- `-o`：所有者とグループ名を表示する（`-l` 相当の詳細確認向け）。
- `-v`：結果を縦方向に揃えて表示し、長いパスを読みやすくする。
- `-x`：マウントポイントを越えた箇所を識別しやすく表示する。

## 4) 実例コマンド

```bash
# 1) パスの各階層とシンボリックリンク解決を確認
namei /var/www/app/current/config.yml

# 2) 各階層の権限・所有者・グループを確認
namei -l /etc/nginx/ssl/server.key

# 3) アプリ用ソケットまでの権限を縦表示で確認
namei -lv /run/myapp/app.sock

# 4) 相対パスを絶対パス化してから階層を調査
namei -l "$(realpath ./deploy/releases/current)"

# 5) 複数パスをまとめて監査
namei -l /etc/ssh/sshd_config /etc/systemd/system/myapp.service

# 6) マウントポイントを含むバックアップ先を確認
namei -lx /mnt/backup/daily/archive.tar.zst
```

## 5) よくあるミスと安全ポイント

- ファイル自身が読めても、途中のディレクトリに `x` がなければ到達できない。全階層を見る。
- `namei` は診断専用で権限を変更しない。原因確認後も、安易な `chmod -R 777` は避ける。
- 実際のサービス権限で確認するなら、`sudo -u www-data test -r /対象/パス` のように `test` を併用する。
- ディストリビューションにより未導入の場合がある。通常は `util-linux` パッケージに含まれる。

## 6) 追加学習

`man namei` では、シンボリックリンクの展開表示と `-l` / `-x` の出力差を確認する。関連コマンドは `realpath`（正規化した絶対パス）、`stat`（対象単体の詳細）、`test -r/-x`（実効的なアクセス可否）。
