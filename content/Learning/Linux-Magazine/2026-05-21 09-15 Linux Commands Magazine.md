# Linux Commands Magazine — 2026-05-21 09:15
Tags: #linux #commands #learning #devops #daily
Links: [[Home]]

## 1) 今日の1コマンド（command name + one-line summary）
**`journalctl`** — systemdジャーナルを時系列・サービス単位で絞り込み、障害調査を高速化するログ閲覧コマンド。

## 2) 実務で使う場面（2-4 concrete scenarios）
- デプロイ直後にAPIが落ちたとき、`nginx` や `app.service` の直近エラーを確認する。
- サーバ再起動後の不具合で、「前回起動」時のログだけ抜き出して原因を切り分ける。
- 夜間障害の報告時に、発生時刻帯（例: 02:00–02:20）のログだけを抽出して共有する。
- 監視アラート発報時、カーネルログと対象サービスログを合わせて確認する。

## 3) よく使うオプション（at least 3 options with explanation）
- `-u <unit>` : 指定サービス（例: `nginx.service`）のログに限定。
- `-b` : 現在の起動分のみ表示（`-b -1` で前回起動分）。
- `--since` / `--until` : 時間範囲で絞り込み。
- `-p <priority>` : 重要度で絞る（例: `err`, `warning`）。
- `-f` : `tail -f` のようにリアルタイム追従。
- `-n <lines>` : 末尾N行だけ表示（まず状況把握したい時に有効）。

## 4) 実例コマンド（at least 5 examples, copy-paste ready）
```bash
# 1) 直近100行のシステムログを確認
journalctl -n 100

# 2) nginxサービスの直近200行を確認
journalctl -u nginx.service -n 200

# 3) 今日の0時以降のエラーログのみ確認
journalctl --since today -p err

# 4) 前回起動時のログを確認（再起動後トラブル調査）
journalctl -b -1

# 5) 特定時間帯だけ抽出
journalctl --since '2026-05-21 02:00:00' --until '2026-05-21 02:20:00'

# 6) サービスログをリアルタイム監視
journalctl -u docker.service -f
```

## 5) よくあるミスと安全ポイント
- **時間指定の解釈ミス**：`--since '1 hour ago'` など相対指定は便利だが、調査報告は絶対時刻も併記すると安全。
- **権限不足で見えない**：詳細ログが出ない時は `sudo journalctl ...` を試す。
- **ログ量を一気に表示して見失う**：まず `-n` や `-p err` で絞ってから広げる。
- **再起動跨ぎを見落とす**：`-b` / `-b -1` を使い分け、どのブートのログか明確にする。

## 6) 追加学習（manページの読みどころ or related command）
- `man journalctl` の **"FILTERING OPTIONS"**（`-u`, `-p`, `--since`）と **"OUTPUT OPTIONS"** を先に読むと実務で即使える。
- 関連コマンド：`systemctl status <unit>`（状態確認）、`dmesg`（カーネルリングバッファ確認）。
