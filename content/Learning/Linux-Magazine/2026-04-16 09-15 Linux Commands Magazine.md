---
tags: [linux, commands, learning, devops, daily]
---

# 2026-04-16 09:15 Linux Commands Magazine
[[Home]]

#linux #commands #learning #devops #daily

## 1) 今日の1コマンド（command name + one-line summary）
**`rsync`** — ローカル/リモート間で差分だけを高速・安全に同期できる定番コマンド。

## 2) 実務で使う場面（2-4 concrete scenarios）
- デプロイ前に `build/` 成果物をサーバへ差分転送するとき
- 日次バックアップで、変更ファイルだけをNASへ複製したいとき
- サーバ移行時に `/var/www` や `/etc` を段階的にコピーするとき
- 大量ファイルの同期で `scp` より再実行しやすい手順を作りたいとき

## 3) よく使うオプション（at least 3 options with explanation）
- `-a` : アーカイブモード（再帰 + パーミッション/時刻などを保持）
- `-v` : 詳細表示（何を同期したか追える）
- `-h` : 人間に読みやすいサイズ表示（`-avh` で定番）
- `--delete` : 転送元にないファイルを転送先から削除（ミラー運用向け、慎重に）
- `-n` / `--dry-run` : 実際には変更せず、実行結果だけ確認（本番前の安全確認）
- `-z` : 圧縮して転送（回線が細いときに有効）

## 4) 実例コマンド（at least 5 examples, copy-paste ready）
```bash
# 1) ローカル同士でプロジェクトを差分同期
rsync -avh ./project/ /backup/project/

# 2) 実行前に差分だけ確認（安全）
rsync -avhn --delete ./public/ /srv/www/public/

# 3) SSH経由でリモートへデプロイ
rsync -avhz -e ssh ./dist/ deploy@app01:/var/www/app/

# 4) リモートからローカルへログ回収
rsync -avh -e ssh ops@app01:/var/log/nginx/ ./logs/nginx/

# 5) 除外指定つきで同期（node_modulesを除外）
rsync -avh --exclude 'node_modules' --exclude '.git' ./ /tmp/work-copy/

# 6) 途中中断に強い大容量転送（再開しやすい）
rsync -avh --partial --progress -e ssh /data/archive.tar ops@backup01:/data/incoming/
```

## 5) よくあるミスと安全ポイント
- **ミス:** 末尾スラッシュの違いを誤解する（`src/` と `src` で結果が変わる）
  - **安全:** 事前に `--dry-run` で転送先のディレクトリ構造を確認
- **ミス:** `--delete` をいきなり本番で使って必要ファイルを消す
  - **安全:** まず `-n --delete` で削除対象を確認してから本実行
- **ミス:** 権限不足で一部だけ失敗し、同期完了したと勘違い
  - **安全:** 終了コード確認（`echo $?`）とログ保存（`| tee rsync.log`）を習慣化

## 6) 追加学習（manページの読みどころ or related command）
- `man rsync` の **"USAGE"**, **"FILTER RULES"**, **"EXAMPLES"** を重点的に読むと実務で困りにくい
- 関連コマンド: `scp`（単純コピー）, `tar`（アーカイブ化）, `ssh`（転送経路の基盤）
