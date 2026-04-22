---
tags: [linux, commands, learning, devops, daily]
---

# 2026-04-22 09:15 Linux Commands Magazine
[[Home]]

#linux #commands #learning #devops #daily

## 1) 今日の1コマンド（command name + one-line summary）
**`xargs`** — 標準入力で受け取った一覧を、実行可能なコマンド引数に安全かつ効率的に渡すコマンド。

## 2) 実務で使う場面（2-4 concrete scenarios）
- `find` の結果に対して一括で `grep` / `chmod` / `rm` などを適用したいとき
- CIで「変更されたファイルだけ」へ `lint` や `formatter` を当てるとき
- ログやID一覧を元に、API呼び出しや調査コマンドを並列実行したいとき
- 大量ファイル処理で、1件ずつでは遅い処理をまとめて実行したいとき

## 3) よく使うオプション（at least 3 options with explanation）
- `-0` : NUL区切り入力を扱う（空白・改行入りファイル名対策。`find -print0` とセット）
- `-I {}` : プレースホルダ置換（複雑な位置に引数を差し込みたいとき）
- `-n <数>` : 1回のコマンド実行で渡す引数数を制限
- `-P <数>` : 並列実行数を指定（CPU/I/Oに合わせて高速化）
- `-r` : 入力が空なら実行しない（無駄実行や誤爆を防ぐ）

## 4) 実例コマンド（at least 5 examples, copy-paste ready）
```bash
# 1) .log を圧縮（空白入りファイル名にも対応）
find /var/log/myapp -type f -name "*.log" -print0 | xargs -0 -r gzip -9

# 2) 変更された Python ファイルだけ整形（Git運用）
git diff --name-only origin/main...HEAD -- '*.py' | xargs -r black

# 3) /etc 配下で "PermitRootLogin" を含むファイルを調査
find /etc -type f -name "*.conf" -print0 | xargs -0 -r grep -n "PermitRootLogin"

# 4) 脆弱な権限のシェルスクリプトを修正（1回100件ずつ）
find ./scripts -type f -name "*.sh" -print0 | xargs -0 -r -n 100 chmod 750

# 5) URL一覧に対してHTTPステータス確認を並列実行
cat urls.txt | xargs -r -n 1 -P 8 -I {} sh -c 'printf "%s -> " "{}"; curl -s -o /dev/null -w "%{http_code}\n" "{}"'

# 6) old-config-* を安全確認してから削除（先にechoで確認）
find . -type f -name "old-config-*" -print0 | xargs -0 -r -n 1 echo rm -v
```

## 5) よくあるミスと安全ポイント
- 空白/改行入りファイル名で誤動作
  - `find -print0 | xargs -0` を基本形にする
- いきなり破壊系コマンド（`rm`, `chmod`, `chown`）を流す
  - まず `echo` を挟んで対象確認してから本実行
- 並列数 `-P` を上げすぎて負荷悪化
  - まず `-P 2〜4` から測定し、段階的に上げる
- 入力ゼロでもコマンドが実行されるケース
  - `-r` を付けて空入力実行を防ぐ

## 6) 追加学習（manページの読みどころ or related command）
- `man xargs` の **`-0` / `-I` / `-P` / `-n`** の挙動差を重点的に読む
- 関連コマンド: `find`（対象選定）, `parallel`（より高度な並列処理）
