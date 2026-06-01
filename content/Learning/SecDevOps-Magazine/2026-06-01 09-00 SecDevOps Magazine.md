---
tags: [security, devops, docker, kubernetes, terraform, linux, cloudsecurity, observability, daily]
---

# 2026-06-01 SecDevOps Magazine

[[Home]]

おはようございます。今日のテーマは **Application Security + DevOps の実践基礎をつなぐ Day 1**。
このマガジンは難易度を **Beginner → Middle → Advanced** で循環させる学習アーク設計です。今日はアークの入口として Beginner 中心で進めます。

---

## 1) Topic + Level
**Topic:** Threat Modeling 入門（Webアプリ + クラウド実行環境）
**Level:** **Beginner**

---

## 2) Why it matters in real projects
実案件では「実装後に脆弱性が見つかる」より、設計段階で危険を潰した方が圧倒的に安く安全です。
Threat Modeling を使うと、OWASP リスク、認証/セッション設計、CI/CD、IaC、Kubernetes 運用、Cloud IAM の弱点を **変更前に可視化** できます。

---

## 3) Core concepts（clear explanations）
- **Asset（守る対象）**: ユーザ情報、JWT/Session、シークレット、Container Image、Terraform state
- **Entry Point（入口）**: API、Ingress、CI runner、管理コンソール、Git push
- **Trust Boundary（信頼境界）**: Internet↔App、Namespace間、CI↔Cloud、Pod↔Metadata API
- **Threat（脅威）**: STRIDE（Spoofing/Tampering/Repudiation/Information Disclosure/DoS/Elevation of Privilege）
- **Mitigation（対策）**: 最小権限 IAM、入力検証、WAF、MFA、NetworkPolicy、Secret rotation、監査ログ

補足（今日の追加必須トラック対応）:
- **Cloud Security:** IAM ロール分離（human/admin/workload/ci）
- **Observability:** OpenTelemetry で trace_id を通し、Prometheus/Grafana で異常を早期検知
- **Kubernetes incident drills:** 失敗注入→rollback→復旧手順を事前に練習

---

## 4) Hands-on mini lab（30–60 min）
**ラボ名:** 「小さな EC API」の脅威モデリング + 防御チェック

1. システム図を紙/Markdownで作る（5–10分）
   - Client → Ingress → API Pod → DB
   - CI/CD → Container Registry → Kubernetes
   - Terraform → Cloud IAM
2. 各経路に STRIDE を1つずつ割り当てる（10分）
3. 上位3リスクを選定し、対策を1行で定義（10分）
   - 例: `CI用IAMキー廃止 → OIDC federationへ移行`
4. 観測ポイントを決める（10分）
   - API latency/error rate、auth failure、pod restart、privileged container 検知
5. インシデントドリル案を1つ書く（10分）
   - 「誤った deploy で 5xx 急増」→ canary rollback → SLO回復確認

成果物:
- `threat-model.md`
- `top-risks.md`
- `incident-drill.md`

---

## 5) Command cheatsheet
### Linux
```bash
# 不審な LISTEN ポート確認
ss -tulpn

# 認証失敗ログ確認（環境によりjournalctl/secure.log）
journalctl -u sshd --since "1 hour ago"
```

### Docker
```bash
# イメージ脆弱性スキャン（Docker Scoutがある場合）
docker scout quickview <image>

# コンテナ実行時に読み取り専用FS
docker run --read-only --cap-drop ALL --security-opt no-new-privileges <image>
```

### Kubernetes
```bash
# Podのセキュリティ関連設定確認
kubectl get pod <pod> -o yaml | grep -E "securityContext|runAsNonRoot|privileged" -n

# 直近イベントで異常確認
kubectl get events -A --sort-by=.lastTimestamp | tail -n 30

# rollout 履歴と rollback
kubectl rollout history deploy/<name>
kubectl rollout undo deploy/<name>
```

### Terraform
```bash
# 差分確認
terraform plan

# stateに秘密情報が混入してないか確認（慎重に）
terraform state list
```

---

## 6) Common mistakes and how to avoid them
1. **「脅威モデリングは後でやる」**
   - 回避: sprint planning時に15分固定で実施
2. **IAM が広すぎる（*:*）**
   - 回避: action/resource/condition を明示、ロールを用途別分離
3. **Observability がメトリクスだけ**
   - 回避: metrics + logs + traces を最初からセット
4. **K8sドリル未実施で本番初対応**
   - 回避: 月次で failure/rollback/recovery を演習
5. **Secrets を env 固定で長期運用**
   - 回避: Secret Manager + rotation + short-lived credential

---

## 7) One interview-style question
「あなたのチームで新しい決済APIを本番投入する前に、Threat Modeling を 30 分で行うなら、どの asset と trust boundary を最優先で確認し、なぜですか？」

---

## 8) Next-step reading links
- OWASP Top 10: https://owasp.org/www-project-top-ten/
- OWASP ASVS: https://owasp.org/www-project-application-security-verification-standard/
- Kubernetes Security Checklist: https://kubernetes.io/docs/concepts/security/
- Terraform Security Best Practices (HashiCorp): https://developer.hashicorp.com/terraform/tutorials/security
- AWS IAM Best Practices: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- GCP IAM Best Practices: https://cloud.google.com/iam/docs/using-iam-securely
- OpenTelemetry Docs: https://opentelemetry.io/docs/
- Prometheus Docs: https://prometheus.io/docs/
- Grafana Docs: https://grafana.com/docs/

---

## 学習アーク（進行管理）
- **Day 1 (今日): Beginner** — Threat Modeling基礎と全体地図
- **Day 2: Middle** — 前提: Day 1 の成果物（threat-model.md）作成済み
- **Day 3: Advanced** — 前提: Middleで作った防御設定と観測ダッシュボード

次号では Middle として、
**「Docker hardening + CI/CD security + Secret管理の実装」** を実際の設定例つきで扱います。
