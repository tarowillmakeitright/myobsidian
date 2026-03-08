---
tags: [linux, commands, learning, devops, daily]
---

# 2026-03-06 09:15 Linux Commands Magazine
[[Home]]

#linux #commands #learning #devops #daily

## 今号の学習アーク（Beginner → Middle → Advanced）
- **Beginner**: ログ調査の基本（`ls`, `cat`, `less`, `tail`, `grep`）
- **Middle**: ログ抽出と集計（`grep`, `awk`, `sort`, `uniq`, `wc`）
- **Advanced**: 障害一次対応の自動化（安全な Bash スクリプト、`journalctl`, `tee`）

> 安全方針: 破壊的な操作（`rm -rf`, `chmod/chown`の誤用, 無闇な`sudo`）は**必ず対象確認**してから実行。検証環境優先。

---

## 1) Topic + Level
### Topic A（Beginner）
**テーマ:** Linuxログを読んで状況を把握する第一歩

### Topic B（Middle）
**テーマ:** ログから「必要な行だけ」を正確に抜き出し、件数を数える
**前提知識:** Beginnerの内容（`less`, `tail`, `grep`の基本）

### Topic C（Advanced）
**テーマ:** 障害調査の初動を再現可能にする安全なシェル自動化
**前提知識:** Middleの内容（パイプライン、`awk/sort/uniq`）+ Bash基礎

---

## 2) Why it matters in real projects
- 本番障害では「まずログ」。読めるかどうかで復旧速度が変わる。
- SRE/DevOps現場では、手作業の調査を**再現可能なコマンド列**にする能力が重要。
- 監査対応や原因分析では、抽出条件を説明できること（例: 5xxのみ、直近10分のみ）が求められる。

---

## 3) Core command explanations
### Beginner（観察）
- `ls -lah`: ファイルサイズ・権限・隠しファイル確認
- `less /var/log/...`: 大きいログを安全に閲覧（編集しない）
- `tail -n 100 file.log`: 末尾100行を確認
- `tail -f file.log`: 追尾表示（Ctrl+Cで終了）
- `grep "ERROR" file.log`: 該当行の抽出

### Middle（抽出・集計）
- `grep -E "ERROR|WARN" app.log`: 複数条件
- `awk '{print $1, $2, $5}' app.log`: 列抽出
- `sort | uniq -c | sort -nr`: 出現頻度ランキング
- `wc -l`: 件数カウント
- 例:
  `grep " 500 " access.log | awk '{print $7}' | sort | uniq -c | sort -nr | head`

### Advanced（自動化・運用安全）
- `journalctl -u nginx --since "10 min ago"`: systemdサービスログの時系列確認
- `set -euo pipefail`: スクリプト安全設定（失敗早期検知）
- `tee`: 画面表示しながら調査結果保存
- 例:
```bash
#!/usr/bin/env bash
set -euo pipefail

since="10 min ago"
out="incident-summary-$(date +%F-%H%M).txt"

{
  echo "=== Nginx 5xx in ${since} ==="
  journalctl -u nginx --since "$since" --no-pager | grep " 5[0-9][0-9] " || true
} | tee "$out"

echo "saved: $out"
```

---

## 4) 30-60 minute hands-on mini lab
### ゴール
「HTTP 500増加」の仮説を、ログ確認→抽出→集計→レポート保存まで実施する。

### 手順（45分想定）
1. **準備 (5分)**
   - サンプルログを用意（または既存のaccess.logをコピーして練習）
   - 本番ログは直接編集しない（読み取り専用）
2. **観察 (10分)**
   - `ls -lah`, `less`, `tail -n 50`で構造把握
3. **抽出 (10分)**
   - `grep " 500 " access.log`で5xx行抽出
4. **集計 (10分)**
   - URL別件数ランキング作成
   - `grep " 500 " access.log | awk '{print $7}' | sort | uniq -c | sort -nr | head`
5. **保存と共有準備 (10分)**
   - `tee`で結果をファイル化
   - 「いつ」「何を」「どの条件で」抽出したかメモ

### 成果物
- `incident-summary-YYYY-MM-DD-HHMM.txt`
- 5xx上位URLと件数
- 次に見るべきログ（アプリ、DB、LB）の候補

---

## 5) Command cheatsheet
- 閲覧: `less file.log`, `tail -n 100 file.log`, `tail -f file.log`
- 抽出: `grep "ERROR" file.log`, `grep -E "ERROR|WARN" file.log`
- 集計: `awk '{print $7}'`, `sort`, `uniq -c`, `wc -l`
- systemd: `journalctl -u <service> --since "10 min ago" --no-pager`
- 保存: `... | tee result.txt`

---

## 6) Common mistakes and safe practices
### よくあるミス
- `sudo`を常用し、誤操作の影響を拡大
- `rm -rf`を補完任せで実行
- `chmod -R 777`で一時しのぎ（重大なセキュリティリスク）
- `chown -R`の対象を誤る

### 安全プラクティス
- 破壊的コマンド前に `pwd` と `ls` で対象確認
- まず `echo` でコマンド展開確認（特にワイルドカード）
- 権限変更は最小権限原則（必要な範囲だけ）
- `sudo`は必要時のみ。理由を言語化してから実行
- 可能なら検証環境で再現してから本番適用

---

## 7) One interview-style question
「アクセスログから5xx増加を検知したとき、あなたなら最初の15分でどのコマンドをどう組み合わせて切り分けますか？
“再現性”と“安全性”の観点も含めて説明してください。」

---

## 8) Next-step resources
- manページ: `man grep`, `man awk`, `man journalctl`, `man bash`
- The Linux Command Line（William Shotts）
- Google SRE Book（障害対応・運用の原則）
- 実践課題: 同じ分析を `zgrep`（圧縮ログ）と `jq`（JSONログ）でも実施

---

次号予告: 「権限管理の実践（umask / chmod / chown / ACL）— 安全な運用変更フロー」