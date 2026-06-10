---
tags:
  - markets
  - ohlc
  - futures
  - fx
  - daily
---

# Global OHLC Memo

[[Home]]

## サマリー
- 取得成功数: 24/26
- N/A件数: 1
- 注意点: Yahoo再照会をstagger/backoff付きで実施。`^SSEC` はYahoo側で当日OHLC非掲載のためN/A維持、`EURJPY=X` はmarketStateのみN/A。主要銘柄は有効OHLCを確認済み。

## 日本/先物

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| Nikkei/USD Futures | `NKD=F` | 2026-06-09 | 65,425 | 66,110 | 63,135 | 64,435 | 67,770 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/NKD=F) |

## 日本/株価指数

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| Nikkei 225 | `^N225` | 2026-06-09 | 64,625.26 | 65,485.16 | 63,918.96 | 65,416.63 | 68,402.13 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/^N225) |

## コモディティ

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| Gold mini futures | `MGC=F` | 2026-06-09 | 4,354.8 | 4,388.8 | 4,260 | 4,285 | 4,475.8 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/MGC=F) |
| Silver futures | `SI=F` | 2026-06-09 | 68.32 | 69.18 | 64.46 | 65.46 | 73.779 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/SI=F) |
| Platinum futures | `PL=F` | 2026-06-09 | 1,758.9 | 1,785.2 | 1,700.9 | 1,725.5 | 1,894 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/PL=F) |
| Palladium futures | `PA=F` | 2026-06-09 | 1,222.5 | 1,269 | 1,213.5 | 1,238 | 1,318.8 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/PA=F) |
| Copper futures | `HG=F` | 2026-06-09 | 6.3395 | 6.4655 | 6.2835 | 6.352 | 6.511 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/HG=F) |
| WTI oil futures | `CL=F` | 2026-06-09 | 91.28 | 91.55 | 85.95 | 88.7 | 93.04 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/CL=F) |

## 米国/指数

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| NASDAQ | `^IXIC` | 2026-06-09 | 26,110.31 | 26,259.92 | 24,980.38 | 25,678.82 | 27,093.9 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/^IXIC) |
| SOX | `^SOX` | 2026-06-09 | 13,142.99 | 13,264.12 | 11,794.15 | 12,657.81 | 13,726.27 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/^SOX) |
| VIX | `^VIX` | 2026-06-09 | 18.19 | 23.34 | 17.52 | 19.87 | 16.06 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/^VIX) |
| Russell 2000 | `^RUT` | 2026-06-09 | 2,879.48 | 2,921.33 | 2,795.48 | 2,867.02 | 2,931.96 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/^RUT) |

## 米国/先物

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| S&P500 futures | `ES=F` | 2026-06-09 | 7,412.75 | 7,491 | 7,247.25 | 7,390 | 7,601 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/ES=F) |
| Mini Dow | `YM=F` | 2026-06-09 | 50,800 | 51,315 | 50,262 | 50,879 | 51,671 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/YM=F) |
| Mini NQ100 | `NQ=F` | 2026-06-09 | 29,435 | 29,848.25 | 28,227.75 | 29,140.5 | 30,488.25 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/NQ=F) |
| Mini S&P500 | `MES=F` | 2026-06-09 | 7,412.25 | 7,491 | 7,247 | 7,390 | 7,601 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/MES=F) |

## 暗号資産

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| Bitcoin | `BTC-USD` | 2026-06-09 | 63,078.89 | 63,484.54 | 60,782.84 | 61,795.02 | 60,922.67 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/BTC-USD) |

## 中国/指数

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| China market index/futures | `000300.SS` | 2026-06-09 | 4,743.45 | 4,802.5 | 4,715.39 | 4,801.81 | 4,938.81 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/000300.SS) |
| Shanghai index | `^SSEC` | N/A | N/A | N/A | N/A | N/A | N/A | REGULAR | [Yahoo](https://finance.yahoo.com/quote/^SSEC) |

## 欧州/指数

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| FTSE 100 | `^FTSE` | 2026-06-09 | 10,372.77 | 10,372.77 | 10,227.33 | 10,227.33 | 10,373.5 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/^FTSE) |
| CAC 40 | `^FCHI` | 2026-06-09 | 8,179.22 | 8,290.7 | 8,175.61 | 8,203.43 | 8,150.42 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/^FCHI) |
| EURO STOXX 50 | `^STOXX50E` | 2026-06-09 | 6,058.79 | 6,149.17 | 6,048.55 | 6,049.74 | 6,053.57 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/^STOXX50E) |
| DAX | `^GDAXI` | 2026-06-09 | 24,589.29 | 24,820.95 | 24,398.87 | 24,433.06 | 25,124.17 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/^GDAXI) |
| MSCI EUROPE | `^125904-USD-STRD` | 2026-06-09 | 2,729.27 | 2,760.32 | 2,712.4 | 2,720.85 | 2,762.59 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/^125904-USD-STRD) |

## FX

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| USD/JPY | `JPY=X` | 2026-06-10 | 160.156 | 160.449 | 160.045 | 160.342 | 159.968 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/JPY=X) |
| EUR/JPY | `EURJPY=X` | 2026-06-10 | 184.678 | 185.462 | 184.597 | 184.982 | 185.909 | N/A | [Yahoo](https://finance.yahoo.com/quote/EURJPY=X) |
