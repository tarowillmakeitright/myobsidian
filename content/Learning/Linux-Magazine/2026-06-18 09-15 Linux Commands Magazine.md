# Linux Commands Magazine — 2026-06-18 09:15
Tags: #linux #commands #learning #devops #daily
Links: [[Home]]

## 1) 今日の1コマンド（command name + one-line summary）
**`grep`** — ログ・設定・ソースコードから必要な行だけを素早く抜き出す、調査と確認の基本コマンド。

## 2) 実務で使う場面（2-4 concrete scenarios）
- アプリ障害時に、ログから `ERROR` / `WARN` / 特定リクエストID を探す
- 設定ファイル群から、同じパラメータがどこで定義されているか確認する
- デプロイ前に `.env` や YAML から対象キーの有無を点検する
- CI の出力から失敗箇所やテスト名だけを絞って確認する

## 3) よく使うオプション（at least 3 options with explanation）
- `-i` — 大文字小文字を無視して検索する
- `-r` / `-R` — ディレクトリを再帰的に検索する
- `-n` — 行番号付きで表示する
- `-v` — マッチしない行を表示する
- `-E` — 拡張正規表現を使う（`foo|bar` など）
- `-C 3` — 前後3行の文脈も一緒に表示する

## 4) 実例コマンド（at least 5 examples, copy-paste ready）
```bash
# 1. nginx のエラーログから error を探す
grep -in "error" /var/log/nginx/error.log

# 2. アプリログ配下から request_id を再帰検索する
grep -R "request_id=abc123" ./logs/

# 3. 設定ファイルから listen / server_name の両方を探す
grep -En "listen|server_name" /etc/nginx/nginx.conf

# 4. コメント行と空行を除いて .env を確認する
grep -Ev '^#|^$' .env

# 5. 直近ログで ERROR の前後3行を確認する
grep -C 3 "ERROR" ./app.log

# 6. Git 管理下のソースから TODO を探す
git ls-files | xargs grep -n "TODO"
```

## 5) よくあるミスと安全ポイント
- `grep -r /` のように広すぎる場所を掘ると遅い。対象ディレクトリを絞る
- バイナリや巨大ログに対して無差別検索すると見づらい。必要なら `--binary-files=without-match` を使う
- 正規表現のつもりで `.` や `*` を書くと意図せず広く当たる。固定文字列なら `grep -F` も有効
- 検索語に空白や記号があるときは、基本的にクォートして実行する

## 6) 追加学習（manページの読みどころ or related command）
- `man grep` の **Regular Expressions** と **Context Line Control** は実務で特に使う
- 関連コマンド: `find`, `sed`, `awk`, `rg`（ripgrep）
