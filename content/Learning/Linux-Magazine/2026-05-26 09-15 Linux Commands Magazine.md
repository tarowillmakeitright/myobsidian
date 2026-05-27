# Linux Commands Magazine — 2026-05-26 09:15
Tags: #linux #commands #learning #devops #daily
Links: [[Home]]

## 1) 今日の1コマンド（command name + one-line summary）
**`find`** — 大量ファイルから「条件に合うものだけ」を安全に検索・抽出・後続処理する基本コマンド。

## 2) 実務で使う場面（2-4 concrete scenarios）
- **ログ肥大の調査**: 一定サイズ以上のログを洗い出して容量圧迫箇所を特定。
- **期限切れ一時ファイルの整理**: 30日以上前のキャッシュ/一時ファイルを定期クリーンアップ。
- **デプロイ前チェック**: 本番投入前に不要な秘密鍵・バックアップファイル（`.bak` など）を検出。
- **CI/CD補助**: 変更対象ファイルだけを拾って静的解析・整形コマンドへ渡す。

## 3) よく使うオプション（at least 3 options with explanation）
- `-name "pattern"` : ファイル名で検索（ワイルドカード可、大小文字区別あり）。
- `-type f|d` : 種別指定（`f`=ファイル, `d`=ディレクトリ）。
- `-mtime N` : 更新日で絞り込み（例: `+30` は30日より古い）。
- `-size +100M` : サイズ条件で検索（容量監査に有効）。
- `-maxdepth N` : 探索深さを制限して誤爆・重さを防ぐ。
- `-exec ... {} \;` : 見つかった各項目に対してコマンド実行。

## 4) 実例コマンド（at least 5 examples, copy-paste ready）
```bash
# 1) /var/log で100MB超のファイルを探す
sudo find /var/log -type f -size +100M

# 2) プロジェクト内の .env ファイルを検出（漏洩防止チェック）
find ~/projects/myapp -type f -name ".env"

# 3) 30日より古い .log を一覧表示
find /srv/app/logs -type f -name "*.log" -mtime +30

# 4) 7日より古い一時ファイルを削除（まず確認してから削除推奨）
find /tmp/myapp -type f -mtime +7 -print
find /tmp/myapp -type f -mtime +7 -delete

# 5) node_modules を探索対象から除外して .js を検索
find ~/projects/web -path "*/node_modules" -prune -o -type f -name "*.js" -print

# 6) 見つかったファイルに対して権限を一括調整
find /srv/shared -type f -name "*.sh" -exec chmod 750 {} \;
```

## 5) よくあるミスと安全ポイント
- **いきなり削除**: `-delete` や `-exec rm` は危険。先に `-print` で対象確認。
- **探索範囲が広すぎる**: `/` 起点は重い。必要なディレクトリに絞る。
- **除外不足**: `node_modules` や `.git` を除外しないと遅い＆ノイズ増。
- **権限エラー見落とし**: `sudo` が必要な領域では標準エラーも確認する。

## 6) 追加学習（manページの読みどころ or related command）
- `man find` は **"TESTS"**, **"ACTIONS"**, **"OPERATORS"** の順で読むと実務で使いやすい。
- 関連コマンド: `xargs`（find結果の安全なバッチ処理）, `locate`（高速検索）, `fd`（モダン代替）。
