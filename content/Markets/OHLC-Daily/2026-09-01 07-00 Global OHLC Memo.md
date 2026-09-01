# Global OHLC Memo

- 取得成功数: 25/26
- N/A件数: 6セル（全N/A行 1件）
- 注意点: Yahoo Finance 再取得を実施（stagger/backoff）。 再試行後も一部未取得: ^SSEC。

#markets #ohlc #futures #fx #daily

[[Home]]

## 日本株・先物

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---|---:|---:|---:|---:|---:|---|---|
| Nikkei/USD Futures | NKD=F | 2026-08-31 | 65610 | 66525 | 64620 | 65845 | 66060 | N/A | [Yahoo](https://finance.yahoo.com/quote/NKD%3DF) |
| Nikkei 225 | ^N225 | 2026-08-27 | 66775.78125 | 66954.6875 | 65782.59375 | 66311.93 | 65528.09 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5EN225) |

## コモディティ

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---|---:|---:|---:|---:|---:|---|---|
| Gold mini futures | MGC=F | 2026-08-31 | 4483.5 | 4521.5 | 4445.5 | 4497.6 | 4638.1 | N/A | [Yahoo](https://finance.yahoo.com/quote/MGC%3DF) |
| Silver futures | SI=F | 2026-08-31 | 66.80000305175781 | 68.18000030517578 | 65.83000183105469 | 67.205 | 68.636 | N/A | [Yahoo](https://finance.yahoo.com/quote/SI%3DF) |
| Platinum futures | PL=F | 2026-08-31 | 1840.199951171875 | 1850 | 1780.5 | 1801.3 | 1852.6 | N/A | [Yahoo](https://finance.yahoo.com/quote/PL%3DF) |
| Palladium futures | PA=F | 2026-08-31 | 1446 | 1461.5 | 1373.5 | 1379.5 | 1331.9 | N/A | [Yahoo](https://finance.yahoo.com/quote/PA%3DF) |
| Copper futures | HG=F | 2026-08-31 | 6.639999866485596 | 6.7270002365112305 | 6.593999862670898 | 6.689 | 6.7095 | N/A | [Yahoo](https://finance.yahoo.com/quote/HG%3DF) |
| WTI oil futures | CL=F | 2026-08-31 | 84.69000244140625 | 86.79000091552734 | 84.11000061035156 | 86.31 | 82.36 | N/A | [Yahoo](https://finance.yahoo.com/quote/CL%3DF) |

## 米国株・指数・先物

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---|---:|---:|---:|---:|---:|---|---|
| NASDAQ | ^IXIC | 2026-08-31 | 26358.55859375 | 26398.33203125 | 26249.771484375 | 26370.889 | 26180.46 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5EIXIC) |
| SOX | ^SOX | 2026-08-31 | 11529.158203125 | 11587.2607421875 | 11444.205078125 | 11535.051 | 11740.37 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5ESOX) |
| S&P500 futures | ES=F | 2026-08-31 | 7723.5 | 7724 | 7674.75 | 7701.25 | 7692 | N/A | [Yahoo](https://finance.yahoo.com/quote/ES%3DF) |
| Mini Dow | YM=F | 2026-08-31 | 53664 | 53664 | 53149 | 53256 | 53645 | N/A | [Yahoo](https://finance.yahoo.com/quote/YM%3DF) |
| Mini NQ100 | NQ=F | 2026-08-31 | 29540 | 29546.25 | 29273.5 | 29521 | 29276.75 | N/A | [Yahoo](https://finance.yahoo.com/quote/NQ%3DF) |
| Mini S&P500 | MES=F | 2026-08-31 | 7723.25 | 7724.75 | 7674.75 | 7701.5 | 7692 | N/A | [Yahoo](https://finance.yahoo.com/quote/MES%3DF) |
| VIX | ^VIX | 2026-08-31 | 15.239999771118164 | 15.479999542236328 | 14.859999656677246 | 14.92 | 15.85 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5EVIX) |

## 暗号資産

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---|---:|---:|---:|---:|---:|---|---|
| Bitcoin | BTC-USD | 2026-08-31 | 77695.484375 | 79218.1875 | 77447.7109375 | 79000 | 79027.42 | N/A | [Yahoo](https://finance.yahoo.com/quote/BTC-USD) |

## 中国・欧州

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---|---:|---:|---:|---:|---:|---|---|
| China market index/futures | 000300.SS | 2026-08-31 | 4561.986328125 | 4625.08642578125 | 4557.345703125 | 4625.0864 | 4609.1763 | N/A | [Yahoo](https://finance.yahoo.com/quote/000300.SS) |
| Shanghai index | ^SSEC | N/A | N/A | N/A | N/A | N/A | N/A | N/A | [Yahoo](https://finance.yahoo.com/quote/%5ESSEC) |
| Russell 2000 | ^RUT | 2026-08-31 | 2967.4326171875 | 2967.4326171875 | 2944.343994140625 | 2956.452 | 3017.87 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5ERUT) |
| FTSE 100 | ^FTSE | 2026-08-27 | 10878.2001953125 | 10878.5 | 10772.599609375 | 10824.26 | 10748.2 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5EFTSE) |
| CAC 40 | ^FCHI | 2026-08-27 | 8460.91015625 | 8460.91015625 | 8308.099609375 | 8334.5 | 8453.01 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5EFCHI) |
| EURO STOXX 50 | ^STOXX50E | 2026-08-27 | 6486.43994140625 | 6490.1298828125 | 6415.56982421875 | 6420.16 | 6447.98 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5ESTOXX50E) |
| DAX | ^GDAXI | 2026-08-27 | 26354.369140625 | 26402.810546875 | 26241.76953125 | 26258.11 | 26136.56 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5EGDAXI) |
| MSCI EUROPE | ^125904-USD-STRD | 2026-08-31 | 2887.050048828125 | 2890.9599609375 | 2876.2099609375 | 2877.17 | 2917.43 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5E125904-USD-STRD) |

## 為替

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---|---:|---:|---:|---:|---:|---|---|
| USD/JPY | JPY=X | 2026-08-31 | 159.7429962158203 | 159.75 | 159.69400024414062 | 159.741 | 158.904 | N/A | [Yahoo](https://finance.yahoo.com/quote/JPY%3DX) |
| EUR/JPY | EURJPY=X | 2026-08-31 | 185.56399536132812 | 185.6009979248047 | 185.52099609375 | 185.566 | 185.625 | N/A | [Yahoo](https://finance.yahoo.com/quote/EURJPY%3DX) |

