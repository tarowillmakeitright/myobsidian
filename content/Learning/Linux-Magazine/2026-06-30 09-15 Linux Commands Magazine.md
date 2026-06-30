#linux #commands #learning #devops #daily
[[Home]]

1) 今日の1コマンド
`tee` — 標準出力を見ながら、同時にファイルへ保存できるコマンド。

2) 実務で使う場面
- デプロイやメンテ作業の実行ログを、画面確認しつつそのまま保存したいとき。
- `curl` や `kubectl` の結果を、確認しながら監査用ファイルにも残したいとき。
- `sudo` が必要な設定ファイルへ、パイプ経由で安全に書き込みたいとき。
- CIや障害対応で、複数コマンドの出力をリアルタイム監視しつつ記録したいとき。

3) よく使うオプション
- `-a` — 追記モード。既存ログを消さずに末尾へ追加する。
- `-i` — 割り込みシグナルを無視。長めのパイプ処理で途中中断に強くしたいときに使う。
- `-p` — パイプ先で一部が先に閉じても、より安全に振る舞う（GNU tee）。複雑なパイプでのエラー検知に便利。
- `--output-error=warn` — 書き込みエラー時に警告を出す。ログ保存失敗を見逃しにくい。

4) 実例コマンド
```bash
# コマンド出力を画面表示しつつファイル保存
ls -lah /var/log | tee logs-snapshot.txt

# デプロイログを追記保存
./deploy.sh 2>&1 | tee -a deploy.log

# APIレスポンスを確認しながらJSON保存
curl -sS https://api.github.com/repos/torvalds/linux | tee linux-repo.json

# sudo権限で設定ファイルを書き込む（リダイレクト代わり）
echo 'vm.swappiness=10' | sudo tee /etc/sysctl.d/99-swappiness.conf > /dev/null

# systemctlの状態を画面表示＋記録
systemctl status nginx --no-pager | tee nginx-status.txt

# 複数段のパイプで途中結果を残す
journalctl -u sshd -n 200 | tee sshd.log | grep 'Failed password'
```

5) よくあるミスと安全ポイント
- `>` と違って、`tee` は標準出力もそのまま流れる。機密情報を含む出力は画面やCIログに露出しないか注意。
- `tee file` は上書き。履歴を残したいなら `-a` を使う。
- `sudo echo ... > /etc/file` は失敗しやすい。権限が必要なのはリダイレクト先なので、`sudo tee` を使う。
- バイナリや巨大ログでも使えるが、不要に画面へ流すと見づらい。必要なら `> /dev/null` を組み合わせる。

6) 追加学習
- `man tee` の「DESCRIPTION」と「OPTIONS」を読むと、`-a` とエラー処理の違いをすぐ押さえられる。
- 関連コマンド: `cat`（内容確認）、`tail -f`（追跡表示）、`script`（端末セッション全体の記録）。
