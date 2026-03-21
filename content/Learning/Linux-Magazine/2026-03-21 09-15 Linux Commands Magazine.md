# Daily Linux Commands Magazine — 2026-03-21 09:15
#linux #commands #learning #devops #daily
[[Home]]

今日のテーマは **「ログ監視と安全な運用コマンド」** です。  
同じ題材を Beginner → Middle → Advanced の順で深める学習アーク形式にしています。

---

## Learning Arc 1 — Beginner

### 1) Topic + Level
**トピック:** 基本ログ確認とシステム状況把握  
**レベル:** Beginner

### 2) Why it matters in real projects
本番障害の最初の一歩は「状況を正しく観測すること」です。  
`ls` / `cat` / `tail` / `grep` を安全に使えるだけで、原因切り分けの速度が大きく上がります。

### 3) Core command explanations
- `pwd` : 現在地の確認（誤操作防止の基本）
- `ls -lah` : ファイル一覧を見やすく表示
- `cat file` : 全文表示（大きいファイルには不向き）
- `less file` : ページャで安全に閲覧（推奨）
- `tail -n 50 file` : 末尾50行を確認
- `tail -f file` : 追記をリアルタイム監視（Ctrl+Cで終了）
- `grep "ERROR" file` : エラー行抽出

### 4) 30-60 minute hands-on mini lab
**所要:** 30分
1. 練習ディレクトリ作成:
   ```bash
   mkdir -p ~/lab/linux-mag && cd ~/lab/linux-mag
   ```
2. 疑似ログ作成:
   ```bash
   for i in {1..200}; do
     if (( i % 25 == 0 )); then
       echo "$(date '+%F %T') ERROR request_id=$i timeout" >> app.log
     else
       echo "$(date '+%F %T') INFO request_id=$i ok" >> app.log
     fi
   done
   ```
3. 末尾確認・検索:
   ```bash
   tail -n 20 app.log
   grep "ERROR" app.log
   grep -n "ERROR" app.log
   ```
4. 別ターミナルで追記し、`tail -f`で監視:
   ```bash
   echo "$(date '+%F %T') ERROR request_id=999 db_down" >> app.log
   ```

### 5) Command cheatsheet
```bash
pwd
ls -lah
less app.log
tail -n 50 app.log
tail -f app.log
grep "ERROR" app.log
grep -n "ERROR" app.log
```

### 6) Common mistakes and safe practices
- **ミス:** いきなり `cat` で巨大ログを開いて固まる  
  **安全策:** `less` と `tail` を優先
- **ミス:** 現在ディレクトリ未確認で操作  
  **安全策:** 実行前に `pwd` と `ls`
- **注意:** `sudo` は必要時のみ。読み取り作業に不要な `sudo` を使わない

### 7) One interview-style question
「`tail -f` と `less +F` の使い分けを、ログ監視の現場視点で説明してください。」

### 8) Next-step resources
- `man tail`, `man grep`, `man less`
- Linux Journey (ログ/テキスト処理章)

---

## Learning Arc 2 — Middle

### 1) Topic + Level
**トピック:** ジャーナルログ分析と絞り込み  
**レベル:** Middle  
**前提条件:** Beginnerの内容（`tail` / `grep` / `less`）を使えること

### 2) Why it matters in real projects
systemd環境では `journalctl` が一次情報源です。  
「いつから壊れたか」「どのサービスで発生したか」を時間軸で絞る力が、復旧時間を短縮します。

### 3) Core command explanations
- `systemctl status <service>` : サービス状態確認
- `journalctl -u <service>` : サービス単位のログ閲覧
- `journalctl --since "1 hour ago"` : 時間範囲絞り込み
- `journalctl -p err..alert` : 優先度で抽出
- `journalctl -f -u <service>` : リアルタイム追跡

### 4) 30-60 minute hands-on mini lab
**所要:** 45分
1. 監視対象を決める（例: sshd / cron / NetworkManager）:
   ```bash
   systemctl status sshd --no-pager
   ```
2. 直近1時間のエラーログ確認:
   ```bash
   journalctl -u sshd --since "1 hour ago" -p err..alert --no-pager
   ```
3. 起動以降のログを時系列確認:
   ```bash
   journalctl -u sshd --since today --no-pager | less
   ```
4. 監視モード:
   ```bash
   journalctl -f -u sshd
   ```
5. 見つけた事象を「時刻・症状・仮説」でメモする

### 5) Command cheatsheet
```bash
systemctl status sshd --no-pager
journalctl -u sshd --since "1 hour ago" --no-pager
journalctl -u sshd -p err..alert --no-pager
journalctl -f -u sshd
journalctl --since today --no-pager | less
```

### 6) Common mistakes and safe practices
- **ミス:** 全ログを無差別に見て時間を浪費  
  **安全策:** `-u`, `--since`, `-p` で先に絞る
- **ミス:** ログ調査なのに設定変更まで一気に実施  
  **安全策:** 調査フェーズと変更フェーズを分離
- **注意:** `sudo journalctl` は必要な場合のみ。操作ログを残す意識を持つ

### 7) One interview-style question
「`journalctl` を使って“本日発生した特定サービスの重大エラーだけ”を抽出する実運用コマンド例を示してください。」

### 8) Next-step resources
- `man journalctl`, `man systemctl`
- systemd公式ドキュメント（journal / unit 管理）

---

## Learning Arc 3 — Advanced

### 1) Topic + Level
**トピック:** 容量逼迫を想定した安全な運用（ディスク調査・ローテーション前点検）  
**レベル:** Advanced  
**前提条件:** Beginner + Middle（ログの場所特定、`journalctl` 絞り込み、基本シェル操作）

### 2) Why it matters in real projects
ディスクフルは障害連鎖（書き込み失敗、DB停止、監視停止）を招きます。  
“削除する前に調査・退避・影響確認”の順序を守れるかが、SRE/運用の実力差になります。

### 3) Core command explanations
- `df -h` : ファイルシステム全体の使用率
- `du -h --max-depth=1 <dir>` : ディレクトリ単位の容量内訳
- `find <dir> -type f -size +100M` : 大容量ファイル探索
- `ls -lhS` : サイズ順表示
- `truncate -s 0 <file>` : ログ内容を空にする（要注意）

> ⚠ **破壊的操作の警告**
> - `rm -rf` は最後の手段。パス誤りで致命傷になります。  
> - `chmod -R` / `chown -R` の誤用は権限事故の定番。対象を必ず限定。  
> - `sudo` は被害を拡大しやすいので、コマンドと対象を声に出して確認してから実行。

### 4) 30-60 minute hands-on mini lab
**所要:** 60分
1. 容量確認:
   ```bash
   df -h
   ```
2. 練習用ディレクトリを作り、ダミーファイル生成:
   ```bash
   mkdir -p ~/lab/disk-check && cd ~/lab/disk-check
   dd if=/dev/zero of=big1.log bs=1M count=120 status=progress
   dd if=/dev/zero of=big2.log bs=1M count=80 status=progress
   ```
3. どこが重いか調べる:
   ```bash
   du -h --max-depth=1 . | sort -h
   ls -lhS
   ```
4. 100MB超のファイル検出:
   ```bash
   find . -type f -size +100M -print
   ```
5. **削除せず**に安全策を練習:
   - `mv` で退避ディレクトリへ移動
   - `gzip` で圧縮して差分確認
6. 最後にクリーンアップ（対象確認後）:
   ```bash
   pwd
   ls -lah
   rm -i big1.log big2.log
   ```

### 5) Command cheatsheet
```bash
df -h
du -h --max-depth=1 /var/log | sort -h
find /var/log -type f -size +100M -print
ls -lhS /var/log
# 危険: truncate/rm は対象を3回確認してから
```

### 6) Common mistakes and safe practices
- **ミス:** いきなり `rm -rf /var/log/*`  
  **安全策:** 先に `du` / `find` で特定 → 退避 → 影響確認
- **ミス:** `chown -R` を広範囲に実行してサービス停止  
  **安全策:** `--from` や限定パス、事前に `ls -l` で確認
- **ミス:** `sudo` 常用で誤操作拡大  
  **安全策:** 普段は一般権限、必要箇所のみ昇格
- **推奨:** 本番前に検証環境で手順化（Runbook化）

### 7) One interview-style question
「/var の使用率が 95% になったとき、サービス停止リスクを最小化する調査〜緩和手順を5分で説明してください。」

### 8) Next-step resources
- `man df`, `man du`, `man find`, `man logrotate`
- The Linux Documentation Project (運用管理)
- SRE本（障害対応・運用設計の章）

---

## 今日のまとめ
- 初級: **見る力**（ログ観測）
- 中級: **絞る力**（時間・サービス・優先度）
- 上級: **守る力**（安全に容量問題へ対処）

明日はこの続編として、`ps` / `top` / `ss` を使った「プロセス・ネットワーク観測アーク」に進むと効果的です。