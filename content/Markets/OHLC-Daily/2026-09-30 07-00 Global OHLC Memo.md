# Global OHLC Memo

- 取得成功数: 25/26
- N/A件数: 6セル（全N/A行 1件）
- 注意点: Yahoo Finance 再取得を実施（stagger/backoff）。 再試行後も一部未取得: ^SSEC。

#markets #ohlc #futures #fx #daily

[[Home]]

## 日本株・先物

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---|---:|---:|---:|---:|---:|---|---|
| Nikkei/USD Futures | NKD=F | 2026-09-29 | 65830 | 66515 | 64945 | 66350 | 65990 | N/A | [Yahoo](https://finance.yahoo.com/quote/NKD%3DF) |
| Nikkei 225 | ^N225 | 2026-09-28 | 66505.9375 | 67034.7421875 | 65877.6171875 | 65481.27 | 64136.25 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5EN225) |

## コモディティ

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---|---:|---:|---:|---:|---:|---|---|
| Gold mini futures | MGC=F | 2026-09-29 | 4150.10009765625 | 4218 | 4145 | 4215 | 4284.8 | N/A | [Yahoo](https://finance.yahoo.com/quote/MGC%3DF) |
| Silver futures | SI=F | 2026-09-29 | 61.029998779296875 | 61.904998779296875 | 60.630001068115234 | 61.845 | 64.382 | N/A | [Yahoo](https://finance.yahoo.com/quote/SI%3DF) |
| Platinum futures | PL=F | 2026-09-29 | 1736.5999755859375 | 1741.199951171875 | 1695.300048828125 | 1725.5 | 1745.7 | N/A | [Yahoo](https://finance.yahoo.com/quote/PL%3DF) |
| Palladium futures | PA=F | 2026-09-29 | 1218 | 1245 | 1206.5 | 1231.5 | 1257.9 | N/A | [Yahoo](https://finance.yahoo.com/quote/PA%3DF) |
| Copper futures | HG=F | 2026-09-29 | 6.613999843597412 | 6.664999961853027 | 6.579500198364258 | 6.6585 | 6.678 | N/A | [Yahoo](https://finance.yahoo.com/quote/HG%3DF) |
| WTI oil futures | CL=F | 2026-09-29 | 93.52999877929688 | 94.73999786376953 | 88.77999877929688 | 88.94 | 92.16 | N/A | [Yahoo](https://finance.yahoo.com/quote/CL%3DF) |

## 米国株・指数・先物

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---|---:|---:|---:|---:|---:|---|---|
| NASDAQ | ^IXIC | 2026-09-29 | 26908.7578125 | 26919.724609375 | 26717.951171875 | 26797.541 | 27122.09 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5EIXIC) |
| SOX | ^SOX | 2026-09-29 | 12667.365234375 | 12773.88671875 | 12588.857421875 | 12629.161 | 12433.17 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5ESOX) |
| S&P500 futures | ES=F | 2026-09-29 | 7746.5 | 7770.75 | 7712.25 | 7738.25 | 7772.5 | N/A | [Yahoo](https://finance.yahoo.com/quote/ES%3DF) |
| Mini Dow | YM=F | 2026-09-29 | 51845 | 52002 | 51459 | 51755 | 51873 | N/A | [Yahoo](https://finance.yahoo.com/quote/YM%3DF) |
| Mini NQ100 | NQ=F | 2026-09-29 | 30560.5 | 30725.5 | 30372.25 | 30652.75 | 30764.75 | N/A | [Yahoo](https://finance.yahoo.com/quote/NQ%3DF) |
| Mini S&P500 | MES=F | 2026-09-29 | 7746.75 | 7767.75 | 7712.25 | 7738.25 | 7772.5 | N/A | [Yahoo](https://finance.yahoo.com/quote/MES%3DF) |
| VIX | ^VIX | 2026-09-29 | 16.170000076293945 | 16.440000534057617 | 15.729999542236328 | 16.04 | 14.21 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5EVIX) |

## 暗号資産

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---|---:|---:|---:|---:|---:|---|---|
| Bitcoin | BTC-USD | 2026-09-29 | 83488 | 84457.8125 | 82800.3984375 | 83461.71 | 84379.06 | N/A | [Yahoo](https://finance.yahoo.com/quote/BTC-USD) |

## 中国・欧州

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---|---:|---:|---:|---:|---:|---|---|
| China market index/futures | 000300.SS | 2026-09-29 | 4335.80859375 | 4359.30126953125 | 4324.529296875 | 4345.209 | 4340.755 | N/A | [Yahoo](https://finance.yahoo.com/quote/000300.SS) |
| Shanghai index | ^SSEC | N/A | N/A | N/A | N/A | N/A | N/A | N/A | [Yahoo](https://finance.yahoo.com/quote/%5ESSEC) |
| Russell 2000 | ^RUT | 2026-09-29 | 2820.3564453125 | 2825.36767578125 | 2794.3857421875 | 2807.922 | 2875.36 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5ERUT) |
| FTSE 100 | ^FTSE | 2026-09-29 | 10685.1904296875 | 10756.150390625 | 10622 | 10636.71 | 10739 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5EFTSE) |
| CAC 40 | ^FCHI | 2026-09-29 | 8086.16015625 | 8107.27978515625 | 8023.97998046875 | 8035.87 | 8154.91 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5EFCHI) |
| EURO STOXX 50 | ^STOXX50E | 2026-09-29 | 0 | 0 | 0 | 6320.26 | 6324.72 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5ESTOXX50E) |
| DAX | ^GDAXI | 2026-09-29 | 25374.33984375 | 25617.310546875 | 25338.029296875 | 25399.21 | 25575.01 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5EGDAXI) |
| MSCI EUROPE | ^125904-USD-STRD | 2026-09-29 | 2767.10009765625 | 2778.969970703125 | 2749.489990234375 | 2754.73 | 2776.95 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5E125904-USD-STRD) |

## 為替

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---|---:|---:|---:|---:|---:|---|---|
| USD/JPY | JPY=X | 2026-09-29 | 157.24600219726562 | 157.27200317382812 | 157.23699951171875 | 157.25 | 157.369 | N/A | [Yahoo](https://finance.yahoo.com/quote/JPY%3DX) |
| EUR/JPY | EURJPY=X | 2026-09-29 | 178.35800170898438 | 178.38999938964844 | 178.35499572753906 | 178.387 | 180.396 | N/A | [Yahoo](https://finance.yahoo.com/quote/EURJPY%3DX) |

