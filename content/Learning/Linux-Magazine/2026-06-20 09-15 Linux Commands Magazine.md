---
tags:
  - linux
  - commands
  - learning
  - devops
  - daily
---

[[Home]]

# Daily Linux Commands Magazine

## 今日の1コマンド
`awk` — テキストを列単位で抜き出し・集計・整形できる、現場で非常に強い定番コマンド。

## 実務で使う場面
- `ps` や `df` の出力から必要な列だけ抜き出して確認するとき
- Web/アプリログからステータスコードやIPごとの件数を集計するとき
- CSV/TSVの特定列を加工してレポート用に整形するとき
- パイプラインの途中で軽いフィルタや条件分岐を入れたいとき

## よく使うオプション
- `-F ','` — 区切り文字を指定する。CSVやコロン区切りの処理で便利
- `-v name=value` — シェル変数を `awk` に安全に渡す
- `-f script.awk` — ワンライナーではなく、awkスクリプトファイルを読む
- `-v OFS='\t'` — 出力区切り文字を指定して整形しやすくする

## 実例コマンド
```bash
ps aux | awk 'NR==1 || /nginx/'
```
ヘッダを残しつつ `nginx` 関連プロセスだけ見る。

```bash
df -h | awk 'NR==1 || $5+0 >= 80'
```
使用率80%以上のファイルシステムだけ確認する。

```bash
awk -F: '{print $1, $7}' /etc/passwd
```
ユーザー名とログインシェルを抜き出す。

```bash
awk '{count[$9]++} END {for (code in count) print code, count[code]}' access.log
```
アクセスログのHTTPステータスコード別件数を集計する。

```bash
awk -F, 'NR>1 && $3 > 100 {print $1, $3}' sales.csv
```
CSVの3列目が100超の行だけ抽出する。

```bash
awk -v OFS='\t' '{print $1, $4, $NF}' app.log
```
1列目・4列目・最終列をタブ区切りで再整形する。
```

## よくあるミスと安全ポイント
- **CSVを過信しない**: 単純な `-F,` はクォート入りCSVで壊れることがある。本格CSVは `python`, `mlr`, `csvkit` も検討
- **列番号のズレ**: ログ形式が変わると `$9` などが簡単にズレる。まず `head` で確認
- **シェル変数の埋め込み**: 文字列連結で書かず、`-v` で渡すほうが安全
- **本番ログで重い処理**: 巨大ログ全件を何度も舐めると遅い。まず `head`, `tail`, `grep` で対象を絞る

## 追加学習
- `man awk` では **PATTERNS AND ACTIONS** と **Built-in Variables** が実務で特に重要
- 関連コマンド: `cut`, `sort`, `uniq`, `sed`, `grep`
