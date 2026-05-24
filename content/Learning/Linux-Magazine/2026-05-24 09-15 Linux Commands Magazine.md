# Linux Commands Magazine — 2026-05-24 09:15
Tags: #linux #commands #learning #devops #daily
Links: [[Home]]

## 1) 今日の1コマンド（command name + one-line summary）
**`rsync`** — 大量ファイルの差分同期を高速・安全に行う、バックアップ/配布の定番コマンド。

## 2) 実務で使う場面（2-4 concrete scenarios）
- **本番デプロイ前の成果物転送**: ビルド済みディレクトリだけ差分でサーバーへ反映する。
- **定期バックアップ**: ローカル→外部ディスク/別サーバーへ増分コピーする。
- **ログ回収**: 複数サーバーのログを管理ノードに集約する。
- **障害復旧**: 退避先から必要なディレクトリだけ迅速に戻す。

## 3) よく使うオプション（at least 3 options with explanation）
- `-a` : アーカイブモード（再帰 + パーミッション/時刻/リンク等を保持）。
- `-v` : 詳細表示（何を同期したか確認しやすい）。
- `-h` : サイズを人間向け表示（K/M/G）。
- `--delete` : 送信元にないファイルを送信先から削除（完全ミラー時に使用）。
- `--progress` : 転送進捗を表示（大容量転送時に便利）。
- `-n` / `--dry-run` : 実際には変更せず、実行結果だけ確認。

## 4) 実例コマンド（at least 5 examples, copy-paste ready）
```bash
# 1) ローカルのディレクトリを別ディスクへ差分バックアップ
rsync -avh /srv/data/ /mnt/backup/data/

# 2) dry-run で削除含む同期内容を事前確認
rsync -avhn --delete /srv/data/ /mnt/backup/data/

# 3) SSH経由で本番サーバーへデプロイ成果物を同期
rsync -avh --progress -e ssh ./dist/ deploy@app01:/var/www/app/

# 4) 帯域を抑えて夜間同期（KB/s指定）
rsync -avh --bwlimit=5000 /var/log/ backup@store01:/data/log-archive/

# 5) 更新ファイルだけを別サーバーから回収
rsync -avh --update ops@db01:/var/backups/ /restore/staging/

# 6) 除外ルールを使って不要物を除いて同期
rsync -avh --exclude='.git/' --exclude='node_modules/' ./project/ backup@store01:/data/project/
```

## 5) よくあるミスと安全ポイント
- **末尾スラッシュの意味違い**: `/src` と `/src/` で同期先構造が変わる。実行前に必ず確認。
- **`--delete` の誤用**: 便利だが破壊力が高い。まず `--dry-run` で差分確認してから本実行。
- **権限不足で属性保持失敗**: システム領域は `sudo rsync` が必要な場合がある。
- **ネットワーク切断時の再実行**: `rsync` は差分再開に強い。焦って `cp` に切り替えない。

## 6) 追加学習（manページの読みどころ or related command）
- `man rsync` の **“USAGE”** と **“FILTER RULES”** を読むと、除外/包含の設計ミスが減る。
- 関連コマンド: `scp`（単純コピー向け）, `tar`（固めて配布する時）。
