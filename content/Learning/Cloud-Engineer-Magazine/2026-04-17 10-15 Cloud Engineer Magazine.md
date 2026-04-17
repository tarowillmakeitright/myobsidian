---
tags: [cloud, aws, oci, gcp, architecture, daily]
---

# Cloud Engineer Magazine (2026-04-17 10:15 JST)
[[Home]]

## 1) 今日のアプリ
**AI在庫最適化付きEC受注管理アプリ（中小D2C向け）**

- 注文取り込み（Web/API）
- 在庫引当・欠品予測
- 出荷ステータス追跡
- 売上/在庫回転ダッシュボード
- 需要予測（毎日バッチ + ピーク時オンデマンド推論）

---

## 2) 要件整理（機能要件/非機能要件）

### 機能要件
- 商品・在庫・注文CRUD
- 決済後の注文確定イベント処理
- 倉庫別在庫引当
- CSV/APIで外部モール連携
- 欠品予兆アラート

### 非機能要件
- **可用性**: 月間99.9%以上、注文受付は単一障害点なし
- **性能**: 通常時 p95 300ms以内、セール時は平常の5倍トラフィック耐性
- **セキュリティ**: 最小権限IAM、暗号化（保存時/転送時）、監査ログ保全
- **コスト**: 初期はサーバレス中心、成長時にホットパスのみ常時稼働へ移行

---

## 3) 推奨アーキテクチャ（なぜその構成か）
**イベント駆動 + マネージドDB + オブジェクトストレージ + 監視基盤**を基本とする。

- 注文確定をイベント化し、在庫更新・通知・分析を疎結合化
- 取引系はRDB（整合性重視）、分析系はDWHへ非同期連携
- 需要予測はバッチ推論を基本、急変時のみオンデマンド推論
- API層は認証ゲートウェイ配下に置き、WAF・レート制御を前段適用

**トレードオフ（例）**
- 完全サーバレス: 運用負荷は低いが高負荷時コスト増の可能性
- コンテナ常時稼働: 安定レイテンシだがアイドル時コスト増
- 結論: 初期はサーバレス、アクセス安定後に一部コンテナ化が実務的

---

## 4) クラウド別実装マップ

### AWS での実装サービス
- API: Amazon API Gateway + AWS Lambda
- 認証: Amazon Cognito
- 取引DB: Amazon Aurora Serverless v2 (PostgreSQL)
- イベント: Amazon EventBridge + Amazon SQS
- ストレージ: Amazon S3
- 予測: Amazon SageMaker（Batch Transform / Endpoint）
- 監視: Amazon CloudWatch + AWS X-Ray + AWS CloudTrail
- 秘密情報: AWS Secrets Manager + AWS KMS

### OCI での実装サービス
- API: OCI API Gateway + OCI Functions
- 認証: OCI Identity and Access Management (IAM)
- 取引DB: Oracle Autonomous Transaction Processing
- イベント: OCI Events + OCI Queue
- ストレージ: OCI Object Storage
- 予測: OCI Data Science（モデルデプロイ/ジョブ）
- 監視: OCI Monitoring + Logging + Audit
- 秘密情報: OCI Vault (KMS/Secrets)

### GCP での実装サービス
- API: API Gateway + Cloud Run / Cloud Functions
- 認証: Identity Platform または IAMベース認可
- 取引DB: Cloud SQL for PostgreSQL（またはSpannerは大規模時）
- イベント: Eventarc + Pub/Sub
- ストレージ: Cloud Storage
- 予測: Vertex AI（Batch Prediction / Endpoint）
- 監視: Cloud Monitoring + Cloud Logging + Cloud Audit Logs + Cloud Trace
- 秘密情報: Secret Manager + Cloud KMS

---

## 5) システム構成図（Mermaid）
```mermaid
flowchart LR
  U[Client/Admin] --> WAF[WAF + API Gateway]
  WAF --> APP[App Service\n(Function/Run/Lambda)]
  APP --> RDB[(Transactional DB)]
  APP --> EV[Event Bus/Queue]
  EV --> INV[Inventory Worker]
  EV --> NOTI[Notification Worker]
  EV --> ETL[ETL to DWH]
  ETL --> DWH[(Analytics Warehouse)]
  DWH --> BI[Dashboard]
  OBJ[(Object Storage)] --> ML[ML Batch/Endpoint]
  ML --> APP
```

---

## 6) データフロー/認証・認可/監視運用の要点

### データフロー
1. クライアントが注文APIを実行
2. アプリがRDBへ注文確定をトランザクション書き込み
3. 同時に注文イベントを発行
4. 在庫・通知・分析連携が非同期処理
5. 日次でDWH集計、需要予測で補充提案

### 認証・認可
- ユーザー認証はOIDC/OAuth2ベース
- サービス間はIAMロールで短命資格情報を使用
- DB接続資格情報はSecrets Manager/Vault/Secret Managerでローテーション
- 管理操作はMFA前提 + 監査ログ必須

### 監視運用
- SLI: API成功率、p95遅延、在庫更新遅延、キュー滞留時間
- SLO違反予兆で自動アラート
- 分散トレースで注文ID単位の追跡
- 監査ログを改ざん耐性のある保管先へ集約

---

## 7) コスト最適化ポイント（初期・成長期）

### 初期
- サーバレス優先（Lambda/Functions/Cloud Run）
- 小さなDB構成 + ストレージライフサイクル設定
- ログ保持期間を要件準拠で短めに開始

### 成長期
- ホットAPIのみ常時コンテナ化（予測可能な負荷を最適化）
- DBのリードレプリカ/キャッシュ導入（無駄なスケールアップ回避）
- 予約割引・Savings Plans/Committed Use等を段階適用

---

## 8) 障害時の設計（DR/バックアップ/フェイルオーバー）
- RPO/RTOを先に定義（例: RPO 15分, RTO 60分）
- DBは自動バックアップ + PITR
- オブジェクトストレージはバージョニング有効
- キュー利用で一時障害時の再処理を担保
- 重要系はマルチAZ、必要に応じてクロスリージョン複製
- DR訓練（四半期）で手順の実効性を検証

---

## 9) 学習ポイント（今日覚えるクラウド機能）
- **AWS EventBridge**: ルーティング規則で疎結合イベント駆動を実装
- **OCI Queue**: 非同期処理と再試行制御で障害吸収
- **GCP Pub/Sub + Eventarc**: イベント配送とサービス連携の標準パターン
- **共通**: IAM最小権限 + KMS + 監査ログの3点セットがSecure-by-Defaultの土台

---

## 10) 30〜60分ミニ演習
**テーマ: 注文イベントから在庫更新までの最小実装**

1. APIで注文作成エンドポイントを1本作る
2. 注文作成後にイベントを発行
3. ワーカーで在庫テーブルを更新（冪等キーあり）
4. 失敗時にDLQ/再試行設定
5. メトリクス（成功率・処理遅延）をダッシュボード化

**ゴール**
- 同期処理を減らし、キューでピーク吸収できる設計を体感する

---

## 11) 公式ドキュメント参照リンク（AWS/OCI/GCP）

### AWS
- Well-Architected Framework: https://docs.aws.amazon.com/wellarchitected/latest/framework/welcome.html
- Amazon API Gateway: https://docs.aws.amazon.com/apigateway/
- AWS Lambda: https://docs.aws.amazon.com/lambda/
- Amazon EventBridge: https://docs.aws.amazon.com/eventbridge/
- Amazon SQS: https://docs.aws.amazon.com/AWSSimpleQueueService/
- Amazon Aurora: https://docs.aws.amazon.com/aurora/
- AWS IAM: https://docs.aws.amazon.com/IAM/
- AWS KMS: https://docs.aws.amazon.com/kms/

### OCI
- OCI Architecture Center: https://docs.oracle.com/en-us/iaas/Content/Architecture/Reference/reference-architectures.htm
- OCI API Gateway: https://docs.oracle.com/en-us/iaas/Content/APIGateway/home.htm
- OCI Functions: https://docs.oracle.com/en-us/iaas/Content/Functions/home.htm
- OCI Events: https://docs.oracle.com/en-us/iaas/Content/Events/home.htm
- OCI Queue: https://docs.oracle.com/en-us/iaas/Content/queue/home.htm
- Autonomous Database: https://docs.oracle.com/en-us/iaas/autonomous-database/
- OCI IAM: https://docs.oracle.com/en-us/iaas/Content/Identity/home.htm
- OCI Vault: https://docs.oracle.com/en-us/iaas/Content/KeyManagement/home.htm

### GCP
- Google Cloud Architecture Framework: https://docs.cloud.google.com/architecture/framework
- API Gateway: https://docs.cloud.google.com/api-gateway/docs
- Cloud Run: https://docs.cloud.google.com/run/docs
- Eventarc: https://docs.cloud.google.com/eventarc/docs
- Pub/Sub: https://docs.cloud.google.com/pubsub/docs
- Cloud SQL: https://docs.cloud.google.com/sql/docs
- Vertex AI: https://docs.cloud.google.com/vertex-ai/docs
- IAM: https://docs.cloud.google.com/iam/docs
- Cloud KMS: https://docs.cloud.google.com/kms/docs
