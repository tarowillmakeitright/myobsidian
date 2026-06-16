---
tags: [markets, ohlc, futures, fx, daily]
---
[[Home]]

# 2026-06-16 07-00 Global OHLC Memo

## サマリー
- 取得成功数: 25/26
- N/A件数: 32（うち marketState 欠損 25 件、完全取得不可 1 銘柄）
- 注意点: Yahoo Finance の query1/chart エンドポイントを直接参照。^SSEC は今回取得不可のため N/A、また marketState は多くの銘柄で返らず N/A です。

## 日本・アジア株価指数

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| Nikkei/USD Futures | `NKD=F` | 2026-06-16 | 63,335.00 | 69,950.00 | 68,150.00 | 69,835.00 | 63,335.00 | N/A | [Yahoo](https://finance.yahoo.com/quote/NKD=F) |
| Nikkei 225 | `^N225` | 2026-06-15 | 65,416.63 | 69,682.23 | 66,783.22 | 69,317.50 | 65,416.63 | N/A | [Yahoo](https://finance.yahoo.com/quote/^N225) |

## 貴金属・資源・エネルギー

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| Gold mini futures | `MGC=F` | 2026-06-16 | 4,108.20 | 4,391.70 | 4,283.10 | 4,331.30 | 4,108.20 | N/A | [Yahoo](https://finance.yahoo.com/quote/MGC=F) |
| Silver futures | `SI=F` | 2026-06-16 | 64.599 | 71.4 | 68.725 | 70.06 | 64.599 | N/A | [Yahoo](https://finance.yahoo.com/quote/SI=F) |
| Platinum futures | `PL=F` | 2026-06-16 | 1,688.00 | 1,824.20 | 1,730.60 | 1,774.20 | 1,688.00 | N/A | [Yahoo](https://finance.yahoo.com/quote/PL=F) |
| Palladium futures | `PA=F` | 2026-06-16 | 1,230.80 | 1,380.00 | 1,305.00 | 1,348.50 | 1,230.80 | N/A | [Yahoo](https://finance.yahoo.com/quote/PA=F) |
| Copper futures | `HG=F` | 2026-06-16 | 6.249 | 6.562 | 6.471 | 6.49 | 6.249 | N/A | [Yahoo](https://finance.yahoo.com/quote/HG=F) |
| WTI oil futures | `CL=F` | 2026-06-16 | 90.03 | 82.42 | 79.7 | 81.16 | 90.03 | N/A | [Yahoo](https://finance.yahoo.com/quote/CL=F) |

## 米国株・先物・ボラ

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| NASDAQ | `^IXIC` | 2026-06-16 | 25,929.66 | 26,687.56 | 26,438.77 | 26,683.94 | 25,929.66 | N/A | [Yahoo](https://finance.yahoo.com/quote/^IXIC) |
| SOX | `^SOX` | 2026-06-16 | 12,906.69 | 14,134.60 | 13,860.32 | 14,099.62 | 12,906.69 | N/A | [Yahoo](https://finance.yahoo.com/quote/^SOX) |
| S&P500 futures | `ES=F` | 2026-06-16 | 7,278.50 | 7,648.75 | 7,542.00 | 7,624.25 | 7,278.50 | N/A | [Yahoo](https://finance.yahoo.com/quote/ES=F) |
| Mini Dow | `YM=F` | 2026-06-16 | 49,990.00 | 52,380.00 | 51,743.00 | 52,134.00 | 49,990.00 | N/A | [Yahoo](https://finance.yahoo.com/quote/YM=F) |
| Mini NQ100 | `NQ=F` | 2026-06-16 | 28,554.00 | 30,915.00 | 30,191.00 | 30,832.00 | 28,554.00 | N/A | [Yahoo](https://finance.yahoo.com/quote/NQ=F) |
| Mini S&P500 | `MES=F` | 2026-06-16 | 7,278.50 | 7,648.75 | 7,540.00 | 7,624.50 | 7,278.50 | N/A | [Yahoo](https://finance.yahoo.com/quote/MES=F) |
| VIX | `^VIX` | 2026-06-16 | 19.87 | 16.85 | 15.98 | 16.2 | 19.87 | N/A | [Yahoo](https://finance.yahoo.com/quote/^VIX) |

## 暗号資産

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| Bitcoin | `BTC-USD` | 2026-06-16 | 63,561.06 | 67,236.12 | 65,333.90 | 66,420.19 | 63,561.06 | N/A | [Yahoo](https://finance.yahoo.com/quote/BTC-USD) |

## 中国・アジア株価指数

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| China market index/futures | `000300.SS` | 2026-06-15 | 4,801.81 | 4,892.55 | 4,803.18 | 4,891.71 | 4,801.81 | N/A | [Yahoo](https://finance.yahoo.com/quote/000300.SS) |
| Shanghai index | `^SSEC` | N/A | N/A | N/A | N/A | N/A | N/A | N/A | [Yahoo](https://finance.yahoo.com/quote/^SSEC) |

## 欧州株価指数

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| Russell 2000 | `^RUT` | 2026-06-16 | 2,855.42 | 2,996.42 | 2,960.68 | 2,965.09 | 2,855.42 | N/A | [Yahoo](https://finance.yahoo.com/quote/^RUT) |
| FTSE 100 | `^FTSE` | 2026-06-16 | 10,373.20 | 10,570.09 | 10,419.22 | 10,430.62 | 10,373.20 | N/A | [Yahoo](https://finance.yahoo.com/quote/^FTSE) |
| CAC 40 | `^FCHI` | 2026-06-16 | 8,203.43 | 8,506.65 | 8,384.01 | 8,384.01 | 8,203.43 | N/A | [Yahoo](https://finance.yahoo.com/quote/^FCHI) |
| EURO STOXX 50 | `^STOXX50E` | 2026-06-16 | 6,049.74 | 6,294.68 | 6,224.76 | 6,229.43 | 6,049.74 | N/A | [Yahoo](https://finance.yahoo.com/quote/^STOXX50E) |
| DAX | `^GDAXI` | 2026-06-16 | 24,616.22 | 25,085.80 | 24,882.01 | 24,894.01 | 24,616.22 | N/A | [Yahoo](https://finance.yahoo.com/quote/^GDAXI) |
| MSCI EUROPE | `^125904-USD-STRD` | 2026-06-16 | 2,716.71 | 2,830.80 | 2,795.89 | 2,802.04 | 2,716.71 | N/A | [Yahoo](https://finance.yahoo.com/quote/^125904-USD-STRD) |

## 為替

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| USD/JPY | `JPY=X` | 2026-06-16 | 160.174 | 160.397 | 159.702 | 160.32 | 160.174 | N/A | [Yahoo](https://finance.yahoo.com/quote/JPY=X) |
| EUR/JPY | `EURJPY=X` | 2026-06-16 | 184.65 | 186.054 | 185.186 | 185.917 | 184.65 | N/A | [Yahoo](https://finance.yahoo.com/quote/EURJPY=X) |
