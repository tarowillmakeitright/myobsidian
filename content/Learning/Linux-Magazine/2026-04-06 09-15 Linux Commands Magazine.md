# 2026-04-06 Linux Commands Magazine（09:15）

#linux #commands #learning #devops #daily  
[[Home]]

---

## 1) Topic + Level

**テーマ:** Linuxログ調査とディスク健全性チェック（現場運用の基礎）  

### 🟢 Beginner
- **レベル:** 入門
- **到達目標:** 「いま何が起きているか」をログとディスク使用率から把握できる

### 🟡 Middle
- **レベル:** 中級
- **前提条件:** `ls`, `cat`, `grep`, `du`, `df` の基本が使えること
- **到達目標:** 障害予兆（ディスク逼迫・エラーログ増加）を絞り込んで説明できる

### 🔴 Advanced
- **レベル:** 上級
- **前提条件:** パイプ、リダイレクト、`journalctl` 基本、権限概念（owner/group/others）
- **到達目標:** 安全策付きでログ調査～容量対策までの運用フローを設計できる

---

## 2) Why it matters in real projects

- 本番障害の初動は **「ログ確認」と「ディスク確認」** が最優先。
- ディスク満杯は、DB停止・CI失敗・アプリ異常の連鎖を引き起こしやすい。
- `rm -rf` のような雑な対処は復旧を難しくするため、**安全な手順化** が評価される。

---

## 3) Core command explanations

### Beginnerコア
- `df -h` : ファイルシステムの使用率を人間向け表示
- `du -sh *` : ディレクトリごとのサイズ要約
- `tail -n 50 /var/log/<file>` : 最新ログを確認
- `grep -i "error" <file>` : エラー行を抽出（大文字小文字無視）

### Middleコア
- `journalctl -p err -n 100 --no-pager` : 直近の高優先度エラー確認
- `find /var/log -type f -name "*.log" -size +100M` : 大きいログ探索
- `sort | uniq -c | sort -nr` : 頻出パターン集計
- `du -xhd1 / | sort -h` : 同一FS内で容量を食う場所を特定

### Advancedコア
- `sudo journalctl --since "-2h" -u <service>` : サービス単位の時系列調査
- `sudo lsof +L1` : 削除済みなのに掴まれたファイル（隠れ容量）確認
- `sudo find / -xdev -type f -size +500M 2>/tmp/find_err.log` : 安全に巨大ファイル探索（エラー分離）
- `sudo du -x /var --max-depth=2 | sort -n | tail` : `/var` 内ホットスポット抽出

> ⚠️ **破壊的操作の前に必ず確認**: `rm -rf`, `chmod -R`, `chown -R`, `sudo` 実行は対象パスを `pwd` / `ls` / `echo` で二重確認。

---

## 4) 30-60 minute hands-on mini lab

**ラボ名:** 「/var 圧迫の原因を安全に切り分ける」  
**所要:** 40分

### Step 0（安全準備・5分）
```bash
mkdir -p ~/linux-lab && cd ~/linux-lab
pwd
```
- 作業場所を限定。いきなり `/` 直下で作業しない。

### Step 1（現状把握・10分）
```bash
df -h
sudo du -xhd1 /var | sort -h
```
- `/var` が太っているか確認し、上位ディレクトリをメモ。

### Step 2（ログ観察・10分）
```bash
sudo find /var/log -type f -name "*.log" -size +50M -print
sudo journalctl -p warning -n 200 --no-pager | tail -n 50
```
- 大きいログと警告傾向を確認。

### Step 3（エラー頻度の可視化・10分）
```bash
sudo journalctl --since "-1h" --no-pager \
  | grep -Ei "error|fail|timeout" \
  | sed 's/[0-9]\+/NUM/g' \
  | sort | uniq -c | sort -nr | head
```
- 類似エラーを集約して「何が多いか」を判断。

### Step 4（安全対策案の作成・5-15分）
- すぐ削除しない。まずは以下を提案としてまとめる：
  1. logrotate設定確認
  2. 不要なデバッグログの出力レベル見直し
  3. 古いアーカイブを退避（削除前にバックアップ）

> ✅ ゴール: 「どこが容量を使い、どのエラーが多いか」を根拠付きで説明できること。

---

## 5) Command cheatsheet

```bash
# 使用率の確認
df -h

# ディレクトリ容量（上位）
sudo du -xhd1 /var | sort -h

# 大きいログ検出
sudo find /var/log -type f -name "*.log" -size +100M

# 直近エラー
journalctl -p err -n 100 --no-pager

# サービス単位ログ
sudo journalctl -u nginx --since "-30m" --no-pager

# 削除済みオープンファイル
sudo lsof +L1
```

---

## 6) Common mistakes and safe practices

### よくあるミス
- `sudo rm -rf /var/log/*` を即実行して証跡を消す
- `chmod -R 777` で権限問題を“力技”解決
- `chown -R` の対象ミスでサービス起動不能
- `sudo` でのコピペ実行（コマンド意味未確認）

### 安全プラクティス
- 破壊操作前に **dry-run相当** を行う（`find ... -print` で対象確認）
- 削除より先に **退避**（`cp -a` / バックアップ）
- `sudo` 実行前に「目的・対象・影響」を1行で言語化
- 権限変更は最小範囲・最小権限（Principle of Least Privilege）

---

## 7) One interview-style question

**Q.** 「本番サーバーで `/var` 使用率が95%を超えました。サービスは断続的にタイムアウト。あなたの初動30分を、**安全性を担保しながら**説明してください。」

（評価ポイント: 事実収集順序、証跡保全、破壊的操作の回避、再発防止の視点）

---

## 8) Next-step resources

- manページ: `man journalctl`, `man du`, `man find`, `man logrotate`
- 公式: systemd journal docs  
  https://www.freedesktop.org/software/systemd/man/journalctl.html
- 実践演習: 「障害対応Runbook」を自分用に1ページ作る
- 次号予告（学習アーク継続）:  
  **Beginner→Middle→Advanced: 権限管理（chmod/chown/umask/ACL）を安全に扱う**
