# Linux Commands Magazine — 2026-05-28 09:15
Tags: #linux #commands #learning #devops #daily
Links: [[Home]]

## 1) 今日の1コマンド（command name + one-line summary）
**`systemctl`** — systemdサービスの起動・停止・状態確認・自動起動設定を一元管理する運用必須コマンド。

## 2) 実務で使う場面（2-4 concrete scenarios）
- **障害一次対応**: APIサーバー（例: `nginx`, `docker`, `sshd`）が落ちた時に状態確認→再起動。
- **デプロイ後確認**: 新しく入れたサービスが正しく起動し、boot時自動起動になっているか検証。
- **定期メンテ**: 設定変更後にサービス再読込（reload）して無停止反映できるか確認。
- **監査/引き継ぎ**: どのサービスが有効化されているか一覧化して運用ドキュメント化。

## 3) よく使うオプション（at least 3 options with explanation）
- `status <unit>` : サービス状態・直近ログ・終了コードを確認。
- `--now` : `enable`/`disable` と同時に今すぐ開始/停止（設定と実行状態を一発で揃える）。
- `--failed` : 失敗状態のunitだけを一覧表示（障害調査の起点）。
- `-l` : 長い行を省略せず表示（エラー全文を確認しやすい）。
- `--type=service` : service unit のみに絞って一覧表示。

## 4) 実例コマンド（at least 5 examples, copy-paste ready）
```bash
# 1) nginx の状態を詳細確認
systemctl status nginx -l

# 2) サービスを再起動（設定反映や復旧時）
sudo systemctl restart nginx

# 3) 起動時の自動起動を有効化し、今すぐ起動
sudo systemctl enable --now docker

# 4) 失敗しているサービスだけを確認
systemctl --failed --type=service

# 5) sshd が有効化されているか確認
systemctl is-enabled sshd

# 6) サービスが稼働中かをスクリプト向けに判定
systemctl is-active --quiet cron && echo "cron is running"
```

## 5) よくあるミスと安全ポイント
- **unit名の取り違え**: `ssh` と `sshd` などディストリ差異あり。`systemctl list-unit-files | grep <name>` で先に確認。
- **`restart` 多用で瞬断**: 無停止で済むなら `reload` を優先（対応していないサービスもあるので `systemctl reload <unit>` の結果確認）。
- **`enable` だけで満足**: 自動起動設定だけで今は動かない。即時反映したいなら `enable --now`。
- **root権限不足**: 参照はできても変更は不可。変更系は `sudo` 前提で実行。

## 6) 追加学習（manページの読みどころ or related command）
- `man systemctl` は **「Unit Commands」「Unit File Commands」「Exit Status」** を優先して読むと現場で効く。
- 関連コマンド: `journalctl`（ログ追跡）, `systemd-analyze`（起動時間解析）, `loginctl`（セッション管理）。
