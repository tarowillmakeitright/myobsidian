# Global OHLC Memo

作成時刻: 2026-04-08 14:55 JST

## サマリー
- 取得成功数: 25/26
- N/A件数: 1
- 注意点: Yahoo chart API (query2.finance.yahoo.com) の日足・meta値を使用。marketStateはcurrentTradingPeriodから推定（取得不可はN/A）。

## 日本・アジア

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| Nikkei/USD Futures | NKD=F | 2026-04-08 | 54020 | 56540 | 54010 | 56530 | 53390 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/NKD=F) |
| Nikkei 225 | ^N225 | 2026-04-08 | 54386.648438 | 56358.828125 | 54380.019531 | 56348.49 | 52463.27 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/%5EN225) |
| China market index/futures | 000300.SS | 2026-04-08 | 4517.340332 | 4589.705078 | 4513.770508 | 4589.101 | 4526.07 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/000300.SS) |
| Shanghai index | ^SSEC | N/A | N/A | N/A | N/A | N/A | N/A | N/A | [Yahoo](https://finance.yahoo.com/quote/%5ESSEC) |

## 米国指数・先物

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| NASDAQ | ^IXIC | 2026-04-08 | 21927.085938 | 22024.896484 | 21611 | 22017.85 | 20794.64 | CLOSED | [Yahoo](https://finance.yahoo.com/quote/%5EIXIC) |
| SOX | ^SOX | 2026-04-08 | 7915.170898 | 8006.34082 | 7790.067871 | 8003.8677 | 7142.33 | CLOSED | [Yahoo](https://finance.yahoo.com/quote/%5ESOX) |
| S&P500 futures | ES=F | 2026-04-08 | 6689 | 6832.75 | 6652.25 | 6830.25 | 6622.25 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/ES=F) |
| Mini Dow | YM=F | 2026-04-08 | 47007 | 47935 | 46828 | 47924 | 46732 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/YM=F) |
| Mini NQ100 | NQ=F | 2026-04-08 | 24514 | 25176 | 24355 | 25163.75 | 24218 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/NQ=F) |
| Mini S&P500 | MES=F | 2026-04-08 | 6677.25 | 6833 | 6675 | 6830 | 6622.25 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/MES=F) |
| VIX | ^VIX | 2026-04-08 | 24.93 | 25.299999 | 23.780001 | 25.78 | 24.54 | CLOSED | [Yahoo](https://finance.yahoo.com/quote/%5EVIX) |
| Russell 2000 | ^RUT | 2026-04-08 | 2534.546387 | 2547.914795 | 2515.495361 | 2544.945 | 2414.01 | CLOSED | [Yahoo](https://finance.yahoo.com/quote/%5ERUT) |

## 欧州指数

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| FTSE 100 | ^FTSE | 2026-04-08 | 10436.200195 | 10487.669922 | 10330.879883 | 10348.79 | 9967.4 | CLOSED | [Yahoo](https://finance.yahoo.com/quote/%5EFTSE) |
| CAC 40 | ^FCHI | 2026-04-08 | 7877.5 | 7993.080078 | 7856.890137 | 7908.74 | 7772.45 | CLOSED | [Yahoo](https://finance.yahoo.com/quote/%5EFCHI) |
| EURO STOXX 50 | ^STOXX50E | 2026-04-08 | 5672.129883 | 5712.890137 | 5589.209961 | 5633.22 | 5541.79 | CLOSED | [Yahoo](https://finance.yahoo.com/quote/%5ESTOXX50E) |
| DAX | ^GDAXI | 2026-04-08 | 23181.650391 | 23397.890625 | 22842.140625 | 22921.59 | 22300.75 | CLOSED | [Yahoo](https://finance.yahoo.com/quote/%5EGDAXI) |
| MSCI EUROPE | ^125904-USD-STRD | 2026-04-08 | 2622.169922 | 2643.75 | 2589.459961 | 2597.25 | 2619.2 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/%5E125904-USD-STRD) |

## コモディティ

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| Gold mini futures | MGC=F | 2026-04-08 | 4745.600098 | 4887.299805 | 4739.5 | 4854.7 | 4651.5 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/MGC=F) |
| Silver futures | SI=F | 2026-04-08 | 73.449997 | 77.445 | 73.345001 | 77.23 | 72.735 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/SI=F) |
| Platinum futures | PL=F | 2026-04-08 | 1970 | 2056.600098 | 1966.699951 | 2046.2 | 1963.8 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/PL=F) |
| Palladium futures | PA=F | 2026-04-08 | 1479.5 | 1549 | 1476 | 1547.5 | 1491.4 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/PA=F) |
| Copper futures | HG=F | 2026-04-08 | 5.6025 | 5.749 | 5.6025 | 5.734 | 5.563 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/HG=F) |
| WTI oil futures | CL=F | 2026-04-08 | 108.739998 | 109.190002 | 91.050003 | 95.9 | 111.54 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/CL=F) |

## 為替

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| USD/JPY | JPY=X | 2026-04-08 | 159.518997 | 159.738998 | 158.138 | 158.251 | 158.688 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/JPY=X) |
| EUR/JPY | EURJPY=X | 2026-04-08 | 184.970001 | 185.548996 | 184.800003 | 185.076 | 183.898 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/EURJPY=X) |

## 暗号資産

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| Bitcoin | BTC-USD | 2026-04-08 | 71926.15625 | 71978.554688 | 71284.617188 | 71746.62 | 67290.516 | REGULAR | [Yahoo](https://finance.yahoo.com/quote/BTC-USD) |

#markets #ohlc #futures #fx #daily
[[Home]]
