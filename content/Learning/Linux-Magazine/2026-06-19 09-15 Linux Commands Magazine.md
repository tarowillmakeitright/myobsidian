---
tags:
  - linux
  - commands
  - learning
  - devops
  - daily
---

[[Home]]

# Linux Commands Magazine — 2026-06-19 09:15

## 1) 今日の1コマンド（command name + one-line summary）
**`find`** — 条件に合うファイルやディレクトリを再帰的に探し、そのまま確認・整理・自動処理につなげる現場の基本コマンド。

## 2) 実務で使う場面（2-4 concrete scenarios）
- ログ肥大化の調査で、一定日数より古いファイルや巨大ファイルを洗い出す
- デプロイ前に、特定拡張子・権限・所有者のファイルだけを点検する
- バックアップ対象から不要ファイルを探して整理する
- CI/CD や運用スクリプトで、条件一致したファイルだけに後続処理をかける

## 3) よく使うオプション（at least 3 options with explanation）
- `-type f` : 通常ファイルだけを対象にする。ディレクトリやソケットを除外したいときの基本
- `-type d` : ディレクトリだけを探す。構成確認や一括権限見直し前の確認に便利
- `-name '*.log'` : ファイル名パターンで検索する。大文字小文字を無視したいなら `-iname`
- `-mtime +7` : 7日より古いファイルを探す。ログ整理や保守でよく使う
- `-size +500M` : 指定サイズより大きいファイルを探す。容量調査で有効
- `-maxdepth 2` : 探索の深さを制限する。無駄な再帰を避けたいときに便利

## 4) 実例コマンド（at least 5 examples, copy-paste ready）
```bash
find /var/log -type f -name '*.log' -mtime +7
```
7日より古いログファイルを洗い出す。

```bash
find /home/app -maxdepth 2 -type f -name '*.env'
```
アプリ配下の `.env` ファイルを浅い階層だけ確認する。

```bash
find / -type f -size +1G 2>/dev/null
```
1GB を超える巨大ファイルをシステム全体から探す。

```bash
find ./src -type f \( -name '*.sh' -o -name '*.py' \)
```
`src` 配下のシェルスクリプトと Python ファイルだけを列挙する。

```bash
find /data/backup -type f -mtime +30 -exec ls -lh {} \;
```
30日より古いバックアップファイルを詳細表示で確認する。

```bash
find /etc -type f -name '*.conf' -exec grep -H 'Listen' {} \; 2>/dev/null
```
設定ファイル群から `Listen` を含む行を探す。

## 5) よくあるミスと安全ポイント
- `find / -name ...` は強力だが重い。まずは対象ディレクトリを絞る
- `-exec rm` や `-delete` は便利だが危険。最初は削除せず一覧確認してから使う
- `-name *.log` のようにクォートを忘れると、シェル展開で意図が変わることがある。`'*.log'` を基本にする
- 権限エラーが多い場所では `2>/dev/null` を併用すると見やすいが、必要なエラーまで隠しすぎないよう注意

## 6) 追加学習（manページの読みどころ or related command）
- `man find` では **tests / actions / operators** の3区分を見ると理解しやすい
- 関連コマンド: `xargs`（検索結果をまとめて後続処理する）, `locate`（事前DBベースで高速検索する）
