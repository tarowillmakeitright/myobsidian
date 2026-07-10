---
tags:
  - linux
  - commands
  - learning
  - devops
  - daily
links:
  - "[[Home]]"
---

# Linux Commands Magazine — 2026-07-10 09:15

## 1) 今日の1コマンド
`find` — 条件を組み合わせて、目的のファイルを安全に探し、そのまま後続処理につなげられる定番コマンド。

## 2) 実務で使う場面
- ログ肥大化調査で、7日以上前の `.log` を探す
- デプロイ前に、権限が緩すぎるファイルやディレクトリを洗い出す
- プロジェクト内で、特定拡張子や大きすぎるファイルを見つける
- バックアップ対象から不要なキャッシュや一時ファイルを除外候補として確認する

## 3) よく使うオプション
- `-name` — ファイル名で検索する。ワイルドカードと一緒によく使う
- `-type f|d` — ファイルだけ / ディレクトリだけに絞る
- `-mtime N` — 更新日ベースで絞る。`+7` は7日より前、`-1` は24時間以内
- `-size` — サイズ条件で絞る。例: `+100M`
- `-maxdepth` — 深すぎる探索を防ぎ、速度と安全性を上げる
- `-exec ... {} \;` — 見つけた結果ごとにコマンドを実行する

## 4) 実例コマンド
```bash
find /var/log -type f -name '*.log' -mtime +7
find . -maxdepth 3 -type f -name '*.env*'
find /srv/app -type f -size +100M
find . -type d -name node_modules -prune
find /etc -type f -perm -o+w
find . -type f -name '*.tmp' -exec rm -i {} \;
```

## 5) よくあるミスと安全ポイント
- いきなり `-exec rm` しない。まずは削除なしで検索結果だけ確認する
- `*.log` をシェル展開させないよう、`'*.log'` のようにクォートする
- `/` 直下など広すぎる場所を探索すると重い。`-maxdepth` や対象ディレクトリの限定を使う
- `-mtime` は「日単位」。分単位・時間単位で見たいなら `-mmin` も検討する
- ディレクトリ除外には `-prune` が便利。巨大ツリーを無駄に掘らない

## 6) 追加学習
`man find` の「TESTS」「ACTIONS」を読むと実戦力が上がる。関連コマンドは `xargs`、`locate`、`fd`。
