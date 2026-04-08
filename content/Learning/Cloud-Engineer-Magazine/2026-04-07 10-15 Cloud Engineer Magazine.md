---
tags: [cloud, aws, oci, gcp, architecture, daily]
---
[[Home]]

# Daily Cloud Engineer Magazine — 2026-04-07

## 1) 今日のアプリ
**工場向け「設備異常の早期検知アプリ」**（センサー時系列データ + 異常アラート + 保全チケット連携）

- 例: 温度・振動・電流センサーを 1〜10 秒間隔で収集
- しきい値超過や異常傾向を検知して通知
- 保全担当がモバイルで対応記録

> 今日の視点: **マルチクラウド比較（AWS / OCI / GCP の同等構成）**

---

## 2) 要件整理（機能要件 / 非機能要件）

### 機能要件
- センサーデータのリアルタイム取り込み
- ルールベース異常検知（将来は ML 拡張）
- 異常時の通知（メール/チャット/Webhook）
- ダッシュボード表示（設備単位の状態・履歴）
- 保全チケット起票 API

### 非機能要件
- **可用性**: 24/7 稼働、単一障害点を排除
- **性能**: 秒間数千イベントまで水平スケール
- **セキュリティ**: デバイス認証、暗号化、最小権限 IAM
- **コスト**: PoC はサーバレス中心、本番で段階最適化

---

## 3) 推奨アーキテクチャ（なぜその構成か）

**推奨:** 「マネージド IoT 取り込み + ストリーム処理 + 時系列/分析基盤 + サーバレス API」

理由:
1. デバイス接続/認証をクラウド管理に寄せ、運用負荷を下げる
2. 取り込みと処理を疎結合化（バースト吸収・再試行しやすい）
3. 可視化と通知を分離し、将来の ML 導入を容易にする

トレードオフ:
- サーバレスは初期運用が楽だが、超高頻度時は常時稼働基盤（例: コンテナ常駐）が単価有利になる場合あり
- 時系列 DB はクエリ特性に強いが、長期分析は DWH 連携が必要

---

## 4) クラウド別実装マップ

### AWS での実装サービス
- デバイス接続: **AWS IoT Core**
- ストリーム取り込み: **Amazon Kinesis Data Streams**
- 処理: **AWS Lambda**（または Kinesis Data Analytics）
- 時系列保存: **Amazon Timestream**
- API: **Amazon API Gateway + Lambda**
- 認証: **Amazon Cognito / IAM**
- 通知: **Amazon SNS**
- 監視: **Amazon CloudWatch + AWS X-Ray**
- 秘密情報: **AWS Secrets Manager / KMS**

### OCI での実装サービス
- デバイス/イベント入口: **OCI Streaming**（デバイスゲートウェイ経由を想定）
- 処理: **OCI Functions**
- 長期保存: **Object Storage**
- トランザクション/状態管理: **Autonomous Database**
- API: **API Gateway**
- 認証・認可: **OCI IAM**
- 通知: **Notifications**
- 監視: **Monitoring / Logging / APM**
- 鍵管理: **Vault / Key Management**

### GCP での実装サービス
- デバイス入口: **Pub/Sub**（ゲートウェイ経由）
- ストリーム処理: **Dataflow**
- 時系列/分析: **BigQuery**（時系列分析を SQL で実装）
- API: **Cloud Run**（または API Gateway + Cloud Run）
- 認証: **IAM / Identity-Aware Proxy（管理画面向け）**
- 通知: **Cloud Monitoring Alerting** + Webhook
- 監視: **Cloud Monitoring / Cloud Logging / Cloud Trace**
- 秘密情報: **Secret Manager / Cloud KMS**

---

## 5) システム構成図（Mermaid）

```mermaid
flowchart LR
  D[Sensor Devices] --> G[Device Gateway]
  G --> I[Ingestion Layer\n(IoT Core / Streaming / PubSub)]
  I --> P[Stream Processing\n(Lambda/Functions/Dataflow)]
  P --> T[Time-series & Analytics\n(Timestream/ADB+Object/BigQuery)]
  P --> N[Alerting\n(SNS/Notifications/Monitoring)]
  T --> A[App API\n(API GW + Serverless)]
  A --> U[Web/Mobile Dashboard]
  P --> O[Observability\n(Logs/Metrics/Trace)]
```

---

## 6) データフロー / 認証・認可 / 監視運用の要点

### データフロー
1. デバイス → ゲートウェイで正規化
2. 取り込み基盤へ publish
3. ストリーム処理で異常判定
4. アラート送信 + 保存
5. API 経由でダッシュボード表示

### 認証・認可（最小権限）
- デバイスごとに個別資格情報（証明書/キー）
- 実行ロールは「必要なトピック/テーブルのみ」許可
- オペレータ権限は閲覧・保全操作を分離（RBAC）
- 監査ログを必須化（誰が何を変更したか）

### 監視運用
- SLI: 取り込み遅延、検知遅延、通知成功率
- SLO 例: 検知→通知 60 秒以内 99%
- 異常時 Runbook: 再試行、DLQ確認、手動エスカレーション

---

## 7) コスト最適化ポイント（初期・成長期）

### 初期（PoC〜小規模）
- サーバレス優先（アイドル時コスト最小化）
- 保存期間を短め設定、古いデータは低頻度層へ
- アラート閾値を調整し通知ノイズを抑える

### 成長期（本番拡大）
- ストリーム処理を常駐実行へ切替検討（単価比較）
- 分析データをホット/コールド分離
- クエリ最適化（パーティション・クラスタリング）

---

## 8) 障害時の設計（DR / バックアップ / フェイルオーバー）

- **DR 方針**: リージョン障害を想定し、データは別リージョン複製
- **バックアップ**: DB スナップショット + オブジェクト世代管理
- **フェイルオーバー**: API 層はヘルスチェック付きで切替
- **メッセージ耐久性**: 再処理可能なキュー保持、DLQ 運用
- **目標値例**: RPO 15 分 / RTO 60 分

---

## 9) 学習ポイント（今日覚えるクラウド機能）

1. ストリーム処理は「再試行・順序・重複排除」設計が肝
2. IAM は人間とマシンで権限モデルを分ける
3. 監視はメトリクスだけでなく、**ログ相関 + トレース**まで揃える
4. 時系列ワークロードは保存ポリシーでコスト差が大きい

---

## 10) 30〜60分ミニ演習

**演習テーマ:** 「しきい値異常通知の最小実装」

- Step 1 (10分): Pub/Sub or Streaming or Kinesis にテストデータ投入
- Step 2 (15分): サーバレス関数で `temperature > 80` 判定
- Step 3 (10分): 通知サービスに連携
- Step 4 (10分): メトリクス/ログで処理件数と失敗件数を可視化
- Step 5 (任意): IAM 権限を最小化し、不要権限を削除

完了条件:
- 異常データ送信から 1 分以内に通知される
- 失敗時ログに原因（認証/権限/タイムアウト）が残る

---

## 11) 公式ドキュメント参照リンク（AWS / OCI / GCP）

### AWS
- AWS IoT Core: https://docs.aws.amazon.com/iot/
- Kinesis Data Streams: https://docs.aws.amazon.com/streams/latest/dev/introduction.html
- AWS Lambda: https://docs.aws.amazon.com/lambda/
- Amazon Timestream: https://docs.aws.amazon.com/timestream/
- API Gateway: https://docs.aws.amazon.com/apigateway/
- Well-Architected Framework: https://docs.aws.amazon.com/wellarchitected/

### OCI
- OCI Streaming: https://docs.oracle.com/en-us/iaas/Content/Streaming/home.htm
- OCI Functions: https://docs.oracle.com/en-us/iaas/Content/Functions/home.htm
- API Gateway: https://docs.oracle.com/en-us/iaas/Content/APIGateway/home.htm
- OCI Monitoring: https://docs.oracle.com/en-us/iaas/Content/Monitoring/home.htm
- OCI Logging: https://docs.oracle.com/en-us/iaas/Content/Logging/home.htm
- OCI IAM: https://docs.oracle.com/en-us/iaas/Content/Identity/home.htm

### GCP
- Pub/Sub: https://docs.cloud.google.com/pubsub/docs
- Dataflow: https://docs.cloud.google.com/dataflow/docs
- BigQuery: https://docs.cloud.google.com/bigquery/docs
- Cloud Run: https://docs.cloud.google.com/run/docs
- Cloud Monitoring: https://docs.cloud.google.com/monitoring/docs
- IAM: https://docs.cloud.google.com/iam/docs
