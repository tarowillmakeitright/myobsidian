# 2026-07-14 07-00 Global OHLC Memo

#markets #ohlc #futures #fx #daily

[[Home]]

- 取得成功数: 25/26
- N/A件数: 1
- 注意点: Yahoo Financeのchartエンドポイントを直接参照。`状態(marketState)` は `currentTradingPeriod` ベースの簡易判定で、指数・先物・FX・暗号資産では実際の取引可否表示と完全一致しない場合があります。

## 日本/株価指数先物

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---|---|---|---|---|---|---|---|
| Nikkei/USD Futures | NKD=F | 2026-07-13 | 69070 | 69225 | 66815 | 67160 | 67865 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/NKD=F) |

## 日本/株価指数

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---|---|---|---|---|---|---|---|
| Nikkei 225 | ^N225 | 2026-07-13 | 68410.632812 | 69078.210938 | 66653.109375 | 67242.73 | 68256.96 | CLOSED | [Yahoo](https://finance.yahoo.com/quote/^N225) |

## 商品/貴金属

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---|---|---|---|---|---|---|---|
| Gold mini futures | MGC=F | 2026-07-13 | 4107 | 4111.600098 | 3992.899902 | 4008.7 | 4082.4 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/MGC=F) |
| Silver futures | SI=F | 2026-07-13 | 59.709999 | 59.794998 | 57.595001 | 57.98 | 58.164 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/SI=F) |
| Platinum futures | PL=F | 2026-07-13 | 1630 | 1641 | 1600.099976 | 1612.1 | 1576.4 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/PL=F) |
| Palladium futures | PA=F | 2026-07-13 | 1276 | 1276 | 1246 | 1252 | 1213.4 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/PA=F) |

## 商品/資源

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---|---|---|---|---|---|---|---|
| Copper futures | HG=F | 2026-07-13 | 6.2705 | 6.356 | 6.197 | 6.276 | 6.055 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/HG=F) |

## 商品/エネルギー

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---|---|---|---|---|---|---|---|
| WTI oil futures | CL=F | 2026-07-13 | 73.690002 | 78.580002 | 72.610001 | 78 | 73.52 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/CL=F) |

## 米国/株価指数

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---|---|---|---|---|---|---|---|
| NASDAQ | ^IXIC | 2026-07-13 | 26088.3125 | 26139.369141 | 25822.095703 | 25873.176 | 26121.16 | POST | [Yahoo](https://finance.yahoo.com/quote/^IXIC) |
| SOX | ^SOX | 2026-07-13 | 12563.631836 | 12646.775391 | 12289.052734 | 12347.783 | 12900.14 | POST | [Yahoo](https://finance.yahoo.com/quote/^SOX) |
| Russell 2000 | ^RUT | 2026-07-13 | 2974.488037 | 2974.488037 | 2947.23584 | 2953.1663 | 3009.54 | POST | [Yahoo](https://finance.yahoo.com/quote/^RUT) |

## 米国/株価指数先物

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---|---|---|---|---|---|---|---|
| S&P500 futures | ES=F | 2026-07-13 | 7607 | 7615.25 | 7547.25 | 7554.25 | 7528.75 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/ES=F) |
| Mini Dow | YM=F | 2026-07-13 | 52844 | 53113 | 52603 | 52720 | 52624 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/YM=F) |
| Mini NQ100 | NQ=F | 2026-07-13 | 29952 | 30041 | 29386.5 | 29428.75 | 29468.5 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/NQ=F) |
| Mini S&P500 | MES=F | 2026-07-13 | 7607.25 | 7615.5 | 7547 | 7553.75 | 7528.75 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/MES=F) |

## 米国/ボラティリティ

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---|---|---|---|---|---|---|---|
| VIX | ^VIX | 2026-07-13 | 16.32 | 17.41 | 16.030001 | 17.16 | 16.13 | CLOSED | [Yahoo](https://finance.yahoo.com/quote/^VIX) |

## 暗号資産

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---|---|---|---|---|---|---|---|
| Bitcoin | BTC-USD | 2026-07-13 | 63745.570312 | 64252.097656 | 61786.308594 | 61867.49 | 63193.15 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/BTC-USD) |

## 中国/株価指数

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---|---|---|---|---|---|---|---|
| China market index/futures | 000300.SS | 2026-07-13 | 4745.438477 | 4775.235352 | 4670.249512 | 4695.383 | 4792.26 | CLOSED | [Yahoo](https://finance.yahoo.com/quote/000300.SS) |
| Shanghai index | ^SSEC | N/A | N/A | N/A | N/A | N/A | N/A | N/A | [Yahoo](https://finance.yahoo.com/quote/^SSEC) |

## 欧州/株価指数

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---|---|---|---|---|---|---|---|
| FTSE 100 | ^FTSE | 2026-07-13 | 10498.049805 | 10532.099609 | 10465 | 10498.29 | 10651.8 | CLOSED | [Yahoo](https://finance.yahoo.com/quote/^FTSE) |
| CAC 40 | ^FCHI | 2026-07-13 | 8306.639648 | 8375.370117 | 8306.639648 | 8364.65 | 8436.24 | CLOSED | [Yahoo](https://finance.yahoo.com/quote/^FCHI) |
| EURO STOXX 50 | ^STOXX50E | 2026-07-13 | 6243.52002 | 6282.959961 | 6242.290039 | 6271.02 | 6319.86 | CLOSED | [Yahoo](https://finance.yahoo.com/quote/^STOXX50E) |
| DAX | ^GDAXI | 2026-07-13 | 24963.800781 | 25154.580078 | 24963.800781 | 25114.25 | 25817.89 | CLOSED | [Yahoo](https://finance.yahoo.com/quote/^GDAXI) |
| MSCI EUROPE | ^125904-USD-STRD | 2026-07-13 | 2784.919922 | 2796.01001 | 2777.790039 | 2785.76 | 2765.38 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/^125904-USD-STRD) |

## 為替

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---|---|---|---|---|---|---|---|
| USD/JPY | JPY=X | 2026-07-14 | 161.630005 | 162.488007 | 161.584 | 162.417 | 162.088 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/JPY=X) |
| EUR/JPY | EURJPY=X | 2026-07-14 | 184.326996 | 185.464005 | 184.225006 | 184.909 | 185.453 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/EURJPY=X) |
