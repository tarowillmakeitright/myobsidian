---
tags: [linux, commands, learning, devops, daily]
---

# 2026-04-19 09:15 Linux Commands Magazine
[[Home]]

#linux #commands #learning #devops #daily

## 1) 今日の1コマンド（command name + one-line summary）
**`systemctl`** — systemdサービスの起動・停止・状態確認を一元管理する運用必須コマンド。

## 2) 実務で使う場面（2-4 concrete scenarios）
- デプロイ後に `myapp.service` を再起動し、正常起動したか即確認するとき
- 障害対応で `nginx` や `docker` が落ちていないか状態確認するとき
- サーバ再起動後に「自動起動が有効か」を点検するとき
- 設定変更後に `daemon-reload` して新しい unit 定義を反映するとき

## 3) よく使うオプション（at least 3 options with explanation）
- `status <unit>` : サービスの現在状態・直近ログ・終了コードを確認
- `--now` : 有効化/無効化と同時に起動/停止も実行（`enable --now` など）
- `--failed` : 失敗状態の unit だけ一覧表示して障害初動を速くする
- `-l` : status出力を省略せずフル表示（長いログ行の確認に便利）

## 4) 実例コマンド（at least 5 examples, copy-paste ready）
```bash
# 1) サービス状態を確認（詳細）
systemctl status -l nginx

# 2) アプリを再起動して状態確認
sudo systemctl restart myapp
systemctl status myapp --no-pager

# 3) OS起動時に自動起動を有効化し、今すぐ起動
sudo systemctl enable --now docker

# 4) 失敗したサービスだけ確認
systemctl --failed

# 5) unitファイル変更後に再読込して再起動
sudo systemctl daemon-reload
sudo systemctl restart myapp

# 6) 自動起動が有効か確認
systemctl is-enabled sshd
```

## 5) よくあるミスと安全ポイント
- unit名ミス（例: `nginx` と `nginx.service` の混同）で対象を間違える
  - `systemctl list-unit-files | grep <name>` で正式名を確認
- `daemon-reload` を忘れて変更が反映されない
  - unit編集後は `daemon-reload` → `restart` をセットで実施
- いきなり本番で `stop` して停止事故
  - まず `status` と依存関係（`list-dependencies`）を確認してから操作

## 6) 追加学習（manページの読みどころ or related command）
- `man systemctl` の **COMMANDS**（`start/stop/restart/status/enable`）と **UNIT COMMANDS** を先に読むと実務で使いやすい
- 関連コマンド: `journalctl -u <unit>`（対象サービスのログ深掘り）
