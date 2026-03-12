---
tags: [cloud, aws, oci, gcp, architecture, daily]
---
[[Home]]

# Cloud Engineer Magazine (2026-03-12)
#cloud #aws #oci #gcp #architecture #daily

## 1) 今日のアプリ
**SaaS型「予約制クリニックの空き枠最適化」アプリ**
- 患者がWeb/モバイルから予約
- 無断キャンセルや直前キャンセルの空き枠を、待機患者へ自動提案
- 管理者が診療科・医師別の稼働率を確認

> 今日の視点: **AWS中心の実装方針**を先に決め、OCI/GCPへ移植しやすい形に落とす

---

## 2) 要件整理（機能要件/非機能要件）
### 機能要件
- 予約作成/変更/キャンセル
- 待機リスト登録、空き枠発生時の一斉通知
- 通知からのワンクリック予約確定
- 管理画面で稼働率・キャンセル率の可視化

### 非機能要件
- **可用性**: 診療時間帯の予約APIはマルチAZ、目標99.95%
- **性能**: 予約検索P95 < 250ms、通知遅延 < 60秒
- **セキュリティ**: 最小権限IAM、PII暗号化、監査ログ、WAF
- **コスト**: 平常時は低コスト、通知バースト時のみ自動スケール

---

## 3) 推奨アーキテクチャ（なぜその構成か）
**API + トランザクションDB + イベント駆動通知 + 分析分離**
- 予約確定はRDBで厳密整合（重複予約防止の一意制約）
- キャンセル発生はイベント化し、通知処理を非同期化
- 分析はOLTPから分離（本番予約APIを守る）

**この構成を選ぶ理由**
- 予約業務は「整合性」が最優先（NoSQL単体よりRDBが安全）
- 通知はスパイクが大きく、キュー/PubSubで吸収すると安定
- 分析を別系統にするとピーク時でも予約UXを落としにくい

---

## 4) クラウド別実装マップ
### AWS での実装サービス
- フロント: **Amazon CloudFront** + **S3 (静的配信)**
- API: **Amazon API Gateway** + **AWS Lambda**
- 予約DB: **Amazon Aurora PostgreSQL**
- イベント: **Amazon EventBridge**
- キュー/ワーカー: **Amazon SQS** + **Lambda**
- 通知: **Amazon SNS**（メール/SMS連携）
- 認証: **Amazon Cognito**
- 監視/監査: **Amazon CloudWatch**, **AWS CloudTrail**
- セキュリティ: **AWS WAF**, **AWS KMS**, **AWS Secrets Manager**

### OCI での実装サービス
- フロント: **OCI Object Storage (Static Website)** + **OCI CDN**
- API: **OCI API Gateway** + **OCI Functions**
- 予約DB: **OCI Base Database Service (PostgreSQL互換構成を選択)**
- イベント: **OCI Events**
- キュー/ワーカー: **OCI Queue** + **OCI Functions**
- 通知: **OCI Notifications**
- 認証: **OCI IAM**
- 監視/監査: **OCI Monitoring**, **OCI Logging**, **OCI Audit**
- セキュリティ: **OCI Web Application Firewall**, **OCI Vault**

### GCP での実装サービス
- フロント: **Cloud CDN** + **Cloud Storage**
- API: **API Gateway** + **Cloud Run**
- 予約DB: **Cloud SQL for PostgreSQL**
- イベント: **Eventarc**
- キュー/ワーカー: **Pub/Sub** + **Cloud Run Jobs/Service**
- 通知: **Pub/Sub + 外部通知プロバイダ連携**
- 認証: **Identity Platform** + **Cloud IAM**
- 監視/監査: **Cloud Monitoring**, **Cloud Logging**, **Cloud Audit Logs**
- セキュリティ: **Cloud Armor**, **Cloud KMS**, **Secret Manager**

**トレードオフ（短評）**
- Lambda/Functionsは短時間処理でコスパ良。長時間処理はCloud Run系やコンテナ基盤が有利。
- EventBridge / OCI Events / Eventarc は疎結合化に有効だが、再試行設計（重複受信前提）が必須。
- Aurora/Cloud SQL系は整合性が強い一方、急激な読み取り増にはキャッシュ層追加が必要。

---

## 5) システム構成図（Mermaid）
```mermaid
flowchart LR
  U[患者アプリ/管理Web] --> CDN[CDN + Static Hosting]
  CDN --> APIGW[API Gateway]
  APIGW --> APP[予約API (Serverless/Container)]
  APP --> DB[(PostgreSQL)]
  APP --> EVT[Event Bus]
  EVT --> Q[Queue/PubSub]
  Q --> WK[通知ワーカー]
  WK --> NTF[Email/SMS通知]
  APP --> OBS[Monitoring/Logging/Audit]
```

---

## 6) データフロー/認証・認可/監視運用の要点
- **データフロー**: 予約確定時にDBトランザクション完了後イベント発行（Outboxパターン推奨）
- **認証・認可**: 患者/スタッフ/管理者でロール分離、管理APIはMFA必須
- **最小権限**: 実行ロールはDB・キュー・秘密情報アクセスを用途別に分割
- **監視**: 
  - SLI: 予約成功率、通知遅延、重複予約エラー率
  - アラート: 5xx急増、DB接続飽和、キュー滞留時間

---

## 7) コスト最適化ポイント（初期・成長期）
### 初期
- APIはサーバレス中心でアイドルコストを削減
- DBは最小インスタンス + 自動バックアップ
- 通知はチャネルを絞る（まずメール中心）

### 成長期
- 読み取り集中にキャッシュ（予約枠参照）導入
- 通知ワーカーをバッチ化し外部通知コストを圧縮
- ログ保持期間を運用要件に合わせて短縮/アーカイブ

---

## 8) 障害時の設計（DR/バックアップ/フェイルオーバー）
- **RPO/RTO例**: RPO 5分、RTO 30分
- DBは自動バックアップ + ポイントインタイムリカバリ
- マルチAZ構成を標準、リージョンDRは段階導入
- キューは再処理可能設計（冪等キー必須）
- フェイルオーバー演習を月1で実施（通知経路含む）

---

## 9) 学習ポイント（今日覚えるクラウド機能）
- **AWS EventBridge**: イベントルーティングと再試行ポリシー
- **OCI Queue**: 非同期ワークロードの平準化
- **GCP Eventarc**: イベント駆動でCloud Run連携
- **共通**: IAM最小権限 + KMS/Vaultで秘密情報管理

---

## 10) 30〜60分ミニ演習
1. 予約APIの「重複予約防止」テーブル設計を書く（ユニーク制約）
2. `予約キャンセル -> 通知送信` のイベントスキーマをJSONで定義
3. 失敗時再試行（最大3回）とDLQ方針を設計
4. IAMポリシーを3ロール（API/Worker/Ops）で分離してみる

---

## 11) 公式ドキュメント参照リンク（AWS/OCI/GCP）
### AWS
- Well-Architected Framework: https://docs.aws.amazon.com/wellarchitected/latest/framework/welcome.html
- Amazon API Gateway: https://docs.aws.amazon.com/apigateway/
- AWS Lambda: https://docs.aws.amazon.com/lambda/
- Amazon Aurora: https://docs.aws.amazon.com/aurora/
- Amazon EventBridge: https://docs.aws.amazon.com/eventbridge/
- Amazon SQS: https://docs.aws.amazon.com/sqs/
- Amazon Cognito: https://docs.aws.amazon.com/cognito/
- AWS WAF: https://docs.aws.amazon.com/waf/

### OCI
- OCI Architecture Center: https://docs.oracle.com/en-us/iaas/Content/Architecture/Concepts/architecturecenter.htm
- OCI API Gateway: https://docs.oracle.com/en-us/iaas/Content/APIGateway/home.htm
- OCI Functions: https://docs.oracle.com/en-us/iaas/Content/Functions/home.htm
- OCI Queue: https://docs.oracle.com/en-us/iaas/Content/queue/home.htm
- OCI Events: https://docs.oracle.com/en-us/iaas/Content/Events/home.htm
- OCI Notifications: https://docs.oracle.com/en-us/iaas/Content/Notification/home.htm
- OCI Vault: https://docs.oracle.com/en-us/iaas/Content/KeyManagement/home.htm

### GCP
- Google Cloud Architecture Framework: https://docs.cloud.google.com/architecture/framework
- API Gateway: https://docs.cloud.google.com/api-gateway/docs
- Cloud Run: https://docs.cloud.google.com/run/docs
- Cloud SQL: https://docs.cloud.google.com/sql/docs
- Pub/Sub: https://docs.cloud.google.com/pubsub/docs
- Eventarc: https://docs.cloud.google.com/eventarc/docs
- Cloud IAM: https://docs.cloud.google.com/iam/docs
- Cloud Armor: https://docs.cloud.google.com/armor/docs
