---
tags: [linux, commands, learning, devops, daily]
---

# Daily Linux Commands Magazine - 2026-05-05
[[Home]]

## 1) 今日の1コマンド（command name + one-line summary）
**`rsync`** — 差分だけを安全・高速に同期し、バックアップやデプロイを効率化する定番コマンド。

## 2) 実務で使う場面（2-4 concrete scenarios）
- リリース前に、アプリ成果物を本番/検証サーバーへ差分転送する。
- 日次バックアップで、変更があったファイルだけNASや別ディスクへ複製する。
- 障害調査時に、大きなログディレクトリをローカルへ最小通信量で退避する。
- CIジョブでビルドキャッシュをワーカー間同期し、ビルド時間を短縮する。

## 3) よく使うオプション（at least 3 options with explanation）
- `-a` : アーカイブモード（再帰＋権限/時刻などを保持）。
- `-v` : 詳細表示（何が同期されたかを確認しやすい）。
- `-h` : 人間に読みやすいサイズ表示（KB/MB/GB）。
- `--progress` : 転送進捗を表示（大容量転送で有用）。
- `--delete` : 送信元にないファイルを送信先から削除（**ミラー用途のみ**）。
- `-n` (`--dry-run`) : 実行せず差分だけ確認（事故防止の最重要オプション）。

## 4) 実例コマンド（at least 5 examples, copy-paste ready）
```bash
# 1) ローカル→ローカルへ差分バックアップ
rsync -avh /var/www/ /backup/www/

# 2) ローカル→リモートへデプロイ（SSH経由）
rsync -avh --progress ./dist/ deploy@10.0.0.20:/srv/app/dist/

# 3) リモート→ローカルへログ退避
rsync -avh ops@10.0.0.30:/var/log/nginx/ ./nginx-logs/

# 4) 削除込みミラー同期（実行前に必ずdry-run）
rsync -avhn --delete /data/source/ /data/mirror/
# 内容確認後に本実行
rsync -avh --delete /data/source/ /data/mirror/

# 5) 除外指定つきでプロジェクト同期
rsync -avh --exclude '.git/' --exclude 'node_modules/' ./project/ backup@10.0.0.40:/data/project/

# 6) 帯域を抑えて同期（回線が細い拠点向け）
rsync -avh --bwlimit=5000 ./artifacts/ sync@10.0.0.50:/srv/artifacts/
```

## 5) よくあるミスと安全ポイント
- パス末尾の `/` 有無で意味が変わる（`src/` は中身、`src` はディレクトリごと）。
- `--delete` は強力。**必ず `-n` で事前確認**してから本実行する。
- 本番同期はまず小さいディレクトリで試し、意図どおりの差分か確認する。
- 権限保持が不要な環境では `-a` を見直し、必要最小限オプションで運用する。

## 6) 追加学習（manページの読みどころ or related command）
- `man rsync` の **"USAGE"**, **"FILTER RULES"**, **"--delete"** 周辺を重点的に読む。
- 関連コマンド: `scp`（単純コピー向け）、`tar`（固めて転送したい時）。
