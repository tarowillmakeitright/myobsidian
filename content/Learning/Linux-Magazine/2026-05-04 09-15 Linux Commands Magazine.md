# Daily Linux Commands Magazine - 2026-05-04

Tags: #linux #commands #learning #devops #daily
Links: [[Home]]

## 1) 今日の1コマンド（command name + one-line summary）
`find` — 条件に合うファイルを高速に絞り込み、調査・整理・一括処理につなげる定番コマンド。

## 2) 実務で使う場面（2-4 concrete scenarios）
- ディスク逼迫時に「大きいログ」「古いバックアップ」を特定して整理する。
- デプロイ前に、誤って残った `.env` や秘密鍵ファイルを検出する。
- CI/CDや運用スクリプトで、対象ファイルだけを抽出してバッチ処理する。
- 障害対応時に、直近更新された設定ファイルを調べて変更点の当たりをつける。

## 3) よく使うオプション（at least 3 options with explanation）
- `-type f|d` : ファイル(`f`)かディレクトリ(`d`)かを絞る。
- `-name "PATTERN"` : ファイル名で検索（ワイルドカード可、大小文字区別あり）。
- `-mtime N` : 更新日ベースで絞る（例: `-mtime +7` は7日より古い）。
- `-size +100M` : サイズ条件で絞る（例: 100MB超）。
- `-maxdepth N` : 探索の深さを制限して高速化・誤爆防止。
- `-exec CMD {} \;` : 見つかった各ファイルに対してコマンド実行。

## 4) 実例コマンド（at least 5 examples, copy-paste ready）
```bash
# 1. /var/log で 200MB を超えるファイルを探す
find /var/log -type f -size +200M

# 2. 14日より古い .log を探す
find /var/log -type f -name "*.log" -mtime +14

# 3. 24時間以内に更新された設定ファイルを確認
find /etc -type f -name "*.conf" -mtime -1

# 4. node_modules を除外して Python ファイルを探す
find . -path "*/node_modules" -prune -o -type f -name "*.py" -print

# 5. 7日より古い圧縮ログを削除（まず確認してから実行）
find /var/log -type f -name "*.gz" -mtime +7 -print
# 問題なければ削除
find /var/log -type f -name "*.gz" -mtime +7 -delete

# 6. 見つかったファイルの権限をまとめて変更
find /srv/app -type f -name "*.sh" -exec chmod 750 {} \;
```

## 5) よくあるミスと安全ポイント
- いきなり `-delete` を使うのは危険。**必ず先に `-print` で対象確認**。
- シェル展開事故防止のため、パターンは `"*.log"` のようにクォートする。
- ルート配下全探索は重い。`-maxdepth` や対象ディレクトリ限定で負荷を下げる。
- 権限不足で取りこぼす場合がある。必要時のみ `sudo` を使い、実行範囲を最小化する。

## 6) 追加学習（manページの読みどころ or related command）
- `man find` の「TESTS」「ACTIONS」（`-mtime`, `-size`, `-exec`, `-delete`）を重点的に読む。
- 関連コマンド: `xargs`（`find` 結果の高速バッチ処理）、`locate`（事前インデックス型の高速検索）。
