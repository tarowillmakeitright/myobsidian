---
tags:
  - linux
  - commands
  - learning
  - devops
  - daily
---

[[Home]]

# Linux Commands Magazine — 2026-06-21 09:15

## 1) 今日の1コマンド（command name + one-line summary）
**`sort`** — テキスト行を並べ替えて、重複整理・集計前処理・差分確認をしやすくする基本コマンド。

## 2) 実務で使う場面（2-4 concrete scenarios）
- ログや一覧をソートして、同じ値をまとめて見やすくする
- `uniq` と組み合わせて、IP・エラーコード・ユーザー名の重複件数を出す
- CSV/TSVの特定列で並べ替えて、レビューや目視確認をしやすくする
- バックアップ前後のファイル一覧をソートして、差分比較しやすくする

## 3) よく使うオプション（at least 3 options with explanation）
- `-n` : 数値として並べ替える。サイズ・件数・ポート番号向け
- `-r` : 逆順にする。大きい順・新しい順の確認で便利
- `-u` : 重複行を除いてユニーク化する
- `-k 2,2` : 2列目だけをキーにして並べ替える
- `-t ','` : 区切り文字を指定する。CSV処理でよく使う
- `-h` : `1K`, `200M`, `3G` のような人間向けサイズを自然順で並べ替える

## 4) 実例コマンド（at least 5 examples, copy-paste ready）
```bash
sort access.log
```
ログ行を辞書順で並べ替えて、同系統の行をまとめて見やすくする。

```bash
cut -d' ' -f1 access.log | sort | uniq -c | sort -nr
```
アクセス元IPごとの件数を多い順に確認する。

```bash
ps -eo user,pid,%cpu,%mem,comm --no-headers | sort -k3,3nr | head
```
CPU使用率が高いプロセスを上位から確認する。

```bash
du -sh /var/log/* 2>/dev/null | sort -h
```
ログディレクトリ配下をサイズ順に並べて、肥大化箇所を見つける。

```bash
sort -t',' -k3,3n users.csv
```
CSVの3列目を数値として並べ替える。

```bash
find . -type f | sort > files.sorted
```
ファイル一覧を安定した順序で保存し、後続のdiffや監査に使う。

## 5) よくあるミスと安全ポイント
- 数字をそのまま `sort` すると文字列順になることがある。件数やサイズは `-n` / `-h` を使う
- `uniq` は隣接した重複しかまとめない。重複除去したいなら基本は `sort | uniq`
- CSVを `-t ','` で扱う方法は、単純なCSV向け。クォートや埋め込みカンマがある本格CSVは `csvkit` などを検討
- ロケール差で順序が変わることがある。自動化では必要に応じて `LC_ALL=C sort` を使う

## 6) 追加学習（manページの読みどころ or related command）
- `man sort` では `-k`（キー指定）と `--stable` の説明が実務向き
- 関連コマンド: `uniq`, `cut`, `comm`, `join`
