# Global OHLC Memo (Yahoo Finance)

作成時刻: 2026-05-08 06:43 JST
取得成功数: 0 / 26  ・N/A件数: 26  ・注意点: marketStateはYahoo chart API(v8)では未提供の銘柄が多く、N/Aが出ています（OHLC/Close/前日終値は取得）。

## 株式指数・先物（日本/米国）

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| Nikkei/USD Futures | NKD=F | 2026-05-08 | 62155 | 63400 | 61760 | 62150 | 59505 | N/A | [link](https://finance.yahoo.com/quote/NKD=F) |
| Nikkei 225 | ^N225 | 2026-05-07 | 60241.3 | 63091.1 | 60213 | 62833.8 | 60537.4 | N/A | [link](https://finance.yahoo.com/quote/^N225) |
| S&P500 futures | ES=F | 2026-05-08 | 7380.5 | 7410.5 | 7345.5 | 7352.25 | 7230.25 | N/A | [link](https://finance.yahoo.com/quote/ES=F) |
| Mini Dow | YM=F | 2026-05-08 | 50024 | 50238 | 49581 | 49639 | 49079 | N/A | [link](https://finance.yahoo.com/quote/YM=F) |
| Mini NQ100 | NQ=F | 2026-05-08 | 28662.8 | 28944.8 | 28552 | 28644 | 27776 | N/A | [link](https://finance.yahoo.com/quote/NQ=F) |
| Mini S&P500 | MES=F | 2026-05-08 | 7381.5 | 7410.75 | 7345.5 | 7353 | 7230.25 | N/A | [link](https://finance.yahoo.com/quote/MES=F) |
| NASDAQ | ^IXIC | 2026-05-08 | 25881.3 | 26036.4 | 25713.6 | 25806.2 | 24892.3 | N/A | [link](https://finance.yahoo.com/quote/^IXIC) |
| SOX | ^SOX | 2026-05-08 | 11332.2 | 11404.4 | 11075.1 | 11161 | 10503.7 | N/A | [link](https://finance.yahoo.com/quote/^SOX) |
| Russell 2000 | ^RUT | 2026-05-08 | 2886.88 | 2886.88 | 2832.73 | 2839.63 | 2799.91 | N/A | [link](https://finance.yahoo.com/quote/^RUT) |
| VIX | ^VIX | 2026-05-08 | 17.53 | 17.6 | 16.85 | 17.08 | 16.99 | N/A | [link](https://finance.yahoo.com/quote/^VIX) |

## コモディティ先物

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| Gold mini futures | MGC=F | 2026-05-08 | 4702 | 4775.3 | 4690 | 4694.4 | 4533.3 | N/A | [link](https://finance.yahoo.com/quote/MGC=F) |
| Silver futures | SI=F | 2026-05-08 | 77.83 | 82.675 | 77.455 | 78.915 | 73.072 | N/A | [link](https://finance.yahoo.com/quote/SI=F) |
| Platinum futures | PL=F | 2026-05-08 | 2069.2 | 2113.6 | 2032.4 | 2032.6 | 1946.9 | N/A | [link](https://finance.yahoo.com/quote/PL=F) |
| Palladium futures | PA=F | 2026-05-08 | 1557 | 1577.5 | 1491 | 1493 | 1474.7 | N/A | [link](https://finance.yahoo.com/quote/PA=F) |
| Copper futures | HG=F | 2026-05-08 | 6.1895 | 6.2445 | 6.1235 | 6.125 | 5.795 | N/A | [link](https://finance.yahoo.com/quote/HG=F) |
| WTI oil futures | CL=F | 2026-05-08 | 96.3 | 97.99 | 89.85 | 97.66 | 106.42 | N/A | [link](https://finance.yahoo.com/quote/CL=F) |

## 欧州指数

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| FTSE 100 | ^FTSE | 2026-05-08 | 10438.6 | 10440.5 | 10277 | 10277 | 10213.1 | N/A | [link](https://finance.yahoo.com/quote/^FTSE) |
| CAC 40 | ^FCHI | 2026-05-08 | 8320.33 | 8361 | 8202.08 | 8202.08 | 8114.84 | N/A | [link](https://finance.yahoo.com/quote/^FCHI) |
| EURO STOXX 50 | ^STOXX50E | 2026-05-08 | 6032.75 | 6066.39 | 5967.92 | 5972.65 | 5881.51 | N/A | [link](https://finance.yahoo.com/quote/^STOXX50E) |
| DAX | ^GDAXI | 2026-05-08 | 24940.4 | 25021 | 24651 | 24663.6 | 23954.6 | N/A | [link](https://finance.yahoo.com/quote/^GDAXI) |
| MSCI EUROPE | ^125904-USD-STRD | 2026-05-08 | 2779.93 | 2788.89 | 2741.78 | 2753.52 | 2688.62 | N/A | [link](https://finance.yahoo.com/quote/^125904-USD-STRD) |

## 中国指数

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| China market index/futures | 000300.SS | 2026-05-07 | 4895.8 | 4901.86 | 4866.88 | 4900.51 | 4758.21 | N/A | [link](https://finance.yahoo.com/quote/000300.SS) |
| Shanghai index | ^SSEC | N/A | N/A | N/A | N/A | N/A | N/A | N/A | [link](https://finance.yahoo.com/quote/^SSEC) |

## 暗号資産・FX

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| Bitcoin | BTC-USD | 2026-05-08 | 81423.9 | 81665.9 | 79658.8 | 79855.9 | 78538.2 | N/A | [link](https://finance.yahoo.com/quote/BTC-USD) |
| USD/JPY | JPY=X | 2026-05-08 | 156.268 | 156.956 | 156.011 | 156.762 | 156.978 | N/A | [link](https://finance.yahoo.com/quote/JPY=X) |
| EUR/JPY | EURJPY=X | 2026-05-08 | 183.621 | 184.239 | 183.489 | 183.894 | 184.149 | N/A | [link](https://finance.yahoo.com/quote/EURJPY=X) |

#markets #ohlc #futures #fx #daily

[[Home]]
