# Global OHLC Memo

- 取得成功数: 25/26
- N/A件数: 6セル（全N/A行 1件）
- 注意点: Yahoo Finance 再取得を実施（stagger/backoff）。 再試行後も一部未取得: ^SSEC。

#markets #ohlc #futures #fx #daily

[[Home]]

## 日本株・先物

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---|---:|---:|---:|---:|---:|---|---|
| Nikkei/USD Futures | NKD=F | 2026-10-05 | 69930 | 70365 | 69600 | 70210 | 66355 | N/A | [Yahoo](https://finance.yahoo.com/quote/NKD%3DF) |
| Nikkei 225 | ^N225 | 2026-10-02 | 68313.4609375 | 68741.4921875 | 68132.15625 | 69946.86 | 65877.62 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5EN225) |

## コモディティ

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---|---:|---:|---:|---:|---:|---|---|
| Gold mini futures | MGC=F | 2026-10-05 | 4169.39990234375 | 4199 | 4150.60009765625 | 4167.6 | 4147.7 | N/A | [Yahoo](https://finance.yahoo.com/quote/MGC%3DF) |
| Silver futures | SI=F | 2026-10-05 | 60.70000076293945 | 62.400001525878906 | 60.64500045776367 | 61.4 | 60.668 | N/A | [Yahoo](https://finance.yahoo.com/quote/SI%3DF) |
| Platinum futures | PL=F | 2026-10-05 | 1710.300048828125 | 1753.699951171875 | 1709.4000244140625 | 1731 | 1680.1 | N/A | [Yahoo](https://finance.yahoo.com/quote/PL%3DF) |
| Palladium futures | PA=F | 2026-10-05 | 1171 | 1192 | 1167 | 1176.5 | 1201.6 | N/A | [Yahoo](https://finance.yahoo.com/quote/PA%3DF) |
| Copper futures | HG=F | 2026-10-05 | 6.572999954223633 | 6.6545000076293945 | 6.559000015258789 | 6.633 | 6.543 | N/A | [Yahoo](https://finance.yahoo.com/quote/HG%3DF) |
| WTI oil futures | CL=F | 2026-10-05 | 91.7699966430664 | 91.87999725341797 | 88.73999786376953 | 89.3 | 89.38 | N/A | [Yahoo](https://finance.yahoo.com/quote/CL%3DF) |

## 米国株・指数・先物

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---|---:|---:|---:|---:|---:|---|---|
| NASDAQ | ^IXIC | 2026-10-05 | 27225.9296875 | 27544.064453125 | 27223.494140625 | 27477.31 | 27068.72 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5EIXIC) |
| SOX | ^SOX | 2026-10-05 | 13148.8427734375 | 13179.7060546875 | 13004.66796875 | 13172.736 | 12668.93 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5ESOX) |
| S&P500 futures | ES=F | 2026-10-05 | 7781.5 | 7847.5 | 7760.25 | 7830 | 7732 | N/A | [Yahoo](https://finance.yahoo.com/quote/ES%3DF) |
| Mini Dow | YM=F | 2026-10-05 | 51486 | 51696 | 51141 | 51598 | 51702 | N/A | [Yahoo](https://finance.yahoo.com/quote/YM%3DF) |
| Mini NQ100 | NQ=F | 2026-10-05 | 31059 | 31371 | 30957.5 | 31339.5 | 30613.25 | N/A | [Yahoo](https://finance.yahoo.com/quote/NQ%3DF) |
| Mini S&P500 | MES=F | 2026-10-05 | 7781.5 | 7847.75 | 7760 | 7830.25 | 7732 | N/A | [Yahoo](https://finance.yahoo.com/quote/MES%3DF) |
| VIX | ^VIX | 2026-10-05 | 16.239999771118164 | 16.3799991607666 | 15.479999542236328 | 15.52 | 16.07 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5EVIX) |

## 暗号資産

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---|---:|---:|---:|---:|---:|---|---|
| Bitcoin | BTC-USD | 2026-10-05 | 86513.3828125 | 86929.65625 | 85098.796875 | 85959.99 | 83553.85 | N/A | [Yahoo](https://finance.yahoo.com/quote/BTC-USD) |

## 中国・欧州

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---|---:|---:|---:|---:|---:|---|---|
| China market index/futures | 000300.SS | 2026-09-30 | 4356.79541015625 | 4368.61376953125 | 4341.87890625 | 4357.616 | 4345.21 | N/A | [Yahoo](https://finance.yahoo.com/quote/000300.SS) |
| Shanghai index | ^SSEC | N/A | N/A | N/A | N/A | N/A | N/A | N/A | [Yahoo](https://finance.yahoo.com/quote/%5ESSEC) |
| Russell 2000 | ^RUT | 2026-10-05 | 2834.2314453125 | 2859.132080078125 | 2821.629638671875 | 2847.1357 | 2837.55 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5ERUT) |
| FTSE 100 | ^FTSE | 2026-10-05 | 10462.3798828125 | 10527.4599609375 | 10451.73046875 | 10497.94 | 10695.3 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5EFTSE) |
| CAC 40 | ^FCHI | 2026-10-05 | 7847.91015625 | 7866.7998046875 | 7796.580078125 | 7834.1 | 8078.48 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5EFCHI) |
| EURO STOXX 50 | ^STOXX50E | 2026-10-05 | 0 | 0 | 0 | 6242.14 | 6301.28 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5ESTOXX50E) |
| DAX | ^GDAXI | 2026-10-05 | 25251.390625 | 25324.69921875 | 25143.259765625 | 25254.21 | 25408.64 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5EGDAXI) |
| MSCI EUROPE | ^125904-USD-STRD | 2026-10-05 | 2700.070068359375 | 2714.3798828125 | 2689.840087890625 | 2704.94 | 2754.73 | N/A | [Yahoo](https://finance.yahoo.com/quote/%5E125904-USD-STRD) |

## 為替

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---|---:|---:|---:|---:|---:|---|---|
| USD/JPY | JPY=X | 2026-10-05 | 157.85899353027344 | 157.88900756835938 | 157.83900451660156 | 157.876 | 157.463 | N/A | [Yahoo](https://finance.yahoo.com/quote/JPY%3DX) |
| EUR/JPY | EURJPY=X | 2026-10-05 | 177.08799743652344 | 177.18299865722656 | 177.08799743652344 | 177.088 | 179.157 | N/A | [Yahoo](https://finance.yahoo.com/quote/EURJPY%3DX) |

