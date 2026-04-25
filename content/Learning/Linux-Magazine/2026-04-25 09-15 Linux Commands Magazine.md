---
tags: [linux, commands, learning, devops, daily]
---

[[Home]]

# 2026-04-25 09:15 Linux Commands Magazine

## 1) 今日の1コマンド（command name + one-line summary）
**`rsync`** — ローカル/リモート間のファイル同期を、差分だけ高速・安全に行う定番コマンド。

## 2) 実務で使う場面（2-4 concrete scenarios）
- デプロイ時に、成果物だけをサーバへ差分転送して反映時間を短縮する
- 定期バックアップで、変更分だけNASや別ディスクへ同期する
- 障害調査前に `/etc` や設定ディレクトリを退避して変更リスクを下げる
- 大容量ログ/アセットを複数サーバへ配布するときに帯域を節約する

## 3) よく使うオプション（at least 3 options with explanation）
- `-a` : アーカイブモード（再帰＋権限/時刻/シンボリックリンクなどを保持）
- `-v` : 詳細表示（何が転送されたか確認しやすい）
- `-h` : 人間向けサイズ表示（KB/MB/GB）
- `--delete` : 送信元にないファイルを送信先から削除（ミラー同期向け）
- `--dry-run` : 実際には変更せず、実行結果だけ確認（本番前の安全確認）

## 4) 実例コマンド（at least 5 examples, copy-paste ready）
```bash
# 1) ローカルの build/ をサーバへ差分反映
rsync -avh ./build/ deploy@app01:/var/www/app/

# 2) 設定ディレクトリを日付付きでバックアップ
rsync -avh /etc/ /backup/etc-$(date +%F)/

# 3) 本番実行前に削除差分まで確認（安全確認）
rsync -avh --delete --dry-run ./public/ deploy@app01:/var/www/public/

# 4) SSHポート2222経由で同期
rsync -avh -e "ssh -p 2222" ./artifact/ ops@10.0.0.20:/opt/artifact/

# 5) ログを圧縮転送しつつ同期（低速回線向け）
rsync -avhz /var/log/myapp/ backup@10.0.0.30:/data/log/myapp/
```

## 5) よくあるミスと安全ポイント
- **末尾スラッシュの違いに注意**: `src/` は「中身をコピー」、`src` は「srcディレクトリごとコピー」。
- **`--delete` は必ず `--dry-run` で確認してから**: 宛先の消えて困るファイルを誤削除しやすい。
- **権限不足/所有者不一致に注意**: 必要に応じて実行ユーザーや `sudo` を調整する。

## 6) 追加学習（manページの読みどころ or related command）
- `man rsync` の **"USAGE"**, **"FILTER RULES"**, **"INCLUDE/EXCLUDE"** を読むと実務で一気に強くなる。
- 関連コマンド: `scp`（単純コピー）, `tar`（固めて転送）, `rclone`（クラウド同期）。
