# Daily Linux Commands Magazine — 2026-03-17
#linux #commands #learning #devops #daily
[[Home]]

---

## 1) Topic + Level

### Beginner
**トピック:** ログ調査の第一歩（`ls` / `cat` / `less` / `tail` / `grep`）

### Middle（前提あり）
**トピック:** パイプラインで必要情報を抽出する（`grep` / `cut` / `sort` / `uniq` / `wc`）  
**前提:** Beginner の内容を理解し、標準入力・標準出力・パイプ（`|`）の意味がわかること

### Advanced（前提あり）
**トピック:** 本番運用を意識した安全なログ監視と定期チェック（`journalctl` / `awk` / `xargs` / `watch` / `crontab`）  
**前提:** Middle の内容を理解し、テキスト処理コマンドを組み合わせて使えること

---

## 2) Why it matters in real projects

- 障害対応では「まず事実をログから拾う」スキルが最優先。
- CI/CD 失敗、アプリ 500 エラー、ディスク圧迫など、原因特定はほぼログ解析から始まる。
- チーム開発では、再現性のあるコマンド列で調査できると引き継ぎが速い。
- SRE/DevOps では、**安全に**確認・集計・監視する習慣が事故防止につながる。

---

## 3) Core command explanations

### Beginner Core
- `ls -lah` : ファイル一覧を詳細表示（サイズ・権限含む）
- `less file.log` : 大きなファイルを安全に閲覧（編集しない）
- `tail -n 50 file.log` : 末尾 50 行を見る
- `tail -f file.log` : 追記をリアルタイム監視（Ctrl+C で終了）
- `grep "ERROR" file.log` : 該当行を検索

### Middle Core
- `cut -d' ' -f1` : 区切り文字で列抽出
- `sort` / `uniq -c` : 並び替え＋重複件数集計
- `wc -l` : 行数カウント
- 例: `grep "ERROR" app.log | cut -d' ' -f5 | sort | uniq -c | sort -nr`

### Advanced Core
- `journalctl -u nginx --since "1 hour ago"` : systemd サービスログを時間範囲で確認
- `awk '{print $1, $9}' access.log` : 列を柔軟に抽出
- `xargs -r` : 空入力時に実行しない安全なバッチ処理
- `watch -n 5 "df -h"` : 5 秒ごとの監視
- `crontab -e` : 定期チェック登録（まずは読み取り系タスクのみ）

---

## 4) 30-60 minute hands-on mini lab

### ゴール
「直近のエラーログを抽出し、頻出原因を集計し、簡易監視コマンドを作る」

### 手順（安全重視）
1. 作業ディレクトリ作成
   ```bash
   mkdir -p ~/linux-mag-lab && cd ~/linux-mag-lab
   ```
2. サンプルログ作成
   ```bash
   cat > app.log <<'EOF'
   2026-03-17T09:00:01 INFO auth login_ok user=alice
   2026-03-17T09:01:12 ERROR api timeout endpoint=/orders
   2026-03-17T09:01:30 WARN db slow_query table=payments
   2026-03-17T09:02:10 ERROR api timeout endpoint=/orders
   2026-03-17T09:03:42 ERROR auth invalid_token user=bob
   2026-03-17T09:04:05 INFO api healthcheck_ok
   EOF
   ```
3. Beginner: 基本確認
   ```bash
   ls -lah
   tail -n 5 app.log
   grep "ERROR" app.log
   ```
4. Middle: 頻出エラーの集計
   ```bash
   grep "ERROR" app.log | awk '{print $4}' | sort | uniq -c | sort -nr
   ```
5. Advanced: 簡易リアルタイム監視
   ```bash
   watch -n 3 "grep 'ERROR' app.log | tail -n 5"
   ```
6. おまけ（安全な定期チェック例）
   ```bash
   crontab -l
   # 例: 毎時0分にディスク使用率をログへ追記（読み取り系）
   # 0 * * * * df -h >> ~/linux-mag-lab/disk-usage.log 2>&1
   ```

所要時間目安: 40 分

---

## 5) Command cheatsheet

```bash
# 閲覧
ls -lah
less app.log
tail -n 100 app.log

# 検索
grep "ERROR" app.log
grep -E "ERROR|WARN" app.log

# 集計
grep "ERROR" app.log | awk '{print $4}' | sort | uniq -c | sort -nr
wc -l app.log

# システムログ
journalctl -u nginx --since "30 min ago"

# 監視
watch -n 5 "df -h"
```

---

## 6) Common mistakes and safe practices

### よくあるミス
- `sudo` を癖で付ける（不要な権限昇格）
- `rm -rf` を補完任せで実行する
- `chmod -R 777` で権限を広げすぎる
- `chown -R` の対象パスを誤る
- 本番ログに対して直接編集系コマンド（`sed -i` など）を実行する

### 安全プラクティス
- **破壊的コマンド前に必ず `pwd` と `ls` で対象確認**
- `rm` の前に `echo` で対象を確認（例: `echo rm -rf ./target`）
- 権限変更は最小限（必要なユーザー・グループ・範囲のみ）
- まずは読み取り専用コマンド（`cat`, `less`, `grep`, `journalctl`）で調査
- `sudo` は必要時のみ。実行理由を言語化してから使う

> ⚠️ 注意: `rm -rf`, `chmod/chown -R`, 安易な `sudo` は重大事故の原因になります。検証環境で手順を固めてから本番へ。

---

## 7) One interview-style question

**質問:**  
本番 API で 5xx が増加したとき、`journalctl` とテキスト処理コマンドを使って「直近1時間のエラー傾向」を5分以内に説明するには、どんなコマンド手順を組みますか？

（狙い: ログ確認の優先順位・再現性・安全性を説明できるか）

---

## 8) Next-step resources

- man ページ入門: `man grep`, `man awk`, `man journalctl`
- The Linux Command Line (William Shotts)
- Linux Foundation の無料学習リソース（LFS 系）
- DevOps Roadmap（ログ監視・運用観点の全体像把握）

次回予告（学習アーク継続）:  
**「権限と所有者の実践運用（Beginner: chmod基礎 → Middle: chown/chgrp運用 → Advanced: ACLと監査）」**