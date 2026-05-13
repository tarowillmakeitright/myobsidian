---
tags: [cloud, aws, oci, gcp, architecture, daily]
---

# Cloud Engineer Magazine (2026-05-13)
[[Home]]

## 1) 今日のアプリ
**現場向け写真付き設備点検アプリ（モバイル）**

- 作業員がスマホで設備写真と点検結果を登録
- オフライン時は一時保存し、復帰後に同期
- 異常検知時は即時アラート
- 監督者はダッシュボードで進捗/不具合を確認

> 今日の視点: **マルチクラウド比較（AWS/OCI/GCP で同等構成）**

## 2) 要件整理（機能要件/非機能要件）

### 機能要件
- 点検チェックリスト入力（必須項目バリデーション）
- 写真アップロード（複数枚、タイムスタンプ付き）
- 異常フラグ時の通知（メール/チャット連携）
- 拠点・設備・担当者別の検索

### 非機能要件
- **可用性**: 業務時間中の停止を最小化（マルチAZ/マルチAD前提）
- **性能**: API P95 < 300ms、画像アップロード体感 < 2秒開始
- **セキュリティ**: 最小権限IAM、保存時暗号化、監査ログ、WAF
- **コスト**: 初期はサーバレス中心、利用増でコンテナ常時稼働へ段階移行

## 3) 推奨アーキテクチャ（なぜその構成か）

- フロントは CDN + 静的ホスティングで高速配信
- API は Managed API Gateway + Functions で初期コストを圧縮
- 画像はオブジェクトストレージへ直接アップロード（署名付きURL）
- 点検データはマネージドRDB（整合性重視）
- 非同期処理（サムネ生成/通知/集計）は Queue + Function

**理由**
1. 点検業務はピークが偏るため、サーバレスが料金効率よい
2. 写真処理を非同期化して操作体感を改善
3. IAM + KMS + 監査ログを標準構成にし、後付けセキュリティを避ける

## 4) クラウド別実装マップ

### AWS
- フロント: S3 + CloudFront
- 認証: Amazon Cognito
- API: Amazon API Gateway + AWS Lambda
- DB: Amazon Aurora Serverless v2 (PostgreSQL)
- 画像保存: Amazon S3（SSE-KMS）
- 非同期: Amazon SQS + Lambda
- 監視: Amazon CloudWatch / AWS X-Ray / CloudTrail
- 保護: AWS WAF

**トレードオフ**: DynamoDB なら運用は軽いが、点検帳票系の複雑集計は Aurora の方がSQL資産を活かしやすい。

### OCI
- フロント: Object Storage + CDN
- 認証: OCI Identity Domains
- API: OCI API Gateway + OCI Functions
- DB: Autonomous Transaction Processing (ATP)
- 画像保存: OCI Object Storage（暗号化）
- 非同期: OCI Queue + Functions
- 監視: OCI Monitoring / Logging / Logging Analytics / Audit
- 保護: OCI WAF

**トレードオフ**: ATP は運用自動化が強い一方、細かいDBチューニング自由度は自己管理DBより低い。

### GCP
- フロント: Cloud Storage + Cloud CDN
- 認証: Identity Platform（または Firebase Authentication）
- API: API Gateway + Cloud Run Functions（または Cloud Functions）
- DB: Cloud SQL for PostgreSQL
- 画像保存: Cloud Storage（CMEK可）
- 非同期: Pub/Sub + Cloud Run Functions
- 監視: Cloud Monitoring / Cloud Logging / Cloud Trace / Cloud Audit Logs
- 保護: Cloud Armor

**トレードオフ**: Firestore は開発速度が高いが、RDB前提の帳票/監査要件では Cloud SQL が扱いやすい。

## 5) システム構成図（Mermaid）

```mermaid
flowchart LR
  U[作業員モバイルアプリ] --> CDN[CDN + Static Hosting]
  U --> IDP[IdP / User Auth]
  U --> APIGW[API Gateway]
  U --> OBJ[Object Storage(写真)]

  APIGW --> FN[Functions]
  FN --> DB[(Managed PostgreSQL)]
  FN --> Q[Queue]
  Q --> W[Worker Function]
  W --> OBJ
  W --> N[Notification]

  APIGW --> MON[Monitoring/Logs/Trace]
  FN --> MON
  DB --> BAK[Backup/DR Copy]
```

## 6) データフロー/認証・認可/監視運用の要点

- **データフロー**: アプリは認証後、APIから署名付きURLを取得し写真を直接オブジェクトストレージへ保存。メタデータのみAPIで登録。
- **認証**: OpenID Connect/OAuth2 ベース。短命トークン + リフレッシュトークン管理。
- **認可**: RBAC（作業員/監督者/管理者）をIAMロールで分離。DB接続権限も職務単位で分割。
- **監視運用**: SLI（成功率/遅延/キュー滞留）を定義し、SLO違反予兆でアラート。監査ログは改ざん耐性ストレージへ長期保管。

## 7) コスト最適化ポイント（初期・成長期）

### 初期
- Functions と小さめDB構成で固定費を下げる
- オブジェクトストレージのライフサイクルで低頻度層へ自動移行
- ログ保持期間を業務要件に合わせて短中期を分離

### 成長期
- 高トラフィックAPIをコンテナ常時稼働へ移行（コールドスタート回避）
- DBはリードレプリカ/接続プール導入で効率化
- CDNキャッシュ戦略最適化でオリジン転送料を削減

## 8) 障害時の設計（DR/バックアップ/フェイルオーバー）

- RTO/RPO を明文化（例: RTO 60分, RPO 15分）
- DB自動バックアップ + PITR有効化
- オブジェクトストレージはリージョン間レプリケーション
- IaC（Terraform等）で復旧手順をコード化
- 定期DR訓練（四半期）で手順の実効性を検証

## 9) 学習ポイント（今日覚えるクラウド機能）

- **AWS**: API Gateway の認可統合（Cognito/JWT Authorizer）
- **OCI**: API Gateway + Functions + Queue のイベント連携
- **GCP**: Pub/Sub と Cloud Run Functions の非同期パターン

## 10) 30〜60分ミニ演習

1. 1クラウド選択（AWS/OCI/GCP）
2. 「点検登録API」1本だけを実装
   - 認証付きエンドポイント
   - 署名付きURL発行
   - メタデータをDBにINSERT
3. 監視メトリクスを3つ可視化
   - APIレイテンシ
   - エラー率
   - キュー滞留（または非同期処理遅延）

**ゴール**: 「写真本体はストレージ直送、APIはメタデータ中心」の設計意図を体験する。

## 11) 公式ドキュメント参照リンク（AWS/OCI/GCP）

### AWS
- API Gateway: https://docs.aws.amazon.com/apigateway/
- Lambda: https://docs.aws.amazon.com/lambda/
- Aurora: https://docs.aws.amazon.com/aurora/
- S3: https://docs.aws.amazon.com/s3/
- Cognito: https://docs.aws.amazon.com/cognito/
- WAF: https://docs.aws.amazon.com/waf/
- CloudWatch: https://docs.aws.amazon.com/cloudwatch/

### OCI
- API Gateway: https://docs.oracle.com/en-us/iaas/Content/APIGateway/home.htm
- Functions: https://docs.oracle.com/en-us/iaas/Content/Functions/home.htm
- Queue: https://docs.oracle.com/en-us/iaas/Content/queue/home.htm
- Object Storage: https://docs.oracle.com/en-us/iaas/Content/Object/home.htm
- Autonomous Database (ATP): https://docs.oracle.com/en-us/iaas/autonomous-database-serverless/doc/
- WAF: https://docs.oracle.com/en-us/iaas/Content/WAF/home.htm
- Monitoring: https://docs.oracle.com/en-us/iaas/Content/Monitoring/home.htm

### GCP
- API Gateway: https://docs.cloud.google.com/api-gateway/docs
- Cloud Run functions: https://docs.cloud.google.com/run/docs/write-functions
- Cloud SQL: https://docs.cloud.google.com/sql/docs
- Cloud Storage: https://docs.cloud.google.com/storage/docs
- Pub/Sub: https://docs.cloud.google.com/pubsub/docs
- Cloud Armor: https://docs.cloud.google.com/armor/docs
- Cloud Monitoring: https://docs.cloud.google.com/monitoring/docs
