---
tags: [linux, commands, learning, devops, daily]
---

[[Home]]

# Daily Linux Commands Magazine — 2026-03-11

## 学習アークA（Beginner）

### 1) Topic + Level
**テーマ:** ログ確認の基本（`ls`, `cat`, `less`, `tail`）  
**レベル:** Beginner

### 2) Why it matters in real projects
本番障害の初動では、まず「どこで何が起きたか」をログで把握します。  
アプリ開発・インフラ運用・CI/CDトラブル対応のすべてで、ログ閲覧の速さが復旧時間に直結します。

### 3) Core command explanations
- `ls -lah /var/log`
  - ログディレクトリの一覧表示。`-l` 詳細、`-a` 隠しファイル、`-h` 人間に読みやすいサイズ。
- `cat file.log`
  - ファイル全体を一気に表示（巨大ファイルには不向き）。
- `less file.log`
  - ページャで安全に閲覧。`/文字列` で検索、`q` で終了。
- `tail -n 50 file.log`
  - 末尾50行を表示。
- `tail -f file.log`
  - 追記をリアルタイム監視（ログ監視の基本）。

### 4) 30-60 minute hands-on mini lab
**所要:** 35分

1. テスト用ログを作る
   ```bash
   mkdir -p ~/linux-lab/logs
   for i in {1..200}; do echo "$(date '+%F %T') INFO request_id=$i" >> ~/linux-lab/logs/app.log; done
   ```
2. `ls -lah` でサイズ確認。
3. `less` で開き、`/request_id=150` を検索。
4. 別ターミナルで追記しながら `tail -f` 監視。
   ```bash
   while true; do echo "$(date '+%F %T') WARN slow_query" >> ~/linux-lab/logs/app.log; sleep 2; done
   ```
5. `Ctrl+C` で停止し、最後の20行だけ `tail -n 20` で確認。

### 5) Command cheatsheet
```bash
ls -lah /var/log
less /var/log/syslog
tail -n 100 /var/log/messages
tail -f /var/log/nginx/access.log
```

### 6) Common mistakes and safe practices
- **ミス:** `cat` で巨大ログを開いてターミナルが固まる。  
  **対策:** まず `less` または `tail` を使う。
- **ミス:** root権限が必要なログを無理に編集。  
  **対策:** 原則「閲覧中心」、編集は目的とバックアップを明確化。
- **安全:** `sudo` は必要最小限。コマンド内容を確認してから実行。

### 7) One interview-style question
「障害発生直後、`tail -f` と `less` をどう使い分けますか？具体的な調査手順を説明してください。」

### 8) Next-step resources
- `man less`, `man tail`
- Ubuntu / RHEL のログ管理ドキュメント
- systemd journal 入門（次アークにつながる）

---

## 学習アークB（Middle）

### 1) Topic + Level
**テーマ:** ログ抽出と絞り込み（`grep`, `awk`, `sed`, `sort`, `uniq`）  
**レベル:** Middle  
**前提知識:** Beginnerの内容（`less`, `tail`, パイプ `|` の基本）

### 2) Why it matters in real projects
大量ログからエラーの傾向を短時間で特定できると、原因分析の精度が大きく上がります。  
SRE/DevOpsでは「ノイズから有意なシグナルを抽出する力」が必須です。

### 3) Core command explanations
- `grep -E "ERROR|WARN" app.log`
  - 複数パターン検索。
- `grep -v healthcheck app.log`
  - 不要行を除外。
- `awk '{print $3}' app.log`
  - 列抽出（ログ形式が固定なら強力）。
- `sort | uniq -c | sort -nr`
  - 出現回数を集計して多い順に並べる定番パターン。
- `sed -n '1,20p' app.log`
  - 範囲指定表示（1〜20行）。

### 4) 30-60 minute hands-on mini lab
**所要:** 45分

1. 疑似ログ生成
   ```bash
   cat > ~/linux-lab/logs/api.log <<'EOF'
   2026-03-11T09:00:00 INFO /health 200
   2026-03-11T09:00:01 WARN /api/users 429
   2026-03-11T09:00:02 ERROR /api/orders 500
   2026-03-11T09:00:03 INFO /api/users 200
   2026-03-11T09:00:04 ERROR /api/orders 500
   EOF
   ```
2. ERRORだけ抽出。
   ```bash
   grep "ERROR" ~/linux-lab/logs/api.log
   ```
3. エンドポイント別件数を集計。
   ```bash
   awk '{print $3}' ~/linux-lab/logs/api.log | sort | uniq -c | sort -nr
   ```
4. 429/500 だけ抽出して調査メモ作成。
   ```bash
   grep -E " 429| 500" ~/linux-lab/logs/api.log > ~/linux-lab/logs/incidents.txt
   ```

### 5) Command cheatsheet
```bash
grep -E "ERROR|WARN" app.log
grep -v "healthcheck" app.log
awk '{print $3}' app.log
awk '{print $4}' app.log | sort | uniq -c | sort -nr
sed -n '1,50p' app.log
```

### 6) Common mistakes and safe practices
- **ミス:** 正規表現の誤爆で想定外の行まで抽出。  
  **対策:** まず `head` で少量サンプルに対して試す。
- **ミス:** 上書きリダイレクト `>` で元ファイルを失う。  
  **対策:** 元ログには書き込まない。出力先を別ファイルにする。
- **安全:** `sudo grep ... /var/log/...` は最小範囲で。全ディレクトリ再帰は負荷注意。

### 7) One interview-style question
「`grep` と `awk` を組み合わせて、5xxエラーの多いAPIパス上位3件を出すにはどうしますか？」

### 8) Next-step resources
- `man grep`, `man awk`, `man sed`
- 正規表現チートシート
- ログ基盤（Loki/Elasticsearch）に進む前のCLI前処理パターン

---

## 学習アークC（Advanced）

### 1) Topic + Level
**テーマ:** systemd/journal と権限安全運用（`journalctl`, `sudo`, `chmod`, `chown`）  
**レベル:** Advanced  
**前提知識:** Middleまでの内容、Linuxのファイル権限（rwx）基礎

### 2) Why it matters in real projects
モダンLinuxでは systemd 管理下のサービス調査に `journalctl` が必須です。  
同時に、権限操作ミスはインシデントに直結するため、安全運用の理解が重要です。

### 3) Core command explanations
- `journalctl -u nginx --since "1 hour ago"`
  - 特定サービスの直近1時間ログ。
- `journalctl -u sshd -f`
  - サービスログを追尾。
- `sudo -l`
  - 自分に許可された sudo 操作を確認。
- `namei -l /path/to/file`
  - パス各階層の権限を可視化（Permission denied調査に有効）。
- `stat file`
  - 所有者・パーミッション・更新時刻を確認。

### 4) 30-60 minute hands-on mini lab
**所要:** 50分

1. サービスログ確認（読み取り中心）。
   ```bash
   journalctl -u sshd --since "30 min ago" | less
   ```
2. テストファイルで権限検証（安全な作業ディレクトリのみ）。
   ```bash
   mkdir -p ~/linux-lab/perm && cd ~/linux-lab/perm
   touch demo.txt
   ls -l demo.txt
   chmod 640 demo.txt
   stat demo.txt
   ```
3. 権限トラブル再現（自分のファイルでのみ）。
   ```bash
   chmod 000 demo.txt
   ls -l demo.txt
   chmod 640 demo.txt
   ```
4. `namei -l` で親ディレクトリ権限確認。

### 5) Command cheatsheet
```bash
journalctl -u <service> --since "2 hours ago"
journalctl -u <service> -f
sudo -l
stat <file>
namei -l <path>
```

### 6) Common mistakes and safe practices
- **重大注意:** `rm -rf` は破壊的。パス確認なしで実行しない。  
  - 推奨: `pwd` / `ls` で対象確認、必要なら `trash` 相当を優先。
- **重大注意:** `chmod -R 777` は原則NG（過剰権限）。  
  - 推奨: 最小権限（Principle of Least Privilege）で個別設定。
- **重大注意:** `chown -R` の誤用でサービス停止リスク。  
  - 推奨: 対象を限定し、実行前後で `ls -l` 比較。
- **重大注意:** 無目的な `sudo` 常用は危険。  
  - 推奨: 通常ユーザーで検証し、必要時のみ昇格。
- **安全方針:** 防御・運用改善を優先し、攻撃・悪用目的の操作は行わない。

### 7) One interview-style question
「本番で `Permission denied` が発生したとき、`journalctl`・`stat`・`namei` を使った切り分け手順を説明してください。」

### 8) Next-step resources
- `man journalctl`, `man systemd.unit`
- Linux権限モデル（UID/GID/ACL）解説
- SRE本のトラブルシュート章（観測→仮説→検証）

---

## 今日のまとめ
- Beginner: まずは安全にログを読む力を固める
- Middle: パイプで「必要情報だけ」を抽出する
- Advanced: systemdログと権限管理を安全に扱う

次回はこのアークを繰り返し、題材を **プロセス監視（ps/top/htop）** に切り替えると、実務対応力がさらに伸びます。
