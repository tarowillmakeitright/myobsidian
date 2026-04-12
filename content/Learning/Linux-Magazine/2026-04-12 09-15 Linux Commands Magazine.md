# Linux Commands Magazine — 2026-04-12 (09:15)

#linux #commands #learning #devops #daily
[[Home]]

---

## 学習アーク1: ファイル探索と安全な操作（Beginner）

### 1) Topic + Level
**Topic:** `ls` / `pwd` / `cd` / `find` / `cp` / `mv` の基本  
**Level:** Beginner

### 2) Why it matters in real projects
実運用では「どこに何があるか」を素早く把握し、設定ファイルやログを正しい場所へ安全に移動・複製する能力が必須です。  
誤ったパス操作は、デプロイ失敗や設定破壊につながります。

### 3) Core command explanations
- `pwd` : 現在の作業ディレクトリを表示
- `ls -la` : 隠しファイル含め一覧表示（権限・所有者も確認可能）
- `cd <dir>` : ディレクトリ移動（`cd -`で直前の場所へ戻る）
- `find . -name "*.conf"` : 条件でファイル検索
- `cp source dest` : ファイル複製（`-r` でディレクトリ）
- `mv source dest` : 移動/リネーム

### 4) 30-60 minute hands-on mini lab
1. `~/lab/linux-beginner` を作成し移動
2. ダミーファイルを3つ作成（例: `app.conf`, `db.conf`, `notes.txt`）
3. `find` で `.conf` ファイルだけ抽出
4. `backup/` ディレクトリを作って `.conf` を `cp` でバックアップ
5. `notes.txt` を `README.txt` に `mv` でリネーム
6. 最後に `tree` または `find` で構造確認

### 5) Command cheatsheet
```bash
pwd
ls -la
cd /path/to/dir
cd -
find . -name "*.conf"
cp app.conf backup/app.conf
cp -r config/ backup/config/
mv notes.txt README.txt
```

### 6) Common mistakes and safe practices
- **ミス:** `cp -r` / `mv` の宛先パスを誤る  
  **安全策:** 実行前に `pwd` と `ls` で位置確認
- **ミス:** ワイルドカード `*` の想定外展開  
  **安全策:** まず `echo *.conf` で対象確認
- **ミス:** 権限不足で `sudo` を安易に付与  
  **安全策:** なぜ権限不足かを先に確認し、必要最小限で `sudo` を使う

### 7) One interview-style question
「`cp` と `mv` の違いを説明し、設定ファイル更新時に“戻せる運用”をするならどんな手順にしますか？」

### 8) Next-step resources
- `man ls`, `man find`, `man cp`, `man mv`
- The Linux Command Line (William Shotts)

---

## 学習アーク2: ログ調査とパイプ処理（Middle）

### 前提条件（Prerequisites）
- Beginnerレベルのパス操作ができる
- 標準入力/標準出力の概念を理解している

### 1) Topic + Level
**Topic:** `cat` / `less` / `tail` / `grep` / `sort` / `uniq` / `wc` / パイプ  
**Level:** Middle

### 2) Why it matters in real projects
障害対応では、巨大ログから異常パターンを短時間で抽出する力が重要です。  
監視アラート時に、GUIなしのサーバでもCLIだけで原因切り分けできます。

### 3) Core command explanations
- `less file.log` : 大きいファイルを安全に閲覧
- `tail -n 100 file.log` : 末尾100行表示
- `tail -f file.log` : 追記をリアルタイム監視
- `grep "ERROR" file.log` : パターン抽出
- `grep -E "ERROR|WARN" file.log` : 複数条件
- `sort | uniq -c` : ソートして重複件数集計
- `wc -l` : 行数カウント

### 4) 30-60 minute hands-on mini lab
1. サンプルログを作る（INFO/WARN/ERRORを混在）
2. `tail -n` で直近ログ確認
3. `grep` で ERROR 行だけ抽出
4. `grep -E` + `sort` + `uniq -c` でエラー種別を件数化
5. `wc -l` で総行数と異常行比率を算出
6. 結果を `report.txt` に保存

### 5) Command cheatsheet
```bash
less app.log
tail -n 100 app.log
tail -f app.log
grep "ERROR" app.log
grep -E "ERROR|WARN" app.log
grep "ERROR" app.log | sort | uniq -c
grep "ERROR" app.log | wc -l
```

### 6) Common mistakes and safe practices
- **ミス:** `cat 巨大ファイル` で端末を埋める  
  **安全策:** まず `less` / `tail` を使う
- **ミス:** `grep` 条件が広すぎて誤検知  
  **安全策:** 正規表現を絞る、テスト用ログで検証
- **ミス:** 本番ログを誤って上書き  
  **安全策:** リダイレクト `>` は慎重に。まず `tee` や別ファイル出力を使う

### 7) One interview-style question
「障害発生時、5GBのログから10分以内に原因候補を絞るなら、どのコマンドをどう組み合わせますか？」

### 8) Next-step resources
- `man grep`, `man less`, `man tail`
- RegexOne（正規表現練習）

---

## 学習アーク3: 権限・所有権・安全な運用自動化（Advanced）

### 前提条件（Prerequisites）
- Middleレベルのログ調査ができる
- Linuxのユーザー/グループ概念を理解している
- `sudo` の影響範囲を説明できる

### 1) Topic + Level
**Topic:** `chmod` / `chown` / `umask` / `sudo` / バックアップ付き運用手順  
**Level:** Advanced

### 2) Why it matters in real projects
権限設計ミスは情報漏えい・改ざん・サービス停止の直接原因です。  
CI/CDや運用自動化でも、最小権限を守れるかが信頼性を左右します。

### 3) Core command explanations
- `ls -l` : 権限と所有者確認
- `chmod 640 file` : 権限変更（所有者rw, グループr, その他なし）
- `chown user:group file` : 所有者/グループ変更
- `umask 027` : 新規作成時のデフォルト権限制御
- `sudo -l` : 実行可能なsudoコマンド確認

### 4) 30-60 minute hands-on mini lab
1. `secure-lab/` を作り、`secret.txt` を配置
2. `ls -l` で初期権限確認
3. `chmod 600 secret.txt` → 読み取り主体を所有者のみに変更
4. テスト用ユーザー/グループ（可能なら検証環境で）でアクセス可否を確認
5. `umask` を切り替えて新規ファイル権限の違いを比較
6. 「変更前バックアップ -> 変更 -> 検証 -> ロールバック」の手順をスクリプト化（本番適用はしない）

### 5) Command cheatsheet
```bash
ls -l
chmod 600 secret.txt
chmod 640 app.conf
chown deploy:deploy app.conf
umask
umask 027
sudo -l
```

### 6) Common mistakes and safe practices
- **危険:** `chmod -R 777` を安易に使う（重大なセキュリティリスク）
- **危険:** `chown -R` の対象パス誤りでシステム破壊
- **危険:** `sudo` で確認なしに実行
- **危険:** `rm -rf` をワイルドカード付きで実行

**安全策（必須）**
- 破壊的コマンド前に `pwd` / `ls` / 対象パスを二重確認
- 可能なら `--preserve-root` を活用し、`rm` は最小範囲に限定
- 本番変更は「バックアップ→変更→検証→記録」を徹底
- `sudo` は必要最小限、コマンドをフルでレビューしてから実行

### 7) One interview-style question
「`chmod 777` を避ける理由を、セキュリティと運用性の両面から説明してください。代替案は？」

### 8) Next-step resources
- `man chmod`, `man chown`, `man sudoers`, `man umask`
- Linux Foundation training (LFS101/LFCS)
- CIS Benchmarks（Linuxハードニング指針）

---

### 今日のまとめ
- Beginner: 正確なファイル操作
- Middle: ログ解析の実戦パイプライン
- Advanced: 権限設計と安全運用

攻撃的な手法ではなく、**防御・安定運用・再現性**を重視して学習を進めましょう。
