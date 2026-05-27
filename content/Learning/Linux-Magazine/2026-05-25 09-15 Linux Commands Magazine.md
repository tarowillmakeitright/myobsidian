# Linux Commands Magazine — 2026-05-25 09:15
Tags: #linux #commands #learning #devops #daily
Links: [[Home]]

## 1) 今日の1コマンド（command name + one-line summary）
**`tar`** — 複数ファイル/ディレクトリを1つに固め、バックアップ・配布・保管を効率化する標準コマンド。

## 2) 実務で使う場面（2-4 concrete scenarios）
- **障害調査のログ退避**: `/var/log` 配下をまとめて保存し、他チームへ共有。
- **デプロイ成果物の受け渡し**: ビルド成果物を1ファイル化して転送・展開。
- **設定バックアップ**: `/etc` やアプリ設定を日次でアーカイブして世代管理。
- **監査証跡の保管**: 月次で証跡ファイルを圧縮し、容量を抑えて長期保存。

## 3) よく使うオプション（at least 3 options with explanation）
- `-c` : 新規アーカイブを作成する（create）。
- `-x` : アーカイブを展開する（extract）。
- `-f` : アーカイブファイル名を指定する（必須級）。
- `-z` : gzip圧縮を使う（`.tar.gz`）。
- `-t` : 展開せず中身一覧だけ確認する。
- `-C <dir>` : 指定ディレクトリへ移動してから展開/収集する。

## 4) 実例コマンド（at least 5 examples, copy-paste ready）
```bash
# 1) 設定ファイルを日付付きでgzip圧縮バックアップ
sudo tar -czf /backup/etc-$(date +%F).tar.gz /etc

# 2) 調査用にアプリログを固める
tar -czf app-logs-$(date +%F).tar.gz /var/log/myapp

# 3) アーカイブ内容を展開前に確認
tar -tzf app-logs-2026-05-25.tar.gz

# 4) 任意ディレクトリへ展開
mkdir -p /tmp/restore && tar -xzf app-logs-2026-05-25.tar.gz -C /tmp/restore

# 5) 配布物ディレクトリをアーカイブ化（相対パスをきれいに保つ）
tar -C /srv/releases -czf webapp-release-2026-05-25.tar.gz webapp

# 6) 圧縮なしで高速アーカイブ（同一サーバー内の一時退避向け）
tar -cf data-snapshot.tar /srv/data
```

## 5) よくあるミスと安全ポイント
- **展開先ミス**: カレントディレクトリに展開されて散らかる。`-C` で展開先を明示。
- **上書き事故**: 既存ファイルへ上書きされる可能性あり。まず `-t` で内容確認。
- **絶対パスの扱い**: 受け渡し用は `-C` を使って相対パス化すると安全。
- **権限不足**: `/etc` などは `sudo` が必要。失敗ログを見落とさない。

## 6) 追加学習（manページの読みどころ or related command）
- `man tar` の **“OPTIONS”** と **“EXAMPLES”** を先に読むと、作成/展開/一覧の使い分けが速くなる。
- 関連コマンド: `gzip`（単体圧縮）, `zstd`（高速高圧縮）, `rsync`（差分同期）。
