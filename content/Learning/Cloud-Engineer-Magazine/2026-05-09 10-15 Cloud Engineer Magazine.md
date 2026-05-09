---
tags: [cloud, aws, oci, gcp, architecture, daily]
---

# Cloud Engineer Magazine (2026-05-09 10:15 JST)
[[Home]]

## 1) 今日のアプリ
**工場向け IoT 異常検知ダッシュボード（温度・振動センサー監視）**

- 現場のセンサーから秒単位でデータ収集
- 閾値超過・異常スコア上昇時にアラート
- ダッシュボードで設備状態と履歴を可視化

---

## 2) 要件整理
### 機能要件
- センサー時系列データのリアルタイム取り込み
- ルールベース異常検知（初期）＋機械学習拡張（将来）
- アラート通知（メール/チャット/Webhook）
- 過去データ検索・可視化

### 非機能要件
- **可用性:** 24/7監視、SLA重視（単一AZ障害に耐える）
- **性能:** 低遅延取り込み（数秒以内で検知）
- **セキュリティ:** デバイス認証、最小権限IAM、保存時/転送時暗号化
- **コスト:** 初期はマネージド中心、増加時に保存階層化と集約で最適化

---

## 3) 推奨アーキテクチャ（なぜその構成か）
**方針: イベント駆動 + マネージド時系列保存 + サーバレス処理**

1. デバイスはMQTT/HTTPSでIoTエンドポイントへ送信
2. ストリーム処理で異常判定（閾値/統計ルール）
3. 時系列DBへ保存、同時にオブジェクトストレージへアーカイブ
4. API + ダッシュボードで参照
5. 監視・ログ・監査を標準サービスで一元化

**理由**
- サーバ管理を減らし、運用負荷を最小化
- データ量増加に追従しやすい（スケールアウト）
- 監視基盤を最初から組み込み、障害解析を短縮

---

## 4) クラウド別実装マップ
### AWS
- 取り込み: **AWS IoT Core**
- ルール/配信: **IoT Rules** → **Kinesis / Lambda**
- 保存: **Amazon Timestream**（時系列）+ **S3**（長期保管）
- API: **API Gateway + Lambda**
- 可視化: **Amazon Managed Grafana**（または QuickSight）
- 認証認可: **IAM / Cognito**
- 監視: **CloudWatch / CloudTrail**

### OCI
- 取り込み: **OCI Streaming**（デバイスGW経由で投入）
- 処理: **OCI Functions** / **Stream Processing系構成**
- 保存: **Autonomous Database（時系列テーブル）** + **Object Storage**
- API: **API Gateway + Functions**
- 可視化: **Oracle Analytics Cloud**（またはGrafana連携）
- 認証認可: **OCI IAM**
- 監視: **Monitoring / Logging / Audit**

### GCP
- 取り込み: **Pub/Sub**
- 処理: **Dataflow**（またはCloud Functions）
- 保存: **Bigtable（時系列向け）**または**BigQuery** + **Cloud Storage**
- API: **API Gateway / Cloud Run**
- 可視化: **Looker Studio**（またはManaged Service for Grafana）
- 認証認可: **Cloud IAM**
- 監視: **Cloud Monitoring / Cloud Logging / Cloud Audit Logs**

---

## 5) システム構成図（Mermaid）
```mermaid
flowchart LR
  D[IoT Sensors] --> I[IoT Ingestion\n(AWS IoT Core / OCI Streaming / PubSub)]
  I --> P[Stream Processing\n(Lambda/Functions/Dataflow)]
  P --> T[Time-series Store]
  P --> A[Alert Engine]
  T --> API[API Layer]
  API --> UI[Dashboard]
  P --> O[Object Storage Archive]
  M[Monitoring & Audit] --- I
  M --- P
  M --- API
```

---

## 6) データフロー/認証・認可/監視運用の要点
- **データフロー:** 取り込み時にスキーマ検証、異常値はDLQ/再処理キューへ
- **認証・認可:**
  - デバイスごとに証明書/キーを分離
  - 人間ユーザーはIdP連携 + ロールベースアクセス
  - サービス間権限は最小権限（書込先バケット/テーブル限定）
- **監視運用:**
  - SLI: 取り込み遅延、処理失敗率、アラート通知遅延
  - アラームは閾値 + 異常検知（急増/欠損）
  - 監査ログを改ざん耐性ある保存先へ集約

---

## 7) コスト最適化ポイント
### 初期
- サーバレス優先（常時稼働VMを避ける）
- 保存期間を短めに設定し、古いデータは安価層へ
- ダッシュボード更新間隔を必要十分に

### 成長期
- ホット/コールド分離（時系列DBは直近中心、履歴はオブジェクトへ）
- ストリーム処理のバッチ窓調整でコスト削減
- APIキャッシュ/事前集計でクエリ課金を抑制

---

## 8) 障害時の設計（DR/バックアップ/フェイルオーバー）
- **DR方針:** リージョン障害を想定し、重要メタデータと設定を別リージョン複製
- **バックアップ:**
  - 時系列DBの定期スナップショット
  - オブジェクトストレージのバージョニング
- **フェイルオーバー:**
  - DNS/グローバルLBで切替
  - 非同期レプリケーション前提でRPO/RTOを明文化（例: RPO 15分, RTO 60分）

---

## 9) 学習ポイント（今日覚えるクラウド機能）
- **AWS:** IoT Rulesで取り込み後の分岐をコード最小で実装できる
- **OCI:** IAMポリシーとCompartmentsで権限境界を明確化しやすい
- **GCP:** Pub/Sub + Dataflowで高スループットのイベント処理を構成しやすい

---

## 10) 30〜60分ミニ演習
1. 1種類のセンサーデータJSONスキーマを定義
2. AWS/OCI/GCPのいずれか1つで「取り込み→保存」だけ最小構成を作る
3. 閾値超過時のアラート1本を設定
4. 「失敗時の再処理」を1つ追加（DLQまたは再試行）

**ゴール:** “動く最小監視パイプライン”を今日中に作る

---

## 11) 公式ドキュメント参照リンク（AWS/OCI/GCP）
### AWS
- https://docs.aws.amazon.com/iot/latest/developerguide/what-is-aws-iot.html
- https://docs.aws.amazon.com/lambda/latest/dg/welcome.html
- https://docs.aws.amazon.com/timestream/latest/developerguide/what-is-timestream.html
- https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/WhatIsCloudWatch.html

### OCI
- https://docs.oracle.com/en-us/iaas/Content/home.htm
- https://docs.oracle.com/en-us/iaas/Content/Streaming/Concepts/streamingoverview.htm
- https://docs.oracle.com/en-us/iaas/Content/Functions/Concepts/functionsoverview.htm
- https://docs.oracle.com/en-us/iaas/Content/Identity/Concepts/overview.htm
- https://docs.oracle.com/en-us/iaas/Content/Monitoring/Concepts/monitoringoverview.htm

### GCP
- https://docs.cloud.google.com/pubsub/docs/overview
- https://docs.cloud.google.com/dataflow/docs/concepts/beam-programming-model
- https://docs.cloud.google.com/bigtable/docs/overview
- https://docs.cloud.google.com/monitoring/docs/monitoring-overview
- https://docs.cloud.google.com/iam/docs/overview
