---
tags: [linux, commands, learning, devops, daily]
---

[[Home]]

# 2026-04-27 09:15 Linux Commands Magazine

## 1) 今日の1コマンド（command name + one-line summary）
**`du`** — ディレクトリやファイルの使用容量を素早く可視化し、容量逼迫の原因を特定するコマンド。

## 2) 実務で使う場面（2-4 concrete scenarios）
- サーバのディスク使用率が急増したとき、どの配下が肥大化しているかを切り分ける
- CIワーカーやビルド環境で、キャッシュや成果物の容量を点検する
- ログローテーション前に `logs/` 配下のサイズを確認し、削除対象を判断する
- 開発端末で Docker/Node/Python の作業ディレクトリ容量を比較する

## 3) よく使うオプション（at least 3 options with explanation）
- `-h` : 人間が読みやすい単位（K/M/G）で表示
- `-s` : 合計のみ表示（サマリ確認に便利）
- `--max-depth=N` : 深さNまでで集計し、調査範囲を制御
- `-x` : 別ファイルシステムを跨がずに集計（マウント先混入を防ぐ）
- `-a` : ファイル単位まで表示（詳細調査向け）

## 4) 実例コマンド（at least 5 examples, copy-paste ready）
```bash
# 1) カレント配下を1階層で容量確認
du -h --max-depth=1 .

# 2) /var/log の合計サイズだけ確認
sudo du -sh /var/log

# 3) ホーム配下の上位候補を確認（2階層まで）
du -h --max-depth=2 ~/ | sort -h

# 4) 別FSを除外して / 配下を調査（本体ディスクだけ見たい場合）
sudo du -xh --max-depth=1 /

# 5) build配下をファイル単位で確認して大きい順に表示
du -ah ./build | sort -h | tail -n 20
```

## 5) よくあるミスと安全ポイント
- **`/` 全体を無計画に実行して重い**: まず `--max-depth=1` で粗く当たりをつけてから深掘りする。
- **権限不足で見落とす**: システム領域は `sudo du ...` を使わないと実態が見えないことがある。
- **別マウントを誤集計**: 意図しないNFS/外部ボリュームを含めたくない場合は `-x` を付ける。
- **見た目容量と実使用量の混同**: 併せて `df -h` でファイルシステム全体の空き容量を確認する。

## 6) 追加学習（manページの読みどころ or related command）
- `man du` の **"--max-depth"**, **"--exclude"**, **"--apparent-size"** を読むと現場での精度が上がる。
- 関連コマンド: `df`, `ncdu`, `find`（大容量ファイル探索）。
