---
tags: [security, devops, docker, kubernetes, terraform, linux, cloudsecurity, observability, daily]
---

[[Home]]

# SecDevOps Magazine — 2026-04-19

#security #devops #docker #kubernetes #terraform #linux #cloudsecurity #observability #daily

## 号情報
- **Issue:** #4
- **Topic + Level:** **Secure Coding + OWASP Top 10入門 — Beginner**
- **学習アーク:** Beginner → Middle → Advanced（3日サイクル反復）
- **Prerequisites:** なし（今日から開始OK）

---

## 1) Topic + Level
**Secure Coding + OWASP Top 10入門 — Beginner**

「動くコード」だけでは本番は守れません。今日は、**よくある脆弱性を“作らない習慣”**を最短で身につけます。

---

## 2) Why it matters in real projects
実案件では、インシデントの多くが“高度なゼロデイ”ではなく、基本的な実装ミスから起きます。
- 入力値検証不足 → SQL Injection / XSS
- 認可漏れ → 他人データの閲覧
- エラーハンドリング不備 → 機密情報の露出

開発初期からSecure Codingを入れると、
- 後工程の修正コストを削減
- リリース速度を維持
- 監査・法令対応（個人情報保護等）をスムーズ化
できます。

---

## 3) Core concepts（要点）
1. **OWASP Top 10は“暗記リスト”ではなく設計チェックリスト**
   - A01 Broken Access Control
   - A03 Injection
   - A05 Security Misconfiguration
   - A07 Identification and Authentication Failures など

2. **入力は全て不正前提（Never trust input）**
   - バリデーション（形式）
   - サニタイズ（表示時）
   - パラメータ化クエリ（DB時）

3. **認可はサーバ側で毎回判定**
   - UIでボタン非表示にしても防御ではない
   - 「誰が・何に・どの操作を」できるかをAPIで検証

4. **機密情報はコードに書かない**
   - APIキー/DBパスワードは環境変数やSecret管理へ

5. **ログは“調査可能”かつ“漏えいしない”形で**
   - 追跡IDを出す
   - パスワード/トークン/個人情報はマスク

---

## 4) Hands-on mini lab（30–60分）
**目的:** 脆弱なAPIを最小修正で安全化する。

### 準備
- ローカルに簡易API（Node/Pythonどちらでも可）
- SQLite か任意DB

### シナリオ
1. `/user?id=...` が文字列連結SQLで実装されている
2. `/profile/:id` が本人確認なしで閲覧可能
3. エラー時にスタックトレースをそのまま返している

### 実施タスク
1. SQLを**パラメータ化**へ置換
2. `/profile/:id` に**認可チェック**を追加
3. エラー応答を一般化（詳細はサーバログへ）
4. 疑似攻撃入力で再テスト（`' OR '1'='1` 等）

### 完了条件
- Injection入力でDB全件取得できない
- 他ユーザーIDにアクセスしても403になる
- APIレスポンスに内部実装情報が出ない

---

## 5) Command cheatsheet
### Linux
```bash
# 露出ポート確認
ss -lntp

# アプリログ確認（systemd運用時）
journalctl -u myapp --since "30 min ago"

# 疑似攻撃リクエスト（URLエンコードに注意）
curl -i "http://localhost:3000/user?id=1%27%20OR%20%271%27=%271"
```

### Docker
```bash
# イメージ脆弱性スキャン（Docker Scoutがある場合）
docker scout quickview myapp:dev

# 環境変数で秘密情報を注入（直書きしない）
docker run --rm -p 3000:3000 \
  -e DB_URL="postgres://app@db/app" \
  -e APP_ENV="dev" myapp:dev
```

### Kubernetes
```bash
# Secret確認（値は直接出力しない）
kubectl get secret -n dev
kubectl describe secret app-secrets -n dev

# Podログから例外発生箇所確認
kubectl logs -n dev deploy/myapp --tail=200
```

### Terraform
```bash
# IaCの基本衛生チェック
terraform fmt -recursive
terraform validate
terraform plan
```

---

## 6) Common mistakes and how to avoid them
1. **「ORM使ってるからInjectionは無関係」**
   - 回避: 生SQL・動的クエリが混ざっていないかレビューする
2. **認証と認可を混同する**
   - 回避: ログイン済みでも操作権限を毎リクエストで判定
3. **例外をそのまま返す**
   - 回避: 利用者向けメッセージは抽象化、詳細は内部ログへ
4. **秘密情報を`.env`やGitにコミット**
   - 回避: Secret管理 + pre-commitで検出
5. **“後で直す”で放置**
   - 回避: PRテンプレにSecurityチェック項目を固定化

---

## 7) One interview-style question
あなたのチームで「ログイン済みユーザーが他人の注文データを見られる」不具合が報告されました。これはOWASP Top 10のどれに該当し、最小の修正をどう設計しますか？

---

## 8) Next-step reading links
- OWASP Top 10: https://owasp.org/www-project-top-ten/
- OWASP Cheat Sheet Series: https://cheatsheetseries.owasp.org/
- OWASP ASVS: https://owasp.org/www-project-application-security-verification-standard/
- PortSwigger Web Security Academy: https://portswigger.net/web-security
- NIST Secure Software Development Framework (SSDF): https://csrc.nist.gov/Projects/ssdf
- CIS Software Supply Chain Security: https://www.cisecurity.org/

---

## ローテーション計画（更新）
- Day 1 (Beginner): Cloud Security (IAM) ✅
- Day 2 (Middle): Observability ✅
- Day 3 (Advanced): Kubernetes incident drills ✅
- Day 4 (Beginner): Secure Coding + OWASPリスク ✅（本日）
- Day 5 (Middle): CI/CD Security + Secrets Management
- Day 6 (Advanced): Threat Modeling + Incident Response演習
- Day 7 (Beginner): Docker Hardening + Linux command mastery
- Day 8 (Middle): Terraform/IaC Best Practices
- Day 9 (Advanced): Auth/Session Security deep dive

次号は**Middle**。Prerequisitesとして「OWASP Top 10の主要カテゴリを説明できること」「基本的なCIパイプライン理解」を前提に、CI/CD Security + Secrets Managementへ進む。