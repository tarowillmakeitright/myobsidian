---
tags: [cloud, aws, oci, gcp, architecture, daily]
---

# Cloud Engineer Magazine (2026-06-01 10:15 JST)
[[Home]]

## 1) 今日のアプリ
**リアルタイム配送ルート最適化アプリ（都市部ラストワンマイル向け）**  
配送員アプリ、配車オペレーター画面、顧客向け追跡画面を持ち、交通状況や新規注文に応じてルートを再計算する。

---

## 2) 要件整理（機能要件/非機能要件）
### 機能要件
- 注文登録（API）
- 配送員位置の継続送信（数秒〜十数秒間隔）
- ルート最適化ジョブ（イベント駆動）
- 顧客向け配送ステータス通知
- 管理画面でKPI可視化（遅延率、稼働率）

### 非機能要件
- **可用性**: APIはマルチAZ前提、最適化ジョブ再実行可能
- **性能**: 位置更新は低遅延取り込み、ルート再計算は数秒〜1分以内
- **セキュリティ**: IAM最小権限、KMS暗号化、WAF、監査ログ有効化
- **コスト**: 初期はサーバレス中心、需要増に応じてコンテナ/DBを段階最適化

---

## 3) 推奨アーキテクチャ（なぜその構成か）
**イベント駆動 + マネージドDB + マネージド監視**を基本にする。  
理由:
1. 注文・位置更新の到着レートが時間帯で大きく変動するため、サーバレス/キューが相性良い。  
2. ルート最適化は非同期化し、失敗時リトライ・DLQで運用安定性を確保できる。  
3. API/通知/分析を疎結合化すると、機能追加（需要予測やETA改善）がしやすい。

---

## 4) クラウド別実装マップ
### AWS での実装サービス
- API: **Amazon API Gateway** + **AWS Lambda**
- イベント取り込み: **Amazon Kinesis Data Streams** または **Amazon SQS**
- 最適化ワークフロー: **AWS Step Functions** + Lambda/ECS
- データ: **Amazon DynamoDB**（配送状態）+ **Amazon RDS/Aurora**（業務データ）
- 認証: **Amazon Cognito**
- 監視: **Amazon CloudWatch**, **AWS X-Ray**, **AWS CloudTrail**
- 保護: **AWS WAF**, **AWS KMS**, **AWS Secrets Manager**

### OCI での実装サービス
- API: **OCI API Gateway** + **OCI Functions**
- イベント取り込み: **OCI Streaming** / **OCI Queue**
- 最適化ワークフロー: **OCI Functions** + **OCI Container Instances**（重い計算時）
- データ: **Autonomous Database** または **MySQL HeatWave** + **OCI NoSQL Database**
- 認証: **OCI IAM**（必要に応じてIdentity Domains）
- 監視: **OCI Monitoring**, **Logging**, **Events**, **Audit**
- 保護: **OCI WAF**, **Vault (KMS/Secrets)**, **Cloud Guard**, **Security Zones**

### GCP での実装サービス
- API: **API Gateway** or **Cloud Endpoints** + **Cloud Run / Cloud Functions**
- イベント取り込み: **Pub/Sub**
- 最適化ワークフロー: **Workflows** + Cloud Run Jobs
- データ: **Firestore**（状態）+ **Cloud SQL**（業務）
- 認証: **Identity and Access Management (IAM)** / **Identity Platform**
- 監視: **Cloud Monitoring**, **Cloud Logging**, **Cloud Trace**, **Cloud Audit Logs**
- 保護: **Cloud Armor**, **Cloud KMS**, **Secret Manager**

**トレードオフ（例）**
- DynamoDB / Firestore / OCI NoSQL はスケールしやすいが、複雑JOINはRDB側が有利。  
- Cloud Run / Container Instances / ECSは実行自由度が高いが、純サーバレスより運用論点が増える。  
- Step Functions / Workflows は可視化が強いが、単純処理ではキュー+関数の方が安価な場合あり。

---

## 5) システム構成図（Mermaid）
```mermaid
flowchart LR
    U[配送員/顧客アプリ] --> GW[API Gateway]
    GW --> APP[App Service (Functions/Run/Lambda)]
    APP --> Q[Stream/Queue]
    Q --> OPT[Route Optimizer Worker]
    OPT --> DB1[(Operational DB)]
    OPT --> DB2[(State Store)]
    APP --> NOTI[Notification Service]
    DB1 --> BI[Analytics/BI]
    APP --> MON[Monitoring & Logging]
```

---

## 6) データフロー/認証・認可/監視運用の要点
- **データフロー**: 位置更新はAPI直書きせずストリーム経由で吸収し、バックプレッシャー耐性を持たせる。  
- **認証・認可**: ユーザー（顧客/配送員/管理者）ロール分離、サービス間は短期認証情報＋最小権限IAM。  
- **監視運用**: SLI（API成功率、最適化遅延、通知遅延）を定義し、閾値アラート＋構造化ログで原因追跡。

---

## 7) コスト最適化ポイント（初期・成長期）
### 初期
- サーバレス優先（Lambda/Functions/Cloud Run）
- 単一リージョン + マルチAZで開始
- ログ保持期間を短めに設計（監査要件を満たす範囲）

### 成長期
- 高頻度ワーカーをコンテナ常駐化（単価最適化）
- ストレージ/DBのライフサイクルとティアリング適用
- 予約/コミット割引（Savings Plans, CUD, OCIの契約モデル）検討

---

## 8) 障害時の設計（DR/バックアップ/フェイルオーバー）
- **DR方針**: RTO/RPOを先に定義（例: RTO 60分, RPO 5分）
- **バックアップ**: RDB自動バックアップ + PITR、有効性を定期リストア検証
- **フェイルオーバー**:
  - API層はリージョン冗長化可能な設計
  - キュー/ストリームの再処理性確保（重複排除キー）
  - DBはマネージドのHA/レプリカ機能を活用

---

## 9) 学習ポイント（今日覚えるクラウド機能）
1. **イベント駆動設計**: 同期APIに処理を詰め込まない
2. **ワークフローオーケストレーション**: 再試行・分岐・可観測性
3. **最小権限IAM**: 人/サービス/環境ごとに権限境界を明確化
4. **マネージド監査ログ**: CloudTrail / OCI Audit / Cloud Audit Logs を常時有効

---

## 10) 30〜60分ミニ演習
**演習テーマ:** 「注文登録→最適化キュー投入→結果保存」最小パスを1クラウドで作る

- 0〜10分: APIエンドポイント1本作成（POST /orders）
- 10〜25分: APIからキュー/トピックへイベント送信
- 25〜40分: コンシューマ関数で受信し、DBへ保存
- 40〜60分: メトリクスとエラーログを可視化、失敗時リトライ確認

完了条件:
- 注文イベントIDが一意発行される
- 失敗イベントが再実行され最終的に保存される
- ダッシュボードで処理成功数/失敗数が見える

---

## 11) 公式ドキュメント参照リンク（AWS/OCI/GCP）
### AWS
- Well-Architected Framework: https://docs.aws.amazon.com/wellarchitected/latest/framework/welcome.html
- API Gateway: https://docs.aws.amazon.com/apigateway/
- Lambda: https://docs.aws.amazon.com/lambda/
- Step Functions: https://docs.aws.amazon.com/step-functions/
- DynamoDB: https://docs.aws.amazon.com/dynamodb/
- CloudWatch: https://docs.aws.amazon.com/cloudwatch/
- IAM best practices: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html

### OCI
- OCI Architecture Center: https://docs.oracle.com/en-us/iaas/Content/Architecture/home.htm
- API Gateway: https://docs.oracle.com/en-us/iaas/Content/APIGateway/home.htm
- Functions: https://docs.oracle.com/en-us/iaas/Content/Functions/home.htm
- Streaming: https://docs.oracle.com/en-us/iaas/Content/Streaming/home.htm
- Monitoring: https://docs.oracle.com/en-us/iaas/Content/Monitoring/home.htm
- IAM Policy Reference: https://docs.oracle.com/en-us/iaas/Content/Identity/Reference/policyreference.htm

### GCP
- Architecture Framework: https://docs.cloud.google.com/architecture/framework
- API Gateway: https://docs.cloud.google.com/api-gateway/docs
- Cloud Run: https://docs.cloud.google.com/run/docs
- Pub/Sub: https://docs.cloud.google.com/pubsub/docs
- Cloud Monitoring: https://docs.cloud.google.com/monitoring/docs
- IAM: https://docs.cloud.google.com/iam/docs

---

明日は、**「医療機関向け予約＋問診プラットフォーム」**を題材に、コンプライアンス要件を含めて比較します。