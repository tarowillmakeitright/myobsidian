---
tags:
  - markets
  - ohlc
  - futures
  - fx
  - daily
---

# Global OHLC Market Memo

[[Home]]

- 取得時点: 2026-08-07 06:40 JST
- 取得成功数: **25/26**
- N/A件数: **1**
- 注意点: Yahoo Financeの日足チャート値を使用。取引時間中のCloseは取得時点の値であり、確定終値ではありません。セッション日付・市場状態はYahooの銘柄メタデータに準拠します。
- 注記: Yahooで4回再試行済み。値が真に利用不可の銘柄: ^SSEC

## 日本・中国

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| Nikkei/USD Futures | `NKD=F` | 2026-08-06 | 65,880 | 66,410 | 64,985 | 65,585 | 65,770 | N/A | [Yahoo](https://query1.finance.yahoo.com/v8/finance/chart/NKD%3DF?range=10d&interval=1d&includePrePost=true&events=div%2Csplits) |
| Nikkei 225 | `^N225` | 2026-08-06 | 65,896 | 65,983.132812 | 64,942.070312 | 65,683.26 | 66,300.4375 | N/A | [Yahoo](https://query1.finance.yahoo.com/v8/finance/chart/%5EN225?range=10d&interval=1d&includePrePost=true&events=div%2Csplits) |
| 中国CSI 300 | `000300.SS` | 2026-08-06 | 4,621.803223 | 4,675.645508 | 4,611.06543 | 4,651.30957 | 4,658.155 | N/A | [Yahoo](https://query1.finance.yahoo.com/v8/finance/chart/000300.SS?range=10d&interval=1d&includePrePost=true&events=div%2Csplits) |
| 上海総合指数 | `^SSEC` | N/A | N/A | N/A | N/A | N/A | N/A | N/A | [Yahoo](https://finance.yahoo.com/quote/%5ESSEC/) |

## 米国株価指数・ボラティリティ

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| NASDAQ | `^IXIC` | 2026-08-06 | 26,268.84375 | 26,499.421875 | 26,208.431641 | 26,348.351562 | 26,363.439453 | N/A | [Yahoo](https://query1.finance.yahoo.com/v8/finance/chart/%5EIXIC?range=10d&interval=1d&includePrePost=true&events=div%2Csplits) |
| SOX | `^SOX` | 2026-08-06 | 11,825.860352 | 12,288.563477 | 11,707.776367 | 12,048.693359 | 12,008.879883 | N/A | [Yahoo](https://query1.finance.yahoo.com/v8/finance/chart/%5ESOX?range=10d&interval=1d&includePrePost=true&events=div%2Csplits) |
| S&P500 futures | `ES=F` | 2026-08-06 | 7,756.75 | 7,770.75 | 7,724.25 | 7,731.5 | 7,749.5 | N/A | [Yahoo](https://query1.finance.yahoo.com/v8/finance/chart/ES%3DF?range=10d&interval=1d&includePrePost=true&events=div%2Csplits) |
| Mini Dow | `YM=F` | 2026-08-06 | 54,555 | 54,678 | 53,952 | 53,981 | 54,494 | N/A | [Yahoo](https://query1.finance.yahoo.com/v8/finance/chart/YM%3DF?range=10d&interval=1d&includePrePost=true&events=div%2Csplits) |
| Mini NQ100 | `NQ=F` | 2026-08-06 | 29,569.5 | 29,686.25 | 29,241.25 | 29,504.25 | 29,615 | N/A | [Yahoo](https://query1.finance.yahoo.com/v8/finance/chart/NQ%3DF?range=10d&interval=1d&includePrePost=true&events=div%2Csplits) |
| Mini S&P500 | `MES=F` | 2026-08-06 | 7,758 | 7,771 | 7,724.25 | 7,731.75 | 7,749.5 | N/A | [Yahoo](https://query1.finance.yahoo.com/v8/finance/chart/MES%3DF?range=10d&interval=1d&includePrePost=true&events=div%2Csplits) |
| VIX | `^VIX` | 2026-08-06 | 15.83 | 16.030001 | 15.11 | 15.15 | 15.81 | N/A | [Yahoo](https://query1.finance.yahoo.com/v8/finance/chart/%5EVIX?range=10d&interval=1d&includePrePost=true&events=div%2Csplits) |
| Russell 2000 | `^RUT` | 2026-08-06 | 3,016.298096 | 3,032.221191 | 2,999.504639 | 3,001.547363 | 3,019.189941 | N/A | [Yahoo](https://query1.finance.yahoo.com/v8/finance/chart/%5ERUT?range=10d&interval=1d&includePrePost=true&events=div%2Csplits) |

## 欧州株価指数

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| FTSE 100 | `^FTSE` | 2026-08-06 | 10,888.450195 | 10,944.75 | 10,865.320312 | 10,867.889648 | 10,888.299805 | N/A | [Yahoo](https://query1.finance.yahoo.com/v8/finance/chart/%5EFTSE?range=10d&interval=1d&includePrePost=true&events=div%2Csplits) |
| CAC 40 | `^FCHI` | 2026-08-06 | 8,721.139648 | 8,742.530273 | 8,699.709961 | 8,699.709961 | 8,669.299805 | N/A | [Yahoo](https://query1.finance.yahoo.com/v8/finance/chart/%5EFCHI?range=10d&interval=1d&includePrePost=true&events=div%2Csplits) |
| EURO STOXX 50 | `^STOXX50E` | 2026-08-06 | 0 | 0 | 0 | 6,502.560059 | 6,476.97998 | N/A | [Yahoo](https://query1.finance.yahoo.com/v8/finance/chart/%5ESTOXX50E?range=10d&interval=1d&includePrePost=true&events=div%2Csplits) |
| DAX | `^GDAXI` | 2026-08-06 | 26,116.269531 | 26,229.330078 | 26,081.689453 | 26,140.130859 | 26,126.300781 | N/A | [Yahoo](https://query1.finance.yahoo.com/v8/finance/chart/%5EGDAXI?range=10d&interval=1d&includePrePost=true&events=div%2Csplits) |
| MSCI EUROPE | `^125904-USD-STRD` | 2026-08-06 | 2,892.969971 | 2,902.73999 | 2,882.610107 | 2,887.419922 | 2,889.070068 | N/A | [Yahoo](https://query1.finance.yahoo.com/v8/finance/chart/%5E125904-USD-STRD?range=10d&interval=1d&includePrePost=true&events=div%2Csplits) |

## 貴金属・非鉄金属

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| Gold mini futures | `MGC=F` | 2026-08-06 | 4,307.5 | 4,363.799805 | 4,280.799805 | 4,298.700195 | 4,245.799805 | N/A | [Yahoo](https://query1.finance.yahoo.com/v8/finance/chart/MGC%3DF?range=10d&interval=1d&includePrePost=true&events=div%2Csplits) |
| Silver futures | `SI=F` | 2026-08-06 | 62.200001 | 63.32 | 61.119999 | 61.785 | 62.098999 | N/A | [Yahoo](https://query1.finance.yahoo.com/v8/finance/chart/SI%3DF?range=10d&interval=1d&includePrePost=true&events=div%2Csplits) |
| Platinum futures | `PL=F` | 2026-08-06 | 1,752.199951 | 1,797.900024 | 1,728 | 1,735.599976 | 1,737.400024 | N/A | [Yahoo](https://query1.finance.yahoo.com/v8/finance/chart/PL%3DF?range=10d&interval=1d&includePrePost=true&events=div%2Csplits) |
| Palladium futures | `PA=F` | 2026-08-06 | 1,375.5 | 1,400.5 | 1,366.5 | 1,376 | 1,364.699951 | N/A | [Yahoo](https://query1.finance.yahoo.com/v8/finance/chart/PA%3DF?range=10d&interval=1d&includePrePost=true&events=div%2Csplits) |
| Copper futures | `HG=F` | 2026-08-06 | 6.748 | 6.8665 | 6.6715 | 6.717 | 6.703 | N/A | [Yahoo](https://query1.finance.yahoo.com/v8/finance/chart/HG%3DF?range=10d&interval=1d&includePrePost=true&events=div%2Csplits) |

## エネルギー・暗号資産

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| WTI oil futures | `CL=F` | 2026-08-06 | 75.139999 | 78.510002 | 74.57 | 78.230003 | 75.220001 | N/A | [Yahoo](https://query1.finance.yahoo.com/v8/finance/chart/CL%3DF?range=10d&interval=1d&includePrePost=true&events=div%2Csplits) |
| Bitcoin | `BTC-USD` | 2026-08-06 | 64,602.320312 | 64,922.953125 | 64,135.496094 | 64,385.710938 | 64,597.5 | N/A | [Yahoo](https://query1.finance.yahoo.com/v8/finance/chart/BTC-USD?range=10d&interval=1d&includePrePost=true&events=div%2Csplits) |

## 為替

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| USD/JPY | `JPY=X` | 2026-08-06 | 158.451996 | 158.464996 | 158.438004 | 158.447998 | 157.600006 | N/A | [Yahoo](https://query1.finance.yahoo.com/v8/finance/chart/JPY%3DX?range=10d&interval=1d&includePrePost=true&events=div%2Csplits) |
| EUR/JPY | `EURJPY=X` | 2026-08-06 | 182.520004 | 182.574997 | 182.494003 | 182.548004 | 182.141006 | N/A | [Yahoo](https://query1.finance.yahoo.com/v8/finance/chart/EURJPY%3DX?range=10d&interval=1d&includePrePost=true&events=div%2Csplits) |

_Source: Yahoo Finance only. Generated 2026-08-07 06:40 JST._
