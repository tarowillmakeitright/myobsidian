---
tags: [markets, ohlc, futures, fx, daily]
---

# Global OHLC Market Memo

[[Home]]

> 取得日時: 2026-07-20 06:42 JST  
> 取得元: Yahoo Finance のみ

**要約:** 取得成功数 **25/26** / N/A件数 **1**。Yahoo Finance Chart API（query1/query2）で再確認済み。`^SSEC` は両ホストで3回ずつ段階的に再試行したものの、Yahoo Finance側で銘柄データが提供されていないため N/A。コア6銘柄（`NKD=F`, `^N225`, `^IXIC`, `ES=F`, `BTC-USD`, `JPY=X`）はすべて有効。Close は取得時点の regularMarketPrice（ない場合は最新日足終値）。先物・海外市場の日付は各取引所タイムゾーン基準。

## 日本

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---:|---:|---:|---:|---:|---:|---:|---|---|
| Nikkei/USD Futures | `NKD=F` | 2026-07-17 | 66,000 | 66,000 | 62,860 | 65,200 | 68,240 | N/A | [Yahoo](https://finance.yahoo.com/quote/NKD%3DF/) |
| Nikkei 225 | `^N225` | 2026-07-17 | 66,339.851562 | 66,441.773438 | 62,704.601562 | 64,141.12 | 67,242.73 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5EN225/) |

## 貴金属・コモディティ

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---:|---:|---:|---:|---:|---:|---:|---|---|
| Gold mini futures | `MGC=F` | 2026-07-17 | 4,087.699951 | 4,102.899902 | 4,086.300049 | 4,018.8 | 4,069.7 | N/A | [Yahoo](https://finance.yahoo.com/quote/MGC%3DF/) |
| Silver futures | `SI=F` | 2026-07-17 | 59.459999 | 59.939999 | 59.459999 | 56.326 | 58.772 | N/A | [Yahoo](https://finance.yahoo.com/quote/SI%3DF/) |
| Platinum futures | `PL=F` | 2026-07-17 | 1,629.5 | 1,634.5 | 1,565.599976 | 1,612.5 | 1,631.5 | N/A | [Yahoo](https://finance.yahoo.com/quote/PL%3DF/) |
| Palladium futures | `PA=F` | 2026-07-17 | 1,259 | 1,264.5 | 1,225 | 1,252.8 | 1,298.6 | N/A | [Yahoo](https://finance.yahoo.com/quote/PA%3DF/) |
| Copper futures | `HG=F` | 2026-07-17 | 6.4205 | 6.44 | 6.419 | 6.265 | 6.33 | N/A | [Yahoo](https://finance.yahoo.com/quote/HG%3DF/) |
| WTI oil futures | `CL=F` | 2026-07-17 | 78.860001 | 82.07 | 77.93 | 81.78 | 79.34 | N/A | [Yahoo](https://finance.yahoo.com/quote/CL%3DF/) |

## 米国株・先物

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---:|---:|---:|---:|---:|---:|---:|---|---|
| NASDAQ | `^IXIC` | 2026-07-17 | 25,412.259766 | 25,703.009766 | 25,250.630859 | 25,520.244 | 26,281.61 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5EIXIC/) |
| SOX | `^SOX` | 2026-07-17 | 11,485.889648 | 11,939.44043 | 11,194.599609 | 11,673.889 | 12,967.16 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5ESOX/) |
| S&P500 futures | `ES=F` | 2026-07-17 | 7,572.75 | 7,575 | 7,473 | 7,497.75 | 7,591.25 | N/A | [Yahoo](https://finance.yahoo.com/quote/ES%3DF/) |
| Mini Dow | `YM=F` | 2026-07-17 | 52,778 | 52,835 | 52,174 | 52,375 | 52,791 | N/A | [Yahoo](https://finance.yahoo.com/quote/YM%3DF/) |
| Mini NQ100 | `NQ=F` | 2026-07-17 | 29,191 | 29,220 | 28,408.25 | 28,773.25 | 29,790.25 | N/A | [Yahoo](https://finance.yahoo.com/quote/NQ%3DF/) |
| Mini S&P500 | `MES=F` | 2026-07-17 | 7,571 | 7,574.75 | 7,473 | 7,497.75 | 7,591.25 | N/A | [Yahoo](https://finance.yahoo.com/quote/MES%3DF/) |
| VIX | `^VIX` | 2026-07-17 | 18.01 | 19.5 | 17.68 | 18.77 | 17.16 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5EVIX/) |
| Russell 2000 | `^RUT` | 2026-07-17 | 2,948.580078 | 2,979.320068 | 2,934.120117 | 2,962.217 | 2,977.81 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5ERUT/) |

## 暗号資産

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---:|---:|---:|---:|---:|---:|---:|---|---|
| Bitcoin | `BTC-USD` | 2026-07-19 | 64,794.25 | 64,867.113281 | 64,263.398438 | 64,326.4 | 64,712.375 | N/A | [Yahoo](https://finance.yahoo.com/quote/BTC-USD/) |

## 中国

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---:|---:|---:|---:|---:|---:|---:|---|---|
| China market index/futures | `000300.SS` | 2026-07-17 | 4,661.620117 | 4,663.529785 | 4,492.089844 | 4,529.095 | 4,695.38 | N/A | [Yahoo](https://finance.yahoo.com/quote/000300.SS/) |
| Shanghai index | `^SSEC` | N/A | N/A | N/A | N/A | N/A | N/A | N/A | [Yahoo](https://finance.yahoo.com/quote/%5ESSEC/) |

## 欧州

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---:|---:|---:|---:|---:|---:|---:|---|---|
| FTSE 100 | `^FTSE` | 2026-07-17 | 10,572.400391 | 10,623.700195 | 10,527.700195 | 10,600.37 | 10,497.3 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5EFTSE/) |
| CAC 40 | `^FCHI` | 2026-07-17 | 8,326.740234 | 8,350.19043 | 8,282.169922 | 8,338.81 | 8,364.65 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5EFCHI/) |
| EURO STOXX 50 | `^STOXX50E` | 2026-07-17 | 6,270.939941 | 6,270.939941 | 6,194.390137 | 6,230.87 | 6,271.02 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5ESTOXX50E/) |
| DAX | `^GDAXI` | 2026-07-17 | 24,755.089844 | 24,850.75 | 24,651.339844 | 24,830.98 | 25,067.09 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5EGDAXI/) |
| MSCI EUROPE | `^125904-USD-STRD` | 2026-07-19 | 2,801.409912 | 2,801.409912 | 2,776.01001 | 2,793.57 | 2,798.56 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5E125904-USD-STRD/) |

## 為替

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---:|---:|---:|---:|---:|---:|---:|---|---|
| USD/JPY | `JPY=X` | 2026-07-19 | 162.384003 | 162.472 | 162.302994 | 162.347 | 161.878 | N/A | [Yahoo](https://finance.yahoo.com/quote/JPY%3DX/) |
| EUR/JPY | `EURJPY=X` | 2026-07-19 | 185.667999 | 185.716003 | 185.501999 | 185.558 | 184.612 | N/A | [Yahoo](https://finance.yahoo.com/quote/EURJPY%3DX/) |
