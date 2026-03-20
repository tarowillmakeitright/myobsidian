---
tags: [cloud, aws, oci, gcp, architecture, daily]
---
[[Home]]

# Cloud Engineer Magazine — 2026-03-20

## 1) 今日のアプリ
**アプリ名:** フラッシュセール向け「リアルタイム在庫・価格最適化API」  
**想定ユーザー:** EC事業者（D2C/小売）  
**今日の視点:** **マルチクラウド比較（AWS/OCI/GCPで同等構成）**

---

## 2) 要件整理（機能要件 / 非機能要件）
### 機能要件
- 商品在庫のリアルタイム更新（注文/キャンセル/返品イベント反映）
- 需要に応じた価格調整（ルールベース + 将来ML拡張）
- 管理画面/API経由でSKU単位の在庫・価格参照
- 閾値通知（在庫逼迫、価格変更失敗）

### 非機能要件
- **可用性:** セール時ピークでもAPI継続（目標99.9%+）
- **性能:** 参照API p95 < 200ms、更新イベント遅延 < 数秒
- **セキュリティ:** 最小権限IAM、暗号化（保存/転送）、監査ログ
- **コスト:** 通常時は低コスト、セール時のみ自動スケール

---

## 3) 推奨アーキテクチャ（なぜその構成か）
**推奨:** 「API + キャッシュ + イベント駆動 + マネージドDB」
- 読み取り集中はキャッシュで吸収し、DB負荷を抑える
- 在庫更新はイベントキュー/ストリームで非同期化し、スパイク耐性を確保
- 価格計算は独立コンポーネント化して将来のML推論に差し替えやすくする
- 監視/監査を初期から組み込み、運用負荷を下げる

**トレードオフ（例）**
- サーバレスAPI: 運用軽いが、超低レイテンシ一定化は工夫が必要
- コンテナAPI: 制御性高いが、運用・チューニング負荷が増える
- 強整合DB中心: 在庫の正確性は高いが、読み取り性能はキャッシュ併用前提

---

## 4) クラウド別実装マップ
### AWS での実装サービス
- API: **Amazon API Gateway** + **AWS Lambda**
- イベント: **Amazon EventBridge**（または **Amazon SQS**）
- 在庫DB: **Amazon DynamoDB**（オンデマンド + TTL活用）
- キャッシュ: **Amazon ElastiCache for Redis**
- 認証: **Amazon Cognito**（管理画面）+ IAMロール
- 秘密情報: **AWS Secrets Manager**
- 監視: **Amazon CloudWatch** + **AWS X-Ray** + **CloudTrail**

### OCI での実装サービス
- API: **API Gateway** + **Functions**
- イベント: **OCI Streaming**（または Queue）
- 在庫DB: **Autonomous Database**（JSON/トランザクション）または NoSQL
- キャッシュ: **OCI Cache (Redis)**
- 認証: **OCI IAM**（動的グループ/ポリシー）
- 秘密情報: **OCI Vault**
- 監視: **OCI Monitoring** + **Logging** + **Audit**

### GCP での実装サービス
- API: **API Gateway** + **Cloud Run**（または Cloud Functions）
- イベント: **Pub/Sub**
- 在庫DB: **Firestore**（ドキュメント）または **Cloud SQL**
- キャッシュ: **Memorystore for Redis**
- 認証: **IAM** +（管理UIは）Identity Platform / IAP構成
- 秘密情報: **Secret Manager**
- 監視: **Cloud Monitoring** + **Cloud Logging** + **Cloud Audit Logs**

---

## 5) システム構成図（Mermaid）
```mermaid
flowchart LR
    U[Client / Admin UI] --> AGW[API Gateway]
    AGW --> APP[App Service\n(Lambda/Functions/Cloud Run)]
    APP --> C[(Redis Cache)]
    APP --> DB[(Inventory DB)]
    APP --> EV[Event Bus / Queue / Stream]
    EV --> PR[Pricing Worker]
    PR --> DB
    APP --> SEC[Secrets / KMS]
    APP --> MON[Monitoring + Logs + Audit]
```

---

## 6) データフロー / 認証・認可 / 監視運用の要点
### データフロー
1. 注文イベント受信 → イベント基盤へ投入
2. ワーカーが在庫引当・価格再計算
3. DB更新後、キャッシュを更新/無効化
4. 参照APIはキャッシュ優先、ミス時DB参照

### 認証・認可
- API利用者はOIDC/JWTベースで認証
- サービス間アクセスは**ロールベース**（長期鍵を避ける）
- SKU更新系APIは読み取りAPIより厳格にスコープ分離
- SecretはVault/Secrets Manager管理、アプリに直書き禁止

### 監視運用
- SLI例: API成功率、p95レイテンシ、イベント遅延、在庫不整合率
- アラート: 在庫更新失敗率、DLQ件数、価格更新遅延
- 監査: IAM変更、機密情報アクセス、本番設定変更を必ず記録

---

## 7) コスト最適化ポイント（初期・成長期）
### 初期
- サーバレス中心（従量課金）で固定費を抑える
- Redisは最小構成 + TTL最適化
- ログ保持期間を用途別に短中長で分ける

### 成長期
- 高トラフィックAPIをコンテナ常時稼働へ一部移行検討
- DBのアクセスパターン最適化（ホットキー対策、パーティション設計）
- 監視メトリクスとログのサンプリングで可観測性コストを制御

---

## 8) 障害時の設計（DR / バックアップ / フェイルオーバー）
- DB: 定期バックアップ + Point-in-Time Recovery（対応サービスで有効化）
- イベント: 冪等処理 + リトライ + DLQ
- API: マルチAZ前提、依存サービス障害時は縮退応答（在庫最終更新時刻を返す）
- DR: RTO/RPOを定義（例: RTO 60分、RPO 5分）し、四半期ごとに復旧演習

---

## 9) 学習ポイント（今日覚えるクラウド機能）
- **AWS:** DynamoDBのオンデマンド/オートスケーリングとTTL
- **OCI:** IAM動的グループ + Vault連携の実践
- **GCP:** Pub/Sub + Cloud Run のイベント駆動パターン

---

## 10) 30〜60分ミニ演習
**お題:** 「在庫更新API + 非同期価格更新」の最小プロトタイプを1クラウドで作る
1. APIエンドポイントを1つ作成（`POST /inventory/update`）
2. 更新イベントをキュー/トピックへ発行
3. ワーカーでイベントを受け、DB更新（ダミー可）
4. 失敗時にDLQへ送る設定を追加
5. ダッシュボードで「成功率・遅延」を可視化

**達成基準**
- API実行からイベント処理完了まで追跡できる
- 1回障害を意図的に起こし、DLQ/アラート動作を確認

---

## 11) 公式ドキュメント参照リンク（AWS/OCI/GCP）
### AWS
- AWS Documentation: https://docs.aws.amazon.com/
- API Gateway: https://docs.aws.amazon.com/apigateway/
- Lambda: https://docs.aws.amazon.com/lambda/
- DynamoDB: https://docs.aws.amazon.com/dynamodb/
- ElastiCache: https://docs.aws.amazon.com/elasticache/
- EventBridge: https://docs.aws.amazon.com/eventbridge/
- SQS: https://docs.aws.amazon.com/sqs/
- CloudWatch: https://docs.aws.amazon.com/cloudwatch/
- CloudTrail: https://docs.aws.amazon.com/cloudtrail/

### OCI
- OCI Documentation: https://docs.oracle.com/en-us/iaas/Content/home.htm
- API Gateway: https://docs.oracle.com/en-us/iaas/Content/APIGateway/home.htm
- Functions: https://docs.oracle.com/en-us/iaas/Content/Functions/home.htm
- Streaming: https://docs.oracle.com/en-us/iaas/Content/Streaming/home.htm
- Autonomous Database: https://docs.oracle.com/en/cloud/paas/autonomous-database/
- OCI Vault: https://docs.oracle.com/en-us/iaas/Content/KeyManagement/home.htm
- Monitoring: https://docs.oracle.com/en-us/iaas/Content/Monitoring/home.htm
- Logging: https://docs.oracle.com/en-us/iaas/Content/Logging/home.htm

### GCP
- Google Cloud Documentation: https://docs.cloud.google.com/docs
- API Gateway: https://cloud.google.com/api-gateway/docs
- Cloud Run: https://cloud.google.com/run/docs
- Pub/Sub: https://cloud.google.com/pubsub/docs
- Firestore: https://cloud.google.com/firestore/docs
- Cloud SQL: https://cloud.google.com/sql/docs
- Memorystore: https://cloud.google.com/memorystore/docs/redis
- Secret Manager: https://cloud.google.com/secret-manager/docs
- Cloud Monitoring: https://cloud.google.com/monitoring/docs
- Cloud Audit Logs: https://cloud.google.com/logging/docs/audit
