---
tags:
  - kubernetes
  - k8s
  - devops
  - learning
  - daily
---

[[Home]]

# 2026-06-18 09-25 Kubernetes Commands Magazine

## 今号のテーマ
**Topic:** `kubectl describe` と `kubectl logs` を軸にした「アプリ障害の初動調査」

**Learning Arc:**
- **Beginner:** Pod の状態を見る
- **Middle:** Deployment / ReplicaSet / Event をつないで原因を特定する
- **Advanced:** namespace・label selector・container 指定・過去ログを使って安全に調査する

---

## [Beginner] Pod の基本観察: `get`, `describe`, `logs`

### なぜ実アプリ開発で重要か
アプリを Kubernetes 上で動かすと、「コードは正しいのに動かない」ケースがよく起きます。たとえば以下です。
- イメージの pull 失敗
- 環境変数の設定漏れ
- readiness probe / liveness probe の不整合
- アプリ起動直後のクラッシュ

このとき最初に使うべきなのが、`kubectl get pod`、`kubectl describe pod`、`kubectl logs` です。開発チームが素早く原因を切り分けられるかどうかで、復旧速度がかなり変わります。

### コア概念
- **Pod**: コンテナを動かす最小単位
- **STATUS**: Pod の現在状態。`Running` でもアプリが正常とは限らない
- **Events**: スケジューリング失敗、イメージ pull 失敗、probe 失敗などの時系列ヒント
- **Logs**: コンテナが stdout/stderr に出した実行ログ

### kubectl / Kubernetes の考え方
Kubernetes では「まずオブジェクト状態を確認し、その後に詳細・ログを見る」のが基本です。

おすすめ順序:
1. `kubectl get pods`
2. `kubectl describe pod <pod名>`
3. `kubectl logs <pod名>`

これは公式ドキュメントの運用・トラブルシュートの流れとも一致しています。いきなり再起動や再 apply をするより、まず観察して原因を特定するほうが安全です。

### アプリ開発中にどう使うか
- 新しいアプリをデプロイした直後に起動確認
- CI/CD 後の簡易ヘルスチェック
- ローカル開発環境（minikube/kind/k3d など）で起動失敗を調べる
- 開発環境 namespace で特定サービスだけ確認する

### 30-60分ミニラボ
**目的:** NGINX Pod を作り、状態確認とログ確認の流れに慣れる

#### 事前準備
- `kubectl` が使える
- 学習用クラスタ（kind / minikube / k3d など）
- **本番クラスタでは実施しないこと**

#### 手順
1. namespace を作る
```bash
kubectl create namespace k8s-magazine-lab
```

2. NGINX Pod を作る
```bash
kubectl run web --image=nginx:1.27 --namespace k8s-magazine-lab
```

3. Pod 一覧を見る
```bash
kubectl get pods -n k8s-magazine-lab
```

4. 詳細を見る
```bash
kubectl describe pod web -n k8s-magazine-lab
```

5. ログを見る
```bash
kubectl logs web -n k8s-magazine-lab
```

6. ラベル付きで一覧を見る
```bash
kubectl get pod web -n k8s-magazine-lab --show-labels
```

7. 後片付け
```bash
kubectl delete namespace k8s-magazine-lab
```

### コマンドチートシート
```bash
kubectl get pods
kubectl get pods -A
kubectl get pods -n <namespace>
kubectl describe pod <pod名> -n <namespace>
kubectl logs <pod名> -n <namespace>
kubectl logs -f <pod名> -n <namespace>
kubectl get events -n <namespace> --sort-by=.lastTimestamp
```

### よくあるミスと安全策
- **ミス:** namespace を指定せず別環境を見てしまう  
  **安全策:** `-n <namespace>` を明示する
- **ミス:** `Running` だから正常と判断する  
  **安全策:** readiness / logs / events も確認する
- **ミス:** 問題発生時にいきなり削除する  
  **安全策:** 先に `describe` と `logs` を保存・確認する
- **注意:** `kubectl delete` は破壊的です。本番文脈では対象 namespace/context を必ず再確認する

### 面接っぽい質問
**Q.** `kubectl get pod` と `kubectl describe pod` の違いは何ですか？  
**A.** `get` は一覧や要約の確認、`describe` はイベントやコンテナ状態を含む詳細調査に向いています。

### 次の一歩
- Kubernetes Pod 概要: https://kubernetes.io/docs/concepts/workloads/pods/
- kubectl cheatsheet: https://kubernetes.io/docs/reference/kubectl/cheatsheet/
- Debug running pods: https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/

---

## [Middle] Deployment から Pod 障害をたどる

**Prerequisites:**
- Pod の基本概念を理解している
- `kubectl get/describe/logs` を使ったことがある
- namespace 指定の重要性を理解している

### なぜ実アプリ開発で重要か
実際のアプリは Pod を直接作るより、通常は **Deployment** で管理します。つまり障害対応では「Pod だけ見る」のでは不十分で、Deployment → ReplicaSet → Pod のつながりを見る必要があります。

たとえば:
- 新しい image tag のミス
- 環境変数や ConfigMap の差し替え漏れ
- rollout 後の CrashLoopBackOff

こうした問題は Deployment 観点で確認した方が早いです。

### コア概念
- **Deployment**: Pod の望ましい状態を管理する上位オブジェクト
- **ReplicaSet**: Deployment が管理する Pod の世代管理
- **Rollout**: 新バージョンへの更新過程
- **Label Selector**: 関連する Pod をまとめて探す鍵

### kubectl / Kubernetes の考え方
Kubernetes は宣言的管理が基本です。アプリ開発では「単一 Pod を手作業で直す」のではなく、Deployment の定義や rollout 状態を確認し、必要なら安全に修正して再適用します。

よく使う流れ:
1. `kubectl get deploy`
2. `kubectl describe deploy <name>`
3. `kubectl get rs`
4. `kubectl get pods -l app=<label>`
5. `kubectl logs` / `kubectl describe pod`

### アプリ開発中にどう使うか
- 新しいバージョンを出した直後の rollout 監視
- staging で再現した不具合の切り分け
- readiness probe 失敗や image tag ミスの検出
- 複数 Pod のうち一部だけ不安定なときの比較

### 30-60分ミニラボ
**目的:** Deployment の更新失敗を観察し、どこを見るべきか覚える

#### 手順
1. namespace 作成
```bash
kubectl create namespace k8s-rollout-lab
```

2. Deployment 作成
```bash
kubectl create deployment web --image=nginx:1.27 -n k8s-rollout-lab
```

3. Deployment / RS / Pod を確認
```bash
kubectl get deploy,rs,pods -n k8s-rollout-lab
```

4. Deployment を存在しないタグへ更新して失敗を起こす
```bash
kubectl set image deployment/web nginx=nginx:does-not-exist -n k8s-rollout-lab
```

5. rollout 状態を確認
```bash
kubectl rollout status deployment/web -n k8s-rollout-lab
```

6. 詳細調査
```bash
kubectl describe deployment web -n k8s-rollout-lab
kubectl get rs -n k8s-rollout-lab
kubectl get pods -n k8s-rollout-lab
kubectl describe pod -n k8s-rollout-lab <pod名>
```

7. 正しいイメージに戻す
```bash
kubectl set image deployment/web nginx=nginx:1.27 -n k8s-rollout-lab
kubectl rollout status deployment/web -n k8s-rollout-lab
```

8. 後片付け
```bash
kubectl delete namespace k8s-rollout-lab
```

### コマンドチートシート
```bash
kubectl get deployment -n <namespace>
kubectl describe deployment <name> -n <namespace>
kubectl get rs -n <namespace>
kubectl get pods -l app=<label> -n <namespace>
kubectl rollout status deployment/<name> -n <namespace>
kubectl rollout history deployment/<name> -n <namespace>
kubectl set image deployment/<name> <container>=<image> -n <namespace>
```

### よくあるミスと安全策
- **ミス:** Pod だけ見て Deployment の更新失敗を見逃す  
  **安全策:** `rollout status` と `describe deployment` をセットで見る
- **ミス:** ラベル指定が曖昧で別アプリの Pod を見てしまう  
  **安全策:** `kubectl get pod --show-labels` で実ラベルを確認する
- **ミス:** 本番で軽率に `set image` する  
  **安全策:** まず staging で確認し、変更対象の context と namespace を二重確認する
- **注意:** `kubectl apply -f .` は対象範囲を誤ると危険。現在の directory・manifest・context を確認してから実行する

### 面接っぽい質問
**Q.** Deployment 配下の Pod が起動しないとき、どの順番で調査しますか？  
**A.** Deployment の状態、rollout status、ReplicaSet、Pod 一覧、該当 Pod の describe/logs、Events の順で調査します。

### 次の一歩
- Deployment 概要: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Updating a Deployment: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#updating-a-deployment
- Troubleshoot applications: https://kubernetes.io/docs/tasks/debug/debug-application/

---

## [Advanced] 安全な調査オペレーション: 複数コンテナ・過去ログ・context確認

**Prerequisites:**
- Deployment / ReplicaSet / Pod の関係を理解している
- rollout と label selector を利用できる
- 開発・staging・本番のクラスタ分離がなぜ重要か理解している

### なぜ実アプリ開発で重要か
実務では 1 Pod 1 コンテナとは限りません。sidecar、initContainer、複数 namespace、複数 cluster が普通です。しかも事故の多くは「知らない」より「操作ミス」で起きます。

代表例:
- 別 context の本番クラスタでコマンドを実行
- `kubectl logs` の対象コンテナを間違える
- 再起動後に現在ログしか見ず、前回クラッシュ原因を見逃す
- `kubectl apply` や `delete` の対象スコープを誤る

### コア概念
- **Context**: どのクラスタ・認証先に対して操作するか
- **Namespace**: リソースの論理分離単位
- **Multi-container Pod**: コンテナごとにログ対象を分ける必要がある
- **Previous Logs**: 再起動したコンテナの直前ログを取る `--previous`
- **Dry-run / 明示指定**: 事故防止の基本

### kubectl / Kubernetes の考え方
Kubernetes のベストプラクティスでは、アプリ開発・運用ともに「安全に観察し、変更は明示的に行う」が重要です。特に以下を習慣化すると事故率が下がります。
- 実行前に `kubectl config current-context` を確認
- namespace を常に明示
- selector を狭くする
- Secret を manifest に直書きしない
- 破壊的コマンドの前に対象確認

### アプリ開発中にどう使うか
- sidecar を含む API Pod のログ切り分け
- CrashLoopBackOff の前回ログ確認
- 本番事故対応で context 誤爆を防ぐ
- CI の manifest レビューで Secret 直書きや広すぎる apply を避ける

### 30-60分ミニラボ
**目的:** 安全確認を挟みながら複数コンテナ Pod と previous logs を扱う

#### 手順
1. まず context を確認
```bash
kubectl config current-context
```

2. namespace 作成
```bash
kubectl create namespace k8s-advanced-lab
```

3. マニフェストを保存（Secret は使わない簡易 lab）
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: multi-log-demo
  namespace: k8s-advanced-lab
spec:
  containers:
    - name: app
      image: busybox:1.36
      command: ["sh", "-c", "while true; do echo app-running; sleep 5; done"]
    - name: sidecar
      image: busybox:1.36
      command: ["sh", "-c", "while true; do echo sidecar-running; sleep 7; done"]
```

4. apply
```bash
kubectl apply -f multi-log-demo.yaml
```

5. コンテナ名を確認
```bash
kubectl get pod multi-log-demo -n k8s-advanced-lab -o jsonpath='{.spec.containers[*].name}'
```

6. コンテナ別ログを確認
```bash
kubectl logs multi-log-demo -n k8s-advanced-lab -c app
kubectl logs multi-log-demo -n k8s-advanced-lab -c sidecar
```

7. Crash する Pod を作って previous logs を試す
```bash
kubectl run crash-demo \
  --image=busybox:1.36 \
  -n k8s-advanced-lab \
  -- sh -c 'echo about-to-crash; exit 1'
```

8. 状態確認後、前回ログを見る
```bash
kubectl get pod crash-demo -n k8s-advanced-lab
kubectl logs crash-demo -n k8s-advanced-lab --previous
kubectl describe pod crash-demo -n k8s-advanced-lab
```

9. 後片付け
```bash
kubectl delete namespace k8s-advanced-lab
```

### コマンドチートシート
```bash
kubectl config current-context
kubectl config get-contexts
kubectl get pods -n <namespace> -o wide
kubectl get pod <pod名> -n <namespace> -o jsonpath='{.spec.containers[*].name}'
kubectl logs <pod名> -n <namespace> -c <container名>
kubectl logs <pod名> -n <namespace> --previous
kubectl describe pod <pod名> -n <namespace>
kubectl apply -f <file> --dry-run=client
```

### よくあるミスと安全策
- **ミス:** `kubectl config current-context` を見ずに操作  
  **安全策:** 変更系コマンド前に毎回確認する
- **ミス:** 複数コンテナ Pod でデフォルトコンテナ以外のログを見逃す  
  **安全策:** `-c <container名>` を明示する
- **ミス:** Secret を manifest に平文で書く  
  **安全策:** Secret 管理手法を使い、Git に秘密情報を入れない
- **ミス:** `kubectl delete -f .` や `kubectl apply -f .` を不用意に実行  
  **安全策:** 対象ファイルを明示し、`--dry-run=client` やレビューを活用する
- **注意:** 破壊的コマンド（`delete`, 大きい範囲の `apply`, namespace 削除）は本番で特に危険。context・namespace・対象 manifest を必ず再確認する

### 面接っぽい質問
**Q.** CrashLoopBackOff の Pod で、なぜ `kubectl logs --previous` が役立つのですか？  
**A.** 再起動済みコンテナの直前実行ログを確認できるため、起動直後クラッシュの原因特定に有効だからです。

### 次の一歩
- Configure access to clusters: https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/
- Debug application: https://kubernetes.io/docs/tasks/debug/debug-application/
- Debug running pods: https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/
- Secrets good practices: https://kubernetes.io/docs/concepts/security/secrets-good-practices/

---

## まとめ
今日のポイントは、「Kubernetes の調査は観察順序で差がつく」です。

- **Beginner:** Pod 単位で `get` / `describe` / `logs`
- **Middle:** Deployment → ReplicaSet → Pod の流れで rollout を見る
- **Advanced:** context / namespace / 複数コンテナ / previous logs を意識して安全に調査する

アプリ開発では、むやみに再作成・再 apply するより、**まず正しいスコープで観察すること**が一番実践的です。

次号ではこの流れを土台に、`kubectl exec`・`port-forward`・Service/Endpoint の確認へ進むと学習がつながりやすいです。
