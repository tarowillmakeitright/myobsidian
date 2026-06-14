---
tags:
  - linux
  - commands
  - learning
  - devops
  - daily
---

[[Home]]

## 1) 今日の1コマンド
`xargs` — 標準入力の一覧を受け取り、別コマンドの引数として安全にまとめて実行する。

## 2) 実務で使う場面
- `find` の結果に対して、まとめて `rm` / `chmod` / `grep` をかけたいとき
- ログや一覧ファイルの値を1件ずつ使って API チェックや疎通確認をしたいとき
- 大量のファイルを一定件数ずつ分割して処理し、負荷を抑えたいとき
- 並列実行で `docker`, `kubectl`, `ssh`, `curl` などの繰り返し処理を速くしたいとき

## 3) よく使うオプション
- `-0` : NUL 区切りで受け取る。空白や改行を含むファイル名を安全に扱う基本形
- `-I {}` : プレースホルダを使って、入力値をコマンド中の任意位置へ埋め込む
- `-n 1` : 1回の実行で使う引数数を制限する。1件ずつ処理したいときに便利
- `-P 4` : 4並列で実行する。I/O 待ちの多い処理を短縮しやすい
- `-r` : 入力が空なら実行しない。空入力事故の予防になる

## 4) 実例コマンド
```bash
find . -type f -name '*.log' -print0 | xargs -0 -r rm -f
```
カレント配下の `.log` を安全にまとめて削除する。

```bash
find /var/log -type f -name '*.log' -print0 | xargs -0 -n 1 gzip
```
ログを1ファイルずつ圧縮する。

```bash
printf '%s\n' app1 app2 app3 | xargs -n 1 systemctl status
```
複数サービスの状態を順番に確認する。

```bash
cat hosts.txt | xargs -n 1 -P 4 -I {} ssh {} 'hostname && uptime'
```
ホスト一覧に対して4並列で接続し、名前と稼働時間を確認する。

```bash
find src -type f -name '*.js' -print0 | xargs -0 grep -n 'TODO'
```
JavaScript ファイル群から `TODO` を横断検索する。

```bash
printf '%s\n' 8080 8443 9000 | xargs -n 1 -I {} sh -c 'ss -ltn | grep -q ":{} " && echo "LISTEN {}"'
```
複数ポートの待受有無をざっと確認する。

## 5) よくあるミスと安全ポイント
- **空白入りファイル名で壊れる**: `find ... -print0 | xargs -0` を基本にする
- **いきなり削除系を流す**: まずは `xargs -n 1 echo` で実行内容を確認する
- **並列を上げすぎる**: `-P` は便利だが、DB・SSH・API 相手に負荷をかけすぎない
- **空入力で誤実行**: `-r` を付けて無駄な1回を防ぐ
- **複雑なシェル展開を直書きする**: 必要なら `sh -c` を使うが、引用符崩れに注意する

## 6) 追加学習
- `man xargs` の **OPTIONS** と **EXAMPLES** を読むと、`-0`, `-I`, `-n`, `-P` の使い分けが分かりやすい
- 関連コマンド: `find`, `parallel`, `grep`, `sh`
