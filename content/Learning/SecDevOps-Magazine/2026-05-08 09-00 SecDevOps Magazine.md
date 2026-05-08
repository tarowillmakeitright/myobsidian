---
tags:
  - security
  - devops
  - docker
  - kubernetes
  - terraform
  - linux
  - cloudsecurity
  - observability
  - daily
---

[[Home]]

# SecDevOps Magazine — 2026-05-08

## 今日の学習テーマ（Issue #001）
**Topic:** Linux Command Mastery for Security Ops（ログ調査と初動トリアージ）  
**Level:** **Beginner**

> 学習アーク: **Beginner → Middle → Advanced** を3日単位で繰り返します。  
> 今回はアーク1のDay 1（Beginner）。次回は同系統のMiddle（より実運用寄り）、その次はAdvanced（障害・侵害対応寄り）へ進みます。

---

### 1) なぜ実務で重要か
インシデント対応や運用トラブルでは、まず「何が起きているか」を素早く把握する必要があります。  
その最短ルートが Linux コマンドです。GUIに頼らず、SSH先でも即座に調査できることは、
- MTTR（復旧時間）短縮
- 誤検知と見落としの削減
- セキュリティ事故の初動精度向上
に直結します。

---

### 2) Core Concepts（要点）
- **標準入力/出力とパイプ (`|`)**  
  小さなコマンドをつなぎ、必要な情報だけを抽出する考え方。
- **絞り込み (`grep`, `awk`, `sed`)**  
  ログから「異常パターン」「特定IP」「エラーレベル」を抜き出す基本。
- **時系列確認 (`journalctl`, `tail -f`)**  
  “いつから”壊れたかを追う。時刻境界の確認が最重要。
- **プロセス/ネットワーク観測 (`ps`, `ss`)**  
  不審プロセス・想定外のLISTENポート・外向き通信を見つける。
- **権限と所有者 (`ls -l`, `find -perm`)**  
  危険な権限（例: world writable）を発見してリスク低減する。

---

### 3) Hands-on Mini Lab（30–60分）
**目的:** 「Webアプリが遅い・エラーが出る」状況を、Linuxだけで初動調査する。

#### 手順
1. テスト用ログを作成
```bash
mkdir -p ~/lab/secdevops && cd ~/lab/secdevops
cat > app.log <<'EOF'
2026-05-08T08:40:02Z INFO request_id=1 path=/health status=200 latency_ms=12 ip=10.0.0.10
2026-05-08T08:44:11Z WARN request_id=2 path=/login status=401 latency_ms=33 ip=203.0.113.4
2026-05-08T08:46:03Z ERROR request_id=3 path=/api/pay status=500 latency_ms=1450 ip=10.0.0.15
2026-05-08T08:47:19Z ERROR request_id=4 path=/api/pay status=500 latency_ms=1610 ip=10.0.0.15
2026-05-08T08:48:55Z INFO request_id=5 path=/health status=200 latency_ms=11 ip=10.0.0.10
EOF
```

2. エラー頻度を確認
```bash
grep "ERROR" app.log | wc -l
grep "status=500" app.log
```

3. 高遅延リクエストを抽出（1000ms超）
```bash
awk -F'latency_ms=' '{if (NF>1) {split($2,a," "); if (a[1] > 1000) print $0}}' app.log
```

4. 送信元IPごとの件数集計
```bash
awk -F'ip=' 'NF>1 {print $2}' app.log | sort | uniq -c | sort -nr
```

5. リアルタイム監視の擬似体験
```bash
tail -f app.log
# 別ターミナルで echo '...ERROR...' >> app.log して挙動確認
```

**ゴール:**  
- 500エラー発生箇所（`/api/pay`）を特定できる  
- 高遅延と関係するログ行を抜き出せる  
- “どのIP・どの時刻で異常が増えたか”を説明できる

---

### 4) Command Cheatsheet
```bash
# ログ閲覧
less app.log
tail -n 100 app.log
tail -f app.log

# フィルタリング
grep "ERROR" app.log
grep -E "WARN|ERROR" app.log

# 集計
awk '{print $1}' app.log | sort | uniq -c

# プロセス/ポート確認
ps aux | head
ss -tulpn

# 危険権限ファイル探索（例）
find /tmp -type f -perm -0002 2>/dev/null | head
```

---

### 5) よくあるミスと回避策
- **ミス1:** `grep` のみで満足して時系列を見ない  
  **回避:** 必ず「いつから増えたか」を確認（`sort`, `journalctl --since`）。
- **ミス2:** 本番でいきなり重いコマンドを実行  
  **回避:** `head`, `tail`, 期間指定で対象を絞る。
- **ミス3:** 権限エラーを無視して調査終了  
  **回避:** sudoが必要な範囲を明確化し、監査ログを残す。
- **ミス4:** 1コマンド1解釈で断定する  
  **回避:** ログ・プロセス・ネットワークの3視点でクロスチェック。

---

### 6) Interview-style Question
「`/api/pay` で 500 が急増したとき、**最初の10分**であなたはどの順番で調査しますか？  
コマンド例を交えて、誤検知を避けるための確認観点も説明してください。」

---

### 7) Next-step Reading
- OWASP Logging Cheat Sheet  
  https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html
- Linux Journey (CLI fundamentals)  
  https://linuxjourney.com/
- Google SRE Workbook（運用実践）  
  https://sre.google/workbook/table-of-contents/
- MITRE ATT&CK（検知観点の整理）  
  https://attack.mitre.org/

---

## ローテーション計画（必須トラックを循環）
次号以降は以下トラックを **Beginner → Middle → Advanced** の反復で進行:
1. Application Security（secure coding / OWASP / threat modeling / auth-session / incident response）
2. DevOps Core（Docker hardening / Kubernetes security / Terraform IaC / Linux / CI-CD security / secrets management）
3. Cloud Security（AWS/GCP IAM & permission design）
4. Observability（Prometheus/Grafana/OpenTelemetry）
5. Kubernetes Incident Drills（failure / rollback / recovery）

**Middleの前提知識（Prerequisites）**
- Linux基本操作、Git基本、Docker run/buildの初歩
- HTTP基礎（status code, headers）、YAML読解

**Advancedの前提知識（Prerequisites）**
- Kubernetes基本リソース（Pod/Deployment/Service）
- Terraformで簡単なリソース作成経験
- CI/CDパイプラインを1つ以上触った経験
- 監視メトリクス（latency/error rate）の基本理解
