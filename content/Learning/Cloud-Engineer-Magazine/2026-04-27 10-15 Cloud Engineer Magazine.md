---
tags: [cloud, aws, oci, gcp, architecture, daily]
---
# 2026-04-27 10:15 Cloud Engineer Magazine
[[Home]]

#cloud #aws #oci #gcp #architecture #daily

## 1) 今日のアプリ
**マルチチャネル注文の在庫同期アプリ（EC + 実店舗）**  
ECサイト、モバイルPOS、倉庫システムからの在庫更新をほぼリアルタイムで統合し、欠品・過剰在庫を減らす。

## 2) 要件整理
### 機能要件
- 注文/返品/入庫イベントを秒〜分単位で在庫へ反映
- SKUごとの現在庫APIを提供
- 閾値割れ時にアラート通知
- 日次で需要予測バッチを実行

### 非機能要件
- **可用性:** 在庫API 99.9%以上、RPO 15分、RTO 1時間
- **性能:** 在庫照会 p95 < 200ms、イベント遅延 < 5秒（通常時）
- **セキュリティ:** 最小権限IAM、KMS暗号化、監査ログ常時有効
- **コスト:** 初期はサーバレス中心、成長時にホットパスのみ専用化

## 3) 推奨アーキテクチャ（なぜその構成か）
**視点: マルチクラウド分担型**
- **AWS**: トランザクション処理（イベント受信〜在庫反映）をサーバレスで高速実装
- **GCP**: 分析/予測（BigQuery + Vertex AI）に集約
- **OCI**: 低コストなDR保管＋スタンバイAPI

**理由**
- 在庫更新は低遅延要件が強く、DynamoDB + Lambdaの相性が良い
- 予測/分析はBigQueryの集計性能と運用効率が高い
- DRはOCI Object Storage/Autonomous DBで保管コスト最適化しやすい

## 4) クラウド別実装マップ
### AWS での実装サービス
- API受信: **Amazon API Gateway**
- 非同期処理: **Amazon EventBridge** / **Amazon SQS**
- 在庫計算: **AWS Lambda**
- 在庫DB: **Amazon DynamoDB**（オンデマンド + Auto Scaling）
- 秘密情報: **AWS Secrets Manager**
- 監視: **Amazon CloudWatch**, **AWS X-Ray**, **CloudTrail**

### OCI での実装サービス
- DRデータ保管: **Object Storage**
- スタンバイDB: **Autonomous Database Serverless**
- 非同期連携: **OCI Streaming**
- API公開（DR時）: **API Gateway** + **Functions**
- 鍵管理: **OCI Vault**
- 監視/監査: **Monitoring**, **Logging**, **Audit**

### GCP での実装サービス
- データ取り込み: **Pub/Sub** + **Dataflow**
- DWH: **BigQuery**
- 特徴量/予測: **Vertex AI**
- API/バッチ実行: **Cloud Run** + **Cloud Scheduler**
- 秘密情報: **Secret Manager**
- 監視/監査: **Cloud Monitoring**, **Cloud Logging**, **Cloud Audit Logs**

## 5) システム構成図（Mermaid）
```mermaid
flowchart LR
  CH[EC/POS/WMS] --> AWSAPI[API Gateway (AWS)]
  AWSAPI --> EVB[EventBridge/SQS]
  EVB --> L1[Lambda: 在庫更新]
  L1 --> DDB[(DynamoDB)]
  DDB --> APIR[在庫照会API]

  EVB --> XFER[CDC/Export]
  XFER --> GCPPUB[Pub/Sub]
  GCPPUB --> DF[Dataflow]
  DF --> BQ[(BigQuery)]
  BQ --> VAI[Vertex AI]

  DDB --> DRSYNC[非同期レプリケーション]
  DRSYNC --> OCISTRM[OCI Streaming]
  OCISTRM --> OCIDB[(Autonomous DB)]
  OCIDB --> OCIAPI[OCI API Gateway + Functions]
```

## 6) データフロー/認証・認可/監視運用の要点
- **データフロー:** 書き込みはイベント駆動、読み取りはDynamoDB直参照で低遅延化
- **認証・認可:**
  - サービス間はIAMロール/動的グループを使用（長期鍵を避ける）
  - APIはJWT/OIDC検証、管理APIはIP制限 + MFA前提
  - KMS/Vault/Cloud KMSで保存時暗号化
- **監視運用:**
  - SLI: API遅延、イベント滞留、在庫不整合率
  - SLO違反予兆で自動通知（Pager/ChatOps）
  - 監査ログは全クラウドで保持期間を統一

## 7) コスト最適化ポイント（初期・成長期）
- **初期:**
  - AWS Lambda/DynamoDBオンデマンドで固定費最小化
  - BigQueryはパーティション/クラスタでスキャン量削減
  - OCI Object StorageをDR保管の主軸に
- **成長期:**
  - 高頻度SKUのみDynamoDBプロビジョンド+Auto Scaling
  - Dataflowのジョブをストリーミング/バッチで分離
  - 保存ポリシーを階層化（ホット/ウォーム/コールド）

## 8) 障害時の設計（DR/バックアップ/フェイルオーバー）
- **AWSリージョン障害:**
  - 直近スナップショット + イベント再処理で復元
  - Route切替でOCIスタンバイAPIへフェイルオーバー
- **データ破損:**
  - DynamoDB PITR + OCI Object Storageバックアップからリカバリ
- **分析系停止（GCP）:**
  - 予測機能を縮退（直近移動平均）し、在庫更新本体は継続

## 9) 学習ポイント（今日覚えるクラウド機能）
- **AWS EventBridge vs SQS**: ルーティング柔軟性 vs 明示的キュー制御
- **OCI Autonomous Database Serverless**: 運用負荷を抑えたDR用DB選択肢
- **BigQuery パーティション/クラスタ**: クエリコストを設計で下げる基本

## 10) 30〜60分ミニ演習
1. 在庫更新イベントJSONを定義（order_created, order_canceled, restocked）
2. AWSで `API Gateway -> Lambda -> DynamoDB` の最小経路を作成
3. 失敗イベントをSQS DLQへ送る設定を追加
4. BigQueryに同イベントを流し、SKU別日次集計SQLを作る
5. 「在庫差分 > 5」のアラート条件を1つ定義

## 11) 公式ドキュメント参照リンク（AWS/OCI/GCP）
### AWS
- API Gateway: https://docs.aws.amazon.com/apigateway/
- EventBridge: https://docs.aws.amazon.com/eventbridge/
- SQS: https://docs.aws.amazon.com/sqs/
- Lambda: https://docs.aws.amazon.com/lambda/
- DynamoDB: https://docs.aws.amazon.com/dynamodb/
- Well-Architected Framework: https://docs.aws.amazon.com/wellarchitected/

### OCI
- API Gateway: https://docs.oracle.com/en-us/iaas/Content/APIGateway/home.htm
- Functions: https://docs.oracle.com/en-us/iaas/Content/Functions/home.htm
- Streaming: https://docs.oracle.com/en-us/iaas/Content/Streaming/home.htm
- Object Storage: https://docs.oracle.com/en-us/iaas/Content/Object/home.htm
- Autonomous Database: https://docs.oracle.com/en-us/iaas/autonomous-database-serverless/index.html

### GCP
- Pub/Sub: https://cloud.google.com/pubsub/docs
- Dataflow: https://cloud.google.com/dataflow/docs
- BigQuery: https://cloud.google.com/bigquery/docs
- Vertex AI: https://cloud.google.com/vertex-ai/docs
- Cloud Run: https://cloud.google.com/run/docs
- Architecture Framework: https://cloud.google.com/architecture/framework

---
**一言トレードオフ:**  
単一クラウドは運用簡素化に強い一方、マルチクラウドは障害分散とサービス適材適所の自由度が高い。今日の構成は「運用複雑性を受け入れてでも、在庫本体の継続性と分析性能を両立する」選択。