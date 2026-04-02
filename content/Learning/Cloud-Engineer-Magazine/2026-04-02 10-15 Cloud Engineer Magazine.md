# Cloud Engineer Magazine — 2026-04-02
Tags: #cloud #aws #oci #gcp #architecture #daily
Links: [[Home]]

## 1) 今日のアプリ
**リアルタイム在庫最適化アプリ（小売向け）**
- 店舗POS・EC注文・倉庫在庫を統合し、在庫切れ/過剰在庫を抑える
- 需要予測で自動発注提案
- 今日の視点: **イベント駆動アーキテクチャを3クラウドで実装比較**

## 2) 要件整理（機能/非機能）
### 機能要件
- 注文/返品/入荷イベントのリアルタイム取り込み
- SKU単位の在庫計算（数秒〜1分以内反映）
- 需要予測バッチ（日次）と欠品アラート
- 管理画面/API提供

### 非機能要件
- 可用性: 業務時間中RTO 30分、RPO 5分以下
- 性能: ピーク時 5,000 events/sec、API p95 < 300ms
- セキュリティ: 最小権限IAM、KMS暗号化、監査ログ
- コスト: 初期はサーバレス中心、成長時にストリーム/DBを段階最適化

## 3) 推奨アーキテクチャ（なぜその構成か）
- **イベント駆動 + CQRS寄り**
  - 書き込み系: イベントストリームで吸収（突発トラフィック耐性）
  - 読み取り系: 集計済み在庫テーブルで低遅延API
- **サーバレス優先**
  - 初期運用の負担を抑え、機能検証を速くする
- **理由**
  - 在庫は「更新頻度高・参照頻度高」でワークロード分離が有効
  - イベント再処理で監査・復旧がしやすい

## 4) クラウド別実装マップ
### AWS での実装サービス
- Ingest: Amazon API Gateway / AWS AppSync, Amazon Kinesis Data Streams
- Compute: AWS Lambda, AWS Step Functions（補正/再処理フロー）
- Data: Amazon DynamoDB（在庫現在値）, Amazon S3（生イベント/分析）, Amazon Aurora PostgreSQL（業務参照系が必要なら）
- Analytics/ML: Amazon Athena, Amazon SageMaker（需要予測）
- Security/Ops: AWS IAM, AWS KMS, Amazon CloudWatch, AWS CloudTrail

### OCI での実装サービス
- Ingest: OCI API Gateway, OCI Streaming
- Compute: OCI Functions, OCI Data Flow（Sparkバッチ）
- Data: OCI NoSQL Database, Object Storage, Autonomous Database
- Analytics/ML: OCI Data Science
- Security/Ops: OCI IAM, OCI Vault, OCI Logging/Monitoring, Audit

### GCP での実装サービス
- Ingest: API Gateway / Cloud Endpoints, Pub/Sub
- Compute: Cloud Functions or Cloud Run, Workflows
- Data: Firestore or Bigtable（在庫参照パターン次第）, Cloud Storage, Cloud SQL（必要時）
- Analytics/ML: BigQuery, Vertex AI
- Security/Ops: IAM, Cloud KMS, Cloud Logging/Monitoring, Cloud Audit Logs

## 5) システム構成図（Mermaid）
```mermaid
flowchart LR
  POS[POS/EC/倉庫システム] --> GW[API Gateway]
  GW --> MQ[Event Stream\n(Kinesis/Streaming/PubSub)]
  MQ --> FN[Stream Processor\n(Lambda/Functions/Cloud Functions)]
  FN --> INV[(在庫テーブル\nDynamoDB/NoSQL/Firestore)]
  FN --> DL[Data Lake\nS3/Object Storage/GCS]
  DL --> ML[Forecast Batch\nSageMaker/Data Science/Vertex AI]
  ML --> ORD[発注提案]
  INV --> API[在庫API]
  API --> DASH[運用ダッシュボード]
```

## 6) データフロー/認証・認可/監視運用の要点
- データフロー
  - 受信イベントに idempotency key を付与し重複更新を防止
  - 在庫更新は「加算/減算イベント」を原本として保持（再計算可能）
- 認証・認可
  - サービス間はIAMロール/動的資格情報を使用（固定鍵を避ける）
  - APIはOAuth2/OIDC + スコープで操作を分離（read:inventory / write:inventory）
- 監視運用
  - SLI: イベント遅延、在庫反映遅延、API p95、失敗率
  - DLQ運用と再処理手順をRunbook化

## 7) コスト最適化ポイント（初期・成長期）
- 初期
  - サーバレス徹底（常時稼働ノードを最小化）
  - データ保持はライフサイクルで低頻度ストレージへ
- 成長期
  - ストリームシャード/パーティション適正化
  - ホットキー対策（SKU偏り）でDBスループット浪費を削減
  - 分析はバッチ窓を調整し、常時クエリを抑える

## 8) 障害時の設計（DR/バックアップ/フェイルオーバー）
- DR方針
  - マルチAZ/ADを基本、リージョン障害は重要度に応じてパイロットライト
- バックアップ
  - 在庫テーブル定期スナップショット + イベントログ長期保管
- フェイルオーバー
  - API/DNS切替手順を事前検証
  - 「最終整合」許容範囲を業務側と合意（例: 5分以内）

## 9) 学習ポイント（今日覚えるクラウド機能）
- AWS: Kinesis + Lambda のイベントソースマッピング設計
- OCI: Streaming と Functions の連携、およびVaultでの秘密情報管理
- GCP: Pub/Sub の再配信制御と Cloud Run/Functions の使い分け

## 10) 30〜60分ミニ演習
1. 任意クラウド1つ選び、イベント受信APIを作成
2. ストリームへ `sale`, `return`, `restock` イベントを投入
3. 関数で在庫テーブル更新（冪等キー対応）
4. 失敗イベントをDLQへ送る設定を追加
5. 監視メトリクス（遅延/失敗率）を1枚ダッシュボード化

## 11) 公式ドキュメント参照リンク（AWS/OCI/GCP）
### AWS
- Well-Architected Framework: https://docs.aws.amazon.com/wellarchitected/latest/framework/welcome.html
- Amazon Kinesis Data Streams: https://docs.aws.amazon.com/streams/latest/dev/introduction.html
- AWS Lambda: https://docs.aws.amazon.com/lambda/latest/dg/welcome.html
- Amazon DynamoDB: https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Introduction.html
- AWS IAM: https://docs.aws.amazon.com/IAM/latest/UserGuide/introduction.html

### OCI
- OCI Architecture Center: https://docs.oracle.com/en/solutions/
- OCI Streaming: https://docs.oracle.com/en-us/iaas/Content/Streaming/home.htm
- OCI Functions: https://docs.oracle.com/en-us/iaas/Content/Functions/home.htm
- OCI NoSQL Database: https://docs.oracle.com/en-us/iaas/nosql-database/index.html
- OCI IAM: https://docs.oracle.com/en-us/iaas/Content/Identity/home.htm

### GCP
- Google Cloud Architecture Framework: https://docs.cloud.google.com/architecture/framework
- Pub/Sub: https://docs.cloud.google.com/pubsub/docs/overview
- Cloud Run: https://docs.cloud.google.com/run/docs/overview/what-is-cloud-run
- Cloud Functions: https://docs.cloud.google.com/functions/docs/concepts/overview
- IAM: https://docs.cloud.google.com/iam/docs/overview
