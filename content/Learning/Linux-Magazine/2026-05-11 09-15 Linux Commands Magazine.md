# Linux Commands Magazine — 2026-05-11 09:15
Tags: #linux #commands #learning #devops #daily
Links: [[Home]]

## 1) 今日の1コマンド（command name + one-line summary）
**`du`** — ディレクトリ/ファイルの使用容量を可視化し、容量不足の原因を素早く特定するコマンド。

## 2) 実務で使う場面（2-4 concrete scenarios）
- サーバの `/var` や `/home` が逼迫したとき、どこが容量を食っているかを切り分ける。
- コンテナホストでログやキャッシュの肥大化箇所を特定する。
- CIワーカーでビルド成果物・依存キャッシュの増加を監視する。
- バックアップ前に対象ディレクトリの概算サイズを確認して転送時間を見積もる。

## 3) よく使うオプション（at least 3 options with explanation）
- `-h` : 人間に読みやすい単位（K/M/G）で表示する。
- `-s` : 各引数の合計のみ表示（サマリー）。
- `--max-depth=N` : N階層まで掘って表示し、深掘りしすぎを防ぐ。
- `-x` : 別ファイルシステムを跨がず集計（マウント先を除外）。

## 4) 実例コマンド（at least 5 examples, copy-paste ready）
```bash
# 1. カレント配下を1階層だけ見て重いディレクトリを把握
sudo du -h --max-depth=1 . | sort -h

# 2. /var の合計容量だけ確認
sudo du -sh /var

# 3. /var/log 配下で大きい順に上位20件を確認
sudo du -ah /var/log | sort -hr | head -n 20

# 4. ルート直下を他FSを跨がず集計（/proc や別マウントの影響を減らす）
sudo du -xh --max-depth=1 /

# 5. 複数候補をまとめて比較（アプリ・ログ・キャッシュ）
sudo du -sh /opt/myapp /var/log /var/cache
```

## 5) よくあるミスと安全ポイント
- **`du` と `df` を混同**しない: `du` はファイル実体の合計、`df` はファイルシステム全体の空き容量。
- **権限不足で過小評価**しやすい: 調査時は `sudo` を使って抜け漏れを減らす。
- **削除済みなのに容量が戻らない**場合は、プロセスがファイルを掴んでいる可能性あり（`lsof +L1` で確認）。

## 6) 追加学習（manページの読みどころ or related command）
- `man du` の **"Display values in units"**（表示単位）と **"--max-depth"** 周辺を読むと実務で即効性あり。
- 関連コマンド: **`df`**（FS空き容量確認）, **`ncdu`**（対話的な容量調査）。
