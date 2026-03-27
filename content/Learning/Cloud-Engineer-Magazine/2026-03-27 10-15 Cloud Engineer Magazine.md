# Cloud Engineer Magazine — 2026-03-27
#cloud #aws #oci #gcp #architecture #daily
[[Home]]

## 1) 今日のアプリ
**リアルタイム在庫引当アプリ（EC + 店舗共通在庫）**

- EC注文・店舗POS・倉庫WMSから在庫を同時更新
- 二重販売（oversell）を防ぎつつ、在庫確保レスポンスを高速化
- セール時の瞬間負荷に耐える

**今日の視点:** マルチクラウド比較（実装は単一クラウド開始、将来のDRで他クラウド活用）

---

## 2) 要件整理（機能要件/非機能要件）

### 機能要件
- 在庫照会（SKU/拠点/販売チャネル別）
- 在庫引当（注文時に短時間ロック）
- 決済失敗時の引当解放
- 在庫イベント配信（注文、返品、棚卸、入荷）
- 管理画面で手動調整・監査履歴確認

### 非機能要件
- **可用性:** 24/7、単一リージョン障害を想定したDR
- **性能:** 引当API P95 < 120ms、イベント遅延 < 3秒
- **セキュリティ:** IAM最小権限、通信/保存時暗号化、監査ログ必須
- **コスト:** 初期はマネージド中心、成長期にキャパシティ最適化

---

## 3) 推奨アーキテクチャ（なぜその構成か）

**推奨構成:**
「API Gateway + コンテナ実行基盤 + 低レイテンシDB + イベントバス + キャッシュ」

理由:
1. 在庫引当は同期APIで低遅延が必要（キャッシュ + 高速DB）
2. 注文/返品などは非同期イベント化し、疎結合で拡張しやすい
3. ピーク時はコンテナ自動スケールで吸収
4. 監査証跡（誰がいつ在庫を変更したか）をログに一元化しやすい

**トレードオフ（例）**
- NoSQLは高スケールだが、複雑集計は別分析基盤に分離が必要
- RDBは整合性設計しやすいが、急激なスケール時にシャーディング検討が必要

---

## 4) クラウド別実装マップ

### AWS での実装サービス
- API: Amazon API Gateway
- アプリ: Amazon ECS on Fargate（または AWS Lambda）
- 在庫DB: Amazon DynamoDB（条件付き書き込みで引当競合制御）
- キャッシュ: Amazon ElastiCache for Redis
- イベント: Amazon EventBridge + Amazon SQS
- 認証: Amazon Cognito / IAM
- 監視: Amazon CloudWatch + AWS X-Ray + AWS CloudTrail
- 秘密情報: AWS Secrets Manager

### OCI での実装サービス
- API: OCI API Gateway
- アプリ: Container Instances（または OKE）
- 在庫DB: Autonomous JSON Database（または MySQL HeatWave）
- キャッシュ: OCI Cache with Redis
- イベント: OCI Events + OCI Queue + OCI Streaming
- 認証: OCI IAM Identity Domains
- 監視: OCI Monitoring + Logging + Audit
- 秘密情報: OCI Vault

### GCP での実装サービス
- API: API Gateway
- アプリ: Cloud Run（必要に応じて GKE）
- 在庫DB: Firestore（トランザクション）または Cloud Spanner
- キャッシュ: Memorystore for Redis
- イベント: Pub/Sub + Eventarc
- 認証: Identity Platform / IAM
- 監視: Cloud Monitoring + Cloud Logging + Cloud Trace + Cloud Audit Logs
- 秘密情報: Secret Manager

---

## 5) システム構成図（Mermaidで簡易図）

```mermaid
flowchart LR
    CH[EC/POS/WMS] --> APIGW[API Gateway]
    APIGW --> APP[Inventory Service]
    APP --> CACHE[(Redis Cache)]
    APP --> DB[(Inventory DB)]
    APP --> BUS[Event Bus / Queue]
    BUS --> CONS[Async Consumers\n(返品・通知・分析連携)]
    CONS --> DB
    APP --> AUTH[IdP / IAM]
    APP --> OBS[Monitoring + Audit Logs]
```

---

## 6) データフロー/認証・認可/監視運用の要点

### データフロー
1. クライアントが在庫照会 → キャッシュヒット時は即時返却
2. 引当要求時はDBトランザクション（または条件付き更新）で原子的に減算
3. 結果をイベントバスへ発行（出荷/通知/分析が購読）
4. 決済失敗イベントで引当解放ワーカーが在庫戻し

### 認証・認可
- OIDC/JWTでユーザー認証、サービス間はIAMロールで機械認証
- 書き込み系APIはスコープ分離（read:inventory / reserve:inventory / admin:inventory）
- Redis/DBはプライベートネットワークのみ公開、公開IPなし
- KMS等で暗号鍵を集中管理、Secretsはマネージドシークレット保管

### 監視運用
- SLI: 引当API P95、在庫不整合件数、イベント遅延、DLQ件数
- アラート: 競合失敗率急増、在庫マイナス発生、キュー滞留
- 監査: 権限変更、在庫手動補正、鍵利用履歴を必ず記録

---

## 7) コスト最適化ポイント（初期・成長期）

### 初期
- サーバレス/マネージド優先で運用人件費を削減
- 低トラフィック時は最小インスタンス/自動停止を活用
- ログ保持期間を要件に合わせて短縮（監査要件は別保管）

### 成長期
- 予約/コミット（Savings Plans, CUD等）を適用
- RedisとDBのホットキー対策で無駄なスケールを防止
- 分析用途はOLTP DBから分離し、集計コストを最適化

---

## 8) 障害時の設計（DR/バックアップ/フェイルオーバー）

- **リージョン内:** マルチAZ構成、キュー再試行 + DLQ
- **リージョン障害:**
  - バックアップを別リージョンへ複製
  - IaCで待機環境を迅速起動（RTO短縮）
  - DNS/Traffic Managerでフェイルオーバー
- **データ保護:**
  - DB PITR（ポイントインタイムリカバリ）
  - オブジェクトストレージのバージョニング/不変化ポリシー
- **演習:** 四半期ごとに復旧訓練（Runbook更新含む）

---

## 9) 学習ポイント（今日覚えるクラウド機能）

- **AWS:** DynamoDB の条件付き書き込みで競合更新を防ぐ
- **OCI:** Queue/Streaming + Events で在庫イベント駆動を実装
- **GCP:** Pub/Sub + Eventarc で疎結合イベント配線
- **共通:** IAM最小権限 + 監査ログを先に設計すると後工程が楽

---

## 10) 30〜60分ミニ演習

1. 在庫引当APIの擬似設計（5エンドポイント）
   - GET /stock/{sku}
   - POST /reservations
   - DELETE /reservations/{id}
   - POST /events/payment-failed
   - GET /audit/{sku}
2. 「同時に2件の引当」が来た時の競合制御を設計
3. DLQに溜まった失敗イベントの再処理Runbookを5手順で作る
4. IAMポリシーを3ロール（閲覧/引当/運用者）に分割する

---

## 11) 公式ドキュメント参照リンク（AWS/OCI/GCP）

### AWS
- API Gateway: https://docs.aws.amazon.com/apigateway/
- ECS/Fargate: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/what-is-ecs.html
- DynamoDB: https://docs.aws.amazon.com/amazondynamodb/
- EventBridge: https://docs.aws.amazon.com/eventbridge/
- SQS: https://docs.aws.amazon.com/sqs/
- ElastiCache for Redis: https://docs.aws.amazon.com/AmazonElastiCache/
- Well-Architected Framework: https://docs.aws.amazon.com/wellarchitected/

### OCI
- OCI Documentation Home: https://docs.oracle.com/en-us/iaas/Content/home.htm
- API Gateway: https://docs.oracle.com/en-us/iaas/Content/APIGateway/home.htm
- Container Instances: https://docs.oracle.com/en-us/iaas/Content/container-instances/home.htm
- Queue: https://docs.oracle.com/en-us/iaas/Content/queue/home.htm
- Streaming: https://docs.oracle.com/en-us/iaas/Content/Streaming/home.htm
- Monitoring: https://docs.oracle.com/en-us/iaas/Content/Monitoring/home.htm
- Vault: https://docs.oracle.com/en-us/iaas/Content/KeyManagement/home.htm

### GCP
- Google Cloud Documentation Home: https://docs.cloud.google.com/docs
- API Gateway: https://cloud.google.com/api-gateway/docs
- Cloud Run: https://cloud.google.com/run/docs
- Firestore: https://cloud.google.com/firestore/docs
- Pub/Sub: https://cloud.google.com/pubsub/docs
- Eventarc: https://cloud.google.com/eventarc/docs
- Cloud Monitoring: https://cloud.google.com/monitoring/docs
- Architecture Framework: https://cloud.google.com/architecture/framework
