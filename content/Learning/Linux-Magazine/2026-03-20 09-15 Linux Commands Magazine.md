---
tags: [linux, commands, learning, devops, daily]
---

# Daily Linux Commands Magazine — 2026-03-20
[[Home]]

> 学習アーク（Beginner → Middle → Advanced）で、実務で使えるLinuxコマンド力を段階的に伸ばす号です。  
> **安全第一**: 破壊的操作（`rm -rf`、`chmod/chown`の誤用、安易な`sudo`）は必ず影響範囲を確認してから実行。

---

## 1) Topic + Level

### Beginner
**トピック:** ログの基本調査（`ls`, `cat`, `less`, `tail`, `grep`）

### Middle
**トピック:** サービス障害の一次切り分け（`journalctl`, `systemctl`, `ss`, `df`, `du`）  
**前提条件:**
- Beginnerのコマンドでファイル閲覧・検索ができる
- 標準出力/標準エラーの違いをざっくり理解している

### Advanced
**トピック:** 安全な復旧オペレーション設計（`find`, `xargs`, `rsync --dry-run`, 権限確認）  
**前提条件:**
- Middleの調査フローを再現できる
- `sudo`利用時に「なぜ必要か」を説明できる

---

## 2) Why it matters in real projects

- 本番障害の初動は「**速く・安全に・再現可能に**」が重要。
- ログ調査とディスク/プロセス確認は、Web/API/バッチ問わずほぼ毎日使う。
- 誤った権限変更や削除は、障害を拡大させる（復旧時間増、監査リスク増）。
- Defensiveな運用（確認→dry-run→実行）を習慣化すると、チームの信頼性が上がる。

---

## 3) Core command explanations

### Beginner core
- `ls -lah` : ファイルのサイズ・権限・更新日時を見やすく表示
- `less /var/log/...` : 大きいログを安全にページ閲覧（編集しない）
- `tail -n 100 file.log` : 末尾100行を確認
- `tail -f file.log` : 追従表示（リアルタイム監視）
- `grep -n "ERROR" file.log` : 行番号付き検索

### Middle core
- `systemctl status nginx` : サービス状態確認
- `journalctl -u nginx -n 200 --no-pager` : ユニット単位で直近ログ確認
- `ss -ltnp` : 待受ポートとプロセス確認
- `df -h` : ファイルシステム空き容量
- `du -sh /var/log/* | sort -h` : 容量を使っているログ特定

### Advanced core
- `find /var/log -type f -name "*.log" -mtime +7` : 7日超のログ候補抽出
- `find ... -print0 | xargs -0 ...` : 空白を含むファイル名でも安全処理
- `rsync -av --dry-run src/ dst/` : 実行前に差分確認
- `chmod/chown` : 最小権限の原則で限定変更（対象・再帰指定を要確認）

> ⚠️ **危険コマンド注意**
> - `rm -rf` は最終手段。まず `ls` / `find` / `--dry-run` で対象確認。
> - `chmod -R` / `chown -R` は破壊範囲が広い。必ずテストディレクトリで検証。
> - `sudo` は「必要な1コマンド」に限定。シェル全体をrootで常用しない。

---

## 4) 30-60 minute hands-on mini lab

**ラボ名:** 「ログ肥大化で遅くなったAPIサーバーを安全に診断する」  
**目安:** 45分

### Step A (10分) 事象把握
1. `uptime` で負荷確認
2. `df -h` でディスク逼迫有無確認
3. `systemctl status <service>` で異常の有無確認

### Step B (15分) ログ調査
1. `journalctl -u <service> -n 200 --no-pager`
2. エラー抽出: `journalctl -u <service> --since "-2h" | grep -Ei "error|timeout|fail"`
3. ログサイズ確認: `du -sh /var/log/* | sort -h`

### Step C (15分) 安全な対処案作成
1. 古いログ候補の抽出のみ（削除しない）  
   `find /var/log -type f -name "*.log" -mtime +14 | head`
2. 退避シミュレーション  
   `rsync -av --dry-run /var/log/myapp/ /tmp/myapp-log-backup/`
3. 実施前チェックリスト作成
   - 対象パス
   - ロールバック手段
   - 影響範囲

### Step D (5分) ふりかえり
- 「確認→dry-run→実行」の順序を守れたか
- `sudo`使用箇所は最小だったか

---

## 5) Command cheatsheet

```bash
# 閲覧・検索
ls -lah
tail -n 100 /var/log/syslog
tail -f /var/log/nginx/error.log
grep -n "ERROR" /var/log/app.log

# サービス・ログ
systemctl status nginx
journalctl -u nginx -n 200 --no-pager
journalctl -u nginx --since "-1h"

# リソース確認
df -h
du -sh /var/log/* | sort -h
ss -ltnp

# 安全なファイル操作（候補確認）
find /var/log -type f -name "*.log" -mtime +7
rsync -av --dry-run /src/ /dst/
```

---

## 6) Common mistakes and safe practices

**よくあるミス**
- いきなり `sudo rm -rf` を実行する
- `chmod -R 777` で「とりあえず動かす」
- `chown -R` の対象を誤り、アプリ全停止
- `tail -f` だけ見て過去ログを見落とす

**安全プラクティス**
- 破壊的操作前に `pwd` と対象パスを声出し確認
- 先に `find` で候補一覧、次に `--dry-run`、最後に本実行
- 権限は最小化（必要ユーザー/グループだけ）
- 実施内容を作業メモに残す（監査・再発防止）

---

## 7) One interview-style question

「本番でディスク使用率が95%に達し、APIのレスポンスが悪化しました。  
あなたなら**最初の15分**でどのコマンドをどの順番で実行し、なぜその順番にしますか？」

---

## 8) Next-step resources

- manページ: `man journalctl`, `man systemctl`, `man find`, `man rsync`
- The Linux Documentation Project: https://tldp.org/
- DigitalOcean Community (Linux運用記事): https://www.digitalocean.com/community/tutorials
- Practice: 自分用に「障害初動チェックリスト.md」を1ページ作る

---

次号予告: **「権限と所有者の実践（事故らない`chmod/chown`）」**（Beginner→Advanced）
