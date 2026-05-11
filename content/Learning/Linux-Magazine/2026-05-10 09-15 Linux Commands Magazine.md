# Linux Commands Magazine — 2026-05-10 09:15
Tags: #linux #commands #learning #devops #daily
Links: [[Home]]

## 1) 今日の1コマンド（command name + one-line summary）
**`xargs`** — 標準入力を安全に引数化して、複数対象への一括処理を高速化するコマンド。

## 2) 実務で使う場面（2-4 concrete scenarios）
- `find` の結果をそのまま削除・圧縮・権限変更へつなげる。
- ログ/CSV/ID一覧から対象サーバーやファイルへバッチ処理する。
- CI/CDで「変更ファイル一覧」に対して整形・検査・アップロードを実行する。
- 大量ファイル処理を並列化してメンテ時間を短縮する。

## 3) よく使うオプション（at least 3 options with explanation）
- `-0` : NUL区切り入力を扱う（空白・改行入りファイル名でも安全）。
- `-n <数>` : 1回の実行で渡す引数数を制限（例: `-n 1` で1件ずつ）。
- `-I {}` : プレースホルダ置換（コマンド中の `{}` に入力値を埋める）。
- `-P <数>` : 並列実行数を指定（I/O待ち処理の高速化に有効）。
- `-r` : 入力が空ならコマンドを実行しない（GNU環境で事故防止）。

## 4) 実例コマンド（at least 5 examples, copy-paste ready）
```bash
# 1) 古いログをgzip圧縮（ファイル名安全）
find /var/log/myapp -type f -name '*.log' -mtime +7 -print0 | xargs -0 -n 1 gzip

# 2) 1件ずつ権限を変更
find ./scripts -type f -name '*.sh' -print0 | xargs -0 -n 1 chmod 755

# 3) エラー行を含むログファイルだけ抽出して確認
grep -rl 'ERROR' ./logs | xargs -n 1 -I {} sh -c 'echo "--- {}"; tail -n 20 "{}"'

# 4) 画像最適化を4並列で実行
find ./public/img -type f -name '*.png' -print0 | xargs -0 -n 1 -P 4 optipng -quiet

# 5) 一覧ファイルのURLを順番にヘルスチェック
cat urls.txt | xargs -n 1 -I {} curl -fsS -o /dev/null -w '{} -> %{http_code}\n' {}
```

## 5) よくあるミスと安全ポイント
- **空白入りファイル名で壊れる**: `find ... -print0 | xargs -0` を基本形にする。
- **意図せぬ大量実行**: まず `echo` を付けてドライラン（例: `... | xargs -0 -n 1 echo rm`）。
- **並列で順序依存タスクを壊す**: 順番が必要な処理は `-P 1` か並列化しない。
- **入力ゼロ時の誤作動**: GNUなら `-r` を付ける。

## 6) 追加学習（manページの読みどころ or related command）
- `man xargs` の **`--max-args` / `--max-procs` / `--null`** を重点確認。
- 関連コマンド: `find`（探索）+ `xargs`（実行）+ `parallel`（高度な並列化）。
