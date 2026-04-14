# Daily Kubernetes Commands Magazine

#kubernetes #k8s #devops #learning #daily

[[Home]]

日付: 2026-04-14 09:25 (Asia/Tokyo)

---

## 今回の学習アーク: `kubectl` で「状態把握 → 調査 → 安全な変更」を身につける

> 進行順: **Beginner → Middle → Advanced**

---

## 1) Topic + Level

### Beginner
**Topic:** クラスタ/Namespace/Pod の「見る」コマンド基礎（`get`, `describe`, `logs`）

### Middle
**Topic:** Deployment のローリング更新と履歴確認（`rollout`）
**Prerequisites:**
- `kubectl get/describe/logs` が使える
- Pod / Deployment / Service の役割を説明できる
- `-n <namespace>` 指定を習慣化している

### Advanced
**Topic:** 本番を意識した安全な適用フロー（`diff`, `apply`, `--server-side`, context確認）
**Prerequisites:**
- Deployment 更新と `rollout undo` の経験
- kubeconfig の context 切替を理解
- Manifest の基本（metadata/spec）を読める

---

## 2) Why it matters for real app development

実アプリ開発では、Kubernetes は「デプロイ先」だけでなく、**障害調査・変更管理・再現性ある運用**の土台です。  
`kubectl` を正しく使えると:
- リリース失敗時に原因を素早く切り分けできる
- 影響範囲を把握したうえで安全に反映できる
- チームで同じ手順を共有し、事故を減らせる

---

## 3) Core kubectl/Kubernetes concept explanations

- **Context**: どのクラスタに向けて操作するか。誤ると別環境を壊す。
- **Namespace**: リソースの論理分離。`default` 依存は事故の元。
- **Desired State**: Manifest に宣言した状態。Controller が実状態を一致させる。
- **Deployment**: Pod の更新/再作成を管理。ローリング更新の中心。
- **Server-side apply**: APIサーバ側でフィールド管理。チーム運用で競合管理がしやすい。

---

## 4) App開発でのKubernetes利用（kubernetes.io/docsのベストプラクティス準拠）

- **明示的な Namespace 指定**（`-n`）で誤操作防止
- **`kubectl diff` → `apply`** の順で差分確認してから反映
- **`rollout status` を監視**して更新完了を確認
- Secret は **manifest直書きしない**（Gitに残るため）
- 変更後は `get/describe/logs/events` でヘルスを確認
- 本番前に `current-context` を毎回確認

参考（公式）:
- Overview: https://kubernetes.io/docs/concepts/overview/
- Namespaces: https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/
- Deployment: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- kubectl cheatsheet: https://kubernetes.io/docs/reference/kubectl/cheatsheet/
- Secrets good practices: https://kubernetes.io/docs/concepts/security/secrets-good-practices/

---

## 5) 30–60分ハンズオン・ミニラボ（目安45分）

### 目標
安全確認を入れながら、Deployment の更新とロールバックまで実施する。

### 手順
1. **対象確認（5分）**
```bash
kubectl config current-context
kubectl get ns
kubectl get deploy -n default
```

2. **状態把握（10分）**
```bash
kubectl get pods -n default -o wide
kubectl describe deploy <your-deployment> -n default
kubectl logs deploy/<your-deployment> -n default --tail=100
```

3. **更新前差分確認（10分）**
- 例: image tag を新しいものに変更した manifest を用意
```bash
kubectl diff -f deployment.yaml -n default
```

4. **安全に反映（10分）**
```bash
kubectl apply -f deployment.yaml -n default
kubectl rollout status deploy/<your-deployment> -n default --timeout=120s
kubectl rollout history deploy/<your-deployment> -n default
```

5. **問題を想定した復旧（10分）**
```bash
kubectl rollout undo deploy/<your-deployment> -n default
kubectl rollout status deploy/<your-deployment> -n default --timeout=120s
```

### 完了条件
- `rollout status` が成功
- 更新履歴が確認できる
- `undo` で前バージョンに戻せる

---

## 6) Command Cheatsheet

```bash
# 安全確認
kubectl config current-context
kubectl config get-contexts

# 基本観察
kubectl get all -n <ns>
kubectl describe pod <pod> -n <ns>
kubectl logs <pod> -n <ns> --tail=200
kubectl get events -n <ns> --sort-by=.metadata.creationTimestamp

# 変更管理
kubectl diff -f <file> -n <ns>
kubectl apply -f <file> -n <ns>
kubectl rollout status deploy/<name> -n <ns>
kubectl rollout history deploy/<name> -n <ns>
kubectl rollout undo deploy/<name> -n <ns>
```

---

## 7) Common mistakes and safe practices

### よくあるミス
- `current-context` 未確認で本番クラスタへ実行
- Namespace未指定で `default` に誤適用
- `kubectl apply -f .` で意図しないファイルまで反映
- Secret を平文で manifest/Git に保存
- `kubectl delete` を対象確認なしで実行

### 安全運用
- 反映前に **context + namespace + diff** を必ず確認
- 破壊的コマンド前は対象を明示して再確認
  - 例: `kubectl delete pod <name> -n <ns>`（ワイルドカードを避ける）
- `apply` のスコープを絞る（`-f` 対象を限定）
- Secret は External Secrets / 暗号化手段を検討
- 本番変更は `rollout status` までを1セットにする

⚠️ **警告:** `delete`, 広範囲 `apply`, context不一致は重大事故の定番です。実行前に必ず読み上げ確認レベルでチェックしてください。

---

## 8) Interview-style question

「本番環境で Deployment 更新後にエラー率が上がりました。`kubectl` を使って、**影響確認 → 原因調査 → 安全なロールバック** までの手順を、実行コマンド付きで説明してください。」

---

## 9) Next-step resources（公式優先）

- kubectl Overview: https://kubernetes.io/docs/reference/kubectl/
- kubectl Cheat Sheet: https://kubernetes.io/docs/reference/kubectl/cheatsheet/
- Debug running pods: https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/
- Deployment updates: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Configure Access to Multiple Clusters: https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/
- Secrets good practices: https://kubernetes.io/docs/concepts/security/secrets-good-practices/

---

次号予告（予定）: Beginner〜Advancedで「`kubectl exec`/ephemeral containers を使った実践デバッグ」
