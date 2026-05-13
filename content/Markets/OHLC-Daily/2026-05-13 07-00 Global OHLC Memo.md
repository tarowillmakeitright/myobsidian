# 2026-05-13 07-00 Global OHLC Memo

#markets #ohlc #futures #fx #daily

[[Home]]

取得成功数: 25/26 | N/A件数: 1
注意点: Yahoo Finance chart APIで再取得（stagger + backoff）。 一部未取得: ^SSEC:404 Client Error: Not Found for url: https://query2.finance.yahoo.com/v8/finance/chart/%5ESSEC?range=5d&interval=1d

### アジア株価指数
| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| Nikkei 225 | ^N225 | 2026-05-12 | 62,618.7188 | 63,218.5117 | 62,158.4297 | 62,417.8789 | 59,513.12 | OSA | [https://finance.yahoo.com/quote/^N225](https://finance.yahoo.com/quote/^N225) |
| China market index/futures | 000300.SS | 2026-05-12 | 4,965.0176 | 4,971.3027 | 4,926.7896 | 4,951.8398 | 4,877.09 | SHH | [https://finance.yahoo.com/quote/000300.SS](https://finance.yahoo.com/quote/000300.SS) |
| Shanghai index | ^SSEC | N/A | N/A | N/A | N/A | N/A | N/A | N/A | [https://finance.yahoo.com/quote/^SSEC](https://finance.yahoo.com/quote/^SSEC) |

### 米国株価指数
| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| NASDAQ | ^IXIC | 2026-05-12 | 26,087.0098 | 26,190.4785 | 25,739.2246 | 26,088.2031 | 25,326.13 | NIM | [https://finance.yahoo.com/quote/^IXIC](https://finance.yahoo.com/quote/^IXIC) |
| SOX | ^SOX | 2026-05-12 | 11,741.4717 | 11,919.0029 | 11,263.5791 | 11,717.2578 | 10,980.58 | NIM | [https://finance.yahoo.com/quote/^SOX](https://finance.yahoo.com/quote/^SOX) |
| VIX | ^VIX | 2026-05-12 | 18.77 | 19.1 | 17.92 | 17.99 | 17.39 | CXI | [https://finance.yahoo.com/quote/^VIX](https://finance.yahoo.com/quote/^VIX) |
| Russell 2000 | ^RUT | 2026-05-12 | 2,861.8291 | 2,861.8291 | 2,799.6929 | 2,842.8311 | 2,845 | WCB | [https://finance.yahoo.com/quote/^RUT](https://finance.yahoo.com/quote/^RUT) |

### 欧州株価指数
| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| FTSE 100 | ^FTSE | 2026-05-12 | 10,271.1699 | 10,271.1699 | 10,152.0498 | 10,265.3203 | 10,219.1 | FGI | [https://finance.yahoo.com/quote/^FTSE](https://finance.yahoo.com/quote/^FTSE) |
| CAC 40 | ^FCHI | 2026-05-12 | 7,973.9902 | 8,026.8101 | 7,962.75 | 8,056.3799 | 8,299.42 | PAR | [https://finance.yahoo.com/quote/^FCHI](https://finance.yahoo.com/quote/^FCHI) |
| EURO STOXX 50 | ^STOXX50E | 2026-05-12 | 0 | 0 | 0 | 5,895.4502 | 6,027.13 | ZRH | [https://finance.yahoo.com/quote/^STOXX50E](https://finance.yahoo.com/quote/^STOXX50E) |
| DAX | ^GDAXI | 2026-05-12 | 24,048.25 | 24,210.7402 | 23,920.6992 | 24,350.2793 | 24,401.7 | GER | [https://finance.yahoo.com/quote/^GDAXI](https://finance.yahoo.com/quote/^GDAXI) |
| MSCI EUROPE | ^125904-USD-STRD | 2026-05-12 | 2,714.3601 | 2,716.95 | 2,694.8101 | 2,701.8799 | 2,753.52 | MSC | [https://finance.yahoo.com/quote/^125904-USD-STRD](https://finance.yahoo.com/quote/^125904-USD-STRD) |

### 株価指数先物
| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| Nikkei/USD Futures | NKD=F | 2026-05-12 | 62,945 | 63,285 | 61,805 | 62,545 | 62,255 | CME | [https://finance.yahoo.com/quote/NKD=F](https://finance.yahoo.com/quote/NKD=F) |
| S&P500 futures | ES=F | 2026-05-12 | 7,435.5 | 7,443.75 | 7,363.25 | 7,420.5 | 7,363 | CME | [https://finance.yahoo.com/quote/ES=F](https://finance.yahoo.com/quote/ES=F) |
| Mini Dow | YM=F | 2026-05-12 | 49,788 | 49,924 | 49,397 | 49,867 | 49,700 | CBT | [https://finance.yahoo.com/quote/YM=F](https://finance.yahoo.com/quote/YM=F) |
| Mini NQ100 | NQ=F | 2026-05-12 | 29,399 | 29,455.75 | 28,742 | 29,134.25 | 28,682.25 | CME | [https://finance.yahoo.com/quote/NQ=F](https://finance.yahoo.com/quote/NQ=F) |
| Mini S&P500 | MES=F | 2026-05-12 | 7,435.25 | 7,443.75 | 7,363.25 | 7,420.5 | 7,363 | CME | [https://finance.yahoo.com/quote/MES=F](https://finance.yahoo.com/quote/MES=F) |

### コモディティ先物
| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| Gold mini futures | MGC=F | 2026-05-12 | 4,746 | 4,783.5 | 4,645.2998 | 4,722.7998 | 4,710.9 | CMX | [https://finance.yahoo.com/quote/MGC=F](https://finance.yahoo.com/quote/MGC=F) |
| Silver futures | SI=F | 2026-05-12 | 86.74 | 88 | 83.67 | 87.205 | 79.701 | CMX | [https://finance.yahoo.com/quote/SI=F](https://finance.yahoo.com/quote/SI=F) |
| Platinum futures | PL=F | 2026-05-12 | 2,153.3999 | 2,167.8 | 2,075.7 | 2,147 | 2,048.1 | NYM | [https://finance.yahoo.com/quote/PL=F](https://finance.yahoo.com/quote/PL=F) |
| Palladium futures | PA=F | 2026-05-12 | 1,530 | 1,540.5 | 1,464 | 1,510.5 | 1,517.8 | NYM | [https://finance.yahoo.com/quote/PA=F](https://finance.yahoo.com/quote/PA=F) |
| Copper futures | HG=F | 2026-05-12 | 6.492 | 6.659 | 6.4405 | 6.6335 | 6.128 | CMX | [https://finance.yahoo.com/quote/HG=F](https://finance.yahoo.com/quote/HG=F) |
| WTI oil futures | CL=F | 2026-05-12 | 98.39 | 102.72 | 98 | 102.05 | 94.81 | NYM | [https://finance.yahoo.com/quote/CL=F](https://finance.yahoo.com/quote/CL=F) |

### FX
| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| USD/JPY | JPY=X | 2026-05-13 | 157.564 | 157.608 | 157.527 | 157.607 | 157.677 | CCY | [https://finance.yahoo.com/quote/JPY=X](https://finance.yahoo.com/quote/JPY=X) |
| EUR/JPY | EURJPY=X | 2026-05-13 | 184.946 | 185.021 | 184.827 | 185.017 | 184.739 | CCY | [https://finance.yahoo.com/quote/EURJPY=X](https://finance.yahoo.com/quote/EURJPY=X) |

### 暗号資産
| 銘柄 | ティッカー | セッション基準日 | Open | High | Low | Close(取得時点) | 前日終値 | 状態(marketState) | ソース(Yahooリンク) |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| Bitcoin | BTC-USD | 2026-05-12 | 81,721.4141 | 81,721.4141 | 79,933.125 | 80,711 | 80,186.766 | CCC | [https://finance.yahoo.com/quote/BTC-USD](https://finance.yahoo.com/quote/BTC-USD) |
