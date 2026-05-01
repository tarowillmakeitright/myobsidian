---
tags: [linux, commands, learning, devops, daily]
---

# Daily Linux Commands Magazine - 2026-05-01
[[Home]]

## 1) 今日の1コマンド（command name + one-line summary）
**`rsync`** — 差分だけを安全に同期して、バックアップ・デプロイ・データ移行を効率化する実務コマンド。

## 2) 実務で使う場面（2-4 concrete scenarios）
- 本番サーバーへ静的ファイルを**差分デプロイ**したい（転送時間と帯域を節約）。
- 定期バックアップで、前回との差分だけをNAS/外部ディスクへ保存したい。
- 新旧サーバー移行時に、巨大ディレクトリを複数回同期して**切替直前だけ最終差分反映**したい。
- ログ収集や成果物回収を、SSH経由で安全に一括同期したい。

## 3) よく使うオプション（at least 3 options with explanation）
- `-a` : アーカイブモード（再帰＋パーミッション/タイムスタンプ等を保持）。
- `-v` : 詳細表示。何が同期されたか確認しやすい。
- `-h` : 人間に読みやすいサイズ表示（KB/MB/GB）。
- `--delete` : 転送先にだけ存在する不要ファイルを削除して、完全ミラー化。
- `--dry-run` : 実際には変更せず、実行結果だけ事前確認（事故防止に必須）。
- `-z` : 転送時圧縮。回線が細い環境で有効。

## 4) 実例コマンド（at least 5 examples, copy-paste ready）
```bash
# 1) ローカル→ローカルの差分バックアップ
rsync -avh /srv/data/ /backup/data/

# 2) ローカル→リモート（SSH）
rsync -avh -e ssh ./dist/ deploy@10.0.0.20:/var/www/app/

# 3) リモート→ローカルでログ回収
rsync -avh -e ssh ops@10.0.0.30:/var/log/nginx/ ./logs/nginx/

# 4) 削除を含むミラー同期（先に dry-run 推奨）
rsync -avh --delete /opt/releases/current/ /opt/releases/mirror/

# 5) 本番実行前の安全確認
rsync -avh --delete --dry-run ./public/ deploy@10.0.0.20:/var/www/html/

# 6) 帯域節約のため圧縮して同期
rsync -avhz -e ssh /home/dev/artifacts/ backup@10.0.0.40:/data/artifacts/
```

## 5) よくあるミスと安全ポイント
- **末尾スラッシュの意味違い**に注意。`src/` は中身を同期、`src` はディレクトリ自体を作って同期。
- `--delete` は強力。まず `--dry-run` で削除対象を確認してから本実行。
- 本番パスのタイプミス防止に、最初は小さいディレクトリでテストする。
- 権限エラー時は、実行ユーザーと所有権（`-a` の保持対象）を確認する。

## 6) 追加学習（manページの読みどころ or related command）
- `man rsync` の **"FILTER RULES"** と **"INCLUDE/EXCLUDE PATTERN RULES"** を読むと、実務での除外設計（例: `.git`, `node_modules`, 一時ファイル）が一気に上達。
- 関連コマンド: `scp`（単発コピー向き）、`tar`（固めて運ぶ向き）。継続同期は `rsync` が本命。
