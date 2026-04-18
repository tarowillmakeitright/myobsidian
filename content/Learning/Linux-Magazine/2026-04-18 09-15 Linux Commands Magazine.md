---
tags: [linux, commands, learning, devops, daily]
---

# 2026-04-18 09:15 Linux Commands Magazine
[[Home]]

#linux #commands #learning #devops #daily

## 1) 今日の1コマンド（command name + one-line summary）
**`find`** — 大量ファイルから「条件に合う対象だけ」を安全に抽出・一括処理する探索コマンド。

## 2) 実務で使う場面（2-4 concrete scenarios）
- 障害調査で「直近1時間に更新されたログ」だけを絞って確認したいとき
- デプロイ前に「不要な巨大ファイル」や「古い成果物」を洗い出したいとき
- 運用で「7日以上前のバックアップ」を定期削除したいとき
- 権限監査で「world-writable(777系)ファイル」を検出したいとき

## 3) よく使うオプション（at least 3 options with explanation）
- `-type f|d` : ファイル(`f`)かディレクトリ(`d`)かを限定する
- `-name 'pattern'` : ファイル名をワイルドカードで一致（大文字小文字区別あり）
- `-mtime N` : 最終更新日ベースで絞り込み（`-mtime -1`=1日以内, `+7`=7日より前）
- `-size +100M` : サイズ条件で抽出（`k`,`M`,`G`指定可）
- `-maxdepth N` : 探索の深さを制限し、誤爆と遅延を防ぐ
- `-exec ... {} \;` : 見つかった各ファイルにコマンドを実行

## 4) 実例コマンド（at least 5 examples, copy-paste ready）
```bash
# 1) logs配下で .log を探す（2階層まで）
find /var/log/myapp -maxdepth 2 -type f -name '*.log'

# 2) 24時間以内に更新されたファイルを確認
find /srv/app -type f -mtime -1

# 3) 500MB超のファイルを検出（容量調査）
find / -type f -size +500M 2>/dev/null

# 4) 30日より古い .gz ログを削除（まず確認）
find /var/log/myapp -type f -name '*.gz' -mtime +30 -print

# 5) 上の結果を実際に削除（確認後に実行）
find /var/log/myapp -type f -name '*.gz' -mtime +30 -delete

# 6) 777権限ファイルの検出（監査）
find /srv -type f -perm -0002
```

## 5) よくあるミスと安全ポイント
- いきなり `-delete` しない：まず `-print` で対象確認する
- パスを広く取りすぎない：`/` 全体探索は重いので対象ディレクトリを絞る
- 予期せぬ権限エラーは想定内：必要に応じて `2>/dev/null` を使う
- `-exec rm` より `-delete` の方が簡潔だが、条件ミス時の影響が大きいので段階実行する

## 6) 追加学習（manページの読みどころ or related command）
- `man find` の **TESTS**（`-mtime`, `-size`, `-perm`）と **ACTIONS**（`-print`, `-delete`, `-exec`）を読むと実務で困りにくい
- 関連コマンド: `xargs`（`find ... -print0 | xargs -0 ...`）で大量対象を効率処理できる
