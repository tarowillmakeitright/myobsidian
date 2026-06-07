# Linux Commands Magazine — 2026-06-07 09:15
Tags: #linux #commands #learning #devops #daily
Links: [[Home]]

## 1) 今日の1コマンド（command name + one-line summary）
**`rsync`** — ファイルを差分同期し、バックアップ・配布・移行を安全かつ効率よく進める定番コマンド。

## 2) 実務で使う場面（2-4 concrete scenarios）
- **設定ファイル配布**: 複数サーバへ `nginx` や `systemd` 設定を差分反映する。
- **バックアップ運用**: ログ・成果物・ホーム配下を日次で退避する。
- **デプロイ前後の同期**: ビルド成果物だけを本番/検証環境へ転送する。
- **大容量移行**: `scp` より再実行しやすく、途中失敗後の再送にも強い。

## 3) よく使うオプション（at least 3 options with explanation）
- `-a` : archive モード。再帰コピーしつつ、権限・時刻などをできるだけ保持。
- `-v` : 詳細表示。何が同期されたか確認しやすい。
- `-h` : サイズを人間向け表示（`1K`, `200M` など）。
- `--delete` : 送信元にないファイルを送信先から削除して完全同期する。
- `-n` : dry-run。実際には変更せず、何が起きるかだけ確認。
- `-z` : 転送時に圧縮。低速回線で有効。

## 4) 実例コマンド（at least 5 examples, copy-paste ready）
```bash
# 1) ローカルのディレクトリを別ディスクへバックアップ
rsync -avh /srv/data/ /backup/data/

# 2) 実行前に差分だけ確認（安全確認）
rsync -avhn --delete /srv/app/current/ /srv/app/staging/

# 3) SSH越しに設定ファイルをリモートへ同期
rsync -avh /etc/nginx/ deploy@web01:/etc/nginx/

# 4) 圧縮付きでログを退避
rsync -avhz /var/log/myapp/ backup@192.168.1.50:/data/backups/myapp-logs/

# 5) 除外指定付きでプロジェクト同期
rsync -avh --exclude '.git' --exclude 'node_modules' ./ deploy@web01:/opt/app/

# 6) 送信先を送信元と完全一致させる（要注意）
rsync -avh --delete /opt/releases/current/ deploy@web01:/opt/app/current/
```

## 5) よくあるミスと安全ポイント
- **末尾スラッシュの違い**に注意。`/src/` は「中身を同期」、`/src` は「srcディレクトリごと同期」になりやすい。
- `--delete` は便利だが危険。**まず `-n` 付きで確認**してから本実行する。
- 権限・所有者保持は環境次第で `sudo` が必要。システム領域同期では特に注意。
- 大量同期時は、まず小さい対象で試してパス誤りを潰すと事故が減る。

## 6) 追加学習（manページの読みどころ or related command）
- `man rsync` は **"FILTER RULES"**, **"COPYING TO A DIFFERENT NAME"**, **"--delete" 周辺** を先に読むと実務で効く。
- 関連: `scp`（単純コピー）, `tar`（固めて保管）, `ssh`（転送経路の基盤）。
