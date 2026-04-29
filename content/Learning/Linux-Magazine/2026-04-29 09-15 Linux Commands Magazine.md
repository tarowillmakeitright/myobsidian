---
tags: [linux, commands, learning, devops, daily]
---

[[Home]]

# 2026-04-29 09:15 Linux Commands Magazine

## 1) 今日の1コマンド（command name + one-line summary）
**`find`** — 条件に合うファイルを高速に検索し、そのまま運用アクション（確認・削除・権限修正）までつなげる実務必須コマンド。

## 2) 実務で使う場面（2-4 concrete scenarios）
- ログ肥大化調査で「7日より古い `.log`」を抽出して整理する
- デプロイ前に「世界書き込み権限（777系）」など危険な権限を検出する
- CI成果物や一時ファイル（`*.tmp`, `*.bak`）を一括で洗い出してクリーンアップする
- 証明書や設定ファイルの配置ミスを、拡張子・更新日時で横断確認する

## 3) よく使うオプション（at least 3 options with explanation）
- `-type f|d` : ファイル/ディレクトリ種別を絞る（誤検出を減らす）
- `-name "PATTERN"` / `-iname "PATTERN"` : 名前で検索（`-iname` は大文字小文字無視）
- `-mtime N` : 更新日ベースで絞る（`+7`=7日超, `-1`=1日以内）
- `-size +100M` : サイズ条件で抽出（容量調査に有効）
- `-maxdepth N` : 探索深さを制限し、重い走査を防ぐ
- `-exec ... {} \;` : 見つけた対象へコマンド実行（本番は先に一覧確認推奨）

## 4) 実例コマンド（at least 5 examples, copy-paste ready）
```bash
# 1) /var/log 配下の 7日超の .log を一覧表示
sudo find /var/log -type f -name "*.log" -mtime +7

# 2) カレント配下の 500MB超ファイルを抽出（容量調査）
find . -type f -size +500M

# 3) /etc 配下で conf/json/yaml を2階層まで確認
find /etc -maxdepth 2 -type f \( -name "*.conf" -o -name "*.json" -o -name "*.yaml" \)

# 4) 世界書き込み可能ファイルを検出（セキュリティ点検）
sudo find / -xdev -type f -perm -0002 2>/dev/null

# 5) 3日以上前の tmp を削除（まずは対象確認してから実行推奨）
find /tmp -type f -name "*.tmp" -mtime +3 -print
# 確認後に実行:
# find /tmp -type f -name "*.tmp" -mtime +3 -delete
```

## 5) よくあるミスと安全ポイント
- **いきなり `-delete` する**: 先に `-print` で対象確認。削除は確認後に実行。
- **探索範囲が広すぎて重い**: `/` 全体より、対象ディレクトリ + `-maxdepth` で絞る。
- **権限エラーを見落とす**: 必要に応じて `sudo` を使い、`2>/dev/null` の使いどころを意識する。
- **`-name` のクォート漏れ**: `"*.log"` のようにクォートしてシェル展開事故を防ぐ。

## 6) 追加学習（manページの読みどころ or related command）
- `man find` の **TESTS**（`-mtime`, `-size`, `-perm`）と **ACTIONS**（`-print`, `-delete`, `-exec`）を重点的に。
- 関連コマンド: `locate`（高速検索DB）, `grep`（内容検索）, `fd`（高速で書きやすい代替）。
