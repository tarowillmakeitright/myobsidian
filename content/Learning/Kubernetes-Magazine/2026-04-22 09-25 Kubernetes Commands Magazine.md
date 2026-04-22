---
tags: [kubernetes, k8s, devops, learning, daily]
---

# Daily Kubernetes Commands Magazine
**日付:** 2026-04-22 09:25 (Asia/Tokyo)  
**学習アーク:** Beginner → Middle → Advanced  
**リンク:** [[Home]]

---

## 1) トピック + レベル

### 🟢 Beginner
**トピック:** `kubectl get / describe / logs` で「Podの状態を読む」

### 🟡 Middle
**トピック:** Deployment のローリングアップデートとロールバック（`rollout`）
**前提知識:**
- Pod / Deployment の基本
- `kubectl get`, `kubectl describe`, `kubectl logs` が使える
- コンテナイメージタグの概念（例: `nginx:1.25`）

### 🔴 Advanced
**トピック:** Probe（Liveness / Readiness / Startup）と安全なデプロイ運用
**前提知識:**
- Deployment の更新手順（`set image`, `rollout status`, `rollout undo`）
- Service とトラフィック分配の基本
- YAML マニフェストの読み書き

---

## 2) なぜ実アプリ開発で重要か

- **障害切り分けの初動が速くなる**: まず `get/describe/logs` ができると、アプリ原因かクラスタ原因かを短時間で判別しやすい。  
- **本番更新の事故を減らせる**: ローリングアップデートとロールバックを理解すると、機能リリース時のダウンタイム/障害時間を最小化できる。  
- **信頼性を設計に組み込める**: Probe を正しく設定すると、「起動途中なのにトラフィックが来る」問題や無限再起動を防ぎやすい。  

---

## 3) コア kubectl / Kubernetes 概念

### A. `kubectl get`
- リソース一覧を見る基本コマンド。
- 例: `kubectl get pods -n default -o wide`
- **見るべき観点**: `STATUS`, `RESTARTS`, `AGE`, ノード配置。

### B. `kubectl describe`
- 1リソースを詳細表示（イベント含む）。
- 例: `kubectl describe pod <pod名>`
- **使いどころ**: `ImagePullBackOff`, `CrashLoopBackOff`, `FailedScheduling` の原因追跡。

### C. `kubectl logs`
- コンテナ標準出力を確認。
- 例: `kubectl logs <pod名> -c <container名> --tail=100 -f`
- `--previous` で再起動前ログも追える。

### D. Deployment と `rollout`
- Deployment は ReplicaSet を通じて Pod の世代管理を行う。
- `kubectl rollout status deployment/<name>` で更新完了を監視。
- 失敗時は `kubectl rollout undo deployment/<name>` で安全に戻す。

### E. Probe（Liveness / Readiness / Startup）
- **Readiness**: 受信可能になってから Service に参加。  
- **Liveness**: ハング時の自動再起動。  
- **Startup**: 起動の遅いアプリ保護（起動完了まで他 Probe 判定を猶予）。

---

## 4) 実アプリ開発での使い方（kubernetes.io/docs ベストプラクティス準拠）

- **宣言的管理を基本にする**: 本番は `kubectl apply -f` + Git 管理（変更履歴を残す）。
- **名前空間で環境分離**: `dev`, `stg`, `prod` で混線を防ぐ。
- **ラベル設計を最初に決める**: `app`, `component`, `version` など、運用時の検索性に直結。
- **Probe を必ず設計**: アプリの起動特性に合わせて `initialDelaySeconds`, `timeoutSeconds` を調整。
- **Secret は平文直書きしない**: マニフェストへの直書き・Gitコミットを避ける。

---

## 5) 30-60分ミニラボ（安全重視）

> 目標: Nginx Deployment を更新し、失敗パターンからロールバックまで体験する

### 手順0: 事前安全確認（必須）
```bash
kubectl config current-context
kubectl get ns
```
- 想定外のクラスタ/コンテキストでないことを確認。

### 手順1: 学習用 namespace 作成
```bash
kubectl create namespace k8s-mag-lab
```

### 手順2: Deployment 作成
```bash
kubectl create deployment web --image=nginx:1.25 -n k8s-mag-lab
kubectl get pods -n k8s-mag-lab
kubectl rollout status deployment/web -n k8s-mag-lab
```

### 手順3: 情報取得の基本
```bash
kubectl describe deployment web -n k8s-mag-lab
kubectl get rs -n k8s-mag-lab
kubectl get pods -n k8s-mag-lab -o wide
```

### 手順4: 正常アップデート
```bash
kubectl set image deployment/web nginx=nginx:1.26 -n k8s-mag-lab
kubectl rollout status deployment/web -n k8s-mag-lab
kubectl rollout history deployment/web -n k8s-mag-lab
```

### 手順5: わざと失敗するイメージへ更新
```bash
kubectl set image deployment/web nginx=nginx:does-not-exist -n k8s-mag-lab
kubectl rollout status deployment/web -n k8s-mag-lab
kubectl get pods -n k8s-mag-lab
kubectl describe pod -n k8s-mag-lab <失敗しているPod名>
```
- `ImagePullBackOff` / `ErrImagePull` を観察。

### 手順6: ロールバック
```bash
kubectl rollout undo deployment/web -n k8s-mag-lab
kubectl rollout status deployment/web -n k8s-mag-lab
kubectl get pods -n k8s-mag-lab
```

### 手順7: 後片付け（実施前に対象確認）
```bash
kubectl get all -n k8s-mag-lab
kubectl delete namespace k8s-mag-lab
```

⚠️ **注意:** `kubectl delete namespace ...` は破壊的操作。対象 namespace を必ず再確認してから実行。

---

## 6) コマンドチートシート

```bash
# コンテキスト確認
kubectl config current-context
kubectl config get-contexts

# よく使う参照
kubectl get pods -A
kubectl get deploy -n <ns>
kubectl describe pod <pod> -n <ns>
kubectl logs <pod> -n <ns> --tail=100
kubectl logs <pod> -c <container> -n <ns> --previous

# Deployment運用
kubectl set image deployment/<name> <container>=<image>:<tag> -n <ns>
kubectl rollout status deployment/<name> -n <ns>
kubectl rollout history deployment/<name> -n <ns>
kubectl rollout undo deployment/<name> -n <ns>

# YAML適用（要スコープ確認）
kubectl apply -f <file-or-dir>
kubectl diff -f <file-or-dir>
```

---

## 7) よくあるミスと安全策

1. **間違った context で apply/delete**  
   - 安全策: 実行前に `kubectl config current-context` を習慣化。

2. **`-n` 指定漏れで default namespace を汚す**  
   - 安全策: 毎回 `-n <ns>` 明示。必要なら context に namespace 設定。

3. **Secret をマニフェストへ直書き**  
   - 安全策: Secret 管理を使い、平文をGitに入れない。

4. **`kubectl apply -f .` の作用範囲誤認**  
   - 安全策: 実行前に対象ディレクトリ確認、可能なら `kubectl diff` を先に実行。

5. **Probe 設定が厳しすぎて再起動ループ**  
   - 安全策: 起動時間を計測し `startupProbe` で保護、段階的に閾値調整。

---

## 8) 面接風クエスチョン（1問）

**Q.** Deployment 更新後に Pod が `CrashLoopBackOff` になりました。あなたならどの順序で調査し、どの条件でロールバックを判断しますか？  

**Aの観点（自己チェック用）:**
- `rollout status` で進行状況確認
- `get pods`, `describe pod`, `logs --previous` で事象特定
- Probe/環境変数/イメージタグ差分確認
- サービス影響が継続するなら `rollout undo` を優先

---

## 9) 次の一歩（公式ドキュメント中心）

- Kubernetes Documentation（公式トップ）  
  https://kubernetes.io/docs/
- kubectl Overview  
  https://kubernetes.io/docs/reference/kubectl/
- Deployment  
  https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Probes (Liveness/Readiness/Startup)  
  https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/
- Secrets Good Practices  
  https://kubernetes.io/docs/concepts/security/secrets-good-practices/
- Configure Access to Multiple Clusters（context管理）  
  https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/

---

### 明日の予告
次号（Beginner→Middle→Advanced）は **ConfigMap / Secret / 環境差分管理（Kustomize入門）** を予定。
