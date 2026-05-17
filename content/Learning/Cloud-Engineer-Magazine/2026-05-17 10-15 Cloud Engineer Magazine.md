---
tags: [cloud, aws, oci, gcp, architecture, daily]
---
[[Home]]

# Cloud Engineer Magazine（2026-05-17）

## 1) 今日のアプリ
**現場向け写真付き点検レポートアプリ（モバイル）**

- 作業員が現場で写真・コメント・位置情報を送信
- 管理者がダッシュボードで進捗確認、異常検知、CSV/PDF出力
- 監査向けに改ざん耐性のある履歴保存

> 今日は「マルチクラウド比較視点」。同じ要件を AWS / OCI / GCP にマッピングして、選定の勘所を掴む回。

---

## 2) 要件整理（機能要件/非機能要件）

### 機能要件
- モバイルアプリからの写真アップロード（最大10MB/枚）
- 点検項目入力（テンプレート方式）
- 点検結果の検索（現場ID・日付・担当者）
- 異常時アラート通知（メール/チャット連携）
- 月次レポート出力（CSV/PDF）

### 非機能要件
- **可用性**: 月間稼働率 99.9%以上
- **性能**: API P95 300ms以内（画像処理除く）
- **セキュリティ**: 最小権限IAM、保存時暗号化、監査ログ完全性
- **コスト**: 初期は従量課金優先、成長後は予約/コミットで圧縮

---

## 3) 推奨アーキテクチャ（なぜその構成か）

**構成方針: 「APIはサーバレス」「画像はオブジェクトストレージ」「検索はマネージドDB + インデックス」**

- サーバレスAPIは初期負荷が読めない段階でコスト効率が高い
- 画像はオブジェクトストレージが耐久性/スケーラビリティ面で有利
- トランザクションはRDB、検索は必要に応じて検索基盤へ分離
- 非同期処理（サムネイル生成、AI判定）はキュー駆動で疎結合化

**トレードオフ（例）**
- API Gateway + Function は運用軽いが、長時間処理は不向き
- コンテナ常駐は柔軟だが、低トラフィック時の固定費が増えやすい

---

## 4) クラウド別実装マップ

### AWS
- フロントAPI: **Amazon API Gateway**
- アプリ実行: **AWS Lambda**
- 画像保存: **Amazon S3**
- RDB: **Amazon Aurora Serverless v2 (PostgreSQL互換)**
- 非同期: **Amazon SQS**
- 認証: **Amazon Cognito**
- 監視: **Amazon CloudWatch + AWS X-Ray**
- 監査: **AWS CloudTrail**

### OCI
- フロントAPI: **OCI API Gateway**
- アプリ実行: **OCI Functions**
- 画像保存: **OCI Object Storage**
- RDB: **OCI Base Database Service (PostgreSQL or MySQL)**
- 非同期: **OCI Queue**
- 認証: **OCI IAM + Identity Domains**
- 監視: **OCI Monitoring + Logging + Application Performance Monitoring**
- 監査: **OCI Audit**

### GCP
- フロントAPI: **API Gateway**
- アプリ実行: **Cloud Run**（HTTPワークロード）
- 画像保存: **Cloud Storage**
- RDB: **Cloud SQL (PostgreSQL)**
- 非同期: **Pub/Sub**
- 認証: **Identity Platform or IAM + IAP構成**
- 監視: **Cloud Monitoring + Cloud Logging + Cloud Trace**
- 監査: **Cloud Audit Logs**

---

## 5) システム構成図（Mermaid）

```mermaid
flowchart LR
  U[作業員モバイルアプリ] --> AGW[API Gateway]
  AGW --> APP[Serverless App\n(Lambda / Functions / Cloud Run)]
  APP --> DB[(Managed RDB)]
  APP --> OBJ[(Object Storage)]
  APP --> MQ[Queue / PubSub]
  MQ --> WK[非同期ワーカー]
  WK --> OBJ
  WK --> DB
  APP --> AUTH[IdP / IAM]
  APP --> MON[Monitoring & Logging]
  APP --> AUDIT[Audit Logs]
  MON --> OPS[運用通知]
```

---

## 6) データフロー/認証・認可/監視運用の要点

### データフロー
1. アプリがトークン取得（ユーザー認証）
2. API呼び出しで点検メタデータ登録
3. 署名付きURLで画像アップロード
4. 非同期でサムネイル生成・異常判定
5. 結果をDB反映、必要なら通知

### 認証・認可
- ユーザー認証はマネージドID基盤（Cognito/Identity Domains/Identity Platform）
- サービス間はIAMロール/サービスアカウントで短期資格情報
- ストレージは「バケット全公開禁止」「prefix単位アクセス制御」
- DB接続はプライベートネットワーク優先

### 監視運用
- SLI: API成功率、P95レイテンシ、キュー滞留、ワーカー失敗率
- アラート: エラー率閾値 + 異常検知（急激な増加）
- 監査: 操作ログとデータイベントを保持・定期レビュー

---

## 7) コスト最適化ポイント（初期・成長期）

### 初期
- サーバレス中心でアイドル課金を削減
- ストレージはライフサイクルで低頻度層へ自動移行
- 開発/検証環境は停止スケジュールを徹底

### 成長期
- DBはサイズ最適化 + read replica検討
- 長時間処理はコンテナワーカーに分離
- 予約/コミット（Savings Plans / OCI割引プラン / GCP CUD）を活用

---

## 8) 障害時の設計（DR/バックアップ/フェイルオーバー）

- **RPO/RTO定義**: 例）RPO 15分、RTO 60分
- DB: 自動バックアップ + PITR（Point-in-Time Recovery）
- オブジェクト: バージョニング + クロスリージョン複製
- API層: IaCで再構築可能にし、リージョン切替手順をRunbook化
- 定期DR訓練: 四半期ごとに復旧演習

---

## 9) 学習ポイント（今日覚えるクラウド機能）

- **AWS**: S3署名付きURLでクライアント直接アップロードしAPI負荷を減らす
- **OCI**: API Gateway + Functions + Object Storage の最小構成パターン
- **GCP**: Cloud Run と Pub/Sub で同期/非同期を分離しやすい

---

## 10) 30〜60分ミニ演習

1. 3クラウドそれぞれで「画像アップロードAPI」の最小構成を紙に設計（10分）
2. IAMポリシーを最小権限で1本作る（読み取り専用 + アップロード限定）（15分）
3. 障害シナリオを1つ決め、検知→通知→復旧のRunbookを箇条書き（15〜30分）

**ゴール**: 同じ要件をクラウドが変わっても実装に落とせる状態にする。

---

## 11) 公式ドキュメント参照リンク（AWS/OCI/GCP）

### AWS
- API Gateway: https://docs.aws.amazon.com/apigateway/
- Lambda: https://docs.aws.amazon.com/lambda/
- S3: https://docs.aws.amazon.com/s3/
- Aurora: https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/CHAP_AuroraOverview.html
- SQS: https://docs.aws.amazon.com/sqs/
- Cognito: https://docs.aws.amazon.com/cognito/
- CloudWatch: https://docs.aws.amazon.com/cloudwatch/
- CloudTrail: https://docs.aws.amazon.com/cloudtrail/

### OCI
- API Gateway: https://docs.oracle.com/en-us/iaas/Content/APIGateway/home.htm
- Functions: https://docs.oracle.com/en-us/iaas/Content/Functions/home.htm
- Object Storage: https://docs.oracle.com/en-us/iaas/Content/Object/home.htm
- Queue: https://docs.oracle.com/en-us/iaas/Content/queue/home.htm
- IAM / Identity Domains: https://docs.oracle.com/en-us/iaas/Content/Identity/home.htm
- Monitoring: https://docs.oracle.com/en-us/iaas/Content/Monitoring/home.htm
- Logging: https://docs.oracle.com/en-us/iaas/Content/Logging/home.htm
- Audit: https://docs.oracle.com/en-us/iaas/Content/Audit/home.htm

### GCP
- API Gateway: https://docs.cloud.google.com/api-gateway/docs
- Cloud Run: https://docs.cloud.google.com/run/docs
- Cloud Storage: https://docs.cloud.google.com/storage/docs
- Cloud SQL: https://docs.cloud.google.com/sql/docs
- Pub/Sub: https://docs.cloud.google.com/pubsub/docs
- Cloud Monitoring: https://docs.cloud.google.com/monitoring/docs
- Cloud Logging: https://docs.cloud.google.com/logging/docs
- Cloud Audit Logs: https://docs.cloud.google.com/logging/docs/audit
