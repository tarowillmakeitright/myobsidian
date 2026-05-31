# Linux Commands Magazine — 2026-05-31 09:15
Tags: #linux #commands #learning #devops #daily
Links: [[Home]]

## 1) 今日の1コマンド（command name + one-line summary）
**`find`** — 条件指定で大量ファイルから必要なものを正確に探し、後続処理までつなげる実務必須コマンド。

## 2) 実務で使う場面（2-4 concrete scenarios）
- **容量調査**: 直近更新された大きなログ/成果物だけ抽出して肥大化原因を特定。
- **運用保守**: 一定日数を超えたバックアップや一時ファイルを棚卸し・削除対象化。
- **セキュリティ/監査**: パーミッションが緩すぎるファイル（例: 777）を検出。
- **開発効率化**: 拡張子や名前パターンで対象ファイルを絞って一括grep/整形処理。

## 3) よく使うオプション（at least 3 options with explanation）
- `-name 'PATTERN'` : ファイル名をワイルドカードで一致（大文字小文字区別あり）。
- `-type f|d` : ファイル(`f`)かディレクトリ(`d`)かを限定。
- `-mtime N` : 更新日で絞る（`-7`=7日以内、`+30`=30日より前）。
- `-size +100M` : サイズ条件で抽出（大容量ファイル調査に有効）。
- `-maxdepth N` : 探索の深さを制限して高速化・誤検出防止。
- `-exec ... {} \;` : 見つけた各ファイルにコマンド実行（安全に段階実行しやすい）。

## 4) 実例コマンド（at least 5 examples, copy-paste ready）
```bash
# 1) /var/log 配下の 200MB 超ファイルを探す
find /var/log -type f -size +200M

# 2) 過去7日以内に更新された .log を列挙
find /var/log -type f -name '*.log' -mtime -7

# 3) 30日より古い .tmp を確認（削除前チェック）
find /tmp -type f -name '*.tmp' -mtime +30

# 4) パーミッション 777 のファイルを検出
find /home -type f -perm 0777

# 5) リポジトリ配下で node_modules を除外して .js を検索
find . -type d -name node_modules -prune -o -type f -name '*.js' -print

# 6) 14日より古い gzip ログを削除（まずは echo でドライラン）
find /var/log/myapp -type f -name '*.gz' -mtime +14 -exec echo rm -f {} \;
```

## 5) よくあるミスと安全ポイント
- いきなり `-exec rm` しない。**先に `-print` や `echo` で対象確認**する。
- `-mtime` は「24時間単位」。厳密な時刻指定が必要なら `-newermt` も検討。
- `-name` の `*` は **シェル展開を防ぐため必ずクォート**（`'*.log'`）。
- ルート配下検索は重いので、`-maxdepth` や探索開始ディレクトリを絞る。

## 6) 追加学習（manページの読みどころ or related command）
- `man find` の **OPERATORS**（`-a`, `-o`, `!`）と **ACTIONS**（`-print`, `-delete`, `-exec`）を重点的に読むと実戦力が上がる。
- 関連: `xargs`（find結果のバッチ処理）、`locate`（事前索引ベースの高速検索）。
