---
tags: [cloud, aws, oci, gcp, architecture, daily]
---

# Daily Cloud Engineer Magazine (2026-04-28)
[[Home]]

## 1) 今日のアプリ
**訪日観光向け「リアルタイム混雑ナビ」アプリ**
- 観光地・駅・商業施設の混雑度を5分間隔で可視化
- ユーザー位置に応じて「空いている代替スポット」を提案
- 事業者向けにダッシュボード（時間帯別混雑、来訪傾向）を提供

> 今日の視点: **マルチクラウド比較（AWS / OCI / GCP）**

---

## 2) 要件整理（機能要件/非機能要件）
### 機能要件
- モバイルAPI（混雑取得、スポット検索、通知設定）
- ストリーミング取込（センサー/アプリイベント）
- 混雑スコア算出（準リアルタイム + バッチ再学習）
- 管理者ダッシュボード

### 非機能要件
- **可用性**: API 99.9%以上、リージョン障害時はRTO 30分以内
- **性能**: API P95 < 300ms、ピーク同時接続 50k
- **セキュリティ**: OIDC認証、最小権限IAM、保存時暗号化、監査ログ
- **コスト**: 初期はサーバレス中心、成長時に常時稼働へ段階移行

---

## 3) 推奨アーキテクチャ（なぜその構成か）
**イベント駆動 + マネージドDB + CDN配信**
- 取込はマネージドストリームで吸収し、突発トラフィックに追従
- API層はオートスケール（またはサーバレス）で運用負荷を低減
- 読み取り中心データはキャッシュ＋CDNで低遅延化
- 分析はDWH連携で運用系と分離し、性能干渉を防ぐ

**トレードオフ（例）**
- サーバレス: 初期コスト最適だが高負荷時に常時実行より割高化し得る
- マネージドRDB: 運用容易だが、厳密な低レイテンシ要件ではNoSQL/キャッシュ設計が重要

---

## 4) クラウド別実装マップ
### AWS
- API: **Amazon API Gateway + AWS Lambda**
- 認証: **Amazon Cognito**
- ストリーム: **Amazon Kinesis Data Streams**
- DB: **Amazon Aurora Serverless v2**（トランザクション）+ **Amazon ElastiCache**
- 分析: **Amazon S3 + Amazon Athena**
- 監視: **Amazon CloudWatch + AWS X-Ray + CloudTrail**

### OCI
- API: **OCI API Gateway + OCI Functions**
- 認証: **OCI IAM (Identity Domains)**
- ストリーム: **OCI Streaming**
- DB: **OCI Autonomous Database** + **OCI Cache**（必要に応じ）
- 分析: **OCI Object Storage + OCI Data Flow/Analytics**
- 監視: **OCI Monitoring + Logging + Audit**

### GCP
- API: **API Gateway + Cloud Run**
- 認証: **Identity Platform / IAM**
- ストリーム: **Pub/Sub**
- DB: **Cloud SQL**（またはFirestore）+ **Memorystore**
- 分析: **Cloud Storage + BigQuery**
- 監視: **Cloud Monitoring + Cloud Logging + Cloud Trace**

---

## 5) システム構成図（Mermaid）
```mermaid
flowchart LR
  U[モバイルアプリ] --> CDN[CDN/WAF]
  CDN --> API[API Gateway]
  API --> AUTH[OIDC認証]
  API --> APP[App Service\n(Lambda/Functions/Cloud Run)]
  APP --> RDB[(Managed DB)]
  APP --> CACHE[(Cache)]
  EVT[センサー/イベント] --> STRM[Streaming]
  STRM --> PROC[Stream Processor]
  PROC --> RDB
  PROC --> DWH[(DWH/Object Storage)]
  OPS[監視/監査] --> API
  OPS --> APP
  OPS --> STRM
```

---

## 6) データフロー/認証・認可/監視運用の要点
- **データフロー**: イベント取込→ストリーム処理→混雑スコア更新→API配信→DWH集計
- **認証・認可**: OIDCでユーザー認証、バックエンドはIAMロールでサービス間認可（長期鍵を避ける）
- **監視運用**:
  - SLI: API成功率、P95レイテンシ、消費ラグ（ストリーム）
  - アラート: エラーレート閾値、DB接続飽和、DLQ増加
  - 監査: すべての管理操作を監査ログへ

---

## 7) コスト最適化ポイント（初期・成長期）
### 初期
- サーバレス採用（リクエスト課金）
- ストレージはライフサイクルで低頻度層へ自動移行
- ダッシュボード更新間隔を5〜10分にしてクエリ費削減

### 成長期
- 常時高負荷APIはコンテナ常駐化（Cloud Run min instances / ECS/Fargate相当設計）
- DBはリードレプリカ/キャッシュ強化でスケール
- 分析クエリはパーティション・クラスタリングでスキャン量削減

---

## 8) 障害時の設計（DR/バックアップ/フェイルオーバー）
- **DR方針**: マルチAZを基本、重要データはクロスリージョン複製
- **バックアップ**: DB自動バックアップ + PITR、有効期限付きスナップショット
- **フェイルオーバー**:
  - APIはDNS/グローバルLBで待機系へ切替
  - 非同期処理は再実行可能（冪等キー）
  - 復旧演習を四半期ごとに実施（Runbook更新）

---

## 9) 学習ポイント（今日覚えるクラウド機能）
1. **イベント駆動設計**でピーク吸収する基本パターン
2. **最小権限IAM + 短期認証情報**で鍵管理リスクを下げる
3. **運用系DBと分析系DWHの分離**で性能とコストを両立

---

## 10) 30〜60分ミニ演習
**演習: 「混雑投稿API」最小構成を設計する**
- 30分:
  1. APIエンドポイント `POST /crowd-events` を定義
  2. 認証方式（OIDC）とIAMロール分離（API実行ロール/DB書込ロール）を図示
  3. 失敗時のDLQ設計を追加
- 追加30分:
  4. AWS/OCI/GCPそれぞれで対応サービスにマッピング
  5. P95 300msを守るためのボトルネック3点と対策を書く

---

## 11) 公式ドキュメント参照リンク（AWS/OCI/GCP）
### AWS
- Well-Architected Framework  
  https://docs.aws.amazon.com/wellarchitected/latest/framework/welcome.html
- Amazon API Gateway  
  https://docs.aws.amazon.com/apigateway/
- AWS Lambda  
  https://docs.aws.amazon.com/lambda/
- Amazon Kinesis Data Streams  
  https://docs.aws.amazon.com/streams/latest/dev/introduction.html
- Amazon Cognito  
  https://docs.aws.amazon.com/cognito/

### OCI
- OCI Architecture Center  
  https://docs.oracle.com/en-us/iaas/Content/Architecture/Concepts/architecturecenter.htm
- OCI API Gateway  
  https://docs.oracle.com/en-us/iaas/Content/APIGateway/home.htm
- OCI Functions  
  https://docs.oracle.com/en-us/iaas/Content/Functions/home.htm
- OCI Streaming  
  https://docs.oracle.com/en-us/iaas/Content/Streaming/home.htm
- OCI Monitoring / Logging / Audit  
  https://docs.oracle.com/en-us/iaas/Content/Monitoring/home.htm

### GCP
- Google Cloud Architecture Framework  
  https://docs.cloud.google.com/architecture/framework
- API Gateway  
  https://docs.cloud.google.com/api-gateway/docs
- Cloud Run  
  https://docs.cloud.google.com/run/docs
- Pub/Sub  
  https://docs.cloud.google.com/pubsub/docs
- BigQuery  
  https://docs.cloud.google.com/bigquery/docs
- Cloud Monitoring  
  https://docs.cloud.google.com/monitoring/docs
