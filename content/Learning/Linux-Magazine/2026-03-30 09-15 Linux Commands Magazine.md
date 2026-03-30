---
tags: [linux, commands, learning, devops, daily]
---

# Linux Commands Magazine — 2026-03-30 09:15
[[Home]]

今日のテーマは、**実務で使えるログ調査と安全な一括処理**です。  
難易度を **Beginner → Middle → Advanced** の順で進めます（学習アーク）。

---

## Issue 1) Topic + Level
### Topic: ログを素早く調べる（grep / less / tail）
**Level: Beginner**

## 2) Why it matters in real projects
障害対応や運用で最初に行うのは「何が起きたか」の確認です。  
ログを読めると、アプリ障害・設定ミス・デプロイ失敗の切り分け速度が大きく上がります。

## 3) Core command explanations
- `less /var/log/syslog` : ログをページ送りで安全に閲覧（編集はしない）
- `tail -n 50 file.log` : 末尾50行だけ確認
- `tail -f file.log` : 追記をリアルタイム監視
- `grep "ERROR" file.log` : エラー行抽出
- `grep -n "timeout" file.log` : 行番号付き検索
- `grep -i "failed" file.log` : 大文字小文字無視

## 4) 30-60 minute hands-on mini lab
1. テストログ作成
   ```bash
   mkdir -p ~/lab/logs
   cat > ~/lab/logs/app.log <<'EOF'
   INFO start server
   INFO db connected
   WARN retry payment api
   ERROR timeout on payment api
   INFO healthcheck ok
   ERROR failed to write cache
   EOF
   ```
2. まず全体を読む
   ```bash
   less ~/lab/logs/app.log
   ```
3. ERRORだけ抽出
   ```bash
   grep "ERROR" ~/lab/logs/app.log
   ```
4. timeoutの位置確認
   ```bash
   grep -n "timeout" ~/lab/logs/app.log
   ```
5. リアルタイム確認（別ターミナルで追記）
   ```bash
   tail -f ~/lab/logs/app.log
   ```

## 5) Command cheatsheet
```bash
less file.log
tail -n 100 file.log
tail -f file.log
grep "ERROR" file.log
grep -n -i "keyword" file.log
```

## 6) Common mistakes and safe practices
- ❌ いきなりログを削除しない（原因調査不能になる）
- ✅ まず`cp`でバックアップ
- ✅ 読み取り中心コマンド（`less`, `grep`, `tail`）を優先
- ⚠️ `sudo`は最小限（権限のある誤操作は被害が大きい）

## 7) Interview-style question
「`tail -f`と`less`はどう使い分けますか？運用障害時の具体例で説明してください。」

## 8) Next-step resources
- `man grep`, `man tail`, `man less`
- Linux Foundation training (LFS101)
- サービス固有ログ（nginx, systemd-journald）の確認手順

---

## Issue 2) Topic + Level
### Topic: ファイル探索と安全な一括対象選定（find / xargs）
**Level: Middle**
**Prerequisites:** Beginnerの`grep`, `tail`, パイプ(`|`)の基本理解

## 2) Why it matters in real projects
ログローテーション漏れ・容量逼迫・古い一時ファイル清掃など、運用では「条件に一致するファイルを正確に扱う」力が必須です。

## 3) Core command explanations
- `find /path -type f -name "*.log"` : 条件に合うファイル列挙
- `find ... -mtime +7` : 7日より古いファイル
- `find ... -size +100M` : 100MB超のファイル
- `find ... -print0 | xargs -0 ...` : スペース/特殊文字を安全に扱う
- `xargs -I{} cmd {}` : 各ファイルへコマンド適用

## 4) 30-60 minute hands-on mini lab
1. 練習用ファイル作成
   ```bash
   mkdir -p ~/lab/archive
   touch ~/lab/archive/app-{1..5}.log
   dd if=/dev/zero of=~/lab/archive/big.log bs=1M count=5 status=none
   ```
2. 条件に合うファイルを確認（削除しない）
   ```bash
   find ~/lab/archive -type f -name "*.log"
   ```
3. ドライラン（対象表示のみ）
   ```bash
   find ~/lab/archive -type f -name "*.log" -print0 | xargs -0 -I{} echo TARGET: {}
   ```
4. 行数確認を一括実行
   ```bash
   find ~/lab/archive -type f -name "*.log" -print0 | xargs -0 wc -l
   ```
5. 7日超ファイルを“表示だけ”
   ```bash
   find ~/lab/archive -type f -mtime +7 -print
   ```

## 5) Command cheatsheet
```bash
find /var/log -type f -name "*.log"
find /tmp -type f -mtime +3
find . -type f -size +100M
find . -type f -print0 | xargs -0 -I{} echo {}
```

## 6) Common mistakes and safe practices
- ⚠️ `find ... -delete` は危険。**必ず先に-deleteなしで結果確認**
- ⚠️ `xargs rm`は誤爆リスク。まず`echo`でドライラン
- ✅ パスに空白がある前提で`-print0 | xargs -0`を使う
- ⚠️ `sudo find /`は高負荷・高リスク。範囲を絞る

## 7) Interview-style question
「古いログを削除するバッチを作る際、誤削除を防ぐためにどんな段階的手順を入れますか？」

## 8) Next-step resources
- `man find`, `man xargs`
- GNU findutils docs
- 「ドライラン→ログ出力→本番実行」の運用設計パターン

---

## Issue 3) Topic + Level
### Topic: 権限監査と安全な修正（ls -l / chmod / chown）
**Level: Advanced**
**Prerequisites:** Middleの`find`活用、Linuxユーザー/グループ概念、`sudo`の基本

## 2) Why it matters in real projects
権限ミスは、情報漏えい・改ざん・サービス停止の直接原因になります。  
本番運用では「必要最小権限」で整えることがセキュリティと安定性の基本です。

## 3) Core command explanations
- `ls -l` : 所有者/グループ/権限確認
- `stat file` : 詳細メタ情報表示
- `chmod 640 file` : 権限変更（数値）
- `chown user:group file` : 所有者変更
- `find ... -perm` : 危険権限の探索

## 4) 30-60 minute hands-on mini lab
1. 検証用ディレクトリ作成
   ```bash
   mkdir -p ~/lab/perms
   echo secret > ~/lab/perms/secret.txt
   chmod 777 ~/lab/perms/secret.txt
   ls -l ~/lab/perms/secret.txt
   ```
2. 危険設定の確認
   ```bash
   find ~/lab/perms -type f -perm -002 -ls
   ```
3. 適正権限へ修正
   ```bash
   chmod 640 ~/lab/perms/secret.txt
   ls -l ~/lab/perms/secret.txt
   ```
4. 修正前後を記録（監査向け）
   ```bash
   stat ~/lab/perms/secret.txt
   ```
5. （任意）再帰変更の危険性確認
   ```bash
   echo "本番で chmod -R を使う前に対象を find で列挙して確認する"
   ```

## 5) Command cheatsheet
```bash
ls -l path
stat file
chmod 640 file
chown user:group file
find /path -type f -perm -002 -ls
```

## 6) Common mistakes and safe practices
- 🚨 `chmod -R 777` は原則禁止（過剰権限）
- 🚨 `chown -R` を誤ったパスで実行すると大事故
- 🚨 `rm -rf` は**最後の手段**。実行前に`pwd`・対象パス・`echo`確認
- ✅ 変更前に`ls -l`/`stat`で現状記録
- ✅ 本番は「小さく試す→レビュー→全体適用」
- ✅ `sudo`実行時はコマンドを声出し確認するレベルで慎重に

## 7) Interview-style question
「`chmod 777`を避ける理由を、セキュリティと運用性の両面から説明してください。」

## 8) Next-step resources
- `man chmod`, `man chown`, `man stat`
- CIS Benchmarks (Linux)
- 最小権限設計（Principle of Least Privilege）

---

## 学習アークの回し方（次回以降）
- Arc A: ログ調査（今回）
- Arc B: プロセス/サービス管理（`ps`, `top`, `systemctl`, `journalctl`）
- Arc C: ネットワーク診断（`ss`, `ip`, `curl`, `dig`）
- Arc D: ストレージ管理（`df`, `du`, `lsblk`, `mount`）

毎回、Beginner→Middle→Advancedの順で繰り返し、Middle/Advancedには前提知識を明記して進める。
