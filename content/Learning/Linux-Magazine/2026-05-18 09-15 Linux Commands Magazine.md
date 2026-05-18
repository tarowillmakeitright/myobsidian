# Linux Commands Magazine — 2026-05-18 09:15
Tags: #linux #commands #learning #devops #daily
Links: [[Home]]

## 1) 今日の1コマンド（command name + one-line summary）
**`find`** — 条件を組み合わせて大量ファイルから目的物を正確に探し、後続処理まで一気に回せる検索コマンド。

## 2) 実務で使う場面（2-4 concrete scenarios）
- ログ肥大時に「7日より古い`.log`」を洗い出して圧縮/削除候補を確認する。
- デプロイ前に、誤って残った秘密鍵や`.env`ファイルをリポジトリ配下から検出する。
- CI失敗時に、特定拡張子（例: `*.tmp`, `*.pyc`）の残骸を一括で特定する。
- 権限監査で、書き込み可能すぎるファイル（例: `-perm /o+w`）を抽出する。

## 3) よく使うオプション（at least 3 options with explanation）
- `-name <pattern>` : ファイル名パターンで検索（ワイルドカード可、通常は引用符で囲む）。
- `-type f|d` : 種別指定（`f`=ファイル, `d`=ディレクトリ）。
- `-mtime +N` : N日より古い（`-mtime -N` はN日以内）。
- `-maxdepth N` : 探索深さを制限して高速化・誤爆防止。
- `-size +100M` : サイズ条件で抽出（容量整理で有効）。
- `-exec ... {} \;` : 見つかった各ファイルにコマンド実行（安全に段階実行しやすい）。

## 4) 実例コマンド（at least 5 examples, copy-paste ready）
```bash
# 1) カレント配下の .log を検索
find . -type f -name '*.log'

# 2) /var/log 配下の 7日より古いログを確認
find /var/log -type f -name '*.log' -mtime +7

# 3) リポジトリで .env を検出（深さ2まで）
find . -maxdepth 2 -type f -name '.env'

# 4) 100MB超のファイルを抽出
find /srv -type f -size +100M

# 5) 30日より古い .tmp を削除前に確認
find /tmp -type f -name '*.tmp' -mtime +30

# 6) 確認後に削除（本番はまず上の確認コマンド実行）
find /tmp -type f -name '*.tmp' -mtime +30 -exec rm -f {} \;
```

## 5) よくあるミスと安全ポイント
- **いきなり`-exec rm`しない**：まず同条件で一覧表示して対象確認。
- **ワイルドカード未クォート**：`'*.log'`のように引用しないとシェル展開で誤動作する。
- **検索範囲が広すぎる**：`/`起点は重い＆危険。`-maxdepth`や対象ディレクトリを絞る。
- **権限不足を見落とす**：`Permission denied`が混じるので、必要に応じて`sudo`で再実行。

## 6) 追加学習（manページの読みどころ or related command）
- `man find` の **“OPERATORS”**（`-and`, `-or`, `!`）と **“ACTIONS”**（`-print`, `-delete`, `-exec`）を重点的に読む。
- 関連コマンド：`xargs`（find結果をまとめて後続処理）、`locate`（事前インデックスで高速検索）。
