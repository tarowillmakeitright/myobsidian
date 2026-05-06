---
tags: [linux, commands, learning, devops, daily]
---

# Daily Linux Commands Magazine - 2026-05-06
[[Home]]

## 1) 今日の1コマンド（command name + one-line summary）
**`find`** — 条件を組み合わせて大量ファイルから目的物を正確に探し、後続処理までつなげる定番コマンド。

## 2) 実務で使う場面（2-4 concrete scenarios）
- サーバ障害時に、直近更新されたログやコアダンプだけを素早く抽出する。
- 容量圧迫時に、大きいファイルや古いバックアップを棚卸しして削除候補を出す。
- CI/CDで成果物（例: `*.jar`, `*.tar.gz`）だけを収集して配布処理へ渡す。
- 設定変更時に、特定拡張子のファイルへ一括処理（権限変更/検査）をかける。

## 3) よく使うオプション（at least 3 options with explanation）
- `-type f|d` : ファイル(`f`)かディレクトリ(`d`)かを限定する。
- `-name` / `-iname` : 名前一致（`-iname`は大文字小文字を無視）。
- `-mtime` / `-mmin` : 更新日時条件（例: `-mtime -1` は1日以内）。
- `-size` : サイズ条件（例: `+500M` で500MB超）。
- `-maxdepth` : 探索の深さを制限して高速化・誤爆防止。
- `-exec ... {} \;` : 見つけた対象にコマンド実行（安全に1件ずつ処理）。

## 4) 実例コマンド（at least 5 examples, copy-paste ready）
```bash
# 1) /var/log 配下で24時間以内に更新された .log を探す
find /var/log -type f -name "*.log" -mtime -1

# 2) カレント配下で 500MB 超のファイルを一覧
find . -type f -size +500M

# 3) 深さ2までで .env ファイルを検索（隠しディレクトリ事故を減らす）
find . -maxdepth 2 -type f -name ".env"

# 4) 7日より古い gzip ログを削除前に確認
find /var/log/myapp -type f -name "*.gz" -mtime +7

# 5) 確認後に削除（本番はまず上の確認コマンドを実行）
find /var/log/myapp -type f -name "*.gz" -mtime +7 -exec rm -f {} \;

# 6) 直近30分で更新された設定ファイルを抽出
find /etc -type f -name "*.conf" -mmin -30
```

## 5) よくあるミスと安全ポイント
- いきなり `-exec rm` しない。**まず検索だけ実行して対象確認**が鉄則。
- `-name *.log` のようにクォートしないと、シェル展開で意図がズレる。`"*.log"` を使う。
- ルート配下を無制限探索すると重い。`-maxdepth` や探索起点を絞る。
- 権限不足エラーが多いときは `2>/dev/null` でノイズを抑えつつ、必要なら権限設計を見直す。

## 6) 追加学習（manページの読みどころ or related command）
- `man find` の **TESTS**, **ACTIONS**, **OPERATORS**（条件のAND/OR）を重点的に読む。
- 関連コマンド: `xargs`（find結果の一括処理高速化）、`locate`（事前DBによる高速検索）。
