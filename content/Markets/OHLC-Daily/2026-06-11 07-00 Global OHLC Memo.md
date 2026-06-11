---
tags: [markets, ohlc, futures, fx, daily]
---

# 2026-06-11 07:00 Global OHLC Memo

[[Home]]

#markets #ohlc #futures #fx #daily

取得成功数: 25 / 26
N/A件数: 1
注意点: Yahoo Finance chart API を再取得。Close は取得時点の直近日足終値ベース。429対策として銘柄ごとに間隔を空け、指数バックオフで再試行。指数・先物・FX・暗号資産で取引時間が異なるため、セッション基準日は銘柄ごとに前後します。^SSEC は Yahoo 側で当回値が返らず、N/A を維持。

## 日本・アジア

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| Nikkei/USD Futures | NKD=F | 2026-06-10 | 64340 | 65090 | 63125 | 63220 | 64525 | N/A | [Yahoo](https://finance.yahoo.com/quote/NKD=F) |
| Nikkei 225 | ^N225 | 2026-06-10 | 64952.3789 | 65098.8594 | 63733.0391 | N/A | 65416.6289 | N/A | [Yahoo](https://finance.yahoo.com/quote/^N225) |

## コモディティ

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| Gold mini futures | MGC=F | 2026-06-10 | 4281.8999 | 4282.2998 | 4089.8 | 4094.5 | 4260 | N/A | [Yahoo](https://finance.yahoo.com/quote/MGC=F) |
| Silver futures | SI=F | 2026-06-10 | 65.2 | 65.89 | 63.425 | 63.5 | 65.094 | N/A | [Yahoo](https://finance.yahoo.com/quote/SI=F) |
| Platinum futures | PL=F | 2026-06-10 | 1728.5 | 1728.5 | 1648.6 | 1665.1 | 1708.6 | N/A | [Yahoo](https://finance.yahoo.com/quote/PL=F) |
| Palladium futures | PA=F | 2026-06-10 | 1240.5 | 1272.5 | 1201 | 1225.5 | 1213.6 | N/A | [Yahoo](https://finance.yahoo.com/quote/PA=F) |
| Copper futures | HG=F | 2026-06-10 | 6.345 | 6.356 | 6.1895 | 6.1995 | 6.3025 | N/A | [Yahoo](https://finance.yahoo.com/quote/HG=F) |
| WTI oil futures | CL=F | 2026-06-10 | 89.4 | 91.87 | 87.39 | 91.85 | 88.2 | N/A | [Yahoo](https://finance.yahoo.com/quote/CL=F) |

## 米国株・指数

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| NASDAQ | ^IXIC | 2026-06-10 | 25512.0703 | 25725.9961 | 25145.3027 | 25169.502 | 25678.8203 | N/A | [Yahoo](https://finance.yahoo.com/quote/^IXIC) |
| SOX | ^SOX | 2026-06-10 | 12501.8379 | 12870.5254 | 12157.6562 | 12206.4619 | 12657.8096 | N/A | [Yahoo](https://finance.yahoo.com/quote/^SOX) |
| S&P500 futures | ES=F | 2026-06-10 | 7380 | 7404.75 | 7256 | 7267 | 7392.75 | N/A | [Yahoo](https://finance.yahoo.com/quote/ES=F) |
| Mini Dow | YM=F | 2026-06-10 | 50843 | 50906 | 49873 | 49923 | 50909 | N/A | [Yahoo](https://finance.yahoo.com/quote/YM=F) |
| Mini NQ100 | NQ=F | 2026-06-10 | 29094.75 | 29250 | 28409 | 28472 | 29117 | N/A | [Yahoo](https://finance.yahoo.com/quote/NQ=F) |
| Mini S&P500 | MES=F | 2026-06-10 | 7382 | 7404.75 | 7256.25 | 7267 | 7392.75 | N/A | [Yahoo](https://finance.yahoo.com/quote/MES=F) |
| VIX | ^VIX | 2026-06-10 | 20.1 | 22.66 | 20.06 | 22.22 | 19.87 | N/A | [Yahoo](https://finance.yahoo.com/quote/^VIX) |

## 暗号資産

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| Bitcoin | BTC-USD | 2026-06-10 | 61672.1992 | 62783.9375 | 60910.793 | 61222.0703 | 61643.7812 | N/A | [Yahoo](https://finance.yahoo.com/quote/BTC-USD) |

## 中国

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| China market index/futures | 000300.SS | 2026-06-10 | 4753.1152 | 4786.5161 | 4718.9946 | N/A | 4801.8101 | N/A | [Yahoo](https://finance.yahoo.com/quote/000300.SS) |
| Shanghai index | ^SSEC | N/A | N/A | N/A | N/A | N/A | N/A | N/A | [Yahoo](https://finance.yahoo.com/quote/^SSEC) |

## 欧州・その他

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| Russell 2000 | ^RUT | 2026-06-10 | 2861.926 | 2905.2834 | 2833.4741 | 2835.4622 | 2867.02 | N/A | [Yahoo](https://finance.yahoo.com/quote/^RUT) |
| FTSE 100 | ^FTSE | 2026-06-10 | 10227.3799 | 10263.8096 | 10127.5996 | 10254.8096 | 10227.2998 | N/A | [Yahoo](https://finance.yahoo.com/quote/^FTSE) |
| CAC 40 | ^FCHI | 2026-06-10 | 8223.0498 | 8240.6299 | 8113 | 8161.8301 | 8203.4297 | N/A | [Yahoo](https://finance.yahoo.com/quote/^FCHI) |
| EURO STOXX 50 | ^STOXX50E | 2026-06-10 | 0 | 0 | 0 | 6009.9502 | 6049.7402 | N/A | [Yahoo](https://finance.yahoo.com/quote/^STOXX50E) |
| DAX | ^GDAXI | 2026-06-10 | 24507.4004 | 24517.4805 | 24043.5195 | 24195.3105 | 24433.0605 | N/A | [Yahoo](https://finance.yahoo.com/quote/^GDAXI) |
| MSCI EUROPE | ^125904-USD-STRD | 2026-06-10 | 2722.2 | 2730.76 | 2691.3201 | 2716.71 | 2720.8501 | N/A | [Yahoo](https://finance.yahoo.com/quote/^125904-USD-STRD) |

## 為替

| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| USD/JPY | JPY=X | 2026-06-10 | 160.481 | 160.519 | 160.462 | 160.486 | 160.384 | N/A | [Yahoo](https://finance.yahoo.com/quote/JPY=X) |
| EUR/JPY | EURJPY=X | 2026-06-10 | 185.144 | 185.177 | 185.102 | 185.164 | 185.002 | N/A | [Yahoo](https://finance.yahoo.com/quote/EURJPY=X) |
