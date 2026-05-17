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

# 2026-05-17 SecDevOps Magazine

[[Home]]

## 1) Topic + Level
**テーマ:** OWASP Top 10 入門と Secure Coding の第一歩（Input Validation / Injection 対策）  
**レベル:** **Beginner**

---

## 2) Why it matters in real projects
本番システムの事故は、派手なゼロデイよりも「基本的な入力チェック不足」や「権限確認漏れ」から起きることが多いです。  
OWASP Top 10 を最初に押さえると、実装・レビュー・運用の共通言語ができ、チーム全体の防御力が上がります。

---

## 3) Core concepts（clear explanations）
- **OWASP Top 10**: Webアプリで頻出する重大リスクの整理（A01: Broken Access Control, A03: Injection など）
- **Secure Coding**: 「動くコード」だけでなく「悪用されにくいコード」を書く習慣
- **Input Validation**: 想定外入力を拒否／正規化する（長さ・型・フォーマット）
- **Parameterized Query**: SQLを文字列連結せず、プレースホルダで渡して Injection を防ぐ
- **Least Privilege**: DBユーザーやアプリ権限は最小限にする

---

## 4) Hands-on mini lab（30-60 min）
### 目標
危険な SQL 文字列連結と、パラメータ化クエリの差を体験する。

### 手順（ローカル）
1. Python + SQLite の簡易スクリプトを作る（危険版と安全版を用意）
2. `' OR 1=1 --` のような入力で挙動比較
3. ログを見て、なぜ unsafe が破られるかを確認
4. 追加課題: 入力長制限と allowlist（例: ユーザーIDは英数字のみ）を実装

### 期待アウトカム
- SQL Injection の成立条件を説明できる
- Parameterized Query を「なぜ有効か」まで説明できる

---

## 5) Command cheatsheet
### Linux
```bash
# ファイル作成
mkdir -p ~/secdevops-labs/day1 && cd ~/secdevops-labs/day1

# Python実行
python3 app.py
```

### Docker（任意）
```bash
# Pythonコンテナで実験
docker run --rm -it -v "$PWD":/work -w /work python:3.12 bash
python app.py
```

### Kubernetes / Terraform
今回は未使用（Beginner導入回）

---

## 6) Common mistakes and how to avoid them
- **ミス:** 「内部ツールだから安全」と思い込む  
  **回避:** 内部でも入力は常に不正値を想定
- **ミス:** エラーメッセージにSQLやスタックトレースをそのまま表示  
  **回避:** ユーザー向けは汎用メッセージ、詳細は監査ログへ
- **ミス:** 1箇所直して満足する  
  **回避:** 同種処理を grep で横断チェックし、再発防止ルール化

---

## 7) One interview-style question
「Prepared Statement を使っていても Injection リスクが残るケースはありますか？ あるなら具体例を挙げ、対策を説明してください。」

---

## 8) Next-step reading links
- OWASP Top 10: https://owasp.org/www-project-top-ten/
- OWASP Cheat Sheet Series: https://cheatsheetseries.owasp.org/
- SQL Injection Prevention Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/SQL_Injection_Prevention_Cheat_Sheet.html
- NIST SSDF (Secure Software Development Framework): https://csrc.nist.gov/Projects/ssdf

---

## 学習アーク（Beginner → Middle → Advanced）
このマガジンは、3日サイクルで難易度を回します。

- **Day A (Beginner):** 概念 + 最小実装
- **Day B (Middle):** 実サービス想定の構成・運用（※前提あり）
- **Day C (Advanced):** 障害注入/インシデント対応/設計トレードオフ（※前提あり）

### 次号予告（Middle）
**テーマ候補:** Docker Hardening + CI/CD Security（中級）  
**Prerequisites:**
- Dockerfile の基本命令（FROM/RUN/COPY/USER）
- Linux 権限（chmod/chown）
- GitHub Actions など CI の基本概念

### 今週内に登場する必須トラック（ローテーション対象）
- Application Security（secure coding, OWASP, threat modeling, auth/session, incident response）
- DevOps core（Docker, Kubernetes, Terraform/IaC, Linux, CI/CD, secrets）
- **Cloud Security（AWS/GCP IAM & permission design）**
- **Observability（Prometheus/Grafana/OpenTelemetry）**
- **Kubernetes incident drills（failure/rollback/recovery）**

> 方針: 倫理的・防御的・合法な学習のみ。攻撃手法は検証環境での再現と防御理解に限定します。
