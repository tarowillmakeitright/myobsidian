# Linux Commands Magazine — 2026-05-17 09:15
Tags: #linux #commands #learning #devops #daily
Links: [[Home]]

## 1) 今日の1コマンド（command name + one-line summary）
**`rsync`** — 差分だけを高速・安全に同期できる、バックアップ/デプロイ/移行の定番コマンド。

## 2) 実務で使う場面（2-4 concrete scenarios）
- 本番リリース前に、ビルド成果物をアプリサーバへ差分転送する。
- 日次バックアップで、変更があったファイルだけNASへ複製する。
- サーバ移行時に、権限やタイムスタンプを保ったままホームディレクトリを移す。
- 大容量ログを調査環境へコピーする際、転送中断後の再開を行う。

## 3) よく使うオプション（at least 3 options with explanation）
- `-a` : アーカイブモード（再帰 + 権限/時刻/シンボリックリンク等を保持）。
- `-v` : 詳細表示。何が同期されたか追跡しやすい。
- `-h` : 人間に読みやすいサイズ表示（`1.2G` など）。
- `--delete` : 転送先にだけある不要ファイルを削除して完全同期。
- `--progress` : 転送進捗を表示（大きいファイルで有用）。
- `-n` (`--dry-run`) : 実行せず差分だけ確認（事故防止の最重要オプション）。

## 4) 実例コマンド（at least 5 examples, copy-paste ready）
```bash
# 1) ローカル同士を差分同期（末尾スラッシュで中身のみ同期）
rsync -avh /srv/app/ /backup/app/

# 2) リモートへデプロイ（SSH経由）
rsync -avh ./dist/ deploy@app01:/var/www/myapp/

# 3) 本番実行前に差分確認（安全確認）
rsync -avhn --delete /srv/app/ /backup/app/

# 4) 不要ファイルも含めてミラー同期
rsync -avh --delete /data/project/ ops@nas01:/volume1/project/

# 5) 転送進捗を見ながら大容量ファイル同期
rsync -avh --progress /var/log/archive/ analyst@lab01:/data/log-archive/

# 6) 特定拡張子だけ同期（例: 設定ファイル）
rsync -avh --include='*/' --include='*.conf' --exclude='*' /etc/ backup@cfg01:/snapshots/etc-conf/
```

## 5) よくあるミスと安全ポイント
- **末尾スラッシュの意味を誤る:** `/src` と `/src/` で同期結果が変わる。迷ったら `-n` で先に確認。
- **`--delete` を即本番投入する:** 誤指定で大量削除の危険。まず `--dry-run` を必ず実施。
- **権限不足で属性が崩れる:** 必要に応じて `sudo rsync` や実行ユーザーを見直す。
- **帯域圧迫:** 業務時間帯は `--bwlimit` の利用も検討（回線共有環境で有効）。

## 6) 追加学習（manページの読みどころ or related command）
- `man rsync` の **"FILTER RULES"** と **"INCLUDE/EXCLUDE PATTERN RULES"** は実務で特に重要。
- 関連コマンド: `scp`（単純コピー）、`tar`（固めて移送）、`ssh`（転送経路の基盤）。
