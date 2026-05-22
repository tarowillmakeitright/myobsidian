# Linux Commands Magazine — 2026-05-22 09:15
Tags: #linux #commands #learning #devops #daily
Links: [[Home]]

## 1) 今日の1コマンド（command name + one-line summary）
**`awk`** — テキストを「列ベース」で加工・集計し、ログ解析やレポート作成を一発で効率化するコマンド。

## 2) 実務で使う場面（2-4 concrete scenarios）
- **アクセスログ解析**: Nginx/Apacheログからステータスコード別件数をすぐ集計する。
- **監視データの整形**: `ps` や `df` の出力から必要列だけ抽出して通知本文を作る。
- **CI/CDの失敗調査**: ビルドログから特定パターン行を抽出し、発生箇所を行番号付きで確認する。
- **CSVっぽい運用データの加工**: 区切り文字を指定して特定列だけ抜き出し、再出力する。

## 3) よく使うオプション（at least 3 options with explanation）
- `-F '<区切り>'` : 入力の列区切りを指定（例: `-F,` でCSV、`-F':'` で `/etc/passwd`）。
- `-v name=value` : awk内で使う変数を外から渡す（閾値や日付を埋め込む時に便利）。
- `-f script.awk` : awkスクリプトファイルを読み込む（複雑処理を再利用可能にする）。
- `-W interactive`（gawk）: 標準出力を行単位でフラッシュしやすくし、ストリーミング時の遅延を減らす。

## 4) 実例コマンド（at least 5 examples, copy-paste ready）
```bash
# 1) /etc/passwd からユーザー名とシェルを表示
awk -F: '{print $1, $7}' /etc/passwd

# 2) Nginxアクセスログのステータスコード別件数（多い順）
awk '{count[$9]++} END {for (c in count) print c, count[c]}' /var/log/nginx/access.log | sort -k2,2nr

# 3) メモリ使用率が閾値(80%)超のプロセスだけ表示
ps aux | awk -v th=80 'NR==1 || $4+0 > th {print $1, $2, $4, $11}'

# 4) ディスク使用率一覧から 90%以上のマウントポイントを抽出
df -hP | awk 'NR==1 || ($5+0) >= 90 {print $6, $5}'

# 5) エラーログの ERROR 行だけ行番号付きで抽出
awk '/ERROR/ {print NR ":" $0}' /var/log/myapp/app.log

# 6) CSVの1列目と3列目だけ再出力（カンマ区切り維持）
awk -F, 'BEGIN{OFS=","} {print $1, $3}' input.csv
```

## 5) よくあるミスと安全ポイント
- **区切り文字ミス**: 想定列が取れない時はまず `-F` を確認（スペース区切り前提で壊れがち）。
- **ヘッダー行の誤集計**: 数値処理は `NR>1` を付けてヘッダーを除外する。
- **空白入りフィールドの崩れ**: `ps` など可変空白の出力は、列番号が環境差でズレることがある。可能ならJSON出力可能コマンドや固定フォーマットを優先。
- **本番ログの直接上書き禁止**: awkは原則読み取りで使い、更新が必要ならバックアップを取って別ファイル出力する。

## 6) 追加学習（manページの読みどころ or related command）
- `man awk` の **“PROGRAM STRUCTURE”** と **“Built-in Variables”**（`FS`, `OFS`, `NR`, `NF`）を先に読むと習得が早い。
- 関連コマンド: `cut`（単純列抽出）, `sed`（行編集）, `jq`（JSON整形）。
