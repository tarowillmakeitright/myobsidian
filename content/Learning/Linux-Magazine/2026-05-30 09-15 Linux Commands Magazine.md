# Linux Commands Magazine — 2026-05-30 09:15
Tags: #linux #commands #learning #devops #daily
Links: [[Home]]

## 1) 今日の1コマンド（command name + one-line summary）
**`journalctl`** — systemd環境のログを時系列で検索・絞り込みし、障害原因を最短で追うためのログ調査コマンド。

## 2) 実務で使う場面（2-4 concrete scenarios）
- **障害直後の一次調査**: サービス再起動後に、直前のエラーを時刻付きで確認。
- **デプロイ検証**: 反映直後のアプリ/サービスログを追って異常を早期検知。
- **夜間アラート対応**: 特定時間帯だけ切り出して、失敗ジョブやクラッシュ原因を確認。
- **監査・証跡確認**: `sudo` 実行や認証関連ログを抽出して運用記録に残す。

## 3) よく使うオプション（at least 3 options with explanation）
- `-u <unit>` : 対象サービス（例: `nginx.service`）に絞る。
- `-f` : ログを追尾表示（`tail -f` 相当）。
- `-n <行数>` : 直近N行だけ表示して素早く確認。
- `--since / --until` : 時間範囲を指定して調査対象を限定。
- `-p <priority>` : 重要度（`err`, `warning` など）で絞り込む。
- `-xe` : 直近の重要ログを詳細付きで確認（障害時の初動向け）。

## 4) 実例コマンド（at least 5 examples, copy-paste ready）
```bash
# 1) nginx の直近100行を確認
sudo journalctl -u nginx -n 100

# 2) nginx ログをリアルタイム追尾
sudo journalctl -u nginx -f

# 3) 今日のエラーレベル以上だけ抽出
sudo journalctl --since today -p err

# 4) 指定時間帯の docker ログを確認
sudo journalctl -u docker --since "2026-05-30 08:30:00" --until "2026-05-30 09:10:00"

# 5) 前回起動（1つ前のブート）のエラーログ確認
sudo journalctl -b -1 -p warning

# 6) 直近の重要ログを詳細付きで確認
sudo journalctl -xe
```

## 5) よくあるミスと安全ポイント
- **時間範囲を絞らずに読む**: 出力が多すぎて見落とす。`--since` と `-u` を先に使う。
- **権限不足で情報欠落**: システムログ調査は `sudo` 前提。
- **`-f` で追いっぱなし**: 作業終了後は `Ctrl+C` で止める（無駄な監視を避ける）。
- **ローカル時刻の誤認**: 複数環境調査時はタイムゾーン差を意識して時刻指定する。

## 6) 追加学習（manページの読みどころ or related command）
- `man journalctl` は **「FILTERING OPTIONS」「OUTPUT OPTIONS」「BOOT OPTIONS(-b)」** を先に読むと実務で効く。
- 関連コマンド: `systemctl status`（サービス状態確認）, `dmesg`（カーネルログ）, `grep`（ログ抽出）。
