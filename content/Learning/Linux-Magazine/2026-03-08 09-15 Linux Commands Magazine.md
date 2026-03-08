---
tags: [linux, commands, learning, devops, daily]
---

# Daily Linux Commands Magazine - 2026-03-08
[[Home]]

## 1) Topic + Level

### 今回の学習アーク: ログ調査と運用トラブルシューティング

- **Beginner（初級）**: `cat` / `less` / `tail` / `wc` でログを安全に読む
- **Middle（中級）**: `grep` / `sort` / `uniq` / `cut` で異常パターンを抽出する
  - **前提知識**: 初級のコマンド、標準入力/出力、パイプ（`|`）
- **Advanced（上級）**: `find` / `xargs` / `journalctl` / `awk` で複数ログを横断分析する
  - **前提知識**: 中級までの内容、正規表現の基本、権限（read権限）

---

## 2) Why it matters in real projects（なぜ実務で重要か）

本番障害の初動では、まず「何が起きたか」をログから素早く把握する必要があります。  
アプリ・Webサーバ・systemdログを安全に確認し、エラー頻度や発生時刻を絞れると、復旧時間（MTTR）を大きく短縮できます。  
また、ログ分析スキルは DevOps/SRE の基礎体力であり、障害対応・監視改善・再発防止策の提案まで一気通貫で行えるようになります。

---

## 3) Core command explanations（コアコマンド解説）

### Beginner

- `less file.log`  
  大きいファイルをページング表示。**まずこれを使う**のが安全。編集はしない。
- `tail -n 50 file.log`  
  末尾50行を確認。直近エラーの把握に有効。
- `tail -f file.log`  
  追記をリアルタイム監視。障害再現時の観察で便利。
- `wc -l file.log`  
  総行数確認。ログ規模感をつかむ。

### Middle

- `grep -i "error" app.log`  
  大文字小文字を無視して error を抽出。
- `grep -E "timeout|failed|denied" app.log`  
  OR検索で複数エラー種別を同時確認。
- `cut -d ' ' -f 1 app.log`  
  区切り文字を指定して必要列だけ取り出す。
- `sort | uniq -c | sort -nr`  
  出現回数を集計して多い順に並べる（頻出エラー調査の基本）。

### Advanced

- `journalctl -u nginx --since "2026-03-08 08:00" --until "2026-03-08 09:15"`  
  systemd管理サービスの時間帯絞り込み。
- `find /var/log -type f -name "*.log"`  
  対象ログの探索。`-type f` でファイル限定。
- `find ... -print0 | xargs -0 grep -H "ERROR"`  
  空白入りファイル名に安全対応して横断検索。
- `awk '{print $1, $2, $5}' app.log`  
  欲しい列だけ整形表示。時刻+コードなどの観察に有効。

---

## 4) 30-60 minute hands-on mini lab（実践ミニラボ）

### 目標

疑似ログから「頻出エラー上位3件」「直近10分の失敗イベント」「影響範囲（どのサービスか）」を特定する。

### 手順（約45分）

1. **準備（5分）**
   ```bash
   mkdir -p ~/lab/linux-mag && cd ~/lab/linux-mag
   cat > app.log <<'EOF'
   2026-03-08T08:58:01 app1 INFO start request_id=1
   2026-03-08T08:58:03 app1 ERROR timeout request_id=2
   2026-03-08T08:58:10 app2 WARN retry request_id=3
   2026-03-08T09:01:12 app1 ERROR failed_login request_id=4
   2026-03-08T09:03:45 app3 ERROR denied request_id=5
   2026-03-08T09:07:21 app1 ERROR timeout request_id=6
   2026-03-08T09:10:05 app2 INFO healthcheck request_id=7
   2026-03-08T09:12:49 app3 ERROR timeout request_id=8
   EOF
   ```

2. **初級タスク（10分）**
   - `less app.log` で全体を読む
   - `tail -n 5 app.log` で最新を確認
   - `wc -l app.log` で行数を確認

3. **中級タスク（15分）**
   - エラーのみ抽出:
     ```bash
     grep "ERROR" app.log
     ```
   - エラー種別の頻度集計:
     ```bash
     grep "ERROR" app.log | awk '{print $4}' | sort | uniq -c | sort -nr
     ```
   - サービス別件数:
     ```bash
     grep "ERROR" app.log | awk '{print $2}' | sort | uniq -c | sort -nr
     ```

4. **上級タスク（15分）**
   - 9:05以降のERRORを抽出:
     ```bash
     awk '$1 >= "2026-03-08T09:05:00" && $3 == "ERROR" {print}' app.log
     ```
   - 複数ログ想定（追加ファイルを作って `find + xargs` で横断検索）:
     ```bash
     cp app.log app2.log
     find . -type f -name "app*.log" -print0 | xargs -0 grep -H "timeout"
     ```

5. **振り返り（5分）**
   - 「何が一番多い障害か？」
   - 「どのサービスで再発しやすいか？」
   - 「次に監視アラート化するならどの指標か？」

---

## 5) Command cheatsheet（チートシート）

```bash
# 閲覧
less file.log
tail -n 100 file.log
tail -f file.log

# 検索
grep -i "error" file.log
grep -E "timeout|failed|denied" file.log

# 集計
grep "ERROR" file.log | awk '{print $4}' | sort | uniq -c | sort -nr

# 時刻フィルタ（文字列比較が成立するISO8601前提）
awk '$1 >= "2026-03-08T09:00:00" {print}' file.log

# 複数ファイル横断（安全な0区切り）
find /var/log/myapp -type f -name "*.log" -print0 | xargs -0 grep -H "ERROR"

# systemdログ
journalctl -u nginx --since "1 hour ago"
```

---

## 6) Common mistakes and safe practices（よくあるミスと安全策）

### よくあるミス

- いきなり `sudo` で操作してしまう（不要な権限昇格）
- `cat` で巨大ログを開いて端末を固める
- `grep -r /` のように広すぎる検索を実行して性能劣化
- ログ調査中に誤って削除・権限変更する

### 安全策（重要）

- **原則は読み取り専用コマンドから開始**（`less`, `tail`, `grep`, `awk`）
- **破壊的コマンドは実行前に対象を必ず確認**
  - `rm -rf ...` は最終手段。実行前に `pwd` と `ls` で対象確認
  - `chmod/chown` は誤るとサービス停止や情報漏えいにつながる
- `sudo` は「必要なコマンドにだけ」限定して使う
- 本番前に検証環境で同手順を再現する
- `find`/`xargs` は `-print0` / `-0` を使って安全に扱う

> ⚠️ 注意: `rm -rf`, 広範囲 `chown -R`, 無差別 `chmod -R 777` は重大事故の典型です。意味と範囲を理解できない場合は実行しないでください。

---

## 7) One interview-style question（面接風質問）

「本番で API レイテンシ急増アラートが出ました。あなたはSSH接続後、最初の10分でどのログを、どのコマンド順で確認しますか？その順番にした理由も説明してください。」

---

## 8) Next-step resources（次の学習リソース）

- `man grep`, `man awk`, `man journalctl`
- The Linux Documentation Project: https://tldp.org/
- DigitalOcean Linux command line tutorials: https://www.digitalocean.com/community/tutorials
- `sadservers.com` で障害対応ハンズオン
- 次回予告（学習アーク継続）:
  - Beginner: `tar` / `gzip` で安全バックアップ
  - Middle: `rsync` で差分同期
  - Advanced: `systemd timer` + ローテーション自動化
