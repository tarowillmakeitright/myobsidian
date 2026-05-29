---
tags: [cloud, aws, oci, gcp, architecture, daily]
---

# Cloud Engineer Magazine — 2026-05-29
[[Home]]

## 1) 今日のアプリ
**マルチテナント型「フィールド点検レポートSaaS」**

- スマホで設備写真・チェックリスト・音声メモを登録
- オフライン時は端末に一時保存、オンライン復帰で同期
- 管理者はダッシュボードで異常件数・対応SLAを可視化

> 今日は **マルチクラウド比較視点**。実装は各クラウドで単独完結できる構成を揃え、将来の移行性も意識。

---

## 2) 要件整理
### 機能要件
- 点検データ登録（画像、テキスト、音声）
- テナント分離（会社ごと）
- しきい値超過時の通知（メール/Chat）
- 日次レポート生成

### 非機能要件
- **可用性**: 月間99.9%以上、リージョン障害時にRTO 4時間以内
- **性能**: API P95 < 300ms、画像アップロード 10MB/件
- **セキュリティ**: 最小権限IAM、保存時暗号化、監査ログ必須
- **コスト**: 初期は従量課金優先、成長期にSavings/Committed Useへ移行

---

## 3) 推奨アーキテクチャ（なぜその構成か）
**API + オブジェクトストレージ + マネージドDB + 非同期処理 + 監視** の定番分離。

- 同期系（ユーザー操作）は低遅延APIへ集中
- 重い処理（画像解析/レポート生成）はキュー経由で非同期化
- 添付ファイルはDBに入れずオブジェクトストレージへ分離（性能/コスト/拡張性）
- 認証はマネージドIdP連携で実装負荷を下げ、監査証跡を取りやすくする

---

## 4) クラウド別実装マップ
### AWS
- フロント/API: **Amazon API Gateway + AWS Lambda**
- 認証: **Amazon Cognito**
- データ: **Amazon Aurora Serverless v2 (PostgreSQL互換)**
- ファイル: **Amazon S3**（署名付きURLアップロード）
- 非同期: **Amazon SQS + Lambda**
- 監視: **Amazon CloudWatch + AWS CloudTrail**

**トレードオフ**: Lambdaは運用軽いがコールドスタート考慮。高負荷安定時はECS/Fargateも候補。

### OCI
- フロント/API: **API Gateway + Functions**
- 認証: **OCI IAM Identity Domains**
- データ: **Autonomous Database (Transaction Processing)**
- ファイル: **Object Storage**
- 非同期: **OCI Queue + Functions**
- 監視: **Monitoring + Logging + Audit**

**トレードオフ**: Autonomous DBは運用容易だが、細かなチューニング自由度は自己管理DBに劣る。

### GCP
- フロント/API: **API Gateway + Cloud Run**
- 認証: **Identity Platform**（またはCloud Identity連携）
- データ: **Cloud SQL for PostgreSQL**
- ファイル: **Cloud Storage**
- 非同期: **Pub/Sub + Cloud Run jobs/worker**
- 監視: **Cloud Monitoring + Cloud Logging + Cloud Audit Logs**

**トレードオフ**: Cloud Runはコンテナ柔軟性が高い。短時間軽量処理中心ならFunctionsも検討余地。

---

## 5) システム構成図（Mermaid）
```mermaid
flowchart LR
  U[Field User App] -->|JWT| AGW[API Gateway]
  AGW --> APP[App Service\n(Lambda/Functions/Cloud Run)]
  APP --> DB[(PostgreSQL/Autonomous DB)]
  APP --> OBJ[(Object Storage)]
  APP --> Q[Queue / PubSub]
  Q --> W[Async Worker]
  W --> DB
  W --> OBJ
  APP --> MON[Monitoring/Logging/Audit]
```

---

## 6) データフロー/認証・認可/監視運用の要点
- **データフロー**: クライアントはAPIでメタデータ登録→署名URL発行→直接オブジェクト保存→完了イベントで非同期処理
- **認証・認可**:
  - OIDC/OAuth2ベース
  - テナントIDをトークンクレームに保持
  - DBアクセスはテナントスコープを強制（行レベル条件）
  - サービス間は短期資格情報（IAMロール/サービスアカウント）
- **監視運用**:
  - SLI: API成功率、P95遅延、キュー滞留、DB接続数
  - アラート: エラー率閾値、DLQ増加、ストレージ失敗
  - 監査: 管理APIとIAM変更は監査ログを長期保管

---

## 7) コスト最適化ポイント（初期・成長期）
### 初期
- サーバレス中心でアイドルコスト削減
- ストレージはライフサイクルルールで低頻度層へ自動移行
- 監視ログは保持期間を短めに設計（要件に合わせる）

### 成長期
- 予約/コミット（Savings Plans, OCI Commit, GCP CUD）検討
- 高頻度クエリ向けにインデックス最適化、無駄なクロスAZ/リージョン転送を削減
- 非同期処理のバッチ化で起動回数を抑制

---

## 8) 障害時の設計（DR/バックアップ/フェイルオーバー）
- DBは自動バックアップ + PITR有効化
- オブジェクトストレージはバージョニング有効化
- IaC（Terraform等）で再作成可能にする
- DRレベル:
  - 通常: 単一リージョン内冗長
  - 強化: セカンダリリージョンにバックアップ複製、DNS/Traffic切替手順をRunbook化
- 定期的に復旧訓練（四半期）を実施

---

## 9) 学習ポイント（今日覚えるクラウド機能）
1. **署名付きURL**で大容量アップロードをAPIサーバー経由にしない設計
2. **キュー + ワーカー**でスパイク耐性を作る
3. **監査ログ（CloudTrail/Audit Logs/Audit）**を必ず有効化する
4. **最小権限IAM**は「人」「アプリ」「運用」を分離して設計する

---

## 10) 30〜60分ミニ演習
1. 任意クラウド1つ選ぶ（AWS/OCI/GCP）
2. API + Object Storage + Queue を最小構成で作る
3. 「画像アップロード完了イベント→ワーカー実行」まで通す
4. 監視で以下を可視化:
   - APIエラー率
   - キュー滞留数
   - ワーカー失敗数
5. 最後にIAM権限を見直し、「不要権限を3つ削る」

---

## 11) 公式ドキュメント参照リンク（AWS/OCI/GCP）
### AWS
- API Gateway: https://docs.aws.amazon.com/apigateway/
- Lambda: https://docs.aws.amazon.com/lambda/
- S3: https://docs.aws.amazon.com/s3/
- Aurora: https://docs.aws.amazon.com/aurora/
- SQS: https://docs.aws.amazon.com/AWSSimpleQueueService/
- Cognito: https://docs.aws.amazon.com/cognito/
- CloudWatch: https://docs.aws.amazon.com/cloudwatch/
- CloudTrail: https://docs.aws.amazon.com/cloudtrail/

### OCI
- API Gateway: https://docs.oracle.com/en-us/iaas/Content/APIGateway/home.htm
- Functions: https://docs.oracle.com/en-us/iaas/Content/Functions/home.htm
- Object Storage: https://docs.oracle.com/en-us/iaas/Content/Object/home.htm
- Autonomous Database: https://docs.oracle.com/en-us/iaas/autonomous-database-serverless/doc/
- Queue: https://docs.oracle.com/en-us/iaas/Content/queue/home.htm
- IAM Identity Domains: https://docs.oracle.com/en-us/iaas/Content/Identity/home.htm
- Monitoring/Logging/Audit:
  - https://docs.oracle.com/en-us/iaas/Content/Monitoring/home.htm
  - https://docs.oracle.com/en-us/iaas/Content/Logging/home.htm
  - https://docs.oracle.com/en-us/iaas/Content/Audit/home.htm

### GCP
- API Gateway: https://docs.cloud.google.com/api-gateway/docs
- Cloud Run: https://docs.cloud.google.com/run/docs
- Cloud Storage: https://docs.cloud.google.com/storage/docs
- Cloud SQL: https://docs.cloud.google.com/sql/docs
- Pub/Sub: https://docs.cloud.google.com/pubsub/docs
- Identity Platform: https://docs.cloud.google.com/identity-platform/docs
- Cloud Monitoring: https://docs.cloud.google.com/monitoring/docs
- Cloud Logging: https://docs.cloud.google.com/logging/docs
- Cloud Audit Logs: https://docs.cloud.google.com/logging/docs/audit
