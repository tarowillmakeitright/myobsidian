# Linux Commands Magazine — 2026-05-14 09:15
Tags: #linux #commands #learning #devops #daily
Links: [[Home]]

## 1) 今日の1コマンド（command name + one-line summary）
**`rsync`** — ローカル/リモート間の差分同期を安全かつ高速に行う、バックアップ・配布の定番コマンド。

## 2) 実務で使う場面（2-4 concrete scenarios）
- 本番反映前に、ビルド成果物をステージング/本番サーバへ差分転送する。
- 日次バックアップで、変更があったファイルだけをNASや別ディスクへ同期する。
- 障害復旧時に、旧サーバから新サーバへデータを再配置する。
- 大容量ログやアセットを再送する際、途中再開して転送時間を短縮する。

## 3) よく使うオプション（at least 3 options with explanation）
- `-a` : アーカイブモード（再帰 + パーミッション/時刻/シンボリックリンク保持）。
- `-v` : 詳細表示（何が同期されたか確認しやすい）。
- `-h` : サイズを読みやすく表示（K/M/G）。
- `--delete` : 送信元にないファイルを送信先から削除（ミラー同期向け）。
- `--progress` : 転送進捗を表示（大きいファイルで有用）。
- `-z` : 圧縮転送（低速回線で有効）。

## 4) 実例コマンド（at least 5 examples, copy-paste ready）
```bash
# 1) ローカル同士の差分バックアップ
rsync -avh ~/projects/ /mnt/backup/projects/

# 2) リモートへデプロイ（SSH経由）
rsync -avhz ./dist/ deploy@app01:/var/www/app/

# 3) 進捗を見ながら大容量データ同期
rsync -avh --progress /data/archive/ backup@10.0.0.20:/srv/archive/

# 4) 削除も含めてミラー同期（本番前に要注意）
rsync -avh --delete ./public/ deploy@web01:/var/www/public/

# 5) dry-runで変更確認してから実行
rsync -avhn --delete ./config/ ops@server:/etc/myapp/

# 6) 通信ポート指定（SSH 2222）
rsync -avh -e "ssh -p 2222" ./ release@host:/opt/release/
```

## 5) よくあるミスと安全ポイント
- **末尾スラッシュの意味を誤る:** `src/` は中身を同期、`src` はディレクトリごと同期。意図どおりか毎回確認。
- **`--delete` の誤用:** 送信先ファイルが消える。必ず最初は `-n`（dry-run）で差分確認。
- **権限不足で失敗:** `/var/www` や `/etc` は権限が必要。必要に応じて接続先側で権限設計を見直す。
- **ネットワーク断の再送コスト:** 大容量では `--partial` や再実行前提の運用にしておく。

## 6) 追加学習（manページの読みどころ or related command）
- `man rsync` の **"TRANSFER RULES"** と **"FILTER RULES"** を読むと、除外（`--exclude`）と削除挙動の理解が一気に深まる。
- 関連コマンド: `scp`（単純コピー向け）、`tar`（固めて転送/保管する用途）。
