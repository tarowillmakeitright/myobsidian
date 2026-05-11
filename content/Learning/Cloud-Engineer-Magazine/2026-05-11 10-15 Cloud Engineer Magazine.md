---
tags: [cloud, aws, oci, gcp, architecture, daily]
---
[[Home]]

# Cloud Engineer Magazine（2026-05-11）

## 1) 今日のアプリ
**在庫連動フラッシュセール基盤（EC向け）**  
短時間（15〜30分）のセールで、在庫数・価格をリアルタイム反映しつつ、アクセス急増に耐えるアプリ。

---

## 2) 要件整理
### 機能要件
- 商品一覧・詳細表示
- セール開始/終了のスケジュール実行
- 在庫引当（先着順、二重購入防止）
- 注文作成と決済連携（外部決済は非同期通知）
- 管理画面（在庫補充、価格変更）

### 非機能要件
- **可用性**: セール中でもSPOFなし、マルチAZ相当
- **性能**: p95 300ms以下（閲覧API）、急激なQPS増加に自動追従
- **セキュリティ**: 最小権限IAM、WAF、暗号化（保存時/転送時）
- **コスト**: 平常時は低コスト、ピーク時のみスケール

---

## 3) 推奨アーキテクチャ（なぜその構成か）
**方針: 読み取り最適化 + 書き込み整合性確保**
- 商品閲覧はCDN + キャッシュで吸収（高トラフィック対策）
- 在庫更新はトランザクション整合性を重視（DB条件更新/ロック）
- 注文・通知はキュー分離でスパイク平準化
- APIはマネージド実行基盤（サーバレス/コンテナ）で自動スケール

**理由**
- フラッシュセールは「読多書少」になりやすい
- 在庫は競合が集中するため、単純キャッシュ書き込みは危険
- 非同期化でユーザー応答を短く保ち、バックエンドを保護

---

## 4) クラウド別実装マップ
### AWS
- エッジ: **CloudFront**, **AWS WAF**
- API: **Amazon API Gateway** + **AWS Lambda**（または ECS Fargate）
- 在庫/注文DB: **Amazon DynamoDB**（条件付き書き込み）または **Amazon Aurora**
- キュー/非同期: **Amazon SQS**, **Amazon EventBridge**
- 認証: **Amazon Cognito**
- 監視: **Amazon CloudWatch**, **AWS X-Ray**, **CloudTrail**

### OCI
- エッジ: **OCI CDN**, **OCI Web Application Firewall**
- API: **OCI API Gateway** + **OCI Functions**（または OKE）
- 在庫/注文DB: **Autonomous Database** または **MySQL HeatWave**
- キュー/非同期: **OCI Queue**, **OCI Events**, **OCI Streaming**
- 認証: **OCI IAM**
- 監視: **OCI Monitoring**, **Logging**, **Audit**

### GCP
- エッジ: **Cloud CDN**, **Cloud Armor**
- API: **API Gateway** + **Cloud Run**（または GKE）
- 在庫/注文DB: **Cloud Spanner** または **Cloud SQL**
- キュー/非同期: **Pub/Sub**, **Eventarc**, **Cloud Tasks**
- 認証: **Cloud IAM**, （エンドユーザーは Identity Platform 検討）
- 監視: **Cloud Monitoring**, **Cloud Logging**, **Cloud Trace**, **Cloud Audit Logs**

**トレードオフ（要点）**
- DynamoDB/Spanner: 高スケール・運用軽量、設計時にアクセスパターン設計が重要
- Aurora/Cloud SQL/ADB: RDBで実装しやすいが、急激な水平スケールは設計工夫が必要
- Lambda/Functions/Cloud Run: 運用楽。極低遅延・常時高負荷ならコンテナ常駐も検討

---

## 5) システム構成図（Mermaid）
```mermaid
flowchart LR
  U[User] --> CDN[CDN + WAF]
  CDN --> API[API Gateway]
  API --> APP[App Service\n(Lambda/Functions/Cloud Run)]
  APP --> CACHE[Cache]
  APP --> DB[(Inventory/Order DB)]
  APP --> Q[Queue/Event Bus]
  Q --> WK[Worker Service]
  WK --> DB
  APP --> OBS[Monitoring/Logging/Trace]
```

---

## 6) データフロー / 認証・認可 / 監視運用の要点
### データフロー
1. 商品閲覧: CDN→API→キャッシュ→DB（キャッシュミス時）
2. 注文: APIで在庫条件更新（`stock > 0`）→成功時に注文イベント発行
3. 後続処理: ワーカーが決済確定・通知・配送連携

### 認証・認可
- 管理者・顧客の権限分離（RBAC）
- サービス間はIAMロール/サービスアカウントで短期認証
- KMS系で暗号鍵管理、シークレットは専用サービス保管

### 監視運用
- RED/USEメトリクス（Rate, Errors, Duration / Utilization, Saturation, Errors）
- SLO例: 注文API成功率 99.9%
- 監査ログ（変更操作、権限変更）を必ず有効化

---

## 7) コスト最適化ポイント（初期・成長期）
### 初期
- サーバレス中心で固定費削減
- 低頻度バッチはイベント駆動に寄せる
- CDNキャッシュTTL最適化でオリジン課金削減

### 成長期
- ホットパスのみ常駐コンテナ化（レイテンシ安定）
- DBの読み取り分離/レプリカ活用
- ログ保持期間を用途別に短縮・階層化

---

## 8) 障害時の設計（DR/バックアップ/フェイルオーバー）
- **リージョン内冗長**: マルチAZ相当を基本
- **バックアップ**: DB自動バックアップ + 定期リストア訓練
- **フェイルオーバー**: DNS/グローバルLBで段階切替
- **イベント再処理**: キューDLQ（デッドレター）と再実行手順を準備
- **RTO/RPOを明文化**: 例）RTO 30分 / RPO 5分

---

## 9) 学習ポイント（今日覚えるクラウド機能）
- 条件付き書き込みで在庫超過販売を防ぐ設計
- API保護（WAF + レート制御 + Bot対策）
- 非同期分離（Queue/PubSub）でピーク吸収
- 監査ログを運用初日から有効化

---

## 10) 30〜60分ミニ演習
1. 任意クラウドで「商品閲覧API」と「注文API」を2本作る
2. 注文APIに在庫条件チェック（0以下なら失敗）を実装
3. 注文成功時にキューへイベント投入
4. 失敗イベントをDLQへ送る設定を追加
5. ダッシュボードに `成功率/レイテンシ/エラー率` を表示

**完了条件**
- 同時10リクエストで在庫がマイナスにならない
- エラー時にDLQで追跡できる

---

## 11) 公式ドキュメント参照リンク（AWS/OCI/GCP）
### AWS
- Well-Architected Framework: https://docs.aws.amazon.com/wellarchitected/latest/framework/welcome.html
- Amazon CloudFront: https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/Introduction.html
- AWS WAF: https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html
- API Gateway: https://docs.aws.amazon.com/apigateway/latest/developerguide/welcome.html
- AWS Lambda: https://docs.aws.amazon.com/lambda/latest/dg/welcome.html
- DynamoDB 条件式: https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Expressions.ConditionExpressions.html
- SQS: https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/welcome.html

### OCI
- OCI Architecture Center: https://docs.oracle.com/en-us/iaas/Content/Architecture/Concepts/architecturecenter.htm
- OCI CDN: https://docs.oracle.com/en-us/iaas/Content/CDN/Concepts/cdnoverview.htm
- OCI WAF: https://docs.oracle.com/en-us/iaas/Content/WAF/Concepts/wafoverview.htm
- OCI API Gateway: https://docs.oracle.com/en-us/iaas/Content/APIGateway/Concepts/apigatewayoverview.htm
- OCI Functions: https://docs.oracle.com/en-us/iaas/Content/Functions/Concepts/functionsoverview.htm
- OCI Queue: https://docs.oracle.com/en-us/iaas/Content/queue/overview.htm
- OCI Monitoring: https://docs.oracle.com/en-us/iaas/Content/Monitoring/home.htm

### GCP
- Google Cloud Architecture Framework: https://docs.cloud.google.com/architecture/framework
- Cloud CDN: https://docs.cloud.google.com/cdn/docs/overview
- Cloud Armor: https://docs.cloud.google.com/armor/docs/overview
- API Gateway: https://docs.cloud.google.com/api-gateway/docs
- Cloud Run: https://docs.cloud.google.com/run/docs/overview/what-is-cloud-run
- Pub/Sub: https://docs.cloud.google.com/pubsub/docs/overview
- Cloud Monitoring: https://docs.cloud.google.com/monitoring/docs
- Cloud Audit Logs: https://docs.cloud.google.com/logging/docs/audit
