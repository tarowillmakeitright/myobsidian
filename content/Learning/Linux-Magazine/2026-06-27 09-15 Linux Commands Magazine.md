# Linux Commands Magazine

Tags: #linux #commands #learning #devops #daily
Links: [[Home]]

1) 今日の1コマンド
`tar` — 複数ファイルやディレクトリを、まとめてアーカイブ・展開する標準コマンド。

2) 実務で使う場面
- デプロイ前に設定ファイルやアプリ一式を固めてバックアップする
- ログや調査結果を1つの成果物にまとめて受け渡す
- サーバ移行時にディレクトリを丸ごと退避・復元する
- CI/CDでビルド成果物をまとめて保存・配布する

3) よく使うオプション
- `-c` : 新しくアーカイブを作る
- `-x` : アーカイブを展開する
- `-f` : 対象ファイル名を指定する
- `-z` : gzip圧縮を使う（`.tar.gz`）
- `-t` : 中身一覧だけ確認する
- `-v` : 処理対象を表示する（確認向け）
- `-C` : 指定ディレクトリに移動してから処理する

4) 実例コマンド
```bash
# logs ディレクトリを gzip 圧縮して保存
tar -czf logs-2026-06-27.tar.gz logs/

# app ディレクトリをそのまま tar 化（圧縮なし）
tar -cf app-release.tar app/

# アーカイブの中身だけ確認
tar -tf logs-2026-06-27.tar.gz

# /tmp/restore に展開
tar -xzf logs-2026-06-27.tar.gz -C /tmp/restore

# /etc/nginx をバックアップしつつ進行表示
tar -czvf nginx-config-backup.tar.gz /etc/nginx

# 複数ファイルをまとめて成果物化
tar -czf incident-report.tar.gz report.md screenshots/ commands.txt
```

5) よくあるミスと安全ポイント
- 展開先を確認せず `tar -x` すると、意図しない場所にファイルが出る。`-C` を使うと安全。
- `-f` の直後はアーカイブ名。順番を崩すと分かりにくいエラーになりやすい。
- 本番の `/etc` やアプリ配下を固めるときは、作成後に `tar -tf` で中身確認しておくと事故が減る。
- 絶対パスを含むアーカイブは復元時に注意。検証環境で一度展開確認するのが無難。

6) 追加学習
- `man tar` の「create」「extract」「list」周辺をまず読むと実務頻度が高い。
- 関連コマンド: `gzip`, `bzip2`, `xz`, `cpio`
