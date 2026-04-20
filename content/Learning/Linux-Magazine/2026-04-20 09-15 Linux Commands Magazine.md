---
tags: [linux, commands, learning, devops, daily]
---

# 2026-04-20 09:15 Linux Commands Magazine
[[Home]]

#linux #commands #learning #devops #daily

## 1) 今日の1コマンド（command name + one-line summary）
**`tee`** — 標準入力を「画面表示しながらファイル保存」できる、ログ取得と検証を同時に進める実務向けコマンド。

## 2) 実務で使う場面（2-4 concrete scenarios）
- デプロイスクリプトの実行結果を、ターミナルで見つつ監査用ログにも残したいとき
- `curl` や `kubectl` の出力を確認しながら、そのままファイルに保存して共有したいとき
- CIのローカル再現で、ビルドログを追いながら失敗箇所の証跡を残したいとき
- パイプ処理の中間結果を一時保存して、後段処理の不具合切り分けをしたいとき

## 3) よく使うオプション（at least 3 options with explanation）
- `-a` : 追記モード（既存ファイルを上書きせず末尾に追加）
- `-i` : 割り込みシグナル（SIGINT）を無視して、長時間処理のログ欠落を減らす
- `-p` : パイプ書き込みエラーを考慮した動作（GNU tee。途中終了する下流コマンドがあるときに有用）

## 4) 実例コマンド（at least 5 examples, copy-paste ready）
```bash
# 1) コマンド結果を表示しつつ保存（上書き）
ls -la /etc | tee /tmp/etc-list.txt

# 2) デプロイログを追記で残す
./deploy.sh 2>&1 | tee -a /var/log/myapp/deploy.log

# 3) APIレスポンスを確認しながらJSON保存
curl -sS https://api.example.com/health | tee /tmp/health.json

# 4) 中間結果を保存しつつ後段で件数確認
ps aux | tee /tmp/ps-snapshot.txt | wc -l

# 5) makeの出力を画面表示＋ログ化（標準エラー含む）
make test 2>&1 | tee /tmp/make-test.log

# 6) 複数ファイルへ同時出力
echo "rotate completed" | tee /tmp/ops.log /tmp/audit.log
```

## 5) よくあるミスと安全ポイント
- `tee file` はデフォルトで上書きする
  - 既存ログを残すなら必ず `tee -a file`
- 権限不足のパスへ保存して失敗する
  - 必要なら `... | sudo tee /path/to/file >/dev/null` を使う（リダイレクトより安全）
- 標準エラーがログに入っていない
  - 失敗調査用途では `2>&1 | tee ...` を基本にする

## 6) 追加学習（manページの読みどころ or related command）
- `man tee` の **DESCRIPTION** と **OPTIONS**（特に `-a`, `-i`, `-p`）を先に確認
- 関連コマンド: `xargs`（保存したリストを後段処理へ渡す）, `script`（端末セッション全体の記録）
