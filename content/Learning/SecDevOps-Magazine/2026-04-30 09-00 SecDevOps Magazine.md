---
tags: [security, devops, docker, kubernetes, terraform, linux, cloudsecurity, observability, daily]
---

[[Home]]

# SecDevOps Magazine — 2026-04-30

今日から「Application Security + DevOps」学習アークを回していきます。  
難易度は **Beginner → Middle → Advanced** の順で進行し、1周したら次のテーマ群で再び Beginner から積み上げます。

---

## 1) Topic + Level
**Topic:** Secure SDLC入門 + OWASP Top 10の見取り図 + 最小権限IAMの第一歩  
**Level:** **Beginner**

> 学習アーク:
> - Day 1-3: Beginner（基礎の地図づくり）
> - Day 4-6: Middle（実装・運用で使う）
> - Day 7-9: Advanced（障害/攻撃シナリオで判断）

---

## 2) Why it matters in real projects
本番事故の多くは「難しい0day」より、**基本設計の抜け**で起きます。  
例えば以下です。
- 認証はあるが認可が弱い（IDOR）
- CI/CDでSecretsが漏れる
- IAM権限が広すぎて横展開される
- 監視が弱く、侵害に気づくのが遅い

基礎を先に固めることで、後から学ぶKubernetesセキュリティやIncident Responseの理解速度が上がります。

---

## 3) Core concepts (clear explanations)
### A. Secure SDLC（安全な開発ライフサイクル）
- **Plan**: 脅威を想定（Threat Modeling）
- **Build**: Secure Coding + 依存関係管理
- **Test**: SAST/DAST/Container Scan
- **Deploy/Run**: 最小権限、監査ログ、監視

### B. OWASP Top 10（まず押さえるべき代表リスク）
- Broken Access Control
- Cryptographic Failures
- Injection
- Security Misconfiguration
- Vulnerable/Outdated Components

### C. IAMの最小権限（AWS/GCP共通）
- 人・CI・アプリごとにID分離
- `*`権限を避ける
- 「必要なActionを必要なResourceへ」だけ許可
- 監査ログ（CloudTrail / Cloud Audit Logs）を必ず有効化

### D. Observabilityの基本
- **Metrics**: 数値の傾向（Prometheus）
- **Logs**: 詳細な事象
- **Traces**: リクエスト経路（OpenTelemetry）
- 可視化（Grafana）で「異常の早期検知」を狙う

---

## 4) Hands-on mini lab (30-60 min)
**Lab: 「小さなWeb APIを安全に運ぶ最短ルート」**

### ゴール
1. Dockerコンテナを非rootで起動  
2. 簡単なIAMポリシーの差を読む  
3. Prometheus形式のメトリクスを叩いて確認

### 手順
1. 任意のサンプルAPIを用意（Hello APIでOK）
2. Dockerfileを非root化
3. `.env`直埋めをやめ、環境変数から読み込む
4. 疑似IAMポリシー（read-only / admin）を比較
5. `/metrics`エンドポイント確認

期待成果:
- 「動く」だけでなく「安全に動かす」視点を1つ増やす

---

## 5) Command cheatsheet
### Linux
```bash
id
whoami
ss -tulpen
ps aux --sort=-%cpu | head
journalctl -xe --no-pager | head -n 50
```

### Docker
```bash
docker build -t secdevops-demo:1 .
docker run --rm -p 8080:8080 --user 10001:10001 secdevops-demo:1
docker inspect secdevops-demo:1 | jq '.[0].Config.User'
docker scout quickview secdevops-demo:1
```

### Kubernetes（基礎確認）
```bash
kubectl get ns
kubectl get pods -A
kubectl auth can-i get secrets --as=system:serviceaccount:default:default
kubectl describe pod <pod-name>
```

### Terraform（読む練習）
```bash
terraform fmt -check
terraform validate
terraform plan -out=tfplan
terraform show -json tfplan | jq '.resource_changes | length'
```

---

## 6) Common mistakes and how to avoid them
1. **「認証した=安全」だと思う**  
   - 回避: 認証(Authentication)と認可(Authorization)を分けて設計

2. **Dockerをrootで実行し続ける**  
   - 回避: `USER`指定、capability最小化、read-only FS検討

3. **IAMに`*`を使う**  
   - 回避: アクションを具体化、期限付き権限、レビュー運用

4. **監視をCPU/メモリだけにする**  
   - 回避: エラーレート・レイテンシ・依存先失敗率を追加

5. **K8s障害訓練をやらない**  
   - 回避: 月1で「障害注入→rollback→復旧時間記録」

---

## 7) One interview-style question
あなたが新規プロダクトの最初のSRE/Sec担当だとします。  
「開発速度を落とさずに、最初の2週間で入れる最低限のセキュリティ/運用ガードレール」を3つ挙げ、理由を説明してください。

---

## 8) Next-step reading links
- OWASP Top 10: https://owasp.org/www-project-top-ten/
- OWASP ASVS: https://owasp.org/www-project-application-security-verification-standard/
- Dockerfile best practices: https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Kubernetes Security Checklist: https://kubernetes.io/docs/concepts/security/
- Terraform Security (HashiCorp docs): https://developer.hashicorp.com/terraform
- AWS IAM Best Practices: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- GCP IAM overview: https://cloud.google.com/iam/docs/overview
- OpenTelemetry docs: https://opentelemetry.io/docs/
- Prometheus docs: https://prometheus.io/docs/
- Grafana docs: https://grafana.com/docs/

---

### 次号予告（Middle）
**Prerequisites（Middle向け）**
- Docker基本操作（build/run/logs）
- Linux権限（user/group, chmod/chown）
- HTTPの基礎（header/status code）

次号では、**CI/CD security + Secrets management + Threat Modeling実践（STRIDEミニ演習）**に進みます。