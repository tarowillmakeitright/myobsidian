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

# SecDevOps Magazine — 2026-04-25 09:00

おはようございます。今日のテーマは**Application Security × DevOpsの土台づくり**です。  
このマガジンは、**Beginner → Middle → Advanced**の学習アークを繰り返し、実務で使える力を積み上げます。  
（※ 倫理的・防御的・合法的な学習のみを扱います）

## 学習アーク（ローテーション）
- **Arc 1 / Day 1（今日）: Beginner** — OWASP Top 10の入口 + Linuxログ確認
- **Arc 1 / Day 2: Middle** — Docker hardening + CI/CD security（**前提**: Linux基礎、Docker基本操作）
- **Arc 1 / Day 3: Advanced** — Kubernetes incident drill（失敗注入→rollback→recovery）（**前提**: kubectl/Deployment/Service、基本監視）
- **Arc 1 / Day 4: Beginner** — Cloud Security（AWS/GCP IAMの最小権限）
- **Arc 1 / Day 5: Middle** — Observability（Prometheus/Grafana/OpenTelemetry導入）
- **Arc 1 / Day 6: Advanced** — Terraform/IaC policy as code + secrets management実践

---

## 1) Topic + Level
**Topic:** OWASPリスクをログで追う：Broken Access Controlの兆候を見つける  
**Level:** **Beginner**

## 2) Why it matters in real projects
本番障害や情報漏えいの多くは、派手なゼロデイよりも**権限チェック漏れ**のような基本ミスで起こります。  
開発者・SRE・DevOpsが同じ指標（アクセスログ、認可失敗率、異常なHTTPコード）を見られると、検知と復旧が速くなります。

## 3) Core concepts
- **OWASP Top 10**: Webアプリの主要リスク集。まずはA01: Broken Access Controlを優先。
- **認証 (Authentication) と 認可 (Authorization)**: 「誰か確認する」のが認証、「何を許可するか」が認可。
- **Session security**: セッション固定化、Cookie属性（HttpOnly/Secure/SameSite）を押さえる。
- **Threat modeling（軽量版）**: 
  1. 重要資産（ユーザーデータ、管理API）
  2. 境界（公開API、管理画面、内部ネットワーク）
  3. 想定攻撃（権限昇格、IDOR）
  4. 防御策（RBAC、監査ログ、rate limit）
- **Incident responseの入口**: 検知→一次切り分け→影響範囲確認→封じ込め→再発防止。

## 4) Hands-on mini lab (30-60 min)
**目標:** 疑似ログから「認可不備の兆候」を見つける

1. 作業ディレクトリ作成
```bash
mkdir -p ~/secdevops-lab/day1 && cd ~/secdevops-lab/day1
```

2. サンプルアクセスログ作成
```bash
cat > access.log <<'EOF'
2026-04-25T08:45:01Z user=alice role=user method=GET path=/api/profile/123 status=200
2026-04-25T08:45:10Z user=bob role=user method=GET path=/api/admin/users status=403
2026-04-25T08:45:22Z user=bob role=user method=GET path=/api/profile/999 status=200
2026-04-25T08:45:40Z user=carol role=admin method=POST path=/api/admin/users/disable status=200
2026-04-25T08:46:02Z user=bob role=user method=GET path=/api/admin/users status=200
EOF
```

3. 怪しい行を抽出（admin pathにuser roleで200）
```bash
awk '/path=\/api\/admin/ && /role=user/ && /status=200/' access.log
```

4. 影響範囲確認（403→200に変化したユーザー）
```bash
grep 'user=bob' access.log
```

5. ミニふりかえり
- どのAPIにRBACテストを追加する？
- 監視アラート条件（例: `role=user AND /api/admin AND status=200`）をどう定義する？

## 5) Command cheatsheet
### Linux
```bash
# ログ検索
grep 'status=403' access.log
# 条件抽出
awk '/role=user/ && /api\/admin/' access.log
# 件数集計
grep '/api/admin' access.log | wc -l
```

### Docker（次回予告向け）
```bash
docker run --read-only --cap-drop ALL --security-opt no-new-privileges nginx:alpine
```

### Kubernetes（次回以降向け）
```bash
kubectl get pods -A
kubectl rollout undo deployment/myapp
```

### Terraform（次回以降向け）
```bash
terraform fmt
terraform validate
terraform plan
```

## 6) Common mistakes and how to avoid them
- **ミス1:** 認証があるから安全だと思い込む  
  **回避:** エンドポイントごとに認可テスト（正常系/異常系）をCIに入れる。
- **ミス2:** ログにuser_idやroleを残していない  
  **回避:** 監査観点の最小ログ項目を標準化する（user, role, path, status, request_id）。
- **ミス3:** 403の増加だけ監視して200の異常を見ない  
  **回避:** 「本来403であるべき200」を検出するルールを用意する。

## 7) One interview-style question
**Q.** 「Broken Access Control」を本番で早期検知するために、アプリ側と運用側で1つずつ対策を挙げてください。  
（例: アプリ=RBAC単体/統合テスト、運用=認可不整合ログのアラート）

## 8) Next-step reading links
- OWASP Top 10: https://owasp.org/www-project-top-ten/
- OWASP ASVS: https://owasp.org/www-project-application-security-verification-standard/
- NIST Incident Response (SP 800-61): https://csrc.nist.gov/publications/detail/sp/800-61/rev-2/final
- Kubernetes Security Checklist (CNCF): https://github.com/kubernetes/community/blob/master/wg-security-audit/README.md
- OpenTelemetry Docs: https://opentelemetry.io/docs/
- Terraform Best Practices (HashiCorp): https://developer.hashicorp.com/terraform

---

### 明日の予告（Middle）
**Docker hardening + CI/CD security**を扱います。  
**Prerequisites:** Linuxファイル権限（chmod/chown）、Dockerfileの基礎、GitHub Actions/GitLab CIの基本。
