# Linux Commands Magazine — 2026-05-20 09:15
Tags: #linux #commands #learning #devops #daily
Links: [[Home]]

## 1) 今日の1コマンド（command name + one-line summary）
**`rsync`** — 差分だけを高速・安全に同期して、バックアップやデプロイを効率化する定番コマンド。

## 2) 実務で使う場面（2-4 concrete scenarios）
- アプリ配布前に、ビルド成果物だけを本番サーバへ差分転送する。
- 日次バックアップで、変更があったファイルのみ外部ディスクへコピーして時間短縮する。
- 設定ファイルを複数サーバ間で揃え、不要ファイルも整理してドリフトを防ぐ。
- 大容量ログを検証環境へ複製し、途中失敗後も再開して転送し直す。

## 3) よく使うオプション（at least 3 options with explanation）
- `-a` : アーカイブモード（権限・時刻・再帰を保持）。
- `-v` : 詳細表示（何が同期されたか確認しやすい）。
- `-h` : サイズを人間向け表示（`-avh`で定番）。
- `--delete` : 転送元にないファイルを転送先から削除（ミラー運用向け）。
- `--progress` : 転送進捗を表示（大きいファイルで安心）。
- `-n` (`--dry-run`) : 実行せず差分だけ確認（事故防止の必須手順）。

## 4) 実例コマンド（at least 5 examples, copy-paste ready）
```bash
# 1) ローカルの作業ディレクトリをバックアップ先へ差分同期
rsync -avh ~/work/ /mnt/backup/work/

# 2) 実行前に dry-run で差分確認
rsync -avhn --delete ~/work/ /mnt/backup/work/

# 3) SSH経由でリモートへ同期（デプロイ向け）
rsync -avh --progress ./dist/ deploy@app01:/srv/app/current/

# 4) リモートからローカルへログ回収
rsync -avh ops@app01:/var/log/nginx/ ./logs/nginx/

# 5) 除外指定つきで同期（node_modulesを除外）
rsync -avh --exclude 'node_modules/' ./project/ /mnt/backup/project/

# 6) 帯域制限をかけて夜間同期（回線圧迫を回避）
rsync -avh --bwlimit=5000 /data/ backup@nas:/volume1/data/
```

## 5) よくあるミスと安全ポイント
- **末尾スラッシュの違いを誤る**：`src/` は中身、`src` はディレクトリ自体をコピー。意図を毎回確認。
- **`--delete`を即本実行する**：先に `-n` で削除対象を確認してから実行。
- **権限不足で属性が揃わない**：必要に応じて `sudo` や実行ユーザーを見直す。
- **巨大同期を一発本番で行う**：小さな対象で検証してから本番適用する。

## 6) 追加学習（manページの読みどころ or related command）
- `man rsync` の **"USAGE"** と **"FILTER RULES"**（`--exclude`/`--include`）を先に読むと実務で効く。
- 関連コマンド：`scp`（単純コピー）、`tar`（まとめて固めて転送）。
