---
tags:
  - kubernetes
  - k8s
  - devops
  - learning
  - daily
---

# 2026-04-07 09:25 Kubernetes Commands Magazine
[[Home]]

今日のテーマは、**Beginner → Middle → Advanced** の学習アークで進む実践特集です。  
実務で「安全に壊さず運用する」ことを最優先に、`kubectl` と Kubernetes の基本〜応用を一気に固めます。

---

## 1) Topic + Level

### Beginner
**Topic:** `kubectl get / describe / logs` で「動いているアプリ」を観察する

### Middle
**Topic:** Deployment のローリングアップデートとロールバック
**Prerequisites:**
- Pod / Deployment の基本概念
- `kubectl get`, `kubectl logs` が使える
- Namespace の基礎理解

### Advanced
**Topic:** ConfigMap / Secret / probes / resources を使った本番向け設定
**Prerequisites:**
- Deployment の更新手順（set image / rollout）が使える
- YAML マニフェストを読める
- コンテナ設定（環境変数、ポート、ヘルスチェック）の基礎知識

---

## 2) なぜ実アプリ開発で重要か

- 開発では「書く」よりも「原因調査する」時間が長い。観察コマンドが弱いと障害対応が遅れる。
- デプロイは必ず失敗しうる。ロールバックを前提にした手順で、サービス停止時間を最小化できる。
- 本番運用では設定値・機密情報・ヘルスチェック・リソース制限が品質を決める。
- Kubernetes を使う目的は「動く」だけでなく、**安全に継続運用できる状態を再現可能にする**こと。

---

## 3) Core kubectl / Kubernetes 概念

### 観察系（Beginner）
- `kubectl get`: リソース一覧を俯瞰
- `kubectl describe`: イベントや状態詳細を見る
- `kubectl logs`: コンテナ標準出力を確認
- `kubectl get events --sort-by=.lastTimestamp`: 直近の異常を時系列で追う

### 更新系（Middle）
- Deployment は ReplicaSet を介して段階更新する
- `kubectl set image` でイメージ更新
- `kubectl rollout status` で進行確認
- `kubectl rollout undo` で安全に戻す

### 本番設定系（Advanced）
- ConfigMap: 非機密の設定値
- Secret: 機密情報（ただし平文管理は厳禁、暗号化/外部Secrets管理を併用）
- livenessProbe / readinessProbe: 自己回復とトラフィック制御
- resources.requests/limits: スケジューリングと暴走防止

---

## 4) アプリ構築時の Kubernetes 活用（kubernetes.io/docs の実践に沿って）

- **宣言的管理（declarative）優先**: `kubectl apply -f` と Git 管理で変更履歴を残す。
- **最小権限・責務分離**: Namespace / ServiceAccount / RBAC で権限を限定する。
- **可観測性を最初から組み込む**: logs, events, probes を必須化。
- **段階的デリバリ**: rollout status を確認し、失敗時は即 rollback。
- **設定とコードを分離**: 設定は ConfigMap、機密は Secret/外部シークレット管理。
- **安全な実行習慣**: 実行前に `kubectl config current-context` と `-n <namespace>` を明示。

---

## 5) 30〜60分ミニラボ（実践）

> 目標: 「観察 → 更新 → 復旧」を一通り体験し、本番で使う最低限の安全動作を身につける。

### 0. 事前安全確認（5分）
```bash
kubectl config get-contexts
kubectl config current-context
kubectl get ns
```
- 作業対象コンテキストが本番でないことを確認。
- **破壊的操作前に必ず確認**（context / namespace / 対象名）。

### 1. Namespace と Deployment 作成（10分）
```bash
kubectl create ns k8s-mag-lab
kubectl -n k8s-mag-lab create deployment web --image=nginx:1.25
kubectl -n k8s-mag-lab expose deployment web --port=80 --type=ClusterIP
kubectl -n k8s-mag-lab get all
```

### 2. 観察（10分）
```bash
kubectl -n k8s-mag-lab get pods -o wide
kubectl -n k8s-mag-lab describe pod -l app=web
kubectl -n k8s-mag-lab logs deploy/web --tail=50
kubectl -n k8s-mag-lab get events --sort-by=.lastTimestamp | tail -n 20
```

### 3. ローリングアップデート（10分）
```bash
kubectl -n k8s-mag-lab set image deployment/web nginx=nginx:1.27
kubectl -n k8s-mag-lab rollout status deployment/web
kubectl -n k8s-mag-lab rollout history deployment/web
```

### 4. 故意に失敗 → ロールバック（10分）
```bash
kubectl -n k8s-mag-lab set image deployment/web nginx=nginx:does-not-exist
kubectl -n k8s-mag-lab rollout status deployment/web --timeout=60s
kubectl -n k8s-mag-lab rollout undo deployment/web
kubectl -n k8s-mag-lab rollout status deployment/web
```

### 5. Advanced: 設定分離（10〜15分）
```bash
kubectl -n k8s-mag-lab create configmap web-config --from-literal=APP_MODE=dev
kubectl -n k8s-mag-lab create secret generic web-secret --from-literal=API_TOKEN='dummy-token'
kubectl -n k8s-mag-lab get configmap,secret
```
- 注意: Secret を Git に平文コミットしない。
- 実務では External Secrets / Sealed Secrets / KMS 連携を検討。

### 6. 後片付け（任意・注意して実行）
```bash
kubectl delete ns k8s-mag-lab
```
⚠️ **削除コマンドは対象確認後に実行。** `default` や本番 namespace を誤削除しない。

---

## 6) Command Cheatsheet

```bash
# 安全確認
kubectl config current-context
kubectl -n <ns> get all

# 観察
kubectl -n <ns> get pods
kubectl -n <ns> describe pod <pod-name>
kubectl -n <ns> logs <pod-name>
kubectl -n <ns> get events --sort-by=.lastTimestamp

# 更新
kubectl -n <ns> set image deployment/<name> <container>=<image:tag>
kubectl -n <ns> rollout status deployment/<name>
kubectl -n <ns> rollout history deployment/<name>
kubectl -n <ns> rollout undo deployment/<name>

# 設定
kubectl -n <ns> create configmap <name> --from-literal=KEY=VALUE
kubectl -n <ns> create secret generic <name> --from-literal=KEY=VALUE
```

---

## 7) よくあるミス & 安全プラクティス

### よくあるミス
1. `kubectl apply -f .` を意図しないディレクトリで実行してしまう
2. context/namespace 未確認のまま `delete` や `apply`
3. Secret を YAML 平文で Git 管理
4. `latest` タグ運用で再現不能
5. Probe 未設定で不健康 Pod にトラフィックが流れる

### 安全プラクティス
- 破壊的操作前チェック: `current-context`, `-n`, 対象名を声出し確認
- `--dry-run=client -o yaml` で事前確認
- イメージは固定タグ（できれば digest）
- 本番は最小権限 RBAC
- Secret は外部管理を優先、少なくとも暗号化 at rest を有効化
- 一括反映前に scope を絞る（単一ファイル/単一namespace から）

---

## 8) Interview-Style Question

**質問:**  
Deployment の更新中に `rollout status` がタイムアウトしました。あなたならどの順番で原因を切り分け、どの条件で `rollout undo` を実行しますか？

（期待される観点: events / pod describe / image pull エラー / readiness 失敗 / 影響範囲評価 / 復旧優先判断）

---

## 9) Next-Step Resources（公式優先）

- Kubernetes Documentation ホーム  
  https://kubernetes.io/docs/
- kubectl チートシート  
  https://kubernetes.io/docs/reference/kubectl/cheatsheet/
- Deployment（更新・ロールバック）  
  https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- ConfigMap  
  https://kubernetes.io/docs/concepts/configuration/configmap/
- Secret  
  https://kubernetes.io/docs/concepts/configuration/secret/
- Probes（liveness/readiness/startup）  
  https://kubernetes.io/docs/concepts/configuration/liveness-readiness-startup-probes/
- Resource Management for Pods and Containers  
  https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/
- Good Practices for Kubernetes Secrets  
  https://kubernetes.io/docs/concepts/security/secrets-good-practices/

---

次号予告（学習アーク継続）:  
**Ingress と Service 設計（Beginner）→ HPA（Middle）→ PodDisruptionBudget と高可用性設計（Advanced）**
