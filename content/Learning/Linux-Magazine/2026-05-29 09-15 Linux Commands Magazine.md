# Linux Commands Magazine — 2026-05-29 09:15
Tags: #linux #commands #learning #devops #daily
Links: [[Home]]

## 1) 今日の1コマンド（command name + one-line summary）
**`rsync`** — ファイルを差分同期して、バックアップ・デプロイ・移行を高速かつ安全に行う定番コマンド。

## 2) 実務で使う場面（2-4 concrete scenarios）
- **本番デプロイ前の静的ファイル反映**: 変更分だけをサーバーへ転送して時間短縮。
- **日次バックアップ**: ローカル→外付けディスク/別サーバーへ差分バックアップ。
- **サーバー移行**: 旧環境から新環境へ、権限やタイムスタンプを保ったままコピー。
- **大容量ログ収集**: 必要ディレクトリだけ圧縮転送して調査用に回収。

## 3) よく使うオプション（at least 3 options with explanation）
- `-a` : アーカイブモード（再帰 + パーミッション/時刻などを保持）。
- `-v` : 詳細表示（何が同期されたか確認しやすい）。
- `-h` : 人間に読みやすいサイズ表示（`1.2G` など）。
- `--delete` : 転送先にだけある不要ファイルを削除して完全同期。
- `--dry-run` : 実行せず結果だけ確認（事故防止に必須）。
- `-z` : 転送時に圧縮（低速回線で有効）。

## 4) 実例コマンド（at least 5 examples, copy-paste ready）
```bash
# 1) ディレクトリをローカルで差分バックアップ
rsync -avh ~/projects/myapp/ /mnt/backup/myapp/

# 2) 実行前に差分だけ確認（安全確認）
rsync -avhn --delete ~/projects/myapp/ /mnt/backup/myapp/

# 3) SSH越しにサーバーへデプロイ
rsync -avhz ./dist/ deploy@web01:/var/www/myapp/

# 4) 特定ファイルを除外して同期
rsync -avh --exclude '.git/' --exclude 'node_modules/' ~/projects/myapp/ backup@nas:/data/myapp/

# 5) サーバーからログを回収
rsync -avh ops@app01:/var/log/myapp/ ~/incident-logs/app01/

# 6) 帯域を抑えて夜間同期（KB/s指定）
rsync -avh --bwlimit=5000 /data/archive/ backup@storage:/backup/archive/
```

## 5) よくあるミスと安全ポイント
- **末尾スラッシュの意味を誤解**: `src/` は中身だけ、`src` はディレクトリごとコピー。意図を統一する。
- **`--delete` の誤爆**: 便利だが危険。まず `--dry-run` で削除対象を必ず確認。
- **権限不足で不完全同期**: システム領域は `sudo` が必要なことがある（読み取り元/書き込み先両方確認）。
- **ネットワーク切断時の過信**: 重要データはログ保存（`--log-file`）や再実行前提で運用する。

## 6) 追加学習（manページの読みどころ or related command）
- `man rsync` は **「USAGE」「INCLUDE/EXCLUDE PATTERN RULES」「--delete」** 周辺を先に読むと事故が減る。
- 関連コマンド: `scp`（単純コピー）, `tar`（固めて転送）, `rclone`（クラウド同期）。
