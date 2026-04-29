---
tags: [cloud, aws, oci, gcp, architecture, daily]
---
[[Home]]

# Cloud Engineer Magazine（2026-04-29）

## 1) 今日のアプリ
**工場設備の予知保全アラートSaaS（B2B）**
- センサー（温度/振動/電流）を5秒間隔で収集
- しきい値判定＋異常スコアで保全チケット自動起票
- 現場向けモバイル通知とダッシュボード提供

> 今日の視点: **マルチクラウド比較（AWS/OCI/GCP）**

---

## 2) 要件整理（機能要件/非機能要件）
### 機能要件
- デバイスからの時系列データ取り込み（MQTT/HTTPS）
- リアルタイム異常検知（数秒以内）
- 設備単位の履歴可視化（直近24h/30日）
- アラート通知（メール/チャット/Webhook）
- テナント分離（企業ごとにデータ分離）

### 非機能要件
- **可用性**: 99.9%以上、単一AZ障害では停止しない
- **性能**: 5,000 device、平均 1,000 msg/sec、P95判定遅延 < 3秒
- **セキュリティ**: デバイス認証、保存時/転送時暗号化、最小権限IAM
- **コスト**: PoCは従量優先、成長後はストレージ階層化と予約/割引活用

---

## 3) 推奨アーキテクチャ（なぜその構成か）
**イベント駆動 + 時系列DB + サーバレス分析**を基本にする。
- 取り込み層はマネージドIoT/メッセージ基盤でスパイク吸収
- 判定層はストリーム処理（関数 or SQL処理）で低遅延
- 保存層は「ホット（高速参照）」と「コールド（長期保管）」を分離
- 通知/運用をマネージド化し、少人数運用でも回る構成

**理由**
- 設備データは突発的に増えるため、オートスケール可能な取り込みが必須
- 分析要件（即時判定）と保存要件（長期監査）を同じDBに寄せない方がコスト効率が高い

---

## 4) クラウド別実装マップ
### AWS での実装サービス
- デバイス接続: **AWS IoT Core**
- ストリーム処理: **AWS IoT Rules + AWS Lambda**（または Kinesis Data Streams）
- 時系列/ホット参照: **Amazon Timestream**
- データレイク: **Amazon S3**
- 通知: **Amazon SNS**
- 可視化: **Amazon Managed Grafana**
- 認証認可: **AWS IAM / AWS IoT Core X.509 認証**
- 監視: **Amazon CloudWatch / AWS X-Ray**

**トレードオフ**
- Timestreamは時系列運用が軽いが、複雑分析はAthena/S3連携が必要になる場面あり

### OCI での実装サービス
- デバイス入口: **OCI API Gateway + Functions**（MQTTが必要なら中継基盤を別途）
- ストリーム処理: **OCI Streaming + OCI Functions**
- 時系列/分析: **Autonomous Database (JSON/SQL活用)** または **MySQL HeatWave**
- データレイク: **OCI Object Storage**
- 通知: **OCI Notifications**
- 可視化: **OCI Logging Analytics / OCI Data Science連携**
- 認証認可: **OCI IAM**
- 監視: **OCI Monitoring / Logging / Alarms**

**トレードオフ**
- OCIはコスト性能が強いケースが多い一方、IoT専用マネージド入口はAWS/GCPより設計判断が必要

### GCP での実装サービス
- デバイス接続: **Pub/Sub（HTTPS ingest）**
- ストリーム処理: **Dataflow（Apache Beam）**
- 時系列/分析: **BigQuery**（時系列分析・長期分析を統合）
- データレイク: **Cloud Storage**
- 通知: **Cloud Monitoring Alerting + Pub/Sub/Webhook**
- 可視化: **Looker Studio**
- 認証認可: **IAM / Workload Identity**
- 監視: **Cloud Monitoring / Cloud Logging / Error Reporting**

**トレードオフ**
- BigQuery中心は分析が強力だが、超低レイテンシ参照はキャッシュ層併用が必要なことがある

---

## 5) システム構成図（Mermaid）
```mermaid
flowchart LR
  D[Factory Devices] --> I[Ingestion Layer\n(IoT/API/PubSub)]
  I --> S[Stream Processing\n(Rules/Functions/Dataflow)]
  S --> H[Hot Store\n(Time-series DB)]
  S --> L[Data Lake\n(Object Storage)]
  S --> N[Alerting\n(SNS/Notifications/Alerting)]
  H --> V[Dashboard/BI]
  L --> A[Batch Analytics/ML]
  IAM[IAM + Cert/AuthN] -.-> I
  MON[Monitoring/Logging/Tracing] -.-> I
  MON -.-> S
  MON -.-> H
```

---

## 6) データフロー/認証・認可/監視運用の要点
### データフロー
1. デバイスがテレメトリ送信
2. 取り込み層で受信・基本バリデーション
3. ストリーム処理で異常スコア計算
4. 異常時に通知、全量を時系列DB/データレイクへ保存

### 認証・認可
- デバイスは証明書ベース（可能なら相互TLS）
- サービス間アクセスはIAMロール/動的資格情報を使用（長期鍵を置かない）
- テナント単位でデータアクセス境界（IAM条件、プロジェクト/コンパートメント分離）

### 監視運用
- SLI: 取り込み成功率、判定遅延P95、通知遅延
- アラートは「症状」と「原因候補」を分ける（例: 遅延増加 / 特定関数エラー）
- 監査ログを有効化し、90日以上保持

---

## 7) コスト最適化ポイント（初期・成長期）
### 初期
- サーバレス中心（Lambda/Functions/Dataflow最小構成）
- 保存期間を短めに設定し、必要データのみホット保持
- ダッシュボード更新頻度を必要最小限に

### 成長期
- ホット/コールド階層を明確化（直近7日ホット、以降アーカイブ）
- 定期バッチで集計済みテーブル作成（クエリ課金削減）
- 予約/コミット割引（各クラウドの割引制度）を利用

---

## 8) 障害時の設計（DR/バックアップ/フェイルオーバー）
- **DR方針**: RPO 5分、RTO 30分を目標
- 取り込み層はリージョン内冗長 + 再送制御
- ストレージはバージョニング/クロスリージョン複製を有効化
- IaCで環境再作成可能に（Terraform等）
- ランブック: 「通知失敗」「遅延増加」「DB書込失敗」ごとに手順化

---

## 9) 学習ポイント（今日覚えるクラウド機能）
- **AWS**: IoT Core Rulesでメッセージを条件分岐しLambda/S3へルーティング
- **OCI**: Streaming + Functions でイベント駆動処理を構成
- **GCP**: Dataflowのウィンドウ/トリガで遅延到着データを扱う

---

## 10) 30〜60分ミニ演習
**お題:** 「異常温度アラートの最小実装」
1. 1クラウド選択（AWS/OCI/GCPどれでも）
2. ダミーデータを1秒ごとに10分投入
3. 閾値（例: 80℃）超過で通知
4. 結果を時系列で可視化

**達成条件**
- 通知までの遅延を測定して記録
- IAMポリシーを見直し、不要権限を1つ削除

---

## 11) 公式ドキュメント参照リンク（AWS/OCI/GCP）
### AWS
- AWS IoT Core: https://docs.aws.amazon.com/iot/latest/developerguide/what-is-aws-iot.html
- AWS Lambda: https://docs.aws.amazon.com/lambda/latest/dg/welcome.html
- Amazon Timestream: https://docs.aws.amazon.com/timestream/latest/developerguide/what-is-timestream.html
- Amazon S3: https://docs.aws.amazon.com/AmazonS3/latest/userguide/Welcome.html
- Amazon CloudWatch: https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/WhatIsCloudWatch.html

### OCI
- OCI Streaming: https://docs.oracle.com/en-us/iaas/Content/Streaming/Concepts/streamingoverview.htm
- OCI Functions: https://docs.oracle.com/en-us/iaas/Content/Functions/Concepts/functionsoverview.htm
- OCI Object Storage: https://docs.oracle.com/en-us/iaas/Content/Object/home.htm
- OCI Monitoring: https://docs.oracle.com/en-us/iaas/Content/Monitoring/home.htm
- OCI IAM: https://docs.oracle.com/en-us/iaas/Content/Identity/home.htm

### GCP
- Pub/Sub: https://docs.cloud.google.com/pubsub/docs/overview
- Dataflow: https://docs.cloud.google.com/dataflow/docs/overview
- BigQuery: https://docs.cloud.google.com/bigquery/docs/introduction
- Cloud Storage: https://docs.cloud.google.com/storage/docs/introduction
- Cloud Monitoring: https://docs.cloud.google.com/monitoring/docs/monitoring_overview
