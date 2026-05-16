# Linux Commands Magazine — 2026-05-16 09:15
Tags: #linux #commands #learning #devops #daily
Links: [[Home]]

## 1) 今日の1コマンド（command name + one-line summary）
**`journalctl`** — systemd環境のログを時刻・サービス単位で高速に追跡できる、障害調査の中核コマンド。

## 2) 実務で使う場面（2-4 concrete scenarios）
- デプロイ直後にAPIが500を返し始めた時、対象サービスの直近ログだけを確認する。
- サーバ再起動後に「いつ」「なぜ」起動失敗したかをブート単位で切り分ける。
- 夜間障害で、特定時間帯（例: 02:00〜02:30）のエラー発生有無を監査する。
- 監視アラート発報時に、エラー優先度（warning/error）でノイズを減らして原因を見る。

## 3) よく使うオプション（at least 3 options with explanation）
- `-u <unit>` : 指定systemdユニット（例: `nginx.service`）のログに限定。
- `-b` : 現在ブート分のログのみ表示（再起動またぎの混在を防ぐ）。
- `-f` : リアルタイム追尾（`tail -f` 相当）。
- `--since` / `--until` : 時間範囲指定で調査範囲を絞る。
- `-p <priority>` : 優先度フィルタ（`err`, `warning` など）。
- `-n <lines>` : 末尾N行だけ表示して素早く状況確認。

## 4) 実例コマンド（at least 5 examples, copy-paste ready）
```bash
# 1) 現在ブートの全体ログを新しい順で確認
journalctl -b -r

# 2) nginxサービスの直近100行を確認
journalctl -u nginx.service -n 100

# 3) アプリサービスをリアルタイム追尾
journalctl -u myapp.service -f

# 4) 障害時間帯だけを抽出（時刻範囲）
journalctl --since "2026-05-16 02:00:00" --until "2026-05-16 02:30:00"

# 5) 現在ブートのエラー以上だけ確認
journalctl -b -p err

# 6) 1つ前のブートでの起動失敗調査
journalctl -b -1 -u myapp.service
```

## 5) よくあるミスと安全ポイント
- **ユニット名の指定ミス:** `myapp` と `myapp.service` を混同しがち。`systemctl status` で正確なユニット名を確認。
- **時間指定のタイムゾーン誤認:** 調査時はサーバTZを先に確認（`timedatectl`）。
- **ログ量が多すぎて見失う:** まず `-u` / `-p` / `--since` で範囲を狭める。
- **権限不足:** 一部ログは一般ユーザーでは見えない。必要時は `sudo` を使う。

## 6) 追加学習（manページの読みどころ or related command）
- `man journalctl` の **"FILTERING OPTIONS"** と **"OUTPUT OPTIONS"** を読むと、現場調査の速度が一気に上がる。
- 関連コマンド: `systemctl status <unit>`（状態確認）と `dmesg`（カーネルログ確認）。
