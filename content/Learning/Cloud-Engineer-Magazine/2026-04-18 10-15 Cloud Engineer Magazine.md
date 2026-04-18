---
tags: [cloud, aws, oci, gcp, architecture, daily]
---

# Daily Cloud Engineer Magazine — 2026-04-18
[[Home]]

## 1) 今日のアプリ
**リアルタイム在庫同期付き「D2C向け注文管理アプリ」**

- EC注文を受け、在庫を引当し、倉庫出荷システムへ連携
- 需要急増（セール時）に耐える
- 将来は複数リージョン・複数クラウド展開も視野

> 今日の視点: **マルチクラウド比較（AWS/OCI/GCP）**

---

## 2) 要件整理
### 機能要件
- 注文API（作成/照会/キャンセル）
- 在庫引当（楽観ロック + 冪等処理）
- 決済完了イベント連携（非同期）
- 出荷指示キューイング

### 非機能要件
- **可用性:** 99.9% 以上、単一AZ障害で継続
- **性能:** 注文API p95 < 300ms、ピーク時 10倍スケール
- **セキュリティ:** 最小権限IAM、保存時暗号化、監査ログ
- **コスト:** 初期はサーバレス中心、成長期に予約/コミット割引

---

## 3) 推奨アーキテクチャ（なぜその構成か）
- **API層**: マネージドAPI Gateway + コンテナ/関数
  - 理由: 急激なトラフィック変動への追従と運用負荷削減
- **注文DB**: マネージドRDB（トランザクション整合性重視）
  - 理由: 注文・在庫引当はACIDが重要
- **イベント連携**: Pub/Sub系で疎結合化
  - 理由: 決済・出荷・通知を非同期化してボトルネック分離
- **キャッシュ**: 在庫参照のホットデータをメモリキャッシュ
  - 理由: 読み取り負荷削減とレイテンシ改善

**トレードオフ**
- フルサーバレスは運用が楽だが、長時間処理や複雑ワークフローではコンテナの方が制御しやすい
- 単一RDBは整合性が高いが、読取急増時はリードレプリカ/キャッシュ設計が必須

---

## 4) クラウド別実装マップ
### AWS
- API: **Amazon API Gateway**
- アプリ実行: **AWS Lambda** または **Amazon ECS on Fargate**
- DB: **Amazon Aurora (MySQL/PostgreSQL互換)**
- 非同期イベント: **Amazon EventBridge / Amazon SQS / Amazon SNS**
- キャッシュ: **Amazon ElastiCache (Redis)**
- 認証: **Amazon Cognito**（顧客）+ **IAM**（サービス間）
- 監視: **Amazon CloudWatch / AWS X-Ray / CloudTrail**

### OCI
- API: **OCI API Gateway**
- アプリ実行: **OCI Functions** または **Container Instances / OKE**
- DB: **Autonomous Transaction Processing** もしくは **MySQL HeatWave**
- 非同期イベント: **OCI Streaming / OCI Queue**
- キャッシュ: **OCI Cache with Redis**
- 認証: **OCI IAM**
- 監視: **OCI Monitoring / Logging / Events / Audit**

### GCP
- API: **API Gateway**
- アプリ実行: **Cloud Run**（第一候補）または **Cloud Functions**
- DB: **Cloud SQL (PostgreSQL/MySQL)**
- 非同期イベント: **Pub/Sub**
- キャッシュ: **Memorystore for Redis**
- 認証: **IAM + Identity Platform（必要時）**
- 監視: **Cloud Monitoring / Cloud Logging / Cloud Trace / Cloud Audit Logs**

---

## 5) システム構成図（Mermaid）
```mermaid
flowchart LR
  U[User/App] --> APIGW[API Gateway]
  APIGW --> APP[Order Service (Serverless/Container)]
  APP --> DB[(Transactional DB)]
  APP --> CACHE[(Redis Cache)]
  APP --> EV[Event Bus / Queue]
  EV --> PAY[Payment Adapter]
  EV --> SHIP[Shipping Adapter]
  APP --> OBS[Logs/Metrics/Trace]
  IAM[IAM/KMS/Secrets] --> APIGW
  IAM --> APP
  IAM --> DB
```

---

## 6) データフロー/認証・認可/監視運用の要点
- **データフロー**
  1. 注文作成リクエスト受信
  2. DBトランザクションで注文+在庫引当
  3. 成功後にイベント発行（決済・出荷へ）
  4. 失敗時は補償処理（在庫戻し）
- **認証・認可**
  - エンドユーザーはOIDC/JWT
  - サービス間はIAMロール（長期鍵を避ける）
  - Secretsは専用マネージド機能に保管、KMS暗号化
- **監視運用**
  - SLI: API成功率、p95遅延、在庫引当失敗率、キュー滞留
  - アラート: エラー率急増、DB接続逼迫、DLQ増加

---

## 7) コスト最適化ポイント（初期・成長期）
### 初期
- サーバレス優先（Lambda/Functions/Cloud Run最小構成）
- 小さいDBインスタンス + オートスケール
- 監視保持期間を要件ベースで短め設定

### 成長期
- 予約/コミット割引（Savings Plans, CUD 等）
- キャッシュヒット率改善でDB負荷削減
- 非同期化を進め、ピーク時過剰プロビジョニングを回避

---

## 8) 障害時の設計（DR/バックアップ/フェイルオーバー）
- **RPO/RTO目標例**: RPO 5分、RTO 30分
- マルチAZ構成（DB/アプリ）
- 自動バックアップ + 定期リストア訓練
- キューにDLQを設定し、再処理Runbookを用意
- リージョン障害に備え、重要データのクロスリージョン複製を段階導入

---

## 9) 学習ポイント（今日覚えるクラウド機能）
1. **イベント駆動で注文処理を疎結合化**する設計意図
2. **最小権限IAM**とサービスアカウント分離の基本
3. **トランザクション整合性 + 非同期連携**の実務バランス

---

## 10) 30〜60分ミニ演習
**課題:** 注文作成APIの最小構成を1クラウドでPoC

- 0-10分: APIエンドポイント作成
- 10-25分: 注文テーブル作成 + INSERT実装
- 25-40分: イベント発行（キュー/トピック）追加
- 40-60分: 失敗時リトライとDLQ確認

**達成条件**
- 注文登録成功時にイベント1件が到達
- 失敗イベントがDLQへ入り、手動再処理できる

---

## 11) 公式ドキュメント参照リンク（AWS/OCI/GCP）
### AWS
- Well-Architected Framework: https://docs.aws.amazon.com/wellarchitected/latest/framework/welcome.html
- Amazon API Gateway: https://docs.aws.amazon.com/apigateway/
- AWS Lambda: https://docs.aws.amazon.com/lambda/
- Amazon ECS (Fargate): https://docs.aws.amazon.com/ecs/
- Amazon Aurora: https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/CHAP_AuroraOverview.html
- Amazon EventBridge: https://docs.aws.amazon.com/eventbridge/
- Amazon SQS: https://docs.aws.amazon.com/sqs/
- Amazon ElastiCache: https://docs.aws.amazon.com/AmazonElastiCache/
- AWS IAM: https://docs.aws.amazon.com/iam/

### OCI
- OCI Architecture Center: https://docs.oracle.com/en/solutions/
- OCI API Gateway: https://docs.oracle.com/en-us/iaas/Content/APIGateway/home.htm
- OCI Functions: https://docs.oracle.com/en-us/iaas/Content/Functions/home.htm
- OCI Container Instances: https://docs.oracle.com/en-us/iaas/Content/container-instances/home.htm
- OCI Autonomous Database: https://docs.oracle.com/en-us/iaas/autonomous-database/index.html
- OCI Streaming: https://docs.oracle.com/en-us/iaas/Content/Streaming/home.htm
- OCI Queue: https://docs.oracle.com/en-us/iaas/Content/queue/home.htm
- OCI Cache with Redis: https://docs.oracle.com/en-us/iaas/Content/redis/home.htm
- OCI IAM: https://docs.oracle.com/en-us/iaas/Content/Identity/home.htm

### GCP
- Google Cloud Architecture Framework: https://docs.cloud.google.com/architecture/framework
- API Gateway: https://docs.cloud.google.com/api-gateway/docs
- Cloud Run: https://docs.cloud.google.com/run/docs
- Cloud SQL: https://docs.cloud.google.com/sql/docs
- Pub/Sub: https://docs.cloud.google.com/pubsub/docs
- Memorystore for Redis: https://docs.cloud.google.com/memorystore/docs/redis
- IAM: https://docs.cloud.google.com/iam/docs
- Cloud Monitoring: https://docs.cloud.google.com/monitoring/docs
